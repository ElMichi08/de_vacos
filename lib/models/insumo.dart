/// Modelo de Insumo para inventario
class Insumo {
  final int? id;
  final String nombre;
  final String unidadMedida;
  final double cantidadActual;
  final double cantidadMinima;
  final double? costoUnitario;
  final bool cancelado;

  Insumo({
    this.id,
    required this.nombre,
    required this.unidadMedida,
    this.cantidadActual = 0,
    this.cantidadMinima = 0,
    this.costoUnitario,
    this.cancelado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'unidadMedida': unidadMedida,
      'cantidadActual': cantidadActual,
      'cantidadMinima': cantidadMinima,
      'costoUnitario': costoUnitario,
      'cancelado': cancelado ? 1 : 0,
    };
  }

  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id'],
      nombre: map['nombre'] as String,
      unidadMedida: map['unidadMedida'] as String,
      cantidadActual: (map['cantidadActual'] as num?)?.toDouble() ?? 0,
      cantidadMinima: (map['cantidadMinima'] as num?)?.toDouble() ?? 0,
      costoUnitario: map['costoUnitario'] != null
          ? (map['costoUnitario'] as num).toDouble()
          : null,
      cancelado: (map['cancelado'] ?? 0) == 1,
    );
  }

  bool get bajoMinimo => cantidadActual < cantidadMinima;

  String? validar() {
    if (nombre.trim().isEmpty) return 'El nombre es obligatorio';
    if (unidadMedida.trim().isEmpty) return 'La unidad de medida es obligatoria';
    if (cantidadActual.isNegative) return 'La cantidad actual no puede ser negativa';
    if (cantidadMinima.isNegative) return 'La cantidad mínima no puede ser negativa';
    if (costoUnitario != null && costoUnitario! < 0) {
      return 'El costo unitario no puede ser negativo';
    }
    return null;
  }

  Insumo copyWith({
    int? id,
    String? nombre,
    String? unidadMedida,
    double? cantidadActual,
    double? cantidadMinima,
    double? costoUnitario,
    bool? cancelado,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      cantidadActual: cantidadActual ?? this.cantidadActual,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      cancelado: cancelado ?? this.cancelado,
    );
  }
}
