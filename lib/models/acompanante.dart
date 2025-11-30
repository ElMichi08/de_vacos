/// Modelo para representar un acompañante opcional de un producto
/// Ejemplo: Papas fritas, Papas cocinadas, Mixtas (mitad/mitad)
class Acompanante {
  final String nombre; // "Papas fritas", "Papas cocinadas", "Mixtas"
  final double precioAdicional; // Precio extra (0 si no tiene costo adicional)
  final bool esPredeterminado; // Si es true, se selecciona por defecto

  Acompanante({
    required this.nombre,
    this.precioAdicional = 0.0,
    this.esPredeterminado = false,
  });

  /// Convierte el objeto a un Map para serialización JSON
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precioAdicional': precioAdicional,
      'esPredeterminado': esPredeterminado ? 1 : 0,
    };
  }

  /// Crea una instancia desde un Map (deserialización JSON)
  factory Acompanante.fromMap(Map<String, dynamic> map) {
    return Acompanante(
      nombre: map['nombre'] as String,
      precioAdicional: map['precioAdicional'] is int
          ? (map['precioAdicional'] as int).toDouble()
          : map['precioAdicional'] as double? ?? 0.0,
      esPredeterminado: (map['esPredeterminado'] ?? 0) == 1,
    );
  }

  /// Valida que los datos sean correctos
  String? validar() {
    if (nombre.trim().isEmpty) {
      return 'El nombre del acompañante es obligatorio';
    }
    if (precioAdicional.isNaN || precioAdicional < 0) {
      return 'El precio adicional debe ser un número positivo o cero';
    }
    return null;
  }

  /// Crea una copia con valores modificados
  Acompanante copyWith({
    String? nombre,
    double? precioAdicional,
    bool? esPredeterminado,
  }) {
    return Acompanante(
      nombre: nombre ?? this.nombre,
      precioAdicional: precioAdicional ?? this.precioAdicional,
      esPredeterminado: esPredeterminado ?? this.esPredeterminado,
    );
  }
}

