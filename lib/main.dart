import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_config.dart';
import 'core/config/asset_branding_loader.dart';
import 'core/constants/app_colors.dart';
import 'core/database/db_helper.dart';
import 'services/printer/printer_service.dart';
import 'services/supabase_sync_service.dart';
import 'app_router.dart';

void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      if (details.stack != null) debugPrint('${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('PlatformDispatcher.onError: $error\n$stack');
    }
    return true;
  };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  runZonedGuarded(
    () {
      unawaited(_bootstrapApp());
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Zone error: $error\n$stack');
      }
    },
  );
}

Future<void> _bootstrapApp() async {
  try {
    // En debug: cargar .env desde disco (no se incluye en el bundle de release).
    // En release: usar --dart-define (ver README).
    String? supabaseUrl;
    String? supabaseAnonKey;
    String? clienteId;

    if (kReleaseMode) {
      supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      supabaseAnonKey =
          String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
      clienteId = String.fromEnvironment('CLIENTE_ID', defaultValue: '');
    } else {
      try {
        await dotenv.load(fileName: '.env');
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
        clienteId = dotenv.env['CLIENTE_ID'];
      } catch (e) {
        if (kDebugMode) debugPrint('Advertencia: no se pudo cargar .env');
      }
    }

    final bool supabaseEnvOk = supabaseUrl != null &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey != null &&
        supabaseAnonKey.isNotEmpty;

    if (!supabaseEnvOk ||
        clienteId == null ||
        clienteId.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'Modo degradado: faltan SUPABASE_URL, SUPABASE_ANON_KEY o CLIENTE_ID. '
          'La app arranca en local; en debug usa .env; en release usa --dart-define.',
        );
      }
    }

    if (supabaseEnvOk) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        ).timeout(const Duration(seconds: 15));
        if (kDebugMode) debugPrint('Supabase inicializado correctamente');
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Supabase: timeout al inicializar (continuando sin Supabase): $e',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error al inicializar Supabase (continuando sin Supabase): $e');
        }
      }
    } else if (kDebugMode) {
      debugPrint('Supabase no inicializado (URL o anon key vacíos).');
    }

    try {
      await DBHelper.initialize();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('DBHelper.initialize: $e\n$st');
      }
    }

    if (PrinterService.isPlatformSupported()) {
      try {
        final printerService = PrinterService();
        await printerService.initialize();
      } catch (e) {
        debugPrint('Advertencia: No se pudo inicializar el servicio de impresión: $e');
      }
    }

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SystemChrome.setPreferredOrientations: $e\n$st');
      }
    }

    try {
      await DBHelper.db;
    } catch (e) {
      debugPrint('Error al inicializar base de datos: $e');
    }

    SupabaseSyncService.syncDailyReportsInBackground().catchError(
      (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('syncDailyReportsInBackground: $e\n$st');
        }
      },
    );

    try {
      final branding = await AssetBrandingLoader().load();
      AppConfig.instance.initFromBranding(branding);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Branding: no se pudo cargar, usando valores por defecto: $e');
      }
    }

    runApp(const VacosApp());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Bootstrap: error no manejado antes de runApp: $e\n$st');
    }
    runApp(const VacosApp());
  }
}

class VacosApp extends StatelessWidget {
  const VacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
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
      routerConfig: appRouter,
    );
  }
}
