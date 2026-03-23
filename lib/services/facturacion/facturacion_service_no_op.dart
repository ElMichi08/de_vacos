import '../../models/pedido.dart';
import 'i_facturacion_service.dart';

/// Implementación que no realiza ninguna acción.
/// Permite tener el punto de integración listo sin afectar el flujo actual.
class FacturacionServiceNoOp implements IFacturacionService {
  @override
  Future<void> registrarVentaCobrada(Pedido pedido) async {
    // No-op: en el futuro sustituir por implementación real (API, cola, etc.)
  }
}
