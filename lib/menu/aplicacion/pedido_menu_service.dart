import '../core/result.dart';
import '../dominio/definicion/menu_item_definicion.dart';
import '../factory/plato_factory.dart';
import '../builder/plato_construido.dart';
import '../strategy/calculo_precio_strategy.dart';
import '../servicios/stock_validator.dart';
import '../eventos/pedido_event_emitter.dart';
import '../eventos/pedido_confirmado_menu.dart';

/// Orquestador del flujo completo de un pedido de menú.
/// Recibe la estrategia de precio activa por inyección de dependencia.
class PedidoMenuService {
  final StockValidator _stockValidator;
  final CalculoPrecioStrategy _precioStrategy;
  final PedidoEventEmitter _emitter;

  PedidoMenuService({
    required StockValidator stockValidator,
    required CalculoPrecioStrategy precioStrategy,
    required PedidoEventEmitter emitter,
  })  : _stockValidator = stockValidator,
        _precioStrategy = precioStrategy,
        _emitter = emitter;

  /// Ejecuta el flujo completo:
  /// validar stock → crear plato → calcular precio → emitir evento.
  ///
  /// Retorna el precio final calculado o un mensaje de error.
  Future<Result<double, String>> procesarPedido({
    required MenuItemDefinicion definicion,
    required SeleccionPlato seleccion,
    required String pedidoId,
  }) async {
    // 1. Validar stock antes de crear el plato
    final stockResult = await _stockValidator.validar(seleccion.proteinas);
    if (stockResult.isErr) return Result.err(stockResult.error);

    // 2. Crear el plato via Factory → Builder
    final platoResult = PlatoFactory.crear(definicion, seleccion);
    if (platoResult.isErr) return Result.err(platoResult.error);

    final PlatoConstruido plato = platoResult.value;

    // 3. Calcular precio con estrategia activa
    final precioFinal = _precioStrategy.calcular(plato);

    // 4. Emitir evento → InsumoMenuService descuenta stock
    _emitter.emit(
      PedidoConfirmadoMenu(
        pedidoId: pedidoId,
        proteinasUsadas: plato.proteinas,
      ),
    );

    return Result.ok(precioFinal);
  }

  /// Cambia la estrategia de precio en runtime (ej: activar modo Feria).
  /// Retorna una nueva instancia con la estrategia actualizada.
  PedidoMenuService conEstrategia(CalculoPrecioStrategy nuevaEstrategia) =>
      PedidoMenuService(
        stockValidator: _stockValidator,
        precioStrategy: nuevaEstrategia,
        emitter: _emitter,
      );
}
