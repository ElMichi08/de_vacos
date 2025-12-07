import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Modal elegante para procesar el pago de un pedido
/// Calcula automáticamente el cambio basado en el dinero recibido
class PaymentModal extends StatefulWidget {
  final double totalAPagar;
  final String cliente;
  final int numeroOrden;

  const PaymentModal({
    super.key,
    required this.totalAPagar,
    required this.cliente,
    required this.numeroOrden,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final TextEditingController _dineroRecibidoController = TextEditingController();
  double? _dineroRecibido;
  double _cambio = 0.0;
  bool _hayError = false;

  @override
  void initState() {
    super.initState();
    _dineroRecibidoController.addListener(_calcularCambio);
  }

  @override
  void dispose() {
    _dineroRecibidoController.dispose();
    super.dispose();
  }

  void _calcularCambio() {
    final texto = _dineroRecibidoController.text.trim();
    if (texto.isEmpty) {
      setState(() {
        _dineroRecibido = null;
        _cambio = 0.0;
        _hayError = false;
      });
      return;
    }

    final recibido = double.tryParse(texto);
    if (recibido == null) {
      setState(() {
        _dineroRecibido = null;
        _cambio = 0.0;
        _hayError = true;
      });
      return;
    }

    setState(() {
      _dineroRecibido = recibido;
      _cambio = recibido - widget.totalAPagar;
      _hayError = _cambio < 0;
    });
  }

  void _cobrar() {
    if (_dineroRecibido == null || _hayError || _cambio < 0) {
      return;
    }
    Navigator.of(context).pop(true); // Retorna true para indicar que se cobró
  }

  void _cancelar() {
    Navigator.of(context).pop(false);
  }

  void _setQuickAmount(double amount) {
    _dineroRecibidoController.text = amount.toStringAsFixed(2);
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return OutlinedButton(
      onPressed: () => _setQuickAmount(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(
          color: Colors.white24,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con información del pedido
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${widget.numeroOrden}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.cliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a pagar:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${widget.totalAPagar.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.price,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de dinero recibido
                  const Text(
                    'Dinero recibido',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dineroRecibidoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(
                        color: AppColors.price,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 24,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        borderSide: BorderSide(
                          color: _hayError ? AppColors.error : Colors.white24,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        borderSide: BorderSide(
                          color: _hayError ? AppColors.error : Colors.white24,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        borderSide: BorderSide(
                          color: _hayError ? AppColors.error : AppColors.accent,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    autofocus: true,
                  ),

                  // Botones rápidos de valores comunes
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickAmountButton('Exacto', widget.totalAPagar),
                      _buildQuickAmountButton('+5', widget.totalAPagar + 5),
                      _buildQuickAmountButton('+10', widget.totalAPagar + 10),
                      _buildQuickAmountButton('+20', widget.totalAPagar + 20),
                    ],
                  ),

                  // Mensaje de error o cambio
                  const SizedBox(height: 16),
                  if (_hayError && _dineroRecibido != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El dinero recibido es menor al total a pagar',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_dineroRecibido != null && !_hayError)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cambio:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${_cambio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Botones de acción
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(
                              color: Colors.white24,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón Cobrar
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_dineroRecibido != null && !_hayError && _cambio >= 0)
                              ? _cobrar
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white24,
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cobrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

