import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/menu/dominio/definicion/menu_item_definicion.dart';
import 'package:de_vacos/services/insumo_service.dart';
import 'package:de_vacos/services/receta_service.dart';

/// Verifica disponibilidad de stock para UI (sin modificar inventario).
class StockChecker {
  /// Retorna false si alguna proteína del ítem no tiene stock suficiente
  /// para al menos 1 porción. Si el ítem no tiene proteínas, retorna true.
  static Future<bool> menuItemDisponible(MenuItemDefinicion def) async {
    if (def.proteinaIds.isEmpty) return true;
    for (final id in def.proteinaIds) {
      final insumo = await di.insumoMenuRepository.findById(id);
      if (insumo != null && insumo.tieneSuficientes(1)) return true;
    }
    return false;
  }

  /// Retorna false si algún insumo de la receta del producto no tiene
  /// cantidadActual suficiente. Retorna true si no hay receta.
  static Future<bool> productoDisponible(int productoId) async {
    final recetas = await RecetaService.obtenerPorProducto(productoId);
    if (recetas.isEmpty) return true;
    for (final receta in recetas) {
      final insumo = await InsumoService.obtenerPorId(receta.insumoId);
      if (insumo == null) continue;
      if (insumo.cantidadActual < receta.cantidad) return false;
    }
    return true;
  }
}
