import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../data/models/animal_model.dart';
import '../../../../../data/models/toro_donante_model.dart';
import '../../../../common/bovine_avatar_placeholder.dart';
import '../../../../controllers/inventario_controller.dart';
import '../cards/animal_card.dart';

class AnimalExpedienteView extends StatelessWidget {
  final AnimalModel animal;
  final InventarioController controller;

  const AnimalExpedienteView({
    super.key,
    required this.animal,
    required this.controller,
  });

  void _ampliarFoto(BuildContext context, String url, int index, int total) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                title: Text(
                  '${animal.codigoSistema} • Foto ${index + 1} de $total (Pellizca o usa rueda para zoom)',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = AnimalCard.colorPorEstado(animal.estadoActual);
    final fincaNom = animal.fincaNombre ?? controller.nombreFincaPorId(animal.fincaId);
    final loteNom = animal.loteNombre ?? controller.nombreLotePorId(animal.loteId);
    final gen = animal.genealogia;
    final padreInterno = controller.buscarAnimalPorId(gen?.padreId);
    final madreInterna = controller.buscarAnimalPorId(gen?.madreId);

    return SingleChildScrollView(
      key: ValueKey('expediente_${animal.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // HISTORIAL DE RETORNO SI NAVEGÓ POR ÁRBOL GENEALÓGICO
        if (controller.historialAnimalesDrawer.isNotEmpty) ...[
          Material(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: controller.regresarAnimalAnteriorEnDrawer,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Volver a Arete ${controller.historialAnimalesDrawer.last.areteManejo}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 1. GALERÍA DE FOTOS AMPLIABLE (HASTA 3)
        _buildGaleriaFotos(context),
        const SizedBox(height: 16),

        // 2. ENCABEZADO DE IDENTIDAD Y ESTADO
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.codigoSistema,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    animal.nombreAlias != null &&
                            animal.nombreAlias!.trim().isNotEmpty
                        ? 'Arete ${animal.areteManejo} "${animal.nombreAlias}"'
                        : 'Arete ${animal.areteManejo}',
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
                color: colorEstado.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                animal.estadoActual,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorEstado,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. FICHA TÉCNICA COMPLETA
        _DetailBlock(
          title: 'Ficha Técnica y Biometría',
          icon: Icons.badge_outlined,
          children: [
            _DataPair('Código Sistema', animal.codigoSistema),
            _DataPair('Arete de Manejo', animal.areteManejo),
            _DataPair('Arete Oficial / RFID', animal.areteOficial ?? 'No registrado'),
            _DataPair('Sexo', animal.sexo),
            _DataPair('Categoría Zootécnica', animal.categoriaZootecnica),
            _DataPair(
              'Peso Actual',
              animal.pesoActual != null
                  ? Formatters.formatearPeso(animal.pesoActual)
                  : 'Pendiente de pesaje',
            ),
            _DataPair(
              'Edad Calculada',
              '${animal.edadFormateada} (${animal.fechaNacimientoExacta ? "Exacta" : "Aproximada"})',
            ),
            _DataPair(
              'Fecha Nacimiento',
              Formatters.formatearFecha(animal.fechaNacimiento),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. DESGLOSE ZOOTÉCNICO (MODO A)
        _DetailBlock(
          title: 'Composición Genética Zootécnica',
          icon: Icons.biotech_outlined,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.esRazaPura
                        ? 'Clasificación: Raza Pura'
                        : 'Clasificación: Cruce / Mezcla (Modo A)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    animal.razaEtiquetaDisplay,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (!animal.esRazaPura && animal.composicionCruces.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: animal.composicionCruces.map((cruce) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${cruce['fraccion'] ?? ''} ${cruce['raza'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // 5. UBICACIÓN ACTUAL
        _DetailBlock(
          title: 'Ubicación y Manejo Actual',
          icon: Icons.place_outlined,
          children: [
            _DataPair('Finca Asignada', fincaNom),
            _DataPair('Manga de Manejo', loteNom),
            _DataPair('Potrero Actual', animal.potreroActual ?? 'Sin asignar'),
            _DataPair('Tipo Explotación', animal.tipoExplotacion),
          ],
        ),
        const SizedBox(height: 12),

        // 6. TRAZABILIDAD ECONÓMICA Y DE ORIGEN
        _DetailBlock(
          title: 'Trazabilidad Económica y Procedencia',
          icon: Icons.receipt_long_outlined,
          children: [
            _DataPair('Origen', animal.origen),
            if (animal.origenOtroDetalle != null &&
                animal.origenOtroDetalle!.trim().isNotEmpty)
              _DataPair('Detalle Procedencia', animal.origenOtroDetalle!),
            _DataPair(
              'Fecha de Entrada',
              Formatters.formatearFecha(animal.fechaEntrada),
            ),
            _DataPair(
              'Precio de Compra',
              animal.precioCompra != null
                  ? Formatters.formatearMoneda(animal.precioCompra)
                  : 'No aplica / Sin registro',
            ),
            if (animal.fechaSalida != null)
              _DataPair(
                'Fecha de Salida',
                Formatters.formatearFecha(animal.fechaSalida),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 7. MARCAS DE HIERRO Y SEÑALES
        _DetailBlock(
          title: 'Marcas de Hierro y Señales Corporales',
          icon: Icons.branding_watermark_outlined,
          children: !animal.marcasHierro.tieneDatos
              ? [
                  const Text(
                    'Sin marcas de hierro o muescas registradas.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ]
              : [
                  if (animal.marcasHierro.ubicacionCuerpo.isNotEmpty)
                    _DataPair(
                      'Ubicación Cuerpo',
                      animal.marcasHierro.ubicacionCuerpo,
                    ),
                  if (animal.marcasHierro.marcasOrejas.isNotEmpty)
                    _DataPair(
                      'Muescas / Orejas',
                      animal.marcasHierro.marcasOrejas,
                    ),
                  if (animal.marcasHierro.colorMarcas.isNotEmpty)
                    _DataPair(
                      'Tipo / Color Marca',
                      animal.marcasHierro.colorMarcas,
                    ),
                  if (animal.marcasHierro.observacionHierro.isNotEmpty)
                    _DataPair(
                      'Observación Hierro',
                      animal.marcasHierro.observacionHierro,
                    ),
                ],
        ),
        const SizedBox(height: 12),

        // 8. ÁRBOL GENEALÓGICO INTERACTIVO
        _DetailBlock(
          title: 'Árbol Genealógico Interactivo',
          icon: Icons.account_tree_outlined,
          children: [
            _ProgenitorTile(
              rol: 'Padre (Toro / Pajuela)',
              icon: Icons.male_rounded,
              progenitorInterno: padreInterno,
              referenciaExterna: gen?.padreExternoReferencia,
              tipoPrueba: gen?.tipoPruebaPaterna ?? 'Sin confirmar',
              toroDonante: gen?.donanteSnapshot != null
                  ? ToroDonanteModel.fromJson(gen!.donanteSnapshot!)
                  : null,
              onTapInterno: padreInterno != null
                  ? () => controller.navegarAProgenitor(padreInterno.id)
                  : null,
            ),
            const SizedBox(height: 10),
            _ProgenitorTile(
              rol: 'Madre (Vaca / Donadora)',
              icon: Icons.female_rounded,
              progenitorInterno: madreInterna,
              referenciaExterna: gen?.madreExternaReferencia,
              tipoPrueba: gen?.tipoPruebaMaterna ?? 'Sin confirmar',
              onTapInterno: madreInterna != null
                  ? () => controller.navegarAProgenitor(madreInterna.id)
                  : null,
            ),
          ],
        ),

        if (animal.observaciones != null &&
            animal.observaciones!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _DetailBlock(
            title: 'Observaciones Generales',
            icon: Icons.notes_rounded,
            children: [
              Text(
                animal.observaciones!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildGaleriaFotos(BuildContext context) {
    if (animal.fotos.isEmpty) {
      return BovineAvatarPlaceholder.animal(
        areteOMote: animal.nombreAlias ?? animal.areteManejo,
        razaODescripcion: animal.razaEtiquetaDisplay,
        sexo: animal.sexo,
        tipoExplotacion: animal.tipoExplotacion,
        height: 140,
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: animal.fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final url = animal.fotos[i];
          return GestureDetector(
            onTap: () => _ampliarFoto(context, url, i, animal.fotos.length),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: animal.fotos.length == 1 ? 300 : 210,
                    height: 165,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${i + 1}/${animal.fotos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailBlock({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
            Row(
              children: [
                Icon(icon, size: 17, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DataPair extends StatelessWidget {
  final String label;
  final String value;

  const _DataPair(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
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

class _ProgenitorTile extends StatelessWidget {
  final String rol;
  final IconData icon;
  final AnimalModel? progenitorInterno;
  final String? referenciaExterna;
  final String tipoPrueba;
  final VoidCallback? onTapInterno;
  final ToroDonanteModel? toroDonante;

  const _ProgenitorTile({
    required this.rol,
    required this.icon,
    this.progenitorInterno,
    this.referenciaExterna,
    required this.tipoPrueba,
    this.onTapInterno,
    this.toroDonante,
  });

  @override
  Widget build(BuildContext context) {
    final tieneInterno = progenitorInterno != null;
    final tieneExterno =
        referenciaExterna != null && referenciaExterna!.trim().isNotEmpty;
    final esIA = toroDonante != null || tipoPrueba == 'Inseminacion';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: tieneInterno
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTapInterno,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rol,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (esIA)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined,
                              size: 11, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            'IA',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tipoPrueba,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (toroDonante != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toroDonante!.nombre,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Pajuela: ${toroDonante!.codigoPajuela}'
                      '${toroDonante!.raza.isNotEmpty ? " · ${toroDonante!.raza}" : ""}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    if (toroDonante!.genealogia.tieneDatos) ...[
                      const SizedBox(height: 4),
                      _AncestrosIA(genealogia: toroDonante!.genealogia),
                    ],
                  ],
                )
              else if (tieneInterno)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arete ${progenitorInterno!.areteManejo}${progenitorInterno!.nombreAlias != null ? ' • "${progenitorInterno!.nombreAlias}"' : ''}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${progenitorInterno!.codigoSistema} • ${progenitorInterno!.razaEtiquetaDisplay}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ],
                )
              else if (tieneExterno)
                Text(
                  'Catálogo / Externo: $referenciaExterna',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                const Text(
                  'Sin progenitor registrado',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget compacto para mostrar los ancestros del toro donante en el expediente

class _AncestrosIA extends StatelessWidget {
  final GenealogiaDonanteModel genealogia;

  const _AncestrosIA({required this.genealogia});

  @override
  Widget build(BuildContext context) {
    final ancestros = <(String, AncestroDonanteModel)>[
      if (genealogia.padre.tieneDatos) ('Padre', genealogia.padre),
      if (genealogia.madre.tieneDatos) ('Madre', genealogia.madre),
      if (genealogia.abueloPaterno.tieneDatos)
        ('Ab. Paterno', genealogia.abueloPaterno),
      if (genealogia.abuelaPaterna.tieneDatos)
        ('Ab. Paterna', genealogia.abuelaPaterna),
      if (genealogia.abueloMaterno.tieneDatos)
        ('Ab. Materno', genealogia.abueloMaterno),
      if (genealogia.abuelaMaterna.tieneDatos)
        ('Ab. Materna', genealogia.abuelaMaterna),
    ];

    if (ancestros.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: ancestros.map((entry) {
        final (label, anc) = entry;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Text(
            '$label: ${anc.nombre}'
            '${anc.codigo.isNotEmpty ? " (${anc.codigo})" : ""}',
            style: const TextStyle(
                fontSize: 10.5, color: Color(0xFF0369A1)),
          ),
        );
      }).toList(),
    );
  }
}
