import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../models/enums.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/info_panel.dart';
import '../widgets/filterable_info_panel.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/order_detail_modal.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/transfer_photo_viewer_modal.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Pedido> pedidos = [];
  bool isLoading = true;
  String? errorMessage;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();
  PaymentMethod? _filtroMetodoPago; // null = todos, PaymentMethod.transferencia o PaymentMethod.efectivo
  int _itemsPerPage = 20; // Cantidad de pedidos a mostrar
  int _paginaActual = 1; // Página actual

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final lista = await PedidoService.obtenerTodos(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      if (!mounted) return;
      setState(() {
        pedidos = lista;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _onFechasChanged(DateTime fechaInicio, DateTime fechaFin) {
    setState(() {
      _fechaInicio = fechaInicio;
      _fechaFin = fechaFin;
    });
    _cargarPedidos();
  }

  List<Pedido> _obtenerPedidosDelRango() {
    return pedidos.where((pedido) {
      final fechaPedido = DateTime(
        pedido.fecha.year,
        pedido.fecha.month,
        pedido.fecha.day,
      );
      final fechaInicio = DateTime(
        _fechaInicio.year,
        _fechaInicio.month,
        _fechaInicio.day,
      );
      final fechaFin = DateTime(_fechaFin.year, _fechaFin.month, _fechaFin.day);
      // Incluir pedidos que estén en el rango (inclusive)
      return (fechaPedido.isAtSameMomentAs(fechaInicio) ||
          fechaPedido.isAtSameMomentAs(fechaFin) ||
          (fechaPedido.isAfter(fechaInicio) && fechaPedido.isBefore(fechaFin)));
    }).toList();
  }

  double _calcularTotalIngresos() {
    // Solo computan los pedidos cerrados y cobrados (no cancelados)
    return _obtenerPedidosDelRango()
        .where(
          (p) =>
              !p.cancelado &&
              p.estado == OrderStatus.cerrados &&
              p.estadoPago == PaymentStatus.cobrado,
        )
        .fold(0.0, (sum, pedido) => sum + pedido.total);
  }

  int _contarPedidos() {
    return _obtenerPedidosDelRango().where((p) => !p.cancelado).length;
  }

  /// True si el pedido incluye al menos un pago con [metodo].
  /// Usa el historial de pagos (multi-pago) o el campo metodoPago como fallback.
  bool _matchesFiltro(Pedido p, PaymentMethod metodo) {
    if (p.pagos != null && p.pagos!.isNotEmpty) {
      return p.pagos!.any((pg) => pg.metodo == metodo);
    }
    return p.metodoPago == metodo;
  }

  /// True si el pedido tiene algún pago por transferencia (para mostrar ícono clickeable).
  bool _tieneTransferencia(Pedido p) => _matchesFiltro(p, PaymentMethod.transferencia);

  int _contarTransferencias() {
    return _obtenerPedidosDelRango()
        .where(
          (p) =>
              !p.cancelado &&
              p.estado == OrderStatus.cerrados &&
              p.estadoPago == PaymentStatus.cobrado &&
              _matchesFiltro(p, PaymentMethod.transferencia),
        )
        .length;
  }

  int _contarEfectivo() {
    return _obtenerPedidosDelRango()
        .where(
          (p) =>
              !p.cancelado &&
              p.estado == OrderStatus.cerrados &&
              p.estadoPago == PaymentStatus.cobrado &&
              _matchesFiltro(p, PaymentMethod.efectivo),
        )
        .length;
  }

  List<Pedido> _obtenerPedidosFiltrados() {
    // Solo mostrar pedidos cerrados y cobrados (no cancelados)
    var pedidosFiltrados =
        _obtenerPedidosDelRango()
            .where(
              (p) =>
                  !p.cancelado &&
                  p.estado == OrderStatus.cerrados &&
                  p.estadoPago == PaymentStatus.cobrado,
            )
            .toList();

    // Aplicar filtro por método de pago si está activo
    if (_filtroMetodoPago != null) {
      pedidosFiltrados =
          pedidosFiltrados
              .where((p) => _matchesFiltro(p, _filtroMetodoPago!))
              .toList();
    }

    // Ordenar por fecha más reciente primero
    pedidosFiltrados.sort((a, b) => b.fecha.compareTo(a.fecha));

    // Calcular índices para paginación
    final inicio = (_paginaActual - 1) * _itemsPerPage;
    final fin = inicio + _itemsPerPage;

    // Retornar solo los items de la página actual
    if (inicio >= pedidosFiltrados.length) {
      return [];
    }
    return pedidosFiltrados.sublist(
      inicio,
      fin > pedidosFiltrados.length ? pedidosFiltrados.length : fin,
    );
  }

  int _calcularTotalPaginas() {
    // Solo contar pedidos cerrados y cobrados (no cancelados)
    var totalPedidos =
        _obtenerPedidosDelRango()
            .where(
              (p) =>
                  !p.cancelado &&
                  p.estado == OrderStatus.cerrados &&
                  p.estadoPago == PaymentStatus.cobrado,
            )
            .toList();

    // Aplicar filtro por método de pago si está activo
    if (_filtroMetodoPago != null) {
      totalPedidos =
          totalPedidos.where((p) => _matchesFiltro(p, _filtroMetodoPago!)).toList();
    }

    return (totalPedidos.length / _itemsPerPage).ceil();
  }

  void _mostrarDetallePedido(BuildContext context, Pedido pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailModal(pedido: pedido),
    );
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
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
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
    final transferencias = _contarTransferencias();
    final efectivo = _contarEfectivo();
    final pedidosFiltrados = _obtenerPedidosFiltrados();
    // Calcular total de pedidos cerrados y cobrados (filtrados por método de pago si aplica)
    var totalPedidosFiltrados =
        _obtenerPedidosDelRango()
            .where(
              (p) =>
                  !p.cancelado &&
                  p.estado == OrderStatus.cerrados &&
                  p.estadoPago == PaymentStatus.cobrado,
            )
            .toList();

    if (_filtroMetodoPago != null) {
      totalPedidosFiltrados =
          totalPedidosFiltrados
              .where((p) => _matchesFiltro(p, _filtroMetodoPago!))
              .toList();
    }

    final totalPedidosFiltradosCount = totalPedidosFiltrados.length;
    final totalPaginas = _calcularTotalPaginas();

    // Asegurar que la página actual no exceda el total de páginas
    if (_paginaActual > totalPaginas && totalPaginas > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _paginaActual = totalPaginas;
        });
      });
    }

    return Column(
      children: [
        // Contenido scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de fecha
                DateFilterWidget(
                  fechaInicio: _fechaInicio,
                  fechaFin: _fechaFin,
                  onFechasChanged: _onFechasChanged,
                ),
                const SizedBox(height: AppConstants.spacingMedium),

                // Paneles de información principales
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
                      child: FilterableInfoPanel(
                        title: 'Pedidos',
                        value: '$totalPedidos',
                        icon: Icons.receipt_long,
                        color: AppColors.accent,
                        isSelected: _filtroMetodoPago == null,
                        onTap: () {
                          setState(() {
                            _filtroMetodoPago = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMedium),

                // Cards de métodos de pago (filtros)
                Row(
                  children: [
                    Expanded(
                      child: FilterableInfoPanel(
                        title: 'Transferencias',
                        value: '$transferencias',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFF64B5F6), // Azul claro
                        isSelected: _filtroMetodoPago == PaymentMethod.transferencia,
                        onTap: () {
                          setState(() {
                            _filtroMetodoPago =
                                _filtroMetodoPago == PaymentMethod.transferencia
                                    ? null
                                    : PaymentMethod.transferencia;
                            _paginaActual =
                                1; // Resetear a la primera página cuando cambia el filtro
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMedium),
                    Expanded(
                      child: FilterableInfoPanel(
                        title: 'Efectivo',
                        value: '$efectivo',
                        icon: Icons.money,
                        color: const Color(0xFF81C784), // Verde claro
                        isSelected: _filtroMetodoPago == PaymentMethod.efectivo,
                        onTap: () {
                          setState(() {
                            _filtroMetodoPago =
                                _filtroMetodoPago == PaymentMethod.efectivo
                                    ? null
                                    : PaymentMethod.efectivo;
                            _paginaActual =
                                1; // Resetear a la primera página cuando cambia el filtro
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingLarge),

                // Lista de pedidos
                if (pedidosFiltrados.isEmpty)
                  Card(
                    elevation: AppConstants.cardElevation,
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filtroMetodoPago != null
                                  ? 'No hay pedidos con $_filtroMetodoPago'
                                  : 'No hay pedidos',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...pedidosFiltrados.map(
                    (pedido) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.spacingMedium,
                      ),
                      child: Card(
                        elevation: AppConstants.cardElevation,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusLarge,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _mostrarDetallePedido(context, pedido),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusLarge,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingMedium,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con número de orden y cliente
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '#${pedido.numeroOrden}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        pedido.cliente,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Información del pedido
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(pedido.fecha),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${pedido.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.price,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Método de pago y estado
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Botón de método de pago (clickeable si tiene algún pago por transferencia)
                                    if (_tieneTransferencia(pedido))
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            barrierColor: Colors.black
                                                .withValues(alpha: 0.7),
                                            builder:
                                                (context) =>
                                                    TransferPhotoViewerModal(
                                                      pedido: pedido,
                                                    ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF64B5F6,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF64B5F6),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.account_balance_wallet,
                                                size: 14,
                                                color: Color(0xFF64B5F6),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Transferencia',
                                                style: TextStyle(
                                                  color: Color(0xFF64B5F6),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF81C784,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF81C784),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.money,
                                              size: 14,
                                              color: Color(0xFF81C784),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Efectivo',
                                              style: TextStyle(
                                                color: Color(0xFF81C784),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.success,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            pedido.estado.displayName,
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Controles de paginación
        PaginationControls(
          itemsPerPage: _itemsPerPage,
          currentPage: totalPaginas > 0 ? _paginaActual : 1,
          totalPages: totalPaginas,
          totalItems: totalPedidosFiltradosCount,
          onItemsPerPageChanged: (int nuevoValor) {
            setState(() {
              _itemsPerPage = nuevoValor;
              _paginaActual = 1; // Resetear a la primera página
            });
          },
          onPageChanged: (int nuevaPagina) {
            setState(() {
              _paginaActual = nuevaPagina;
            });
          },
        ),
      ],
    );
  }
}
