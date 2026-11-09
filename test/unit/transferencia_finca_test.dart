import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/predio_consistency_helper.dart';
import 'package:bovino_mvp/data/models/lote_model.dart';

void main() {
  group('PredioConsistencyHelper - Transferencias y Estados de Baja', () {
    const loteFinca1 = LoteModel(
      id: 'lote-1',
      fincaId: 'finca-1',
      identificador: 'LOT-F1-01',
      nombre: 'Ordeño Finca 1',
      propositoProductivo: 'Lecheria',
    );

    const loteFinca2 = LoteModel(
      id: 'lote-2',
      fincaId: 'finca-2',
      identificador: 'LOT-F2-01',
      nombre: 'Ceba Finca 2',
      propositoProductivo: 'Ceba',
    );

    final todosLosLotes = [loteFinca1, loteFinca2];

    test('Desasocia inmediatamente el lote si no pertenece a la nueva finca asignada', () {
      final loteResuelto =
          PredioConsistencyHelper.resolverLoteTrasCambioFinca(
        nuevaFincaId: 'finca-2',
        loteActualId: 'lote-1', // Pertenecía a finca-1
        lotesDisponibles: [loteFinca2],
      );

      // Debe anularse para evitar lotes huérfanos entre predios
      expect(loteResuelto, isNull);
    });

    test('Conserva el lote si efectivamente pertenece a la finca seleccionada', () {
      final loteResuelto =
          PredioConsistencyHelper.resolverLoteTrasCambioFinca(
        nuevaFincaId: 'finca-2',
        loteActualId: 'lote-2',
        lotesDisponibles: [loteFinca2],
      );

      expect(loteResuelto, 'lote-2');
    });

    test('Filtra lotes disponibles estrictamente por finca', () {
      final lotesFinca1 = PredioConsistencyHelper.filtrarLotesPorFinca(
        fincaId: 'finca-1',
        todosLosLotes: todosLosLotes,
      );

      expect(lotesFinca1.length, 1);
      expect(lotesFinca1.first.id, 'lote-1');
    });

    test('Al dar de baja (Vendido/Muerto), limpia lote y potrero y asigna fecha_salida', () {
      final hoy = DateTime.now();
      final resultadoBaja =
          PredioConsistencyHelper.procesarUbicacionPorEstado(
        estadoActual: 'Vendido',
        loteIdOriginal: 'lote-1',
        potreroOriginal: 'Potrero 4',
        fechaSalidaOriginal: null,
      );

      expect(resultadoBaja.esBaja, isTrue);
      expect(resultadoBaja.loteId, isNull);
      expect(resultadoBaja.potreroActual, isNull);
      expect(resultadoBaja.fechaSalida, isNotNull);
      expect(resultadoBaja.fechaSalida!.day, hoy.day);
    });

    test('Animales activos preservan su lote y potrero sin forzar fecha_salida', () {
      final resultadoActivo =
          PredioConsistencyHelper.procesarUbicacionPorEstado(
        estadoActual: 'Activo',
        loteIdOriginal: 'lote-1',
        potreroOriginal: 'Potrero 4',
        fechaSalidaOriginal: null,
      );

      expect(resultadoActivo.esBaja, isFalse);
      expect(resultadoActivo.loteId, 'lote-1');
      expect(resultadoActivo.potreroActual, 'Potrero 4');
      expect(resultadoActivo.fechaSalida, isNull);
    });
  });
}

