import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/finca_model.dart';
import '../../../../data/models/lote_model.dart';
import '../../../../data/services/lotes_service.dart';
import '../../../common/custom_form_dropdown.dart';
import '../../../common/custom_text_field.dart';

class LoteForm extends StatefulWidget {
  final List<FincaModel> fincas;
  final bool isLoadingFincas;
  final String? preselectedFincaId;
  final FincaModel? newlyCreatedFinca;
  final VoidCallback? onRequestCreateFinca;
  final VoidCallback? onRefreshFincas;
  final ValueChanged<LoteModel>? onLoteCreated;

  const LoteForm({
    super.key,
    required this.fincas,
    this.isLoadingFincas = false,
    this.preselectedFincaId,
    this.newlyCreatedFinca,
    this.onRequestCreateFinca,
    this.onRefreshFincas,
    this.onLoteCreated,
  });

  @override
  State<LoteForm> createState() => _LoteFormState();
}

class _LoteFormState extends State<LoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _lotesService = LotesService();

  final _identificadorCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _metaGananciaCtrl = TextEditingController(text: '0.750');
  final _dietaCtrl = TextEditingController();

  final _identificadorFocus = FocusNode();
  final _nombreFocus = FocusNode();
  final _metaGananciaFocus = FocusNode();
  final _dietaFocus = FocusNode();

  String? _selectedFincaId;
  String? _propositoProductivo = 'Lecheria';
  String _estado = 'Activo';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFincaId = widget.preselectedFincaId ??
        (widget.fincas.isNotEmpty ? widget.fincas.first.id : null);
  }

  @override
  void didUpdateWidget(covariant LoteForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preselectedFincaId != null &&
        widget.preselectedFincaId != oldWidget.preselectedFincaId) {
      setState(() {
        _selectedFincaId = widget.preselectedFincaId;
      });
    } else if (widget.newlyCreatedFinca != null &&
        widget.newlyCreatedFinca?.id != oldWidget.newlyCreatedFinca?.id) {
      setState(() {
        _selectedFincaId = widget.newlyCreatedFinca!.id;
      });
    } else if (_selectedFincaId == null && widget.fincas.isNotEmpty) {
      setState(() {
        _selectedFincaId = widget.fincas.first.id;
      });
    }
  }

  @override
  void dispose() {
    _identificadorCtrl.dispose();
    _nombreCtrl.dispose();
    _metaGananciaCtrl.dispose();
    _dietaCtrl.dispose();

    _identificadorFocus.dispose();
    _nombreFocus.dispose();
    _metaGananciaFocus.dispose();
    _dietaFocus.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _identificadorCtrl.clear();
    _nombreCtrl.clear();
    _metaGananciaCtrl.text = '0.750';
    _dietaCtrl.clear();
    setState(() {
      _propositoProductivo = 'Lecheria';
      _estado = 'Activo';
    });
  }

  Future<void> _guardarLote() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFincaId == null || _selectedFincaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar obligatoriamente una finca perteneciente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final identificador = _identificadorCtrl.text.trim();
      final duplicado = await _lotesService.existeIdentificadorEnFinca(
        fincaId: _selectedFincaId!,
        identificador: identificador,
      );

      if (duplicado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ya existe un lote con el identificador "$identificador" en la finca seleccionada.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final metaTexto = _metaGananciaCtrl.text.trim().replaceAll(',', '.');
      final metaGanancia =
          metaTexto.isNotEmpty ? (double.tryParse(metaTexto) ?? 0.0) : 0.0;

      final nuevoLote = LoteModel(
        id: '',
        fincaId: _selectedFincaId!,
        identificador: identificador,
        nombre: _nombreCtrl.text.trim(),
        propositoProductivo: _propositoProductivo!,
        metaGananciaPesoDiaria: metaGanancia,
        dietaAsignada:
            _dietaCtrl.text.trim().isNotEmpty ? _dietaCtrl.text.trim() : null,
        estado: _estado,
      );

      final loteCreado = await _lotesService.crear(nuevoLote);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lote "${loteCreado.nombre}" (${loteCreado.identificador}) registrado correctamente.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      _limpiarFormulario();
      widget.onLoteCreated?.call(loteCreado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar el lote: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          if (!widget.isLoadingFincas && widget.fincas.isEmpty)
            _buildEmptyFincasAlert(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración del Lote de Manejo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomFormDropdown<String>(
                  label: 'Finca Perteneciente',
                  isRequired: true,
                  isLoading: widget.isLoadingFincas,
                  value: _selectedFincaId,
                  hint: 'Seleccione la finca a la que pertenece el lote',
                  prefixIcon: const Icon(Icons.landscape_outlined, size: 20),
                  headerTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onRefreshFincas != null)
                        IconButton(
                          tooltip: 'Recargar fincas',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onRefreshFincas,
                          icon: const Icon(
                            Icons.sync_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (widget.onRequestCreateFinca != null)
                        TextButton.icon(
                          onPressed: widget.onRequestCreateFinca,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Nueva Finca'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  items: widget.fincas
                      .map(
                        (finca) => DropdownMenuItem<String>(
                          value: finca.id,
                          child: Text(
                            '${finca.nombre} (${finca.identificador})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Todo lote debe pertenecer obligatoriamente a una finca'
                      : null,
                  onChanged: (val) {
                    setState(() => _selectedFincaId = val);
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 620;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildIdentificadorField()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildNombreField()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildIdentificadorField(),
                        const SizedBox(height: 14),
                        _buildNombreField(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 620;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPropositoDropdown()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMetaGananciaField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildEstadoDropdown()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildPropositoDropdown(),
                        const SizedBox(height: 14),
                        _buildMetaGananciaField(),
                        const SizedBox(height: 14),
                        _buildEstadoDropdown(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Dieta Asignada / Suplementación',
                  hint:
                      'Ej. Pastoreo rotacional Kikuyo + 2 kg concentrado lechero 18% PC + sal mineralizada 8%',
                  controller: _dietaCtrl,
                  focusNode: _dietaFocus,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _limpiarFormulario,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Limpiar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _guardarLote,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 19),
                        label: Text(
                          _isSaving ? 'Guardando Lote...' : 'Guardar Lote',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            child: Icon(Icons.grid_view_rounded),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creación de Lote de Manejo Productivo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Agrupa animales por propósito zootécnico, dieta nutricional y metas de ganancia diaria (GDP).',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFincasAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Aún no hay fincas registradas. Crea primero una finca para poder asociar este lote.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          if (widget.onRequestCreateFinca != null)
            FilledButton.tonal(
              onPressed: widget.onRequestCreateFinca,
              child: const Text('+ Crear Finca'),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentificadorField() {
    return CustomTextField(
      label: 'Identificador de Lote',
      hint: 'Ej. LOT-LECH-01',
      controller: _identificadorCtrl,
      focusNode: _identificadorFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
      validator: (v) =>
          Validators.requerido(v, 'Ingrese el identificador del lote'),
    );
  }

  Widget _buildNombreField() {
    return CustomTextField(
      label: 'Nombre del Lote',
      hint: 'Ej. Lote Alta Producción Ordeño 1',
      controller: _nombreCtrl,
      focusNode: _nombreFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.bookmarks_outlined, size: 20),
      validator: (v) => Validators.requerido(v, 'Ingrese el nombre del lote'),
    );
  }

  Widget _buildPropositoDropdown() {
    return CustomFormDropdown<String>(
      label: 'Propósito Productivo',
      value: _propositoProductivo,
      isRequired: true,
      prefixIcon: const Icon(Icons.track_changes_outlined, size: 20),
      items: const [
        DropdownMenuItem(value: 'Lecheria', child: Text('Lechería')),
        DropdownMenuItem(value: 'Cria', child: Text('Cría')),
        DropdownMenuItem(value: 'Ceba', child: Text('Ceba')),
      ],
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Seleccione el propósito' : null,
      onChanged: (val) => setState(() => _propositoProductivo = val),
    );
  }

  Widget _buildMetaGananciaField() {
    return CustomTextField.numeric(
      label: 'Meta Ganancia Diaria (GDP)',
      hint: '0.750',
      suffixText: 'kg/día',
      controller: _metaGananciaCtrl,
      focusNode: _metaGananciaFocus,
      prefixIcon: const Icon(Icons.trending_up_rounded, size: 20),
      validator: (val) => Validators.numeroPositivo(
        val,
        'Ingrese un valor numérico >= 0',
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return CustomFormDropdown<String>(
      label: 'Estado del Lote',
      value: _estado,
      isRequired: true,
      prefixIcon: const Icon(Icons.toggle_on_outlined, size: 20),
      items: const [
        DropdownMenuItem(value: 'Activo', child: Text('Activo')),
        DropdownMenuItem(value: 'Cerrado', child: Text('Cerrado')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _estado = val);
      },
    );
  }
}

