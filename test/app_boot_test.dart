import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/app_router.dart';
import 'package:de_vacos/core/config/app_config.dart';
import 'package:de_vacos/core/config/branding_config.dart';
import 'package:de_vacos/main.dart';
import 'package:de_vacos/screens/home_screen.dart';

/// Arranque de la app (Opción A): sin depender de `.env`, `dotenv` ni `CLIENTE_ID` en este archivo.
/// Usa el mismo [VacosApp] / [appRouter] que producción.
///
/// **Contrato:** la ruta inicial es `/home` y muestra [HomeScreen] sin splash ni bloqueo.
void main() {
  setUp(() {
    AppConfig.initForTest(
      const BrandingConfig(
        appName: 'De Vacos Test',
        appSubtitle: 'Boot test',
        primary: Color(0xFFE65100),
        background: Color(0xFF121212),
        accent: Color(0xFFFF9800),
        cardBackground: Color(0xFF1E1E1E),
        features: BrandingConfig.defaultFeatureIds,
      ),
    );
  });

  tearDown(AppConfig.reset);

  testWidgets('VacosApp + appRouter terminan en HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const VacosApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(appRouter.state.matchedLocation, '/home');
  });
}
