import 'producto_ticket_helper.dart';
import '../ticket_builder.dart';

/// Clase responsable de formatear el contenido del ticket
/// Centraliza la lógica de construcción de strings para evitar duplicación
class TicketFormatter {
  /// Formatea el detalle completo de un producto (acompañantes + extras)
  /// Retorna string vacío si no hay detalles
  static String formatearDetalleProducto(Map<String, dynamic> producto) {
    final acompanantesStr = _formatearAcompanantes(producto);
    final extrasStr = _formatearExtras(producto);

    if (acompanantesStr.isNotEmpty && extrasStr.isNotEmpty) {
      return '$acompanantesStr, $extrasStr';
    } else if (acompanantesStr.isNotEmpty) {
      return acompanantesStr;
    } else if (extrasStr.isNotEmpty) {
      return extrasStr;
    }
    return '';
  }

  /// Formatea los acompañantes de un producto
  /// Soporta tanto el formato nuevo (lista) como el antiguo (string único)
  static String _formatearAcompanantes(Map<String, dynamic> producto) {
    final acompanantes = ProductoTicketHelper.getAcompanantes(producto);
    
    if (acompanantes.isNotEmpty) {
      return acompanantes.map((a) {
        final nombre = a['nombre'] as String? ?? '';
        final cant = a['cantidad'] as int? ?? 1;
        final nombreNormalizado = TicketBuilder.normalizeToAscii(nombre);
        return cant > 1 ? '$nombreNormalizado x$cant' : nombreNormalizado;
      }).join(', ');
    }
    
    // Retrocompatibilidad: formato antiguo con un solo acompañante
    final acompananteAntiguo = ProductoTicketHelper.getAcompananteAntiguo(producto);
    if (acompananteAntiguo != null && acompananteAntiguo.isNotEmpty) {
      return TicketBuilder.normalizeToAscii(acompananteAntiguo);
    }
    
    return '';
  }

  /// Formatea los extras de un producto
  static String _formatearExtras(Map<String, dynamic> producto) {
    final extras = ProductoTicketHelper.getExtras(producto);
    if (extras.isEmpty) {
      return '';
    }

    return extras
        .map((e) => TicketBuilder.normalizeToAscii(e))
        .join(', ');
  }

  /// Formatea el texto de cantidad y precio unitario
  static String formatearCantidadYPrecio(int cantidad, double precio) {
    return 'Cant: $cantidad  \$${precio.toStringAsFixed(2)} c/u';
  }

  /// Formatea el texto de envases
  static String formatearEnvases(int cantidad, double precioUnitario) {
    final total = cantidad * precioUnitario;
    return 'Envases (${cantidad}x \$${precioUnitario.toStringAsFixed(2)}): \$${total.toStringAsFixed(2)}';
  }

  /// Formatea el texto del total a pagar
  static String formatearTotal(double total) {
    return 'Total a pagar:     \$${total.toStringAsFixed(2)}';
  }
}

