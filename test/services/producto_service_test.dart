import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/producto.dart';
import 'package:de_vacos/services/producto_service.dart';

/// Helper para crear un producto de prueba rápido
Producto _productoFactory({
  String nombre = 'Producto Test',
  double precio = 10.0,
  String imagenPath = '/test/image.png',
}) {
  return Producto(
    nombre: nombre,
    precio: precio,
    imagenPath: imagenPath,
  );
}

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_producto_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ─── 3.1 CRUD ────────────────────────────────────────────────────────

  group('ProductoService CRUD', () {
    test('guardar() inserta producto y retorna id', () async {
      final id = await ProductoService.guardar(
          _productoFactory(nombre: 'Asado'));
      expect(id, greaterThan(0));
    });

    test('obtenerTodos() lista solo activos ordenados por nombre', () async {
      await ProductoService.guardar(_productoFactory(nombre: 'Zebra'));
      await ProductoService.guardar(_productoFactory(nombre: 'Alitas'));
      await ProductoService.guardar(_productoFactory(nombre: 'Morcilla'));

      final productos = await ProductoService.obtenerTodos();
      expect(productos.length, 3);
      expect(productos[0].nombre, 'Alitas');
      expect(productos[1].nombre, 'Morcilla');
      expect(productos[2].nombre, 'Zebra');
    });

    test('obtenerPorId() retorna producto correcto', () async {
      final id = await ProductoService.guardar(
          _productoFactory(nombre: 'Parrilla'));
      final producto = await ProductoService.obtenerPorId(id);
      expect(producto, isNotNull);
      expect(producto!.nombre, 'Parrilla');
      expect(producto.id, id);
    });

    test('actualizar() modifica nombre y precio', () async {
      final id = await ProductoService.guardar(
          _productoFactory(nombre: 'Original', precio: 5.0));
      final original = await ProductoService.obtenerPorId(id);

      final modificado = original!.copyWith(
        nombre: 'Modificado',
        precio: 15.0,
      );
      final rows = await ProductoService.actualizar(modificado);
      expect(rows, 1);

      final actualizado = await ProductoService.obtenerPorId(id);
      expect(actualizado!.nombre, 'Modificado');
      expect(actualizado.precio, 15.0);
    });
  });

  // ─── 3.2 Soft delete ──────────────────────────────────────────────────

  group('ProductoService soft delete', () {
    test('desactivar() marca cancelado=1', () async {
      final id = await ProductoService.guardar(_productoFactory());
      await ProductoService.desactivar(id);

      final producto = await ProductoService.obtenerPorId(id);
      expect(producto!.cancelado, true);
    });

    test('producto desactivado NO aparece en obtenerTodos()', () async {
      final id1 = await ProductoService.guardar(
          _productoFactory(nombre: 'Activo'));
      final id2 = await ProductoService.guardar(
          _productoFactory(nombre: 'Desactivado'));
      await ProductoService.desactivar(id2);

      final todos = await ProductoService.obtenerTodos();
      expect(todos.length, 1);
      expect(todos[0].id, id1);
    });

    test('producto desactivado SÍ aparece con obtenerPorId()', () async {
      final id = await ProductoService.guardar(_productoFactory());
      await ProductoService.desactivar(id);

      final producto = await ProductoService.obtenerPorId(id);
      expect(producto, isNotNull);
      expect(producto!.cancelado, true);
    });
  });

  // ─── 3.3 Eliminación permanente ───────────────────────────────────────

  group('ProductoService eliminación permanente', () {
    test('eliminar() borra registro', () async {
      final id = await ProductoService.guardar(_productoFactory());
      final rows = await ProductoService.eliminar(id);
      expect(rows, 1);
    });

    test('obtenerPorId() retorna null después de eliminar', () async {
      final id = await ProductoService.guardar(_productoFactory());
      await ProductoService.eliminar(id);

      final producto = await ProductoService.obtenerPorId(id);
      expect(producto, isNull);
    });
  });

  // ─── 3.4 Validación ──────────────────────────────────────────────────

  group('ProductoService validación', () {
    test('guardar producto con nombre vacío → Exception', () async {
      expect(
        () async => await ProductoService.guardar(
            _productoFactory(nombre: '')),
        throwsException,
      );
    });

    test('guardar producto con precio <= 0 → Exception', () async {
      expect(
        () async => await ProductoService.guardar(
            _productoFactory(precio: 0)),
        throwsException,
      );
    });
  });
}
