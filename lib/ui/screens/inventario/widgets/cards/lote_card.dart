import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/lote_model.dart';

class LoteCard extends StatelessWidget {
  final LoteModel lote;
  final String fincaNombre;
  final int animalesCount;
  final bool isSelected;
  final VoidCallback onTap;

  const LoteCard({
    super.key,
    required this.lote,
    required this.fincaNombre,
    required this.animalesCount,
    this.isSelected = false,
    required this.onTap,
  });

  String _propositoLabel(String p) {
    switch (p) {
      case 'Lecheria':
        return 'Lechería';
      case 'Cria':
        return 'Cría';
      default:
        return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esActivo = lote.estado == 'Activo';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lote.identificador,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          lote.nombre,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (esActivo
                              ? AppColors.success
                              : AppColors.textSecondary)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lote.estado,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: esActivo
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.landscape_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      fincaNombre,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BadgeInfo(
                    text: _propositoLabel(lote.propositoProductivo),
                    bgColor: const Color(0xFFE8F5E9),
                    textColor: AppColors.primary,
                  ),
                  _BadgeInfo(
                    text:
                        'GDP: ${lote.metaGananciaPesoDiaria.toStringAsFixed(3)} kg/día',
                    bgColor: const Color(0xFFF3F4F6),
                    textColor: AppColors.textPrimary,
                  ),
                  _BadgeInfo(
                    text: '$animalesCount animales',
                    bgColor: const Color(0xFFF3F4F6),
                    textColor: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _BadgeInfo({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

