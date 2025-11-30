import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/producto_service.dart';
import '../services/pedido_service.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/order_form_widget.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
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

  Future<void> _guardarPedido(Pedido pedido) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final error = pedido.validar();
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      await PedidoService.guardar(pedido);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido guardado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Nuevo Pedido'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _isSaving
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : productos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: Colors.white38),
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
                      onSave: _guardarPedido,
                    ),
    );
  }
}

