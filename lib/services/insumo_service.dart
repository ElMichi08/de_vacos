import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/models/receta_detalle.dart';
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/core/exceptions/stock_insuficiente_exception.dart';

class InsumoService {
  static Future<List<Insumo>> listar() async {
    return di.insumoRepository.obtenerTodosLosInsumos();
  }

  static Future<Insumo?> obtenerPorId(int id) async {
    return di.insumoRepository.obtenerInsumoPorId(id);
  }

  static Future<int> crear(Insumo insumo) async {
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    final creado = await di.insumoRepository.crearInsumo(insumo);
    return creado.id ?? 0;
  }

  static Future<int> actualizar(Insumo insumo) async {
    if (insumo.id == null)
      throw Exception('El insumo debe tener id para actualizar');
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    await di.insumoRepository.actualizarInsumo(insumo);
    return insumo.id ?? 0;
  }

  static Future<int> eliminar(int id) async {
    await di.insumoRepository.eliminarInsumo(id);
    return id;
  }

  /// Descuenta insumos del stock de forma atómica (transacción)
  /// Lanza StockInsuficienteException si no hay stock suficiente
  static Future<void> descontarStock({
    required List<RecetaDetalle> recetas,
    required int cantidadProducto,
  }) async {
    final db = await DBHelper.db;

    // Usar transacción para atomicidad
    await db.transaction((txn) async {
      // 1. Validar stock suficiente primero (dentro de transacción)
      for (final receta in recetas) {
        final insumo = await obtenerPorId(receta.insumoId);
        if (insumo == null) continue;

        final requerido = receta.cantidad * cantidadProducto;
        if (insumo.cantidadActual < requerido) {
          throw StockInsuficienteException(
            insumo: insumo.nombre,
            requerido: requerido,
            disponible: insumo.cantidadActual,
          );
        }
      }

      // 2. Descontar stock (si todas las validaciones pasaron)
      for (final receta in recetas) {
        final requerido = receta.cantidad * cantidadProducto;
        await txn.rawUpdate(
          'UPDATE insumos SET cantidadActual = cantidadActual - ? WHERE id = ?',
          [requerido, receta.insumoId],
        );
      }
    });
  }
}
