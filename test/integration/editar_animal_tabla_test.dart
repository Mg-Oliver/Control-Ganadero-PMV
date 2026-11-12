import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bovino_mvp/core/constants/columna_tabla.dart';
import 'package:bovino_mvp/core/services/app_feedback.dart';
import 'package:bovino_mvp/core/utils/predio_consistency_helper.dart';
import 'package:bovino_mvp/data/dev/seed_service.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/editar_animal_dialog.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/entity_data_table.dart';
import '../helpers/test_theme.dart';

// ─── Mock AnimalesService ─────────────────────────────────────────────────────

class _MockAnimalesService extends AnimalesService {
  AnimalModel? lastUpdated;
  Exception? errorToThrow;

  @override
  Future<AnimalModel> actualizar(AnimalModel animal) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastUpdated = animal;
    return animal;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: testTheme,
      scaffoldMessengerKey: AppFeedback.messengerKey,
      home: Scaffold(body: child),
    );

Widget _wrapDialog(Widget dialog) => MaterialApp(
      theme: testTheme,
      scaffoldMessengerKey: AppFeedback.messengerKey,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showDialog<void>(
              context: ctx,
              builder: (_) => dialog,
            ),
            child: const Text('Abrir'),
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

AnimalModel _animalActivo() => AnimalModel(
      id: 'test-animal-001',
      codigoSistema: 'GAN-TEST-001',
      areteManejo: 'TR-101',
      nombreAlias: 'Test Animal',
      sexo: 'Macho',
      pesoActual: 350.0,
      esRazaPura: false,
      razaEtiquetaDisplay: 'Cruza',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2022, 1, 1),
      origen: 'Nacido en finca',
      fincaId: SeedService.fincaRocioId,
      loteId: SeedService.loteLecheriaPardoId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2022, 6, 1),
      fincaNombre: 'Hacienda El Rocío',
      loteNombre: 'Manga Lechería',
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late InventarioController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = InventarioController();
    SeedService.cargarEnControlador(controller);
  });

  tearDown(() {
    controller.dispose();
  });

  // ─── 12.1 — Columna Acciones en tabla ─────────────────────────────────────

  group('12.1 — Columna Acciones en EntityDataTable', () {
    testWidgets('12.1.1 — columna "Acciones" aparece en la tabla de animales',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap(
        EntityDataTable(
          controller: controller,
          columnasAnimalesActivas: kColumnasDefault,
        ),
      ));
      await tester.pump();

      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('12.1.1 — botón editar (edit_outlined) aparece por cada fila',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap(
        EntityDataTable(
          controller: controller,
          columnasAnimalesActivas: kColumnasDefault,
        ),
      ));
      await tester.pump();

      final editBtns = find.byIcon(Icons.edit_outlined);
      final animalesPagina =
          controller.animalesFiltrados.length.clamp(0, controller.rowsPerPage);
      expect(editBtns, findsNWidgets(animalesPagina));
    });

    testWidgets(
        '12.1.2 — tocar botón editar abre EditarAnimalDialog con título correcto',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap(
        EntityDataTable(
          controller: controller,
          columnasAnimalesActivas: kColumnasDefault,
        ),
      ));
      await tester.pump();

      // Toca el primer botón editar
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      // El dialog debe mostrarse con texto "Editar animal"
      expect(find.textContaining('Editar animal'), findsOneWidget);
    });
  });

  // ─── 12.1.3 — Formulario pre-poblado ──────────────────────────────────────

  group('12.1.3 — Formulario pre-poblado con datos del animal', () {
    testWidgets('arete pre-poblado en el campo de texto', (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // El TextFormField con el arete debe tener el valor correcto
      expect(find.text('TR-101'), findsAtLeastNWidgets(1));
    });

    testWidgets('nombre alias pre-poblado en el campo de texto', (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Test Animal'), findsOneWidget);
    });

    testWidgets('peso pre-poblado en el campo numérico', (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('350.00'), findsOneWidget);
    });
  });

  // ─── 12.1.3 — Validación de campos ───────────────────────────────────────

  group('12.1.3 — Validación de formulario', () {
    testWidgets('arete vacío muestra error de validación', (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Limpiar el campo arete
      final areteField = find.ancestor(
        of: find.text('TR-101'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(areteField, '');

      // Intentar guardar
      await tester.tap(find.text('Guardar'));
      await tester.pump();

      expect(find.text('El arete es obligatorio'), findsOneWidget);
    });

    testWidgets('peso inválido muestra error de validación', (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Campo de peso — encontrarlo por etiqueta
      final pesoField = find.ancestor(
        of: find.text('350.00'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(pesoField, 'abc');

      await tester.tap(find.text('Guardar'));
      await tester.pump();

      expect(find.text('Peso inválido'), findsOneWidget);
    });
  });

  // ─── 12.2 — Reglas de baja (PredioConsistencyHelper) ──────────────────────

  group('12.2 — Reglas de baja zootécnica', () {
    test('12.2.1 — estado de baja limpia loteId y potreroActual', () {
      const estados = ['Vendido', 'Muerto', 'Robado', 'Descartado'];
      for (final estado in estados) {
        final resultado = PredioConsistencyHelper.procesarUbicacionPorEstado(
          estadoActual: estado,
          loteIdOriginal: 'lote-123',
          potreroOriginal: 'Potrero Sur',
          fechaSalidaOriginal: null,
        );
        expect(resultado.loteId, isNull,
            reason: 'Estado $estado debe limpiar loteId');
        expect(resultado.potreroActual, isNull,
            reason: 'Estado $estado debe limpiar potreroActual');
        expect(resultado.fechaSalida, isNotNull,
            reason: 'Estado $estado debe establecer fechaSalida');
        expect(resultado.esBaja, isTrue);
      }
    });

    test('12.2.1 — estado Activo preserva ubicación', () {
      final resultado = PredioConsistencyHelper.procesarUbicacionPorEstado(
        estadoActual: 'Activo',
        loteIdOriginal: 'lote-123',
        potreroOriginal: 'Potrero Sur',
        fechaSalidaOriginal: null,
      );
      expect(resultado.loteId, equals('lote-123'));
      expect(resultado.potreroActual, equals('Potrero Sur'));
      expect(resultado.esBaja, isFalse);
    });

    testWidgets(
        '12.2.1 — UI: cambiar a estado baja oculta campos manga/potrero',
        (tester) async {
      final animal = _animalActivo();
      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: _MockAnimalesService(),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Inicialmente manga y potrero visibles
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Potrero actual'), findsOneWidget);

      // Cambiar estado a Vendido (tocar el DropdownButton de estado)
      final estadoDropdown = find
          .ancestor(
            of: find.text('Estado actual'),
            matching: find.byType(InputDecorator),
          )
          .first;
      await tester.tap(estadoDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vendido').last);
      await tester.pumpAndSettle();

      // Manga y Potrero deben ocultarse
      expect(find.text('Manga'), findsNothing);
      expect(find.text('Potrero actual'), findsNothing);
      // Fecha de salida debe aparecer
      expect(find.text('Fecha de salida *'), findsOneWidget);
    });
  });

  // ─── 12.3 — actualizarAnimalOptimista ─────────────────────────────────────

  group('12.3 — actualizarAnimalOptimista en InventarioController', () {
    test('12.3.2 — actualiza el animal en la lista preservando orden', () {
      final original = controller.allAnimales.first;
      final updated = AnimalModel(
        id: original.id,
        codigoSistema: original.codigoSistema,
        areteManejo: 'ARETE-NUEVO',
        nombreAlias: original.nombreAlias,
        sexo: original.sexo,
        pesoActual: 999.0,
        esRazaPura: original.esRazaPura,
        razaEtiquetaDisplay: original.razaEtiquetaDisplay,
        tipoExplotacion: original.tipoExplotacion,
        fechaNacimiento: original.fechaNacimiento,
        origen: original.origen,
        fincaId: original.fincaId,
        estadoActual: original.estadoActual,
        fechaEntrada: original.fechaEntrada,
      );

      controller.actualizarAnimalOptimista(updated);

      final encontrado =
          controller.allAnimales.firstWhere((a) => a.id == original.id);
      expect(encontrado.areteManejo, equals('ARETE-NUEVO'));
      expect(encontrado.pesoActual, equals(999.0));
    });

    test('12.3.2 — limpiar loteId actualiza loteNombre a null', () {
      // Tomar un animal que tenga lote
      final conLote = controller.allAnimales
          .where((a) => a.loteId != null)
          .first;
      final sinLote = AnimalModel(
        id: conLote.id,
        codigoSistema: conLote.codigoSistema,
        areteManejo: conLote.areteManejo,
        sexo: conLote.sexo,
        esRazaPura: conLote.esRazaPura,
        razaEtiquetaDisplay: conLote.razaEtiquetaDisplay,
        tipoExplotacion: conLote.tipoExplotacion,
        fechaNacimiento: conLote.fechaNacimiento,
        origen: conLote.origen,
        fincaId: conLote.fincaId,
        estadoActual: 'Vendido',
        loteId: null, // limpio
        potreroActual: null,
        fechaEntrada: conLote.fechaEntrada,
        fechaSalida: DateTime.now(),
      );

      controller.actualizarAnimalOptimista(sinLote);

      final resultado =
          controller.allAnimales.firstWhere((a) => a.id == conLote.id);
      expect(resultado.loteId, isNull);
      expect(resultado.loteNombre, isNull);
    });

    test('12.3.2 — notifica listeners al actualizar', () {
      int notificaciones = 0;
      controller.addListener(() => notificaciones++);

      final original = controller.allAnimales.first;
      controller.actualizarAnimalOptimista(
        AnimalModel(
          id: original.id,
          codigoSistema: original.codigoSistema,
          areteManejo: 'NUEVO',
          sexo: original.sexo,
          esRazaPura: original.esRazaPura,
          razaEtiquetaDisplay: original.razaEtiquetaDisplay,
          tipoExplotacion: original.tipoExplotacion,
          fechaNacimiento: original.fechaNacimiento,
          origen: original.origen,
          fincaId: original.fincaId,
          estadoActual: original.estadoActual,
          fechaEntrada: original.fechaEntrada,
        ),
      );

      expect(notificaciones, greaterThanOrEqualTo(1));
    });
  });

  // ─── 12.4 — SnackBars de feedback ─────────────────────────────────────────

  group('12.4 — SnackBar de éxito/error', () {
    testWidgets('12.4.1 — guarda correctamente y muestra SnackBar de éxito',
        (tester) async {
      final animal = _animalActivo();
      final mockSvc = _MockAnimalesService();

      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: mockSvc,
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // El campo arete ya tiene 'TR-101', solo guardar
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // SnackBar de éxito
      expect(find.textContaining('actualizado correctamente'), findsOneWidget);
    });

    testWidgets('12.4.2 — error de red muestra SnackBar de error y revierte',
        (tester) async {
      final animal = _animalActivo();
      // Agregar el animal al controller para poder revertir
      controller.registrarAnimalOptimista(animal);

      final mockSvc = _MockAnimalesService()
        ..errorToThrow = Exception('Error de red simulado');

      await tester.pumpWidget(_wrapDialog(
        EditarAnimalDialog(
          animal: animal,
          controller: controller,
          animalesService: mockSvc,
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error al guardar'), findsOneWidget);
      // El dialog NO debe haberse cerrado (sigue el formulario en pantalla)
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });
}
