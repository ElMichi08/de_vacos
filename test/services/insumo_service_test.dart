import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/services/insumo_service.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_insumo_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ─── 4.1 CRUD ────────────────────────────────────────────────────────

  group('InsumoService CRUD', () {
    test('crear() inserta y retorna id', () async {
      final id = await InsumoService.crear(Insumo(
        nombre: 'Carne',
        unidadMedida: 'kg',
        cantidadActual: 10.0,
        cantidadMinima: 2.0,
      ));
      expect(id, greaterThan(0));
    });

    test('listar() retorna solo activos', () async {
      await InsumoService.crear(Insumo(
        nombre: 'Aceite',
        unidadMedida: 'litros',
        cantidadActual: 5.0,
      ));
      await InsumoService.crear(Insumo(
        nombre: 'Sal',
        unidadMedida: 'kg',
        cantidadActual: 1.0,
      ));

      final lista = await InsumoService.listar();
      expect(lista.length, 2);
    });

    test('obtenerPorId() correcto', () async {
      final id = await InsumoService.crear(Insumo(
        nombre: 'Arroz',
        unidadMedida: 'kg',
        cantidadActual: 20.0,
        cantidadMinima: 5.0,
        costoUnitario: 1.50,
      ));

      final insumo = await InsumoService.obtenerPorId(id);
      expect(insumo, isNotNull);
      expect(insumo!.nombre, 'Arroz');
      expect(insumo.unidadMedida, 'kg');
      expect(insumo.cantidadActual, 20.0);
      expect(insumo.costoUnitario, 1.50);
    });

    test('actualizar() modifica campos', () async {
      final id = await InsumoService.crear(Insumo(
        nombre: 'Papas',
        unidadMedida: 'kg',
        cantidadActual: 10.0,
      ));

      final original = await InsumoService.obtenerPorId(id);
      final modificado = original!.copyWith(
        cantidadActual: 5.0,
        cantidadMinima: 3.0,
      );
      final rows = await InsumoService.actualizar(modificado);
      expect(rows, 1);

      final actualizado = await InsumoService.obtenerPorId(id);
      expect(actualizado!.cantidadActual, 5.0);
      expect(actualizado.cantidadMinima, 3.0);
    });
  });

  // ─── 4.2 Soft delete ──────────────────────────────────────────────────

  group('InsumoService soft delete', () {
    test('eliminar() marca cancelado=1', () async {
      final id = await InsumoService.crear(Insumo(
        nombre: 'A eliminar',
        unidadMedida: 'unidades',
      ));
      final rows = await InsumoService.eliminar(id);
      expect(rows, 1);
    });

    test('insumo eliminado no aparece en listar()', () async {
      final id1 = await InsumoService.crear(Insumo(
        nombre: 'Activo',
        unidadMedida: 'kg',
      ));
      final id2 = await InsumoService.crear(Insumo(
        nombre: 'Oculto',
        unidadMedida: 'litros',
      ));
      await InsumoService.eliminar(id2);

      final lista = await InsumoService.listar();
      expect(lista.length, 1);
      expect(lista[0].id, id1);
    });
  });

  // ─── 4.3 Validación ──────────────────────────────────────────────────

  group('InsumoService validación', () {
    test('crear insumo con nombre vacío → Exception', () async {
      expect(
        () async => await InsumoService.crear(Insumo(
          nombre: '',
          unidadMedida: 'kg',
        )),
        throwsException,
      );
    });

    test('crear insumo con unidad vacía → Exception', () async {
      expect(
        () async => await InsumoService.crear(Insumo(
          nombre: 'Test',
          unidadMedida: '',
        )),
        throwsException,
      );
    });
  });
}
