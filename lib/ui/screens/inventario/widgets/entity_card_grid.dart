import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../controllers/inventario_controller.dart';
import 'cards/animal_card.dart';
import 'cards/finca_card.dart';
import 'cards/lote_card.dart';

class EntityCardGrid extends StatefulWidget {
  final InventarioController controller;

  const EntityCardGrid({super.key, required this.controller});

  @override
  State<EntityCardGrid> createState() => _EntityCardGridState();
}

class _EntityCardGridState extends State<EntityCardGrid> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. FILA DE KPIs VISUALES CONTEXTUALES
        _buildKpiRow(c),
        const SizedBox(height: 16),

        // 2. HEADER DE TARJETAS DE RESUMEN RÁPIDO
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Tarjetas de Resumen Rápido',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3. GRID RESPONSIVO DE TARJETAS
        if (c.totalResultadosCoincidentes == 0)
          _buildEmptyCardsState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final cols = maxW >= 920 ? 3 : (maxW >= 560 ? 2 : 1);
              const spacing = 12.0;
              final itemWidth = (maxW - (spacing * (cols - 1))) / cols;

              final widgets = _construirTarjetasActivas(c);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: widgets
                    .map((card) => SizedBox(width: itemWidth, child: card))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  List<Widget> _construirTarjetasActivas(InventarioController c) {
    final porId = {for (final a in c.allAnimales) a.id: a};
    switch (c.seccionActiva) {
      case InventarioSeccion.fincas:
        return c.fincasFiltradas.map((finca) {
          return FincaCard(
            finca: finca,
            lotesCount: c.obtenerLotesDeFinca(finca.id).length,
            animalesCount: c.obtenerAnimalesDeFinca(finca.id).length,
            isSelected: c.selectedFinca?.id == finca.id,
            onTap: () => c.seleccionarFinca(finca),
          );
        }).toList();

      case InventarioSeccion.lotes:
        return c.lotesFiltrados.map((lote) {
          return LoteCard(
            lote: lote,
            fincaNombre: lote.fincaNombre ?? c.nombreFincaPorId(lote.fincaId),
            animalesCount: c.obtenerAnimalesDeLote(lote.id).length,
            isSelected: c.selectedLote?.id == lote.id,
            onTap: () => c.seleccionarLote(lote),
          );
        }).toList();

      case InventarioSeccion.animales:
        return c.animalesFiltrados.map((animal) {
          return AnimalCard(
            animal: animal,
            buscarAnimal: (id) => porId[id],
            isSelected: c.selectedAnimal?.id == animal.id,
            onTap: () => c.seleccionarAnimal(animal),
          );
        }).toList();
    }
  }

  Widget _buildKpiRow(InventarioController c) {
    final List<({String label, String value, IconData icon, Color color})> kpis;

    switch (c.seccionActiva) {
      case InventarioSeccion.fincas:
        final lista = c.fincasFiltradas;
        final activas = lista.where((f) => f.estado == 'Activa').length;
        final totalHa = lista.fold<double>(
          0.0,
          (sum, f) => sum + (f.superficieHectareas ?? 0.0),
        );
        kpis = [
          (
            label: 'Fincas en Vista',
            value: '${lista.length}',
            icon: Icons.landscape_rounded,
            color: AppColors.primary,
          ),
          (
            label: 'Predios Activos',
            value: '$activas',
            icon: Icons.verified_outlined,
            color: AppColors.success,
          ),
          (
            label: 'Superficie Acumulada',
            value: '${totalHa.toStringAsFixed(1)} ha',
            icon: Icons.square_foot_rounded,
            color: AppColors.secondary,
          ),
        ];

      case InventarioSeccion.lotes:
        final lista = c.lotesFiltrados;
        final activos = lista.where((l) => l.estado == 'Activo').length;
        final gdpProm = lista.isEmpty
            ? 0.0
            : lista.fold<double>(0.0, (s, l) => s + l.metaGananciaPesoDiaria) /
                  lista.length;
        kpis = [
          (
            label: 'Mangas Filtradas',
            value: '${lista.length}',
            icon: Icons.grid_view_rounded,
            color: AppColors.primary,
          ),
          (
            label: 'Mangas Activas',
            value: '$activos',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          (
            label: 'Meta GDP Promedio',
            value: '${gdpProm.toStringAsFixed(3)} kg/día',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
        ];

      case InventarioSeccion.animales:
        final lista = c.animalesFiltrados;
        final activos = lista.where((a) => a.estadoActual == 'Activo').length;
        final hembras = lista.where((a) => a.sexo == 'Hembra').length;
        final conPeso = lista.where((a) => a.pesoActual != null).toList();
        final pesoProm = conPeso.isEmpty
            ? 0.0
            : conPeso.fold<double>(0.0, (s, a) => s + a.pesoActual!) /
                  conPeso.length;
        kpis = [
          (
            label: 'Cabezas Filtradas',
            value: '${lista.length}',
            icon: Icons.pets_rounded,
            color: AppColors.primary,
          ),
          (
            label: 'Activos / Hembras',
            value: '$activos act. • $hembras ♀',
            icon: Icons.health_and_safety_outlined,
            color: AppColors.success,
          ),
          (
            label: 'Peso Promedio',
            value: conPeso.isEmpty
                ? 'N/D'
                : '${pesoProm.toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.secondary,
          ),
        ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cols = maxW >= 660 ? 3 : 1;
        const spacing = 12.0;
        final width = (maxW - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: kpis.map((kpi) {
            return SizedBox(
              width: width,
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: kpi.color.withValues(alpha: 0.12),
                        child: Icon(kpi.icon, color: kpi.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kpi.label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kpi.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyCardsState() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 8),
              Text(
                'No hay registros que coincidan con los filtros actuales.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
