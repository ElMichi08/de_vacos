# AGENTS.md - De Vacos Urban Grill POS

## Regla General

**Este proyecto usa un pipeline OPTIMIZADO basado en best practices de Anthropic Claude Code.**

El pipeline tiene 3 fases (no 6):
1. Orquestador planifica y decide tipo de tarea
2. Desarrollador implementa + tests (fast-track o normal)
3. PM revisión final + commit

El trigger "Michibot [tarea]" inicia el flujo.

---

## 1. Project Overview

App POS (Point of Sale) multiplataforma para "De Vacos Urban Grill", construida con **Flutter/Dart**.
    
- **Local-first:** SQLite como base de datos principal (`db_helper.dart`, migraciones v7).
- **Cloud sync:** Supabase para licencias, reportes semanales y cobros.
- **Panel web admin:** Vistas read-only en `/panel/*` para administradores.
- **Impresión térmica:** Subsistema con transporte abstracto (USB/Bluetooth).
- **Branding dinámico:** Configurable via `assets/config/branding.json`.
- **Imagen opcional:** Los productos pueden crearse sin imagen (v7 migration).
- **Validación de estados:** Pedidos no pueden cerrarse sin estar cobrados.

Para detalles extendidos, ver **[README.md](README.md)**.

## 2. Dev Setup

**Requisitos:** Flutter SDK 3+, Dart, Android Studio / VS Code.

**Setup:** `flutter pub get`

**CRITICAL:** Load @agents/rules/*.md only when the specific task requires it. Do NOT load all instructions preemptively.

## 3. Commands

| Comando | Propósito |
|---------|-----------|
| `flutter pub get` | Instalar dependencias |
| `flutter test` | Ejecutar tests |
| `flutter run` | Ejecutar en dispositivo/emulador |
| `flutter analyze` | Análisis estático |
| `flutter build apk` | Build producción Android |

Ref: `@agents/rules/development-commands.md` para detalles completos.

## 4. Testing

- **Tests existentes:** 67+ tests en `test/services/` y `test/`
- **Pendientes:** `test/screens/` y `test/widgets/` vacíos

Ref: `@agents/rules/development-commands.md` para estructura y reglas.

## 5. Architecture

- **Models:** `lib/models/` — DTOs (Pedido, Producto, Caja, Insumo, etc.)
- **Services:** `lib/services/` — Lógica de negocio estática
- **Database:** `lib/core/database/` — SQLite con migraciones v6
- **Screens:** `lib/screens/` — 13 pantallas
- **Widgets:** `lib/widgets/` — 16 componentes
- **Routing:** GoRouter (NUNCA usar Navigator.of(context).pushReplacement)

Ref: `@agents/rules/architecture.md` para deuda técnica y detalles.

## 6. Security

- **Debug:** `.env` con SUPABASE_URL, SUPABASE_ANON_KEY, CLIENTE_ID
- **Release:** Usar `--dart-define` en build time
- **NUNCA commitear** `.env` ni credenciales reales
- **Licencias:** Periodo de gracia 14 días sin internet

**OWASP:** Para auditorías de seguridad, cargar skill `@sergiodxa/agent-skills/owasp-security-check`

Ref: `@agents/rules/security.md` para detalles completos.

## 6.5 Business Rules
Para reglas de negocio críticas ver: `.agents/rules/business-rules.md`

**Guía para el Orquestador:** Al delegar tareas que involucren reglas de negocio, identifica las categorías relevantes (Pedidos, Inventario, Caja, Reportes, Validaciones, Impresión, Sincronización) basándote en los archivos/modulos afectados. Especifica en la tarea del sub-agente: "Consulta las reglas en las secciones [categorías] de business-rules.md".

**Mapeo rápido:**
- Archivos que contienen "pedido" o "order" → Pedidos, Validaciones
- Archivos que contienen "insumo" o "stock" → Inventario, Validaciones
- Archivos que contienen "caja" o "cash" → Caja
- Archivos que contienen "report" o "audit" → Reportes
- Archivos que contienen "product" o "modelo" → Validaciones de Modelos
- Archivos que contienen "print" o "ticket" → Impresión
- Archivos que contienen "sync" o "supabase" → Sincronización

**Responsabilidad del PM:** Documentar y actualizar reglas de negocio en `business-rules.md` cuando haya cambios en el código que afecten reglas existentes o se agreguen nuevas. Referenciar observaciones de Engram (IDs) para mantener contexto histórico.

## 8. Skills Registry

Las skills se cargan **únicamente** en sub-agentes, nunca en el Orquestador.

| Necesitas... | Skill | Ubicación |
|---|---|---|
| Estructura de capas Flutter | `flutter-architecting-apps` | `.agents/skills/` |
| Widgets, state, routes, performance | `flutter-expert` | `.agents/skills/` |
| Unit / widget / integration tests | `flutter-testing-apps` | `.agents/skills/` |
| SQLite, migraciones, queries | `flutter-working-with-databases` | `.agents/skills/` |
| Caching local, shared_preferences | `flutter-caching-data` | `.agents/skills/` |
| Code review Dart/Flutter | `flutter-dart-code-review` | `.agents/skills/` |
| Principios de diseño Clean Code, SOLID, DRY | `flutter-clean-solid-dry` | `.agents/skills/` |
| Migraciones SQLite centralizadas (PRAGMA/ALTER) | `flutter-sqlite-migrations` | `.agents/skills/` |
| Build nativo iOS/Android | `senior-mobile` | `.agents/skills/` |
| Auditorías OWASP Top 10 | `owasp-security-check` | `.agents/skills/` |
| Descubrir e instalar skills | `find-skills` | `.agents/skills/` |
| Git commit messages | `git-commit` | `.agents/skills/` |
| GitHub CLI | `gh-cli` | `.agents/skills/` |
| Documentación de código y README | `code-documenter` | `.agents/skills/` |
| Testing QA patterns | `qa-expert` | `.agents/skills/` (instalada) |
| Security review | `security-review` | `.agents/skills/` (instalada) |
| Revisión de calidad | `quality-gate` | `.agents/rules/quality-gate.md` |

### Skill Manager Agent

**Propósito:** Gestionar el ciclo de vida de skills — buscar, instalar, crear y documentar.

**Cuándo se activa:** Cuando el Orquestador detecta que no existe skill para una tarea en el registry.

**Flujo completo:** Ver `@agents/rules/orchestration.md#skill-manager`.

**Lineamientos para crear skills propias:**
- **Calidad de código:** Aplicar reglas de `flutter-dart-code-review`
- **Seguridad:** Aplicar reglas de `owasp-security-check`

**Persistencia:** Toda acción se guarda en Engram (mem_save).

## 9. Orchestration

### Pipeline Optimizado (3 fases)

| Fase | Responsable | Cuándo se activa |
|------|-------------|------------------|
| **1. Orquestador** | Coordina flujo, planifica, decide tipo de tarea | Siempre (trigger Michibot) |
| **2. Desarrollador** | Implementa + tests unitarios | Siempre (Implementa) |
| **3. PM** | Revisión final, commit, push | Después de implementación |

**Fast-Track:** Tareas simples (< 10 líneas, un archivo) van directo:
```
Orquestador → Desarrollador (fast-track) → PM
```

**Con Exploración:** Tareas complejas (múltiples archivos, nueva feature):
```
Orquestador → Exploración → Plan → Desarrollador → PM
```

**Agentes opcionales** (solo cuando son necesarios):
- **Skill Manager:** Cuando necesitas una skill que no existe
- **QA:** Para testing complejo con integración
- **IC:** Para cambios de seguridad críticos

### Reglas de Ejecución

- **Delegación Obligatoria:** El Orquestador DEBE usar `Task tool` para lanzar sub-agentes.
- **Identificación de roles:** Eliminados los prefijos "michito-[rol]:" con colores. Los agentes se identifican por el contexto de su respuesta.
- **Contratos de Resultado:** Cada rol debe producir output estructurado.
- **HITL:** Pedir confirmación antes de cambios significativos.
- **Mínimo Toque:** Modificar solo lo necesario.

> **Nota:** Los agentes QA, IC, Skill Manager siguen disponibles pero NO son obligatorio en el pipeline estándar. Ver `.agents/rules/orchestration.md` para detalles.

## 10. Engram

Sistema de memoria persistente para reducir pérdida de contexto.

- **Guardar:** Después de bugfix, decisiones arquitectónicas, descubrimientos.
- **Buscar:** Al inicio de sesión (`mem_context`), antes de tareas (`mem_search`).
- **Cerrar:** Siempre ejecutar `mem_session_summary`.

Ref: `@agents/rules/engram.md` para formato y reglas.

## 11. Intake Protocol (Michibot)

### Trigger
Usuario dice: "Michibot [tarea]"

### Flujo
1. **Analizar** — Deducir: tipo (feature/bug/refactor/testing), objetivo, alcance
2. **Confirmar** — Si hay ambigüedad, UNA pregunta clarificadora
3. **Ejecutar** — Lanzar sub-agentes según plan

### Regla
- Objetivo claro → ejecutar directo
- Ambigüedad → UNA pregunta, no 4
- "sí, proceed" → skipear confirmación

### Ejemplo
- "Michibot agrega dark mode al Settings" → ejecutar
- "Michibot arregla el bug de pagos" → confirmar alcance antes


-Fix all bugs
opencode -s ses_2c03464e4ffer0LsP2ZB2T5hHH

-Toneks
opencode -s ses_2bffca113ffe0GhxLZ5TQshefH
