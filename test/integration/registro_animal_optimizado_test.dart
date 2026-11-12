import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _fincaTest = FincaModel(
  id: 'finca-test-001',
  identificador: 'FNC-TST-01',
  nombre: 'Finca Test',
  estado: 'Activa',
  fuentesAgua: [],
);

Widget _wrap(List<FincaModel> fincas) => MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimalForm(fincas: fincas),
          ),
        ),
      ),
    );

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ─── 13.1 — Campo Código de Sistema eliminado ─────────────────────────────

  group('13.1 — Campo Código de Sistema eliminado del formulario', () {
    testWidgets('13.1.1 — no aparece texto "Código Sistema" en el formulario',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(find.text('Código Sistema'), findsNothing);
    });

    testWidgets('13.1.1 — no aparece hint GAN-XXXXXX visible en el form',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(
        find.textContaining('Generado automáticamente'),
        findsNothing,
      );
    });

    testWidgets(
        '13.1.1 — campo Arete de Manejo sigue presente y sigue siendo requerido',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      // findRichText: true es necesario porque CustomTextField usa RichText para la etiqueta
      expect(
        find.textContaining('Arete de Manejo', findRichText: true),
        findsOneWidget,
      );
    });
  });

  // ─── 13.2 — Autocompletado de Nombre/Alias con Arete ──────────────────────

  group('13.2 — Hint de autocompletado de alias', () {
    testWidgets('13.2.2 — hint del campo alias menciona el arete de manejo',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      // 'si vacío' es una frase única del nuevo hint de Nombre/Alias
      expect(
        find.textContaining('si vacío'),
        findsOneWidget,
      );
    });

    testWidgets('13.2.2 — campo Nombre o Alias está presente', (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      // findRichText: true es necesario porque CustomTextField usa RichText para la etiqueta
      expect(
        find.textContaining('Nombre o Alias', findRichText: true),
        findsOneWidget,
      );
    });
  });

  // ─── 13.3 — Sección unificada "Genética y Linaje" ─────────────────────────

  group('13.3 — Sección unificada Genética y Linaje', () {
    testWidgets('13.3.1 — aparece el título "2. Genética y Linaje"',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(find.text('2. Genética y Linaje'), findsOneWidget);
    });

    testWidgets(
        '13.3.1 — NO aparece sección separada "Genealogía y Linaje Reproductivo"',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(
        find.text('5. Genealogía y Linaje Reproductivo'),
        findsNothing,
      );
    });

    testWidgets(
        '13.3.2 — sub-encabezado "Linaje y Progenitores" dentro de la sección fusionada',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(find.text('Linaje y Progenitores'), findsOneWidget);
    });

    testWidgets(
        '13.3.2 — selector de Padre visible dentro del bloque fusionado',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(find.textContaining('Padre (Reproductor'), findsOneWidget);
    });

    testWidgets(
        '13.3.2 — selector de Madre visible dentro del bloque fusionado',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(find.textContaining('Madre (Vaca'), findsOneWidget);
    });

    testWidgets('13.3.3 — sección Observaciones renumerada a 5', (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      expect(
          find.text('5. Observaciones y Registro Fotográfico'), findsOneWidget);
      expect(
          find.text('6. Observaciones y Registro Fotográfico'), findsNothing);
    });

    testWidgets('13.3.3 — total de secciones visibles es 5 (no 6)',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap([_fincaTest]));
      await tester.pump();

      // Las 5 secciones esperadas
      expect(find.text('1. Identificación y Biometría'), findsOneWidget);
      expect(find.text('2. Genética y Linaje'), findsOneWidget);
      expect(find.text('3. Ubicación Actual y Manejo Productivo'), findsOneWidget);
      expect(find.text('4. Marcas de Hierro y Señales Físicas'), findsOneWidget);
      expect(
          find.text('5. Observaciones y Registro Fotográfico'), findsOneWidget);
    });
  });
}
