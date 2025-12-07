import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/license_service.dart';

/// Modal que muestra el estado actual de la licencia
class LicenseStatusModal extends StatefulWidget {
  const LicenseStatusModal({super.key});

  @override
  State<LicenseStatusModal> createState() => _LicenseStatusModalState();
}

class _LicenseStatusModalState extends State<LicenseStatusModal> {
  bool _cargando = true;
  Map<String, dynamic>? _infoLicencia;
  String? _error;
  String? _errorMessage; // Mensaje de error específico para operaciones
  double _deudaPendiente = 0.0; // Deuda pendiente desde la tabla cobros

  @override
  void initState() {
    super.initState();
    _cargarInformacionLicencia();
  }

  Future<void> _cargarInformacionLicencia() async {
    setState(() {
      _cargando = true;
      _error = null;
      _errorMessage = null; // Limpiar mensaje de error anterior
    });

    try {
      final info = await LicenseService.obtenerInformacionLicencia();
      final deuda = await LicenseService.obtenerDeudaPendiente();
      
      if (!mounted) return;
      
      if (info == null) {
        setState(() {
          _error = 'No se pudo obtener la información de la licencia. Verifique su conexión a internet.';
          _cargando = false;
        });
      } else {
        setState(() {
          _infoLicencia = info;
          _deudaPendiente = deuda;
          _cargando = false;
          _errorMessage = null; // Limpiar error si la carga fue exitosa
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al consultar la licencia: ${e.toString()}\n\nVerifique su conexión a internet y que Supabase esté configurado correctamente.';
        _errorMessage = e.toString(); // Guardar mensaje de error específico
        _cargando = false;
      });
    }
  }
  
  /// Actualiza la información de la licencia y reporta ventas
  /// Maneja errores específicos de Supabase
  Future<void> _actualizarYReportar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _errorMessage = null;
    });

    try {
      // Intentar verificar y reportar (esto puede lanzar excepción si falla Supabase)
      final resultado = await LicenseService.verificarYReportar();
      final licenciaActiva = resultado['licenciaActiva'] as bool;
      final deudaTotal = resultado['deudaTotal'] as double;
      
      if (!mounted) return;
      
      if (!licenciaActiva) {
        setState(() {
          _errorMessage = 'La licencia está bloqueada. Contacte a soporte.';
          _cargando = false;
        });
        return;
      }
      
      // Si la verificación fue exitosa, recargar la información
      // Actualizar la deuda con el valor obtenido
      setState(() {
        _deudaPendiente = deudaTotal;
      });
      await _cargarInformacionLicencia();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al actualizar: ${e.toString()}\n\nPosibles causas:\n- Error de conexión a Supabase\n- Problema con RLS (Row Level Security)\n- Error de autenticación';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Estado de Licencia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: _cargando
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildInfoWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _cargarInformacionLicencia,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoWidget() {
    final estado = _infoLicencia!['estado'] as String;
    final porcentajeComision = _infoLicencia!['porcentaje_comision'] as double;
    final fechaUltimoPago = _infoLicencia!['fecha_ultimo_pago'] as String?;
    final clienteId = _infoLicencia!['cliente_id'] as String;
    final estadoPagoHoy = _infoLicencia!['estado_pago_hoy'] as String?;

    final estaActiva = estado == 'activo';
    final colorEstado = estaActiva ? AppColors.success : AppColors.error;
    final iconoEstado = estaActiva ? Icons.check_circle : Icons.cancel;
    
    // Formatear comisión: siempre multiplicar por 100 para mostrar porcentaje
    // Si el valor en BD es 0.06, mostrará 6%
    // Si el valor en BD es 0.0006, mostrará 0.06%
    final comisionFormateada = '${(porcentajeComision * 100).toStringAsFixed(2)}%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estado principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorEstado.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorEstado.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                iconoEstado,
                size: 64,
                color: colorEstado,
              ),
              const SizedBox(height: 16),
              Text(
                estaActiva ? 'Licencia Activa' : 'Licencia Bloqueada',
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado.toUpperCase(),
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Información detallada - Cliente ID y Comisión en la misma fila
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                icon: Icons.badge,
                label: 'Cliente',
                value: clienteId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoRow(
                icon: Icons.percent,
                label: 'Comisión',
                value: comisionFormateada,
              ),
            ),
          ],
        ),
        // Mostrar estado de pago de hoy si existe
        if (estadoPagoHoy != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.payment,
            label: 'Estado Pago (Hoy)',
            value: estadoPagoHoy == 'pagado' 
                ? 'Pagado' 
                : estadoPagoHoy == 'pendiente'
                    ? 'Pendiente'
                    : estadoPagoHoy,
            valueColor: estadoPagoHoy == 'pagado' 
                ? AppColors.success 
                : AppColors.accent,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _deudaPendiente > 0 
                ? Colors.orange.withValues(alpha: 0.15)
                : AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _deudaPendiente > 0 
                  ? Colors.orange.withValues(alpha: 0.5)
                  : AppColors.success.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _deudaPendiente > 0 ? Icons.warning : Icons.check_circle,
                color: _deudaPendiente > 0 ? Colors.orange : AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deudaPendiente > 0 ? 'Deuda Pendiente' : 'Al día',
                      style: TextStyle(
                        color: _deudaPendiente > 0 
                            ? Colors.orange.withValues(alpha: 0.9)
                            : AppColors.success.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _deudaPendiente > 0 
                          ? '\$${_deudaPendiente.toStringAsFixed(2)}'
                          : 'Sin deuda pendiente',
                      style: TextStyle(
                        color: _deudaPendiente > 0 
                            ? Colors.orange
                            : AppColors.success,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (fechaUltimoPago != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Último Pago',
            value: _formatearFecha(fechaUltimoPago),
          ),
        ],
        const SizedBox(height: 24),

        // Mensaje de error si existe
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botón de actualizar
        ElevatedButton.icon(
          onPressed: _cargando ? null : _actualizarYReportar,
          icon: _cargando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
          label: Text(_cargando ? 'Actualizando...' : 'Actualizar Información'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fechaIso) {
    try {
      // Parsear la fecha ISO - Supabase devuelve fechas en UTC
      // DateTime.parse() convierte automáticamente a la zona horaria local del dispositivo
      DateTime fechaParseada = DateTime.parse(fechaIso);
      
      // Obtener la diferencia de zona horaria del dispositivo
      final offsetLocal = fechaParseada.timeZoneOffset;
      
      // Si la fecha fue convertida a local, necesitamos revertir esa conversión
      // y luego convertir a UTC, y finalmente a Ecuador (UTC-5)
      DateTime fechaUtc;
      if (fechaParseada.isUtc) {
        // Ya está en UTC, usar directamente
        fechaUtc = fechaParseada;
      } else {
        // La fecha fue convertida a local, revertir la conversión sumando el offset
        // para obtener la fecha UTC original
        fechaUtc = fechaParseada.add(offsetLocal);
        // Asegurar que sea UTC
        fechaUtc = DateTime.utc(
          fechaUtc.year,
          fechaUtc.month,
          fechaUtc.day,
          fechaUtc.hour,
          fechaUtc.minute,
          fechaUtc.second,
          fechaUtc.millisecond,
          fechaUtc.microsecond,
        );
      }
      
      // Convertir de UTC a zona horaria de Ecuador (America/Guayaquil = UTC-5)
      // Ecuador no tiene horario de verano, siempre está en UTC-5
      // Restar 5 horas para obtener la hora local de Ecuador
      final fechaEcuador = fechaUtc.subtract(const Duration(hours: 5));
      
      // Formato: YYYY-MM-DD | HH:MM
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fechaEcuador);
      final horaFormateada = DateFormat('HH:mm').format(fechaEcuador);
      return '$fechaFormateada | $horaFormateada';
    } catch (e) {
      return fechaIso; // Retornar original si falla el parseo
    }
  }
}

