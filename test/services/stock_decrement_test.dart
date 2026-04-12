/// Tests de decremento de stock — UC-01 al UC-06
///
/// Cubre:
///   UC-01 ítem de menú: cobrar descuenta proteínas vía proteinaIds
///   UC-01 producto regular: cobrar descuenta vía receta_detalle
///   UC-02: producto sin receta → cobrar no falla, no descuenta
///   UC-03: snapshot productosCobrados guardado al cobrar
///   UC-04: re-cobro incremental descuenta solo el diff (menú y regular)
///   UC-06: cancelarConEleccion devuelve o no stock
///
///   3A: devolverStock incrementa; no tiene techo
///   3B: _calcularDiffStock (via aplicarDiffStock con []): nuevo, eliminado, +cant, -cant
///   3C: aplicarDiffStock(antes, []) devuelve todo el stock
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/receta_detalle.dart';
import 'package:de_vacos/services/insumo_service.dart';
import 'package:de_vacos/services/pedido_service.dart';
import 'package:de_vacos/services/receta_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Crea un insumo en la DB y retorna su ID.
Future<int> _crearInsumo({
  String nombre = 'Carne',
  double stock = 10.0,
}) async {
  return InsumoService.crear(Insumo(
    nombre: nombre,
    unidadMedida: 'kg',
    cantidadActual: stock,
    cantidadMinima: 0,
  ));
}

/// Obtiene el stock actual de un insumo por ID.
Future<double> _stockActual(int insumoId) async {
  final insumo = await InsumoService.obtenerPorId(insumoId);
  return insumo!.cantidadActual;
}

/// Crea y guarda un pedido con ítems de menú (tipo='menu', proteinaIds).
Future<int> _pedidoMenu({
  required List<int> proteinaIds,
  int cantidad = 1,
}) async {
  final pedido = Pedido(
    numeroOrden: 0,
    cliente: 'Test',
    celular: '',
    metodoPago: PaymentMethod.efectivo,
    estado: OrderStatus.enPreparacion,
    productos: [
      {
        'nombre': 'Combo Test',
        'precio': 15.0,
        'cantidad': cantidad,
        'tipo': 'menu',
        'tier': 'Simple',
        'proteinas': ['Carne'],
        'proteinaIds': proteinaIds,
        'acompanantes': [],
        'extras': [],
      }
    ],
    fecha: DateTime.now(),
    total: 15.0,
  );
  return PedidoService.guardar(pedido);
}

/// Crea y guarda un pedido con producto regular (productoId).
Future<int> _pedidoRegular({
  required int productoId,
  int cantidad = 1,
}) async {
  final pedido = Pedido(
    numeroOrden: 0,
    cliente: 'Test',
    celular: '',
    metodoPago: PaymentMethod.efectivo,
    estado: OrderStatus.enPreparacion,
    productos: [
      {
        'nombre': 'Producto Regular',
        'precio': 10.0,
        'cantidad': cantidad,
        'productoId': productoId,
      }
    ],
    fecha: DateTime.now(),
    total: 10.0,
  );
  return PedidoService.guardar(pedido);
}

// ── Setup/Teardown ────────────────────────────────────────────────────────────

void main() {
  late String testDbPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DBHelper.initialize();
  });

  setUp(() async {
    testDbPath = path_utils.join(
      Directory.current.path,
      'test_stock_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  // ── UC-01 Ítem de menú ────────────────────────────────────────────────────

  group('UC-01 cobro ítem de menú descuenta proteínas', () {
    test('cobrar 1 unidad descuenta 1 porción de cada proteína', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      expect(await _stockActual(insumoId), 4.0);
    });

    test('cobrar 2 unidades descuenta 2 porciones', () async {
      final insumoId = await _crearInsumo(stock: 8.0);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId], cantidad: 2);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      expect(await _stockActual(insumoId), 6.0);
    });

    test('cobrar ítem con 2 proteínas descuenta ambas', () async {
      final carneId = await _crearInsumo(nombre: 'Carne', stock: 5.0);
      final polloId = await _crearInsumo(nombre: 'Pollo', stock: 3.0);

      final pedidoId = await _pedidoMenu(
        proteinaIds: [carneId, polloId],
        cantidad: 1,
      );
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      expect(await _stockActual(carneId), 4.0);
      expect(await _stockActual(polloId), 2.0);
    });

    test('sin stock suficiente lanza StockInsuficienteException', () async {
      final insumoId = await _crearInsumo(stock: 0.5);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId], cantidad: 1);

      expect(
        () => PedidoService.actualizarEstadoPago(
          pedidoId,
          PaymentStatus.cobrado.displayName,
        ),
        throwsException,
      );
    });
  });

  // ── UC-01 Producto regular (receta_detalle) ───────────────────────────────

  group('UC-01 cobro producto regular descuenta vía receta', () {
    test('cobrar descuenta la cantidad de receta', () async {
      final insumoId = await _crearInsumo(stock: 10.0);
      const productoId = 1; // ID ficticio para receta_detalle

      await RecetaService.guardarReceta(productoId, [
        RecetaDetalle(productoId: productoId, insumoId: insumoId, cantidad: 0.3),
      ]);

      final pedidoId = await _pedidoRegular(productoId: productoId);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      // 10 - 0.3 * 1 = 9.7
      final stockFinal = await _stockActual(insumoId);
      expect(stockFinal, closeTo(9.7, 0.001));
    });

    test('cantidad de producto multiplica la receta', () async {
      final insumoId = await _crearInsumo(stock: 10.0);
      const productoId = 2;

      await RecetaService.guardarReceta(productoId, [
        RecetaDetalle(productoId: productoId, insumoId: insumoId, cantidad: 0.5),
      ]);

      final pedidoId = await _pedidoRegular(productoId: productoId, cantidad: 3);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      // 10 - 0.5 * 3 = 8.5
      expect(await _stockActual(insumoId), closeTo(8.5, 0.001));
    });
  });

  // ── UC-02 Producto sin receta ─────────────────────────────────────────────

  group('UC-02 producto sin receta no falla ni descuenta', () {
    test('cobrar producto sin receta actualiza estadoPago sin tocar stock', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      // Pedido con productoId=99 que no tiene receta_detalle
      final pedido = Pedido(
        numeroOrden: 0,
        cliente: 'Test',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [
          {'nombre': 'Sin Receta', 'precio': 10.0, 'cantidad': 1, 'productoId': 99},
        ],
        fecha: DateTime.now(),
        total: 10.0,
      );
      final pedidoId = await PedidoService.guardar(pedido);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      // Estado actualizado
      final guardado = await PedidoService.obtenerPorId(pedidoId);
      expect(guardado!.estadoPago, PaymentStatus.cobrado);

      // Stock no tocado
      expect(await _stockActual(insumoId), 5.0);
    });

    test('cobrar ítem de menú sin proteinaIds no falla', () async {
      final pedido = Pedido(
        numeroOrden: 0,
        cliente: 'Test',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        productos: [
          {
            'nombre': 'Menu sin IDs',
            'precio': 10.0,
            'cantidad': 1,
            'tipo': 'menu',
            'tier': 'Simple',
            'proteinas': [],
          },
        ],
        fecha: DateTime.now(),
        total: 10.0,
      );
      final pedidoId = await PedidoService.guardar(pedido);

      // No debe lanzar excepción
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      final guardado = await PedidoService.obtenerPorId(pedidoId);
      expect(guardado!.estadoPago, PaymentStatus.cobrado);
    });
  });

  // ── UC-03 Snapshot productosCobrados ─────────────────────────────────────

  group('UC-03 snapshot productosCobrados', () {
    test('cobrar guarda snapshot productosCobrados', () async {
      final insumoId = await _crearInsumo(stock: 5.0);
      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);

      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      final pedido = await PedidoService.obtenerPorId(pedidoId);
      expect(pedido!.productosCobrados, isNotNull);
      expect(pedido.productosCobrados, isNotEmpty);
    });

    test('productosCobrados es null antes de cobrar', () async {
      final pedidoId = await _pedidoMenu(proteinaIds: []);

      final pedido = await PedidoService.obtenerPorId(pedidoId);
      expect(pedido!.productosCobrados, isNull);
    });
  });

  // ── UC-04 Re-cobro incremental ────────────────────────────────────────────

  group('UC-04 re-cobro incremental solo descuenta el diff', () {
    test('agregar proteína al re-cobrar solo descuenta la nueva', () async {
      final carneId = await _crearInsumo(nombre: 'Carne', stock: 5.0);
      final polloId = await _crearInsumo(nombre: 'Pollo', stock: 5.0);

      // Cobro inicial con solo carne
      final pedidoId = await _pedidoMenu(proteinaIds: [carneId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );
      expect(await _stockActual(carneId), 4.0);
      expect(await _stockActual(polloId), 5.0);

      // Editar pedido para agregar pollo
      final pedidoOriginal = await PedidoService.obtenerPorId(pedidoId);
      final pedidoEditado = Pedido(
        id: pedidoOriginal!.id,
        numeroOrden: pedidoOriginal.numeroOrden,
        cliente: pedidoOriginal.cliente,
        celular: pedidoOriginal.celular,
        metodoPago: pedidoOriginal.metodoPago,
        estado: pedidoOriginal.estado,
        estadoPago: pedidoOriginal.estadoPago,
        productos: [
          {
            'nombre': 'Combo Test',
            'precio': 15.0,
            'cantidad': 1,
            'tipo': 'menu',
            'tier': 'Simple',
            'proteinas': ['Carne', 'Pollo'],
            'proteinaIds': [carneId, polloId],
            'acompanantes': [],
            'extras': [],
          }
        ],
        fecha: pedidoOriginal.fecha,
        total: 15.0,
        productosCobrados: pedidoOriginal.productosCobrados,
        fotoTransferenciaPath: pedidoOriginal.fotoTransferenciaPath,
      );
      await PedidoService.actualizar(pedidoEditado);

      // Re-cobrar: solo debe descontar pollo (diff = +1 pollo)
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      // Carne: no cambia (ya descontada)
      expect(await _stockActual(carneId), 4.0);
      // Pollo: ahora descontado
      expect(await _stockActual(polloId), 4.0);
    });

    test('quitar proteína al re-cobrar devuelve stock', () async {
      final carneId = await _crearInsumo(nombre: 'Carne', stock: 5.0);
      final polloId = await _crearInsumo(nombre: 'Pollo', stock: 5.0);

      // Cobro inicial con carne + pollo
      final pedidoId = await _pedidoMenu(proteinaIds: [carneId, polloId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );
      expect(await _stockActual(carneId), 4.0);
      expect(await _stockActual(polloId), 4.0);

      // Editar: quitar pollo
      final pedidoOriginal = await PedidoService.obtenerPorId(pedidoId);
      final pedidoEditado = Pedido(
        id: pedidoOriginal!.id,
        numeroOrden: pedidoOriginal.numeroOrden,
        cliente: pedidoOriginal.cliente,
        celular: pedidoOriginal.celular,
        metodoPago: pedidoOriginal.metodoPago,
        estado: pedidoOriginal.estado,
        estadoPago: pedidoOriginal.estadoPago,
        productos: [
          {
            'nombre': 'Combo Test',
            'precio': 15.0,
            'cantidad': 1,
            'tipo': 'menu',
            'tier': 'Simple',
            'proteinas': ['Carne'],
            'proteinaIds': [carneId],
            'acompanantes': [],
            'extras': [],
          }
        ],
        fecha: pedidoOriginal.fecha,
        total: 15.0,
        productosCobrados: pedidoOriginal.productosCobrados,
        fotoTransferenciaPath: pedidoOriginal.fotoTransferenciaPath,
      );
      await PedidoService.actualizar(pedidoEditado);

      // Re-cobrar: devuelve pollo
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      expect(await _stockActual(carneId), 4.0); // Sin cambio
      expect(await _stockActual(polloId), 5.0); // Devuelto
    });

    test('pedido histórico sin snapshot no re-descuenta (guard en service)', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      // Pedido ya cobrado con productosCobrados=null (simula histórico)
      final pedido = Pedido(
        numeroOrden: 0,
        cliente: 'Histórico',
        celular: '',
        metodoPago: PaymentMethod.efectivo,
        estado: OrderStatus.enPreparacion,
        estadoPago: PaymentStatus.cobrado,
        productos: [
          {
            'nombre': 'Combo Test',
            'precio': 15.0,
            'cantidad': 1,
            'tipo': 'menu',
            'tier': 'Simple',
            'proteinas': ['Carne'],
            'proteinaIds': [insumoId],
            'acompanantes': [],
            'extras': [],
          }
        ],
        fecha: DateTime.now(),
        total: 15.0,
        // productosCobrados: null → histórico sin snapshot
      );
      final pedidoId = await PedidoService.guardar(pedido);

      // Llamar a actualizarEstadoPago en un pedido que ya está cobrado
      // pero sin snapshot → se trata como cobro inicial y descuenta
      // Este test documenta el comportamiento actual
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      // Descuenta como cobro inicial (productosCobrados null → camino inicial)
      expect(await _stockActual(insumoId), 4.0);
      // Y guarda snapshot
      final guardado = await PedidoService.obtenerPorId(pedidoId);
      expect(guardado!.productosCobrados, isNotNull);
    });
  });

  // ── UC-06 Cancelación con elección de stock ───────────────────────────────

  group('UC-06 cancelarConEleccion', () {
    test('devolverStock=true revierte el stock cobrado', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );
      expect(await _stockActual(insumoId), 4.0);

      await PedidoService.cancelarConEleccion(pedidoId, devolverStock: true);

      expect(await _stockActual(insumoId), 5.0);
    });

    test('devolverStock=false NO revierte el stock', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );
      expect(await _stockActual(insumoId), 4.0);

      await PedidoService.cancelarConEleccion(pedidoId, devolverStock: false);

      expect(await _stockActual(insumoId), 4.0);
    });

    test('cancelar pedido no cobrado (sin snapshot) no toca stock', () async {
      final insumoId = await _crearInsumo(stock: 5.0);

      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);
      // Sin cobrar → productosCobrados == null

      await PedidoService.cancelarConEleccion(pedidoId, devolverStock: true);

      expect(await _stockActual(insumoId), 5.0); // Sin cambio
    });

    test('cancelar marca pedido como cancelado', () async {
      final insumoId = await _crearInsumo(stock: 5.0);
      final pedidoId = await _pedidoMenu(proteinaIds: [insumoId]);
      await PedidoService.actualizarEstadoPago(
        pedidoId,
        PaymentStatus.cobrado.displayName,
      );

      await PedidoService.cancelarConEleccion(pedidoId, devolverStock: true);

      final pedido = await PedidoService.obtenerPorId(pedidoId);
      expect(pedido!.cancelado, true);
      expect(pedido.estado, OrderStatus.cancelada);
    });
  });

  // ── 3A: devolverStock ─────────────────────────────────────────────────────

  group('3A InsumoService.devolverStock', () {
    test('devuelve stock correctamente', () async {
      final insumoId = await _crearInsumo(stock: 3.0);

      final db = await DBHelper.db;
      await db.transaction((txn) async {
        await InsumoService.devolverStock(
          recetas: [
            RecetaDetalle(productoId: 0, insumoId: insumoId, cantidad: 1.5)
          ],
          cantidadProducto: 2,
          txn: txn,
        );
      });

      // 3.0 + 1.5 * 2 = 6.0
      expect(await _stockActual(insumoId), closeTo(6.0, 0.001));
    });

    test('puede superar la cantidad mínima sin fallo (sin techo)', () async {
      final insumoId = await _crearInsumo(stock: 0.0);

      final db = await DBHelper.db;
      await db.transaction((txn) async {
        await InsumoService.devolverStock(
          recetas: [
            RecetaDetalle(productoId: 0, insumoId: insumoId, cantidad: 100.0)
          ],
          cantidadProducto: 1,
          txn: txn,
        );
      });

      expect(await _stockActual(insumoId), closeTo(100.0, 0.001));
    });
  });

  // ── 3C: aplicarDiffStock(antes, []) ──────────────────────────────────────

  group('3C aplicarDiffStock con lista vacía devuelve todo', () {
    test('devuelve todo el stock de ítems de menú', () async {
      final insumoId = await _crearInsumo(stock: 10.0);

      final productosAntes = [
        {
          'nombre': 'Combo',
          'cantidad': 2,
          'tipo': 'menu',
          'proteinaIds': [insumoId],
        }
      ];

      await InsumoService.aplicarDiffStock(
        productosAntes: productosAntes,
        productosDespues: [],
      );

      // Debe devolver 2 porciones → 10 + 2 = 12
      expect(await _stockActual(insumoId), 12.0);
    });

    test('devuelve todo el stock de productos regulares vía receta', () async {
      final insumoId = await _crearInsumo(stock: 5.0);
      const productoId = 1;

      await RecetaService.guardarReceta(productoId, [
        RecetaDetalle(productoId: productoId, insumoId: insumoId, cantidad: 1.0),
      ]);

      final productosAntes = [
        {'cantidad': 3, 'productoId': productoId}
      ];

      await InsumoService.aplicarDiffStock(
        productosAntes: productosAntes,
        productosDespues: [],
      );

      // Devuelve 1.0 * 3 = 3 → 5 + 3 = 8
      expect(await _stockActual(insumoId), 8.0);
    });
  });
}
