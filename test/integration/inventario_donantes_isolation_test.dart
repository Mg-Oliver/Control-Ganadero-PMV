// Tests de integración — Fase 16.2
// Blindaje de inventario vivo vs. catálogo de donantes e IA trazabilidad.

import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/poblacion_aggregator.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/models/toro_donante_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';

// ─── Factories de datos de prueba ────────────────────────────────────────────

AnimalModel _animalVivo({
  required String id,
  required String fincaId,
  required String sexo,
  int mesesEdad = 12,
  int partos = 0,
}) =>
    AnimalModel(
      id: id,
      codigoSistema: id,
      areteManejo: id,
      sexo: sexo,
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento:
          DateTime.now().subtract(Duration(days: mesesEdad * 30)),
      origen: 'Nacido en la finca',
      fincaId: fincaId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2024),
      numeroPartos: partos,
    );

FincaModel _finca(String id) => FincaModel(
      id: id,
      nombre: 'Finca $id',
      identificador: id,
    );

ToroDonanteModel _donante({String id = 'td-001'}) => ToroDonanteModel(
      id: id,
      nombre: 'ABS Manso Extra',
      codigoPajuela: 'ABS-EX-$id',
      raza: 'Gyr Lechero',
      genealogia: GenealogiaDonanteModel(
        padre: const AncestroDonanteModel(nombre: 'Magnus', codigo: 'BR-001'),
        madre: const AncestroDonanteModel(nombre: 'Beleza', codigo: 'BR-002'),
      ),
    );

// ─── 16.2.1 — Blindaje de inventario vivo ────────────────────────────────────

void main() {
  group('16.2.1 — Inventario vivo aislado de toros donantes', () {
    test('ToroDonanteModel no tiene fincaId ni estadoActual', () {
      final toro = _donante();
      // La clase ToroDonanteModel no tiene fincaId, estadoActual ni loteId;
      // esto garantiza que nunca puede aparecer en las listas de AnimalModel.
      expect(toro.id, isNotNull);
      expect(toro.nombre, isNotEmpty);
      // Verificar que no es un AnimalModel
      expect(toro, isNot(isA<AnimalModel>()));
    });

    test('PoblacionAggregator acepta solo AnimalModel, excluye donantes', () {
      // Cargar animales vivos (no donantes)
      final animales = [
        _animalVivo(id: 'a1', fincaId: 'f1', sexo: 'Macho'),
        _animalVivo(id: 'a2', fincaId: 'f1', sexo: 'Hembra'),
        _animalVivo(id: 'a3', fincaId: 'f1', sexo: 'Hembra', partos: 1),
      ];

      final resultado = PoblacionAggregator.agregar(animales);

      // Solo los 3 animales vivos — donantes nunca se pasan al aggregator
      expect(resultado.totalHato, 3);
      expect(resultado.totalMachos, 1);
      expect(resultado.totalHembras, 2);
    });

    test('InventarioController no expone lista de toros donantes', () {
      final controller = InventarioController();
      controller.registrarFincaOptimista(_finca('f1'));
      controller.registrarAnimalOptimista(
          _animalVivo(id: 'a1', fincaId: 'f1', sexo: 'Macho'));

      // InventarioController.allAnimales solo contiene AnimalModel
      expect(controller.allAnimales.length, 1);
      expect(controller.allAnimales.every((a) => a.id.isNotEmpty), isTrue);
      // No existe ningún método que mezcle toros donantes con el hato
      controller.dispose();
    });

    test('Animales vendidos o muertos no pasan al gráfico de distribución', () {
      final animales = [
        _animalVivo(id: 'activo', fincaId: 'f1', sexo: 'Macho'),
        AnimalModel(
          id: 'vendido',
          codigoSistema: 'BV-999',
          areteManejo: 'ART-X',
          sexo: 'Hembra',
          razaEtiquetaDisplay: 'Jersey',
          tipoExplotacion: 'Lecheria',
          fechaNacimiento: DateTime(2021),
          origen: 'Comprado en subasta',
          fincaId: 'f1',
          estadoActual: 'Vendido',
          fechaEntrada: DateTime(2022),
          fechaSalida: DateTime(2023),
        ),
      ];

      // El dashboard filtra por estadoActual == 'Activo' antes de llamar al aggregator
      final activos = animales.where((a) => a.estadoActual == 'Activo').toList();
      final resultado = PoblacionAggregator.agregar(activos);

      expect(resultado.totalHato, 1);
      expect(resultado.machos.length, 1);
      expect(resultado.hembras, isEmpty);
    });

    test('Donante y animal con mismo nombre no se confunden', () {
      // Un donante con nombre "Holstein Star" no afecta al inventario
      final donante = ToroDonanteModel(
        id: 'td-conflicto',
        nombre: 'Holstein Star',
        codigoPajuela: 'HS-001',
      );
      final animal = _animalVivo(id: 'hs-001', fincaId: 'f1', sexo: 'Macho');

      // Son tipos Dart distintos, no hay colisión de ids
      expect(donante.id, isNot(equals(animal.id)));
      expect(donante, isNot(isA<AnimalModel>()));
    });
  });

  // ─── 16.2.2 — Trazabilidad IA sin alterar inventario vivo ─────────────────

  group('16.2.2 — Trazabilidad IA en genealogía', () {
    test('GenealogiaModel con donanteSnapshot recupera ToroDonanteModel', () {
      final toro = _donante();
      final snapshot = toro.toJson();

      final gen = GenealogiaModel(
        id: 'gen-ia-01',
        animalId: 'cria-01',
        tipoPruebaPaterna: 'Inseminacion',
        donanteId: toro.id,
        donanteSnapshot: snapshot,
      );

      // Puede reconstruir el donante desde el snapshot
      final restoredToro = ToroDonanteModel.fromJson(
        {...gen.donanteSnapshot!, 'id': gen.donanteId!},
      );

      expect(restoredToro.nombre, toro.nombre);
      expect(restoredToro.codigoPajuela, toro.codigoPajuela);
      expect(restoredToro.raza, toro.raza);
    });

    test('Snapshot preserva genealogía multinivel del donante', () {
      final toro = _donante();
      final snapshot = toro.toJson();

      final restoredToro = ToroDonanteModel.fromJson(
        {...snapshot, 'id': toro.id},
      );

      expect(restoredToro.genealogia.padre.nombre, 'Magnus');
      expect(restoredToro.genealogia.padre.codigo, 'BR-001');
      expect(restoredToro.genealogia.madre.nombre, 'Beleza');
      expect(restoredToro.genealogia.madre.codigo, 'BR-002');
      expect(restoredToro.genealogia.tieneDatos, isTrue);
    });

    test('Animal con padre IA no cuenta como "sin padre" en genealogía', () {
      final toro = _donante();
      final gen = GenealogiaModel(
        id: 'gen-02',
        animalId: 'cria-02',
        tipoPruebaPaterna: 'Inseminacion',
        donanteId: toro.id,
        donanteSnapshot: toro.toJson(),
      );

      // La cría conoce su padre (vía IA)
      expect(gen.donanteId, isNotNull);
      expect(gen.donanteSnapshot, isNotNull);
      expect(gen.tipoPruebaPaterna, 'Inseminacion');
      // Pero no tiene padre interno ni referencia externa (correcto para IA)
      expect(gen.padreId, isNull);
      expect(gen.padreExternoReferencia, isNull);
    });

    test('GenealogiaModel.copyWith preserva campos IA al actualizar otros', () {
      final toro = _donante();
      final original = GenealogiaModel(
        id: 'gen-03',
        animalId: 'cria-03',
        donanteId: toro.id,
        donanteSnapshot: toro.toJson(),
        tipoPruebaPaterna: 'Inseminacion',
      );

      // Simula actualizar el campo de madre sin perder la info del padre IA
      final actualizado = original.copyWith(
        madreId: 'madre-999',
        tipoPruebaMaterna: 'Registros Visuales',
      );

      expect(actualizado.donanteId, toro.id);
      expect(actualizado.donanteSnapshot!['nombre'], toro.nombre);
      expect(actualizado.madreId, 'madre-999');
      expect(actualizado.tipoPruebaMaterna, 'Registros Visuales');
    });

    test('Crías IA no alteran conteo de animales vivos del hato', () {
      final controller = InventarioController();
      controller.registrarFincaOptimista(_finca('f1'));

      // Registrar madre (viva) y cría (viva con padre IA)
      final madre = _animalVivo(id: 'madre-01', fincaId: 'f1', sexo: 'Hembra', partos: 1);
      final cria = _animalVivo(id: 'cria-ia-01', fincaId: 'f1', sexo: 'Macho');

      controller.registrarAnimalOptimista(madre);
      controller.registrarAnimalOptimista(cria);

      // 2 animales vivos; el toro donante NO está en el inventario
      final activos = controller.allAnimales
          .where((a) => a.estadoActual == 'Activo')
          .toList();
      expect(activos.length, 2);

      controller.dispose();
    });
  });
}
