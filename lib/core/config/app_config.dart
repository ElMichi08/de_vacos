import 'branding_config.dart';

/// Configuración de marca expuesta como singleton para título, subtítulo y logo en la app.
/// Se inicializa desde [BrandingConfig] en main (tras cargar branding desde asset o remoto).
class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  BrandingConfig? _branding;

  /// Branding completo (para colores, tema, etc.). Usar [appName] / [appSubtitle] para textos.
  static BrandingConfig? get branding => instance._branding;

  String appName = 'De Vacos Urban Grill';
  String appSubtitle = 'Sistema de Gestión de Restaurante';
  String? logoUrl;
  String? logoAssetPath;

  List<String>? get features => _branding?.features;

  /// true si el feature está habilitado; si features es null o vacío, todos habilitados.
  bool isFeatureEnabled(String id) {
    final f = _branding?.features;
    if (f == null || f.isEmpty) return true;
    return f.contains(id);
  }

  void initFromBranding(BrandingConfig branding) {
    _branding = branding;
    appName = branding.appName;
    appSubtitle = branding.appSubtitle;
    logoUrl = branding.logoUrl;
    logoAssetPath = branding.logoAssetPath;
  }

  /// Para tests: inyectar config sin cargar asset.
  static void initForTest(BrandingConfig branding) {
    instance.initFromBranding(branding);
  }

  /// Para tests: limpiar después de cada test (llamar en tearDown).
  static void reset() {
    instance._branding = null;
    instance.appName = 'De Vacos Urban Grill';
    instance.appSubtitle = 'Sistema de Gestión de Restaurante';
    instance.logoUrl = null;
    instance.logoAssetPath = null;
  }

  bool get hasLogo => (logoUrl != null && logoUrl!.isNotEmpty) ||
      (logoAssetPath != null && logoAssetPath!.isNotEmpty);
}
