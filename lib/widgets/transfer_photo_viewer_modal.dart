import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/pedido.dart';
import '../models/enums.dart';

/// Modal para ver las fotos de transferencia de un pedido.
/// Soporta múltiples fotos (multi-pago) con PageView y paginador.
class TransferPhotoViewerModal extends StatefulWidget {
  final Pedido pedido;

  const TransferPhotoViewerModal({super.key, required this.pedido});

  @override
  State<TransferPhotoViewerModal> createState() =>
      _TransferPhotoViewerModalState();
}

class _TransferPhotoViewerModalState extends State<TransferPhotoViewerModal> {
  late final PageController _pageCtrl;
  int _paginaActual = 0;

  List<String> get _fotos {
    // Preferir historial de pagos si existe
    if (widget.pedido.pagos != null && widget.pedido.pagos!.isNotEmpty) {
      return widget.pedido.pagos!
          .where(
            (p) =>
                p.metodo == PaymentMethod.transferencia &&
                p.foto != null &&
                p.foto!.isNotEmpty,
          )
          .map((p) => p.foto!)
          .toList();
    }
    // Fallback a campo único (órdenes históricas)
    final f = widget.pedido.fotoTransferenciaPath;
    if (f != null && f.isNotEmpty) return [f];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = _fotos;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              margin: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusLarge,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(fotos.length),

                  // Contenido
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: fotos.isEmpty
                          ? _buildNoPhotoMessage()
                          : _buildPhotoGallery(fotos),
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

  Widget _buildHeader(int totalFotos) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${widget.pedido.numeroOrden}',
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
                  widget.pedido.cliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '\$${widget.pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.price, fontSize: 14),
                    ),
                    if (totalFotos > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF64B5F6)),
                        ),
                        child: Text(
                          '$totalFotos fotos',
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> fotos) {
    if (fotos.length == 1) {
      return _buildPhotoView(fotos.first);
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: fotos.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                right: i < fotos.length - 1 ? 8.0 : 0,
              ),
              child: _buildPhotoView(fotos[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Indicador de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            fotos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _paginaActual ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _paginaActual
                    ? const Color(0xFF64B5F6)
                    : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Foto ${_paginaActual + 1} de ${fotos.length}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPhotoView(String fotoPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(fotoPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, _) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error al cargar la foto',
                      style: TextStyle(color: AppColors.error, fontSize: 18),
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
        border: Border.all(color: Colors.orange, width: 2),
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
                'No hay foto de transferencia disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Este pedido no tiene una foto de transferencia asociada.',
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
