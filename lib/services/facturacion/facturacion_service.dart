import 'i_facturacion_service.dart';
import 'facturacion_service_no_op.dart';

/// Punto de acceso al servicio de facturación.
/// Por defecto devuelve la implementación no-op; se puede cambiar
/// por una implementación real sin tocar la UI.
class FacturacionService {
  static IFacturacionService? _instance;

  /// Instancia actual del servicio de facturación (por defecto NoOp).
  static IFacturacionService get instance => _instance ??= FacturacionServiceNoOp();
}
