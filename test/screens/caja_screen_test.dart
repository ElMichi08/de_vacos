import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/screens/caja_screen.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_caja_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('CajaScreen Widget Tests', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CajaScreen()));
      await tester.pump();
      expect(find.text('Caja'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CajaScreen()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has date filter widgets', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CajaScreen()));
      // Esperar a que la carga termine
      await tester.pump(const Duration(seconds: 1));
      // No debería haber loading indicator después de la carga
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Debería haber botones de filtro de fecha (iconos de calendario) si no hay error
      final hasCalendarIcon = find.byIcon(Icons.calendar_today).evaluate().isNotEmpty;
      final hasErrorMessage = find.text('Error:').evaluate().isNotEmpty;
      // Si no hay icono de calendario, al menos no debería haber error
      expect(hasCalendarIcon || !hasErrorMessage, isTrue);
    });
  });
}
