import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovino_mvp/main.dart';
import 'package:bovino_mvp/ui/common/app_drawer.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

Finder campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is CustomTextField && w.label == label),
  matching: find.byType(TextFormField),
);
Finder menu(String label) =>
    find.descendant(of: find.byType(AppDrawer), matching: find.text(label));
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<InventarioController> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = InventarioController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: MainWorkspaceShell(inventarioController: c),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'menú de 280 px sigue visible al registrar y conserva el borrador al cambiar de sección',
    (tester) async {
      await abrir(tester);
      expect(tester.getSize(find.byType(AppDrawer)).width, 280);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar Animal').first,
      );
      await tester.pumpAndSettle();
      expect(menu('Inventario'), findsOneWidget);
      expect(find.byType(AnimalForm), findsOneWidget);
      final estado = tester.state(find.byType(AnimalForm));
      await tester.ensureVisible(campo('Código de animal'));
      await tester.enterText(campo('Código de animal'), 'BORRADOR-123');
      await tester.tap(menu('Ciclo Reproductivo'));
      await tester.pumpAndSettle();
      expect(find.text('Control reproductivo del hato'), findsOneWidget);
      expect(menu('Inventario'), findsOneWidget);
      await tester.tap(menu('Inventario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver al registro'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(AnimalForm)), same(estado));
      expect(
        tester.widget<TextFormField>(campo('Código de animal')).controller!.text,
        'BORRADOR-123',
      );
      expect(menu('Configuración'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(menu('Inventario'));
      await tester.pumpAndSettle();
      expect(find.text('Volver al registro'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'menú permanece al consultar inventario sobre el registro y al abrir configuración',
    (tester) async {
      await abrir(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar Animal').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver inventario'));
      await tester.pumpAndSettle();
      expect(menu('Panel de Control'), findsOneWidget);
      expect(find.text('Volver al registro'), findsOneWidget);
      await tester.tap(find.text('Volver al registro'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalForm), findsOneWidget);
      await tester.tap(menu('Configuración'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Configurar Categorías'));
      await tester.tap(find.text('Configurar Categorías'));
      await tester.pumpAndSettle();
      expect(menu('Inventario'), findsOneWidget);
      expect(tester.getSize(find.byType(AppDrawer)).width, 280);
      expect(tester.takeException(), isNull);
    },
  );
}
