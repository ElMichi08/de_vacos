import '../core/database/db_helper.dart';
import '../models/receta_detalle.dart';

/// Servicio para recetas por producto (insumos y cantidades)
class RecetaService {
  /// Obtiene la receta de un producto: lista de líneas (insumo_id, cantidad)
  static Future<List<RecetaDetalle>> obtenerPorProducto(int productoId) async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'receta_detalle',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );
      return maps.map((m) => RecetaDetalle.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Error al obtener receta: $e');
    }
  }

  /// Guarda o actualiza la receta de un producto.
  /// Reemplaza todas las líneas existentes por la lista dada.
  static Future<void> guardarReceta(int productoId, List<RecetaDetalle> lineas) async {
    try {
      final db = await DBHelper.db;
      await db.delete(
        'receta_detalle',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );
      for (final linea in lineas) {
        if (linea.cantidad <= 0) continue;
        await db.insert('receta_detalle', {
          'producto_id': productoId,
          'insumo_id': linea.insumoId,
          'cantidad': linea.cantidad,
        });
      }
    } catch (e) {
      throw Exception('Error al guardar receta: $e');
    }
  }
}
