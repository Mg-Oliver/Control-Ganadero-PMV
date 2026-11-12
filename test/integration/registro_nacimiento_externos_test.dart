import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

class _AnimalesMemoria extends AnimalesService {
  AnimalModel? registrado;
  @override
  Future<AnimalModel> registrar(
    AnimalModel animal, {
    GenealogiaModel? genealogia,
  }) async {
    registrado = animal.copyWith(
      id: 'padre-externo',
      codigoSistema: 'EXT-01',
      genealogia: genealogia,
    );
    return registrado!;
  }
}

const finca = FincaModel(id: 'f1', identificador: 'F1', nombre: 'Finca');

AnimalModel animal(
  String id, {
  bool externo = false,
  GenealogiaModel? genealogia,
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
  esExterno: externo,
  genealogia: genealogia,
);

Future<void> abrirFormulario(
  WidgetTester tester, {
  bool progenitor = false,
  AnimalesService? servicio,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnimalForm(
            animalesService: servicio,
            fincas: const [finca],
            preguntarPertenencia: progenitor,
            sexoInicial: progenitor ? 'Macho' : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is CustomTextField && w.label == label),
  matching: find.byType(TextFormField),
);

void main() {
  test(
    'externos siguen disponibles como ancestros y quedan fuera de existencias',
    () {
      final controller = InventarioController();
      addTearDown(controller.dispose);
      final padre = animal('padre', externo: true);
      final hijo = animal(
        'hijo',
        genealogia: const GenealogiaModel(
          id: 'g1',
          animalId: 'hijo',
          padreId: 'padre',
        ),
      );
      controller.registrarAnimalOptimista(padre);
      controller.registrarAnimalOptimista(hijo);
      expect(controller.animalesFiltrados.map((a) => a.id), ['hijo']);
      expect(controller.obtenerAnimalesDeFinca('f1').map((a) => a.id), [
        'hijo',
      ]);
      expect(
        controller.buscarAnimalPorId(hijo.genealogia!.padreId)?.id,
        'padre',
      );
      final restaurado = AnimalModel.fromJson(padre.toJson());
      expect(restaurado.esExterno, isTrue);
      expect(restaurado.copyWith(nombreAlias: 'Toro').esExterno, isTrue);
    },
  );

  testWidgets(
    'registrar padre externo guarda expediente completo y lo asigna al hijo',
    (tester) async {
      final servicio = _AnimalesMemoria();
      await abrirFormulario(tester, servicio: servicio);
      final registrar = find.text('Registrar').first;
      await tester.ensureVisible(registrar);
      await tester.tap(registrar);
      await tester.pumpAndSettle();
      expect(find.text('¿Forma parte de la finca?'), findsOneWidget);
      await tester.enterText(campo('Arete de Manejo'), 'TORO-EXT');
      final raza = find.text(
        'Buscar y seleccionar raza pura (Holstein, Brahman, Gyr...)',
      );
      await tester.ensureVisible(raza);
      await tester.tap(raza);
      await tester.pumpAndSettle();
      final busqueda = find.byType(TextField).last;
      await tester.enterText(busqueda, 'Holstein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Holstein').last);
      await tester.pumpAndSettle();
      final pertenencia = find.text('¿Forma parte de la finca?');
      await tester.ensureVisible(pertenencia);
      await tester.tap(pertenencia);
      await tester.pump();
      final guardar = find.text('Guardar Expediente Animal');
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(servicio.registrado?.esExterno, isTrue);
      expect(servicio.registrado?.sexo, 'Macho');
      expect(servicio.registrado?.razaPuraNombre, 'Holstein');
      expect(servicio.registrado?.loteId, isNull);
      expect(find.textContaining('TORO-EXT ·'), findsOneWidget);
    },
  );

  testWidgets('fecha se escribe directamente y rechaza días inexistentes', (
    tester,
  ) async {
    await abrirFormulario(tester);
    final fecha = campo('Fecha de Nacimiento');
    await tester.ensureVisible(fecha);
    await tester.enterText(fecha, '31/02/2024');
    final estado = tester.state<FormFieldState<String>>(fecha);
    expect(estado.validate(), isFalse);
    await tester.enterText(fecha, '29/02/2024');
    expect(estado.validate(), isTrue);
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(
      tester.getTopLeft(find.text('¿Fecha de nacimiento exacta conocida?')).dy,
      lessThan(tester.getTopLeft(fecha).dy),
    );
  });

  testWidgets(
    'edad calcula nacimiento aproximado y permite volver a fecha exacta',
    (tester) async {
      await abrirFormulario(tester);
      final modoEdad = find.widgetWithText(
        SwitchListTile,
        'Ingresar edad actual',
      );
      await tester.ensureVisible(modoEdad);
      await tester.tap(modoEdad);
      await tester.pump();
      final dias = campo('Días');
      await tester.ensureVisible(dias);
      await tester.enterText(dias, '10');
      await tester.pump();
      final fecha = tester.widget<TextFormField>(campo('Fecha de Nacimiento'));
      expect(
        fecha.controller!.text,
        DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.now().subtract(const Duration(days: 10))),
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: campo('Fecha de Nacimiento'),
                matching: find.byType(EditableText),
              ),
            )
            .readOnly,
        isTrue,
      );
      final exacta = find.widgetWithText(
        SwitchListTile,
        '¿Fecha de nacimiento exacta conocida?',
      );
      expect(tester.widget<SwitchListTile>(exacta).value, isFalse);
      await tester.ensureVisible(exacta);
      await tester.tap(exacta);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: campo('Fecha de Nacimiento'),
                matching: find.byType(EditableText),
              ),
            )
            .readOnly,
        isFalse,
      );
    },
  );

  testWidgets('progenitor usa formulario completo y pregunta pertenencia', (
    tester,
  ) async {
    await abrirFormulario(tester, progenitor: true);
    final pertenencia = find.widgetWithText(
      SwitchListTile,
      '¿Forma parte de la finca?',
    );
    expect(pertenencia, findsOneWidget);
    expect(
      find.text('5. Observaciones y Registro Fotográfico'),
      findsOneWidget,
    );
    await tester.tap(pertenencia);
    await tester.pump();
    expect(
      find.textContaining('Configuración > Animales externos'),
      findsOneWidget,
    );
    expect(find.text('Hato'), findsNothing);
    expect(find.text('Manga de Manejo Actual'), findsNothing);
    expect(find.text('Nueva manga'), findsNothing);
    expect(find.text('Tipo de Prueba / Respaldo'), findsNothing);
  });
}
