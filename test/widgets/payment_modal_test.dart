import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/widgets/payment_modal.dart';

void main() {
  group('PaymentModal', () {
    testWidgets('renderiza el modal correctamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 150.00,
              cliente: 'Juan Pérez',
              numeroOrden: 5,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentModal), findsOneWidget);
    });

    testWidgets('muestra el nombre del cliente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      expect(find.text('Test Cliente'), findsOneWidget);
    });

    testWidgets('muestra el total a pagar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      expect(find.text('\$100.00'), findsOneWidget);
    });

    testWidgets('tiene campo de texto para dinero recibido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('acepta entrada numérica', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '150');
      await tester.pump();

      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('botón cobrar existe', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      expect(find.text('Cobrar'), findsOneWidget);
    });

    testWidgets('botón cancelar existe', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              totalAPagar: 100.00,
              cliente: 'Test Cliente',
              numeroOrden: 1,
            ),
          ),
        ),
      );

      expect(find.text('Cancelar'), findsOneWidget);
    });
  });
}
