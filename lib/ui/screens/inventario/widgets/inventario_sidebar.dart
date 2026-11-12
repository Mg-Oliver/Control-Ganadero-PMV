import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/razas_catalog.dart';
import '../../../controllers/inventario_controller.dart';

class InventarioSidebar extends StatefulWidget {
  final InventarioController controller;

  const InventarioSidebar({
    super.key,
    required this.controller,
  });

  @override
  State<InventarioSidebar> createState() => _InventarioSidebarState();
}

class _InventarioSidebarState extends State<InventarioSidebar> {
  final _minHaCtrl = TextEditingController();
  final _maxHaCtrl = TextEditingController();
  final _animalTextoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sincronizarInputsConControlador();
  }

  void _sincronizarInputsConControlador() {
    final c = widget.controller;
    _minHaCtrl.text =
        c.fincaMinHectareas != null ? c.fincaMinHectareas.toString() : '';
    _maxHaCtrl.text =
        c.fincaMaxHectareas != null ? c.fincaMaxHectareas.toString() : '';
    _animalTextoCtrl.text = c.animalBusquedaEspecifica;
  }

  @override
  void dispose() {
    _minHaCtrl.dispose();
    _maxHaCtrl.dispose();
    _animalTextoCtrl.dispose();
    super.dispose();
  }

  void _actualizarRangoHa() {
    final min = double.tryParse(_minHaCtrl.text.trim().replaceAll(',', '.'));
    final max = double.tryParse(_maxHaCtrl.text.trim().replaceAll(',', '.'));
    widget.controller.setFincaRangoHectareas(min: min, max: max);
  }

  void _limpiarTodo() {
    _minHaCtrl.clear();
    _maxHaCtrl.clear();
    _animalTextoCtrl.clear();
    widget.controller.limpiarFiltrosActivos();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return Material(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SELECTOR DE SECCIÓN
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SECCIÓN DEL CATÁLOGO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SeccionNavTile(
                      label: 'Fincas',
                      icon: Icons.landscape_outlined,
                      count: c.allFincas.length,
                      selected: c.seccionActiva == InventarioSeccion.fincas,
                      onTap: () => c.cambiarSeccion(InventarioSeccion.fincas),
                    ),
                    const SizedBox(height: 6),
                    _SeccionNavTile(
                      label: 'Mangas',
                      icon: Icons.grid_view_rounded,
                      count: c.allLotes.length,
                      selected: c.seccionActiva == InventarioSeccion.lotes,
                      onTap: () => c.cambiarSeccion(InventarioSeccion.lotes),
                    ),
                    const SizedBox(height: 6),
                    _SeccionNavTile(
                      label: 'Animales',
                      icon: Icons.pets_outlined,
                      count: c.allAnimales.where((a) => !a.esExterno).length,
                      selected: c.seccionActiva == InventarioSeccion.animales,
                      onTap: () => c.cambiarSeccion(InventarioSeccion.animales),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 2. ACORDEÓN DE FILTROS DINÁMICOS SEGÚN ENTIDAD
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Filtros de ${_tituloSeccion(c.seccionActiva)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (c.seccionActiva == InventarioSeccion.fincas)
                        ..._buildFiltrosFincas(c)
                      else if (c.seccionActiva == InventarioSeccion.lotes)
                        ..._buildFiltrosLotes(c)
                      else
                        ..._buildFiltrosAnimales(c),
                    ],
                  ),
                ),
              ),

              // 3. RESUMEN DE COINCIDENCIAS Y BOTÓN LIMPIAR FILTROS
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Resultados coincidentes:',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${c.totalResultadosCoincidentes}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: c.tieneFiltrosAplicados ? _limpiarTodo : null,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                      label: const Text('Limpiar Filtros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: c.tieneFiltrosAplicados
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _tituloSeccion(InventarioSeccion sec) {
    switch (sec) {
      case InventarioSeccion.fincas:
        return 'Fincas';
      case InventarioSeccion.lotes:
        return 'Mangas';
      case InventarioSeccion.animales:
        return 'Animales';
    }
  }

  List<Widget> _buildFiltrosFincas(InventarioController c) {
    const aguas = [
      ('Quebrada', 'Quebrada'),
      ('Pozo', 'Pozo'),
      ('Rio', 'Río'),
      ('Acueducto rural', 'Acueducto rural'),
    ];

    return [
      _FilterAccordionSection(
        title: 'Estado del Predio',
        initiallyExpanded: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: c.fincaEstado == null,
              onSelected: (_) => c.setFincaEstado(null),
            ),
            ChoiceChip(
              label: const Text('Activa'),
              selected: c.fincaEstado == 'Activa',
              onSelected: (_) => c.setFincaEstado('Activa'),
            ),
            ChoiceChip(
              label: const Text('Inactiva'),
              selected: c.fincaEstado == 'Inactiva',
              onSelected: (_) => c.setFincaEstado('Inactiva'),
            ),
          ],
        ),
      ),
      _FilterAccordionSection(
        title: 'Fuentes de Agua',
        initiallyExpanded: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: aguas.map((item) {
            final selected = c.fincaFuentesAgua.contains(item.$1);
            return FilterChip(
              label: Text(item.$2, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => c.toggleFincaFuenteAgua(item.$1),
            );
          }).toList(),
        ),
      ),
      _FilterAccordionSection(
        title: 'Rango de Hectáreas (ha)',
        initiallyExpanded: true,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minHaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _compactInputDecoration('Mín. ha'),
                onChanged: (_) => _actualizarRangoHa(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxHaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _compactInputDecoration('Máx. ha'),
                onChanged: (_) => _actualizarRangoHa(),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFiltrosLotes(InventarioController c) {
    return [
      _FilterAccordionSection(
        title: 'Finca Madre',
        initiallyExpanded: true,
        child: DropdownButtonFormField<String?>(
          key: ValueKey('lote_finca_${c.loteFincaId}'),
          initialValue: c.loteFincaId,
          isExpanded: true,
          decoration: _compactInputDecoration('Todas las fincas'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas las fincas'),
            ),
            ...c.allFincas.map(
              (f) => DropdownMenuItem<String?>(
                value: f.id,
                child: Text(f.nombre, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: c.setLoteFincaId,
        ),
      ),
      _FilterAccordionSection(
        title: 'Propósito Productivo',
        initiallyExpanded: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: c.loteProposito == null,
              onSelected: (_) => c.setLoteProposito(null),
            ),
            ChoiceChip(
              label: const Text('Lechería'),
              selected: c.loteProposito == 'Lecheria',
              onSelected: (_) => c.setLoteProposito('Lecheria'),
            ),
            ChoiceChip(
              label: const Text('Cría'),
              selected: c.loteProposito == 'Cria',
              onSelected: (_) => c.setLoteProposito('Cria'),
            ),
            ChoiceChip(
              label: const Text('Ceba'),
              selected: c.loteProposito == 'Ceba',
              onSelected: (_) => c.setLoteProposito('Ceba'),
            ),
          ],
        ),
      ),
      _FilterAccordionSection(
        title: 'Estado de la Manga',
        initiallyExpanded: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: c.loteEstado == null,
              onSelected: (_) => c.setLoteEstado(null),
            ),
            ChoiceChip(
              label: const Text('Activo'),
              selected: c.loteEstado == 'Activo',
              onSelected: (_) => c.setLoteEstado('Activo'),
            ),
            ChoiceChip(
              label: const Text('Cerrado'),
              selected: c.loteEstado == 'Cerrado',
              onSelected: (_) => c.setLoteEstado('Cerrado'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFiltrosAnimales(InventarioController c) {

    return [
      _FilterAccordionSection(
        title: 'Identificación Rápida',
        initiallyExpanded: true,
        child: TextField(
          controller: _animalTextoCtrl,
          decoration: _compactInputDecoration(
            'Arete manejo, oficial o alias...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
          ),
          onChanged: c.setAnimalBusquedaEspecifica,
        ),
      ),
      _FilterAccordionSection(
        title: 'Ubicación (Finca)',
        initiallyExpanded: true,
        child: Column(
          children: [
            DropdownButtonFormField<String?>(
              key: ValueKey('anim_finca_${c.animalFincaId}'),
              initialValue: c.animalFincaId,
              isExpanded: true,
              decoration: _compactInputDecoration('Todas las fincas'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las fincas'),
                ),
                ...c.allFincas.map(
                  (f) => DropdownMenuItem<String?>(
                    value: f.id,
                    child: Text(f.nombre, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: c.setAnimalFincaId,
            ),

          ],
        ),
      ),
      _FilterAccordionSection(
        title: 'Sexo y Explotación',
        initiallyExpanded: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Ambos'),
                  selected: c.animalSexo == null,
                  onSelected: (_) => c.setAnimalSexo(null),
                ),
                ChoiceChip(
                  label: const Text('Hembras'),
                  selected: c.animalSexo == 'Hembra',
                  onSelected: (_) => c.setAnimalSexo('Hembra'),
                ),
                ChoiceChip(
                  label: const Text('Machos'),
                  selected: c.animalSexo == 'Macho',
                  onSelected: (_) => c.setAnimalSexo('Macho'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              key: ValueKey('anim_exp_${c.animalTipoExplotacion}'),
              initialValue: c.animalTipoExplotacion,
              isExpanded: true,
              decoration: _compactInputDecoration('Cualquier explotación'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas las explotaciones')),
                DropdownMenuItem(value: 'Lecheria', child: Text('Lechería')),
                DropdownMenuItem(
                  value: 'Doble Proposito',
                  child: Text('Doble Propósito'),
                ),
                DropdownMenuItem(value: 'Cria', child: Text('Cría')),
                DropdownMenuItem(value: 'Ceba', child: Text('Ceba')),
              ],
              onChanged: c.setAnimalTipoExplotacion,
            ),
          ],
        ),
      ),
      _FilterAccordionSection(
        title: 'Estado en el Hato',
        initiallyExpanded: false,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final est in [
              null,
              'Activo',
              'Vendido',
              'Muerto',
              'Descartado',
              'Robado',
            ])
              ChoiceChip(
                label: Text(est ?? 'Todos', style: const TextStyle(fontSize: 12)),
                selected: c.animalEstado == est,
                onSelected: (_) => c.setAnimalEstado(est),
              ),
          ],
        ),
      ),
      _FilterAccordionSection(
        title: 'Composición Genética',
        initiallyExpanded: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: c.animalFiltroGenetico == FiltroGenetico.todos,
                  onSelected: (_) =>
                      c.setAnimalFiltroGenetico(FiltroGenetico.todos),
                ),
                ChoiceChip(
                  label: const Text('Raza Pura'),
                  selected: c.animalFiltroGenetico == FiltroGenetico.razaPura,
                  onSelected: (_) =>
                      c.setAnimalFiltroGenetico(FiltroGenetico.razaPura),
                ),
                ChoiceChip(
                  label: const Text('Cruces / F1'),
                  selected: c.animalFiltroGenetico == FiltroGenetico.cruces,
                  onSelected: (_) =>
                      c.setAnimalFiltroGenetico(FiltroGenetico.cruces),
                ),
              ],
            ),
            if (c.animalFiltroGenetico == FiltroGenetico.razaPura) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                key: ValueKey('anim_raza_${c.animalRazaPuraNombre}'),
                initialValue: c.animalRazaPuraNombre,
                isExpanded: true,
                decoration: _compactInputDecoration('Todas las razas puras'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas las razas puras'),
                  ),
                  ...RazasCatalog.razas.map(
                    (r) => DropdownMenuItem<String?>(
                      value: r.nombre,
                      child: Text(r.nombre, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: c.setAnimalRazaPuraNombre,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  InputDecoration _compactInputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      prefixIcon: prefixIcon,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _SeccionNavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SeccionNavTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textSecondary,
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

class _FilterAccordionSection extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget child;

  const _FilterAccordionSection({
    required this.title,
    this.initiallyExpanded = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [child],
    );
  }
}
