import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/cards/animal_card.dart';
import '../helpers/test_theme.dart';

AnimalModel animal(
  String id, {
  GenealogiaModel? genealogia,
  bool externo = false,
}) => AnimalModel(
  id: id,
  codigoSistema: id,
  areteManejo: id,
  sexo: 'Macho',
  razaEtiquetaDisplay: 'Holstein',
  tipoExplotacion: 'Lecheria',
  fechaNacimiento: DateTime(2020),
  origen: 'Otro',
  fincaId: 'f1',
  fechaEntrada: DateTime(2024),
  genealogia: genealogia,
  esExterno: externo,
);
Future<void> mostrar(
  WidgetTester tester,
  AnimalModel hijo,
  Map<String, AnimalModel> catalogo,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 300,
              child: AnimalCard(
                animal: hijo,
                buscarAnimal: (id) => catalogo[id],
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'muestra padres y cuatro abuelos incluso externos sin desbordarse',
    (tester) async {
      final padre = animal(
        'Padre1',
        externo: true,
        genealogia: const GenealogiaModel(
          id: 'gp',
          animalId: 'Padre1',
          padreId: 'AP',
          madreId: 'BP',
        ),
      );
      final madre = animal(
        'Madre1',
        genealogia: const GenealogiaModel(
          id: 'gm',
          animalId: 'Madre1',
          padreId: 'AM',
          madreId: 'BM',
        ),
      );
      final hijo = animal(
        'Hijo',
        genealogia: const GenealogiaModel(
          id: 'gh',
          animalId: 'Hijo',
          padreId: 'Padre1',
          madreId: 'Madre1',
        ),
      );
      final lista = [
        padre,
        madre,
        animal('AP'),
        animal('BP'),
        animal('AM'),
        animal('BM'),
      ];
      await mostrar(tester, hijo, {for (final a in lista) a.id: a});
      for (final a in lista) {
        expect(find.text(a.areteManejo), findsOneWidget);
      }
      expect(find.text('Sin registrar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('indica los seis ancestros desconocidos', (tester) async {
    await mostrar(tester, animal('Hijo'), {});
    expect(find.text('Sin registrar'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
  testWidgets('donante IA proporciona padre y abuelos paternos', (
    tester,
  ) async {
    final hijo = animal(
      'Hijo',
      genealogia: const GenealogiaModel(
        id: 'g',
        animalId: 'Hijo',
        donanteId: 'd1',
        donanteSnapshot: {
          'nombre': 'Donante IA',
          'genealogia': {
            'padre': {'nombre': 'Abuelo IA'},
            'madre': {'nombre': 'Abuela IA'},
          },
        },
      ),
    );
    await mostrar(tester, hijo, {});
    for (final nombre in ['Donante IA', 'Abuelo IA', 'Abuela IA']) {
      expect(find.text(nombre), findsOneWidget);
    }
    expect(find.text('Sin registrar'), findsNWidgets(3));
  });
}
