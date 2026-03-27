abstract class IVentasRepository {
  Future<double> obtenerVentasDelDia(DateTime fecha);
  Future<double> obtenerVentasDelRango(DateTime fechaInicio, DateTime fechaFin);
}
