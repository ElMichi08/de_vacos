import 'package:de_vacos/models/modalidad.dart';
import '../dominio/componentes/i_plato_fuerte.dart';
import 'calculo_precio_strategy.dart';

/// Precio con modificador de modalidad (ej: Feria +$2, Delivery +$1.5).
/// El modificador viene del catálogo global de Modalidades, no está hardcodeado.
class ModalidadStrategy extends CalculoPrecioStrategy {
  final Modalidad _modalidad;

  ModalidadStrategy(this._modalidad);

  @override
  double calcular(IPlatoFuerte plato) =>
      plato.getPrecio() + _modalidad.modificador;
}
