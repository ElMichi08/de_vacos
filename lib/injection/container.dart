import 'package:de_vacos/repositories/i_pedido_repository.dart';
import 'package:de_vacos/repositories/i_producto_repository.dart';
import 'package:de_vacos/repositories/i_caja_repository.dart';
import 'package:de_vacos/repositories/i_insumo_repository.dart';
import 'package:de_vacos/repositories/i_ventas_repository.dart';
import 'package:de_vacos/repositories/i_image_repository.dart';
import 'package:de_vacos/repositories/i_modalidad_repository.dart';
import 'package:de_vacos/repositories/pedido_repository.dart';
import 'package:de_vacos/repositories/producto_repository.dart';
import 'package:de_vacos/repositories/caja_repository.dart';
import 'package:de_vacos/repositories/insumo_repository.dart';
import 'package:de_vacos/repositories/ventas_repository.dart';
import 'package:de_vacos/repositories/image_repository.dart';
import 'package:de_vacos/repositories/modalidad_repository.dart';
// Menu module
import 'package:de_vacos/menu/repositorios/i_menu_item_repository.dart';
import 'package:de_vacos/menu/repositorios/menu_item_local_repository.dart';
import 'package:de_vacos/menu/dominio/insumo/i_insumo_menu_repository.dart';
import 'package:de_vacos/menu/repositorios/insumo_menu_local_repository.dart';
import 'package:de_vacos/menu/eventos/pedido_event_emitter.dart';
import 'package:de_vacos/menu/servicios/stock_validator.dart';
import 'package:de_vacos/menu/servicios/insumo_menu_service.dart';
import 'package:de_vacos/menu/strategy/precio_normal_strategy.dart';
import 'package:de_vacos/menu/aplicacion/pedido_menu_service.dart';

class DIContainer {
  static final DIContainer _instance = DIContainer._internal();
  factory DIContainer() => _instance;
  DIContainer._internal();

  // ── Repositorios existentes ──────────────────────────────────────────────

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

  IModalidadRepository? _modalidadRepository;
  IModalidadRepository get modalidadRepository =>
      _modalidadRepository ??= ModalidadRepository();

  // ── Módulo Menú ──────────────────────────────────────────────────────────

  IMenuItemRepository? _menuItemRepository;
  IMenuItemRepository get menuItemRepository =>
      _menuItemRepository ??= MenuItemLocalRepository();

  IInsumoMenuRepository? _insumoMenuRepository;
  IInsumoMenuRepository get insumoMenuRepository =>
      _insumoMenuRepository ??= InsumoMenuLocalRepository();

  PedidoEventEmitter get pedidoEventEmitter => PedidoEventEmitter();

  StockValidator? _stockValidator;
  StockValidator get stockValidator =>
      _stockValidator ??= StockValidator(insumoMenuRepository);

  InsumoMenuService? _insumoMenuService;
  InsumoMenuService get insumoMenuService =>
      _insumoMenuService ??= InsumoMenuService(insumoMenuRepository, pedidoEventEmitter);

  PedidoMenuService? _pedidoMenuService;
  PedidoMenuService get pedidoMenuService =>
      _pedidoMenuService ??= PedidoMenuService(
        stockValidator: stockValidator,
        precioStrategy: PrecioNormalStrategy(),
        emitter: pedidoEventEmitter,
      );

  // ── Overrides para tests ─────────────────────────────────────────────────

  set pedidoRepository(IPedidoRepository repository) {
    _pedidoRepository = repository;
  }

  set menuItemRepository(IMenuItemRepository repository) {
    _menuItemRepository = repository;
  }

  void setInsumoMenuRepository(IInsumoMenuRepository repository) {
    _insumoMenuRepository = repository;
    _stockValidator = null;      // fuerza recreación con nuevo repo
    _insumoMenuService = null;
    _pedidoMenuService = null;
  }
}

final di = DIContainer();
