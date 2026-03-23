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
}

