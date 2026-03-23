import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/producto.dart';
import '../models/producto_variante.dart';
import '../models/acompanante.dart';
import '../models/extra.dart';
import '../models/receta_detalle.dart';
import '../models/insumo.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/image_service.dart';
import '../services/receta_service.dart';
import '../services/insumo_service.dart';

class ProductFormWidget extends StatefulWidget {
  final Producto? producto;
  final void Function(Producto product, List<RecetaDetalle> recetaLineas)
  onSave;

  const ProductFormWidget({super.key, this.producto, required this.onSave});

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  String? _imagenPath;
  bool _isLoading = false;

  // Listas para gestionar variantes, acompañantes, extras y receta
  List<ProductoVariante> _variantes = [];
  List<Acompanante> _acompanantes = [];
  List<Extra> _extras = [];
  List<RecetaDetalle> _recetaLineas = [];
  List<Insumo> _insumos = [];

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _nombreController.text = widget.producto!.nombre;
      _precioController.text = widget.producto!.precio.toStringAsFixed(2);
      _imagenPath = widget.producto!.imagenPath;

      _variantes = List<ProductoVariante>.from(
        widget.producto!.variantes ?? [],
      );
      _acompanantes = List<Acompanante>.from(
        widget.producto!.acompanantes ?? [],
      );
      _extras = List<Extra>.from(widget.producto!.extras ?? []);
    }
    _cargarInsumosYReceta();
  }

  Future<void> _cargarInsumosYReceta() async {
    final insumos = await InsumoService.listar();
    List<RecetaDetalle> receta = [];
    if (widget.producto?.id != null) {
      receta = await RecetaService.obtenerPorProducto(widget.producto!.id!);
    }
    if (mounted) {
      setState(() {
        _insumos = insumos;
        _recetaLineas = receta;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final compressedPath = await ImageService.comprimirYGuardar(
          File(image.path),
        );

        setState(() {
          _imagenPath = compressedPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imagenPath == null || _imagenPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una imagen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Si hay variantes, usar lista de variantes, sino usar precio base
    final variantes = _variantes.isNotEmpty ? _variantes : null;
    final acompanantes = _acompanantes.isNotEmpty ? _acompanantes : null;
    final extras = _extras.isNotEmpty ? _extras : null;

    final producto = Producto(
      id: widget.producto?.id,
      nombre: _nombreController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      imagenPath: _imagenPath!,
      variantes: variantes,
      acompanantes: acompanantes,
      extras: extras,
    );

    // Receta: productoId se asigna al guardar en la pantalla
    final recetaLineas =
        _recetaLineas
            .where((l) => l.cantidad > 0)
            .map(
              (l) => RecetaDetalle(
                productoId: 0,
                insumoId: l.insumoId,
                cantidad: l.cantidad,
              ),
            )
            .toList();

    widget.onSave(producto, recetaLineas);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de imagen
            GestureDetector(
              onTap: _isLoading ? null : _seleccionarImagen,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  border: Border.all(color: AppColors.highlight, width: 2),
                ),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                        : _imagenPath != null && File(_imagenPath!).existsSync()
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          child: Image.file(
                            File(_imagenPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: AppColors.accent,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Toca para seleccionar imagen',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLarge),

            // Campo nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
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
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingMedium),

            // Campo precio
            TextFormField(
              controller: _precioController,
              decoration: InputDecoration(
                labelText: 'Precio',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.cardBackground,
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: AppColors.price),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es obligatorio';
                }
                final precio = double.tryParse(value.trim());
                if (precio == null || precio <= 0) {
                  return 'El precio debe ser un número positivo';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingLarge),

            // Sección de Variantes
            _buildVariantesSection(),
            const SizedBox(height: AppConstants.spacingMedium),

            // Sección de Acompañantes
            _buildAcompanantesSection(),
            const SizedBox(height: AppConstants.spacingMedium),

            // Sección de Extras
            _buildExtrasSection(),
            const SizedBox(height: AppConstants.spacingMedium),
            // Sección Receta (insumos y cantidades)
            _buildRecetaSection(),
            const SizedBox(height: AppConstants.spacingLarge),

            // Botón guardar
            ElevatedButton(
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
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SECCIÓN DE VARIANTES ====================

  Widget _buildVariantesSection() {
    return Card(
      color: AppColors.cardBackground,
      child: ExpansionTile(
        title: const Text(
          'Variantes de tamaño/precio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _variantes.isEmpty
              ? 'Sin variantes (precio único)'
              : '${_variantes.length} variante(s) definida(s)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        leading: Icon(Icons.straighten, color: AppColors.accent),
        iconColor: AppColors.accent,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Lista de variantes
                if (_variantes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      'Sin variantes. El producto tendrá un precio único.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._variantes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variante = entry.value;
                    return _buildVarianteItem(variante, index);
                  }),

                const SizedBox(height: AppConstants.spacingSmall),

                // Botón agregar variante
                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoAgregarVariante(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar variante'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianteItem(ProductoVariante variante, int index) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
      child: ListTile(
        title: Text(
          variante.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '\$${variante.precio.toStringAsFixed(2)}${variante.descripcion != null ? ' - ${variante.descripcion}' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.accent,
              onPressed: () => _mostrarDialogoEditarVariante(variante, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: () => _eliminarVariante(index),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarVariante() {
    _mostrarDialogoVariante();
  }

  void _mostrarDialogoEditarVariante(ProductoVariante variante, int index) {
    _mostrarDialogoVariante(variante: variante, index: index);
  }

  void _mostrarDialogoVariante({ProductoVariante? variante, int? index}) {
    final nombreController = TextEditingController(
      text: variante?.nombre ?? '',
    );
    final precioController = TextEditingController(
      text: variante?.precio.toStringAsFixed(2) ?? '',
    );
    final descripcionController = TextEditingController(
      text: variante?.descripcion ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
            ),
            title: Text(
              variante == null ? 'Agregar Variante' : 'Editar Variante',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Nombre
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: 1 corte, 2 cortes, Grande',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Precio
                    TextFormField(
                      controller: precioController,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        hintText: '0.00',
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(
                          color: AppColors.price,
                          fontSize: 16,
                        ),
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio es obligatorio';
                        }
                        final precio = double.tryParse(value.trim());
                        if (precio == null || precio <= 0) {
                          return 'El precio debe ser un número positivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Descripción (opcional)
                    TextFormField(
                      controller: descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Ej: Solo para cocina',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final nuevaVariante = ProductoVariante(
                      nombre: nombreController.text.trim(),
                      precio: double.parse(precioController.text.trim()),
                      descripcion:
                          descripcionController.text.trim().isEmpty
                              ? null
                              : descripcionController.text.trim(),
                    );

                    setState(() {
                      if (index != null) {
                        _variantes[index] = nuevaVariante;
                      } else {
                        _variantes.add(nuevaVariante);
                      }
                    });

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _eliminarVariante(int index) {
    setState(() {
      _variantes.removeAt(index);
    });
  }

  // ==================== SECCIÓN DE ACOMPAÑANTES ====================

  Widget _buildAcompanantesSection() {
    return Card(
      color: AppColors.cardBackground,
      child: ExpansionTile(
        title: const Text(
          'Acompañantes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _acompanantes.isEmpty
              ? 'Sin acompañantes opcionales'
              : '${_acompanantes.length} acompañante(s) definido(s)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        leading: Icon(Icons.restaurant_menu, color: AppColors.accent),
        iconColor: AppColors.accent,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                if (_acompanantes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      'Sin acompañantes. Los clientes no podrán seleccionar opciones.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._acompanantes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final acompanante = entry.value;
                    return _buildAcompananteItem(acompanante, index);
                  }),

                const SizedBox(height: AppConstants.spacingSmall),

                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoAgregarAcompanante(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar acompañante'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcompananteItem(Acompanante acompanante, int index) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
      child: ListTile(
        title: Text(
          acompanante.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          acompanante.precioAdicional > 0
              ? '+\$${acompanante.precioAdicional.toStringAsFixed(2)}'
              : 'Gratis',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (acompanante.esPredeterminado)
              Icon(Icons.star, color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.accent,
              onPressed:
                  () => _mostrarDialogoEditarAcompanante(acompanante, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: () => _eliminarAcompanante(index),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarAcompanante() {
    _mostrarDialogoAcompanante();
  }

  void _mostrarDialogoEditarAcompanante(Acompanante acompanante, int index) {
    _mostrarDialogoAcompanante(acompanante: acompanante, index: index);
  }

  void _mostrarDialogoAcompanante({Acompanante? acompanante, int? index}) {
    final nombreController = TextEditingController(
      text: acompanante?.nombre ?? '',
    );
    final precioController = TextEditingController(
      text: acompanante?.precioAdicional.toStringAsFixed(2) ?? '0.00',
    );
    bool esPredeterminado = acompanante?.esPredeterminado ?? false;
    final formKey = GlobalKey<FormState>();

    showDialog(
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
                    acompanante == null
                        ? 'Agregar Acompañante'
                        : 'Editar Acompañante',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Campo Nombre
                          TextFormField(
                            controller: nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              hintText:
                                  'Ej: Papas fritas, Papas cocinadas, Mixtas',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              hintStyle: TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Campo Precio
                          TextFormField(
                            controller: precioController,
                            decoration: InputDecoration(
                              labelText: 'Precio adicional',
                              hintText: '0.00',
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(
                                color: AppColors.price,
                                fontSize: 16,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              hintStyle: TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El precio es obligatorio';
                              }
                              final precio = double.tryParse(value.trim());
                              if (precio == null || precio < 0) {
                                return 'El precio debe ser un número positivo o cero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Checkbox predeterminado
                          CheckboxListTile(
                            title: const Text(
                              'Selección predeterminada',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            value: esPredeterminado,
                            onChanged: (value) {
                              setDialogState(() {
                                esPredeterminado = value ?? false;
                              });
                            },
                            activeColor: AppColors.accent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final nuevoAcompanante = Acompanante(
                            nombre: nombreController.text.trim(),
                            precioAdicional: double.parse(
                              precioController.text.trim(),
                            ),
                            esPredeterminado: esPredeterminado,
                          );

                          setState(() {
                            if (index != null) {
                              _acompanantes[index] = nuevoAcompanante;
                            } else {
                              _acompanantes.add(nuevoAcompanante);
                            }
                          });

                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _eliminarAcompanante(int index) {
    setState(() {
      _acompanantes.removeAt(index);
    });
  }

  // ==================== SECCIÓN DE EXTRAS ====================

  Widget _buildExtrasSection() {
    return Card(
      color: AppColors.cardBackground,
      child: ExpansionTile(
        title: const Text(
          'Extras',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _extras.isEmpty
              ? 'Sin extras opcionales'
              : '${_extras.length} extra(s) definido(s)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        leading: Icon(Icons.add_circle_outline, color: AppColors.accent),
        iconColor: AppColors.accent,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                if (_extras.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      'Sin extras. Los clientes no podrán agregar elementos adicionales.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._extras.asMap().entries.map((entry) {
                    final index = entry.key;
                    final extra = entry.value;
                    return _buildExtraItem(extra, index);
                  }),

                const SizedBox(height: AppConstants.spacingSmall),

                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoAgregarExtra(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar extra'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraItem(Extra extra, int index) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
      child: ListTile(
        title: Text(
          extra.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          extra.precioAdicional > 0
              ? '+\$${extra.precioAdicional.toStringAsFixed(2)}'
              : 'Gratis',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.accent,
              onPressed: () => _mostrarDialogoEditarExtra(extra, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: () => _eliminarExtra(index),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarExtra() {
    _mostrarDialogoExtra();
  }

  void _mostrarDialogoEditarExtra(Extra extra, int index) {
    _mostrarDialogoExtra(extra: extra, index: index);
  }

  void _mostrarDialogoExtra({Extra? extra, int? index}) {
    final nombreController = TextEditingController(text: extra?.nombre ?? '');
    final precioController = TextEditingController(
      text: extra?.precioAdicional.toStringAsFixed(2) ?? '0.00',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
            ),
            title: Text(
              extra == null ? 'Agregar Extra' : 'Editar Extra',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Nombre
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Gaseosa grande, Porción de papas extra',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Precio
                    TextFormField(
                      controller: precioController,
                      decoration: InputDecoration(
                        labelText: 'Precio adicional',
                        hintText: '0.00',
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(
                          color: AppColors.price,
                          fontSize: 16,
                        ),
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio es obligatorio';
                        }
                        final precio = double.tryParse(value.trim());
                        if (precio == null || precio < 0) {
                          return 'El precio debe ser un número positivo o cero';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final nuevoExtra = Extra(
                      nombre: nombreController.text.trim(),
                      precioAdicional: double.parse(
                        precioController.text.trim(),
                      ),
                    );

                    setState(() {
                      if (index != null) {
                        _extras[index] = nuevoExtra;
                      } else {
                        _extras.add(nuevoExtra);
                      }
                    });

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _eliminarExtra(int index) {
    setState(() {
      _extras.removeAt(index);
    });
  }

  // ==================== SECCIÓN RECETA ====================

  Widget _buildRecetaSection() {
    return Card(
      color: AppColors.cardBackground,
      child: ExpansionTile(
        title: const Text(
          'Receta (insumos)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _recetaLineas.isEmpty
              ? 'Sin receta'
              : '${_recetaLineas.length} insumo(s)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        leading: Icon(Icons.menu_book, color: AppColors.accent),
        iconColor: AppColors.accent,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                if (_recetaLineas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      'Agrega insumos y cantidades para este producto.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._recetaLineas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final linea = entry.value;
                    final insumoNombre =
                        _insumos
                            .where((i) => i.id == linea.insumoId)
                            .map((i) => i.nombre)
                            .firstOrNull ??
                        'ID ${linea.insumoId}';
                    return Card(
                      color: AppColors.background,
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingSmall,
                      ),
                      child: ListTile(
                        title: Text(
                          insumoNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${linea.cantidad}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: AppColors.accent,
                              onPressed:
                                  () =>
                                      _mostrarDialogoRecetaLinea(index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: AppColors.error,
                              onPressed: () {
                                setState(() => _recetaLineas.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppConstants.spacingSmall),
                OutlinedButton.icon(
                  onPressed:
                      _insumos.isEmpty
                          ? null
                          : () => _mostrarDialogoRecetaLinea(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar insumo a la receta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRecetaLinea({int? index}) {
    final linea = index != null ? _recetaLineas[index] : null;
    int? insumoIdSeleccionado = linea?.insumoId;
    final cantidadController = TextEditingController(
      text: linea?.cantidad.toString() ?? '1',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
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
                    linea == null
                        ? 'Agregar insumo a receta'
                        : 'Editar cantidad',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (linea == null)
                            DropdownButtonFormField<int>(
                              initialValue: insumoIdSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Insumo',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium,
                                  ),
                                ),
                              ),
                              dropdownColor: AppColors.cardBackground,
                              items:
                                  _insumos
                                      .where(
                                        (i) =>
                                            !_recetaLineas.any(
                                              (r) => r.insumoId == i.id,
                                            ),
                                      )
                                      .map(
                                        (i) => DropdownMenuItem(
                                          value: i.id,
                                          child: Text(
                                            i.nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setDialogState(
                                    () => insumoIdSeleccionado = v,
                                  ),
                              validator:
                                  (v) => v == null ? 'Elige un insumo' : null,
                            ),
                          if (linea == null) const SizedBox(height: 16),
                          TextFormField(
                            controller: cantidadController,
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              final n = double.tryParse(v.trim());
                              if (n == null || n <= 0) return 'Debe ser > 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final cantidad =
                            double.tryParse(cantidadController.text.trim()) ??
                            0;
                        if (cantidad <= 0) return;
                        final id = insumoIdSeleccionado ?? linea?.insumoId;
                        if (id == null) return;
                        setState(() {
                          if (index != null) {
                            _recetaLineas[index] = RecetaDetalle(
                              productoId: 0,
                              insumoId: id,
                              cantidad: cantidad,
                            );
                          } else {
                            _recetaLineas.add(
                              RecetaDetalle(
                                productoId: 0,
                                insumoId: id,
                                cantidad: cantidad,
                              ),
                            );
                          }
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
