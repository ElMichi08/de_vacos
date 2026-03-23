import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../widgets/back_header_widget.dart';

/// Pantalla KDS (Kitchen Display): pedidos en cocina (En preparación) con polling y "Marcar listo"
class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> {
  List<Pedido> _pedidos = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  static const Duration _pollingInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(_pollingInterval, (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final todos = await PedidoService.obtenerTodos();
      final enCocina = todos
          .where((p) =>
              p.estado == 'En preparación' || p.estado == 'Pendiente')
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      if (mounted) {
        setState(() {
          _pedidos = enCocina;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _marcarListo(Pedido pedido) async {
    if (pedido.id == null) return;
    try {
      await PedidoService.actualizarEstado(pedido.id!, 'Despachada');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido #${pedido.numeroOrden} marcado como listo'),
            backgroundColor: AppColors.success,
          ),
        );
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Cocina (KDS)'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _pedidos.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null && _pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_pedidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'No hay pedidos en cocina',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Se actualiza cada 10 segundos',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          return _buildPedidoCard(_pedidos[index]);
        },
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    final numOrden = pedido.numeroOrden;
    final productosCount = pedido.productos.length;
    return Card(
      elevation: AppConstants.cardElevation,
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$numOrden',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pedido.cliente,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  pedido.estado,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (pedido.notas.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notas: ${pedido.notas}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '$productosCount ítem(s) · \$${pedido.total.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _marcarListo(pedido),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Marcar listo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
