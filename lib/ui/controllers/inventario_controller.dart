import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/animal_model.dart';
import '../../data/models/finca_model.dart';
import '../../data/models/lote_model.dart';
import '../../data/services/animales_service.dart';
import '../../data/services/fincas_service.dart';
import '../../data/services/lotes_service.dart';

enum InventarioSeccion { fincas, lotes, animales }

enum FiltroGenetico { todos, razaPura, cruces }

class InventarioController extends ChangeNotifier {
  final FincasService _fincasService;
  final LotesService _lotesService;
  final AnimalesService _animalesService;

  InventarioController({
    FincasService? fincasService,
    LotesService? lotesService,
    AnimalesService? animalesService,
  })  : _fincasService = fincasService ?? FincasService(),
        _lotesService = lotesService ?? LotesService(),
        _animalesService = animalesService ?? AnimalesService();

  // Sección activa
  InventarioSeccion _seccionActiva = InventarioSeccion.animales;
  InventarioSeccion get seccionActiva => _seccionActiva;

  // Datos maestros cargados desde Supabase
  List<FincaModel> _allFincas = [];
  List<LoteModel> _allLotes = [];
  List<AnimalModel> _allAnimales = [];

  List<FincaModel> get allFincas => _allFincas;
  List<LoteModel> get allLotes => _allLotes;
  List<AnimalModel> get allAnimales => _allAnimales;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorConexion;
  String? get errorConexion => _errorConexion;

  // Búsqueda global superior
  String _busquedaGlobal = '';
  String get busquedaGlobal => _busquedaGlobal;

  // --- Filtros de Fincas ---
  String? _fincaEstado;
  final Set<String> _fincaFuentesAgua = {};
  double? _fincaMinHectareas;
  double? _fincaMaxHectareas;

  String? get fincaEstado => _fincaEstado;
  Set<String> get fincaFuentesAgua => Set.unmodifiable(_fincaFuentesAgua);
  double? get fincaMinHectareas => _fincaMinHectareas;
  double? get fincaMaxHectareas => _fincaMaxHectareas;

  // --- Filtros de Lotes ---
  String? _loteFincaId;
  String? _loteProposito;
  String? _loteEstado;

  String? get loteFincaId => _loteFincaId;
  String? get loteProposito => _loteProposito;
  String? get loteEstado => _loteEstado;

  // --- Filtros de Animales ---
  String _animalBusquedaEspecifica = '';
  String? _animalFincaId;
  String? _animalLoteId;
  String? _animalSexo;
  String? _animalTipoExplotacion;
  String? _animalEstado;
  FiltroGenetico _animalFiltroGenetico = FiltroGenetico.todos;
  String? _animalRazaPuraNombre;

  String get animalBusquedaEspecifica => _animalBusquedaEspecifica;
  String? get animalFincaId => _animalFincaId;
  String? get animalLoteId => _animalLoteId;
  String? get animalSexo => _animalSexo;
  String? get animalTipoExplotacion => _animalTipoExplotacion;
  String? get animalEstado => _animalEstado;
  FiltroGenetico get animalFiltroGenetico => _animalFiltroGenetico;
  String? get animalRazaPuraNombre => _animalRazaPuraNombre;

  // --- Ordenamiento y Paginación ---
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;
  int _rowsPerPage = 10;

  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;

  // --- Expediente activo en el Drawer Derecho ---
  FincaModel? _selectedFinca;
  LoteModel? _selectedLote;
  AnimalModel? _selectedAnimal;
  final List<AnimalModel> _historialAnimalesDrawer = [];

  FincaModel? get selectedFinca => _selectedFinca;
  LoteModel? get selectedLote => _selectedLote;
  AnimalModel? get selectedAnimal => _selectedAnimal;
  List<AnimalModel> get historialAnimalesDrawer =>
      List.unmodifiable(_historialAnimalesDrawer);

  bool get isDrawerOpen =>
      _selectedFinca != null ||
      _selectedLote != null ||
      _selectedAnimal != null;

  // Suscripciones Realtime
  StreamSubscription<dynamic>? _subFincas;
  StreamSubscription<dynamic>? _subLotes;
  StreamSubscription<dynamic>? _subAnimales;
  Timer? _debounceRealtime;
  bool _realtimeActivo = false;
  bool get realtimeActivo => _realtimeActivo;

  Future<void> inicializar({bool suscribirRealtime = true}) async {
    await cargarInventarioCompleto();
    if (suscribirRealtime && _errorConexion == null) {
      _iniciarSuscripcionesRealtime();
    }
  }

  void _iniciarSuscripcionesRealtime() {
    _cancelarRealtime();
    try {
      _subFincas = _fincasService.streamCambios().listen(
            (_) => _programarRecargaSuave(),
            onError: (_) {},
          );
      _subLotes = _lotesService.streamCambios().listen(
            (_) => _programarRecargaSuave(),
            onError: (_) {},
          );
      _subAnimales = _animalesService.streamCambios().listen(
            (_) => _programarRecargaSuave(),
            onError: (_) {},
          );
      _realtimeActivo = true;
      notifyListeners();
    } catch (_) {
      _realtimeActivo = false;
    }
  }

  void _programarRecargaSuave() {
    _debounceRealtime?.cancel();
    _debounceRealtime = Timer(const Duration(milliseconds: 500), () {
      cargarInventarioCompleto(silencioso: true);
    });
  }

  void _cancelarRealtime() {
    _debounceRealtime?.cancel();
    _subFincas?.cancel();
    _subLotes?.cancel();
    _subAnimales?.cancel();
    _subFincas = null;
    _subLotes = null;
    _subAnimales = null;
    _realtimeActivo = false;
  }

  Future<void> cargarInventarioCompleto({bool silencioso = false}) async {
    if (!silencioso) {
      _isLoading = true;
      _errorConexion = null;
      notifyListeners();
    }

    try {
      final resultados = await Future.wait([
        _fincasService.consultarInventario(),
        _lotesService.consultarInventario(),
        _animalesService.consultarInventarioRelacional(),
      ]);

      _allFincas = resultados[0] as List<FincaModel>;
      _allLotes = resultados[1] as List<LoteModel>;
      _allAnimales = resultados[2] as List<AnimalModel>;
      _errorConexion = null;

      // Refrescar selección activa del drawer si sigue abierta
      if (_selectedFinca != null) {
        _selectedFinca = _allFincas
                .where((f) => f.id == _selectedFinca!.id)
                .firstOrNull ??
            _selectedFinca;
      }
      if (_selectedLote != null) {
        _selectedLote = _allLotes
                .where((l) => l.id == _selectedLote!.id)
                .firstOrNull ??
            _selectedLote;
      }
      if (_selectedAnimal != null) {
        _selectedAnimal = _allAnimales
                .where((a) => a.id == _selectedAnimal!.id)
                .firstOrNull ??
            _selectedAnimal;
      }
    } catch (e) {
      _errorConexion =
          'Sin conexión activa a Supabase. Configura SUPABASE_URL y SUPABASE_ANON_KEY en .env.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Recarga Optimista tras altas en Pantalla 1 ---
  void registrarFincaOptimista(FincaModel finca) {
    _allFincas = [finca, ..._allFincas.where((f) => f.id != finca.id)];
    notifyListeners();
  }

  void registrarLoteOptimista(LoteModel lote) {
    final finca = _allFincas.where((f) => f.id == lote.fincaId).firstOrNull;
    final enriquecido = lote.copyWith(
      fincaNombre: lote.fincaNombre ?? finca?.nombre,
      fincaIdentificador: lote.fincaIdentificador ?? finca?.identificador,
    );
    _allLotes = [enriquecido, ..._allLotes.where((l) => l.id != lote.id)];
    notifyListeners();
  }

  void registrarAnimalOptimista(AnimalModel animal) {
    final finca = _allFincas.where((f) => f.id == animal.fincaId).firstOrNull;
    final lote = _allLotes.where((l) => l.id == animal.loteId).firstOrNull;
    final enriquecido = animal.copyWith(
      fincaNombre: animal.fincaNombre ?? finca?.nombre,
      fincaIdentificador: animal.fincaIdentificador ?? finca?.identificador,
      loteNombre: animal.loteNombre ?? lote?.nombre,
      loteIdentificador: animal.loteIdentificador ?? lote?.identificador,
    );
    _allAnimales = [
      enriquecido,
      ..._allAnimales.where((a) => a.id != animal.id),
    ];
    notifyListeners();
  }

  void actualizarAnimalOptimista(AnimalModel animal) {
    final finca = _allFincas.where((f) => f.id == animal.fincaId).firstOrNull;
    final lote = animal.loteId != null
        ? _allLotes.where((l) => l.id == animal.loteId).firstOrNull
        : null;

    final enriquecido = AnimalModel(
      id: animal.id,
      codigoSistema: animal.codigoSistema,
      areteManejo: animal.areteManejo,
      areteOficial: animal.areteOficial,
      nombreAlias: animal.nombreAlias,
      sexo: animal.sexo,
      pesoActual: animal.pesoActual,
      esRazaPura: animal.esRazaPura,
      razaPuraNombre: animal.razaPuraNombre,
      composicionCruces: animal.composicionCruces,
      razaEtiquetaDisplay: animal.razaEtiquetaDisplay,
      tipoExplotacion: animal.tipoExplotacion,
      fechaNacimiento: animal.fechaNacimiento,
      fechaNacimientoExacta: animal.fechaNacimientoExacta,
      origen: animal.origen,
      origenOtroDetalle: animal.origenOtroDetalle,
      fincaId: animal.fincaId,
      potreroActual: animal.potreroActual,
      loteId: animal.loteId,
      estadoActual: animal.estadoActual,
      fechaEntrada: animal.fechaEntrada,
      precioCompra: animal.precioCompra,
      fechaSalida: animal.fechaSalida,
      marcasHierro: animal.marcasHierro,
      observaciones: animal.observaciones,
      fotos: animal.fotos,
      createdAt: animal.createdAt,
      updatedAt: animal.updatedAt,
      numeroPartos: animal.numeroPartos,
      fincaNombre: animal.fincaNombre ?? finca?.nombre,
      fincaIdentificador: animal.fincaIdentificador ?? finca?.identificador,
      loteNombre: lote?.nombre,
      loteIdentificador: lote?.identificador,
      genealogia: animal.genealogia,
    );

    final existe = _allAnimales.any((a) => a.id == animal.id);
    if (existe) {
      _allAnimales =
          _allAnimales.map((a) => a.id == animal.id ? enriquecido : a).toList();
    } else {
      _allAnimales = [enriquecido, ..._allAnimales];
    }
    notifyListeners();
  }

  // --- Cambio de sección y búsqueda ---
  void cambiarSeccion(InventarioSeccion nueva) {
    if (_seccionActiva == nueva) return;
    _seccionActiva = nueva;
    _sortColumnIndex = 0;
    _sortAscending = true;
    _currentPage = 0;
    cerrarDrawer();
    notifyListeners();
  }

  void actualizarBusquedaGlobal(String valor) {
    _busquedaGlobal = valor;
    _currentPage = 0;
    notifyListeners();
  }

  // --- Mutadores de Filtros: Fincas ---
  void setFincaEstado(String? valor) {
    _fincaEstado = valor;
    _currentPage = 0;
    notifyListeners();
  }

  void toggleFincaFuenteAgua(String fuente) {
    if (_fincaFuentesAgua.contains(fuente)) {
      _fincaFuentesAgua.remove(fuente);
    } else {
      _fincaFuentesAgua.add(fuente);
    }
    _currentPage = 0;
    notifyListeners();
  }

  void setFincaRangoHectareas({double? min, double? max}) {
    _fincaMinHectareas = min;
    _fincaMaxHectareas = max;
    _currentPage = 0;
    notifyListeners();
  }

  // --- Mutadores de Filtros: Lotes ---
  void setLoteFincaId(String? fincaId) {
    _loteFincaId = fincaId;
    _currentPage = 0;
    notifyListeners();
  }

  void setLoteProposito(String? proposito) {
    _loteProposito = proposito;
    _currentPage = 0;
    notifyListeners();
  }

  void setLoteEstado(String? estado) {
    _loteEstado = estado;
    _currentPage = 0;
    notifyListeners();
  }

  // --- Mutadores de Filtros: Animales ---
  void setAnimalBusquedaEspecifica(String valor) {
    _animalBusquedaEspecifica = valor;
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalFincaId(String? fincaId) {
    _animalFincaId = fincaId;
    if (fincaId != null && _animalLoteId != null) {
      final pertenece = _allLotes.any(
        (l) => l.id == _animalLoteId && l.fincaId == fincaId,
      );
      if (!pertenece) _animalLoteId = null;
    }
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalLoteId(String? loteId) {
    _animalLoteId = loteId;
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalSexo(String? sexo) {
    _animalSexo = sexo;
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalTipoExplotacion(String? tipo) {
    _animalTipoExplotacion = tipo;
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalEstado(String? estado) {
    _animalEstado = estado;
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalFiltroGenetico(FiltroGenetico filtro) {
    _animalFiltroGenetico = filtro;
    if (filtro != FiltroGenetico.razaPura) {
      _animalRazaPuraNombre = null;
    }
    _currentPage = 0;
    notifyListeners();
  }

  void setAnimalRazaPuraNombre(String? raza) {
    _animalRazaPuraNombre = raza;
    _currentPage = 0;
    notifyListeners();
  }

  void limpiarFiltrosActivos() {
    _busquedaGlobal = '';
    switch (_seccionActiva) {
      case InventarioSeccion.fincas:
        _fincaEstado = null;
        _fincaFuentesAgua.clear();
        _fincaMinHectareas = null;
        _fincaMaxHectareas = null;
      case InventarioSeccion.lotes:
        _loteFincaId = null;
        _loteProposito = null;
        _loteEstado = null;
      case InventarioSeccion.animales:
        _animalBusquedaEspecifica = '';
        _animalFincaId = null;
        _animalLoteId = null;
        _animalSexo = null;
        _animalTipoExplotacion = null;
        _animalEstado = null;
        _animalFiltroGenetico = FiltroGenetico.todos;
        _animalRazaPuraNombre = null;
    }
    _currentPage = 0;
    notifyListeners();
  }

  bool get tieneFiltrosAplicados {
    if (_busquedaGlobal.trim().isNotEmpty) return true;
    switch (_seccionActiva) {
      case InventarioSeccion.fincas:
        return _fincaEstado != null ||
            _fincaFuentesAgua.isNotEmpty ||
            _fincaMinHectareas != null ||
            _fincaMaxHectareas != null;
      case InventarioSeccion.lotes:
        return _loteFincaId != null ||
            _loteProposito != null ||
            _loteEstado != null;
      case InventarioSeccion.animales:
        return _animalBusquedaEspecifica.trim().isNotEmpty ||
            _animalFincaId != null ||
            _animalLoteId != null ||
            _animalSexo != null ||
            _animalTipoExplotacion != null ||
            _animalEstado != null ||
            _animalFiltroGenetico != FiltroGenetico.todos ||
            _animalRazaPuraNombre != null;
    }
  }

  // --- Listas Filtradas y Ordenadas ---
  List<FincaModel> get fincasFiltradas {
    final q = _busquedaGlobal.trim().toLowerCase();
    final resultado = _allFincas.where((f) {
      if (_fincaEstado != null && f.estado != _fincaEstado) return false;
      if (_fincaFuentesAgua.isNotEmpty &&
          !_fincaFuentesAgua.every((agua) => f.fuentesAgua.contains(agua))) {
        return false;
      }
      if (_fincaMinHectareas != null) {
        final sup = f.superficieHectareas ?? 0;
        if (sup < _fincaMinHectareas!) return false;
      }
      if (_fincaMaxHectareas != null) {
        final sup = f.superficieHectareas ?? 0;
        if (sup > _fincaMaxHectareas!) return false;
      }
      if (q.isNotEmpty) {
        final match = f.nombre.toLowerCase().contains(q) ||
            f.identificador.toLowerCase().contains(q) ||
            (f.ubicacion ?? '').toLowerCase().contains(q) ||
            (f.observaciones ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    resultado.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.identificador.compareTo(b.identificador);
        case 1:
          cmp = a.nombre.compareTo(b.nombre);
        case 2:
          cmp = (a.ubicacion ?? '').compareTo(b.ubicacion ?? '');
        case 3:
          cmp = (a.superficieHectareas ?? 0)
              .compareTo(b.superficieHectareas ?? 0);
        case 4:
          cmp = a.estado.compareTo(b.estado);
        default:
          cmp = (a.createdAt ?? DateTime(2000))
              .compareTo(b.createdAt ?? DateTime(2000));
      }
      return _sortAscending ? cmp : -cmp;
    });

    return resultado;
  }

  List<LoteModel> get lotesFiltrados {
    final q = _busquedaGlobal.trim().toLowerCase();
    final resultado = _allLotes.where((l) {
      if (_loteFincaId != null && l.fincaId != _loteFincaId) return false;
      if (_loteProposito != null && l.propositoProductivo != _loteProposito) {
        return false;
      }
      if (_loteEstado != null && l.estado != _loteEstado) return false;
      if (q.isNotEmpty) {
        final fincaNom = nombreFincaPorId(l.fincaId).toLowerCase();
        final match = l.nombre.toLowerCase().contains(q) ||
            l.identificador.toLowerCase().contains(q) ||
            fincaNom.contains(q) ||
            l.propositoProductivo.toLowerCase().contains(q) ||
            (l.dietaAsignada ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    resultado.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.identificador.compareTo(b.identificador);
        case 1:
          cmp = a.nombre.compareTo(b.nombre);
        case 2:
          cmp = nombreFincaPorId(a.fincaId)
              .compareTo(nombreFincaPorId(b.fincaId));
        case 3:
          cmp = a.propositoProductivo.compareTo(b.propositoProductivo);
        case 4:
          cmp = a.metaGananciaPesoDiaria.compareTo(b.metaGananciaPesoDiaria);
        case 5:
          cmp = a.estado.compareTo(b.estado);
        default:
          cmp = (a.createdAt ?? DateTime(2000))
              .compareTo(b.createdAt ?? DateTime(2000));
      }
      return _sortAscending ? cmp : -cmp;
    });

    return resultado;
  }

  List<AnimalModel> get animalesFiltrados {
    final qGlobal = _busquedaGlobal.trim().toLowerCase();
    final qLocal = _animalBusquedaEspecifica.trim().toLowerCase();

    final resultado = _allAnimales.where((a) {
      if (a.esExterno) return false;
      if (_animalFincaId != null && a.fincaId != _animalFincaId) return false;
      if (_animalLoteId != null && a.loteId != _animalLoteId) return false;
      if (_animalSexo != null && a.sexo != _animalSexo) return false;
      if (_animalTipoExplotacion != null &&
          a.tipoExplotacion != _animalTipoExplotacion) {
        return false;
      }
      if (_animalEstado != null && a.estadoActual != _animalEstado) {
        return false;
      }
      if (_animalFiltroGenetico == FiltroGenetico.razaPura) {
        if (!a.esRazaPura) return false;
        if (_animalRazaPuraNombre != null &&
            _animalRazaPuraNombre!.isNotEmpty &&
            a.razaPuraNombre != _animalRazaPuraNombre) {
          return false;
        }
      } else if (_animalFiltroGenetico == FiltroGenetico.cruces) {
        if (a.esRazaPura) return false;
      }

      if (qLocal.isNotEmpty) {
        final matchLocal = a.areteManejo.toLowerCase().contains(qLocal) ||
            (a.areteOficial ?? '').toLowerCase().contains(qLocal) ||
            (a.nombreAlias ?? '').toLowerCase().contains(qLocal) ||
            a.codigoSistema.toLowerCase().contains(qLocal);
        if (!matchLocal) return false;
      }

      if (qGlobal.isNotEmpty) {
        final fincaNom = nombreFincaPorId(a.fincaId).toLowerCase();
        final loteNom = nombreLotePorId(a.loteId).toLowerCase();
        final matchGlobal = a.areteManejo.toLowerCase().contains(qGlobal) ||
            (a.areteOficial ?? '').toLowerCase().contains(qGlobal) ||
            (a.nombreAlias ?? '').toLowerCase().contains(qGlobal) ||
            a.codigoSistema.toLowerCase().contains(qGlobal) ||
            a.razaEtiquetaDisplay.toLowerCase().contains(qGlobal) ||
            fincaNom.contains(qGlobal) ||
            loteNom.contains(qGlobal) ||
            (a.potreroActual ?? '').toLowerCase().contains(qGlobal);
        if (!matchGlobal) return false;
      }

      return true;
    }).toList();

    resultado.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.codigoSistema.compareTo(b.codigoSistema);
        case 1:
          cmp = a.areteManejo.toLowerCase().compareTo(b.areteManejo.toLowerCase());
        case 2:
          cmp = (a.nombreAlias ?? '')
              .toLowerCase()
              .compareTo((b.nombreAlias ?? '').toLowerCase());
        case 3:
          cmp = a.sexo.compareTo(b.sexo);
        case 4:
          cmp = a.razaEtiquetaDisplay.compareTo(b.razaEtiquetaDisplay);
        case 5:
          cmp = (a.pesoActual ?? -1).compareTo(b.pesoActual ?? -1);
        case 6:
          cmp = nombreFincaPorId(a.fincaId)
              .compareTo(nombreFincaPorId(b.fincaId));
        case 7:
          cmp = a.estadoActual.compareTo(b.estadoActual);
        case 8:
          cmp = a.fechaEntrada.compareTo(b.fechaEntrada);
        default:
          cmp = a.fechaNacimiento.compareTo(b.fechaNacimiento);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return resultado;
  }

  int get totalResultadosCoincidentes {
    switch (_seccionActiva) {
      case InventarioSeccion.fincas:
        return fincasFiltradas.length;
      case InventarioSeccion.lotes:
        return lotesFiltrados.length;
      case InventarioSeccion.animales:
        return animalesFiltrados.length;
    }
  }

  List<LoteModel> get lotesDisponiblesParaFiltroAnimal {
    if (_animalFincaId == null) return _allLotes;
    return _allLotes.where((l) => l.fincaId == _animalFincaId).toList();
  }

  // --- Ordenamiento y Paginación ---
  void ordenarPorColumna(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _currentPage = 0;
    notifyListeners();
  }

  void cambiarPagina(int nuevaPagina) {
    _currentPage = nuevaPagina;
    notifyListeners();
  }

  void cambiarFilasPorPagina(int filas) {
    _rowsPerPage = filas;
    _currentPage = 0;
    notifyListeners();
  }

  // --- Control del Drawer Lateral Derecho ---
  void seleccionarFinca(FincaModel finca) {
    _selectedLote = null;
    _selectedAnimal = null;
    _historialAnimalesDrawer.clear();
    _selectedFinca = finca;
    notifyListeners();
  }

  void seleccionarLote(LoteModel lote) {
    _selectedFinca = null;
    _selectedAnimal = null;
    _historialAnimalesDrawer.clear();
    _selectedLote = lote;
    notifyListeners();
  }

  void seleccionarAnimal(AnimalModel animal, {bool limpiarHistorial = true}) {
    _selectedFinca = null;
    _selectedLote = null;
    if (limpiarHistorial) {
      _historialAnimalesDrawer.clear();
    }
    _selectedAnimal = animal;
    notifyListeners();
  }

  void navegarAProgenitor(String progenitorId) {
    final encontrado = buscarAnimalPorId(progenitorId);
    if (encontrado == null) return;
    if (_selectedAnimal != null) {
      _historialAnimalesDrawer.add(_selectedAnimal!);
    }
    _selectedAnimal = encontrado;
    notifyListeners();
  }

  void regresarAnimalAnteriorEnDrawer() {
    if (_historialAnimalesDrawer.isEmpty) return;
    _selectedAnimal = _historialAnimalesDrawer.removeLast();
    notifyListeners();
  }

  void cerrarDrawer() {
    _selectedFinca = null;
    _selectedLote = null;
    _selectedAnimal = null;
    _historialAnimalesDrawer.clear();
    notifyListeners();
  }

  // --- Helpers de Resolución Relacional ---
  String nombreFincaPorId(String fincaId) {
    final finca = _allFincas.where((f) => f.id == fincaId).firstOrNull;
    return finca?.nombre ?? 'Finca no especificada';
  }

  String nombreLotePorId(String? loteId) {
    if (loteId == null || loteId.isEmpty) return 'Sin manga asignada';
    final lote = _allLotes.where((l) => l.id == loteId).firstOrNull;
    return lote?.nombre ?? 'Sin manga';
  }

  AnimalModel? buscarAnimalPorId(String? animalId) {
    if (animalId == null || animalId.isEmpty) return null;
    return _allAnimales.where((a) => a.id == animalId).firstOrNull;
  }

  // Fuerza reclasificación visual inmediata de todos los animales en memoria
  // sin recargar desde Supabase. Las categorías se recalculan via getter.
  void actualizarCategorias() => notifyListeners();

  List<LoteModel> obtenerLotesDeFinca(String fincaId) {
    return _allLotes.where((l) => l.fincaId == fincaId).toList();
  }

  List<AnimalModel> obtenerAnimalesDeFinca(String fincaId) {
    return _allAnimales.where((a) => !a.esExterno && a.fincaId == fincaId).toList();
  }

  List<AnimalModel> obtenerAnimalesDeLote(String loteId) {
    return _allAnimales.where((a) => !a.esExterno && a.loteId == loteId).toList();
  }

  @override
  void dispose() {
    _cancelarRealtime();
    super.dispose();
  }
}

