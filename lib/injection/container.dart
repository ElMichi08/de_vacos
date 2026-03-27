import 'package:de_vacos/repositories/i_pedido_repository.dart';
import 'package:de_vacos/repositories/i_producto_repository.dart';
import 'package:de_vacos/repositories/i_caja_repository.dart';
import 'package:de_vacos/repositories/i_insumo_repository.dart';
import 'package:de_vacos/repositories/i_ventas_repository.dart';
import 'package:de_vacos/repositories/i_image_repository.dart';
import 'package:de_vacos/repositories/pedido_repository.dart';
import 'package:de_vacos/repositories/producto_repository.dart';
import 'package:de_vacos/repositories/caja_repository.dart';
import 'package:de_vacos/repositories/insumo_repository.dart';
import 'package:de_vacos/repositories/ventas_repository.dart';
import 'package:de_vacos/repositories/image_repository.dart';

class DIContainer {
  static final DIContainer _instance = DIContainer._internal();
  factory DIContainer() => _instance;
  DIContainer._internal();

  IPedidoRepository? _pedidoRepository;
  IPedidoRepository get pedidoRepository =>
      _pedidoRepository ??= PedidoRepository();

  IProductoRepository? _productoRepository;
  IProductoRepository get productoRepository =>
      _productoRepository ??= ProductoRepository();

  ICajaRepository? _cajaRepository;
  ICajaRepository get cajaRepository => _cajaRepository ??= CajaRepository();

  IInsumoRepository? _insumoRepository;
  IInsumoRepository get insumoRepository =>
      _insumoRepository ??= InsumoRepository();

  IVentasRepository? _ventasRepository;
  IVentasRepository get ventasRepository =>
      _ventasRepository ??= VentasRepository();

  IImageRepository? _imageRepository;
  IImageRepository get imageRepository =>
      _imageRepository ??= ImageRepository();

  void setPedidoRepository(IPedidoRepository repository) {
    _pedidoRepository = repository;
  }
}

final di = DIContainer();
