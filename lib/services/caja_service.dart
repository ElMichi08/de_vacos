import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/caja.dart';

class CajaService {
  static Future<int> guardar(Caja movimiento) async {
    final error = movimiento.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }

    if (movimiento.tipo == 'Caja Chica') {
      final fecha = DateTime(
        movimiento.fecha.year,
        movimiento.fecha.month,
        movimiento.fecha.day,
      );
      final existente = await obtenerCajaChicaPorFecha(fecha);
      if (existente != null && existente.id != movimiento.id) {
        throw Exception(
          'Ya existe una Caja Chica para esta fecha. Puedes editarla pero no crear otra.',
        );
      }
    }

    return await di.cajaRepository.guardar(movimiento);
  }

  static Future<List<Caja>> obtenerPorFecha(
    DateTime fecha, {
    DateTime? fechaFin,
  }) async {
    return di.cajaRepository.obtenerPorFecha(fecha, fechaFin: fechaFin);
  }

  static Future<Caja?> obtenerCajaChicaPorFecha(DateTime fecha) async {
    return await di.cajaRepository.obtenerCajaChicaPorFecha(fecha);
  }

  static Future<List<Caja>> obtenerTodos() async {
    return await obtenerPorFecha(DateTime.now());
  }

  static Future<int> actualizar(Caja movimiento) async {
    if (movimiento.id == null) {
      throw Exception('El movimiento debe tener un ID para actualizar');
    }

    final error = movimiento.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }

    return await di.cajaRepository.actualizar(movimiento);
  }

  static Future<int> eliminar(int id) async {
    return await di.cajaRepository.eliminar(id);
  }

  static Future<void> eliminarPorFecha(DateTime fecha) async {
    await di.cajaRepository.eliminarPorFecha(fecha);
  }
}
