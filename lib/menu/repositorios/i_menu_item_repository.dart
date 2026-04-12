import '../dominio/definicion/menu_item_definicion.dart';

abstract class IMenuItemRepository {
  Future<List<MenuItemDefinicion>> findAll();
  Future<MenuItemDefinicion?> findById(int id);
  Future<MenuItemDefinicion> save(MenuItemDefinicion item);
  Future<void> update(MenuItemDefinicion item);
  Future<void> delete(int id);
}
