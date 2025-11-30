import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/order_detail_modal.dart';
import 'new_order_screen.dart';
import 'edit_order_screen.dart';

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
  bool _mostrarFiltroFecha = false; // Por defecto colapsado
  
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
      final resultado = _filtroEstado == 'Todos'
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
    
    try {
      await PedidoService.actualizarEstadoPago(pedido.id!, 'Cobrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado de pago cambiado a Cobrado'),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
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
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 18),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ).then((confirmar) {
    if (confirmar == true) {
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

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
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
        _fechaInicio = fecha;
        _fechaFin = fecha;
      });
      _cargarPedidos(resetearPagina: true);
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
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

    if (fechaInicio != null) {
      if (!mounted) return;
      final fechaFin = await showDatePicker(
        context: context,
        initialDate: _fechaFin.isBefore(fechaInicio) ? fechaInicio : _fechaFin,
        firstDate: fechaInicio,
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

      if (fechaFin != null) {
        setState(() {
          _fechaInicio = fechaInicio;
          _fechaFin = fechaFin;
        });
        _cargarPedidos(resetearPagina: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white12, width: 1),
                          ),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          childrenPadding: EdgeInsets.zero,
                          initiallyExpanded: _mostrarFiltroFecha,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _mostrarFiltroFecha = expanded;
                            });
                          },
                          title: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fechaInicio.year == _fechaFin.year &&
                                          _fechaInicio.month == _fechaFin.month &&
                                          _fechaInicio.day == _fechaFin.day
                                      ? DateFormat('dd/MM/yyyy').format(_fechaInicio)
                                      : '${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          iconColor: Colors.white70,
                          collapsedIconColor: Colors.white70,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppConstants.paddingMedium),
                              child: Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _seleccionarFecha,
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: const Text('Día', style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(color: Colors.white24, width: 1.5),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      minimumSize: const Size(double.infinity, 0),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _seleccionarRangoFechas,
                                    icon: const Icon(Icons.date_range, size: 18),
                                    label: const Text('Rango', style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(color: Colors.white24, width: 1.5),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      minimumSize: const Size(double.infinity, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filtros de estado
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                          child: Column(
                            children: ['Todos', 'En preparación', 'Despachada', 'Cerrados', 'Canceladas'].map((estado) {
                              final isSelected = _filtroEstado == estado;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
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
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: AppColors.background,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.white24,
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
                Expanded(
                  child: _buildBody(),
                ),
              ],
            );
          }
          
          // Layout vertical (portrait o landscape pequeño)
          return Column(
            children: [
              // Filtro de fecha
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingSmall,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  initiallyExpanded: _mostrarFiltroFecha,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _mostrarFiltroFecha = expanded;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fechaInicio.year == _fechaFin.year &&
                                  _fechaInicio.month == _fechaFin.month &&
                                  _fechaInicio.day == _fechaFin.day
                              ? DateFormat('dd/MM/yyyy').format(_fechaInicio)
                              : '${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: _fechaInicio.year == _fechaFin.year &&
                          _fechaInicio.month == _fechaFin.month &&
                          _fechaInicio.day == _fechaFin.day
                      ? null
                      : const Text(
                          'Rango de fechas',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                  iconColor: Colors.white70,
                  collapsedIconColor: Colors.white70,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingMedium,
                        AppConstants.paddingSmall,
                        AppConstants.paddingMedium,
                        AppConstants.paddingMedium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _seleccionarFecha,
                              icon: const Icon(Icons.calendar_today, size: 20),
                              label: const Text(
                                'Día',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white24, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _seleccionarRangoFechas,
                              icon: const Icon(Icons.date_range, size: 20),
                              label: const Text(
                                'Rango',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white24, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Filtro de estado con chips
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'En preparación', 'Despachada', 'Cerrados', 'Canceladas']
                        .map((String estado) {
                      final isSelected = _filtroEstado == estado;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.spacingSmall),
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
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: AppColors.background,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.white24,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Lista de pedidos
              Expanded(
                child: _buildBody(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewOrderScreen()),
          );
          if (result == true) {
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
            key: PageStorageKey<String>('pedidos_list_$_paginaActual$_tamanoPagina'),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
              // Usar key estable basado en id para evitar problemas de scroll
              
              // Solo mostrar acción de cancelar si el pedido NO está cerrado
              final puedeCancelar = pedido.estado != 'Cerrados' && 
                                    pedido.estado != 'Cancelada' && 
                                    !pedido.cancelado;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
                child: Slidable(
                  key: ValueKey<int>(pedido.id ?? index),
                  // Acción de cancelar al deslizar hacia la izquierda
                  endActionPane: puedeCancelar
                      ? ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) => _mostrarDialogoCancelacion(pedido),
                              backgroundColor: const Color(0xFFC62828), // Rojo más sutil
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(AppConstants.borderRadiusLarge),
                                bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
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
                    margin: EdgeInsets.zero, // Sin margen, el padding del Slidable lo maneja
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                        bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                      ),
                    ),
                  child: InkWell(
                    onTap: () {
                      _mostrarDetallePedido(context, pedido);
                    },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                      bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con número de orden y cliente
                          Row(
              children: [
                Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                onTap: pedido.estado != 'Cancelada' && 
                                       pedido.estado != 'Cerrados' && 
                                       !pedido.cancelado
                                    ? () {
                                        _cambiarEstadoSecuencial(pedido);
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(pedido.estado).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getEstadoColor(pedido.estado),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        size: 14,
                                        color: _getEstadoColor(pedido.estado),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                        pedido.estado,
                        style: TextStyle(
                          color: _getEstadoColor(pedido.estado),
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
                                          color: _getEstadoColor(pedido.estado).withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // Badge de estado de pago (clickeable solo si no está cancelado ni cerrado)
                              InkWell(
                                onTap: pedido.estadoPago == 'Pendiente' && 
                                       pedido.estado != 'Cancelada' && 
                                       pedido.estado != 'Cerrados' && 
                                       !pedido.cancelado
                                    ? () {
                                        _cambiarEstadoPagoSecuencial(pedido);
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoPagoColor(pedido.estadoPago).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getEstadoPagoColor(pedido.estadoPago),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        pedido.estadoPago == 'Cobrado' ? Icons.check_circle : Icons.pending,
                                        size: 14,
                                        color: _getEstadoPagoColor(pedido.estadoPago),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                        pedido.estadoPago,
                        style: TextStyle(
                          color: _getEstadoPagoColor(pedido.estadoPago),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                                      if (pedido.estadoPago == 'Pendiente' && 
                                          pedido.estado != 'Cancelada' && 
                                          pedido.estado != 'Cerrados' && 
                                          !pedido.cancelado) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 10,
                                          color: _getEstadoPagoColor(pedido.estadoPago).withValues(alpha: 0.7),
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
                                pedido.metodoPago == 'Efectivo' ? Icons.money : Icons.account_balance_wallet,
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
                    if (pedido.estado != 'Cerrados' && pedido.estado != 'Cancelada')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditOrderScreen(pedido: pedido),
                                ),
                              );
                              if (result == true) {
                                _cargarPedidos();
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selector de tamaño de página - a la izquierda
            PopupMenuButton<int>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_tamanoPagina',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => [10, 20, 50, 100].map((int value) {
                return PopupMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value por página',
                    style: TextStyle(
                      color: value == _tamanoPagina ? AppColors.accent : Colors.white,
                      fontWeight: value == _tamanoPagina ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onSelected: (int nuevoTamano) {
                setState(() {
                  _tamanoPagina = nuevoTamano;
                  _paginaActual = 1;
                });
                _cargarPedidos();
              },
            ),
            
            // Botones de navegación y información centrada
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón anterior
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: _paginaActual > 1
                        ? () {
                            setState(() {
                              _paginaActual--;
                            });
                            _cargarPedidos();
                          }
                        : null,
                    tooltip: 'Anterior',
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Información de paginación - en el centro
                  Text(
                    '$_paginaActual de $_totalPaginas • $_totalPedidos pedidos',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botón siguiente
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: _paginaActual < _totalPaginas
                        ? () {
                            setState(() {
                              _paginaActual++;
                            });
                            _cargarPedidos();
                          }
                        : null,
                    tooltip: 'Siguiente',
                  ),
                ],
              ),
            ),
            
            // Espacio para compensar el selector de la izquierda y evitar solapamiento con FAB
            const SizedBox(width: 56), // Ancho aproximado del selector
          ],
        ),
      ),
    );
  }

}
