import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/printer/printer_service.dart';
import '../services/printer/discovered_printer.dart';
import '../services/printer/printer_result.dart';
import '../widgets/back_header_widget.dart';

/// Pantalla de configuración de impresora
/// Permite buscar, seleccionar y probar impresoras
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  List<DiscoveredPrinter> _availablePrinters = [];
  DiscoveredPrinter? _connectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  PaperSize _selectedPaperSize = PaperSize.mm80;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrinter();
    _loadPaperSize();
  }

  /// Carga el tamaño de papel actual
  void _loadPaperSize() {
    _selectedPaperSize = _printerService.paperSize;
  }

  /// Cambia el tamaño de papel seleccionado
  Future<void> _changePaperSize(PaperSize paperSize) async {
    setState(() {
      _selectedPaperSize = paperSize;
    });
    await _printerService.setPaperSize(paperSize);
    if (mounted) {
      _showSnackBar(
        'Tamaño de papel cambiado a ${paperSize == PaperSize.mm58 ? "56mm" : "80mm"}',
        isError: false,
      );
    }
  }

  /// Carga la impresora actualmente conectada
  void _loadCurrentPrinter() {
    final printer = _printerService.getConnectedPrinter();
    setState(() {
      _connectedPrinter = printer;
    });
  }

  /// Busca impresoras disponibles
  Future<void> _scanPrinters() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _availablePrinters = [];
    });

    try {
      final result = await _printerService.scan();

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _availablePrinters = result.valueOrNull ?? [];
        });

        if (_availablePrinters.isEmpty) {
          _showSnackBar(
            'No se encontraron impresoras',
            isError: false,
          );
        } else {
          _showSnackBar(
            'Se encontraron ${_availablePrinters.length} impresora(s)',
            isError: false,
          );
        }
      } else {
        _showSnackBar(result.errorOrNull ?? 'Error al buscar impresoras');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Conecta a una impresora seleccionada
  Future<void> _connectToPrinter(DiscoveredPrinter printer) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final result = await _printerService.selectAndConnect(printer);

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _connectedPrinter = printer;
        });
        _showSnackBar(
          'Impresora conectada correctamente',
          isError: false,
        );
      } else {
        _showSnackBar(result.errorOrNull ?? 'Error al conectar impresora');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  /// Imprime un ticket de prueba
  Future<void> _printTestTicket() async {
    if (_isPrinting || !_printerService.isConnected) return;

    setState(() {
      _isPrinting = true;
    });

    try {
      final result = await _printerService.printTestTicket();

      if (!mounted) return;

      if (result.isSuccess) {
        _showSnackBar(
          'Ticket de prueba impreso correctamente',
          isError: false,
        );
      } else {
        // Mostrar el error completo con todos los detalles
        final errorMessage = result.errorOrNull ?? 'No se pudo imprimir';
        _showErrorDialog(errorMessage);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Error inesperado al imprimir: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorDialog('Error inesperado:\n\n$e\n\nStack trace:\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  /// Muestra un SnackBar con el mensaje
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Muestra un diálogo con el error completo
  void _showErrorDialog(String errorMessage) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text(
              'Error al Imprimir',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            errorMessage,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copiar al portapapeles (opcional)
              // Clipboard.setData(ClipboardData(text: errorMessage));
            },
            child: Text(
              'Entendido',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Configuración de Impresora'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de estado de la impresora
              _buildStatusCard(),
              const SizedBox(height: AppConstants.spacingLarge),

              // Botón de buscar impresoras
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanPrinters,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Buscando...' : 'Buscar impresoras'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),

              // Lista de impresoras encontradas
              if (_availablePrinters.isNotEmpty) ...[
                Text(
                  'Impresoras encontradas (${_availablePrinters.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                _buildPrintersList(),
                const SizedBox(height: AppConstants.spacingLarge),
              ],

              // Botón de imprimir ticket de prueba
              ElevatedButton.icon(
                onPressed: (_isPrinting || !_printerService.isConnected)
                    ? null
                    : _printTestTicket,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: Text(_isPrinting ? 'Imprimiendo...' : 'Imprimir ticket de prueba'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la card de estado de la impresora
  Widget _buildStatusCard() {
    final isConnected = _printerService.isConnected;
    final printer = _connectedPrinter;

    return Card(
      color: AppColors.cardBackground,
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.cancel,
                  color: isConnected ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'Estado: ${isConnected ? "Conectado" : "Desconectado"}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (isConnected && printer != null) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              const Divider(color: Colors.white24),
              const SizedBox(height: AppConstants.spacingSmall),
              _buildStatusRow('Nombre:', printer.name),
              const SizedBox(height: AppConstants.spacingSmall),
              _buildStatusRow('Dirección:', printer.address),
              const SizedBox(height: AppConstants.spacingSmall),
              _buildStatusRow(
                'Tipo:',
                printer.type == AppPrinterType.bluetooth
                    ? 'Bluetooth'
                    : printer.type == AppPrinterType.usb
                        ? 'USB'
                        : 'Desconocido',
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              const Divider(color: Colors.white24),
              const SizedBox(height: AppConstants.spacingSmall),
              const Text(
                'Tamaño de papel:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              _buildPaperSizeSelector(),
            ] else if (!isConnected) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              const Text(
                'No hay impresora seleccionada',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información de estado
  Widget _buildStatusRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el selector de tamaño de papel con radio buttons
  Widget _buildPaperSizeSelector() {
    final isConnected = _printerService.isConnected;
    return Row(
      children: [
        Expanded(
          // ignore: deprecated_member_use - TODO: Migrar a RadioGroup cuando Flutter lo soporte
          child: RadioListTile<PaperSize>(
            title: const Text(
              '80mm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: PaperSize.mm80,
            // ignore: deprecated_member_use
            groupValue: _selectedPaperSize,
            // ignore: deprecated_member_use
            onChanged: isConnected
                ? (PaperSize? value) {
                    if (value != null) {
                      _changePaperSize(value);
                    }
                  }
                : null,
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        Expanded(
          // ignore: deprecated_member_use - TODO: Migrar a RadioGroup cuando Flutter lo soporte
          child: RadioListTile<PaperSize>(
            title: const Text(
              '56mm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: PaperSize.mm58,
            // ignore: deprecated_member_use
            groupValue: _selectedPaperSize,
            // ignore: deprecated_member_use
            onChanged: isConnected
                ? (PaperSize? value) {
                    if (value != null) {
                      _changePaperSize(value);
                    }
                  }
                : null,
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  /// Construye la lista de impresoras encontradas
  Widget _buildPrintersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availablePrinters.length,
      itemBuilder: (context, index) {
        final printer = _availablePrinters[index];
        final isConnected = _connectedPrinter?.address == printer.address &&
            _connectedPrinter?.type == printer.type;

        return Card(
          color: isConnected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBackground,
          elevation: AppConstants.cardElevation,
          margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            side: BorderSide(
              color: isConnected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
            leading: Icon(
              printer.type == AppPrinterType.bluetooth
                  ? Icons.bluetooth
                  : Icons.usb,
              color: AppColors.accent,
              size: 32,
            ),
            title: Text(
              printer.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  printer.address,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  printer.type == AppPrinterType.bluetooth ? 'Bluetooth' : 'USB',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: isConnected
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  )
                : _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 20,
                      ),
            onTap: isConnected || _isConnecting
                ? null
                : () => _connectToPrinter(printer),
          ),
        );
      },
    );
  }
}

