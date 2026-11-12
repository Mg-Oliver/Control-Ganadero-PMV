import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/utils/predio_consistency_helper.dart';
import '../../../../data/models/animal_model.dart';
import '../../../../data/services/animales_service.dart';
import '../../../controllers/inventario_controller.dart';

class EditarAnimalDialog extends StatefulWidget {
  final AnimalModel animal;
  final InventarioController controller;
  final AnimalesService? animalesService;

  const EditarAnimalDialog({
    super.key,
    required this.animal,
    required this.controller,
    this.animalesService,
  });

  @override
  State<EditarAnimalDialog> createState() => _EditarAnimalDialogState();
}

class _EditarAnimalDialogState extends State<EditarAnimalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _areteCtrl;
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _potreroCtrl;

  late String _estadoSeleccionado;
  late String _tipoExplotacionSeleccionado;
  DateTime? _fechaSalida;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _areteCtrl = TextEditingController(text: a.areteManejo);
    _aliasCtrl = TextEditingController(text: a.nombreAlias ?? '');
    _pesoCtrl = TextEditingController(
      text: a.pesoActual != null ? a.pesoActual!.toStringAsFixed(2) : '',
    );
    _potreroCtrl = TextEditingController(text: a.potreroActual ?? '');
    _estadoSeleccionado = a.estadoActual;
    _tipoExplotacionSeleccionado = a.tipoExplotacion;
    _fechaSalida = a.fechaSalida;
  }

  @override
  void dispose() {
    _areteCtrl.dispose();
    _aliasCtrl.dispose();
    _pesoCtrl.dispose();
    _potreroCtrl.dispose();
    super.dispose();
  }

  bool get _esBaja =>
      PredioConsistencyHelper.esEstadoDeBaja(_estadoSeleccionado);

  void _onEstadoChanged(String? val) {
    if (val == null) return;
    setState(() {
      _estadoSeleccionado = val;
      if (PredioConsistencyHelper.esEstadoDeBaja(val)) {
        _potreroCtrl.clear();
        _fechaSalida ??= DateTime.now();
      }
    });
  }

  AnimalModel _buildUpdatedAnimal() {
    final pesoDouble = double.tryParse(_pesoCtrl.text.trim());
    final resultado = PredioConsistencyHelper.procesarUbicacionPorEstado(
      estadoActual: _estadoSeleccionado,
      loteIdOriginal: null,
      potreroOriginal: _potreroCtrl.text.trim().isEmpty
          ? null
          : _potreroCtrl.text.trim(),
      fechaSalidaOriginal: _fechaSalida,
    );

    return AnimalModel(
      id: widget.animal.id,
      codigoSistema: widget.animal.codigoSistema,
      areteManejo: _areteCtrl.text.trim(),
      areteOficial: widget.animal.areteOficial,
      nombreAlias: _aliasCtrl.text.trim().isEmpty
          ? null
          : _aliasCtrl.text.trim(),
      sexo: widget.animal.sexo,
      pesoActual: pesoDouble,
      esRazaPura: widget.animal.esRazaPura,
      razaPuraNombre: widget.animal.razaPuraNombre,
      composicionCruces: widget.animal.composicionCruces,
      razaEtiquetaDisplay: widget.animal.razaEtiquetaDisplay,
      tipoExplotacion: _tipoExplotacionSeleccionado,
      fechaNacimiento: widget.animal.fechaNacimiento,
      fechaNacimientoExacta: widget.animal.fechaNacimientoExacta,
      origen: widget.animal.origen,
      origenOtroDetalle: widget.animal.origenOtroDetalle,
      fincaId: widget.animal.fincaId,
      potreroActual: resultado.potreroActual,
      loteId: null,
      estadoActual: _estadoSeleccionado,
      fechaEntrada: widget.animal.fechaEntrada,
      precioCompra: widget.animal.precioCompra,
      fechaSalida: resultado.fechaSalida,
      marcasHierro: widget.animal.marcasHierro,
      observaciones: widget.animal.observaciones,
      fotos: widget.animal.fotos,
      createdAt: widget.animal.createdAt,
      updatedAt: DateTime.now(),
      numeroPartos: widget.animal.numeroPartos,
      fincaNombre: widget.animal.fincaNombre,
      fincaIdentificador: widget.animal.fincaIdentificador,
      genealogia: widget.animal.genealogia,
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_esBaja && _fechaSalida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese la fecha de salida')),
      );
      return;
    }

    setState(() => _guardando = true);

    final original = widget.animal;
    final updated = _buildUpdatedAnimal();

    // Actualización optimista inmediata
    widget.controller.actualizarAnimalOptimista(updated);

    try {
      final svc = widget.animalesService ?? AnimalesService();
      await svc.actualizar(updated);

      if (mounted) {
        AppFeedback.mostrarExito(
          context: context,
          mensaje:
              'Animal ${updated.areteManejo} actualizado correctamente.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Revertir en caso de error
      widget.controller.actualizarAnimalOptimista(original);
      if (mounted) {
        setState(() => _guardando = false);
        AppFeedback.mostrarError(
          context: context,
          mensaje: 'Error al guardar. Revisa tu conexión e intenta de nuevo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arete = widget.animal.areteManejo;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editar animal · $arete',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _areteCtrl,
                  label: 'Arete de manejo',
                  icon: Icons.tag_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'El arete es obligatorio'
                          : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _aliasCtrl,
                  label: 'Nombre / Alias',
                  icon: Icons.pets_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _pesoCtrl,
                  label: 'Peso actual (kg)',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final d = double.tryParse(v.trim());
                    if (d == null || d < 0) return 'Peso inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  label: 'Tipo de explotación',
                  icon: Icons.agriculture_outlined,
                  value: _tipoExplotacionSeleccionado,
                  items: const [
                    DropdownMenuItem(
                        value: 'Lecheria', child: Text('Lechería')),
                    DropdownMenuItem(
                        value: 'Doble Proposito',
                        child: Text('Doble Propósito')),
                    DropdownMenuItem(value: 'Cria', child: Text('Cría')),
                    DropdownMenuItem(value: 'Ceba', child: Text('Ceba')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _tipoExplotacionSeleccionado = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  label: 'Estado actual',
                  icon: Icons.health_and_safety_outlined,
                  value: _estadoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                    DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
                    DropdownMenuItem(value: 'Muerto', child: Text('Muerto')),
                    DropdownMenuItem(
                        value: 'Descartado', child: Text('Descartado')),
                    DropdownMenuItem(value: 'Robado', child: Text('Robado')),
                  ],
                  onChanged: _onEstadoChanged,
                ),
                if (_esBaja) ...[
                  const SizedBox(height: 12),
                  _buildFechaSalidaTile(),
                ],
                if (!_esBaja) ...[
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _potreroCtrl,
                    label: 'Potrero actual',
                    icon: Icons.grass_outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        isDense: true,
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFechaSalidaTile() {
    final texto = _fechaSalida != null
        ? '${_fechaSalida!.day.toString().padLeft(2, '0')}/'
            '${_fechaSalida!.month.toString().padLeft(2, '0')}/'
            '${_fechaSalida!.year}'
        : 'Seleccionar fecha';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaSalida ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          helpText: 'Fecha de salida / baja',
        );
        if (picked != null) {
          setState(() => _fechaSalida = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de salida *',
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        child: Text(texto),
      ),
    );
  }
}
