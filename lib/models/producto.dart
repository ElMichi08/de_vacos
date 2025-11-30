import 'dart:convert';
import 'producto_variante.dart';
import 'acompanante.dart';
import 'extra.dart';

/// Modelo de Producto que soporta:
/// - Productos simples (precio único)
/// - Variantes de tamaño/precio (ej: Asado 1/2/3 cortes)
/// - Acompañantes opcionales (ej: Papas fritas, cocinadas, mixtas)
/// 
/// Mantiene retrocompatibilidad: productos existentes funcionan igual
class Producto {
  final int? id;
  final String nombre;
  final double precio; // Precio base (se usa si no hay variantes, o como precio mínimo)
  final String imagenPath;
  final bool cancelado; // Soft delete
  
  // Nuevos campos opcionales para productos complejos
  final List<ProductoVariante>? variantes; // null = producto simple, [] = sin variantes, [variantes] = producto con variantes
  final List<Acompanante>? acompanantes; // null o [] = sin acompañantes opcionales (opciones excluyentes)
  final List<Extra>? extras; // null o [] = sin extras opcionales (aditivos, se pueden seleccionar múltiples)

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.imagenPath,
    this.cancelado = false,
    this.variantes,
    this.acompanantes,
    this.extras,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'imagenPath': imagenPath,
      'cancelado': cancelado ? 1 : 0,
      // Campos nuevos: almacenados como JSON para retrocompatibilidad
      if (variantes != null && variantes!.isNotEmpty)
        'variantes': jsonEncode(variantes!.map((v) => v.toMap()).toList()),
      if (acompanantes != null && acompanantes!.isNotEmpty)
        'acompanantes': jsonEncode(acompanantes!.map((a) => a.toMap()).toList()),
      if (extras != null && extras!.isNotEmpty)
        'extras': jsonEncode(extras!.map((e) => e.toMap()).toList()),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    // Parsear variantes (retrocompatibilidad: si no existe, es null)
    List<ProductoVariante>? variantes;
    if (map['variantes'] != null && map['variantes'].toString().trim().isNotEmpty) {
      try {
        final variantesJson = map['variantes'] is String 
            ? jsonDecode(map['variantes'] as String)
            : map['variantes'];
        if (variantesJson is List) {
          variantes = variantesJson
              .map((v) => ProductoVariante.fromMap(v as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        // Si hay error al parsear, mantener como null (producto simple)
        variantes = null;
      }
    }

    // Parsear acompañantes (retrocompatibilidad: si no existe, es null)
    List<Acompanante>? acompanantes;
    if (map['acompanantes'] != null && map['acompanantes'].toString().trim().isNotEmpty) {
      try {
        final acompanantesJson = map['acompanantes'] is String
            ? jsonDecode(map['acompanantes'] as String)
            : map['acompanantes'];
        if (acompanantesJson is List) {
          acompanantes = acompanantesJson
              .map((a) => Acompanante.fromMap(a as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        // Si hay error al parsear, mantener como null
        acompanantes = null;
      }
    }

    // Parsear extras (retrocompatibilidad: si no existe, es null)
    List<Extra>? extras;
    if (map['extras'] != null && map['extras'].toString().trim().isNotEmpty) {
      try {
        final extrasJson = map['extras'] is String
            ? jsonDecode(map['extras'] as String)
            : map['extras'];
        if (extrasJson is List) {
          extras = extrasJson
              .map((e) => Extra.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        // Si hay error al parsear, mantener como null
        extras = null;
      }
    }

    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'] is int ? (map['precio'] as int).toDouble() : map['precio'],
      imagenPath: map['imagenPath'] ?? '',
      cancelado: (map['cancelado'] ?? 0) == 1,
      variantes: variantes,
      acompanantes: acompanantes,
      extras: extras,
    );
  }

  /// Valida los datos del producto
  /// Retorna null si es válido, o un mensaje de error si no lo es
  String? validar() {
    if (nombre.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (precio.isNaN || precio <= 0) {
      return 'El precio debe ser un número positivo';
    }
    if (imagenPath.trim().isEmpty) {
      return 'La imagen es obligatoria';
    }

    // Validar variantes si existen
    if (variantes != null) {
      for (var variante in variantes!) {
        final error = variante.validar();
        if (error != null) {
          return 'Error en variante "${variante.nombre}": $error';
        }
      }
    }

    // Validar acompañantes si existen
    if (acompanantes != null) {
      for (var acompanante in acompanantes!) {
        final error = acompanante.validar();
        if (error != null) {
          return 'Error en acompañante "${acompanante.nombre}": $error';
        }
      }
    }

    // Validar extras si existen
    if (extras != null) {
      for (var extra in extras!) {
        final error = extra.validar();
        if (error != null) {
          return 'Error en extra "${extra.nombre}": $error';
        }
      }
    }

    return null;
  }

  /// Indica si el producto tiene variantes
  bool get tieneVariantes => variantes != null && variantes!.isNotEmpty;

  /// Indica si el producto tiene acompañantes opcionales
  bool get tieneAcompanantes => acompanantes != null && acompanantes!.isNotEmpty;

  /// Indica si el producto tiene extras opcionales
  bool get tieneExtras => extras != null && extras!.isNotEmpty;

  /// Obtiene el precio mínimo (precio base o precio mínimo de variantes)
  double get precioMinimo {
    if (!tieneVariantes) {
      return precio;
    }
    final preciosVariantes = variantes!.map((v) => v.precio).toList();
    return preciosVariantes.reduce((a, b) => a < b ? a : b);
  }

  /// Obtiene el precio máximo (precio base o precio máximo de variantes)
  double get precioMaximo {
    if (!tieneVariantes) {
      return precio;
    }
    final preciosVariantes = variantes!.map((v) => v.precio).toList();
    return preciosVariantes.reduce((a, b) => a > b ? a : b);
  }

  /// Obtiene una representación de rango de precios para mostrar en UI
  /// Ejemplo: "$4.50 - $8.50" o "$4.50"
  String get rangoPrecioTexto {
    if (!tieneVariantes) {
      return '\$${precio.toStringAsFixed(2)}';
    }
    if (precioMinimo == precioMaximo) {
      return '\$${precioMinimo.toStringAsFixed(2)}';
    }
    return '\$${precioMinimo.toStringAsFixed(2)} - \$${precioMaximo.toStringAsFixed(2)}';
  }

  /// Crea una copia del producto con valores modificados
  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    String? imagenPath,
    bool? cancelado,
    List<ProductoVariante>? variantes,
    List<Acompanante>? acompanantes,
    List<Extra>? extras,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      imagenPath: imagenPath ?? this.imagenPath,
      cancelado: cancelado ?? this.cancelado,
      variantes: variantes ?? this.variantes,
      acompanantes: acompanantes ?? this.acompanantes,
      extras: extras ?? this.extras,
    );
  }
}

