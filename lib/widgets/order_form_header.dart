import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class OrderFormHeader extends StatelessWidget {
  final TextEditingController clienteController;
  final TextEditingController celularController;
  final TextEditingController notasController;
  final PaymentMethod metodoPago;
  final ValueChanged<PaymentMethod> onMetodoPagoChanged;
  final int envasesLlevar;
  final ValueChanged<int> onEnvasesLlevarChanged;
  final VoidCallback onAddProduct;

  const OrderFormHeader({
    super.key,
    required this.clienteController,
    required this.celularController,
    required this.notasController,
    required this.metodoPago,
    required this.onMetodoPagoChanged,
    required this.envasesLlevar,
    required this.onEnvasesLlevarChanged,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campos de cliente
        TextFormField(
          controller: clienteController,
          decoration: InputDecoration(
            labelText: 'Nombre del cliente',
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
          controller: celularController,
          decoration: InputDecoration(
            labelText: 'Celular (opcional)',
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
              child: RadioListTile<PaymentMethod>(
                title: const Text(
                  'Efectivo',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: PaymentMethod.efectivo,
                // ignore: deprecated_member_use
                groupValue: metodoPago,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  onMetodoPagoChanged(value!);
                },
                activeColor: AppColors.accent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              // ignore: deprecated_member_use - TODO: Migrar a RadioGroup cuando Flutter lo soporte
              child: RadioListTile<PaymentMethod>(
                title: const Text(
                  'Transferencia',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: PaymentMethod.transferencia,
                // ignore: deprecated_member_use
                groupValue: metodoPago,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  onMetodoPagoChanged(value!);
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
                  envasesLlevar > 0
                      ? () => onEnvasesLlevarChanged(envasesLlevar - 1)
                      : null,
            ),
            Text(
              '$envasesLlevar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => onEnvasesLlevarChanged(envasesLlevar + 1),
            ),
            const Spacer(),
            Text(
              '\$0.25 c/u',
              style: const TextStyle(color: AppColors.price, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMedium),

        // Notas
        TextFormField(
          controller: notasController,
          decoration: InputDecoration(
            labelText: 'Notas (opcional)',
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
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        const SizedBox(height: AppConstants.spacingLarge),

        // Botón agregar producto
        ElevatedButton.icon(
          onPressed: onAddProduct,
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingMedium),
      ],
    );
  }
}
