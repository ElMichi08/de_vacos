import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/models/receta_detalle.dart';
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/core/exceptions/stock_insuficiente_exception.dart';
import 'package:de_vacos/services/receta_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class InsumoService {
  static Future<List<Insumo>> listar() async {
    return di.insumoRepository.obtenerTodosLosInsumos();
  }

  static Future<List<Insumo>> listarPorTipo(InsumoTipo tipo) async {
    return di.insumoRepository.obtenerPorTipo(tipo);
  }

  static Future<Insumo?> obtenerPorId(int id) async {
    return di.insumoRepository.obtenerInsumoPorId(id);
  }

  static Future<int> crear(Insumo insumo) async {
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    final creado = await di.insumoRepository.crearInsumo(insumo);
    return creado.id ?? 0;
  }

  static Future<int> actualizar(Insumo insumo) async {
    if (insumo.id == null) {
      throw Exception('El insumo debe tener id para actualizar');
    }
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    await di.insumoRepository.actualizarInsumo(insumo);
    return insumo.id ?? 0;
  }

  static Future<int> eliminar(int id) async {
    await di.insumoRepository.eliminarInsumo(id);
    return id;
  }

  /// Descuenta insumos del stock de forma atómica (transacción)
  /// Lanza StockInsuficienteException si no hay stock suficiente
  static Future<void> descontarStock({
    required List<RecetaDetalle> recetas,
    required int cantidadProducto,
    Transaction? txn,
  }) async {
    Future<void> executeStockDiscount(Transaction tx) async {
      for (final receta in recetas) {
        // Usar tx directamente para evitar deadlock (no pasar por el repo)
        final rows = await tx.rawQuery(
          'SELECT * FROM insumos WHERE id = ? AND cancelado = 0',
          [receta.insumoId],
        );
        if (rows.isEmpty) continue;
        final insumo = Insumo.fromMap(rows.first);

        final requerido = receta.cantidad * cantidadProducto;
        if (insumo.cantidadActual < requerido) {
          throw StockInsuficienteException(
            insumo: insumo.nombre,
            requerido: requerido,
            disponible: insumo.cantidadActual,
          );
        }
      }

      for (final receta in recetas) {
        final requerido = receta.cantidad * cantidadProducto;
        await tx.rawUpdate(
          'UPDATE insumos SET cantidadActual = cantidadActual - ? WHERE id = ?',
          [requerido, receta.insumoId],
        );
      }
    }

    if (txn != null) {
      await executeStockDiscount(txn);
      return;
    }

    final db = await DBHelper.db;
    await db.transaction((tx) async {
      await executeStockDiscount(tx);
    });
  }

  /// Devuelve insumos al stock (simétrico a descontarStock).
  /// Sin validación de techo. Usa la misma firma de txn opcional.
  static Future<void> devolverStock({
    required List<RecetaDetalle> recetas,
    required int cantidadProducto,
    Transaction? txn,
  }) async {
    Future<void> execute(Transaction tx) async {
      for (final receta in recetas) {
        final requerido = receta.cantidad * cantidadProducto;
        await tx.rawUpdate(
          'UPDATE insumos SET cantidadActual = cantidadActual + ? WHERE id = ?',
          [requerido, receta.insumoId],
        );
      }
    }

    if (txn != null) {
      await execute(txn);
      return;
    }

    final db = await DBHelper.db;
    await db.transaction((tx) async => execute(tx));
  }

  /// Calcula el diff de stock entre dos snapshots de productos regulares
  /// (los que tienen `productoId`). No hace IO — solo aritmética.
  static ({Map<int, int> descontar, Map<int, int> devolver}) _calcularDiffStock(
    List<Map<String, dynamic>> productosAntes,
    List<Map<String, dynamic>> productosDespues,
  ) {
    Map<int, int> agrupar(List<Map<String, dynamic>> lista) {
      final m = <int, int>{};
      for (final p in lista) {
        final idRaw = p['productoId'] ?? p['id'];
        if (idRaw == null) continue;
        final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
        if (id == null) continue;
        final cantRaw = p['cantidad'] ?? 1;
        final cant = cantRaw is int
            ? cantRaw
            : (cantRaw is double
                ? cantRaw.toInt()
                : int.tryParse(cantRaw.toString()) ?? 1);
        m[id] = (m[id] ?? 0) + cant;
      }
      return m;
    }

    final antes = agrupar(productosAntes);
    final despues = agrupar(productosDespues);

    final descontar = <int, int>{};
    final devolver = <int, int>{};

    final ids = {...antes.keys, ...despues.keys};
    for (final id in ids) {
      final a = antes[id] ?? 0;
      final d = despues[id] ?? 0;
      final diff = d - a;
      if (diff > 0) descontar[id] = diff;
      if (diff < 0) devolver[id] = -diff;
    }

    return (descontar: descontar, devolver: devolver);
  }

  /// Calcula el diff de stock directo a nivel de insumo para ítems de menú
  /// (los que tienen `proteinaIds`). No hace IO — solo aritmética.
  static ({Map<int, int> descontar, Map<int, int> devolver}) _calcularDiffInsumos(
    List<Map<String, dynamic>> productosAntes,
    List<Map<String, dynamic>> productosDespues,
  ) {
    Map<int, int> expandir(List<Map<String, dynamic>> lista) {
      final m = <int, int>{};
      for (final p in lista) {
        final cantRaw = p['cantidad'] ?? 1;
        final cant = cantRaw is int
            ? cantRaw
            : (cantRaw is double
                ? cantRaw.toInt()
                : int.tryParse(cantRaw.toString()) ?? 1);
        final rawIds = p['proteinaIds'];
        if (rawIds is! List) continue;
        for (final rawId in rawIds) {
          final id = rawId is int ? rawId : int.tryParse(rawId.toString());
          if (id == null) continue;
          m[id] = (m[id] ?? 0) + cant;
        }
      }
      return m;
    }

    final antes = expandir(productosAntes);
    final despues = expandir(productosDespues);

    final descontar = <int, int>{};
    final devolver = <int, int>{};

    final ids = {...antes.keys, ...despues.keys};
    for (final id in ids) {
      final a = antes[id] ?? 0;
      final d = despues[id] ?? 0;
      final diff = d - a;
      if (diff > 0) descontar[id] = diff;
      if (diff < 0) devolver[id] = -diff;
    }

    return (descontar: descontar, devolver: devolver);
  }

  /// Aplica diff de insumos directamente (para ítems de menú).
  static Future<void> _aplicarDiffInsumos(
    Map<int, int> descontar,
    Map<int, int> devolver,
    Transaction tx,
  ) async {
    for (final entry in descontar.entries) {
      final rows = await tx.rawQuery(
        'SELECT * FROM insumos WHERE id = ? AND cancelado = 0',
        [entry.key],
      );
      if (rows.isEmpty) continue;
      final insumo = Insumo.fromMap(rows.first);
      final requerido = entry.value.toDouble();
      if (insumo.cantidadActual < requerido) {
        throw StockInsuficienteException(
          insumo: insumo.nombre,
          requerido: requerido,
          disponible: insumo.cantidadActual,
        );
      }
      await tx.rawUpdate(
        'UPDATE insumos SET cantidadActual = cantidadActual - ? WHERE id = ?',
        [requerido, entry.key],
      );
    }
    for (final entry in devolver.entries) {
      await tx.rawUpdate(
        'UPDATE insumos SET cantidadActual = cantidadActual + ? WHERE id = ?',
        [entry.value.toDouble(), entry.key],
      );
    }
  }

  /// Aplica el diff de stock entre dos snapshots.
  /// Soporta tanto productos regulares (via receta_detalle) como ítems de menú (via proteinaIds).
  /// `productosDespues: []` devuelve todo el stock de `productosAntes`.
  static Future<void> aplicarDiffStock({
    required List<Map<String, dynamic>> productosAntes,
    required List<Map<String, dynamic>> productosDespues,
    Transaction? txn,
  }) async {
    // Separar productos regulares de ítems de menú
    bool esMenu(Map<String, dynamic> p) => p['tipo'] == 'menu';

    final antesMenu = productosAntes.where(esMenu).toList();
    final despuesMenu = productosDespues.where(esMenu).toList();
    final antesReg = productosAntes.where((p) => !esMenu(p)).toList();
    final despuesReg = productosDespues.where((p) => !esMenu(p)).toList();

    final diffReg = _calcularDiffStock(antesReg, despuesReg);
    final diffMenu = _calcularDiffInsumos(antesMenu, despuesMenu);

    Future<void> execute(Transaction tx) async {
      // Productos regulares vía receta_detalle
      for (final entry in diffReg.descontar.entries) {
        final recetas = await RecetaService.obtenerPorProducto(entry.key, txn: tx);
        if (recetas.isNotEmpty) {
          await descontarStock(recetas: recetas, cantidadProducto: entry.value, txn: tx);
        }
      }
      for (final entry in diffReg.devolver.entries) {
        final recetas = await RecetaService.obtenerPorProducto(entry.key, txn: tx);
        if (recetas.isNotEmpty) {
          await devolverStock(recetas: recetas, cantidadProducto: entry.value, txn: tx);
        }
      }
      // Ítems de menú directo a insumos
      await _aplicarDiffInsumos(diffMenu.descontar, diffMenu.devolver, tx);
    }

    if (txn != null) {
      await execute(txn);
      return;
    }

    final db = await DBHelper.db;
    await db.transaction((tx) async => execute(tx));
  }
}
