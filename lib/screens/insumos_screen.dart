import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../injection/container.dart';
import '../models/insumo.dart';
import '../models/modalidad.dart';
import '../services/insumo_service.dart';
import '../widgets/back_header_widget.dart';
import 'insumo_form_screen.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Insumo> _proteinas = [];
  List<Insumo> _acompanantes = [];
  List<Modalidad> _modalidades = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        InsumoService.listarPorTipo(InsumoTipo.proteina),
        InsumoService.listarPorTipo(InsumoTipo.acompanante),
        di.modalidadRepository.obtenerTodas(),
      ]);
      if (mounted) {
        setState(() {
          _proteinas = results[0] as List<Insumo>;
          _acompanantes = results[1] as List<Insumo>;
          _modalidades = results[2] as List<Modalidad>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeaderWidget(
        title: 'Insumos',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Proteínas'),
            Tab(text: 'Acompañantes'),
            Tab(text: 'Modalidades'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _InsumosTab(
                      insumos: _proteinas,
                      tipo: InsumoTipo.proteina,
                      showMinimo: true,
                      onRefresh: _cargar,
                    ),
                    _InsumosTab(
                      insumos: _acompanantes,
                      tipo: InsumoTipo.acompanante,
                      showMinimo: false,
                      onRefresh: _cargar,
                    ),
                    _ModalidadesTab(
                      modalidades: _modalidades,
                      onRefresh: _cargar,
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _onFabTap() async {
    final tab = _tabController.index;
    if (tab == 2) {
      // Modalidades tab
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ModalidadFormDialog(),
      );
      if (ok ?? false) _cargar();
    } else {
      final tipo = tab == 0 ? InsumoTipo.proteina : InsumoTipo.acompanante;
      final ok = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InsumoFormScreen(tipoFijo: tipo),
        ),
      );
      if (ok ?? false) _cargar();
    }
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

// ── Tab de Insumos (Proteínas / Acompañantes) ─────────────────────────────

class _InsumosTab extends StatelessWidget {
  final List<Insumo> insumos;
  final InsumoTipo tipo;
  final bool showMinimo;
  final VoidCallback onRefresh;

  const _InsumosTab({
    required this.insumos,
    required this.tipo,
    required this.showMinimo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (insumos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              tipo == InsumoTipo.proteina
                  ? 'No hay proteínas'
                  : 'No hay acompañantes',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Toca + para agregar uno',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: insumos.length,
        itemBuilder: (context, i) => _InsumoCard(
          insumo: insumos[i],
          showMinimo: showMinimo,
          onEdit: () async {
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsumoFormScreen(insumo: insumos[i]),
              ),
            );
            if (ok == true) onRefresh();
          },
          onDelete: () async {
            final confirmar = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                title: const Text('Eliminar insumo',
                    style: TextStyle(color: Colors.white)),
                content: Text(
                  '¿Eliminar "${insumos[i].nombre}"? Esta acción no se puede deshacer.',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Eliminar',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirmar ?? false) {
              await InsumoService.eliminar(insumos[i].id!);
              onRefresh();
            }
          },
        ),
      ),
    );
  }
}

class _InsumoCard extends StatelessWidget {
  final Insumo insumo;
  final bool showMinimo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InsumoCard({
    required this.insumo,
    required this.showMinimo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bajoMinimo = showMinimo && insumo.bajoMinimo;

    double porcentaje = 1.0;
    if (showMinimo) {
      if (insumo.cantidadMinima <= 0) {
        porcentaje = insumo.cantidadActual > 0 ? 1.0 : 0.0;
      } else {
        porcentaje =
            (insumo.cantidadActual / insumo.cantidadMinima).clamp(0.0, 1.0);
      }
    }

    final barraColor = bajoMinimo
        ? AppColors.error
        : porcentaje < 0.5
            ? AppColors.error
            : porcentaje < 1.0
                ? AppColors.highlight
                : AppColors.success;

    return Card(
      elevation: AppConstants.cardElevation,
      color: bajoMinimo
          ? AppColors.cardBackground.withValues(alpha: 0.9)
          : AppColors.cardBackground,
      margin:
          const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppConstants.borderRadiusLarge),
        side: bajoMinimo
            ? const BorderSide(color: AppColors.error, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bajoMinimo
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.3),
          child: Icon(
            bajoMinimo ? Icons.warning_amber_rounded : Icons.inventory_2,
            color: bajoMinimo ? AppColors.error : AppColors.accent,
          ),
        ),
        title: Text(insumo.nombre,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (showMinimo)
              Text(
                '${insumo.cantidadActual} / ${insumo.cantidadMinima} ${insumo.unidadMedida}',
                style: TextStyle(
                    color: bajoMinimo ? AppColors.error : Colors.white70,
                    fontSize: 14),
              )
            else
              Text(
                '${insumo.cantidadActual} ${insumo.unidadMedida}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            if (insumo.precioExtra > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Extra: \$${insumo.precioExtra.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
            if (showMinimo) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: porcentaje,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(barraColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                '${(porcentaje * 100).toStringAsFixed(0)}% del mínimo',
                style: TextStyle(
                    color: barraColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
            if (bajoMinimo)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Stock por debajo del mínimo',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab de Modalidades ────────────────────────────────────────────────────

class _ModalidadesTab extends StatelessWidget {
  final List<Modalidad> modalidades;
  final VoidCallback onRefresh;

  const _ModalidadesTab({
    required this.modalidades,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (modalidades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_change_outlined,
                size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text('No hay modalidades',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            SizedBox(height: 8),
            Text('Toca + para agregar una',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: modalidades.length,
        itemBuilder: (context, i) => _ModalidadCard(
          modalidad: modalidades[i],
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

class _ModalidadCard extends StatelessWidget {
  final Modalidad modalidad;
  final VoidCallback onRefresh;

  const _ModalidadCard({required this.modalidad, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final signo = modalidad.modificador >= 0 ? '+' : '';
    return Card(
      color: AppColors.cardBackground,
      margin:
          const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusLarge)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.3),
          child: Icon(Icons.price_change_outlined,
              color: AppColors.accent),
        ),
        title: Text(modalidad.nombre,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle: Text(
          '$signo\$${modalidad.modificador.toStringAsFixed(2)} sobre precio base',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) =>
                      _ModalidadFormDialog(modalidad: modalidad),
                );
                if (ok ?? false) onRefresh();
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    title: const Text('Eliminar modalidad',
                        style: TextStyle(color: Colors.white)),
                    content: Text(
                      '¿Eliminar "${modalidad.nombre}"?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Eliminar',
                            style:
                                TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmar ?? false) {
                  await di.modalidadRepository
                      .eliminar(modalidad.id!);
                  onRefresh();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo formulario de Modalidad ──────────────────────────────────────

class _ModalidadFormDialog extends StatefulWidget {
  final Modalidad? modalidad;

  const _ModalidadFormDialog({this.modalidad});

  @override
  State<_ModalidadFormDialog> createState() => _ModalidadFormDialogState();
}

class _ModalidadFormDialogState extends State<_ModalidadFormDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _modificadorCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl =
        TextEditingController(text: widget.modalidad?.nombre ?? '');
    _modificadorCtrl = TextEditingController(
        text: widget.modalidad?.modificador.toString() ?? '0.0');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _modificadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final modificador = double.tryParse(_modificadorCtrl.text) ?? 0.0;

    setState(() => _saving = true);
    try {
      if (widget.modalidad == null) {
        await di.modalidadRepository.crear(
          Modalidad(nombre: nombre, modificador: modificador),
        );
      } else {
        await di.modalidadRepository.actualizar(
          widget.modalidad!.copyWith(
              nombre: nombre, modificador: modificador),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent),
            borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        widget.modalidad == null ? 'Nueva modalidad' : 'Editar modalidad',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _nombreCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _deco('Nombre (ej: Feria, Delivery)'),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modificadorCtrl,
          style: const TextStyle(color: Colors.white),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[-\d.]'))
          ],
          decoration: _deco('Modificador \$ (puede ser negativo)'),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.white54)),
        ),
        if (_saving)
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          TextButton(
            onPressed: _guardar,
            child: Text('Guardar',
                style: TextStyle(color: AppColors.accent)),
          ),
      ],
    );
  }
}
