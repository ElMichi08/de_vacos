# AGENTS.md - De Vacos Urban Grill POS

## 1. Project Overview

App POS (Point of Sale) multiplataforma para "De Vacos Urban Grill", construida con **Flutter/Dart**.

- **Local-first:** SQLite como base de datos principal (`db_helper.dart`, migraciones v6).
- **Cloud sync:** Supabase para licencias, reportes semanales y cobros.
- **Panel web admin:** Vistas read-only en `/panel/*` para administradores.
- **Impresión térmica:** Subsistema con transporte abstracto (USB/Bluetooth).
- **Branding dinámico:** Configurable via `assets/config/branding.json`.

Para detalles extendidos (despliegue, RLS, panel web, auth admin), ver **[README.md](README.md)**.

## 2. Dev Environment & Setup

**Requisitos:** Flutter SDK 3+, Dart, Android Studio / VS Code.

**Setup inicial:**
```bash
flutter pub get
```

**Variables de entorno (desarrollo):**
Crear `.env` en la raíz con:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
CLIENTE_ID=...
```
Referencia: `env.example`. El archivo `.env` **no se incluye en el bundle** de release; solo se carga en modo debug.

## 3. Build & Run Commands

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

## 4. Testing Instructions

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

## 5. Code Conventions & Architecture

### Capas del proyecto

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

Para tabla completa con alineación a skill flutter-architecting-apps, ver **[README.md](README.md)**.

### Reglas de enrutamiento (GoRouter)

Toda navegación global usa `MaterialApp.router` con `GoRouter`.

- **USAR:** `context.go('/ruta')`, `context.push('/ruta')` y funciones nativas de GoRouter.
- **NUNCA USAR:** `Navigator.of(context).pushReplacement(...)` -- desincroniza el historial de GoRouter, forzando recargas accidentales de la raíz (`/splash`) al navegar hacia atrás o ejecutar `context.pop()`.

### Base de datos local (SQLite)

- Tablas: `productos`, `pedidos`, `caja_movimientos`, `insumos`, `receta_detalle`.
- Migraciones incrementales en `lib/core/database/db_helper.dart` (versión actual: 6).
- Singleton pattern con soporte de `testDbPathOverride` para tests.

### Numeración de órdenes

`obtenerSiguienteNumeroOrden()` calcula `(MAX(numeroOrden) del día % 100) + 1`. Se reinicia automáticamente al pasar 100 pedidos o al cambiar de día.

### Print Service

Los layouts de tickets (`lib/services/printer/ticket_builder.dart`) usan escalado de logo dinámico al 50% y fuentes estandarizadas (`PosTextSize.size2`).

### Deuda técnica identificada

- Services son estáticos y combinan lógica de negocio con acceso a datos (sin Repositories ni ViewModels separados).
- Directorios `test/screens/` y `test/widgets/` vacíos.

## 6. Security & Environment Variables

- **Debug:** `.env` en raíz con `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `CLIENTE_ID`. Se carga desde disco solo en debug.
- **Release:** Usar `--dart-define` en build time. No se usa dotenv.
- **NUNCA commitear** `.env` ni archivos con credenciales reales.
- **Licencias:** Verificación al iniciar. Periodo de gracia sin internet: 14 días (configurable en `lib/core/constants/security_constants.dart`).
- **Reportes:** Envío en segundo plano (total ventas, pedidos, top 3 productos). Un fallo de envío no bloquea al usuario.
- **Ofuscación en release:** `build/symbols` no se sube al repositorio.

Detalle completo: **[docs/LICENCIAS_Y_REPORTES.md](docs/LICENCIAS_Y_REPORTES.md)**.

## 7. Skills Registry

Las skills se encuentran en `.agents/skills/` y se cargan **únicamente** en sub-agentes dedicados, nunca en el Orquestador, para mantener el contexto limpio.

| Necesitas... | Skill | Ubicación |
|---|---|---|
| Definir/validar estructura de capas Flutter (UI -> Logic -> Data) | `flutter-architecting-apps` | `.agents/skills/flutter-architecting-apps/` |
| Implementar widgets, state management, routes, performance | `flutter-expert` | `.agents/skills/flutter-expert/` |
| Escribir unit / widget / integration tests | `flutter-testing-apps` | `.agents/skills/flutter-testing-apps/` |
| SQLite, drift, sqflite, migraciones, queries optimizados | `flutter-working-with-databases` | `.agents/skills/flutter-working-with-databases/` |
| Caching local, shared_preferences, estrategias de invalidación | `flutter-caching-data` | `.agents/skills/flutter-caching-data/` |
| Code review automatizado, análisis de calidad Dart/Flutter | `flutter-dart-code-review` | `.agents/skills/flutter-dart-code-review/` |
| Build nativo iOS/Android, React Native, store submissions | `senior-mobile` | `.agents/skills/senior-mobile/` |

**Skills eliminadas:** `senior-architect` (genérico multi-stack, no aporta a Flutter puro), `flutter-clean-arch` (prescribe Riverpod + Dio/Retrofit, no alineado con la arquitectura actual del proyecto).

**Regla:** El Orquestador nunca carga skills directamente. Instancia un sub-agente efímero con `Task tool` y le indica qué skill cargar. Esto mitiga el "Context Overload".

## 8. Agent Orchestration (SDD Pipeline)

### Roles

Este proyecto utiliza una arquitectura multi-agente:

- **Orquestador Principal (SDD Orchestrator):** **NUNCA** hace trabajo real ni escribe código directamente. Su rol es coordinar el flujo, instanciar sub-agentes efímeros (con contexto limpio) mediante `Task tool`, delegar la ejecución, y validar los resultados. Usa `TodoWrite` para planificación y tracking visible al usuario.
- **Arquitecto / Documentador:** Sub-agente responsable de explorar el estado del repositorio, diseñar la estructura del proyecto (con skill `flutter-architecting-apps`), y actualizar documentación (`README.md`, estado arquitectónico) para evitar pérdida de contexto.
- **Implementers (Spec Writer / Testing / Resolución):** Sub-agentes efímeros levantados bajo demanda para ejecutar tareas aisladas. Cada uno recibe un prompt detallado con el contexto mínimo necesario.

### Reglas de ejecución

1. **Contratos de Resultado:** Cada sub-agente debe producir un output estructurado (plan en markdown, informe de errores, diff de cambios) que sirva como input para la siguiente fase. Sin contratos, no hay orquestación.

2. **Puntos de Aprobación Humana (HITL):** El Orquestador DEBE detenerse y pedir confirmación al humano (usando `Question tool`) antes de:
   - Desplegar sub-agentes de implementación que modifiquen código.
   - Sobreescribir arquitectura clave o decisiones de diseño.
   - Eliminar o refactorizar componentes existentes.

3. **Mínimo Toque:** Los agentes de resolución deben modificar estrictamente lo necesario, aplicando principios SOLID y DRY, sin afectar la lógica de negocio circundante.

### Output Contracts (obligatorios)

Cada sub-agente DEBE retornar su resultado en un formato estructurado según el tipo de tarea. El Orquestador NO procesa resultados que no cumplan el contrato.

**Exploración / Análisis:**
```
## Hallazgos
- [hallazgo 1]
- [hallazgo 2]

## Archivos relevantes
- path/to/file.dart — [qué hace o qué se encontró]

## Recomendación
[acción sugerida en 1-2 oraciones]
```

**Implementación / Bugfix:**
```
## Cambios realizados
- [archivo]: [qué se cambió y por qué]

## Tests
- [nuevo/modificado]: [qué valida]
- Resultado: [PASS/FAIL + count]

## Verificación
- `flutter analyze`: [0 issues / N issues]
- `flutter test`: [N passed / N failed]
```

**Code Review:**
```
## Severidad: [CRITICAL / WARNING / INFO]
## Problemas encontrados
1. [archivo:línea] — [descripción del problema]

## Sugerencias
- [mejora propuesta]

## Veredicto: [APROBADO / REQUIERE CAMBIOS]
```

### Contexto mínimo para sub-agentes

Al instanciar un sub-agente con `Task tool`, el Orquestador DEBE seguir estas reglas para optimizar tokens:

1. **Solo incluir archivos relevantes** — NO enviar todo el codebase. Especificar paths exactos que el sub-agente necesita leer o modificar.
2. **Incluir constraints del proyecto** — Mencionar reglas críticas (ej: "usar GoRouter, nunca Navigator", "Services son estáticos", "DB migrations en db_helper.dart v6").
3. **Especificar el output contract esperado** — Indicar qué formato de respuesta se espera (ver sección anterior).
4. **Indicar skill a cargar** — Si aplica, decir explícitamente qué skill debe cargar el sub-agente (ej: "Carga la skill `flutter-testing-apps` antes de empezar").
5. **NO duplicar AGENTS.md completo** — El sub-agente ya tiene acceso al archivo vía system prompt. Solo referenciar secciones específicas si es necesario.

**Ejemplo de prompt óptimo para sub-agente:**
```
Tarea: Escribir tests unitarios para InsumoService.
Archivos a leer: lib/services/insumo_service.dart, lib/models/insumo.dart, test/services/pedido_service_test.dart (como referencia de patrón).
Constraints: Tests usan SQLite real con testDbPathOverride. tearDown debe llamar DBHelper.deleteTestDb(). No usar mocks para DB.
Skill: Carga `flutter-testing-apps`.
Output esperado: Contrato de Implementación (ver sección 8 de AGENTS.md).
```

### Post-validación del Orquestador

Después de recibir el resultado de un sub-agente, el Orquestador DEBE ejecutar estos pasos antes de dar la tarea por completada:

1. **Verificar contrato** — ¿El output del sub-agente cumple el formato del Output Contract esperado? Si no, rechazar y re-delegar con instrucciones más claras.
2. **Correr `flutter analyze`** — Verificar 0 issues. Si hay issues nuevos, crear sub-agente de resolución para corregirlos.
3. **Correr `flutter test`** — Verificar que todos los tests pasan (incluyendo los nuevos). Si hay fallos, crear sub-agente de resolución.
4. **Guardar en Engram** — Si la tarea involucró una decisión arquitectónica, bugfix, o descubrimiento, llamar `mem_save` inmediatamente.
5. **Actualizar TodoWrite** — Marcar la tarea como `completed` y reportar al usuario.

**Regla de 3 intentos:** Si un sub-agente falla la post-validación 3 veces consecutivas, el Orquestador DEBE detenerse, reportar el problema al usuario con `Question tool`, y pedir dirección.

### Herramientas del pipeline

| Herramienta | Uso en el pipeline |
|---|---|
| `Task tool` | Instanciar sub-agentes efímeros con contexto limpio |
| `TodoWrite` | Planificar tareas, tracking de progreso visible al usuario |
| `Question tool` | Implementar Human Gates (HITL) |
| `Engram (mem_*)` | Persistir decisiones, bugs, descubrimientos entre sesiones |

## 9. Engram (Persistent Memory)

El proyecto usa **Engram MCP** para persistir aprendizajes y reducir la pérdida de contexto entre sesiones.

### Cuándo guardar (`mem_save`)
- Después de cada bugfix completado.
- Después de cada decisión arquitectónica o de diseño.
- Al descubrir algo no obvio del codebase.
- Al cambiar configuración o setup.
- Al establecer un patrón o convención nueva.

### Cuándo buscar (`mem_search` / `mem_context`)
- Al inicio de cada sesión: `mem_context` para recuperar contexto reciente.
- Antes de trabajar en algo que pudo haberse hecho antes: `mem_search` con keywords.
- Cuando el usuario menciona un tema sin contexto previo.

### Al cerrar sesión (`mem_session_summary`)
**Obligatorio.** Guardar resumen estructurado con: Goal, Instructions, Discoveries, Accomplished, Next Steps, Relevant Files.

## 10. Intake Protocol (Michibot)

### Trigger
Cuando el usuario diga **"Michibot tengo una nueva tarea"**, el Orquestador DEBE ejecutar el siguiente protocolo de intake ANTES de hacer cualquier otra cosa.

### Paso 1: Recuperar contexto (automático, no mostrar al usuario)
- Ejecutar `mem_context` para recuperar sesiones recientes.
- Ejecutar `mem_search` con keywords relevantes del proyecto para traer decisiones y aprendizajes previos.
- Este paso es interno; no mostrar el resultado al usuario.

### Paso 2: Recopilar información (Question tool)
Hacer las siguientes preguntas al usuario usando `Question tool` en una sola invocación:

**Pregunta 1 - Tipo de tarea:**
Opciones:
- Feature nueva
- Bugfix
- Refactor / Deuda técnica
- Testing
- Investigación / Análisis
- Documentación

**Pregunta 2 - Objetivo:**
(Campo libre) "Describí brevemente qué necesitas lograr."

**Pregunta 3 - Alcance:**
(Campo libre) "Qué archivos o módulos están involucrados? Hay algo que NO deba tocarse?"

**Pregunta 4 - Nivel de autonomía:**
Opciones:
- Máximo control: mostrar plan completo antes de tocar cualquier archivo
- Moderado: pedir aprobación solo antes de cambios críticos (Recommended)
- Alta autonomía: implementar sin aprobación intermedia, mostrar resultado final

### Paso 3: Planificar (TodoWrite)
Con las respuestas del Paso 2, el Orquestador:
1. Crea un plan de tareas estructurado con `TodoWrite`.
2. Identifica qué skills necesitará cada sub-agente (ver sección 7).
3. Presenta el plan al usuario para aprobación (si el nivel de autonomía lo requiere).

### Paso 4: Ejecutar
Lanzar sub-agentes efímeros con `Task tool` según el plan aprobado, respetando las reglas de la sección 8 (contratos de resultado, HITL, mínimo toque).

### Nota sobre modelos
- El **Orquestador (Build)** usa `Claude Opus 4.6 Thinking` para razonamiento complejo y coordinación.
- Los **sub-agentes (General / Explore)** usan `Claude Sonnet 4.6` para ejecución eficiente y ahorro de tokens.
- Esta configuración se define en `opencode.json` del proyecto.
