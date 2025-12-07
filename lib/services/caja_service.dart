import 'package:flutter/foundation.dart';
import '../core/database/db_helper.dart';
import '../models/caja.dart';

/// Servicio para gestionar movimientos de caja
class CajaService {
  /// Guarda un nuevo movimiento de caja
  /// Si es Caja Chica, verifica que no exista ya una para esa fecha
  static Future<int> guardar(Caja movimiento) async {
    final error = movimiento.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    
    // Si es Caja Chica, verificar que no exista ya una para esa fecha
    if (movimiento.tipo == 'Caja Chica') {
      final fecha = DateTime(movimiento.fecha.year, movimiento.fecha.month, movimiento.fecha.day);
      final existente = await obtenerCajaChicaPorFecha(fecha);
      if (existente != null && existente.id != movimiento.id) {
        throw Exception('Ya existe una Caja Chica para esta fecha. Puedes editarla pero no crear otra.');
      }
    }
    
    try {
      final db = await DBHelper.db;
      
      // Verificar que la columna isSystemGenerated existe antes de insertar
      final tableInfo = await db.rawQuery('PRAGMA table_info(caja_movimientos)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      final tieneColumna = columnNames.contains('isSystemGenerated');
      
      // Si la columna no existe, intentar agregarla
      bool columnaAgregada = false;
      if (!tieneColumna) {
        try {
          await db.execute('ALTER TABLE caja_movimientos ADD COLUMN isSystemGenerated INTEGER DEFAULT 0');
          debugPrint('Columna isSystemGenerated agregada a caja_movimientos');
          columnaAgregada = true;
        } catch (e) {
          debugPrint('Error al agregar columna isSystemGenerated: $e');
        }
      }
      
      // Crear un mapa solo con las columnas que existen (o que acabamos de agregar)
      final mapToInsert = <String, dynamic>{
        'descripcion': movimiento.descripcion,
        'tipo': movimiento.tipo,
        'valor': movimiento.valor,
        'fecha': movimiento.fecha.toIso8601String(),
      };
      
      // Solo incluir isSystemGenerated si la columna existe o fue agregada
      if (tieneColumna || columnaAgregada) {
        mapToInsert['isSystemGenerated'] = movimiento.isSystemGenerated ? 1 : 0;
      }
      
      return await db.insert('caja_movimientos', mapToInsert);
    } catch (e) {
      throw Exception('Error al guardar movimiento de caja: $e');
    }
  }

  /// Obtiene todos los movimientos de una fecha específica o rango
  static Future<List<Caja>> obtenerPorFecha(DateTime fecha, {DateTime? fechaFin}) async {
    try {
      final db = await DBHelper.db;
      final inicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fin = fechaFin != null
          ? DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59, 999)
          : DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);

      final maps = await db.query(
        'caja_movimientos',
        where: 'fecha BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
        orderBy: 'fecha DESC',
      );

      return maps.map((map) => Caja.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos de caja: $e');
    }
  }

  /// Verifica si ya existe una caja chica para una fecha específica
  static Future<Caja?> obtenerCajaChicaPorFecha(DateTime fecha) async {
    try {
      final db = await DBHelper.db;
      final inicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);

      final maps = await db.query(
        'caja_movimientos',
        where: 'tipo = ? AND fecha BETWEEN ? AND ?',
        whereArgs: ['Caja Chica', inicio.toIso8601String(), fin.toIso8601String()],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return Caja.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error al verificar caja chica: $e');
    }
  }

  /// Obtiene todos los movimientos
  static Future<List<Caja>> obtenerTodos() async {
    try {
      final db = await DBHelper.db;
      final maps = await db.query(
        'caja_movimientos',
        orderBy: 'fecha DESC',
      );
      return maps.map((map) => Caja.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos de caja: $e');
    }
  }

  /// Actualiza un movimiento de caja
  static Future<int> actualizar(Caja movimiento) async {
    if (movimiento.id == null) {
      throw Exception('El movimiento debe tener un ID para actualizar');
    }
    
    final error = movimiento.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    
    try {
      final db = await DBHelper.db;
      
      // Verificar que la columna isSystemGenerated existe antes de actualizar
      final tableInfo = await db.rawQuery('PRAGMA table_info(caja_movimientos)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      final tieneColumna = columnNames.contains('isSystemGenerated');
      
      // Crear un mapa solo con las columnas que existen
      final mapToUpdate = <String, dynamic>{
        'descripcion': movimiento.descripcion,
        'tipo': movimiento.tipo,
        'valor': movimiento.valor,
        'fecha': movimiento.fecha.toIso8601String(),
      };
      
      // Solo incluir isSystemGenerated si la columna existe
      if (tieneColumna) {
        mapToUpdate['isSystemGenerated'] = movimiento.isSystemGenerated ? 1 : 0;
      }
      
      return await db.update(
        'caja_movimientos',
        mapToUpdate,
        where: 'id = ?',
        whereArgs: [movimiento.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar movimiento de caja: $e');
    }
  }

  /// Elimina un movimiento por su ID
  static Future<int> eliminar(int id) async {
    try {
      final db = await DBHelper.db;
      return await db.delete(
        'caja_movimientos',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar movimiento de caja: $e');
    }
  }

  /// Elimina todos los movimientos de una fecha
  static Future<void> eliminarPorFecha(DateTime fecha) async {
    try {
      final db = await DBHelper.db;
      final inicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);

      await db.delete(
        'caja_movimientos',
        where: 'fecha BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      );
    } catch (e) {
      throw Exception('Error al eliminar movimientos de caja: $e');
    }
  }
}

