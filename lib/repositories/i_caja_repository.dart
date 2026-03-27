import 'package:de_vacos/models/caja.dart';

abstract class ICajaRepository {
  Future<Caja> abrirCaja(Caja caja);
  Future<Caja?> obtenerCajaActiva();
  Future<List<Caja>> obtenerPorFecha(
    DateTime fechaInicio, {
    DateTime? fechaFin,
  });
  Future<void> registrarMovimiento(Caja movimiento);
  Future<double> obtenerSaldoActual();
  Future<int> guardar(Caja caja);
  Future<Caja?> obtenerCajaChicaPorFecha(DateTime fecha);
  Future<int> actualizar(Caja caja);
  Future<int> eliminar(int id);
  Future<void> eliminarPorFecha(DateTime fecha);
}
