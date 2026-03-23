import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'branding_config.dart';
import 'branding_config_loader.dart';

/// Valores por defecto cuando el JSON falla o está incompleto.
BrandingConfig _defaultBrandingConfig() {
  return BrandingConfig(
    appName: 'De Vacos Urban Grill',
    appSubtitle: 'Sistema de Gestión de Restaurante',
    primary: const Color(0xFFA32D13),
    background: const Color(0xFF2B1E1A),
    accent: Colors.orangeAccent,
    cardBackground: const Color(0xFF3B2C24),
    features: List<String>.from(BrandingConfig.defaultFeatureIds),
    schemaVersion: 1,
    logoUrl: null,
    logoAssetPath: null,
  );
}

/// Parsea un color desde string hex (#RRGGBB o #AARRGGBB). Devuelve null si falla.
Color? _parseColor(dynamic value) {
  if (value == null) return null;
  final s = value is String ? value : value.toString().trim();
  if (s.isEmpty) return null;
  String hex = s.startsWith('#') ? s.substring(1) : s;
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

/// Cargador que lee branding desde assets/config/branding.json.
/// No lanza excepciones por JSON mal formado; usa defaults y debugPrint.
class AssetBrandingLoader implements BrandingConfigLoader {
  AssetBrandingLoader({this.assetPath = 'assets/config/branding.json'});

  final String assetPath;

  @override
  Future<BrandingConfig> load() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic data = _parseJson(jsonString);
      if (data is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('Branding: JSON no es un objeto, usando defaults');
        }
        return _defaultBrandingConfig();
      }

      final schemaVersion = data['schemaVersion'];
      const supportedVersion = 1;
      if (schemaVersion == null ||
          (schemaVersion is! int) ||
          schemaVersion != supportedVersion) {
        if (kDebugMode) {
          debugPrint(
            'Branding: schemaVersion faltante o inválido (esperado $supportedVersion), usando defaults',
          );
        }
        return _defaultBrandingConfig();
      }

      final colors = data['colors'];
      Color? primary;
      Color? background;
      Color? accent;
      Color? cardBackground;
      if (colors is Map<String, dynamic>) {
        primary = _parseColor(colors['primary']);
        background = _parseColor(colors['background']);
        accent = _parseColor(colors['accent']);
        cardBackground = _parseColor(colors['cardBackground']);
      }

      List<String> features = BrandingConfig.defaultFeatureIds;
      final featuresRaw = data['features'];
      if (featuresRaw is List) {
        features =
            featuresRaw
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
        if (features.isEmpty) {
          features = List.from(BrandingConfig.defaultFeatureIds);
        }
      }

      return BrandingConfig(
        appName:
            data['appName'] is String
                ? data['appName'] as String
                : 'De Vacos Urban Grill',
        appSubtitle:
            data['appSubtitle'] is String
                ? data['appSubtitle'] as String
                : 'Sistema de Gestión de Restaurante',
        primary: primary ?? const Color(0xFFA32D13),
        background: background ?? const Color(0xFF2B1E1A),
        accent: accent ?? Colors.orangeAccent,
        cardBackground: cardBackground ?? const Color(0xFF3B2C24),
        features: features,
        schemaVersion: schemaVersion,
        logoUrl: data['logoUrl'] is String ? data['logoUrl'] as String? : null,
        logoAssetPath:
            data['logoAssetPath'] is String
                ? data['logoAssetPath'] as String?
                : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Branding: error al cargar $assetPath: $e');
      return _defaultBrandingConfig();
    }
  }

  static dynamic _parseJson(String source) {
    return convert.jsonDecode(source);
  }
}
