import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/producto_seleccionado.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class OrderFormProductList extends StatelessWidget {
  final List<ProductoSeleccionado> productosSeleccionados;
  final ValueChanged<String> onIncrementar;
  final ValueChanged<String> onDecrementar;
  final ValueChanged<String> onEditar;
  final ValueChanged<String> onEliminar;

  const OrderFormProductList({
    super.key,
    required this.productosSeleccionados,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEditar,
    required this.onEliminar,
  });

  /// Agrupa productos por configuración (mismo producto, variante, acompañantes, extras)
  String _obtenerClaveAgrupacion(ProductoSeleccionado producto) {
    final acompanantesKey = producto.acompanantes
        .map((a) => '${a.nombre}:${a.cantidad}')
        .join(',');
    final extrasKey = producto.extrasNombres.join(',');
    return '${producto.productoId}_${producto.varianteNombre ?? 'base'}_${acompanantesKey}_$extrasKey';
  }

  /// Obtiene productos agrupados con sus cantidades
  Map<String, Map<String, dynamic>> _obtenerProductosAgrupados() {
    final grupos = <String, List<ProductoSeleccionado>>{};

    for (final producto in productosSeleccionados) {
      final clave = _obtenerClaveAgrupacion(producto);
      if (!grupos.containsKey(clave)) {
        grupos[clave] = [];
      }
      grupos[clave]!.add(producto);
    }

    return grupos.map((clave, productos) {
      final primera = productos.first;
      final cantidad = productos.length;
      return MapEntry(clave, {
        'producto': primera,
        'cantidad': cantidad,
        'instancias': productos,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (productosSeleccionados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Center(
          child: Text(
            'Carrito vacío',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    final grupos = _obtenerProductosAgrupados();
    return Column(
      children:
          grupos.entries.map((entry) {
            final claveAgrupacion = entry.key;
            final grupo = entry.value;
            final productoSeleccionado =
                grupo['producto'] as ProductoSeleccionado;
            final cantidad = grupo['cantidad'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
              child: Slidable(
                key: ValueKey<String>(claveAgrupacion),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) => onEliminar(claveAgrupacion),
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outline,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppConstants.borderRadius),
                        bottomRight: Radius.circular(AppConstants.borderRadius),
                      ),
                      flex: 1,
                    ),
                  ],
                ),
                child: Card(
                  color: AppColors.cardBackground,
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadius),
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onEditar(claveAgrupacion),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadius),
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      productoSeleccionado.nombreProducto,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (cantidad > 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'x$cantidad',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(productoSeleccionado.precioUnitario * cantidad).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.price,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (productoSeleccionado.varianteNombre != null ||
                              productoSeleccionado.acompanantes.isNotEmpty ||
                              productoSeleccionado
                                  .extrasNombres
                                  .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            if (productoSeleccionado.varianteNombre != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      productoSeleccionado.varianteNombre!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (productoSeleccionado.acompanantes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        productoSeleccionado.acompanantes
                                            .map((a) => a.nombre)
                                            .join(', '),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (productoSeleccionado.extrasNombres.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        productoSeleccionado.extrasNombres.join(
                                          ', ',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          // Contador de cantidad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => onDecrementar(claveAgrupacion),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$cantidad',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => onIncrementar(claveAgrupacion),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
