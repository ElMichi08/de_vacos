import 'printer_exceptions.dart';

/// Resultado de una operación de impresión
/// Encapsula el resultado exitoso o el error sin usar excepciones
sealed class PrinterResult<T> {
  const PrinterResult();

  /// Verifica si el resultado es exitoso
  bool get isSuccess;

  /// Verifica si el resultado es fallo
  bool get isFailure;
}

/// Resultado exitoso de una operación de impresión
class PrinterSuccess<T> extends PrinterResult<T> {
  final T data;

  const PrinterSuccess(this.data);

  @override
  bool get isSuccess => true;
  @override
  bool get isFailure => false;
}

/// Resultado fallido de una operación de impresión
class PrinterFailure<T> extends PrinterResult<T> {
  final String message;
  final PrinterException? exception;

  const PrinterFailure(this.message, [this.exception]);

  @override
  bool get isSuccess => false;
  @override
  bool get isFailure => true;

  @override
  String toString() => message;
}

/// Extensión para facilitar el uso de PrinterResult
extension PrinterResultExtension<T> on PrinterResult<T> {
  /// Retorna el mensaje de error si es fallo, o null si es éxito
  String? get errorOrNull {
    return switch (this) {
      PrinterSuccess() => null,
      PrinterFailure(message: final message) => message,
    };
  }
  /// Retorna el valor si es éxito, o null si es fallo
  T? get valueOrNull {
    return switch (this) {
      PrinterSuccess(data: final data) => data,
      PrinterFailure() => null,
    };
  }

  /// Ejecuta una función si es éxito
  PrinterResult<U> map<U>(U Function(T) mapper) {
    return switch (this) {
      PrinterSuccess(data: final data) => PrinterSuccess(mapper(data)),
      PrinterFailure(message: final message, exception: final exception) =>
        PrinterFailure(message, exception),
    };
  }

  /// Ejecuta una función si es fallo
  PrinterResult<T> mapError(String Function(String) mapper) {
    return switch (this) {
      PrinterSuccess() => this,
      PrinterFailure(message: final message, exception: final exception) =>
        PrinterFailure(mapper(message), exception),
    };
  }
}

