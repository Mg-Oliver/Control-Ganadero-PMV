import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/razas_catalog.dart';
import '../../core/utils/breed_cross_calculator.dart';

class BreedSelectionResult {
  final bool esRazaPura;
  final String? razaPuraNombre;
  final List<Map<String, String>> composicionCruces;
  final String razaEtiquetaDisplay;

  const BreedSelectionResult({
    required this.esRazaPura,
    this.razaPuraNombre,
    this.composicionCruces = const [],
    required this.razaEtiquetaDisplay,
  });

  bool get isValid {
    if (esRazaPura) {
      return razaPuraNombre != null &&
          razaPuraNombre!.trim().isNotEmpty &&
          razaEtiquetaDisplay.trim().isNotEmpty;
    }
    if (composicionCruces.isEmpty) return false;
    final todasCompletas = composicionCruces.every(
      (item) =>
          (item['raza']?.trim().isNotEmpty ?? false) &&
          (item['fraccion']?.trim().isNotEmpty ?? false),
    );
    return todasCompletas && razaEtiquetaDisplay.trim().isNotEmpty;
  }
}

class _CrossRowEntry {
  String? razaNombre;
  String fraccion;

  _CrossRowEntry({this.razaNombre, this.fraccion = '1/2'});
}

class BreedCrossBuilder extends StatefulWidget {
  final BreedSelectionResult initialValue;
  final ValueChanged<BreedSelectionResult> onChanged;

  const BreedCrossBuilder({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<BreedCrossBuilder> createState() => _BreedCrossBuilderState();
}

class _BreedCrossBuilderState extends State<BreedCrossBuilder> {
  late bool _esRazaPura;
  String? _razaPuraNombre;
  final List<_CrossRowEntry> _filasCruces = [];

  @override
  void initState() {
    super.initState();
    _syncFromInitial(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant BreedCrossBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue.razaEtiquetaDisplay.isEmpty &&
        oldWidget.initialValue.razaEtiquetaDisplay.isNotEmpty) {
      _syncFromInitial(widget.initialValue);
    }
  }

  void _syncFromInitial(BreedSelectionResult value) {
    _esRazaPura = value.esRazaPura;
    _razaPuraNombre = value.razaPuraNombre;
    _filasCruces.clear();
    if (value.composicionCruces.isNotEmpty) {
      for (final item in value.composicionCruces) {
        _filasCruces.add(
          _CrossRowEntry(
            razaNombre: item['raza'],
            fraccion: item['fraccion'] ?? '1/2',
          ),
        );
      }
    } else {
      _filasCruces.addAll([
        _CrossRowEntry(razaNombre: 'Holstein', fraccion: '1/2'),
        _CrossRowEntry(razaNombre: 'Gyr Lechero', fraccion: '1/2'),
      ]);
    }
  }

  int _fraccionAOctavos(String fraccion) =>
      BreedCrossCalculator.fraccionAOctavos(fraccion);

  int get _sumaOctavos {
    return _filasCruces.fold<int>(
      0,
      (acc, fila) =>
          acc +
          ((fila.razaNombre != null && fila.razaNombre!.isNotEmpty)
              ? _fraccionAOctavos(fila.fraccion)
              : 0),
    );
  }

  String _generarEtiquetaCruces(List<_CrossRowEntry> validas) {
    return BreedCrossCalculator.generarEtiquetaCruces(
      validas
          .map((f) => {'raza': f.razaNombre ?? '', 'fraccion': f.fraccion})
          .toList(),
    );
  }

  void _emitirCambio() {
    if (_esRazaPura) {
      final nombre = _razaPuraNombre ?? '';
      widget.onChanged(
        BreedSelectionResult(
          esRazaPura: true,
          razaPuraNombre: nombre.isNotEmpty ? nombre : null,
          composicionCruces: const [],
          razaEtiquetaDisplay: nombre,
        ),
      );
    } else {
      final validas = _filasCruces
          .where((f) => f.razaNombre != null && f.razaNombre!.trim().isNotEmpty)
          .toList();
      final composicion = validas
          .map(
            (f) => <String, String>{
              'raza': f.razaNombre!,
              'fraccion': f.fraccion,
            },
          )
          .toList();
      final etiqueta = _generarEtiquetaCruces(validas);

      widget.onChanged(
        BreedSelectionResult(
          esRazaPura: false,
          razaPuraNombre: null,
          composicionCruces: composicion,
          razaEtiquetaDisplay: etiqueta,
        ),
      );
    }
  }

  Future<void> _abrirBuscadorRaza({
    required String? valorActual,
    required ValueChanged<String> onSelected,
  }) async {
    final seleccionada = await showDialog<RazaItem>(
      context: context,
      builder: (_) => _RazaSearchDialog(selectedNombre: valorActual),
    );
    if (seleccionada != null) {
      onSelected(seleccionada.nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiquetaPreview = _esRazaPura
        ? (_razaPuraNombre ?? '')
        : _generarEtiquetaCruces(
            _filasCruces
                .where((f) => f.razaNombre != null && f.razaNombre!.isNotEmpty)
                .toList(),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.biotech_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Composición Genética / Raza (Modo A) *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.verified_outlined, size: 17),
                    label: Text('Raza Pura'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.merge_type_rounded, size: 17),
                    label: Text('Cruce / Mezcla'),
                  ),
                ],
                selected: {_esRazaPura},
                onSelectionChanged: (selection) {
                  setState(() {
                    _esRazaPura = selection.first;
                  });
                  _emitirCambio();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return Colors.white;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return AppColors.textPrimary;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_esRazaPura)
            _buildSelectorRazaPura()
          else
            _buildConstructorCruces(),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: etiquetaPreview.isNotEmpty
                  ? AppColors.primary.withValues(alpha: 0.09)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.label_important_outline,
                  size: 18,
                  color: etiquetaPreview.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Etiqueta Zootécnica: ',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: etiquetaPreview.isNotEmpty
                              ? etiquetaPreview
                              : 'Pendiente de selección',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: etiquetaPreview.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorRazaPura() {
    final razaObj = RazasCatalog.razas
        .where((r) => r.nombre == _razaPuraNombre)
        .firstOrNull;

    return InkWell(
      onTap: () => _abrirBuscadorRaza(
        valorActual: _razaPuraNombre,
        onSelected: (nombre) {
          setState(() => _razaPuraNombre = nombre);
          _emitirCambio();
        },
      ),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Raza Pura del Catálogo Oficial',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        child: razaObj != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      '${razaObj.nombre} • ${razaObj.origen}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      razaObj.aptitudLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              )
            : const Text(
                'Buscar y seleccionar raza pura (Holstein, Brahman, Gyr...)',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }

  Widget _buildConstructorCruces() {
    final octavos = _sumaOctavos;
    final porcentaje = (octavos / 8.0 * 100).round();
    final esExacto = octavos == 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fracciones de Sangre:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: esExacto
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Proporción: $octavos/8 ($porcentaje%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: esExacto ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_filasCruces.length, (index) {
          final fila = _filasCruces[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 105,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('frac_${index}_${fila.fraccion}'),
                    initialValue: fila.fraccion,
                    decoration: InputDecoration(
                      labelText: 'Fracción',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: RazasCatalog.fraccionesZootecnicas
                        .map(
                          (frac) => DropdownMenuItem(
                            value: frac,
                            child: Text(
                              frac,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (nuevaFrac) {
                      if (nuevaFrac != null) {
                        setState(() => fila.fraccion = nuevaFrac);
                        _emitirCambio();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _abrirBuscadorRaza(
                      valorActual: fila.razaNombre,
                      onSelected: (nombre) {
                        setState(() => fila.razaNombre = nombre);
                        _emitirCambio();
                      },
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Raza #${index + 1}',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: const Icon(Icons.search_rounded, size: 19),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        fila.razaNombre ?? 'Seleccionar raza...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: fila.razaNombre != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: fila.razaNombre != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (_filasCruces.length > 1) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Quitar fracción',
                    onPressed: () {
                      setState(() => _filasCruces.removeAt(index));
                      _emitirCambio();
                    },
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _filasCruces.length >= 6
                ? null
                : () {
                    setState(() {
                      _filasCruces.add(_CrossRowEntry(fraccion: '1/4'));
                    });
                    _emitirCambio();
                  },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Añadir Sangre'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _RazaSearchDialog extends StatefulWidget {
  final String? selectedNombre;

  const _RazaSearchDialog({this.selectedNombre});

  @override
  State<_RazaSearchDialog> createState() => _RazaSearchDialogState();
}

class _RazaSearchDialogState extends State<_RazaSearchDialog> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  AptitudProductiva? _filtroAptitud;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = RazasCatalog.razas.where((r) {
      final coincideAptitud =
          _filtroAptitud == null || r.aptitud == _filtroAptitud;
      final q = _query.trim().toLowerCase();
      final coincideTexto =
          q.isEmpty ||
          r.nombre.toLowerCase().contains(q) ||
          r.origen.toLowerCase().contains(q) ||
          r.aptitudLabel.toLowerCase().contains(q);
      return coincideAptitud && coincideTexto;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Catálogo Zootécnico de Razas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar raza por nombre u origen...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: _filtroAptitud == null,
                      onSelected: (_) => setState(() => _filtroAptitud = null),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Leche'),
                      selected: _filtroAptitud == AptitudProductiva.leche,
                      onSelected: (_) => setState(
                        () => _filtroAptitud = AptitudProductiva.leche,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Carne'),
                      selected: _filtroAptitud == AptitudProductiva.carne,
                      onSelected: (_) => setState(
                        () => _filtroAptitud = AptitudProductiva.carne,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Doble Propósito'),
                      selected:
                          _filtroAptitud == AptitudProductiva.dobleProposito,
                      onSelected: (_) => setState(
                        () => _filtroAptitud = AptitudProductiva.dobleProposito,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Criollas'),
                      selected: _filtroAptitud == AptitudProductiva.criolla,
                      onSelected: (_) => setState(
                        () => _filtroAptitud = AptitudProductiva.criolla,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 18),
              Expanded(
                child: filtradas.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron razas con ese criterio.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtradas.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final raza = filtradas[i];
                          final selected = raza.nombre == widget.selectedNombre;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: AppColors.primary.withValues(
                              alpha: 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(
                              raza.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              raza.origen,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                raza.aptitudLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            onTap: () => Navigator.pop(context, raza),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
