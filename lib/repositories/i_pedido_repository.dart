import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  Future<int> actualizarEstadoPago(
    int pedidoId,
    String estadoPago, {
    PaymentMethod? metodoPago,
    double? montoPagado,
    String? fotoTransferenciaPath,
    String? productosCobradosJson,
    Transaction? txn,
  });
  Future<void> setRecobrar(int pedidoId, {Transaction? txn});
  Future<int> eliminarPedidosDelDiaActual();
}
