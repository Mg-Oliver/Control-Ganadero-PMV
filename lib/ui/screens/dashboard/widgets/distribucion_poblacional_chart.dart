import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/poblacion_aggregator.dart';

class DistribucionPoblacionalChart extends StatefulWidget {
  final ResultadoAgregacion datos;
  final VoidCallback? onRegistrarAnimal;

  const DistribucionPoblacionalChart({
    super.key,
    required this.datos,
    this.onRegistrarAnimal,
  });

  @override
  State<DistribucionPoblacionalChart> createState() =>
      _DistribucionPoblacionalChartState();
}

class _DistribucionPoblacionalChartState
    extends State<DistribucionPoblacionalChart> {
  int? _barTocadaGrupoIdx;
  int? _barTocadaRodIdx;

  // ─── Paleta zootécnica ────────────────────────────────────────────────────

  // 10.2.3 — tonalidades frías/azuladas para Machos
  static const _paletaMachos = [
    Color(0xFF38BDF8), // Ternero – sky blue
    Color(0xFF0369A1), // Novillo – dark blue
    Color(0xFF7C3AED), // Toro – violet
    Color(0xFF0E7490), // extra 1
    Color(0xFF1D4ED8), // extra 2
  ];

  // 10.2.3 — tonalidades cálidas/rosáceas para Hembras
  static const _paletaHembras = [
    Color(0xFFFBBF24), // Ternera – amber
    Color(0xFFF97316), // Novilla – orange
    Color(0xFF047857), // Vaca – emerald
    Color(0xFFEC4899), // extra 1
    Color(0xFFD97706), // extra 2
  ];

  Color _colorMacho(int idx) =>
      _paletaMachos[idx % _paletaMachos.length];

  Color _colorHembra(int idx) =>
      _paletaHembras[idx % _paletaHembras.length];

  // ─── Build helpers ────────────────────────────────────────────────────────

  List<BarChartGroupData> _buildGroups() {
    final groups = <BarChartGroupData>[];
    final machos = widget.datos.machos;
    final hembras = widget.datos.hembras;

    // Machos: x = 0, 1, 2, ...
    for (int i = 0; i < machos.length; i++) {
      final g = machos[i];
      final touched =
          _barTocadaGrupoIdx == i && _barTocadaRodIdx == 0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: g.cantidad.toDouble(),
              color: _colorMacho(i),
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ],
          showingTooltipIndicators: touched ? [0] : [],
        ),
      );
    }

    // Gap visual entre sexos (si hay ambos grupos)
    final gapX = machos.length;

    // Hembras: x = machos.length + 1, machos.length + 2, ...
    for (int i = 0; i < hembras.length; i++) {
      final g = hembras[i];
      final xPos = gapX + 1 + i;
      final touched =
          _barTocadaGrupoIdx == xPos && _barTocadaRodIdx == 0;
      groups.add(
        BarChartGroupData(
          x: xPos,
          barRods: [
            BarChartRodData(
              toY: g.cantidad.toDouble(),
              color: _colorHembra(i),
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ],
          showingTooltipIndicators: touched ? [0] : [],
        ),
      );
    }

    return groups;
  }

  /// Devuelve el grupo de datos asociado al x del chart
  GrupoPoblacional? _grupoPorX(int x) {
    final machos = widget.datos.machos;
    final hembras = widget.datos.hembras;
    if (x < machos.length) return machos[x];
    final hIdx = x - machos.length - 1;
    if (hIdx >= 0 && hIdx < hembras.length) return hembras[hIdx];
    return null;
  }

  String _etiquetaX(double value) {
    final g = _grupoPorX(value.toInt());
    if (g == null) return '';
    // Nombre corto: hasta 7 chars para no solapar
    final cat = g.categoria;
    return cat.length > 7 ? '${cat.substring(0, 6)}…' : cat;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.datos.estaVacio) {
      return _EmptyState(onRegistrarAnimal: widget.onRegistrarAnimal);
    }

    final maxY = [
      ...widget.datos.machos.map((g) => g.cantidad),
      ...widget.datos.hembras.map((g) => g.cantidad),
    ].fold(0, (a, b) => a > b ? a : b);

    final chartMaxY = (maxY + (maxY * 0.25).ceil()).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 10.2.1 — Gráfico de barras
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              groupsSpace: 8,
              barGroups: _buildGroups(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (chartMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              // 10.2.2 — Tooltips interactivos
              barTouchData: BarTouchData(
                handleBuiltInTouches: true,
                touchCallback: (event, response) {
                  setState(() {
                    if (event is FlTapUpEvent ||
                        event is FlPointerExitEvent) {
                      _barTocadaGrupoIdx = null;
                      _barTocadaRodIdx = null;
                    } else if (response?.spot != null) {
                      _barTocadaGrupoIdx =
                          response!.spot!.touchedBarGroup.x;
                      _barTocadaRodIdx =
                          response.spot!.touchedBarGroupIndex;
                    }
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      AppColors.textPrimary.withValues(alpha: 0.92),
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final g = _grupoPorX(group.x);
                    if (g == null) return null;
                    return BarTooltipItem(
                      '${g.categoria}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${g.cantidad} cabezas  •  ${g.porcentaje.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: (chartMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final label = _etiquetaX(value);
                      if (label.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 10.3.1 — Leyenda cromática
        _Leyenda(
          machos: widget.datos.machos,
          hembras: widget.datos.hembras,
          colorMacho: _colorMacho,
          colorHembra: _colorHembra,
        ),
        const SizedBox(height: 16),
        // 10.3.2 — Panel de resumen poblacional
        _ResumenPoblacional(datos: widget.datos),
      ],
    );
  }
}

// ─── Leyenda ─────────────────────────────────────────────────────────────────

class _Leyenda extends StatelessWidget {
  final List<GrupoPoblacional> machos;
  final List<GrupoPoblacional> hembras;
  final Color Function(int) colorMacho;
  final Color Function(int) colorHembra;

  const _Leyenda({
    required this.machos,
    required this.hembras,
    required this.colorMacho,
    required this.colorHembra,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ...machos.asMap().entries.map(
              (e) => _LegendaChip(
                label: e.value.categoria,
                sexo: 'Macho',
                color: colorMacho(e.key),
              ),
            ),
        ...hembras.asMap().entries.map(
              (e) => _LegendaChip(
                label: e.value.categoria,
                sexo: 'Hembra',
                color: colorHembra(e.key),
              ),
            ),
      ],
    );
  }
}

class _LegendaChip extends StatelessWidget {
  final String label;
  final String sexo;
  final Color color;

  const _LegendaChip({
    required this.label,
    required this.sexo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '(${sexo == 'Macho' ? '♂' : '♀'})',
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Resumen poblacional ──────────────────────────────────────────────────────

class _ResumenPoblacional extends StatelessWidget {
  final ResultadoAgregacion datos;

  const _ResumenPoblacional({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _StatItem(
            label: '♂ Machos',
            valor: '${datos.totalMachos}',
            color: const Color(0xFF0369A1),
          ),
          _Divisor(),
          _StatItem(
            label: '♀ Hembras',
            valor: '${datos.totalHembras}',
            color: const Color(0xFFF97316),
          ),
          _Divisor(),
          _StatItem(
            label: 'Total hato',
            valor: '${datos.totalHato}',
            color: AppColors.primary,
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final bool destacado;

  const _StatItem({
    required this.label,
    required this.valor,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

// ─── Empty State (10.3.3) ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback? onRegistrarAnimal;

  const _EmptyState({this.onRegistrarAnimal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 52,
            color: AppColors.border,
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin datos de distribución',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra animales para visualizar la distribución\npoblacional del hato por categoría y sexo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRegistrarAnimal,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Registrar Animal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
