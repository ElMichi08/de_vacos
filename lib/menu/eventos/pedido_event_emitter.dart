import 'dart:async';
import 'pedido_confirmado_menu.dart';

/// Emisor de eventos de pedidos. Singleton.
/// PedidoMenuService emite; InsumoMenuService escucha.
/// El desacople via Observer mantiene SRP: PlatoBuilder no sabe de stock.
class PedidoEventEmitter {
  static final PedidoEventEmitter _instance = PedidoEventEmitter._();
  factory PedidoEventEmitter() => _instance;
  PedidoEventEmitter._();

  final StreamController<PedidoConfirmadoMenu> _controller =
      StreamController<PedidoConfirmadoMenu>.broadcast();

  Stream<PedidoConfirmadoMenu> get onPedidoConfirmado => _controller.stream;

  void emit(PedidoConfirmadoMenu evento) => _controller.add(evento);

  void dispose() => _controller.close();
}
