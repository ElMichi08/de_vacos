import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../printer_transport.dart';
import '../discovered_printer.dart';
import '../printer_exceptions.dart';

/// Implementación de transporte para impresoras Bluetooth
/// Usa el plugin flutter_pos_printer_platform_image_3 para comunicación Bluetooth
class BluetoothPrinterTransport implements PrinterTransport {
  final PrinterManager _printerManager;
  DiscoveredPrinter? _connectedPrinter;

  BluetoothPrinterTransport(this._printerManager);

  @override
  Future<void> connect(DiscoveredPrinter printer) async {
    if (printer.type != AppPrinterType.bluetooth) {
      throw const PrinterConnectionException(
        'El tipo de impresora no es Bluetooth',
      );
    }

    if (!_isPlatformSupported()) {
      throw const PrinterPlatformNotSupportedException(
        'Bluetooth solo disponible en Android/iOS',
      );
    }

    try {
      // Obtener el dispositivo original del extraData
      final device = printer.extraData?['device'] as PrinterDevice?;
      if (device == null) {
        throw const PrinterConnectionException(
          'Información del dispositivo no disponible',
        );
      }

      // Crear BluetoothPrinterInput a partir de los datos del dispositivo
      // IMPORTANTE: isBle: false para Bluetooth clásico, autoConnect: true
      final bluetoothInput = BluetoothPrinterInput(
        address: device.address ?? '',
        name: device.name,
        isBle: false, // Bluetooth clásico para JP80H
        autoConnect: true,
      );

      // Conectar usando el método connect del plugin
      final result = await _printerManager.connect(
        type: PrinterType.bluetooth,
        model: bluetoothInput,
      );

      if (result == true) {
        _connectedPrinter = printer;
      } else {
        throw const PrinterConnectionException(
          'No se pudo establecer la conexión',
        );
      }
    } catch (e) {
      if (e is PrinterException) {
        rethrow;
      }
      debugPrint('Error al conectar impresora Bluetooth: $e');
      throw PrinterConnectionException('Error al conectar: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedPrinter == null) {
      return;
    }

    try {
      await _printerManager.disconnect(type: PrinterType.bluetooth);
      _connectedPrinter = null;
    } catch (e) {
      debugPrint('Error al desconectar impresora Bluetooth: $e');
      // Ignorar errores al desconectar, pero limpiar el estado
      _connectedPrinter = null;
    }
  }

  @override
  Future<void> printBytes(List<int> bytes) async {
    if (!isConnected) {
      throw const PrinterConnectionException('No hay impresora conectada');
    }

    // Validar que bytes no esté vacío
    if (bytes.isEmpty) {
      throw const PrinterSendException(
        'No se puede enviar una lista de bytes vacía',
      );
    }

    // Validar que todos los bytes sean valores válidos (0-255)
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw const PrinterSendException(
          'El formato de los datos no es válido para la impresora ESC/POS. Los bytes deben estar entre 0 y 255.',
        );
      }
    }

    try {
      debugPrint(
        'Enviando ${bytes.length} bytes ESC/POS a la impresora Bluetooth',
      );

      // Enviar los datos usando el método send del plugin
      // El plugin espera List<int>, no Uint8List (esto causa ClassCastException en Android)
      final result = await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: bytes, // Enviar List<int> directamente
      );

      if (result != true) {
        // La impresora rechazó los datos - probablemente formato inválido
        throw const PrinterSendException(
          'El formato de los datos no es válido para la impresora ESC/POS. Verifica que los bytes se generen correctamente con esc_pos_utils_plus.',
        );
      }

      debugPrint('Bytes enviados correctamente a la impresora Bluetooth');
    } catch (e) {
      if (e is PrinterException) {
        rethrow;
      }

      // Verificar si la impresora se desconectó
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('disconnect') ||
          errorStr.contains('connection') ||
          errorStr.contains('not connected')) {
        _connectedPrinter = null;
        throw const PrinterDisconnectedException('La impresora se desconectó');
      }

      // Verificar si el error indica formato inválido
      if (errorStr.contains('invalid') ||
          errorStr.contains('format') ||
          errorStr.contains('reject') ||
          errorStr.contains('invalid data') ||
          errorStr.contains('protocol')) {
        throw const PrinterSendException(
          'El formato de los datos no es válido para la impresora ESC/POS.',
        );
      }

      debugPrint('Error al enviar datos Bluetooth: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Preservar el error original completo incluyendo detalles
      final errorMessage = e.toString();
      final errorDetails = e is Error ? e.stackTrace.toString() : '';
      throw PrinterSendException(
        'Error al enviar datos a la impresora: $errorMessage${errorDetails.isNotEmpty ? "\n\nDetalles:\n$errorDetails" : ""}',
      );
    }
  }

  @override
  bool get isConnected => _connectedPrinter != null;

  @override
  DiscoveredPrinter? get connectedPrinter => _connectedPrinter;

  @override
  Future<List<DiscoveredPrinter>> scanPrinters() async {
    if (!_isPlatformSupported()) {
      throw const PrinterPlatformNotSupportedException(
        'Bluetooth directo solo disponible en Android/iOS',
      );
    }

    try {
      // Usar el método discovery del plugin con tipo Bluetooth
      // discovery() retorna un Stream<PrinterDevice>, necesitamos convertirlo a lista
      // IMPORTANTE: isBle: false para Bluetooth clásico (no BLE)
      final devicesStream = _printerManager.discovery(
        type: PrinterType.bluetooth,
        isBle: false, // Bluetooth clásico para JP80H
      );

      // Convertir el Stream a una lista
      final devices = await devicesStream.toList();

      if (devices.isEmpty) {
        return [];
      }

      // Convertir los dispositivos del plugin a nuestro modelo DiscoveredPrinter
      return devices.map((device) {
        final deviceName = device.name;
        final deviceAddress = device.address ?? '';
        return DiscoveredPrinter(
          name: deviceName.isNotEmpty ? deviceName : 'Impresora sin nombre',
          address: deviceAddress,
          type: AppPrinterType.bluetooth,
          extraData: {'device': device},
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al escanear impresoras Bluetooth: $e');
      throw PrinterNotFoundException('Error al buscar impresoras: $e');
    }
  }

  /// Verifica si la plataforma soporta Bluetooth
  bool _isPlatformSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}
