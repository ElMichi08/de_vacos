/// Entidad de dominio para el inventario usado por el menú.
/// Solo expone nombre y porciones disponibles.
/// Persiste en la tabla `insumos` existente (columna cantidadActual).
class InsumoMenu {
  final int id;
  final String nombre;
  final double porcionesDisponibles;

  const InsumoMenu({
    required this.id,
    required this.nombre,
    required this.porcionesDisponibles,
  });

  InsumoMenu descontar(double cantidad) => InsumoMenu(
        id: id,
        nombre: nombre,
        porcionesDisponibles: porcionesDisponibles - cantidad,
      );

  bool tieneSuficientes(double cantidad) => porcionesDisponibles >= cantidad;
}
