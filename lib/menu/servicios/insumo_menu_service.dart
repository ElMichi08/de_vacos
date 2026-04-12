import 'dart:async';
import '../dominio/insumo/i_insumo_menu_repository.dart';
import '../eventos/pedido_event_emitter.dart';
import '../eventos/pedido_confirmado_menu.dart';

/// Escucha el evento PedidoConfirmadoMenu y descuenta porciones del stock.
/// Observer del sistema: reacciona sin que PlatoBuilder lo conozca (SRP).
class InsumoMenuService {
  final IInsumoMenuRepository _repository;
  final PedidoEventEmitter _emitter;
  StreamSubscription<PedidoConfirmadoMenu>? _subscription;

  InsumoMenuService(this._repository, this._emitter);

  /// Inicia la escucha. Llamar al inicializar la app.
  void iniciar() {
    _subscription = _emitter.onPedidoConfirmado.listen(_onPedidoConfirmado);
  }

  void detener() => _subscription?.cancel();

  Future<void> _onPedidoConfirmado(PedidoConfirmadoMenu evento) async {
    for (final proteina in evento.proteinasUsadas) {
      final insumo = await _repository.findById(proteina.insumoId);
      if (insumo == null) continue;
      final actualizado = insumo.descontar(1);
      await _repository.save(actualizado);
    }
  }
}
