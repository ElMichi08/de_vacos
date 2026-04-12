import '../core/database/db_helper.dart';
import '../models/modalidad.dart';
import 'i_modalidad_repository.dart';

class ModalidadRepository implements IModalidadRepository {
  @override
  Future<List<Modalidad>> obtenerTodas() async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'modalidades',
      where: 'cancelado = 0',
      orderBy: 'nombre ASC',
    );
    return rows.map(Modalidad.fromMap).toList();
  }

  @override
  Future<Modalidad?> obtenerPorId(int id) async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'modalidades',
      where: 'id = ? AND cancelado = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Modalidad.fromMap(rows.first);
  }

  @override
  Future<Modalidad> crear(Modalidad modalidad) async {
    final db = await DBHelper.db;
    final id = await db.insert('modalidades', modalidad.toMap());
    return Modalidad(
      id: id,
      nombre: modalidad.nombre,
      modificador: modalidad.modificador,
    );
  }

  @override
  Future<void> actualizar(Modalidad modalidad) async {
    if (modalidad.id == null) throw Exception('Modalidad sin id');
    final db = await DBHelper.db;
    await db.update(
      'modalidades',
      modalidad.toMap(),
      where: 'id = ?',
      whereArgs: [modalidad.id],
    );
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await DBHelper.db;
    await db.update(
      'modalidades',
      {'cancelado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
