/// Una línea de receta: insumo + cantidad por producto
class RecetaDetalle {
  final int productoId;
  final int insumoId;
  final double cantidad;

  RecetaDetalle({
    required this.productoId,
    required this.insumoId,
    required this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'producto_id': productoId,
      'insumo_id': insumoId,
      'cantidad': cantidad,
    };
  }

  factory RecetaDetalle.fromMap(Map<String, dynamic> map) {
    return RecetaDetalle(
      productoId: map['producto_id'] as int,
      insumoId: map['insumo_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
    );
  }
}
