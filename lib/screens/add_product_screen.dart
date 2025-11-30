import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/product_form_widget.dart';

class AddProductScreen extends StatefulWidget {
  final Producto? producto;

  const AddProductScreen({
    super.key,
    this.producto,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _isSaving = false;

  Future<void> _guardarProducto(Producto producto) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final error = producto.validar();
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

      if (producto.id == null) {
        await ProductoService.guardar(producto);
      } else {
        await ProductoService.actualizar(producto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado exitosamente'),
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
      appBar: BackHeaderWidget(
        title: widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : ProductFormWidget(
              producto: widget.producto,
              onSave: _guardarProducto,
            ),
    );
  }
}

