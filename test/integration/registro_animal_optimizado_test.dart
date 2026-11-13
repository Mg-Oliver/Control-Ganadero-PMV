import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:bovino_mvp/core/services/categoria_rules_service.dart';
import 'package:bovino_mvp/data/models/categoria_rule_model.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/common/custom_form_dropdown.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

Finder caja(String label) =>
    find.byWidgetPredicate((w) => w is CustomTextField && w.label == label);
Finder campo(String label) =>
    find.descendant(of: caja(label), matching: find.byType(TextFormField));
Finder lista(String label) => find.byWidgetPredicate(
  (w) => w is CustomFormDropdown<String> && w.label == label,
);
Future<void> abrir(WidgetTester tester, {double ancho = 1000}) async {
  tester.view.physicalSize = Size(ancho, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: testTheme,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: AnimalForm(fincas: []),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoriaRulesService.updateInstance(CategoriaRulesService());
  });
  testWidgets(
    'explotación y finca, identificación y progenitores en el orden solicitado',
    (tester) async {
      await abrir(tester);
      final filas = [
        [lista('Tipo de Explotación'), lista('Finca Actual')],
        [caja('Código de animal'), caja('Arete oficial'), caja('Nombre')],
        [lista('Seleccionar padre'), lista('Seleccionar madre (vaca)')],
        [lista('Sexo'), caja('Fecha de Nacimiento'), find.text('Edad actual')],
        [find.text('Categoría'), lista('Origen del Animal')],
      ];
      double anterior = -1;
      for (final fila in filas) {
        final y = tester.getTopLeft(fila.first).dy;
        expect(y, greaterThan(anterior));
        anterior = y;
        for (final campo in fila.skip(1)) {
          expect(tester.getTopLeft(campo).dy, closeTo(y, 1));
        }
        expect(
          tester.getTopLeft(fila[1]).dx,
          greaterThan(tester.getTopLeft(fila[0]).dx),
        );
        if (fila.length > 2) {
          expect(
            tester.getTopLeft(fila[2]).dx,
            greaterThan(tester.getTopLeft(fila[1]).dx),
          );
        }
      }
      expect(
        find.text('Apertura de Expediente Individual Bovino'),
        findsNothing,
      );
      for (final titulo in [
        '1. Identificación y Biometría',
        '2. Genética y Linaje',
        '3. Ubicación Actual y Manejo Productivo',
        '4. Marcas de Hierro y Señales Físicas',
        '5. Observaciones y Registro Fotográfico',
      ]) {
        expect(find.text(titulo), findsNothing);
      }
      expect(
        tester.widget<CustomTextField>(caja('Código de animal')).isRequired,
        isTrue,
      );
      expect(
        tester.widget<CustomTextField>(caja('Fecha de Nacimiento')).suffixIcon,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fecha y edad se recalculan en ambas direcciones sin calendario',
    (tester) async {
      await abrir(tester);
      final hoy = DateTime.now();
      final nacimiento = DateTime(hoy.year - 2, hoy.month, hoy.day);
      await tester.enterText(
        campo('Fecha de Nacimiento'),
        DateFormat('dd/MM/yyyy').format(nacimiento),
      );
      await tester.pump();
      expect(tester.widget<TextFormField>(campo('Años')).controller!.text, '2');
      expect(
        tester.widget<TextFormField>(campo('Meses')).controller!.text,
        '0',
      );
      expect(tester.widget<TextFormField>(campo('Días')).controller!.text, '0');
      await tester.enterText(campo('Días'), '10');
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(campo('Fecha de Nacimiento'))
            .controller!
            .text,
        DateFormat(
          'dd/MM/yyyy',
        ).format(nacimiento.subtract(const Duration(days: 10))),
      );
      expect(find.text('Aproximada'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
    },
  );
  testWidgets(
    'categoría cambia con fecha, partos y configuración sin permitir edición',
    (tester) async {
      await abrir(tester);
      final hoy = DateTime.now();
      await tester.enterText(
        campo('Fecha de Nacimiento'),
        DateFormat('dd/MM/yyyy').format(hoy),
      );
      await tester.pump();
      Text categoria() => tester.widget<Text>(
        find.byKey(const ValueKey('categoria_calculada')),
      );
      expect(categoria().data, 'Ternera');
      await tester.enterText(
        campo('Fecha de Nacimiento'),
        DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime(hoy.year - 2, hoy.month, hoy.day)),
      );
      await tester.pump();
      expect(categoria().data, 'Novilla');
      await tester.enterText(campo('Número de partos'), '1');
      await tester.pump();
      expect(categoria().data, 'Vaca');
      CategoriaRulesService.updateInstance(
        CategoriaRulesService(const [
          CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 0,
            edadMaximoMeses: -1,
            categoria: 'Categoría personalizada',
          ),
        ]),
      );
      await tester.pump();
      expect(categoria().data, 'Categoría personalizada');
      await tester.enterText(campo('Fecha de Nacimiento'), '31/02/2024');
      await tester.pump();
      expect(categoria().data, 'Por calcular');
    },
  );
  testWidgets(
    'en pantalla estrecha se apilan campos y se conserva el resto del registro',
    (tester) async {
      await abrir(tester, ancho: 390);
      expect(
        tester.getTopLeft(caja('Arete oficial')).dy,
        greaterThan(tester.getTopLeft(caja('Código de animal')).dy),
      );
      for (final label in [
        'Padre (Reproductor / Toro)',
        'Madre (Vaca / Donadora)',
        'Observaciones Sanitarias o Productivas Iniciales',
        'Fotografías del Animal (Máx. 3)',
      ]) {
        expect(find.text(label, findRichText: true), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
