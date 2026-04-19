# Architecture

## Capas del proyecto

| Capa | Ubicación | Responsabilidad |
|------|-----------|-----------------|
| **Models** | `lib/models/` | DTOs: Pedido, Producto, Caja, Insumo, Modalidad, Extra, Acompanante, ProductoVariante, RecetaDetalle, ProductoSeleccionado |
| **Services** | `lib/services/` | Lógica de negocio (estática): PedidoService, CajaService, ProductoService, InsumoService, VentasService, RecetaService, ImageService |
| **Repositories** | `lib/repositories/` | Acceso a datos: interfaces (`I*Repository`) + implementaciones SQLite. Usados por Services vía DIContainer. |
| **DI** | `lib/injection/container.dart` | `DIContainer` singleton — punto de acceso a todas las instancias de repositorio. |
| **Database** | `lib/core/database/` | `DBHelper` — singleton SQLite con migraciones incrementales (v11) |
| **Config** | `lib/core/config/` | `BrandingConfig` cargado desde `assets/config/branding.json` |
| **Screens** | `lib/screens/` | 15 pantallas (ver lista abajo) |
| **Widgets** | `lib/widgets/` | 20 componentes reutilizables (modales, formularios, gráficos) |
| **Panel Web** | `lib/panel/` | Vistas read-only para admin (Supabase) |
| **Routing** | `lib/app_router.dart` | GoRouter con rutas POS + panel web + feature-flag guards |
| **Printer** | `lib/services/printer/` | Subsistema de impresión térmica: transporte abstracto (USB/Bluetooth), ticket builder y helpers |
| **Facturación** | `lib/services/facturacion/` | Interfaz + implementación pluggable (incluye no-op stub) |

## Pantallas (15)

| Pantalla | Archivo | Descripción |
|----------|---------|-------------|
| Home | `screens/home_screen.dart` | Dashboard principal y navegación |
| Órdenes | `screens/order_list_screen.dart` | Lista de pedidos activos, cobro, recobro |
| Formulario Pedido | `screens/order_form_screen.dart` | Crear / editar pedido (parámetro `Pedido? pedido`) |
| Cocina | `screens/cocina_screen.dart` | Vista de cocina con timer (pedidos en preparación) |
| Caja | `screens/caja_screen.dart` | Caja chica, ingresos, egresos y cierre diario |
| Reportes | `screens/report_screen.dart` | Ventas, top productos, filtros por fecha y método de pago |
| Productos | `screens/product_grid_screen.dart` | Grilla de productos con búsqueda |
| Agregar Producto | `screens/add_product_screen.dart` | Alta / edición de producto |
| Insumos | `screens/insumos_screen.dart` | Inventario con alertas de stock mínimo |
| Formulario Insumo | `screens/insumo_form_screen.dart` | Alta / edición de insumo |
| Config. Impresora | `screens/printer_settings_screen.dart` | Selección y configuración de impresora |
| Test Data | `screens/test_data_screen.dart` | Carga de datos de prueba (solo debug) |
| Menú Grid | `screens/menu/menu_grid_screen.dart` | Grilla de ítems del menú con modalidades |
| Formulario Menú | `screens/menu/menu_item_form_screen.dart` | Alta / edición de ítem de menú |
| Selector de Plato | `screens/menu/plato_selector_sheet.dart` | Bottom sheet para elegir modalidad al agregar ítem |

## Reglas de enrutamiento (GoRouter)

Toda navegación global usa `MaterialApp.router` con `GoRouter`.

- **USAR:** `context.go('/ruta')`, `context.push('/ruta')` y funciones nativas de GoRouter.
- **NUNCA USAR:** `Navigator.of(context).pushReplacement(...)` — desincroniza el historial de GoRouter, forzando recargas accidentales de la raíz (`/splash`) al navegar hacia atrás o ejecutar `context.pop()`.

## Patrón crear / editar (DRY)

Las pantallas de crear y editar comparten una sola clase con parámetro nullable:

```dart
class OrderFormScreen extends StatefulWidget {
  final Pedido? pedido; // null = crear, non-null = editar
}
```

Este patrón aplica a `OrderFormScreen`, `InsumoFormScreen`, `AddProductScreen` y `MenuItemFormScreen`.

## Base de datos local (SQLite)

- **Versión actual:** v11
- **Tablas:** `productos`, `pedidos`, `caja_movimientos`, `insumos`, `receta_detalle`, `modalidades`, `menu_items`
- **Migraciones:** incrementales en `lib/core/database/db_helper.dart` (`onUpgrade`)
- **Singleton:** `DBHelper.db` con soporte de `testDbPathOverride` para tests
- **Columnas clave en `pedidos`:** `pagos TEXT` (JSON historial multi-pago), `productosCobrados TEXT` (snapshot de productos al último cobro)

## Numeración de órdenes

`obtenerSiguienteNumeroOrden()` retorna `MAX(numeroOrden HOY, incluyendo cancelados) + 1`.

- Sin ciclo ni límite superior: la secuencia crece indefinidamente durante el día.
- Reinicio implícito al cambiar de día: el MAX del nuevo día es 0, por lo que el primer pedido recibe #1.
- Los números de órdenes canceladas **no se reutilizan** (el MAX incluye cancelados).
- La asignación ocurre dentro de una transacción exclusiva de SQLite para garantizar unicidad bajo concurrencia.

## Flujo de stock (decremento y diff)

El stock se descuenta al momento del **cobro**, no al crear el pedido.

- **Primer cobro:** `InsumoService.descontarStock()` decuenta todos los productos. Se guarda snapshot en `productosCobrados`.
- **Recobro / edición cobrada:** `PedidoService.actualizarConDiffStock()` aplica solo el delta entre `productosCobrados` (snapshot previo) y los productos actuales. Todo en una sola transacción atómica.
- **Cancelación:** devuelve stock según `productosCobrados` si el pedido ya estaba cobrado.

## Flujo de pago (multi-pago)

Cada cobro se agrega a la columna `pagos` (JSON array) del pedido:

```
Pendiente ──[cobrar]──▶ Cobrado ──[editar orden]──▶ Recobrar
                                                        │
                                          [pagar diferencia]
                                                        ▼
                                                    Cobrado
                                        (máx 2 recobros = 3 pagos totales)
```

- `estadoPago`: `Pendiente | Cobrado | Recobrar`
- `pagos`: `[{metodo, monto, foto?}, ...]` — máx. 3 entradas
- Al editar un pedido ya cobrado con snapshot disponible → `actualizarConDiffStock()` (stock + snapshot + estadoPago=Recobrar en transacción única)
- Al editar un pedido cobrado sin snapshot → `actualizar()` + `setRecobrar()`

## Print Service

Los layouts de tickets (`lib/services/printer/ticket_builder.dart`) usan escalado de logo dinámico al 50% y fuentes estandarizadas (`PosTextSize.size2`).

## Feature flags

Módulos opcionales habilitados/deshabilitados en `assets/config/branding.json` bajo el array `features`. Actualmente: `insumos` habilitado.
