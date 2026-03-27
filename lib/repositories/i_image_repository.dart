abstract class IImageRepository {
  Future<String> guardarImagen(dynamic imageData);
  Future<void> eliminarImagen(String path);
}
