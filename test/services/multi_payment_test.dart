import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/pedido_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Pedido _pedido({
  double total = 10.0,
  PaymentMethod metodo = PaymentMethod.efectivo,
  List<Map<String, dynamic>>? productos,
}) {
  return Pedido(
    numeroOrden: 0,
    cliente: 'Test',
    celular: '',
    metodoPago: metodo,
    estado: OrderStatus.enPreparacion,
    productos: productos ??
        [
          {
            'nombre': 'Producto',
            'productoId': 1,
            'cantidad': 1,
            'precio': total,
          }
        ],
    fecha: DateTime.now(),
    total: total,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  late String testDbPath;
  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_multi_payment_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ── Pago model ──────────────────────────────────────────────────────────────

  group('Pago model', () {
    test('toMap y fromMap son inversos', () {
      const pago = Pago(
        metodo: PaymentMethod.transferencia,
        monto: 12.50,
        foto: '/ruta/foto.jpg',
      );
      final map = pago.toMap();
      final reconstructed = Pago.fromMap(map);

      expect(reconstructed.metodo, pago.metodo);
      expect(reconstructed.monto, pago.monto);
      expect(reconstructed.foto, pago.foto);
    });

    test('toMap sin foto serializa foto como null', () {
      const pago = Pago(metodo: PaymentMethod.efectivo, monto: 5.0);
      final map = pago.toMap();
      expect(map['foto'], isNull);
      expect(map['monto'], 5.0);
      expect(map['metodo'], 'Efectivo');
    });

    test('fromMap con foto null mantiene null', () {
      final pago = Pago.fromMap({'metodo': 'Efectivo', 'monto': 3.0, 'foto': null});
      expect(pago.foto, isNull);
      expect(pago.metodo, PaymentMethod.efectivo);
    });
  });

  // ── Pedido helpers ──────────────────────────────────────────────────────────

  group('Pedido helpers multi-pago', () {
    test('totalYaCobrado es 0 sin pagos', () {
      final p = _pedido(total: 15.0);
      expect(p.totalYaCobrado, 0.0);
    });

    test('totalYaCobrado suma montos de pagos', () {
      final p = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [],
        fecha: DateTime.now(),
        total: 20.0,
        pagos: [
          const Pago(metodo: PaymentMethod.transferencia, monto: 12.0),
          const Pago(metodo: PaymentMethod.efectivo, monto: 8.0),
        ],
      );
      expect(p.totalYaCobrado, 20.0);
    });

    test('diferencia = total - totalYaCobrado', () {
      final p = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [],
        fecha: DateTime.now(),
        total: 15.0,
        pagos: [const Pago(metodo: PaymentMethod.efectivo, monto: 10.0)],
      );
      expect(p.diferencia, 5.0);
    });

    test('diferencia nunca es negativa (clamp 0)', () {
      final p = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [],
        fecha: DateTime.now(),
        total: 10.0,
        pagos: [const Pago(metodo: PaymentMethod.efectivo, monto: 15.0)],
      );
      expect(p.diferencia, 0.0);
    });

    test('puedeRecobrar es true con menos de 3 pagos', () {
      final sinPagos = _pedido();
      expect(sinPagos.puedeRecobrar, isTrue);

      final conDos = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [],
        fecha: DateTime.now(),
        total: 10.0,
        pagos: [
          const Pago(metodo: PaymentMethod.efectivo, monto: 5.0),
          const Pago(metodo: PaymentMethod.efectivo, monto: 5.0),
        ],
      );
      expect(conDos.puedeRecobrar, isTrue);
    });

    test('puedeRecobrar es false con 3 o más pagos', () {
      final conTres = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [],
        fecha: DateTime.now(),
        total: 15.0,
        pagos: [
          const Pago(metodo: PaymentMethod.efectivo, monto: 5.0),
          const Pago(metodo: PaymentMethod.efectivo, monto: 5.0),
          const Pago(metodo: PaymentMethod.efectivo, monto: 5.0),
        ],
      );
      expect(conTres.puedeRecobrar, isFalse);
    });
  });

  // ── Pedido fromMap / pagos JSON ─────────────────────────────────────────────

  group('Pedido.fromMap pagos deserialization', () {
    test('pagos null cuando columna es null', () {
      final p = Pedido.fromMap({
        'id': 1,
        'numeroOrden': 1,
        'cliente': 'X',
        'celular': '',
        'metodoPago': 'Efectivo',
        'estado': 'En preparación',
        'estadoPago': 'Pendiente',
        'productos': '[]',
        'fecha': DateTime.now().toIso8601String(),
        'total': 10.0,
        'envasesLlevar': 0,
        'notas': '',
        'cancelado': 0,
        'pagos': null,
      });
      expect(p.pagos, isNull);
    });

    test('pagos deserializa correctamente desde JSON', () {
      final pagosJson = jsonEncode([
        {'metodo': 'Efectivo', 'monto': 5.0, 'foto': null},
        {'metodo': 'Transferencia', 'monto': 10.0, 'foto': '/ruta/foto.jpg'},
      ]);
      final p = Pedido.fromMap({
        'id': 1,
        'numeroOrden': 1,
        'cliente': 'X',
        'celular': '',
        'metodoPago': 'Efectivo',
        'estado': 'En preparación',
        'estadoPago': 'Cobrado',
        'productos': '[]',
        'fecha': DateTime.now().toIso8601String(),
        'total': 15.0,
        'envasesLlevar': 0,
        'notas': '',
        'cancelado': 0,
        'pagos': pagosJson,
      });
      expect(p.pagos, hasLength(2));
      expect(p.pagos![0].metodo, PaymentMethod.efectivo);
      expect(p.pagos![0].monto, 5.0);
      expect(p.pagos![1].metodo, PaymentMethod.transferencia);
      expect(p.pagos![1].foto, '/ruta/foto.jpg');
    });

    test('pagos con JSON malformado retorna null sin lanzar', () {
      final p = Pedido.fromMap({
        'id': 1,
        'numeroOrden': 1,
        'cliente': 'X',
        'celular': '',
        'metodoPago': 'Efectivo',
        'estado': 'En preparación',
        'estadoPago': 'Pendiente',
        'productos': '[]',
        'fecha': DateTime.now().toIso8601String(),
        'total': 10.0,
        'envasesLlevar': 0,
        'notas': '',
        'cancelado': 0,
        'pagos': 'JSON_INVALIDO',
      });
      expect(p.pagos, isNull);
    });
  });

  // ── PaymentStatus.recobrar ──────────────────────────────────────────────────

  group('PaymentStatus.recobrar', () {
    test('fromString reconoce Recobrar', () {
      expect(
        PaymentStatus.fromString('Recobrar'),
        PaymentStatus.recobrar,
      );
    });

    test('displayName es Recobrar', () {
      expect(PaymentStatus.recobrar.displayName, 'Recobrar');
    });

    test('fromString desconocido devuelve pendiente como fallback', () {
      expect(PaymentStatus.fromString('Invalido'), PaymentStatus.pendiente);
    });
  });

  // ── PedidoService.setRecobrar ───────────────────────────────────────────────

  group('PedidoService.setRecobrar', () {
    test('cambia estadoPago a recobrar sin tocar pagos ni stock', () async {
      final id = await PedidoService.guardar(_pedido(total: 10.0));
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.efectivo,
        montoPagado: 10.0,
      );

      final antesDeEditar = (await PedidoService.obtenerPorId(id))!;
      expect(antesDeEditar.estadoPago, PaymentStatus.cobrado);
      expect(antesDeEditar.pagos, hasLength(1));

      await PedidoService.setRecobrar(id);

      final despues = (await PedidoService.obtenerPorId(id))!;
      expect(despues.estadoPago, PaymentStatus.recobrar);
      // pagos no cambia
      expect(despues.pagos, hasLength(1));
    });
  });

  // ── PedidoService.actualizarEstadoPago con multi-pago ──────────────────────

  group('PedidoService.actualizarEstadoPago multi-pago', () {
    test('primer cobro crea pagos con un elemento', () async {
      final id = await PedidoService.guardar(_pedido(total: 8.0));

      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.efectivo,
        montoPagado: 8.0,
      );

      final p = (await PedidoService.obtenerPorId(id))!;
      expect(p.estadoPago, PaymentStatus.cobrado);
      expect(p.pagos, isNotNull);
      expect(p.pagos!, hasLength(1));
      expect(p.pagos![0].metodo, PaymentMethod.efectivo);
      expect(p.pagos![0].monto, 8.0);
    });

    test('recobro appenda segundo elemento a pagos', () async {
      final id = await PedidoService.guardar(_pedido(total: 12.0));

      // Primer cobro: $8 en efectivo
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.efectivo,
        montoPagado: 8.0,
      );

      // Simular que se editó el pedido y quedó en recobrar
      await PedidoService.setRecobrar(id);

      // Recobro: $4 en transferencia
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.transferencia,
        montoPagado: 4.0,
        fotoTransferenciaPath: '/foto/transfer.jpg',
      );

      final p = (await PedidoService.obtenerPorId(id))!;
      expect(p.estadoPago, PaymentStatus.cobrado);
      expect(p.pagos, hasLength(2));
      expect(p.pagos![0].metodo, PaymentMethod.efectivo);
      expect(p.pagos![0].monto, 8.0);
      expect(p.pagos![1].metodo, PaymentMethod.transferencia);
      expect(p.pagos![1].monto, 4.0);
      expect(p.pagos![1].foto, '/foto/transfer.jpg');
    });

    test('fotoTransferenciaPath backward compat: se setea con primera foto transfer', () async {
      final id = await PedidoService.guardar(_pedido(total: 5.0));

      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.transferencia,
        montoPagado: 5.0,
        fotoTransferenciaPath: '/fotos/primera.jpg',
      );

      final p = (await PedidoService.obtenerPorId(id))!;
      expect(p.fotoTransferenciaPath, '/fotos/primera.jpg');
    });

    test('fotoTransferenciaPath no se sobreescribe en recobros posteriores', () async {
      final id = await PedidoService.guardar(_pedido(total: 15.0));

      // Primera transferencia
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.transferencia,
        montoPagado: 10.0,
        fotoTransferenciaPath: '/fotos/primera.jpg',
      );

      await PedidoService.setRecobrar(id);

      // Segunda transferencia (recobro)
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
        metodoPago: PaymentMethod.transferencia,
        montoPagado: 5.0,
        fotoTransferenciaPath: '/fotos/segunda.jpg',
      );

      final p = (await PedidoService.obtenerPorId(id))!;
      // fotoTransferenciaPath mantiene la primera
      expect(p.fotoTransferenciaPath, '/fotos/primera.jpg');
      // pero pagos tiene ambas
      expect(p.pagos, hasLength(2));
      expect(p.pagos![1].foto, '/fotos/segunda.jpg');
    });

    test('sin metodoPago/montoPagado no agrega entrada a pagos', () async {
      final id = await PedidoService.guardar(_pedido(total: 10.0));

      // Cobro sin metadata (backward compat para código que no pasa los nuevos params)
      await PedidoService.actualizarEstadoPago(
        id,
        PaymentStatus.cobrado.displayName,
      );

      final p = (await PedidoService.obtenerPorId(id))!;
      expect(p.estadoPago, PaymentStatus.cobrado);
      // pagos permanece null porque no se pasaron parámetros
      expect(p.pagos, isNull);
    });
  });

  // ── Helpers de filtrado multi-pago (lógica _matchesFiltro) ─────────────────

  group('lógica de filtrado multi-pago', () {
    bool matchesFiltro(Pedido p, PaymentMethod metodo) {
      if (p.pagos != null && p.pagos!.isNotEmpty) {
        return p.pagos!.any((pg) => pg.metodo == metodo);
      }
      return p.metodoPago == metodo;
    }

    test('fallback a metodoPago cuando pagos es null', () {
      final p = _pedido(metodo: PaymentMethod.transferencia);
      expect(matchesFiltro(p, PaymentMethod.transferencia), isTrue);
      expect(matchesFiltro(p, PaymentMethod.efectivo), isFalse);
    });

    test('usa pagos cuando están disponibles (ignora metodoPago)', () {
      final p = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo, // metodoPago primario es efectivo
        estado: OrderStatus.cerrados,
        productos: [],
        fecha: DateTime.now(),
        total: 15.0,
        pagos: [
          const Pago(metodo: PaymentMethod.efectivo, monto: 10.0),
          const Pago(metodo: PaymentMethod.transferencia, monto: 5.0),
        ],
      );
      // Debe aparecer en filtro transfer porque pagos[1] es transfer
      expect(matchesFiltro(p, PaymentMethod.transferencia), isTrue);
      // También aparece en filtro efectivo
      expect(matchesFiltro(p, PaymentMethod.efectivo), isTrue);
    });

    test('orden sin transfer no aparece en filtro transfer', () {
      final p = Pedido(
        numeroOrden: 1,
        cliente: 'X',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.cerrados,
        productos: [],
        fecha: DateTime.now(),
        total: 10.0,
        pagos: [
          const Pago(metodo: PaymentMethod.efectivo, monto: 10.0),
        ],
      );
      expect(matchesFiltro(p, PaymentMethod.transferencia), isFalse);
      expect(matchesFiltro(p, PaymentMethod.efectivo), isTrue);
    });
  });
}
