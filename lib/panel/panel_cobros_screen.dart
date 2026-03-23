import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/supabase_constants.dart';

/// Vista de solo lectura de cobros desde Supabase (panel web).
class PanelCobrosScreen extends StatefulWidget {
  const PanelCobrosScreen({super.key});

  @override
  State<PanelCobrosScreen> createState() => _PanelCobrosScreenState();
}

class _PanelCobrosScreenState extends State<PanelCobrosScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from(SupabaseConstants.tableCobros)
          .select()
          .order('id', ascending: false)
          .limit(200);
      setState(() {
        _data = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Cobros (solo lectura)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_data.isEmpty)
          const Center(
            child: Text(
              'No hay registros.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.5)),
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Cliente ID', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Monto a pagar', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Estado', style: TextStyle(color: Colors.white))),
              ],
              rows: _data.map((e) {
                final id = e[SupabaseConstants.colCobroId]?.toString() ?? '';
                final clienteId = e[SupabaseConstants.colCobroClienteId]?.toString() ?? '';
                final monto = (e[SupabaseConstants.colCobroMontoAPagar] as num?)?.toDouble();
                final estado = e[SupabaseConstants.colCobroEstado]?.toString() ?? '';
                return DataRow(
                  cells: [
                    DataCell(Text(id, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(clienteId, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(monto != null ? '\$${monto.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(estado, style: const TextStyle(color: Colors.white70))),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
