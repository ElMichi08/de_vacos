# De Vacos Urban Grill

App POS para controlar las ventas de "De Vacos Urban Grill".

## Configuración de marca (branding.json)

La app usa un archivo de configuración de marca para nombre, subtítulo, colores y features.

- **Ubicación:** `assets/config/branding.json` (declarado en `pubspec.yaml`).
- **Claves principales:**
  - `schemaVersion` (int): versión del esquema; actualmente se admite `1`. Si falta o es distinto, se usan valores por defecto y se escribe un mensaje en debug.
  - `appName`, `appSubtitle`: textos de identificación de la app.
  - `colors`: objeto con `primary`, `background`, `accent`, `cardBackground` en hex (ej. `"#A32D13"`).
  - `features`: lista de IDs de funcionalidades (ej. `productos`, `pedidos`, `cocina`, `insumos`, `reportes`, `caja`, `impresora`, `pruebas`, `licencia`).
  - `logoUrl`, `logoAssetPath`: opcionales (string o `null`).

**Estrategia en dos fases:**

- **Fase 1 (actual):** La configuración se carga desde el asset `assets/config/branding.json` al arranque mediante `AssetBrandingLoader`. Si el archivo falla o el JSON es inválido, se usan valores por defecto sin lanzar excepción.
- **Fase 2 (futura):** Cargar branding desde Supabase por `client_id` (por ejemplo una tabla `branding` filtrada por cliente), permitiendo multi-tenant con colores y nombre por cliente. El loader abstracto `BrandingConfigLoader` permite añadir una implementación `SupabaseBrandingLoader` sin cambiar el resto del código.

## Variables de entorno

- **En desarrollo (debug):** Crea un archivo `.env` en la raíz del proyecto con `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `CLIENTE_ID`. El archivo `.env` **no se incluye en el bundle** de release; solo se carga en modo debug desde disco.
- **En release:** No se usa `dotenv`. Pasa las variables en build time con `--dart-define`, por ejemplo:
  ```bash
  flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=CLIENTE_ID=...
  ```

## Ofuscación (release)

Para builds de producción se recomienda ofuscar el código y guardar símbolos para posibles stack traces:

```bash
flutter build apk --obfuscate --split-debug-info=build/symbols
```

Los archivos en `build/symbols` sirven para desofuscar crash reports; guárdalos de forma segura y no los subas al repositorio.

## Licencias y reportes a Supabase

La app verifica la licencia al iniciar y envía en **segundo plano** el total diario de ventas, cantidad de pedidos y **top 3 productos más vendidos**. Un fallo al enviar el reporte **no bloquea** al usuario. El período de gracia sin internet es de **14 días** (configurable en `lib/core/constants/security_constants.dart`). Detalle completo: **[docs/LICENCIAS_Y_REPORTES.md](docs/LICENCIAS_Y_REPORTES.md)**.

En Supabase, añade la columna opcional para top 3 productos en `reportes_semanales`:

```sql
ALTER TABLE reportes_semanales ADD COLUMN IF NOT EXISTS top_productos jsonb DEFAULT NULL;
```

## Políticas RLS recomendadas (Supabase)

En las tablas que usa la app, conviene restringir acceso por `cliente_id` con Row Level Security (RLS):

- **`licencias`:** Solo el cliente puede leer su fila (`cliente_id = auth.uid()` o equivalente según tu modelo de auth; si usas `CLIENTE_ID` fijo, una política que filtre por `cliente_id` igual al valor del cliente).
- **`reportes_semanales`:** El cliente solo puede INSERT/UPDATE/SELECT sus propias filas (`cliente_id` igual al identificador del cliente de la app).
- **`cobros`:** El cliente solo puede SELECT (y si aplica, otras operaciones) donde `cliente_id` coincida con el suyo.

Ejemplo genérico (adaptar nombres y condiciones a tu esquema):

```sql
-- Ejemplo: permitir a un cliente ver/actualizar solo sus registros
CREATE POLICY "Cliente reportes_semanales" ON reportes_semanales
FOR ALL USING (cliente_id = current_setting('app.cliente_id', true));
```

Configura `app.cliente_id` desde la app si usas JWT custom claims, o bien políticas que comparen con el valor que identifique al cliente (tenant).

## Panel web (vistas de solo lectura)

La misma app incluye un **panel web** con vistas de solo lectura para **reportes semanales**, **licencias** y **cobros**, leyendo directamente de Supabase.

### Rutas del panel

- **`/panel/reportes`** – Listado de `reportes_semanales`
- **`/panel/licencias`** – Listado de `licencias`
- **`/panel/cobros`** – Listado de `cobros`

Ejecutar en navegador:

```bash
flutter run -d chrome
```

Luego ir a `http://localhost:PORT/#/panel/reportes`, `#/panel/licencias` o `#/panel/cobros`. En producción la URL será la del hosting (ej. `https://tu-dominio.com/#/panel/reportes`).

### Autenticación (Supabase Auth) para administradores

Para restringir el panel a administradores:

1. **Supabase Dashboard:** En Authentication → Providers habilita Email o el método que uses. Crea usuarios admin.
2. **En la app (panel):** Antes de mostrar datos, comprobar sesión con `Supabase.instance.client.auth.currentUser`. Si no hay sesión, redirigir a una pantalla de login que use `Supabase.instance.client.auth.signInWithPassword()` (o `signInWithOAuth()` para proveedores sociales).
3. **RLS en Supabase:** Crea políticas que permitan **SELECT** en `reportes_semanales`, `licencias` y `cobros` solo cuando el usuario esté autenticado y sea admin (por ejemplo con un claim `role = 'admin'` en el JWT o una tabla `admins` que liste `user_id`). La app POS móvil/desktop sigue usando `CLIENTE_ID` y no requiere login de usuario.

Documentación: [Supabase Auth](https://supabase.com/docs/guides/auth).

### Despliegue del panel (web)

1. **Build web:**
   ```bash
   flutter build web
   ```
   Salida en `build/web/` (incluye `index.html`, `main.dart.js`, assets).

2. **Desplegar en Firebase Hosting (ejemplo):**
   - Instala Firebase CLI: `npm install -g firebase-tools`
   - Inicia sesión: `firebase login`
   - En la raíz del proyecto: `firebase init hosting` → directorio público: `build/web`, single-page app: Yes
   - Tras cada build: `flutter build web && firebase deploy`
   - Opcional: configura un dominio en la consola de Firebase.

   Alternativas: **Vercel**, **Netlify** o cualquier hosting estático: sube el contenido de `build/web/` y configura la SPA para que todas las rutas devuelvan `index.html` (base href `/` o el que uses).

3. **Variables de entorno en web:** Para que Supabase funcione en producción web, configura `SUPABASE_URL` y `SUPABASE_ANON_KEY` en build time (por ejemplo con `--dart-define`) o mediante un backend que inyecte la config; el panel usa el mismo cliente Supabase que el resto de la app.

## Getting Started

This project is a starting point for a Flutter application.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

## Tests

Ejecutar todos los tests (sin credenciales reales; los tests de licencia y splash usan mocks):

```bash
flutter test
```

## Arquitectura del proyecto

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

- Los services son estáticos y combinan lógica de negocio con acceso a datos (sin Repositories ni ViewModels separados).
