# De Vacos Urban Grill POS

Aplicación de Point of Sale (POS) multiplataforma para el restaurante "De Vacos Urban Grill". Construida con Flutter/Dart, SQLite local y sincronización con Supabase.

## Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/de_vacos.git
cd de_vacos

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno (ver Configuración)
#    - Crear archivo .env en la raíz con SUPABASE_URL, SUPABASE_ANON_KEY, CLIENTE_ID

# 4. Ejecutar en modo desarrollo
flutter run
```

## Características

- **POS completo**: Gestión de productos, pedidos, caja, cocina e inventario.
- **Base de datos local**: SQLite con migraciones, funciona offline.
- **Sincronización en la nube**: Supabase para licencias, reportes y cobros.
- **Panel web admin**: Vistas read-only para reportes, licencias y cobros.
- **Impresión térmica**: Soporte para impresoras USB/Bluetooth.
- **Branding dinámico**: Configurable vía `assets/config/branding.json`.

## Prerrequisitos

- Flutter SDK 3.7.2 o superior
- Dart
- Android Studio / VS Code con plugins de Flutter
- (Opcional) Node.js para herramientas de desarrollo

## Instalación

1. **Clonar repositorio**:
   ```bash
   git clone https://github.com/tu-usuario/de_vacos.git
   cd de_vacos
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**:
   - **Desarrollo (debug)**: Crear archivo `.env` en la raíz con:
     ```
     SUPABASE_URL=tu_url
     SUPABASE_ANON_KEY=tu_clave
     CLIENTE_ID=tu_cliente_id
     ```
   - **Producción (release)**: Usar `--dart-define` en el build:
     ```bash
     flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=CLIENTE_ID=...
     ```

4. **Ejecutar**:
   ```bash
   flutter run
   ```

## Uso

### Ejemplo básico
1. Iniciar sesión en la app (la primera vez carga datos de ejemplo).
2. Navegar a **Productos** para agregar ítems al menú.
3. Crear un **Pedido** seleccionando productos.
4. En **Cocina** ver los pedidos pendientes.
5. En **Caja** registrar pagos y ver reportes.

### Panel web
Ejecutar en navegador:
```bash
flutter run -d chrome
```
Luego acceder a:
- `/panel/reportes` – Reportes semanales
- `/panel/licencias` – Gestión de licencias
- `/panel/cobros` – Cobros pendientes

## Configuración avanzada

- **Branding**: Personalizar nombre, colores y funcionalidades en `assets/config/branding.json`. Ver [Guía de Branding](docs/LICENCIAS_Y_REPORTES.md#configuración-de-marca-brandingjson).
- **Licencias y reportes**: Configurar política de gracia, envío de datos a Supabase. Ver [Guía de Licencias](docs/LICENCIAS_Y_REPORTES.md).
- **Ofuscación**: Para builds de producción, ofuscar código:
  ```bash
  flutter build apk --obfuscate --split-debug-info=build/symbols
  ```

## Arquitectura

Arquitectura basada en Flutter con separación de capas (UI → Logic → Data). Para detalles completos ver [Arquitectura del proyecto](docs/architecture.md).

### Estructura principal
```
lib/
├── models/         # DTOs (Pedido, Producto, Caja, etc.)
├── services/       # Lógica de negocio (estática)
├── core/           # Configuración, base de datos, constantes
├── screens/        # 15 pantallas de la app
├── widgets/        # Componentes reutilizables
├── panel/          # Vistas web de admin
└── app_router.dart # Navegación con GoRouter
```

### Reglas de navegación
Usar siempre `context.go()` o `context.push()` de GoRouter. **No usar** `Navigator.of(context).pushReplacement()`.

## Tests

Ejecutar todos los tests:
```bash
flutter test
```

Cobertura actual: 91 tests unitarios en servicios, 24 tests de widgets, algunos tests de screens pendientes.

## Contribuir

Ver [Guía de Contribución](docs/contributing.md) (próximamente).

## Documentación completa

- [Licencias y Reportes](docs/LICENCIAS_Y_REPORTES.md)
- [Arquitectura del Proyecto](docs/architecture.md)
- [Deuda Técnica](docs/deuda-tecnica.md)

## Licencia

Propietario – De Vacos Urban Grill. Todos los derechos reservados.
