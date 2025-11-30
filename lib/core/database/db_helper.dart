import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import '../../models/producto.dart';
import '../../models/pedido.dart';

class DBHelper {
  static Database? _db;
  static const int _versionDb = 4; // Incrementado para soportar soft delete en productos
  static bool _initialized = false;

  /// Inicializa el databaseFactory para plataformas de escritorio
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Verificar si estamos en una plataforma de escritorio
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Inicializar sqflite_common_ffi para escritorio
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _initialized = true;
  }

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path;
    
    // Obtener la ruta de la base de datos según la plataforma
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Para escritorio, usar el directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      path = path_utils.join(directory.path, 'vacos.db');
    } else {
      // Para móvil, usar getDatabasesPath()
      path = path_utils.join(await getDatabasesPath(), 'vacos.db');
    }
    
    return await openDatabase(
      path,
      version: _versionDb,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Verificar y agregar columnas faltantes al abrir la base de datos
        try {
          // Verificar columnas de pedidos
          final pedidosTableInfo = await db.rawQuery('PRAGMA table_info(pedidos)');
          final pedidosColumnNames = pedidosTableInfo.map((row) => row['name'] as String).toList();
          
          if (!pedidosColumnNames.contains('numeroOrden')) {
            await db.execute('ALTER TABLE pedidos ADD COLUMN numeroOrden INTEGER DEFAULT 0');
            await db.execute('UPDATE pedidos SET numeroOrden = id WHERE numeroOrden = 0 OR numeroOrden IS NULL');
          }
          if (!pedidosColumnNames.contains('estadoPago')) {
            await db.execute('ALTER TABLE pedidos ADD COLUMN estadoPago TEXT DEFAULT \'Pendiente\'');
            await db.execute('UPDATE pedidos SET estadoPago = \'Pendiente\' WHERE estadoPago IS NULL');
          }
          if (!pedidosColumnNames.contains('cancelado')) {
            await db.execute('ALTER TABLE pedidos ADD COLUMN cancelado INTEGER DEFAULT 0');
            await db.execute('UPDATE pedidos SET cancelado = 0 WHERE cancelado IS NULL');
          }

          // Verificar columnas de productos (variantes y acompañantes)
          final productosTableInfo = await db.rawQuery('PRAGMA table_info(productos)');
          final productosColumnNames = productosTableInfo.map((row) => row['name'] as String).toList();
          
          if (!productosColumnNames.contains('variantes')) {
            await db.execute('ALTER TABLE productos ADD COLUMN variantes TEXT DEFAULT NULL');
          }
          if (!productosColumnNames.contains('acompanantes')) {
            await db.execute('ALTER TABLE productos ADD COLUMN acompanantes TEXT DEFAULT NULL');
          }
          if (!productosColumnNames.contains('extras')) {
            await db.execute('ALTER TABLE productos ADD COLUMN extras TEXT DEFAULT NULL');
          }
          if (!productosColumnNames.contains('cancelado')) {
            await db.execute('ALTER TABLE productos ADD COLUMN cancelado INTEGER DEFAULT 0');
            await db.execute('UPDATE productos SET cancelado = 0 WHERE cancelado IS NULL');
          }
        } catch (e) {
          debugPrint('Error al verificar columnas: $e');
        }
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabla productos
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        imagenPath TEXT NOT NULL,
        variantes TEXT DEFAULT NULL,
        acompanantes TEXT DEFAULT NULL,
        extras TEXT DEFAULT NULL,
        cancelado INTEGER DEFAULT 0
      )
    ''');

    // Tabla pedidos
    await db.execute('''
      CREATE TABLE pedidos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numeroOrden INTEGER NOT NULL,
        cliente TEXT NOT NULL,
        celular TEXT NOT NULL,
        metodoPago TEXT NOT NULL,
        estado TEXT NOT NULL,
        estadoPago TEXT NOT NULL DEFAULT 'Pendiente',
        productos TEXT NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        envasesLlevar INTEGER DEFAULT 0,
        notas TEXT DEFAULT '',
        cancelado INTEGER DEFAULT 0
      )
    ''');

    // Tabla caja_movimientos
    await db.execute('''
      CREATE TABLE caja_movimientos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración a versión 4: agregar campo cancelado a productos
    if (oldVersion < 4) {
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(productos)');
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        if (!columnNames.contains('cancelado')) {
          await db.execute('ALTER TABLE productos ADD COLUMN cancelado INTEGER DEFAULT 0');
          await db.execute('UPDATE productos SET cancelado = 0 WHERE cancelado IS NULL');
        }
      } catch (e) {
        debugPrint('Error al migrar productos a versión 4: $e');
      }
    }
    // Migración a versión 3: agregar campos para variantes y acompañantes
    if (oldVersion < 3) {
      try {
        // Verificar si las columnas ya existen antes de agregarlas
        final tableInfo = await db.rawQuery('PRAGMA table_info(productos)');
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        if (!columnNames.contains('variantes')) {
          await db.execute('ALTER TABLE productos ADD COLUMN variantes TEXT DEFAULT NULL');
        }
        if (!columnNames.contains('acompanantes')) {
          await db.execute('ALTER TABLE productos ADD COLUMN acompanantes TEXT DEFAULT NULL');
        }
        if (!columnNames.contains('extras')) {
          await db.execute('ALTER TABLE productos ADD COLUMN extras TEXT DEFAULT NULL');
        }
      } catch (e) {
        debugPrint('Error al migrar productos a versión 3: $e');
      }
    }
    if (oldVersion < 2) {
      try {
        // Verificar y agregar columnas solo si no existen
        final tableInfo = await db.rawQuery('PRAGMA table_info(pedidos)');
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        if (!columnNames.contains('numeroOrden')) {
          await db.execute('ALTER TABLE pedidos ADD COLUMN numeroOrden INTEGER DEFAULT 0');
        }
        if (!columnNames.contains('estadoPago')) {
          await db.execute('ALTER TABLE pedidos ADD COLUMN estadoPago TEXT DEFAULT \'Pendiente\'');
        }
        if (!columnNames.contains('cancelado')) {
          await db.execute('ALTER TABLE pedidos ADD COLUMN cancelado INTEGER DEFAULT 0');
        }
        
        // Actualizar registros existentes
        await db.execute('UPDATE pedidos SET numeroOrden = id WHERE numeroOrden = 0 OR numeroOrden IS NULL');
        await db.execute('UPDATE pedidos SET estadoPago = \'Pendiente\' WHERE estadoPago IS NULL');
        await db.execute('UPDATE pedidos SET cancelado = 0 WHERE cancelado IS NULL');
      } catch (e) {
        // Si falla, intentar recrear la tabla
        debugPrint('Error en migración, recreando tabla pedidos: $e');
        await db.execute('DROP TABLE IF EXISTS pedidos_backup');
        await db.execute('CREATE TABLE pedidos_backup AS SELECT * FROM pedidos');
        await db.execute('DROP TABLE pedidos');
        await _onCreate(db, newVersion);
        await db.execute('''
          INSERT INTO pedidos (id, numeroOrden, cliente, celular, metodoPago, estado, estadoPago, productos, fecha, total, envasesLlevar, notas, cancelado)
          SELECT id, COALESCE(id, 0) as numeroOrden, cliente, celular, metodoPago, estado, COALESCE(estadoPago, 'Pendiente') as estadoPago, productos, fecha, total, envasesLlevar, COALESCE(notas, '') as notas, 0 as cancelado
          FROM pedidos_backup
        ''');
        await db.execute('DROP TABLE pedidos_backup');
      }
    }
  }
  
  /// Obtiene el siguiente número de orden (1-100, luego se reinicia)
  /// Usa el conteo de pedidos del día en lugar de MAX(numeroOrden) para evitar
  /// problemas cuando hay números duplicados después de pasar 100
  static Future<int> obtenerSiguienteNumeroOrden() async {
    try {
      final dbClient = await db;
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);
      
      // Contar cuántos pedidos hay en el día (no cancelados)
      // Esto garantiza que siempre obtengamos el siguiente número correcto,
      // incluso cuando hay múltiples pedidos con el mismo número de orden
      final result = await dbClient.rawQuery('''
        SELECT COUNT(*) as totalPedidos
        FROM pedidos 
        WHERE fecha BETWEEN ? AND ? AND cancelado = 0
      ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);
      
      final totalPedidos = result.first['totalPedidos'] as int? ?? 0;
      
      // Calcular el siguiente número de orden: (totalPedidos % 100) + 1
      // Si hay 0 pedidos: (0 % 100) + 1 = 1
      // Si hay 99 pedidos: (99 % 100) + 1 = 100
      // Si hay 100 pedidos: (100 % 100) + 1 = 1 (reinicia)
      // Si hay 101 pedidos: (101 % 100) + 1 = 2
      return (totalPedidos % 100) + 1;
    } catch (e) {
      throw Exception('Error al obtener siguiente número de orden: $e');
    }
  }

  // Métodos helper para productos
  static Future<int> insertarProducto(Producto producto) async {
    final error = producto.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    try {
      final dbClient = await db;
      return await dbClient.insert('productos', producto.toMap());
    } catch (e) {
      throw Exception('Error al insertar producto: $e');
    }
  }

  // Métodos helper para pedidos
  static Future<int> insertarPedido(Pedido pedido) async {
    final error = pedido.validar();
    if (error != null) {
      throw Exception('Error de validación: $error');
    }
    try {
      final dbClient = await db;
      return await dbClient.insert('pedidos', pedido.toMap());
    } catch (e) {
      throw Exception('Error al insertar pedido: $e');
    }
  }
}

