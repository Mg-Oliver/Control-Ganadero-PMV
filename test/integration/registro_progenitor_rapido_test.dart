import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/registrar_progenitor_modal.dart';
import '../helpers/test_theme.dart';

// ─── Mock AnimalesService ─────────────────────────────────────────────────────

class _MockAnimalesService extends AnimalesService {
  AnimalModel? lastRegistered;
  Exception? errorToThrow;

  @override
  Future<AnimalModel> registrar(
    AnimalModel animal, {
    GenealogiaModel? genealogia,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastRegistered = animal;
    return AnimalModel(
      id: 'mock-id-${animal.areteManejo}',
      codigoSistema: 'GAN-0001',
      areteManejo: animal.areteManejo,
      nombreAlias: animal.nombreAlias,
      sexo: animal.sexo,
      razaEtiquetaDisplay: animal.razaEtiquetaDisplay,
      tipoExplotacion: animal.tipoExplotacion,
      fechaNacimiento: animal.fechaNacimiento,
      origen: animal.origen,
      fincaId: animal.fincaId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime.now(),
      fincaNombre: animal.fincaNombre,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _fincaTest = FincaModel(
  id: 'finca-001',
  identificador: 'FNC-001',
  nombre: 'Finca La Esperanza',
  estado: 'Activa',
  fuentesAgua: [],
);

Widget _wrapForm(List<FincaModel> fincas) => MaterialApp(
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

Widget _wrapModal({
  required String sexo,
  required String tituloRol,
  AnimalesService? animalesService,
}) =>
    MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open-modal'),
            onPressed: () => RegistrarProgenitorModal.mostrar(
              context,
              sexo: sexo,
              tituloRol: tituloRol,
              fincaId: 'finca-001',
              fincaNombre: 'Finca La Esperanza',
              animalesService: animalesService,
            ),
            child: const Text('Abrir Modal'),
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
  // ─── 14.1 — Botones contextuales en los selectores de linaje ─────────────

  group('14.1 — Botones contextuales [+ Registrar] en selectores de linaje', () {
    testWidgets(
        '14.1.1 — botón [+ Registrar] aparece en el selector de Padre cuando hay finca',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrapForm([_fincaTest]));
      await tester.pump();

      expect(find.text('Registrar'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        '14.1.2 — botón [+ Registrar] aparece en el selector de Madre cuando hay finca',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrapForm([_fincaTest]));
      await tester.pump();

      // Deben aparecer al menos 2 botones Registrar (uno por padre, otro por madre)
      expect(find.text('Registrar'), findsAtLeastNWidgets(2));
    });

    testWidgets(
        '14.1.3 — botón [+ Registrar] NO aparece cuando no hay finca seleccionada',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      // Sin fincas → fincaSeleccionada: false
      await tester.pumpWidget(_wrapForm([]));
      await tester.pump();

      expect(find.text('Registrar'), findsNothing);
    });
  });

  // ─── 14.2 — Modal de sub-formulario ──────────────────────────────────────

  group('14.2 — Modal RegistrarProgenitorModal', () {
    testWidgets('14.2.1 — modal se abre y muestra el título correcto para Padre',
        (tester) async {
      await tester.pumpWidget(_wrapModal(sexo: 'Macho', tituloRol: 'Padre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Registrar Padre'), findsOneWidget);
    });

    testWidgets('14.2.1 — modal se abre y muestra el título correcto para Madre',
        (tester) async {
      await tester.pumpWidget(_wrapModal(sexo: 'Hembra', tituloRol: 'Madre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Registrar Madre'), findsOneWidget);
    });

    testWidgets(
        '14.2.2 — modal muestra chip de finca con nombre heredado',
        (tester) async {
      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      expect(find.text('Finca La Esperanza'), findsOneWidget);
    });

    testWidgets(
        '14.2.2 — modal muestra chip de sexo bloqueado según rol',
        (tester) async {
      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      expect(find.text('Macho'), findsOneWidget);
    });

    testWidgets(
        '14.2.2 — campo Arete de manejo es obligatorio (error en vacío)',
        (tester) async {
      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      // Intentar guardar sin arete
      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('El arete es obligatorio'), findsOneWidget);
    });

    testWidgets('14.2.2 — Cancelar cierra el modal sin retorno', (tester) async {
      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsNothing);
      expect(find.text('Registrar'), findsNothing);
    });
  });

  // ─── 14.3 — Guardado y autoselección ────────────────────────────────────

  group('14.3 — Guardado y auto-selección del progenitor', () {
    testWidgets(
        '14.3.1 — guardar llama a AnimalesService.registrar con sexo correcto',
        (tester) async {
      final mock = _MockAnimalesService();

      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre', animalesService: mock));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      // Llenar arete obligatorio
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Arete de manejo *'),
        'TORO-001',
      );
      await tester.pump();

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(mock.lastRegistered?.areteManejo, 'TORO-001');
      expect(mock.lastRegistered?.sexo, 'Macho');
      expect(mock.lastRegistered?.fincaId, 'finca-001');
    });

    testWidgets(
        '14.3.2 — alias vacío usa el arete como fallback en el guardado',
        (tester) async {
      final mock = _MockAnimalesService();

      await tester.pumpWidget(
          _wrapModal(sexo: 'Hembra', tituloRol: 'Madre', animalesService: mock));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Arete de manejo *'),
        'VACA-404',
      );
      // Alias vacío → no escribir nada
      await tester.pump();

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(mock.lastRegistered?.nombreAlias, 'VACA-404');
    });

    testWidgets(
        '14.3.4 — error en servicio muestra SnackBar de error y no cierra el modal',
        (tester) async {
      final mock = _MockAnimalesService()
        ..errorToThrow = Exception('fallo de red');

      await tester.pumpWidget(
          _wrapModal(sexo: 'Macho', tituloRol: 'Padre', animalesService: mock));
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-modal')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Arete de manejo *'),
        'ERR-001',
      );
      await tester.pump();

      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      // Modal sigue abierto
      expect(find.textContaining('Registrar Padre'), findsOneWidget);
      // SnackBar con error
      expect(find.textContaining('Error al registrar'), findsOneWidget);
    });
  });
}
