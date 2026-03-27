import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/widgets/order_detail_modal.dart';
import 'package:de_vacos/models/pedido.dart';

void main() {
  group('OrderDetailModal', () {
    late Pedido testPedido;

    setUp(() {
      testPedido = Pedido(
        id: 1,
        numeroOrden: 42,
        cliente: 'María García',
        celular: '099123456',
        metodoPago: 'Efectivo',
        estado: 'Listo',
        estadoPago: 'Cobrado',
        productos: [
          {'nombre': 'Hamburguesa', 'cantidad': 2, 'precio': 150.0},
          {'nombre': 'Papas', 'cantidad': 1, 'precio': 80.0},
        ],
        fecha: DateTime(2026, 3, 26, 14, 30),
        total: 380.0,
        envasesLlevar: 2,
      );
    });

    testWidgets('renderiza el modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.byType(OrderDetailModal), findsOneWidget);
    });

    testWidgets('muestra título Detalle del Pedido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.text('Detalle del Pedido'), findsOneWidget);
    });

    testWidgets('muestra número de orden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('muestra nombre del cliente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.text('María García'), findsOneWidget);
    });

    testWidgets('muestra método de pago', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.text('Método de pago:'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
    });

    testWidgets('muestra estado del pedido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.text('Estado:'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets('tiene botón de imprimir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.byIcon(Icons.print), findsOneWidget);
    });

    testWidgets('tiene botón de cerrar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OrderDetailModal(pedido: testPedido))),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
