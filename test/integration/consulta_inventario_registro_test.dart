import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/screens/creacion/creacion_screen.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import 'package:bovino_mvp/ui/screens/inventario/inventario_screen.dart';
import '../helpers/test_theme.dart';

Finder campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is CustomTextField && w.label == label),
  matching: find.byType(TextFormField),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final boton in [true, false]) {
    testWidgets(
      'conserva el registro al consultar inventario y volver con ${boton ? "botón" : "flecha atrás"}',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = InventarioController();
        addTearDown(controller.dispose);
        controller.registrarAnimalOptimista(
          AnimalModel(
            id: 'referencia',
            codigoSistema: 'GAN-001',
            areteManejo: 'REFERENCIA-001',
            sexo: 'Hembra',
            razaEtiquetaDisplay: 'Holstein',
            tipoExplotacion: 'Lecheria',
            fechaNacimiento: DateTime(2020),
            origen: 'Otro',
            fincaId: 'f1',
            fechaEntrada: DateTime(2024),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: CreacionScreen(
              initialTab: ModuloCreacionTab.animal,
              inventarioController: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final estado = tester.state(find.byType(AnimalForm));
        await tester.ensureVisible(campo('Arete de Manejo'));
        await tester.enterText(campo('Arete de Manejo'), 'NUEVO-123');
        await tester.ensureVisible(campo('Nombre o Alias'));
        await tester.enterText(campo('Nombre o Alias'), 'Lucera');
        await tester.ensureVisible(campo('Fecha de Nacimiento'));
        await tester.enterText(campo('Fecha de Nacimiento'), '15/03/2024');
        for (var visita = 0; visita < 2; visita++) {
          final ver = find.text('Ver inventario');
          await tester.ensureVisible(ver);
          await tester.tap(ver);
          await tester.pumpAndSettle();
          expect(find.byType(InventarioScreen), findsOneWidget);
          expect(find.textContaining('REFERENCIA-001'), findsWidgets);
          expect(find.text('Volver al registro'), findsOneWidget);
          if (boton) {
            await tester.tap(find.text('Volver al registro'));
          } else {
            await tester.pageBack();
          }
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(AnimalForm)), same(estado));
          expect(
            tester
                .widget<TextFormField>(campo('Arete de Manejo'))
                .controller!
                .text,
            'NUEVO-123',
          );
          expect(
            tester
                .widget<TextFormField>(campo('Nombre o Alias'))
                .controller!
                .text,
            'Lucera',
          );
          expect(
            tester
                .widget<TextFormField>(campo('Fecha de Nacimiento'))
                .controller!
                .text,
            '15/03/2024',
          );
        }
        expect(controller.allAnimales.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('inventario normal no ofrece volver a un registro inexistente', (
    tester,
  ) async {
    final controller = InventarioController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: InventarioScreen(externalController: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Volver al registro'), findsNothing);
  });
}
