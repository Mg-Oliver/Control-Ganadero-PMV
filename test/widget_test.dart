import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/models/genealogia_model.dart';
import 'package:bovino_mvp/data/models/lote_model.dart';
import 'package:bovino_mvp/main.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/inventario_screen.dart';

void main() {
  testWidgets(
    'Panel de Control es la pantalla inicial y el menú lateral fijo navega a todas las secciones sin hamburguesa',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const BovinoApp());
      await tester.pumpAndSettle();

      // Verifica que no haya ícono de menú de hamburguesa
      expect(find.byIcon(Icons.menu), findsNothing);

      // Verifica que el título del AppBar sea "Panel de Control" por defecto
      expect(find.text('Panel de Control'), findsWidgets);

      // Verifica que la pestaña "Expediente" ya NO esté en el menú lateral
      expect(find.text('Expediente'), findsNothing);

      // Verifica que las opciones del menú fijo estén visibles
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Ciclo Reproductivo'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);

      // Navega directamente a "Inventario" desde el menú lateral fijo
      await tester.tap(find.text('Inventario'));
      await tester.pumpAndSettle();

      expect(find.text('Catálogo General Bovino'), findsOneWidget);
      expect(find.text('Inventario'), findsWidgets);

      // Navega a "Ciclo Reproductivo"
      await tester.tap(find.text('Ciclo Reproductivo'));
      await tester.pumpAndSettle();

      expect(
        find.text('Este módulo estará disponible próximamente.'),
        findsOneWidget,
      );
      expect(find.text('Ciclo Reproductivo'), findsWidgets);

      // Navega a "Configuración"
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Conexión a Supabase'), findsOneWidget);
      expect(find.text('Configuración'), findsWidgets);

      // Regresa al Panel de Control
      await tester.tap(find.text('Panel de Control').first);
      await tester.pumpAndSettle();

      expect(find.text('Resumen del Hato'), findsOneWidget);
      expect(find.text('Accesos Rápidos'), findsOneWidget);

      // Verifica que el botón principal de registrar animal abra la pantalla de creación
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar Animal'));
      await tester.pumpAndSettle();

      expect(
        find.text('Control Ganadero Bovino • Registro y Altas'),
        findsOneWidget,
      );
      expect(find.text('+ Nuevo Animal'), findsOneWidget);
    },
  );

  testWidgets(
    'Inventario 3 columnas: filtra animales, abre Drawer y navega por genealogía interactiva',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = InventarioController();

      const finca = FincaModel(
        id: 'finca-1',
        identificador: 'FNC-01',
        nombre: 'Hacienda El Roble',
        superficieHectareas: 120.5,
        fuentesAgua: ['Quebrada', 'Pozo'],
      );

      const lote = LoteModel(
        id: 'lote-1',
        fincaId: 'finca-1',
        identificador: 'LOT-01',
        nombre: 'Ordeño Alta Producción',
        propositoProductivo: 'Lecheria',
        metaGananciaPesoDiaria: 0.85,
        fincaNombre: 'Hacienda El Roble',
      );

      final toroPadre = AnimalModel(
        id: 'toro-1',
        codigoSistema: 'GAN-000001',
        areteManejo: 'T-100',
        nombreAlias: 'Emperador',
        sexo: 'Macho',
        pesoActual: 780.0,
        esRazaPura: true,
        razaPuraNombre: 'Simmental',
        razaEtiquetaDisplay: 'Simmental',
        tipoExplotacion: 'Doble Proposito',
        fechaNacimiento: DateTime(2022, 3, 15),
        origen: 'Nacido en la finca',
        fincaId: 'finca-1',
        fechaEntrada: DateTime(2022, 3, 15),
      );

      final hijaF1 = AnimalModel(
        id: 'cria-2',
        codigoSistema: 'GAN-000002',
        areteManejo: 'C-205',
        nombreAlias: 'Princesa',
        sexo: 'Hembra',
        pesoActual: 340.0,
        esRazaPura: false,
        composicionCruces: const [
          {'raza': 'Simmental', 'fraccion': '1/2'},
          {'raza': 'Brahman Gris', 'fraccion': '1/2'},
        ],
        razaEtiquetaDisplay: 'Simbrah F1 (1/2 Simmental, 1/2 Brahman Gris)',
        tipoExplotacion: 'Doble Proposito',
        fechaNacimiento: DateTime(2025, 4, 10),
        origen: 'Nacido en la finca',
        fincaId: 'finca-1',
        loteId: 'lote-1',
        fechaEntrada: DateTime(2025, 4, 10),
        marcasHierro: const MarcasHierro(
          ubicacionCuerpo: 'Pierna derecha',
          marcasOrejas: 'Muesca V',
          colorMarcas: 'Hierro caliente',
          observacionHierro: 'Marca HR',
        ),
        genealogia: const GenealogiaModel(
          id: 'gen-1',
          animalId: 'cria-2',
          padreId: 'toro-1',
          tipoPruebaPaterna: 'ADN',
          madreExternaReferencia: 'Donadora Brahman #88',
          tipoPruebaMaterna: 'Inseminacion',
        ),
      );

      controller.registrarFincaOptimista(finca);
      controller.registrarLoteOptimista(lote);
      controller.registrarAnimalOptimista(toroPadre);
      controller.registrarAnimalOptimista(hijaF1);

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

      // Verifica renderizado de sidebar, tarjetas y tabla en 3 columnas
      expect(find.text('SECCIÓN DEL CATÁLOGO'), findsOneWidget);
      expect(find.text('C-205 • Princesa'), findsOneWidget);
      expect(find.text('T-100 • Emperador'), findsOneWidget);

      // Filtra por Cruces / F1 en el sidebar
      await tester.ensureVisible(find.text('Cruces / F1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cruces / F1'));
      await tester.pumpAndSettle();
      expect(find.text('C-205 • Princesa'), findsOneWidget);
      expect(find.text('T-100 • Emperador'), findsNothing);

      // Abre el Drawer Lateral Derecho haciendo clic en la tarjeta de Princesa
      await tester.tap(find.text('C-205 • Princesa'));
      await tester.pumpAndSettle();

      expect(find.text('Expediente Individual Bovino'), findsOneWidget);
      expect(find.text('Pierna derecha'), findsOneWidget);
      expect(find.text('Arete T-100 • "Emperador"'), findsOneWidget);

      // Navega interactivamente al expediente del Padre desde el árbol genealógico
      await tester.ensureVisible(find.text('Arete T-100 • "Emperador"'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arete T-100 • "Emperador"'));
      await tester.pumpAndSettle();

      expect(find.text('Volver a Arete C-205'), findsOneWidget);
      expect(find.text('Arete T-100 "Emperador"'), findsOneWidget);

      controller.dispose();
    },
  );
}
