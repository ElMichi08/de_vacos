import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/supabase_constants.dart';

/// Vista de solo lectura de reportes_semanales desde Supabase (panel web).
class PanelReportesScreen extends StatefulWidget {
  const PanelReportesScreen({super.key});

  @override
  State<PanelReportesScreen> createState() => _PanelReportesScreenState();
}

class _PanelReportesScreenState extends State<PanelReportesScreen> {
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
          .from(SupabaseConstants.tableReportesSemanales)
          .select()
          .order(SupabaseConstants.colReporteFechaCorte, ascending: false)
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
          'Reportes semanales (solo lectura)',
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
                DataColumn(label: Text('Cliente ID', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Fecha corte', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Pedidos', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Total ventas', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Comisión', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Estado pago', style: TextStyle(color: Colors.white))),
              ],
              rows: _data.map((e) {
                final clienteId = e[SupabaseConstants.colReporteClienteId]?.toString() ?? '';
                final fecha = e[SupabaseConstants.colReporteFechaCorte]?.toString() ?? '';
                final pedidos = e[SupabaseConstants.colReporteCantidadPedidos]?.toString() ?? '';
                final ventas = (e[SupabaseConstants.colReporteTotalVentas] as num?)?.toDouble();
                final comision = (e[SupabaseConstants.colReporteTotalComision] as num?)?.toDouble();
                final estado = e[SupabaseConstants.colReporteEstadoPago]?.toString() ?? '';
                return DataRow(
                  cells: [
                    DataCell(Text(clienteId, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(fecha, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(pedidos, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(ventas != null ? '\$${ventas.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(comision != null ? '\$${comision.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.white70))),
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
