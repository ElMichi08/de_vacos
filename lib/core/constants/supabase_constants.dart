/// Constantes de tablas y columnas de Supabase para uso en panel web y app.
/// Mantener DRY entre lectura de reportes_semanales y cobros.
class SupabaseConstants {
  SupabaseConstants._();

  // Tablas
  static const String tableReportesSemanales = 'reportes_semanales';
  static const String tableCobros = 'cobros';

  // Columnas reportes_semanales
  static const String colReporteId = 'id';
  static const String colReporteClienteId = 'cliente_id';
  static const String colReporteFechaCorte = 'fecha_corte';
  static const String colReporteCantidadPedidos = 'cantidad_pedidos';
  static const String colReporteTotalVentas = 'total_ventas';
  static const String colReporteTotalComision = 'total_comision_esperada';
  static const String colReporteEstadoPago = 'estado_pago';

  // Columnas cobros
  static const String colCobroId = 'id';
  static const String colCobroClienteId = 'cliente_id';
  static const String colCobroMontoAPagar = 'monto_a_pagar';
  static const String colCobroEstado = 'estado';
}
