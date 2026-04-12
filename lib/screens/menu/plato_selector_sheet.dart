import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../injection/container.dart';
import '../../menu/dominio/definicion/menu_item_definicion.dart';
import '../../menu/dominio/definicion/tier_definicion.dart';
import '../../menu/factory/plato_factory.dart';
import '../../menu/strategy/modalidad_strategy.dart';
import '../../menu/strategy/precio_normal_strategy.dart';
import '../../models/insumo.dart';
import '../../models/modalidad.dart';

/// Resultado confirmado de armar un plato.
/// Solo calcula precio — el descuento de stock se maneja por separado
/// cuando el pedido es guardado/completado.
class PlatoConfirmado {
  final String nombre;
  final double precio;
  final String tier;
  final List<String> proteinas;
  /// IDs de insumos seleccionados como proteínas (usados al cobrar para descontar stock).
  final List<int> proteinaIds;
  final List<String> acompanantes;
  final List<String> extras;
  final String? modalidad;

  const PlatoConfirmado({
    required this.nombre,
    required this.precio,
    required this.tier,
    required this.proteinas,
    this.proteinaIds = const [],
    required this.acompanantes,
    required this.extras,
    this.modalidad,
  });

  /// Convierte a Map compatible con Pedido.productos
  Map<String, dynamic> toProductoMap() => {
        'nombre': nombre,
        'nombreProducto': nombre,
        'precio': precio,
        'cantidad': 1,
        'tipo': 'menu',
        'tier': tier,
        'proteinas': proteinas,
        // IDs para descontar stock al cobrar
        if (proteinaIds.isNotEmpty) 'proteinaIds': proteinaIds,
        // Format as List<Map> so TicketFormatter/OrderDetailModal can read nombre+cantidad
        'acompanantes': acompanantes
            .map((a) => {'nombre': a, 'cantidad': 1})
            .toList(),
        'extras': extras,
        if (modalidad != null) 'modalidad': modalidad,
      };
}

/// Muestra el selector de plato como bottom sheet.
/// Retorna [PlatoConfirmado] si el operador confirmó, null si canceló.
Future<PlatoConfirmado?> showPlatoSelectorSheet(
  BuildContext context,
  MenuItemDefinicion definicion,
) {
  return showModalBottomSheet<PlatoConfirmado>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlatoSelectorSheet(definicion: definicion),
  );
}

class _PlatoSelectorSheet extends StatefulWidget {
  final MenuItemDefinicion definicion;

  const _PlatoSelectorSheet({required this.definicion});

  @override
  State<_PlatoSelectorSheet> createState() => _PlatoSelectorSheetState();
}

class _PlatoSelectorSheetState extends State<_PlatoSelectorSheet> {
  // ── Datos cargados desde repositorios ───────────────────────────────────
  List<Insumo> _proteinas = [];
  List<Insumo> _acompanantes = [];
  List<Insumo> _extras = [];
  List<Modalidad> _modalidades = [];
  bool _loading = true;
  String? _error;

  // ── Selección del usuario ────────────────────────────────────────────────
  TierDefinicion? _tier;
  final Set<int> _proteinaIds = {};
  final Set<int> _acompananteIds = {};
  final Set<int> _extraIds = {};
  Modalidad? _modalidad;

  // ── Estado de procesamiento ──────────────────────────────────────────────
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = await Future.wait([
        _cargarInsumosPorIds(widget.definicion.proteinaIds),
        _cargarInsumosPorIds(widget.definicion.acompananteIds),
        _cargarInsumosPorIds(widget.definicion.extraIds),
        _cargarModalidadesPorIds(widget.definicion.modalidadIds),
      ]);

      if (mounted) {
        setState(() {
          _proteinas = futures[0] as List<Insumo>;
          _acompanantes = futures[1] as List<Insumo>;
          _extras = futures[2] as List<Insumo>;
          _modalidades = futures[3] as List<Modalidad>;
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

  Future<List<Insumo>> _cargarInsumosPorIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final results = await Future.wait(
      ids.map(di.insumoRepository.obtenerInsumoPorId),
    );
    return results.whereType<Insumo>().toList();
  }

  Future<List<Modalidad>> _cargarModalidadesPorIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final results = await Future.wait(
      ids.map(di.modalidadRepository.obtenerPorId),
    );
    return results.whereType<Modalidad>().toList();
  }

  // ── Lógica de selección ─────────────────────────────────────────────────

  int get _maxProteinas => _tier?.maxProteinas ?? 0;

  void _toggleProteina(int id) {
    setState(() {
      if (_proteinaIds.contains(id)) {
        _proteinaIds.remove(id);
      } else if (_proteinaIds.length < _maxProteinas) {
        _proteinaIds.add(id);
      }
    });
  }

  void _toggleAcompanante(int id) {
    setState(() {
      if (_acompananteIds.contains(id)) {
        _acompananteIds.remove(id);
      } else {
        _acompananteIds.add(id);
      }
    });
  }

  void _toggleExtra(int id) {
    setState(() {
      if (_extraIds.contains(id)) {
        _extraIds.remove(id);
      } else {
        _extraIds.add(id);
      }
    });
  }

  // ── Confirmación (solo calcula precio, no descuenta stock) ──────────────

  bool get _puedeConfirmar =>
      _tier != null &&
      (_maxProteinas == 0 || _proteinaIds.isNotEmpty);

  Future<void> _confirmar() async {
    if (!_puedeConfirmar || _procesando) return;
    setState(() => _procesando = true);

    final proteinasSeleccionadas =
        _proteinas.where((i) => _proteinaIds.contains(i.id)).toList();
    final acompanantesSeleccionados =
        _acompanantes.where((i) => _acompananteIds.contains(i.id)).toList();
    final extrasSeleccionados =
        _extras.where((i) => _extraIds.contains(i.id)).toList();

    final seleccion = SeleccionPlato(
      tierNombre: _tier!.nombre,
      proteinas: proteinasSeleccionadas,
      acompanantes: acompanantesSeleccionados,
      extras: extrasSeleccionados,
      modalidad: _modalidad,
    );

    // Crear plato via Factory (sin descontar stock)
    final platoResult = PlatoFactory.crear(widget.definicion, seleccion);
    if (platoResult.isErr) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(platoResult.error),
            backgroundColor: AppColors.error,
          ));
      }
      return;
    }

    final plato = platoResult.value;

    // Calcular precio con la estrategia seleccionada
    final strategy = _modalidad != null
        ? ModalidadStrategy(_modalidad!)
        : PrecioNormalStrategy();
    final precio = strategy.calcular(plato);

    if (!mounted) return;
    setState(() => _procesando = false);

    final confirmado = PlatoConfirmado(
      nombre: plato.getNombre(),
      precio: precio,
      tier: _tier!.nombre,
      proteinas: proteinasSeleccionadas.map((p) => p.nombre).toList(),
      proteinaIds: proteinasSeleccionadas.map((p) => p.id!).toList(),
      acompanantes: acompanantesSeleccionados.map((a) => a.nombre).toList(),
      extras: extrasSeleccionados.map((e) => e.nombre).toList(),
      modalidad: _modalidad?.nombre,
    );

    Navigator.pop(context, confirmado);
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.definicion.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12),
          // Cuerpo scrollable
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error)),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _SectionLabel('Tier', required: true),
                          _buildTierChips(),
                          if (_proteinas.isNotEmpty && _tier != null) ...[
                            _SectionLabel(
                              'Proteína(s)',
                              required: true,
                              hint: 'Máx. $_maxProteinas',
                            ),
                            _buildInsumoGrid(
                              insumos: _proteinas,
                              selected: _proteinaIds,
                              onToggle: _toggleProteina,
                              disableWhenMax:
                                  _proteinaIds.length >= _maxProteinas,
                            ),
                          ],
                          if (_acompanantes.isNotEmpty && _tier != null) ...[
                            _SectionLabel(
                              'Acompañantes',
                              hint:
                                  '${_tier!.maxAcompanantesGratis} gratis, resto +precio',
                            ),
                            _buildAcompananteGrid(),
                          ],
                          if (_extras.isNotEmpty && _tier != null) ...[
                            _SectionLabel('Extras', hint: 'Opcional · con costo'),
                            _buildInsumoGrid(
                              insumos: _extras,
                              selected: _extraIds,
                              onToggle: _toggleExtra,
                              disableWhenMax: false,
                              showPrice: true,
                            ),
                          ],
                          if (_modalidades.isNotEmpty) ...[
                            _SectionLabel('Modalidad', hint: 'Opcional'),
                            _buildModalidadChips(),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _puedeConfirmar && !_procesando
                                ? _confirmar
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successDark,
                              disabledBackgroundColor:
                                  AppColors.successDark.withValues(alpha: 0.3),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                              ),
                            ),
                            child: _procesando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Confirmar plato',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.definicion.tiers.map((tier) {
        final selected = _tier?.nombre == tier.nombre;
        return ChoiceChip(
          label: Text('${tier.nombre}  \$${tier.precio.toStringAsFixed(0)}'),
          selected: selected,
          onSelected: (_) => setState(() {
            _tier = tier;
            _proteinaIds.clear();
          }),
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.cardBackground,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsumoGrid({
    required List<Insumo> insumos,
    required Set<int> selected,
    required void Function(int) onToggle,
    required bool disableWhenMax,
    bool showPrice = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: insumos.map((insumo) {
        final isSelected = selected.contains(insumo.id!);
        final disabled = disableWhenMax && !isSelected;
        String label = insumo.nombre;
        if (showPrice && insumo.precioExtra > 0) {
          label += '  +\$${insumo.precioExtra.toStringAsFixed(0)}';
        }
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: disabled ? null : (_) => onToggle(insumo.id!),
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.cardBackground,
          disabledColor: AppColors.cardBackground.withValues(alpha: 0.4),
          labelStyle: TextStyle(
            color: disabled
                ? Colors.white24
                : isSelected
                    ? Colors.white
                    : Colors.white70,
          ),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildAcompananteGrid() {
    final gratuitos = _tier!.maxAcompanantesGratis;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _acompanantes.map((insumo) {
        final isSelected = _acompananteIds.contains(insumo.id!);
        final posicion = _acompananteIds.toList().indexOf(insumo.id!);
        final esGratis = isSelected && posicion < gratuitos;
        final extraPrice = insumo.precioExtra;

        String label = insumo.nombre;
        if (isSelected) {
          label += esGratis
              ? '  (gratis)'
              : '  +\$${extraPrice.toStringAsFixed(0)}';
        } else if (_acompananteIds.length >= gratuitos && extraPrice > 0) {
          label += '  +\$${extraPrice.toStringAsFixed(0)}';
        }

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => _toggleAcompanante(insumo.id!),
          selectedColor: esGratis ? AppColors.success : AppColors.accent,
          backgroundColor: AppColors.cardBackground,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildModalidadChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Normal'),
          selected: _modalidad == null,
          onSelected: (_) => setState(() => _modalidad = null),
          selectedColor: AppColors.cardBackground,
          backgroundColor: AppColors.cardBackground,
          labelStyle: TextStyle(
            color: _modalidad == null ? Colors.white : Colors.white54,
          ),
        ),
        ..._modalidades.map((modal) {
          final selected = _modalidad?.id == modal.id;
          final signo = modal.modificador >= 0 ? '+' : '';
          return ChoiceChip(
            label: Text(
                '${modal.nombre}  $signo\$${modal.modificador.toStringAsFixed(0)}'),
            selected: selected,
            onSelected: (_) =>
                setState(() => _modalidad = selected ? null : modal),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.cardBackground,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.white70,
            ),
          );
        }),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;

  const _SectionLabel(this.label, {this.required = false, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (required)
            const Text(' *',
                style: TextStyle(color: AppColors.error, fontSize: 14)),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Text(hint!,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
