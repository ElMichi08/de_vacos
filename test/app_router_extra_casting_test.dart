import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/app_router.dart';
import 'package:de_vacos/core/config/app_config.dart';
import 'package:de_vacos/core/config/branding_config.dart';
import 'package:de_vacos/main.dart';
import 'package:de_vacos/screens/add_product_screen.dart';

/// Navegación con `path` no numérico y `extra` de tipo incorrecto: los wrappers
/// usan `is Producto` / `is Pedido` y [int.tryParse]; no deben producir TypeError.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.initForTest(
      const BrandingConfig(
        appName: 'De Vacos Router Test',
        appSubtitle: 'extra casting',
        primary: Color(0xFFE65100),
        background: Color(0xFF121212),
        accent: Color(0xFFFF9800),
        cardBackground: Color(0xFF1E1E1E),
        features: BrandingConfig.defaultFeatureIds,
      ),
    );
  });

  tearDown(() {
    AppConfig.reset();
    appRouter.go('/home');
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(const VacosApp());
    await tester.pump();
    appRouter.go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  testWidgets(
    '/productos/editar/<idNoInt> con extra incorrecto muestra AddProductScreen (Nuevo Producto)',
    (WidgetTester tester) async {
      await pumpHome(tester);

      appRouter.go(
        '/productos/editar/not-an-int',
        extra: <String, Object>{'wrong': true},
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(find.text('Nuevo Producto'), findsOneWidget);
    },
  );

  testWidgets(
    '/pedidos/<idNoInt>/editar con extra incorrecto muestra Pedido no encontrado',
    (WidgetTester tester) async {
      await pumpHome(tester);

      appRouter.go(
        '/pedidos/NaN/editar',
        extra: 999, // no es Pedido
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Pedido no encontrado'), findsOneWidget);
      expect(find.text('No se encontró el pedido.'), findsOneWidget);
    },
  );
}
