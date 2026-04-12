/// Contrato base para todos los componentes de un plato.
/// Permite tratar tiers, decoradores y extras de forma uniforme (LSP).
abstract class IComponenteMenu {
  String getNombre();
  double getPrecio();
}
