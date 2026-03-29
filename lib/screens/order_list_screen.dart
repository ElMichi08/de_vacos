import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/order_detail_modal.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/payment_modal.dart';
import '../widgets/transfer_payment_modal.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Pedido> pedidos = [];
  bool isLoading = true;
  String? errorMessage;
  String _filtroEstado = 'Todos';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();
  final bool _mostrarFiltroFecha =
      false; // Por defecto colapsado (manejado por DateFilterWidget)

  // Paginación
  int _paginaActual = 1;
  int _tamanoPagina = 20;
  int _totalPedidos = 0;
  int _totalPaginas = 1;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos({bool resetearPagina = false}) async {
    if (resetearPagina) {
      setState(() {
        _paginaActual = 1;
      });
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final resultado =
          _filtroEstado == 'Todos'
              ? await PedidoService.obtenerTodosPaginados(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
                pagina: _paginaActual,
                tamanoPagina: _tamanoPagina,
              )
              : await PedidoService.obtenerPorEstadoPaginados(
                _filtroEstado,
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
                pagina: _paginaActual,
                tamanoPagina: _tamanoPagina,
              );

      setState(() {
        pedidos = resultado['pedidos'] as List<Pedido>;
        _totalPedidos = resultado['total'] as int;
        _totalPaginas = resultado['totalPaginas'] as int;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'En preparación':
        return Colors.blue;
      case 'Despachada':
        return AppColors.success;
      case 'Cerrados':
        return Colors.grey;
      case 'Cancelada':
        return AppColors.error;
      default:
        return Colors.white70;
    }
  }

  Color _getEstadoPagoColor(String estadoPago) {
    return estadoPago == 'Cobrado' ? AppColors.success : Colors.orange;
  }

  /// Cambia el estado del pedido de forma secuencial
  /// En preparación → Despachada → Cerrados
  Future<void> _cambiarEstadoSecuencial(Pedido pedido) async {
    // Validar que el pedido no esté cancelado o cerrado
    if (pedido.estado == 'Cancelada' ||
        pedido.estado == 'Cerrados' ||
        pedido.cancelado) {
      return;
    }

    String nuevoEstado;

    switch (pedido.estado) {
      case 'En preparación':
        nuevoEstado = 'Despachada';
        break;
      case 'Despachada':
        // Validar que el pedido esté cobrado antes de cerrar
        if (pedido.estadoPago != 'Cobrado') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No se puede cerrar un pedido sin cobrar'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        nuevoEstado = 'Cerrados';
        break;
      default:
        return; // No se puede cambiar si ya está en Cerrados o Cancelada
    }

    try {
      await PedidoService.actualizarEstado(pedido.id!, nuevoEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado cambiado a $nuevoEstado'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        _cargarPedidos();
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

  /// Cambia el estado de pago de forma secuencial
  /// Pendiente → Cobrado
  /// Si es efectivo, muestra modal para calcular cambio
  /// Si es transferencia, muestra modal para tomar foto de la transferencia
  Future<void> _cambiarEstadoPagoSecuencial(Pedido pedido) async {
    // Validar que el pedido no esté cancelado o cerrado
    if (pedido.estado == 'Cancelada' ||
        pedido.estado == 'Cerrados' ||
        pedido.cancelado) {
      return;
    }

    if (pedido.estadoPago != 'Pendiente') {
      return; // Solo se puede cambiar si está pendiente
    }

    // Si es efectivo, mostrar modal de cobro con cálculo de cambio
    if (pedido.metodoPago == 'Efectivo') {
      final resultado = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder:
            (context) => PaymentModal(
              totalAPagar: pedido.total,
              cliente: pedido.cliente,
              numeroOrden: pedido.numeroOrden,
            ),
      );

      // Si el usuario confirmó el cobro (retornó true)
      if ((resultado ?? false) && mounted) {
        try {
          await PedidoService.actualizarEstadoPago(pedido.id!, 'Cobrado');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pago registrado correctamente'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
            _cargarPedidos();
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
    } else {
      // Si es transferencia, mostrar modal para tomar foto
      final resultado = await showDialog<Map<String, dynamic>?>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder:
            (context) => TransferPaymentModal(
              totalAPagar: pedido.total,
              cliente: pedido.cliente,
              numeroOrden: pedido.numeroOrden,
            ),
      );

      // Si el usuario confirmó el cobro (retornó Map con cobrado: true y fotoPath)
      if (resultado != null && resultado['cobrado'] == true && mounted) {
        try {
          final fotoPath = resultado['fotoPath'] as String?;
          await PedidoService.actualizarEstadoPago(
            pedido.id!,
            'Cobrado',
            fotoTransferenciaPath: fotoPath,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pago registrado correctamente'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
            _cargarPedidos();
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
    }
  }

  void _mostrarDialogoCancelacion(Pedido pedido) {
    // Validar que el pedido no esté cerrado
    if (pedido.estado == 'Cerrados') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden cancelar pedidos cerrados'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cancelar Pedido',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de cancelar el pedido #${pedido.numeroOrden}?',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los pedidos cancelados no computan para los ingresos',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'No, mantener',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Sí, cancelar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
    ).then((confirmar) {
      if (confirmar ?? false) {
        _cancelarPedido(pedido);
      }
    });
  }

  Future<void> _cancelarPedido(Pedido pedido) async {
    try {
      await PedidoService.cancelar(pedido.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido #${pedido.numeroOrden} cancelado'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        _cargarPedidos();
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

  void _onFechasChanged(DateTime fechaInicio, DateTime fechaFin) {
    setState(() {
      _fechaInicio = fechaInicio;
      _fechaFin = fechaFin;
    });
    _cargarPedidos(resetearPagina: true);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Pedidos'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // En landscape con suficiente ancho, usar layout de dos columnas
          if (isLandscape && constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel lateral con filtros
                Container(
                  width: 280,
                  color: AppColors.cardBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filtro de fecha
                      DateFilterWidget(
                        fechaInicio: _fechaInicio,
                        fechaFin: _fechaFin,
                        onFechasChanged: _onFechasChanged,
                        initiallyExpanded: _mostrarFiltroFecha,
                      ),
                      // Filtros de estado
                      Padding(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        child: const Text(
                          'Filtros',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                          ),
                          child: Column(
                            children:
                                [
                                  'Todos',
                                  'En preparación',
                                  'Despachada',
                                  'Cerrados',
                                  'Canceladas',
                                ].map((estado) {
                                  final isSelected = _filtroEstado == estado;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppConstants.spacingSmall,
                                    ),
                                    child: FilterChip(
                                      label: Text(estado),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _filtroEstado = estado;
                                        });
                                        _cargarPedidos(resetearPagina: true);
                                      },
                                      selectedColor: AppColors.primary,
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                      backgroundColor: AppColors.background,
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de pedidos
                Expanded(child: _buildBody()),
              ],
            );
          }

          // Layout vertical (portrait o landscape pequeño)
          return Column(
            children: [
              // Filtro de fecha
              DateFilterWidget(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
                onFechasChanged: _onFechasChanged,
                initiallyExpanded: _mostrarFiltroFecha,
              ),

              // Filtro de estado con chips
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'Todos',
                          'En preparación',
                          'Despachada',
                          'Cerrados',
                          'Canceladas',
                        ].map((String estado) {
                          final isSelected = _filtroEstado == estado;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppConstants.spacingSmall,
                            ),
                            child: FilterChip(
                              label: Text(estado),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _filtroEstado = estado;
                                });
                                _cargarPedidos(resetearPagina: true);
                              },
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              backgroundColor: AppColors.background,
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.white24,
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              // Lista de pedidos
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/pedidos/nueva');
          if ((result ?? false) && mounted) {
            _cargarPedidos();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

    if (pedidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'No hay pedidos',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Toca el botón + para crear uno',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Lista de pedidos
        Expanded(
          child: ListView.builder(
            key: PageStorageKey<String>(
              'pedidos_list_$_paginaActual$_tamanoPagina',
            ),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              // Usar key estable basado en id para evitar problemas de scroll

              // Solo mostrar acción de cancelar si el pedido NO está cerrado
              final puedeCancelar =
                  pedido.estado != 'Cerrados' &&
                  pedido.estado != 'Cancelada' &&
                  !pedido.cancelado;

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.spacingMedium,
                ),
                child: Slidable(
                  key: ValueKey<int>(pedido.id ?? index),
                  // Acción de cancelar al deslizar hacia la izquierda
                  endActionPane:
                      puedeCancelar
                          ? ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed:
                                    (context) =>
                                        _mostrarDialogoCancelacion(pedido),
                                backgroundColor: const Color(
                                  0xFFC62828,
                                ), // Rojo más sutil
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(
                                    AppConstants.borderRadiusLarge,
                                  ),
                                  bottomRight: Radius.circular(
                                    AppConstants.borderRadiusLarge,
                                  ),
                                ),
                                flex: 1,
                              ),
                            ],
                          )
                          : null,
                  child: Card(
                    key: ValueKey<int>(pedido.id ?? index),
                    elevation: AppConstants.cardElevation,
                    color: AppColors.cardBackground,
                    margin:
                        EdgeInsets
                            .zero, // Sin margen, el padding del Slidable lo maneja
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                        bottomLeft: Radius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        _mostrarDetallePedido(context, pedido);
                      },
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                        bottomLeft: Radius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
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

                                // Estados clickeables
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Badge de estado (clickeable solo si no está cerrado ni cancelado)
                                    InkWell(
                                      onTap:
                                          pedido.estado != 'Cancelada' &&
                                                  pedido.estado != 'Cerrados' &&
                                                  !pedido.cancelado
                                              ? () {
                                                _cambiarEstadoSecuencial(
                                                  pedido,
                                                );
                                              }
                                              : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEstadoColor(
                                            pedido.estado,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getEstadoColor(
                                              pedido.estado,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.restaurant,
                                              size: 14,
                                              color: _getEstadoColor(
                                                pedido.estado,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              pedido.estado,
                                              style: TextStyle(
                                                color: _getEstadoColor(
                                                  pedido.estado,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (pedido.estado != 'Cancelada' &&
                                                pedido.estado != 'Cerrados' &&
                                                !pedido.cancelado) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 10,
                                                color: _getEstadoColor(
                                                  pedido.estado,
                                                ).withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Badge de estado de pago (clickeable solo si no está cancelado ni cerrado)
                                    InkWell(
                                      onTap:
                                          pedido.estadoPago == 'Pendiente' &&
                                                  pedido.estado !=
                                                      'Cancelada' &&
                                                  pedido.estado != 'Cerrados' &&
                                                  !pedido.cancelado
                                              ? () {
                                                _cambiarEstadoPagoSecuencial(
                                                  pedido,
                                                );
                                              }
                                              : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEstadoPagoColor(
                                            pedido.estadoPago,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getEstadoPagoColor(
                                              pedido.estadoPago,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              pedido.estadoPago == 'Cobrado'
                                                  ? Icons.check_circle
                                                  : Icons.pending,
                                              size: 14,
                                              color: _getEstadoPagoColor(
                                                pedido.estadoPago,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              pedido.estadoPago,
                                              style: TextStyle(
                                                color: _getEstadoPagoColor(
                                                  pedido.estadoPago,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (pedido.estadoPago ==
                                                    'Pendiente' &&
                                                pedido.estado != 'Cancelada' &&
                                                pedido.estado != 'Cerrados' &&
                                                !pedido.cancelado) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 10,
                                                color: _getEstadoPagoColor(
                                                  pedido.estadoPago,
                                                ).withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Información de pago y total
                                Row(
                                  children: [
                                    Icon(
                                      pedido.metodoPago == 'Efectivo'
                                          ? Icons.money
                                          : Icons.account_balance_wallet,
                                      size: 16,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pedido.metodoPago,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${pedido.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.price,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // FloatingActionButton circular para editar (esquina superior derecha)
                          // Solo se muestra si el pedido no está cerrado ni cancelado
                          if (pedido.estado != 'Cerrados' &&
                              pedido.estado != 'Cancelada')
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    final result = await context.push<bool>(
                                      '/pedidos/${pedido.id}/editar',
                                      extra: pedido,
                                    );
                                    if ((result ?? false) && mounted) {
                                      _cargarPedidos();
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Controles de paginación inferior
        _buildPaginacionControls(),
      ],
    );
  }

  void _mostrarDetallePedido(BuildContext context, Pedido pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailModal(pedido: pedido),
    );
  }

  Widget _buildPaginacionControls() {
    return PaginationControls(
      itemsPerPage: _tamanoPagina,
      currentPage: _paginaActual,
      totalPages: _totalPaginas,
      totalItems: _totalPedidos,
      onItemsPerPageChanged: (int nuevoTamano) {
        setState(() {
          _tamanoPagina = nuevoTamano;
          _paginaActual = 1;
        });
        _cargarPedidos();
      },
      onPageChanged: (int nuevaPagina) {
        setState(() {
          _paginaActual = nuevaPagina;
        });
        _cargarPedidos();
      },
    );
  }
}
