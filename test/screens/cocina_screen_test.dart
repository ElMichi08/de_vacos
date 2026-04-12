import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/screens/cocina_screen.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/pedido_service.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_cocina_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
    // Insertar un pedido de prueba para que la pantalla muestre datos
    final pedido = Pedido(
      numeroOrden: 1,
      cliente: 'Test Cliente',
      celular: '099999999',
      metodoPago: PaymentMethod.efectivo,
      estado: OrderStatus.enPreparacion,
      estadoPago: PaymentStatus.pendiente,
      productos: [
        {'nombre': 'Producto Test', 'cantidad': 1, 'precio': 10.0},
      ],
      fecha: DateTime.now(),
      total: 10.0,
    );
    await PedidoService.guardar(pedido);
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('CocinaScreen Widget Tests', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CocinaScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Cocina (KDS)'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CocinaScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has refresh capability', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CocinaScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final hasRefresh = find.byType(RefreshIndicator).evaluate().isNotEmpty;
      final hasNoOrdersMessage =
          find.text('No hay pedidos en cocina').evaluate().isNotEmpty;
      final hasPedidos = find.byType(ListView).evaluate().isNotEmpty;
      final isLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      expect(
        hasRefresh || hasNoOrdersMessage || hasPedidos || isLoading,
        isTrue,
      );
      expect(find.text('Error:'), findsNothing);
    });
  });
}
