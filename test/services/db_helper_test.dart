import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_db_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('DBHelper esquema', () {
    test('tabla productos existe con columnas esperadas', () async {
      final db = await DBHelper.db;
      final info = await db.rawQuery('PRAGMA table_info(productos)');
      final columnas = info.map((r) => r['name'] as String).toList();
      expect(columnas, contains('id'));
      expect(columnas, contains('nombre'));
      expect(columnas, contains('precio'));
      expect(columnas, contains('imagenPath'));
      expect(columnas, contains('cancelado'));
    });

    test('tabla pedidos existe con columnas esperadas', () async {
      final db = await DBHelper.db;
      final info = await db.rawQuery('PRAGMA table_info(pedidos)');
      final columnas = info.map((r) => r['name'] as String).toList();
      expect(columnas, contains('id'));
      expect(columnas, contains('numeroOrden'));
      expect(columnas, contains('estado'));
      expect(columnas, contains('estadoPago'));
      expect(columnas, contains('cancelado'));
    });

    test('tabla insumos existe con columnas esperadas', () async {
      final db = await DBHelper.db;
      final info = await db.rawQuery('PRAGMA table_info(insumos)');
      final columnas = info.map((r) => r['name'] as String).toList();
      expect(columnas, contains('id'));
      expect(columnas, contains('nombre'));
      expect(columnas, contains('unidadMedida'));
      expect(columnas, contains('cantidadActual'));
      expect(columnas, contains('cantidadMinima'));
      expect(columnas, contains('costoUnitario'));
      expect(columnas, contains('cancelado'));
    });

    test('tabla receta_detalle existe con columnas esperadas', () async {
      final db = await DBHelper.db;
      final info = await db.rawQuery('PRAGMA table_info(receta_detalle)');
      final columnas = info.map((r) => r['name'] as String).toList();
      expect(columnas, contains('producto_id'));
      expect(columnas, contains('insumo_id'));
      expect(columnas, contains('cantidad'));
    });

    test('tabla caja_movimientos existe', () async {
      final db = await DBHelper.db;
      final info = await db.rawQuery('PRAGMA table_info(caja_movimientos)');
      final columnas = info.map((r) => r['name'] as String).toList();
      expect(columnas, contains('id'));
      expect(columnas, contains('tipo'));
      expect(columnas, contains('valor'));
    });
  });
}
