/// Excepciones tipadas para el servicio de impresión.
/// Facilita el manejo de errores y mensajes claros al usuario.
abstract class PrinterException implements Exception {
  final String message;
  final String? details;

  const PrinterException(this.message, [this.details]);

  @override
  String toString() => details != null ? '$message: $details' : message;
}

/// Error cuando el servicio no está inicializado
class PrinterNotInitializedException extends PrinterException {
  const PrinterNotInitializedException([String? details])
      : super('El servicio de impresión no está inicializado', details);
}

/// Error cuando no se encuentran impresoras disponibles
class PrinterNotFoundException extends PrinterException {
  const PrinterNotFoundException([String? details])
      : super('No se encontraron impresoras disponibles', details);
}

/// Error al conectar con la impresora
class PrinterConnectionException extends PrinterException {
  const PrinterConnectionException([String? details])
      : super('Error al conectar con la impresora', details);
}

/// Error cuando la impresora se desconecta durante la impresión
class PrinterDisconnectedException extends PrinterException {
  const PrinterDisconnectedException([String? details])
      : super('La impresora se desconectó durante la impresión', details);
}

/// Error al enviar datos a la impresora
class PrinterSendException extends PrinterException {
  const PrinterSendException([String? details])
      : super('Error al enviar datos a la impresora', details);
}

/// Error cuando la plataforma no soporta impresión
class PrinterPlatformNotSupportedException extends PrinterException {
  const PrinterPlatformNotSupportedException([String? platform])
      : super('La plataforma no soporta impresión térmica', platform);
}

/// Error de timeout al conectar o imprimir
class PrinterTimeoutException extends PrinterException {
  const PrinterTimeoutException([String? details])
      : super('Tiempo de espera agotado', details);
}

/// Error cuando faltan permisos USB
class PrinterUsbPermissionException extends PrinterException {
  const PrinterUsbPermissionException([String? details])
      : super('Error de permisos USB', details);
}

/// Error cuando la impresora no está conectada
class PrinterNotConnectedException extends PrinterException {
  const PrinterNotConnectedException([String? details])
      : super('No hay impresora conectada', details);
}

