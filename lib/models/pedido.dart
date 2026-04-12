import 'dart:convert';
import 'enums.dart';

/// Representa un pago individual aplicado a un pedido.
/// Un pedido puede tener hasta 3 pagos: 1 inicial + 2 recobros.
class Pago {
  final PaymentMethod metodo;
  final double monto;
  final String? foto;

  const Pago({required this.metodo, required this.monto, this.foto});

  Map<String, dynamic> toMap() => {
    'metodo': metodo.displayName,
    'monto': monto,
    'foto': foto,
  };

  static Pago fromMap(Map<String, dynamic> m) => Pago(
    metodo: PaymentMethod.fromString(m['metodo'] as String),
    monto: (m['monto'] as num).toDouble(),
    foto: m['foto'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is Pago &&
      other.metodo == metodo &&
      other.monto == monto &&
      other.foto == foto;

  @override
  int get hashCode => Object.hash(metodo, monto, foto);
}

class Pedido {
  final int? id;
  final int numeroOrden;
  final String cliente;
  final String celular;
  final PaymentMethod metodoPago;
  final OrderStatus estado;
  final PaymentStatus estadoPago;
  final List<Map<String, dynamic>> productos;
  final DateTime fecha;
  final double total;
  final int envasesLlevar;
  final String notas;
  final bool cancelado; // Soft delete
  final String? fotoTransferenciaPath; // Ruta de la foto de transferencia
  // Snapshot de productos al momento del cobro. null = nunca cobrado.
  final List<Map<String, dynamic>>? productosCobrados;
  // Historial de pagos: 1 inicial + máx 2 recobros = 3 entradas máx.
  final List<Pago>? pagos;

  Pedido({
    this.id,
    required this.numeroOrden,
    required this.cliente,
    required this.celular,
    required this.metodoPago,
    required this.estado,
    this.estadoPago = PaymentStatus.pendiente,
    required this.productos,
    required this.fecha,
    required this.total,
    this.envasesLlevar = 0,
    this.notas = '',
    this.cancelado = false,
    this.fotoTransferenciaPath,
    this.productosCobrados,
    this.pagos,
  });

  /// Suma de montos ya cobrados en todos los pagos registrados.
  double get totalYaCobrado =>
      pagos?.fold<double>(0.0, (s, p) => s + p.monto) ?? 0.0;

  /// Diferencia pendiente de cobro.
  double get diferencia => (total - totalYaCobrado).clamp(0.0, double.infinity);

  /// True si aún puede recibir más recobros (máx 2, es decir 3 pagos en total).
  bool get puedeRecobrar => (pagos?.length ?? 0) < 3;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroOrden': numeroOrden,
      'cliente': cliente,
      'celular': celular,
      'metodoPago': metodoPago.displayName,
      'estado': estado.displayName,
      'estadoPago': estadoPago.displayName,
      'productos': jsonEncode(productos),
      'fecha': fecha.toIso8601String(),
      'total': total,
      'envasesLlevar': envasesLlevar,
      'notas': notas,
      'cancelado': cancelado ? 1 : 0,
      'fotoTransferenciaPath': fotoTransferenciaPath,
      if (productosCobrados != null)
        'productosCobrados': jsonEncode(productosCobrados),
      if (pagos != null)
        'pagos': jsonEncode(pagos!.map((p) => p.toMap()).toList()),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'],
      numeroOrden: map['numeroOrden'] ?? 0,
      cliente: map['cliente'],
      celular: map['celular'],
      metodoPago: PaymentMethod.fromString(map['metodoPago']),
      estado: OrderStatus.fromString(map['estado']),
      estadoPago: PaymentStatus.fromString(map['estadoPago'] ?? 'Pendiente'),
      productos: _parseProductos(map['productos']),
      fecha: DateTime.parse(map['fecha']),
      total:
          map['total'] is int ? (map['total'] as int).toDouble() : map['total'],
      envasesLlevar: map['envasesLlevar'] ?? 0,
      notas: map['notas'] ?? '',
      cancelado: (map['cancelado'] ?? 0) == 1,
      fotoTransferenciaPath: map['fotoTransferenciaPath'],
      productosCobrados: map['productosCobrados'] != null
          ? _parseProductos(map['productosCobrados'])
          : null,
      pagos: _parsePagos(map['pagos']),
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

  static List<Pago>? _parsePagos(dynamic valor) {
    if (valor == null) return null;
    if (valor is String) {
      try {
        final decoded = jsonDecode(valor);
        if (decoded is List) {
          return decoded
              .map((e) => Pago.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }
    return null;
  }

  String? validar() {
    if (cliente.trim().isEmpty) {
      return 'El nombre del cliente es obligatorio';
    }
    // Celular es opcional, no se valida
    // metodoPago y estado son enums, siempre tienen valor
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
