import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../injection/container.dart';
import '../menu/dominio/definicion/menu_item_definicion.dart';
import '../models/enums.dart';
import '../models/pedido.dart';
import '../screens/menu/plato_selector_sheet.dart';
import '../services/pedido_service.dart';
import '../services/stock_checker.dart';
import '../widgets/back_header_widget.dart';
import '../widgets/order_form_payment_section.dart';

/// Pantalla unificada para crear y editar pedidos.
/// Si [pedido] es null → modo creación; si no → modo edición.
class OrderFormScreen extends StatefulWidget {
  final Pedido? pedido;

  const OrderFormScreen({super.key, this.pedido});

  bool get isEditing => pedido != null;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _notasCtrl = TextEditingController();

  late String _nombreCliente;
  late PaymentMethod _metodoPago;

  List<MenuItemDefinicion> _menuItems = [];
  Map<int, bool> _stockDisponible = {};
  late List<_ItemPedido> _itemsPedido;

  bool _loading = true;
  bool _saving = false;

  double get _total => _itemsPedido.fold(0.0, (s, i) => s + i.precioTotal);

  bool get _clienteValido => _nombreCliente.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.pedido;
    if (p != null) {
      _nombreCliente = p.cliente;
      _metodoPago = p.metodoPago;
      _notasCtrl.text = p.notas;
      _itemsPedido = p.productos.map(_ItemPedido.fromProductoMap).toList();
    } else {
      _nombreCliente = '';
      _metodoPago = PaymentMethod.efectivo;
      _itemsPedido = [];
    }
    _cargarMenu();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMenu() async {
    try {
      final items = await di.menuItemRepository.findAll();
      final stock = <int, bool>{};
      for (final item in items) {
        if (item.id != null) {
          stock[item.id!] = await StockChecker.menuItemDisponible(item);
        }
      }
      if (mounted) {
        setState(() {
          _menuItems = items;
          _stockDisponible = stock;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _agregarDelMenu(MenuItemDefinicion def) async {
    final confirmado = await showPlatoSelectorSheet(context, def);
    if (confirmado == null || !mounted) return;
    setState(() => _itemsPedido.add(_ItemPedido.fromConfirmado(confirmado, def)));
  }

  Future<void> _editarItem(int index) async {
    final item = _itemsPedido[index];
    if (item.def == null) return;
    final confirmado = await showPlatoSelectorSheet(context, item.def!);
    if (confirmado == null || !mounted) return;
    final cantidadPrevia = item.cantidad;
    final newItem = _ItemPedido.fromConfirmado(confirmado, item.def!)
      ..cantidad = cantidadPrevia;
    setState(() => _itemsPedido[index] = newItem);
  }

  void _eliminarItem(int index) =>
      setState(() => _itemsPedido.removeAt(index));

  Future<void> _mostrarModalCliente() async {
    final result = await showModalBottomSheet<_ClienteData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClienteDataSheet(
        initialNombre: _nombreCliente,
        initialMetodoPago: _metodoPago,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _nombreCliente = result.nombre;
        _metodoPago = result.metodoPago;
      });
    }
  }

  Future<void> _guardar() async {
    if (_itemsPedido.isEmpty) {
      _snack('Agrega al menos un ítem al pedido', error: true);
      return;
    }
    if (!_clienteValido) {
      _snack('Completa los datos del cliente', error: true);
      await _mostrarModalCliente();
      if (!_clienteValido) return;
    }

    setState(() => _saving = true);
    try {
      final p = widget.pedido;
      final Pedido pedidoFinal;

      if (p != null) {
        pedidoFinal = Pedido(
          id: p.id,
          numeroOrden: p.numeroOrden,
          cliente: _nombreCliente.trim(),
          celular: p.celular,
          metodoPago: _metodoPago,
          estado: p.estado,
          estadoPago: p.estadoPago,
          productos: _itemsPedido.map((i) => i.mapa).toList(),
          fecha: p.fecha,
          total: _total,
          envasesLlevar: 0,
          notas: _notasCtrl.text.trim(),
          cancelado: p.cancelado,
          fotoTransferenciaPath: p.fotoTransferenciaPath,
        );
      } else {
        pedidoFinal = Pedido(
          numeroOrden: 0,
          cliente: _nombreCliente.trim(),
          celular: '',
          metodoPago: _metodoPago,
          estado: OrderStatus.enPreparacion,
          productos: _itemsPedido.map((i) => i.mapa).toList(),
          fecha: DateTime.now(),
          total: _total,
          notas: _notasCtrl.text.trim(),
        );
      }

      final error = pedidoFinal.validar();
      if (error != null) {
        _snack(error, error: true);
        setState(() => _saving = false);
        return;
      }

      if (p != null) {
        await PedidoService.actualizar(pedidoFinal);
        // Si el pedido ya estaba cobrado, marcarlo para recobro
        if (p.estadoPago == PaymentStatus.cobrado) {
          await PedidoService.setRecobrar(p.id!);
        }
        if (mounted) { _snack('Pedido actualizado exitosamente', error: false); context.pop(true); }
      } else {
        await PedidoService.guardar(pedidoFinal);
        if (mounted) { _snack('Pedido guardado exitosamente', error: false); context.pop(true); }
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {required bool error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    // Guard: pedidos cerrados o cancelados no se pueden editar
    if (p != null &&
        (p.estado == OrderStatus.cerrados ||
            p.estado == OrderStatus.cancelada ||
            p.cancelado)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pueden editar pedidos cerrados o cancelados'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      });
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeaderWidget(title: 'Editar Pedido'),
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final title = p != null ? 'Editar Pedido #${p.numeroOrden}' : 'Nuevo Pedido';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeaderWidget(title: title),
      body: _saving
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    children: [
                      // ── Menú ─────────────────────────────────────────
                      _SectionHeader(
                        icon: Icons.restaurant_menu_outlined,
                        title: 'Agregar menú',
                        hint: 'Toca un plato para configurarlo',
                      ),
                      const SizedBox(height: 8),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_menuItems.isEmpty)
                        const _EmptyHint(
                          'No hay ítems de menú.\nCrea ítems desde la sección Menú.',
                        )
                      else
                        ..._menuItems.map(
                          (def) => _MenuCard(
                            def: def,
                            disponible: _stockDisponible[def.id] ?? true,
                            onTap: () => _agregarDelMenu(def),
                          ),
                        ),

                      // ── Pedido ────────────────────────────────────────
                      if (_itemsPedido.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.spacingLarge),
                        _SectionHeader(
                          icon: Icons.receipt_long_outlined,
                          title: 'Pedido',
                          count: _itemsPedido.length,
                        ),
                        const SizedBox(height: 8),
                        ..._itemsPedido.asMap().entries.map(
                              (e) => _PedidoItemTile(
                                item: e.value,
                                onEdit: e.value.def != null
                                    ? () => _editarItem(e.key)
                                    : null,
                                onDelete: () => _eliminarItem(e.key),
                                onIncrement: () =>
                                    setState(() => e.value.cantidad++),
                                onDecrement: () => setState(() {
                                  if (e.value.cantidad > 1) e.value.cantidad--;
                                }),
                              ),
                            ),
                      ],

                      // ── Notas ─────────────────────────────────────────
                      const SizedBox(height: AppConstants.spacingLarge),
                      const _SectionHeader(
                        icon: Icons.notes_outlined,
                        title: 'Notas',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notasCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Notas para cocina (opcional)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                        ),
                      ),

                      // ── Datos del cliente ─────────────────────────────
                      const SizedBox(height: AppConstants.spacingLarge),
                      _buildClienteButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // ── Bottom fijo ───────────────────────────────────────
                OrderFormPaymentSection(
                  total: _total,
                  isEditing: widget.isEditing,
                  onSave: _guardar,
                ),
              ],
            ),
    );
  }

  Widget _buildClienteButton() {
    final filled = _clienteValido;
    final color = filled ? AppColors.success : AppColors.accent;
    return OutlinedButton.icon(
      onPressed: _mostrarModalCliente,
      icon: Icon(
        filled ? Icons.person : Icons.person_add_outlined,
        size: 18,
        color: color,
      ),
      label: Text(
        filled
            ? '$_nombreCliente  ·  ${_metodoPago.displayName}'
            : 'Datos del cliente',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(double.infinity, 0),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      ),
    );
  }
}

// ── Modelo de ítem en memoria ─────────────────────────────────────────────────

class _ItemPedido {
  final String nombre;
  final double precioUnitario;
  int cantidad;
  final Map<String, dynamic> _baseMap;
  final MenuItemDefinicion? def;

  _ItemPedido({
    required this.nombre,
    required this.precioUnitario,
    required Map<String, dynamic> baseMap,
    this.cantidad = 1,
    this.def,
  }) : _baseMap = baseMap;

  double get precioTotal => precioUnitario * cantidad;

  Map<String, dynamic> get mapa =>
      {..._baseMap, 'precio': precioUnitario, 'cantidad': cantidad};

  factory _ItemPedido.fromConfirmado(PlatoConfirmado c, MenuItemDefinicion def) =>
      _ItemPedido(
        nombre: c.nombre,
        precioUnitario: c.precio,
        baseMap: c.toProductoMap(),
        def: def,
      );

  factory _ItemPedido.fromProductoMap(Map<String, dynamic> m) {
    final nombre = m['nombre'] as String? ?? 'Producto';
    final precio = (m['precio'] as num?)?.toDouble() ?? 0.0;
    final cantidad = (m['cantidad'] as int?) ?? 1;
    return _ItemPedido(
      nombre: nombre,
      precioUnitario: precio,
      baseMap: Map<String, dynamic>.from(m),
      cantidad: cantidad,
    );
  }
}

// ── Widgets de apoyo ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final int? count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.hint,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 14),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemDefinicion def;
  final bool disponible;
  final VoidCallback onTap;

  const _MenuCard({
    required this.def,
    required this.disponible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final precios = def.tiers.map((t) => t.precio).toList()..sort();
    final precioLabel = precios.isEmpty
        ? ''
        : precios.length == 1
            ? '\$${precios.first.toStringAsFixed(0)}'
            : '\$${precios.first.toStringAsFixed(0)}–\$${precios.last.toStringAsFixed(0)}';

    final cardColor = disponible
        ? AppColors.cardBackground
        : AppColors.cardBackground.withValues(alpha: 0.5);

    return Tooltip(
      message: disponible ? '' : 'Sin stock suficiente',
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        child: InkWell(
          onTap: disponible ? onTap : null,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.nombre,
                        style: TextStyle(
                          color: disponible ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (def.tiers.isNotEmpty)
                        Text(
                          '${def.tiers.length} tier(s)',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (precioLabel.isNotEmpty)
                  Text(
                    precioLabel,
                    style: TextStyle(
                      color: disponible ? AppColors.price : Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                const SizedBox(width: 10),
                Icon(
                  Icons.add_circle_outline,
                  color: disponible ? AppColors.accent : Colors.white24,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PedidoItemTile extends StatelessWidget {
  final _ItemPedido item;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PedidoItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: onEdit != null
            ? BorderSide(color: AppColors.accent.withValues(alpha: 0.25), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      if (onEdit != null) ...[
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '\$${item.precioUnitario.toStringAsFixed(2)} c/u',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: item.cantidad > 1 ? AppColors.accent : Colors.white24,
              ),
              onPressed: item.cantidad > 1 ? onDecrement : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            SizedBox(
              width: 22,
              child: Text(
                '${item.cantidad}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.price),
              onPressed: onIncrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            const SizedBox(width: 2),
            Text(
              '\$${item.precioTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.price, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 18),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modal datos del cliente ───────────────────────────────────────────────────

class _ClienteData {
  final String nombre;
  final PaymentMethod metodoPago;
  const _ClienteData({required this.nombre, required this.metodoPago});
}

class _ClienteDataSheet extends StatefulWidget {
  final String initialNombre;
  final PaymentMethod initialMetodoPago;

  const _ClienteDataSheet({
    required this.initialNombre,
    required this.initialMetodoPago,
  });

  @override
  State<_ClienteDataSheet> createState() => _ClienteDataSheetState();
}

class _ClienteDataSheetState extends State<_ClienteDataSheet> {
  late final TextEditingController _nombreCtrl;
  late PaymentMethod _metodo;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre);
    _metodo = widget.initialMetodoPago;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Datos del cliente',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nombreCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre del cliente',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Método de pago',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<PaymentMethod>(
                  title: const Text('Efectivo',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: PaymentMethod.efectivo,
                  // ignore: deprecated_member_use
                  groupValue: _metodo,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _metodo = v!),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<PaymentMethod>(
                  title: const Text('Transferencia',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: PaymentMethod.transferencia,
                  // ignore: deprecated_member_use
                  groupValue: _metodo,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _metodo = v!),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _ClienteData(
                  nombre: _nombreCtrl.text.trim(),
                  metodoPago: _metodo,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
