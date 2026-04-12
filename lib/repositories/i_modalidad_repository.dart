import '../models/modalidad.dart';

abstract class IModalidadRepository {
  Future<List<Modalidad>> obtenerTodas();
  Future<Modalidad?> obtenerPorId(int id);
  Future<Modalidad> crear(Modalidad modalidad);
  Future<void> actualizar(Modalidad modalidad);
  Future<void> eliminar(int id);
}
