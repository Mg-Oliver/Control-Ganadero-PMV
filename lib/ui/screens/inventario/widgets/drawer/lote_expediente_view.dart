import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../data/models/lote_model.dart';
import '../../../../controllers/inventario_controller.dart';

class LoteExpedienteView extends StatelessWidget {
  final LoteModel lote;
  final InventarioController controller;

  const LoteExpedienteView({
    super.key,
    required this.lote,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animales = controller.obtenerAnimalesDeLote(lote.id);
    final finca =
        controller.allFincas.where((f) => f.id == lote.fincaId).firstOrNull;
    final esActivo = lote.estado == 'Activo';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lote.identificador,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    lote.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (esActivo ? AppColors.success : AppColors.textSecondary)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lote.estado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: esActivo ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Material(
          color: const Color(0xFFF9FAFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parámetros Productivos y Nutrición',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Divider(height: 16),
                _LoteRow(
                  'Finca Madre',
                  lote.fincaNombre ?? controller.nombreFincaPorId(lote.fincaId),
                ),
                _LoteRow('Propósito', lote.propositoProductivo),
                _LoteRow(
                  'Meta GDP Diaria',
                  '${lote.metaGananciaPesoDiaria.toStringAsFixed(3)} kg/día',
                ),
                _LoteRow(
                  'Dieta Asignada',
                  lote.dietaAsignada ?? 'Pastoreo base sin suplemento registrado',
                ),
              ],
            ),
          ),
        ),

        if (finca != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => controller.seleccionarFinca(finca),
            icon: const Icon(Icons.landscape_outlined, size: 17),
            label: Text('Ver Ficha de ${finca.nombre}'),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          'Animales Asignados a la Manga (${animales.length})',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (animales.isEmpty)
          const Text(
            'Actualmente no hay animales asignados a esta manga.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          )
        else
          ...animales.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 19,
                  ),
                  title: Text(
                    'Arete ${a.areteManejo}${a.nombreAlias != null ? ' • ${a.nombreAlias}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${a.razaEtiquetaDisplay} • ${a.pesoActual != null ? Formatters.formatearPeso(a.pesoActual) : "Sin peso"}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () => controller.seleccionarAnimal(a),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoteRow extends StatelessWidget {
  final String label;
  final String value;

  const _LoteRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

