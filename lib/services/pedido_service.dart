import '../core/database/db_helper.dart';
import '../models/pedido.dart';

/// Servicio para gestionar pedidos
class PedidoService {
  /// Obtiene todos los pedidos del día actual (no cancelados) ordenados por fecha
  /// Ordena por fecha DESC y luego por id DESC para garantizar un orden estable
  /// cuando hay múltiples pedidos con el mismo número de orden
  static Future<List<Pedido>> obtenerTodos({DateTime? fechaInicio, DateTime? fechaFin}) async {
    try {
      final db = await DBHelper.db;
      
      DateTime inicio, fin;
      if (fechaInicio != null && fechaFin != null) {
        inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999);
      } else {
        // Por defecto, día actual
        final hoy = DateTime.now();
        inicio = DateTime(hoy.year, hoy.month, hoy.day);
        fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
      }
      
      final maps = await db.query(
        'pedidos',
        where: 'fecha BETWEEN ? AND ? AND cancelado = 0',
        whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
        orderBy: 'fecha DESC, id DESC',
      );
      return maps.map((map) => Pedido.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtiene pedidos paginados
  /// Retorna una lista de pedidos con paginación y el total de pedidos disponibles
  static Future<Map<String, dynamic>> obtenerTodosPaginados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int pagina = 1,
    int tamanoPagina = 20,
  }) async {
    try {
      final db = await DBHelper.db;
      
      DateTime inicio, fin;
      if (fechaInicio != null && fechaFin != null) {
        inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999);
      } else {
        final hoy = DateTime.now();
        inicio = DateTime(hoy.year, hoy.month, hoy.day);
        fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
      }

      // Obtener el total de pedidos
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM pedidos 
        WHERE fecha BETWEEN ? AND ? AND cancelado = 0
      ''', [inicio.toIso8601String(), fin.toIso8601String()]);
      
      final total = countResult.first['total'] as int? ?? 0;

      // Calcular offset
      final offset = (pagina - 1) * tamanoPagina;

      // Obtener pedidos paginados
      final maps = await db.query(
        'pedidos',
        where: 'fecha BETWEEN ? AND ? AND cancelado = 0',
        whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
        orderBy: 'fecha DESC, id DESC',
        limit: tamanoPagina,
        offset: offset,
      );

      final pedidos = maps.map((map) => Pedido.fromMap(map)).toList();
      
      return {
        'pedidos': pedidos,
        'total': total,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'totalPaginas': (total / tamanoPagina).ceil(),
      };
    } catch (e) {
      throw Exception('Error al obtener pedidos paginados: $e');
    }
  }

  /// Obtiene pedidos paginados por estado
  static Future<Map<String, dynamic>> obtenerPorEstadoPaginados(
    String estado, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int pagina = 1,
    int tamanoPagina = 20,
  }) async {
    try {
      final db = await DBHelper.db;
      
      DateTime inicio, fin;
      if (fechaInicio != null && fechaFin != null) {
        inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999);
      } else {
        final hoy = DateTime.now();
        inicio = DateTime(hoy.year, hoy.month, hoy.day);
        fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
      }

      // Determinar la cláusula WHERE
      String whereClause;
      List<dynamic> whereArgs;
      if (estado == 'Canceladas') {
        whereClause = 'cancelado = 1 AND fecha BETWEEN ? AND ?';
        whereArgs = [inicio.toIso8601String(), fin.toIso8601String()];
      } else {
        whereClause = 'estado = ? AND fecha BETWEEN ? AND ? AND cancelado = 0';
        whereArgs = [estado, inicio.toIso8601String(), fin.toIso8601String()];
      }

      // Obtener el total de pedidos
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM pedidos 
        WHERE $whereClause
      ''', whereArgs);
      
      final total = countResult.first['total'] as int? ?? 0;

      // Calcular offset
      final offset = (pagina - 1) * tamanoPagina;

      // Obtener pedidos paginados
      final maps = await db.query(
        'pedidos',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'fecha DESC, id DESC',
        limit: tamanoPagina,
        offset: offset,
      );

      final pedidos = maps.map((map) => Pedido.fromMap(map)).toList();
      
      return {
        'pedidos': pedidos,
        'total': total,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'totalPaginas': (total / tamanoPagina).ceil(),
      };
    } catch (e) {
      throw Exception('Error al obtener pedidos por estado paginados: $e');
    }
  }

  /// Obtiene pedidos por estado y fecha
  static Future<List<Pedido>> obtenerPorEstado(String estado, {DateTime? fechaInicio, DateTime? fechaFin}) async {
    try {
      final db = await DBHelper.db;
      
      DateTime inicio, fin;
      if (fechaInicio != null && fechaFin != null) {
        inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999);
      } else {
        final hoy = DateTime.now();
        inicio = DateTime(hoy.year, hoy.month, hoy.day);
        fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
      }
      
      // Si el estado es "Canceladas", mostrar solo los cancelados
      String whereClause;
      List<dynamic> whereArgs;
      if (estado == 'Canceladas') {
        whereClause = 'cancelado = 1 AND fecha BETWEEN ? AND ?';
        whereArgs = [inicio.toIso8601String(), fin.toIso8601String()];
      } else {
        whereClause = 'estado = ? AND fecha BETWEEN ? AND ? AND cancelado = 0';
        whereArgs = [estado, inicio.toIso8601String(), fin.toIso8601String()];
      }
      
      final maps = await db.query(
        'pedidos',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'fecha DESC, id DESC',
      );
      return maps.map((map) => Pedido.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos por estado: $e');
    }
  }

  /// Obtiene un pedido por su ID
  static Future<Pedido?> obtenerPorId(int id) async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'pedidos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Pedido.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error al obtener pedido: $e');
    }
  }

  /// Guarda un nuevo pedido (automáticamente en estado "En preparación")
  static Future<int> guardar(Pedido pedido) async {
    // Obtener siguiente número de orden
    final numeroOrden = await DBHelper.obtenerSiguienteNumeroOrden();
    
    // Crear pedido con número de orden y estado "En preparación"
    final pedidoConOrden = Pedido(
      numeroOrden: numeroOrden,
      cliente: pedido.cliente,
      celular: pedido.celular,
      metodoPago: pedido.metodoPago,
      estado: 'En preparación', // Automáticamente en preparación
      estadoPago: pedido.estadoPago,
      productos: pedido.productos,
      fecha: pedido.fecha,
      total: pedido.total,
      envasesLlevar: pedido.envasesLlevar,
      notas: pedido.notas,
      cancelado: false,
    );
    
    return await DBHelper.insertarPedido(pedidoConOrden);
  }

  /// Actualiza un pedido existente
  static Future<int> actualizar(Pedido pedido) async {
    if (pedido.id == null) {
      throw Exception('El pedido debe tener un ID para actualizar');
    }
    
    final error = pedido.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    
    try {
      final db = await DBHelper.db;
      
      // Asegurar que la columna fotoTransferenciaPath existe antes de actualizar
      final tableInfo = await db.rawQuery('PRAGMA table_info(pedidos)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      if (!columnNames.contains('fotoTransferenciaPath')) {
        await db.execute('ALTER TABLE pedidos ADD COLUMN fotoTransferenciaPath TEXT DEFAULT NULL');
      }
      
      return await db.update(
        'pedidos',
        pedido.toMap(),
        where: 'id = ?',
        whereArgs: [pedido.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar pedido: $e');
    }
  }

  /// Actualiza el estado de un pedido
  static Future<int> actualizarEstado(int id, String nuevoEstado) async {
    try {
      final db = await DBHelper.db;
      return await db.update(
        'pedidos',
        {'estado': nuevoEstado},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al actualizar estado del pedido: $e');
    }
  }

  /// Actualiza el estado de pago de un pedido
  /// Opcionalmente puede actualizar la ruta de la foto de transferencia
  static Future<int> actualizarEstadoPago(int id, String nuevoEstadoPago, {String? fotoTransferenciaPath}) async {
    try {
      final db = await DBHelper.db;
      final updateData = <String, dynamic>{'estadoPago': nuevoEstadoPago};
      if (fotoTransferenciaPath != null) {
        updateData['fotoTransferenciaPath'] = fotoTransferenciaPath;
      }
      return await db.update(
        'pedidos',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al actualizar estado de pago: $e');
    }
  }

  /// Cancela un pedido (soft delete)
  static Future<int> cancelar(int id) async {
    try {
      final db = await DBHelper.db;
      return await db.update(
        'pedidos',
        {'cancelado': 1, 'estado': 'Cancelada'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al cancelar pedido: $e');
    }
  }

  /// Elimina todos los pedidos del día actual
  /// Útil para limpiar datos de prueba generados con el factory
  static Future<int> eliminarPedidosDelDiaActual() async {
    try {
      final db = await DBHelper.db;
      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      return await db.delete(
        'pedidos',
        where: 'fecha BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      );
    } catch (e) {
      throw Exception('Error al eliminar pedidos del día actual: $e');
    }
  }
}

