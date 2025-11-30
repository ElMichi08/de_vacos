/// Modelo para representar una variante de tamaño/precio de un producto
/// Ejemplo: Asado - 1 corte ($4.50), 2 cortes ($6.50), 3 cortes ($8.50)
class ProductoVariante {
  final String nombre; // "1 corte", "2 cortes", "3 cortes"
  final double precio;
  final String? descripcion; // Opcional: información adicional (ej: "Información solo para cocina")

  ProductoVariante({
    required this.nombre,
    required this.precio,
    this.descripcion,
  });

  /// Convierte el objeto a un Map para serialización JSON
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precio': precio,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  /// Crea una instancia desde un Map (deserialización JSON)
  factory ProductoVariante.fromMap(Map<String, dynamic> map) {
    return ProductoVariante(
      nombre: map['nombre'] as String,
      precio: map['precio'] is int 
          ? (map['precio'] as int).toDouble() 
          : map['precio'] as double,
      descripcion: map['descripcion'] as String?,
    );
  }

  /// Valida que los datos sean correctos
  String? validar() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la variante es obligatorio';
    }
    if (precio.isNaN || precio <= 0) {
      return 'El precio debe ser un número positivo';
    }
    return null;
  }

  /// Crea una copia con valores modificados
  ProductoVariante copyWith({
    String? nombre,
    double? precio,
    String? descripcion,
  }) {
    return ProductoVariante(
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}

