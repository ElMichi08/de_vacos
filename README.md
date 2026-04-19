# De Vacos Urban Grill POS

Aplicación de Point of Sale (POS) multiplataforma para el restaurante "De Vacos Urban Grill". Construida con Flutter/Dart, SQLite local y sincronización con Supabase.

## Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/ElMichi08/de_vacos.git
cd de_vacos

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno (ver Configuración)
#    Crear archivo .env en la raíz con SUPABASE_URL, SUPABASE_ANON_KEY, CLIENTE_ID

# 4. Ejecutar en modo desarrollo
flutter run
```

## Características

- **POS completo**: Gestión de productos, pedidos, caja, cocina e inventario.
- **Base de datos local**: SQLite v11 con migraciones incrementales, funciona offline.
- **Sincronización en la nube**: Supabase para licencias, reportes y cobros.
- **Multi-pago**: Soporte para cobros mixtos (efectivo + transferencia) con hasta 3 pagos por pedido.
- **Panel web admin**: Vistas read-only para reportes, licencias y cobros.
- **Impresión térmica**: Soporte para impresoras USB/Bluetooth.
- **Branding dinámico**: Configurable vía `assets/config/branding.json`.

## Prerrequisitos

- Flutter SDK 3.7.2 o superior
- Dart
- Android Studio / VS Code con plugins de Flutter

## Instalación

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Configurar variables de entorno**:
   - **Desarrollo (debug)**: Crear archivo `.env` en la raíz:
     ```
     SUPABASE_URL=tu_url
     SUPABASE_ANON_KEY=tu_clave
     CLIENTE_ID=tu_cliente_id
     ```
   - **Producción (release)**:
     ```bash
     flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=CLIENTE_ID=...
     ```

3. **Ejecutar**:
   ```bash
   flutter run
   ```

## Uso

1. Iniciar la app (la primera vez carga datos de ejemplo vía Test Data).
2. Navegar a **Productos** para agregar ítems al menú.
3. Crear un **Pedido** desde la pantalla de órdenes.
4. En **Cocina** ver los pedidos pendientes en tiempo real.
5. En **Caja** registrar pagos, recobros y ver el resumen diario.
6. En **Reportes** consultar ventas, top productos y filtrar por método de pago.

### Panel web
```bash
flutter run -d chrome
```
Rutas disponibles: `/panel/reportes`, `/panel/licencias`, `/panel/cobros`.

## Arquitectura

Basada en Flutter con separación de capas UI → Services → Repositories → SQLite.

```
lib/
├── models/         # DTOs (Pedido, Producto, Caja, Insumo, Modalidad...)
├── services/       # Lógica de negocio (estática)
├── repositories/   # Acceso a datos (interfaces + implementaciones SQLite)
├── injection/      # DIContainer (singleton de repositorios)
├── core/           # SQLite DBHelper v11, BrandingConfig
├── screens/        # 15 pantallas
├── widgets/        # 20 componentes reutilizables
├── panel/          # Vistas web de admin (Supabase)
└── app_router.dart # Navegación con GoRouter
```

Reglas detalladas: `.agents/rules/architecture.md`  
Reglas de negocio: `.agents/rules/business-rules.md`

### Navegación
Usar siempre `context.go()` o `context.push()`. **No usar** `Navigator.of(context).pushReplacement()`.

## Quality Gate

Antes de cada commit el hook pre-commit ejecuta automáticamente:
```bash
flutter analyze   # 0 issues
flutter test      # 0 failures (192+ tests)
```

## Configuración avanzada

- **Branding**: Personalizar nombre, colores y features en `assets/config/branding.json`.
- **Licencias**: Ver [Guía de Licencias](docs/LICENCIAS_Y_REPORTES.md).
- **Ofuscación** (release):
  ```bash
  flutter build apk --obfuscate --split-debug-info=build/symbols
  ```

## Licencia

Propietario – De Vacos Urban Grill. Todos los derechos reservados.
