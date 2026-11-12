import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reproduccion_model.dart';
import '../../common/custom_form_dropdown.dart';
import '../../common/custom_text_field.dart';

class EventoReproductivoDialog extends StatefulWidget {
  final List<CicloAnimal> ciclos;
  final String? animalInicialId;
  final TipoEventoReproductivo? tipoInicial;
  const EventoReproductivoDialog({
    super.key,
    required this.ciclos,
    this.animalInicialId,
    this.tipoInicial,
  });
  @override
  State<EventoReproductivoDialog> createState() =>
      _EventoReproductivoDialogState();
}

class _EventoReproductivoDialogState extends State<EventoReproductivoDialog> {
  final _form = GlobalKey<FormState>();
  final _fecha = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final _fpp = TextEditingController();
  final _notas = TextEditingController();
  String? _animalId;
  TipoEventoReproductivo _tipo = TipoEventoReproductivo.celo;
  String _metodo = metodosConcepcion.first;
  String _estado = 'Vacía';
  bool _positivo = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _animalId = widget.animalInicialId;
    _tipo = widget.tipoInicial ?? _tipo;
  }

  @override
  void dispose() {
    _fecha.dispose();
    _fpp.dispose();
    _notas.dispose();
    super.dispose();
  }

  DateTime? _parse(String? s) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(s ?? '');
    } catch (_) {
      return null;
    }
  }

  CicloAnimal? get _ciclo =>
      widget.ciclos.where((c) => c.animal.id == _animalId).firstOrNull;
  bool get _esServicio =>
      _tipo == TipoEventoReproductivo.servicio ||
      (_tipo == TipoEventoReproductivo.estadoInicial && _estado == 'Servida');
  bool get _requiereFpp =>
      (_tipo == TipoEventoReproductivo.diagnostico && _positivo) ||
      (_tipo == TipoEventoReproductivo.estadoInicial &&
          ['Gestante', 'Seca'].contains(_estado));
  Widget _campoFecha(
    String label,
    TextEditingController ctrl, {
    bool futura = false,
  }) => CustomTextField(
    label: label,
    hint: 'dd/mm/aaaa',
    controller: ctrl,
    keyboardType: TextInputType.datetime,
    isRequired: true,
    validator: (s) {
      final fecha = _parse(s);
      if (fecha == null) return 'Use una fecha válida (dd/mm/aaaa)';
      if (!futura && fecha.isAfter(DateUtils.dateOnly(DateTime.now()))) {
        return 'El evento no puede ser futuro';
      }
      if (!futura &&
          _ciclo != null &&
          fecha.isBefore(_ciclo!.animal.fechaNacimiento)) {
        return 'La fecha es anterior al nacimiento';
      }
      if (futura &&
          _parse(_fecha.text) != null &&
          !fecha.isAfter(_parse(_fecha.text)!)) {
        return 'La FPP debe ser posterior al evento';
      }
      return null;
    },
    suffixIcon: IconButton(
      tooltip: 'Calendario',
      icon: const Icon(Icons.calendar_today_outlined),
      onPressed: () async {
        final hoy = DateTime.now();
        final limite = futura
            ? DateTime(hoy.year + 2)
            : DateUtils.dateOnly(hoy);
        final escrita = _parse(ctrl.text) ?? hoy;
        final inicial = escrita.isAfter(limite)
            ? limite
            : escrita.isBefore(DateTime(1900))
            ? DateTime(1900)
            : escrita;
        final fecha = await showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          lastDate: limite,
          initialDate: inicial,
        );
        if (fecha != null) ctrl.text = DateFormat('dd/MM/yyyy').format(fecha);
      },
    ),
  );
  void _guardar() {
    if (!_form.currentState!.validate() || _ciclo == null) return;
    final c = _ciclo!;
    final fecha = _parse(_fecha.text)!;
    String? error;
    if (c.eventos.any((e) => e.tipo == _tipo && e.fecha == fecha)) {
      error = 'Ya existe un evento de este tipo para esa fecha.';
    }
    if (_tipo == TipoEventoReproductivo.estadoInicial && c.eventos.isNotEmpty) {
      error = 'El estado inicial solo se registra antes del primer evento.';
    }
    if ((_tipo == TipoEventoReproductivo.servicio ||
            _tipo == TipoEventoReproductivo.celo) &&
        c.prenada) {
      error =
          'El animal tiene una gestación activa. Revise su historial antes de registrar este evento.';
    }
    if (_tipo == TipoEventoReproductivo.servicio && c.estado == 'Servida') {
      error =
          'Registre el diagnóstico del servicio pendiente antes de un nuevo servicio.';
    }
    if (_tipo == TipoEventoReproductivo.secado && c.estado != 'Gestante') {
      error = 'El secado requiere una gestación confirmada.';
    }
    if (_tipo == TipoEventoReproductivo.diagnostico &&
        c.servicioPendiente == null) {
      error = 'Seleccione una hembra con un servicio pendiente de diagnóstico.';
    }
    if (_tipo == TipoEventoReproductivo.diagnostico &&
        c.servicioPendiente != null &&
        fecha.isBefore(c.servicioPendiente!.fecha)) {
      error = 'El diagnóstico debe ser posterior o igual al servicio.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(
      EventoReproductivo(
        id: const Uuid().v4(),
        animalId: _animalId!,
        tipo: _esServicio ? TipoEventoReproductivo.servicio : _tipo,
        fecha: fecha,
        metodo: _esServicio ? _metodo : null,
        servicioId: _tipo == TipoEventoReproductivo.diagnostico
            ? c.servicioPendiente?.id
            : null,
        positivo: _tipo == TipoEventoReproductivo.diagnostico
            ? _positivo
            : null,
        estadoInicial: _tipo == TipoEventoReproductivo.estadoInicial
            ? _estado
            : null,
        fechaProbableParto: _requiereFpp ? _parse(_fpp.text) : null,
        notas: _notas.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar evento reproductivo'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFormDropdown<String>(
                label: 'Animal',
                value: _animalId,
                isRequired: true,
                items: widget.ciclos
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.animal.id,
                        child: Text(
                          '${c.animal.areteManejo} · ${c.animal.nombreAlias ?? c.animal.codigoSistema}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (v) => v == null ? 'Seleccione una hembra' : null,
                onChanged: (v) => setState(() {
                  _animalId = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 14),
              CustomFormDropdown<TipoEventoReproductivo>(
                label: 'Evento',
                value: _tipo,
                items: TipoEventoReproductivo.values
                    .map(
                      (t) =>
                          DropdownMenuItem(value: t, child: Text(t.etiqueta)),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) _tipo = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 14),
              _campoFecha('Fecha del evento', _fecha),
              if (_tipo == TipoEventoReproductivo.estadoInicial) ...[
                const SizedBox(height: 14),
                CustomFormDropdown<String>(
                  label: 'Estado reproductivo',
                  value: _estado,
                  items: estadosReproductivos
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _estado = v;
                  }),
                ),
              ],
              if (_esServicio) ...[
                const SizedBox(height: 14),
                CustomFormDropdown<String>(
                  label: 'Método de concepción',
                  value: _metodo,
                  items: metodosConcepcion
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _metodo = v;
                  }),
                ),
              ],
              if (_tipo == TipoEventoReproductivo.diagnostico) ...[
                const SizedBox(height: 14),
                CustomFormDropdown<bool>(
                  label: 'Resultado',
                  value: _positivo,
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Positivo · Gestante'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Negativo · Vacía'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    if (v != null) _positivo = v;
                  }),
                ),
                if (_ciclo?.servicioPendiente != null)
                  Text(
                    'Servicio: ${DateFormat('dd/MM/yyyy').format(_ciclo!.servicioPendiente!.fecha)} · ${_ciclo!.servicioPendiente!.metodo}',
                  ),
              ],
              if (_requiereFpp) ...[
                const SizedBox(height: 14),
                _campoFecha(
                  'Fecha probable de parto (FPP)',
                  _fpp,
                  futura: true,
                ),
              ],
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Observaciones',
                controller: _notas,
                maxLines: 3,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar evento')),
    ],
  );
}
