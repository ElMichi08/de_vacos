import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/producto_variante.dart';
import '../models/producto_seleccionado.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class OrderFormDialogContent extends StatefulWidget {
  final Producto producto;
  final ProductoSeleccionado? productoSeleccionadoExistente;

  const OrderFormDialogContent({
    super.key,
    required this.producto,
    this.productoSeleccionadoExistente,
  });

  @override
  State<OrderFormDialogContent> createState() => _OrderFormDialogContentState();
}

class _OrderFormDialogContentState extends State<OrderFormDialogContent> {
  ProductoVariante? varianteSeleccionada;
  final Map<String, int> acompanantesCantidades = {}; // nombre -> cantidad
  final Map<String, double> preciosAcompanantes =
      {}; // nombre -> precio adicional
  String? extraSeleccionado; // Solo un extra seleccionado
  final Map<String, double> preciosExtras = {};
  String? mensajeError; // Mensaje de error a mostrar

  @override
  void initState() {
    super.initState();
    _cargarDatosExistentes();
  }

  void _cargarDatosExistentes() {
    if (widget.productoSeleccionadoExistente != null) {
      final existente = widget.productoSeleccionadoExistente!;
      // Cargar variante
      if (existente.varianteNombre != null && widget.producto.tieneVariantes) {
        varianteSeleccionada = widget.producto.variantes!.firstWhere(
          (v) => v.nombre == existente.varianteNombre,
          orElse: () => widget.producto.variantes!.first,
        );
      }

      // Cargar acompañantes (suma debe ser igual a la cantidad de cortes)
      for (final acompananteSel in existente.acompanantes) {
        acompanantesCantidades[acompananteSel.nombre] = acompananteSel.cantidad;
        preciosAcompanantes[acompananteSel.nombre] =
            acompananteSel.precioAdicional;
      }

      // Cargar extra (solo uno)
      if (existente.extrasNombres.isNotEmpty) {
        final extraNombre = existente.extrasNombres.first;
        extraSeleccionado = extraNombre;
        if (widget.producto.tieneExtras) {
          final extra = widget.producto.extras!.firstWhere(
            (e) => e.nombre == extraNombre,
            orElse: () => widget.producto.extras!.first,
          );
          preciosExtras[extraNombre] = extra.precioAdicional;
        }
      }
    } else {
      // Si es un producto nuevo y tiene extras, seleccionar el primero automáticamente
      if (widget.producto.tieneExtras && widget.producto.extras!.isNotEmpty) {
        final primerExtra = widget.producto.extras!.first;
        extraSeleccionado = primerExtra.nombre;
        preciosExtras[primerExtra.nombre] = primerExtra.precioAdicional;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      title: Text(
        producto.nombre,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selección de variante (chips deslizables horizontales)
            if (producto.tieneVariantes) ...[
              const Text(
                'Tamaño/Porción:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      producto.variantes!.map((variante) {
                        final isSelected = varianteSeleccionada == variante;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variante.nombre,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '\$${variante.precio.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColors.price,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                varianteSeleccionada = variante;
                                // Limpiar acompañantes cuando cambia la variante
                                acompanantesCantidades.clear();
                                preciosAcompanantes.clear();
                              });
                            },
                            selectedColor: AppColors.accent,
                            checkmarkColor: Colors.white,
                            backgroundColor: AppColors.background,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.accent
                                      : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Selección de acompañantes con contadores (cantidad = cantidad de cortes)
            if (producto.tieneAcompanantes) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Acompañantes:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final cantidadCortes =
                          varianteSeleccionada != null
                              ? int.tryParse(
                                    varianteSeleccionada!.nombre
                                        .split(' ')
                                        .first,
                                  ) ??
                                  1
                              : 1;
                      final totalAcompanantes = acompanantesCantidades.values
                          .fold<int>(0, (sum, cant) => sum + cant);
                      final isValid = totalAcompanantes == cantidadCortes;
                      if (totalAcompanantes == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isValid
                                  ? AppColors.successDark.withValues(alpha: 0.2)
                                  : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isValid
                                    ? AppColors.successDark
                                    : AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isValid ? Icons.check_circle : Icons.warning,
                              size: 14,
                              color:
                                  isValid
                                      ? AppColors.successDark
                                      : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalAcompanantes/$cantidadCortes',
                              style: TextStyle(
                                color:
                                    isValid
                                        ? AppColors.successDark
                                        : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...producto.acompanantes!.map((acompanante) {
                final cantidadActual =
                    acompanantesCantidades[acompanante.nombre] ?? 0;
                return Card(
                  color: AppColors.background,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acompanante.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                acompanante.precioAdicional > 0
                                    ? '+\$${acompanante.precioAdicional.toStringAsFixed(2)}'
                                    : 'Gratis',
                                style: TextStyle(
                                  color:
                                      acompanante.precioAdicional > 0
                                          ? AppColors.price
                                          : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed:
                                  cantidadActual > 0
                                      ? () {
                                        setState(() {
                                          if (cantidadActual > 1) {
                                            acompanantesCantidades[acompanante
                                                    .nombre] =
                                                cantidadActual - 1;
                                          } else {
                                            acompanantesCantidades.remove(
                                              acompanante.nombre,
                                            );
                                            preciosAcompanantes.remove(
                                              acompanante.nombre,
                                            );
                                          }
                                        });
                                      }
                                      : null,
                            ),
                            Text(
                              '$cantidadActual',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final cantidadCortes =
                                    varianteSeleccionada != null
                                        ? int.tryParse(
                                              varianteSeleccionada!.nombre
                                                  .split(' ')
                                                  .first,
                                            ) ??
                                            1
                                        : 1;
                                final totalAcompanantes = acompanantesCantidades
                                    .values
                                    .fold<int>(0, (sum, cant) => sum + cant);
                                final puedeAgregar =
                                    totalAcompanantes < cantidadCortes;
                                return IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed:
                                      puedeAgregar
                                          ? () {
                                            setState(() {
                                              acompanantesCantidades[acompanante
                                                      .nombre] =
                                                  (cantidadActual) + 1;
                                              preciosAcompanantes[acompanante
                                                      .nombre] =
                                                  acompanante.precioAdicional;
                                            });
                                          }
                                          : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // Selección de extras (chips deslizables horizontales - solo uno)
            if (producto.tieneExtras) ...[
              const Text(
                'Extras:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      producto.extras!.map((extra) {
                        final isSelected = extraSeleccionado == extra.nombre;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  extra.nombre,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                if (extra.precioAdicional > 0)
                                  Text(
                                    '+\$${extra.precioAdicional.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppColors.price,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                extraSeleccionado = extra.nombre;
                                preciosExtras.clear();
                                preciosExtras[extra.nombre] =
                                    extra.precioAdicional;
                              });
                            },
                            selectedColor: AppColors.accent,
                            checkmarkColor: Colors.white,
                            backgroundColor: AppColors.background,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.accent
                                      : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        // Mensaje de advertencia (solo se muestra si hay error después de presionar Agregar)
        if (mensajeError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mensajeError!,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Botones
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  side: const BorderSide(color: Colors.white24, width: 1),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // Limpiar mensaje de error anterior
                setState(() {
                  mensajeError = null;
                });

                // Validar que se haya seleccionado una variante si el producto las tiene
                if (producto.tieneVariantes && varianteSeleccionada == null) {
                  setState(() {
                    mensajeError = 'Debes seleccionar un tamaño/porción';
                  });
                  return;
                }

                // Validar acompañantes: la suma debe ser igual a la cantidad de cortes
                if (producto.tieneAcompanantes) {
                  final cantidadCortes =
                      varianteSeleccionada != null
                          ? int.tryParse(
                                varianteSeleccionada!.nombre.split(' ').first,
                              ) ??
                              1
                          : 1;
                  final totalAcompanantes = acompanantesCantidades.values
                      .fold<int>(0, (sum, cant) => sum + cant);
                  if (totalAcompanantes != cantidadCortes) {
                    setState(() {
                      mensajeError =
                          'Debes seleccionar exactamente $cantidadCortes acompañante${cantidadCortes > 1 ? 's' : ''} (actual: $totalAcompanantes)';
                    });
                    return;
                  }
                }

                // Validar extras: deben ser obligatorios si existen
                if (producto.tieneExtras && extraSeleccionado == null) {
                  setState(() {
                    mensajeError = 'Debes seleccionar un extra';
                  });
                  return;
                }

                double precioBase =
                    varianteSeleccionada?.precio ?? producto.precio;
                double precioExtrasTotal = preciosExtras.values.fold(
                  0.0,
                  (sum, precio) => sum + precio,
                );

                // Crear lista de acompañantes seleccionados
                // La cantidad de cada acompañante se mantiene según lo seleccionado
                final acompanantesList =
                    acompanantesCantidades.entries
                        .map(
                          (entry) => AcompananteSeleccionado(
                            nombre: entry.key,
                            precioAdicional:
                                preciosAcompanantes[entry.key] ?? 0.0,
                            cantidad:
                                entry
                                    .value, // Mantener la cantidad seleccionada
                          ),
                        )
                        .toList();

                final productoSeleccionado = ProductoSeleccionado(
                  id: widget.productoSeleccionadoExistente?.id,
                  productoId: producto.id!,
                  nombreProducto: producto.nombre,
                  cantidad: 1, // Siempre 1 por instancia
                  varianteNombre: varianteSeleccionada?.nombre,
                  precioBase: precioBase,
                  acompanantes: acompanantesList,
                  extrasNombres:
                      extraSeleccionado != null ? [extraSeleccionado!] : [],
                  precioExtras: precioExtrasTotal,
                );

                Navigator.pop(context, productoSeleccionado);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Agregar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Muestra un diálogo para configurar un producto con variantes, acompañantes y extras.
/// Retorna null si se cancela, o un ProductoSeleccionado si se confirma.
Future<ProductoSeleccionado?> showOrderFormDialog(
  BuildContext context, {
  required Producto producto,
  ProductoSeleccionado? productoSeleccionadoExistente,
}) {
  return showDialog<ProductoSeleccionado?>(
    context: context,
    builder:
        (context) => OrderFormDialogContent(
          producto: producto,
          productoSeleccionadoExistente: productoSeleccionadoExistente,
        ),
  );
}
