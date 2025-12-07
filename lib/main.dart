import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/database/db_helper.dart';
import 'services/printer/printer_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno desde archivo .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Advertencia: No se pudo cargar el archivo .env: $e');
    debugPrint('Asegúrate de que el archivo .env existe en la raíz del proyecto.');
  }
  
  // Validar que las variables de entorno estén presentes
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  final clienteId = dotenv.env['CLIENTE_ID'];
  
  if (supabaseUrl == null || supabaseAnonKey == null || clienteId == null) {
    debugPrint('ERROR CRÍTICO: Variables de entorno requeridas no encontradas.');
    debugPrint('Por favor, crea un archivo .env en la raíz del proyecto con:');
    debugPrint('SUPABASE_URL=tu_url_supabase');
    debugPrint('SUPABASE_ANON_KEY=tu_clave_anon');
    debugPrint('CLIENTE_ID=tu_cliente_id');
    throw Exception('Variables de entorno faltantes. Revisa el archivo .env');
  }
  
  // Inicializar Supabase con variables de entorno
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('Supabase inicializado correctamente');
  } catch (e) {
    debugPrint('ERROR: No se pudo inicializar Supabase: $e');
    throw Exception('Error al inicializar Supabase: $e');
  }
  
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
