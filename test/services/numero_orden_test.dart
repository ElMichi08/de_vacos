import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/services/pedido_service.dart';

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
      {'nombre': 'P', 'cantidad': 1, 'precio': total}
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

      // ignore: avoid_print
      print('Pedido original #3: numeroOrden=${tercero!.numeroOrden}');
      // ignore: avoid_print
      print('Pedido nuevo: numeroOrden=${nuevo!.numeroOrden}');
      // ignore: avoid_print
      print('¿Duplicado? ${tercero.numeroOrden == nuevo.numeroOrden}');
    });
  });

  // ─── 5.3 Auditoría semanal ────────────────────────────────────────────

  group('obtenerAuditoriaSemanal', () {
    test('retorna cantidad y total correctos solo pedidos cobrados',
        () async {
      // Crear 3 pedidos, cobrar 2
      final id1 =
          await PedidoService.guardar(_pedidoRapido(total: 10.0));
      final id2 =
          await PedidoService.guardar(_pedidoRapido(total: 20.0));
      await PedidoService.guardar(_pedidoRapido(total: 30.0)); // pendiente

      await PedidoService.actualizarEstadoPago(id1, 'Cobrado');
      await PedidoService.actualizarEstadoPago(id2, 'Cobrado');

      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin =
          DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

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
      final fin =
          DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

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
        {'nombre': 'Asado', 'cantidad': 5, 'precio': 10.0}
      ];
      final productos2 = [
        {'nombre': 'Pollo', 'cantidad': 3, 'precio': 8.0}
      ];
      final productos3 = [
        {'nombre': 'Costilla', 'cantidad': 7, 'precio': 12.0}
      ];
      final productos4 = [
        {'nombre': 'Morcilla', 'cantidad': 1, 'precio': 5.0}
      ];

      for (final prods in [productos1, productos2, productos3, productos4]) {
        final id = await PedidoService.guardar(Pedido(
          numeroOrden: 0,
          cliente: 'Test',
          celular: '',
          metodoPago: 'Efectivo',
          estado: 'En preparación',
          estadoPago: 'Pendiente',
          productos: prods,
          fecha: DateTime.now(),
          total: (prods[0]['precio'] as double) *
              (prods[0]['cantidad'] as int),
        ));
        await PedidoService.actualizarEstadoPago(id, 'Cobrado');
      }

      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin =
          DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

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
}
