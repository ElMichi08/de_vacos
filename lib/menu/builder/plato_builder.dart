import 'package:de_vacos/models/insumo.dart';
import '../core/result.dart';
import '../dominio/componentes/i_proteina.dart';
import '../dominio/componentes/i_acompanante.dart';
import '../dominio/componentes/i_extra.dart';
import '../dominio/definicion/tier_definicion.dart';
import 'plato_construido.dart';

/// Implementaciones internas — no se exponen fuera del builder.
class _ProteinaImpl extends IProteina {
  final Insumo _insumo;
  _ProteinaImpl(this._insumo);

  @override
  int get insumoId => _insumo.id!;

  @override
  String getNombre() => _insumo.nombre;

  @override
  double getPrecio() => 0.0; // siempre incluida en el tier
}

class _AcompananteImpl extends IAcompanante {
  final Insumo _insumo;
  @override
  final bool esGratis;

  _AcompananteImpl(this._insumo, {required this.esGratis});

  @override
  String getNombre() => _insumo.nombre;

  @override
  double getPrecio() => esGratis ? 0.0 : _insumo.precioExtra;
}

class _ExtraImpl extends IExtra {
  final Insumo _insumo;
  _ExtraImpl(this._insumo);

  @override
  String getNombre() => _insumo.nombre;

  @override
  double getPrecio() => _insumo.precioExtra;
}

/// Construye un PlatoConstruido paso a paso.
/// Responsabilidad única: validar límites de tier y ensamblar el objeto.
/// NO accede a stock ni a la base de datos.
class PlatoBuilder {
  final TierDefinicion _tier;
  final List<_ProteinaImpl> _proteinas = [];
  final List<_AcompananteImpl> _acompanantes = [];
  final List<_ExtraImpl> _extras = [];

  PlatoBuilder(this._tier);

  /// Agrega una proteína. Valida que no supere [tier.maxProteinas].
  Result<PlatoBuilder, String> agregarProteina(Insumo insumo) {
    if (_proteinas.length >= _tier.maxProteinas) {
      return Result.err(
        'El tier "${_tier.nombre}" permite máximo ${_tier.maxProteinas} proteína(s)',
      );
    }
    _proteinas.add(_ProteinaImpl(insumo));
    return Result.ok(this);
  }

  /// Agrega un acompañante. Los primeros [tier.maxAcompanantesGratis]
  /// son gratis; los siguientes aplican [insumo.precioExtra].
  PlatoBuilder agregarAcompanante(Insumo insumo) {
    final esGratis = _acompanantes.length < _tier.maxAcompanantesGratis;
    _acompanantes.add(_AcompananteImpl(insumo, esGratis: esGratis));
    return this;
  }

  /// Agrega un extra opcional con [insumo.precioExtra].
  PlatoBuilder agregarExtra(Insumo insumo) {
    _extras.add(_ExtraImpl(insumo));
    return this;
  }

  /// Construye el plato. Valida que se haya elegido al menos una proteína
  /// si el tier requiere alguna.
  Result<PlatoConstruido, String> build() {
    if (_tier.maxProteinas > 0 && _proteinas.isEmpty) {
      return Result.err('Debes elegir al menos una proteína');
    }
    return Result.ok(
      PlatoConstruido(
        tier: _tier,
        proteinas: List.unmodifiable(_proteinas),
        acompanantes: List.unmodifiable(_acompanantes),
        extras: List.unmodifiable(_extras),
      ),
    );
  }
}
