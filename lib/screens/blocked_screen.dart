import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/license_service.dart';
import 'home_screen.dart';

/// Pantalla de bloqueo cuando la licencia está vencida o bloqueada
/// Implementa seguridad para evitar que el usuario salga de la pantalla
class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  bool _verificando = false;

  Future<void> _reintentarConexion() async {
    setState(() {
      _verificando = true;
    });

    try {
      final resultado = await LicenseService.verificarYReportar();
      final licenciaActiva = resultado['licenciaActiva'] as bool;

      if (!mounted) return;

      if (licenciaActiva) {
        // Licencia activa, navegar al Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        // Aún bloqueada, mostrar mensaje
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La licencia sigue bloqueada. Verifique su conexión a internet.',
              ),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _verificando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Bloquear botón de "Atrás" de Android
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de alerta
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  const Text(
                    'Suscripción Vencida',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Mensaje
                  const Text(
                    'Su suscripción ha expirado o ha sido bloqueada.\n\n'
                    'Por favor, contacte a soporte para renovar su licencia.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Botón de reintentar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verificando ? null : _reintentarConexion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _verificando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh),
                                SizedBox(width: 8),
                                Text(
                                  'Reintentar Conexión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

