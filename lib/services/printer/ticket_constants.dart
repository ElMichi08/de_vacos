import '../../core/config/app_config.dart';

/// Constantes utilizadas en la generación de tickets
class TicketConstants {
  /// Precio unitario de un envase para llevar
  static const double precioEnvase = 0.25;

  /// Nombre del restaurante (desde config de marca)
  static String get nombreRestaurante => AppConfig.instance.appName;

  /// Número de dígitos para el padding de factura
  static const int facturaPadding = 6;

  /// Carácter de padding para factura
  static const String facturaPaddingChar = '0';

  /// Tolerancia para comparación de totales (para evitar problemas de precisión de punto flotante)
  static const double toleranciaTotal = 0.01;

  /// Símbolo de moneda configurado
  /// Algunas impresoras chinas interpretan '$' como '¥' debido a páginas de código diferentes
  /// Este símbolo se usa en todos los tickets para consistencia
  static const String currencySymbol = '\$';

  /// Altura de fuente para títulos en 56mm (más compacto)
  static const int titleHeight56mm = 1;

  /// Altura de fuente para títulos en 80mm
  static const int titleHeight80mm = 2;

  /// Ancho máximo de caracteres por línea en 56mm
  static const int maxCharsPerLine56mm = 32;

  /// Ancho máximo de caracteres por línea en 80mm
  static const int maxCharsPerLine80mm = 48;

  /// Trunca texto al ancho máximo del papel
  static String truncateToWidth(String text, bool is56mm) {
    final maxWidth = is56mm ? maxCharsPerLine56mm : maxCharsPerLine80mm;
    if (text.length <= maxWidth) return text;
    return '${text.substring(0, maxWidth - 2)}..';
  }
}
