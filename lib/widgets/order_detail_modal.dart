import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/config/app_config.dart';
import '../models/pedido.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/printer/printer_result.dart';
import '../services/printer/printer_service.dart';

class OrderDetailModal extends StatelessWidget {
  final Pedido pedido;

  const OrderDetailModal({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Spacer(),
                _ActionChip(
                  icon: Icons.print_outlined,
                  label: 'Imprimir',
                  onTap: () => _imprimirPedido(context),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.close,
                  label: 'Cerrar',
                  onTap: () => Navigator.pop(context),
                  color: Colors.white30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Ticket content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _buildTicketContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketContent(BuildContext context) {
    final productos = _obtenerProductosAgrupados(pedido.productos);
    final appName = AppConfig.instance.appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header tipo recibo ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text(
                appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'TICKET DE PEDIDO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Número de orden ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDEN',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 2)),
                  Text(
                    '#${pedido.numeroOrden}',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(pedido.fecha),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    DateFormat('HH:mm').format(pedido.fecha),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Info del cliente ───────────────────────────────────────────
        _TicketSection(
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Cliente',
              value: pedido.cliente,
            ),
            if (pedido.celular.isNotEmpty)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Celular',
                value: pedido.celular,
              ),
            _InfoRow(
              icon: Icons.payment_outlined,
              label: 'Pago',
              value: pedido.metodoPago.displayName,
            ),
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Estado',
              value: pedido.estado.displayName,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Productos ─────────────────────────────────────────────────
        _TicketSection(
          header: 'PRODUCTOS',
          children: [
            ...productos.map((producto) => _ProductoRow(producto: producto)),
            if (pedido.envasesLlevar > 0) ...[
              const Divider(color: Colors.white12, height: 16),
              _EnvasesRow(cantidad: pedido.envasesLlevar),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── Notas ──────────────────────────────────────────────────────
        if (pedido.notas.isNotEmpty) ...[
          _TicketSection(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido.notas,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Total ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppColors.price.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '\$${pedido.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.price,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Agrupación de productos ─────────────────────────────────────────────

  List<Map<String, dynamic>> _obtenerProductosAgrupados(
    List<dynamic> productos,
  ) {
    final agrupados = <String, Map<String, dynamic>>{};

    for (final raw in productos) {
      final producto = raw as Map<String, dynamic>;
      final nombre = producto['nombre'] as String? ?? 'Producto';
      final variante = producto['variante'] as String? ?? '';
      final clave = '${nombre}_${variante}_${_acompanantesKey(producto)}_${_extrasKey(producto)}';

      if (agrupados.containsKey(clave)) {
        agrupados[clave]!['cantidad'] =
            (agrupados[clave]!['cantidad'] as int) +
            (producto['cantidad'] as int? ?? 1);
      } else {
        agrupados[clave] = Map<String, dynamic>.from(producto);
        agrupados[clave]!.putIfAbsent('cantidad', () => 1);
      }
    }

    return agrupados.values.toList();
  }

  String _acompanantesKey(Map<String, dynamic> p) {
    final list = p['acompanantes'];
    if (list is List) {
      return list.map((a) {
        if (a is Map) return '${a['nombre']}:${a['cantidad'] ?? 1}';
        return a.toString();
      }).join(',');
    }
    return '';
  }

  String _extrasKey(Map<String, dynamic> p) {
    final list = p['extras'];
    if (list is List) return list.map((e) => e.toString()).join(',');
    return '';
  }

  // ── Impresión ───────────────────────────────────────────────────────────

  static DateTime? _lastPrintTime;
  static const Duration _printDebounceDuration = Duration(seconds: 2);

  Future<void> _imprimirPedido(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPrintTime != null &&
        now.difference(_lastPrintTime!) < _printDebounceDuration) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Espera un momento antes de imprimir nuevamente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ));
      }
      return;
    }
    _lastPrintTime = now;

    final printerService = PrinterService();

    if (!PrinterService.isPlatformSupported()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('La impresión no está disponible en esta plataforma'),
            backgroundColor: Colors.orange,
          ));
      }
      return;
    }

    if (!printerService.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text(
              'No hay impresora configurada. Ve a Configuración de impresora.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ));
      }
      return;
    }

    if (!context.mounted) return;
    await _ejecutarImpresion(context, printerService);
  }

  Future<void> _ejecutarImpresion(
    BuildContext context,
    PrinterService printerService,
  ) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await printerService.printPedido(pedido);

    if (!context.mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(result.isSuccess
            ? 'Ticket impreso correctamente.'
            : result.errorOrNull ?? 'Error al imprimir'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ));
  }
}

// ── Widgets de apoyo ────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: color ?? AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: color != null ? Colors.white60 : AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color != null ? Colors.white60 : AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const _TicketSection({this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Text(
              header!,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white12, height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white38),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoRow extends StatelessWidget {
  final Map<String, dynamic> producto;

  const _ProductoRow({required this.producto});

  @override
  Widget build(BuildContext context) {
    final cantidad = producto['cantidad'] as int? ?? 1;
    final nombre = producto['nombre'] as String? ?? 'Producto';
    final precio = (producto['precio'] as num?)?.toDouble() ?? 0.0;
    final subtotal = precio * cantidad;

    // Construir líneas de detalle
    final List<String> detalles = [];

    // Proteinas (new menu format) — ya vienen en el nombre, no duplicar
    // Acompañantes — soporta List<Map> y List<String>
    final acompRaw = producto['acompanantes'];
    if (acompRaw is List && acompRaw.isNotEmpty) {
      final acompStr = acompRaw.map((a) {
        if (a is Map) {
          final n = a['nombre'] as String? ?? '';
          final c = a['cantidad'] as int? ?? 1;
          return c > 1 ? '$n ×$c' : n;
        }
        return a.toString();
      }).where((s) => s.isNotEmpty).join(', ');
      if (acompStr.isNotEmpty) detalles.add(acompStr);
    }

    // Extras
    final extrasRaw = producto['extras'];
    if (extrasRaw is List && extrasRaw.isNotEmpty) {
      detalles.add(extrasRaw.map((e) => e.toString()).join(', '));
    }

    // Modalidad
    final modalidad = producto['modalidad'] as String?;
    if (modalidad != null && modalidad.isNotEmpty) detalles.add(modalidad);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                child: Text(
                  '$cantidad×',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.price,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (detalles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                detalles.join('  ·  '),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnvasesRow extends StatelessWidget {
  final int cantidad;
  static const double _precioUnitario = 0.25;

  const _EnvasesRow({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.takeout_dining_outlined,
            size: 15, color: Colors.white38),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Envases × $cantidad',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Text(
          '\$${(cantidad * _precioUnitario).toStringAsFixed(2)}',
          style: const TextStyle(color: AppColors.price, fontSize: 13),
        ),
      ],
    );
  }
}
