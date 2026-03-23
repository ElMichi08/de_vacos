import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Widget reutilizable para filtrar por fecha o rango de fechas
///
/// Permite seleccionar un día específico o un rango de fechas.
/// Notifica los cambios a través de callbacks.
class DateFilterWidget extends StatefulWidget {
  /// Fecha de inicio del filtro
  final DateTime fechaInicio;

  /// Fecha de fin del filtro
  final DateTime fechaFin;

  /// Callback que se ejecuta cuando cambian las fechas
  /// Recibe la nueva fecha de inicio y fin
  final void Function(DateTime fechaInicio, DateTime fechaFin) onFechasChanged;

  /// Si está inicialmente expandido
  final bool initiallyExpanded;

  /// Fecha mínima permitida (por defecto 2020)
  final DateTime? firstDate;

  /// Fecha máxima permitida (por defecto hoy)
  final DateTime? lastDate;

  const DateFilterWidget({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onFechasChanged,
    this.initiallyExpanded = false,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterWidget> {
  late bool _mostrarFiltroFecha;

  @override
  void initState() {
    super.initState();
    _mostrarFiltroFecha = widget.initiallyExpanded;
  }

  /// Selecciona un día específico (establece inicio y fin en el mismo día)
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: widget.fechaInicio,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null && mounted) {
      widget.onFechasChanged(fecha, fecha);
    }
  }

  /// Selecciona un rango de fechas
  Future<void> _seleccionarRangoFechas() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: widget.fechaInicio,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaInicio != null && mounted) {
      final fechaFin = await showDatePicker(
        context: context,
        initialDate:
            widget.fechaFin.isBefore(fechaInicio)
                ? fechaInicio
                : widget.fechaFin,
        firstDate: fechaInicio,
        lastDate: widget.lastDate ?? DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.accent,
                onPrimary: Colors.white,
                surface: AppColors.cardBackground,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (fechaFin != null && mounted) {
        widget.onFechasChanged(fechaInicio, fechaFin);
      }
    }
  }

  /// Formatea el texto a mostrar en el título del filtro
  String _formatearTextoFecha() {
    final fechaInicio = widget.fechaInicio;
    final fechaFin = widget.fechaFin;

    // Si es el mismo día, mostrar solo una fecha
    if (fechaInicio.year == fechaFin.year &&
        fechaInicio.month == fechaFin.month &&
        fechaInicio.day == fechaFin.day) {
      return DateFormat('dd/MM/yyyy').format(fechaInicio);
    }

    // Si es un rango, mostrar ambas fechas
    return '${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _mostrarFiltroFecha ? 0 : AppConstants.cardElevation,
      color:
          _mostrarFiltroFecha ? Colors.transparent : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: ExpansionTile(
        initiallyExpanded: _mostrarFiltroFecha,
        onExpansionChanged: (expanded) {
          setState(() {
            _mostrarFiltroFecha = expanded;
          });
        },
        title: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatearTextoFecha(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Día', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: AppColors.cardBackground,
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarRangoFechas,
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Rango', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: AppColors.cardBackground,
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
