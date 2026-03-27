import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/producto.dart';

class ProductoService {
  static Future<List<Producto>> obtenerTodos() async {
    return di.productoRepository.obtenerTodosLosProductos();
  }

  static Future<Producto?> obtenerPorId(int id) async {
    return di.productoRepository.obtenerProductoPorId(id);
  }

  static Future<int> guardar(Producto producto) async {
    final error = producto.validar();
    if (error != null) throw Exception(error);
    final creado = await di.productoRepository.crearProducto(producto);
    return creado.id ?? 0;
  }

  static Future<int> actualizar(Producto producto) async {
    await di.productoRepository.actualizarProducto(producto);
    return producto.id ?? 0;
  }

  static Future<int> desactivar(int id) async {
    await di.productoRepository.eliminarProducto(id);
    return id;
  }

  static Future<int> eliminar(int id) async {
    await di.productoRepository.eliminarProductoPermanentemente(id);
    return id;
  }
}
