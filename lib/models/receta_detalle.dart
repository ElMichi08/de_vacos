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
    final productoId = map['producto_id'];
    final insumoId = map['insumo_id'];
    final cantidad = map['cantidad'];

    if (productoId == null) {
      throw FormatException(
        'producto_id is null in RecetaDetalle.fromMap',
        map,
      );
    }
    if (insumoId == null) {
      throw FormatException('insumo_id is null in RecetaDetalle.fromMap', map);
    }
    if (cantidad == null) {
      throw FormatException('cantidad is null in RecetaDetalle.fromMap', map);
    }

    int? productoIdInt =
        productoId is int ? productoId : int.tryParse(productoId.toString());
    int? insumoIdInt =
        insumoId is int ? insumoId : int.tryParse(insumoId.toString());
    double? cantidadDouble =
        cantidad is num
            ? cantidad.toDouble()
            : double.tryParse(cantidad.toString());

    if (productoIdInt == null) {
      throw FormatException(
        'producto_id cannot be parsed as int: $productoId',
        map,
      );
    }
    if (insumoIdInt == null) {
      throw FormatException(
        'insumo_id cannot be parsed as int: $insumoId',
        map,
      );
    }
    if (cantidadDouble == null) {
      throw FormatException(
        'cantidad cannot be parsed as double: $cantidad',
        map,
      );
    }

    return RecetaDetalle(
      productoId: productoIdInt,
      insumoId: insumoIdInt,
      cantidad: cantidadDouble,
    );
  }
}
