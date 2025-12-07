import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/pedido.dart';

/// Modal para ver la foto de transferencia de un pedido específico
/// Muestra la foto en pantalla completa o un mensaje si no tiene foto
class TransferPhotoViewerModal extends StatelessWidget {
  final Pedido pedido;

  const TransferPhotoViewerModal({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    final tieneFoto = pedido.fotoTransferenciaPath != null && 
                     pedido.fotoTransferenciaPath!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Contenido principal
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              margin: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                        topRight: Radius.circular(AppConstants.borderRadiusLarge),
                      ),
                    ),
                    child: Row(
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
                            '#${pedido.numeroOrden}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pedido.cliente,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '\$${pedido.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.price,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: tieneFoto
                          ? _buildPhotoView(pedido.fotoTransferenciaPath!)
                          : _buildNoPhotoMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoView(String fotoPath) {
    final file = File(fotoPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error al cargar la foto',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoPhotoMessage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: Colors.orange,
          width: 2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pedido de versión anterior',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Este pedido fue creado en una versión anterior de la aplicación que no incluía la funcionalidad de captura de fotos de transferencia.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Por lo tanto, no se puede mostrar la foto de la transferencia.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

