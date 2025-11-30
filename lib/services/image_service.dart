import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;

/// Servicio para manejar imágenes
class ImageService {
  /// Comprime y guarda una imagen en el directorio de documentos
  /// Retorna la ruta del archivo comprimido
  static Future<String> comprimirYGuardar(File imageFile, {int quality = 70}) async {
    try {
      // Leer la imagen original
      final originalBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);
      
      if (decodedImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Comprimir la imagen (JPEG)
      final compressedBytes = img.encodeJpg(decodedImage, quality: quality);

      // Obtener el directorio de documentos
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = path_utils.join(dir.path, fileName);

      // Guardar la imagen comprimida
      final compressedFile = File(newPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      return newPath;
    } catch (e) {
      throw Exception('Error al comprimir imagen: $e');
    }
  }

  /// Elimina una imagen del sistema de archivos
  static Future<void> eliminar(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }
}

