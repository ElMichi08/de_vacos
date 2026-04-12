import 'insumo_menu.dart';

/// Contrato del repositorio de insumos para el módulo de menú.
/// Desacopla el origen de datos (SQLite, Supabase, etc.).
/// Singleton — una sola fuente de verdad del stock.
abstract class IInsumoMenuRepository {
  Future<InsumoMenu?> findById(int id);
  Future<List<InsumoMenu>> findAll();
  Future<void> save(InsumoMenu insumo);
}
