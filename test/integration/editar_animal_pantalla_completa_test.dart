import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bovino_mvp/core/constants/columna_tabla.dart';
import 'package:bovino_mvp/core/services/app_feedback.dart';
import 'package:bovino_mvp/data/dev/seed_service.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/editar_animal_screen.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/entity_data_table.dart';
import '../helpers/test_theme.dart';

class _MockAnimalesService extends AnimalesService {
  AnimalModel? lastUpdated;

  @override
  Future<AnimalModel> actualizar(AnimalModel animal) async {
    lastUpdated = animal;
    return animal;
  }

  @override
  Future<List<AnimalModel>> obtenerPorFinca(String fincaId, {String? sexo}) async => [];
}

Widget _wrap(Widget child) => MaterialApp(
      theme: testTheme,
      scaffoldMessengerKey: AppFeedback.messengerKey,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Redirección a pantalla completa de edición con datos completos y guardado',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = InventarioController();
      SeedService.cargarEnControlador(controller);

      final animalEnTabla = controller.animalesFiltrados.first;

      await tester.pumpWidget(_wrap(
        Scaffold(
          body: EntityDataTable(
            controller: controller,
            columnasAnimalesActivas: kColumnasDefault,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Pulsa el botón editar en la tabla
      final editBtn = find.byIcon(Icons.edit_outlined).first;
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verifica que nos haya redirigido a EditarAnimalScreen
      expect(find.byType(EditarAnimalScreen), findsOneWidget);
      expect(
        find.text('Editar animal · ${animalEnTabla.areteManejo}'),
        findsOneWidget,
      );

      // Verifica que el banner de modificación con datos completos esté presente
      expect(
        find.textContaining('Modificación de Expediente Bovino'),
        findsOneWidget,
      );

      // Verifica que el botón de acción principal sea "Guardar Cambios"
      expect(find.text('Guardar Cambios'), findsOneWidget);

      // Verifica que los datos del animal estén pre-cargados
      expect(find.text(animalEnTabla.areteManejo), findsWidgets);
    },
  );

  testWidgets(
    'EditarAnimalScreen guarda cambios optimistas y notifica al controlador',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = InventarioController();
      SeedService.cargarEnControlador(controller);

      final mockService = _MockAnimalesService();
      final animal = controller.allAnimales.first;

      await tester.pumpWidget(_wrap(
        EditarAnimalScreen(
          animal: animal,
          controller: controller,
          animalesService: mockService,
        ),
      ));
      await tester.pumpAndSettle();

      // Encuentra el botón "Guardar Cambios" y pulsa
      final guardarBtn = find.widgetWithText(FilledButton, 'Guardar Cambios');
      expect(guardarBtn, findsOneWidget);

      await tester.ensureVisible(guardarBtn);
      await tester.pumpAndSettle();

      await tester.tap(guardarBtn);
      await tester.pumpAndSettle();

      // Debe haber llamado a actualizar en el servicio
      expect(mockService.lastUpdated, isNotNull);
      expect(mockService.lastUpdated!.id, equals(animal.id));
      expect(mockService.lastUpdated!.areteManejo, equals(animal.areteManejo));
    },
  );
}
