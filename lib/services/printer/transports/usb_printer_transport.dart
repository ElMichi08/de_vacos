import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../printer_transport.dart';
import '../discovered_printer.dart';
import '../printer_exceptions.dart';

/// Implementación de transporte para impresoras USB
/// Usa el plugin flutter_pos_printer_platform_image_3 para comunicación USB
/// Soporta Android y Windows
class UsbPrinterTransport implements PrinterTransport {
  final PrinterManager _printerManager;
  DiscoveredPrinter? _connectedPrinter;

  UsbPrinterTransport(this._printerManager);

  @override
  Future<void> connect(DiscoveredPrinter printer) async {
    if (printer.type != AppPrinterType.usb) {
      throw const PrinterConnectionException('El tipo de impresora no es USB');
    }

    if (!_isPlatformSupported()) {
      throw const PrinterPlatformNotSupportedException(
        'USB solo disponible en Android/Windows',
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

      // Crear UsbPrinterInput a partir de los datos del dispositivo
      final usbInput = UsbPrinterInput(
        name: device.name,
        vendorId: device.vendorId,
        productId: device.productId,
      );

      // Conectar usando el método connect del plugin con tipo USB
      final result = await _printerManager.connect(
        type: PrinterType.usb,
        model: usbInput,
      );

      if (result == true) {
        _connectedPrinter = printer;
      } else {
        throw const PrinterConnectionException(
          'No se pudo establecer la conexión USB',
        );
      }
    } catch (e) {
      if (e is PrinterException) {
        rethrow;
      }

      // Detectar errores de permisos USB
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('permiso') ||
          errorStr.contains('access denied')) {
        throw PrinterUsbPermissionException(
          'Se requieren permisos USB. Verifica la configuración del dispositivo.',
        );
      }

      debugPrint('Error al conectar impresora USB: $e');
      throw PrinterConnectionException('Error al conectar USB: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedPrinter == null) {
      return;
    }

    try {
      await _printerManager.disconnect(type: PrinterType.usb);
      _connectedPrinter = null;
    } catch (e) {
      debugPrint('Error al desconectar impresora USB: $e');
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
      debugPrint('Enviando ${bytes.length} bytes ESC/POS a la impresora USB');

      // Enviar los datos usando el método send del plugin
      // El plugin espera List<int>, no Uint8List (esto causa ClassCastException en Android)
      final result = await _printerManager.send(
        type: PrinterType.usb,
        bytes: bytes, // Enviar List<int> directamente
      );

      if (result != true) {
        // La impresora rechazó los datos - probablemente formato inválido
        throw const PrinterSendException(
          'El formato de los datos no es válido para la impresora ESC/POS. Verifica que los bytes se generen correctamente con esc_pos_utils_plus.',
        );
      }

      debugPrint('Bytes enviados correctamente a la impresora USB');
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

      debugPrint('Error al enviar datos USB: $e');
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
        'USB solo disponible en Android/Windows',
      );
    }

    try {
      // Usar el método discovery del plugin con tipo USB
      // discovery() retorna un Stream<PrinterDevice>, necesitamos convertirlo a lista
      final devicesStream = _printerManager.discovery(type: PrinterType.usb);

      // Convertir el Stream a una lista
      final devices = await devicesStream.toList();

      if (devices.isEmpty) {
        return [];
      }

      // Convertir los dispositivos del plugin a nuestro modelo DiscoveredPrinter
      return devices.map((device) {
        final deviceName = device.name;
        final deviceAddress = device.address ?? '';

        // Para USB, el address puede ser el path del dispositivo o vendorId:productId
        // El plugin maneja esto internamente
        final extraData = <String, dynamic>{'device': device};

        // Nota: vendorId y productId pueden no estar disponibles en PrinterDevice
        // El plugin maneja la identificación del dispositivo internamente

        return DiscoveredPrinter(
          name: deviceName.isNotEmpty ? deviceName : 'Impresora USB',
          address: deviceAddress,
          type: AppPrinterType.usb,
          extraData: extraData,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al escanear impresoras USB: $e');

      // Detectar errores de permisos USB
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('permiso') ||
          errorStr.contains('access denied')) {
        throw PrinterUsbPermissionException(
          'Se requieren permisos USB para escanear impresoras. Verifica la configuración del dispositivo.',
        );
      }

      throw PrinterNotFoundException('Error al buscar impresoras USB: $e');
    }
  }

  /// Verifica si la plataforma soporta USB
  bool _isPlatformSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isWindows);
  }
}
