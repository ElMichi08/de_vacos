import 'package:flutter/foundation.dart';
import '../producto_service.dart';
import '../pedido_service.dart';
import '../../models/producto.dart';
import '../../models/pedido.dart';
import 'pedido_factory.dart';

/// Servicio para generar datos de prueba
/// Encapsula la lógica de creación de datos de prueba usando la Factory
class TestDataService {
  /// Productos por defecto que se crearán si no hay suficientes productos
  /// Usa rutas placeholder que el sistema puede manejar (mostrará ícono si no existe el archivo)
  static final List<Producto> _productosPorDefecto = [
    Producto(
      nombre: 'Hamburguesa Clásica',
      precio: 5.0,
      imagenPath: 'placeholder_producto_1', // Ruta placeholder que pasa validación
    ),
    Producto(
      nombre: 'Hamburguesa Especial',
      precio: 6.0,
      imagenPath: 'placeholder_producto_2',
    ),
    Producto(
      nombre: 'Papas Fritas',
      precio: 2.0,
      imagenPath: 'placeholder_producto_3',
    ),
    Producto(
      nombre: 'Bebida',
      precio: 1.0,
      imagenPath: 'placeholder_producto_4',
    ),
  ];

  /// Verifica que existan al menos 2 productos en el sistema
  /// Si no existen, crea productos por defecto
  static Future<void> asegurarProductosDisponibles() async {
    try {
      final productosExistentes = await ProductoService.obtenerTodos();
      
      if (productosExistentes.length >= 2) {
        debugPrint('Hay ${productosExistentes.length} productos disponibles. No se necesitan crear más.');
        return;
      }

      debugPrint('Solo hay ${productosExistentes.length} producto(s). Creando productos por defecto...');

      int productosCreados = 0;
      for (final producto in _productosPorDefecto) {
        try {
          await ProductoService.guardar(producto);
          productosCreados++;
          debugPrint('Producto creado: ${producto.nombre}');
        } catch (e) {
          debugPrint('Error al crear producto ${producto.nombre}: $e');
        }
      }

      debugPrint('Se crearon $productosCreados productos por defecto.');
      
      // Verificar nuevamente que tengamos al menos 2
      final productosActualizados = await ProductoService.obtenerTodos();
      if (productosActualizados.length < 2) {
        throw Exception(
          'No se pudieron crear suficientes productos. '
          'Por favor, crea al menos 2 productos manualmente desde la pantalla de Productos.'
        );
      }
    } catch (e) {
      throw Exception('Error al asegurar productos disponibles: $e');
    }
  }

  /// Genera una cantidad específica de pedidos aleatorios
  /// 
  /// [cantidad]: Número de pedidos a generar
  /// [onProgress]: Callback opcional para reportar progreso (0.0 a 1.0)
  /// 
  /// Retorna el número de pedidos creados exitosamente
  static Future<int> generarPedidos(int cantidad, {Function(double)? onProgress}) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad de pedidos debe ser mayor a 0');
    }

    try {
      // Asegurar que haya productos disponibles
      await asegurarProductosDisponibles();

      // Obtener productos disponibles
      final productos = await ProductoService.obtenerTodos();
      
      if (productos.isEmpty) {
        throw Exception('No hay productos disponibles. Por favor, crea productos primero.');
      }

      if (productos.length < 2) {
        throw Exception(
          'Se requieren al menos 2 productos. Actualmente hay ${productos.length}. '
          'Por favor, crea más productos desde la pantalla de Productos.'
        );
      }

      debugPrint('Generando $cantidad pedidos aleatorios...');
      debugPrint('Productos disponibles: ${productos.length}');

      // Reiniciar el contador de fechas para asegurar orden secuencial
      PedidoFactory.reiniciarContadorFecha();

      int pedidosCreados = 0;
      int pedidosConError = 0;

      // Crear pedidos uno por uno para tener mejor control del progreso
      for (int i = 0; i < cantidad; i++) {
        try {
          // Crear pedido aleatorio usando la factory
          final pedidoAleatorio = PedidoFactory.crearPedidoAleatorio(productos);
          
          // Guardar el pedido (el servicio asignará automáticamente el número de orden)
          await PedidoService.guardar(pedidoAleatorio);
          pedidosCreados++;

          // Reportar progreso
          if (onProgress != null) {
            final progreso = (i + 1) / cantidad;
            onProgress(progreso);
          }

          // Log cada 10 pedidos para no saturar
          if ((i + 1) % 10 == 0 || (i + 1) == cantidad) {
            debugPrint('Progreso: ${i + 1}/$cantidad pedidos generados');
          }
        } catch (e) {
          pedidosConError++;
          debugPrint('Error al crear pedido ${i + 1}: $e');
          
          // Si hay muchos errores consecutivos, detener
          if (pedidosConError > 10) {
            throw Exception(
              'Demasiados errores al crear pedidos. '
              'Se crearon $pedidosCreados pedidos antes de detenerse. '
              'Último error: $e'
            );
          }
        }
      }

      debugPrint('Generación completada: $pedidosCreados pedidos creados exitosamente');
      
      if (pedidosConError > 0) {
        debugPrint('Advertencia: $pedidosConError pedidos tuvieron errores al crearse');
      }

      return pedidosCreados;
    } catch (e) {
      throw Exception('Error al generar pedidos: $e');
    }
  }

  /// Obtiene estadísticas de los pedidos generados
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      final pedidos = await PedidoService.obtenerTodos(
        fechaInicio: inicioDia,
        fechaFin: finDia,
      );

      final productos = await ProductoService.obtenerTodos();

      return {
        'totalPedidos': pedidos.length,
        'totalProductos': productos.length,
        'pedidosPorEstado': _contarPorEstado(pedidos),
        'pedidosPorMetodoPago': _contarPorMetodoPago(pedidos),
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  static Map<String, int> _contarPorEstado(List<Pedido> pedidos) {
    final conteo = <String, int>{};
    for (final pedido in pedidos) {
      conteo[pedido.estado] = (conteo[pedido.estado] ?? 0) + 1;
    }
    return conteo;
  }

  static Map<String, int> _contarPorMetodoPago(List<Pedido> pedidos) {
    final conteo = <String, int>{};
    for (final pedido in pedidos) {
      conteo[pedido.metodoPago] = (conteo[pedido.metodoPago] ?? 0) + 1;
    }
    return conteo;
  }

  /// Elimina todos los pedidos del día actual
  /// Útil para limpiar datos de prueba generados con el factory
  static Future<int> eliminarPedidosDelDia() async {
    try {
      debugPrint('Eliminando pedidos del día actual...');
      
      final pedidosEliminados = await PedidoService.eliminarPedidosDelDiaActual();
      
      debugPrint('Se eliminaron $pedidosEliminados pedidos del día actual.');
      
      return pedidosEliminados;
    } catch (e) {
      throw Exception('Error al eliminar pedidos del día: $e');
    }
  }
}
