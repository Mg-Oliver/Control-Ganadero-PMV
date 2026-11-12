// Tests de integración para Fase 15: Gestión de Toros Donantes e IA
//
// Cobertura:
//   15.1 — Modelos ToroDonanteModel y GenealogiaDonanteModel
//   15.2 — Modo IA en selector de padre del AnimalForm
//   15.3 — Modal RegistrarToroDonanteModal
//   15.4 — GenealogiaModel con campos donanteId / donanteSnapshot
//   15.5 — Badge IA en AnimalExpedienteView (a través del modelo)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/models/toro_donante_model.dart';
import 'package:bovino_mvp/data/services/toros_donantes_service.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/registrar_toro_donante_modal.dart';
import '../helpers/test_theme.dart';

// ─── Mock del servicio de toros donantes ─────────────────────────────────────

class _MockTorosDonantesService extends TorosDonantesService {
  final List<ToroDonanteModel> donantesPrecargados;
  ToroDonanteModel? lastCreated;
  Exception? errorToThrow;

  _MockTorosDonantesService({this.donantesPrecargados = const []});

  @override
  Future<List<ToroDonanteModel>> obtenerActivos() async =>
      List.from(donantesPrecargados);

  @override
  Future<ToroDonanteModel> crear(ToroDonanteModel toro) async {
    if (errorToThrow != null) throw errorToThrow!;
    final guardado = ToroDonanteModel(
      id: 'mock-id-${toro.codigoPajuela}',
      nombre: toro.nombre,
      codigoPajuela: toro.codigoPajuela,
      raza: toro.raza,
      genealogia: toro.genealogia,
    );
    lastCreated = guardado;
    return guardado;
  }
}

// ─── Datos de prueba ─────────────────────────────────────────────────────────

ToroDonanteModel _donanteSinGenealogiaBase() => const ToroDonanteModel(
      id: 'toro-001',
      nombre: 'ABS Manso 420',
      codigoPajuela: 'ABS-420',
      raza: 'Gyr Lechero',
    );

ToroDonanteModel _donanteConGenealogiaBase() => ToroDonanteModel(
      id: 'toro-002',
      nombre: 'Sansão Leiteiro',
      codigoPajuela: 'BR-9942',
      raza: 'Gyr Lechero',
      genealogia: GenealogiaDonanteModel(
        padre: const AncestroDonanteModel(
            nombre: 'Magnus', codigo: 'BR-001', raza: 'Gyr'),
        madre: const AncestroDonanteModel(
            nombre: 'Beleza', codigo: 'BR-002', raza: 'Gyr'),
      ),
    );

// ─── 15.1 — Modelos ──────────────────────────────────────────────────────────

void main() {
  group('15.1 — ToroDonanteModel y GenealogiaDonanteModel', () {
    test('15.1.1 — ToroDonanteModel.etiquetaDisplay incluye nombre y código', () {
      final toro = _donanteSinGenealogiaBase();
      expect(toro.etiquetaDisplay, contains('ABS Manso 420'));
      expect(toro.etiquetaDisplay, contains('ABS-420'));
    });

    test('15.1.2 — ToroDonanteModel serializa y deserializa correctamente', () {
      final original = _donanteConGenealogiaBase();
      final json = original.toJson();
      final restaurado = ToroDonanteModel.fromJson({...json, 'id': original.id});

      expect(restaurado.nombre, original.nombre);
      expect(restaurado.codigoPajuela, original.codigoPajuela);
      expect(restaurado.raza, original.raza);
      expect(restaurado.genealogia.padre.nombre, 'Magnus');
      expect(restaurado.genealogia.padre.codigo, 'BR-001');
      expect(restaurado.genealogia.madre.nombre, 'Beleza');
    });

    test('15.1.3 — GenealogiaDonanteModel.tieneDatos detecta datos presentes', () {
      final sinDatos = const GenealogiaDonanteModel();
      final conDatos = GenealogiaDonanteModel(
        padre: const AncestroDonanteModel(nombre: 'Test'),
      );

      expect(sinDatos.tieneDatos, isFalse);
      expect(conDatos.tieneDatos, isTrue);
    });

    test('15.1.4 — AncestroDonanteModel.tieneDatos con solo código', () {
      const sinNada = AncestroDonanteModel();
      const conCodigo = AncestroDonanteModel(codigo: 'ABC-123');

      expect(sinNada.tieneDatos, isFalse);
      expect(conCodigo.tieneDatos, isTrue);
    });

    test('15.1.5 — GenealogiaModel admite donanteId y donanteSnapshot', () {
      final toro = _donanteSinGenealogiaBase();
      final gen = GenealogiaModel(
        id: 'gen-001',
        animalId: 'animal-001',
        tipoPruebaPaterna: 'Inseminacion',
        donanteId: toro.id,
        donanteSnapshot: toro.toJson(),
      );

      expect(gen.donanteId, 'toro-001');
      expect(gen.donanteSnapshot, isNotNull);
      expect(gen.donanteSnapshot!['nombre'], 'ABS Manso 420');
      expect(gen.tipoPruebaPaterna, 'Inseminacion');
    });

    test('15.1.6 — GenealogiaModel.toJson incluye campos IA', () {
      final toro = _donanteSinGenealogiaBase();
      final gen = GenealogiaModel(
        id: '',
        animalId: 'animal-001',
        donanteId: toro.id,
        donanteSnapshot: toro.toJson(),
        tipoPruebaPaterna: 'Inseminacion',
      );

      final json = gen.toJson(includeId: false);
      expect(json['toro_donante_id'], 'toro-001');
      expect(json['toro_donante_snapshot'], isA<Map<String, dynamic>>());
    });

    test('15.1.7 — GenealogiaModel.fromJson carga campos IA', () {
      final toro = _donanteSinGenealogiaBase();
      final json = {
        'id': 'gen-001',
        'animal_id': 'animal-001',
        'tipo_prueba_paterna': 'Inseminacion',
        'tipo_prueba_materna': 'Sin confirmar',
        'toro_donante_id': toro.id,
        'toro_donante_snapshot': toro.toJson(),
      };

      final gen = GenealogiaModel.fromJson(json);
      expect(gen.donanteId, 'toro-001');
      expect(gen.donanteSnapshot!['codigo_pajuela'], 'ABS-420');
    });
  });

  // ─── 15.2 — Modo IA en AnimalForm ─────────────────────────────────────────

  group('15.2 — Selector de padre en modo IA (AnimalForm)', () {
    final fincaPrueba = FincaModel(
      id: 'finca-001',
      nombre: 'El Vergel',
      identificador: 'EV',
      ubicacion: 'Palmira, Valle, Colombia',
    );

    Widget wrapForm({TorosDonantesService? svc}) {
      return MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnimalForm(
              fincas: [fincaPrueba],
              torosDonantesService: svc,
            ),
          ),
        ),
      );
    }

    testWidgets('15.2.1 — Selector de padre muestra botón "IA" para padre',
        (tester) async {
      await tester.pumpWidget(wrapForm(
        svc: _MockTorosDonantesService(
            donantesPrecargados: [_donanteSinGenealogiaBase()]),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // El botón IA debe existir en el selector de padre
      expect(find.text('IA'), findsOneWidget);
    });

    testWidgets('15.2.2 — La madre no tiene botón "IA"', (tester) async {
      await tester.pumpWidget(wrapForm(
        svc: _MockTorosDonantesService(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Hato y Externo / Pajuela aparecen para padre y madre,
      // pero IA solo aparece para padre (1 vez)
      expect(find.text('IA'), findsOneWidget);
    });
  });

  // ─── 15.3 — RegistrarToroDonanteModal ─────────────────────────────────────

  group('15.3 — RegistrarToroDonanteModal', () {
    Widget wrapModal({TorosDonantesService? svc}) {
      return MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () =>
                  RegistrarToroDonanteModal.mostrar(ctx, torosDonantesService: svc),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );
    }

    testWidgets('15.3.1 — Modal muestra campos de nombre y código',
        (tester) async {
      await tester.pumpWidget(wrapModal());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Toro Donante / Pajuela'), findsOneWidget);
      expect(find.text('Nombre comercial del toro *'), findsOneWidget);
      expect(find.text('Código de pajuela *'), findsOneWidget);
    });

    testWidgets('15.3.2 — Validación rechaza guardar sin nombre ni código',
        (tester) async {
      await tester.pumpWidget(wrapModal(svc: _MockTorosDonantesService()));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar donante'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre obligatorio'), findsOneWidget);
      expect(find.text('Código obligatorio'), findsOneWidget);
    });

    testWidgets('15.3.3 — Cancelar cierra el modal sin guardar',
        (tester) async {
      await tester.pumpWidget(wrapModal(svc: _MockTorosDonantesService()));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Toro Donante / Pajuela'), findsNothing);
    });

    testWidgets('15.3.4 — Servicio recibe nombre y código al guardar',
        (tester) async {
      final svc = _MockTorosDonantesService();
      await tester.pumpWidget(wrapModal(svc: svc));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre comercial del toro *'),
          'Touro Super');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código de pajuela *'),
          'TSP-9000');

      await tester.tap(find.text('Registrar donante'));
      await tester.pumpAndSettle();

      expect(svc.lastCreated, isNotNull);
      expect(svc.lastCreated!.nombre, 'Touro Super');
      expect(svc.lastCreated!.codigoPajuela, 'TSP-9000');
    });

    testWidgets('15.3.5 — Error del servicio muestra SnackBar de error',
        (tester) async {
      final svc = _MockTorosDonantesService()
        ..errorToThrow = Exception('DB timeout');
      await tester.pumpWidget(wrapModal(svc: svc));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre comercial del toro *'),
          'El Fallo');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código de pajuela *'),
          'ERR-001');

      await tester.tap(find.text('Registrar donante'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error al registrar donante'), findsOneWidget);
    });

    testWidgets('15.3.6 — Acordeón de genealogía se expande',
        (tester) async {
      await tester.pumpWidget(wrapModal(svc: _MockTorosDonantesService()));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(
          find.text('Genealogía del donante (opcional)'));
      await tester.pumpAndSettle();

      expect(find.text('Padre del Donante'), findsOneWidget);
      expect(find.text('Madre del Donante'), findsOneWidget);
      expect(find.text('Abuelo Paterno'), findsOneWidget);
    });
  });

  // ─── 15.4 — Snapshot IA en GenealogiaModel ───────────────────────────────

  group('15.4 — Snapshot IA: serialización round-trip completa', () {
    test('15.4.1 — Snapshot con genealogía completa conserva todos los ancestros',
        () {
      final toro = _donanteConGenealogiaBase();
      final json = toro.toJson();
      final restaurado = ToroDonanteModel.fromJson({...json, 'id': toro.id});

      expect(restaurado.genealogia.padre.nombre, 'Magnus');
      expect(restaurado.genealogia.madre.nombre, 'Beleza');
      // Abuelos vacíos por defecto
      expect(restaurado.genealogia.abueloPaterno.tieneDatos, isFalse);
    });

    test('15.4.2 — GenealogiaModel.copyWith preserva campos IA', () {
      final gen = GenealogiaModel(
        id: 'gen-001',
        animalId: 'animal-001',
        donanteId: 'toro-001',
        donanteSnapshot: {'nombre': 'Orig'},
      );

      final copia = gen.copyWith(tipoPruebaPaterna: 'Inseminacion');
      expect(copia.donanteId, 'toro-001');
      expect(copia.donanteSnapshot!['nombre'], 'Orig');
      expect(copia.tipoPruebaPaterna, 'Inseminacion');
    });
  });
}
