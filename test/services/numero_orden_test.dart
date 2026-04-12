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

    test('con 100 pedidos → retorna 1 (reinicio)', () async {
      for (int i = 0; i < 100; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }
      final num = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num, 1);
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

    test('números cancelados se reutilizan correctamente', () async {
      // Crear 5 pedidos activos (números 1-5)
      final ids = <int>[];
      for (int i = 0; i < 5; i++) {
        ids.add(await PedidoService.guardar(_pedidoRapido()));
      }

      // Cancelar pedidos con números 2 y 4
      await PedidoService.cancelar(ids[1]); // numeroOrden = 2
      await PedidoService.cancelar(ids[3]); // numeroOrden = 4

      // El siguiente número disponible debe ser 6 (porque 6 no está activo)
      final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num1, 6);

      // Crear un pedido nuevo - debería usar el 6
      final id6 = await PedidoService.guardar(_pedidoRapido());
      final pedido6 = await PedidoService.obtenerPorId(id6);
      expect(pedido6!.numeroOrden, 6);

      // Ahora cancelar el pedido 6
      await PedidoService.cancelar(id6);

      // El siguiente número disponible debería ser 6 nuevamente (reutilizar)
      // porque el máximo activo es 5, siguiente = 6, y 6 no está activo
      final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num2, 6);

      // Verificar que podemos reutilizar números cancelados
      // Cancelar todos los pedidos activos
      for (final id in ids) {
        await PedidoService.cancelar(id);
      }

      // Ahora no hay pedidos activos, el máximo activo es 0, siguiente = 1
      final num3 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num3, 1);
    });

    test('no duplica números al reiniciar ciclo después de 100', () async {
      // Crear 100 pedidos (números 1-100)
      for (int i = 0; i < 100; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }

      // El siguiente número debe ser 1 (reinicio)
      final num1 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num1, 1);

      // Cancelar el pedido número 1 (el primer pedido del día)
      // Para esto necesitamos obtener el primer pedido
      final db = await DBHelper.db;
      final primerPedido = await db.query(
        'pedidos',
        where: 'cancelado = 0',
        orderBy: 'numeroOrden ASC',
        limit: 1,
      );
      final primerId = primerPedido.first['id'] as int;
      await PedidoService.cancelar(primerId);

      // El siguiente número disponible debe ser 1 (reutilizar)
      final num2 = await DBHelper.obtenerSiguienteNumeroOrden();
      expect(num2, 1);

      // Crear pedido nuevo - debe usar 1
      final idNuevo = await PedidoService.guardar(_pedidoRapido());
      final pedidoNuevo = await PedidoService.obtenerPorId(idNuevo);
      expect(pedidoNuevo!.numeroOrden, 1);
    });

    test('asegura unicidad para pedidos activos del mismo día', () async {
      // Crear varios pedidos y cancelar algunos en patrón irregular
      final ids = <int>[];
      for (int i = 0; i < 10; i++) {
        ids.add(await PedidoService.guardar(_pedidoRapido()));
      }

      // Cancelar pedidos en posiciones impares
      for (int i = 1; i < ids.length; i += 2) {
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

      // Crear 20 pedidos más y verificar que siguen sin duplicados
      for (int i = 0; i < 20; i++) {
        await PedidoService.guardar(_pedidoRapido());
      }

      final activos2 = await db.rawQuery(
        'SELECT numeroOrden FROM pedidos WHERE cancelado = 0 GROUP BY numeroOrden HAVING COUNT(*) > 1',
      );
      expect(
        activos2,
        isEmpty,
        reason:
            'No debe haber números duplicados en pedidos activos después de crear más',
      );
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
