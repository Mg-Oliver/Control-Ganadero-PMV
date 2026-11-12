import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/razas_catalog.dart';
import '../../../../data/models/animal_model.dart';
import '../../../../data/services/animales_service.dart';

class RegistrarProgenitorModal extends StatefulWidget {
  final String sexo;
  final String tituloRol;
  final String fincaId;
  final String fincaNombre;
  final AnimalesService? animalesService;

  const RegistrarProgenitorModal({
    super.key,
    required this.sexo,
    required this.tituloRol,
    required this.fincaId,
    required this.fincaNombre,
    this.animalesService,
  });

  static Future<AnimalModel?> mostrar(
    BuildContext context, {
    required String sexo,
    required String tituloRol,
    required String fincaId,
    required String fincaNombre,
    AnimalesService? animalesService,
  }) {
    return showDialog<AnimalModel?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RegistrarProgenitorModal(
        sexo: sexo,
        tituloRol: tituloRol,
        fincaId: fincaId,
        fincaNombre: fincaNombre,
        animalesService: animalesService,
      ),
    );
  }

  @override
  State<RegistrarProgenitorModal> createState() =>
      _RegistrarProgenitorModalState();
}

class _RegistrarProgenitorModalState extends State<RegistrarProgenitorModal> {
  final _formKey = GlobalKey<FormState>();
  final _areteCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _etiquetaCruceCtrl = TextEditingController();

  bool _esRazaPura = true;
  String? _razaPuraId;
  DateTime _fechaNacimiento =
      DateTime.now().subtract(const Duration(days: 730)); // ~2 años aprox
  bool _guardando = false;

  static const String _idCruce = '__cruce__';

  @override
  void dispose() {
    _areteCtrl.dispose();
    _aliasCtrl.dispose();
    _etiquetaCruceCtrl.dispose();
    super.dispose();
  }

  String get _razaEtiqueta {
    if (!_esRazaPura) return _etiquetaCruceCtrl.text.trim();
    if (_razaPuraId == null) return '';
    return RazasCatalog.razas
            .where((r) => r.id == _razaPuraId)
            .firstOrNull
            ?.nombre ??
        '';
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final arete = _areteCtrl.text.trim();
    final alias = _aliasCtrl.text.trim();

    setState(() => _guardando = true);

    final animal = AnimalModel(
      id: '',
      codigoSistema: '',
      areteManejo: arete,
      nombreAlias: alias.isNotEmpty ? alias : arete,
      sexo: widget.sexo,
      esRazaPura: _esRazaPura,
      razaPuraNombre: _esRazaPura ? _razaPuraId : null,
      composicionCruces: const [],
      razaEtiquetaDisplay: _razaEtiqueta,
      tipoExplotacion: widget.sexo == 'Macho' ? 'Cria' : 'Lecheria',
      fechaNacimiento: _fechaNacimiento,
      fechaNacimientoExacta: false,
      origen: 'Nacido en la finca',
      fincaId: widget.fincaId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime.now(),
      fincaNombre: widget.fincaNombre,
    );

    try {
      final svc = widget.animalesService ?? AnimalesService();
      final guardado = await svc.registrar(animal);
      if (mounted) Navigator.of(context).pop(guardado);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.sexo == 'Macho' ? Icons.male_rounded : Icons.female_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Registrar ${widget.tituloRol}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips de contexto bloqueados
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _ContextChip(
                      icon: Icons.place_outlined,
                      label: widget.fincaNombre,
                    ),
                    _ContextChip(
                      icon: widget.sexo == 'Macho'
                          ? Icons.male_rounded
                          : Icons.female_rounded,
                      label: widget.sexo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Arete de manejo
                TextFormField(
                  controller: _areteCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _deco('Arete de manejo *', Icons.tag_rounded),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'El arete es obligatorio'
                          : null,
                ),
                const SizedBox(height: 12),
                // Nombre / Alias
                TextFormField(
                  controller: _aliasCtrl,
                  decoration: _deco(
                    'Nombre o Alias (opcional)',
                    Icons.edit_note_rounded,
                    hint: 'Si vacío, se usa el arete de manejo',
                  ),
                ),
                const SizedBox(height: 12),
                // Raza selector
                InputDecorator(
                  decoration: _deco('Raza', Icons.biotech_outlined),
                  child: DropdownButton<String>(
                    value: _esRazaPura ? (_razaPuraId ?? '') : _idCruce,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('— Sin especificar —'),
                      ),
                      const DropdownMenuItem<String>(
                        value: _idCruce,
                        child: Text('Cruce / Mestizo'),
                      ),
                      ...RazasCatalog.razas.map(
                        (r) => DropdownMenuItem<String>(
                          value: r.id,
                          child: Text(r.nombre),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        if (v == _idCruce) {
                          _esRazaPura = false;
                          _razaPuraId = null;
                        } else {
                          _esRazaPura = true;
                          _razaPuraId = v.isEmpty ? null : v;
                        }
                      });
                    },
                  ),
                ),
                if (!_esRazaPura) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _etiquetaCruceCtrl,
                    decoration: _deco(
                      'Composición del cruce',
                      Icons.science_outlined,
                      hint: 'Ej. 1/2 Holstein + 1/2 Brahman',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Fecha de nacimiento aproximada
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaNacimiento,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      helpText: 'Fecha (o fecha aproximada) de nacimiento',
                    );
                    if (picked != null) {
                      setState(() => _fechaNacimiento = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: _deco(
                      'Fecha de nacimiento (aprox.)',
                      Icons.cake_outlined,
                    ),
                    child: Text(
                      '${_fechaNacimiento.day.toString().padLeft(2, '0')}/'
                      '${_fechaNacimiento.month.toString().padLeft(2, '0')}/'
                      '${_fechaNacimiento.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Registrar'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContextChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
