# De Vacos Urban Grill — POS App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=for-the-badge)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-v11-003B57?logo=sqlite&logoColor=white&style=for-the-badge)](https://www.sqlite.org)
[![Supabase](https://img.shields.io/badge/Supabase-cloud-3ECF8E?logo=supabase&logoColor=white&style=for-the-badge)](https://supabase.com)

[![Pre-commit](https://img.shields.io/badge/pre--commit-analyze%20%2B%20test-blueviolet?style=flat-square)](https://github.com/ElMichi08/de_vacos)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-555?style=flat-square)](https://github.com/ElMichi08/de_vacos)
[![License](https://img.shields.io/badge/license-Proprietary-red?style=flat-square)](https://github.com/ElMichi08/de_vacos)

</div>

App POS en Flutter/Dart, offline-first, que desarrollé para De Vacos Urban Grill, el negocio de comida rápida de mi familia en Latacunga. Reemplazó un proceso 100% manual y está en uso diario desde [mes y año].

**Resultado:** el negocio pasó de ~40 a más de 100 pedidos diarios, con picos de 160, y la app sostuvo ese volumen sin cambios en el proceso operativo.

---

## El problema que resuelve

El negocio gestionaba pedidos, caja e inventario a mano. Había errores de despacho frecuentes, el cierre de caja era desordenado y los pagos se registraban por WhatsApp. La app reemplazó todo ese flujo con un POS offline-first que funciona sin conexión y sincroniza con la nube cuando hay red.

| Antes | Después |
|:------|:--------|
| Pedidos en papel, errores de despacho frecuentes | POS digital con pantalla de cocina en tiempo real |
| Cobros registrados por WhatsApp | Cobros mixtos: hasta 3 métodos de pago por pedido |
| Sin visibilidad de inventario | Control de stock en tiempo real que evita la sobreventa |
| Sin reportes | Panel web de administración con ventas y productos más vendidos |
| ~40 pedidos diarios | Más de 100 pedidos diarios (picos de 160) con el mismo proceso |

<!-- Recomendado: agrega 2 o 3 capturas (pantalla de pedidos, cocina, caja) en docs/img/ y enlázalas aquí. -->

---

## Características principales

| | |
|:--|:--|
| **POS completo:** productos, pedidos, caja, cocina e inventario en una sola app. | **Impresión térmica:** impresoras USB y Bluetooth. |
| **Offline-first:** SQLite v11 con migraciones incrementales; funciona sin internet. | **Branding configurable:** nombre, colores y features en `branding.json`. |
| **Sincronización en la nube:** Supabase para licencias, reportes y cobros remotos. | **Build seguro:** ofuscación en release y variables vía `--dart-define`. |
| **Multi-pago:** efectivo y transferencia, hasta 3 pagos por pedido. | |

---

## Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/ElMichi08/de_vacos.git
cd de_vacos

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno (ver env.example)
#    Crear archivo .env en la raíz:
#    SUPABASE_URL=tu_url
#    SUPABASE_ANON_KEY=tu_clave
#    CLIENTE_ID=tu_cliente_id

# 4. Ejecutar
flutter run
```

---

## Arquitectura

Separación de capas: **UI → Services → Repositories → SQLite**

```
lib/
├── models/          # DTOs: Pedido, Producto, Caja, Insumo, Modalidad...
├── services/        # Lógica de negocio
├── repositories/    # Interfaces + implementaciones SQLite
├── injection/       # DIContainer (singleton de repositorios)
├── core/            # SQLite DBHelper v11, BrandingConfig
├── screens/         # 15 pantallas
├── widgets/         # 20 componentes reutilizables
├── panel/           # Vistas web de administración (Supabase)
└── app_router.dart  # Navegación con GoRouter
```

- Reglas de arquitectura: [`.agents/rules/architecture.md`](.agents/rules/architecture.md)
- Reglas de negocio: [`.agents/rules/business-rules.md`](.agents/rules/business-rules.md)

**Convención de navegación:** usar siempre `context.go()` o `context.push()`, nunca `Navigator.of(context).pushReplacement()`.

---

## Cómo se desarrolló

Definí las reglas de negocio y de arquitectura (en `.agents/rules/`) y desarrollé la app con un agente de IA trabajando sobre esas reglas, revisando los cambios antes de integrarlos. Los tests también se generaron con IA a partir de las reglas de negocio que definí.

### Quality gate

Un hook pre-commit bloquea cualquier commit si alguna de estas verificaciones falla:

```bash
flutter analyze   # 0 issues
flutter test      # 0 failures
```

---

## Instalación detallada

### Prerrequisitos

- Flutter SDK **3.7.2+**
- Dart 3.x
- Android Studio o VS Code con la extensión de Flutter

### Variables de entorno

**Desarrollo (debug):** crear `.env` en la raíz:

```env
SUPABASE_URL=tu_url
SUPABASE_ANON_KEY=tu_clave
CLIENTE_ID=tu_cliente_id
```

**Producción (release):**

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=CLIENTE_ID=...
```

**Build con ofuscación:**

```bash
flutter build apk --obfuscate --split-debug-info=build/symbols
```

---

## Uso

1. Iniciar la app. La primera vez carga datos de ejemplo vía **Test Data**.
2. Ir a **Productos** para configurar el menú.
3. Crear un **Pedido** desde la pantalla de órdenes.
4. En **Cocina**, monitorear los pedidos pendientes en tiempo real.
5. En **Caja**, registrar pagos y ver el resumen diario.
6. En **Reportes**, consultar ventas y productos más vendidos, y filtrar por método de pago.

## Configuración avanzada

- **Branding:** personalizar en `assets/config/branding.json`.
- **Licencias:** ver la [Guía de Licencias](docs/LICENCIAS_Y_REPORTES.md).

---

## Licencia

Propietario — Gabriel Vaca. Todos los derechos reservados.
