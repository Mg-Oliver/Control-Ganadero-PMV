import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/categoria_rules_service.dart';
import '../../../core/utils/categoria_rules_validator.dart';
import '../../../data/models/categoria_rule_model.dart';
import '../../controllers/inventario_controller.dart';

class ConfiguracionCategoriasScreen extends StatefulWidget {
  final InventarioController? inventarioController;

  const ConfiguracionCategoriasScreen({super.key, this.inventarioController});

  @override
  State<ConfiguracionCategoriasScreen> createState() =>
      _ConfiguracionCategoriasScreenState();
}

class _ConfiguracionCategoriasScreenState
    extends State<ConfiguracionCategoriasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<CategoriaRuleModel> _reglas;
  bool _guardando = false;

  static const _tabs = [
    'General',
    'Cría',
    'Ceba',
    'Lechería',
    'Doble Propósito',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _reglas = List<CategoriaRuleModel>.from(
      CategoriaRulesService.instance.reglas,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _tipoExplotacionDelTab(int index) {
    if (index == 0) return null;
    return _tabs[index];
  }

  List<CategoriaRuleModel> _reglasDeLaTab(int index) {
    final tipo = _tipoExplotacionDelTab(index);
    return _reglas
        .where((r) => r.tipoExplotacion == tipo)
        .toList();
  }

  Future<void> _aplicarYGuardar(List<CategoriaRuleModel> nuevas) async {
    final err = CategoriaRulesValidator.validarTraslapes(nuevas);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _reglas = nuevas;
      _guardando = true;
    });

    final svc = CategoriaRulesService(nuevas);
    CategoriaRulesService.updateInstance(svc);
    widget.inventarioController?.actualizarCategorias();
    await svc.guardarPreferencias();

    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _confirmarRestaurarDefectos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar valores de fábrica'),
        content: const Text(
          'Se eliminarán todas las categorías personalizadas y se restaurarán '
          'las categorías predeterminadas del sistema. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _aplicarYGuardar(
        List<CategoriaRuleModel>.from(CategoriaRulesService.reglasDefault),
      );
    }
  }

  Future<void> _abrirDialogoEditar(
    CategoriaRuleModel regla,
    int indexGlobal,
  ) async {
    final resultado = await showDialog<CategoriaRuleModel>(
      context: context,
      builder: (ctx) => _ReglaDialog(
        regla: regla,
        tipoExplotacion: regla.tipoExplotacion,
        reglasExistentes: _reglas,
        indiceEdicion: indexGlobal,
      ),
    );
    if (resultado != null) {
      final nuevas = List<CategoriaRuleModel>.from(_reglas);
      nuevas[indexGlobal] = resultado;
      await _aplicarYGuardar(nuevas);
    }
  }

  Future<void> _abrirDialogoAgregar(int tabIndex) async {
    final resultado = await showDialog<CategoriaRuleModel>(
      context: context,
      builder: (ctx) => _ReglaDialog(
        regla: null,
        tipoExplotacion: _tipoExplotacionDelTab(tabIndex),
        reglasExistentes: _reglas,
        indiceEdicion: null,
      ),
    );
    if (resultado != null) {
      final nuevas = List<CategoriaRuleModel>.from(_reglas)..add(resultado);
      await _aplicarYGuardar(nuevas);
    }
  }

  Future<void> _eliminar(int indexGlobal) async {
    final regla = _reglas[indexGlobal];
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar la categoría "${regla.categoria}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      final nuevas = List<CategoriaRuleModel>.from(_reglas)
        ..removeAt(indexGlobal);
      await _aplicarYGuardar(nuevas);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Categorías Zootécnicas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Restaurar valores de fábrica',
              icon: const Icon(Icons.restore_rounded),
              onPressed: _confirmarRestaurarDefectos,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _tabs.length,
          (i) => _TabContent(
            tabIndex: i,
            reglasDeLaTab: _reglasDeLaTab(i),
            todasLasReglas: _reglas,
            onEditar: (regla) {
              final idx = _reglas.indexOf(regla);
              if (idx != -1) _abrirDialogoEditar(regla, idx);
            },
            onEliminar: (regla) {
              final idx = _reglas.indexOf(regla);
              if (idx != -1) _eliminar(idx);
            },
            onAgregar: () => _abrirDialogoAgregar(i),
          ),
        ),
      ),
    );
  }
}

// ─── Vista de una pestaña ────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final int tabIndex;
  final List<CategoriaRuleModel> reglasDeLaTab;
  final List<CategoriaRuleModel> todasLasReglas;
  final void Function(CategoriaRuleModel) onEditar;
  final void Function(CategoriaRuleModel) onEliminar;
  final VoidCallback onAgregar;

  const _TabContent({
    required this.tabIndex,
    required this.reglasDeLaTab,
    required this.todasLasReglas,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final machos = reglasDeLaTab
        .where((r) => r.sexo == 'Macho' || r.sexo == 'Ambos')
        .toList();
    final hembras = reglasDeLaTab
        .where((r) => r.sexo == 'Hembra' || r.sexo == 'Ambos')
        .toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GrupoSexo(
                titulo: 'Machos',
                icono: Icons.male_rounded,
                reglas: machos,
                onEditar: onEditar,
                onEliminar: onEliminar,
              ),
              const SizedBox(height: 20),
              _GrupoSexo(
                titulo: 'Hembras',
                icono: Icons.female_rounded,
                reglas: hembras,
                onEditar: onEditar,
                onEliminar: onEliminar,
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'fab_tab_$tabIndex',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: onAgregar,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar categoría'),
          ),
        ),
      ],
    );
  }
}

class _GrupoSexo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<CategoriaRuleModel> reglas;
  final void Function(CategoriaRuleModel) onEditar;
  final void Function(CategoriaRuleModel) onEliminar;

  const _GrupoSexo({
    required this.titulo,
    required this.icono,
    required this.reglas,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${reglas.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reglas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Sin categorías definidas para $titulo.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...reglas.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReglaCard(
                regla: r,
                onEditar: () => onEditar(r),
                onEliminar: () => onEliminar(r),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReglaCard extends StatelessWidget {
  final CategoriaRuleModel regla;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ReglaCard({
    required this.regla,
    required this.onEditar,
    required this.onEliminar,
  });

  String _etiquetaRango() {
    if (regla.requiereParto) return 'Con ≥ 1 parto';
    final max = regla.edadMaximoMeses;
    if (max == -1) return '${regla.edadMinimoMeses}+ meses';
    return '${regla.edadMinimoMeses} – $max meses';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.label_outline_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  regla.categoria,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Chip(label: _etiquetaRango(), color: AppColors.primary),
                    _Chip(
                      label: regla.sexo,
                      color: regla.sexo == 'Macho'
                          ? const Color(0xFF0369A1)
                          : const Color(0xFF9D174D),
                    ),
                    if (regla.requiereParto)
                      _Chip(
                        label: 'Requiere parto',
                        color: const Color(0xFF047857),
                      ),
                    if (regla.tipoExplotacion != null)
                      _Chip(
                        label: regla.tipoExplotacion!,
                        color: AppColors.secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined,
                size: 19, color: AppColors.primary),
            onPressed: onEditar,
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline_rounded,
                size: 19, color: AppColors.error),
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Diálogo editar / crear regla ────────────────────────────────────────────

class _ReglaDialog extends StatefulWidget {
  final CategoriaRuleModel? regla; // null = nueva
  final String? tipoExplotacion;
  final List<CategoriaRuleModel> reglasExistentes;
  final int? indiceEdicion;

  const _ReglaDialog({
    required this.regla,
    required this.tipoExplotacion,
    required this.reglasExistentes,
    required this.indiceEdicion,
  });

  @override
  State<_ReglaDialog> createState() => _ReglaDialogState();
}

class _ReglaDialogState extends State<_ReglaDialog> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late String _sexo;
  late bool _requiereParto;
  late bool _sinLimiteMax;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.regla;
    _nombreCtrl = TextEditingController(text: r?.categoria ?? '');
    _minCtrl =
        TextEditingController(text: '${r?.edadMinimoMeses ?? 0}');
    _sinLimiteMax = r == null ? false : (r.edadMaximoMeses == -1);
    _maxCtrl = TextEditingController(
      text: _sinLimiteMax ? '' : '${r?.edadMaximoMeses ?? 12}',
    );
    _sexo = r?.sexo ?? 'Macho';
    _requiereParto = r?.requiereParto ?? false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    final min = int.tryParse(_minCtrl.text.trim()) ?? -1;
    final max = _sinLimiteMax ? -1 : (int.tryParse(_maxCtrl.text.trim()) ?? -1);

    // Validaciones básicas
    final errNombre = CategoriaRulesValidator.validarNombre(nombre);
    if (errNombre != null) {
      setState(() => _error = errNombre);
      return;
    }
    final errRango = CategoriaRulesValidator.validarRango(min, max);
    if (errRango != null) {
      setState(() => _error = errRango);
      return;
    }

    // Construye la nueva regla
    final nueva = CategoriaRuleModel(
      sexo: _sexo,
      edadMinimoMeses: min,
      edadMaximoMeses: max,
      requiereParto: _requiereParto,
      tipoExplotacion: widget.tipoExplotacion,
      categoria: nombre,
    );

    // Verifica traslapes con el resto de las reglas
    final simulada = List<CategoriaRuleModel>.from(widget.reglasExistentes);
    if (widget.indiceEdicion != null) {
      simulada[widget.indiceEdicion!] = nueva;
    } else {
      simulada.add(nueva);
    }
    final errTraslape = CategoriaRulesValidator.validarTraslapes(simulada);
    if (errTraslape != null) {
      setState(() => _error = errTraslape);
      return;
    }

    Navigator.of(context).pop(nueva);
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = widget.regla == null;
    return AlertDialog(
      title: Text(esNueva ? 'Nueva categoría' : 'Editar categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ej. Becerra, Torete…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            // Sexo
            if (esNueva) ...[
              const Text(
                'Sexo aplicable',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Macho', label: Text('Macho')),
                  ButtonSegment(value: 'Hembra', label: Text('Hembra')),
                  ButtonSegment(value: 'Ambos', label: Text('Ambos')),
                ],
                selected: {_sexo},
                onSelectionChanged: (s) =>
                    setState(() => _sexo = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Parto toggle
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Requiere parto',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Se activa cuando el animal tiene ≥ 1 parto registrado.',
                style: TextStyle(fontSize: 11.5),
              ),
              value: _requiereParto,
              onChanged: (v) => setState(() {
                _requiereParto = v;
                if (v) {
                  _minCtrl.text = '0';
                  _sinLimiteMax = true;
                }
              }),
              activeTrackColor: AppColors.primary,
            ),
            if (!_requiereParto) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Edad mín. (meses)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxCtrl,
                      enabled: !_sinLimiteMax,
                      decoration: const InputDecoration(
                        labelText: 'Edad máx. (meses)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Sin límite de edad máxima',
                  style: TextStyle(fontSize: 12.5),
                ),
                value: _sinLimiteMax,
                onChanged: (v) => setState(() {
                  _sinLimiteMax = v ?? false;
                  if (_sinLimiteMax) _maxCtrl.clear();
                }),
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : null,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(esNueva ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}
