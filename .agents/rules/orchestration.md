# Agent Orchestration (SDD Pipeline)

## Roles

Este proyecto utiliza una arquitectura multi-agente:

- **Orquestador Principal (SDD Orchestrator):** **NUNCA** hace trabajo real ni escribe código directamente. Su rol es coordinar el flujo, instanciar sub-agentes efímeros (con contexto limpio) mediante `Task tool`, delegar la ejecución, y validar los resultados. Usa `TodoWrite` para planificación y tracking visible al usuario. si un subagente le dice que si quiere que le pase una tarea para que el orquestador lo haga, NUNCA debe hacer, mas bien delegar a otro subagente usando `Task tool`.
- **PM (Project Manager):** Sub-agente responsable de explorar el estado del repositorio, diseñar la estructura del proyecto (con skill `flutter-architecting-apps`), actualizar documentación (README.md, estado arquitectónico) para evitar pérdida de contexto, y actuar como último revisor antes de commits y pushes. Carga las skills `git-commit` (para commits convencionales) y `gh-cli` (para operaciones con GitHub) cuando sea necesario. Valida la calidad del código, aplica estándares de commit, y ejecuta git push tras aprobación del usuario.
- **Implementers (Spec Writer / Testing / Resolución):** Sub-agentes efímeros levantados bajo demanda para ejecutar tareas aisladas. Cada uno recibe un prompt detallado con el contexto mínimo necesario.

## Reglas de ejecución

0. **Delegación Obligatoria:** El Orquestador DEBE usar `Task tool` para lanzar sub-agentes. NUNCA hacer trabajo directo de ningún rol (Desarrollador, QA, IC, Skill Manager).

1. **Identificación del Orquestador:** Toda respuesta debe incluir "michito-[rol]:" como prefijo para que el usuario identifique qué rol responde.
   - Usar color **amarillo** (#FFD700) para el identificador y **verde** para el resto del texto.
   - Roles: `michito-orquestador:`, `michito-desarrollador:`, `michito-qa:`, `michito-ic:`, `michito-skill-manager:`, `michito-pm:`

2. **Contratos de Resultado:** Cada sub-agente debe producir un output estructurado (plan en markdown, informe de errores, diff de cambios) que sirva como input para la siguiente fase. Sin contratos, no hay orquestación.

2. **Puntos de Aprobación Humana (HITL):** El Orquestador DEBE detenerse y pedir confirmación al humano (usando `Question tool`) antes de:
   - Desplegar sub-agentes de implementación que modifiquen código.
   - Sobreescribir arquitectura clave o decisiones de diseño.
   - Eliminar o refactorizar componentes existentes.

3. **Mínimo Toque:** Los agentes de resolución deben modificar estrictamente lo necesario, aplicando principios SOLID y DRY, sin afectar la lógica de negocio circundante.

## Output Contracts (obligatorios)

Cada sub-agente DEBE retornar su resultado en un formato estructurado según el tipo de tarea. El Orquestador NO procesa resultados que no cumplan el contrato.

### Exploración / Análisis
```
## Hallazgos
- [hallazgo 1]
- [hallazgo 2]

## Archivos relevantes
- path/to/file.dart — [qué hace o qué se encontró]

## Recomendación
[acción sugerida en 1-2 oraciones]
```

### Implementación / Bugfix
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

### Code Review
```
## Severidad: [CRITICAL / WARNING / INFO]
## Problemas encontrados
1. [archivo:línea] — [descripción del problema]

## Sugerencias
- [mejora propuesta]

## Veredicto: [APROBADO / REQUIERE CAMBIOS]
```

### PM / Git Admin
```
## Revisión final
- [ ] Código cumple estándares del proyecto
- [ ] Tests pasan (flutter analyze, flutter test)
- [ ] Documentación actualizada si aplica

## Commits aplicados
- [commit hash] — [mensaje convencional]

## Push realizado
- Rama: [branch]
- Commits push: [N]
- Resultado: [SUCCESS / ERROR]

## Notas
[Cualquier observación o recomendación]
```

## Contexto mínimo para sub-agentes

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

## Post-validación del Orquestador

Después de recibir el resultado de un sub-agente, el Orquestador DEBE ejecutar estos pasos antes de dar la tarea por completada:

1. **Verificar contrato** — ¿El output del sub-agente cumple el formato del Output Contract esperado? Si no, rechazar y re-delegar con instrucciones más claras.
2. **Correr `flutter analyze`** — Verificar 0 issues. Si hay issues nuevos, crear sub-agente de resolución para corregirlos.
3. **Correr `flutter test`** — Verificar que todos los tests pasan (incluyendo los nuevos). Si hay fallos, crear sub-agente de resolución.
4. **Guardar en Engram** — Si la tarea involucró una decisión arquitectónica, bugfix, o descubrimiento, llamar `mem_save` inmediatamente.
5. **Actualizar TodoWrite** — Marcar la tarea como `completed` y reportar al usuario.

**Regla de 3 intentos:** Si un sub-agente falla la post-validación 3 veces consecutivas, el Orquestador DEBE detenerse, reportar el problema al usuario con `Question tool`, y pedir dirección.

## Herramientas del pipeline

| Herramienta | Uso en el pipeline |
|---|---|
| `Task tool` | Instanciar sub-agentes efímeros con contexto limpio |
| `TodoWrite` | Planificar tareas, tracking de progreso visible al usuario |
| `Question tool` | Implementar Human Gates (HITL) |
| `Engram (mem_*)` | Persistir decisiones, bugs, descubrimientos entre sesiones |

---

## Skill Manager Agent

### Propósito

Gestionar el ciclo de vida de skills — buscar, instalar, crear y documentar nuevas skills cuando el Orquestador las necesita pero no existen en el registry.

### Cuándo se activa

El Orquestador lanza el Skill Manager Agent cuando:
- El usuario pide ayuda con algo que requiere una skill especializada
- El Orquestador detecta que no existe skill en el registry (sección 7 de AGENTS.md)
- La tarea requiere conocimiento que no está documentado en las skills actuales

### Flujo de Ejecución

```
1. Orquestador detecta necesidad → Lanza Skill Manager Agent

2. Skill Manager Agent:
   a. Carga find-skills
   b. Analiza la necesidad: qué dominio, qué tarea específica
   c. Busca en skills.sh (npx skills find [query])
   d. Verifica calidad (installs > 1000, stars > 100, source oficial)

3. Si encuentra skill adecuada:
   a. Presenta opciones al usuario (Question tool)
   b. Si usuario confirma → Instala: npx skills add <owner/repo@skill> -g -y
   c. Actualiza Skills Registry en AGENTS.md
   d. Persiste en Engram: mem_save

4. Si NO encuentra o usuario rechaza:
   a. Verifica si tiene información suficiente para crear skill propia
   b. Si TIENE suficiente info → Crea skill propia (ver abajo)
   c. Si NO tiene suficiente → Documenta en Engram cómo hacer sin skill

5. Retorna resultado al Orquestador con Output Contract
```

### Criterios de Calidad para Skills Existentes

| Criterio | Mínimo |
|----------|--------|
| Installs | > 1000 |
| Stars | > 100 |
| Source | Oficial (vercel-labs, anthropics, microsoft, sergiodxa) |

### Creación de Skills Propias

**Cuándo crear:** Cuando no existe skill en registry ni en skills.sh Y el agente tiene suficiente información.

**Lineamientos obligatorios:**

| Guideline | Skill de Referencia |
|-----------|---------------------|
| Calidad de código | `flutter-dart-code-review` |
| Seguridad | `owasp-security-check` |

**Proceso de creación:**

```
1. Documentar propósito y casos de uso
2. Aplicar flutter-dart-code-review:
   - Código limpio y siguen patrones Flutter
   - Tests incluidos
   - Documentación clara

3. Aplicar owasp-security-check:
   - Validación de inputs
   - Manejo seguro de secrets
   - Patterns seguros documentados

4. Crear estructura:
   .agents/skills/<nombre>/
   └── SKILL.md

5. Actualizar AGENTS.md (Skills Registry)

6. Persistir en Engram:
   mem_save(title="Skill propia creada: <nombre>",
            type="pattern",
            content="Skill creada en .agents/skills/<nombre>/SKILL.md
                    Lineamientos: flutter-dart-code-review + owasp-security-check")
```

### Estructura de SKILL.md para Skills Propias

```markdown
# <Nombre de Skill>

## Propósito
[Una oración: qué hace esta skill y cuándo usarla]

## Lineamientos aplicados
- flutter-dart-code-review: [cómo se aplicó en código]
- owasp-security-check: [cómo se aplicó en seguridad]

## Casos de uso
- [caso 1 - cuándo usar]
- [caso 2 - cuándo usar]

## Ejemplos
[Ejemplos concretos de uso]

## Restricciones
- [qué NO hace esta skill]
- [cuándo NO usarla]

## Archivos relacionados
[Links a código real del proyecto si aplica]
```

### Output Contract del Skill Manager Agent

```markdown
## Resultado
- Estado: [INSTALADA / CREADA / NO_DISPONIBLE / SIN_SUFICIENTE_INFO]
- Skill: [nombre de la skill]
- Fuente: [skills.sh / Propia / N/A]

## Si se instaló/creó:
- Ubicación: .agents/skills/<nombre>/
- Registro actualizado: [Sí/No]

## Si NO se pudo:
- Razón: [qué pasó]
- Alternativa documentada: [cómo hacer sin skill]

## Engram persistido: [Sí/No]
```

### Ejemplo de Uso

```
Usuario: "Michibot necesito ayuda con autenticación OAuth"

Orquestador: [detecta que no existe skill para OAuth]
→ Lanza Skill Manager Agent

Skill Manager Agent:
1. Busca "oauth authentication" en skills.sh
2. Encuentra oauth-skills de Auth0
3. Presenta al usuario con Question tool
4. Usuario confirma → Instala
5. Actualiza AGENTS.md
6. Persiste en Engram

Skill Manager Agent retorna resultado al Orquestador
Orquestador → Lanza sub-agente con nueva skill cargada
```

### Reglas del Skill Manager Agent

1. **NUNCA instalar skill sin confirmación** del usuario
2. **Siempre persistir** lo aprendido en Engram (mem_save)
3. **Mantener AGENTS.md actualizado** después de cada acción
4. **Si no tiene suficiente info**, documentar en Engram las mejores prácticas de todas formas
5. **Usar lineamientos** (flutter-dart-code-review + owasp-security-check) al crear skills propias

---

## Desarrollador Agent

### Propósito

Crear, editar y eliminar código siguiendo las mejores prácticas de calidad y seguridad. Implementa la funcionalidad solicitada y escribe pruebas unitarias para validar su implementación.

### Cuándo se activa

El Orquestador lanza el Desarrollador después de que el Skill Manager (si fue necesario) ha preparado el contexto.

### Skills requeridas

| Skill | Propósito |
|-------|-----------|
| `flutter-expert` | Widgets, state, routes, performance |
| `flutter-testing-apps` | Unit tests, integration tests |
| `flutter-dart-code-review` | Calidad de código |
| `owasp-security-check` | Lineamientos de seguridad |

### Flujo de Ejecución

```
1. Orquestador → Lanza Desarrollador con contexto de la tarea
2. Desarrollador:
   a. Analiza requisitos
   b. Implementa código
   c. Escribe tests unitarios
   d. Corre flutter analyze y flutter test
3. Retorna resultado con Output Contract
```

### Output Contract del Desarrollador

```markdown
## Implementación
- Archivos modificados/creados: [lista]
- Funcionalidad implementada: [descripción]

## Tests
- Tests unitarios: [N nuevos/modificados]
- flutter test: [N passed / N failed]

## Verificación
- flutter analyze: [0 issues / N issues]
- Estado: [COMPLETADO / CON ERRORES]

## Siguiente paso
- Listo para QA / necesita correcciones
```

### Reglas del Desarrollador

1. **Cargar skills necesarias** antes de empezar (flutter-expert, flutter-testing-apps, flutter-dart-code-review, owasp-security-check)
2. **Escribir tests unitarios** para toda nueva funcionalidad
3. **Ejecutar flutter analyze** antes de retornar (0 issues requeridos)
4. **Ejecutar flutter test** para verificar que no hay regresiones
5. **Aplicar flutter-dart-code-review** para calidad de código
6. **Aplicar owasp-security-check** para validar seguridad

---

## QA Agent

### Propósito

Validar y verificar las pruebas unitarias del Desarrollador, crear pruebas de integración para validar que el módulo actual no rompa nada existente. Reportar errores o fallos encontrados.

### Cuándo se activa

Después de que el Desarrollador retorna su Output Contract.

### Skills requeridas

| Skill | Propósito |
|-------|-----------|
| `flutter-testing-apps` | Testing patterns |
| `find-skills` (opcional) | Si necesita skills de testing adicionales |

### Flujo de Ejecución

```
1. Desarrollador retorna código + tests
2. Orquestador → Lanza QA Agent
3. QA Agent:
   a. Revisa tests unitarios del Desarrollador
   b. Ejecuta tests existentes (verificar no hay regresiones)
   c. Crea tests de integración si es necesario
   d. Reporta errores/fallos encontrados
4. Retorna reporte al Orquestador
```

### Output Contract del QA

```markdown
## Validación de Tests
- Tests unitarios revisados: [N]
- Tests de integración creados: [N]

## Resultados de Ejecución
- flutter test: [N passed / N failed]
- Regresiones detectadas: [lista o "Ninguna"]

## Fallos Encontrados
1. [severidad] - [archivo:línea] - [descripción]
2. [severidad] - [archivo:línea] - [descripción]

## Estado
- APROBADO / REQUIERE CORRECCIONES

## Recomendaciones
- [sugerencias de mejora opcionales]
```

### Reglas del QA

1. **Ejecutar todos los tests** (existentes + nuevos del Desarrollador)
2. **Verificar cobertura** de tests unitarios
3. **Crear tests de integración** para validar flujos completos
4. **Reportar fallos con severidad** (CRITICAL / HIGH / MEDIUM / LOW)
5. **Si hay fallos** → Retornar "REQUIERE CORRECCIONES"
6. **Si todo OK** → Retornar "APROBADO"

---

## Ingeniero Cybersecurity (IC) Agent

### Propósito

Detectar vulnerabilidades de seguridad en el código implementado. Realiza auditorías de seguridad siguiendo OWASP Top 10 y otras prácticas de seguridad. Reporta vulnerabilidades o cambios necesarios.

### Cuándo se activa

Después de QA (aprobado) o en paralelo con QA.

### Skills requeridas

| Skill | Propósito |
|-------|-----------|
| `owasp-security-check` | Auditorías OWASP Top 10 |
| `flutter-dart-code-review` | Patrones de código seguro |

### Flujo de Ejecución

```
1. QA retorna "APROBADO"
2. Orquestador → Lanza IC Agent
3. IC Agent:
   a. Carga owasp-security-check
   b. Analiza el código implementado
   c. Busca vulnerabilidades comunes
   d. Genera reporte de seguridad
4. Retorna reporte al Orquestador
```

### Output Contract del IC

```markdown
## Auditoría de Seguridad

### Vulnerabilidades Encontradas
1. [severidad] - [OWASP categoría] - [archivo:línea]
   - Descripción: [qué vulnerability]
   - Impacto: [qué podría pasar]
   - Remedio: [cómo corregir]

2. [severidad] - [OWASP categoría] - [archivo:línea]
   ...

### Patrones Seguros Verificados
- [patrón 1]: [OK / FALLO]
- [patrón 2]: [OK / FALLO]

### Estado
- APROBADO / REQUIERE CORRECCIONES

### Score de Seguridad
- CRITICAL: [N]
- HIGH: [N]
- MEDIUM: [N]
- LOW: [N]
```

### Reglas del IC

1. **Cargar owasp-security-check** antes de auditar
2. **Aplicar flutter-dart-code-review** para patrones de código seguro
3. **Categorizar vulnerabilidades** por severidad (CRITICAL / HIGH / MEDIUM / LOW)
4. **Mapear a OWASP Top 10** cuando aplique
5. **Proporcionar remediación concreta** para cada vulnerabilidad
6. **Si hay vulnerabilidades CRITICAL/HIGH** → Retornar "REQUIERE CORRECCIONES"
7. **Si todo OK** → Retornar "APROBADO"