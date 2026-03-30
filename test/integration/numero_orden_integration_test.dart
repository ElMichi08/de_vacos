import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/services/pedido_service.dart';
import 'dart:developer' show log;

/// Helper para crear un pedido rápido
Pedido _pedidoRapido({double total = 10.0, String estadoPago = 'Pendiente'}) {
  return Pedido(
    numeroOrden: 0,
    cliente: 'Test',
    celular: '',
    metodoPago: 'Efectivo',
    estado: 'En preparación',
    estadoPago: estadoPago,
    productos: [
      {'nombre': 'P', 'cantidad': 1, 'precio': total},
    ],
    fecha: DateTime.now(),
    total: total,
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
      'test_integration_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('Integración: Reinicio diario', () {
    test('al cambiar de día, el reinicio ocurre y no hay duplicación', () async {
      // Crear 100 pedidos el día de hoy
      for (int i = 0; i < 100; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }

      // El siguiente número debe ser 1 (reinicio)
      final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num1, 1);

      // Simular cambio de día: modificar la fecha de los pedidos existentes al día anterior
      final db = await DBHelper.db;
      final ayer = DateTime.now().subtract(Duration(days: 1));
      await db.update('pedidos', {
        'fecha': ayer.toIso8601String(),
      }, where: '1=1');

      // Ahora, para el día de hoy, no debería haber pedidos activos
      final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num2, 1);

      // Crear un pedido nuevo para hoy
      final id = await PedidoService.guardar(_pedidoRapido());
      final pedido = await PedidoService.obtenerPorId(id);
      expect(pedido!.numeroOrden, 1);

      // Crear otro pedido para hoy
      final id2 = await PedidoService.guardar(_pedidoRapido());
      final pedido2 = await PedidoService.obtenerPorId(id2);
      expect(pedido2!.numeroOrden, 2);
    });
  });

  group('Integración: Reutilización de números cancelados después de reinicio', () {
    test(
      'cancelar números y verificar que se reutilizan después de reinicio diario',
      () async {
        // Crear 5 pedidos hoy
        final ids = <int>[];
        for (int i = 0; i < 5; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar pedidos 2 y 4
        await PedidoService.cancelar(ids[1]);
        await PedidoService.cancelar(ids[3]);

        // El siguiente número disponible debe ser 6 (porque 6 no está activo)
        final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num1, 6);

        // Crear pedido con número 6
        final id6 = await PedidoService.guardar(_pedidoRapido());
        final pedido6 = await PedidoService.obtenerPorId(id6);
        expect(pedido6!.numeroOrden, 6);

        // Cambiar de día: mover todos los pedidos al día anterior
        final db = await DBHelper.db;
        final ayer = DateTime.now().subtract(Duration(days: 1));
        await db.update('pedidos', {
          'fecha': ayer.toIso8601String(),
        }, where: '1=1');

        // Para hoy, no hay pedidos activos
        final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num2, 1);

        // Crear pedidos hoy, números deben ser secuenciales
        final idNuevo1 = await PedidoService.guardar(_pedidoRapido());
        final pedidoNuevo1 = await PedidoService.obtenerPorId(idNuevo1);
        expect(pedidoNuevo1!.numeroOrden, 1);

        // Cancelar el pedido 1
        await PedidoService.cancelar(idNuevo1);

        // El siguiente debe ser 2 (porque 1 está cancelado, max activo es 0, siguiente 1, pero 1 está activo? No, está cancelado, entonces debería ser 1? Verifiquemos)
        // Según lógica: maxOrden activo = 0, siguiente = 1, verificar unicidad: no hay pedidos activos con numeroOrden=1, entonces devuelve 1.
        final num3 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num3, 1); // Reutiliza el cancelado
      },
    );
  });

  group('Integración: Unicidad en ciclo de 100', () {
    test(
      'crear 100 pedidos, cancelar algunos, verificar que no hay duplicados',
      () async {
        // Crear 100 pedidos
        final ids = <int>[];
        for (int i = 0; i < 100; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar pedidos en posiciones impares
        for (int i = 0; i < ids.length; i += 2) {
          await PedidoService.cancelar(ids[i]);
        }

        // Verificar que no hay duplicados en pedidos activos
        final db = await DBHelper.db;
        final activos = await db.rawQuery(
          'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
        );
        expect(
          activos,
          isEmpty,
          reason: 'No debe haber números duplicados en pedidos activos',
        );

        // El siguiente número debe estar en el rango 1-100 y no estar activo
        final siguiente = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(siguiente, greaterThanOrEqualTo(1));
        expect(siguiente, lessThanOrEqualTo(100));

        // Crear 50 pedidos más (esto debería seguir el ciclo)
        for (int i = 0; i < 50; i++) {
          await PedidoService.guardar(_pedidoRapido());
        }

        // Verificar que aún no hay duplicados
        final activos2 = await db.rawQuery(
          'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
        );
        expect(
          activos2,
          isEmpty,
          reason: 'No debe haber duplicados después de más pedidos',
        );
      },
    );
  });

  group('Integración: Soft delete no afecta reinicio', () {
    test(
      'pedidos cancelados no cuentan como activos pero sus números están disponibles',
      () async {
        // Crear 10 pedidos
        final ids = <int>[];
        for (int i = 0; i < 10; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar todos
        for (final id in ids) {
          await PedidoService.cancelar(id);
        }

        // No hay pedidos activos, siguiente debe ser 1
        final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num1, 1);

        // Crear 100 pedidos nuevos (debería reiniciar ciclo después de 100)
        for (int i = 0; i < 100; i++) {
          await PedidoService.guardar(_pedidoRapido());
        }

        // El siguiente debe ser 1 (reinicio)
        final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num2, 1);
      },
    );
  });
}
