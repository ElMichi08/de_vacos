# Arquitectura del proyecto

### Referencia de diseño

La arquitectura sigue los principios de la skill **flutter-architecting-apps** (UI → Logic → Data), adaptados al estado actual del proyecto.

### Capas actuales

| Capa | Ubicación | Responsabilidad | Alineación con skill |
|------|-----------|-----------------|----------------------|
| **Models** | `lib/models/` | DTOs: `Pedido`, `Producto`, `Caja`, `Insumo`, `Extra`, `Acompanante`, `ProductoVariante`, `RecetaDetalle`, `ProductoSeleccionado` | ✅ Domain Models |
| **Services** | `lib/services/` | Lógica de negocio (estática): `PedidoService`, `CajaService`, `ProductoService`, `InsumoService`, `VentasService`, `RecetaService`, `LicenseService`, `ImageService` | ⚠️ Combinan rol de Service + Repository (sin separación) |
| **Database** | `lib/core/database/` | `DBHelper` – singleton SQLite con migraciones (v6). Soporta `testDbPathOverride` para tests | ✅ Data source |
| **Config** | `lib/core/config/` | `BrandingConfig` cargado desde asset JSON | ✅ Config |
| **Screens** | `lib/screens/` | 15 pantallas (Home, Caja, Cocina, Orders, Products, Insumos, Reports, Printer, Splash, Blocked, Test Data) | ⚠️ Views sin ViewModels (lógica en widgets) |
| **Widgets** | `lib/widgets/` | 17 componentes reutilizables (modales, formularios, gráficos) | ✅ UI Components |
| **Panel Web** | `lib/panel/` | Vistas read-only para admin (Supabase) | ✅ UI Layer |
| **Routing** | `lib/app_router.dart` | `GoRouter` con rutas POS + panel web | ✅ Navigation |

### Reglas de Enrutamiento

Toda la navegación global manejada mediante `MaterialApp.router` requiere el uso estricto de las funciones nativas de `GoRouter` (ej. `context.go('/ruta')`, `context.push('/ruta')`). 
**🚫 Antipatrón:** El uso de `Navigator.of(context).pushReplacement(...)` desincroniza el historial de `GoRouter`, forzando recargas accidentales de la raíz (`/splash`) al navegar hacia atrás o ejecutar `context.pop()`.

### Base de datos local (SQLite)

Tablas: `productos`, `pedidos`, `caja_movimientos`, `insumos`, `receta_detalle`.
Migraciones incrementales gestionadas en `db_helper.dart` (versión actual: 6).

### Numeración de órdenes

`obtenerSiguienteNumeroOrden()` calcula `(MAX(numeroOrden) del día % 100) + 1`.
Se reinicia automáticamente al pasar 100 pedidos o al cambiar de día, garantizando que no existan duplicados tras cancelaciones.

### Cobertura de tests actual

- **Services y Core:** 67 tests unitarios en suites (`caja_service`, `insumo_service`, `producto_service`, `ventas_service`, `pedido_service`, `numero_orden`, `db_helper`).
- **Screens:** `splash_flow_test`.
- **Patrón DB Test:** Se limpia la BD asíncronamente en cada `tearDown` mediante `DBHelper.deleteTestDb()`, evitando bloqueos de archivos `.db`.

### Documentación del Print Service

Los layouts de tickets (`lib/services/printer/ticket_builder.dart`) utilizan escalado de logo dinámico al 50% de su capacidad original y fuentes estandarizadas (`PosTextSize.size2`) tanto en descripciones de producto como identificadores de encabezado.

### Deuda técnica identificada

