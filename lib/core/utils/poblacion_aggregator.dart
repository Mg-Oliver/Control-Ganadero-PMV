import '../../data/models/animal_model.dart';

class GrupoPoblacional {
  final String sexo;
  final String categoria;
  final int cantidad;
  final double porcentaje;

  const GrupoPoblacional({
    required this.sexo,
    required this.categoria,
    required this.cantidad,
    required this.porcentaje,
  });
}

class ResultadoAgregacion {
  final List<GrupoPoblacional> machos;
  final List<GrupoPoblacional> hembras;
  final int totalMachos;
  final int totalHembras;
  final int totalHato;

  const ResultadoAgregacion({
    required this.machos,
    required this.hembras,
    required this.totalMachos,
    required this.totalHembras,
    required this.totalHato,
  });

  bool get estaVacio => totalHato == 0;
}

class PoblacionAggregator {
  /// Agrupa los animales activos por sexo y categoría zootécnica.
  static ResultadoAgregacion agregar(List<AnimalModel> animalesActivos) {
    final machosCounts = <String, int>{};
    final hembrasCounts = <String, int>{};

    for (final a in animalesActivos) {
      final cat = a.categoriaZootecnica;
      if (a.sexo == 'Macho') {
        machosCounts[cat] = (machosCounts[cat] ?? 0) + 1;
      } else if (a.sexo == 'Hembra') {
        hembrasCounts[cat] = (hembrasCounts[cat] ?? 0) + 1;
      }
    }

    final totalMachos = machosCounts.values.fold(0, (a, b) => a + b);
    final totalHembras = hembrasCounts.values.fold(0, (a, b) => a + b);
    final total = totalMachos + totalHembras;

    List<GrupoPoblacional> toGrupos(
      Map<String, int> counts,
      String sexo,
    ) {
      final grupos = counts.entries
          .map(
            (e) => GrupoPoblacional(
              sexo: sexo,
              categoria: e.key,
              cantidad: e.value,
              porcentaje: total > 0 ? e.value / total * 100 : 0,
            ),
          )
          .toList();
      // Orden descendente por cantidad
      grupos.sort((a, b) => b.cantidad.compareTo(a.cantidad));
      return grupos;
    }

    return ResultadoAgregacion(
      machos: toGrupos(machosCounts, 'Macho'),
      hembras: toGrupos(hembrasCounts, 'Hembra'),
      totalMachos: totalMachos,
      totalHembras: totalHembras,
      totalHato: total,
    );
  }
}
