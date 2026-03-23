import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/services/pedido_service.dart';
import 'package:de_vacos/services/ventas_service.dart';

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_ventas_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  group('VentasService', () {
    test('total del día con pedidos cobrados', () async {
      final hoy = DateTime.now();
      final pedido = Pedido(
        numeroOrden: 1,
        cliente: 'Cliente',
        celular: '',
        metodoPago: 'Efectivo',
        estado: 'En preparación',
        estadoPago: 'Pendiente',
        productos: [{'nombre': 'A', 'cantidad': 1, 'precio': 25.0}],
        fecha: hoy,
        total: 25.0,
      );
      final id = await PedidoService.guardar(pedido);
      await PedidoService.actualizarEstadoPago(id, 'Cobrado');

      final total = await VentasService.obtenerVentasDelDia(hoy);
      expect(total, greaterThanOrEqualTo(25.0));
    });

    test('obtenerVentasDelDia retorna double', () async {
      final total = await VentasService.obtenerVentasDelDia(DateTime.now());
      expect(total, isA<double>());
      expect(total, greaterThanOrEqualTo(0));
    });
  });
}
