/// Define un tier de un ítem de menú.
/// Precio y límites se configuran desde la UI, no se hardcodean.
class TierDefinicion {
  final String nombre;
  final double precio;
  final int maxProteinas;
  final int maxAcompanantesGratis;

  const TierDefinicion({
    required this.nombre,
    required this.precio,
    required this.maxProteinas,
    required this.maxAcompanantesGratis,
  });

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'precio': precio,
        'maxProteinas': maxProteinas,
        'maxAcompanantesGratis': maxAcompanantesGratis,
      };

  factory TierDefinicion.fromMap(Map<String, dynamic> m) => TierDefinicion(
        nombre: m['nombre'] as String,
        precio: (m['precio'] as num).toDouble(),
        maxProteinas: m['maxProteinas'] as int,
        maxAcompanantesGratis: m['maxAcompanantesGratis'] as int,
      );
}
