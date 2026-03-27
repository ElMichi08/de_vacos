import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../models/producto_variante.dart';
import '../models/producto_seleccionado.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class OrderFormWidget extends StatefulWidget {
  final List<Producto> productos;
  final Function(Pedido) onSave;
  final Pedido? pedido; // Pedido opcional para edición

  const OrderFormWidget({
    super.key,
    required this.productos,
    required this.onSave,
    this.pedido, // Opcional: si se proporciona, se usa para edición
  });

  @override
  State<OrderFormWidget> createState() => _OrderFormWidgetState();
}

class _OrderFormWidgetState extends State<OrderFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _celularController = TextEditingController();
  final _notasController = TextEditingController();
  String _metodoPago = 'Efectivo';
  int _envasesLlevar = 0;
  // Lista de instancias de productos seleccionados
  // Permite múltiples instancias del mismo producto con diferentes configuraciones
  final List<ProductoSeleccionado> _productosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    // Si hay un pedido para editar, cargar sus datos
    if (widget.pedido != null) {
      _cargarDatosPedido(widget.pedido!);
    }
  }

  void _cargarDatosPedido(Pedido pedido) {
    _clienteController.text = pedido.cliente;
    _celularController.text = pedido.celular;
    _metodoPago = pedido.metodoPago;
    _envasesLlevar = pedido.envasesLlevar;
    _notasController.text = pedido.notas;

    // Cargar productos seleccionados
    // Expandir productos con cantidad > 1 en múltiples instancias individuales
    for (final productoPedido in pedido.productos) {
      final productoSeleccionado = ProductoSeleccionado.fromMap(productoPedido);
      final cantidad = productoSeleccionado.cantidad;

      // Si cantidad es 1, agregar directamente
      if (cantidad == 1) {
        _productosSeleccionados.add(productoSeleccionado);
      } else {
        // Si cantidad > 1, crear múltiples instancias (una por cada unidad)
        // Cada instancia mantiene la misma configuración (variante, acompañantes, extras)
        // Distribuir acompañantes de manera que la suma total se mantenga correctamente

        // Pre-calcular la distribución de acompañantes para cada instancia
        // Usar índice en lugar de nombre para evitar colisiones cuando hay acompañantes duplicados
        final acompanantesDistribuidos = <int, List<int>>{};
        for (
          int acompananteIndex = 0;
          acompananteIndex < productoSeleccionado.acompanantes.length;
          acompananteIndex++
        ) {
          final acompanante =
              productoSeleccionado.acompanantes[acompananteIndex];
          final totalCantidad = acompanante.cantidad;
          final cantidadBase =
              totalCantidad ~/ cantidad; // División entera (floor)
          final resto = totalCantidad % cantidad; // Resto a distribuir

          // Distribuir: las primeras 'resto' instancias reciben cantidadBase + 1
          // las restantes reciben cantidadBase
          final distribucion = List<int>.generate(cantidad, (index) {
            return index < resto ? cantidadBase + 1 : cantidadBase;
          });
          acompanantesDistribuidos[acompananteIndex] = distribucion;
        }

        // Crear las instancias con acompañantes distribuidos correctamente
        for (int i = 0; i < cantidad; i++) {
          _productosSeleccionados.add(
            ProductoSeleccionado(
              productoId: productoSeleccionado.productoId,
              nombreProducto: productoSeleccionado.nombreProducto,
              cantidad: 1, // Cada instancia es cantidad 1
              varianteNombre: productoSeleccionado.varianteNombre,
              precioBase: productoSeleccionado.precioBase,
              acompanantes:
                  productoSeleccionado.acompanantes.asMap().entries.map((
                    entry,
                  ) {
                    final acompananteIndex = entry.key;
                    final acompanante = entry.value;
                    // Obtener la cantidad asignada a esta instancia específica usando el índice
                    final cantidadAsignada =
                        acompanantesDistribuidos[acompananteIndex]?[i] ?? 0;
                    return AcompananteSeleccionado(
                      nombre: acompanante.nombre,
                      precioAdicional: acompanante.precioAdicional,
                      cantidad: cantidadAsignada,
                    );
                  }).toList(),
              extrasNombres: List<String>.from(
                productoSeleccionado.extrasNombres,
              ),
              precioExtras: productoSeleccionado.precioExtras,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _celularController.dispose();
    _notasController.dispose();
    super.dispose();
  }

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

    for (final producto in _productosSeleccionados) {
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

  /// Incrementa la cantidad de un producto agrupado
  void _incrementarCantidadProducto(String claveAgrupacion) {
    final grupo = _obtenerProductosAgrupados()[claveAgrupacion];
    if (grupo == null) return;

    final productoBase = grupo['producto'] as ProductoSeleccionado;
    setState(() {
      // Agregar una nueva instancia
      _productosSeleccionados.add(
        ProductoSeleccionado(
          productoId: productoBase.productoId,
          nombreProducto: productoBase.nombreProducto,
          cantidad: 1,
          varianteNombre: productoBase.varianteNombre,
          precioBase: productoBase.precioBase,
          acompanantes:
              productoBase.acompanantes
                  .map(
                    (a) => AcompananteSeleccionado(
                      nombre: a.nombre,
                      precioAdicional: a.precioAdicional,
                      cantidad: a.cantidad,
                    ),
                  )
                  .toList(),
          extrasNombres: List<String>.from(productoBase.extrasNombres),
          precioExtras: productoBase.precioExtras,
        ),
      );
    });
  }

  /// Decrementa la cantidad de un producto agrupado
  void _decrementarCantidadProducto(String claveAgrupacion) {
    final grupo = _obtenerProductosAgrupados()[claveAgrupacion];
    if (grupo == null) return;

    final instancias = grupo['instancias'] as List<ProductoSeleccionado>;
    if (instancias.length <= 1) {
      // Si solo hay una instancia, eliminar todo el grupo
      _eliminarGrupoProducto(claveAgrupacion);
    } else {
      // Eliminar la última instancia
      setState(() {
        _productosSeleccionados.remove(instancias.last);
      });
    }
  }

  /// Elimina todo un grupo de productos
  void _eliminarGrupoProducto(String claveAgrupacion) {
    final grupo = _obtenerProductosAgrupados()[claveAgrupacion];
    if (grupo == null) return;

    final instancias = grupo['instancias'] as List<ProductoSeleccionado>;
    setState(() {
      for (final instancia in instancias) {
        _productosSeleccionados.removeWhere((p) => p.id == instancia.id);
      }
    });
  }

  /// Edita un grupo de productos (edita la primera instancia y actualiza todas)
  Future<void> _editarGrupoProducto(String claveAgrupacion) async {
    final grupo = _obtenerProductosAgrupados()[claveAgrupacion];
    if (grupo == null) return;

    final productoBase = grupo['producto'] as ProductoSeleccionado;
    final producto = widget.productos.firstWhere(
      (p) => p.id == productoBase.productoId,
    );

    // Mostrar diálogo para editar
    final resultado = await _mostrarDialogoConfigurarProducto(
      producto,
      productoSeleccionadoExistente: productoBase,
    );
    if (resultado != null) {
      final instancias = grupo['instancias'] as List<ProductoSeleccionado>;
      final cantidad = instancias.length;

      setState(() {
        // Eliminar todas las instancias del grupo
        for (final instancia in instancias) {
          _productosSeleccionados.removeWhere((p) => p.id == instancia.id);
        }

        // Agregar nuevas instancias con la configuración editada
        for (int i = 0; i < cantidad; i++) {
          _productosSeleccionados.add(
            ProductoSeleccionado(
              productoId: resultado.productoId,
              nombreProducto: resultado.nombreProducto,
              cantidad: 1,
              varianteNombre: resultado.varianteNombre,
              precioBase: resultado.precioBase,
              acompanantes:
                  resultado.acompanantes
                      .map(
                        (a) => AcompananteSeleccionado(
                          nombre: a.nombre,
                          precioAdicional: a.precioAdicional,
                          cantidad: a.cantidad,
                        ),
                      )
                      .toList(),
              extrasNombres: List<String>.from(resultado.extrasNombres),
              precioExtras: resultado.precioExtras,
            ),
          );
        }
      });
    }
  }

  /// Agrega un producto al pedido, siempre crea una nueva instancia
  /// Muestra diálogo para seleccionar variantes/acompañantes/extras si los tiene
  Future<void> _agregarProducto(Producto producto) async {
    // Si el producto no tiene opciones, agregar directamente
    if (!producto.tieneVariantes &&
        !producto.tieneAcompanantes &&
        !producto.tieneExtras) {
      setState(() {
        _productosSeleccionados.add(
          ProductoSeleccionado(
            productoId: producto.id!,
            nombreProducto: producto.nombre,
            cantidad: 1,
            precioBase: producto.precio,
          ),
        );
      });
      return;
    }

    // Mostrar diálogo para configurar el producto (siempre crea nueva instancia)
    final resultado = await _mostrarDialogoConfigurarProducto(producto);
    if (resultado != null) {
      setState(() {
        _productosSeleccionados.add(resultado);
      });
    }
  }

  /// Muestra un diálogo para configurar un producto con variantes, acompañantes y extras
  /// Siempre configura cantidad = 1 (cada instancia es un plato individual)
  /// Permite editar un producto existente si se proporciona productoSeleccionadoExistente
  Future<ProductoSeleccionado?> _mostrarDialogoConfigurarProducto(
    Producto producto, {
    ProductoSeleccionado? productoSeleccionadoExistente,
  }) async {
    ProductoVariante? varianteSeleccionada;
    final Map<String, int> acompanantesCantidades = {}; // nombre -> cantidad
    final Map<String, double> preciosAcompanantes =
        {}; // nombre -> precio adicional
    String? extraSeleccionado; // Solo un extra seleccionado
    final Map<String, double> preciosExtras = {};
    String? mensajeError; // Mensaje de error a mostrar

    // Si hay un producto existente, cargar sus valores
    if (productoSeleccionadoExistente != null) {
      // Cargar variante
      if (productoSeleccionadoExistente.varianteNombre != null &&
          producto.tieneVariantes) {
        varianteSeleccionada = producto.variantes!.firstWhere(
          (v) => v.nombre == productoSeleccionadoExistente.varianteNombre,
          orElse: () => producto.variantes!.first,
        );
      }

      // Cargar acompañantes (suma debe ser igual a la cantidad de cortes)
      for (final acompananteSel in productoSeleccionadoExistente.acompanantes) {
        acompanantesCantidades[acompananteSel.nombre] = acompananteSel.cantidad;
        preciosAcompanantes[acompananteSel.nombre] =
            acompananteSel.precioAdicional;
      }

      // Cargar extra (solo uno)
      if (productoSeleccionadoExistente.extrasNombres.isNotEmpty) {
        final extraNombre = productoSeleccionadoExistente.extrasNombres.first;
        extraSeleccionado = extraNombre;
        if (producto.tieneExtras) {
          final extra = producto.extras!.firstWhere(
            (e) => e.nombre == extraNombre,
            orElse: () => producto.extras!.first,
          );
          preciosExtras[extraNombre] = extra.precioAdicional;
        }
      }
    } else {
      // Si es un producto nuevo y tiene extras, seleccionar el primero automáticamente
      if (producto.tieneExtras && producto.extras!.isNotEmpty) {
        final primerExtra = producto.extras!.first;
        extraSeleccionado = primerExtra.nombre;
        preciosExtras[primerExtra.nombre] = primerExtra.precioAdicional;
      }
    }

    return showDialog<ProductoSeleccionado?>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusLarge,
                    ),
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
                                    final isSelected =
                                        varianteSeleccionada == variante;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          setDialogState(() {
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
                                  final totalAcompanantes =
                                      acompanantesCantidades.values.fold<int>(
                                        0,
                                        (sum, cant) => sum + cant,
                                      );
                                  final isValid =
                                      totalAcompanantes == cantidadCortes;
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
                                              ? AppColors.successDark
                                                  .withValues(alpha: 0.2)
                                              : AppColors.error.withValues(
                                                alpha: 0.2,
                                              ),
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
                                          isValid
                                              ? Icons.check_circle
                                              : Icons.warning,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  acompanante.precioAdicional >
                                                          0
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
                                                    setDialogState(() {
                                                      if (cantidadActual > 1) {
                                                        acompanantesCantidades[acompanante
                                                                .nombre] =
                                                            cantidadActual - 1;
                                                      } else {
                                                        acompanantesCantidades
                                                            .remove(
                                                              acompanante
                                                                  .nombre,
                                                            );
                                                        preciosAcompanantes
                                                            .remove(
                                                              acompanante
                                                                  .nombre,
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
                                                          varianteSeleccionada!
                                                              .nombre
                                                              .split(' ')
                                                              .first,
                                                        ) ??
                                                        1
                                                    : 1;
                                            final totalAcompanantes =
                                                acompanantesCantidades.values
                                                    .fold<int>(
                                                      0,
                                                      (sum, cant) => sum + cant,
                                                    );
                                            final puedeAgregar =
                                                totalAcompanantes <
                                                cantidadCortes;
                                            return IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  puedeAgregar
                                                      ? () {
                                                        setDialogState(() {
                                                          acompanantesCantidades[acompanante
                                                                  .nombre] =
                                                              (cantidadActual) +
                                                              1;
                                                          preciosAcompanantes[acompanante
                                                                  .nombre] =
                                                              acompanante
                                                                  .precioAdicional;
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
                                    final isSelected =
                                        extraSeleccionado == extra.nombre;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          setDialogState(() {
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
                        padding: const EdgeInsets.only(
                          bottom: 8,
                          left: 16,
                          right: 16,
                        ),
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
                              side: const BorderSide(
                                color: Colors.white24,
                                width: 1,
                              ),
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
                            setDialogState(() {
                              mensajeError = null;
                            });

                            // Validar que se haya seleccionado una variante si el producto las tiene
                            if (producto.tieneVariantes &&
                                varianteSeleccionada == null) {
                              setDialogState(() {
                                mensajeError =
                                    'Debes seleccionar un tamaño/porción';
                              });
                              return;
                            }

                            // Validar acompañantes: la suma debe ser igual a la cantidad de cortes
                            if (producto.tieneAcompanantes) {
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
                              if (totalAcompanantes != cantidadCortes) {
                                setDialogState(() {
                                  mensajeError =
                                      'Debes seleccionar exactamente $cantidadCortes acompañante${cantidadCortes > 1 ? 's' : ''} (actual: $totalAcompanantes)';
                                });
                                return;
                              }
                            }

                            // Validar extras: deben ser obligatorios si existen
                            if (producto.tieneExtras &&
                                extraSeleccionado == null) {
                              setDialogState(() {
                                mensajeError = 'Debes seleccionar un extra';
                              });
                              return;
                            }

                            double precioBase =
                                varianteSeleccionada?.precio ?? producto.precio;
                            double precioExtrasTotal = preciosExtras.values
                                .fold(0.0, (sum, precio) => sum + precio);

                            // Crear lista de acompañantes seleccionados
                            // La cantidad de cada acompañante se mantiene según lo seleccionado
                            final acompanantesList =
                                acompanantesCantidades.entries
                                    .map(
                                      (entry) => AcompananteSeleccionado(
                                        nombre: entry.key,
                                        precioAdicional:
                                            preciosAcompanantes[entry.key] ??
                                            0.0,
                                        cantidad:
                                            entry
                                                .value, // Mantener la cantidad seleccionada
                                      ),
                                    )
                                    .toList();

                            final productoSeleccionado = ProductoSeleccionado(
                              id: productoSeleccionadoExistente?.id,
                              productoId: producto.id!,
                              nombreProducto: producto.nombre,
                              cantidad: 1, // Siempre 1 por instancia
                              varianteNombre: varianteSeleccionada?.nombre,
                              precioBase: precioBase,
                              acompanantes: acompanantesList,
                              extrasNombres:
                                  extraSeleccionado != null
                                      ? [extraSeleccionado!]
                                      : [],
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
                ),
          ),
    );
  }

  double _calcularTotal() {
    double total = 0;
    for (final productoSeleccionado in _productosSeleccionados) {
      total += productoSeleccionado.precioTotal;
    }
    // Agregar costo de envases: $0.25 por envase
    total += _envasesLlevar * 0.25;
    return total;
  }

  List<Map<String, dynamic>> _obtenerProductosLista() {
    // Guardar cada instancia individualmente para mantener control granular
    return _productosSeleccionados.map((productoSeleccionado) {
      return productoSeleccionado.toMap();
    }).toList();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un producto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final pedido = Pedido(
      id: widget.pedido?.id, // Mantener el ID si es edición
      numeroOrden:
          widget.pedido?.numeroOrden ??
          0, // Mantener número de orden si es edición
      cliente: _clienteController.text.trim(),
      celular: _celularController.text.trim(),
      metodoPago: _metodoPago,
      estado:
          widget.pedido?.estado ??
          'En preparación', // Mantener estado si es edición
      estadoPago:
          widget.pedido?.estadoPago ??
          'Pendiente', // Mantener estado de pago si es edición
      productos: _obtenerProductosLista(),
      fecha:
          widget.pedido?.fecha ??
          DateTime.now(), // Mantener fecha original si es edición
      total: _calcularTotal(),
      envasesLlevar: _envasesLlevar,
      notas: _notasController.text.trim(),
      cancelado: widget.pedido?.cancelado ?? false,
    );

    widget.onSave(pedido);
  }

  void _mostrarSelectorProductos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder:
          (modalContext) => Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: AppConstants.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Selecciona un producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.productos.length,
                    itemBuilder: (context, index) {
                      final producto = widget.productos[index];
                      // Contar cuántas instancias de este producto hay
                      final cantidadInstancias =
                          _productosSeleccionados
                              .where((p) => p.productoId == producto.id)
                              .length;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingSmall,
                          vertical: AppConstants.paddingSmall / 2,
                        ),
                        leading: Icon(
                          Icons.restaurant,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          producto.nombre,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '\$${producto.precio.toStringAsFixed(2)}${producto.tieneVariantes ? ' (variantes)' : ''}',
                          style: const TextStyle(
                            color: AppColors.price,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing:
                            cantidadInstancias > 0
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$cantidadInstancias',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                                : null,
                        onTap: () {
                          Navigator.pop(modalContext);
                          _agregarProducto(producto);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campos de cliente
                  TextFormField(
                    controller: _clienteController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del cliente',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del cliente es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),

                  TextFormField(
                    controller: _celularController,
                    decoration: InputDecoration(
                      labelText: 'Celular (opcional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    // Celular es opcional, no se valida
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),

                  // Método de pago con radio buttons (lado a lado)
                  const Text(
                    'Método de pago',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: AppConstants.spacingSmall),
                  Row(
                    children: [
                      Expanded(
                        // ignore: deprecated_member_use - TODO: Migrar a RadioGroup cuando Flutter lo soporte
                        child: RadioListTile<String>(
                          title: const Text(
                            'Efectivo',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: 'Efectivo',
                          // ignore: deprecated_member_use
                          groupValue: _metodoPago,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              _metodoPago = value!;
                            });
                          },
                          activeColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        // ignore: deprecated_member_use - TODO: Migrar a RadioGroup cuando Flutter lo soporte
                        child: RadioListTile<String>(
                          title: const Text(
                            'Transferencia',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: 'Transferencia',
                          // ignore: deprecated_member_use
                          groupValue: _metodoPago,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              _metodoPago = value!;
                            });
                          },
                          activeColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),

                  // Envases a llevar
                  Row(
                    children: [
                      const Text(
                        'Envases a llevar:',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed:
                            _envasesLlevar > 0
                                ? () => setState(() => _envasesLlevar--)
                                : null,
                      ),
                      Text(
                        '$_envasesLlevar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => setState(() => _envasesLlevar++),
                      ),
                      const Spacer(),
                      Text(
                        '\$0.25 c/u',
                        style: const TextStyle(
                          color: AppColors.price,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),

                  // Notas
                  TextFormField(
                    controller: _notasController,
                    decoration: InputDecoration(
                      labelText: 'Notas (opcional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.spacingLarge),

                  // Botón agregar producto
                  ElevatedButton.icon(
                    onPressed: _mostrarSelectorProductos,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),

                  // Lista de productos seleccionados (agrupados por configuración)
                  if (_productosSeleccionados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppConstants.paddingLarge),
                      child: Center(
                        child: Text(
                          'Carrito vacío',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ..._obtenerProductosAgrupados().entries.map((entry) {
                      final claveAgrupacion = entry.key;
                      final grupo = entry.value;
                      final productoSeleccionado =
                          grupo['producto'] as ProductoSeleccionado;
                      final cantidad = grupo['cantidad'] as int;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingSmall,
                        ),
                        child: Slidable(
                          key: ValueKey<String>(claveAgrupacion),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed:
                                    (context) =>
                                        _eliminarGrupoProducto(claveAgrupacion),
                                backgroundColor: const Color(0xFFC62828),
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                  bottomRight: Radius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                ),
                                flex: 1,
                              ),
                            ],
                          ),
                          child: Card(
                            color: AppColors.cardBackground,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(
                                  AppConstants.borderRadius,
                                ),
                                bottomLeft: Radius.circular(
                                  AppConstants.borderRadius,
                                ),
                              ),
                            ),
                            child: InkWell(
                              onTap:
                                  () => _editarGrupoProducto(claveAgrupacion),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(
                                  AppConstants.borderRadius,
                                ),
                                bottomLeft: Radius.circular(
                                  AppConstants.borderRadius,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppConstants.paddingMedium,
                                ),
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
                                                productoSeleccionado
                                                    .nombreProducto,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (cantidad > 1) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'x$cantidad',
                                                    style: TextStyle(
                                                      color: AppColors.accent,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                    if (productoSeleccionado.varianteNombre !=
                                            null ||
                                        productoSeleccionado
                                            .acompanantes
                                            .isNotEmpty ||
                                        productoSeleccionado
                                            .extrasNombres
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      if (productoSeleccionado.varianteNombre !=
                                          null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.straighten,
                                                size: 14,
                                                color: Colors.white54,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                productoSeleccionado
                                                    .varianteNombre!,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (productoSeleccionado
                                          .acompanantes
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
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
                                                  productoSeleccionado
                                                      .acompanantes
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
                                      if (productoSeleccionado
                                          .extrasNombres
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
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
                                                  productoSeleccionado
                                                      .extrasNombres
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
                                          onPressed:
                                              () =>
                                                  _decrementarCantidadProducto(
                                                    claveAgrupacion,
                                                  ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                          onPressed:
                                              () =>
                                                  _incrementarCantidadProducto(
                                                    claveAgrupacion,
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
                      );
                    }),
                ],
              ),
            ),
          ),

          // Resumen y botón guardar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.price,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.pedido != null
                          ? 'Actualizar Pedido'
                          : 'Guardar Pedido',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
