import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../injection/container.dart';
import '../../menu/dominio/definicion/menu_item_definicion.dart';
import '../../widgets/back_header_widget.dart';
import 'plato_selector_sheet.dart';

class MenuGridScreen extends StatefulWidget {
  const MenuGridScreen({super.key});

  @override
  State<MenuGridScreen> createState() => _MenuGridScreenState();
}

class _MenuGridScreenState extends State<MenuGridScreen> {
  List<MenuItemDefinicion> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await di.menuItemRepository.findAll();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _eliminar(MenuItemDefinicion item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Eliminar ítem', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${item.nombre}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if ((confirmar ?? false) && item.id != null) {
      await di.menuItemRepository.delete(item.id!);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeaderWidget(title: 'Menú'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          final ok = await context.push<bool>('/menu/nuevo');
          if (ok ?? false) _cargar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargar,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
          : _items.isEmpty
              ? const Center(
                  child: Text('No hay ítems de menú.\nToca + para crear uno.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _MenuItemCard(
                    item: _items[i],
                    onEdit: () async {
                      final ok = await context.push<bool>(
                        '/menu/editar/${_items[i].id}',
                        extra: _items[i],
                      );
                      if (ok ?? false) _cargar();
                    },
                    onDelete: () => _eliminar(_items[i]),
                    onOrdenar: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final confirmado = await showPlatoSelectorSheet(context, _items[i]);
                      if (confirmado != null) {
                        messenger
                          ..clearSnackBars()
                          ..showSnackBar(SnackBar(
                            content: Text(
                              '${confirmado.nombre}  →  \$${confirmado.precio.toStringAsFixed(2)}',
                            ),
                            backgroundColor: AppColors.successDark,
                            duration: const Duration(seconds: 3),
                          ));
                      }
                    },
                  ),
                ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemDefinicion item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOrdenar;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onOrdenar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(item.nombre,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${item.tiers.length} tier(s) · ${item.proteinaIds.length} proteína(s)',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ElevatedButton.icon(
              onPressed: onOrdenar,
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text('Ordenar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
