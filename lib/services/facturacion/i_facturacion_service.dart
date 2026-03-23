import '../../models/pedido.dart';

/// Contrato para el servicio de facturación.
/// Permite registrar ventas cobradas (ej. para integración con sistemas externos)
/// sin acoplar la UI a una implementación concreta.
abstract class IFacturacionService {
  /// Registra una venta ya cobrada (ej. enviar a sistema de facturación electrónica).
  /// Se invoca cuando un pedido pasa a estado de pago "Cobrado".
  Future<void> registrarVentaCobrada(Pedido pedido);
}
