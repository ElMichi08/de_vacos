import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Valores por defecto cuando AppConfig no está inicializado (tests o antes de init).
const Color _defaultPrimary = Color(0xFFA32D13);
const Color _defaultBackground = Color(0xFF2B1E1A);
const Color _defaultAccent = Colors.orangeAccent;
const Color _defaultCardBackground = Color(0xFF3B2C24);

/// Paleta de colores centralizada de la aplicación.
/// primary, background, accent y cardBackground leen de AppConfig cuando está inicializado;
/// si no (tests o antes de init), se usan constantes por defecto.
class AppColors {
  // Colores dinámicos desde branding (o defaults)
  static Color get primary =>
      AppConfig.branding?.primary ?? _defaultPrimary;
  static Color get background =>
      AppConfig.branding?.background ?? _defaultBackground;
  static Color get cardBackground =>
      AppConfig.branding?.cardBackground ?? _defaultCardBackground;
  static Color get accent => AppConfig.branding?.accent ?? _defaultAccent;

  // Colores fijos (no definidos en branding)
  static const Color drawerBackground = Color(0xFF1E1512);
  static const Color alternateBackground = Color(0xFF33251F);

  // Colores de acento y estado
  static const Color success = Color(0xFF28A745);
  static const Color successDark = Color(0xFF117C2A);
  static const Color error = Colors.redAccent;
  static const Color highlight = Color(0xFFFFA726);
  static const Color price = Color(0xFF66BB6A);

  AppColors._();
}
