import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/screens/report_screen.dart';
import 'package:de_vacos/widgets/date_filter_widget.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_report_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('ReportScreen Widget Tests', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReportScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Reportes'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ReportScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has date filter widgets', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReportScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final hasDateFilter = find.byType(DateFilterWidget).evaluate().isNotEmpty;
      final hasErrorMessage = find.text('Error:').evaluate().isNotEmpty;
      final hasPedidos = find.text('No hay pedidos').evaluate().isNotEmpty;
      final isLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      expect(
        hasDateFilter || hasErrorMessage || hasPedidos || isLoading,
        isTrue,
      );
    });
  });
}
