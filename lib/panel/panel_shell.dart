import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/config/app_config.dart';

/// Layout del panel web con navegación a reportes y cobros.
class PanelShell extends StatelessWidget {
  final Widget child;

  const PanelShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Panel ${AppConfig.instance.appName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.cardBackground,
            selectedIndex: _selectedIndex(path),
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/panel/reportes');
                  break;
                case 1:
                  context.go('/panel/cobros');
                  break;
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.assessment, color: Colors.white70),
                selectedIcon: Icon(Icons.assessment, color: AppColors.accent),
                label: Text('Reportes', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payment, color: Colors.white70),
                selectedIcon: Icon(Icons.payment, color: AppColors.accent),
                label: Text('Cobros', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(String path) {
    if (path.contains('cobros')) return 1;
    return 0;
  }
}
