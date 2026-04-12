import 'i_componente_menu.dart';
import 'i_proteina.dart';
import 'i_acompanante.dart';
import 'i_extra.dart';
import '../definicion/tier_definicion.dart';

/// Plato principal construido. Agrega precio base del tier
/// más los componentes con precio (acompañantes extra, extras).
abstract class IPlatoFuerte extends IComponenteMenu {
  TierDefinicion get tier;
  List<IProteina> get proteinas;
  List<IAcompanante> get acompanantes;
  List<IExtra> get extras;

  /// Precio base del tier sin contexto aplicado.
  double getPrecioBase();
}
