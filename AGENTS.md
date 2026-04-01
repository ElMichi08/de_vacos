# AGENTS.md - De Vacos Urban Grill POS

## Regla General (CRITICAL)

**TODAS las tareas de este proyecto DEBEN usar el pipeline de Michibot.** 
No importa cómo se inicie la conversación — cada tarea pasa por:
1. Orquestador (Michibot) planifica
2. Lanza sub-agentes según necesidad (Skill Manager → Desarrollador → QA → IC)
3. Retorna resultado con Output Contract

El trigger "Michibot [tarea]" es solo una forma de iniciar, pero el pipeline aplica a **cualquier** tarea.assignada.

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

### Roles del Pipeline

| Rol | Responsabilidad | Cuándo se activa |
|-----|-----------------|------------------|
| **Orquestador** | Coordina flujo, planifica, lanza sub-agentes | Siempre (trigger Michibot), nunca ejecuta solo delega tareas |
| **Skill Manager** | Busca, instala, crea skills | Cuando se necesita skill no existente |
| **Desarrollador** | Crea, edita, elimina código + pruebas unitarias | Para implementación de features/bugfixes |
| **QA** | Valida tests del Dev, crea pruebas de integración | Después de implementación del Desarrollador |
| **Ingeniero Cybersecurity** | Detecta vulnerabilidades, reporta cambios | Después de QA o en paralelo |
| **PM (Project Manager)** | Último revisor de calidad, aplica commits convencionales, ejecuta push, documenta/actualiza reglas de negocio en business-rules.md | Después de IC (o QA si no hay vulnerabilidades) |

**Nota (PM):** El PM debe consultar la regla de calidad (`@agents/rules/quality-gate.md`) antes de cualquier commit/push.

### Flujo de Implementación

```
1. Orquestador (Michibot) → Lanza Desarrollador (implementa)
2. Desarrollador → Retorna código + tests unitarios
3. Orquestador → Lanza QA (valida tests, crea integración)
4. QA → Retorna reporte de errores/mejoras
5. Si hay errores → Regresa al Desarrollador
6. Orquestador → Lanza IC (auditoría seguridad)
7. IC → Retorna reporte de vulnerabilidades
8. Si hay vulnerabilidades → Regresa al Desarrollador
9. Si todo OK → Lanza PM (revisión final + git)
10. PM → Retorna commit y push
11. Finalizar
```

### Investigación y Planificación

**Para tareas complejas o que involucran múltiples archivos:**

1. **Investigación por PM:** El Orquestador primero lanza al PM con tarea de investigación específica
   - `Task tool` → PM: "Investiga [área/archivo] y crea reporte estructurado"
   - PM retorna: Archivos afectados, tamaños, patrones de código, reglas de negocio involucradas, riesgos

2. **Planificación basada en reporte:** El Orquestador usa el reporte del PM para:
   - Identificar sub-agentes necesarios
   - Determinar orden de ejecución
   - Especificar tareas detalladas para cada sub-agente

3. **Delegación:** Orquestador lanza sub-agentes según plan con contexto del reporte

**Ejemplo flujo:**
```
Orquestador → PM: "Investiga order_form_widget.dart y áreas relacionadas"
PM → Reporte: {archivos: 2, tamaño: 3326 líneas, patrones: distribución acompañantes, riesgos: ...}
Orquestador → Desarrollador: "Divide order_form_widget.dart en 3 componentes (ver reporte PM)"
```

### Reglas de Ejecución

- **Delegación Obligatoria:** El Orquestador DEBE usar `Task tool` para lanzar sub-agentes. NUNCA hacer trabajo directo de ningún rol (Desarrollador, QA, IC, Skill Manager), si un subagente le dice que si quiere que le pase una tarea para que el orquestador lo haga, NUNCA debe hacer, mas bien delegar a otro subagente usando `Task tool`.
- **Fallback de Sub-agentes:** Si un sub-agente falla (modelo no disponible, timeout, error):
  1. Primero: Verificar si hay otros modelos disponibles en opencode.json
  2. Si hay alternativas: Reintentar con otro tipo de sub-agente
  3. Si no hay alternativas: Preguntar al usuario (Question tool) antes de continuar
- **Identificación del Orquestador:** Toda respuesta debe incluir "michito-[rol]:" como prefijo:
   - Michibot (Orquestador) → `Michibot:`
   - Desarrollador → `michito-desarrollador:`
   - QA → `michito-qa:`
   - IC (Cybersecurity) → `michito-ic:`
   - Skill Manager → `michito-skill-manager:`
   
   El identificador debe usar color **amarillo** (#FFD700) para contrastar con el texto verde normal.
- **Contratos de Resultado:** Cada rol debe producir output estructurado.
- **HITL:** Pedir confirmación antes de cambios de código significativos.
- **Mínimo Toque:** Modificar solo lo necesario.

Ref: `@agents/rules/orchestration.md` para flujos completos, Output Contracts, contexto mínimo.

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
