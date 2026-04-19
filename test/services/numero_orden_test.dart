import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/pedido_service.dart';
import 'dart:developer' show log;

/// Helper para crear un pedido rápido
Pedido _pedidoRapido({double total = 10.0, PaymentStatus estadoPago = PaymentStatus.pendiente}) {
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
      'test_numorden_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ─── 5.1 Secuencial ──────────────────────────────────────────────────

  group('obtenerSiguienteNumeroOrden secuencial', () {
    test('sin pedidos → retorna 1', () async {
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 1);
    });

    test('con 1 pedido activo → retorna 2', () async {
      await PedidoService.guardar(_pedidoRapido());
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 2);
    });

    test('con 99 pedidos → retorna 100', () async {
      for (int i = 0; i < 99; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 100);
    });

    test('con 100 pedidos → retorna 101 (sin ciclo)', () async {
      for (int i = 0; i < 100; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 101);
    });

    test('con 150 pedidos → retorna 151', () async {
      for (int i = 0; i < 150; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 151);
    });
  });

  // ─── 5.2 Con cancelados ───────────────────────────────────────────────

  group('obtenerSiguienteNumeroOrden con cancelados', () {
    test('3 pedidos, cancelar 1 → siguiente = 4', () async {
      final ids = <int>[];
      for (int i = 0; i < 3; i++) {
        ids.add(await PedidoService.guardar(_pedidoRapido()));
      }
      await PedidoService.cancelar(ids[1]);

      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      // El máximo fue 3, por lo tanto el siguiente debe ser 4, a pesar de la cancelación.
      expect(num, 4);

      // Verificar si causa duplicación
      final nuevoId = await PedidoService.guardar(_pedidoRapido());
      final nuevo = await PedidoService.obtenerPorId(nuevoId);
      final tercero = await PedidoService.obtenerPorId(ids[2]);

      log('Pedido original #3: numeroOrden=${tercero!.numeroOrden}');
      log('Pedido nuevo: numeroOrden=${nuevo!.numeroOrden}');
      log('¿Duplicado? ${tercero.numeroOrden == nuevo.numeroOrden}');
    });

    test('números cancelados NO se reutilizan (UC-NUM-02)', () async {
      // Crear 5 pedidos (#1–5)
      final ids = <int>[];
      for (int i = 0; i < 5; i++) {
        ids.add(await PedidoService.guardar(_pedidoRapido()));
      }

      // Cancelar #2 y #4 — el high-water mark del día sigue siendo 5
      await PedidoService.cancelar(ids[1]); // numeroOrden = 2
      await PedidoService.cancelar(ids[3]); // numeroOrden = 4

      // Siguiente = MAX(todos incluido cancelados) + 1 = 5 + 1 = 6
      final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num1, 6);

      // Crear #6 y cancelarlo — el high-water mark pasa a 6
      final id6 = await PedidoService.guardar(_pedidoRapido());
      final pedido6 = await PedidoService.obtenerPorId(id6);
      expect(pedido6!.numeroOrden, 6);
      await PedidoService.cancelar(id6);

      // Siguiente debe ser 7, NO 6 (el 6 fue cancelado pero no se reutiliza)
      final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num2, 7);

      // Cancelar todos los activos restantes
      for (final id in ids) {
        await PedidoService.cancelar(id);
      }

      // Aunque no hay pedidos activos, el high-water mark del día es 6 → siguiente = 7
      final num3 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num3, 7);
    });

    test('nuevos pedidos continúan desde el máximo, sin rellenar huecos', () async {
      // Crear 10 pedidos (#1–10) y cancelar los de posición impar (#2,#4,#6,#8,#10)
      final ids = <int>[];
      for (int i = 0; i < 10; i++) {
        ids.add(await PedidoService.guardar(_pedidoRapido()));
      }
      for (int i = 1; i < ids.length; i += 2) {
        await PedidoService.cancelar(ids[i]); // cancela #2, #4, #6, #8, #10
      }

      // El high-water mark es 10 → siguiente = 11 (sin rellenar #2, #4, #6, #8, #10)
      final siguienteEsperado = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(siguienteEsperado, 11);

      // Crear 5 pedidos más: deben ser #11, #12, #13, #14, #15
      final nuevosIds = <int>[];
      for (int i = 0; i < 5; i++) {
        nuevosIds.add(await PedidoService.guardar(_pedidoRapido()));
      }

      final db = await DBHelper.db;
      final nuevos = await Future.wait(
        nuevosIds.map((id) => PedidoService.obtenerPorId(id)),
      );
      final numerosNuevos = nuevos.map((p) => p!.numeroOrden).toList();
      expect(numerosNuevos, [11, 12, 13, 14, 15]);

      // No debe haber duplicados en pedidos activos
      final duplicados = await db.rawQuery(
        'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
      );
      expect(duplicados, isEmpty, reason: 'No debe haber números duplicados en pedidos activos');

      // Los huecos (2, 4, 6, 8, 10) no fueron reutilizados
      final numerosActivos = await db.rawQuery(
        'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 ORDER BY numeroOrden',
      );
      final nums = numerosActivos.map((r) => r['numeroOrden'] as int).toSet();
      expect(nums.contains(2), isFalse, reason: '#2 fue cancelado y no debe reaparecer');
      expect(nums.contains(4), isFalse, reason: '#4 fue cancelado y no debe reaparecer');
    });
  });

  // ─── 5.3 Auditoría semanal ────────────────────────────────────────────

  group('obtenerAuditoriaSemanal', () {
    test('retorna cantidad y total correctos solo pedidos cobrados', () async {
      // Crear 3 pedidos, cobrar 2
      final id1 = await PedidoService.guardar(_pedidoRapido(total: 10.0));
      final id2 = await PedidoService.guardar(_pedidoRapido(total: 20.0));
      await PedidoService.guardar(_pedidoRapido(total: 30.0)); // pendiente

      await PedidoService.actualizarEstadoPago(id1, 'Cobrado');
      await PedidoService.actualizarEstadoPago(id2, 'Cobrado');

      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      final audit = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
      expect(audit['cantidad'], 2);
      expect(audit['total'], 30.0); // 10 + 20
    });

    test('no cuenta pedidos cancelados aunque estén cobrados', () async {
      final id1 = await PedidoService.guardar(_pedidoRapido(total: 50.0));
      await PedidoService.actualizarEstadoPago(id1, 'Cobrado');
      await PedidoService.cancelar(id1);

      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      final audit = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
      expect(audit['cantidad'], 0);
      expect(audit['total'], 0.0);
    });
  });

  // ─── 5.4 Top productos ───────────────────────────────────────────────

  group('obtenerTopProductosPorVentas', () {
    test('con 3+ productos distintos → retorna top 3', () async {
      // Crear pedidos con diferentes productos
      final productos1 = [
        {'nombre': 'Asado', 'cantidad': 5, 'precio': 10.0},
      ];
      final productos2 = [
        {'nombre': 'Pollo', 'cantidad': 3, 'precio': 8.0},
      ];
      final productos3 = [
        {'nombre': 'Costilla', 'cantidad': 7, 'precio': 12.0},
      ];
      final productos4 = [
        {'nombre': 'Morcilla', 'cantidad': 1, 'precio': 5.0},
      ];

      for (final prods in [productos1, productos2, productos3, productos4]) {
        final id = await PedidoService.guardar(
          Pedido(
            numeroOrden: 0,
            cliente: 'Test',
            celular: '',
            metodoPago: PaymentMethod.efectivo,
            estado: OrderStatus.enPreparacion,
            estadoPago: PaymentStatus.pendiente,
            productos: prods,
            fecha: DateTime.now(),
            total:
                (prods[0]['precio'] as double) * (prods[0]['cantidad'] as int),
          ),
        );
        await PedidoService.actualizarEstadoPago(id, 'Cobrado');
      }

      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      final top = await DBHelper.obtenerTopProductosPorVentas(inicio, fin);
      expect(top.length, 3);
      // Costilla (7) > Asado (5) > Pollo (3) > Morcilla (1)
      expect(top[0]['nombre'], 'Costilla');
      expect(top[1]['nombre'], 'Asado');
      expect(top[2]['nombre'], 'Pollo');
    });

    test('con 0 pedidos → retorna lista vacía', () async {
      final hoy = DateTime.now();
      final top = await DBHelper.obtenerTopProductosPorVentas(
        DateTime(hoy.year, hoy.month, hoy.day),
        DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999),
      );
      expect(top, isEmpty);
    });
  });

  // ─── 5.5 Concurrencia ─────────────────────────────────────────────
  group('obtenerSiguienteNumeroOrden concurrencia', () {
    test('dos inserciones simultáneas no duplican números', () async {
      // Usar dos futures paralelas que inserten pedidos
      final futures = List.generate(2, (_) async {
        return await PedidoService.guardar(_pedidoRapido());
      });
      final ids = await Future.wait(futures);
      expect(ids.length, 2);
      expect(ids[0], isNot(equals(ids[1])));

      // Obtener los pedidos y verificar que sus números de orden son distintos
      final pedido1 = await PedidoService.obtenerPorId(ids[0]);
      final pedido2 = await PedidoService.obtenerPorId(ids[1]);
      expect(pedido1, isNotNull);
      expect(pedido2, isNotNull);
      expect(pedido1!.numeroOrden, isNot(equals(pedido2!.numeroOrden)));
    });

    test('transacción serializa asignación de números', () async {
      // Simular dos transacciones que leen y escriben concurrentemente
      final db = await DBHelper.db;
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();

      // Iniciar dos transacciones que se solapan en tiempo
      final transaction1 = db.transaction((txn) async {
        final num = await DBHelper.obtenerSiguienteNumeroOrden(txn: txn);
        // Simular algún trabajo
        await Future.delayed(Duration(milliseconds: 50));
        completer1.complete(num);
        // Esperar a que la otra transacción también lea (para forzar solapamiento)
        await Future.delayed(Duration(milliseconds: 100));
        // Insertar pedido con ese número (simulado)
        await txn.insert('pedidos', {
          'numeroOrden': num,
          'cliente': 'Test1',
          'celular': '',
          'metodoPago': 'Efectivo',
          'estado': 'En preparación',
          'estadoPago': 'Pendiente',
          'productos': '[]',
          'fecha': DateTime.now().toIso8601String(),
          'total': 10.0,
          'cancelado': 0,
        });
      });

      final transaction2 = db.transaction((txn) async {
        final num = await DBHelper.obtenerSiguienteNumeroOrden(txn: txn);
        await Future.delayed(Duration(milliseconds: 50));
        completer2.complete(num);
        await Future.delayed(Duration(milliseconds: 100));
        await txn.insert('pedidos', {
          'numeroOrden': num,
          'cliente': 'Test2',
          'celular': '',
          'metodoPago': 'Efectivo',
          'estado': 'En preparación',
          'estadoPago': 'Pendiente',
          'productos': '[]',
          'fecha': DateTime.now().toIso8601String(),
          'total': 10.0,
          'cancelado': 0,
        });
      });

      // Esperar a que ambas transacciones terminen
      await Future.wait([transaction1, transaction2]);

      final num1 = await completer1.future;
      final num2 = await completer2.future;
      expect(num1, isNot(equals(num2)));

      // Verificar que no hay números duplicados en la tabla
      final duplicados = await db.rawQuery(
        'SELECT numeroOrden, COUNT(*) as count FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING count > 1',
      );
      expect(duplicados, isEmpty);
    });

    test('concurrencia con transacción exclusiva no duplica números', () async {
      // Dos transacciones exclusivas concurrentes que obtienen número e insertan
      final db = await DBHelper.db;
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();

      Future<void> proceso(int id) async {
        // Iniciar transacción exclusiva
        await db.transaction((txn) async {
          // Obtener siguiente número dentro de la transacción exclusiva
          final num = await DBHelper.obtenerSiguienteNumeroOrden(txn: txn);
          // Simular trabajo con delay
          await Future.delayed(Duration(milliseconds: 30));
          // Insertar pedido con ese número dentro de la misma transacción
          await txn.insert('pedidos', {
            'numeroOrden': num,
            'cliente': 'Test$id',
            'celular': '',
            'metodoPago': 'Efectivo',
            'estado': 'En preparación',
            'estadoPago': 'Pendiente',
            'productos': '[]',
            'fecha': DateTime.now().toIso8601String(),
            'total': 10.0,
            'cancelado': 0,
          });
          if (id == 1) completer1.complete(num);
          if (id == 2) completer2.complete(num);
        }, exclusive: true);
      }

      // Iniciar dos procesos concurrentemente
      final futuro1 = proceso(1);
      final futuro2 = proceso(2);
      await Future.wait([futuro1, futuro2]);

      final num1 = await completer1.future;
      final num2 = await completer2.future;
      expect(num1, isNot(equals(num2)));

      // Verificar que no hay números duplicados en la tabla
      final duplicados = await db.rawQuery(
        'SELECT numeroOrden, COUNT(*) as count FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING count > 1',
      );
      expect(duplicados, isEmpty);
    });
  });
}
