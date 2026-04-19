import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/pedido_service.dart';

/// Helper para crear un pedido rápido
Pedido _pedidoRapido({
  double total = 10.0,
  PaymentStatus estadoPago = PaymentStatus.pendiente,
}) {
  return Pedido(
    numeroOrden: 0,
    cliente: 'Test',
    celular: '',
    metodoPago: PaymentMethod.efectivo,
    estado: OrderStatus.enPreparacion,
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

      // Sin ciclo: 100 pedidos → siguiente = 101
      final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num1, 101);

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

  group('Integración: Números cancelados no se reutilizan entre ni dentro de días', () {
    test(
      'números cancelados no se reutilizan; nuevo día reinicia desde 1 (UC-NUM-02, UC-NUM-04)',
      () async {
        // Crear 5 pedidos hoy (#1–5)
        final ids = <int>[];
        for (int i = 0; i < 5; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar #2 y #4 — high-water mark del día sigue siendo 5
        await PedidoService.cancelar(ids[1]);
        await PedidoService.cancelar(ids[3]);

        // Siguiente = high-water mark (5) + 1 = 6
        final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num1, 6);

        // Crear pedido #6
        final id6 = await PedidoService.guardar(_pedidoRapido());
        final pedido6 = await PedidoService.obtenerPorId(id6);
        expect(pedido6!.numeroOrden, 6);

        // Cambiar de día: mover todos los pedidos al día anterior
        final db = await DBHelper.db;
        final ayer = DateTime.now().subtract(Duration(days: 1));
        await db.update('pedidos', {'fecha': ayer.toIso8601String()}, where: '1=1');

        // Nuevo día → MAX de hoy = 0 → siguiente = 1 (reinicio implícito, UC-NUM-04)
        final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num2, 1);

        // Primer pedido del nuevo día es #1
        final idNuevo1 = await PedidoService.guardar(_pedidoRapido());
        final pedidoNuevo1 = await PedidoService.obtenerPorId(idNuevo1);
        expect(pedidoNuevo1!.numeroOrden, 1);

        // Cancelar el #1 del nuevo día
        await PedidoService.cancelar(idNuevo1);

        // Siguiente debe ser 2 — el #1 cancelado NO se reutiliza
        final num3 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num3, 2);
      },
    );
  });

  group('Integración: Unicidad sin límite superior (UC-NUM-01)', () {
    test(
      'crear 100 pedidos, cancelar algunos, verificar no duplicados y secuencia continúa más allá de 100',
      () async {
        // Crear 100 pedidos (#1–100)
        final ids = <int>[];
        for (int i = 0; i < 100; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar pedidos en posiciones pares (indices 0, 2, 4…)
        for (int i = 0; i < ids.length; i += 2) {
          await PedidoService.cancelar(ids[i]);
        }

        // No debe haber duplicados en pedidos activos
        final db = await DBHelper.db;
        final activos = await db.rawQuery(
          'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
        );
        expect(activos, isEmpty, reason: 'No debe haber números duplicados en pedidos activos');

        // El siguiente debe ser 101 (high-water mark = 100, sin ciclo)
        final siguiente = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(siguiente, 101);

        // Crear 50 pedidos más (#101–150)
        for (int i = 0; i < 50; i++) {
          await PedidoService.guardar(_pedidoRapido());
        }

        // Aún sin duplicados
        final activos2 = await db.rawQuery(
          'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
        );
        expect(activos2, isEmpty, reason: 'No debe haber duplicados después de más pedidos');

        // El siguiente debe ser 151
        final siguiente2 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(siguiente2, 151);
      },
    );
  });

  group('Integración: Soft delete no recicla números (UC-NUM-02, UC-NUM-03)', () {
    test(
      'cancelar todos los pedidos del día no reinicia el contador',
      () async {
        // Crear 10 pedidos (#1–10)
        final ids = <int>[];
        for (int i = 0; i < 10; i++) {
          ids.add(await PedidoService.guardar(_pedidoRapido()));
        }

        // Cancelar todos (UC-NUM-03: todos cancelados)
        for (final id in ids) {
          await PedidoService.cancelar(id);
        }

        // High-water mark = 10 → siguiente = 11 (no resetea a 1)
        final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num1, 11);

        // Crear 100 pedidos más (#11–110)
        for (int i = 0; i < 100; i++) {
          await PedidoService.guardar(_pedidoRapido());
        }

        // High-water mark = 110 → siguiente = 111 (sin ciclo)
        final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
        expect(num2, 111);
      },
    );
  });
}
