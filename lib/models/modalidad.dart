/// Modalidad de precio — contexto configurable que modifica el precio base.
/// Ejemplos: Normal (+$0), Feria (+$2), Delivery (+$1.5).
/// Se crean desde InsumosScreen y se seleccionan al armar un ítem de menú.
class Modalidad {
  final int? id;
  final String nombre;
  final double modificador;
  final bool cancelado;

  const Modalidad({
    this.id,
    required this.nombre,
    required this.modificador,
    this.cancelado = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'modificador': modificador,
        'cancelado': cancelado ? 1 : 0,
      };

  factory Modalidad.fromMap(Map<String, dynamic> m) => Modalidad(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        modificador: (m['modificador'] as num).toDouble(),
        cancelado: (m['cancelado'] as int? ?? 0) == 1,
      );

  Modalidad copyWith({String? nombre, double? modificador, bool? cancelado}) =>
      Modalidad(
        id: id,
        nombre: nombre ?? this.nombre,
        modificador: modificador ?? this.modificador,
        cancelado: cancelado ?? this.cancelado,
      );
}
