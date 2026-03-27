import 'package:de_vacos/injection/container.dart';

class VentasService {
  static Future<double> obtenerVentasDelDia(DateTime fecha) async {
    return di.ventasRepository.obtenerVentasDelDia(fecha);
  }

  static Future<double> obtenerVentasDelRango(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    return di.ventasRepository.obtenerVentasDelRango(fechaInicio, fechaFin);
  }
}
