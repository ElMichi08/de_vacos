import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/widgets/product_card_widget.dart';
import 'package:de_vacos/models/producto.dart';

void main() {
  group('ProductCardWidget', () {
    late Producto testProducto;

    setUp(() {
      testProducto = Producto(
        id: 1,
        nombre: 'Hamburguesa Clásica',
        precio: 150.0,
        imagenPath: '',
      );
    });

    testWidgets('muestra nombre del producto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(producto: testProducto, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Hamburguesa Clásica'), findsOneWidget);
    });

    testWidgets('muestra precio formateado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(producto: testProducto, onTap: () {}),
          ),
        ),
      );

      expect(find.text('\$150.00'), findsOneWidget);
    });

    testWidgets('llama onTap al tocar el card', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('muestra cantidad cuando es mayor a 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              cantidad: 3,
              onTap: () {},
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('no muestra controles de cantidad cuando cantidad es 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              cantidad: 0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('muestra controles de cantidad cuando cantidad > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              cantidad: 2,
              onTap: () {},
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('llama onIncrement al presionar botón +', (tester) async {
      bool incremented = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              cantidad: 1,
              onTap: () {},
              onIncrement: () => incremented = true,
              onDecrement: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(incremented, isTrue);
    });

    testWidgets('llama onDecrement al presionar botón -', (tester) async {
      bool decremented = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(
              producto: testProducto,
              cantidad: 1,
              onTap: () {},
              onIncrement: () {},
              onDecrement: () => decremented = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      expect(decremented, isTrue);
    });

    testWidgets('muestra ícono cuando no tiene imagen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardWidget(producto: testProducto, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });
}
