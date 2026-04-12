import 'dart:convert';
import 'tier_definicion.dart';

/// Definición completa de un ítem de menú.
/// Se persiste en la tabla `menu_items` y se edita desde la UI.
/// Ningún precio está hardcodeado: todo viene de esta definición.
/// Los insumos y modalidades se referencian por ID; los datos vivos
/// se resuelven en runtime desde sus repositorios.
class MenuItemDefinicion {
  final int? id;
  final String nombre;
  final List<TierDefinicion> tiers;

  /// IDs de insumos con tipo=proteina disponibles en este ítem.
  final List<int> proteinaIds;

  /// IDs de insumos con tipo=acompanante disponibles en este ítem.
  final List<int> acompananteIds;

  /// IDs de insumos que pueden agregarse como extra (con precio).
  final List<int> extraIds;

  /// IDs de modalidades de precio aplicables a este ítem.
  final List<int> modalidadIds;

  final bool cancelado;

  const MenuItemDefinicion({
    this.id,
    required this.nombre,
    required this.tiers,
    this.proteinaIds = const [],
    this.acompananteIds = const [],
    this.extraIds = const [],
    this.modalidadIds = const [],
    this.cancelado = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'tiers': jsonEncode(tiers.map((t) => t.toMap()).toList()),
        'proteinas': jsonEncode(proteinaIds),
        'acompanantes': jsonEncode(acompananteIds),
        'extras': jsonEncode(extraIds),
        'modificadores': jsonEncode(modalidadIds),
        'cancelado': cancelado ? 1 : 0,
      };

  factory MenuItemDefinicion.fromMap(Map<String, dynamic> m) {
    // Soporta tanto el formato nuevo (lista de IDs: [1,2,3])
    // como el formato viejo (lista de objetos: [{id:1,...}]).
    List<int> decodeIds(String key) {
      final raw = jsonDecode(m[key] as String? ?? '[]');
      if (raw is! List) return [];
      return raw.map<int?>((e) {
        if (e is int) return e;
        if (e is Map) return (e['id'] as num?)?.toInt();
        return null;
      }).whereType<int>().toList();
    }

    return MenuItemDefinicion(
      id: m['id'] as int?,
      nombre: m['nombre'] as String,
      tiers: (jsonDecode(m['tiers'] as String? ?? '[]') as List)
          .map((t) => TierDefinicion.fromMap(t as Map<String, dynamic>))
          .toList(),
      proteinaIds: decodeIds('proteinas'),
      acompananteIds: decodeIds('acompanantes'),
      extraIds: decodeIds('extras'),
      modalidadIds: decodeIds('modificadores'),
      cancelado: (m['cancelado'] as int? ?? 0) == 1,
    );
  }

  MenuItemDefinicion copyWith({
    int? id,
    String? nombre,
    List<TierDefinicion>? tiers,
    List<int>? proteinaIds,
    List<int>? acompananteIds,
    List<int>? extraIds,
    List<int>? modalidadIds,
    bool? cancelado,
  }) =>
      MenuItemDefinicion(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        tiers: tiers ?? this.tiers,
        proteinaIds: proteinaIds ?? this.proteinaIds,
        acompananteIds: acompananteIds ?? this.acompananteIds,
        extraIds: extraIds ?? this.extraIds,
        modalidadIds: modalidadIds ?? this.modalidadIds,
        cancelado: cancelado ?? this.cancelado,
      );
}
