import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/models/modalidad.dart';
import '../dominio/definicion/menu_item_definicion.dart';
import '../dominio/definicion/tier_definicion.dart';
import '../builder/plato_builder.dart';
import '../builder/plato_construido.dart';
import '../core/result.dart';

/// Selección del usuario para armar un plato.
/// Usa objetos `Insumo` resueltos desde el repositorio, no IDs.
class SeleccionPlato {
  final String tierNombre;
  final List<Insumo> proteinas;
  final List<Insumo> acompanantes;
  final List<Insumo> extras;

  /// Modalidad de precio activa. Null = precio base sin modificador.
  final Modalidad? modalidad;

  const SeleccionPlato({
    required this.tierNombre,
    required this.proteinas,
    this.acompanantes = const [],
    this.extras = const [],
    this.modalidad,
  });
}

/// Orquesta la creación de un PlatoConstruido a partir de una
/// MenuItemDefinicion y la selección del usuario.
/// Pasa al PlatoBuilder los límites correctos según el tier.
/// NO valida stock — eso es responsabilidad de StockValidator.
class PlatoFactory {
  /// Crea el plato o retorna un error descriptivo.
  static Result<PlatoConstruido, String> crear(
    MenuItemDefinicion definicion,
    SeleccionPlato seleccion,
  ) {
    final TierDefinicion? tier = _buscarTier(definicion, seleccion.tierNombre);
    if (tier == null) {
      return Result.err(
        'El tier "${seleccion.tierNombre}" no existe en "${definicion.nombre}"',
      );
    }

    final builder = PlatoBuilder(tier);

    for (final proteina in seleccion.proteinas) {
      final resultado = builder.agregarProteina(proteina);
      if (resultado.isErr) return Result.err(resultado.error);
    }

    for (final acompanante in seleccion.acompanantes) {
      builder.agregarAcompanante(acompanante);
    }

    for (final extra in seleccion.extras) {
      builder.agregarExtra(extra);
    }

    return builder.build();
  }

  static TierDefinicion? _buscarTier(
    MenuItemDefinicion definicion,
    String nombre,
  ) {
    try {
      return definicion.tiers
          .firstWhere((t) => t.nombre.toLowerCase() == nombre.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
