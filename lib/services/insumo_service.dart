import '../core/database/db_helper.dart';
import '../models/insumo.dart';

/// Servicio CRUD para insumos (inventario)
class InsumoService {
  /// Lista todos los insumos activos (no cancelados), ordenados por nombre
  static Future<List<Insumo>> listar() async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'insumos',
        where: 'cancelado = 0',
        orderBy: 'nombre ASC',
      );
      return maps.map((m) => Insumo.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Error al listar insumos: $e');
    }
  }

  /// Obtiene un insumo por ID
  static Future<Insumo?> obtenerPorId(int id) async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'insumos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Insumo.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error al obtener insumo: $e');
    }
  }

  /// Crea un nuevo insumo
  static Future<int> crear(Insumo insumo) async {
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    try {
      final db = await DBHelper.db;
      return await db.insert('insumos', insumo.toMap());
    } catch (e) {
      throw Exception('Error al crear insumo: $e');
    }
  }

  /// Actualiza un insumo existente
  static Future<int> actualizar(Insumo insumo) async {
    if (insumo.id == null) throw Exception('El insumo debe tener id para actualizar');
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    try {
      final db = await DBHelper.db;
      return await db.update(
        'insumos',
        insumo.toMap(),
        where: 'id = ?',
        whereArgs: [insumo.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar insumo: $e');
    }
  }

  /// Soft delete: marca el insumo como cancelado
  static Future<int> eliminar(int id) async {
    try {
      final db = await DBHelper.db;
      return await db.update(
        'insumos',
        {'cancelado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar insumo: $e');
    }
  }
}
