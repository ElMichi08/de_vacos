# Engram (Persistent Memory)

El proyecto usa **Engram MCP** para persistir aprendizajes y reducir la pérdida de contexto entre sesiones.

## Cuándo guardar (`mem_save`)

- Después de cada bugfix completado.
- Después de cada decisión arquitectónica o de diseño.
- Al descubrir algo no obvio del codebase.
- Al cambiar configuración o setup.
- Al establecer un patrón o convención nueva.

## Cuándo buscar (`mem_search` / `mem_context`)

- Al inicio de cada sesión: `mem_context` para recuperar sesiones recientes.
- Antes de trabajar en algo que pudo haberse hecho antes: `mem_search` con keywords.
- Cuando el usuario menciona un tema sin contexto previo.

## Al cerrar sesión (`mem_session_summary`)

**Obligatorio.** Guardar resumen estructurado con: Goal, Instructions, Discoveries, Accomplished, Next Steps, Relevant Files.

## Formato para mem_save

**title**: Verb + what — short, searchable
**type**: bugfix | decision | architecture | discovery | pattern | config | preference
**scope**: project (default) | personal
**topic_key** (optional): stable key para decisiones evolucionando
**content**:
- **What**: One sentence — what was done
- **Why**: What motivated it
- **Where**: Files or paths affected
- **Learned**: Gotchas, edge cases (omit if none)