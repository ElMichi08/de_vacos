import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pedido.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/printer/printer_service.dart';
import '../services/printer/printer_result.dart';

class OrderDetailModal extends StatelessWidget {
  final Pedido pedido;

  const OrderDetailModal({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                  'Detalle del Pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.white),
                      onPressed: () => _imprimirPedido(context),
                      tooltip: 'Imprimir',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppConstants.spacingMedium),

            _buildInfoRow('Número de orden:', '#${pedido.numeroOrden}'),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildInfoRow('Cliente:', pedido.cliente),
            if (pedido.celular.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              _buildInfoRow('Celular:', pedido.celular),
            ],
            const SizedBox(height: AppConstants.spacingSmall),
            _buildInfoRow('Método de pago:', pedido.metodoPago),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildInfoRow('Estado:', pedido.estado),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildInfoRow('Estado de pago:', pedido.estadoPago),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildInfoRow(
              'Fecha:',
              DateFormat('dd/MM/yyyy HH:mm').format(pedido.fecha),
            ),
            if (pedido.envasesLlevar > 0) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              _buildInfoRow(
                'Envases a llevar:',
                pedido.envasesLlevar.toString(),
              ),
            ],
            if (pedido.notas.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              _buildInfoRow('Notas:', pedido.notas),
            ],

            const SizedBox(height: AppConstants.spacingMedium),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppConstants.spacingSmall),

            const Text(
              'Productos:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),

            ..._obtenerProductosAgrupados(pedido.productos).map((producto) {
              final cantidad = producto['cantidad'] as int;
              final nombre = producto['nombre'] as String? ?? 'Producto';
              final precio = (producto['precio'] as num).toDouble();

              // Construir nombre completo con detalles
              String nombreCompleto = nombre;
              final variante = producto['variante'] as String?;
              final acompanantes = producto['acompanantes'] as List?;
              final extras = producto['extras'] as List?;

              List<String> detalles = [];
              if (variante != null && variante.isNotEmpty) {
                detalles.add(variante);
              }
              if (acompanantes != null && acompanantes.isNotEmpty) {
                final acompanantesStr = acompanantes
                    .map((a) {
                      final nombreAcomp = a['nombre'] as String? ?? '';
                      final cantAcomp = a['cantidad'] as int? ?? 1;
                      return cantAcomp > 1
                          ? '$nombreAcomp x$cantAcomp'
                          : nombreAcomp;
                    })
                    .join(', ');
                detalles.add(acompanantesStr);
              }
              if (extras != null && extras.isNotEmpty) {
                detalles.add(extras.join(', '));
              }

              if (detalles.isNotEmpty) {
                nombreCompleto = '$nombreCompleto (${detalles.join(', ')})';
              }

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.spacingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${cantidad}x $nombreCompleto',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      '\$${(precio * cantidad).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.price,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppConstants.spacingMedium),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppConstants.spacingSmall),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.price,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Agrupa productos iguales antes de mostrar
  List<Map<String, dynamic>> _obtenerProductosAgrupados(
    List<dynamic> productos,
  ) {
    final productosAgrupados = <String, Map<String, dynamic>>{};

    for (final producto in productos) {
      // Crear clave única basada en configuración
      final nombreProducto = producto['nombre'] as String? ?? 'Producto';
      final variante = producto['variante'] as String? ?? '';
      final acompanantes = producto['acompanantes'] as List?;
      final acompanantesKey =
          acompanantes != null
              ? acompanantes
                  .map((a) => '${a['nombre']}:${a['cantidad']}')
                  .join(',')
              : '';
      final extras = producto['extras'] as List?;
      final extrasKey = extras != null ? extras.join(',') : '';
      final clave =
          '${nombreProducto}_${variante}_${acompanantesKey}_$extrasKey';

      if (productosAgrupados.containsKey(clave)) {
        // Incrementar cantidad
        productosAgrupados[clave]!['cantidad'] =
            (productosAgrupados[clave]!['cantidad'] as int) +
            (producto['cantidad'] as int? ?? 1);
      } else {
        // Agregar nuevo producto
        productosAgrupados[clave] = Map<String, dynamic>.from(producto);
      }
    }

    return productosAgrupados.values.toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  static DateTime? _lastPrintTime;
  static const Duration _printDebounceDuration = Duration(seconds: 2);

  Future<void> _imprimirPedido(BuildContext context) async {
    // Validar debouncing para evitar múltiples impresiones
    final now = DateTime.now();
    if (_lastPrintTime != null) {
      final timeSinceLastPrint = now.difference(_lastPrintTime!);
      if (timeSinceLastPrint < _printDebounceDuration) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Por favor espera un momento antes de imprimir nuevamente.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }
    _lastPrintTime = now;

    final printerService = PrinterService();

    // Verificar si la plataforma soporta impresión
    if (!PrinterService.isPlatformSupported()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La impresión no está disponible en esta plataforma'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Verificar si hay impresora conectada
    // Si no hay impresora, mostrar mensaje claro para que el usuario vaya a Configuración
    if (!printerService.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay impresora configurada. Por favor, ve a Configuración de impresora para seleccionar una impresora.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Ya hay impresora conectada, imprimir directamente
    if (!context.mounted) return;
    await _ejecutarImpresion(context, printerService);
  }

  Future<void> _ejecutarImpresion(
    BuildContext context,
    PrinterService printerService,
  ) async {
    // Mostrar indicador de carga
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await printerService.printPedido(pedido);

    if (!context.mounted) return;
    Navigator.pop(context); // Cerrar indicador de carga

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket impreso correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Error al imprimir'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
