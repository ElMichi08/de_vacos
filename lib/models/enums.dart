enum PaymentMethod {
  efectivo('Efectivo'),
  transferencia('Transferencia');

  final String displayName;
  const PaymentMethod(this.displayName);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => PaymentMethod.efectivo,
    );
  }

  @override
  String toString() => displayName;
}

enum OrderStatus {
  enPreparacion('En preparación'),
  despachada('Despachada'),
  cerrados('Cerrados'),
  cancelada('Cancelada');

  final String displayName;
  const OrderStatus(this.displayName);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => OrderStatus.enPreparacion,
    );
  }

  @override
  String toString() => displayName;
}

enum PaymentStatus {
  pendiente('Pendiente'),
  cobrado('Cobrado'),
  recobrar('Recobrar');

  final String displayName;
  const PaymentStatus(this.displayName);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => PaymentStatus.pendiente,
    );
  }

  @override
  String toString() => displayName;
}
