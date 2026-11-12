import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/services/reproduccion_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/reproduccion/reproduccion_screen.dart';
import '../helpers/test_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final ancho in [1440.0, 520.0]) {
    testWidgets(
      'ejemplo incluye indicadores, métodos y ventanas sin desbordarse a $ancho px',
      (tester) async {
        tester.view.physicalSize = Size(ancho, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: const Scaffold(body: ReproduccionScreen()),
          ),
        );
        await tester.pumpAndSettle();
        for (final texto in [
          '154 días',
          '82 días',
          '62%',
          '65%',
          '58%',
          '52%',
          '48%',
          'Celos por servir',
          'Diagnóstico de gestación',
          'Secados proyectados',
          'Partos inminentes',
        ]) {
          expect(find.text(texto), findsOneWidget);
        }
        expect(find.textContaining('no representan tu finca'), findsOneWidget);
        expect(await ReproduccionService().cargar(), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('estado real se guarda y se restaura sin datos de ejemplo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = InventarioController();
    addTearDown(controller.dispose);
    controller.registrarAnimalOptimista(
      AnimalModel(
        id: 'v1',
        codigoSistema: 'GAN1',
        areteManejo: 'VACA-REAL',
        sexo: 'Hembra',
        razaEtiquetaDisplay: 'Holstein',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2020),
        origen: 'Otro',
        fincaId: 'f1',
        fechaEntrada: DateTime(2024),
      ),
    );
    Widget app(Key key) => MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: ReproduccionScreen(key: key, inventarioController: controller),
      ),
    );
    await tester.pumpWidget(app(const ValueKey('primero')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi finca'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sin datos'),
      findsNWidgets(7),
    ); // Tres KPIs + cuatro métodos.
    expect(find.text('EJ-001 · Lucera'), findsNothing);
    final registrar = find.byTooltip('Registrar evento');
    await tester.ensureVisible(registrar);
    await tester.tap(registrar);
    await tester.pumpAndSettle();
    expect(find.text('Registrar evento reproductivo'), findsOneWidget);
    await tester.tap(find.text('Guardar evento'));
    await tester.pumpAndSettle();
    final datos = await ReproduccionService().cargar();
    expect(datos.single.animalId, 'v1');
    expect(datos.single.estadoInicial, 'Vacía');
    await tester.pumpWidget(app(const ValueKey('recarga')));
    await tester.pumpAndSettle();
    expect(
      find.text('Registros guardados solo en este navegador'),
      findsOneWidget,
    );
    expect(find.text('EJ-001 · Lucera'), findsNothing);
    expect(find.text('VACA-REAL · GAN1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
