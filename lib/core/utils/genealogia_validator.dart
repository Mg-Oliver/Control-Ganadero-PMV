import '../../data/models/animal_model.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.valido() => const ValidationResult(isValid: true);

  factory ValidationResult.invalido(String mensaje) =>
      ValidationResult(isValid: false, errorMessage: mensaje);
}

/// Validador de consistencia zootécnica y prevención de ciclos circulares en el árbol genealógico.
class GenealogiaValidator {
  /// Verifica si el candidato coincide con el mismo animal actual.
  static bool esMismoAnimal(String? animalId, String? candidatoId) {
    if (animalId == null || candidatoId == null) return false;
    return animalId.trim().isNotEmpty && animalId.trim() == candidatoId.trim();
  }

  /// Retorna el conjunto de IDs de todos los descendientes directos e indirectos
  /// (hijos, nietos, bisnietos...) del animal especificado, previniendo recursión infinita.
  static Set<String> obtenerDescendientesIds({
    required String animalId,
    required List<AnimalModel> todosLosAnimales,
  }) {
    final descendientes = <String>{};
    final porVisitar = <String>[animalId];

    while (porVisitar.isNotEmpty) {
      final actualId = porVisitar.removeLast();

      for (final a in todosLosAnimales) {
        final padreId = a.genealogia?.padreId;
        final madreId = a.genealogia?.madreId;

        if (padreId == actualId || madreId == actualId) {
          if (!descendientes.contains(a.id)) {
            descendientes.add(a.id);
            porVisitar.add(a.id);
          }
        }
      }
    }

    return descendientes;
  }

  /// Retorna el conjunto de IDs de todos los ancestros directos e indirectos
  /// (padres, abuelos, bisabuelos...) del animal especificado.
  static Set<String> obtenerAncestrosIds({
    required String animalId,
    required List<AnimalModel> todosLosAnimales,
  }) {
    final ancestros = <String>{};
    final mapaAnimales = {for (final a in todosLosAnimales) a.id: a};
    final porVisitar = <String>[animalId];

    while (porVisitar.isNotEmpty) {
      final actualId = porVisitar.removeLast();
      final animal = mapaAnimales[actualId];
      if (animal == null) continue;

      final padreId = animal.genealogia?.padreId;
      if (padreId != null && padreId.isNotEmpty && !ancestros.contains(padreId)) {
        ancestros.add(padreId);
        porVisitar.add(padreId);
      }

      final madreId = animal.genealogia?.madreId;
      if (madreId != null && madreId.isNotEmpty && !ancestros.contains(madreId)) {
        ancestros.add(madreId);
        porVisitar.add(madreId);
      }
    }

    return ancestros;
  }

  /// Valida si un progenitor propuesto es apto para un animal, garantizando
  /// que no sea él mismo ni uno de sus descendientes conocidos.
  static ValidationResult validarProgenitor({
    String? animalId,
    required String proposedParentId,
    required String rol,
    required List<AnimalModel> todosLosAnimales,
  }) {
    if (animalId != null && animalId.isNotEmpty) {
      if (esMismoAnimal(animalId, proposedParentId)) {
        return ValidationResult.invalido(
          'Un animal no puede ser registrado como su propio $rol.',
        );
      }

      final descendientes = obtenerDescendientesIds(
        animalId: animalId,
        todosLosAnimales: todosLosAnimales,
      );

      if (descendientes.contains(proposedParentId)) {
        return ValidationResult.invalido(
          'El animal seleccionado como $rol es un descendiente de este ejemplar. '
          'Asignarlo generaría un ciclo genealógico circular prohibido.',
        );
      }
    }

    return ValidationResult.valido();
  }

  /// Filtra la lista de animales disponibles para excluir al animal actual (si ya tiene ID)
  /// y a toda su descendencia conocida, garantizando que el usuario solo elija progenitores válidos.
  static List<AnimalModel> filtrarCandidatosValidos({
    String? animalActualId,
    required String sexo,
    required List<AnimalModel> candidatos,
    required List<AnimalModel> todosLosAnimales,
  }) {
    final descendientes = (animalActualId != null && animalActualId.isNotEmpty)
        ? obtenerDescendientesIds(
            animalId: animalActualId,
            todosLosAnimales: todosLosAnimales,
          )
        : <String>{};

    return candidatos.where((c) {
      if (c.sexo != sexo) return false;
      if (animalActualId != null && c.id == animalActualId) return false;
      if (descendientes.contains(c.id)) return false;
      return true;
    }).toList();
  }
}

