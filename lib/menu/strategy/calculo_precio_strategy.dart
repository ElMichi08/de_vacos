import '../dominio/componentes/i_plato_fuerte.dart';

/// Contrato para el cálculo de precio según contexto.
/// PedidoMenuService recibe la estrategia activa por inyección de dependencia.
abstract class CalculoPrecioStrategy {
  /// Calcula el precio final del plato según el contexto activo.
  double calcular(IPlatoFuerte plato);
}
