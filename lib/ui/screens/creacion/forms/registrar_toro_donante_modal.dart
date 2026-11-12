import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/razas_catalog.dart';
import '../../../../data/models/toro_donante_model.dart';
import '../../../../data/services/toros_donantes_service.dart';

class RegistrarToroDonanteModal extends StatefulWidget {
  final TorosDonantesService? torosDonantesService;

  const RegistrarToroDonanteModal({super.key, this.torosDonantesService});

  static Future<ToroDonanteModel?> mostrar(
    BuildContext context, {
    TorosDonantesService? torosDonantesService,
  }) {
    return showDialog<ToroDonanteModel?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RegistrarToroDonanteModal(
          torosDonantesService: torosDonantesService),
    );
  }

  @override
  State<RegistrarToroDonanteModal> createState() =>
      _RegistrarToroDonanteModalState();
}

class _RegistrarToroDonanteModalState
    extends State<RegistrarToroDonanteModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  String _razaId = '';
  bool _guardando = false;

  // Controladores de genealogía (6 ancestros × 3 campos)
  final _ctrls = <String, TextEditingController>{};

  static const _ancestros = [
    ('padre', 'Padre del Donante', Icons.male_rounded),
    ('madre', 'Madre del Donante', Icons.female_rounded),
    ('abuelo_paterno', 'Abuelo Paterno', Icons.male_rounded),
    ('abuela_paterna', 'Abuela Paterna', Icons.female_rounded),
    ('abuelo_materno', 'Abuelo Materno', Icons.male_rounded),
    ('abuela_materna', 'Abuela Materna', Icons.female_rounded),
  ];

  @override
  void initState() {
    super.initState();
    for (final (key, _, _) in _ancestros) {
      _ctrls['${key}_nombre'] = TextEditingController();
      _ctrls['${key}_codigo'] = TextEditingController();
      _ctrls['${key}_raza'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  AncestroDonanteModel _ancestro(String key) => AncestroDonanteModel(
        nombre: _ctrls['${key}_nombre']!.text.trim(),
        codigo: _ctrls['${key}_codigo']!.text.trim(),
        raza: _ctrls['${key}_raza']!.text.trim(),
      );

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);

    final toro = ToroDonanteModel(
      id: '',
      nombre: _nombreCtrl.text.trim(),
      codigoPajuela: _codigoCtrl.text.trim(),
      raza: _razaId.isEmpty
          ? ''
          : RazasCatalog.razas
                  .where((r) => r.id == _razaId)
                  .firstOrNull
                  ?.nombre ??
              '',
      genealogia: GenealogiaDonanteModel(
        padre: _ancestro('padre'),
        madre: _ancestro('madre'),
        abueloPaterno: _ancestro('abuelo_paterno'),
        abuelaPaterna: _ancestro('abuela_paterna'),
        abueloMaterno: _ancestro('abuelo_materno'),
        abuelaMaterna: _ancestro('abuela_materna'),
      ),
    );

    try {
      final svc = widget.torosDonantesService ?? TorosDonantesService();
      final guardado = await svc.crear(toro);
      if (mounted) Navigator.of(context).pop(guardado);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar donante: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.science_outlined, size: 20, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Registrar Toro Donante / Pajuela',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre comercial
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _deco(
                    'Nombre comercial del toro *',
                    Icons.pets_outlined,
                    hint: 'Ej. ABS Global Manso 420',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nombre obligatorio' : null,
                ),
                const SizedBox(height: 10),
                // Código de pajuela
                TextFormField(
                  controller: _codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _deco(
                    'Código de pajuela *',
                    Icons.tag_rounded,
                    hint: 'Ej. BR-9942 / ABS-00420',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Código obligatorio' : null,
                ),
                const SizedBox(height: 10),
                // Raza del donante
                InputDecorator(
                  decoration: _deco('Raza del donante', Icons.biotech_outlined),
                  child: DropdownButton<String>(
                    value: _razaId.isEmpty ? '' : _razaId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('— Sin especificar —')),
                      ...RazasCatalog.razas.map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.nombre),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _razaId = v ?? ''),
                  ),
                ),
                const SizedBox(height: 14),
                // Genealogía acordeón
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.account_tree_outlined,
                        color: AppColors.primary, size: 20),
                    title: const Text(
                      'Genealogía del donante (opcional)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Padre, madre y 4 abuelos con nombre, código y raza',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      for (final (key, label, icon) in _ancestros) ...[
                        _AncestroCard(
                          label: label,
                          icon: icon,
                          nombreCtrl: _ctrls['${key}_nombre']!,
                          codigoCtrl: _ctrls['${key}_codigo']!,
                          razaCtrl: _ctrls['${key}_raza']!,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
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
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.botonPrincipal,
          ),
          icon: _guardando
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Registrar donante'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}

// ─── Widget compacto para un ancestro ────────────────────────────────────────

class _AncestroCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController nombreCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController razaCtrl;

  const _AncestroCard({
    required this.label,
    required this.icon,
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.razaCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _CompactField(
                    ctrl: nombreCtrl, label: 'Nombre', icon: Icons.badge_outlined),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _CompactField(
                    ctrl: codigoCtrl, label: 'Código', icon: Icons.tag_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _CompactField(
                    ctrl: razaCtrl,
                    label: 'Raza',
                    icon: Icons.biotech_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;

  const _CompactField(
      {required this.ctrl, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: Icon(icon, size: 14, color: AppColors.textSecondary),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 28, minHeight: 28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
    );
  }
}
