/// Utilidad zootécnica para el cálculo exacto de octavos de sangre,
/// simplificación de fracciones genéticas y generación de etiquetas compuestas (Modo A).
class BreedCrossCalculator {
  /// Máximo común divisor para simplificar fracciones.
  static int mcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  /// Convierte una fracción textual en su equivalente exacto en octavos de sangre (0 a 8).
  static int fraccionAOctavos(String fraccion) {
    switch (fraccion.trim()) {
      case '1/2':
      case '2/4':
      case '4/8':
        return 4;
      case '3/4':
      case '6/8':
        return 6;
      case '1/4':
      case '2/8':
        return 2;
      case '5/8':
        return 5;
      case '3/8':
        return 3;
      case '7/8':
        return 7;
      case '1/8':
        return 1;
      case '1/1':
      case '8/8':
      case '1':
        return 8;
      default:
        return 0;
    }
  }

  /// Simplifica una fracción al mínimo denominador común (ej. 2/4 -> 1/2, 4/8 -> 1/2, 6/8 -> 3/4).
  static String simplificarFraccion(int numerador, int denominador) {
    if (denominador == 0) return '0';
    if (numerador == 0) return '0';
    final divisor = mcd(numerador, denominador);
    final numSimp = numerador ~/ divisor;
    final denSimp = denominador ~/ divisor;
    if (denSimp == 1) return '$numSimp';
    return '$numSimp/$denSimp';
  }

  /// Suma una lista de fracciones y devuelve el total de octavos.
  static int sumarOctavos(List<String> fracciones) {
    return fracciones.fold<int>(
      0,
      (acc, f) => acc + fraccionAOctavos(f),
    );
  }

  /// Genera la etiqueta zootécnica compuesta (F1 o sintética comercial)
  /// siguiendo los estándares de razas sintéticas (Simbrah, Girolando, Brangus, etc.).
  static String generarEtiquetaCruces(
    List<Map<String, String>> cruces,
  ) {
    final validas = cruces
        .where(
          (c) =>
              (c['raza']?.trim().isNotEmpty ?? false) &&
              (c['fraccion']?.trim().isNotEmpty ?? false),
        )
        .toList();

    if (validas.isEmpty) return '';

    final partes =
        validas.map((c) => '${c['fraccion']} ${c['raza']}').join(', ');

    if (validas.length == 2) {
      final r1 = validas[0]['raza']!.toLowerCase();
      final r2 = validas[1]['raza']!.toLowerCase();
      final f1 = validas[0]['fraccion']!;
      final f2 = validas[1]['fraccion']!;

      bool tieneAmbos(String a, String b) =>
          (r1.contains(a) && r2.contains(b)) ||
          (r1.contains(b) && r2.contains(a));

      if (f1 == '1/2' && f2 == '1/2') {
        if (tieneAmbos('simmental', 'brahman')) {
          return 'Simbrah F1 ($partes)';
        }
        if (tieneAmbos('holstein', 'gyr')) {
          return 'Girolando F1 ($partes)';
        }
        if (tieneAmbos('angus', 'brahman')) {
          return 'Brangus F1 ($partes)';
        }
        return 'Cruce F1 ($partes)';
      }

      if (tieneAmbos('holstein', 'gyr')) {
        final fracHolstein = r1.contains('holstein') ? f1 : f2;
        if (fracHolstein == '5/8' || fracHolstein == '3/4') {
          return 'Girolando $fracHolstein ($partes)';
        }
      }

      if (tieneAmbos('angus', 'brahman')) {
        final fracAngus = r1.contains('angus') ? f1 : f2;
        if (fracAngus == '3/4' || fracAngus == '5/8') {
          return 'Brangus $fracAngus ($partes)';
        }
      }

      if (tieneAmbos('simmental', 'brahman')) {
        final fracSimm = r1.contains('simmental') ? f1 : f2;
        if (fracSimm == '3/4' || fracSimm == '5/8') {
          return 'Simbrah $fracSimm ($partes)';
        }
      }
    }

    return 'Cruce ($partes)';
  }
}

