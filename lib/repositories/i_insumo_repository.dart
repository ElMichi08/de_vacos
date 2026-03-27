import 'package:de_vacos/models/insumo.dart';

abstract class IInsumoRepository {
  Future<Insumo> crearInsumo(Insumo insumo);
  Future<Insumo?> obtenerInsumoPorId(int id);
  Future<List<Insumo>> obtenerTodosLosInsumos();
  Future<void> actualizarInsumo(Insumo insumo);
  Future<void> eliminarInsumo(int id);
}
