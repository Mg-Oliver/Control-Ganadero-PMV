import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/animal_model.dart';
import '../../../data/models/reproduccion_model.dart';
import '../../../data/services/reproduccion_service.dart';
import '../../controllers/inventario_controller.dart';
import 'evento_reproductivo_dialog.dart';

class ReproduccionScreen extends StatefulWidget {
  final InventarioController? inventarioController;
  final ReproduccionService? service;
  const ReproduccionScreen({
    super.key,
    this.inventarioController,
    this.service,
  });
  @override
  State<ReproduccionScreen> createState() => _ReproduccionScreenState();
}

class _ReproduccionScreenState extends State<ReproduccionScreen> {
  late final ReproduccionService _service =
      widget.service ?? ReproduccionService();
  List<EventoReproductivo> _eventos = [];
  bool _demo = true, _cargando = true, _guardando = false;
  String? _error;
  String _estado = 'Todos', _busqueda = '';
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await _service.cargar();
      if (!mounted) return;
      setState(() {
        _eventos = datos;
        _demo = datos.isEmpty;
        _error = null;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'No se pudieron leer los registros guardados. Reintente antes de registrar nuevos eventos.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _registrar(
    List<CicloAnimal> ciclos, {
    String? animalId,
    TipoEventoReproductivo? tipo,
  }) async {
    final hembras = ciclos.where((c) => c.animal.sexo == 'Hembra').toList();
    if (_demo) {
      setState(() {
        _demo = false;
        _estado = 'Todos';
      });
      return;
    }
    if (hembras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero registre una hembra activa en el inventario de la finca.',
          ),
        ),
      );
      return;
    }
    final evento = await showDialog<EventoReproductivo>(
      context: context,
      builder: (_) => EventoReproductivoDialog(
        ciclos: hembras,
        animalInicialId: animalId,
        tipoInicial: tipo,
      ),
    );
    if (evento == null || !mounted) return;
    setState(() => _guardando = true);
    try {
      final actualizados = [..._eventos, evento];
      await _service.guardar(actualizados);
      if (!mounted) return;
      setState(() => _eventos = actualizados);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento reproductivo guardado en este navegador.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el evento. Los registros anteriores se conservan.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _historial(CicloAnimal c) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Historial · ${c.animal.areteManejo}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado actual: ${c.estado}'),
                const SizedBox(height: 14),
                if (c.eventos.isEmpty) const Text('Sin eventos registrados.'),
                for (final e in c.eventos.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.tipo.etiqueta),
                    subtitle: Text(
                      [
                        _fecha(e.fecha),
                        if (e.metodo != null) e.metodo!,
                        if (e.estadoInicial != null) e.estadoInicial!,
                        if (e.positivo != null)
                          e.positivo!
                              ? 'Diagnóstico positivo'
                              : 'Diagnóstico negativo',
                        if (e.fechaProbableParto != null)
                          'FPP: ${_fecha(e.fechaProbableParto)}',
                        if (e.notas.isNotEmpty) e.notas,
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _fecha(DateTime? d) =>
      d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);
  Widget _panel(String titulo, Widget child) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
  Widget _estadoBadge(String estado) {
    final color = switch (estado) {
      'Gestante' => AppColors.success,
      'Seca' => const Color(0xFF7C3AED),
      'Servida' => AppColors.primary,
      'Vacía' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _alerta(
    String titulo,
    String regla,
    List<CicloAnimal> lista,
    String Function(CicloAnimal) detalle,
    Color color,
  ) => _panel(
    titulo,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          regla,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const Text(
            'Sin pendientes en esta ventana.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        for (final c in lista)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                '${c.animal.areteManejo} · ${c.animal.nombreAlias ?? c.animal.codigoSistema}',
              ),
              subtitle: Text(detalle(c)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _historial(c),
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final controller = widget.inventarioController;
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller,
        builder: (_, _) => _contenido(controller.allAnimales),
      );
    }
    return _contenido([]);
  }

  Widget _contenido(List<AnimalModel> animales) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final ejemplo = _datosEjemplo(hoy);
    final resumen = ResumenReproductivo(
      _demo ? ejemplo.$1 : animales,
      _demo ? ejemplo.$2 : _eventos,
      hoy,
    );
    final ciclos = resumen.ciclos;
    final visibles = ciclos
        .where(
          (c) =>
              (_estado == 'Todos' || c.estado == _estado) &&
              '${c.animal.areteManejo} ${c.animal.nombreAlias ?? ''} ${c.animal.codigoSistema}'
                  .toLowerCase()
                  .contains(_busqueda),
        )
        .toList();
    final kpis = [
      (
        'DEL promedio',
        _demo
            ? '154 días'
            : resumen.delPromedio == null
            ? 'Sin datos'
            : '${resumen.delPromedio!.round()} días',
        'Desde el último parto · excluye secas',
      ),
      (
        'Días abiertos',
        _demo
            ? '82 días'
            : resumen.diasAbiertosPromedio == null
            ? 'Sin datos'
            : '${resumen.diasAbiertosPromedio!.round()} días',
        'Del parto a concepción, o hasta hoy',
      ),
      (
        'Tasa de concepción',
        _demo
            ? '62%'
            : resumen.tasa() == null
            ? 'Sin datos'
            : '${resumen.tasa()!.toStringAsFixed(0)}%',
        _demo
            ? '+4 puntos · último trimestre (ejemplo)'
            : 'Positivos / servicios con diagnóstico',
      ),
      (
        'Próximos partos',
        '${resumen.proximosPartos}',
        'FPP dentro de los próximos 30 días',
      ),
      ('Celos hoy', '${resumen.celosHoy}', 'Detectados hoy y aún sin servicio'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control reproductivo del hato',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estados, servicios, gestaciones y agenda de atención',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _cargando || _guardando || _error != null
                    ? null
                    : () => _registrar(ciclos),
                icon: const Icon(Icons.add),
                label: Text(
                  _demo ? 'Usar datos de mi finca' : 'Registrar evento',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.botonPrincipal,
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Mi finca'),
                    icon: Icon(Icons.agriculture_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Ejemplo'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                ],
                selected: {_demo},
                onSelectionChanged: (s) => setState(() {
                  _demo = s.first;
                  _estado = 'Todos';
                  _busqueda = '';
                }),
              ),
              Text(
                _demo
                    ? 'Datos de demostración · no representan tu finca'
                    : 'Registros guardados solo en este navegador',
                style: TextStyle(
                  color: _demo ? AppColors.warning : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_cargando || _guardando)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.error),
              title: Text(_error!),
              trailing: TextButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ),
          if (_demo)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Indicadores de referencia proporcionados · los animales de ejemplo ilustran las alertas',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth >= 1050
                  ? 5
                  : constraints.maxWidth >= 650
                  ? 3
                  : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final k in kpis)
                    SizedBox(
                      width:
                          (constraints.maxWidth - 12 * (columnas - 1)) /
                          columnas,
                      child: _panel(
                        k.$1,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.$2,
                              style: const TextStyle(
                                fontSize: 28,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              k.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (_, constraints) {
              final efectividad = _panel(
                'Efectividad por método de concepción',
                Column(
                  children: [
                    for (var i = 0; i < metodosConcepcion.length; i++)
                      Builder(
                        builder: (_) {
                          final metodo = metodosConcepcion[i];
                          final tasa = _demo
                              ? [65.0, 58.0, 52.0, 48.0][i]
                              : resumen.tasa(metodo);
                          final n = resumen.resultados
                              .where((r) => r.metodo == metodo)
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(metodo)),
                                    Text(
                                      tasa == null
                                          ? 'Sin datos'
                                          : '${tasa.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: (tasa ?? 0) / 100,
                                    minHeight: 12,
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.border,
                                  ),
                                ),
                                if (!_demo)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '$n servicios con diagnóstico',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Text(
                      'Los servicios pendientes no se incluyen en la tasa.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
              final estados = _panel(
                'Estados reproductivos',
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final estado in [
                      ...estadosReproductivos,
                      'N/A (Macho)',
                      'Sin registro',
                    ])
                      ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: .1,
                          ),
                          child: Text(
                            '${ciclos.where((c) => c.estado == estado).length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        label: Text(estado),
                        onPressed: () => setState(() => _estado = estado),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vacía: sin gestación ni servicio activo. Servida: espera diagnóstico. Gestante: preñez confirmada. Seca: descanso productivo previo al parto.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [efectividad, const SizedBox(height: 16), estados],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: efectividad),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: estados),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Agenda y alertas operativas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, constraints) {
              final secados =
                  resumen.hembras
                      .where((c) => c.estado == 'Gestante' && c.fpp != null)
                      .toList()
                    ..sort((a, b) => a.fpp!.compareTo(b.fpp!));
              final paneles = [
                _alerta(
                  'Celos por servir',
                  'Detectados hoy · requieren atención para servicio',
                  resumen.hembras.where((c) => c.celoPorServir).toList(),
                  (c) => c.ultimo(TipoEventoReproductivo.celo)!.notas.isEmpty
                      ? 'Celo detectado hoy · sin servicio'
                      : c.ultimo(TipoEventoReproductivo.celo)!.notas,
                  AppColors.warning,
                ),
                _alerta(
                  'Diagnóstico de gestación',
                  'Ventana de atención: 30 a 45 días post-servicio',
                  resumen.hembras
                      .where((c) => c.ecografiaEnVentana || c.ecografiaVencida)
                      .toList(),
                  (c) =>
                      '${c.diasPostServicio} días post-servicio · ${c.ecografiaVencida ? "Ventana vencida" : "En ventana"}',
                  AppColors.primary,
                ),
                _alerta(
                  'Secados proyectados',
                  'Programados 60 días antes de la FPP',
                  secados,
                  (c) =>
                      '${_fecha(c.fpp!.subtract(const Duration(days: 60)))} · ${c.secadoPendiente || c.partoVencido ? "Pendiente de secado" : "Programado"}',
                  const Color(0xFF7C3AED),
                ),
                _alerta(
                  'Partos inminentes',
                  'Menos de 7 días para la FPP',
                  resumen.hembras
                      .where((c) => c.partoInminente || c.partoVencido)
                      .toList(),
                  (c) =>
                      '${c.diasGestacion == null ? '' : '${c.diasGestacion} días de gestación · '}${_fecha(c.fpp)} · ${c.partoVencido ? "FPP vencida: revisar" : "En ${c.diasParaParto} días"}',
                  AppColors.botonPrincipal,
                ),
              ];
              final cols = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in paneles)
                    SizedBox(
                      width: (constraints.maxWidth - 12 * (cols - 1)) / cols,
                      child: p,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          _panel(
            'Seguimiento por animal',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        key: ValueKey('busqueda_repro_$_demo'),
                        decoration: const InputDecoration(
                          labelText: 'Buscar animal',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            setState(() => _busqueda = v.trim().toLowerCase()),
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey(_estado),
                        initialValue: _estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'Todos',
                                  ...estadosReproductivos,
                                  'N/A (Macho)',
                                  'Sin registro',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => _estado = v ?? 'Todos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Sin animales para mostrar. Registre animales en el inventario o cambie los filtros.',
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Animal')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('DEL')),
                        DataColumn(label: Text('Días abiertos')),
                        DataColumn(label: Text('Último servicio')),
                        DataColumn(label: Text('FPP')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: visibles
                          .map(
                            (c) => DataRow(
                              onSelectChanged: (_) => _historial(c),
                              cells: [
                                DataCell(
                                  Text(
                                    '${c.animal.areteManejo} · ${c.animal.nombreAlias ?? c.animal.codigoSistema}',
                                  ),
                                ),
                                DataCell(_estadoBadge(c.estado)),
                                DataCell(Text(c.del?.toString() ?? '—')),
                                DataCell(
                                  Text(c.diasAbiertos?.toString() ?? '—'),
                                ),
                                DataCell(
                                  Text(
                                    _fecha(
                                      c
                                          .ultimo(
                                            TipoEventoReproductivo.servicio,
                                          )
                                          ?.fecha,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_fecha(c.fpp))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Ver historial',
                                        icon: const Icon(Icons.history),
                                        onPressed: () => _historial(c),
                                      ),
                                      if (!_demo && c.animal.sexo == 'Hembra')
                                        IconButton(
                                          tooltip: 'Registrar evento',
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed:
                                              _guardando || _error != null
                                              ? null
                                              : () => _registrar(
                                                  ciclos,
                                                  animalId: c.animal.id,
                                                  tipo: c.eventos.isEmpty
                                                      ? TipoEventoReproductivo
                                                            .estadoInicial
                                                      : null,
                                                ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Las alertas usan las fechas registradas. La FPP se introduce al confirmar la gestación; no se deduce una preñez a partir de un servicio.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

(List<AnimalModel>, List<EventoReproductivo>) _datosEjemplo(DateTime hoy) {
  final animales = <AnimalModel>[];
  final eventos = <EventoReproductivo>[];
  for (var i = 1; i <= 8; i++) {
    final id = 'ejemplo-$i';
    animales.add(
      AnimalModel(
        id: id,
        codigoSistema: 'EJ-$i',
        areteManejo: 'EJ-00$i',
        nombreAlias: [
          'Lucera',
          'Estrella',
          'Canela',
          'Luna',
          'Mora',
          'Nube',
          'Perla',
          'Sol',
        ][i - 1],
        sexo: 'Hembra',
        razaEtiquetaDisplay: 'Holstein',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(hoy.year - 4),
        origen: 'Otro',
        fincaId: 'ejemplo',
        fechaEntrada: DateTime(hoy.year - 2),
        numeroPartos: 1,
      ),
    );
    eventos.add(
      EventoReproductivo(
        id: 'parto-$i',
        animalId: id,
        tipo: TipoEventoReproductivo.parto,
        fecha: hoy.subtract(Duration(days: i >= 5 ? 400 : 154 + i)),
      ),
    );
    if (i <= 2) {
      eventos.add(
        EventoReproductivo(
          id: 'celo-$i',
          animalId: id,
          tipo: TipoEventoReproductivo.celo,
          fecha: hoy,
          notas: i == 1 ? 'Signos de celo intenso' : 'Moco vulvar filante',
        ),
      );
    } else if (i <= 4) {
      eventos.add(
        EventoReproductivo(
          id: 'servicio-$i',
          animalId: id,
          tipo: TipoEventoReproductivo.servicio,
          fecha: hoy.subtract(Duration(days: i == 3 ? 35 : 46)),
          metodo: metodosConcepcion[i - 3],
        ),
      );
    } else {
      final dias = {5: 2, 6: 5, 7: 24, 8: 75}[i]!;
      eventos.add(
        EventoReproductivo(
          id: 'servicio-$i',
          animalId: id,
          tipo: TipoEventoReproductivo.servicio,
          fecha: hoy.subtract(Duration(days: 283 - dias)),
          metodo: metodosConcepcion[(i - 5) % 4],
        ),
      );
      eventos.add(
        EventoReproductivo(
          id: 'diagnostico-$i',
          animalId: id,
          tipo: TipoEventoReproductivo.diagnostico,
          fecha: hoy.subtract(Duration(days: 283 - dias - 35)),
          servicioId: 'servicio-$i',
          positivo: true,
          fechaProbableParto: hoy.add(Duration(days: dias)),
        ),
      );
      if (i <= 6) {
        eventos.add(
          EventoReproductivo(
            id: 'secado-$i',
            animalId: id,
            tipo: TipoEventoReproductivo.secado,
            fecha: hoy.add(Duration(days: dias - 60)),
          ),
        );
      }
    }
  }
  return (animales, eventos);
}
