import '../dominio/componentes/i_plato_fuerte.dart';
import 'calculo_precio_strategy.dart';

/// Precio normal: sin modificador adicional.
class PrecioNormalStrategy extends CalculoPrecioStrategy {
  @override
  double calcular(IPlatoFuerte plato) => plato.getPrecio();
}
