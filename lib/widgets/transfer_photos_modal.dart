import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/pedido.dart';

/// Modal para ver las fotos de transferencias en pantalla completa
/// Muestra todas las fotos de los pedidos con método de pago "Transferencia"
class TransferPhotosModal extends StatelessWidget {
  final List<Pedido> pedidosConTransferencia;

  const TransferPhotosModal({
    super.key,
    required this.pedidosConTransferencia,
  });

  @override
  Widget build(BuildContext context) {
    // Separar pedidos con foto y sin foto
    final pedidosConFoto = pedidosConTransferencia
        .where((p) => p.fotoTransferenciaPath != null && p.fotoTransferenciaPath!.isNotEmpty)
        .toList();
    final pedidosSinFoto = pedidosConTransferencia
        .where((p) => p.fotoTransferenciaPath == null || p.fotoTransferenciaPath!.isEmpty)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fotos de Transferencias',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
              child: pedidosConTransferencia.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pedidos con foto
                          if (pedidosConFoto.isNotEmpty) ...[
                            _buildSectionTitle('Pedidos con foto'),
                            const SizedBox(height: 12),
                            ...pedidosConFoto.map((pedido) => _buildPhotoCard(context, pedido)),
                            if (pedidosSinFoto.isNotEmpty) const SizedBox(height: 24),
                          ],

                          // Pedidos sin foto (versiones anteriores)
                          if (pedidosSinFoto.isNotEmpty) ...[
                            _buildSectionTitle('Pedidos sin foto'),
                            const SizedBox(height: 12),
                            ...pedidosSinFoto.map((pedido) => _buildNoPhotoCard(pedido)),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, Pedido pedido) {
    final fotoPath = pedido.fotoTransferenciaPath!;
    final file = File(fotoPath);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () => _showFullScreenPhoto(context, file, pedido),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del pedido
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${pedido.numeroOrden}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pedido.cliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.price,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vista previa de la foto
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                child: Stack(
                  children: [
                    Image.file(
                      file,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: AppColors.error.withValues(alpha: 0.1),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Error al cargar la foto',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Overlay para indicar que es clickeable
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.0),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca para ver en pantalla completa',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPhotoCard(Pedido pedido) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        side: BorderSide(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${pedido.numeroOrden}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: Colors.orange,
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sin foto',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay pedidos con transferencia',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, File fotoFile, Pedido pedido) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Foto en pantalla completa
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  fotoFile,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                      ),
                      child: const Column(
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
                    );
                  },
                ),
              ),
            ),

            // Información del pedido en la parte superior
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

