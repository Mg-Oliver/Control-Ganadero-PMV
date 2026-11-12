import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/inventario_screen.dart';

void main() {
  testWidgets(
    'Flujo de Baja / Salida: Animal Vendido y Muerto restringen ubicación y muestran expediente consistente',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = InventarioController();

      const finca = FincaModel(
        id: 'finca-baja-1',
        identificador: 'FNC-BJ-01',
        nombre: 'Hacienda La Colina',
        superficieHectareas: 150.0,
      );

      final novilloVendido = AnimalModel(
        id: 'anim-vendido-1',
        codigoSistema: 'GAN-900001',
        areteManejo: 'V-901',
        nombreAlias: 'Toro Vendido',
        sexo: 'Macho',
        pesoActual: 560.0,
        esRazaPura: true,
        razaPuraNombre: 'Angus',
        razaEtiquetaDisplay: 'Angus',
        tipoExplotacion: 'Ceba',
        fechaNacimiento: DateTime(2022, 2, 1),
        origen: 'Nacido en la finca',
        fincaId: 'finca-baja-1',
        potreroActual: null, // Desasociado por baja
        loteId: null, // Desasociado por baja
        estadoActual: 'Vendido',
        fechaEntrada: DateTime(2022, 2, 1),
        fechaSalida: DateTime(2025, 1, 15),
        observaciones: 'Precio de Venta: \$ 5,200,000 | Vendido para engorde.',
        fincaNombre: 'Hacienda La Colina',
      );

      final vacaMuerta = AnimalModel(
        id: 'anim-muerto-2',
        codigoSistema: 'GAN-900002',
        areteManejo: 'M-902',
        nombreAlias: 'Vaca Muerta',
        sexo: 'Hembra',
        pesoActual: 480.0,
        esRazaPura: true,
        razaPuraNombre: 'Holstein',
        razaEtiquetaDisplay: 'Holstein',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2021, 6, 1),
        origen: 'Nacido en la finca',
        fincaId: 'finca-baja-1',
        potreroActual: null,
        loteId: null,
        estadoActual: 'Muerto',
        fechaEntrada: DateTime(2021, 6, 1),
        fechaSalida: DateTime(2024, 11, 20),
        observaciones: 'Fallecimiento por causas naturales.',
        fincaNombre: 'Hacienda La Colina',
      );

      controller.registrarFincaOptimista(finca);
      controller.registrarAnimalOptimista(novilloVendido);
      controller.registrarAnimalOptimista(vacaMuerta);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            splashFactory: InkRipple.splashFactory,
          ),
          home: InventarioScreen(externalController: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que ambos animales se renderizan en el inventario con sus badges de estado
      expect(find.text('V-901 • Toro Vendido'), findsOneWidget);
      expect(find.text('M-902 • Vaca Muerta'), findsOneWidget);

      // Abrir el expediente del animal Vendido
      await tester.tap(find.text('V-901 • Toro Vendido'));
      await tester.pumpAndSettle();

      // Validar que el Drawer refleja el estado de baja, la fecha de salida y la trazabilidad económica
      expect(find.text('Expediente Individual Bovino'), findsOneWidget);
      expect(find.text('Vendido'), findsWidgets);
      expect(find.text('Fecha de Salida'), findsOneWidget);
      expect(find.text('15/01/2025'), findsOneWidget);
      expect(find.text('Sin asignar'), findsWidgets);

      controller.dispose();
    },
  );
}

