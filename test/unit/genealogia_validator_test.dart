import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/genealogia_validator.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';

void main() {
  group('GenealogiaValidator - Detección y Prevención de Ciclos', () {
    // Toro Abuelo
    final toroAbuelo = AnimalModel(
      id: 'toro-abuelo',
      codigoSistema: 'GAN-000001',
      areteManejo: 'TR-01',
      sexo: 'Macho',
      razaEtiquetaDisplay: 'Brahman Gris',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2018, 1, 1),
      origen: 'Nacido en la finca',
      fincaId: 'finca-1',
      fechaEntrada: DateTime(2018, 1, 1),
    );

    // Vaca Madre
    final vacaMadre = AnimalModel(
      id: 'vaca-madre',
      codigoSistema: 'GAN-000002',
      areteManejo: 'VC-02',
      sexo: 'Hembra',
      razaEtiquetaDisplay: 'Brahman Gris',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2020, 5, 10),
      origen: 'Nacido en la finca',
      fincaId: 'finca-1',
      fechaEntrada: DateTime(2020, 5, 10),
      genealogia: const GenealogiaModel(
        id: 'gen-madre',
        animalId: 'vaca-madre',
        padreId: 'toro-abuelo',
      ),
    );

    // Ternero Hijo (Nieto de toroAbuelo)
    final terneroHijo = AnimalModel(
      id: 'ternero-hijo',
      codigoSistema: 'GAN-000003',
      areteManejo: 'CR-03',
      sexo: 'Macho',
      razaEtiquetaDisplay: 'Brahman Gris',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2023, 3, 15),
      origen: 'Nacido en la finca',
      fincaId: 'finca-1',
      fechaEntrada: DateTime(2023, 3, 15),
      genealogia: const GenealogiaModel(
        id: 'gen-hijo',
        animalId: 'ternero-hijo',
        madreId: 'vaca-madre',
      ),
    );

    // Bisnieta
    final criaBisnieta = AnimalModel(
      id: 'cria-bisnieta',
      codigoSistema: 'GAN-000004',
      areteManejo: 'CR-04',
      sexo: 'Hembra',
      razaEtiquetaDisplay: 'Brahman Gris',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2025, 1, 10),
      origen: 'Nacido en la finca',
      fincaId: 'finca-1',
      fechaEntrada: DateTime(2025, 1, 10),
      genealogia: const GenealogiaModel(
        id: 'gen-bisnieta',
        animalId: 'cria-bisnieta',
        padreId: 'ternero-hijo',
      ),
    );

    final todos = [toroAbuelo, vacaMadre, terneroHijo, criaBisnieta];

    test('Rechaza que un animal sea registrado como su propio padre o madre', () {
      final res = GenealogiaValidator.validarProgenitor(
        animalId: 'toro-abuelo',
        proposedParentId: 'toro-abuelo',
        rol: 'padre',
        todosLosAnimales: todos,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('no puede ser registrado como su propio padre'));
    });

    test('Detecta descendientes directos e indirectos en cascada', () {
      final descendientesAbuelo = GenealogiaValidator.obtenerDescendientesIds(
        animalId: 'toro-abuelo',
        todosLosAnimales: todos,
      );

      expect(descendientesAbuelo, contains('vaca-madre'));
      expect(descendientesAbuelo, contains('ternero-hijo'));
      expect(descendientesAbuelo, contains('cria-bisnieta'));
      expect(descendientesAbuelo.length, 3);
    });

    test('Rechaza asignar a un hijo o bisnieto como progenitor de su ancestro', () {
      // Intentar asignar a 'ternero-hijo' como padre del 'toro-abuelo'
      final res = GenealogiaValidator.validarProgenitor(
        animalId: 'toro-abuelo',
        proposedParentId: 'ternero-hijo',
        rol: 'padre',
        todosLosAnimales: todos,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('ciclo genealógico circular prohibido'));
    });

    test('Permite una asignación legítima sin ciclo', () {
      final res = GenealogiaValidator.validarProgenitor(
        animalId: 'cria-bisnieta',
        proposedParentId: 'vaca-madre',
        rol: 'madre',
        todosLosAnimales: todos,
      );

      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
    });

    test('Filtra candidatos excluyendo al propio animal y a toda su descendencia', () {
      final machosValidosParaAbuelo =
          GenealogiaValidator.filtrarCandidatosValidos(
        animalActualId: 'toro-abuelo',
        sexo: 'Macho',
        candidatos: [toroAbuelo, terneroHijo],
        todosLosAnimales: todos,
      );

      // Ni toroAbuelo (él mismo) ni terneroHijo (su nieto) pueden ser candidatos
      expect(machosValidosParaAbuelo, isEmpty);
    });
  });
}

