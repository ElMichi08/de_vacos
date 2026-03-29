class StockInsuficienteException implements Exception {
  final String insumo;
  final double requerido;
  final double disponible;

  StockInsuficienteException({
    required this.insumo,
    required this.requerido,
    required this.disponible,
  });

  String get mensaje =>
      'Stock insuficiente para $insumo: requerido $requerido, disponible $disponible';

  @override
  String toString() => mensaje;
}
