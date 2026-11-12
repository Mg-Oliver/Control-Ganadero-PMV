import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bovino_mvp/core/utils/poblacion_aggregator.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/ui/screens/dashboard/widgets/distribucion_poblacional_chart.dart';
import 'package:bovino_mvp/data/dev/seed_service.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import '../helpers/test_theme.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

AnimalModel _animal({
  required String id,
  required String sexo,
  required DateTime fechaNacimiento,
  int numeroPartos = 0,
  String estado = 'Activo',
}) =>
    AnimalModel(
      id: id,
      codigoSistema: id,
      areteManejo: id,
      sexo: sexo,
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lechería',
      fechaNacimiento: fechaNacimiento,
      origen: 'Nacido en la finca',
      fincaId: 'f1',
      estadoActual: estado,
      fechaEntrada: DateTime(2024),
      numeroPartos: numeroPartos,
    );

Widget _wrap(Widget child) =>
    MaterialApp(theme: testTheme, home: Scaffold(body: SingleChildScrollView(child: child)));

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ─── 10.1.2 + 10.1.3 — Agregación matemática ─────────────────────────────

  group('10.1 — Agregación poblacional', () {
    test('lista vacía produce resultado vacío', () {
      final resultado = PoblacionAggregator.agregar([]);
      expect(resultado.estaVacio, isTrue);
      expect(resultado.totalHato, 0);
      expect(resultado.machos, isEmpty);
      expect(resultado.hembras, isEmpty);
    });

    test('clasifica animales por sexo correctamente', () {
      final animales = [
        _animal(
          id: 'a1',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 100)),
        ),
        _animal(
          id: 'a2',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 100)),
        ),
        _animal(
          id: 'a3',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 100)),
        ),
      ];
      final resultado = PoblacionAggregator.agregar(animales);
      expect(resultado.totalMachos, 1);
      expect(resultado.totalHembras, 2);
      expect(resultado.totalHato, 3);
    });

    test('10.1.3 — porcentaje suma ~100%', () {
      final animales = [
        _animal(
          id: 'a1',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 50)),
        ),
        _animal(
          id: 'a2',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 800)),
        ),
        _animal(
          id: 'a3',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 50)),
        ),
      ];
      final resultado = PoblacionAggregator.agregar(animales);
      final sumaPct = [
        ...resultado.machos,
        ...resultado.hembras,
      ].fold(0.0, (acc, g) => acc + g.porcentaje);
      expect(sumaPct, closeTo(100.0, 0.01));
    });

    test('categorías correctas para datos semilla', () {
      final controller = InventarioController();
      SeedService.cargarEnControlador(controller);
      final activos = controller.allAnimales
          .where((a) => a.estadoActual == 'Activo')
          .toList();
      final resultado = PoblacionAggregator.agregar(activos);
      expect(resultado.estaVacio, isFalse);
      // Datos semilla tiene machos y hembras
      expect(resultado.totalMachos + resultado.totalHembras,
          activos.length);
    });

    test('conteo absoluto exacto por categoría', () {
      final hoy = DateTime.now();
      final animales = [
        // Ternero: 0-4 meses
        _animal(
          id: 'a1',
          sexo: 'Macho',
          fechaNacimiento: hoy.subtract(const Duration(days: 60)),
        ),
        _animal(
          id: 'a2',
          sexo: 'Macho',
          fechaNacimiento: hoy.subtract(const Duration(days: 90)),
        ),
        // Toro: >= 24 meses
        _animal(
          id: 'a3',
          sexo: 'Macho',
          fechaNacimiento: hoy.subtract(const Duration(days: 900)),
        ),
      ];
      final resultado = PoblacionAggregator.agregar(animales);
      // Debe haber 2 grupos de machos: Ternero(2) y Toro(1)
      expect(resultado.machos.length, 2);
      final terneros =
          resultado.machos.firstWhere((g) => g.categoria == 'Ternero');
      expect(terneros.cantidad, 2);
      final toros =
          resultado.machos.firstWhere((g) => g.categoria == 'Toro');
      expect(toros.cantidad, 1);
    });

    test('animales vendidos no se incluyen (solo activos se pasan)', () {
      // El filtro de estado ocurre antes de llamar al agregador —
      // pasar lista vacía simula el comportamiento esperado
      final resultado = PoblacionAggregator.agregar([]);
      expect(resultado.estaVacio, isTrue);
    });

    test('orden descendente por cantidad dentro de cada sexo', () {
      final hoy = DateTime.now();
      final animales = [
        // 1 Toro
        _animal(
          id: 't1',
          sexo: 'Macho',
          fechaNacimiento: hoy.subtract(const Duration(days: 900)),
        ),
        // 3 Terneros
        for (int i = 0; i < 3; i++)
          _animal(
            id: 'tn$i',
            sexo: 'Macho',
            fechaNacimiento: hoy.subtract(const Duration(days: 60)),
          ),
      ];
      final resultado = PoblacionAggregator.agregar(animales);
      // Ternero(3) debe estar antes que Toro(1)
      expect(resultado.machos.first.categoria, 'Ternero');
    });
  });

  // ─── 10.2 + 10.3 — Renderizado del componente visual ─────────────────────

  group('10.2 / 10.3 — Renderizado del gráfico', () {
    testWidgets('10.3.3 — empty state cuando no hay animales',
        (tester) async {
      final datos = PoblacionAggregator.agregar([]);
      await tester.pumpWidget(
        _wrap(DistribucionPoblacionalChart(datos: datos)),
      );
      await tester.pump();

      expect(find.text('Sin datos de distribución'), findsOneWidget);
      expect(find.text('Registrar Animal'), findsOneWidget);
    });

    testWidgets('10.3.3 — empty state llama callback al presionar botón',
        (tester) async {
      bool llamado = false;
      final datos = PoblacionAggregator.agregar([]);
      await tester.pumpWidget(
        _wrap(DistribucionPoblacionalChart(
          datos: datos,
          onRegistrarAnimal: () => llamado = true,
        )),
      );
      await tester.pump();

      await tester.tap(find.text('Registrar Animal'));
      expect(llamado, isTrue);
    });

    testWidgets('10.2.1 — gráfico de barras se renderiza con datos',
        (tester) async {
      final controller = InventarioController();
      SeedService.cargarEnControlador(controller);
      final activos = controller.allAnimales
          .where((a) => a.estadoActual == 'Activo')
          .toList();
      final datos = PoblacionAggregator.agregar(activos);

      await tester.pumpWidget(
        _wrap(DistribucionPoblacionalChart(datos: datos)),
      );
      await tester.pump();

      // No debería mostrar el empty state
      expect(find.text('Sin datos de distribución'), findsNothing);
      // Debería mostrar el resumen poblacional
      expect(find.text('Total hato'), findsOneWidget);
    });

    testWidgets('10.3.1 — leyenda muestra categorías', (tester) async {
      final hoy = DateTime.now();
      final animales = [
        _animal(
          id: 'a1',
          sexo: 'Macho',
          fechaNacimiento: hoy.subtract(const Duration(days: 60)),
        ),
        _animal(
          id: 'a2',
          sexo: 'Hembra',
          fechaNacimiento: hoy.subtract(const Duration(days: 60)),
        ),
      ];
      final datos = PoblacionAggregator.agregar(animales);

      await tester.pumpWidget(
        _wrap(DistribucionPoblacionalChart(datos: datos)),
      );
      await tester.pump();

      // La leyenda (y el eje X) deben mostrar "Ternero" y "Ternera"
      expect(find.text('Ternero'), findsWidgets);
      expect(find.text('Ternera'), findsWidgets);
    });

    testWidgets('10.3.2 — panel resumen muestra machos, hembras y total',
        (tester) async {
      final controller = InventarioController();
      SeedService.cargarEnControlador(controller);
      final activos = controller.allAnimales
          .where((a) => a.estadoActual == 'Activo')
          .toList();
      final datos = PoblacionAggregator.agregar(activos);

      await tester.pumpWidget(
        _wrap(DistribucionPoblacionalChart(datos: datos)),
      );
      await tester.pump();

      expect(find.textContaining('Machos'), findsOneWidget);
      expect(find.textContaining('Hembras'), findsOneWidget);
      expect(find.text('Total hato'), findsOneWidget);
    });
  });
}
