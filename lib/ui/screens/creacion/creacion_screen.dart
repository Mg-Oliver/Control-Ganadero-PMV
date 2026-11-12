import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/animal_model.dart';
import '../../../data/models/finca_model.dart';
import '../../../data/models/lote_model.dart';
import '../../../data/services/fincas_service.dart';
import 'forms/animal_form.dart';
import 'forms/finca_form.dart';
import 'forms/lote_form.dart';

enum ModuloCreacionTab { finca, lote, animal }

class CreacionScreen extends StatefulWidget {
  final ModuloCreacionTab initialTab;
  final bool showAppBar;
  final ValueChanged<FincaModel>? onFincaCreatedGlobal;
  final ValueChanged<LoteModel>? onLoteCreatedGlobal;
  final ValueChanged<AnimalModel>? onAnimalCreatedGlobal;

  const CreacionScreen({
    super.key,
    this.initialTab = ModuloCreacionTab.finca,
    this.showAppBar = true,
    this.onFincaCreatedGlobal,
    this.onLoteCreatedGlobal,
    this.onAnimalCreatedGlobal,
  });

  @override
  State<CreacionScreen> createState() => _CreacionScreenState();
}

class _CreacionScreenState extends State<CreacionScreen> {
  final _fincasService = FincasService();

  late ModuloCreacionTab _activeTab;
  ModuloCreacionTab? _returnTab;
  String? _preselectedFincaForLote;

  List<FincaModel> _fincas = [];
  bool _loadingFincas = false;
  String? _connectionWarning;

  FincaModel? _newlyCreatedFinca;
  LoteModel? _newlyCreatedLote;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _cargarFincas();
  }

  @override
  void didUpdateWidget(CreacionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _cambiarTabManual(widget.initialTab);
    }
  }

  Future<void> _cargarFincas() async {
    setState(() {
      _loadingFincas = true;
      _connectionWarning = null;
    });

    try {
      final lista = await _fincasService.obtenerTodas();
      if (!mounted) return;
      setState(() {
        _fincas = lista;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionWarning =
            'Verifica tus credenciales SUPABASE_URL y SUPABASE_ANON_KEY en el archivo .env para sincronizar datos en la nube.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingFincas = false);
      }
    }
  }

  void _cambiarTabManual(ModuloCreacionTab tab) {
    setState(() {
      _activeTab = tab;
      _returnTab = null;
    });
  }

  void _abrirCreacionTemporal(
    ModuloCreacionTab destino, {
    required ModuloCreacionTab origen,
    String? fincaId,
  }) {
    setState(() {
      _returnTab = origen;
      if (fincaId != null) {
        _preselectedFincaForLote = fincaId;
      }
      _activeTab = destino;
    });
  }

  void _handleFincaCreated(FincaModel nuevaFinca) {
    setState(() {
      _fincas = [..._fincas, nuevaFinca]
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      _newlyCreatedFinca = nuevaFinca;
      _connectionWarning = null;

      if (_returnTab != null) {
        _activeTab = _returnTab!;
        _returnTab = null;
      }
    });
    widget.onFincaCreatedGlobal?.call(nuevaFinca);
  }

  void _handleLoteCreated(LoteModel nuevoLote) {
    setState(() {
      _newlyCreatedLote = nuevoLote;
      if (_returnTab != null) {
        _activeTab = _returnTab!;
        _returnTab = null;
      }
    });
    widget.onLoteCreatedGlobal?.call(nuevoLote);
  }

  void _handleAnimalCreated(AnimalModel nuevoAnimal) {
    widget.onAnimalCreatedGlobal?.call(nuevoAnimal);
  }

  String _nombreTab(ModuloCreacionTab tab) {
    switch (tab) {
      case ModuloCreacionTab.finca:
        return 'Finca';
      case ModuloCreacionTab.lote:
        return 'Manga';
      case ModuloCreacionTab.animal:
        return 'Expediente Animal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: !widget.showAppBar
          ? null
          : AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.agriculture_rounded, size: 24),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Control Ganadero Bovino • Registro y Altas',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _loadingFincas ? null : _cargarFincas,
              icon: _loadingFincas
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              label: Text(
                '${_fincas.length} Fincas',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA SUPERIOR DE ACCESO RÁPIDO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _QuickAccessTabButton(
                      label: '+ Nueva Finca',
                      icon: Icons.landscape_outlined,
                      isSelected: _activeTab == ModuloCreacionTab.finca,
                      onTap: () => _cambiarTabManual(ModuloCreacionTab.finca),
                    ),
                    _QuickAccessTabButton(
                      label: '+ Nueva Manga',
                      icon: Icons.grid_view_rounded,
                      isSelected: _activeTab == ModuloCreacionTab.lote,
                      onTap: () => _cambiarTabManual(ModuloCreacionTab.lote),
                    ),
                    _QuickAccessTabButton(
                      label: '+ Nuevo Animal',
                      icon: Icons.pets_outlined,
                      isSelected: _activeTab == ModuloCreacionTab.animal,
                      onTap: () => _cambiarTabManual(ModuloCreacionTab.animal),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BANNER DE RETORNO ASISTIDO (CUANDO VIENE DESDE CASCADA)
          if (_returnTab != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shortcut_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Creación rápida desde ${_nombreTab(_returnTab!)}: al guardar regresarás automáticamente con el registro seleccionado.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _activeTab = _returnTab!;
                            _returnTab = null;
                          });
                        },
                        child: const Text('Volver ahora'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AVISO SI SUPABASE NO ESTÁ CONECTADO AÚN
          if (_connectionWarning != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectionWarning!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // CONTENIDO DE FORMULARIO CON PRESERVACIÓN DE ESTADO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: IndexedStack(
                    index: _activeTab.index,
                    children: [
                      FincaForm(
                        onFincaCreated: _handleFincaCreated,
                      ),
                      LoteForm(
                        fincas: _fincas,
                        isLoadingFincas: _loadingFincas,
                        preselectedFincaId: _preselectedFincaForLote,
                        newlyCreatedFinca: _newlyCreatedFinca,
                        onRefreshFincas: _cargarFincas,
                        onRequestCreateFinca: () => _abrirCreacionTemporal(
                          ModuloCreacionTab.finca,
                          origen: ModuloCreacionTab.lote,
                        ),
                        onLoteCreated: _handleLoteCreated,
                      ),
                      AnimalForm(
                        fincas: _fincas,
                        isLoadingFincas: _loadingFincas,
                        newlyCreatedFinca: _newlyCreatedFinca,
                        newlyCreatedLote: _newlyCreatedLote,
                        onRefreshFincas: _cargarFincas,
                        onRequestCreateFinca: () => _abrirCreacionTemporal(
                          ModuloCreacionTab.finca,
                          origen: ModuloCreacionTab.animal,
                        ),
                        onRequestCreateLote: (fincaId) => _abrirCreacionTemporal(
                          ModuloCreacionTab.lote,
                          origen: ModuloCreacionTab.animal,
                          fincaId: fincaId,
                        ),
                        onAnimalCreated: _handleAnimalCreated,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAccessTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

