import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/insumo.dart';
import '../services/insumo_service.dart';
import '../widgets/back_header_widget.dart';
import 'insumo_form_screen.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  List<Insumo> _insumos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await InsumoService.listar();
      setState(() {
        _insumos = lista;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeaderWidget(title: 'Insumos'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InsumoFormScreen()),
          );
          if (ok == true) _cargar();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_insumos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'No hay insumos',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Toca + para agregar uno',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _insumos.length,
        itemBuilder: (context, index) {
          return _buildInsumoCard(_insumos[index]);
        },
      ),
    );
  }

  Widget _buildInsumoCard(Insumo insumo) {
    final bajoMinimo = insumo.bajoMinimo;
    // Calcular porcentaje de stock respecto al mínimo
    double porcentaje;
    if (insumo.cantidadMinima <= 0) {
      porcentaje = insumo.cantidadActual > 0 ? 1.0 : 0.0;
    } else {
      porcentaje = insumo.cantidadActual / insumo.cantidadMinima;
      if (porcentaje > 1.0) porcentaje = 1.0;
    }

    // Determinar color según nivel de stock
    Color barraColor;
    if (bajoMinimo) {
      barraColor = AppColors.error;
    } else if (porcentaje < 0.5) {
      barraColor = AppColors.error;
    } else if (porcentaje < 1.0) {
      barraColor = AppColors.highlight;
    } else {
      barraColor = AppColors.success;
    }

    return Card(
      elevation: AppConstants.cardElevation,
      color:
          bajoMinimo
              ? AppColors.cardBackground.withValues(alpha: 0.9)
              : AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        side:
            bajoMinimo
                ? const BorderSide(color: AppColors.error, width: 1.5)
                : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor:
              bajoMinimo
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.accent.withValues(alpha: 0.3),
          child: Icon(
            bajoMinimo ? Icons.warning_amber_rounded : Icons.inventory_2,
            color: bajoMinimo ? AppColors.error : AppColors.accent,
          ),
        ),
        title: Text(
          insumo.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${insumo.cantidadActual} / ${insumo.cantidadMinima} ${insumo.unidadMedida}',
              style: TextStyle(
                color: bajoMinimo ? AppColors.error : Colors.white70,
                fontSize: 14,
              ),
            ),
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
                fontWeight: FontWeight.w500,
              ),
            ),
            if (bajoMinimo)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Stock por debajo del mínimo',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
          size: 16,
        ),
        onTap: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InsumoFormScreen(insumo: insumo),
            ),
          );
          if (ok == true) _cargar();
        },
      ),
    );
  }
}
