import 'package:de_vacos/models/pedido.dart';
import 'package:de_vacos/repositories/i_pedido_repository.dart';
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PedidoRepository implements IPedidoRepository {
  @override
  Future<Pedido> crearPedido(Pedido pedido) async {
    final db = await DBHelper.db;
    return await db.transaction((txn) async {
      final numeroOrden = await DBHelper.obtenerSiguienteNumeroOrden(txn: txn);
      final pedidoConOrden = Pedido(
        numeroOrden: numeroOrden,
        cliente: pedido.cliente,
        celular: pedido.celular,
        metodoPago: pedido.metodoPago,
        estado: 'En preparación',
        estadoPago: pedido.estadoPago,
        productos: pedido.productos,
        fecha: pedido.fecha,
        total: pedido.total,
        envasesLlevar: pedido.envasesLlevar,
        notas: pedido.notas,
        cancelado: false,
        fotoTransferenciaPath: pedido.fotoTransferenciaPath,
      );
      final id = await DBHelper.insertarPedido(pedidoConOrden, txn: txn);
      return Pedido(
        id: id,
        numeroOrden: numeroOrden,
        cliente: pedido.cliente,
        celular: pedido.celular,
        metodoPago: pedido.metodoPago,
        estado: 'En preparación',
        estadoPago: pedido.estadoPago,
        productos: pedido.productos,
        fecha: pedido.fecha,
        total: pedido.total,
        envasesLlevar: pedido.envasesLlevar,
        notas: pedido.notas,
        cancelado: false,
        fotoTransferenciaPath: pedido.fotoTransferenciaPath,
      );
    }, exclusive: true);
  }

  @override
  Future<Pedido?> obtenerPedidoPorId(int id) async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'pedidos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Pedido.fromMap(maps.first);
  }

  @override
  Future<List<Pedido>> obtenerTodosLosPedidos() async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'pedidos',
      where: 'cancelado = 0',
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => Pedido.fromMap(m)).toList();
  }

  @override
  Future<List<Pedido>> obtenerPorFecha(
    DateTime fechaInicio, {
    DateTime? fechaFin,
    bool incluirCancelados = false,
  }) async {
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    final fin =
        (fechaFin != null)
            ? DateTime(
              fechaFin.year,
              fechaFin.month,
              fechaFin.day,
              23,
              59,
              59,
              999,
            )
            : DateTime(
              fechaInicio.year,
              fechaInicio.month,
              fechaInicio.day,
              23,
              59,
              59,
              999,
            );

    final db = await DBHelper.db;
    final whereClause =
        incluirCancelados
            ? 'fecha BETWEEN ? AND ?'
            : 'fecha BETWEEN ? AND ? AND cancelado = 0';
    final maps = await db.query(
      'pedidos',
      where: whereClause,
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((map) => Pedido.fromMap(map)).toList();
  }

  @override
  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    final db = await DBHelper.db;
    await db.update(
      'pedidos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> actualizarPedido(Pedido pedido) async {
    if (pedido.id == null) {
      throw Exception('El pedido debe tener un ID para actualizar');
    }
    final error = pedido.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    final db = await DBHelper.db;

    await DBHelper.addColumnIfNotExists(
      db,
      'pedidos',
      'fotoTransferenciaPath',
      'TEXT',
      defaultValue: 'NULL',
    );

    await db.update(
      'pedidos',
      pedido.toMap(),
      where: 'id = ?',
      whereArgs: [pedido.id],
    );
  }

  @override
  Future<void> eliminarPedido(int id) async {
    final db = await DBHelper.db;
    await db.update(
      'pedidos',
      {'cancelado': 1, 'estado': 'Cancelada'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> actualizarEstadoPago(
    int pedidoId,
    String estadoPago, {
    String? fotoTransferenciaPath,
  }) async {
    final db = await DBHelper.db;
    final updateData = <String, dynamic>{'estadoPago': estadoPago};
    if (fotoTransferenciaPath != null) {
      updateData['fotoTransferenciaPath'] = fotoTransferenciaPath;
    }
    final rows = await db.update(
      'pedidos',
      updateData,
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
    return rows;
  }

  @override
  Future<int> eliminarPedidosDelDiaActual() async {
    final db = await DBHelper.db;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
    return await db.delete(
      'pedidos',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
    );
  }
}
