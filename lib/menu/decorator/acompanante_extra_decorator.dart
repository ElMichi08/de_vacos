import '../dominio/componentes/i_componente_menu.dart';

/// Decorator que añade un acompañante con costo extra al precio total.
/// Se aplica cuando el cliente supera el límite gratuito del tier.
/// Open/Closed: nuevos acompañantes extra se agregan como nuevos decorators.
class AcompananteExtraDecorator extends IComponenteMenu {
  final IComponenteMenu _base;
  final String _nombre;
  final double _precio;

  AcompananteExtraDecorator(
    this._base, {
    required String nombre,
    required double precio,
  })  : _nombre = nombre,
        _precio = precio;

  @override
  String getNombre() => '${_base.getNombre()} + $_nombre';

  @override
  double getPrecio() => _base.getPrecio() + _precio;
}
