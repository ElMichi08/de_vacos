import '../dominio/componentes/i_plato_fuerte.dart';
import '../dominio/componentes/i_proteina.dart';
import '../dominio/componentes/i_acompanante.dart';
import '../dominio/componentes/i_extra.dart';
import '../dominio/definicion/tier_definicion.dart';

/// Implementación concreta de IPlatoFuerte producida por PlatoBuilder.
/// Calcula el precio sumando: tier + acompañantes con costo + extras.
class PlatoConstruido extends IPlatoFuerte {
  @override
  final TierDefinicion tier;
  @override
  final List<IProteina> proteinas;
  @override
  final List<IAcompanante> acompanantes;
  @override
  final List<IExtra> extras;

  PlatoConstruido({
    required this.tier,
    required this.proteinas,
    required this.acompanantes,
    required this.extras,
  });

  @override
  String getNombre() {
    final partes = [
      tier.nombre,
      if (proteinas.isNotEmpty)
        proteinas.map((p) => p.getNombre()).join(' + '),
    ];
    return partes.join(' — ');
  }

  @override
  double getPrecioBase() => tier.precio;

  @override
  double getPrecio() {
    final precioAcompanantes =
        acompanantes.fold(0.0, (sum, a) => sum + a.getPrecio());
    final precioExtras = extras.fold(0.0, (sum, e) => sum + e.getPrecio());
    return tier.precio + precioAcompanantes + precioExtras;
  }
}
