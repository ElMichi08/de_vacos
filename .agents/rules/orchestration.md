---
trigger: model_decision
---

# Agent Orchestration (Pipeline Optimizado)

Basado en best practices de Anthropic Claude Code.

## Principios Fundamentales

1. **Explorar antes de planificar** — Claude Code patrón: Explore → Plan → Implement
2. **Delegar cuando sea necesario** — No todas las tareas necesitan sub-agentes
3. **Contexto óptimo** — Solo lo necesario, no todo el codebase
4. **Skills on-demand** — Cargar solo cuando el sub-agente lo necesite
5. **Pipeline adaptativo** — No todas las tareas necesitan todas las fases

## Roles (3 fases)

- **Orquestador:** Coordina flujo, planifica con `TodoWrite`, lanza sub-agentes. NUNCA escribe código directamente.
- **Desarrollador:** Implementa código + tests unitarios. Puede ser "fast-track" para tareas simples.
- **PM:** Revisión final, commits, documentación.

> **Nota:** Skill Manager, QA, IC se lanzan **solo cuando son necesarios**, no siempre.

## Pipeline Estándar (3 fases)

```
1. Orquestador → Analiza tarea
                    ↓
2. Exploración (opcional) → Fase de análisis para tareas complejas
                    ↓
3. Desarrollador → Implementa + tests
                    ↓
4. PM → Revisión + commit
```

## Pipeline Fast-Track (para tareas simples)

Para tareas simples (fix de typo, small refactor, rename), el Orquestador puede ir directo:

```
Orquestador → Desarrollador (fast-track) → PM
```

Criterios fast-track:
- Cambios en un solo archivo
- < 10 líneas de código
- Sin cambios en arquitectura
- Sin nuevos tests requeridos

## Fase de Exploración (Plan Mode)

Para tareas complejas, el Orquestador debe PRIMERO explorar antes de delegar:

```
1. Lanzar sub-agente "Explore" para investigar el codebase
2. Generar plan basado en hallazgos
3. Delegar implementación con contexto claro
```

**Cuándo usar:**
- Nuevas features que afectan múltiples archivos
- Bugfix que requiere entender el contexto
- Refactorización significativa

## Identificación de Roles

> **Eliminado:** Prefijos "michito-[rol]:" con colores. Esto es noise.

Los sub-agentes se identifican naturalmente:
- PM reporta: "## Revisión final"
- Desarrollador reporta: "## Implementación"
- Exploración reporta: "## Hallazgos"

No se requiere prefijo visual. El contexto de la respuesta indica el rol.

## Skills: On-Demand, No Pre-cargadas

**Antes (problemático):** Skills pre-cargadas en todos los sub-agentes.

**Ahora (optimizado):** El sub-agente CARGA la skill cuando la necesita.

**Cómo especificar:**
```
Tarea: Implementar nuevo widget
Skills requeridas: flutter-expert, flutter-dart-code-review
```

El sub-agente debe cargar las skills explícitamente al inicio.

## Contexto Mínimo para Sub-agentes

Al instanciar un sub-agente:

1. **Solo archivos relevantes** — No todo el codebase
2. **Constraints del proyecto** — Mencionar reglas críticas
3. **Output contract esperado** — Indicar formato de respuesta
4. **Skills a cargar** — Cuál/necesaria

**Ejemplo:**
```
Tarea: Tests para InsumoService
Archivos: lib/services/insumo_service.dart, lib/models/insumo.dart
Constraints: Tests con SQLite real, tearDown = DBHelper.deleteTestDb()
Skills: flutter-testing-apps
Output: Contrato de Implementación
```

## Output Contracts (Simplificados)

### Exploración
```
## Hallazgos
- [hallazgo]

## Archivos relevantes
- path/file.dart

## Recomendación
[acción sugerida]
```

### Implementación
```
## Cambios
- [archivo]: [qué se cambió]

## Tests
- [N] unitarios ejecutados
- flutter test: [PASS/FAIL]

## Verificación
- flutter analyze: [0 issues / N]
```

### PM / Git
```
## Revisión
- Código cumple estándares: [✓/✗]
- Tests pasan: [✓/✗]

## Commit
- [hash] — [mensaje]
```

## Post-Validación del Orquestador

1. **Verificar contrato** — Output cumple formato esperado
2. **flutter analyze** — 0 issues requeridos
3. **flutter test** — Todos pasan
4. **Guardar Engram** — Decisiones, bugs, descubrimientos
5. **Actualizar TodoWrite** — Marcar completada

**Regla de 3 intentos:** Si sub-agente falla 3x consecutivas → pedir dirección al usuario.

## Herramientas del Pipeline

| Herramienta | Uso |
|-------------|-----|
| `Task tool` | Lanzar sub-agentes |
| `TodoWrite` | Planificación y tracking |
| `Question tool` | Human Gates (HITL) |
| `Engram` | Persistir decisiones |

---

## Cuándo Lanzar Cada Agente

### Skill Manager (solo si necesita nueva skill)
- Usuario pide algo sin skill existente
- Tarea requiere dominio especializado

### QA (solo si hay tests complejos)
- Nueva funcionalidad con múltiples escenarios
- Necesita tests de integración

### IC (solo para cambios de seguridad)
- Autenticación/autorización nueva
- Manejo de datos sensibles

### Desarrollador (siempre)
- Implementación de código
- Tests unitarios

### PM (siempre)
- Revisión final
- Commit y push

---

## Ejemplo de Flujo Optimizado

**Tarea simple:** "Corregir typo en README"
```
Orquestador → Desarrollador (fast-track) → PM
```

**Tarea compleja:** "Implementar dark mode"
```
Orquestador → Exploración → Plan → Desarrollador → PM
```

**Tarea con nueva skill:** "Agregar OAuth"
```
Orquestador → Skill Manager → Instala skill → Desarrollador (con nueva skill) → PM
```

---

## Legacy: Agentes Originales (Referencia)

Los agentes QA, IC, Skill Manager siguen disponibles pero NO son obligatorio en el pipeline estándar.

- **QA:** Útil para testing complejo
- **IC:** Útil para cambios de seguridad críticos
- **Skill Manager:** Útil cuando necesitas una skill que no existe