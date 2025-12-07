import 'dart:convert';

class Pedido {
  final int? id;
  final int numeroOrden;
  final String cliente;
  final String celular;
  final String metodoPago;
  final String estado;
  final String estadoPago; // 'Pendiente' o 'Cobrado'
  final List<Map<String, dynamic>> productos;
  final DateTime fecha;
  final double total;
  final int envasesLlevar;
  final String notas;
  final bool cancelado; // Soft delete
  final String? fotoTransferenciaPath; // Ruta de la foto de transferencia

  Pedido({
    this.id,
    required this.numeroOrden,
    required this.cliente,
    required this.celular,
    required this.metodoPago,
    required this.estado,
    this.estadoPago = 'Pendiente',
    required this.productos,
    required this.fecha,
    required this.total,
    this.envasesLlevar = 0,
    this.notas = '',
    this.cancelado = false,
    this.fotoTransferenciaPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroOrden': numeroOrden,
      'cliente': cliente,
      'celular': celular,
      'metodoPago': metodoPago,
      'estado': estado,
      'estadoPago': estadoPago,
      'productos': jsonEncode(productos),
      'fecha': fecha.toIso8601String(),
      'total': total,
      'envasesLlevar': envasesLlevar,
      'notas': notas,
      'cancelado': cancelado ? 1 : 0,
      'fotoTransferenciaPath': fotoTransferenciaPath,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'],
      numeroOrden: map['numeroOrden'] ?? 0,
      cliente: map['cliente'],
      celular: map['celular'],
      metodoPago: map['metodoPago'],
      estado: map['estado'],
      estadoPago: map['estadoPago'] ?? 'Pendiente',
      productos: _parseProductos(map['productos']),
      fecha: DateTime.parse(map['fecha']),
      total: map['total'] is int ? (map['total'] as int).toDouble() : map['total'],
      envasesLlevar: map['envasesLlevar'] ?? 0,
      notas: map['notas'] ?? '',
      cancelado: (map['cancelado'] ?? 0) == 1,
      fotoTransferenciaPath: map['fotoTransferenciaPath'],
    );
  }

  static List<Map<String, dynamic>> _parseProductos(dynamic valor) {
    if (valor is String) {
      try {
        final decoded = jsonDecode(valor);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  String? validar() {
    if (cliente.trim().isEmpty) {
      return 'El nombre del cliente es obligatorio';
    }
    // Celular es opcional, no se valida
    if (metodoPago.trim().isEmpty) {
      return 'El método de pago es obligatorio';
    }
    if (estado.trim().isEmpty) {
      return 'El estado es obligatorio';
    }
    if (productos.isEmpty) {
      return 'Debes seleccionar al menos un producto';
    }
    if (total.isNaN || total <= 0) {
      return 'El total debe ser mayor a 0';
    }
    if (envasesLlevar < 0) {
      return 'El número de envases a llevar no puede ser negativo';
    }
    return null;
  }
}

