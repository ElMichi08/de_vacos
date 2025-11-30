import 'dart:math';
import '../../models/pedido.dart';
import '../../models/producto.dart';

/// Factory para generar pedidos aleatorios de prueba
/// Implementa el patrón Factory para crear instancias de Pedido con datos aleatorios
class PedidoFactory {
  static final Random _random = Random();
  
  // Lista de nombres de clientes aleatorios
  static final List<String> _nombresClientes = [
    'Juan Pérez',
    'María González',
    'Carlos Rodríguez',
    'Ana Martínez',
    'Luis Fernández',
    'Laura Sánchez',
    'Pedro López',
    'Carmen Torres',
    'Miguel Díaz',
    'Isabel García',
    'Francisco Ramírez',
    'Elena Gómez',
    'Antonio Morales',
    'Patricia Jiménez',
    'Roberto Herrera',
    'Mónica Vázquez',
    'Javier Ruiz',
    'Sofía Medina',
    'Diego Castro',
    'Andrea Mendoza',
    'Ricardo Vega',
    'Claudia Ríos',
    'Fernando Campos',
    'Valeria Paredes',
    'Óscar Vargas',
    'Daniela Rojas',
    'Andrés Montoya',
    'Natalia Suárez',
    'Sergio Cárdenas',
    'Camila Ortiz',
  ];

  // Lista de métodos de pago
  static final List<String> _metodosPago = [
    'Efectivo',
    'Transferencia',
  ];

  // Lista de notas aleatorias (algunas vacías para simular realidad)
  static final List<String> _notas = [
    '',
    '',
    '',
    'Sin cebolla',
    'Sin tomate',
    'Extra salsa',
    'Poco picante',
    'Muy picante',
    'Para llevar urgente',
    'Sin cilantro',
    'Agregar lechuga',
    'Sin queso',
    'Doble queso',
    'Para entrega en 30 minutos',
    'Sin aderezo',
  ];

  /// Genera un número de teléfono aleatorio colombiano
  static String _generarTelefono() {
    final prefijos = ['300', '301', '302', '310', '311', '312', '320', '321', '322', '350', '351'];
    final prefijo = prefijos[_random.nextInt(prefijos.length)];
    final numero = _random.nextInt(9000000) + 1000000; // 7 dígitos
    return '$prefijo$numero';
  }

  /// Genera una lista aleatoria de productos para un pedido
  /// Asegura que al menos seleccione un producto
  static List<Map<String, dynamic>> _generarProductos(List<Producto> productosDisponibles) {
    if (productosDisponibles.isEmpty) {
      throw Exception('No hay productos disponibles para generar pedidos');
    }

    final productosPedido = <Map<String, dynamic>>[];
    
    // Seleccionar entre 1 y 5 productos diferentes
    final cantidadProductos = _random.nextInt(5) + 1;
    final productosSeleccionados = <Producto>[];
    
    // Seleccionar productos únicos
    final productosCopia = List<Producto>.from(productosDisponibles);
    for (int i = 0; i < cantidadProductos && productosCopia.isNotEmpty; i++) {
      final indice = _random.nextInt(productosCopia.length);
      productosSeleccionados.add(productosCopia.removeAt(indice));
    }

    // Crear lista de productos con cantidades aleatorias
    for (final producto in productosSeleccionados) {
      final cantidad = _random.nextInt(4) + 1; // Entre 1 y 4
      productosPedido.add({
        'id': producto.id,
        'nombre': producto.nombre,
        'precio': producto.precio,
        'cantidad': cantidad,
      });
    }

    return productosPedido;
  }

  /// Calcula el total de un pedido basado en sus productos
  static double _calcularTotal(List<Map<String, dynamic>> productos, int envasesLlevar) {
    double total = 0.0;
    
    for (final producto in productos) {
      final precio = producto['precio'] as double;
      final cantidad = producto['cantidad'] as int;
      total += precio * cantidad;
    }
    
    // Agregar costo de envases (0.25 por envase)
    total += envasesLlevar * 0.25;
    
    return double.parse(total.toStringAsFixed(2));
  }

  /// Variable estática para mantener el contador de fechas secuenciales
  static DateTime? _ultimaFechaGenerada;
  static int _contadorMinutos = 0;

  /// Genera una fecha secuencial dentro del día actual
  /// Las fechas se generan de manera incremental para mantener un orden secuencial
  /// Los pedidos se distribuyen a lo largo del día de forma ordenada
  static DateTime _generarFechaSecuencial() {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    
    // Si es la primera vez o el último pedido fue de otro día, empezar desde las 6 AM
    if (_ultimaFechaGenerada == null || 
        _ultimaFechaGenerada!.year != ahora.year ||
        _ultimaFechaGenerada!.month != ahora.month ||
        _ultimaFechaGenerada!.day != ahora.day) {
      _ultimaFechaGenerada = DateTime(
        inicioDia.year,
        inicioDia.month,
        inicioDia.day,
        6, // Empezar a las 6 AM
        0,
        0,
      );
      _contadorMinutos = 0;
    }
    
    // Incrementar por intervalos de 1 minuto para distribuir los pedidos de forma secuencial
    _contadorMinutos += 1;
    
    final nuevaFecha = DateTime(
      inicioDia.year,
      inicioDia.month,
      inicioDia.day,
      6, // Hora inicial
      0, // Minuto inicial
    ).add(Duration(minutes: _contadorMinutos));
    
    // Si la nueva fecha excede las 11:59 PM, usar microsegundos para mantener orden
    if (nuevaFecha.hour >= 23 && nuevaFecha.minute >= 59) {
      // Usar microsegundos para diferenciar fechas cuando se exceden las horas
      // Mantener el orden pero usando una granularidad más fina
      final minutosExtras = _contadorMinutos - ((23 - 6) * 60 + 59);
      final fechaFinal = DateTime(
        inicioDia.year,
        inicioDia.month,
        inicioDia.day,
        23,
        59,
        59,
        minutosExtras * 10000, // Usar microsegundos para diferenciar
      );
      _ultimaFechaGenerada = fechaFinal;
      return fechaFinal;
    }
    
    _ultimaFechaGenerada = nuevaFecha;
    return nuevaFecha;
  }

  /// Reinicia el contador de fechas (útil cuando se generan nuevos lotes de pedidos)
  static void reiniciarContadorFecha() {
    _ultimaFechaGenerada = null;
    _contadorMinutos = 0;
  }

  /// Crea un pedido aleatorio basado en productos disponibles
  /// 
  /// [productosDisponibles]: Lista de productos disponibles en el sistema
  /// [numeroOrden]: Número de orden que se asignará al pedido (se genera automáticamente)
  /// 
  /// Retorna un Pedido con datos aleatorios válidos
  static Pedido crearPedidoAleatorio(
    List<Producto> productosDisponibles, {
    int numeroOrden = 0, // Se asignará automáticamente en el servicio
  }) {
    if (productosDisponibles.isEmpty) {
      throw Exception('Se requiere al menos un producto para crear un pedido');
    }

    final cliente = _nombresClientes[_random.nextInt(_nombresClientes.length)];
    final celular = _generarTelefono();
    final metodoPago = _metodosPago[_random.nextInt(_metodosPago.length)];
    final envasesLlevar = _random.nextInt(6); // Entre 0 y 5 envases
    final notaIndex = _random.nextInt(_notas.length);
    final notas = _notas[notaIndex];
    final productos = _generarProductos(productosDisponibles);
    final total = _calcularTotal(productos, envasesLlevar);
    final fecha = _generarFechaSecuencial();

    return Pedido(
      numeroOrden: numeroOrden,
      cliente: cliente,
      celular: celular,
      metodoPago: metodoPago,
      estado: 'En preparación',
      estadoPago: _random.nextBool() ? 'Cobrado' : 'Pendiente',
      productos: productos,
      fecha: fecha,
      total: total,
      envasesLlevar: envasesLlevar,
      notas: notas,
      cancelado: false,
    );
  }

  /// Crea múltiples pedidos aleatorios
  /// 
  /// [cantidad]: Número de pedidos a crear
  /// [productosDisponibles]: Lista de productos disponibles
  /// 
  /// Retorna una lista de pedidos aleatorios
  static List<Pedido> crearPedidosAleatorios(
    int cantidad,
    List<Producto> productosDisponibles,
  ) {
    if (cantidad <= 0) {
      throw Exception('La cantidad de pedidos debe ser mayor a 0');
    }

    if (productosDisponibles.isEmpty) {
      throw Exception('Se requiere al menos un producto para crear pedidos');
    }

    final pedidos = <Pedido>[];
    
    for (int i = 0; i < cantidad; i++) {
      pedidos.add(crearPedidoAleatorio(productosDisponibles));
    }

    return pedidos;
  }
}
