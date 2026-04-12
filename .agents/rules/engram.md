# Engram (Persistent Memory)

El proyecto usa **Engram MCP** para persistir aprendizajes y reducir la pérdida de contexto entre sesiones.

## Configuración

MCP configurado en `.mcp.json` (raíz del proyecto) con `ENGRAM_PROJECT=de_vacos`.  
Para OpenCode: ejecutar `engram setup opencode` una vez.

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

**title**: Verb + what — corto y buscable  
**type**: bugfix | decision | architecture | discovery | pattern | config | preference  
**scope**: project (default) | personal  
**topic_key** (opcional): clave estable para decisiones que evolucionan  
**content**:
- **What**: Una oración — qué se hizo
- **Why**: Qué lo motivó
- **Where**: Archivos o paths afectados
- **Learned**: Gotchas, edge cases (omitir si no hay)

## Si Engram no está disponible

Continuar el pipeline normalmente pero indicar al inicio de la respuesta:
> "Operando sin memoria histórica (Engram no disponible)."

No bloquear el flujo por falta de Engram — es una ayuda, no un requisito bloqueante.
