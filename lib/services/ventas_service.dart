import '../core/database/db_helper.dart';

/// Servicio para calcular ventas desde pedidos
class VentasService {
  /// Obtiene el total de ventas del día desde pedidos
  /// Filtros: cancelado = 0, estadoPago = 'Cobrado'
  /// Retorna el total de ventas (double)
  static Future<double> obtenerVentasDelDia(DateTime fecha) async {
    try {
      final inicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
      
      final auditoria = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
      return auditoria['total'] as double;
    } catch (e) {
      throw Exception('Error al obtener ventas del día: $e');
    }
  }
  
  /// Obtiene el total de ventas de un rango de fechas desde pedidos
  /// Filtros: cancelado = 0, estadoPago = 'Cobrado'
  /// Retorna el total de ventas (double)
  static Future<double> obtenerVentasDelRango(DateTime fechaInicio, DateTime fechaFin) async {
    try {
      final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
      final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999);
      
      final auditoria = await DBHelper.obtenerAuditoriaSemanal(inicio, fin);
      return auditoria['total'] as double;
    } catch (e) {
      throw Exception('Error al obtener ventas del rango: $e');
    }
  }
}

