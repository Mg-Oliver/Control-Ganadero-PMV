import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/receptora_embriones.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/common/custom_form_dropdown.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

AnimalModel animal(
  String id, {
  String sexo = 'Hembra',
  GenealogiaModel? genealogia,
}) => AnimalModel(
  id: id,
  codigoSistema: id,
  areteManejo: id,
  sexo: sexo,
  razaPuraNombre: 'Holstein',
  razaEtiquetaDisplay: 'Holstein',
  tipoExplotacion: 'Lecheria',
  fechaNacimiento: DateTime(2020),
  origen: 'Nacido en la finca',
  fincaId: 'f1',
  fechaEntrada: DateTime(2024),
  numeroPartos: sexo == 'Hembra' ? 1 : 0,
  genealogia: genealogia,
  observaciones: 'Animal sano',
);

class _Service extends AnimalesService {
  AnimalModel? guardado;
  @override
  Future<AnimalModel> actualizar(AnimalModel animal) async {
    guardado = animal;
    return animal;
  }

  @override
  Future<List<AnimalModel>> consultarInventarioRelacional({
    String? fincaId,
    String? loteId,
    String? sexo,
    String? tipoExplotacion,
    String? estadoActual,
    bool? esRazaPura,
    String? razaPuraNombre,
    String? busqueda,
  }) async => [animal('PADRE', sexo: 'Macho'), animal('MADRE')];
}

Finder caja(String label) =>
    find.byWidgetPredicate((w) => w is CustomTextField && w.label == label);
Finder campo(String label) =>
    find.descendant(of: caja(label), matching: find.byType(TextFormField));
Finder lista(String label) => find.byWidgetPredicate(
  (w) => w is CustomFormDropdown<String> && w.label == label,
);
Future<_Service> _abrir(
  WidgetTester tester, {
  AnimalModel? edit,
  double ancho = 1060,
}) async {
  tester.view.physicalSize = Size(ancho, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final service = _Service();
  await tester.pumpWidget(
    MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            child: const Text('Abrir'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimalForm(
                        fincas: const [
                          FincaModel(
                            id: 'f1',
                            nombre: 'Finca',
                            identificador: 'F1',
                          ),
                        ],
                        animalAEditar: service.guardado ?? edit,
                        animalesService: service,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return service;
}

Future<void> concepcion(WidgetTester tester, String valor) async {
  await tester.ensureVisible(lista('Tipo de concepción'));
  await tester.tap(lista('Tipo de concepción'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(valor).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'partos se activa a 18 meses y un día y se desactiva para machos',
    (tester) async {
      await _abrir(tester);
      expect(
        tester.widget<CustomTextField>(caja('Número de partos')).enabled,
        isFalse,
      );
      for (final campoEdad in [('Años', '1'), ('Meses', '6'), ('Días', '0')]) {
        await tester.ensureVisible(campo(campoEdad.$1));
        await tester.enterText(campo(campoEdad.$1), campoEdad.$2);
      }
      await tester.pump();
      expect(
        tester.widget<CustomTextField>(caja('Número de partos')).enabled,
        isFalse,
      );
      await tester.enterText(campo('Días'), '1');
      await tester.pump();
      expect(
        tester.widget<CustomTextField>(caja('Número de partos')).enabled,
        isTrue,
      );
      await tester.enterText(campo('Número de partos'), '1');
      await tester.pump();
      expect(find.text('Vaca'), findsOneWidget);
      await tester.ensureVisible(lista('Sexo'));
      await tester.tap(lista('Sexo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Macho').last);
      await tester.pumpAndSettle();
      expect(caja('Número de partos'), findsNothing);
    },
  );
  testWidgets(
    'deshabilitar partos no borra un dato histórico al editar otros campos',
    (tester) async {
      final service = await _abrir(
        tester,
        edit: animal('JOVEN').copyWith(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 400)),
        ),
      );
      expect(
        tester.widget<CustomTextField>(caja('Número de partos')).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextFormField>(campo('Número de partos'))
            .controller!
            .text,
        '1',
      );
      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();
      expect(service.guardado!.numeroPartos, 1);
    },
  );
  for (final ancho in [1060.0, 390.0]) {
    testWidgets('padre y madre están al lado y cargan candidatos a $ancho px', (
      tester,
    ) async {
      await _abrir(tester, ancho: ancho);
      final padre = find.text('Padre (Reproductor / Toro)');
      final madre = find.text('Madre (Vaca / Donadora)');
      expect(
        tester.getTopLeft(padre).dy,
        closeTo(tester.getTopLeft(madre).dy, 1),
      );
      expect(
        tester.getTopLeft(madre).dx,
        greaterThan(tester.getTopLeft(padre).dx),
      );
      expect(
        tester
            .widget<CustomFormDropdown<String>>(lista('Seleccionar padre'))
            .items
            .length,
        2,
      );
      expect(
        tester
            .widget<CustomFormDropdown<String>>(
              lista('Seleccionar madre (vaca)'),
            )
            .items
            .length,
        2,
      );
      expect(find.text('Tipo de nacimiento'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'TE muestra receptora, guarda y restaura sin alterar la madre genética',
    (tester) async {
      final hijo = animal(
        'HIJO',
        genealogia: const GenealogiaModel(
          id: 'g',
          animalId: 'HIJO',
          padreId: 'PADRE',
          madreId: 'MADRE',
          tipoPruebaPaterna: 'Visual / Monta natural',
        ),
      );
      final service = await _abrir(tester, edit: hijo);
      expect(caja('Vaca receptora'), findsNothing);
      await concepcion(tester, 'Transferencia de embriones');
      expect(caja('Vaca receptora'), findsOneWidget);
      await tester.ensureVisible(campo('Vaca receptora'));
      await tester.enterText(campo('Vaca receptora'), 'RC-010 · Receptora');
      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();
      expect(
        ReceptoraEmbriones.extraer(service.guardado!.observaciones),
        'RC-010 · Receptora',
      );
      expect(service.guardado!.genealogia!.madreId, 'MADRE');
      expect(service.guardado!.genealogia!.padreId, 'PADRE');
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(campo('Vaca receptora')).controller!.text,
        'RC-010 · Receptora',
      );
      await concepcion(tester, 'Monta Natural');
      expect(caja('Vaca receptora'), findsNothing);
      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();
      expect(
        ReceptoraEmbriones.extraer(service.guardado!.observaciones),
        isNull,
      );
      expect(service.guardado!.observaciones, 'Animal sano');
    },
  );
}
