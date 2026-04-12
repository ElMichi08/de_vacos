/// Modelo para representar un acompañante seleccionado con cantidad
class AcompananteSeleccionado {
  final String nombre;
  final double precioAdicional;
  final int cantidad;

  AcompananteSeleccionado({
    required this.nombre,
    required this.precioAdicional,
    required this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precioAdicional': precioAdicional,
      'cantidad': cantidad,
    };
  }

  factory AcompananteSeleccionado.fromMap(Map<String, dynamic> map) {
    // Helper to parse int safely
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper to parse double safely
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return AcompananteSeleccionado(
      nombre: map['nombre']?.toString() ?? '',
      precioAdicional: parseDouble(map['precioAdicional']),
      cantidad: parseInt(map['cantidad'], defaultValue: 1),
    );
  }
}

/// Modelo para representar un producto seleccionado en un pedido
/// Incluye el producto base, variante seleccionada, acompañantes con cantidades y extras
/// Permite múltiples acompañantes, donde la suma de sus cantidades debe ser igual a la cantidad del producto
class ProductoSeleccionado {
  final String id; // ID único para identificar esta instancia específica
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final String?
  varianteNombre; // Nombre de la variante seleccionada (null si no tiene variantes)
  final double precioBase; // Precio de la variante o precio base
  final List<AcompananteSeleccionado>
  acompanantes; // Lista de acompañantes con cantidades
  final List<String> extrasNombres; // Lista de nombres de extras seleccionados
  final double precioExtras; // Suma de precios de extras

  ProductoSeleccionado({
    String? id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    this.varianteNombre,
    required this.precioBase,
    List<AcompananteSeleccionado>? acompanantes,
    List<String>? extrasNombres,
    this.precioExtras = 0.0,
    // Retrocompatibilidad: mantener campos antiguos
    String? acompananteNombre,
    double precioAcompanante = 0.0,
  }) : id =
           id ??
           '${DateTime.now().millisecondsSinceEpoch}_${productoId}_${varianteNombre ?? 'base'}',
       extrasNombres = extrasNombres ?? [],
       acompanantes =
           acompanantes ??
           (acompananteNombre != null
               ? [
                 AcompananteSeleccionado(
                   nombre: acompananteNombre,
                   precioAdicional: precioAcompanante,
                   cantidad: 1,
                 ),
               ]
               : []);

  /// Calcula el precio total de acompañantes para esta instancia
  /// Como cada instancia tiene cantidad = 1, esto es simplemente la suma de precios
  double get precioAcompanantesTotal {
    return acompanantes.fold<double>(
      0.0,
      (sum, a) => sum + (a.precioAdicional * a.cantidad),
    );
  }

  /// Calcula el precio unitario de esta instancia (cantidad siempre es 1)
  double get precioUnitario =>
      precioBase + precioAcompanantesTotal + precioExtras;

  /// Calcula el precio total (precio unitario * cantidad)
  /// Como cantidad siempre es 1, esto es igual a precioUnitario
  double get precioTotal => precioUnitario * cantidad;

  /// Genera un nombre descriptivo para mostrar en la UI
  String get nombreCompleto {
    final partes = <String>[nombreProducto];

    if (varianteNombre != null) {
      partes.add('($varianteNombre)');
    }

    // Mostrar acompañantes con sus cantidades
    if (acompanantes.isNotEmpty) {
      final acompanantesStr = acompanantes
          .map((a) => a.cantidad > 1 ? '${a.nombre} x${a.cantidad}' : a.nombre)
          .join(', ');
      partes.add('+ $acompanantesStr');
    }

    if (extrasNombres.isNotEmpty) {
      partes.add('+ ${extrasNombres.join(", ")}');
    }

    return partes.join(' ');
  }

  /// Valida que la suma de cantidades de acompañantes sea igual a la cantidad del producto
  bool get acompanantesValidados {
    if (acompanantes.isEmpty) return true;
    final totalAcompanantes = acompanantes.fold<int>(
      0,
      (sum, a) => sum + a.cantidad,
    );
    return totalAcompanantes == cantidad;
  }

  /// Convierte a Map para guardar en el pedido
  /// Incluye toda la información detallada para poder reconstruir la instancia
  Map<String, dynamic> toMap() {
    return {
      'id': productoId,
      'instanciaId': id, // ID único de esta instancia
      'nombre': nombreProducto, // Nombre base del producto
      'nombreCompleto': nombreCompleto, // Nombre completo con opciones
      'precio': precioUnitario,
      'cantidad': cantidad,
      // Guardar detalles para poder reconstruir
      'variante': varianteNombre,
      'acompanantes': acompanantes.map((a) => a.toMap()).toList(),
      'extras': extrasNombres,
      'precioBase': precioBase,
      'precioAcompanantesTotal': precioAcompanantesTotal,
      'precioExtras': precioExtras,
      // Retrocompatibilidad: mantener formato antiguo
      if (acompanantes.isNotEmpty && acompanantes.length == 1)
        'acompanante': acompanantes.first.nombre,
      if (acompanantes.isNotEmpty && acompanantes.length == 1)
        'precioAcompanante': acompanantes.first.precioAdicional,
    };
  }

  /// Crea una instancia desde un Map (deserialización)
  factory ProductoSeleccionado.fromMap(Map<String, dynamic> map) {
    // Helper to parse int safely
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper to parse double safely
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final extras = map['extras'];
    final extrasList =
        extras is List
            ? List<String>.from(extras.map((e) => e.toString()))
            : <String>[];

    // Cargar acompañantes (nuevo formato o retrocompatibilidad)
    List<AcompananteSeleccionado> acompanantesList = [];
    if (map.containsKey('acompanantes') && map['acompanantes'] is List) {
      final acompanantesData = map['acompanantes'] as List;
      acompanantesList =
          acompanantesData
              .whereType<Map>()
              .map(
                (a) => AcompananteSeleccionado.fromMap(
                  a.cast<String, dynamic>(),
                ),
              )
              .toList();
    } else if (map.containsKey('acompanante') && map['acompanante'] != null) {
      // Retrocompatibilidad: formato antiguo con un solo acompañante
      acompanantesList = [
        AcompananteSeleccionado(
          nombre: map['acompanante']?.toString() ?? '',
          precioAdicional: parseDouble(map['precioAcompanante']),
          cantidad: parseInt(map['cantidad'], defaultValue: 1),
        ),
      ];
    }

    return ProductoSeleccionado(
      id: map['instanciaId']?.toString(),
      productoId: parseInt(map['id']),
      nombreProducto:
          map['nombre']?.toString() ?? map['nombreCompleto']?.toString() ?? '',
      cantidad: parseInt(map['cantidad'], defaultValue: 1),
      varianteNombre: map['variante']?.toString(),
      precioBase: parseDouble(map['precioBase'] ?? map['precio']),
      acompanantes: acompanantesList,
      extrasNombres: extrasList,
      precioExtras: parseDouble(map['precioExtras']),
    );
  }
}
