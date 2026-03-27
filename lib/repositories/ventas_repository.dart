import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/repositories/i_ventas_repository.dart';

class VentasRepository implements IVentasRepository {
  @override
  Future<double> obtenerVentasDelDia(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
    final auditoria = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
    return auditoria['total'] as double;
  }

  @override
  Future<double> obtenerVentasDelRango(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    final fin = DateTime(
      fechaFin.year,
      fechaFin.month,
      fechaFin.day,
      23,
      59,
      59,
      999,
    );
    final auditoria = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
    return auditoria['total'] as double;
  }
}
