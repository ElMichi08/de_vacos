import 'producto_ticket_helper.dart';
import '../ticket_builder.dart';
import '../ticket_constants.dart';

/// Clase responsable de formatear el contenido del ticket
/// Centraliza la lógica de construcción de strings para evitar duplicación
class TicketFormatter {
  /// Formatea el detalle completo de un producto (acompañantes + extras)
  /// Retorna string vacío si no hay detalles
  static String formatearDetalleProducto(
    Map<String, dynamic> producto, {
    bool is56mm = false,
  }) {
    final acompanantesStr = _formatearAcompanantes(producto);
    final extrasStr = _formatearExtras(producto);

    String resultado;
    if (acompanantesStr.isNotEmpty && extrasStr.isNotEmpty) {
      resultado = '$acompanantesStr, $extrasStr';
    } else if (acompanantesStr.isNotEmpty) {
      resultado = acompanantesStr;
    } else if (extrasStr.isNotEmpty) {
      resultado = extrasStr;
    } else {
      resultado = '';
    }

    return is56mm
        ? TicketConstants.truncateToWidth(resultado, true)
        : resultado;
  }

  /// Formatea los acompañantes de un producto
  /// Soporta tanto el formato nuevo (lista) como el antiguo (string único)
  static String _formatearAcompanantes(Map<String, dynamic> producto) {
    final acompanantes = ProductoTicketHelper.getAcompanantes(producto);

    if (acompanantes.isNotEmpty) {
      return acompanantes
          .map((a) {
            final nombre = a['nombre'] as String? ?? '';
            final cant = a['cantidad'] as int? ?? 1;
            final nombreNormalizado = TicketBuilder.normalizeToAscii(nombre);
            return cant > 1 ? '$nombreNormalizado x$cant' : nombreNormalizado;
          })
          .join(', ');
    }

    // Retrocompatibilidad: formato antiguo con un solo acompañante
    final acompananteAntiguo = ProductoTicketHelper.getAcompananteAntiguo(
      producto,
    );
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

    return extras.map((e) => TicketBuilder.normalizeToAscii(e)).join(', ');
  }

  /// Formatea el texto de cantidad y precio unitario
  /// [is56mm] - Si es true, usa formato más compacto para papel de 56mm
  static String formatearCantidadYPrecio(
    int cantidad,
    double precio, {
    bool is56mm = false,
  }) {
    final texto =
        is56mm
            ? '${cantidad}x ${_formatPrice(precio)} c/u'
            : 'Cant: $cantidad  ${_formatPrice(precio)} c/u';
    return is56mm ? TicketConstants.truncateToWidth(texto, true) : texto;
  }

  /// Formatea el texto de envases
  /// [is56mm] - Si es true, usa formato más compacto
  static String formatearEnvases(
    int cantidad,
    double precioUnitario, {
    bool is56mm = false,
  }) {
    final total = cantidad * precioUnitario;
    final texto =
        is56mm
            ? 'Env: ${cantidad}x${_formatPrice(precioUnitario)} = ${_formatPrice(total)}'
            : 'Envases (${cantidad}x ${_formatPrice(precioUnitario)}): ${_formatPrice(total)}';
    return is56mm ? TicketConstants.truncateToWidth(texto, true) : texto;
  }

  /// Formatea el texto del total a pagar
  /// [is56mm] - Si es true, usa formato más compacto
  static String formatearTotal(double total, {bool is56mm = false}) {
    final texto =
        is56mm
            ? 'TOTAL: ${_formatPrice(total)}'
            : 'Total a pagar:     ${_formatPrice(total)}';
    return texto;
  }

  /// Formatea un precio con el símbolo de moneda
  /// Usa el símbolo configurado en TicketConstants
  static String _formatPrice(double price) {
    return '${TicketConstants.currencySymbol}${price.toStringAsFixed(2)}';
  }

  /// Formatea nombre de producto truncado según tamaño de papel
  static String formatearNombreProducto(String nombre, {bool is56mm = false}) {
    final normalizado = TicketBuilder.normalizeToAscii(nombre);
    return is56mm
        ? TicketConstants.truncateToWidth(normalizado, true)
        : normalizado;
  }
}
