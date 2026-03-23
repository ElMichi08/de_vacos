import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _buildAppBarTitle(context),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false, // Sin flecha de regreso
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          final isTablet = constraints.maxWidth > 600;
          
          // Ajustar columnas según orientación y tamaño
          int crossAxisCount;
          if (isLandscape) {
            // En landscape, usar más columnas
            crossAxisCount = isTablet ? 4 : 3;
          } else {
            // En portrait, usar menos columnas
            crossAxisCount = isTablet ? 3 : 2;
          }
          
          final padding = isTablet 
              ? AppConstants.paddingLarge 
              : AppConstants.paddingMedium;
          
          // En landscape, centrar el contenido y limitar el ancho máximo
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 1200 : double.infinity,
              ),
              child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
                child: _buildMenuGrid(context, crossAxisCount, isLandscape),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    final config = AppConfig.instance;
    final hasLogo = config.hasLogo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLogo && config.logoUrl != null && config.logoUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.network(
              config.logoUrl!,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
            ),
          )
        else if (hasLogo && config.logoAssetPath != null && config.logoAssetPath!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset(
              config.logoAssetPath!,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
            ),
          )
        else
          const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
        const SizedBox(width: 10),
        Text(
          config.appName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, int crossAxisCount, bool isLandscape) {
    // Lista completa de ítems del menú (orden: productos, pedidos, cocina, insumos, reportes, caja, impresora, pruebas).
    // IDs válidos: productos, pedidos, cocina, insumos, reportes, caja, impresora, pruebas.
    final fullMenu = [
      _MenuDef(id: 'productos', icon: Icons.restaurant_menu, title: 'Productos', subtitle: 'Gestionar productos del menú', color: AppColors.accent, path: '/productos'),
      _MenuDef(id: 'pedidos', icon: Icons.receipt_long, title: 'Pedidos', subtitle: 'Ver y gestionar pedidos', color: AppColors.success, path: '/pedidos'),
      _MenuDef(id: 'cocina', icon: Icons.restaurant, title: 'Cocina (KDS)', subtitle: 'Pedidos en preparación · Marcar listo', color: Colors.deepOrange, path: '/cocina'),
      _MenuDef(id: 'insumos', icon: Icons.inventory_2, title: 'Insumos', subtitle: 'Inventario y recetas', color: Colors.cyan, path: '/insumos'),
      _MenuDef(id: 'reportes', icon: Icons.assessment, title: 'Reportes', subtitle: 'Estadísticas y reportes', color: AppColors.price, path: '/reportes'),
      _MenuDef(id: 'caja', icon: Icons.account_balance_wallet, title: 'Caja', subtitle: 'Gestión de ingresos y egresos', color: Colors.amber, path: '/caja'),
      _MenuDef(id: 'impresora', icon: Icons.print, title: 'Impresora', subtitle: 'Configurar impresora térmica', color: Colors.blue, path: '/impresora'),
      _MenuDef(id: 'pruebas', icon: Icons.science, title: 'Pruebas', subtitle: 'Generar datos de prueba', color: Colors.purple, path: '/pruebas'),
    ];

    final features = AppConfig.instance.features;
    final visible = (features == null || features.isEmpty)
        ? fullMenu.toList()
        : fullMenu.where((e) => features.contains(e.id)).toList();

    final menuItems = visible
        .map(
          (def) => _MenuItem(
            icon: def.icon,
            title: def.title,
            subtitle: def.subtitle,
            color: def.color,
            onTap: () => context.push(def.path),
          ),
        )
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.spacingMedium,
        mainAxisSpacing: AppConstants.spacingMedium,
        childAspectRatio: isLandscape 
            ? (crossAxisCount >= 4 ? 0.9 : 0.85) // Más anchos en landscape
            : (crossAxisCount == 3 ? 0.75 : 0.85), // Más altos en portrait
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _MenuCard(item: menuItems[index], isTablet: crossAxisCount == 3);
      },
    );
  }
}

/// Definición de un ítem del menú (id para feature flags).
class _MenuDef {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String path;

  const _MenuDef({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.path,
  });
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final bool isTablet;

  const _MenuCard({required this.item, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: EdgeInsets.all(
            isTablet ? AppConstants.paddingLarge : AppConstants.paddingMedium,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.icon,
                  size: isTablet ? 48 : 40,
                  color: item.color,
                ),
              ),
              SizedBox(height: isTablet ? 20 : AppConstants.spacingMedium),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 10 : 8),
              Flexible(
                child: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 14 : 12,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
