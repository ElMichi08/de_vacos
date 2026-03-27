import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/services/facturacion/facturacion_service.dart';

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
    return all.where((p) => p.estado == estado && !p.cancelado).toList();
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
    await di.pedidoRepository.actualizarEstado(id, nuevoEstado);
    return id;
  }

  static Future<int> actualizarEstadoPago(
    int id,
    String nuevoEstadoPago, {
    String? fotoTransferenciaPath,
  }) async {
    final rows = await di.pedidoRepository.actualizarEstadoPago(
      id,
      nuevoEstadoPago,
      fotoTransferenciaPath: fotoTransferenciaPath,
    );
    if (rows > 0 && nuevoEstadoPago == 'Cobrado') {
      final pedido = await obtenerPorId(id);
      if (pedido != null) {
        await FacturacionService.instance.registrarVentaCobrada(pedido);
      }
    }
    return rows;
  }

  static Future<int> cancelar(int id) async {
    await di.pedidoRepository.eliminarPedido(id);
    return id;
  }

  static Future<int> eliminarPedidosDelDiaActual() async {
    return await di.pedidoRepository.eliminarPedidosDelDiaActual();
  }
}
