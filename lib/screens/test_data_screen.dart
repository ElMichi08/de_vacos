import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../widgets/back_header_widget.dart';
import '../services/test/test_data_service.dart';

/// Pantalla para generar datos de prueba
/// Permite generar múltiples pedidos aleatorios para probar la funcionalidad
class TestDataScreen extends StatefulWidget {
  const TestDataScreen({super.key});

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  bool _isGenerating = false;
  double _progress = 0.0;
  String? _statusMessage;
  String? _errorMessage;
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _generarPedidos(int cantidad) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _statusMessage = 'Iniciando generación de $cantidad pedidos...';
      _errorMessage = null;
    });

    try {
      final pedidosCreados = await TestDataService.generarPedidos(
        cantidad,
        onProgress: (progreso) {
          if (mounted) {
            setState(() {
              _progress = progreso;
              _statusMessage = 'Generando pedidos... ${(progreso * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 1.0;
          _statusMessage = '¡$pedidosCreados pedidos generados exitosamente!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se generaron $pedidosCreados pedidos correctamente'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString();
          _statusMessage = 'Error al generar pedidos';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _eliminarPedidosDelDia() async {
    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Confirmar Eliminación',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de eliminar todos los pedidos del día actual? '
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Eliminando pedidos del día actual...';
      _errorMessage = null;
    });

    try {
      final pedidosEliminados = await TestDataService.eliminarPedidosDelDia();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = 'Se eliminaron $pedidosEliminados pedidos correctamente.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se eliminaron $pedidosEliminados pedidos del día actual'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString();
          _statusMessage = 'Error al eliminar pedidos';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _generarCantidadPersonalizada() {
    final cantidadTexto = _cantidadController.text.trim();
    if (cantidadTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una cantidad'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser un número mayor a 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cantidad > 1000) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Confirmar cantidad grande',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Estás a punto de generar $cantidad pedidos. '
            'Esto puede tomar varios minutos. ¿Continuar?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generarPedidos(cantidad);
              },
              child: Text(
                'Continuar',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _generarPedidos(cantidad);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Generar Datos de Prueba'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Información',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta herramienta genera pedidos aleatorios para probar la funcionalidad del sistema, '
                      'especialmente la numeración de pedidos del 1 al 100 y la paginación.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Se asegurará que haya al menos 2 productos disponibles\n'
                      '• Se crearán productos por defecto si es necesario\n'
                      '• Los pedidos se distribuirán a lo largo del día actual',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de cantidad predefinida
            const Text(
              'Cantidades Predefinidas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCantidadButton(120, '120 pedidos'),
                _buildCantidadButton(210, '210 pedidos'),
                _buildCantidadButton(350, '350 pedidos'),
                _buildCantidadButton(500, '500 pedidos'),
              ],
            ),

            const SizedBox(height: 24),

            // Cantidad personalizada
            const Text(
              'Cantidad Personalizada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Cantidad de pedidos',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Ej: 100',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _generarCantidadPersonalizada,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Generar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sección de eliminación
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Eliminar Pedidos de Prueba',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Elimina todos los pedidos del día actual. '
                      'Útil para limpiar datos de prueba generados.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGenerating ? null : _eliminarPedidosDelDia,
                        icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                        label: const Text(
                          'Eliminar Todos los Pedidos del Día',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Indicador de progreso
            if (_isGenerating || _statusMessage != null) ...[
              Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    children: [
                      if (_isGenerating) ...[
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_statusMessage != null)
                        Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _errorMessage != null ? AppColors.error : Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadButton(int cantidad, String label) {
    return ElevatedButton(
      onPressed: _isGenerating
          ? null
          : () {
              _generarPedidos(cantidad);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
