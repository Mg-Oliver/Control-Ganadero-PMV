import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import '../helpers/animales_schema_server.dart';

AnimalModel animal({String sexo = 'Macho', bool externo = false}) =>
    AnimalModel(
      id: 'padre',
      codigoSistema: '',
      areteManejo: 'TORO-1',
      sexo: sexo,
      razaPuraNombre: 'Holstein',
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2020),
      origen: 'Otro',
      fincaId: 'f1',
      fechaEntrada: DateTime(2024),
      esExterno: externo,
      numeroPartos: sexo == 'Hembra' ? 2 : 0,
      marcasHierro: const MarcasHierro(ubicacionCuerpo: 'Pierna izquierda'),
    );
const natural = GenealogiaModel(
  id: '',
  animalId: 'padre',
  tipoPruebaPaterna: 'Visual / Monta natural',
  tipoPruebaMaterna: 'Visual / Monta natural',
);
AnimalesService service(AnimalesSchemaServer server) {
  final client = SupabaseClient(
    'https://schema.test',
    'public-test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: server.client,
  );
  addTearDown(client.dispose);
  return AnimalesService(client: client);
}

void main() {
  for (final sexo in ['Macho', 'Hembra']) {
    for (final externo in [true, false]) {
      test(
        'registra $sexo externo=$externo en esquema sin columnas nuevas y restaura sus datos',
        () async {
          final server = AnimalesSchemaServer();
          final s = service(server);
          final a = await s.registrar(
            animal(sexo: sexo, externo: externo),
            genealogia: natural,
          );
          expect(a.sexo, sexo);
          expect(a.esExterno, externo);
          expect(a.numeroPartos, sexo == 'Hembra' ? 2 : 0);
          expect(a.marcasHierro.ubicacionCuerpo, 'Pierna izquierda');
          expect(a.genealogia!.tipoPruebaPaterna, 'Visual / Monta natural');
          expect(server.insertados, 1);
          expect(server.borrados, 0);
          expect(server.animales.length, 1);
          final leido = (await s.consultarInventarioRelacional()).single;
          expect(leido.esExterno, externo);
          expect(leido.numeroPartos, a.numeroPartos);
        },
      );
    }
  }
  test(
    'esquema nuevo usa columnas propias sin respaldo y permite vaciar datos IA',
    () async {
      final server = AnimalesSchemaServer(legado: false);
      final s = service(server);
      final a = await s.registrar(animal(externo: true), genealogia: natural);
      expect(server.intentosAnimal, 1);
      expect(server.animales[a.id]!['es_externo'], isTrue);
      expect(
        (server.animales[a.id]!['marcas_hierro'] as Map).containsKey(
          AnimalModel.metadataRegistroKey,
        ),
        isFalse,
      );
      expect(server.genealogias[a.id]!.containsKey('toro_donante_id'), isTrue);
      expect(server.genealogias[a.id]!['toro_donante_id'], isNull);
    },
  );
  test('actualización también conserva datos en esquema antiguo', () async {
    final server = AnimalesSchemaServer();
    final s = service(server);
    final a = await s.registrar(animal(sexo: 'Hembra'), genealogia: natural);
    final actualizado = await s.actualizar(
      a.copyWith(esExterno: true, numeroPartos: 3),
    );
    expect(actualizado.esExterno, isTrue);
    expect(actualizado.numeroPartos, 3);
    expect(server.animales.length, 1);
    expect(server.insertados, 1);
  });
  test(
    'si falla genealogía se revierte solo el animal recién creado',
    () async {
      final server = AnimalesSchemaServer()..denegarGenealogia = true;
      final s = service(server);
      await expectLater(
        s.registrar(animal(), genealogia: natural),
        throwsA(isA<PostgrestException>()),
      );
      expect(server.insertados, 1);
      expect(server.borrados, 1);
      expect(server.animales, isEmpty);
    },
  );
  test(
    'un rechazo de permisos no se reintenta como error de esquema',
    () async {
      final server = AnimalesSchemaServer()..denegarAnimal = true;
      await expectLater(
        service(server).registrar(animal(), genealogia: natural),
        throwsA(isA<PostgrestException>()),
      );
      expect(server.intentosAnimal, 1);
      expect(server.borrados, 0);
    },
  );
  test('no descarta un donante asignado si falta su columna', () async {
    final server = AnimalesSchemaServer();
    final donante = natural.copyWith(donanteId: 'donante-1');
    await expectLater(
      service(server).registrar(animal(), genealogia: donante),
      throwsA(isA<PostgrestException>()),
    );
    expect(server.animales, isEmpty);
    expect(server.genealogias, isEmpty);
  });
}
