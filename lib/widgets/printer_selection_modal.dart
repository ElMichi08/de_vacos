import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/printer/printer_service.dart';
import '../services/printer/printer_exceptions.dart';
import '../services/printer/discovered_printer.dart';

/// Modal para seleccionar y conectar una impresora (Bluetooth o USB)
/// Usa el nuevo PrinterService con arquitectura limpia
/// La UI no necesita conocer el tipo de conexión
class PrinterSelectionModal extends StatefulWidget {
  const PrinterSelectionModal({super.key});

  @override
  State<PrinterSelectionModal> createState() => _PrinterSelectionModalState();
}

class _PrinterSelectionModalState extends State<PrinterSelectionModal> {
  final PrinterService _printerService = PrinterService();
  List<DiscoveredPrinter> _impresoras = [];
  bool _buscando = false;
  String? _error;
  DiscoveredPrinter? _impresoraConectada;

  @override
  void initState() {
    super.initState();
    _impresoraConectada = _printerService.getConnectedPrinter();
    _buscarImpresoras();
  }

  Future<void> _buscarImpresoras() async {
    setState(() {
      _buscando = true;
      _error = null;
    });

    try {
      // Usar el método unificado que escanea Bluetooth y USB
      final impresoras = await _printerService.scanPrinters();
      if (!mounted) return;
      setState(() {
        _impresoras = impresoras;
        _buscando = false;
      });
    } on PrinterNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _buscando = false;
      });
    } on PrinterPlatformNotSupportedException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _buscando = false;
      });
    } on PrinterUsbPermissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${e.message}\n\nVerifica los permisos USB en la configuración del dispositivo.';
        _buscando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado: $e';
        _buscando = false;
      });
    }
  }

  Future<void> _conectarImpresora(DiscoveredPrinter impresora) async {
    try {
      await _printerService.connectToPrinter(impresora);
      if (!mounted) return;
      setState(() {
        _impresoraConectada = impresora;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impresora conectada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } on PrinterConnectionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _desconectar() async {
    try {
      await _printerService.disconnect();
      if (!mounted) return;
      setState(() {
        _impresoraConectada = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impresora desconectada'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desconectar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _imprimirPrueba() async {
    if (!_printerService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay impresora conectada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _printerService.printTestTicket();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket de prueba impreso exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } on PrinterException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Impresora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppConstants.spacingMedium),

            // Estado de conexión
            if (_impresoraConectada != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Conectado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _impresoraConectada!.name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _desconectar,
                          child: const Text('Desconectar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    ElevatedButton.icon(
                      onPressed: _imprimirPrueba,
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir Ticket de Prueba'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
            ],

            // Botón de buscar
            ElevatedButton.icon(
              onPressed: _buscando ? null : _buscarImpresoras,
              icon: _buscando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_buscando ? 'Buscando...' : 'Buscar Impresoras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),

            // Mensaje de error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error al buscar impresoras:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    const Text(
                      'Solución:\n'
                      'Bluetooth:\n'
                      '1. Asegúrate de que la impresora esté emparejada desde la configuración de Bluetooth\n'
                      '2. Verifica que los permisos de Bluetooth estén activados\n'
                      'USB:\n'
                      '1. Conecta la impresora USB al dispositivo\n'
                      '2. Verifica los permisos USB en la configuración\n'
                      '3. Reinicia la aplicación si el problema persiste',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Mensaje cuando no hay impresoras
            if (_impresoras.isEmpty && !_buscando && _error == null)
              const Padding(
                padding: EdgeInsets.all(AppConstants.paddingLarge),
                child: Text(
                  'No se encontraron impresoras.\n\n'
                  'Bluetooth: Asegúrate de emparejar tu impresora desde la configuración de Bluetooth.\n\n'
                  'USB: Conecta la impresora USB al dispositivo y verifica los permisos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),

            // Lista de impresoras
            ..._impresoras.map((impresora) {
              final esSeleccionada = _impresoraConectada?.address == impresora.address;

              return Card(
                color: AppColors.background,
                margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
                child: ListTile(
                  leading: Icon(
                    Icons.print,
                    color: esSeleccionada ? Colors.green : AppColors.accent,
                  ),
                  title: Text(
                    impresora.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${impresora.address} • ${_getTipoTexto(impresora.type)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: esSeleccionada
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                          icon: Icon(
                            _getTipoIcono(impresora.type),
                            color: AppColors.accent,
                          ),
                          onPressed: () => _conectarImpresora(impresora),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Obtiene el texto descriptivo del tipo de impresora
  String _getTipoTexto(AppPrinterType type) {
    switch (type) {
      case AppPrinterType.bluetooth:
        return 'Bluetooth';
      case AppPrinterType.usb:
        return 'USB';
      case AppPrinterType.wifi:
        return 'WiFi';
      case AppPrinterType.network:
        return 'Red';
    }
  }

  /// Obtiene el icono apropiado para el tipo de impresora
  IconData _getTipoIcono(AppPrinterType type) {
    switch (type) {
      case AppPrinterType.bluetooth:
        return Icons.bluetooth;
      case AppPrinterType.usb:
        return Icons.usb;
      case AppPrinterType.wifi:
        return Icons.wifi;
      case AppPrinterType.network:
        return Icons.network_check;
    }
  }
}
