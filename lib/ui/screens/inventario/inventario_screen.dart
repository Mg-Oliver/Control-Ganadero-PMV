import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/columna_tabla.dart';
import '../../../core/services/inventario_prefs_service.dart';
import '../../controllers/inventario_controller.dart';
import 'widgets/drawer/expediente_drawer.dart';
import 'widgets/entity_card_grid.dart';
import 'widgets/entity_data_table.dart';
import 'widgets/inventario_sidebar.dart';

class InventarioScreen extends StatefulWidget {
  final VoidCallback? onVolverAlRegistro;
  final InventarioController? externalController;
  final VoidCallback? onGoToCreacion;
  final VoidCallback? onGoToCrearFinca;
  final VoidCallback? onGoToCrearManga;

  const InventarioScreen({
    super.key,
    this.externalController,
    this.onVolverAlRegistro,
    this.onGoToCreacion,
    this.onGoToCrearFinca,
    this.onGoToCrearManga,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late final InventarioController _controller;
  late final bool _ownsController;
  final _globalSearchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // 11.1 — vista activa (tarjetas / tabla)
  VistaInventario _vistaActual = VistaInventario.tarjetas;
  // 11.2/11.3 — columnas visibles en la tabla de animales
  Set<ColumnaTabla> _columnasVisibles = Set.of(kColumnasDefault);

  @override
  void initState() {
    super.initState();
    if (widget.externalController != null) {
      _controller = widget.externalController!;
      _ownsController = false;
    } else {
      _controller = InventarioController();
      _ownsController = true;
      _controller.inicializar();
    }
    _globalSearchCtrl.text = _controller.busquedaGlobal;
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final vista = await InventarioPrefsService.cargarVista();
    final columnas = await InventarioPrefsService.cargarColumnas();
    if (mounted) {
      setState(() {
        _vistaActual = vista;
        _columnasVisibles = columnas;
      });
    }
  }

  Future<void> _abrirSelectorColumnas() async {
    final resultado = await showDialog<Set<ColumnaTabla>>(
      context: context,
      builder: (_) =>
          _ColumnasSelectorDialog(columnasActivas: _columnasVisibles),
    );
    if (resultado != null && mounted) {
      setState(() => _columnasVisibles = resultado);
      InventarioPrefsService.guardarColumnas(resultado);
    }
  }

  @override
  void dispose() {
    _globalSearchCtrl.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _etiquetaSeccion(InventarioSeccion sec) {
    switch (sec) {
      case InventarioSeccion.fincas:
        return 'Fincas Registradas';
      case InventarioSeccion.lotes:
        return 'Mangas de Manejo';
      case InventarioSeccion.animales:
        return 'Catálogo General Bovino';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.busquedaGlobal.isEmpty &&
            _globalSearchCtrl.text.isNotEmpty) {
          _globalSearchCtrl.clear();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final isDesktop = totalW >= 1020;
            final drawerWidth = isDesktop
                ? math.min(430.0, math.max(340.0, totalW * 0.33))
                : math.min(440.0, totalW * 0.92);

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: AppColors.background,
              drawer: isDesktop
                  ? null
                  : Drawer(
                      width: 300,
                      child: SafeArea(
                        child: InventarioSidebar(controller: _controller),
                      ),
                    ),
              body: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // COLUMNA 1: SIDEBAR IZQUIERDO (Desktop fijo)
                      if (isDesktop) ...[
                        SizedBox(
                          width: 285,
                          child: InventarioSidebar(controller: _controller),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                      ],

                      // COLUMNA 2: ÁREA CENTRAL (Header + Tarjetas + Tabla)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.onVolverAlRegistro != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.icon(
                                    onPressed: widget.onVolverAlRegistro,
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    label: const Text('Volver al registro'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.botonPrincipal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            _buildCentralHeader(isDesktop: isDesktop),
                            if (_controller.errorConexion != null)
                              _buildConnectionBanner(
                                _controller.errorConexion!,
                              ),
                            if (_controller.isLoading)
                              const LinearProgressIndicator(
                                minHeight: 3,
                                color: AppColors.secondary,
                              ),
                            Expanded(
                              child: RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: () =>
                                    _controller.cargarInventarioCompleto(),
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(20),
                                  child:
                                      _vistaActual == VistaInventario.tarjetas
                                      ? EntityCardGrid(controller: _controller)
                                      : EntityDataTable(
                                          controller: _controller,
                                          columnasAnimalesActivas:
                                              _columnasVisibles,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // COLUMNA 3: DRAWER LATERAL DERECHO EN DESKTOP (1/3 PANTALLA)
                      if (isDesktop && _controller.isDrawerOpen) ...[
                        const VerticalDivider(width: 1, thickness: 1),
                        SizedBox(
                          width: drawerWidth,
                          child: ExpedienteDrawer(controller: _controller),
                        ),
                      ],
                    ],
                  ),

                  // DRAWER LATERAL DERECHO MODAL EN PANTALLAS ESTRECHAS / TABLET
                  if (!isDesktop && _controller.isDrawerOpen) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _controller.cerrarDrawer,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: drawerWidth,
                        height: double.infinity,
                        child: Material(
                          elevation: 12,
                          child: SafeArea(
                            child: ExpedienteDrawer(controller: _controller),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCentralHeader({required bool isDesktop}) {
    final c = _controller;

    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDesktop) ...[
                  IconButton(
                    tooltip: 'Abrir panel de secciones y filtros',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(
                      Icons.filter_list_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _etiquetaSeccion(c.seccionActiva),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${c.totalResultadosCoincidentes} registros',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (c.realtimeActivo) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message:
                                'Sincronización Realtime activa con Supabase',
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 17,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 270,
                  child: TextField(
                    controller: _globalSearchCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'Búsqueda global (código, arete, raza, finca...)',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      suffixIcon: c.busquedaGlobal.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _globalSearchCtrl.clear();
                                c.actualizarBusquedaGlobal('');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 17),
                            )
                          : null,
                      isDense: true,
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
                    onChanged: c.actualizarBusquedaGlobal,
                  ),
                ),
                // 11.1.1 — Selector de vista (Tarjetas / Tabla)
                SegmentedButton<VistaInventario>(
                  segments: const [
                    ButtonSegment(
                      value: VistaInventario.tarjetas,
                      icon: Icon(Icons.grid_view_rounded, size: 16),
                      label: Text('Tarjetas'),
                    ),
                    ButtonSegment(
                      value: VistaInventario.tabla,
                      icon: Icon(Icons.table_rows_rounded, size: 16),
                      label: Text('Tabla'),
                    ),
                  ],
                  selected: {_vistaActual},
                  onSelectionChanged: (s) {
                    setState(() => _vistaActual = s.first);
                    InventarioPrefsService.guardarVista(s.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                // 11.2.1 — Personalizar Columnas (solo tabla + animales)
                if (_vistaActual == VistaInventario.tabla &&
                    c.seccionActiva == InventarioSeccion.animales)
                  IconButton(
                    tooltip: 'Personalizar columnas',
                    onPressed: _abrirSelectorColumnas,
                    icon: const Icon(
                      Icons.view_column_outlined,
                      color: AppColors.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  tooltip: 'Sincronizar ahora con Supabase',
                  onPressed: c.isLoading
                      ? null
                      : () => c.cargarInventarioCompleto(),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                ),
                if (widget.onGoToCrearFinca != null)
                  OutlinedButton.icon(
                    onPressed: widget.onGoToCrearFinca,
                    icon: const Icon(Icons.landscape_outlined, size: 16),
                    label: const Text('+ Finca'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (widget.onGoToCrearManga != null)
                  OutlinedButton.icon(
                    onPressed: widget.onGoToCrearManga,
                    icon: const Icon(Icons.grid_view_outlined, size: 16),
                    label: const Text('+ Manga'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (widget.onGoToCreacion != null)
                  FilledButton.icon(
                    onPressed: widget.onGoToCreacion,
                    icon: const Icon(Icons.pets_rounded, size: 18),
                    label: const Text('+ Animal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.botonPrincipal,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner(String message) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 11.2 — Diálogo selector de columnas ─────────────────────────────────────

class _ColumnasSelectorDialog extends StatefulWidget {
  final Set<ColumnaTabla> columnasActivas;

  const _ColumnasSelectorDialog({required this.columnasActivas});

  @override
  State<_ColumnasSelectorDialog> createState() =>
      _ColumnasSelectorDialogState();
}

class _ColumnasSelectorDialogState extends State<_ColumnasSelectorDialog> {
  late Set<ColumnaTabla> _seleccionadas;

  @override
  void initState() {
    super.initState();
    _seleccionadas = Set.of(widget.columnasActivas);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Personalizar columnas',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 11.2.4 — Botones rápidos
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _seleccionadas = Set.of(ColumnaTabla.values),
                    ),
                    icon: const Icon(Icons.select_all_rounded, size: 16),
                    label: const Text('Seleccionar todas'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _seleccionadas = Set.of(kColumnasDefault),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Restablecer por defecto'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              // 11.2.2 — Checkboxes de columnas
              ...ColumnaTabla.values.map((col) {
                final activa = _seleccionadas.contains(col);
                return CheckboxListTile(
                  dense: true,
                  title: Text(col.label, style: const TextStyle(fontSize: 13)),
                  subtitle: col.esAnclaje
                      ? const Text(
                          'Columna fija — siempre visible',
                          style: TextStyle(fontSize: 11),
                        )
                      : null,
                  value: activa,
                  // 11.2.3 — arete es anclaje, no se puede desmarcar
                  onChanged: col.esAnclaje
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _seleccionadas.add(col);
                            } else {
                              _seleccionadas.remove(col);
                            }
                          });
                        },
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (col.esAnclaje) {
                      return AppColors.primary.withValues(alpha: 0.5);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return null;
                  }),
                  checkColor: Colors.white,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            _seleccionadas.add(ColumnaTabla.arete);
            Navigator.of(context).pop(_seleccionadas);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
