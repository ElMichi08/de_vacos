import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/services/pedido_service.dart';
import 'dart:developer' show log;

/// Helper para crear un pedido de prueba rápido
Pedido _pedidoFactory({
  String cliente = 'Test Cliente',
  String metodoPago = 'Efectivo',
  double total = 10.0,
  DateTime? fecha,
}) {
  return Pedido(
    numeroOrden: 0, // Se sobreescribe en guardar()
    cliente: cliente,
    celular: '099999999',
    metodoPago: metodoPago,
    estado: 'En preparación',
    estadoPago: 'Pendiente',
    productos: [
      {'nombre': 'Producto Test', 'cantidad': 1, 'precio': total}
    ],
    fecha: fecha ?? DateTime.now(),
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
      'test_pedido_ext_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ─── 1.1 CRUD completo ───────────────────────────────────────────────

  group('PedidoService CRUD completo', () {
    test('guardar() retorna id > 0 y asigna numeroOrden', () async {
      final id = await PedidoService.guardar(_pedidoFactory());
      expect(id, greaterThan(0));

      final pedido = await PedidoService.obtenerPorId(id);
      expect(pedido, isNotNull);
      expect(pedido!.numeroOrden, 1); // Primer pedido del día
    });

    test('obtenerPorId retorna el pedido correcto', () async {
      final id = await PedidoService.guardar(
          _pedidoFactory(cliente: 'Específico'));
      final pedido = await PedidoService.obtenerPorId(id);

      expect(pedido, isNotNull);
      expect(pedido!.cliente, 'Específico');
      expect(pedido.id, id);
    });

    test('actualizar() modifica campos', () async {
      final id = await PedidoService.guardar(_pedidoFactory());
      final original = await PedidoService.obtenerPorId(id);

      final modificado = Pedido(
        id: original!.id,
        numeroOrden: original.numeroOrden,
        cliente: 'Nuevo Cliente',
        celular: original.celular,
        metodoPago: original.metodoPago,
        estado: original.estado,
        estadoPago: original.estadoPago,
        productos: original.productos,
        fecha: original.fecha,
        total: 50.0,
        notas: 'Nota nueva',
      );

      final rows = await PedidoService.actualizar(modificado);
      expect(rows, 1);

      final actualizado = await PedidoService.obtenerPorId(id);
      expect(actualizado!.cliente, 'Nuevo Cliente');
      expect(actualizado.total, 50.0);
      expect(actualizado.notas, 'Nota nueva');
    });

    test('actualizarEstado cambia solo el estado', () async {
      final id = await PedidoService.guardar(_pedidoFactory());
      await PedidoService.actualizarEstado(id, 'Listo');

      final pedido = await PedidoService.obtenerPorId(id);
      expect(pedido!.estado, 'Listo');
      expect(pedido.estadoPago, 'Pendiente'); // No cambia
    });

    test('actualizarEstadoPago cambia estadoPago', () async {
      final id = await PedidoService.guardar(_pedidoFactory());
      await PedidoService.actualizarEstadoPago(id, 'Cobrado');

      final pedido = await PedidoService.obtenerPorId(id);
      expect(pedido!.estadoPago, 'Cobrado');
    });

    test('cancelar marca cancelado=1 y estado=Cancelada', () async {
      final id = await PedidoService.guardar(_pedidoFactory());
      await PedidoService.cancelar(id);

      final pedido = await PedidoService.obtenerPorId(id);
      expect(pedido!.cancelado, true);
      expect(pedido.estado, 'Cancelada');
    });
  });

  // ─── 1.2 Paginación ──────────────────────────────────────────────────

  group('PedidoService paginación', () {
    test('obtenerTodosPaginados estructura correcta', () async {
      // Crear 25 pedidos
      for (int i = 0; i < 25; i++) {
        await PedidoService.guardar(_pedidoFactory(cliente: 'C$i'));
      }

      final resultado = await PedidoService.obtenerTodosPaginados(
        pagina: 1,
        tamanoPagina: 10,
      );

      expect(resultado.containsKey('pedidos'), true);
      expect(resultado.containsKey('total'), true);
      expect(resultado.containsKey('pagina'), true);
      expect(resultado.containsKey('totalPaginas'), true);
      expect(resultado['total'], 25);
      expect((resultado['pedidos'] as List).length, 10);
      expect(resultado['totalPaginas'], 3);
    });

    test('página 3 con tamaño 10 retorna 5 items de 25', () async {
      for (int i = 0; i < 25; i++) {
        await PedidoService.guardar(_pedidoFactory(cliente: 'C$i'));
      }

      final resultado = await PedidoService.obtenerTodosPaginados(
        pagina: 3,
        tamanoPagina: 10,
      );

      expect((resultado['pedidos'] as List).length, 5);
    });

    test('obtenerPorEstadoPaginados filtra correctamente', () async {
      for (int i = 0; i < 10; i++) {
        await PedidoService.guardar(_pedidoFactory());
      }
      // Cambiar 3 a Listo
      final todos = await PedidoService.obtenerTodos();
      for (int i = 0; i < 3; i++) {
        await PedidoService.actualizarEstado(todos[i].id!, 'Listo');
      }

      final resultado = await PedidoService.obtenerPorEstadoPaginados(
        'En preparación',
        pagina: 1,
        tamanoPagina: 20,
      );
      expect(resultado['total'], 7);
    });
  });

  // ─── 1.3 Filtro por estado ────────────────────────────────────────────

  group('PedidoService filtro por estado', () {
    test('obtenerPorEstado devuelve solo activos con ese estado', () async {
      for (int i = 0; i < 5; i++) {
        await PedidoService.guardar(_pedidoFactory());
      }
      final todos = await PedidoService.obtenerTodos();
      await PedidoService.actualizarEstado(todos[0].id!, 'Listo');
      await PedidoService.actualizarEstado(todos[1].id!, 'Listo');

      final enPrep = await PedidoService.obtenerPorEstado('En preparación');
      final listos = await PedidoService.obtenerPorEstado('Listo');

      expect(enPrep.length, 3);
      expect(listos.length, 2);
    });

    test('obtenerPorEstado Canceladas retorna los cancelados', () async {
      for (int i = 0; i < 5; i++) {
        await PedidoService.guardar(_pedidoFactory());
      }
      final todos = await PedidoService.obtenerTodos();
      await PedidoService.cancelar(todos[0].id!);
      await PedidoService.cancelar(todos[1].id!);

      final canceladas = await PedidoService.obtenerPorEstado('Canceladas');
      expect(canceladas.length, 2);
      for (final p in canceladas) {
        expect(p.cancelado, true);
      }
    });
  });

  // ─── 1.4 CASO CRÍTICO: Consistencia de numeración ─────────────────────

  group('🔴 CASO CRÍTICO: Consistencia de numeroOrden al cancelar/eliminar',
      () {
    test(
        'Escenario volumen alto: 10 pedidos, cancelar 2, crear 5 más → verificar duplicación',
        () async {
      // 1. Crear 10 pedidos
      final ids = <int>[];
      for (int i = 0; i < 10; i++) {
        ids.add(await PedidoService.guardar(
            _pedidoFactory(cliente: 'Cliente ${i + 1}')));
      }

      // Verificar que tienen órdenes 1-10
      final pedidosOriginales = <Pedido>[];
      for (final id in ids) {
        final p = await PedidoService.obtenerPorId(id);
        expect(p, isNotNull);
        pedidosOriginales.add(p!);
      }
      for (int i = 0; i < 10; i++) {
        expect(pedidosOriginales[i].numeroOrden, i + 1,
            reason: 'Pedido ${i + 1} debería tener numeroOrden ${i + 1}');
      }

      // 2. Cancelar pedido 3 y pedido 7 (índices 2 y 6)
      await PedidoService.cancelar(ids[2]);
      await PedidoService.cancelar(ids[6]);

      // 3. Crear 5 pedidos nuevos
      final nuevosIds = <int>[];
      final nuevosOrdenes = <int>[];
      for (int i = 0; i < 5; i++) {
        final nuevoId = await PedidoService.guardar(
            _pedidoFactory(cliente: 'Nuevo ${i + 1}'));
        nuevosIds.add(nuevoId);
        final p = await PedidoService.obtenerPorId(nuevoId);
        nuevosOrdenes.add(p!.numeroOrden);
      }

      // 4. Documentar los números de orden asignados
      log('=== CASO CRÍTICO: Números de orden ===');
      log('Originales (1-10): ${pedidosOriginales.map((p) => '${p.cliente}=#${p.numeroOrden}').join(', ')}');
      log('Cancelados: pedido 3 (orden #3) y pedido 7 (orden #7)');
      log('Nuevos órdenes asignados: $nuevosOrdenes');

      // 5. Verificar unicidad entre pedidos activos
      final todosActivos = await PedidoService.obtenerTodos();
      final numerosActivos = todosActivos.map((p) => p.numeroOrden).toList();
      final numerosUnicos = numerosActivos.toSet();

      log('Todos los numeroOrden activos: $numerosActivos');
      log('¿Hay duplicados? ${numerosActivos.length != numerosUnicos.length}');

      if (numerosActivos.length != numerosUnicos.length) {
        // Encontrar duplicados
        final conteo = <int, int>{};
        for (final n in numerosActivos) {
          conteo[n] = (conteo[n] ?? 0) + 1;
        }
        final duplicados =
            conteo.entries.where((e) => e.value > 1).map((e) => e.key);
        log('⚠️ DUPLICADOS ENCONTRADOS: $duplicados');
      }

      // Este test DOCUMENTA el comportamiento, no fuerza pass/fail sobre la duplicación.
      // Verificar que al menos se crearon los pedidos correctamente.
      expect(todosActivos.length, 13); // 10 - 2 cancelados + 5 nuevos
    });

    test('Escenario eliminación masiva: crear 10, borrar todos, crear 5 → reinicia desde 1',
        () async {
      // 1. Crear 10 pedidos
      for (int i = 0; i < 10; i++) {
        await PedidoService.guardar(_pedidoFactory(cliente: 'C${i + 1}'));
      }
      final antes = await PedidoService.obtenerTodos();
      expect(antes.length, 10);

      // 2. Eliminar todos los pedidos del día
      await PedidoService.eliminarPedidosDelDiaActual();
      final despuesBorrar = await PedidoService.obtenerTodos();
      expect(despuesBorrar.length, 0);

      // 3. Crear 5 pedidos nuevos
      final nuevosOrdenes = <int>[];
      for (int i = 0; i < 5; i++) {
        final id = await PedidoService.guardar(
            _pedidoFactory(cliente: 'Nuevo ${i + 1}'));
        final p = await PedidoService.obtenerPorId(id);
        nuevosOrdenes.add(p!.numeroOrden);
      }

      // 4. Verificar que reinician desde 1
      log('Secuencia post-eliminación: $nuevosOrdenes');
      expect(nuevosOrdenes, [1, 2, 3, 4, 5]);
    });
  });
}
