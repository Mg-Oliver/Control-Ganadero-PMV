import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/animal_model.dart';

/// Dos generaciones: usa el inventario completo, incluidos los animales externos.
class AnimalGenealogiaTree extends StatelessWidget {
  final AnimalModel animal;
  final AnimalModel? Function(String?)? buscarAnimal;
  const AnimalGenealogiaTree({
    super.key,
    required this.animal,
    this.buscarAnimal,
  });

  String _nombre(AnimalModel a) {
    final alias = a.nombreAlias?.trim() ?? '';
    return alias.isEmpty || alias == a.areteManejo
        ? a.areteManejo
        : '${a.areteManejo} · $alias';
  }

  String? _texto(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  ({String nombre, AnimalModel? registro}) _progenitor(
    AnimalModel? hijo,
    bool padre,
  ) {
    final g = hijo?.genealogia;
    final id = padre ? g?.padreId : g?.madreId;
    final registro = id == null ? null : buscarAnimal?.call(id);
    if (registro != null) {
      return (nombre: _nombre(registro), registro: registro);
    }
    final donante = padre ? g?.donanteSnapshot : null;
    final nombre = _texto(donante?['nombre']);
    final referencia = padre
        ? g?.padreExternoReferencia
        : g?.madreExternaReferencia;
    return (
      nombre:
          nombre ??
          _texto(referencia) ??
          (id != null ? 'Registro no disponible' : 'Sin registrar'),
      registro: null,
    );
  }

  String _abuelo(
    AnimalModel? progenitor,
    bool padre, {
    Map<String, dynamic>? donante,
  }) {
    if (progenitor != null) return _progenitor(progenitor, padre).nombre;
    final genealogia = donante?['genealogia'];
    if (genealogia is Map) {
      final ancestro = genealogia[padre ? 'padre' : 'madre'];
      if (ancestro is Map) {
        return _texto(ancestro['nombre']) ??
            _texto(ancestro['codigo']) ??
            'Sin registrar';
      }
    }
    return 'Sin registrar';
  }

  Widget _nodo(String rol, String nombre, {bool principal = false}) => Tooltip(
    message: '$rol: $nombre',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: principal
            ? AppColors.primary.withValues(alpha: .09)
            : const Color(0xFFF8FAFC),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            rol,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: principal ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _linea() =>
      Center(child: Container(width: 1, height: 10, color: AppColors.border));

  @override
  Widget build(BuildContext context) {
    final padre = _progenitor(animal, true);
    final madre = _progenitor(animal, false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            SizedBox(width: 6),
            Text(
              'Árbol genealógico',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _nodo('Animal', _nombre(animal), principal: true),
        _linea(),
        Center(child: FractionallySizedBox(
          widthFactor: .5,
          child: Container(height: 1, color: AppColors.border),
        )),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final paterna in [true, false])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: paterna ? 0 : 5,
                    right: paterna ? 5 : 0,
                  ),
                  child: Column(
                    children: [
                      _linea(),
                      _nodo(
                        paterna ? 'Padre' : 'Madre',
                        paterna ? padre.nombre : madre.nombre,
                        principal: true,
                      ),
                      _linea(),
                      FractionallySizedBox(
                        widthFactor: .5,
                        child: Container(height: 1, color: AppColors.border),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final abuelo in [true, false])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: abuelo ? 0 : 3,
                                  right: abuelo ? 3 : 0,
                                ),
                                child: Column(
                                  children: [
                                    _linea(),
                                    _nodo(
                                      abuelo
                                          ? (paterna
                                                ? 'Abuelo paterno'
                                                : 'Abuelo materno')
                                          : (paterna
                                                ? 'Abuela paterna'
                                                : 'Abuela materna'),
                                      _abuelo(
                                        paterna
                                            ? padre.registro
                                            : madre.registro,
                                        abuelo,
                                        donante: paterna
                                            ? animal.genealogia?.donanteSnapshot
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
