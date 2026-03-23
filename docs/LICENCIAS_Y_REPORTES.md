# Licencias y reportes a Supabase – Guía y mejores prácticas

## Problemas que se abordan

1. **Bloqueo por fallos de red o reporte:** Si el envío de reportes falla (por RLS, timeout o red), la app no debe bloquear a los usuarios. La decisión de licencia debe ser independiente del éxito del reporte.
2. **Período de gracia de 3 días:** Demasiado corto; se aumenta de forma configurable (p. ej. 14 días) para locales con internet inestable.
3. **Datos que debes enviar:** Total diario de ventas, número de órdenes al día y **top 3 productos más vendidos**. La tabla actual ya soporta totales; se añade el envío de top 3 productos.

---

## 1. Estrategia de licencia (recomendada)

### Principios

- **Solo bloqueas si Supabase dice “bloqueado”.** Si no hay red o hay error al leer, no bloquees: usa período de gracia o “último estado conocido”.
- **El reporte de ventas es en segundo plano.** No esperas a que termine para decidir si la licencia está activa. Si el reporte falla, se reintenta en el siguiente arranque o en un job en background.
- **Período de gracia más largo.** Por defecto 14 días sin conexión antes de bloquear (configurable en `SecurityConstants.graceDays`).

### Flujo en la app

1. **Al abrir la app (splash):**
   - Si **no hay internet:** Se usa solo el período de gracia (días desde la última verificación exitosa). No se bloquea por “no pudo enviar reporte”.
   - Si **hay internet:**
     - **Paso 1 – Verificación de licencia:** Se consulta la tabla `licencias` por `cliente_id`. Si `estado == 'bloqueado'` → bloquear. Cualquier otro caso (activo, null, error de red) → permitir acceso.
     - **Paso 2 – Reporte en background:** Se envían total diario, cantidad de pedidos y top 3 productos en segundo plano. Si falla, la app **no** se bloquea; solo se registra y se reintentará después.
   - Se guarda la fecha de última verificación exitosa solo cuando la licencia está activa (para el período de gracia cuando no haya internet).

2. **`fecha_ultimo_pago` en `licencias`:**  
   Es un campo que **tú actualizas desde el back office** cuando el cliente paga (no lo escribe la app). La app no lo usa para decidir si bloquear o no; solo lee `estado`.

---

## 2. Tablas en Supabase

### 2.1 `licencias`

- `cliente_id` (text, PK)
- `estado` (text): `'activo'` | `'bloqueado'`
- `porcentaje_comision` (numeric)
- `fecha_ultimo_pago` (timestamptz, opcional): lo actualizas tú al registrar un pago.

**RLS:** El cliente (anon key con `cliente_id` en el request o en un JWT) debe poder **solo leer** su fila. No debe poder escribir `estado` ni `fecha_ultimo_pago`.

### 2.2 `reportes_semanales` (reportes diarios por fecha)

Columnas usadas por la app:

| Columna               | Tipo    | Uso                                      |
|-----------------------|--------|------------------------------------------|
| `id`                  | uuid   | PK                                       |
| `cliente_id`          | text   | Identificador del negocio                |
| `fecha_corte`         | date   | Fecha del reporte (día)                  |
| `cantidad_pedidos`    | int4   | Número de órdenes del día                |
| `total_ventas`        | numeric| Total diario de ventas                   |
| `top_productos`       | jsonb  | **Nuevo.** Top 3 productos (ver abajo)   |
| `total_comision_esperada` | numeric | Calculado en Supabase si aplica      |
| `estado_pago`         | text   | 'pendiente' | 'pagado' (lo gestionas tú)         |

**Constraint UNIQUE:** `(cliente_id, fecha_corte)` para hacer UPSERT por día.

**Formato sugerido de `top_productos` (JSON):**

```json
[
  { "nombre": "Hamburguesa clásica", "cantidad": 45, "monto": 1125.00 },
  { "nombre": "Pizza mediana", "cantidad": 32, "monto": 960.00 },
  { "nombre": "Café", "cantidad": 28, "monto": 280.00 }
]
```

**SQL para añadir la columna en Supabase:**

```sql
ALTER TABLE reportes_semanales
ADD COLUMN IF NOT EXISTS top_productos jsonb DEFAULT NULL;
```

**RLS:** El cliente debe poder hacer INSERT/UPDATE solo de sus propias filas (`cliente_id` = su id). No debe poder borrar ni modificar otros clientes.

### 2.3 `cobros`

Sin cambios en el modelo actual: la app solo lee para mostrar deuda pendiente.

---

## 3. Comportamiento de la app (resumen)

| Situación                         | Acceso   | Reporte                          |
|-----------------------------------|----------|----------------------------------|
| Internet OK, licencia activa      | Permitido| Se envía en background           |
| Internet OK, licencia bloqueada   | Bloqueado| No aplica                        |
| Internet OK, error leyendo licencia| Permitido| Se intenta en background        |
| Sin internet, dentro de gracia    | Permitido| Se encola / se intenta después   |
| Sin internet, gracia excedida     | Bloqueado| No aplica                        |
| Error al subir reporte             | Permitido| No bloquea; reintento después   |

La app **nunca** bloquea al usuario solo porque falló el envío del reporte a Supabase.

---

## 4. Configuración local

- **Período de gracia (días sin internet):**  
  `lib/core/constants/security_constants.dart` → `SecurityConstants.graceDays` (por defecto 14).

- **CLIENTE_ID:**  
  Definido en `.env` (debug) o `--dart-define=CLIENTE_ID=xxx` (release). Debe coincidir con `cliente_id` en `licencias` y en los reportes.

---

## 5. Panel / back office

- **Licencias:** Actualizar `estado` a `'bloqueado'` solo cuando quieras cortar el acceso. Actualizar `fecha_ultimo_pago` cuando registres un pago.
- **Reportes:** Puedes leer `reportes_semanales` (total_ventas, cantidad_pedidos, top_productos) por `cliente_id` y `fecha_corte` para facturación y analytics.
- **Cobros:** Gestionar `cobros` (monto_a_pagar, estado) y dejar que la app solo consulte para mostrar la deuda al usuario.
