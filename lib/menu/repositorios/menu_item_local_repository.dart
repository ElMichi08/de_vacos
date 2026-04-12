import 'package:de_vacos/core/database/db_helper.dart';
import '../dominio/definicion/menu_item_definicion.dart';
import 'i_menu_item_repository.dart';

/// Implementación SQLite de IMenuItemRepository.
/// Lee y escribe en la tabla `menu_items`.
class MenuItemLocalRepository implements IMenuItemRepository {
  @override
  Future<List<MenuItemDefinicion>> findAll() async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'menu_items',
      where: 'cancelado = 0',
      orderBy: 'nombre ASC',
    );
    return rows.map(MenuItemDefinicion.fromMap).toList();
  }

  @override
  Future<MenuItemDefinicion?> findById(int id) async {
    final db = await DBHelper.db;
    final rows = await db.query(
      'menu_items',
      where: 'id = ? AND cancelado = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MenuItemDefinicion.fromMap(rows.first);
  }

  @override
  Future<MenuItemDefinicion> save(MenuItemDefinicion item) async {
    final db = await DBHelper.db;
    final id = await db.insert('menu_items', item.toMap());
    return item.copyWith(id: id);
  }

  @override
  Future<void> update(MenuItemDefinicion item) async {
    if (item.id == null) throw Exception('MenuItemDefinicion debe tener id para actualizar');
    final db = await DBHelper.db;
    await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await DBHelper.db;
    await db.update(
      'menu_items',
      {'cancelado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
