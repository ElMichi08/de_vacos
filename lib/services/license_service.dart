import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/database/db_helper.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar la verificación de licencia y reporte de ventas
class LicenseService {
  // ID del cliente desde variables de entorno (obligatorio)
  static String get clienteId {
    final id = dotenv.env['CLIENTE_ID'];
    if (id == null || id.isEmpty) {
      throw Exception('CLIENTE_ID no está definido en el archivo .env');
    }
    return id;
  }
  
  // Clave para SharedPreferences
  static const String _keyLastCheckDate = 'last_check_date';
  
  // Días de gracia sin conexión
  static const int diasGracia = 3;
  
  /// Obtiene la deuda pendiente del cliente desde la tabla cobros
  /// Suma todos los monto_a_pagar donde estado = 'pendiente'
  /// Retorna 0.0 si no hay deuda o si hay error
  static Future<double> obtenerDeudaPendiente() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Consultar cobros pendientes del cliente
      final cobros = await supabase
          .from('cobros')
          .select('monto_a_pagar')
          .eq('cliente_id', clienteId)
          .eq('estado', 'pendiente');
      
      if (cobros == null || cobros.isEmpty) {
        return 0.0;
      }
      
      // Sumar todos los montos pendientes
      double deudaTotal = 0.0;
      for (var cobro in cobros) {
        final monto = (cobro['monto_a_pagar'] as num?)?.toDouble() ?? 0.0;
        deudaTotal += monto;
      }
      
      debugPrint('Deuda pendiente calculada: \$${deudaTotal.toStringAsFixed(2)}');
      return deudaTotal;
    } catch (e) {
      debugPrint('Error al obtener deuda pendiente: $e');
      // Retornar 0.0 en caso de error para no bloquear la app
      return 0.0;
    }
  }
  
  /// Verifica la licencia y reporta las ventas usando "Barrido de Seguridad" de 3 días
  /// Retorna un Map con:
  /// - 'licenciaActiva': bool (true si está activa, false si está bloqueada)
  /// - 'deudaTotal': double (suma de todos los cobros pendientes)
  /// Maneja período de gracia de 3 días si no hay conexión
  /// 
  /// Estrategia: Itera sobre los últimos 3 días (Hoy, Ayer, Anteayer)
  /// - HOY: Siempre envía (incluso si es 0) para auditoría
  /// - PASADO: Solo envía si total_ventas > 0 (evita llenar BD de ceros)
  static Future<Map<String, dynamic>> verificarYReportar() async {
    try {
      // Verificar conectividad
      final connectivityResult = await Connectivity().checkConnectivity();
      final tieneInternet = connectivityResult != ConnectivityResult.none;
      
      if (!tieneInternet) {
        debugPrint('Sin conexión a internet. Verificando período de gracia...');
        final periodoGracia = await _verificarPeriodoGracia();
        // En modo offline, no podemos obtener la deuda, retornar 0.0
        return {
          'licenciaActiva': periodoGracia,
          'deudaTotal': 0.0,
        };
      }
      
      // Hay internet: proceder con verificación y reporte
      try {
        final ahora = DateTime.now();
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        
        // Barrido de Seguridad: iterar sobre los últimos 3 días
        int diasSincronizados = 0;
        int diasConVentas = 0;
        
        for (int i = 0; i < 3; i++) {
          final fecha = hoy.subtract(Duration(days: i));
          final esHoy = i == 0;
          
          try {
            // 1. Consulta Local: Obtener ventas de esta fecha específica
            final auditoria = await DBHelper.obtenerAuditoriaSemanal(
              fecha,
              fecha,
            );
            
            final cantidadPedidos = auditoria['cantidad'] as int;
            final totalVentas = auditoria['total'] as double;
            
            // 2. Regla de Envío (Lógica de Negocio)
            bool debeEnviar = false;
            if (esHoy) {
              // HOY: Siempre envía (incluso si es 0) para auditoría
              debeEnviar = true;
              debugPrint('📅 HOY (${_formatearFecha(fecha)}): $cantidadPedidos pedidos, \$${totalVentas.toStringAsFixed(2)} - Enviando siempre (auditoría)');
            } else {
              // PASADO: Solo envía si hay ventas
              debeEnviar = totalVentas > 0;
              if (debeEnviar) {
                debugPrint('📅 ${_formatearFecha(fecha)}: $cantidadPedidos pedidos, \$${totalVentas.toStringAsFixed(2)} - Enviando (hay ventas)');
              } else {
                debugPrint('📅 ${_formatearFecha(fecha)}: Sin ventas - Omitiendo (no llenar BD de ceros)');
              }
            }
            
            // 3. Ejecución UPSERT si debe enviar
            if (debeEnviar) {
              await _enviarReporteSemanal(
                fechaCorte: fecha,
                cantidadPedidos: cantidadPedidos,
                totalVentas: totalVentas,
              );
              diasSincronizados++;
              if (totalVentas > 0) {
                diasConVentas++;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error al sincronizar fecha ${_formatearFecha(fecha)}: $e');
            // Continuar con el siguiente día aunque falle uno
          }
        }
        
        debugPrint('✅ Sincronización completada: $diasSincronizados días sincronizados ($diasConVentas con ventas)');
        
        // 3. Consultar estado de licencia en Supabase
        final licenciaActiva = await _verificarLicencia();
        
        // 4. Obtener deuda pendiente
        final deudaTotal = await obtenerDeudaPendiente();
        
        // 5. Si todo salió bien, guardar fecha de verificación
        if (licenciaActiva) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _keyLastCheckDate,
            ahora.toIso8601String(),
          );
          debugPrint('Licencia verificada exitosamente. Fecha guardada.');
        }
        
        return {
          'licenciaActiva': licenciaActiva,
          'deudaTotal': deudaTotal,
        };
      } catch (e) {
        debugPrint('Error al verificar licencia con Supabase: $e');
        // Si falla la conexión con Supabase, usar período de gracia
        final periodoGracia = await _verificarPeriodoGracia();
        return {
          'licenciaActiva': periodoGracia,
          'deudaTotal': 0.0, // No se puede obtener deuda sin conexión
        };
      }
    } catch (e) {
      debugPrint('Error general en verificarYReportar: $e');
      // En caso de error, usar período de gracia
      final periodoGracia = await _verificarPeriodoGracia();
      return {
        'licenciaActiva': periodoGracia,
        'deudaTotal': 0.0, // No se puede obtener deuda sin conexión
      };
    }
  }
  
  /// Formatea una fecha para logging (DD/MM/YYYY)
  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
  
  /// Envía el reporte semanal a Supabase usando UPSERT
  /// Usa la nueva estructura: solo fecha_corte (sin fecha_inicio ni url_foto_cierre)
  /// NOTA: total_comision_esperada es una columna generada en Supabase, no se envía
  /// NOTA: estado_pago no se incluye para proteger valores existentes (Opción A)
  static Future<void> _enviarReporteSemanal({
    required DateTime fechaCorte,
    required int cantidadPedidos,
    required double totalVentas,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Convertir fechaCorte a formato YYYY-MM-DD (solo fecha, sin hora)
      // Supabase acepta tanto formato de fecha como timestamp para timestamp with time zone
      // Usamos formato de fecha simple para que coincida con la constraint UNIQUE
      final fechaString = '${fechaCorte.year.toString().padLeft(4, '0')}-'
          '${fechaCorte.month.toString().padLeft(2, '0')}-'
          '${fechaCorte.day.toString().padLeft(2, '0')}';
      
      // Preparar datos para UPSERT
      // NO incluir estado_pago para proteger valores existentes (si ya está 'pagado', no se sobrescribe)
      // NO incluir total_comision_esperada - es una columna generada en Supabase
      final datos = {
        'cliente_id': clienteId,
        'fecha_corte': fechaString, // Formato YYYY-MM-DD
        'cantidad_pedidos': cantidadPedidos,
        'total_ventas': totalVentas,
      };
      
      // Usar UPSERT con onConflict para manejar duplicados
      // La constraint UNIQUE es (cliente_id, fecha_corte)
      // onConflict debe ser una cadena con los nombres de las columnas separadas por coma
      await supabase.from('reportes_semanales').upsert(
        datos,
        onConflict: 'cliente_id,fecha_corte',
      );
      
      debugPrint('✅ Reporte sincronizado con éxito (UPSERT)');
    } catch (e) {
      // 🔴 CAMBIO: Imprimir el error real y relanzarlo
      debugPrint('❌ ERROR CRÍTICO EN SUPABASE: $e');
      
      // Detectar errores de RLS (Row Level Security)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('row-level security') || 
          errorString.contains('rls') ||
          errorString.contains('42501') ||
          errorString.contains('unauthorized')) {
        debugPrint('');
        debugPrint('⚠️⚠️⚠️ ERROR DE SEGURIDAD (RLS) ⚠️⚠️⚠️');
        debugPrint('La tabla reportes_semanales tiene Row Level Security activado.');
        debugPrint('Necesitas configurar una política RLS en Supabase que permita:');
        debugPrint('  - INSERT para el cliente_id: $clienteId');
        debugPrint('  - UPDATE para el cliente_id: $clienteId');
        debugPrint('');
        debugPrint('Pasos para solucionar:');
        debugPrint('1. Ve a Supabase Dashboard > Authentication > Policies');
        debugPrint('2. Selecciona la tabla "reportes_semanales"');
        debugPrint('3. Crea una política que permita INSERT y UPDATE para tu cliente_id');
        debugPrint('   Ejemplo SQL:');
        debugPrint('   CREATE POLICY "Permitir upsert reportes" ON reportes_semanales');
        debugPrint('   FOR ALL USING (cliente_id = \'$clienteId\');');
        debugPrint('');
      }
      
      // Lanzar excepción para que el flujo superior sepa que falló
      throw Exception('Error subiendo reporte: $e');
    }
  }
  
  /// Envía un reporte de cierre de caja a Supabase
  /// Este método es público y puede ser llamado desde la UI para cerrar la caja
  /// Retorna true si el envío fue exitoso, false si hubo error
  static Future<bool> enviarCierreCaja({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      // Verificar conectividad
      final connectivityResult = await Connectivity().checkConnectivity();
      final tieneInternet = connectivityResult != ConnectivityResult.none;
      
      if (!tieneInternet) {
        throw Exception('No hay conexión a internet. Verifique su conexión e intente nuevamente.');
      }
      
      // Obtener ventas del rango desde SQLite
      final auditoria = await DBHelper.obtenerAuditoriaSemanal(
        fechaInicio,
        fechaFin,
      );
      
      final cantidadPedidos = auditoria['cantidad'] as int;
      final totalVentas = auditoria['total'] as double;
      
      debugPrint('Cierre de caja: $cantidadPedidos pedidos, \$${totalVentas.toStringAsFixed(2)}');
      
      // Enviar reporte a Supabase
      // Usar fechaFin como fecha_corte (el momento exacto del cierre)
      final fechaCorte = DateTime.now(); // Fecha y hora exacta del cierre
      await _enviarReporteSemanal(
        fechaCorte: fechaCorte,
        cantidadPedidos: cantidadPedidos,
        totalVentas: totalVentas,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al enviar cierre de caja: $e');
      rethrow; // Relanzar para que el UI pueda mostrar el error
    }
  }
  
  /// Obtiene información completa de la licencia desde Supabase
  /// Retorna un Map con: estado, porcentaje_comision, fecha_ultimo_pago, valor_a_pagar, estado_pago_hoy
  /// Retorna null si hay error o no se encuentra la licencia
  static Future<Map<String, dynamic>?> obtenerInformacionLicencia() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Consultar licencia del cliente
      final response = await supabase
          .from('licencias')
          .select()
          .eq('cliente_id', clienteId)
          .single();
      
      // Obtener el total de comisión acumulada desde reportes_semanales
      double valorAPagar = 0.0;
      String? estadoPagoHoy;
      
      try {
        // Obtener todos los reportes para calcular valor a pagar
        final reportes = await supabase
            .from('reportes_semanales')
            .select('total_comision_esperada, fecha_corte, estado_pago')
            .eq('cliente_id', clienteId);
        
        if (reportes != null && reportes is List) {
          // Obtener fecha de hoy en formato YYYY-MM-DD
          final hoy = DateTime.now();
          final fechaHoyString = '${hoy.year.toString().padLeft(4, '0')}-'
              '${hoy.month.toString().padLeft(2, '0')}-'
              '${hoy.day.toString().padLeft(2, '0')}';
          
          for (var reporte in reportes) {
            final comision = (reporte['total_comision_esperada'] as num?)?.toDouble() ?? 0.0;
            valorAPagar += comision;
            
            // Verificar si este reporte es de hoy para obtener estado_pago
            final fechaCorte = reporte['fecha_corte'] as String?;
            if (fechaCorte != null && fechaCorte.startsWith(fechaHoyString)) {
              estadoPagoHoy = reporte['estado_pago'] as String?;
            }
          }
        }
      } catch (e) {
        debugPrint('Error al obtener valor a pagar: $e');
        // Continuar con valor 0.0 si hay error
      }
      
      return {
        'estado': response['estado'] as String? ?? 'desconocido',
        'porcentaje_comision': (response['porcentaje_comision'] as num?)?.toDouble() ?? 0.0,
        'fecha_ultimo_pago': response['fecha_ultimo_pago'] as String?,
        'cliente_id': response['cliente_id'] as String? ?? clienteId,
        'valor_a_pagar': valorAPagar,
        'estado_pago_hoy': estadoPagoHoy, // 'pendiente', 'pagado', o null si no existe registro
      };
    } catch (e) {
      debugPrint('Error al obtener información de licencia: $e');
      return null;
    }
  }

  /// Verifica el estado de la licencia en Supabase
  /// Retorna true si está activa, false si está bloqueada
  static Future<bool> _verificarLicencia() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Consultar licencia del cliente
      final response = await supabase
          .from('licencias')
          .select()
          .eq('cliente_id', clienteId)
          .single();
      
      final estado = response['estado'] as String?;
      
      if (estado == null) {
        debugPrint('Licencia no encontrada en Supabase');
        return false;
      }
      
      if (estado == 'bloqueado') {
        debugPrint('Licencia bloqueada');
        return false;
      }
      
      if (estado == 'activo') {
        debugPrint('Licencia activa');
        return true;
      }
      
      // Estado desconocido, tratar como bloqueado por seguridad
      debugPrint('Estado de licencia desconocido: $estado');
      return false;
    } catch (e) {
      debugPrint('Error al verificar licencia: $e');
      // En caso de error, bloquear por seguridad
      return false;
    }
  }
  
  /// Verifica el período de gracia (3 días sin conexión)
  /// Retorna true si aún está dentro del período, false si se excedió
  static Future<bool> _verificarPeriodoGracia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckDateString = prefs.getString(_keyLastCheckDate);
      
      if (lastCheckDateString == null) {
        debugPrint('No hay fecha de última verificación. Bloqueando acceso.');
        return false;
      }
      
      final lastCheckDate = DateTime.parse(lastCheckDateString);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(lastCheckDate);
      
      if (diferencia.inDays > diasGracia) {
        debugPrint(
          'Período de gracia excedido. Última verificación: ${diferencia.inDays} días atrás',
        );
        return false;
      }
      
      final diasRestantes = diasGracia - diferencia.inDays;
      debugPrint(
        'Dentro del período de gracia. Días restantes: $diasRestantes',
      );
      return true;
    } catch (e) {
      debugPrint('Error al verificar período de gracia: $e');
      // En caso de error, bloquear por seguridad
      return false;
    }
  }
}

