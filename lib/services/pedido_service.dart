import 'dart:convert';
import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/models/receta_detalle.dart';
import 'package:de_vacos/services/facturacion/facturacion_service.dart';
import 'package:de_vacos/services/insumo_service.dart';
import 'package:de_vacos/services/receta_service.dart';
import 'package:de_vacos/core/database/db_helper.dart';

class PedidoService {
  static Future<List<Pedido>> obtenerTodos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final inicio = fechaInicio ?? DateTime.now();
    return di.pedidoRepository.obtenerPorFecha(
      inicio,
      fechaFin: fechaFin,
      incluirCancelados: false,
    );
  }

  static Future<List<Pedido>> obtenerTodosConCancelados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final inicio = fechaInicio ?? DateTime.now();
    return di.pedidoRepository.obtenerPorFecha(
      inicio,
      fechaFin: fechaFin,
      incluirCancelados: true,
    );
  }

  static Future<Map<String, dynamic>> obtenerTodosPaginados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int pagina = 1,
    int tamanoPagina = 20,
  }) async {
    final all = await obtenerTodos(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final total = all.length;
    final start = (pagina - 1) * tamanoPagina;
    final end = (start + tamanoPagina) > total ? total : (start + tamanoPagina);
    if (start >= total) {
      return {
        'pedidos': <Pedido>[],
        'total': total,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'totalPaginas': (total / tamanoPagina).ceil(),
      };
    }
    final pedidos = all.sublist(start, end);
    final totalPaginas = (total / tamanoPagina).ceil();
    return {
      'pedidos': pedidos,
      'total': total,
      'pagina': pagina,
      'tamanoPagina': tamanoPagina,
      'totalPaginas': totalPaginas,
    };
  }

  static Future<Map<String, dynamic>> obtenerPorEstadoPaginados(
    String estado, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int pagina = 1,
    int tamanoPagina = 20,
  }) async {
    final list = await obtenerPorEstado(
      estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final total = list.length;
    final start = (pagina - 1) * tamanoPagina;
    final end = (start + tamanoPagina) > total ? total : (start + tamanoPagina);
    if (start >= total) {
      return {
        'pedidos': <Pedido>[],
        'total': total,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'totalPaginas': (total / tamanoPagina).ceil(),
      };
    }
    final pedidos = list.sublist(start, end);
    final totalPaginas = (total / tamanoPagina).ceil();
    return {
      'pedidos': pedidos,
      'total': total,
      'pagina': pagina,
      'tamanoPagina': tamanoPagina,
      'totalPaginas': totalPaginas,
    };
  }

  static Future<List<Pedido>> obtenerPorEstado(
    String estado, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    if (estado == 'Canceladas') {
      final all = await obtenerTodosConCancelados(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      return all.where((p) => p.cancelado).toList();
    }
    final all = await obtenerTodos(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final estadoEnum = OrderStatus.fromString(estado);
    return all.where((p) => p.estado == estadoEnum && !p.cancelado).toList();
  }

  static Future<Pedido?> obtenerPorId(int id) async {
    return di.pedidoRepository.obtenerPedidoPorId(id);
  }

  static Future<int> guardar(Pedido pedido) async {
    final creado = await di.pedidoRepository.crearPedido(pedido);
    return creado.id ?? 0;
  }

  static Future<int> actualizar(Pedido pedido) async {
    await di.pedidoRepository.actualizarPedido(pedido);
    return pedido.id ?? 0;
  }

  /// Actualiza un pedido ya cobrado con snapshot: aplica el diff de stock
  /// vs [pedidoAnterior.productosCobrados] y actualiza el snapshot —
  /// todo en una sola transacción atómica. Marca estadoPago = recobrar
  /// para que la conciliación de pago posterior no vuelva a tocar el stock.
  static Future<void> actualizarConDiffStock({
    required Pedido pedidoAnterior,
    required Pedido pedidoNuevo,
  }) async {
    final error = pedidoNuevo.validar();
    if (error != null) throw Exception('Validación: $error');

    final db = await DBHelper.db;
    await db.transaction((txn) async {
      // 1. Guardar datos del pedido
      await txn.update(
        'pedidos',
        pedidoNuevo.toMap(),
        where: 'id = ?',
        whereArgs: [pedidoNuevo.id],
      );

      // 2. Ajustar stock: solo el delta respecto a lo cobrado anteriormente
      await InsumoService.aplicarDiffStock(
        productosAntes: pedidoAnterior.productosCobrados!,
        productosDespues: pedidoNuevo.productos,
        txn: txn,
      );

      // 3. Actualizar snapshot + marcar para recobro de pago
      await txn.update(
        'pedidos',
        {
          'estadoPago': PaymentStatus.recobrar.displayName,
          'productosCobrados': jsonEncode(pedidoNuevo.productos),
        },
        where: 'id = ?',
        whereArgs: [pedidoNuevo.id],
      );
    });
  }

  static Future<int> actualizarEstado(int id, String nuevoEstado) async {
    // Validar que no se pueda cerrar un pedido sin cobrar
    if (nuevoEstado == OrderStatus.cerrados.displayName) {
      final pedido = await obtenerPorId(id);
      if (pedido != null && pedido.estadoPago != PaymentStatus.cobrado) {
        throw Exception('No se puede cerrar un pedido sin cobrar');
      }
    }
    await di.pedidoRepository.actualizarEstado(id, nuevoEstado);
    return id;
  }

  /// Marca el pedido como [recobrar] sin tocar pagos ni stock.
  /// Se llama al guardar una edición sobre un pedido ya cobrado.
  static Future<void> setRecobrar(int id) async {
    await di.pedidoRepository.setRecobrar(id);
  }

  /// Actualiza el estado de pago de un pedido.
  /// Si se cobra exitosamente, descuenta stock Y actualiza el estado en UNA transacción.
  /// Esto evita el locking de la base de datos.
  static Future<int> actualizarEstadoPago(
    int id,
    String nuevoEstadoPago, {
    PaymentMethod? metodoPago,
    double? montoPagado,
    String? fotoTransferenciaPath,
  }) async {
    if (nuevoEstadoPago != PaymentStatus.cobrado.displayName) {
      return await di.pedidoRepository.actualizarEstadoPago(
        id,
        nuevoEstadoPago,
        metodoPago: metodoPago,
        montoPagado: montoPagado,
        fotoTransferenciaPath: fotoTransferenciaPath,
      );
    }

    final pedido = await obtenerPorId(id);
    if (pedido == null) return 0;

    final db = await DBHelper.db;
    return await db.transaction((txn) async {
      if (pedido.productosCobrados == null) {
        // Cobro inicial: descontar stock completo (UC-01)
        for (final prod in pedido.productos) {
          final cantidadRaw = prod['cantidad'] ?? 1;
          final cantidad =
              cantidadRaw is int
                  ? cantidadRaw
                  : (cantidadRaw is double
                      ? cantidadRaw.toInt()
                      : int.tryParse(cantidadRaw.toString()) ?? 1);

          // Ítem de menú: descontar proteínas directamente por ID (UC-02 menú)
          if (prod['tipo'] == 'menu') {
            final rawIds = prod['proteinaIds'];
            if (rawIds is List) {
              for (final rawId in rawIds) {
                final insumoId =
                    rawId is int ? rawId : int.tryParse(rawId.toString());
                if (insumoId == null) continue;
                final receta = [
                  RecetaDetalle(
                    productoId: 0,
                    insumoId: insumoId,
                    cantidad: 1.0,
                  )
                ];
                await InsumoService.descontarStock(
                  recetas: receta,
                  cantidadProducto: cantidad,
                  txn: txn,
                );
              }
            }
            continue;
          }

          // Producto regular: descontar vía receta_detalle
          final productoIdRaw = prod['productoId'] ?? prod['id'];
          if (productoIdRaw == null) continue;

          final productoId =
              productoIdRaw is int
                  ? productoIdRaw
                  : int.tryParse(productoIdRaw.toString());
          if (productoId == null) continue;

          final recetas = await RecetaService.obtenerPorProducto(productoId, txn: txn);
          if (recetas.isNotEmpty) {
            await InsumoService.descontarStock(
              recetas: recetas,
              cantidadProducto: cantidad,
              txn: txn,
            );
          }
        }
      } else {
        // Re-cobro incremental: solo descontar/devolver el diff (UC-04)
        await InsumoService.aplicarDiffStock(
          productosAntes: pedido.productosCobrados!,
          productosDespues: pedido.productos,
          txn: txn,
        );
      }

      final rows = await di.pedidoRepository.actualizarEstadoPago(
        id,
        nuevoEstadoPago,
        metodoPago: metodoPago,
        montoPagado: montoPagado,
        fotoTransferenciaPath: fotoTransferenciaPath,
        productosCobradosJson: jsonEncode(pedido.productos),
        txn: txn,
      );

      if (rows > 0) {
        await FacturacionService.instance.registrarVentaCobrada(pedido);
      }

      return rows;
    });
  }

  /// Cancela un pedido con elección de devolución de stock (UC-06).
  /// Si [devolverStock] es true y había snapshot, revierte el stock descontado.
  static Future<int> cancelarConEleccion(
    int id, {
    required bool devolverStock,
  }) async {
    final pedido = await obtenerPorId(id);
    if (pedido == null) return 0;

    final db = await DBHelper.db;
    return await db.transaction((txn) async {
      if (devolverStock && pedido.productosCobrados != null) {
        await InsumoService.aplicarDiffStock(
          productosAntes: pedido.productosCobrados!,
          productosDespues: [],
          txn: txn,
        );
      }
      await txn.update(
        'pedidos',
        {'cancelado': 1, 'estado': 'Cancelada'},
        where: 'id = ?',
        whereArgs: [id],
      );
      return 1;
    });
  }

  static Future<int> cancelar(int id) async {
    await di.pedidoRepository.eliminarPedido(id);
    return id;
  }

  static Future<int> eliminarPedidosDelDiaActual() async {
    return await di.pedidoRepository.eliminarPedidosDelDiaActual();
  }
}
