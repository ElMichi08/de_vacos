import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/info_panel.dart';
import '../widgets/bar_chart_panel.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Pedido> pedidos = [];
  bool isLoading = true;
  String? errorMessage;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final lista = await PedidoService.obtenerTodos(
        fechaInicio: _fechaSeleccionada,
        fechaFin: _fechaSeleccionada,
      );
      setState(() {
        pedidos = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<Pedido> _obtenerPedidosDelDia() {
    return pedidos.where((pedido) {
      return pedido.fecha.year == _fechaSeleccionada.year &&
          pedido.fecha.month == _fechaSeleccionada.month &&
          pedido.fecha.day == _fechaSeleccionada.day;
    }).toList();
  }

  double _calcularTotalIngresos() {
    // Solo computan los pedidos cerrados y cobrados (no cancelados)
    return _obtenerPedidosDelDia()
        .where((p) => 
            !p.cancelado && 
            p.estado == 'Cerrados' && 
            p.estadoPago == 'Cobrado')
        .fold(0.0, (sum, pedido) => sum + pedido.total);
  }

  int _contarPedidos() {
    return _obtenerPedidosDelDia()
        .where((p) => !p.cancelado)
        .length;
  }

  int _contarPedidosEntregados() {
    return _obtenerPedidosDelDia()
        .where((p) => !p.cancelado && (p.estado == 'Despachada' || p.estado == 'Cerrados'))
        .length;
  }

  List<Map<String, dynamic>> _obtenerDatosGrafico() {
    final pedidosDelDia = _obtenerPedidosDelDia();
    final Map<String, double> ventasPorMetodo = {};

    // Solo computan los pedidos cerrados y cobrados (no cancelados)
    for (var pedido in pedidosDelDia.where((p) => 
        !p.cancelado && 
        p.estado == 'Cerrados' && 
        p.estadoPago == 'Cobrado')) {
      ventasPorMetodo[pedido.metodoPago] =
          (ventasPorMetodo[pedido.metodoPago] ?? 0) + pedido.total;
    }

    return ventasPorMetodo.entries.map((entry) {
      return {
        'label': entry.key,
        'value': entry.value,
      };
    }).toList();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Reportes'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarPedidos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final totalIngresos = _calcularTotalIngresos();
    final totalPedidos = _contarPedidos();
    final pedidosEntregados = _contarPedidosEntregados();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de fecha
          Card(
            elevation: AppConstants.cardElevation,
            color: AppColors.cardBackground,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.accent),
              title: const Text(
                'Fecha',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              onTap: _seleccionarFecha,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),

          // Paneles de información
          Row(
            children: [
              Expanded(
                child: InfoPanel(
                  title: 'Total Ingresos',
                  value: '\$${totalIngresos.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: AppColors.price,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: InfoPanel(
                  title: 'Pedidos',
                  value: '$totalPedidos',
                  icon: Icons.receipt_long,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          InfoPanel(
            title: 'Pedidos Entregados',
            value: '$pedidosEntregados',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          const SizedBox(height: AppConstants.spacingLarge),

          // Gráfico
          BarChartPanel(
            data: _obtenerDatosGrafico(),
            title: 'Ventas por Método de Pago',
          ),
        ],
      ),
    );
  }
}

