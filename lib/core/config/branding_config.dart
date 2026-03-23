import 'package:flutter/material.dart';

/// Modelo de configuración de marca cargado desde asset o remoto.
class BrandingConfig {
  final String appName;
  final String appSubtitle;
  final Color primary;
  final Color background;
  final Color accent;
  final Color cardBackground;
  final List<String> features;
  final int? schemaVersion;
  final String? logoUrl;
  final String? logoAssetPath;

  const BrandingConfig({
    required this.appName,
    required this.appSubtitle,
    required this.primary,
    required this.background,
    required this.accent,
    required this.cardBackground,
    required this.features,
    this.schemaVersion,
    this.logoUrl,
    this.logoAssetPath,
  });

  /// Feature IDs por defecto cuando no hay config válida.
  static const List<String> defaultFeatureIds = [
    'productos',
    'pedidos',
    'cocina',
    'insumos',
    'reportes',
    'caja',
    'impresora',
    'pruebas',
  ];

  bool hasFeature(String id) => features.contains(id);
}
