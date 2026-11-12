import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/finca_model.dart';
import '../../../../data/services/fincas_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../common/custom_form_dropdown.dart';
import '../../../common/custom_text_field.dart';
import '../../../common/photo_uploader_widget.dart';

class FincaForm extends StatefulWidget {
  final ValueChanged<FincaModel>? onFincaCreated;

  const FincaForm({
    super.key,
    this.onFincaCreated,
  });

  @override
  State<FincaForm> createState() => _FincaFormState();
}

class _FincaFormState extends State<FincaForm> {
  final _formKey = GlobalKey<FormState>();
  final _fincasService = FincasService();
  final _storageService = StorageService();

  final _identificadorCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  final _identificadorFocus = FocusNode();
  final _nombreFocus = FocusNode();
  final _ubicacionFocus = FocusNode();
  final _superficieFocus = FocusNode();
  final _observacionesFocus = FocusNode();

  String _estado = 'Activa';
  final Set<String> _fuentesAguaSeleccionadas = {};
  final List<SelectedPhoto> _fotos = [];

  bool _isSaving = false;
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;

  static const List<({String dbValue, String label, IconData icon})>
      _opcionesFuentesAgua = [
    (dbValue: 'Quebrada', label: 'Quebrada', icon: Icons.water_outlined),
    (dbValue: 'Pozo', label: 'Pozo profundo', icon: Icons.opacity),
    (dbValue: 'Rio', label: 'Río', icon: Icons.waves_outlined),
    (
      dbValue: 'Acueducto rural',
      label: 'Acueducto rural',
      icon: Icons.plumbing_outlined
    ),
  ];

  @override
  void dispose() {
    _identificadorCtrl.dispose();
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _superficieCtrl.dispose();
    _observacionesCtrl.dispose();

    _identificadorFocus.dispose();
    _nombreFocus.dispose();
    _ubicacionFocus.dispose();
    _superficieFocus.dispose();
    _observacionesFocus.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _identificadorCtrl.clear();
    _nombreCtrl.clear();
    _ubicacionCtrl.clear();
    _superficieCtrl.clear();
    _observacionesCtrl.clear();
    setState(() {
      _estado = 'Activa';
      _fuentesAguaSeleccionadas.clear();
      _fotos.clear();
      _uploadProgress = 0.0;
      _uploadStatus = null;
    });
  }

  Future<void> _guardarFinca() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
      _uploadStatus = null;
    });

    try {
      final identificador = _identificadorCtrl.text.trim();
      final yaExiste = await _fincasService.existeIdentificador(identificador);
      if (yaExiste) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El identificador "$identificador" ya está registrado en otra finca.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final fincaId = const Uuid().v4();
      List<String> urlsFotos = [];

      if (_fotos.isNotEmpty) {
        setState(() {
          _isUploadingPhotos = true;
          _uploadStatus = 'Subiendo foto 1 de ${_fotos.length}...';
        });

        urlsFotos = await _storageService.uploadMultiplePhotos(
          bucket: 'fincas_fotos',
          entityId: fincaId,
          files: _fotos
              .map((f) => (bytes: f.bytes, extension: f.extension))
              .toList(),
          onProgress: (completed, total) {
            if (mounted) {
              setState(() {
                _uploadProgress = completed / total;
                _uploadStatus = completed < total
                    ? 'Subiendo foto ${completed + 1} de $total...'
                    : 'Fotografías cargadas ($completed/$total)';
              });
            }
          },
        );
      }

      final superficieTexto = _superficieCtrl.text.trim().replaceAll(',', '.');
      final superficie = superficieTexto.isNotEmpty
          ? double.tryParse(superficieTexto)
          : null;

      final nuevaFinca = FincaModel(
        id: fincaId,
        identificador: identificador,
        nombre: _nombreCtrl.text.trim(),
        ubicacion: _ubicacionCtrl.text.trim().isNotEmpty
            ? _ubicacionCtrl.text.trim()
            : null,
        superficieHectareas: superficie,
        estado: _estado,
        fuentesAgua: _fuentesAguaSeleccionadas.toList(),
        observaciones: _observacionesCtrl.text.trim().isNotEmpty
            ? _observacionesCtrl.text.trim()
            : null,
        fotos: urlsFotos,
      );

      final fincaCreada = await _fincasService.crear(nuevaFinca);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Finca "${fincaCreada.nombre}" (${fincaCreada.identificador}) creada exitosamente.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      _limpiarFormulario();
      widget.onFincaCreated?.call(fincaCreada);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la finca: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingPhotos = false;
        });
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
                  'Datos Generales del Predio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
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
                CustomTextField(
                  label: 'Ubicación / Dirección / Vereda',
                  hint: 'Ej. Km 12 Vía San Pedro, Vereda El Roble',
                  controller: _ubicacionCtrl,
                  focusNode: _ubicacionFocus,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 620;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSuperficieField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildEstadoDropdown()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildSuperficieField(),
                        const SizedBox(height: 14),
                        _buildEstadoDropdown(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Fuentes de Agua Disponibles',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _opcionesFuentesAgua.map((opcion) {
                    final selected =
                        _fuentesAguaSeleccionadas.contains(opcion.dbValue);
                    return FilterChip(
                      selected: selected,
                      label: Text(opcion.label),
                      avatar: Icon(
                        opcion.icon,
                        size: 17,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFFF3F4F6),
                      onSelected: _isSaving
                          ? null
                          : (val) {
                              setState(() {
                                if (val) {
                                  _fuentesAguaSeleccionadas.add(opcion.dbValue);
                                } else {
                                  _fuentesAguaSeleccionadas
                                      .remove(opcion.dbValue);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Observaciones',
                  hint:
                      'Topografía, tipo de pasturas predominantes, infraestructura de corrales...',
                  controller: _observacionesCtrl,
                  focusNode: _observacionesFocus,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                PhotoUploaderWidget(
                  label: 'Fotografías del Predio (Máx. 3)',
                  photos: _fotos,
                  maxPhotos: 3,
                  isUploading: _isUploadingPhotos,
                  uploadProgress: _uploadProgress,
                  uploadStatusText: _uploadStatus,
                  onPhotoAdded: (photo) {
                    if (_fotos.length < 3) {
                      setState(() => _fotos.add(photo));
                    }
                  },
                  onPhotoRemoved: (index) {
                    setState(() => _fotos.removeAt(index));
                  },
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
                        onPressed: _isSaving ? null : _guardarFinca,
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
                          _isSaving ? 'Guardando Finca...' : 'Guardar Finca',
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
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.landscape_outlined),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro de Nueva Finca / Predio Ganadero',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Registra la unidad productiva base para asociar mangas de manejo e inventario animal.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificadorField() {
    return CustomTextField(
      label: 'Identificador de Finca',
      hint: 'Ej. FNC-001',
      controller: _identificadorCtrl,
      focusNode: _identificadorFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.tag_rounded, size: 20),
      validator: (v) =>
          Validators.requerido(v, 'Ingrese un identificador único'),
    );
  }

  Widget _buildNombreField() {
    return CustomTextField(
      label: 'Nombre de la Finca',
      hint: 'Ej. Hacienda La Esperanza',
      controller: _nombreCtrl,
      focusNode: _nombreFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.home_work_outlined, size: 20),
      validator: (v) => Validators.requerido(v, 'Ingrese el nombre de la finca'),
    );
  }

  Widget _buildSuperficieField() {
    return CustomTextField.numeric(
      label: 'Superficie en Hectáreas',
      hint: 'Ej. 125.50',
      suffixText: 'ha',
      controller: _superficieCtrl,
      focusNode: _superficieFocus,
      prefixIcon: const Icon(Icons.square_foot_outlined, size: 20),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final numVal = double.tryParse(val.replaceAll(',', '.'));
        if (numVal == null || numVal <= 0) {
          return 'Ingrese una superficie mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildEstadoDropdown() {
    return CustomFormDropdown<String>(
      label: 'Estado Operativo',
      value: _estado,
      isRequired: true,
      prefixIcon: const Icon(Icons.verified_outlined, size: 20),
      items: const [
        DropdownMenuItem(value: 'Activa', child: Text('Activa')),
        DropdownMenuItem(value: 'Inactiva', child: Text('Inactiva')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _estado = val);
      },
    );
  }
}
