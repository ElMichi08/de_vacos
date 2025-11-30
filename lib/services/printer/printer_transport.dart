import 'discovered_printer.dart';

/// Abstracción de transporte para impresoras
/// Implementa el patrón Strategy para separar la lógica de conexión por tipo
/// Permite agregar nuevos tipos de conexión sin modificar PrinterService
abstract class PrinterTransport {
  /// Conecta a una impresora usando este transporte
  /// [printer] debe tener el tipo correcto para este transporte
  Future<void> connect(DiscoveredPrinter printer);

  /// Desconecta la impresora actual
  Future<void> disconnect();

  /// Envía bytes ESC/POS a la impresora conectada
  Future<void> printBytes(List<int> bytes);

  /// Verifica si hay una impresora conectada
  bool get isConnected;

  /// Obtiene la impresora actualmente conectada (si existe)
  DiscoveredPrinter? get connectedPrinter;

  /// Escanea impresoras disponibles usando este transporte
  /// Retorna una lista de impresoras encontradas
  Future<List<DiscoveredPrinter>> scanPrinters();
}

