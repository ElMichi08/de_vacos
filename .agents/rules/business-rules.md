# Reglas de Negocio Críticas - De Vacos Urban Grill POS

> **Objetivo:** Documentar reglas que, si se eliminan o modifican, causarían problemas en el sistema.
> **Mantenimiento:** Actualizar este documento cuando se añadan nuevas reglas o se modifiquen existentes.

## Tabla de Contenidos
1. [Pedidos](#1-pedidos)
2. [Inventario](#2-inventario)
3. [Caja](#3-caja)
4. [Reportes](#4-reportes)
5. [Validaciones de Modelos](#5-validaciones-de-modelos)
6. [Impresión](#6-impresión)
7. [Sincronización](#7-sincronización)

## Mapeo Módulo → Categorías de Reglas

| Módulo / Ruta afectada | Categorías Relevantes |
|------------------------|----------------------|
| `lib/models/pedido.dart` | Pedidos, Validaciones de Modelos |
| `lib/services/pedido_service.dart` | Pedidos, Inventario |
| `lib/core/database/db_helper.dart` | Pedidos, Reportes |
| `lib/services/insumo_service.dart` | Inventario, Validaciones |
| `lib/services/caja_service.dart` | Caja, Reportes |
| `lib/models/caja.dart` | Caja, Validaciones de Modelos |
| `lib/models/insumo.dart` | Inventario, Validaciones de Modelos |
| `lib/models/producto.dart` | Validaciones de Modelos |
| `lib/services/printer/printer_service.dart` | Impresión |
| `lib/services/printer/ticket_builder.dart` | Impresión |
| `lib/services/supabase_sync_service.dart` | Sincronización, Reportes |
| `lib/screens/order_list_screen.dart` | Pedidos, Reportes |
| `lib/screens/report_screen.dart` | Reportes |
| `lib/screens/inventory_screen.dart` | Inventario |
| `lib/screens/cash_register_screen.dart` | Caja |
| `lib/screens/print_screen.dart` | Impresión |

## Palabras Clave para Búsqueda

| Palabra Clave | Categoría | Regla específica |
|---------------|-----------|------------------|
| "numeración" | Pedidos | Numeración 1-100 |
| "unicidad" | Pedidos | Unicidad de numeroOrden |
| "cancelado" | Pedidos | Soft delete (cancelado) |
| "cerrar" | Pedidos | No cerrar sin cobrar |
| "estadoPago" | Pedidos | estadoPago valores |
| "stock" | Inventario | Stock atómico, Validación suficiente |
| "insumo" | Inventario | Campos obligatorios insumo |
| "caja chica" | Caja | Una Caja Chica por día |
| "tipo" | Caja | Tipos válidos |
| "valor" | Caja | Valores positivos |
| "descripción" | Caja | Descripción obligatoria |
| "cobrados" | Reportes | Auditoría solo cobrados |
| "top productos" | Reportes | Top productos solo cobrados |
| "cancelados" | Reportes | No contar cancelados |
| "producto" | Validaciones de Modelos | Producto: nombre obligatorio |
| "precio" | Validaciones de Modelos | Producto: precio positivo |
| "variantes" | Validaciones de Modelos | Producto: variantes válidas |
| "cantidades" | Validaciones de Modelos | Insumo: cantidades no negativas |
| "debounce" | Impresión | Debounce 2 segundos |
| "ESC/POS" | Impresión | Validación bytes ESC/POS |
| "CLIENTE_ID" | Sincronización | CLIENTE_ID obligatorio |
| "lookback" | Sincronización | Lookback 14 días |
| "conectividad" | Sincronización | Conexión requerida |

---

## 1. Pedidos

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Numeración 1-100** | Los números de orden se generan en ciclo de 1 a 100 diariamente (`maxOrden % 100 + 1`). | `lib/core/database/db_helper.dart:440` | Perdida de unicidad, números repetidos o fuera de rango. | ID 79 |
| **Unicidad de numeroOrden** | Verifica que no existan pedidos activos con el mismo numeroOrden en el mismo día. | `lib/core/database/db_helper.dart:443-482` | Confusión entre pedidos, pérdida de identificación única. | ID 67 |
| **Soft delete (cancelado)** | Pedidos no se eliminan físicamente, se marcan como `cancelado = true`. | `lib/models/pedido.dart:16` | Pérdida histórica de datos, imposibilidad de auditoría. | ID 77 |
| **No cerrar sin cobrar** | No se permite cambiar estado a 'Cerrados' si `estadoPago != 'Cobrado'`. | `lib/screens/order_list_screen.dart:124-135` | Pérdida de ingresos, pedidos cerrados sin pago registrado. | ID 68 |
| **Campos obligatorios** | `cliente`, `metodoPago`, `estado` y `productos` son obligatorios. `total` debe ser > 0. | `lib/models/pedido.dart:89-108` | Datos incompletos, cálculos incorrectos, bugs en reportes. | - |
| **estadoPago valores** | Solo admite 'Pendiente' o 'Cobrado'. | `lib/models/pedido.dart:10` | Estados inválidos, lógica de cobros rota. | ID 75 |

---

## 2. Inventario

*Nota: El módulo de insumos está habilitado en `assets/config/branding.json` (feature flag `insumos`). Las siguientes reglas aplican cuando el módulo está accesible.*

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Stock atómico** | Descuento de insumos en transacción SQLite (validación + descuento atómico). | `lib/services/insumo_service.dart:46-70` | Stock inconsistente, ventas con insumos insuficientes. | - |
| **Validación suficiente** | Antes de descontar, valida que `cantidadActual >= requerido`. Lanza `StockInsuficienteException`. | `lib/services/insumo_service.dart:47-59` | Inventario negativo, imposibilidad de cumplir pedidos. | - |
| **Campos obligatorios insumo** | `nombre` y `unidadMedida` obligatorios; cantidades no negativas. | `lib/models/insumo.dart:49-57` | Datos corruptos, cálculos erróneos. | - |

---

## 3. Caja

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Una Caja Chica por día** | Solo se permite un movimiento tipo 'Caja Chica' por fecha. | `lib/services/caja_service.dart:11-23` | Múltiples cajas chicas, confusión en cierres diarios. | - |
| **Tipos válidos** | Solo admite 'Ingreso', 'Egreso', 'Caja Chica'. | `lib/models/caja.dart:44-45` | Tipos inválidos, reportes de caja incorrectos. | - |
| **Valores positivos** | `valor` debe ser > 0. | `lib/models/caja.dart:47-48` | Negativos en caja, balances erróneos. | - |
| **Descripción obligatoria** | `descripcion` no puede estar vacía. | `lib/models/caja.dart:41-43` | Registros sin contexto, auditoría difícil. | - |

---

## 4. Reportes

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Auditoría solo cobrados** | Solo cuenta pedidos con `estadoPago = 'Cobrado'` y `estado = 'Cerrados'`. | `lib/screens/report_screen.dart:98-99` | Inflado de ventas, reportes no confiables. | - |
| **Top productos solo cobrados** | Top productos se calculan solo de pedidos cobrados y cerrados. | `lib/screens/report_screen.dart:114-115` | Análisis de productos incorrecto. | - |
| **No contar cancelados** | Pedidos `cancelado = true` se excluyen de todos los reportes. | `lib/screens/report_screen.dart:97` | Conteo inflado, métricas erróneas. | - |

---

## 5. Validaciones de Modelos

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Producto: nombre obligatorio** | `nombre` no puede estar vacío. | `lib/models/producto.dart:141-142` | Productos sin identificación, bugs en UI. | - |
| **Producto: precio positivo** | `precio` debe ser > 0. | `lib/models/producto.dart:144-145` | Precios inválidos, ventas con monto cero. | - |
| **Producto: variantes válidas** | Cada variante debe pasar su propia validación. | `lib/models/producto.dart:149-156` | Variantes corruptas, precios inconsistentes. | - |
| **Insumo: cantidades no negativas** | `cantidadActual` y `cantidadMinima` no pueden ser negativas. | `lib/models/insumo.dart:52-53` | Inventario negativo, alertas falsas de stock bajo. | - |

---

## 6. Impresión

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **Debounce 2 segundos** | Evita impresiones duplicadas con ventana de 2 segundos. | `lib/services/printer/printer_service.dart:26` | Impresiones múltiples, desperdicio de papel. | - |
| **Validación bytes ESC/POS** | Verifica que todos los bytes estén en rango 0-255 antes de enviar a impresora. | `lib/services/printer/ticket_builder.dart:144-164` | Impresoras se bloquean, tickets corruptos. | - |

---

## 7. Sincronización

| Regla | Descripción | Ubicación | Consecuencias si se elimina | Ref Engram |
|-------|-------------|-----------|-----------------------------|------------|
| **CLIENTE_ID obligatorio** | Sin CLIENTE_ID, la sincronización a Supabase se omite. En release, debe definirse via `--dart-define`. | `lib/services/supabase_sync_service.dart:16-28` | Reportes no se suben, pérdida de datos en nube. | - |
| **Lookback 14 días** | Sincroniza reportes de los últimos 14 días en background. | `lib/services/supabase_sync_service.dart:13` | Reportes antiguos no se envían, brechas en datos. | - |
| **Conexión requerida** | Antes de enviar cierre de caja, verifica conectividad a internet. | `lib/services/supabase_sync_service.dart:131-136` | Intentos fallidos, frustración de usuario. | - |

---

## Notas de Mantenimiento

- **Agregar nueva regla:** Incluir en la categoría correspondiente con todos los campos.
- **Modificar regla:** Actualizar descripción y consecuencias; verificar que el código siga cumpliendo.
- **Eliminar regla:** Documentar motivo y migración (si aplica).
- **Referencias Engram:** Usar IDs cuando la regla esté vinculada a observaciones pasadas.
- **Feature Flags:** Algunos módulos (ej. `insumos`) pueden estar habilitados/deshabilitados via `assets/config/branding.json`. Actualmente el módulo de insumos está habilitado en el array `features`.
- **Defensive casting:** Se han reemplazado casts inseguros con patrones defensivos en modelos críticos (receta_detalle, producto_seleccionado, etc.) para mejorar la seguridad de tipos y prevenir null-safety bugs.
- **Quality gate:** Se ha integrado una regla de quality gate (`.agents/rules/quality-gate.md`) que verifica análisis estático, tests, seguridad y calidad antes de cada commit.

---

*Documento generado el 30/03/2026 por el pipeline Michibot (PM role).* Se actualizó el 01/04/2026 para incluir defensive casting y quality gate.
