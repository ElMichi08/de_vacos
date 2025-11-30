/// Helper para acceder de forma segura a los datos de productos en tickets
/// Proporciona métodos type-safe para evitar errores en runtime
class ProductoTicketHelper {
  /// Obtiene el nombre del producto de forma segura
  static String getNombre(Map<String, dynamic> producto) {
    return producto['nombre'] as String? ?? 'Producto';
  }

  /// Obtiene el precio del producto de forma segura
  /// Soporta tanto 'precio' como 'precioBase' para retrocompatibilidad
  static double getPrecio(Map<String, dynamic> producto) {
    final precio = producto['precio'] ?? producto['precioBase'];
    if (precio is num) {
      return precio.toDouble();
    }
    return 0.0;
  }

  /// Obtiene la cantidad del producto de forma segura
  static int getCantidad(Map<String, dynamic> producto) {
    final cantidad = producto['cantidad'];
    if (cantidad is int) {
      return cantidad;
    }
    if (cantidad is num) {
      return cantidad.toInt();
    }
    return 1;
  }

  /// Obtiene la variante del producto de forma segura
  static String? getVariante(Map<String, dynamic> producto) {
    return producto['variante'] as String?;
  }

  /// Obtiene la lista de acompañantes de forma segura
  /// Retorna lista vacía si no hay acompañantes o el formato es incorrecto
  static List<Map<String, dynamic>> getAcompanantes(
    Map<String, dynamic> producto,
  ) {
    final acompanantes = producto['acompanantes'];
    if (acompanantes is List) {
      return acompanantes
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  /// Obtiene el acompañante en formato antiguo (retrocompatibilidad)
  static String? getAcompananteAntiguo(Map<String, dynamic> producto) {
    return producto['acompanante'] as String?;
  }

  /// Obtiene la lista de extras de forma segura
  /// Convierte todos los extras a String
  static List<String> getExtras(Map<String, dynamic> producto) {
    final extras = producto['extras'];
    if (extras is List) {
      return extras.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Calcula el precio total de un producto (precio * cantidad)
  static double calcularPrecioTotal(Map<String, dynamic> producto) {
    final precio = getPrecio(producto);
    final cantidad = getCantidad(producto);
    return precio * cantidad;
  }
}

