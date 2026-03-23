import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/insumo.dart';
import '../services/insumo_service.dart';
import '../widgets/back_header_widget.dart';

class InsumoFormScreen extends StatefulWidget {
  final Insumo? insumo;

  const InsumoFormScreen({super.key, this.insumo});

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _unidadController;
  late TextEditingController _cantidadActualController;
  late TextEditingController _cantidadMinimaController;
  late TextEditingController _costoController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.insumo;
    _nombreController = TextEditingController(text: i?.nombre ?? '');
    _unidadController = TextEditingController(text: i?.unidadMedida ?? '');
    _cantidadActualController = TextEditingController(
      text: i?.cantidadActual.toString() ?? '0',
    );
    _cantidadMinimaController = TextEditingController(
      text: i?.cantidadMinima.toString() ?? '0',
    );
    _costoController = TextEditingController(
      text: i?.costoUnitario?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _unidadController.dispose();
    _cantidadActualController.dispose();
    _cantidadMinimaController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cantidadActual = double.tryParse(_cantidadActualController.text.trim()) ?? 0;
      final cantidadMinima = double.tryParse(_cantidadMinimaController.text.trim()) ?? 0;
      final costoStr = _costoController.text.trim();
      final costoUnitario = costoStr.isEmpty ? null : double.tryParse(costoStr);

      final insumo = Insumo(
        id: widget.insumo?.id,
        nombre: _nombreController.text.trim(),
        unidadMedida: _unidadController.text.trim(),
        cantidadActual: cantidadActual,
        cantidadMinima: cantidadMinima,
        costoUnitario: costoUnitario,
      );

      if (insumo.id == null) {
        await InsumoService.crear(insumo);
      } else {
        await InsumoService.actualizar(insumo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insumo guardado'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeaderWidget(
        title: widget.insumo == null ? 'Nuevo Insumo' : 'Editar Insumo',
      ),
      body: _saving
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration('Nombre'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  TextFormField(
                    controller: _unidadController,
                    decoration: _inputDecoration('Unidad de medida (ej: kg, L, u)'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  TextFormField(
                    controller: _cantidadActualController,
                    decoration: _inputDecoration('Cantidad actual'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obligatorio';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Debe ser ≥ 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  TextFormField(
                    controller: _cantidadMinimaController,
                    decoration: _inputDecoration('Cantidad mínima'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obligatorio';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Debe ser ≥ 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  TextFormField(
                    controller: _costoController,
                    decoration: _inputDecoration('Costo unitario (opcional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppConstants.spacingLarge),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    );
  }
}
