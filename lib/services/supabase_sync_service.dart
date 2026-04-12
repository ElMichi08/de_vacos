import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/db_helper.dart';

/// Sincronización de reportes de ventas y cierre de caja hacia Supabase (no bloquea la UI).
class SupabaseSyncService {
  SupabaseSyncService._();

  /// Días hacia atrás para intentar subir reportes diarios en background (mismo alcance que el antiguo envío tras verificación).
  static const int _reportLookbackDays = 14;

  /// Vacío si no hay CLIENTE_ID; no lanza (evita cierre en release sin defines).
  static String get clienteId {
    if (kReleaseMode) {
      return String.fromEnvironment('CLIENTE_ID', defaultValue: '');
    }
    final id = dotenv.env['CLIENTE_ID'];
    if (id == null || id.isEmpty) {
      if (kDebugMode) {
        debugPrint('CLIENTE_ID no definido en .env; sync a Supabase omitido.');
      }
      return '';
    }
    return id;
  }

  /// Intenta subir reportes de los últimos [_reportLookbackDays] días en segundo plano. No lanza.
  static Future<void> syncDailyReportsInBackground() async {
    try {
      if (clienteId.isEmpty) {
        if (kDebugMode) {
          debugPrint('Supabase sync background: CLIENTE_ID vacío, omitido.');
        }
        return;
      }
      final hoy = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      int enviados = 0;
      for (int i = 0; i < _reportLookbackDays; i++) {
        final fecha = hoy.subtract(Duration(days: i));
        final esHoy = i == 0;
        try {
          final auditoria = await DBHelper.obtenerAuditoriaSemanal(
            fecha,
            fecha,
          );
          final cantidadPedidos = (auditoria['cantidad'] as int?) ?? 0;
          final totalVentas = (auditoria['total'] as num?)?.toDouble() ?? 0.0;
          final debeEnviar = esHoy || totalVentas > 0;
          if (!debeEnviar) continue;
          final topProductos = await DBHelper.obtenerTopProductosPorVentas(
            fecha,
            fecha,
            limit: 3,
          );
          await _upsertReporteSemanal(
            fechaCorte: fecha,
            cantidadPedidos: cantidadPedidos,
            totalVentas: totalVentas,
            topProductos: topProductos,
          );
          enviados++;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Error al sincronizar fecha ${_formatearFecha(fecha)}',
            );
          }
        }
      }
      if (kDebugMode && enviados > 0) {
        debugPrint('✅ Reportes en background: $enviados días enviados.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en envío background de reportes: $e');
      }
    }
  }

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  static Future<void> _upsertReporteSemanal({
    required DateTime fechaCorte,
    required int cantidadPedidos,
    required double totalVentas,
    List<Map<String, dynamic>>? topProductos,
  }) async {
    try {
      if (clienteId.isEmpty) {
        if (kDebugMode) {
          debugPrint('Upsert reporte omitido: CLIENTE_ID vacío.');
        }
        return;
      }
      final supabase = Supabase.instance.client;
      final fechaString =
          '${fechaCorte.year.toString().padLeft(4, '0')}-'
          '${fechaCorte.month.toString().padLeft(2, '0')}-'
          '${fechaCorte.day.toString().padLeft(2, '0')}';

      final datos = <String, dynamic>{
        'cliente_id': clienteId,
        'fecha_corte': fechaString,
        'cantidad_pedidos': cantidadPedidos,
        'total_ventas': totalVentas,
      };
      if (topProductos != null && topProductos.isNotEmpty) {
        datos['top_productos'] = topProductos;
      }

      await supabase
          .from('reportes_semanales')
          .upsert(datos, onConflict: 'cliente_id,fecha_corte');
      if (kDebugMode) {
        debugPrint('✅ Reporte sincronizado (${_formatearFecha(fechaCorte)})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al subir reporte: $e');
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('row-level security') ||
            errorString.contains('rls') ||
            errorString.contains('42501') ||
            errorString.contains('unauthorized')) {
          debugPrint('⚠️ Revisa RLS en reportes_semanales.');
        }
      }
    }
  }

  /// Envía un reporte de cierre de caja a Supabase. Relanza errores para que la UI los muestre.
  static Future<bool> enviarCierreCaja({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    if (clienteId.isEmpty) {
      throw Exception(
        'CLIENTE_ID no configurado. En debug use .env; en release --dart-define=CLIENTE_ID=...',
      );
    }
    final connectivityResult = await Connectivity().checkConnectivity();
    final tieneInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (!tieneInternet) {
      throw Exception(
        'No hay conexión a internet. Verifique su conexión e intente nuevamente.',
      );
    }

    final auditoria = await DBHelper.obtenerAuditoriaSemanal(
      fechaInicio,
      fechaFin,
    );

    final cantidadPedidos = (auditoria['cantidad'] as int?) ?? 0;
    final totalVentas = (auditoria['total'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
      'Cierre de caja: $cantidadPedidos pedidos, \$${totalVentas.toStringAsFixed(2)}',
    );

    final fechaCorte = DateTime.now();
    final topProductos = await DBHelper.obtenerTopProductosPorVentas(
      fechaInicio,
      fechaFin,
      limit: 3,
    );
    await _upsertReporteSemanal(
      fechaCorte: fechaCorte,
      cantidadPedidos: cantidadPedidos,
      totalVentas: totalVentas,
      topProductos: topProductos,
    );
    return true;
  }
}
