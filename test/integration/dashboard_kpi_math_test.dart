// Tests de integración — Fase 16.3
// Validación matemática exacta de los KPI del Dashboard y distribución poblacional.

import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/services/categoria_rules_service.dart';
import 'package:bovino_mvp/core/utils/poblacion_aggregator.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';

// ─── Factories ───────────────────────────────────────────────────────────────

FincaModel finca(String id) => FincaModel(
      id: id,
      nombre: 'Finca $id',
      identificador: id,
    );

AnimalModel animal({
  required String id,
  required String fincaId,
  required String sexo,
  String estado = 'Activo',
  double? precioCompra,
  DateTime? fechaEntrada,
  DateTime? fechaSalida,
  int mesesEdad = 30,
  int partos = 0,
}) =>
    AnimalModel(
      id: id,
      codigoSistema: id,
      areteManejo: id,
      sexo: sexo,
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime.now().subtract(Duration(days: mesesEdad * 30)),
      origen: 'Nacido en la finca',
      fincaId: fincaId,
      estadoActual: estado,
      fechaEntrada: fechaEntrada ?? DateTime(2024, 1, 1),
      precioCompra: precioCompra,
      fechaSalida: fechaSalida,
      numeroPartos: partos,
    );

// Calcula eventosHoy como lo hace el DashboardScreen
int calcularEventosHoy(List<AnimalModel> todos) {
  final hoy = DateTime.now();
  final todayStart = DateTime(hoy.year, hoy.month, hoy.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  return todos.where((a) {
    final altaHoy = !a.fechaEntrada.isBefore(todayStart) &&
        a.fechaEntrada.isBefore(todayEnd);
    final salidaHoy = a.fechaSalida != null &&
        !a.fechaSalida!.isBefore(todayStart) &&
        a.fechaSalida!.isBefore(todayEnd);
    return altaHoy || salidaHoy;
  }).length;
}

// ─── 16.3.1 — KPI Cards ───────────────────────────────────────────────────

void main() {
  group('16.3.1 — Cálculo exacto de KPI del Dashboard', () {
    late InventarioController controller;

    setUp(() => controller = InventarioController());
    tearDown(() => controller.dispose());

    test('Fincas Activas: cuenta exactamente todas las fincas registradas', () {
      controller.registrarFincaOptimista(finca('f1'));
      controller.registrarFincaOptimista(finca('f2'));
      controller.registrarFincaOptimista(finca('f3'));

      expect(controller.allFincas.length, 3);
    });

    test('Total Animales: cuenta solo animales con estadoActual == "Activo"',
        () {
      controller.registrarFincaOptimista(finca('f1'));
      controller.registrarAnimalOptimista(
          animal(id: 'a1', fincaId: 'f1', sexo: 'Macho', estado: 'Activo'));
      controller.registrarAnimalOptimista(
          animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra', estado: 'Activo'));
      controller.registrarAnimalOptimista(
          animal(id: 'a3', fincaId: 'f1', sexo: 'Macho', estado: 'Vendido'));
      controller.registrarAnimalOptimista(
          animal(id: 'a4', fincaId: 'f1', sexo: 'Hembra', estado: 'Muerto'));

      final activos = controller.allAnimales
          .where((a) => a.estadoActual == 'Activo')
          .toList();

      expect(activos.length, 2);
      expect(controller.allAnimales.length, 4); // total sin filtro
    });

    test('Eventos del Día: solo altas de hoy cuentan', () {
      final ahora = DateTime.now();
      final hoy9am = DateTime(ahora.year, ahora.month, ahora.day, 9);
      final ayer = DateTime(ahora.year, ahora.month, ahora.day - 1);

      final todos = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho', fechaEntrada: hoy9am),
        animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra', fechaEntrada: ayer),
      ];

      expect(calcularEventosHoy(todos), 1);
    });

    test('Eventos del Día: salidas de hoy también cuentan', () {
      final ahora = DateTime.now();
      final hoy14pm = DateTime(ahora.year, ahora.month, ahora.day, 14);

      final todos = [
        animal(
          id: 'a1',
          fincaId: 'f1',
          sexo: 'Macho',
          estado: 'Vendido',
          fechaEntrada: DateTime(2023),
          fechaSalida: hoy14pm,
        ),
        animal(
          id: 'a2',
          fincaId: 'f1',
          sexo: 'Hembra',
          estado: 'Activo',
          fechaEntrada: DateTime(2024, 3, 1), // anterior
        ),
      ];

      expect(calcularEventosHoy(todos), 1);
    });

    test('Eventos del Día: alta y salida el mismo día suman 2 eventos', () {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day, 8);

      final todos = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho', fechaEntrada: hoy),
        animal(
          id: 'a2',
          fincaId: 'f1',
          sexo: 'Hembra',
          estado: 'Vendido',
          fechaEntrada: DateTime(2023),
          fechaSalida: hoy,
        ),
      ];

      expect(calcularEventosHoy(todos), 2);
    });

    test('Eventos del Día: sin actividad hoy → 0', () {
      final todos = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho',
            fechaEntrada: DateTime(2024, 1, 1)),
        animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra',
            fechaEntrada: DateTime(2024, 2, 15)),
      ];

      expect(calcularEventosHoy(todos), 0);
    });

    test('Valor Monetario: suma exacta de precioCompra de activos', () {
      final animalesActivos = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho', precioCompra: 3500000),
        animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra', precioCompra: 2800000),
        animal(id: 'a3', fincaId: 'f1', sexo: 'Hembra', precioCompra: null),
      ];

      final valorEstimado = animalesActivos.fold<double>(
        0,
        (acc, a) => acc + (a.precioCompra ?? 0),
      );

      expect(valorEstimado, closeTo(6300000, 0.01));
    });

    test('Valor Monetario: solo animales activos se suman (vendidos excluidos)',
        () {
      final todos = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho',
            estado: 'Activo', precioCompra: 4000000),
        animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra',
            estado: 'Vendido', precioCompra: 3000000),
      ];

      final activos = todos.where((a) => a.estadoActual == 'Activo').toList();
      final valor = activos.fold<double>(0, (acc, a) => acc + (a.precioCompra ?? 0));

      expect(valor, closeTo(4000000, 0.01));
    });

    test('Valor Monetario: hato sin precio → 0', () {
      final animales = [
        animal(id: 'a1', fincaId: 'f1', sexo: 'Macho', precioCompra: null),
        animal(id: 'a2', fincaId: 'f1', sexo: 'Hembra', precioCompra: null),
      ];

      final valor = animales.fold<double>(0, (acc, a) => acc + (a.precioCompra ?? 0));
      expect(valor, 0.0);
    });
  });

  // ─── 16.3.2 — Distribución Poblacional exacta ────────────────────────────

  group('16.3.2 — Distribución poblacional (matemática exacta)', () {
    test('Hato mixto: totales por sexo son exactos', () {
      final animales = [
        // 2 terneros (< 4 meses)
        animal(id: 'm1', fincaId: 'f1', sexo: 'Macho', mesesEdad: 2),
        animal(id: 'm2', fincaId: 'f1', sexo: 'Macho', mesesEdad: 3),
        // 1 novillo
        animal(id: 'm3', fincaId: 'f1', sexo: 'Macho', mesesEdad: 10),
        // 1 toro
        animal(id: 'm4', fincaId: 'f1', sexo: 'Macho', mesesEdad: 30),
        // 3 vacas
        animal(id: 'h1', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 24, partos: 1),
        animal(id: 'h2', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 36, partos: 2),
        animal(id: 'h3', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 48, partos: 3),
        // 2 novillas
        animal(id: 'h4', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 10),
        animal(id: 'h5', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 15),
      ];

      final resultado = PoblacionAggregator.agregar(animales);

      expect(resultado.totalMachos, 4);
      expect(resultado.totalHembras, 5);
      expect(resultado.totalHato, 9);
    });

    test('Porcentajes suman exactamente 100% con margen de punto flotante', () {
      final animales = [
        for (int i = 0; i < 7; i++)
          animal(id: 'a$i', fincaId: 'f1', sexo: 'Macho', mesesEdad: 2),
        for (int i = 0; i < 3; i++)
          animal(id: 'h$i', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 10),
      ];

      final resultado = PoblacionAggregator.agregar(animales);
      final sumaPct = [...resultado.machos, ...resultado.hembras]
          .fold(0.0, (acc, g) => acc + g.porcentaje);

      expect(sumaPct, closeTo(100.0, 0.01));
    });

    test('Grupos machos ordenados de mayor a menor cantidad', () {
      final animales = [
        // 1 toro
        animal(id: 'tr1', fincaId: 'f1', sexo: 'Macho', mesesEdad: 30),
        // 3 terneros
        animal(id: 'tn1', fincaId: 'f1', sexo: 'Macho', mesesEdad: 2),
        animal(id: 'tn2', fincaId: 'f1', sexo: 'Macho', mesesEdad: 3),
        animal(id: 'tn3', fincaId: 'f1', sexo: 'Macho', mesesEdad: 1),
        // 2 novillos
        animal(id: 'nv1', fincaId: 'f1', sexo: 'Macho', mesesEdad: 12),
        animal(id: 'nv2', fincaId: 'f1', sexo: 'Macho', mesesEdad: 15),
      ];

      final resultado = PoblacionAggregator.agregar(animales);

      // Orden: Ternero(3) > Novillo(2) > Toro(1)
      expect(resultado.machos[0].categoria, 'Ternero');
      expect(resultado.machos[0].cantidad, 3);
      expect(resultado.machos[1].categoria, 'Novillo');
      expect(resultado.machos[1].cantidad, 2);
      expect(resultado.machos[2].categoria, 'Toro');
      expect(resultado.machos[2].cantidad, 1);
    });

    test('Hato solo hembras: machos vacío, hembras correctas', () {
      final animales = [
        animal(id: 'h1', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 2),
        animal(id: 'h2', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 24, partos: 1),
      ];

      final resultado = PoblacionAggregator.agregar(animales);

      expect(resultado.machos, isEmpty);
      expect(resultado.totalMachos, 0);
      expect(resultado.totalHembras, 2);
      expect(resultado.hembras.length, 2);
    });

    test('Porcentaje individual es correcto con 4 animales', () {
      // 1 de cada categoría → 25% cada uno
      final animales = [
        animal(id: 'm1', fincaId: 'f1', sexo: 'Macho', mesesEdad: 2),   // Ternero
        animal(id: 'm2', fincaId: 'f1', sexo: 'Macho', mesesEdad: 10),  // Novillo
        animal(id: 'm3', fincaId: 'f1', sexo: 'Macho', mesesEdad: 30),  // Toro
        animal(id: 'h1', fincaId: 'f1', sexo: 'Hembra', mesesEdad: 10), // Novilla
      ];

      // Resetear instancia para usar reglas por defecto
      CategoriaRulesService.updateInstance(CategoriaRulesService());

      final resultado = PoblacionAggregator.agregar(animales);
      final total = resultado.totalHato;

      expect(total, 4);

      // Cada grupo representa 1/4 = 25%
      for (final g in [...resultado.machos, ...resultado.hembras]) {
        expect(g.cantidad, 1);
        expect(g.porcentaje, closeTo(25.0, 0.01));
      }
    });

    test('Resultado vacío produce estaVacio = true y 0 en todos los campos',
        () {
      final resultado = PoblacionAggregator.agregar([]);

      expect(resultado.estaVacio, isTrue);
      expect(resultado.totalHato, 0);
      expect(resultado.totalMachos, 0);
      expect(resultado.totalHembras, 0);
      expect(resultado.machos, isEmpty);
      expect(resultado.hembras, isEmpty);
    });
  });
}
