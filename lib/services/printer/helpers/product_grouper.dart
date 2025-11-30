import 'producto_ticket_helper.dart';

/// Clase responsable de agrupar productos iguales para el ticket
/// Implementa la lógica de agrupación considerando nombre, variante, precio,
/// acompañantes y extras para generar una clave única correcta
class ProductGrouper {
  /// Agrupa productos basándose en su configuración completa
  /// Retorna un mapa donde la clave es única y el valor es el producto agrupado
  static Map<String, Map<String, dynamic>> agruparProductos(
    List<Map<String, dynamic>> productos,
  ) {
    final productosAgrupados = <String, Map<String, dynamic>>{};

    for (final producto in productos) {
      final clave = _generarClave(producto);

      if (productosAgrupados.containsKey(clave)) {
        _incrementarCantidad(productosAgrupados[clave]!, producto);
      } else {
        productosAgrupados[clave] = Map<String, dynamic>.from(producto);
      }
    }

    return productosAgrupados;
  }

  /// Genera una clave única para un producto basándose en:
  /// - Nombre
  /// - Variante
  /// - Precio (IMPORTANTE: incluye precio para evitar agrupar productos diferentes)
  /// - Acompañantes (ordenados y con cantidades)
  /// - Extras (ordenados)
  static String _generarClave(Map<String, dynamic> producto) {
    final nombre = ProductoTicketHelper.getNombre(producto);
    final variante = ProductoTicketHelper.getVariante(producto) ?? '';
    final precio = ProductoTicketHelper.getPrecio(producto);
    final acompanantesKey = _generarAcompanantesKey(producto);
    final extrasKey = _generarExtrasKey(producto);

    // Incluir precio en la clave para evitar agrupar productos con precios diferentes
    return '${nombre}_${variante}_${precio.toStringAsFixed(2)}_${acompanantesKey}_$extrasKey';
  }

  /// Genera una clave para los acompañantes considerando nombre y cantidad
  /// Los acompañantes se ordenan para garantizar consistencia
  static String _generarAcompanantesKey(Map<String, dynamic> producto) {
    final acompanantes = ProductoTicketHelper.getAcompanantes(producto);
    if (acompanantes.isEmpty) {
      return '';
    }

    // Ordenar acompañantes por nombre para garantizar consistencia
    acompanantes.sort((a, b) {
      final nombreA = a['nombre'] as String? ?? '';
      final nombreB = b['nombre'] as String? ?? '';
      return nombreA.compareTo(nombreB);
    });

    return acompanantes
        .map((a) {
          final nombre = a['nombre'] as String? ?? '';
          final cantidad = a['cantidad'] as int? ?? 1;
          return '$nombre:$cantidad';
        })
        .join(',');
  }

  /// Genera una clave para los extras
  /// Los extras se ordenan para garantizar consistencia
  static String _generarExtrasKey(Map<String, dynamic> producto) {
    final extras = ProductoTicketHelper.getExtras(producto);
    if (extras.isEmpty) {
      return '';
    }

    // Ordenar extras para garantizar consistencia
    final extrasOrdenados = List<String>.from(extras)..sort();
    return extrasOrdenados.join(',');
  }

  /// Incrementa la cantidad de un producto agrupado
  static void _incrementarCantidad(
    Map<String, dynamic> productoAgrupado,
    Map<String, dynamic> productoNuevo,
  ) {
    final cantidadActual = ProductoTicketHelper.getCantidad(productoAgrupado);
    final cantidadNueva = ProductoTicketHelper.getCantidad(productoNuevo);
    productoAgrupado['cantidad'] = cantidadActual + cantidadNueva;
  }

  /// Calcula la suma total de todos los productos agrupados
  /// Incluye precio * cantidad para cada producto
  static double calcularSumaTotal(
    Map<String, Map<String, dynamic>> productosAgrupados,
  ) {
    double suma = 0.0;
    for (final producto in productosAgrupados.values) {
      suma += ProductoTicketHelper.calcularPrecioTotal(producto);
    }
    return suma;
  }
}

