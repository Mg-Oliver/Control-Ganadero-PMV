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
import '../../../../data/services/storage_service.dart';
import '../../../common/breed_cross_builder.dart';
import '../../../common/custom_form_dropdown.dart';
import '../../../common/custom_text_field.dart';
import '../../../common/photo_uploader_widget.dart';
import 'package:intl/intl.dart';
import 'registrar_toro_donante_modal.dart';
import '../../../../data/models/toro_donante_model.dart';
import '../../../../data/services/toros_donantes_service.dart';

class AnimalForm extends StatefulWidget {
  final VoidCallback? onVerInventario;
  final String? sexoInicial;
  final String? fincaInicialId;
  final bool preguntarPertenencia;
  final List<FincaModel> fincas;
  final bool isLoadingFincas;
  final FincaModel? newlyCreatedFinca;
  final LoteModel? newlyCreatedLote;
  final VoidCallback? onRefreshFincas;
  final VoidCallback? onRequestCreateFinca;
  final ValueChanged<String?>? onRequestCreateLote;
  final ValueChanged<AnimalModel>? onAnimalCreated;
  final ValueChanged<AnimalModel>? onAnimalUpdated;
  final AnimalModel? animalAEditar;
  final AnimalesService? animalesService;
  final TorosDonantesService? torosDonantesService;

  const AnimalForm({
    super.key,
    required this.fincas,
    this.onVerInventario,
    this.sexoInicial,
    this.fincaInicialId,
    this.preguntarPertenencia = false,
    this.isLoadingFincas = false,
    this.newlyCreatedFinca,
    this.newlyCreatedLote,
    this.onRefreshFincas,
    this.onRequestCreateFinca,
    this.onRequestCreateLote,
    this.onAnimalCreated,
    this.onAnimalUpdated,
    this.animalAEditar,
    this.animalesService,
    this.torosDonantesService,
  });

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  final _formKey = GlobalKey<FormState>();
  late final AnimalesService _animalesService;
  final _storageService = StorageService();
  late final TorosDonantesService _torosDonantesService;
  List<String> _fotosExistentes = [];

  // Identificación y biometría
  final _areteManejoCtrl = TextEditingController();
  final _areteOficialCtrl = TextEditingController();
  final _nombreAliasCtrl = TextEditingController();
  final _pesoActualCtrl = TextEditingController();
  final _numeroPartosCtrl = TextEditingController(text: '0');

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
  DateTime _fechaNacimiento = DateTime.now().subtract(
    const Duration(days: 180),
  );
  bool _fechaNacimientoExacta = true;
  bool _ingresarEdad = false;
  bool _esExterno = false;
  final _fechaNacimientoCtrl = TextEditingController();
  final _edadAniosCtrl = TextEditingController();
  final _edadMesesCtrl = TextEditingController();
  final _edadDiasCtrl = TextEditingController();

  String _origen = 'Nacido en la finca';
  String? _selectedFincaId;
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
  List<AnimalModel> _animalesDeFinca = [];

  // Genealogía Padre y Madre
  bool _padreEsInterno = true;
  bool _padreEsIA = false;
  AnimalModel? _padreSeleccionado;
  String _tipoPruebaPaterna = 'Visual / Monta natural';
  ToroDonanteModel? _toroDonante;
  List<ToroDonanteModel> _torosDonantes = [];

  bool _madreEsInterna = true;
  AnimalModel? _madreSeleccionada;

  // Fotos y progreso
  final List<SelectedPhoto> _fotos = [];
  bool _isSaving = false;
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    _animalesService = widget.animalesService ?? AnimalesService();
    _torosDonantesService =
        widget.torosDonantesService ?? TorosDonantesService();
    _sexo = widget.sexoInicial ?? _sexo;
    _fechaNacimientoCtrl.text = Formatters.formatearFecha(_fechaNacimiento);
    _cargarTorosDonantes();
    if (widget.animalAEditar != null) {
      _cargarDatosAnimalAEditar(widget.animalAEditar!);
    } else if (widget.fincas.isNotEmpty) {
      _selectedFincaId = widget.fincaInicialId ?? widget.fincas.first.id;
      _cargarDatosEnCascada(_selectedFincaId!);
    }
  }

  void _cargarDatosAnimalAEditar(AnimalModel a) {
    _areteManejoCtrl.text = a.areteManejo;
    _areteOficialCtrl.text = a.areteOficial ?? '';
    _nombreAliasCtrl.text = a.nombreAlias ?? '';
    _pesoActualCtrl.text = a.pesoActual != null ? a.pesoActual!.toString() : '';
    _numeroPartosCtrl.text = a.numeroPartos.toString();
    _sexo = a.sexo;
    _tipoExplotacion = a.tipoExplotacion;
    _esExterno = a.esExterno;
    _fechaNacimiento = a.fechaNacimiento;
    _fechaNacimientoCtrl.text = Formatters.formatearFecha(_fechaNacimiento);
    _fechaNacimientoExacta = a.fechaNacimientoExacta;
    _origen = a.origen;
    _origenOtroCtrl.text = a.origenOtroDetalle ?? '';
    _precioCompraCtrl.text = a.precioCompra != null
        ? a.precioCompra!.toString()
        : '';
    _selectedFincaId = a.fincaId;
    _potreroCtrl.text = a.potreroActual ?? '';
    _estadoActual = a.estadoActual;
    _fechaEntrada = a.fechaEntrada;
    _fechaSalida = a.fechaSalida ?? DateTime.now();

    _hierroUbicacionCtrl.text = a.marcasHierro.ubicacionCuerpo;
    _hierroOrejasCtrl.text = a.marcasHierro.marcasOrejas;
    _hierroColorCtrl.text = a.marcasHierro.colorMarcas;
    _hierroObsCtrl.text = a.marcasHierro.observacionHierro;

    _observacionesCtrl.text = a.observaciones ?? '';

    final composicion = a.composicionCruces
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    _breedSelection = BreedSelectionResult(
      esRazaPura: a.esRazaPura,
      razaPuraNombre: a.razaPuraNombre,
      composicionCruces: composicion,
      razaEtiquetaDisplay: a.razaEtiquetaDisplay,
    );

    _fotosExistentes = List<String>.from(a.fotos);

    final g = a.genealogia;
    if (g != null) {
      if (g.donanteId != null) {
        _padreEsIA = true;
        _padreEsInterno = false;
        if (g.donanteSnapshot != null) {
          _toroDonante = ToroDonanteModel.fromJson(g.donanteSnapshot!);
        }
      } else if (g.padreId != null) {
        _padreEsInterno = true;
        _padreEsIA = false;
      } else if (g.padreExternoReferencia != null) {
        _padreEsInterno = false;
        _padreEsIA = false;
        _padreExternoCtrl.text = g.padreExternoReferencia!;
      }
      _tipoPruebaPaterna =
          g.donanteId != null || g.tipoPruebaPaterna == 'Inseminacion'
          ? 'Inseminacion'
          : g.tipoPruebaPaterna == 'Transferencia de embriones'
          ? 'Transferencia de embriones'
          : 'Visual / Monta natural';
      if (_tipoPruebaPaterna == 'Inseminacion') {
        _padreEsIA = true;
        _padreEsInterno = false;
      }

      if (g.madreId != null) {
        _madreEsInterna = true;
      } else if (g.madreExternaReferencia != null) {
        _madreEsInterna = false;
        _madreExternaCtrl.text = g.madreExternaReferencia!;
      }
    }

    _cargarDatosEnCascada(a.fincaId, preselectGenealogia: g);
  }

  Future<void> _cargarTorosDonantes() async {
    try {
      final toros = await _torosDonantesService.obtenerActivos();
      if (mounted) {
        setState(() {
          _torosDonantes = toros;
          if (widget.animalAEditar?.genealogia?.donanteId != null) {
            final donId = widget.animalAEditar!.genealogia!.donanteId!;
            _toroDonante =
                toros.where((t) => t.id == donId).firstOrNull ??
                (widget.animalAEditar!.genealogia!.donanteSnapshot != null
                    ? ToroDonanteModel.fromJson(
                        widget.animalAEditar!.genealogia!.donanteSnapshot!,
                      )
                    : null);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _mostrarModalToroDonante() async {
    final resultado = await RegistrarToroDonanteModal.mostrar(
      context,
      torosDonantesService: _torosDonantesService,
    );
    if (resultado != null && mounted) {
      setState(() {
        _torosDonantes = [resultado, ..._torosDonantes];
        _toroDonante = resultado;
      });
      AppFeedback.mostrarExito(
        context: context,
        mensaje:
            'Toro donante registrado y asignado: ${resultado.nombre} (${resultado.codigoPajuela})',
      );
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
        _padreSeleccionado = null;
        _madreSeleccionada = null;
      });
      _cargarDatosEnCascada(nuevaFincaId);
      return;
    }

    if (_selectedFincaId == null && widget.fincas.isNotEmpty) {
      _selectedFincaId = widget.fincas.first.id;
      _cargarDatosEnCascada(_selectedFincaId!);
    }
  }

  @override
  void dispose() {
    _fechaNacimientoCtrl.dispose();
    _edadAniosCtrl.dispose();
    _edadMesesCtrl.dispose();
    _edadDiasCtrl.dispose();
    _areteManejoCtrl.dispose();
    _areteOficialCtrl.dispose();
    _nombreAliasCtrl.dispose();
    _pesoActualCtrl.dispose();
    _numeroPartosCtrl.dispose();
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
    GenealogiaModel? preselectGenealogia,
  }) async {
    try {
      final animales = await _animalesService.consultarInventarioRelacional();
      if (!mounted || _selectedFincaId != fincaId) return;
      setState(() {
        if (preselectGenealogia != null) {
          if (preselectGenealogia.padreId != null) {
            _padreSeleccionado = animales
                .where((a) => a.id == preselectGenealogia.padreId)
                .firstOrNull;
          }
          if (preselectGenealogia.madreId != null) {
            _madreSeleccionada = animales
                .where((a) => a.id == preselectGenealogia.madreId)
                .firstOrNull;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _animalesDeFinca = [];
        });
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
      firstDate: DateTime(1900),
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
    _numeroPartosCtrl.text = '0';
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
      _sexo = widget.sexoInicial ?? 'Hembra';
      _tipoExplotacion = 'Lecheria';
      _fechaNacimiento = DateTime.now().subtract(const Duration(days: 180));
      _fechaNacimientoExacta = true;
      _fechaNacimientoCtrl.text = Formatters.formatearFecha(_fechaNacimiento);
      _ingresarEdad = false;
      _edadAniosCtrl.clear();
      _edadMesesCtrl.clear();
      _edadDiasCtrl.clear();
      _origen = 'Nacido en la finca';
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
      _padreEsIA = false;
      _padreSeleccionado = null;
      _toroDonante = null;
      _tipoPruebaPaterna = 'Visual / Monta natural';
      _madreEsInterna = true;
      _madreSeleccionada = null;
      _fotos.clear();
      _uploadProgress = 0.0;
      _uploadStatus = null;
    });
  }

  bool get _esOrigenComprado =>
      _origen == 'Comprado en subasta' || _origen == 'Otro';

  Future<void> _mostrarModalProgenitor({
    required String sexo,
    required String tituloRol,
    required void Function(AnimalModel) onAnimalRegistrado,
  }) async {
    if (_selectedFincaId == null) return;
    final resultado = await Navigator.of(context).push<AnimalModel>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Registrar $tituloRol')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AnimalForm(
              fincas: widget.fincas,
              fincaInicialId: _selectedFincaId,
              sexoInicial: sexo,
              preguntarPertenencia: true,
              onVerInventario: widget.onVerInventario,
              animalesService: _animalesService,
              torosDonantesService: _torosDonantesService,
              onAnimalCreated: (animal) => Navigator.of(context).pop(animal),
            ),
          ),
        ),
      ),
    );
    if (resultado != null && mounted) {
      onAnimalRegistrado(resultado);
      AppFeedback.mostrarExito(
        context: context,
        mensaje: 'Progenitor registrado y asignado: ${resultado.areteManejo}',
      );
    }
  }

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
      final animalId = widget.animalAEditar?.id ?? const Uuid().v4();
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
      final pesoActual = pesoTexto.isNotEmpty
          ? double.tryParse(pesoTexto)
          : null;

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
          animalId: widget.animalAEditar?.id,
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
          animalId: widget.animalAEditar?.id,
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
            loteIdOriginal: null,
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
        esExterno: _esExterno,
        id: animalId,
        codigoSistema: '', // Generado por trigger trg_generar_codigo_animal
        areteManejo: _areteManejoCtrl.text.trim(),
        areteOficial: _areteOficialCtrl.text.trim().isNotEmpty
            ? _areteOficialCtrl.text.trim()
            : null,
        nombreAlias: _nombreAliasCtrl.text.trim().isNotEmpty
            ? _nombreAliasCtrl.text.trim()
            : _areteManejoCtrl.text.trim(),
        sexo: _sexo,
        numeroPartos: _sexo == 'Hembra'
            ? int.tryParse(_numeroPartosCtrl.text) ?? 0
            : 0,
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
        potreroActual: _esExterno ? null : ubicacionAjustada.potreroActual,
        loteId: null,
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
        padreId: (_padreEsInterno && !_padreEsIA)
            ? _padreSeleccionado?.id
            : null,
        padreExternoReferencia:
            (!_padreEsInterno && !_padreEsIA) &&
                _padreExternoCtrl.text.trim().isNotEmpty
            ? _padreExternoCtrl.text.trim()
            : null,
        tipoPruebaPaterna: _tipoPruebaPaterna,
        donanteId: _padreEsIA ? _toroDonante?.id : null,
        donanteSnapshot: _padreEsIA ? _toroDonante?.toJson() : null,
        madreId: _madreEsInterna ? _madreSeleccionada?.id : null,
        madreExternaReferencia:
            !_madreEsInterna && _madreExternaCtrl.text.trim().isNotEmpty
            ? _madreExternaCtrl.text.trim()
            : null,
        tipoPruebaMaterna: _tipoPruebaPaterna,
      );

      if (widget.animalAEditar != null) {
        final a = widget.animalAEditar!;
        final actualizado = AnimalModel(
          esExterno: _esExterno,
          id: a.id,
          codigoSistema: a.codigoSistema,
          areteManejo: _areteManejoCtrl.text.trim(),
          areteOficial: _areteOficialCtrl.text.trim().isNotEmpty
              ? _areteOficialCtrl.text.trim()
              : null,
          nombreAlias: _nombreAliasCtrl.text.trim().isNotEmpty
              ? _nombreAliasCtrl.text.trim()
              : _areteManejoCtrl.text.trim(),
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
          potreroActual: _esExterno ? null : ubicacionAjustada.potreroActual,
          loteId: null,
          estadoActual: _estadoActual,
          fechaEntrada: _fechaEntrada,
          precioCompra: precioCompra,
          fechaSalida: ubicacionAjustada.fechaSalida,
          marcasHierro: marcasHierro,
          observaciones: obsFinal.isNotEmpty ? obsFinal : null,
          fotos: [..._fotosExistentes, ...urlsFotos],
          createdAt: a.createdAt,
          updatedAt: DateTime.now(),
          numeroPartos: _sexo == 'Hembra'
              ? int.tryParse(_numeroPartosCtrl.text) ?? 0
              : 0,
          genealogia: genealogia,
        );

        final guardado = await _animalesService.actualizar(actualizado);

        if (!mounted) return;
        AppFeedback.mostrarExito(
          context: context,
          mensaje:
              'Expediente del animal ${guardado.areteManejo} modificado con éxito.',
        );

        widget.onAnimalUpdated?.call(guardado);
        Navigator.of(context).pop(guardado);
        return;
      }

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
      animalActualId: widget.animalAEditar?.id,
      sexo: 'Macho',
      candidatos: _animalesDeFinca,
      todosLosAnimales: _animalesDeFinca,
    );
    final hembrasValidas = GenealogiaValidator.filtrarCandidatosValidos(
      animalActualId: widget.animalAEditar?.id,
      sexo: 'Hembra',
      candidatos: _animalesDeFinca,
      todosLosAnimales: _animalesDeFinca,
    ).where((a) => a.categoriaZootecnica == 'Vaca').toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.preguntarPertenencia)
            SwitchListTile.adaptive(
              title: const Text('¿Forma parte de la finca?'),
              subtitle: Text(
                _esExterno
                    ? 'Se guardará en Configuración > Animales externos para su genealogía.'
                    : 'Se añadirá al inventario de la finca.',
              ),
              value: !_esExterno,
              onChanged: (value) => setState(() => _esExterno = !value),
            ),

          if (widget.onVerInventario != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: widget.onVerInventario,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Ver inventario'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildHeaderBanner(),
          const SizedBox(height: 16),

          // SECCIÓN 1: IDENTIFICACIÓN Y BIOMETRÍA
          _FormSectionCard(
            title: widget.animalAEditar != null
                ? '1. Identificación y Biometría · ${widget.animalAEditar!.codigoSistema}'
                : '1. Identificación y Biometría',
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
                          Expanded(child: _buildAreteManejoField()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildAreteOficialField()),
                        ],
                      );
                    }
                    return Column(
                      children: [
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

          // SECCIÓN 2: GENÉTICA Y LINAJE (RAZA, CLASIFICACIÓN Y PROGENITORES FUSIONADOS)
          _FormSectionCard(
            title: '2. Genética y Linaje',
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
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _fechaNacimientoExacta,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    '¿Fecha de nacimiento exacta conocida?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
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
                  onChanged: (val) => setState(() {
                    _fechaNacimientoExacta = val;
                    if (val) _ingresarEdad = false;
                  }),
                ),
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
                const Divider(height: 28),
                const Row(
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Linaje y Progenitores',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_sexo == 'Hembra') ...[
                  CustomTextField.numeric(
                    label: 'Número de partos',
                    controller: _numeroPartosCtrl,
                    allowDecimals: false,
                    helperText:
                        'Una hembra con al menos un parto se clasifica como vaca.',
                    validator: (value) {
                      final partos = int.tryParse(value ?? '');
                      if (partos == null || partos < 0) {
                        return 'Ingrese un número válido';
                      }
                      if (widget.sexoInicial == 'Hembra' && partos == 0) {
                        return 'La madre debe tener al menos un parto para registrarse como vaca';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                CustomFormDropdown<String>(
                  label: 'Tipo de nacimiento',
                  value: _tipoPruebaPaterna,
                  items: const [
                    DropdownMenuItem(
                      value: 'Visual / Monta natural',
                      child: Text('Monta Natural'),
                    ),
                    DropdownMenuItem(
                      value: 'Inseminacion',
                      child: Text('Inseminación artificial'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencia de embriones',
                      child: Text('Transferencia de embriones'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _tipoPruebaPaterna = value;
                      _padreEsIA = value == 'Inseminacion';
                      _padreEsInterno = !_padreEsIA;
                      _madreEsInterna = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _ParentescoSelectorCard(
                  tituloRol: 'Padre (Reproductor / Toro)',
                  iconoRol: Icons.male_rounded,
                  esInterno: _padreEsInterno,
                  esIA: _padreEsIA,
                  candidatosInternos: machosValidos,
                  animalSeleccionado: _padreSeleccionado,
                  referenciaExternaCtrl: _padreExternoCtrl,
                  referenciaExternaFocus: _padreExternoFocus,
                  hintExterno:
                      'Ej. Pajuela Toro Gyr Sansão #BR-9942 / Catálogo ABS',
                  fincaSeleccionada: _selectedFincaId != null,
                  toroDonante: _toroDonante,
                  todosDonantes: _torosDonantes,
                  onAnimalSelected: (animal) {
                    setState(() => _padreSeleccionado = animal);
                  },
                  onToroDonante: (toro) {
                    setState(() => _toroDonante = toro);
                  },
                  onRegistrarNuevo: () => _mostrarModalProgenitor(
                    sexo: 'Macho',
                    tituloRol: 'Padre (Reproductor / Toro)',
                    onAnimalRegistrado: (nuevo) {
                      setState(() {
                        _animalesDeFinca = [nuevo, ..._animalesDeFinca];
                        _padreSeleccionado = nuevo;
                        _padreEsInterno = true;
                      });
                    },
                  ),
                  onRegistrarToroNuevo: _mostrarModalToroDonante,
                ),
                const SizedBox(height: 16),
                _ParentescoSelectorCard(
                  tituloRol: 'Madre (Vaca / Donadora)',
                  iconoRol: Icons.female_rounded,
                  esInterno: _madreEsInterna,
                  candidatosInternos: hembrasValidas,
                  animalSeleccionado: _madreSeleccionada,
                  referenciaExternaCtrl: _madreExternaCtrl,
                  referenciaExternaFocus: _madreExternaFocus,
                  hintExterno: 'Ej. Donadora Embriones Hacienda El Vergel #405',
                  fincaSeleccionada: _selectedFincaId != null,
                  onAnimalSelected: (animal) {
                    setState(() => _madreSeleccionada = animal);
                  },
                  onRegistrarNuevo: () => _mostrarModalProgenitor(
                    sexo: 'Hembra',
                    tituloRol: 'Madre (Vaca / Donadora)',
                    onAnimalRegistrado: (nuevo) {
                      setState(() {
                        _animalesDeFinca = [nuevo, ..._animalesDeFinca];
                        _madreSeleccionada = nuevo;
                        _madreEsInterna = true;
                      });
                    },
                  ),
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
                _buildFincaCascadeDropdown(),
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
                            'Se inhabilita el potrero, y se requiere fecha de salida.',
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
                  hint:
                      'Iniciales o figura del hierro criador / propietario anterior',
                  controller: _hierroObsCtrl,
                  focusNode: _hierroObsFocus,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 5: OBSERVACIONES Y FOTOGRAFÍAS
          _FormSectionCard(
            title: '5. Observaciones y Registro Fotográfico',
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
                if (_fotosExistentes.isNotEmpty) ...[
                  const Text(
                    'Fotografías Actuales Guardadas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < _fotosExistentes.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _fotosExistentes[i],
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 96,
                                  height: 96,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _fotosExistentes.removeAt(i);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                PhotoUploaderWidget(
                  label: _fotosExistentes.isNotEmpty
                      ? 'Añadir Nuevas Fotografías'
                      : 'Fotografías del Animal (Máx. 3)',
                  photos: _fotos,
                  maxPhotos: (3 - _fotosExistentes.length).clamp(0, 3),
                  isUploading: _isUploadingPhotos,
                  uploadProgress: _uploadProgress,
                  uploadStatusText: _uploadStatus,
                  onPhotoAdded: (photo) {
                    if (_fotos.length + _fotosExistentes.length < 3) {
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
                        onPressed: _isSaving
                            ? null
                            : () {
                                if (widget.animalAEditar != null) {
                                  _cargarDatosAnimalAEditar(
                                    widget.animalAEditar!,
                                  );
                                } else {
                                  _limpiarFormulario();
                                }
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          widget.animalAEditar != null
                              ? 'Restablecer Valores'
                              : 'Limpiar Expediente',
                        ),
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
                              ? (widget.animalAEditar != null
                                    ? 'Guardando Cambios...'
                                    : 'Guardando Expediente...')
                              : (widget.animalAEditar != null
                                    ? 'Guardar Cambios'
                                    : 'Guardar Expediente Animal'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.botonPrincipal,
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
    final esEdicion = widget.animalAEditar != null;
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(
              esEdicion ? Icons.edit_note_rounded : Icons.pets_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esEdicion
                      ? 'Modificación de Expediente Bovino · Arete ${widget.animalAEditar!.areteManejo}'
                      : 'Apertura de Expediente Individual Bovino',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esEdicion
                      ? 'Actualice los datos biométricos, de genealogía, marcas o ubicación del animal ${widget.animalAEditar!.codigoSistema}.'
                      : 'Trazabilidad genética Modo A, ubicación por finca y registro genealógico completo.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      hint: 'Ej. Marquesa / Sultán (si vacío, se usa el arete de manejo)',
      controller: _nombreAliasCtrl,
      focusNode: _nombreAliasFocus,
      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
    );
  }

  Widget _buildSexoDropdown() {
    return CustomFormDropdown<String>(
      label: 'Sexo',
      enabled: widget.sexoInicial == null,
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
          value: 'Doble Proposito',
          child: Text('Doble Propósito'),
        ),
        DropdownMenuItem(value: 'Cria', child: Text('Cría')),
        DropdownMenuItem(value: 'Ceba', child: Text('Ceba')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _tipoExplotacion = val);
      },
    );
  }

  DateTime? _leerFechaNacimiento(String? texto) {
    try {
      final fecha = DateFormat('dd/MM/yyyy').parseStrict(texto ?? '');
      final hoy = DateUtils.dateOnly(DateTime.now());
      return fecha.year >= 1900 && !fecha.isAfter(hoy) ? fecha : null;
    } catch (_) {
      return null;
    }
  }

  void _calcularNacimientoPorEdad() {
    final anios = int.tryParse(_edadAniosCtrl.text) ?? 0;
    final meses = int.tryParse(_edadMesesCtrl.text) ?? 0;
    final dias = int.tryParse(_edadDiasCtrl.text) ?? 0;
    if (anios < 0 ||
        anios > 40 ||
        meses < 0 ||
        meses > 11 ||
        dias < 0 ||
        dias > 30) {
      return;
    }
    final hoy = DateTime.now();
    final mes = DateTime(hoy.year - anios, hoy.month - meses);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
    setState(() {
      _fechaNacimiento = DateTime(
        mes.year,
        mes.month,
        hoy.day > ultimoDia ? ultimoDia : hoy.day,
      ).subtract(Duration(days: dias));
      _fechaNacimientoExacta = false;
      _fechaNacimientoCtrl.text = Formatters.formatearFecha(_fechaNacimiento);
    });
  }

  Widget _buildFechaNacimientoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ingresar edad actual'),
          value: _ingresarEdad,
          onChanged: (value) => setState(() {
            _ingresarEdad = value;
            if (value) _fechaNacimientoExacta = false;
          }),
        ),
        if (_ingresarEdad) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final campo in [
                ('Años', _edadAniosCtrl, 40),
                ('Meses', _edadMesesCtrl, 11),
                ('Días', _edadDiasCtrl, 30),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomTextField.numeric(
                      label: campo.$1,
                      controller: campo.$2,
                      allowDecimals: false,
                      validator: (value) {
                        final numero = int.tryParse(value ?? '');
                        if ((value ?? '').isNotEmpty &&
                            (numero == null ||
                                numero < 0 ||
                                numero > campo.$3)) {
                          return 'Use 0–${campo.$3}';
                        }
                        if (campo.$1 == 'Años' &&
                            [
                              _edadAniosCtrl,
                              _edadMesesCtrl,
                              _edadDiasCtrl,
                            ].every((c) => c.text.isEmpty)) {
                          return 'Ingrese la edad';
                        }
                        return null;
                      },
                      onChanged: (_) => _calcularNacimientoPorEdad(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        CustomTextField(
          label: 'Fecha de Nacimiento',
          hint: 'dd/mm/aaaa',
          controller: _fechaNacimientoCtrl,
          readOnly: _ingresarEdad,
          isRequired: true,
          keyboardType: TextInputType.datetime,
          validator: (value) => _leerFechaNacimiento(value) == null
              ? 'Ingrese una fecha válida entre 1900 y hoy (dd/mm/aaaa)'
              : null,
          onChanged: (value) {
            final fecha = _leerFechaNacimiento(value);
            if (fecha != null) setState(() => _fechaNacimiento = fecha);
          },
          suffixIcon: _ingresarEdad
              ? null
              : IconButton(
                  tooltip: 'Seleccionar en calendario',
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _seleccionarFecha(
                    initialDate: _fechaNacimiento,
                    onSelected: (fecha) => setState(() {
                      _fechaNacimiento = fecha;
                      _fechaNacimientoCtrl.text = Formatters.formatearFecha(
                        fecha,
                      );
                    }),
                  ),
                ),
        ),
      ],
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
        DropdownMenuItem(
          value: 'Arriendo',
          child: Text('Arriendo / Al aumento'),
        ),
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
          return Validators.requerido(val, 'Especifique el detalle del origen');
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
              label: const Text('Nueva finca'),
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
          _padreSeleccionado = null;
          _madreSeleccionada = null;
        });
        _cargarDatosEnCascada(nuevoFincaId);
      },
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
  final bool isRequired;
  final VoidCallback onTap;

  const _DateSelectorField({
    required this.label,
    required this.valueText,
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
  final bool esIA;
  final List<AnimalModel> candidatosInternos;
  final AnimalModel? animalSeleccionado;
  final TextEditingController referenciaExternaCtrl;
  final FocusNode referenciaExternaFocus;
  final String hintExterno;
  final bool fincaSeleccionada;
  final ValueChanged<AnimalModel?> onAnimalSelected;
  final VoidCallback? onRegistrarNuevo;
  // IA fields
  final ToroDonanteModel? toroDonante;
  final List<ToroDonanteModel> todosDonantes;
  final ValueChanged<ToroDonanteModel?>? onToroDonante;
  final VoidCallback? onRegistrarToroNuevo;

  const _ParentescoSelectorCard({
    required this.tituloRol,
    required this.iconoRol,
    required this.esInterno,
    required this.candidatosInternos,
    required this.animalSeleccionado,
    required this.referenciaExternaCtrl,
    required this.referenciaExternaFocus,
    required this.hintExterno,
    required this.fincaSeleccionada,
    required this.onAnimalSelected,
    this.esIA = false,
    this.onRegistrarNuevo,
    this.toroDonante,
    this.todosDonantes = const [],
    this.onToroDonante,
    this.onRegistrarToroNuevo,
  });

  @override
  State<_ParentescoSelectorCard> createState() =>
      _ParentescoSelectorCardState();
}

class _ParentescoSelectorCardState extends State<_ParentescoSelectorCard> {
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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.onRegistrarNuevo != null &&
                        widget.fincaSeleccionada &&
                        !widget.esIA)
                      OutlinedButton.icon(
                        onPressed: widget.onRegistrarNuevo,
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('Registrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final selectorPrincipal = widget.esIA
                    ? _buildSelectorIA()
                    : (widget.esInterno
                          ? _buildBuscadorInterno()
                          : CustomTextField(
                              label: 'Referencia o Código de Catálogo Externo',
                              hint: widget.hintExterno,
                              controller: widget.referenciaExternaCtrl,
                              focusNode: widget.referenciaExternaFocus,
                              prefixIcon: const Icon(
                                Icons.science_outlined,
                                size: 19,
                              ),
                            ));

                return selectorPrincipal;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscadorInterno() {
    return CustomFormDropdown<String>(
      label: widget.iconoRol == Icons.female_rounded
          ? 'Seleccionar madre (vaca)'
          : 'Seleccionar padre',
      value: widget.animalSeleccionado?.id,
      enabled: widget.fincaSeleccionada,
      hint: widget.candidatosInternos.isEmpty
          ? 'Sin progenitores disponibles'
          : 'Seleccione un progenitor',
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('Sin asignar')),
        ...widget.candidatosInternos.map(
          (a) => DropdownMenuItem(
            value: a.id,
            child: Text(
              '${a.areteManejo} · ${a.nombreAlias ?? a.codigoSistema}${a.esExterno ? " (Externo)" : ""}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (id) => widget.onAnimalSelected(
        widget.candidatosInternos.where((a) => a.id == id).firstOrNull,
      ),
    );
  }

  Widget _buildSelectorIA() {
    if (!widget.fincaSeleccionada) {
      return const Text(
        'Seleccione una finca primero para registrar o asignar un toro donante.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    final seleccionado = widget.toroDonante;
    if (seleccionado != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seleccionado.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Código pajuela: ${seleccionado.codigoPajuela}'
                    '${seleccionado.raza.isNotEmpty ? " · ${seleccionado.raza}" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cambiar toro donante',
              onPressed: () => widget.onToroDonante?.call(null),
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormDropdown<String>(
          label: 'Toro Donante / Pajuela',
          value: widget.toroDonante?.id,
          hint: widget.todosDonantes.isEmpty
              ? 'Sin donantes registrados'
              : 'Seleccionar donante',
          prefixIcon: const Icon(Icons.science_outlined, size: 19),
          items: widget.todosDonantes
              .map(
                (t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(t.etiquetaDisplay),
                ),
              )
              .toList(),
          onChanged: (id) => widget.onToroDonante?.call(
            widget.todosDonantes.where((t) => t.id == id).firstOrNull,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onRegistrarToroNuevo,
          icon: const Icon(Icons.add_rounded, size: 15),
          label: const Text('Registrar nuevo toro donante'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
