# Security

## Environment Variables

### Debug
`.env` en raíz con:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
CLIENTE_ID=...
```
Referencia: `env.example`. El archivo `.env` **no se incluye en el bundle** de release; solo se carga en modo debug.

### Release
Usar `--dart-define` en build time. No se usa dotenv.

## Reglas fundamentales

- **NUNCA commitear** `.env` ni archivos con credenciales reales.
- **Ofuscación en release:** `build/symbols` no se sube al repositorio.

## Licencias

Verificación al iniciar. Periodo de gracia sin internet: 14 días (configurable en `lib/core/constants/security_constants.dart`).

## Reportes

Envío en segundo plano (total ventas, pedidos, top 3 productos). Un fallo de envío no bloquea al usuario.

---

## OWASP Security Skill

**Para auditorías de seguridad**, cargar la skill `owasp-security-check`:

```
Skill: @sergiodxa/agent-skills/owasp-security-check
```

Esta skill proporciona:
- 20 reglas de auditoría
- Cobertura OWASP Top 10
- Patrones de vulnerabilidad comunes
- Workflow de remediación

**Aplicar cuando:**
- Se agregan features que manejan datos sensibles
- Antes de deployment a producción
- Al revisar configuraciones de deployment