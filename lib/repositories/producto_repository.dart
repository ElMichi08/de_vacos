import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/models/producto.dart';
import 'package:de_vacos/repositories/i_producto_repository.dart';

class ProductoRepository implements IProductoRepository {
  @override
  Future<Producto> crearProducto(Producto producto) async {
    final db = await DBHelper.db;
    final id = await db.insert('productos', producto.toMap());
    return Producto(
      id: id,
      nombre: producto.nombre,
      precio: producto.precio,
      imagenPath: producto.imagenPath,
      cancelado: false,
      variantes: producto.variantes,
      acompanantes: producto.acompanantes,
      extras: producto.extras,
    );
  }

  @override
  Future<Producto?> obtenerProductoPorId(int id) async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  @override
  Future<List<Producto>> obtenerTodosLosProductos() async {
    final db = await DBHelper.db;
    final maps = await db.query(
      'productos',
      where: 'cancelado = 0',
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  @override
  Future<List<Producto>> obtenerProductosActivos() async {
    final todos = await obtenerTodosLosProductos();
    return todos.where((p) => !p.cancelado).toList();
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    if (producto.id == null)
      throw Exception('El producto debe tener ID para actualizar');
    final db = await DBHelper.db;
    await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  @override
  Future<void> eliminarProducto(int id) async {
    final db = await DBHelper.db;
    await db.update(
      'productos',
      {'cancelado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> eliminarProductoPermanentemente(int id) async {
    final db = await DBHelper.db;
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }
}
