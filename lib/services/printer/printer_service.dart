import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'printer_exceptions.dart';
import 'printer_result.dart';
import 'discovered_printer.dart';
import 'ticket_builder.dart';
import 'printer_transport.dart';
import 'transports/bluetooth_printer_transport.dart';
import 'transports/usb_printer_transport.dart';
import '../../models/pedido.dart';

/// Servicio principal para gestionar impresión térmica
/// Encapsula toda la lógica de conexión e impresión usando plugins modernos
/// Usa el patrón Strategy para soportar múltiples tipos de transporte (Bluetooth, USB, etc.)
/// La UI no necesita conocer el tipo de conexión, solo usa este servicio unificado
class PrinterService {
  static PrinterService? _instance;
  late final PrinterManager _printerManager;
  PrinterTransport? _currentTransport;
  bool _isInitialized = false;
  PaperSize _paperSize = PaperSize.mm80;
  DateTime? _lastPrintTime;
  static const Duration _printDebounceDuration = Duration(seconds: 2);

  /// Singleton para mantener una única instancia del servicio
  factory PrinterService() {
    _instance ??= PrinterService._internal();
    return _instance!;
  }

  PrinterService._internal() {
    // Usar el singleton del plugin, no crear nueva instancia
    _printerManager = PrinterManager.instance;
  }

  /// Verifica si la plataforma soporta impresión térmica
  static bool isPlatformSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isWindows);
  }

  /// Verifica si la plataforma soporta Bluetooth directo
  static bool isBluetoothSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Verifica si la plataforma soporta USB
  static bool isUsbSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isWindows);
  }

  /// Inicializa el servicio de impresión
  /// Debe llamarse antes de usar cualquier otro método
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isPlatformSupported()) {
      throw const PrinterPlatformNotSupportedException(
          'Web no soporta impresión térmica');
    }

    // Cargar tamaño de papel guardado
    await _loadPaperSize();

    _isInitialized = true;
  }

  /// Carga el tamaño de papel desde preferencias
  Future<void> _loadPaperSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paperSizeIndex = prefs.getInt('printer_paper_size') ?? 0; // 0 = 80mm, 1 = 56mm
      _paperSize = paperSizeIndex == 1 ? PaperSize.mm58 : PaperSize.mm80;
    } catch (e) {
      debugPrint('Error al cargar tamaño de papel: $e');
      _paperSize = PaperSize.mm80; // Por defecto 80mm
    }
  }

  /// Guarda el tamaño de papel en preferencias
  Future<void> setPaperSize(PaperSize paperSize) async {
    try {
      _paperSize = paperSize;
      final prefs = await SharedPreferences.getInstance();
      final paperSizeIndex = paperSize == PaperSize.mm58 ? 1 : 0;
      await prefs.setInt('printer_paper_size', paperSizeIndex);
      debugPrint('Tamaño de papel guardado: ${paperSize == PaperSize.mm58 ? "56mm" : "80mm"}');
    } catch (e) {
      debugPrint('Error al guardar tamaño de papel: $e');
    }
  }

  /// Obtiene el tamaño de papel actual
  PaperSize get paperSize => _paperSize;

  /// Escanea impresoras disponibles
  /// Método de alto nivel para la UI
  /// Retorna un PrinterResult con la lista de impresoras o un error
  Future<PrinterResult<List<DiscoveredPrinter>>> scan({AppPrinterType? filter}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final printers = await scanPrinters(filter: filter);
      return PrinterSuccess(printers);
    } on PrinterException catch (e) {
      return PrinterFailure(e.message, e);
    } catch (e) {
      debugPrint('Error inesperado al escanear impresoras: $e');
      return PrinterFailure('Error al buscar impresoras: $e');
    }
  }

  /// Selecciona y conecta una impresora
  /// Método de alto nivel para la UI
  /// Retorna un PrinterResult indicando éxito o fallo
  Future<PrinterResult<void>> selectAndConnect(DiscoveredPrinter printer) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await connectToPrinter(printer);
      debugPrint('Impresora conectada: ${printer.name}');
      return const PrinterSuccess(null);
    } on PrinterException catch (e) {
      return PrinterFailure(e.message, e);
    } catch (e) {
      debugPrint('Error inesperado al conectar impresora: $e');
      return PrinterFailure('Error al conectar impresora: $e');
    }
  }

  /// Escanea impresoras disponibles de todos los tipos soportados
  /// [filter] permite filtrar por tipo específico (null = todos los tipos)
  /// Retorna una lista unificada de impresoras encontradas
  /// @internal Método interno, usar scan() desde la UI
  Future<List<DiscoveredPrinter>> scanPrinters({AppPrinterType? filter}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final List<DiscoveredPrinter> allPrinters = [];

    // Escanear Bluetooth si está soportado y no hay filtro o el filtro es Bluetooth
    if ((filter == null || filter == AppPrinterType.bluetooth) &&
        isBluetoothSupported()) {
      try {
        final bluetoothTransport = BluetoothPrinterTransport(_printerManager);
        final bluetoothPrinters = await bluetoothTransport.scanPrinters();
        allPrinters.addAll(bluetoothPrinters);
      } catch (e) {
        debugPrint('Error al escanear impresoras Bluetooth: $e');
        // Continuar con otros tipos aunque falle Bluetooth
      }
    }

    // Escanear USB si está soportado y no hay filtro o el filtro es USB
    if ((filter == null || filter == AppPrinterType.usb) && isUsbSupported()) {
      try {
        final usbTransport = UsbPrinterTransport(_printerManager);
        final usbPrinters = await usbTransport.scanPrinters();
        allPrinters.addAll(usbPrinters);
      } catch (e) {
        debugPrint('Error al escanear impresoras USB: $e');
        // Continuar aunque falle USB
      }
    }

    return allPrinters;
  }

  /// Escanea solo impresoras Bluetooth (método legacy para compatibilidad)
  /// @deprecated Usa scanPrinters() en su lugar
  @Deprecated('Usa scanPrinters() en su lugar')
  Future<List<DiscoveredPrinter>> scanBluetoothPrinters() async {
    return scanPrinters(filter: AppPrinterType.bluetooth);
  }

  /// Conecta a una impresora usando el transporte apropiado
  /// El servicio selecciona automáticamente el transporte según el tipo de impresora
  Future<void> connectToPrinter(DiscoveredPrinter printer) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Desconectar cualquier impresora previa
    if (_currentTransport != null && _currentTransport!.isConnected) {
      await _currentTransport!.disconnect();
    }

    // Seleccionar el transporte apropiado según el tipo de impresora
    PrinterTransport transport;
    switch (printer.type) {
      case AppPrinterType.bluetooth:
        if (!isBluetoothSupported()) {
          throw const PrinterPlatformNotSupportedException(
              'Bluetooth no está soportado en esta plataforma');
        }
        transport = BluetoothPrinterTransport(_printerManager);
        break;
      case AppPrinterType.usb:
        if (!isUsbSupported()) {
          throw const PrinterPlatformNotSupportedException(
              'USB no está soportado en esta plataforma');
        }
        transport = UsbPrinterTransport(_printerManager);
        break;
      case AppPrinterType.wifi:
      case AppPrinterType.network:
        throw const PrinterPlatformNotSupportedException(
            'WiFi/Network aún no está implementado');
    }

    // Conectar usando el transporte seleccionado
    await transport.connect(printer);
    _currentTransport = transport;
  }

  /// Desconecta la impresora actual
  Future<void> disconnect() async {
    if (_currentTransport != null && _currentTransport!.isConnected) {
      await _currentTransport!.disconnect();
      _currentTransport = null;
    }
  }

  /// Verifica si hay una impresora conectada
  bool get isConnected {
    return _currentTransport?.isConnected ?? false;
  }

  /// Obtiene la impresora actualmente conectada
  DiscoveredPrinter? getConnectedPrinter() {
    return _currentTransport?.connectedPrinter;
  }

  /// Valida que no haya múltiples impresiones en un corto período
  bool _canPrint() {
    final now = DateTime.now();
    if (_lastPrintTime != null) {
      final timeSinceLastPrint = now.difference(_lastPrintTime!);
      if (timeSinceLastPrint < _printDebounceDuration) {
        debugPrint('Impresión ignorada: muy pronto después de la última (${timeSinceLastPrint.inMilliseconds}ms)');
        return false;
      }
    }
    _lastPrintTime = now;
    return true;
  }

  /// Imprime un ticket de prueba
  /// Útil para verificar que la impresora funciona correctamente
  /// Método de alto nivel para la UI
  /// Retorna un PrinterResult indicando éxito o fallo
  Future<PrinterResult<void>> printTestTicket() async {
    if (!isConnected) {
      return const PrinterFailure(
        'No hay impresora conectada. Por favor, ve a Configuración de impresora para seleccionar una impresora.',
        PrinterNotConnectedException(),
      );
    }

    // Validar debouncing
    if (!_canPrint()) {
      return const PrinterFailure(
        'Por favor espera un momento antes de imprimir nuevamente.',
      );
    }

    try {
      // Construir el ticket de prueba con el tamaño de papel actual
      final ticketBytes = await TicketBuilder.buildTestTicket(paperSize: _paperSize);
      
      // Logging para diagnóstico
      debugPrint('=== DIAGNÓSTICO DE TICKET DE PRUEBA ===');
      debugPrint('Tamaño de papel: ${_paperSize == PaperSize.mm58 ? "56mm" : "80mm"}');
      debugPrint('Total de bytes generados: ${ticketBytes.length}');
      if (ticketBytes.isNotEmpty) {
        debugPrint('Primeros 20 bytes: ${ticketBytes.take(20).join(", ")}');
        debugPrint('Últimos 20 bytes: ${ticketBytes.skip(ticketBytes.length > 20 ? ticketBytes.length - 20 : 0).join(", ")}');
      }

      // Enviar a la impresora usando el transporte actual
      await _currentTransport!.printBytes(ticketBytes);
      debugPrint('Ticket de prueba impreso correctamente');
      return const PrinterSuccess(null);
    } on PrinterException catch (e) {
      debugPrint('Error de impresión (PrinterException): $e');
      debugPrint('Detalles del error: ${e.toString()}');
      // Incluir todos los detalles del error
      final errorMessage = e.details != null 
          ? '${e.message}\n\n${e.details}'
          : e.message;
      return PrinterFailure(errorMessage, e);
    } catch (e, stackTrace) {
      debugPrint('Error inesperado al imprimir ticket de prueba: $e');
      debugPrint('Stack trace: $stackTrace');
      // Incluir el error completo con stack trace
      final errorMessage = 'Error al imprimir:\n\n$e\n\nStack trace:\n$stackTrace';
      return PrinterFailure(errorMessage);
    }
  }

  /// Imprime un ticket de pedido
  /// Construye el ticket usando TicketBuilder y lo envía a la impresora
  /// Método de alto nivel que abstrae la construcción y envío del ticket
  /// Retorna un PrinterResult indicando éxito o fallo
  Future<PrinterResult<void>> printPedido(Pedido pedido) async {
    if (!isConnected) {
      return const PrinterFailure(
        'No hay impresora configurada. Por favor, ve a Configuración de impresora para seleccionar una impresora.',
        PrinterNotConnectedException(),
      );
    }

    // Validar debouncing
    if (!_canPrint()) {
      return const PrinterFailure(
        'Por favor espera un momento antes de imprimir nuevamente.',
      );
    }

    try {
      // Construir el ticket del pedido con el tamaño de papel actual
      final ticketBytes = await TicketBuilder.buildPedidoTicket(
        pedido,
        paperSize: _paperSize,
      );
      
      // Logging para diagnóstico
      debugPrint('=== DIAGNÓSTICO DE TICKET DE PEDIDO ===');
      debugPrint('Pedido #${pedido.numeroOrden}');
      debugPrint('Tamaño de papel: ${_paperSize == PaperSize.mm58 ? "56mm" : "80mm"}');
      debugPrint('Total de bytes generados: ${ticketBytes.length}');

      // Enviar a la impresora usando el transporte actual
      await _currentTransport!.printBytes(ticketBytes);
      debugPrint('Ticket del pedido #${pedido.numeroOrden} impreso correctamente');
      return const PrinterSuccess(null);
    } on PrinterException catch (e) {
      return PrinterFailure(e.message, e);
    } catch (e) {
      debugPrint('Error inesperado al imprimir pedido: $e');
      return const PrinterFailure('Error al imprimir el ticket. Revisa la conexión y vuelve a intentar.');
    }
  }


  /// Limpia recursos y desconecta
  /// Debe llamarse cuando la app se cierre o ya no se necesite el servicio
  Future<void> dispose() async {
    await disconnect();
    _isInitialized = false;
  }
}
