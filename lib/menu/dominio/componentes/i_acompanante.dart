import 'i_componente_menu.dart';

/// Guarnición del plato.
/// - Si está dentro del límite gratuito del tier → getPrecio() retorna 0.0
/// - Si supera el límite → getPrecio() retorna precioExtra definido en config.
abstract class IAcompanante extends IComponenteMenu {
  bool get esGratis;
}
