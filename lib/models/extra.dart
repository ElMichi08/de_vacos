/// Modelo para representar un extra opcional de un producto
/// Los extras son elementos adicionales que se pueden agregar al pedido
/// Ejemplo: Gaseosa grande, Porción de papas extra, Queso extra, etc.
/// A diferencia de los acompañantes (que son opciones excluyentes),
/// los extras son aditivos (puedes agregar múltiples)
class Extra {
  final String nombre; // "Gaseosa grande", "Porción de papas extra", "Queso extra"
  final double precioAdicional; // Precio extra (puede ser 0 si es gratis)
  final bool esObligatorio; // Si es true, se debe seleccionar al menos uno (raro, pero por si acaso)

  Extra({
    required this.nombre,
    required this.precioAdicional,
    this.esObligatorio = false,
  });

  /// Convierte el objeto a un Map para serialización JSON
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precioAdicional': precioAdicional,
      'esObligatorio': esObligatorio ? 1 : 0,
    };
  }

  /// Crea una instancia desde un Map (deserialización JSON)
  factory Extra.fromMap(Map<String, dynamic> map) {
    return Extra(
      nombre: map['nombre'] as String,
      precioAdicional: map['precioAdicional'] is int
          ? (map['precioAdicional'] as int).toDouble()
          : map['precioAdicional'] as double? ?? 0.0,
      esObligatorio: (map['esObligatorio'] ?? 0) == 1,
    );
  }

  /// Valida que los datos sean correctos
  String? validar() {
    if (nombre.trim().isEmpty) {
      return 'El nombre del extra es obligatorio';
    }
    if (precioAdicional.isNaN || precioAdicional < 0) {
      return 'El precio adicional debe ser un número positivo o cero';
    }
    return null;
  }

  /// Crea una copia con valores modificados
  Extra copyWith({
    String? nombre,
    double? precioAdicional,
    bool? esObligatorio,
  }) {
    return Extra(
      nombre: nombre ?? this.nombre,
      precioAdicional: precioAdicional ?? this.precioAdicional,
      esObligatorio: esObligatorio ?? this.esObligatorio,
    );
  }
}

