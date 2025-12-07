import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/license_service.dart';
import 'home_screen.dart';
import 'blocked_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Mostrar splash por al menos 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Verificar licencia y reportar ventas
    try {
      final resultado = await LicenseService.verificarYReportar();
      final licenciaActiva = resultado['licenciaActiva'] as bool;
      
      if (!mounted) return;
      
      if (licenciaActiva) {
        // Licencia activa, navegar al Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Licencia bloqueada, navegar a pantalla de bloqueo
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BlockedScreen()),
        );
      }
    } catch (e) {
      // En caso de error, bloquear por seguridad
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BlockedScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de llamita blanca
            const Icon(
              Icons.local_fire_department,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            // Título
            const Text(
              'De Vacos Urban Grill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Subtítulo
            const Text(
              'Sistema de Gestión de Restaurante',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
