import 'i_componente_menu.dart';

/// Representa una proteína/insumo elegida para el plato.
/// Siempre vinculada a un insumo real del inventario (por id).
/// Su precio dentro del tier es $0 (incluida); el costo real
/// se descuenta del stock via InsumoMenuService.
abstract class IProteina extends IComponenteMenu {
  int get insumoId;
}
