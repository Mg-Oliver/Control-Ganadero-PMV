import '../../data/models/categoria_rule_model.dart';

class CategoriaRulesValidator {
  // 8.3.2 — Coherencia de rango
  static String? validarRango(int min, int max) {
    if (min < 0) return 'La edad mínima no puede ser negativa.';
    if (max != -1 && max < min) {
      return 'La edad máxima debe ser mayor o igual a la mínima.';
    }
    if (max != -1 && max == min) {
      return 'La edad máxima debe ser mayor que la mínima (rango de al menos 1 mes).';
    }
    return null;
  }

  // 8.3.3 — Nombre no vacío
  static String? validarNombre(String nombre) {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la categoría no puede estar vacío.';
    }
    return null;
  }

  // 8.3.1 — Sin traslapes dentro del mismo sexo + tipoExplotacion (solo reglas de edad)
  static String? validarTraslapes(List<CategoriaRuleModel> reglas) {
    // Collect unique group keys: sexo|tipoExplotacion
    final groupKeys = <String>{};
    for (final r in reglas) {
      if (!r.requiereParto) {
        groupKeys.add('${r.sexo}|${r.tipoExplotacion ?? '_'}');
      }
    }

    for (final key in groupKeys) {
      final parts = key.split('|');
      final sexo = parts[0];
      final tipo = parts[1] == '_' ? null : parts[1];

      final grupo = reglas
          .where(
            (r) =>
                !r.requiereParto &&
                r.sexo == sexo &&
                r.tipoExplotacion == tipo,
          )
          .toList();

      for (int i = 0; i < grupo.length; i++) {
        for (int j = i + 1; j < grupo.length; j++) {
          if (_seSolapan(grupo[i], grupo[j])) {
            return 'Las categorías "${grupo[i].categoria}" y "${grupo[j].categoria}" '
                'tienen rangos de edad solapados para ${sexo}s. '
                'Ajuste los límites para evitar el conflicto.';
          }
        }
      }
    }
    return null;
  }

  static bool _seSolapan(CategoriaRuleModel a, CategoriaRuleModel b) {
    final aMax = a.edadMaximoMeses == -1 ? 9999 : a.edadMaximoMeses;
    final bMax = b.edadMaximoMeses == -1 ? 9999 : b.edadMaximoMeses;
    return a.edadMinimoMeses <= bMax && aMax >= b.edadMinimoMeses;
  }

  // Validación completa: nombre + rango + traslapes
  static String? validarReglaCompleta({
    required String nombre,
    required int edadMin,
    required int edadMax,
    required List<CategoriaRuleModel> reglasExistentes,
    int? indiceEdicion, // índice de la regla que se está editando (para excluirla)
  }) {
    final errNombre = validarNombre(nombre);
    if (errNombre != null) return errNombre;

    final errRango = validarRango(edadMin, edadMax);
    if (errRango != null) return errRango;

    // Construye lista simulada para detectar traslapes
    final simulada = List<CategoriaRuleModel>.from(reglasExistentes);
    if (indiceEdicion != null) simulada.removeAt(indiceEdicion);

    final errTraslape = validarTraslapes(simulada);
    return errTraslape;
  }
}
