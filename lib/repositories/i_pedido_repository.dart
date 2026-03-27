import 'package:de_vacos/models/pedido.dart';

abstract class IPedidoRepository {
  Future<Pedido> crearPedido(Pedido pedido);
  Future<Pedido?> obtenerPedidoPorId(int id);
  Future<List<Pedido>> obtenerTodosLosPedidos();
  Future<List<Pedido>> obtenerPorFecha(
    DateTime fechaInicio, {
    DateTime? fechaFin,
    bool incluirCancelados = false,
  });
  Future<void> actualizarEstado(int id, String estado);
  Future<void> actualizarPedido(Pedido pedido);
  Future<void> eliminarPedido(int id);
  Future<int> actualizarEstadoPago(int pedidoId, String estadoPago, {String? fotoTransferenciaPath});
  Future<int> eliminarPedidosDelDiaActual();
}
