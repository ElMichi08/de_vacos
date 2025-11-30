import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/database/db_helper.dart';
import 'services/printer/printer_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar databaseFactory para plataformas de escritorio
  await DBHelper.initialize();
  
  // Inicializar servicio de impresión térmica
  if (PrinterService.isPlatformSupported()) {
    try {
      final printerService = PrinterService();
      await printerService.initialize();
    } catch (e) {
      debugPrint('Advertencia: No se pudo inicializar el servicio de impresión: $e');
    }
  }
  
  // Permitir todas las orientaciones para soportar tablets en horizontal
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Inicializar base de datos
  try {
    await DBHelper.db;
  } catch (e) {
    debugPrint('Error al inicializar base de datos: $e');
  }
  
  runApp(const VacosApp());
}

class VacosApp extends StatelessWidget {
  const VacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'De Vacos Urban Grill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
