import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_colors.dart';
import 'models/pedido.dart';
import 'models/producto.dart';
import 'panel/panel_cobros_screen.dart';
import 'panel/panel_reportes_screen.dart';
import 'panel/panel_shell.dart';
import 'screens/caja_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/printer_settings_screen.dart';
import 'screens/product_grid_screen.dart';
import 'screens/report_screen.dart';
import 'screens/test_data_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/cocina_screen.dart';
import 'screens/insumos_screen.dart';
import 'screens/menu/menu_grid_screen.dart';
import 'screens/menu/menu_item_form_screen.dart';
import 'menu/dominio/definicion/menu_item_definicion.dart';
import 'services/pedido_service.dart';
import 'services/producto_service.dart';

/// Mapa ruta base → feature id (para guard: si el feature no está habilitado, redirigir a /home).
const Map<String, String> _routeToFeature = {
  '/menu': 'menu',
  '/productos': 'productos',
  '/pedidos': 'pedidos',
  '/cocina': 'cocina',
  '/insumos': 'insumos',
  '/reportes': 'reportes',
  '/caja': 'caja',
  '/impresora': 'impresora',
  '/pruebas': 'pruebas',
};

/// Redirect: si la ruta actual requiere un feature deshabilitado, ir a /home.
String? _redirectByFeature(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  if (path.startsWith('/panel') || path == '/' || path == '/home') {
    return null;
  }
  final base =
      path.split('/').where((s) => s.isNotEmpty).isEmpty
          ? '/'
          : '/${path.split('/').where((s) => s.isNotEmpty).first}';
  final feature = _routeToFeature[base];
  if (feature != null && !AppConfig.instance.isFeatureEnabled(feature)) {
    return '/home';
  }
  return null;
}

/// Configuración central del GoRouter para De Vacos POS.
/// Rutas: /, /home, /productos, /pedidos, /pedidos/nueva, /pedidos/:id/editar,
/// /reportes, /caja, /impresora, /pruebas, /panel/...
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  debugLogDiagnostics: true,
  redirect: _redirectByFeature,
  errorBuilder: (context, state) {
    // Log the error for debugging
    debugPrint('GoRouter error: ${state.error}');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Ha ocurrido un error. Por favor, inténtelo nuevamente.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  },
  routes: <RouteBase>[
    GoRoute(path: '/', name: 'root', redirect: (_, __) => '/home'),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/productos',
      name: 'productos',
      builder: (_, __) => const ProductGridScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'nuevo',
          name: 'productoNuevo',
          builder: (_, __) => const AddProductScreen(),
        ),
        GoRoute(
          path: 'editar/:id',
          name: 'productoEditar',
          builder: (context, state) {
            final productId = state.pathParameters['id'];
            final extra = state.extra;
            final product = extra is Producto ? extra : null;
            return _EditProductRouteWrapper(
              productId: productId,
              product: product,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/pedidos',
      name: 'pedidos',
      builder: (_, __) => const OrderListScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'nueva',
          name: 'pedidoNueva',
          builder: (_, __) => const OrderFormScreen(),
        ),
        GoRoute(
          path: ':id/editar',
          name: 'pedidoEditar',
          builder: (context, state) {
            final orderId = state.pathParameters['id'];
            final extra = state.extra;
            final pedido = extra is Pedido ? extra : null;
            return _EditOrderRouteWrapper(orderId: orderId, pedido: pedido);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/reportes',
      name: 'reportes',
      builder: (_, __) => const ReportScreen(),
    ),
    GoRoute(
      path: '/caja',
      name: 'caja',
      builder: (_, __) => const CajaScreen(),
    ),
    GoRoute(
      path: '/impresora',
      name: 'impresora',
      builder: (_, __) => const PrinterSettingsScreen(),
    ),
    GoRoute(
      path: '/pruebas',
      name: 'pruebas',
      builder: (_, __) => const TestDataScreen(),
    ),
    GoRoute(
      path: '/insumos',
      name: 'insumos',
      builder: (_, __) => const InsumosScreen(),
    ),
    GoRoute(
      path: '/cocina',
      name: 'cocina',
      builder: (_, __) => const CocinaScreen(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (_, __) => const MenuGridScreen(),
      routes: [
        GoRoute(
          path: 'nuevo',
          name: 'menuNuevo',
          builder: (_, __) => const MenuItemFormScreen(),
        ),
        GoRoute(
          path: 'editar/:id',
          name: 'menuEditar',
          builder: (context, state) {
            final extra = state.extra;
            final item = extra is MenuItemDefinicion ? extra : null;
            return MenuItemFormScreen(item: item);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/panel',
      name: 'panel',
      redirect: (_, __) => '/panel/reportes',
    ),
    GoRoute(
      path: '/panel/reportes',
      name: 'panelReportes',
      builder: (_, __) => const PanelShell(child: PanelReportesScreen()),
    ),
    GoRoute(
      path: '/panel/cobros',
      name: 'panelCobros',
      builder: (_, __) => const PanelShell(child: PanelCobrosScreen()),
    ),
  ],
);

/// Wrapper que muestra [OrderFormScreen] en modo edición con [Pedido] pasado por extra o cargado por id.
class _EditOrderRouteWrapper extends StatefulWidget {
  final String? orderId;
  final Pedido? pedido;

  const _EditOrderRouteWrapper({this.orderId, this.pedido});

  @override
  State<_EditOrderRouteWrapper> createState() => _EditOrderRouteWrapperState();
}

class _EditOrderRouteWrapperState extends State<_EditOrderRouteWrapper> {
  Future<Pedido?> _loadPedido() async {
    if (widget.pedido != null) return widget.pedido;
    final id = int.tryParse(widget.orderId ?? '');
    if (id == null) return null;
    try {
      return await PedidoService.obtenerPorId(id);
    } catch (e, stackTrace) {
      debugPrint('Error loading pedido: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow; // Let the errorBuilder handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pedido != null) {
      return OrderFormScreen(pedido: widget.pedido!);
    }
    return FutureBuilder<Pedido?>(
      future: _loadPedido(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        final pedido = snapshot.data;
        if (pedido == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text(
                'Pedido no encontrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: Text(
                'No se encontró el pedido.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return OrderFormScreen(pedido: pedido);
      },
    );
  }
}

/// Wrapper que muestra [AddProductScreen] con [Producto] pasado por extra o cargado por id.
class _EditProductRouteWrapper extends StatefulWidget {
  final String? productId;
  final Producto? product;

  const _EditProductRouteWrapper({this.productId, this.product});

  @override
  State<_EditProductRouteWrapper> createState() =>
      _EditProductRouteWrapperState();
}

class _EditProductRouteWrapperState extends State<_EditProductRouteWrapper> {
  Future<Producto?> _loadProducto() async {
    if (widget.product != null) return widget.product;
    final id = int.tryParse(widget.productId ?? '');
    if (id == null) return null;
    try {
      return await ProductoService.obtenerPorId(id);
    } catch (e, stackTrace) {
      debugPrint('Error loading producto: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow; // Let the errorBuilder handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product != null) {
      return AddProductScreen(producto: widget.product);
    }
    final id = int.tryParse(widget.productId ?? '');
    if (id == null) {
      return const AddProductScreen();
    }
    return FutureBuilder<Producto?>(
      future: _loadProducto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Product load error: ${snapshot.error}');
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Error al cargar el producto. Por favor, inténtelo nuevamente.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return AddProductScreen(producto: snapshot.data);
      },
    );
  }
}
