import '../core/database/db_helper.dart';
import '../models/producto.dart';

/// Servicio para gestionar productos
/// Contiene toda la lógica de negocio relacionada con productos
class ProductoService {
  /// Obtiene todos los productos activos (no cancelados) ordenados por nombre
  static Future<List<Producto>> obtenerTodos() async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'productos',
        where: 'cancelado = 0',
        orderBy: 'nombre ASC',
      );
      return maps.map((map) => Producto.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Obtiene un producto por su ID
  static Future<Producto?> obtenerPorId(int id) async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Producto.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Guarda un nuevo producto
  static Future<int> guardar(Producto producto) async {
    return await DBHelper.insertarProducto(producto);
  }

  /// Actualiza un producto existente
  static Future<int> actualizar(Producto producto) async {
    if (producto.id == null) {
      throw Exception('El producto debe tener un ID para actualizar');
    }
    
    final error = producto.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    
    try {
      final db = await DBHelper.db;
      return await db.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Desactiva un producto (soft delete)
  /// El producto se marca como cancelado pero no se elimina de la base de datos
  /// Esto garantiza que el ID no se reutilice
  static Future<int> desactivar(int id) async {
    try {
      final db = await DBHelper.db;
      return await db.update(
        'productos',
        {'cancelado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al desactivar producto: $e');
    }
  }

  /// Elimina permanentemente un producto por su ID
  /// ADVERTENCIA: Esta acción no se puede deshacer y el ID se perderá
  static Future<int> eliminar(int id) async {
    try {
      final db = await DBHelper.db;
      return await db.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}

