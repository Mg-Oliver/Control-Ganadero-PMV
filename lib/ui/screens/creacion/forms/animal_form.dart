import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/genealogia_validator.dart';
import '../../../../core/utils/predio_consistency_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/animal_model.dart';
import '../../../../data/models/finca_model.dart';
import '../../../../data/models/genealogia_model.dart';
import '../../../../data/models/lote_model.dart';
import '../../../../data/services/animales_service.dart';
import '../../../../data/services/lotes_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../common/breed_cross_builder.dart';
import '../../../common/custom_form_dropdown.dart';
import '../../../common/custom_text_field.dart';
import '../../../common/photo_uploader_widget.dart';

class AnimalForm extends StatefulWidget {
  final List<FincaModel> fincas;
  final bool isLoadingFincas;
  final FincaModel? newlyCreatedFinca;
  final LoteModel? newlyCreatedLote;
  final VoidCallback? onRefreshFincas;
  final VoidCallback? onRequestCreateFinca;
  final ValueChanged<String?>? onRequestCreateLote;
  final ValueChanged<AnimalModel>? onAnimalCreated;

  const AnimalForm({
    super.key,
    required this.fincas,
    this.isLoadingFincas = false,
    this.newlyCreatedFinca,
    this.newlyCreatedLote,
    this.onRefreshFincas,
    this.onRequestCreateFinca,
    this.onRequestCreateLote,
    this.onAnimalCreated,
  });

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  final _formKey = GlobalKey<FormState>();
  final _lotesService = LotesService();
  final _animalesService = AnimalesService();
  final _storageService = StorageService();

  // Identificación y biometría
  final _areteManejoCtrl = TextEditingController();
  final _areteOficialCtrl = TextEditingController();
  final _nombreAliasCtrl = TextEditingController();
  final _pesoActualCtrl = TextEditingController();

  final _areteManejoFocus = FocusNode();
  final _areteOficialFocus = FocusNode();
  final _nombreAliasFocus = FocusNode();
  final _pesoActualFocus = FocusNode();

  // Origen y compra
  final _origenOtroCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _origenOtroFocus = FocusNode();
  final _precioCompraFocus = FocusNode();

  // Ubicación y baja
  final _potreroCtrl = TextEditingController();
  final _potreroFocus = FocusNode();
  final _precioVentaCtrl = TextEditingController();
  final _precioVentaFocus = FocusNode();
  DateTime _fechaSalida = DateTime.now();

  // Marcas de hierro
  final _hierroUbicacionCtrl = TextEditingController();
  final _hierroOrejasCtrl = TextEditingController();
  final _hierroColorCtrl = TextEditingController();
  final _hierroObsCtrl = TextEditingController();

  final _hierroUbicacionFocus = FocusNode();
  final _hierroOrejasFocus = FocusNode();
  final _hierroColorFocus = FocusNode();
  final _hierroObsFocus = FocusNode();

  // Genealogía externa
  final _padreExternoCtrl = TextEditingController();
  final _madreExternaCtrl = TextEditingController();
  final _padreExternoFocus = FocusNode();
  final _madreExternaFocus = FocusNode();

  // Observaciones generales
  final _observacionesCtrl = TextEditingController();
  final _observacionesFocus = FocusNode();

  // Estados reactivos del formulario
  String _sexo = 'Hembra';
  String _tipoExplotacion = 'Lecheria';
  DateTime _fechaNacimiento = DateTime.now().subtract(const Duration(days: 180));
  bool _fechaNacimientoExacta = true;

  String _origen = 'Nacido en la finca';
  String? _selectedFincaId;
  String? _selectedLoteId;
  String _estadoActual = 'Activo';
  bool get _esDeBaja => PredioConsistencyHelper.esEstadoDeBaja(_estadoActual);
  DateTime _fechaEntrada = DateTime.now();

  BreedSelectionResult _breedSelection = const BreedSelectionResult(
    esRazaPura: true,
    razaPuraNombre: null,
    composicionCruces: [],
    razaEtiquetaDisplay: '',
  );
  String? _breedErrorText;

  // Datos en cascada por Finca
  List<LoteModel> _lotesDeFinca = [];
  List<AnimalModel> _animalesDeFinca = [];
  bool _loadingCascada = false;

  // Genealogía Padre y Madre
  bool _padreEsInterno = true;
  AnimalModel? _padreSeleccionado;
  String _tipoPruebaPaterna = 'Sin confirmar';

  bool _madreEsInterna = true;
  AnimalModel? _madreSeleccionada;
  String _tipoPruebaMaterna = 'Sin confirmar';

  // Fotos y progreso
  final List<SelectedPhoto> _fotos = [];
  bool _isSaving = false;
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    if (widget.fincas.isNotEmpty) {
      _selectedFincaId = widget.fincas.first.id;
      _cargarDatosEnCascada(_selectedFincaId!);
    }
  }

  @override
  void didUpdateWidget(covariant AnimalForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.newlyCreatedFinca != null &&
        widget.newlyCreatedFinca?.id != oldWidget.newlyCreatedFinca?.id) {
      final nuevaFincaId = widget.newlyCreatedFinca!.id;
      setState(() {
        _selectedFincaId = nuevaFincaId;
        _selectedLoteId = null;
        _padreSeleccionado = null;
        _madreSeleccionada = null;
      });
      _cargarDatosEnCascada(nuevaFincaId);
      return;
    }

    if (widget.newlyCreatedLote != null &&
        widget.newlyCreatedLote?.id != oldWidget.newlyCreatedLote?.id) {
      final nuevoLote = widget.newlyCreatedLote!;
      if (nuevoLote.fincaId == _selectedFincaId) {
        _cargarDatosEnCascada(
          nuevoLote.fincaId,
          preselectLoteId: nuevoLote.id,
        );
      } else {
        setState(() {
          _selectedFincaId = nuevoLote.fincaId;
          _padreSeleccionado = null;
          _madreSeleccionada = null;
        });
        _cargarDatosEnCascada(
          nuevoLote.fincaId,
          preselectLoteId: nuevoLote.id,
        );
      }
      return;
    }

    if (_selectedFincaId == null && widget.fincas.isNotEmpty) {
      _selectedFincaId = widget.fincas.first.id;
      _cargarDatosEnCascada(_selectedFincaId!);
    }
  }

  @override
  void dispose() {
    _areteManejoCtrl.dispose();
    _areteOficialCtrl.dispose();
    _nombreAliasCtrl.dispose();
    _pesoActualCtrl.dispose();
    _areteManejoFocus.dispose();
    _areteOficialFocus.dispose();
    _nombreAliasFocus.dispose();
    _pesoActualFocus.dispose();

    _origenOtroCtrl.dispose();
    _precioCompraCtrl.dispose();
    _origenOtroFocus.dispose();
    _precioCompraFocus.dispose();

    _potreroCtrl.dispose();
    _potreroFocus.dispose();
    _precioVentaCtrl.dispose();
    _precioVentaFocus.dispose();

    _hierroUbicacionCtrl.dispose();
    _hierroOrejasCtrl.dispose();
    _hierroColorCtrl.dispose();
    _hierroObsCtrl.dispose();
    _hierroUbicacionFocus.dispose();
    _hierroOrejasFocus.dispose();
    _hierroColorFocus.dispose();
    _hierroObsFocus.dispose();

    _padreExternoCtrl.dispose();
    _madreExternaCtrl.dispose();
    _padreExternoFocus.dispose();
    _madreExternaFocus.dispose();

    _observacionesCtrl.dispose();
    _observacionesFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosEnCascada(
    String fincaId, {
    String? preselectLoteId,
  }) async {
    setState(() => _loadingCascada = true);
    try {
      final resultados = await Future.wait([
        _lotesService.obtenerPorFinca(fincaId, soloActivos: true),
        _animalesService.obtenerPorFinca(fincaId),
      ]);

      if (!mounted || _selectedFincaId != fincaId) return;
      final lotes = resultados[0] as List<LoteModel>;
      final animales = resultados[1] as List<AnimalModel>;

      setState(() {
        _lotesDeFinca = lotes;
        _animalesDeFinca = animales;
        if (preselectLoteId != null &&
            lotes.any((l) => l.id == preselectLoteId)) {
          _selectedLoteId = preselectLoteId;
        } else if (_selectedLoteId != null &&
            !lotes.any((l) => l.id == _selectedLoteId)) {
          _selectedLoteId = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lotesDeFinca = [];
          _animalesDeFinca = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCascada = false);
      }
    }
  }

  Future<void> _seleccionarFecha({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(hoy) ? hoy : initialDate,
      firstDate: DateTime(1995),
      lastDate: hoy,
    );
    if (elegida != null) {
      onSelected(elegida);
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _areteManejoCtrl.clear();
    _areteOficialCtrl.clear();
    _nombreAliasCtrl.clear();
    _pesoActualCtrl.clear();
    _origenOtroCtrl.clear();
    _precioCompraCtrl.clear();
    _potreroCtrl.clear();
    _precioVentaCtrl.clear();
    _hierroUbicacionCtrl.clear();
    _hierroOrejasCtrl.clear();
    _hierroColorCtrl.clear();
    _hierroObsCtrl.clear();
    _padreExternoCtrl.clear();
    _madreExternaCtrl.clear();
    _observacionesCtrl.clear();

    setState(() {
      _sexo = 'Hembra';
      _tipoExplotacion = 'Lecheria';
      _fechaNacimiento = DateTime.now().subtract(const Duration(days: 180));
      _fechaNacimientoExacta = true;
      _origen = 'Nacido en la finca';
      _selectedLoteId = null;
      _estadoActual = 'Activo';
      _fechaEntrada = DateTime.now();
      _fechaSalida = DateTime.now();
      _breedSelection = const BreedSelectionResult(
        esRazaPura: true,
        razaPuraNombre: null,
        composicionCruces: [],
        razaEtiquetaDisplay: '',
      );
      _breedErrorText = null;
      _padreEsInterno = true;
      _padreSeleccionado = null;
      _tipoPruebaPaterna = 'Sin confirmar';
      _madreEsInterna = true;
      _madreSeleccionada = null;
      _tipoPruebaMaterna = 'Sin confirmar';
      _fotos.clear();
      _uploadProgress = 0.0;
      _uploadStatus = null;
    });
  }

  bool get _esOrigenComprado =>
      _origen == 'Comprado en subasta' || _origen == 'Otro';

  Future<void> _guardarAnimal() async {
    FocusScope.of(context).unfocus();
    final formValido = _formKey.currentState!.validate();

    if (!_breedSelection.isValid) {
      setState(() {
        _breedErrorText = _breedSelection.esRazaPura
            ? 'Seleccione una raza pura del catálogo zootécnico.'
            : 'Añada al menos una raza y fracción válida para el cruce.';
      });
    } else {
      setState(() => _breedErrorText = null);
    }

    if (!formValido || !_breedSelection.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor revisa los campos obligatorios marcados en el formulario.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFincaId == null || _selectedFincaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la finca actual donde se ubica el animal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
      _uploadStatus = null;
    });

    try {
      final animalId = const Uuid().v4();
      List<String> urlsFotos = [];

      if (_fotos.isNotEmpty) {
        setState(() {
          _isUploadingPhotos = true;
          _uploadStatus = 'Subiendo fotografía 1 de ${_fotos.length}...';
        });

        urlsFotos = await _storageService.uploadMultiplePhotos(
          bucket: 'animales_fotos',
          entityId: animalId,
          files: _fotos
              .map((f) => (bytes: f.bytes, extension: f.extension))
              .toList(),
          onProgress: (completed, total) {
            if (mounted) {
              setState(() {
                _uploadProgress = completed / total;
                _uploadStatus = completed < total
                    ? 'Subiendo fotografía ${completed + 1} de $total...'
                    : 'Fotografías listas ($completed/$total)';
              });
            }
          },
        );
      }

      final pesoTexto = _pesoActualCtrl.text.trim().replaceAll(',', '.');
      final pesoActual =
          pesoTexto.isNotEmpty ? double.tryParse(pesoTexto) : null;

      final precioTexto = _precioCompraCtrl.text.trim().replaceAll(',', '.');
      final precioCompra = (_esOrigenComprado && precioTexto.isNotEmpty)
          ? double.tryParse(precioTexto)
          : null;

      final marcasHierro = MarcasHierro(
        ubicacionCuerpo: _hierroUbicacionCtrl.text.trim(),
        marcasOrejas: _hierroOrejasCtrl.text.trim(),
        colorMarcas: _hierroColorCtrl.text.trim(),
        observacionHierro: _hierroObsCtrl.text.trim(),
      );

      if (_padreEsInterno && _padreSeleccionado != null) {
        final valPadre = GenealogiaValidator.validarProgenitor(
          proposedParentId: _padreSeleccionado!.id,
          rol: 'padre',
          todosLosAnimales: _animalesDeFinca,
        );
        if (!valPadre.isValid) {
          if (mounted) {
            AppFeedback.mostrarAdvertenciaZootecnica(
              context: context,
              mensaje: valPadre.errorMessage!,
            );
          }
          return;
        }
      }

      if (_madreEsInterna && _madreSeleccionada != null) {
        final valMadre = GenealogiaValidator.validarProgenitor(
          proposedParentId: _madreSeleccionada!.id,
          rol: 'madre',
          todosLosAnimales: _animalesDeFinca,
        );
        if (!valMadre.isValid) {
          if (mounted) {
            AppFeedback.mostrarAdvertenciaZootecnica(
              context: context,
              mensaje: valMadre.errorMessage!,
            );
          }
          return;
        }
      }

      final ubicacionAjustada =
          PredioConsistencyHelper.procesarUbicacionPorEstado(
        estadoActual: _estadoActual,
        loteIdOriginal: _selectedLoteId,
        potreroOriginal: _potreroCtrl.text.trim().isNotEmpty
            ? _potreroCtrl.text.trim()
            : null,
        fechaSalidaOriginal: _esDeBaja ? _fechaSalida : null,
      );

      var obsFinal = _observacionesCtrl.text.trim();
      if (_estadoActual == 'Vendido' &&
          _precioVentaCtrl.text.trim().isNotEmpty) {
        final precioVentaFmt = _precioVentaCtrl.text.trim();
        obsFinal = obsFinal.isNotEmpty
            ? 'Precio de Venta: \$ $precioVentaFmt | $obsFinal'
            : 'Precio de Venta: \$ $precioVentaFmt';
      }

      final animal = AnimalModel(
        id: animalId,
        codigoSistema: '', // Generado por trigger trg_generar_codigo_animal
        areteManejo: _areteManejoCtrl.text.trim(),
        areteOficial: _areteOficialCtrl.text.trim().isNotEmpty
            ? _areteOficialCtrl.text.trim()
            : null,
        nombreAlias: _nombreAliasCtrl.text.trim().isNotEmpty
            ? _nombreAliasCtrl.text.trim()
            : null,
        sexo: _sexo,
        pesoActual: pesoActual,
        esRazaPura: _breedSelection.esRazaPura,
        razaPuraNombre: _breedSelection.razaPuraNombre,
        composicionCruces: _breedSelection.composicionCruces,
        razaEtiquetaDisplay: _breedSelection.razaEtiquetaDisplay,
        tipoExplotacion: _tipoExplotacion,
        fechaNacimiento: _fechaNacimiento,
        fechaNacimientoExacta: _fechaNacimientoExacta,
        origen: _origen,
        origenOtroDetalle: _origen == 'Otro'
            ? _origenOtroCtrl.text.trim()
            : null,
        fincaId: _selectedFincaId!,
        potreroActual: ubicacionAjustada.potreroActual,
        loteId: ubicacionAjustada.loteId,
        estadoActual: _estadoActual,
        fechaEntrada: _fechaEntrada,
        precioCompra: precioCompra,
        fechaSalida: ubicacionAjustada.fechaSalida,
        marcasHierro: marcasHierro,
        observaciones: obsFinal.isNotEmpty ? obsFinal : null,
        fotos: urlsFotos,
      );

      final genealogia = GenealogiaModel(
        id: '',
        animalId: animalId,
        padreId: _padreEsInterno ? _padreSeleccionado?.id : null,
        padreExternoReferencia: !_padreEsInterno &&
                _padreExternoCtrl.text.trim().isNotEmpty
            ? _padreExternoCtrl.text.trim()
            : null,
        tipoPruebaPaterna: _tipoPruebaPaterna,
        madreId: _madreEsInterna ? _madreSeleccionada?.id : null,
        madreExternaReferencia: !_madreEsInterna &&
                _madreExternaCtrl.text.trim().isNotEmpty
            ? _madreExternaCtrl.text.trim()
            : null,
        tipoPruebaMaterna: _tipoPruebaMaterna,
      );

      final registrado = await _animalesService.registrar(
        animal,
        genealogia: genealogia,
      );

      if (!mounted) return;
      AppFeedback.mostrarExito(
        context: context,
        mensaje:
            'Animal registrado exitosamente con código ${registrado.codigoSistema} (Arete: ${registrado.areteManejo}).',
      );

      final fincaActual = _selectedFincaId;
      _limpiarFormulario();
      if (fincaActual != null) {
        _cargarDatosEnCascada(fincaActual);
      }
      widget.onAnimalCreated?.call(registrado);
    } catch (e) {
      if (mounted) {
        AppFeedback.mostrarError(
          context: context,
          mensaje: 'Error al guardar el expediente del animal: $e',
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
    final machosValidos = GenealogiaValidator.filtrarCandidatosValidos(
      animalActualId: null,
      sexo: 'Macho',
      candidatos: _animalesDeFinca,
      todosLosAnimales: _animalesDeFinca,
    );
    final hembrasValidas = GenealogiaValidator.filtrarCandidatosValidos(
      animalActualId: null,
      sexo: 'Hembra',
      candidatos: _animalesDeFinca,
      todosLosAnimales: _animalesDeFinca,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: 16),

          // SECCIÓN 1: IDENTIFICACIÓN Y BIOMETRÍA
          _FormSectionCard(
            title: '1. Identificación y Biometría',
            icon: Icons.badge_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCodigoSistemaReadOnly()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildAreteManejoField()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildAreteOficialField()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildCodigoSistemaReadOnly(),
                        const SizedBox(height: 12),
                        _buildAreteManejoField(),
                        const SizedBox(height: 12),
                        _buildAreteOficialField(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildNombreAliasField()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildSexoDropdown()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildPesoActualField()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildNombreAliasField(),
                        const SizedBox(height: 12),
                        _buildSexoDropdown(),
                        const SizedBox(height: 12),
                        _buildPesoActualField(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 2: RAZA Y MANEJO ZOOTÉCNICO (MODO A)
          _FormSectionCard(
            title: '2. Genética y Clasificación Zootécnica',
            icon: Icons.biotech_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BreedCrossBuilder(
                  initialValue: _breedSelection,
                  onChanged: (res) {
                    setState(() {
                      _breedSelection = res;
                      if (res.isValid) _breedErrorText = null;
                    });
                  },
                ),
                if (_breedErrorText != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      _breedErrorText!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTipoExplotacionDropdown()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildFechaNacimientoSelector()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildTipoExplotacionDropdown(),
                        const SizedBox(height: 14),
                        _buildFechaNacimientoSelector(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _fechaNacimientoExacta,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    '¿Fecha de nacimiento exacta conocida?',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _fechaNacimientoExacta
                        ? 'Registrada según parto documentado'
                        : 'Estimada por cronometría dentaria / fenotipo (aproximada)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _fechaNacimientoExacta = val),
                ),
                const Divider(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    final mostrarDetalleOtro = _origen == 'Otro';
                    final mostrarPrecio = _esOrigenComprado;

                    if (isWide && (mostrarDetalleOtro || mostrarPrecio)) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildOrigenDropdown()),
                          if (mostrarDetalleOtro) ...[
                            const SizedBox(width: 14),
                            Expanded(child: _buildOrigenOtroField()),
                          ],
                          if (mostrarPrecio) ...[
                            const SizedBox(width: 14),
                            Expanded(child: _buildPrecioCompraField()),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildOrigenDropdown(),
                        if (mostrarDetalleOtro) ...[
                          const SizedBox(height: 12),
                          _buildOrigenOtroField(),
                        ],
                        if (mostrarPrecio) ...[
                          const SizedBox(height: 12),
                          _buildPrecioCompraField(),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 3: UBICACIÓN EN CASCADA (FINCA -> LOTES)
          _FormSectionCard(
            title: '3. Ubicación Actual y Manejo Productivo',
            icon: Icons.place_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildFincaCascadeDropdown()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildLoteCascadeDropdown()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildFincaCascadeDropdown(),
                        const SizedBox(height: 14),
                        _buildLoteCascadeDropdown(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPotreroField()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildEstadoActualDropdown()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildFechaEntradaSelector()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildPotreroField(),
                        const SizedBox(height: 12),
                        _buildEstadoActualDropdown(),
                        const SizedBox(height: 12),
                        _buildFechaEntradaSelector(),
                      ],
                    );
                  },
                ),
                if (_esDeBaja) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Animal en estado de $_estadoActual: '
                            'Se inhabilitan potrero y lote físico, y se requiere fecha de salida.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 680;
                      if (isWide && _estadoActual == 'Vendido') {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFechaSalidaSelector()),
                            const SizedBox(width: 14),
                            Expanded(child: _buildPrecioVentaField()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildFechaSalidaSelector(),
                          if (_estadoActual == 'Vendido') ...[
                            const SizedBox(height: 12),
                            _buildPrecioVentaField(),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 4: MARCAS DE HIERRO Y SEÑALES
          _FormSectionCard(
            title: '4. Marcas de Hierro y Señales Físicas',
            icon: Icons.branding_watermark_outlined,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 680;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Ubicación en el Cuerpo',
                              hint: 'Ej. Pierna derecha / Paleta izquierda',
                              controller: _hierroUbicacionCtrl,
                              focusNode: _hierroUbicacionFocus,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomTextField(
                              label: 'Marcas en las Orejas',
                              hint: 'Ej. Muesca en V oreja derecha / Tatuaje',
                              controller: _hierroOrejasCtrl,
                              focusNode: _hierroOrejasFocus,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomTextField(
                              label: 'Color / Tipo de Marca',
                              hint: 'Ej. Hierro candente / Nitrógeno blanco',
                              controller: _hierroColorCtrl,
                              focusNode: _hierroColorFocus,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        CustomTextField(
                          label: 'Ubicación en el Cuerpo',
                          hint: 'Ej. Pierna derecha / Paleta izquierda',
                          controller: _hierroUbicacionCtrl,
                          focusNode: _hierroUbicacionFocus,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Marcas en las Orejas',
                          hint: 'Ej. Muesca en V oreja derecha / Tatuaje',
                          controller: _hierroOrejasCtrl,
                          focusNode: _hierroOrejasFocus,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Color / Tipo de Marca',
                          hint: 'Ej. Hierro candente / Nitrógeno blanco',
                          controller: _hierroColorCtrl,
                          focusNode: _hierroColorFocus,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Observaciones del Hierro',
                  hint: 'Iniciales o figura del hierro criador / propietario anterior',
                  controller: _hierroObsCtrl,
                  focusNode: _hierroObsFocus,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 5: GENEALOGÍA / LINAJE (PADRE Y MADRE)
          _FormSectionCard(
            title: '5. Genealogía y Linaje Reproductivo',
            icon: Icons.account_tree_outlined,
            child: Column(
              children: [
                _ParentescoSelectorCard(
                  tituloRol: 'Padre (Reproductor / Toro)',
                  iconoRol: Icons.male_rounded,
                  esInterno: _padreEsInterno,
                  etiquetaToggleExterno: 'Externo / Pajuela',
                  candidatosInternos: machosValidos,
                  animalSeleccionado: _padreSeleccionado,
                  referenciaExternaCtrl: _padreExternoCtrl,
                  referenciaExternaFocus: _padreExternoFocus,
                  hintExterno:
                      'Ej. Pajuela Toro Gyr Sansão #BR-9942 / Catálogo ABS',
                  tipoPrueba: _tipoPruebaPaterna,
                  fincaSeleccionada: _selectedFincaId != null,
                  onModoChanged: (interno) {
                    setState(() => _padreEsInterno = interno);
                  },
                  onAnimalSelected: (animal) {
                    setState(() => _padreSeleccionado = animal);
                  },
                  onTipoPruebaChanged: (prueba) {
                    if (prueba != null) {
                      setState(() => _tipoPruebaPaterna = prueba);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ParentescoSelectorCard(
                  tituloRol: 'Madre (Vaca / Donadora)',
                  iconoRol: Icons.female_rounded,
                  esInterno: _madreEsInterna,
                  etiquetaToggleExterno: 'Externa / Donadora',
                  candidatosInternos: hembrasValidas,
                  animalSeleccionado: _madreSeleccionada,
                  referenciaExternaCtrl: _madreExternaCtrl,
                  referenciaExternaFocus: _madreExternaFocus,
                  hintExterno:
                      'Ej. Donadora Embriones Hacienda El Vergel #405',
                  tipoPrueba: _tipoPruebaMaterna,
                  fincaSeleccionada: _selectedFincaId != null,
                  onModoChanged: (interna) {
                    setState(() => _madreEsInterna = interna);
                  },
                  onAnimalSelected: (animal) {
                    setState(() => _madreSeleccionada = animal);
                  },
                  onTipoPruebaChanged: (prueba) {
                    if (prueba != null) {
                      setState(() => _tipoPruebaMaterna = prueba);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 6: OBSERVACIONES Y FOTOGRAFÍAS
          _FormSectionCard(
            title: '6. Observaciones y Registro Fotográfico',
            icon: Icons.camera_enhance_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Observaciones Sanitarias o Productivas Iniciales',
                  hint:
                      'Condición corporal al ingreso, temperamento, aplomos, historial vacunal...',
                  controller: _observacionesCtrl,
                  focusNode: _observacionesFocus,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                PhotoUploaderWidget(
                  label: 'Fotografías del Animal (Máx. 3)',
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
                        label: const Text('Limpiar Expediente'),
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
                        onPressed: _isSaving ? null : _guardarAnimal,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isSaving
                              ? 'Guardando Expediente...'
                              : 'Guardar Expediente Animal',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
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

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.pets_outlined),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apertura de Expediente Individual Bovino',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trazabilidad genética Modo A, asignación en cascada Finca → Lote y registro genealógico completo.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodigoSistemaReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Código Sistema',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_clock_outlined,
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Generado automáticamente (GAN-XXXXXX)',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAreteManejoField() {
    return CustomTextField(
      label: 'Arete de Manejo',
      hint: 'Ej. 402-A',
      controller: _areteManejoCtrl,
      focusNode: _areteManejoFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.loyalty_outlined, size: 19),
      validator: (v) => Validators.requerido(v, 'Ingrese el arete de manejo'),
    );
  }

  Widget _buildAreteOficialField() {
    return CustomTextField(
      label: 'Arete Oficial / Chip RFID',
      hint: 'Ej. CO-055129834 (Opcional)',
      controller: _areteOficialCtrl,
      focusNode: _areteOficialFocus,
      prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
    );
  }

  Widget _buildNombreAliasField() {
    return CustomTextField(
      label: 'Nombre o Alias',
      hint: 'Ej. Marquesa / Sultán (Opcional)',
      controller: _nombreAliasCtrl,
      focusNode: _nombreAliasFocus,
      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
    );
  }

  Widget _buildSexoDropdown() {
    return CustomFormDropdown<String>(
      label: 'Sexo',
      value: _sexo,
      isRequired: true,
      prefixIcon: Icon(
        _sexo == 'Macho' ? Icons.male_rounded : Icons.female_rounded,
        size: 20,
      ),
      items: const [
        DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
        DropdownMenuItem(value: 'Macho', child: Text('Macho')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _sexo = val);
      },
    );
  }

  Widget _buildPesoActualField() {
    return CustomTextField.numeric(
      label: 'Peso Actual',
      hint: 'Ej. 420.5',
      suffixText: 'kg',
      controller: _pesoActualCtrl,
      focusNode: _pesoActualFocus,
      prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
      validator: (val) =>
          Validators.numeroPositivo(val, 'Ingrese un peso válido'),
    );
  }

  Widget _buildTipoExplotacionDropdown() {
    return CustomFormDropdown<String>(
      label: 'Tipo de Explotación',
      value: _tipoExplotacion,
      isRequired: true,
      prefixIcon: const Icon(Icons.agriculture_outlined, size: 20),
      items: const [
        DropdownMenuItem(value: 'Lecheria', child: Text('Lechería')),
        DropdownMenuItem(
            value: 'Doble Proposito', child: Text('Doble Propósito')),
        DropdownMenuItem(value: 'Cria', child: Text('Cría')),
        DropdownMenuItem(value: 'Ceba', child: Text('Ceba')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _tipoExplotacion = val);
      },
    );
  }

  Widget _buildFechaNacimientoSelector() {
    return _DateSelectorField(
      label: 'Fecha de Nacimiento',
      isRequired: true,
      valueText: Formatters.formatearFecha(_fechaNacimiento),
      badgeText: _fechaNacimientoExacta ? 'Exacta' : 'Aproximada',
      onTap: () => _seleccionarFecha(
        initialDate: _fechaNacimiento,
        onSelected: (fecha) => setState(() => _fechaNacimiento = fecha),
      ),
    );
  }

  Widget _buildOrigenDropdown() {
    return CustomFormDropdown<String>(
      label: 'Origen del Animal',
      value: _origen,
      isRequired: true,
      prefixIcon: const Icon(Icons.flag_outlined, size: 20),
      items: const [
        DropdownMenuItem(
          value: 'Nacido en la finca',
          child: Text('Nacido en la finca'),
        ),
        DropdownMenuItem(
          value: 'Comprado en subasta',
          child: Text('Comprado en subasta / feria'),
        ),
        DropdownMenuItem(value: 'Arriendo', child: Text('Arriendo / Al aumento')),
        DropdownMenuItem(value: 'Otro', child: Text('Otro origen')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _origen = val);
        }
      },
    );
  }

  Widget _buildOrigenOtroField() {
    return CustomTextField(
      label: 'Detalle de Otro Origen',
      hint: 'Especifique procedencia (compra directa, permuta, donación...)',
      controller: _origenOtroCtrl,
      focusNode: _origenOtroFocus,
      isRequired: true,
      validator: (val) {
        if (_origen == 'Otro') {
          return Validators.requerido(
            val,
            'Especifique el detalle del origen',
          );
        }
        return null;
      },
    );
  }

  Widget _buildPrecioCompraField() {
    return CustomTextField.numeric(
      label: 'Precio de Compra (Opcional)',
      hint: 'Ej. 3500000',
      suffixText: 'COP',
      controller: _precioCompraCtrl,
      focusNode: _precioCompraFocus,
      prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
      validator: (val) =>
          Validators.numeroPositivo(val, 'Ingrese un monto válido'),
    );
  }

  Widget _buildFincaCascadeDropdown() {
    return CustomFormDropdown<String>(
      label: 'Finca Actual',
      value: _selectedFincaId,
      isRequired: true,
      isLoading: widget.isLoadingFincas,
      hint: 'Seleccione la finca actual',
      prefixIcon: const Icon(Icons.landscape_outlined, size: 20),
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onRefreshFincas != null)
            IconButton(
              tooltip: 'Actualizar lista de fincas',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onRefreshFincas,
              icon: const Icon(
                Icons.sync_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
            ),
          if (widget.onRequestCreateFinca != null)
            TextButton.icon(
              onPressed: widget.onRequestCreateFinca,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Nueva'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      items: widget.fincas
          .map(
            (f) => DropdownMenuItem<String>(
              value: f.id,
              child: Text(
                '${f.nombre} (${f.identificador})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Seleccione una finca' : null,
      onChanged: (nuevoFincaId) {
        if (nuevoFincaId == null || nuevoFincaId == _selectedFincaId) return;
        setState(() {
          _selectedFincaId = nuevoFincaId;
          _selectedLoteId = null;
          _padreSeleccionado = null;
          _madreSeleccionada = null;
        });
        _cargarDatosEnCascada(nuevoFincaId);
      },
    );
  }

  Widget _buildLoteCascadeDropdown() {
    return CustomFormDropdown<String>(
      label: 'Lote de Manejo Actual',
      value: _selectedLoteId,
      isLoading: _loadingCascada,
      enabled: _selectedFincaId != null && !_esDeBaja,
      hint: _esDeBaja
          ? 'No aplica (animal dado de baja)'
          : (_selectedFincaId == null
              ? 'Seleccione primero una finca'
              : (_lotesDeFinca.isEmpty
                  ? 'Sin lotes activos en esta finca'
                  : 'Seleccione lote (Opcional)')),
      prefixIcon: const Icon(Icons.grid_view_outlined, size: 20),
      headerTrailing: (widget.onRequestCreateLote != null && !_esDeBaja)
          ? TextButton.icon(
              onPressed: () => widget.onRequestCreateLote!(_selectedFincaId),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Nuevo Lote'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                visualDensity: VisualDensity.compact,
              ),
            )
          : null,
      items: _lotesDeFinca
          .map(
            (lote) => DropdownMenuItem<String>(
              value: lote.id,
              child: Text(
                '${lote.nombre} (${lote.propositoProductivo})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedLoteId = val),
    );
  }

  Widget _buildPotreroField() {
    return CustomTextField(
      label: 'Potrero Actual',
      hint: _esDeBaja
          ? 'No aplica (animal dado de baja)'
          : 'Ej. Potrero La Ceiba #4',
      enabled: !_esDeBaja,
      controller: _potreroCtrl,
      focusNode: _potreroFocus,
      prefixIcon: const Icon(Icons.grass_outlined, size: 20),
    );
  }

  Widget _buildEstadoActualDropdown() {
    return CustomFormDropdown<String>(
      label: 'Estado Actual',
      value: _estadoActual,
      isRequired: true,
      prefixIcon: const Icon(Icons.health_and_safety_outlined, size: 20),
      items: const [
        DropdownMenuItem(value: 'Activo', child: Text('Activo')),
        DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
        DropdownMenuItem(value: 'Muerto', child: Text('Muerto')),
        DropdownMenuItem(value: 'Descartado', child: Text('Descartado')),
        DropdownMenuItem(value: 'Robado', child: Text('Robado')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _estadoActual = val;
            if (_esDeBaja) {
              _selectedLoteId = null;
              _potreroCtrl.clear();
            }
          });
        }
      },
    );
  }

  Widget _buildFechaSalidaSelector() {
    return _DateSelectorField(
      label: 'Fecha de Salida / Baja',
      isRequired: true,
      valueText: Formatters.formatearFecha(_fechaSalida),
      onTap: () => _seleccionarFecha(
        initialDate: _fechaSalida,
        onSelected: (fecha) => setState(() => _fechaSalida = fecha),
      ),
    );
  }

  Widget _buildPrecioVentaField() {
    return CustomTextField.numeric(
      label: 'Precio de Venta',
      hint: 'Ej. 4500000',
      suffixText: 'COP',
      controller: _precioVentaCtrl,
      focusNode: _precioVentaFocus,
      isRequired: true,
      prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
      validator: (val) {
        if (_estadoActual == 'Vendido') {
          return Validators.numeroPositivo(val, 'Ingrese el precio de venta');
        }
        return null;
      },
    );
  }

  Widget _buildFechaEntradaSelector() {
    return _DateSelectorField(
      label: 'Fecha de Entrada al Hato',
      isRequired: true,
      valueText: Formatters.formatearFecha(_fechaEntrada),
      onTap: () => _seleccionarFecha(
        initialDate: _fechaEntrada,
        onSelected: (fecha) => setState(() => _fechaEntrada = fecha),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateSelectorField extends StatelessWidget {
  final String label;
  final String valueText;
  final String? badgeText;
  final bool isRequired;
  final VoidCallback onTap;

  const _DateSelectorField({
    required this.label,
    required this.valueText,
    this.badgeText,
    this.isRequired = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ParentescoSelectorCard extends StatefulWidget {
  final String tituloRol;
  final IconData iconoRol;
  final bool esInterno;
  final String etiquetaToggleExterno;
  final List<AnimalModel> candidatosInternos;
  final AnimalModel? animalSeleccionado;
  final TextEditingController referenciaExternaCtrl;
  final FocusNode referenciaExternaFocus;
  final String hintExterno;
  final String tipoPrueba;
  final bool fincaSeleccionada;
  final ValueChanged<bool> onModoChanged;
  final ValueChanged<AnimalModel?> onAnimalSelected;
  final ValueChanged<String?> onTipoPruebaChanged;

  const _ParentescoSelectorCard({
    required this.tituloRol,
    required this.iconoRol,
    required this.esInterno,
    required this.etiquetaToggleExterno,
    required this.candidatosInternos,
    required this.animalSeleccionado,
    required this.referenciaExternaCtrl,
    required this.referenciaExternaFocus,
    required this.hintExterno,
    required this.tipoPrueba,
    required this.fincaSeleccionada,
    required this.onModoChanged,
    required this.onAnimalSelected,
    required this.onTipoPruebaChanged,
  });

  @override
  State<_ParentescoSelectorCard> createState() =>
      _ParentescoSelectorCardState();
}

class _ParentescoSelectorCardState extends State<_ParentescoSelectorCard> {
  final _busquedaCtrl = TextEditingController();
  final _busquedaFocus = FocusNode();
  String _termino = '';

  @override
  void initState() {
    super.initState();
    _busquedaFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _busquedaFocus.removeListener(_onFocusChange);
    _busquedaCtrl.dispose();
    _busquedaFocus.dispose();
    super.dispose();
  }

  List<AnimalModel> get _resultadosFiltrados {
    final q = _termino.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.candidatosInternos.take(5).toList();
    }
    return widget.candidatosInternos.where((a) {
      final manejo = a.areteManejo.toLowerCase();
      final oficial = (a.areteOficial ?? '').toLowerCase();
      final alias = (a.nombreAlias ?? '').toLowerCase();
      final codigo = a.codigoSistema.toLowerCase();
      return manejo.contains(q) ||
          oficial.contains(q) ||
          alias.contains(q) ||
          codigo.contains(q);
    }).take(8).toList();
  }

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.iconoRol, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    widget.tituloRol,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SegmentedButton<bool>(
                segments: [
                  const ButtonSegment<bool>(
                    value: true,
                    label: Text('Animal de la Finca'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(widget.etiquetaToggleExterno),
                  ),
                ],
                selected: {widget.esInterno},
                onSelectionChanged: (sel) => widget.onModoChanged(sel.first),
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
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 620;
              final selectorPrincipal = widget.esInterno
                  ? _buildBuscadorInterno()
                  : CustomTextField(
                      label: 'Referencia o Código de Catálogo Externo',
                      hint: widget.hintExterno,
                      controller: widget.referenciaExternaCtrl,
                      focusNode: widget.referenciaExternaFocus,
                      prefixIcon:
                          const Icon(Icons.science_outlined, size: 19),
                    );

              final selectorPrueba = CustomFormDropdown<String>(
                label: 'Tipo de Prueba / Respaldo',
                value: widget.tipoPrueba,
                items: const [
                  DropdownMenuItem(
                    value: 'Sin confirmar',
                    child: Text('Sin confirmar'),
                  ),
                  DropdownMenuItem(
                    value: 'Visual / Monta natural',
                    child: Text('Visual / Monta natural'),
                  ),
                  DropdownMenuItem(
                    value: 'Inseminacion',
                    child: Text('Inseminación Artificial'),
                  ),
                  DropdownMenuItem(
                    value: 'ADN',
                    child: Text('Prueba Genética ADN'),
                  ),
                ],
                onChanged: widget.onTipoPruebaChanged,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: selectorPrincipal),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: selectorPrueba),
                  ],
                );
              }
              return Column(
                children: [
                  selectorPrincipal,
                  const SizedBox(height: 12),
                  selectorPrueba,
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBuscadorInterno() {
    if (!widget.fincaSeleccionada) {
      return const Text(
        'Seleccione una finca primero para buscar reproductores registrados.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    if (widget.animalSeleccionado != null) {
      final sel = widget.animalSeleccionado!;
      final alias =
          (sel.nombreAlias != null && sel.nombreAlias!.trim().isNotEmpty)
              ? ' • "${sel.nombreAlias}"'
              : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arete ${sel.areteManejo}$alias (${sel.codigoSistema})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    sel.razaEtiquetaDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cambiar selección',
              onPressed: () => widget.onAnimalSelected(null),
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            ),
          ],
        ),
      );
    }

    final sugerencias = _resultadosFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Buscar en la Finca (Arete Manejo, Oficial o Nombre)',
          hint: widget.candidatosInternos.isEmpty
              ? 'No hay ejemplares de este sexo registrados en la finca'
              : 'Escribe arete o nombre para filtrar (${widget.candidatosInternos.length} disponibles)...',
          controller: _busquedaCtrl,
          focusNode: _busquedaFocus,
          enabled: widget.candidatosInternos.isNotEmpty,
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          onChanged: (val) => setState(() => _termino = val),
        ),
        if (widget.candidatosInternos.isNotEmpty &&
            (_termino.trim().isNotEmpty || _busquedaFocus.hasFocus)) ...[
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 170),
              child: sugerencias.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Sin coincidencias por arete o nombre en esta finca.',
                      style:
                          TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: sugerencias.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sugerencias[index];
                      final aliasTxt = (item.nombreAlias != null &&
                              item.nombreAlias!.isNotEmpty)
                          ? ' - ${item.nombreAlias}'
                          : '';
                      final oficialTxt = (item.areteOficial != null &&
                              item.areteOficial!.isNotEmpty)
                          ? ' | Oficial: ${item.areteOficial}'
                          : '';
                      return ListTile(
                        dense: true,
                        title: Text(
                          'Arete: ${item.areteManejo}$aliasTxt',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.codigoSistema} • ${item.razaEtiquetaDisplay}$oficialTxt',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        onTap: () {
                          _busquedaCtrl.clear();
                          setState(() => _termino = '');
                          widget.onAnimalSelected(item);
                        },
                      );
                    },
                  ),
            ),
          ),
        ] else if (widget.candidatosInternos.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.candidatosInternos.take(4).map((item) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.pets, size: 14, color: AppColors.primary),
                label: Text(
                  '${item.areteManejo}${item.nombreAlias != null ? " (${item.nombreAlias})" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => widget.onAnimalSelected(item),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
