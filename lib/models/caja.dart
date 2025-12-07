class Caja {
  final int? id;
  final String descripcion;
  final String tipo; // 'Ingreso', 'Egreso', 'Caja Chica'
  final double valor;
  final DateTime fecha;
  final bool isSystemGenerated; // true si es generado automáticamente por el sistema

  Caja({
    this.id,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    required this.fecha,
    this.isSystemGenerated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'tipo': tipo,
      'valor': valor,
      'fecha': fecha.toIso8601String(),
      'isSystemGenerated': isSystemGenerated ? 1 : 0,
    };
  }

  factory Caja.fromMap(Map<String, dynamic> map) {
    return Caja(
      id: map['id'],
      descripcion: map['descripcion'],
      tipo: map['tipo'],
      valor: map['valor'] is int ? (map['valor'] as int).toDouble() : map['valor'],
      fecha: DateTime.parse(map['fecha']),
      isSystemGenerated: (map['isSystemGenerated'] ?? 0) == 1,
    );
  }

  String? validar() {
    if (descripcion.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (!['Ingreso', 'Egreso', 'Caja Chica'].contains(tipo)) {
      return 'El tipo debe ser Ingreso, Egreso o Caja Chica';
    }
    if (valor.isNaN || valor <= 0) {
      return 'El valor debe ser un número positivo';
    }
    return null;
  }
}

