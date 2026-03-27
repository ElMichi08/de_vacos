import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/caja.dart';
import 'package:de_vacos/repositories/i_caja_repository.dart';

class CajaRepository implements ICajaRepository {
  @override
  Future<Caja> abrirCaja(Caja caja) async {
    final db = await DBHelper.db;
    final id = await db.insert('caja_movimientos', caja.toMap());
    return Caja(
      id: id,
      descripcion: caja.descripcion,
      tipo: caja.tipo,
      valor: caja.valor,
      fecha: caja.fecha,
      isSystemGenerated: caja.isSystemGenerated,
    );
  }

  @override
  Future<Caja?> obtenerCajaActiva() async {
    final db = await DBHelper.db;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

    final maps = await db.query(
      'caja_movimientos',
      where: 'tipo = ? AND fecha BETWEEN ? AND ?',
      whereArgs: [
        'Caja Chica',
        inicio.toIso8601String(),
        fin.toIso8601String(),
      ],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Caja.fromMap(maps.first);
  }

  @override
  Future<List<Caja>> obtenerPorFecha(
    DateTime fechaInicio, {
    DateTime? fechaFin,
  }) async {
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    final fin =
        fechaFin != null
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
    final maps = await db.query(
      'caja_movimientos',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Caja.fromMap(m)).toList();
  }

  @override
  Future<void> registrarMovimiento(Caja movimiento) async {
    final db = await DBHelper.db;
    final tieneColumna = await DBHelper.columnExists(
      db,
      'caja_movimientos',
      'isSystemGenerated',
    );

    final mapToInsert = <String, dynamic>{
      'descripcion': movimiento.descripcion,
      'tipo': movimiento.tipo,
      'valor': movimiento.valor,
      'fecha': movimiento.fecha.toIso8601String(),
    };

    if (tieneColumna) {
      mapToInsert['isSystemGenerated'] = movimiento.isSystemGenerated ? 1 : 0;
    }

    await db.insert('caja_movimientos', mapToInsert);
  }

  @override
  Future<double> obtenerSaldoActual() async {
    final movimientos = await obtenerPorFecha(DateTime.now());
    double total = 0.0;
    for (final m in movimientos) {
      total += m.valor;
    }
    return total;
  }

  @override
  Future<int> guardar(Caja caja) async {
    final error = caja.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    final db = await DBHelper.db;

    await DBHelper.addColumnIfNotExists(
      db,
      'caja_movimientos',
      'isSystemGenerated',
      'INTEGER',
      defaultValue: '0',
    );

    final mapToInsert = <String, dynamic>{
      'descripcion': caja.descripcion,
      'tipo': caja.tipo,
      'valor': caja.valor,
      'fecha': caja.fecha.toIso8601String(),
      'isSystemGenerated': caja.isSystemGenerated ? 1 : 0,
    };

    return await db.insert('caja_movimientos', mapToInsert);
  }

  @override
  Future<Caja?> obtenerCajaChicaPorFecha(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
    final db = await DBHelper.db;
    final maps = await db.query(
      'caja_movimientos',
      where: 'tipo = ? AND fecha BETWEEN ? AND ?',
      whereArgs: [
        'Caja Chica',
        inicio.toIso8601String(),
        fin.toIso8601String(),
      ],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Caja.fromMap(maps.first);
  }

  @override
  Future<int> actualizar(Caja caja) async {
    if (caja.id == null) {
      throw Exception('El movimiento debe tener un ID para actualizar');
    }
    final error = caja.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    final db = await DBHelper.db;
    final tieneColumna = await DBHelper.columnExists(
      db,
      'caja_movimientos',
      'isSystemGenerated',
    );

    final mapToUpdate = <String, dynamic>{
      'descripcion': caja.descripcion,
      'tipo': caja.tipo,
      'valor': caja.valor,
      'fecha': caja.fecha.toIso8601String(),
    };

    if (tieneColumna) {
      mapToUpdate['isSystemGenerated'] = caja.isSystemGenerated ? 1 : 0;
    }

    return await db.update(
      'caja_movimientos',
      mapToUpdate,
      where: 'id = ?',
      whereArgs: [caja.id],
    );
  }

  @override
  Future<int> eliminar(int id) async {
    final db = await DBHelper.db;
    return await db.delete(
      'caja_movimientos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> eliminarPorFecha(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
    final db = await DBHelper.db;
    await db.delete(
      'caja_movimientos',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
    );
  }
}
