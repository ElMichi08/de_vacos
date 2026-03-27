# Architecture

## Capas del proyecto

| Capa | Ubicación | Responsabilidad |
|------|-----------|-----------------|
| **Models** | `lib/models/` | DTOs: Pedido, Producto, Caja, Insumo, Extra, Acompanante, ProductoVariante, RecetaDetalle, ProductoSeleccionado |
| **Services** | `lib/services/` | Lógica de negocio (estática): PedidoService, CajaService, ProductoService, InsumoService, VentasService, RecetaService, ImageService |
| **Database** | `lib/core/database/` | DBHelper -- singleton SQLite con migraciones incrementales (v6) |
| **Config** | `lib/core/config/` | BrandingConfig cargado desde asset JSON |
| **Screens** | `lib/screens/` | 13 pantallas (Home, Caja, Cocina, Orders, Products, Insumos, Reports, Printer, Test Data) |
| **Widgets** | `lib/widgets/` | 16 componentes reutilizables (modales, formularios, gráficos) |
| **Panel Web** | `lib/panel/` | Vistas read-only para admin (Supabase) |
| **Routing** | `lib/app_router.dart` | GoRouter con rutas POS + panel web + feature-flag guards |
| **Printer** | `lib/services/printer/` | Subsistema de impresión térmica con transporte abstracto (USB/Bluetooth), ticket builder y helpers |
| **Facturación** | `lib/services/facturacion/` | Interfaz + implementación pluggable (incluye no-op stub) |

## Reglas de enrutamiento (GoRouter)

Toda navegación global usa `MaterialApp.router` con `GoRouter`.

- **USAR:** `context.go('/ruta')`, `context.push('/ruta')` y funciones nativas de GoRouter.
- **NUNCA USAR:** `Navigator.of(context).pushReplacement(...)` -- desincroniza el historial de GoRouter, forzando recargas accidentales de la raíz (`/splash`) al navegar hacia atrás o ejecutar `context.pop()`.

## Base de datos local (SQLite)

- Tablas: `productos`, `pedidos`, `caja_movimientos`, `insumos`, `receta_detalle`.
- Migraciones incrementales en `lib/core/database/db_helper.dart` (versión actual: 6).
- Singleton pattern con soporte de `testDbPathOverride` para tests.

## Numeración de órdenes

`obtenerSiguienteNumeroOrden()` calcula `(MAX(numeroOrden) del día % 100) + 1`. Se reinicia automáticamente al pasar 100 pedidos o al cambiar de día.

## Print Service

Los layouts de tickets (`lib/services/printer/ticket_builder.dart`) usan escalado de logo dinámico al 50% y fuentes estandarizadas (`PosTextSize.size2`).

## Deuda técnica

- Services son estáticos y combinan lógica de negocio con acceso a datos (sin Repositories ni ViewModels separados).
- Directorios `test/screens/` y `test/widgets/` vacíos.