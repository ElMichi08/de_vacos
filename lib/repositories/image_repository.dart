import 'dart:io';
import 'package:de_vacos/services/image_service.dart';
import 'package:de_vacos/repositories/i_image_repository.dart';

class ImageRepository implements IImageRepository {
  @override
  Future<String> guardarImagen(dynamic imageData) async {
    if (imageData is File) {
      return ImageService.comprimirYGuardar(imageData);
    }
    throw ArgumentError('Expected File');
  }

  @override
  Future<void> eliminarImagen(String path) async {
    await ImageService.eliminar(path);
  }
}
