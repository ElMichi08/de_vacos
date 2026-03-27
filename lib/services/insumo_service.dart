import 'package:de_vacos/injection/container.dart';
import 'package:de_vacos/models/insumo.dart';

class InsumoService {
  static Future<List<Insumo>> listar() async {
    return di.insumoRepository.obtenerTodosLosInsumos();
  }

  static Future<Insumo?> obtenerPorId(int id) async {
    return di.insumoRepository.obtenerInsumoPorId(id);
  }

  static Future<int> crear(Insumo insumo) async {
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    final creado = await di.insumoRepository.crearInsumo(insumo);
    return creado.id ?? 0;
  }

  static Future<int> actualizar(Insumo insumo) async {
    if (insumo.id == null)
      throw Exception('El insumo debe tener id para actualizar');
    final err = insumo.validar();
    if (err != null) throw Exception('Validación: $err');
    await di.insumoRepository.actualizarInsumo(insumo);
    return insumo.id ?? 0;
  }

  static Future<int> eliminar(int id) async {
    await di.insumoRepository.eliminarInsumo(id);
    return id;
  }
}
