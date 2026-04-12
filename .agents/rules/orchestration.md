---
trigger: always
---

# Reglas de Trabajo

## Contexto obligatorio

Antes de implementar cualquier cambio, leer y respetar:
- `.agents/rules/business-rules.md` — invariantes del dominio (numeración, estados, soft-delete, etc.)
- `.agents/rules/architecture.md` — capas, patrones, routing

## Verificación obligatoria

Antes de considerar una tarea completada:
```bash
flutter analyze   # 0 issues
flutter test      # 0 failures
```

Si alguno falla, corregir antes de reportar al usuario.

## Commit

Usar Conventional Commits: `<type>(<scope>): <description>`

## Engram (memoria persistente)

- **Guardar** (`mem_save`): después de bugfixes, decisiones de arquitectura, descubrimientos no obvios.
- **Consultar** (`mem_search`/`mem_context`): cuando la tarea parece relacionada con trabajo previo o el usuario menciona algo de sesiones anteriores.
- No es obligatorio en cada tarea. Usar cuando aporte valor.

## Sub-agentes

Lanzar sub-agentes solo cuando aporten valor:
- **Exploración paralela**: buscar en muchos archivos a la vez
- **Tareas independientes**: dos cambios que no dependen entre sí

No delegar por defecto. Implementar directamente es más rápido y preciso para la mayoría de tareas.

## Skills

Cargar skills (`.agents/skills/`) solo cuando se necesite consultar un patrón específico. No pre-cargar todo.

## Seguridad

Aplicar revisión de seguridad (skill `security-review`) solo en cambios que toquen autenticación, credenciales, o datos sensibles.

## Brainstorming antes de implementar

En features complejas o ambiguas, hacer **máximo 2-3 preguntas** al usuario antes de codear:
- ¿Qué caso borde cubre esto?
- ¿Hay restricción de negocio que deba respetar?
- ¿Cómo debería verse el flujo completo?

No aplica en tareas simples o donde el alcance es claro. El objetivo es evitar implementar en la dirección equivocada.

## Regla de 3 fallos

Si un fix o enfoque falla **3 veces consecutivas**, detener y hacer revisión de causa raíz antes de continuar:
1. Leer el error completo sin asumir
2. Buscar en Engram si el problema ya se vio antes (`mem_search`)
3. Revisar `architecture.md` y `business-rules.md` por invariantes relevantes
4. Solo entonces proponer un nuevo enfoque

No intentar un cuarto fix sin haber completado estos 4 pasos.
