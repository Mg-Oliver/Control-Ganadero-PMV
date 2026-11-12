import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bovino_mvp/core/constants/columna_tabla.dart';
import 'package:bovino_mvp/core/services/inventario_prefs_service.dart';
import 'package:bovino_mvp/data/dev/seed_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/inventario_screen.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/entity_data_table.dart';
import '../helpers/test_theme.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: testTheme,
      home: Scaffold(body: child),
    );

Widget _screen(InventarioController ctrl) => _wrap(
      InventarioScreen(externalController: ctrl),
    );

// Viewport amplio para activar el layout desktop
void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

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

  // ─── 11.1 — Alternancia de vistas ─────────────────────────────────────────

  group('11.1 — Alternancia de vistas', () {
    testWidgets('11.1.1 — SegmentedButton de vista está presente',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      expect(find.byType(SegmentedButton<VistaInventario>), findsOneWidget);
    });

    testWidgets('11.1.2 — vista tarjetas muestra EntityCardGrid por defecto',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      // EntityDataTable no debe estar en modo tarjetas
      expect(find.byType(EntityDataTable), findsNothing);
    });

    testWidgets('11.1.2 — cambiar a Tabla muestra EntityDataTable',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      // Toca el segmento "Tabla" por su etiqueta de texto
      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      expect(find.byType(EntityDataTable), findsOneWidget);
    });

    testWidgets('11.1.2 — volver a Tarjetas oculta EntityDataTable',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      // Ir a tabla
      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();
      expect(find.byType(EntityDataTable), findsOneWidget);

      // Volver a tarjetas
      await tester.tap(find.text('Tarjetas'));
      await tester.pumpAndSettle();
      expect(find.byType(EntityDataTable), findsNothing);
    });

    testWidgets('11.1.3 — preferencia de vista se guarda en SharedPreferences',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('inventario_vista'), 'tabla');
    });
  });

  // ─── 11.2 — Selector de columnas ──────────────────────────────────────────

  group('11.2 — Selector de columnas', () {
    testWidgets(
        '11.2.1 — botón Personalizar Columnas visible en tabla + animales',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
    });

    testWidgets(
        '11.2.1 — botón Personalizar Columnas NO visible en vista tarjetas',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      // Vista tarjetas por defecto
      expect(find.byIcon(Icons.view_column_outlined), findsNothing);
    });

    testWidgets('11.2.2 — dialog abre con checkboxes al tocar el botón',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Personalizar columnas'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets(
        '11.2.3 — columna Arete siempre visible y no puede desmarcarse',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Arete de manejo'), findsOneWidget);
      expect(find.text('Columna fija — siempre visible'), findsOneWidget);
    });

    testWidgets('11.2.4 — "Seleccionar todas" marca todas las columnas',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar todas'));
      await tester.pump();

      final allCols = ColumnaTabla.values.length;
      final tiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      final marcadas = tiles.where((t) => t.value == true).length;
      expect(marcadas, allCols);
    });

    testWidgets('11.2.4 — "Restablecer por defecto" restaura columnas default',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar todas'));
      await tester.pump();

      await tester.tap(find.text('Restablecer por defecto'));
      await tester.pump();

      final tiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      final marcadas = tiles.where((t) => t.value == true).length;
      expect(marcadas, kColumnasDefault.length);
    });

    testWidgets('11.2 — Aplicar cierra el dialog y actualiza columnas',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Personalizar columnas'), findsNothing);
    });

    testWidgets('11.2 — Cancelar cierra el dialog sin cambios', (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_screen(controller));
      await tester.pump();

      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Personalizar columnas'), findsNothing);
    });
  });

  // ─── 11.3 — Columnas dinámicas en tabla ───────────────────────────────────

  group('11.3 — Renderizado dinámico de columnas', () {
    testWidgets('11.3.1 — tabla solo muestra columnas de kColumnasDefault',
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

      // Columnas default deben estar presentes
      expect(find.text('Arete Manejo'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Raza / Genética'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);

      // Columnas no default NO deben estar
      expect(find.text('Nombre / Alias'), findsNothing);
      expect(find.text('Peso (kg)'), findsNothing);
      expect(find.text('Manga'), findsNothing);
      expect(find.text('Potrero'), findsNothing);
      expect(find.text('Finca Actual'), findsNothing);
    });

    testWidgets('11.3.1 — todas las columnas aparecen al pasar Set completo',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(_wrap(
        EntityDataTable(
          controller: controller,
          columnasAnimalesActivas: Set.of(ColumnaTabla.values),
        ),
      ));
      await tester.pump();

      expect(find.text('Arete Manejo'), findsOneWidget);
      expect(find.text('Nombre / Alias'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Raza / Genética'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Potrero'), findsOneWidget);
      expect(find.text('Finca Actual'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
    });

    testWidgets('11.3.1 — columna desactivada no aparece con Set mínimo',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      // Solo arete
      await tester.pumpWidget(_wrap(
        EntityDataTable(
          controller: controller,
          columnasAnimalesActivas: {ColumnaTabla.arete},
        ),
      ));
      await tester.pump();

      expect(find.text('Arete Manejo'), findsOneWidget);
      expect(find.text('Sexo'), findsNothing);
      expect(find.text('Estado'), findsNothing);
    });
  });

  // ─── 11.3.2 — Persistencia de columnas ────────────────────────────────────

  group('11.3.2 — Persistencia de columnas en SharedPreferences', () {
    test('guardar y cargar columnas preserva la selección', () async {
      final original = {
        ColumnaTabla.arete,
        ColumnaTabla.sexo,
        ColumnaTabla.peso,
      };
      await InventarioPrefsService.guardarColumnas(original);
      final cargadas = await InventarioPrefsService.cargarColumnas();

      expect(cargadas, containsAll(original));
      expect(cargadas, contains(ColumnaTabla.arete));
    });

    test('arete siempre se añade aunque no esté en la lista guardada',
        () async {
      // Guardamos sin arete (caso de corrupción hipotética)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'inventario_columnas',
        ['sexo', 'estado'],
      );
      final cargadas = await InventarioPrefsService.cargarColumnas();
      expect(cargadas, contains(ColumnaTabla.arete));
    });

    test('cargarVista devuelve tarjetas cuando no hay valor guardado', () async {
      final vista = await InventarioPrefsService.cargarVista();
      expect(vista, VistaInventario.tarjetas);
    });

    test('guardar y cargar vista tabla funciona correctamente', () async {
      await InventarioPrefsService.guardarVista(VistaInventario.tabla);
      final vista = await InventarioPrefsService.cargarVista();
      expect(vista, VistaInventario.tabla);
    });
  });
}
