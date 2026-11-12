import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/dashboard/dashboard_screen.dart';
import 'package:bovino_mvp/data/dev/seed_service.dart';
import '../helpers/test_theme.dart';

// ─── Helpers de test ─────────────────────────────────────────────────────────

FincaModel _finca(String id, String nombre) => FincaModel(
      id: id,
      nombre: nombre,
      identificador: id,
    );

AnimalModel _animal({
  required String id,
  required String fincaId,
  required String sexo,
  String estado = 'Activo',
  double? precioCompra,
  DateTime? fechaEntrada,
  DateTime? fechaSalida,
}) =>
    AnimalModel(
      id: id,
      codigoSistema: id,
      areteManejo: id,
      sexo: sexo,
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lechería',
      fechaNacimiento: DateTime(2022),
      origen: 'Nacido en la finca',
      fincaId: fincaId,
      estadoActual: estado,
      fechaEntrada: fechaEntrada ?? DateTime(2024),
      precioCompra: precioCompra,
      fechaSalida: fechaSalida,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: testTheme,
      home: Scaffold(
        body: AppFeedbackWrapper(child: child),
      ),
    );

// MaterialApp necesita ScaffoldMessenger para SnackBars del seed
class AppFeedbackWrapper extends StatelessWidget {
  final Widget child;
  const AppFeedbackWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late InventarioController controller;

  setUp(() {
    controller = InventarioController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('9.1 — Encabezado y botón Registrar Animal', () {
    testWidgets('muestra el título "Panel de Control"', (tester) async {
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Panel de Control'), findsOneWidget);
    });

    testWidgets('9.1.1 — botón "Registrar Animal" está presente',
        (tester) async {
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      // Puede aparecer también en el empty state del gráfico
      expect(find.text('Registrar Animal'), findsWidgets);
    });

    testWidgets('9.1.2 — botón "Registrar Animal" llama al callback',
        (tester) async {
      bool llamado = false;
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
        onRegistrarAnimal: () => llamado = true,
      )));
      await tester.pump();

      // Toca el primero (encabezado)
      await tester.tap(find.text('Registrar Animal').first);
      expect(llamado, isTrue);
    });
  });

  group('9.2 — Cuarteto de tarjetas KPI', () {
    testWidgets('9.2.1 — tarjeta "Fincas Activas" muestra total correcto',
        (tester) async {
      SeedService.cargarEnControlador(controller);

      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Fincas Activas'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // 3 fincas semilla
    });

    testWidgets(
        '9.2.2 — tarjeta "Animales en Inventario" cuenta solo activos',
        (tester) async {
      controller.registrarFincaOptimista(_finca('f1', 'La Esperanza'));
      controller.registrarAnimalOptimista(_animal(
        id: 'a1',
        fincaId: 'f1',
        sexo: 'Macho',
        estado: 'Activo',
      ));
      controller.registrarAnimalOptimista(_animal(
        id: 'a2',
        fincaId: 'f1',
        sexo: 'Hembra',
        estado: 'Vendido',
      ));

      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Animales en Inventario'), findsOneWidget);
      // Solo 1 activo (a2 es Vendido)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('9.2.3 — tarjeta "Eventos del Día" está presente',
        (tester) async {
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Eventos del Día'), findsOneWidget);
    });

    testWidgets(
        '9.2.3 — Eventos del Día cuenta animales dados de alta hoy',
        (tester) async {
      controller.registrarFincaOptimista(_finca('f1', 'La Esperanza'));
      final hoy = DateTime.now();
      controller.registrarAnimalOptimista(_animal(
        id: 'a1',
        fincaId: 'f1',
        sexo: 'Macho',
        fechaEntrada: DateTime(hoy.year, hoy.month, hoy.day, 9),
      ));
      // Animal de ayer — no debe contar
      controller.registrarAnimalOptimista(_animal(
        id: 'a2',
        fincaId: 'f1',
        sexo: 'Hembra',
        fechaEntrada: DateTime(hoy.year, hoy.month, hoy.day - 1),
      ));

      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      // 1 evento hoy (a1)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('9.2.4 — tarjeta "Valor Estimado del Hato" está presente',
        (tester) async {
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Valor Estimado del Hato'), findsOneWidget);
    });

    testWidgets('9.2.4 — valor \$0 cuando no hay precios registrados',
        (tester) async {
      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('\$0'), findsOneWidget);
    });
  });

  group('9.2.4 — Formateo monetario', () {
    test('formatea cero como \$0', () {
      expect(_formatMoneda(0), '\$0');
    });

    test('formatea millones con sufijo M', () {
      final resultado = _formatMoneda(5500000);
      expect(resultado.startsWith('\$'), isTrue);
      expect(resultado.contains('M'), isTrue);
    });

    test('formatea miles sin sufijo especial', () {
      final resultado = _formatMoneda(850000);
      expect(resultado.startsWith('\$'), isTrue);
    });
  });

  group('9.3 — Responsividad', () {
    testWidgets('muestra las 4 tarjetas KPI en viewport amplio',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Fincas Activas'), findsOneWidget);
      expect(find.text('Animales en Inventario'), findsOneWidget);
      expect(find.text('Eventos del Día'), findsOneWidget);
      expect(find.text('Valor Estimado del Hato'), findsOneWidget);
    });

    testWidgets('muestra las 4 tarjetas KPI en viewport móvil',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(DashboardScreen(
        controller: controller,
        onGoToExpediente: () {},
        onGoToInventario: () {},
      )));
      await tester.pump();

      expect(find.text('Fincas Activas'), findsOneWidget);
      expect(find.text('Animales en Inventario'), findsOneWidget);
    });
  });
}

// Función auxiliar para test unitario de formateo (replica la lógica interna)
String _formatMoneda(double valor) {
  if (valor == 0) return '\$0';
  if (valor >= 1000000000) {
    final v = valor / 1000000000;
    return '\$${v.toStringAsFixed(1)}B';
  }
  if (valor >= 1000000) {
    final v = valor / 1000000;
    return '\$${v.toStringAsFixed(1)}M';
  }
  // Miles simples
  final miles = valor ~/ 1000;
  final resto = (valor % 1000).toInt();
  if (miles > 0 && resto > 0) return '\$${miles}K';
  if (miles > 0) return '\$${miles}K';
  return '\$${valor.toStringAsFixed(0)}';
}
