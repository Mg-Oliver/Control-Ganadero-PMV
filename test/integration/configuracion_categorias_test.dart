import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bovino_mvp/core/services/categoria_rules_service.dart';
import 'package:bovino_mvp/core/utils/categoria_rules_validator.dart';
import 'package:bovino_mvp/data/models/categoria_rule_model.dart';
import 'package:bovino_mvp/ui/screens/configuracion/configuracion_categorias_screen.dart';
import '../helpers/test_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Restaurar el singleton a las reglas por defecto antes de cada test
    CategoriaRulesService.updateInstance(CategoriaRulesService());
  });

  // ─── 8.3 — Validador de consistencia ──────────────────────────────────────

  group('8.3.1 — Detección de traslapes de edad', () {
    test('sin traslapes en reglas predeterminadas', () {
      final err = CategoriaRulesValidator.validarTraslapes(
        CategoriaRulesService.reglasDefault,
      );
      expect(err, isNull);
    });

    test('detecta traslape entre dos reglas de Macho', () {
      const reglas = [
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: 10,
          categoria: 'Ternero',
        ),
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 8,
          edadMaximoMeses: 20,
          categoria: 'Novillo',
        ),
      ];
      final err = CategoriaRulesValidator.validarTraslapes(reglas);
      expect(err, isNotNull);
      expect(err, contains('Ternero'));
      expect(err, contains('Novillo'));
    });

    test('detecta traslape cuando ambas reglas tienen rango ilimitado', () {
      const reglas = [
        CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 5,
          edadMaximoMeses: -1,
          categoria: 'Novilla',
        ),
        CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 12,
          edadMaximoMeses: -1,
          categoria: 'Vaquilla',
        ),
      ];
      final err = CategoriaRulesValidator.validarTraslapes(reglas);
      expect(err, isNotNull);
    });

    test('no detecta traslape cuando los rangos son contiguos pero no solapados',
        () {
      const reglas = [
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: 4,
          categoria: 'Ternero',
        ),
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 5,
          edadMaximoMeses: 23,
          categoria: 'Novillo',
        ),
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 24,
          edadMaximoMeses: -1,
          categoria: 'Toro',
        ),
      ];
      final err = CategoriaRulesValidator.validarTraslapes(reglas);
      expect(err, isNull);
    });

    test('las reglas parto se ignoran en la detección de traslapes', () {
      const reglas = [
        CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 0,
          edadMaximoMeses: -1,
          requiereParto: true,
          categoria: 'Vaca',
        ),
        CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 0,
          edadMaximoMeses: 4,
          categoria: 'Ternera',
        ),
        CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 5,
          edadMaximoMeses: -1,
          categoria: 'Novilla',
        ),
      ];
      final err = CategoriaRulesValidator.validarTraslapes(reglas);
      expect(err, isNull);
    });
  });

  group('8.3.2 — Validación de rangos', () {
    test('edad mínima negativa es inválida', () {
      final err = CategoriaRulesValidator.validarRango(-1, 10);
      expect(err, isNotNull);
    });

    test('max igual a min es inválido', () {
      final err = CategoriaRulesValidator.validarRango(5, 5);
      expect(err, isNotNull);
    });

    test('max menor que min es inválido', () {
      final err = CategoriaRulesValidator.validarRango(10, 5);
      expect(err, isNotNull);
    });

    test('max -1 (sin límite) es válido', () {
      final err = CategoriaRulesValidator.validarRango(5, -1);
      expect(err, isNull);
    });

    test('rango válido normal', () {
      final err = CategoriaRulesValidator.validarRango(0, 4);
      expect(err, isNull);
    });
  });

  group('8.3.3 — Validación de nombre', () {
    test('nombre vacío es inválido', () {
      final err = CategoriaRulesValidator.validarNombre('');
      expect(err, isNotNull);
    });

    test('nombre solo espacios es inválido', () {
      final err = CategoriaRulesValidator.validarNombre('   ');
      expect(err, isNotNull);
    });

    test('nombre válido pasa la validación', () {
      final err = CategoriaRulesValidator.validarNombre('Torete');
      expect(err, isNull);
    });
  });

  // ─── 8.1 — Renderización de la pantalla ───────────────────────────────────

  group('8.1 — UI de visualización de categorías', () {
    Widget crearApp() {
      return MaterialApp(
        theme: testTheme,
        home: const Scaffold(
          body: ConfiguracionCategoriasScreen(),
        ),
      );
    }

    testWidgets('8.1.1 — muestra las pestañas de tipos de explotación',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Cría'), findsOneWidget);
      expect(find.text('Ceba'), findsOneWidget);
      expect(find.text('Lechería'), findsOneWidget);
      expect(find.text('Doble Propósito'), findsOneWidget);
    });

    testWidgets('8.1.2 — muestra secciones Machos y Hembras', (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      expect(find.text('Machos'), findsOneWidget);
      expect(find.text('Hembras'), findsOneWidget);
    });

    testWidgets('8.1.3 — muestra las categorías predeterminadas',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      expect(find.text('Ternero'), findsWidgets);
      expect(find.text('Ternera'), findsWidgets);
      expect(find.text('Vaca'), findsWidgets);
    });

    testWidgets('8.1.4 — botón de restaurar valores de fábrica está presente',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      expect(find.byIcon(Icons.restore_rounded), findsOneWidget);
    });
  });

  // ─── 8.2 — Modales de edición ─────────────────────────────────────────────

  group('8.2 — Modales de edición y creación', () {
    Widget crearApp() {
      return MaterialApp(
        theme: testTheme,
        home: const Scaffold(
          body: ConfiguracionCategoriasScreen(),
        ),
      );
    }

    testWidgets('8.2.1 — botón de edición abre el modal', (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      // Toca el primer botón de editar
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Editar categoría'), findsOneWidget);
    });

    testWidgets('8.2.2 — FAB Agregar categoría abre el modal de creación',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      await tester.tap(find.text('Agregar categoría').first);
      await tester.pumpAndSettle();

      expect(find.text('Nueva categoría'), findsOneWidget);
    });

    testWidgets(
        '8.2 — modal muestra error cuando nombre está vacío al guardar',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      await tester.tap(find.text('Agregar categoría').first);
      await tester.pumpAndSettle();

      // Intentar guardar sin nombre
      await tester.tap(find.text('Agregar').last);
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre de la categoría no puede estar vacío.'),
        findsOneWidget,
      );
    });

    testWidgets('8.1.4 — diálogo de confirmación al restaurar defaults',
        (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.restore_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Restaurar valores de fábrica'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Restaurar'), findsOneWidget);
    });
  });

  // ─── 8.4 — Conexión reactiva ──────────────────────────────────────────────

  group('8.4 — Singleton y propagación de reglas', () {
    test('8.4.1 — updateInstance actualiza el singleton', () {
      const nuevaRegla = CategoriaRuleModel(
        sexo: 'Macho',
        edadMinimoMeses: 0,
        edadMaximoMeses: 6,
        categoria: 'Becerro',
      );
      final nuevaSvc = CategoriaRulesService([nuevaRegla]);
      CategoriaRulesService.updateInstance(nuevaSvc);

      expect(CategoriaRulesService.instance.reglas.length, 1);
      expect(CategoriaRulesService.instance.reglas.first.categoria, 'Becerro');
    });

    test('8.4.2 — restaurar defaults restablece el singleton', () {
      // Primero modificar
      CategoriaRulesService.updateInstance(
        CategoriaRulesService([
          const CategoriaRuleModel(
            sexo: 'Macho',
            edadMinimoMeses: 0,
            edadMaximoMeses: 10,
            categoria: 'Personalizado',
          ),
        ]),
      );

      // Luego restaurar
      CategoriaRulesService.updateInstance(CategoriaRulesService());
      expect(
        CategoriaRulesService.instance.reglas.length,
        CategoriaRulesService.reglasDefault.length,
      );
    });

    test(
        '8.4.3 — categoriaZootecnica usa el singleton, reflejando reglas personalizadas',
        () {
      // Regla: todo Macho sin importar edad → "Becerrito" (para test)
      final svc = CategoriaRulesService([
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: -1,
          categoria: 'Becerrito',
        ),
      ]);
      CategoriaRulesService.updateInstance(svc);

      final cat = CategoriaRulesService.instance.determinarCategoria(
        fechaNacimiento: DateTime.now().subtract(const Duration(days: 400)),
        sexo: 'Macho',
        numeroPartos: 0,
      );
      expect(cat, 'Becerrito');
    });
  });
}
