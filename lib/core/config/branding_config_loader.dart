import 'branding_config.dart';

/// Cargador abstracto de configuración de marca (asset, remoto, etc.).
abstract class BrandingConfigLoader {
  Future<BrandingConfig> load();
}
