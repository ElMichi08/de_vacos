import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import '../../models/producto.dart';
import '../../models/pedido.dart';

class DBHelper {
  static Database? _db;
  static const int _versionDb = 6; // Insumos + receta_detalle
  static bool _initialized = false;

  static String? _testDbPathOverride;
  static set testDbPathOverride(String? value) {
    _testDbPathOverride = value;
    _db?.close();
    _db = null;
  }

  /// Limpia y elimina la base de datos de test
  static Future<void> deleteTestDb() async {
    if (_testDbPathOverride != null) {
      await _db?.close();
      _db = null;
      try {
        await databaseFactory.deleteDatabase(_testDbPathOverride!);
      } catch (e) {
        debugPrint('Error deleting test db: $e');
      }
    }
  }

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
    if (_testDbPathOverride != null) {
      path = _testDbPathOverride!;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      path = path_utils.join(directory.path, 'vacos.db');
    } else {
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
          if (!pedidosColumnNames.contains('fotoTransferenciaPath')) {
            await db.execute('ALTER TABLE pedidos ADD COLUMN fotoTransferenciaPath TEXT DEFAULT NULL');
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

          // Verificar columnas de caja_movimientos
          try {
            final cajaTableInfo = await db.rawQuery('PRAGMA table_info(caja_movimientos)');
            final cajaColumnNames = cajaTableInfo.map((row) => row['name'] as String).toList();
            
            if (!cajaColumnNames.contains('isSystemGenerated')) {
              debugPrint('Agregando columna isSystemGenerated a caja_movimientos...');
              await db.execute('ALTER TABLE caja_movimientos ADD COLUMN isSystemGenerated INTEGER DEFAULT 0');
              await db.execute('UPDATE caja_movimientos SET isSystemGenerated = 0 WHERE isSystemGenerated IS NULL');
              debugPrint('Columna isSystemGenerated agregada exitosamente');
            }
          } catch (e) {
            debugPrint('Error al verificar columnas de caja_movimientos: $e');
            // Si la tabla no existe, no es un error crítico
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
        cancelado INTEGER DEFAULT 0,
        fotoTransferenciaPath TEXT DEFAULT NULL
      )
    ''');

    // Tabla caja_movimientos
    await db.execute('''
      CREATE TABLE caja_movimientos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        fecha TEXT NOT NULL,
        isSystemGenerated INTEGER DEFAULT 0
      )
    ''');

    // Tabla insumos
    await db.execute('''
      CREATE TABLE insumos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        unidadMedida TEXT NOT NULL,
        cantidadActual REAL NOT NULL DEFAULT 0,
        cantidadMinima REAL NOT NULL DEFAULT 0,
        costoUnitario REAL DEFAULT NULL,
        cancelado INTEGER DEFAULT 0
      )
    ''');

    // Tabla receta_detalle (producto_id, insumo_id, cantidad)
    await db.execute('''
      CREATE TABLE receta_detalle(
        producto_id INTEGER NOT NULL,
        insumo_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        PRIMARY KEY (producto_id, insumo_id),
        FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
        FOREIGN KEY (insumo_id) REFERENCES insumos(id)
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración a versión 6: tablas insumos y receta_detalle
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS insumos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          unidadMedida TEXT NOT NULL,
          cantidadActual REAL NOT NULL DEFAULT 0,
          cantidadMinima REAL NOT NULL DEFAULT 0,
          costoUnitario REAL DEFAULT NULL,
          cancelado INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receta_detalle(
          producto_id INTEGER NOT NULL,
          insumo_id INTEGER NOT NULL,
          cantidad REAL NOT NULL,
          PRIMARY KEY (producto_id, insumo_id),
          FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
          FOREIGN KEY (insumo_id) REFERENCES insumos(id)
        )
      ''');
    }
    // Migración a versión 5: agregar campo fotoTransferenciaPath a pedidos
    if (oldVersion < 5) {
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(pedidos)');
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        if (!columnNames.contains('fotoTransferenciaPath')) {
          await db.execute('ALTER TABLE pedidos ADD COLUMN fotoTransferenciaPath TEXT DEFAULT NULL');
        }
      } catch (e) {
        debugPrint('Error al migrar pedidos a versión 5: $e');
      }
    }
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
          INSERT INTO pedidos (id, numeroOrden, cliente, celular, metodoPago, estado, estadoPago, productos, fecha, total, envasesLlevar, notas, cancelado, fotoTransferenciaPath)
          SELECT id, COALESCE(id, 0) as numeroOrden, cliente, celular, metodoPago, estado, COALESCE(estadoPago, 'Pendiente') as estadoPago, productos, fecha, total, envasesLlevar, COALESCE(notas, '') as notas, 0 as cancelado, NULL as fotoTransferenciaPath
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
      
      // Obtener el máximo número de orden generado hoy
      // Usar MAX() garantiza que no se repitan números aunque haya pedidos anulados
      final result = await dbClient.rawQuery('''
        SELECT MAX(numeroOrden) as maxOrden
        FROM pedidos 
        WHERE fecha BETWEEN ? AND ?
      ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);
      
      final maxOrden = result.first['maxOrden'] as int? ?? 0;
      
      // Calcular el siguiente número de orden
      return (maxOrden % 100) + 1;
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

  /// Obtiene la auditoría semanal de ventas
  /// Retorna un Map con 'cantidad' (int) y 'total' (double)
  /// Filtros aplicados:
  /// - cancelado = 0 (solo pedidos activos)
  /// - estadoPago = 'Cobrado' (solo dinero real)
  /// - Rango de fechas entre inicio y fin
  static Future<Map<String, dynamic>> obtenerAuditoriaSemanal(
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      final dbClient = await db;
      
      // Normalizar fechas: inicio al inicio del día, fin al final del día
      final inicioNormalizado = DateTime(inicio.year, inicio.month, inicio.day);
      final finNormalizado = DateTime(
        fin.year,
        fin.month,
        fin.day,
        23,
        59,
        59,
        999,
      );
      
      // Consulta SQL para obtener cantidad y total de pedidos cobrados
      final result = await dbClient.rawQuery('''
        SELECT 
          COUNT(*) as cantidad,
          COALESCE(SUM(total), 0) as total
        FROM pedidos
        WHERE cancelado = 0
          AND estadoPago = 'Cobrado'
          AND fecha BETWEEN ? AND ?
      ''', [
        inicioNormalizado.toIso8601String(),
        finNormalizado.toIso8601String(),
      ]);
      
      if (result.isEmpty) {
        return {'cantidad': 0, 'total': 0.0};
      }
      
      final row = result.first;
      final cantidad = row['cantidad'] as int? ?? 0;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'cantidad': cantidad,
        'total': total,
      };
    } catch (e) {
      debugPrint('Error al obtener auditoría semanal: $e');
      throw Exception('Error al obtener auditoría semanal: $e');
    }
  }

  /// Top N productos más vendidos por cantidad en un rango de fechas (solo pedidos cobrados, no cancelados).
  /// Retorna lista de mapas con 'nombre', 'cantidad', 'monto' (máximo [limit] elementos).
  static Future<List<Map<String, dynamic>>> obtenerTopProductosPorVentas(
    DateTime inicio,
    DateTime fin,
    {int limit = 3}
  ) async {
    try {
      final dbClient = await db;
      final inicioNorm = DateTime(inicio.year, inicio.month, inicio.day);
      final finNorm = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      final result = await dbClient.rawQuery('''
        SELECT productos FROM pedidos
        WHERE cancelado = 0 AND estadoPago = 'Cobrado'
          AND fecha BETWEEN ? AND ?
      ''', [inicioNorm.toIso8601String(), finNorm.toIso8601String()]);
      final Map<String, Map<String, dynamic>> agregado = {};
      for (final row in result) {
        final productosJson = row['productos'] as String?;
        if (productosJson == null) continue;
        try {
          final lista = jsonDecode(productosJson);
          if (lista is! List) continue;
          for (final p in lista) {
            if (p is! Map<String, dynamic>) continue;
            final nombre = (p['nombre'] as String?) ?? (p['nombreProducto'] as String?) ?? 'Producto';
            final cantidad = (p['cantidad'] as int?) ?? 1;
            final precio = (p['precio'] as num?)?.toDouble() ?? 0.0;
            final monto = precio * cantidad;
            if (!agregado.containsKey(nombre)) {
              agregado[nombre] = {'nombre': nombre, 'cantidad': 0, 'monto': 0.0};
            }
            agregado[nombre]!['cantidad'] = (agregado[nombre]!['cantidad'] as int) + cantidad;
            agregado[nombre]!['monto'] = (agregado[nombre]!['monto'] as double) + monto;
          }
        } catch (_) {}
      }
      final ordenado = agregado.values.toList()
        ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
      return ordenado.take(limit).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error al obtener top productos: $e');
      return [];
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
      
      // Asegurar que la columna fotoTransferenciaPath existe antes de insertar
      final tableInfo = await dbClient.rawQuery('PRAGMA table_info(pedidos)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      if (!columnNames.contains('fotoTransferenciaPath')) {
        await dbClient.execute('ALTER TABLE pedidos ADD COLUMN fotoTransferenciaPath TEXT DEFAULT NULL');
      }
      
      return await dbClient.insert('pedidos', pedido.toMap());
    } catch (e) {
      throw Exception('Error al insertar pedido: $e');
    }
  }
}

