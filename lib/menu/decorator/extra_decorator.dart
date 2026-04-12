import '../dominio/componentes/i_componente_menu.dart';

/// Decorator para extras opcionales (Bebida, Para llevar, etc.).
/// Suma nombre y precio al componente base.
/// Open/Closed: nuevos extras = nuevos decorators, sin modificar clases existentes.
class ExtraDecorator extends IComponenteMenu {
  final IComponenteMenu _base;
  final String _nombre;
  final double _precio;

  ExtraDecorator(
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
