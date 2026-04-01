import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:de_vacos/services/facturacion/facturacion_service.dart';
import 'package:de_vacos/services/insumo_service.dart';
import 'package:de_vacos/services/receta_service.dart';
import 'package:flutter/foundation.dart';

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

  /// Actualiza el estado de pago de un pedido.
  /// Si se cobra exitosamente, descuenta stock ANTES de actualizar el estado.
  /// Esto asegura que si falla el descuento, el pedido NO queda como cobrado.
  static Future<int> actualizarEstadoPago(
    int id,
    String nuevoEstadoPago, {
    String? fotoTransferenciaPath,
  }) async {
    // Si se está cobrando, descontar stock PRIMERO antes de actualizar estado
    if (nuevoEstadoPago == PaymentStatus.cobrado.displayName) {
      final pedido = await obtenerPorId(id);
      if (pedido != null) {
        // Descuenta stock (lanza excepción si stock insuficiente)
        await _descontarStockPedido(pedido);
      }
    }

    // Solo si el descuento fue exitoso, actualizar el estado de pago
    final rows = await di.pedidoRepository.actualizarEstadoPago(
      id,
      nuevoEstadoPago,
      fotoTransferenciaPath: fotoTransferenciaPath,
    );

    // Registrar venta en facturación (después de actualizar estado)
    if (rows > 0 && nuevoEstadoPago == PaymentStatus.cobrado.displayName) {
      final pedido = await obtenerPorId(id);
      if (pedido != null) {
        await FacturacionService.instance.registrarVentaCobrada(pedido);
      }
    }
    return rows;
  }

  static Future<void> _descontarStockPedido(Pedido pedido) async {
    // Parsear productos del pedido
    final productos = pedido.productos;

    for (final prod in productos) {
      final productoIdRaw = prod['productoId'] ?? prod['id'];
      if (productoIdRaw == null) {
        if (kDebugMode) {
          debugPrint(
            'Skipping product in stock discount: missing productoId/id in $prod',
          );
        }
        continue;
      }
      final productoId =
          productoIdRaw is int
              ? productoIdRaw
              : int.tryParse(productoIdRaw.toString());
      if (productoId == null) {
        if (kDebugMode) {
          debugPrint(
            'Skipping product in stock discount: cannot parse productoId from $productoIdRaw',
          );
        }
        continue;
      }

      final cantidadRaw = prod['cantidad'] ?? 1;
      final cantidad =
          cantidadRaw is int
              ? cantidadRaw
              : (cantidadRaw is double
                  ? cantidadRaw.toInt()
                  : int.tryParse(cantidadRaw.toString()) ?? 1);
      if (cantidadRaw is! int && cantidadRaw is! double) {
        if (kDebugMode) {
          debugPrint(
            'Quantity fallback to $cantidad for productoId $productoId (raw: $cantidadRaw)',
          );
        }
      }

      // Obtener receta del producto
      final recetas = await RecetaService.obtenerPorProducto(productoId);

      if (recetas.isNotEmpty) {
        await InsumoService.descontarStock(
          recetas: recetas,
          cantidadProducto: cantidad,
        );
      } else {
        if (kDebugMode) {
          debugPrint(
            'No recipe found for productoId $productoId, stock not discounted.',
          );
        }
      }
    }
  }

  static Future<int> cancelar(int id) async {
    await di.pedidoRepository.eliminarPedido(id);
    return id;
  }

  static Future<int> eliminarPedidosDelDiaActual() async {
    return await di.pedidoRepository.eliminarPedidosDelDiaActual();
  }
}
