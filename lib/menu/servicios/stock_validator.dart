import 'package:de_vacos/models/insumo.dart';
import '../core/result.dart';
import '../dominio/insumo/i_insumo_menu_repository.dart';

/// Valida stock ANTES de crear el pedido.
/// Responsabilidad única: verificar porciones disponibles.
/// NO descuenta stock — eso es responsabilidad de InsumoMenuService.
class StockValidator {
  final IInsumoMenuRepository _repository;

  StockValidator(this._repository);

  /// Verifica que haya al menos 1 porción disponible por proteína elegida.
  /// Retorna Ok(true) si hay stock, Err(mensaje) si falta alguna.
  Future<Result<bool, String>> validar(List<Insumo> proteinas) async {
    for (final insumo in proteinas) {
      final insumoMenu = await _repository.findById(insumo.id!);
      if (insumoMenu == null) {
        return Result.err(
          'Insumo "${insumo.nombre}" no encontrado en el inventario',
        );
      }
      if (!insumoMenu.tieneSuficientes(1)) {
        return Result.err(
          'Sin stock de "${insumo.nombre}" (disponible: ${insumoMenu.porcionesDisponibles})',
        );
      }
    }
    return Result.ok(true);
  }
}
