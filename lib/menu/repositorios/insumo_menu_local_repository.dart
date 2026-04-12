import 'package:de_vacos/core/database/db_helper.dart';
import '../dominio/insumo/insumo_menu.dart';
import '../dominio/insumo/i_insumo_menu_repository.dart';

/// Implementación SQLite de IInsumoMenuRepository.
/// Reutiliza la tabla `insumos` existente.
/// Solo lee nombre y cantidadActual (porciones disponibles).
class InsumoMenuLocalRepository implements IInsumoMenuRepository {
  @override
  Future<InsumoMenu?> findById(int id) async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'insumos',
      columns: ['id', 'nombre', 'cantidadActual'],
      where: 'id = ? AND cancelado = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<InsumoMenu>> findAll() async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'insumos',
      columns: ['id', 'nombre', 'cantidadActual'],
      where: 'cancelado = 0',
      orderBy: 'nombre ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> save(InsumoMenu insumo) async {
    final db = await DBHelper.db;
    await db.update(
      'insumos',
      {'cantidadActual': insumo.porcionesDisponibles},
      where: 'id = ?',
      whereArgs: [insumo.id],
    );
  }

  InsumoMenu _fromRow(Map<String, dynamic> row) => InsumoMenu(
        id: row['id'] as int,
        nombre: row['nombre'] as String,
        porcionesDisponibles: (row['cantidadActual'] as num).toDouble(),
      );
}
