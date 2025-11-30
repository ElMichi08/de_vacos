/// Validadores reutilizables para formularios
class Validators {
  /// Valida que un texto no esté vacío
  static String? required(String? value, {String message = 'Este campo es obligatorio'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Valida un número positivo
  static String? positiveNumber(String? value, {String message = 'Debe ser un número positivo'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return message;
    }
    return null;
  }

  /// Valida un teléfono
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }
    // Validación básica: al menos 7 dígitos
    if (value.trim().length < 7) {
      return 'El teléfono debe tener al menos 7 dígitos';
    }
    return null;
  }

  Validators._();
}

