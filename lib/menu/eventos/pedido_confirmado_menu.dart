import '../dominio/componentes/i_proteina.dart';

/// Evento emitido al confirmar un pedido de menú.
/// Contiene las proteínas usadas para que InsumoMenuService descuente el stock.
class PedidoConfirmadoMenu {
  final String pedidoId;
  final List<IProteina> proteinasUsadas;
  final DateTime fechaHora;

  PedidoConfirmadoMenu({
    required this.pedidoId,
    required this.proteinasUsadas,
    DateTime? fechaHora,
  }) : fechaHora = fechaHora ?? DateTime.now();
}
