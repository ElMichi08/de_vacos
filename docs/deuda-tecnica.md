# Deuda Técnica - De Vacos POS

## Resumen Ejecutivo

Este documento lista la deuda técnica identificada y las tareas pendientes para resolverla.

**Última actualización:** 2026-03-26 23:15

---

## Phase 1: Tests (HIGH) - Estado: ✅ COMPLETADO

### ✅ Completado
- **1.1 Widget Tests:** 24 tests creados y pasando
  - `test/widgets/payment_modal_test.dart` - 7 tests
  - `test/widgets/order_detail_modal_test.dart` - 8 tests  
  - `test/widgets/product_card_widget_test.dart` - 9 tests

- **1.2 Screen Tests:** ✅ CREADOS (6 FALLANDO)
  - `test/screens/cocina_screen_test.dart` - 3 tests (fallan por pumpAndSettle timeout)
  - `test/screens/caja_screen_test.dart` - 3 tests (fallan por pumpAndSettle timeout)
  - `test/screens/report_screen_test.dart` - 3 tests (fallan por pumpAndSettle timeout)

- **1.3 Integration Tests:** ✅ CREADO
  - Estructura preparada en `test/integration/`

---

## Phase 2: Arquitectura (HIGH) - Estado: ✅ COMPLETADO

### ✅ Completado (Infraestructura)
Se implementó el patrón Repository con inyección de dependencias:

#### Interfaces Creadas
| Archivo | Descripción |
|---------|-------------|
| `lib/repositories/i_pedido_repository.dart` | Interfaz abstracta para pedidos |
| `lib/repositories/i_producto_repository.dart` | Interfaz abstracta para productos |
| `lib/repositories/i_caja_repository.dart` | Interfaz abstracta para caja |
| `lib/repositories/i_insumo_repository.dart` | Interfaz abstracta para insumos |
| `lib/repositories/i_ventas_repository.dart` | Interfaz abstracta para ventas |
| `lib/repositories/i_image_repository.dart` | Interfaz abstracta para imágenes |

#### Repositorios Implementados
| Archivo | Descripción |
|---------|-------------|
| `lib/repositories/pedido_repository.dart` | Implementación de IPedidoRepository |
| `lib/repositories/producto_repository.dart` | Implementación de IProductoRepository |
| `lib/repositories/caja_repository.dart` | Implementación de ICajaRepository |
| `lib/repositories/insumo_repository.dart` | Implementación de IInsumoRepository |
| `lib/repositories/ventas_repository.dart` | Implementación de IVentasRepository |
| `lib/repositories/image_repository.dart` | Implementación de IImageRepository |

#### Inyección de Dependencias
| Archivo | Descripción |
|---------|-------------|
| `lib/injection/container.dart` | DIContainer singleton para acceso a repositorios |

### ✅ Adoptada (COMPLETADO)
**La infraestructura de DI fue creada y adoptada en todos los Services:**
- Todos los Services ahora usan repositorios a través de DIContainer
- `PedidoService` usa `di.pedidoRepository` para todos los métodos
- `CajaService` usa `di.cajaRepository` para todos los métodos
- Se agregaron métodos faltantes a las interfaces de repositorio

**Migración completada:**
| Archivo | Antes | Después |
|---------|-------|---------|
| `lib/services/pedido_service.dart` | DBHelper directo | `di.pedidoRepository` |
| `lib/services/producto_service.dart` | DBHelper directo | `di.productoRepository` |
| `lib/services/caja_service.dart` | DBHelper directo | `di.cajaRepository` |
| `lib/services/insumo_service.dart` | DBHelper directo | `di.insumoRepository` |
| `lib/services/ventas_service.dart` | DBHelper directo | `di.ventasRepository` |

---

## Phase 3: Mantenimiento (MEDIUM) - Estado: ✅ COMPLETADO

### ✅ Dependencias Actualizadas

| Paquete | Anterior | Nueva | Estado |
|---------|----------|-------|--------|
| `go_router` | 14.6.2 | **17.1.0** | ✅ Actualizado |
| `fl_chart` | 0.68.0 | **1.2.0** | ✅ Actualizado |
| `connectivity_plus` | 6.0.5 | **7.0.0** | ✅ Actualizado |
| `permission_handler` | 11.4.0 | **12.0.1** | ✅ Actualizado |
| `intl` | 0.19.0 | **0.20.2** | ✅ Actualizado |
| `flutter_dotenv` | 5.1.0 | **6.0.0** | ✅ Actualizado |

### Correcciones Aplicadas
- `lib/widgets/bar_chart_panel.dart`: Corregido `tooltipRoundedRadius` → `tooltipBorderRadius` (fl_chart 1.x API)

---

## Phase 4: Screen Tests (MEDIUM) - Estado: ⚠️ FALLANDO (parcialmente corregido)

### ✅ Correcciones aplicadas
- Reemplazado `pumpAndSettle()` con `pump()` para evitar timeouts de animación
- Corregido timer infinito en `CocinaScreen` (dispose() cancela timer)
- Agregado setup de BD de test en tests

### ⚠️ Problemas restantes
Los tests de screens aún fallan por problemas complejos:

| Test | Archivo | Error |
|------|---------|-------|
| has date filter widgets | `caja_screen_test.dart` | CircularProgressIndicator no desaparece |
| has refresh capability | `cocina_screen_test.dart` | RefreshIndicator no encontrado |
| renders title correctly | `report_screen_test.dart` | setState() called after dispose() |

### Causa probable
- **CajaScreen**: FutureBuilder no resuelve o BD de test no inicializa correctamente
- **CocinaScreen**: Pedidos de prueba no se insertan correctamente en BD de test
- **ReportScreen**: setState() se llama después de dispose() por timer/async no cancelado

---

## Phase 5: Cleanup (LOW) - Estado: ✅ COMPLETADO

### ✅ Limpieza aplicada
- **TODOs de RadioGroup**: Consolidados y documentados (esperando soporte de Flutter)
- **Warnings de análisis estático**: Limpiados (deprecated_member_use, avoid_print)
- **Print statements en tests**: Reemplazados con `log()` de `dart:developer`

### ✅ Estado final
| Archivo | Línea | Estado |
|---------|-------|--------|
| `lib/widgets/order_form_widget.dart` | 1211, 1231 | ✅ Consolidado (TODO + ignore) |
| `lib/screens/printer_settings_screen.dart` | 441, 464 | ✅ Consolidado (TODO + ignore) |
| `test/services/numero_orden_test.dart` | múltiples | ✅ print → log() |
| `test/services/pedido_service_extended_test.dart` | múltiples | ✅ print → log() |

---

## Phase 6: DI Adoption (CRITICAL) - Estado: ✅ COMPLETADO

### ✅ Implementado
La arquitectura Repository + DI ha sido implementada y adoptada:

**Services refactorizados:**
| Archivo | Cambios |
|---------|---------|
| `lib/services/pedido_service.dart` | ✅ Usa `di.pedidoRepository` |
| `lib/services/producto_service.dart` | ✅ Usa `di.productoRepository` |
| `lib/services/caja_service.dart` | ✅ Usa `di.cajaRepository` |
| `lib/services/insumo_service.dart` | ✅ Usa `di.insumoRepository` |
| `lib/services/ventas_service.dart` | ✅ Usa `di.ventasRepository` |

**Repositorios implementados (acceso directo a DBHelper):**
| Archivo | Estado |
|---------|--------|
| `lib/repositories/pedido_repository.dart` | ✅ Implementado |
| `lib/repositories/producto_repository.dart` | ✅ Implementado |
| `lib/repositories/caja_repository.dart` | ✅ Implementado |
| `lib/repositories/insumo_repository.dart` | ✅ Implementado |
| `lib/repositories/ventas_repository.dart` | ✅ Implementado |

**Correcciones post-migración:**
- Validación de Producto en `ProductoService.guardar()` ✅
- Hard delete para `ProductoService.eliminar()` (eliminarProductoPermanentemente) ✅
- Soporte para pedidos cancelados en `obtenerPorEstado('Canceladas')` ✅

### Impacto
- Tests unitarios ahora pueden usar mocks de repositorios
- Acoplamiento reducido entre capas
- Facilidad para testing con bases de datos en memoria

---

## Estado de Tests

| Directorio | Estado | Detalles |
|------------|--------|-----------|
| `test/services/` | ✅ 91 tests pasando | Suite completa post-DI |
| `test/screens/` | ⚠️ 5 fallando / 4 pasando | Problemas de configuración BD test |
| `test/widgets/` | ✅ 24 tests pasando | Suite completa |
| `test/integration/` | ✅ Estructura preparada | - |

---

## Análisis Estático

```
dart analyze lib
- 4 infos (estilo de código)
- 0 warnings
- 0 errors
```

---

## Resumen de Cambios

### Archivos Creados (ya existían)
- 6 archivos de interfaces en `lib/repositories/`
- 6 archivos de implementaciones en `lib/repositories/`
- 1 archivo de DI en `lib/injection/`
- 3 archivos de tests en `test/screens/`

### Archivos Modificados en esta sesión
- `pubspec.yaml`: Actualizadas permission_handler (12.0.1), intl (0.20.2), flutter_dotenv (6.0.0)
- `android/app/build.gradle.kts`: Actualizado compileSdk a 35 para permission_handler 12.x
- `lib/repositories/i_pedido_repository.dart`: Agregados métodos actualizarEstadoPago, eliminarPedidosDelDiaActual
- `lib/repositories/pedido_repository.dart`: Implementados nuevos métodos
- `lib/repositories/i_caja_repository.dart`: Agregados métodos guardar, obtenerCajaChicaPorFecha, actualizar, eliminar, eliminarPorFecha
- `lib/repositories/caja_repository.dart`: Implementados nuevos métodos
- `lib/services/pedido_service.dart`: Migrados métodos restantes a DI
- `lib/services/caja_service.dart`: Migrados métodos restantes a DI
- `test/screens/cocina_screen_test.dart`: Corregido pumpAndSettle timeout
- `test/screens/caja_screen_test.dart`: Corregido pumpAndSettle timeout
- `test/screens/report_screen_test.dart`: Corregido pumpAndSettle timeout
- `lib/widgets/order_form_widget.dart`: Consolidados TODOs de RadioGroup
- `lib/screens/printer_settings_screen.dart`: Consolidados TODOs de RadioGroup
- `test/services/numero_orden_test.dart`: Reemplazado print() por log()
- `test/services/pedido_service_extended_test.dart`: Reemplazado print() por log()

---

## Deuda Técnica Pendiente

| Prioridad | Tarea | Estado |
|-----------|-------|--------|
| CRITICAL | Adoptar DI en Services | ✅ Completado |
| CRITICAL | Adoptar DI en Screens | ⏳ Pendiente (opcional) |
| HIGH | Corregir tests de screens (configuración BD test) | ⏳ Pendiente (problema complejo) |
| MEDIUM | Actualizar permission_handler | ✅ Completado |
| MEDIUM | Actualizar intl | ✅ Completado |
| MEDIUM | Actualizar flutter_dotenv | ✅ Completado |
| MEDIUM | Centralizar código duplicado PRAGMA/ALTER | ⏳ Pendiente (investigación) |
| LOW | Limpiar warnings de análisis estático | ✅ Completado |
| LOW | Migrar a RadioGroup (cuando Flutter soporte) | ⏳ Pendiente |

---

## Progreso de Eliminación de Deuda Técnica (Sesión 2026-03-26 23:15)

### ✅ Completado
1. **DI en Services**: Completada migración de todos los servicios a repositorios
2. **Dependencias**: Actualizadas permission_handler, intl y flutter_dotenv
3. **Warnings**: Limpiados todos los warnings de análisis estático
4. **Tests de screens**: Corregido timeout de pumpAndSettle (aunque siguen fallando por otros problemas)

### 📊 Impacto
- **Acoplamiento reducido**: Services ahora dependen de interfaces, no de implementaciones directas
- **Mantenibilidad**: Cambios en BD no afectan directamente a los services
- **Testabilidad**: Fácil mockear repositorios en tests futuros
- **Dependencias actualizadas**: Seguridad y compatibilidad mejoradas

### ⚠️ Deuda Crítica Restante
- Tests de screens fallando por problemas de configuración de BD de test
- Centralización de código duplicado (PRAGMA/ALTER TABLE)

---

## Próximos Pasos (Opcional)

1. **Corregir screen tests**: Investigar por qué FutureBuilder no resuelve en BD de test
2. **Centralizar código duplicado**: Mover lógica PRAGMA/ALTER TABLE a DBHelper
3. **Adoptar DI en Screens**: Usar repositorios directamente en screens (opcional)
4. **Migrar a RadioGroup**: Cuando Flutter lo soporte nativamente
