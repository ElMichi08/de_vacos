# Plan: Multi-Payment System con estado `recobrar`

## Context
El flujo de cobro actual soporta un solo pago por orden con un único método. "Cobrar diferencia" es un diálogo simple de confirmación sin modales reutilizados. Necesitamos:
- Agregar `recobrar` como estado explícito en DB (más corto que "cobrar diferencia")
- Reutilizar `PaymentModal`/`TransferPaymentModal` para recobros con título "Actualizar Pago"
- Soportar múltiples pagos por orden con distintos métodos (1 inicial + máx. 2 recobros)
- Almacenar historial de pagos en columna `pagos` (JSON) en la DB
- Actualizar reportes: filtro transfer = cualquier pago en transfer
- Mostrar múltiples fotos de transferencia en `TransferPhotoViewerModal`

---

## Archivos a modificar

| Archivo | Cambio |
|---|---|
| `lib/models/enums.dart` | Agregar `recobrar` a `PaymentStatus` |
| `lib/models/pedido.dart` | Agregar clase `Pago` + campo `pagos: List<Pago>?` |
| `lib/core/database/db_helper.dart` | Migración v11: columna `pagos TEXT DEFAULT NULL` |
| `lib/repositories/pedido_repository.dart` | Actualizar `actualizarEstadoPago` para escribir `pagos` |
| `lib/services/pedido_service.dart` | Actualizar firma de `actualizarEstadoPago`, agregar `setRecobrar` |
| `lib/widgets/payment_modal.dart` | Param opcional `String? titulo` |
| `lib/widgets/transfer_payment_modal.dart` | Param opcional `String? titulo` |
| `lib/screens/order_list_screen.dart` | Reemplazar `_cobrarDiferencia` con flujo selector+modal; badge `recobrar` |
| `lib/screens/order_form_screen.dart` | Al guardar orden editada cobrada → `estadoPago = recobrar` |
| `lib/screens/report_screen.dart` | Filtro y stats adaptados para multi-pago |
| `lib/widgets/transfer_photo_viewer_modal.dart` | Mostrar múltiples fotos de pagos en transferencia |

---

## Step 1 — Enum `PaymentStatus`
**`lib/models/enums.dart`**

```dart
enum PaymentStatus {
  pendiente('Pendiente'),
  cobrado('Cobrado'),
  recobrar('Recobrar');   // ← NUEVO
}
```

Color en `order_list_screen._getEstadoPagoColor`:
- `cobrado` → `AppColors.success` (verde, actual)
- `recobrar` → `Colors.orange`
- `pendiente` → existente

---

## Step 2 — Modelo `Pago` + campo `pagos` en `Pedido`
**`lib/models/pedido.dart`**

Nueva clase (puede ir en el mismo archivo):
```dart
class Pago {
  final PaymentMethod metodo;
  final double monto;
  final String? foto;

  const Pago({required this.metodo, required this.monto, this.foto});

  Map<String, dynamic> toMap() => {
    'metodo': metodo.displayName,
    'monto': monto,
    'foto': foto,
  };

  static Pago fromMap(Map<String, dynamic> m) => Pago(
    metodo: PaymentMethod.fromString(m['metodo'] as String),
    monto: (m['monto'] as num).toDouble(),
    foto: m['foto'] as String?,
  );
}
```

En `Pedido`:
- Agregar `final List<Pago>? pagos;`
- En `fromMap`: deserializar `jsonDecode(map['pagos'] as String)` → `List<Pago>`
- En `toMap`: `jsonEncode(pagos?.map((p) => p.toMap()).toList())`
- Constructor, `copyWith`, `==`, `hashCode`

Helpers en `Pedido`:
```dart
double get totalYaCobrado =>
    pagos?.fold(0.0, (s, p) => s + p.monto) ?? 0.0;

double get diferencia => total - totalYaCobrado;

bool get puedeRecobrar =>
    (pagos?.length ?? 0) < 3; // max 1 inicial + 2 recobros
```

---

## Step 3 — DB Migration v11
**`lib/core/database/db_helper.dart`**

Incrementar `_dbVersion` de 10 → 11.

En `onUpgrade` case 11:
```dart
await db.execute('ALTER TABLE pedidos ADD COLUMN pagos TEXT DEFAULT NULL');
```

En `_ensureTableColumns`: agregar `pagos TEXT DEFAULT NULL` al guard.

---

## Step 4 — Modales con título personalizable
**`lib/widgets/payment_modal.dart`** y **`lib/widgets/transfer_payment_modal.dart`**

Agregar param opcional a cada `StatefulWidget`:
```dart
final String titulo; // default: 'Cobrar' / 'Pago por transferencia'
```

En el header del modal usar `widget.titulo` en lugar del texto hardcodeado.

---

## Step 5 — Repository: `actualizarEstadoPago` actualizado
**`lib/repositories/pedido_repository.dart`**

Nueva firma:
```dart
Future<int> actualizarEstadoPago(
  int pedidoId,
  String estadoPago, {
  PaymentMethod? metodoPago,
  double? montoPagado,
  String? fotoPath,
  String? productosCobradosJson,
  Transaction? txn,
}) async
```

Lógica de `pagos`:
1. Leer `pagos` actual del registro
2. Crear nuevo `Pago(metodo: metodoPago, monto: montoPagado, foto: fotoPath)`
3. Hacer `append` a la lista
4. Serializar y escribir `pagos` en el update
5. Mantener `fotoTransferenciaPath` ← primera foto de transferencia (backward compat)

Agregar método `setRecobrar(int pedidoId, {Transaction? txn})`:
```dart
Future<void> setRecobrar(int pedidoId, {Transaction? txn}) async {
  // Solo actualiza estadoPago = 'Recobrar', no toca pagos ni stock
}
```

---

## Step 6 — Service: `actualizarEstadoPago` y `setRecobrar`
**`lib/services/pedido_service.dart`**

Actualizar `actualizarEstadoPago` para:
- Pasar `metodoPago`, `monto`, `fotoPath` al repository
- La lógica de stock diff existente (via `productosCobrados`) no cambia

Agregar:
```dart
static Future<void> setRecobrar(int pedidoId) async {
  final repo = getIt<IPedidoRepository>();
  await repo.setRecobrar(pedidoId);
}
```

---

## Step 7 — Order form: set `recobrar` al guardar edición
**`lib/screens/order_form_screen.dart`**

Al guardar (`_guardarPedido`) cuando se está editando (`widget.pedido != null`):
```dart
if (pedidoOriginal.estadoPago == PaymentStatus.cobrado) {
  await PedidoService.setRecobrar(pedidoOriginal.id!);
}
```

Esto se ejecuta DESPUÉS de guardar los productos actualizados.

---

## Step 8 — Order list: badge y flujo `_actualizarPago`
**`lib/screens/order_list_screen.dart`**

### Badge logic (sin `_tieneProductosDiferentes` para nuevas órdenes)
```dart
final puedeReCobro = activo &&
    pedido.estadoPago == PaymentStatus.recobrar &&
    pedido.puedeRecobrar;

// Fallback histórico (sin pagos column, cobrado, productos cambiaron)
final puedeReCobroHistorico = activo &&
    pedido.estadoPago == PaymentStatus.cobrado &&
    pedido.pagos == null &&
    _tieneProductosDiferentes(pedido);

final label = (puedeReCobro || puedeReCobroHistorico)
    ? 'Recobrar'
    : pedido.estadoPago.displayName;
```

En `_getEstadoPagoColor`: agregar `case PaymentStatus.recobrar: return Colors.orange;`

### Método `_actualizarPago` (reemplaza `_cobrarDiferencia`)
```dart
Future<void> _actualizarPago(Pedido pedido) async {
  // 1. Verificar límite
  if (!pedido.puedeRecobrar) {
    // Snackbar: "Límite de 2 recobros alcanzado"
    return;
  }

  // 2. Bottom sheet: elegir método
  final metodo = await showModalBottomSheet<PaymentMethod>(
    context: context,
    builder: (ctx) => _MetodoPagoSheet(
      diferencia: pedido.diferencia,
      numeroOrden: pedido.numeroOrden,
    ),
  );
  if (metodo == null || !mounted) return;

  // 3. Mostrar modal según método
  if (metodo == PaymentMethod.efectivo) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PaymentModal(
        totalAPagar: pedido.diferencia,
        cliente: pedido.cliente,
        numeroOrden: pedido.numeroOrden,
        titulo: 'Actualizar Pago',
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    await PedidoService.actualizarEstadoPago(
      pedido.id!, PaymentStatus.cobrado.displayName,
      metodoPago: PaymentMethod.efectivo,
      montoPagado: pedido.diferencia,
    );
  } else {
    final res = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => TransferPaymentModal(
        totalAPagar: pedido.diferencia,
        cliente: pedido.cliente,
        numeroOrden: pedido.numeroOrden,
        titulo: 'Actualizar Pago',
      ),
    );
    if (res == null || !(res['cobrado'] as bool) || !mounted) return;
    await PedidoService.actualizarEstadoPago(
      pedido.id!, PaymentStatus.cobrado.displayName,
      metodoPago: PaymentMethod.transferencia,
      montoPagado: pedido.diferencia,
      fotoPath: res['fotoPath'] as String?,
    );
  }
  if (mounted) _cargarPedidos();
}
```

Nuevo widget privado `_MetodoPagoSheet` en el mismo archivo (BottomSheet con 2 botones grandes: Efectivo / Transferencia, mostrando el monto diferencia).

---

## Step 9 — Reports: filtrado multi-pago
**`lib/screens/report_screen.dart`**

En `_obtenerPedidosFiltrados`, reemplazar:
```dart
p.metodoPago == _filtroMetodoPago
```
por:
```dart
_matchesFiltro(p, _filtroMetodoPago!)
```

Método helper:
```dart
bool _matchesFiltro(Pedido p, PaymentMethod metodo) {
  if (p.pagos != null && p.pagos!.isNotEmpty) {
    return p.pagos!.any((pg) => pg.metodo == metodo);
  }
  return p.metodoPago == metodo;
}
```

Actualizar `_contarTransferencias` y `_contarEfectivo` con el mismo helper.

---

## Step 10 — `TransferPhotoViewerModal`: múltiples fotos
**`lib/widgets/transfer_photo_viewer_modal.dart`**

En `build`, extraer lista de fotos:
```dart
final fotos = pedido.pagos
    ?.where((p) => p.metodo == PaymentMethod.transferencia && p.foto != null)
    .map((p) => p.foto!)
    .toList()
    ?? (pedido.fotoTransferenciaPath != null ? [pedido.fotoTransferenciaPath!] : []);
```

Si `fotos.length == 1` → comportamiento actual.
Si `fotos.length > 1` → `PageView` con indicador de páginas (puntos) debajo. Cada página muestra la foto con `InteractiveViewer`.

---

## Step 11 — Documentar cambios en rules
Una vez que `flutter analyze` y `flutter test` pasen con 0 errores/fallos:
- Actualizar `.agents/rules/business-rules.md` con:
  - Nuevo estado `recobrar` en la máquina de estados de pedidos
  - Campo `pagos` (JSON) en Pedido: estructura `[{metodo, monto, foto?}]`
  - Límite de 2 recobros (3 pagos máx total)
  - Regla: al editar orden con `estadoPago == cobrado` → setear `recobrar`
- Actualizar `.agents/rules/architecture.md` si se menciona el modelo Pedido o sus campos de pago

---

## Máquina de estados resumida

```
Pendiente ──[cobrar]──▶ Cobrado ──[editar orden]──▶ Recobrar
                                                        │
                                          [pagar diferencia]
                                          (efectivo o transfer)
                                                        │
                                                        ▼
                                                    Cobrado
                                          (máx 2 recobros totales)
```

---

## Verificación

```bash
flutter analyze  # 0 issues
flutter test     # 0 failures
```

**Flujo manual:**
1. Crear orden $5 → pagar por Transferencia → badge "Cobrado" verde, `pagos[0]` en DB
2. Editar orden (agregar producto $3, total=$8) → guardar → badge "Recobrar" naranja
3. Tocar "Recobrar" → sheet → elegir Efectivo → ingresar $3 → badge vuelve "Cobrado", `pagos[1]`
4. Editar otra vez → badge "Recobrar" → elegir Transferencia → tomar foto → `pagos[2]`
5. Intentar 3er recobro → bloqueado con snackbar
6. Reportes → filtrar Transferencia → orden aparece (tiene transfer en `pagos[0]`)
7. Tocar card transfer → `TransferPhotoViewerModal` muestra PageView con 2 fotos
8. Órdenes históricas (sin `pagos`) → fallback `_tieneProductosDiferentes` sigue funcionando
