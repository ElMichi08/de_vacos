import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/caja.dart';
import 'package:de_vacos/services/caja_service.dart';

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

  // ─── 2.1 CRUD ────────────────────────────────────────────────────────

  group('CajaService CRUD', () {
    test('guardar() crea movimiento y retorna id > 0', () async {
      final mov = Caja(
        descripcion: 'Ingreso test',
        tipo: 'Ingreso',
        valor: 100.0,
        fecha: DateTime.now(),
      );
      final id = await CajaService.guardar(mov);
      expect(id, greaterThan(0));
    });

    test('obtenerPorFecha retorna movimientos del día', () async {
      final hoy = DateTime.now();
      await CajaService.guardar(Caja(
        descripcion: 'Ingreso hoy',
        tipo: 'Ingreso',
        valor: 50.0,
        fecha: hoy,
      ));
      await CajaService.guardar(Caja(
        descripcion: 'Egreso hoy',
        tipo: 'Egreso',
        valor: 20.0,
        fecha: hoy,
      ));

      final movimientos = await CajaService.obtenerPorFecha(hoy);
      expect(movimientos.length, 2);
    });

    test('actualizar() modifica descripcion y valor', () async {
      final hoy = DateTime.now();
      final id = await CajaService.guardar(Caja(
        descripcion: 'Original',
        tipo: 'Ingreso',
        valor: 100.0,
        fecha: hoy,
      ));

      final modificado = Caja(
        id: id,
        descripcion: 'Modificado',
        tipo: 'Ingreso',
        valor: 200.0,
        fecha: hoy,
      );
      final rows = await CajaService.actualizar(modificado);
      expect(rows, 1);

      final lista = await CajaService.obtenerPorFecha(hoy);
      final encontrado = lista.firstWhere((m) => m.id == id);
      expect(encontrado.descripcion, 'Modificado');
      expect(encontrado.valor, 200.0);
    });

    test('eliminar() borra el registro', () async {
      final hoy = DateTime.now();
      final id = await CajaService.guardar(Caja(
        descripcion: 'A borrar',
        tipo: 'Egreso',
        valor: 30.0,
        fecha: hoy,
      ));

      final rows = await CajaService.eliminar(id);
      expect(rows, 1);

      final lista = await CajaService.obtenerPorFecha(hoy);
      expect(lista.where((m) => m.id == id), isEmpty);
    });
  });

  // ─── 2.2 Regla de Caja Chica única por día ────────────────────────────

  group('CajaService regla Caja Chica única', () {
    test('guardar una Caja Chica → OK', () async {
      final id = await CajaService.guardar(Caja(
        descripcion: 'Caja Chica',
        tipo: 'Caja Chica',
        valor: 50.0,
        fecha: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('segunda Caja Chica mismo día → Exception', () async {
      await CajaService.guardar(Caja(
        descripcion: 'Caja Chica 1',
        tipo: 'Caja Chica',
        valor: 50.0,
        fecha: DateTime.now(),
      ));

      expect(
        () async => await CajaService.guardar(Caja(
          descripcion: 'Caja Chica 2',
          tipo: 'Caja Chica',
          valor: 100.0,
          fecha: DateTime.now(),
        )),
        throwsException,
      );
    });

    test('Caja Chica para día diferente → OK', () async {
      await CajaService.guardar(Caja(
        descripcion: 'Caja Chica hoy',
        tipo: 'Caja Chica',
        valor: 50.0,
        fecha: DateTime.now(),
      ));

      // Un día diferente (ayer)
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final id = await CajaService.guardar(Caja(
        descripcion: 'Caja Chica ayer',
        tipo: 'Caja Chica',
        valor: 100.0,
        fecha: ayer,
      ));
      expect(id, greaterThan(0));
    });
  });

  // ─── 2.3 Filtro por fecha y rango ─────────────────────────────────────

  group('CajaService filtro por rango de fechas', () {
    test('obtenerPorFecha con fechaFin retorna rango', () async {
      final hoy = DateTime.now();
      final ayer = hoy.subtract(const Duration(days: 1));

      await CajaService.guardar(Caja(
        descripcion: 'Ayer',
        tipo: 'Ingreso',
        valor: 10.0,
        fecha: ayer,
      ));
      await CajaService.guardar(Caja(
        descripcion: 'Hoy',
        tipo: 'Ingreso',
        valor: 20.0,
        fecha: hoy,
      ));

      final rango = await CajaService.obtenerPorFecha(ayer, fechaFin: hoy);
      expect(rango.length, 2);
    });

    test('eliminarPorFecha borra solo los de esa fecha', () async {
      final hoy = DateTime.now();
      final ayer = hoy.subtract(const Duration(days: 1));

      await CajaService.guardar(Caja(
        descripcion: 'Ayer',
        tipo: 'Ingreso',
        valor: 10.0,
        fecha: ayer,
      ));
      await CajaService.guardar(Caja(
        descripcion: 'Hoy',
        tipo: 'Ingreso',
        valor: 20.0,
        fecha: hoy,
      ));

      await CajaService.eliminarPorFecha(ayer);

      final movimientosAyer = await CajaService.obtenerPorFecha(ayer);
      final movimientosHoy = await CajaService.obtenerPorFecha(hoy);

      expect(movimientosAyer, isEmpty);
      expect(movimientosHoy.length, 1);
    });
  });
}
