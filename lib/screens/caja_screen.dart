import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/caja_service.dart';
import '../models/caja.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/info_panel.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  List<Caja> movimientos = [];
  bool isLoading = true;
  String? errorMessage;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final lista = await CajaService.obtenerPorFecha(_fechaInicio, fechaFin: _fechaFin);
      setState(() {
        movimientos = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  double _calcularTotalIngresos() {
    return movimientos
        .where((m) => m.tipo == 'Ingreso')
        .fold(0.0, (sum, movimiento) => sum + movimiento.valor);
  }

  double _calcularTotalEgresos() {
    return movimientos
        .where((m) => m.tipo == 'Egreso')
        .fold(0.0, (sum, movimiento) => sum + movimiento.valor);
  }

  double _calcularCajaChica() {
    return movimientos
        .where((m) => m.tipo == 'Caja Chica')
        .fold(0.0, (sum, movimiento) => sum + movimiento.valor);
  }

  double _calcularSaldo() {
    return _calcularTotalIngresos() - _calcularTotalEgresos() - _calcularCajaChica();
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'Ingreso':
        return AppColors.success;
      case 'Egreso':
        return AppColors.error;
      case 'Caja Chica':
        return AppColors.accent;
      default:
        return Colors.white70;
    }
  }

  Future<void> _agregarMovimiento() async {
    // Verificar si ya existe caja chica para la fecha
    final cajaChicaExistente = await CajaService.obtenerCajaChicaPorFecha(_fechaInicio);
    
    if (!mounted) return;
    
    final result = await showDialog<Caja>(
      context: context,
      builder: (context) => _MovimientoDialog(
        fecha: _fechaInicio,
        cajaChicaExistente: cajaChicaExistente,
      ),
    );

    if (result != null) {
      try {
        await CajaService.guardar(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento guardado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          _cargarMovimientos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editarMovimiento(Caja movimiento) async {
    final result = await showDialog<Caja>(
      context: context,
      builder: (context) => _MovimientoDialog(
        fecha: movimiento.fecha,
        movimiento: movimiento,
      ),
    );

    if (result != null) {
      try {
        await CajaService.actualizar(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento actualizado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          _cargarMovimientos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarMovimiento(Caja movimiento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar este movimiento?',
          style: const TextStyle(color: Colors.white70),
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

    if (confirmar == true) {
      try {
        await CajaService.eliminar(movimiento.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento eliminado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          _cargarMovimientos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
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

    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
        _fechaFin = fecha;
      });
      _cargarMovimientos();
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
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

    if (fechaInicio != null) {
      if (!mounted) return;
      final fechaFin = await showDatePicker(
        context: context,
        initialDate: _fechaFin.isBefore(fechaInicio) ? fechaInicio : _fechaFin,
        firstDate: fechaInicio,
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
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

      if (fechaFin != null) {
        setState(() {
          _fechaInicio = fechaInicio;
          _fechaFin = fechaFin;
        });
        _cargarMovimientos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Caja'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarMovimiento,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarMovimientos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final totalIngresos = _calcularTotalIngresos();
    final totalEgresos = _calcularTotalEgresos();
    final cajaChica = _calcularCajaChica();
    final saldo = _calcularSaldo();

    return Column(
      children: [
        // Selector de fecha y resumen
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.cardBackground,
          child: Column(
            children: [
              // Filtro de fecha
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fechaInicio.year == _fechaFin.year &&
                                _fechaInicio.month == _fechaFin.month &&
                                _fechaInicio.day == _fechaFin.day
                            ? 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)}'
                            : 'Rango: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _seleccionarFecha,
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
                      label: const Text('Día', style: TextStyle(color: AppColors.accent)),
                    ),
                    TextButton.icon(
                      onPressed: _seleccionarRangoFechas,
                      icon: const Icon(Icons.date_range, size: 16, color: AppColors.accent),
                      label: const Text('Rango', style: TextStyle(color: AppColors.accent)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: InfoPanel(
                        title: 'Ingresos',
                        value: '\$${totalIngresos.toStringAsFixed(2)}',
                        icon: Icons.arrow_downward,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSmall),
                    Expanded(
                      child: InfoPanel(
                        title: 'Egresos',
                        value: '\$${totalEgresos.toStringAsFixed(2)}',
                        icon: Icons.arrow_upward,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: InfoPanel(
                        title: 'Caja Chica',
                        value: '\$${cajaChica.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSmall),
                    Expanded(
                      child: InfoPanel(
                        title: 'Saldo',
                        value: '\$${saldo.toStringAsFixed(2)}',
                        icon: Icons.account_balance,
                        color: saldo >= 0 ? AppColors.price : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de movimientos
        Expanded(
          child: movimientos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.white38),
                      SizedBox(height: 16),
                      Text(
                        'No hay movimientos',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Toca el botón + para agregar uno',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: movimientos.length,
                  itemBuilder: (context, index) {
                    final movimiento = movimientos[index];
                    return Card(
                      elevation: AppConstants.cardElevation,
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTipoColor(movimiento.tipo).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            movimiento.tipo == 'Ingreso'
                                ? Icons.arrow_downward
                                : movimiento.tipo == 'Egreso'
                                    ? Icons.arrow_upward
                                    : Icons.account_balance_wallet,
                            color: _getTipoColor(movimiento.tipo),
                          ),
                        ),
                        title: Text(
                          movimiento.descripcion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              movimiento.tipo,
                              style: TextStyle(
                                color: _getTipoColor(movimiento.tipo),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(movimiento.fecha),
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${movimiento.valor.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _getTipoColor(movimiento.tipo),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton(
                              iconColor: Colors.white,
                              color: AppColors.cardBackground,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar', style: TextStyle(color: Colors.white)),
                                ),
                                if (movimiento.tipo != 'Caja Chica')
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                                  ),
                              ],
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _editarMovimiento(movimiento);
                                } else if (value == 'eliminar') {
                                  _eliminarMovimiento(movimiento);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MovimientoDialog extends StatefulWidget {
  final DateTime fecha;
  final Caja? movimiento;
  final Caja? cajaChicaExistente;

  const _MovimientoDialog({
    required this.fecha,
    this.movimiento,
    this.cajaChicaExistente,
  });

  @override
  State<_MovimientoDialog> createState() => _MovimientoDialogState();
}

class _MovimientoDialogState extends State<_MovimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _valorController = TextEditingController();
  String _tipo = 'Ingreso';
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.movimiento != null) {
      _descripcionController.text = widget.movimiento!.descripcion;
      _valorController.text = widget.movimiento!.valor.toStringAsFixed(2);
      _tipo = widget.movimiento!.tipo;
      _fechaSeleccionada = widget.movimiento!.fecha;
    } else {
      _fechaSeleccionada = widget.fecha;
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
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

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final movimiento = Caja(
      id: widget.movimiento?.id,
      descripcion: _descripcionController.text.trim(),
      tipo: _tipo,
      valor: double.parse(_valorController.text.trim()),
      fecha: _fechaSeleccionada,
    );

    Navigator.pop(context, movimiento);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        widget.movimiento == null ? 'Nuevo Movimiento' : 'Editar Movimiento',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selector de fecha
              ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.accent),
                title: const Text(
                  'Fecha',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: ['Ingreso', 'Egreso', 'Caja Chica'].map((String tipo) {
                  // Si ya existe caja chica y estamos creando nuevo (no editando), deshabilitar la opción
                  final isDisabled = tipo == 'Caja Chica' &&
                      widget.movimiento == null &&
                      widget.cajaChicaExistente != null;
                  return DropdownMenuItem<String>(
                    value: tipo,
                    enabled: !isDisabled,
                    child: Text(
                      tipo,
                      style: TextStyle(
                        color: isDisabled ? Colors.white38 : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: widget.movimiento != null && widget.movimiento!.tipo == 'Caja Chica'
                    ? null // No permitir cambiar tipo si es caja chica existente
                    : (value) {
                        setState(() {
                          _tipo = value!;
                        });
                      },
              ),
              if (widget.movimiento != null && widget.movimiento!.tipo == 'Caja Chica')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Nota: No puedes cambiar el tipo de Caja Chica',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              if (widget.movimiento == null && widget.cajaChicaExistente != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Ya existe una Caja Chica para esta fecha. Puedes editarla desde la lista.',
                    style: TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background,
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El valor es obligatorio';
                  }
                  final valor = double.tryParse(value.trim());
                  if (valor == null || valor <= 0) {
                    return 'El valor debe ser un número positivo';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successDark,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

