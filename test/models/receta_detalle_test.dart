import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/models/receta_detalle.dart';

void main() {
  group('RecetaDetalle.fromMap', () {
    test('should parse valid map', () {
      final map = {'producto_id': 1, 'insumo_id': 2, 'cantidad': 3.5};
      final receta = RecetaDetalle.fromMap(map);
      expect(receta.productoId, 1);
      expect(receta.insumoId, 2);
      expect(receta.cantidad, 3.5);
    });

    test('should parse string numbers', () {
      final map = {'producto_id': '5', 'insumo_id': '6', 'cantidad': '7.25'};
      final receta = RecetaDetalle.fromMap(map);
      expect(receta.productoId, 5);
      expect(receta.insumoId, 6);
      expect(receta.cantidad, 7.25);
    });

    test('should throw FormatException when producto_id is null', () {
      final map = {'producto_id': null, 'insumo_id': 2, 'cantidad': 3.0};
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when insumo_id is null', () {
      final map = {'producto_id': 1, 'insumo_id': null, 'cantidad': 3.0};
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when cantidad is null', () {
      final map = {'producto_id': 1, 'insumo_id': 2, 'cantidad': null};
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when producto_id cannot be parsed', () {
      final map = {
        'producto_id': 'not_a_number',
        'insumo_id': 2,
        'cantidad': 3.0,
      };
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when insumo_id cannot be parsed', () {
      final map = {
        'producto_id': 1,
        'insumo_id': 'not_a_number',
        'cantidad': 3.0,
      };
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when cantidad cannot be parsed', () {
      final map = {
        'producto_id': 1,
        'insumo_id': 2,
        'cantidad': 'not_a_number',
      };
      expect(() => RecetaDetalle.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('should handle int cantidad', () {
      final map = {'producto_id': 1, 'insumo_id': 2, 'cantidad': 5};
      final receta = RecetaDetalle.fromMap(map);
      expect(receta.cantidad, 5.0);
    });
  });
}
