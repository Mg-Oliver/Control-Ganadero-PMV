import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../data/models/animal_model.dart';
import '../../../../common/bovine_avatar_placeholder.dart';
import 'animal_genealogia_tree.dart';

class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final AnimalModel? Function(String?)? buscarAnimal;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animal,
    this.buscarAnimal,
    this.isSelected = false,
    required this.onTap,
  });

  static Color colorPorEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return AppColors.success;
      case 'Vendido':
        return const Color(0xFF6B7280);
      case 'Muerto':
        return AppColors.error;
      case 'Descartado':
        return AppColors.warning;
      case 'Robado':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = colorPorEstado(animal.estadoActual);
    final urlPrincipal = animal.fotos.isNotEmpty ? animal.fotos.first : null;
    final tituloNombre =
        (animal.nombreAlias != null && animal.nombreAlias!.trim().isNotEmpty)
        ? '${animal.areteManejo} • ${animal.nombreAlias}'
        : 'Arete ${animal.areteManejo}';

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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: urlPrincipal == null || urlPrincipal.trim().isEmpty
                          ? _buildPlaceholder()
                          : Image.network(
                              urlPrincipal,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: const Color(0xFFF3F4F6),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                animal.codigoSistema,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                animal.estadoActual,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tituloNombre,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: animal.esRazaPura
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            animal.razaEtiquetaDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: animal.esRazaPura
                                  ? AppColors.primary
                                  : const Color(0xFF1D4ED8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _CategoriaBadge(categoria: animal.categoriaZootecnica),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  animal.sexo == 'Macho'
                                      ? Icons.male_rounded
                                      : Icons.female_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  animal.sexo,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monitor_weight_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  animal.pesoActual != null
                                      ? Formatters.formatearPeso(
                                          animal.pesoActual,
                                        )
                                      : 'Sin peso',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              AnimalGenealogiaTree(animal: animal, buscarAnimal: buscarAnimal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return BovineAvatarPlaceholder.animal(
      areteOMote: animal.nombreAlias ?? animal.areteManejo,
      razaODescripcion: animal.razaEtiquetaDisplay,
      sexo: animal.sexo,
      tipoExplotacion: animal.tipoExplotacion,
      width: 72,
      height: 72,
    );
  }
}

class _CategoriaBadge extends StatelessWidget {
  final String categoria;

  const _CategoriaBadge({required this.categoria});

  static Color _colorPorCategoria(String cat) {
    switch (cat) {
      case 'Ternero':
      case 'Ternera':
        return const Color(0xFF92400E); // ámbar oscuro
      case 'Novillo':
      case 'Novilla':
        return const Color(0xFF0369A1); // azul
      case 'Toro':
        return const Color(0xFF7C3AED); // violeta
      case 'Vaca':
        return const Color(0xFF047857); // verde esmeralda
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorPorCategoria(categoria);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
