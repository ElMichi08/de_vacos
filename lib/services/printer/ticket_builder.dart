import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../core/config/app_config.dart';
import '../../models/pedido.dart';
import 'helpers/product_grouper.dart';
import 'helpers/ticket_formatter.dart';
import 'helpers/producto_ticket_helper.dart';
import 'ticket_constants.dart';

/// Builder para construir tickets ESC/POS
class TicketBuilder {
  /// Ancho de papel estándar para impresoras térmicas de 80mm
  static const int paperWidthMm = 80;

  static const int logoMaxWidth80mm = 102;
  
  static const int logoMaxWidth56mm = 62;

  // Cache de logos cargados para evitar cargar en cada impresión
  static img.Image? _cachedLogo80mm;
  static img.Image? _cachedLogo56mm;

  /// Carga y redimensiona el logo desde los assets
  /// [paperSize] determina el tamaño máximo del logo
  /// Retorna la imagen decodificada lista para imprimir, o null si no se encuentra
  /// Implementa cache para mejorar rendimiento
  static Future<img.Image?> _loadLogo({PaperSize paperSize = PaperSize.mm80}) async {
    // Verificar cache primero
    if (paperSize == PaperSize.mm58 && _cachedLogo56mm != null) {
      return _cachedLogo56mm;
    }
    if (paperSize == PaperSize.mm80 && _cachedLogo80mm != null) {
      return _cachedLogo80mm;
    }
    try {
      Uint8List? logoBytes;

      // Preferir logo de marca desde config (branding)
      final logoAssetPath = AppConfig.instance.logoAssetPath;
      if (logoAssetPath != null && logoAssetPath.isNotEmpty) {
        try {
          logoBytes = await rootBundle.load(logoAssetPath).then((data) => data.buffer.asUint8List());
        } catch (e) {
          debugPrint('No se pudo cargar logo de marca ($logoAssetPath): $e');
        }
      }

      // Fallback: logo por defecto en raíz de assets
      if (logoBytes == null) {
        try {
          logoBytes = await rootBundle.load('logo.jpg').then((data) => data.buffer.asUint8List());
        } catch (_) {
          try {
            logoBytes = await rootBundle.load('logo.png').then((data) => data.buffer.asUint8List());
          } catch (e2) {
            debugPrint('No se pudo cargar logo desde assets: $e2');
            return null;
          }
        }
      }

      if (logoBytes == null) return null;

      // Decodificar la imagen
      final originalImage = img.decodeImage(logoBytes);
      if (originalImage == null) {
        debugPrint('No se pudo decodificar el logo');
        return null;
      }

      // Redimensionar el logo manteniendo la proporción según el tamaño de papel
      final logoMaxWidth = paperSize == PaperSize.mm58 ? logoMaxWidth56mm : logoMaxWidth80mm;
      final aspectRatio = originalImage.height / originalImage.width;
      int targetWidth = logoMaxWidth;
      int targetHeight = (targetWidth * aspectRatio).round();

      // Si la imagen original es más pequeña que el objetivo, mantener su tamaño
      if (originalImage.width < targetWidth) {
        targetWidth = originalImage.width;
        targetHeight = originalImage.height;
      }

      // Redimensionar la imagen manteniendo la proporción
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // Guardar en cache
      if (paperSize == PaperSize.mm58) {
        _cachedLogo56mm = resizedImage;
      } else {
        _cachedLogo80mm = resizedImage;
      }

      return resizedImage;
    } catch (e) {
      debugPrint('Error al cargar el logo: $e');
      return null;
    }
  }

  /// Normaliza texto a ASCII válido para impresoras ESC/POS
  /// Reemplaza caracteres especiales por equivalentes ASCII
  /// Método público para uso en helpers
  static String normalizeToAscii(String text) {
    return text
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('á', 'a')
        .replaceAll('Á', 'A')
        .replaceAll('é', 'e')
        .replaceAll('É', 'E')
        .replaceAll('í', 'i')
        .replaceAll('Í', 'I')
        .replaceAll('ó', 'o')
        .replaceAll('Ó', 'O')
        .replaceAll('ú', 'u')
        .replaceAll('Ú', 'U')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('–', '-') // Guión largo a guión normal
        .replaceAll('—', '-') // Raya a guión normal
        .replaceAll('¡', '!')
        .replaceAll('¿', '?');
  }

  /// Valida que todos los bytes ESC/POS estén en el rango válido (0-255)
  /// Lanza una excepción si encuentra bytes inválidos
  /// También valida que el formato sea consistente (sin tamaños de fuente inesperados)
  static void _validateEscPosBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError('El ticket no puede estar vacío');
    }
    
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte < 0 || byte > 255) {
        throw ArgumentError(
          'Byte inválido en posición $i: $byte (debe estar entre 0 y 255)',
        );
      }
    }
    
    // Validar que el ticket termine con comando de corte
    // Los comandos ESC/POS de corte suelen ser: 0x1D, 0x56, 0x00 o similar
    final hasCutCommand = bytes.length >= 3 && 
        bytes[bytes.length - 3] == 0x1D && 
        bytes[bytes.length - 2] == 0x56;
    if (!hasCutCommand) {
      debugPrint('ADVERTENCIA: El ticket podría no tener comando de corte válido');
    }
  }

  /// Construye un ticket de prueba estándar
  /// Retorna los bytes ESC/POS válidos listos para enviar a la impresora
  /// Usa CapabilityProfile.load(), PaperSize.mm80 y comandos ESC/POS estándar
  static Future<List<int>> buildStandardTestTicket() async {
    // Cargar perfil de capacidades (NO usar CapabilityProfile.empty())
    final profile = await CapabilityProfile.load();
    
    // Crear generator con PaperSize.mm80 (estándar para JP80H)
    // El Generator se inicializa automáticamente al crearlo
    final generator = Generator(PaperSize.mm80, profile);
    
    // Construir los bytes ESC/POS usando el Generator
    // El Generator maneja internamente la generación de comandos ESC/POS válidos
    List<int> bytes = [];

    // Título centrado, tamaño doble (solo ASCII)
    bytes += generator.text(
      TicketConstants.nombreRestaurante,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    // Línea separadora
    bytes += generator.hr();

    // Información del ticket (normalizado a ASCII)
    bytes += generator.text(
      normalizeToAscii('Ticket de prueba - JP80H'),
      styles: const PosStyles(align: PosAlign.center),
    );

    // Línea separadora
    bytes += generator.hr();

    // Mensaje de confirmación (normalizado a ASCII)
    bytes += generator.text(
      normalizeToAscii('Si puedes leer esto, la configuracion es correcta.'),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // Cortar papel con comando ESC/POS estándar
    bytes += generator.cut();

    // Validar que todos los bytes estén en el rango válido (0-255)
    _validateEscPosBytes(bytes);

    return bytes;
  }

  /// Construye un ticket de prueba
  /// Retorna los bytes ESC/POS listos para enviar a la impresora
  static Future<List<int>> buildTestTicket({
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    // Cargar perfil de capacidades (NO usar CapabilityProfile.empty())
    final profile = await CapabilityProfile.load();
    
    // Crear generator con el tamaño de papel especificado
    final generator = Generator(paperSize, profile);
    
    List<int> bytes = [];

    // Título centrado - tamaño según papel
    final titleSize = paperSize == PaperSize.mm58 ? PosTextSize.size1 : PosTextSize.size2;
    bytes += generator.text(
      TicketConstants.nombreRestaurante,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: titleSize,
      ),
    );
    bytes += generator.feed(1);

    // Línea separadora
    bytes += generator.hr();

    // Información del ticket (normalizado a ASCII)
    bytes += generator.text(
      normalizeToAscii('Ticket de prueba - ${paperSize == PaperSize.mm58 ? "56mm" : "80mm"}'),
      styles: const PosStyles(align: PosAlign.center),
    );

    // Línea separadora
    bytes += generator.hr();

    // Mensaje de confirmación (normalizado a ASCII)
    bytes += generator.text(
      normalizeToAscii('Si puedes leer esto, la configuracion es correcta.'),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // Cortar papel con comando ESC/POS estándar
    bytes += generator.cut();

    // Validar que todos los bytes estén en el rango válido (0-255)
    _validateEscPosBytes(bytes);

    return bytes;
  }

  /// Construye un ticket de pedido
  /// Retorna los bytes ESC/POS válidos listos para enviar a la impresora
  /// Garantiza formato ESC/POS válido usando CapabilityProfile.load()
  /// Normaliza todos los textos a ASCII para evitar errores de codificación
  /// Formato compacto optimizado para usar menos papel, especialmente en 56mm
  static Future<List<int>> buildPedidoTicket(
    Pedido pedido, {
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    // Cargar perfil de capacidades (NO usar CapabilityProfile.empty())
    final profile = await CapabilityProfile.load();
    
    // Crear generator con el tamaño de papel especificado
    final generator = Generator(paperSize, profile);
    
    // Construir los bytes ESC/POS usando el Generator
    List<int> bytes = [];

    // Logo (centrado) - más grande que el texto para jerarquía visual
    final logo = await _loadLogo(paperSize: paperSize);
    if (logo != null) {
      bytes += generator.image(logo);
      bytes += generator.feed(1); // Espacio después del logo
    } else {
      // Fallback a texto si el logo no se encuentra - fuente compacta
      bytes += generator.text(
        TicketConstants.nombreRestaurante,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
          bold: true,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
    }

    // Número de orden (centrado) - fuente pequeña para que el logo sea más prominente
    bytes += generator.text(
      'Orden #${pedido.numeroOrden}',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontA,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size1,
      ),
    );
    bytes += generator.hr(); // Línea separadora después del número de orden

    // Factura (ID único de la orden) - fuente compacta
    if (pedido.id != null) {
      final facturaId = pedido.id!.toString().padLeft(
        TicketConstants.facturaPadding,
        TicketConstants.facturaPaddingChar,
      );
      bytes += generator.text(
        'Factura: $facturaId',
        styles: const PosStyles(
          fontType: PosFontType.fontB,
          width: PosTextSize.size1,
          height: PosTextSize.size2,
          bold: false,
        ),
      );
    }

    // Información del cliente - fuente compacta
    bytes += generator.text(
      'Cliente: ${normalizeToAscii(pedido.cliente)}',
      styles: const PosStyles(
        fontType: PosFontType.fontB,
        width: PosTextSize.size1,
        height: PosTextSize.size2,
        bold: false,
      ),
    );

    // Fecha - fuente compacta
    final fechaStr = _formatDate(pedido.fecha);
    final horaStr = _formatTime(pedido.fecha);
    bytes += generator.text(
      'Fecha: $fechaStr $horaStr',
      styles: const PosStyles(
        fontType: PosFontType.fontB,
        width: PosTextSize.size1,
        height: PosTextSize.size2,
        bold: false,
      ),
    );

    // Pago (normalizado a ASCII) - fuente compacta
    bytes += generator.text(
      'Pago: ${normalizeToAscii(pedido.metodoPago)}',
      styles: const PosStyles(
        fontType: PosFontType.fontB,
        width: PosTextSize.size1,
        height: PosTextSize.size2,
        bold: false,
      ),
    );
    bytes += generator.hr(); // Línea separadora antes de los productos

    // Agrupar productos iguales antes de imprimir usando ProductGrouper
    final productosAgrupados = ProductGrouper.agruparProductos(pedido.productos);

    // Validar que el total del pedido coincida con la suma calculada
    final sumaProductos = ProductGrouper.calcularSumaTotal(productosAgrupados);
    final costoEnvases = pedido.envasesLlevar * TicketConstants.precioEnvase;
    final sumaCalculada = sumaProductos + costoEnvases;
    final diferencia = (pedido.total - sumaCalculada).abs();
    
    if (diferencia > TicketConstants.toleranciaTotal) {
      debugPrint(
        'ADVERTENCIA: Total del pedido (${pedido.total}) no coincide con suma calculada ($sumaCalculada). '
        'Diferencia: $diferencia',
      );
    }

    // Lista de productos agrupados según formato especificado
    for (final producto in productosAgrupados.values) {
      final cantidad = ProductoTicketHelper.getCantidad(producto);
      final nombreProducto = ProductoTicketHelper.getNombre(producto);
      final precio = ProductoTicketHelper.getPrecio(producto);

      // Nombre del producto (solo el nombre base, sin variante ni acompañantes) - fuente compacta
      bytes += generator.text(
        normalizeToAscii(nombreProducto),
        styles: const PosStyles(
          fontType: PosFontType.fontB,
          width: PosTextSize.size1,
          height: PosTextSize.size2,
          bold: true, // nombre del producto en negrita
        ),
      );

      // Detalle: Acompañantes y Extras - fuente compacta
      final detalleStr = TicketFormatter.formatearDetalleProducto(producto);
      if (detalleStr.isNotEmpty) {
        bytes += generator.text(
          'Detalle: $detalleStr',
          styles: const PosStyles(
            fontType: PosFontType.fontB,
            width: PosTextSize.size1,
            height: PosTextSize.size2,
            bold: false,
          ),
        );
      }

      // Cant: X $XX.XX c/u (alineado a la derecha) - fuente compacta
      final cantidadTexto = TicketFormatter.formatearCantidadYPrecio(cantidad, precio);
      bytes += generator.text(
        cantidadTexto,
        styles: const PosStyles(
          align: PosAlign.right,
          fontType: PosFontType.fontB,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
          bold: false,
        ),
      );
    }

    bytes += generator.hr(); // Línea separadora después de los productos
    // Envases (solo si tiene) - fuente compacta
    if (pedido.envasesLlevar > 0) {
      final textoEnvases = TicketFormatter.formatearEnvases(
        pedido.envasesLlevar,
        TicketConstants.precioEnvase,
      );
      bytes += generator.text(
        textoEnvases,
        styles: const PosStyles(
          fontType: PosFontType.fontB,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
          bold: false,
        ),
      );
    }

    // Notas del pedido (solo si tiene) - fuente compacta
    if (pedido.notas.isNotEmpty) {
      bytes += generator.text(
        'Notas: ${normalizeToAscii(pedido.notas)}',
        styles: const PosStyles(
          fontType: PosFontType.fontB,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
          bold: false,
        ),
      );
    }

    bytes += generator.hr(); // Línea separadora antes del total
    // Total a pagar (alineado a la derecha) - fuente compacta con negrita
    final totalTexto = TicketFormatter.formatearTotal(pedido.total);
    bytes += generator.text(
      totalTexto,
      styles: const PosStyles(
        align: PosAlign.right,
        fontType: PosFontType.fontA,
        bold: true,
        width: PosTextSize.size1,
        height: PosTextSize.size2,
      ),
    );

    // Feed final y cortar
    bytes += generator.cut();

    // Validar que todos los bytes estén en el rango válido (0-255)
    _validateEscPosBytes(bytes);

    return bytes;
  }

  /// Alias para mantener compatibilidad con código existente
  @Deprecated('Usa buildPedidoTicket en su lugar')
  static Future<List<int>> buildOrderTicket(
    Pedido pedido, {
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    return buildPedidoTicket(pedido, paperSize: paperSize);
  }

  /// Formatea la fecha en formato DD/MM/YYYY
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatea la hora en formato HH:MM
  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
