import 'package:flutter/material.dart';

/// Paleta de colores centralizada de la aplicación
/// Usar estos colores en lugar de valores hardcodeados
class AppColors {
  // Colores principales
  static const Color primary = Color(0xFFA32D13);
  static const Color background = Color(0xFF2B1E1A);
  static const Color drawerBackground = Color(0xFF1E1512);
  static const Color cardBackground = Color(0xFF3B2C24);
  static const Color alternateBackground = Color(0xFF33251F);
  
  // Colores de acento y estado
  static const Color accent = Colors.orangeAccent;
  static const Color success = Color(0xFF28A745);
  static const Color successDark = Color(0xFF117C2A);
  static const Color error = Colors.redAccent;
  static const Color highlight = Color(0xFFFFA726);
  static const Color price = Color(0xFF66BB6A);
  
  // Prevenir instanciación
  AppColors._();
}

