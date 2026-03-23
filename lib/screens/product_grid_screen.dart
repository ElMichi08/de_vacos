import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/producto_service.dart';
import '../models/producto.dart';
import '../widgets/back_header_widget.dart';

class ProductGridScreen extends StatefulWidget {
  const ProductGridScreen({super.key});

  @override
  State<ProductGridScreen> createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  List<Producto> productos = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final lista = await ProductoService.obtenerTodos();
      setState(() {
        productos = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Productos'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/productos/nuevo');
          if ((result ?? false) && mounted) {
            _cargarProductos();
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
      return _buildErrorView();
    }

    if (productos.isEmpty) {
      return _buildEmptyView();
    }

    return _buildGridView();
  }

  Widget _buildErrorView() {
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
            onPressed: _cargarProductos,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'No hay productos',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar uno',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final isTablet = constraints.maxWidth > 600;

        // En landscape o tablets grandes, usar grid de 2 columnas
        if (isLandscape || isTablet) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  isLandscape && constraints.maxWidth > 1000 ? 3 : 2,
              crossAxisSpacing: AppConstants.spacingMedium,
              mainAxisSpacing: AppConstants.spacingMedium,
              childAspectRatio: isLandscape ? 2.5 : 2.0,
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              return _buildProductCard(productos[index], index);
            },
          );
        }

        // En portrait móvil, usar lista
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            return _buildProductCard(productos[index], index);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Producto producto, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      child: Slidable(
        key: ValueKey<int>(producto.id ?? index),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _mostrarDialogoEliminacion(producto),
              backgroundColor: const Color(
                0xFFC62828,
              ), // Mismo color que pedidos
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
                bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
              flex: 1,
            ),
          ],
        ),
        child: Card(
          elevation: AppConstants.cardElevation,
          color: AppColors.cardBackground,
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
            leading: Icon(Icons.restaurant, color: AppColors.accent, size: 32),
            title: Text(
              producto.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '\$${producto.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.price,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
            onTap: () async {
              final result = await context.push<bool>(
                '/productos/editar/${producto.id}',
                extra: producto,
              );
              if ((result ?? false) && mounted) {
                _cargarProductos();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoEliminacion(Producto producto) async {
    if (!mounted) return;

    final confirmar = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Eliminar producto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué deseas hacer con "${producto.nombre}"?',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Desactivar: El producto se ocultará pero se mantendrá en el sistema (el ID no se reutilizará)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Eliminar permanentemente: El producto se borrará completamente (acción irreversible)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('desactivar'),
                child: const Text(
                  'Desactivar',
                  style: TextStyle(color: Colors.orange, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
    );

    if (!mounted || confirmar == null) return;

    if (confirmar == 'desactivar') {
      await _desactivarProducto(producto);
    } else if (confirmar == 'eliminar') {
      await _eliminarProducto(producto);
    }
  }

  Future<void> _desactivarProducto(Producto producto) async {
    try {
      await ProductoService.desactivar(producto.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${producto.nombre}" desactivado'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        _cargarProductos();
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

  Future<void> _eliminarProducto(Producto producto) async {
    if (!mounted) return;

    // Esperar un momento para asegurar que el diálogo anterior se cerró completamente
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Confirmación adicional para eliminación permanente
    final confirmarEliminacion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Confirmar eliminación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar permanentemente "${producto.nombre}"?\n\nEsta acción no se puede deshacer y el ID del producto se perderá.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Sí, eliminar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
    );

    if (!mounted || confirmarEliminacion != true) return;

    try {
      await ProductoService.eliminar(producto.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Producto "${producto.nombre}" eliminado permanentemente',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        _cargarProductos();
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
