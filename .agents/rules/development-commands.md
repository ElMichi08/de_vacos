# Development Commands

## Build & Run

| Comando | Propósito |
|---------|-----------|
| `flutter pub get` | Instalar dependencias |
| `flutter test` | Ejecutar todos los tests (67 tests, sin credenciales reales) |
| `flutter run` | Ejecutar en dispositivo/emulador conectado |
| `flutter run -d chrome` | Ejecutar panel web admin en navegador |
| `flutter analyze` | Análisis estático de Dart |
| `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=CLIENTE_ID=...` | Build producción Android |
| `flutter build apk --obfuscate --split-debug-info=build/symbols` | Build ofuscado para release |

**Importante:** Correr `flutter test` y `flutter analyze` antes de cada commit.

## Testing

### Estructura actual
- **Tests de servicios** (8 suites, 67+ tests): `test/services/` -- `caja_service_test`, `pedido_service_test`, `pedido_service_extended_test`, `producto_service_test`, `insumo_service_test`, `ventas_service_test`, `numero_orden_test`, `db_helper_test`.
- **Tests de boot/router**: `test/app_boot_test.dart`, `test/app_router_extra_casting_test.dart`, `test/supabase_sync_empty_cliente_test.dart`.
- **Pendientes:** `test/screens/` y `test/widgets/` existen pero están vacíos.

### Patrón de DB para tests
Los tests de licencia y splash usan mocks. Para tests que usan SQLite real:
- Cada `tearDown` limpia la BD asincrónicamente mediante `DBHelper.deleteTestDb()`, evitando bloqueos de archivos `.db`.
- Se soporta `testDbPathOverride` para aislar la base de datos en tests.

### Reglas
- Correr `flutter test` completo antes de mergear.
- Agregar o actualizar tests para el código que cambies, incluso si nadie lo pidió.
- Corregir errores de test o tipo hasta que la suite esté verde.