import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/repositories/i_insumo_repository.dart';

class InsumoRepository implements IInsumoRepository {
  @override
  Future<Insumo> crearInsumo(Insumo insumo) async {
    final db = await DBHelper.db;
    final id = await db.insert('insumos', insumo.toMap());
    return insumo.copyWith(id: id, cancelado: false);
  }

  @override
  Future<List<Insumo>> obtenerPorTipo(InsumoTipo tipo) async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'insumos',
      where: 'cancelado = 0 AND tipo = ?',
      whereArgs: [tipo.valor],
      orderBy: 'nombre ASC',
    );
    return maps.map(Insumo.fromMap).toList();
  }

  @override
  Future<Insumo?> obtenerInsumoPorId(int id) async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'insumos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Insumo.fromMap(maps.first);
  }

  @override
  Future<List<Insumo>> obtenerTodosLosInsumos() async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'insumos',
      where: 'cancelado = 0',
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Insumo.fromMap(m)).toList();
  }

  @override
  Future<void> actualizarInsumo(Insumo insumo) async {
    if (insumo.id == null) {
      throw Exception('El insumo debe tener id para actualizar');
    }
    final db = await DBHelper.db;
    await db.update(
      'insumos',
      insumo.toMap(),
      where: 'id = ?',
      whereArgs: [insumo.id],
    );
  }

  @override
  Future<void> eliminarInsumo(int id) async {
    final db = await DBHelper.db;
    await db.update(
      'insumos',
      {'cancelado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
