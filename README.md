# De Vacos Urban Grill — POS App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=for-the-badge)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-v11-003B57?logo=sqlite&logoColor=white&style=for-the-badge)](https://www.sqlite.org)
[![Supabase](https://img.shields.io/badge/Supabase-cloud-3ECF8E?logo=supabase&logoColor=white&style=for-the-badge)](https://supabase.com)

[![Tests](https://img.shields.io/badge/✓%20tests-192%20passing-22863a?style=flat-square)](https://github.com/ElMichi08/de_vacos)
[![Pre-commit](https://img.shields.io/badge/pre--commit-analyze%20%2B%20test-blueviolet?style=flat-square)](https://github.com/ElMichi08/de_vacos)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-555?style=flat-square)](https://github.com/ElMichi08/de_vacos)
[![License](https://img.shields.io/badge/license-Proprietary-red?style=flat-square)](https://github.com/ElMichi08/de_vacos)

<br/>

> **App Flutter/Dart offline-first que digitalizó operaciones completas de un restaurante de alto volumen,
> reemplazando un proceso 100% manual.**
>
>  **Resultado: ingresos escalaron 5× desde la implementación.**

</div>

---

## 🎯 El problema que resuelve

El restaurante gestionaba pedidos, caja e inventario de forma completamente manual — errores de despacho frecuentes, cierre de caja caótico y pagos registrados por WhatsApp. Esta app reemplazó todo ese flujo con un sistema POS **offline-first** que funciona sin conexión y sincroniza con la nube cuando hay red.

<div align="center">

| ❌ Antes | ✅ Después |
|:---------|:-----------|
| Pedidos en papel, errores de despacho constantes | POS digital con pantalla de cocina en tiempo real |
| Cobros registrados por WhatsApp | Cobros mixtos: hasta 3 métodos de pago por pedido |
| Sin visibilidad de inventario | Control de stock en tiempo real, previene sobreventa |
| Reportes inexistentes | Panel web admin con ventas y top productos |
| Capacidad de atención limitada | **Ingresos 5× desde la implementación** 🚀 |

</div>

---

## Características principales

<table>
<tr>
<td width="50%">

**🖥️ POS completo**
Gestión de productos, pedidos, caja, cocina e inventario en una sola app.

**📴 Offline-first**
SQLite v11 con migraciones incrementales. Funciona sin internet.

**☁️ Sincronización en la nube**
Supabase para licencias, reportes y cobros remotos.

**💳 Multi-pago**
Cobros mixtos (efectivo + transferencia) con hasta 3 pagos por pedido.

</td>
<td width="50%">

**🖨️ Impresión térmica**
Soporte para impresoras USB y Bluetooth.

**🎨 Branding dinámico**
Nombre, colores y features configurables en `branding.json`.

**🔒 Build seguro**
Ofuscación de código en release, variables via `--dart-define`.

</td>
</tr>
</table>

---

## 🚀 Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/ElMichi08/de_vacos.git
cd de_vacos

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
#    Crear archivo .env en la raíz:
#    SUPABASE_URL=tu_url
#    SUPABASE_ANON_KEY=tu_clave
#    CLIENTE_ID=tu_cliente_id

# 4. Ejecutar
flutter run
```

---

## Arquitectura

Separación estricta de capas: **UI → Services → Repositories → SQLite**

```
lib/
├── 📁 models/          # DTOs: Pedido, Producto, Caja, Insumo, Modalidad...
├── 📁 services/        # Lógica de negocio (estática)
├── 📁 repositories/    # Interfaces + implementaciones SQLite
├── 📁 injection/       # DIContainer (singleton de repositorios)
├── 📁 core/            # SQLite DBHelper v11, BrandingConfig
├── 📁 screens/         # 15 pantallas
├── 📁 widgets/         # 20 componentes reutilizables
├── 📁 panel/           # Vistas web admin (Supabase)
└── 📄 app_router.dart  # Navegación con GoRouter
```

>  Reglas de arquitectura: [`.agents/rules/architecture.md`](.agents/rules/architecture.md)
>  Reglas de negocio: [`.agents/rules/business-rules.md`](.agents/rules/business-rules.md)

**Navegación:** usar siempre `context.go()` o `context.push()` — nunca `Navigator.of(context).pushReplacement()`.

---

## Quality Gate

Cada commit pasa automáticamente por un hook pre-commit:

```bash
flutter analyze   # 0 issues requerido
flutter test      # 0 failures — 192+ tests
```

---

##  Instalación detallada

### Prerrequisitos

- Flutter SDK **3.7.2+**
- Dart 3.x
- Android Studio o VS Code con extensión Flutter

### Variables de entorno

**Desarrollo (debug)** — crear `.env` en la raíz:

```env
SUPABASE_URL=tu_url
SUPABASE_ANON_KEY=tu_clave
CLIENTE_ID=tu_cliente_id
```

**Producción (release)**:

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=CLIENTE_ID=...
```

**Build con ofuscación**:

```bash
flutter build apk --obfuscate --split-debug-info=build/symbols
```

---

## Uso

1. Iniciar la app — la primera vez carga datos de ejemplo vía **Test Data**
2. Ir a **Productos** para configurar el menú
3. Crear un **Pedido** desde la pantalla de órdenes
4. En **Cocina** monitorear pedidos pendientes en tiempo real
5. En **Caja** registrar pagos y ver el resumen diario
6. En **Reportes** consultar ventas, top productos y filtrar por método de pago

### Panel web admin

```bash
flutter run -d chrome
```

| Ruta | Contenido |
|------|-----------|
| `/panel/reportes` | Ventas y métricas |
| `/panel/licencias` | Gestión de licencias |
| `/panel/cobros` | Historial de cobros |

---

## Configuración avanzada

- **Branding**: personalizar en `assets/config/branding.json`
- **Licencias**: ver [Guía de Licencias](docs/LICENCIAS_Y_REPORTES.md)

---

## 📄 Licencia

Propietario — Gabriel Vaca. Todos los derechos reservados.
