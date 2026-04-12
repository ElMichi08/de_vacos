import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/pedido_service.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_pedidos_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('PedidoService', () {
    test('crear pedido, actualizar estado pago a Cobrado, listar', () async {
      final ahora = DateTime.now();
      final pedido = Pedido(
        numeroOrden: 1,
        cliente: 'Test Cliente',
        celular: '099999999',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        estadoPago: PaymentStatus.pendiente,
        productos: [
          {'nombre': 'Producto Test', 'cantidad': 1, 'precio': 10.0},
        ],
        fecha: ahora,
        total: 10.0,
      );

      final id = await PedidoService.guardar(pedido);
      expect(id, greaterThan(0));

      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
      );

      final lista = await PedidoService.obtenerTodos();
      expect(lista, isNotEmpty);
      final encontrado = lista.firstWhere((p) => p.id == id);
      expect(encontrado.estadoPago, PaymentStatus.cobrado);
    });

    test('listar pedidos del día devuelve lista', () async {
      final lista = await PedidoService.obtenerTodos();
      expect(lista, isA<List<Pedido>>());
    });

    test('cerrar pedido sin cobrar lanza error', () async {
      final pedido = Pedido(
        numeroOrden: 2,
        cliente: 'Test Cliente 2',
        celular: '099999998',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.despachada,
        estadoPago: PaymentStatus.pendiente,
        productos: [
          {'nombre': 'Producto Test', 'cantidad': 1, 'precio': 10.0},
        ],
        fecha: DateTime.now(),
        total: 10.0,
      );

      final id = await PedidoService.guardar(pedido);
      expect(id, greaterThan(0));

      // Intentar cerrar sin cobrar debe lanzar excepción
      expect(
        () => PedidoService.actualizarEstado(id, 'Cerrados'),
        throwsA(isA<Exception>()),
      );
    });

    test('cerrar pedido cobrado funciona correctamente', () async {
      final pedido = Pedido(
        numeroOrden: 3,
        cliente: 'Test Cliente 3',
        celular: '099999997',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.despachada,
        estadoPago: PaymentStatus.cobrado,
        productos: [
          {'nombre': 'Producto Test', 'cantidad': 1, 'precio': 10.0},
        ],
        fecha: DateTime.now(),
        total: 10.0,
      );

      final id = await PedidoService.guardar(pedido);
      expect(id, greaterThan(0));

      // Cerrar pedido cobrado debe funcionar
      await PedidoService.actualizarEstado(id, 'Cerrados');

      final lista = await PedidoService.obtenerTodos();
      final encontrado = lista.firstWhere((p) => p.id == id);
      expect(encontrado.estado, OrderStatus.cerrados);
    });
  });
}
