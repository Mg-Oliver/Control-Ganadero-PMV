import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/poblacion_aggregator.dart';
import '../../../data/dev/seed_service.dart';
import '../../../core/services/app_feedback.dart';
import '../../controllers/inventario_controller.dart';
import 'widgets/distribucion_poblacional_chart.dart';
import 'widgets/metricas_ganaderas.dart';

class DashboardScreen extends StatelessWidget {
  final InventarioController controller;
  final VoidCallback onGoToExpediente;
  final VoidCallback onGoToInventario;
  final VoidCallback? onRegistrarAnimal;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onGoToExpediente,
    required this.onGoToInventario,
    this.onRegistrarAnimal,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hoy = DateTime.now();
        final todayStart = DateTime(hoy.year, hoy.month, hoy.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final animalesActivos = controller.allAnimales
            .where((a) => !a.esExterno && a.estadoActual == 'Activo')
            .toList();
        final distribucion = PoblacionAggregator.agregar(animalesActivos);

        final totalFincas = controller.allFincas.length;
        final totalAnimalesActivos = animalesActivos.length;

        // Eventos del día: altas + salidas ocurridas hoy
        int eventosHoy = controller.allAnimales.where((a) {
          if (a.esExterno) return false;
          final entrada = a.fechaEntrada;
          final salida = a.fechaSalida;
          final altaHoy =
              !entrada.isBefore(todayStart) && entrada.isBefore(todayEnd);
          final salidaHoy =
              salida != null &&
              !salida.isBefore(todayStart) &&
              salida.isBefore(todayEnd);
          return altaHoy || salidaHoy;
        }).length;

        // Valor estimado: suma de precio_compra de animales activos
        final valorEstimado = animalesActivos.fold<double>(
          0,
          (acc, a) => acc + (a.precioCompra ?? 0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 9.1 Encabezado ──────────────────────────────────────────
              _DashboardHeader(
                onRegistrarAnimal: onRegistrarAnimal ?? onGoToExpediente,
              ),
              const SizedBox(height: 28),
              // ── 9.2 + 9.3 Cuarteto KPI responsivo ──────────────────────
              _SectionTitle(
                icon: Icons.bar_chart_rounded,
                label: 'Resumen del Hato',
              ),
              const SizedBox(height: 16),
              _KpiGrid(
                totalFincas: totalFincas,
                totalAnimalesActivos: totalAnimalesActivos,
                eventosHoy: eventosHoy,
                valorEstimado: valorEstimado,
                onTapInventario: onGoToInventario,
              ),
              const SizedBox(height: 28),
              // ── 10.2 + 10.3 + 10.4 Gráfico de distribución poblacional ──
              _SectionTitle(
                icon: Icons.pie_chart_outline_rounded,
                label: 'Distribución Poblacional',
              ),
              const SizedBox(height: 16),
              DistribucionPoblacionalChart(
                datos: distribucion,
                onRegistrarAnimal: onRegistrarAnimal ?? onGoToExpediente,
              ),
              const SizedBox(height: 24),
              MetricasGanaderas(
                animales: controller.allAnimales,
                nombreFinca: controller.nombreFincaPorId,
              ),
              const SizedBox(height: 32),
              _SectionTitle(
                icon: Icons.flash_on_rounded,
                label: 'Accesos Rápidos',
              ),
              const SizedBox(height: 16),
              _QuickActionsGrid(
                onGoToExpediente: onRegistrarAnimal ?? onGoToExpediente,
              ),
              const SizedBox(height: 32),
              _SectionTitle(
                icon: Icons.dataset_outlined,
                label: 'Datos de Demostración',
              ),
              const SizedBox(height: 12),
              _SeedCard(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

// ─── 9.1 Encabezado ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onRegistrarAnimal;

  const _DashboardHeader({required this.onRegistrarAnimal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fecha = Text(
          _formatFecha(DateTime.now()),
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        );
        final registrar = FilledButton.icon(
          onPressed: onRegistrarAnimal,
          icon: const Icon(Icons.add_rounded, size: 26),
          label: const Text(
            'Registrar Animal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.botonPrincipal,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 60),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fecha, const SizedBox(height: 16), registrar],
          );
        }
        return Row(
          children: [
            Expanded(child: fecha),
            const SizedBox(width: 24),
            registrar,
          ],
        );
      },
    );
  }

  static String _formatFecha(DateTime d) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final diasSemana = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return '${diasSemana[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}

// ─── Helpers comunes ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 9.2 + 9.3 KPI Grid responsivo ──────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final int totalFincas;
  final int totalAnimalesActivos;
  final int eventosHoy;
  final double valorEstimado;
  final VoidCallback onTapInventario;

  const _KpiGrid({
    required this.totalFincas,
    required this.totalAnimalesActivos,
    required this.eventosHoy,
    required this.valorEstimado,
    required this.onTapInventario,
  });

  static String _formatMoneda(double valor) {
    if (valor == 0) return '\$0';
    final fmt = NumberFormat('#,###', 'es_CO');
    if (valor >= 1000000000) {
      return '\$${NumberFormat('#,##0.0', 'es_CO').format(valor / 1000000000)}B';
    }
    if (valor >= 1000000) {
      return '\$${NumberFormat('#,##0.0', 'es_CO').format(valor / 1000000)}M';
    }
    return '\$${fmt.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      // 9.2.1 — Fincas Activas
      _KpiCard(
        icon: Icons.landscape_rounded,
        valor: '$totalFincas',
        etiqueta: 'Fincas Activas',
        subtexto: 'unidades productivas',
        color: AppColors.primary,
        onTap: onTapInventario,
      ),
      // 9.2.2 — Animales en Inventario
      _KpiCard(
        icon: Icons.pets_rounded,
        valor: '$totalAnimalesActivos',
        etiqueta: 'Animales en Inventario',
        subtexto: 'bovinos activos en hato',
        color: const Color(0xFF0369A1),
        onTap: onTapInventario,
      ),
      // 9.2.3 — Eventos del Día
      _KpiCard(
        icon: Icons.event_note_rounded,
        valor: '$eventosHoy',
        etiqueta: 'Eventos del Día',
        subtexto: 'altas y salidas hoy',
        color: const Color(0xFF7C3AED),
        onTap: null,
      ),
      // 9.2.4 — Valor Estimado del Hato
      _KpiCard(
        icon: Icons.attach_money_rounded,
        valor: _formatMoneda(valorEstimado),
        etiqueta: 'Valor Estimado del Hato',
        subtexto: 'suma de precios de compra',
        color: const Color(0xFF047857),
        onTap: null,
        compacto: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // 9.3.1 — 4 cols >= 900, 2 cols en el resto
        final cols = w >= 900 ? 4 : 2;
        final spacing = 12.0;
        final cardW = (w - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: cardW, child: c)).toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String etiqueta;
  final String subtexto;
  final Color color;
  final VoidCallback? onTap;
  final bool compacto;

  const _KpiCard({
    required this.icon,
    required this.valor,
    required this.etiqueta,
    required this.subtexto,
    required this.color,
    this.onTap,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    // 9.3.2 — Elevación sutil, bordes suaves, AppColors
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                valor,
                style: TextStyle(
                  fontSize: compacto ? 20 : 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtexto,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Accesos Rápidos ──────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onGoToExpediente;

  const _QuickActionsGrid({required this.onGoToExpediente});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.pets_rounded,
        label: '+ Nuevo Animal',
        color: AppColors.botonPrincipal,
        onTap: onGoToExpediente,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return Row(
            children: actions
                .map(
                  (a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: a,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: actions
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: a,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Seed Card ────────────────────────────────────────────────────────────────

class _SeedCard extends StatelessWidget {
  final InventarioController controller;

  const _SeedCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dataset_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cargar datos de demostración con 3 fincas, 6 mangas y 28 animales.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () async {
              SeedService.cargarEnControlador(controller);
              final sincronizado = await SeedService.repoblarEnSupabase();
              if (!context.mounted) return;
              AppFeedback.mostrarExito(
                context: context,
                mensaje: sincronizado
                    ? '¡Datos semilla cargados y sincronizados con Supabase!'
                    : '¡Datos semilla cargados! (3 fincas, 6 mangas y 28 animales)',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.botonPrincipal,
            ),
            child: const Text('Poblar Demo'),
          ),
        ],
      ),
    );
  }
}
