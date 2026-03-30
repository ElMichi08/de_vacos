import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../services/producto_service.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/order_form_widget.dart';

class EditOrderScreen extends StatefulWidget {
  final Pedido pedido;

  const EditOrderScreen({super.key, required this.pedido});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Producto> productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final lista = await ProductoService.obtenerTodos();
      setState(() {
        productos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _actualizarPedido(Pedido pedidoActualizado) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final error = pedidoActualizado.validar();
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Crear pedido actualizado manteniendo el id y número de orden original
      final pedidoParaActualizar = Pedido(
        id: widget.pedido.id,
        numeroOrden: widget.pedido.numeroOrden,
        cliente: pedidoActualizado.cliente,
        celular: pedidoActualizado.celular,
        metodoPago: pedidoActualizado.metodoPago,
        estado: widget.pedido.estado, // Mantener el estado actual
        estadoPago:
            widget.pedido.estadoPago, // Mantener el estado de pago actual
        productos: pedidoActualizado.productos,
        fecha: widget.pedido.fecha, // Mantener la fecha original
        total: pedidoActualizado.total,
        envasesLlevar: pedidoActualizado.envasesLlevar,
        notas: pedidoActualizado.notas,
        cancelado: widget.pedido.cancelado,
        fotoTransferenciaPath: widget.pedido.fotoTransferenciaPath,
      );

      await PedidoService.actualizar(pedidoParaActualizar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validar que el pedido no esté cerrado ni cancelado
    if (widget.pedido.estado == 'Cerrados' ||
        widget.pedido.estado == 'Cancelada' ||
        widget.pedido.cancelado) {
      // Si intenta editar un pedido cerrado o cancelado, mostrar error y volver
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pueden editar pedidos cerrados o cancelados'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      });

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeaderWidget(title: 'Editar Pedido'),
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Editar Pedido'),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
              : _isSaving
              ? Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
              : productos.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.white38,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay productos disponibles',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Agrega productos primero',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              )
              : OrderFormWidget(
                productos: productos,
                pedido: widget.pedido, // Pasar el pedido para edición
                onSave: _actualizarPedido,
              ),
    );
  }
}
