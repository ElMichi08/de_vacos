import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/image_service.dart';

/// Modal elegante para procesar el pago por transferencia
/// Requiere tomar una foto de la transferencia antes de confirmar el cobro
class TransferPaymentModal extends StatefulWidget {
  final double totalAPagar;
  final String cliente;
  final int numeroOrden;

  const TransferPaymentModal({
    super.key,
    required this.totalAPagar,
    required this.cliente,
    required this.numeroOrden,
  });

  @override
  State<TransferPaymentModal> createState() => _TransferPaymentModalState();
}

class _TransferPaymentModalState extends State<TransferPaymentModal> {
  String? _fotoGuardadaPath; // Ruta de la foto guardada en el dispositivo
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _tomarFoto() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null) {
        // Usuario canceló la captura
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Si ya hay una foto guardada, eliminarla primero
      if (_fotoGuardadaPath != null) {
        try {
          await ImageService.eliminar(_fotoGuardadaPath!);
        } catch (e) {
          // Ignorar errores al eliminar
        }
      }

      // Comprimir y guardar la foto automáticamente
      final pathGuardado = await ImageService.comprimirYGuardar(
        File(image.path),
        quality: 85,
      );

      setState(() {
        _fotoGuardadaPath = pathGuardado;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al tomar la foto: ${e.toString()}';
      });
    }
  }

  Future<void> _repetirFoto() async {
    // Eliminar la foto guardada si existe
    if (_fotoGuardadaPath != null) {
      try {
        await ImageService.eliminar(_fotoGuardadaPath!);
      } catch (e) {
        // Ignorar errores al eliminar
      }
    }

    // Limpiar estado
    setState(() {
      _fotoGuardadaPath = null;
      _errorMessage = null;
    });

    // Tomar nueva foto (se guardará automáticamente)
    await _tomarFoto();
  }

  void _cobrar() {
    if (_fotoGuardadaPath == null || _fotoGuardadaPath!.isEmpty) {
      return;
    }
    // Retorna la ruta de la foto guardada junto con true
    Navigator.of(context).pop({'cobrado': true, 'fotoPath': _fotoGuardadaPath});
  }

  void _cancelar() {
    // Si hay una foto temporal, no hacer nada especial
    // Si hay una foto guardada, se mantiene guardada (no se elimina al cancelar)
    Navigator.of(context).pop(null); // Retornar null en lugar de false para consistencia con el tipo esperado
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Ajustar constraints según orientación
    final maxWidth = isLandscape 
        ? screenWidth * 0.7 
        : 500.0;
    final maxHeight = isLandscape
        ? screenHeight * 0.9
        : screenHeight * 0.85;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: isLandscape
            ? _buildLandscapeLayout()
            : _buildPortraitLayout(),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Header en el lado izquierdo
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.borderRadiusLarge),
              bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
            ),
          ),
          child: _buildHeader(),
        ),
        // Contenido en el lado derecho
        Expanded(
          child: SingleChildScrollView(
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
                  // Título de sección
                  const Text(
                    'Foto de la transferencia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Área de foto
                  if (_fotoGuardadaPath != null)
                    // Foto guardada (vista de confirmación)
                    Container(
                      height: MediaQuery.of(context).orientation == Orientation.landscape ? 300 : 250,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: AppColors.success,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        child: Image.file(
                          File(_fotoGuardadaPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    // Sin foto - botón para tomar foto
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: Colors.white24,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: InkWell(
                        onTap: _isLoading ? null : _tomarFoto,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading)
                                const CircularProgressIndicator(
                                  color: AppColors.accent,
                                )
                              else
                                const Icon(
                                  Icons.camera_alt,
                                  size: 64,
                                  color: AppColors.accent,
                                ),
                              const SizedBox(height: 16),
                              Text(
                                _isLoading ? 'Abriendo cámara...' : 'Tocar para tomar foto',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Mensaje de error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
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
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botón para repetir foto (solo si hay foto guardada)
                  if (_fotoGuardadaPath != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _repetirFoto,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(
                          color: Colors.white24,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Repetir foto'),
                    ),
                  ],

                  // Mensaje de confirmación cuando hay foto guardada
                  if (_fotoGuardadaPath != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Foto guardada correctamente',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botones de acción
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _cancelar,
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
                          onPressed: (_fotoGuardadaPath != null && !_isLoading)
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
            );
  }
}

