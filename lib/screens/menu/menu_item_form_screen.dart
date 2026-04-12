import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../injection/container.dart';
import '../../models/insumo.dart';
import '../../models/modalidad.dart';
import '../../menu/dominio/definicion/menu_item_definicion.dart';
import '../../menu/dominio/definicion/tier_definicion.dart';
import '../../services/insumo_service.dart';
import '../../widgets/back_header_widget.dart';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItemDefinicion? item;
  const MenuItemFormScreen({super.key, this.item});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;

  final List<_TierEntry> _tiers = [];
  final List<int> _proteinaIds = [];
  final List<int> _acompananteIds = [];
  final List<int> _extraIds = [];
  final List<int> _modalidadIds = [];

  List<Insumo> _proteinas = [];
  List<Insumo> _acompanantes = [];
  List<Modalidad> _modalidades = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nombreCtrl = TextEditingController(text: item?.nombre ?? '');

    if (item != null) {
      _tiers.addAll(item.tiers.map((t) => _TierEntry.fromDef(t)));
      _proteinaIds.addAll(item.proteinaIds);
      _acompananteIds.addAll(item.acompananteIds);
      _extraIds.addAll(item.extraIds);
      _modalidadIds.addAll(item.modalidadIds);
    }

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
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
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    for (final t in _tiers) { t.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tiers.isEmpty) {
      _showError('Agrega al menos un tier de precio');
      return;
    }

    setState(() => _saving = true);
    try {
      final definicion = MenuItemDefinicion(
        id: widget.item?.id,
        nombre: _nombreCtrl.text.trim(),
        tiers: _tiers.map((t) => t.toDefinicion()).toList(),
        proteinaIds: List.from(_proteinaIds),
        acompananteIds: List.from(_acompananteIds),
        extraIds: List.from(_extraIds),
        modalidadIds: List.from(_modalidadIds),
      );

      if (definicion.id == null) {
        await di.menuItemRepository.save(definicion);
      } else {
        await di.menuItemRepository.update(definicion);
      }

      if (mounted) context.pop(true);
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _saving) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeaderWidget(
          title: widget.item == null ? 'Nuevo plato' : 'Editar plato',
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeaderWidget(
        title: widget.item == null ? 'Nuevo plato' : 'Editar plato',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Nombre del plato ──────────────────────────────────────
            _buildNombreCard(),
            const SizedBox(height: 20),

            // ── Tiers ─────────────────────────────────────────────────
            _buildFormSection(
              icon: Icons.layers_outlined,
              title: 'Tiers de precio',
              subtitle: 'Define los tamaños y precios del plato',
              accentColor: AppColors.accent,
              child: _buildTiers(),
            ),
            const SizedBox(height: 16),

            // ── Proteínas ─────────────────────────────────────────────
            _buildFormSection(
              icon: Icons.egg_alt_outlined,
              title: 'Proteínas disponibles',
              subtitle: 'El cliente elige según el límite del tier',
              accentColor: const Color(0xFFEF9A9A),
              child: _buildInsumoPicker(
                insumos: _proteinas,
                selectedIds: _proteinaIds,
                emptyLabel: 'Sin proteínas configuradas',
                chipColor: const Color(0xFFEF9A9A),
              ),
            ),
            const SizedBox(height: 16),

            // ── Acompañantes ──────────────────────────────────────────
            _buildFormSection(
              icon: Icons.restaurant_outlined,
              title: 'Acompañantes disponibles',
              subtitle: 'Los primeros N son gratis según el tier',
              accentColor: const Color(0xFF80CBC4),
              child: _buildInsumoPicker(
                insumos: _acompanantes,
                selectedIds: _acompananteIds,
                emptyLabel: 'Sin acompañantes configurados',
                chipColor: const Color(0xFF80CBC4),
                showPrecioExtra: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Extras ────────────────────────────────────────────────
            _buildFormSection(
              icon: Icons.add_circle_outline,
              title: 'Extras (costo adicional)',
              subtitle: 'Opcionales, con cargo extra al precio base',
              accentColor: const Color(0xFFFFCC80),
              child: _buildInsumoPicker(
                insumos: [..._proteinas, ..._acompanantes],
                selectedIds: _extraIds,
                emptyLabel: 'Sin extras configurados',
                chipColor: const Color(0xFFFFCC80),
                showPrecioExtra: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Modalidades ───────────────────────────────────────────
            _buildFormSection(
              icon: Icons.tune_outlined,
              title: 'Modalidades de precio',
              subtitle: 'Modificadores opcionales al precio total',
              accentColor: const Color(0xFFCE93D8),
              child: _buildModalidadesPicker(),
            ),
            const SizedBox(height: 28),

            // ── Botón guardar ─────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.item == null ? 'Guardar plato' : 'Actualizar plato',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nombre del plato ────────────────────────────────────────────────────

  Widget _buildNombreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nombre del plato',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreCtrl,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Ej: Asado, Pollo, Mixto…',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
          ),
        ],
      ),
    );
  }

  // ── Sección genérica ────────────────────────────────────────────────────

  Widget _buildFormSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Insumo picker ───────────────────────────────────────────────────────

  Widget _buildInsumoPicker({
    required List<Insumo> insumos,
    required List<int> selectedIds,
    required String emptyLabel,
    required Color chipColor,
    bool showPrecioExtra = false,
  }) {
    final selected = insumos.where((i) => selectedIds.contains(i.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(emptyLabel,
                style:
                    const TextStyle(color: Colors.white30, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((insumo) {
              String label = insumo.nombre;
              if (showPrecioExtra && insumo.precioExtra > 0) {
                label += '  +\$${insumo.precioExtra.toStringAsFixed(2)}';
              }
              return Chip(
                label: Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
                backgroundColor: chipColor.withValues(alpha: 0.18),
                side: BorderSide(color: chipColor.withValues(alpha: 0.5)),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white60),
                onDeleted: () =>
                    setState(() => selectedIds.remove(insumo.id)),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickInsumo(insumos, selectedIds),
          icon: Icon(Icons.add, color: chipColor, size: 16),
          label: Text('Agregar', style: TextStyle(color: chipColor)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: chipColor.withValues(alpha: 0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Future<void> _pickInsumo(List<Insumo> insumos, List<int> selectedIds) async {
    final disponibles = insumos
        .where((i) => i.id != null && !selectedIds.contains(i.id))
        .toList();
    if (disponibles.isEmpty) {
      _showError('No hay insumos disponibles para agregar.');
      return;
    }
    final elegido = await showDialog<Insumo>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Elegir insumo',
            style: TextStyle(color: Colors.white)),
        children: disponibles
            .map((i) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, i),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(i.nombre,
                            style: const TextStyle(color: Colors.white)),
                      ),
                      if (i.precioExtra > 0)
                        Text('+\$${i.precioExtra.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (elegido != null && elegido.id != null) {
      setState(() => selectedIds.add(elegido.id!));
    }
  }

  // ── Modalidades picker ──────────────────────────────────────────────────

  Widget _buildModalidadesPicker() {
    final selected =
        _modalidades.where((m) => _modalidadIds.contains(m.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sin modalidades configuradas',
                style: TextStyle(color: Colors.white30, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((m) {
              final signo = m.modificador >= 0 ? '+' : '';
              return Chip(
                label: Text(
                    '${m.nombre}  $signo\$${m.modificador.toStringAsFixed(2)}',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13)),
                backgroundColor:
                    const Color(0xFFCE93D8).withValues(alpha: 0.18),
                side: BorderSide(
                    color:
                        const Color(0xFFCE93D8).withValues(alpha: 0.5)),
                deleteIcon:
                    const Icon(Icons.close, size: 14, color: Colors.white60),
                onDeleted: () =>
                    setState(() => _modalidadIds.remove(m.id)),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickModalidad,
          icon: const Icon(Icons.add,
              color: Color(0xFFCE93D8), size: 16),
          label: const Text('Agregar modalidad',
              style: TextStyle(color: Color(0xFFCE93D8))),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: const Color(0xFFCE93D8).withValues(alpha: 0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Future<void> _pickModalidad() async {
    final disponibles =
        _modalidades.where((m) => !_modalidadIds.contains(m.id)).toList();
    if (disponibles.isEmpty) {
      _showError('No hay modalidades disponibles. Crea modalidades desde Insumos.');
      return;
    }
    final elegida = await showDialog<Modalidad>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Elegir modalidad',
            style: TextStyle(color: Colors.white)),
        children: disponibles
            .map((m) {
              final signo = m.modificador >= 0 ? '+' : '';
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.nombre,
                        style: const TextStyle(color: Colors.white)),
                    Text(
                        '$signo\$${m.modificador.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              );
            })
            .toList(),
      ),
    );
    if (elegida != null && elegida.id != null) {
      setState(() => _modalidadIds.add(elegida.id!));
    }
  }

  // ── Tiers ───────────────────────────────────────────────────────────────

  Widget _buildTiers() {
    return Column(
      children: [
        ..._tiers.asMap().entries.map((e) => _TierCard(
              entry: e.value,
              index: e.key,
              onRemove: () => setState(() => _tiers.removeAt(e.key)),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() => _tiers.add(_TierEntry())),
          icon: Icon(Icons.add, color: AppColors.accent, size: 16),
          label: Text('Agregar tier',
              style: TextStyle(color: AppColors.accent)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

// ── Tier entry (estado mutable para el formulario) ────────────────────────

class _TierEntry {
  final TextEditingController nombreCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController maxProteinasCtrl;
  final TextEditingController maxAcompanantesCtrl;

  _TierEntry()
      : nombreCtrl = TextEditingController(),
        precioCtrl = TextEditingController(text: '0.0'),
        maxProteinasCtrl = TextEditingController(text: '1'),
        maxAcompanantesCtrl = TextEditingController(text: '0');

  _TierEntry.fromDef(TierDefinicion def)
      : nombreCtrl = TextEditingController(text: def.nombre),
        precioCtrl = TextEditingController(text: def.precio.toString()),
        maxProteinasCtrl =
            TextEditingController(text: def.maxProteinas.toString()),
        maxAcompanantesCtrl =
            TextEditingController(text: def.maxAcompanantesGratis.toString());

  TierDefinicion toDefinicion() => TierDefinicion(
        nombre: nombreCtrl.text.trim(),
        precio: double.tryParse(precioCtrl.text) ?? 0.0,
        maxProteinas: int.tryParse(maxProteinasCtrl.text) ?? 1,
        maxAcompanantesGratis: int.tryParse(maxAcompanantesCtrl.text) ?? 0,
      );

  void dispose() {
    nombreCtrl.dispose();
    precioCtrl.dispose();
    maxProteinasCtrl.dispose();
    maxAcompanantesCtrl.dispose();
  }
}

// ── Tier card mejorada ────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final _TierEntry entry;
  final int index;
  final VoidCallback onRemove;

  const _TierCard({
    required this.entry,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: entry.nombreCtrl,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  decoration: _deco('Nombre del tier  (ej: Sencillo)'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: entry.precioCtrl,
                  style: const TextStyle(
                      color: AppColors.price,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  textAlign: TextAlign.right,
                  decoration: _deco('\$  Precio'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StepperField(
                  controller: entry.maxProteinasCtrl,
                  label: 'Máx. proteínas',
                  color: const Color(0xFFEF9A9A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StepperField(
                  controller: entry.maxAcompanantesCtrl,
                  label: 'Acomp. gratis',
                  color: const Color(0xFF80CBC4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Colors.white38, fontSize: 11),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white12),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white38),
            borderRadius: BorderRadius.circular(8)),
      );
}

// ── Stepper field para números enteros ────────────────────────────────────

class _StepperField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _StepperField({
    required this.controller,
    required this.label,
    required this.color,
  });

  int get _value => int.tryParse(controller.text) ?? 0;

  void _increment() {
    controller.text = (_value + 1).toString();
  }

  void _decrement() {
    if (_value > 0) controller.text = (_value - 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: _decrement,
                borderRadius: BorderRadius.circular(4),
                child: Icon(Icons.remove, color: color, size: 18),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              InkWell(
                onTap: _increment,
                borderRadius: BorderRadius.circular(4),
                child: Icon(Icons.add, color: color, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
