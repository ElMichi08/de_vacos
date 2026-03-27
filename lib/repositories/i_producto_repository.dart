import 'package:de_vacos/models/producto.dart';

abstract class IProductoRepository {
  Future<Producto> crearProducto(Producto producto);
  Future<Producto?> obtenerProductoPorId(int id);
  Future<List<Producto>> obtenerTodosLosProductos();
  Future<List<Producto>> obtenerProductosActivos();
  Future<void> actualizarProducto(Producto producto);
  Future<void> eliminarProducto(int id);
  Future<void> eliminarProductoPermanentemente(int id);
}
