import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/inventario_screen.dart';

void main() {
  testWidgets(
    'Navegación Genealógica en Drawer: Salto interactivo entre padre e hijo y retorno limpio con historial',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = InventarioController();

      const finca = FincaModel(
        id: 'finca-gen-1',
        identificador: 'FNC-GEN-01',
        nombre: 'Hacienda El Porvenir',
        superficieHectareas: 210.0,
      );

      final toroPadre = AnimalModel(
        id: 'toro-progenitor',
        codigoSistema: 'GAN-800001',
        areteManejo: 'TR-PROG',
        nombreAlias: 'Toro Campeón Padre',
        sexo: 'Macho',
        pesoActual: 890.0,
        esRazaPura: true,
        razaPuraNombre: 'Gyr Lechero',
        razaEtiquetaDisplay: 'Gyr Lechero',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2020, 3, 10),
        origen: 'Nacido en la finca',
        fincaId: 'finca-gen-1',
        fechaEntrada: DateTime(2020, 3, 10),
      );

      final terneroHijo = AnimalModel(
        id: 'ternero-descendiente',
        codigoSistema: 'GAN-800002',
        areteManejo: 'CR-DESC',
        nombreAlias: 'Ternero Sucesor',
        sexo: 'Macho',
        pesoActual: 240.0,
        esRazaPura: true,
        razaPuraNombre: 'Gyr Lechero',
        razaEtiquetaDisplay: 'Gyr Lechero',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2025, 4, 1),
        origen: 'Nacido en la finca',
        fincaId: 'finca-gen-1',
        fechaEntrada: DateTime(2025, 4, 1),
        genealogia: const GenealogiaModel(
          id: 'gen-sucesor',
          animalId: 'ternero-descendiente',
          padreId: 'toro-progenitor',
          tipoPruebaPaterna: 'ADN',
        ),
      );

      controller.registrarFincaOptimista(finca);
      controller.registrarAnimalOptimista(toroPadre);
      controller.registrarAnimalOptimista(terneroHijo);

      await tester.pumpWidget(
        MaterialApp(
          home: InventarioScreen(externalController: controller),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Abrir expediente del hijo
      expect(find.text('CR-DESC • Ternero Sucesor'), findsOneWidget);
      await tester.tap(find.text('CR-DESC • Ternero Sucesor'));
      await tester.pumpAndSettle();

      expect(find.text('Expediente Individual Bovino'), findsOneWidget);
      expect(find.text('Arete CR-DESC "Ternero Sucesor"'), findsOneWidget);

      // 2. Localizar y pulsar la tarjeta interactiva del Padre en el árbol genealógico
      await tester.ensureVisible(find.text('Arete TR-PROG • "Toro Campeón Padre"'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arete TR-PROG • "Toro Campeón Padre"'));
      await tester.pumpAndSettle();

      // 3. Validar que el Drawer ahora despliega el expediente del Padre y ofrece botón de retorno
      expect(find.text('Arete TR-PROG "Toro Campeón Padre"'), findsOneWidget);
      expect(find.text('Volver a Arete CR-DESC'), findsOneWidget);

      // 4. Pulsar el botón de volver y validar que retorna al expediente del hijo
      await tester.ensureVisible(find.text('Volver a Arete CR-DESC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver a Arete CR-DESC'));
      await tester.pumpAndSettle();

      expect(find.text('Arete CR-DESC "Ternero Sucesor"'), findsOneWidget);

      controller.dispose();
    },
  );
}

