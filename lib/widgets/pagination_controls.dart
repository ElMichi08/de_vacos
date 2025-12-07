import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Widget reutilizable para controles de paginación
/// 
/// Incluye selector de items por página y navegación entre páginas
class PaginationControls extends StatelessWidget {
  /// Cantidad actual de items por página
  final int itemsPerPage;
  
  /// Página actual
  final int currentPage;
  
  /// Total de páginas
  final int totalPages;
  
  /// Total de items
  final int totalItems;
  
  /// Callback cuando cambia la cantidad de items por página
  final void Function(int newValue) onItemsPerPageChanged;
  
  /// Callback cuando cambia la página
  final void Function(int newPage) onPageChanged;
  
  /// Opciones disponibles para items por página (por defecto: 10, 20, 50, 100)
  final List<int> itemsPerPageOptions;
  
  /// Etiqueta personalizada para el texto (por defecto: "por página")
  final String itemsPerPageLabelSuffix;
  
  /// Etiqueta personalizada para los items (por defecto: "pedidos")
  final String itemsLabel;

  const PaginationControls({
    super.key,
    required this.itemsPerPage,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onItemsPerPageChanged,
    required this.onPageChanged,
    this.itemsPerPageOptions = const [10, 20, 50, 100],
    this.itemsPerPageLabelSuffix = 'por página',
    this.itemsLabel = 'pedidos',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selector de tamaño de página - a la izquierda
            PopupMenuButton<int>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$itemsPerPage',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => itemsPerPageOptions.map((int value) {
                return PopupMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value $itemsPerPageLabelSuffix',
                    style: TextStyle(
                      color: value == itemsPerPage ? AppColors.accent : Colors.white,
                      fontWeight: value == itemsPerPage ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onSelected: onItemsPerPageChanged,
            ),
            
            // Botones de navegación y información centrada
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón anterior
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: currentPage > 1
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    tooltip: 'Anterior',
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Información de paginación - en el centro
                  Text(
                    '$currentPage de $totalPages • $totalItems $itemsLabel',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botón siguiente
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: currentPage < totalPages
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    tooltip: 'Siguiente',
                  ),
                ],
              ),
            ),
            
            // Espacio para compensar el selector de la izquierda y evitar solapamiento con FAB
            const SizedBox(width: 56), // Ancho aproximado del selector
          ],
        ),
      ),
    );
  }
}

