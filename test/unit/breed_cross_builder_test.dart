import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/breed_cross_calculator.dart';

void main() {
  group('BreedCrossCalculator - Cálculos Zootécnicos Modo A', () {
    test('Conversión exacta de fracciones zootécnicas a octavos de sangre', () {
      expect(BreedCrossCalculator.fraccionAOctavos('1/2'), 4);
      expect(BreedCrossCalculator.fraccionAOctavos('3/4'), 6);
      expect(BreedCrossCalculator.fraccionAOctavos('1/4'), 2);
      expect(BreedCrossCalculator.fraccionAOctavos('5/8'), 5);
      expect(BreedCrossCalculator.fraccionAOctavos('3/8'), 3);
      expect(BreedCrossCalculator.fraccionAOctavos('7/8'), 7);
      expect(BreedCrossCalculator.fraccionAOctavos('1/8'), 1);
      expect(BreedCrossCalculator.fraccionAOctavos('8/8'), 8);
    });

    test('Simplificación matemática de fracciones genéticas al mínimo común divisor', () {
      expect(BreedCrossCalculator.simplificarFraccion(2, 4), '1/2');
      expect(BreedCrossCalculator.simplificarFraccion(4, 8), '1/2');
      expect(BreedCrossCalculator.simplificarFraccion(6, 8), '3/4');
      expect(BreedCrossCalculator.simplificarFraccion(2, 8), '1/4');
      expect(BreedCrossCalculator.simplificarFraccion(8, 8), '1');
      expect(BreedCrossCalculator.simplificarFraccion(5, 8), '5/8');
    });

    test('Suma acumulativa de fracciones hasta completar la unidad zootécnica (8/8)', () {
      expect(BreedCrossCalculator.sumarOctavos(['1/2', '1/2']), 8);
      expect(BreedCrossCalculator.sumarOctavos(['3/4', '1/4']), 8);
      expect(BreedCrossCalculator.sumarOctavos(['5/8', '3/8']), 8);
      expect(BreedCrossCalculator.sumarOctavos(['1/2', '1/4', '1/4']), 8);
      expect(BreedCrossCalculator.sumarOctavos(['1/4', '1/4']), 4);
    });

    test('Generación de etiquetas zootécnicas compuestas y sintéticas (F1 / Sintéticas)', () {
      // Simbrah F1
      final simbrah = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Simmental', 'fraccion': '1/2'},
        {'raza': 'Brahman Gris', 'fraccion': '1/2'},
      ]);
      expect(simbrah, contains('Simbrah F1'));

      // Girolando F1
      final girolandoF1 = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Holstein', 'fraccion': '1/2'},
        {'raza': 'Gyr Lechero', 'fraccion': '1/2'},
      ]);
      expect(girolandoF1, contains('Girolando F1'));

      // Brangus F1
      final brangusF1 = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Angus', 'fraccion': '1/2'},
        {'raza': 'Brahman Gris', 'fraccion': '1/2'},
      ]);
      expect(brangusF1, contains('Brangus F1'));

      // Girolando 5/8
      final girolando58 = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Holstein', 'fraccion': '5/8'},
        {'raza': 'Gyr Lechero', 'fraccion': '3/8'},
      ]);
      expect(girolando58, contains('Girolando 5/8'));

      // Brangus 3/4
      final brangus34 = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Angus', 'fraccion': '3/4'},
        {'raza': 'Brahman Gris', 'fraccion': '1/4'},
      ]);
      expect(brangus34, contains('Brangus 3/4'));

      // Tri-híbrido genérico
      final triHibrido = BreedCrossCalculator.generarEtiquetaCruces([
        {'raza': 'Holstein', 'fraccion': '1/2'},
        {'raza': 'Gyr Lechero', 'fraccion': '1/4'},
        {'raza': 'Pardo Suizo', 'fraccion': '1/4'},
      ]);
      expect(triHibrido, startsWith('Cruce'));
    });
  });
}

