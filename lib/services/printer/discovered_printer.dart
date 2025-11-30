/// Modelo para representar una impresora descubierta
/// Encapsula la información de la impresora independientemente del plugin usado
class DiscoveredPrinter {
  final String name;
  final String address;
  final AppPrinterType type;
  final Map<String, dynamic>? extraData;

  const DiscoveredPrinter({
    required this.name,
    required this.address,
    required this.type,
    this.extraData,
  });

  @override
  String toString() => 'DiscoveredPrinter(name: $name, address: $address, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredPrinter &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          type == other.type;

  @override
  int get hashCode => Object.hash(address, type);
}

/// Tipo de impresora disponible (renombrado para evitar conflicto con PrinterType del plugin)
enum AppPrinterType {
  bluetooth,
  usb,
  wifi,
  network,
}
