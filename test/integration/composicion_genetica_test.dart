import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/ui/common/breed_cross_builder.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import '../helpers/test_theme.dart';

void main() {
  testWidgets(
    'selector deslizante y Otro persisten sin mostrar etiqueta zootécnica',
    (tester) async {
      BreedSelectionResult? resultado;
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: BreedCrossBuilder(
                initialValue: const BreedSelectionResult(
                  esRazaPura: true,
                  razaEtiquetaDisplay: '',
                ),
                onChanged: (r) => resultado = r,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byType(CupertinoSlidingSegmentedControl<bool>),
        findsOneWidget,
      );
      expect(find.textContaining('Etiqueta Zootécnica'), findsNothing);
      await tester.tap(
        find.text('Buscar y seleccionar raza pura (Holstein, Brahman, Gyr...)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'raza fuera de catálogo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      expect(resultado!.isValid, isTrue);
      expect(resultado!.razaPuraNombre, 'Otro');
      expect(find.text('Otro'), findsOneWidget);
      final animal = AnimalModel(
        id: 'a',
        codigoSistema: 'A',
        areteManejo: 'A',
        sexo: 'Hembra',
        razaEtiquetaDisplay: resultado!.razaEtiquetaDisplay,
        esRazaPura: resultado!.esRazaPura,
        razaPuraNombre: resultado!.razaPuraNombre,
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2020),
        origen: 'Otro',
        fincaId: 'f1',
        fechaEntrada: DateTime(2024),
      );
      expect(AnimalModel.fromJson(animal.toJson()).razaPuraNombre, 'Otro');
      await tester.tap(find.text('Cruce'));
      await tester.pumpAndSettle();
      expect(resultado!.esRazaPura, isFalse);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is InputDecorator && w.decoration.labelText == 'Raza #1',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      expect(resultado!.composicionCruces.first['raza'], 'Otro');
      expect(resultado!.isValid, isTrue);
      expect(resultado!.razaEtiquetaDisplay, contains('Otro'));
      expect(find.textContaining('Etiqueta Zootécnica'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'composición genética se adapta a móvil y conserva una raza guardada',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: BreedCrossBuilder(
                initialValue: const BreedSelectionResult(
                  esRazaPura: true,
                  razaPuraNombre: 'Otro',
                  razaEtiquetaDisplay: 'Otro',
                ),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Otro'), findsOneWidget);
      await tester.tap(find.text('Cruce'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
