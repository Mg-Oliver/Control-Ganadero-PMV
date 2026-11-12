import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/finca_model.dart';
import '../../../../controllers/inventario_controller.dart';

class FincaExpedienteView extends StatelessWidget {
  final FincaModel finca;
  final InventarioController controller;

  const FincaExpedienteView({
    super.key,
    required this.finca,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final lotes = controller.obtenerLotesDeFinca(finca.id);
    final animales = controller.obtenerAnimalesDeFinca(finca.id);
    final esActiva = finca.estado == 'Activa';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (finca.fotos.isNotEmpty) ...[
          SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: finca.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: finca.fotos.length == 1 ? 300 : 210,
                  height: 155,
                  child: Image.network(
                    finca.fotos[i],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finca.identificador,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    finca.nombre,
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
                color: (esActiva ? AppColors.success : AppColors.textSecondary)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                finca.estado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: esActiva ? AppColors.success : AppColors.textSecondary,
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
                  'Información Territorial e Hídrica',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Divider(height: 16),
                _RowDato('Ubicación', finca.ubicacion ?? 'No especificada'),
                _RowDato(
                  'Superficie',
                  finca.superficieHectareas != null
                      ? '${finca.superficieHectareas!.toStringAsFixed(2)} hectáreas'
                      : 'No registrada',
                ),
                _RowDato(
                  'Fuentes de Agua',
                  finca.fuentesAgua.isEmpty
                      ? 'Sin fuentes registradas'
                      : finca.fuentesAgua.join(', '),
                ),
                if (finca.observaciones != null &&
                    finca.observaciones!.trim().isNotEmpty)
                  _RowDato('Observaciones', finca.observaciones!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Mangas de Manejo (${lotes.length})',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (lotes.isEmpty)
          const Text(
            'No hay mangas registradas en esta finca.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          )
        else
          ...lotes.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    '${l.nombre} (${l.identificador})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${l.propositoProductivo} • GDP ${l.metaGananciaPesoDiaria.toStringAsFixed(3)} kg/día',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () => controller.seleccionarLote(l),
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),
        Text(
          'Animales Asignados Actualmente (${animales.length})',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (animales.isEmpty)
          const Text(
            'No hay animales ubicados en este predio.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          )
        else
          ...animales.take(25).map(
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
                        '${a.codigoSistema} • ${a.razaEtiquetaDisplay}',
                      ),
                      trailing:
                          const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => controller.seleccionarAnimal(a),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _RowDato extends StatelessWidget {
  final String label;
  final String value;

  const _RowDato(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

