import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/ui/controllers/inventario_controller.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/entity_data_table.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/entity_card_grid.dart';
import 'package:bovino_mvp/ui/screens/inventario/widgets/cards/animal_card.dart';
import 'package:bovino_mvp/ui/screens/dashboard/widgets/distribucion_poblacional_chart.dart';
import 'package:bovino_mvp/core/utils/poblacion_aggregator.dart';
import '../helpers/test_theme.dart';

void main() {
  testWidgets('inventario muestra todas las tarjetas y filas sin paginación', (
    tester,
  ) async {
    final c = InventarioController();
    addTearDown(c.dispose);
    for (var i = 0; i < 27; i++) {
      c.registrarAnimalOptimista(
        AnimalModel(
          id: '$i',
          codigoSistema: 'GAN-$i',
          areteManejo: '$i',
          sexo: 'Macho',
          razaEtiquetaDisplay: 'Holstein',
          tipoExplotacion: 'Lecheria',
          fechaNacimiento: DateTime(2020),
          origen: 'Otro',
          fincaId: 'f1',
          fechaEntrada: DateTime(2024),
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                EntityCardGrid(controller: c),
                EntityDataTable(controller: c),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AnimalCard), findsNWidgets(27));
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 27);
    expect(find.text('Filas por página:'), findsNothing);
    expect(find.text('Contraer vista'), findsNothing);
  });
  testWidgets('distribución usa sectores circulares con cantidades reales', (
    tester,
  ) async {
    const datos = ResultadoAgregacion(
      machos: [
        GrupoPoblacional(
          sexo: 'Macho',
          categoria: 'Toro',
          cantidad: 2,
          porcentaje: 40,
        ),
      ],
      hembras: [
        GrupoPoblacional(
          sexo: 'Hembra',
          categoria: 'Vaca',
          cantidad: 3,
          porcentaje: 60,
        ),
      ],
      totalMachos: 2,
      totalHembras: 3,
      totalHato: 5,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: const Scaffold(body: DistribucionPoblacionalChart(datos: datos)),
      ),
    );
    expect(
      tester
          .widget<PieChart>(find.byType(PieChart))
          .data
          .sections
          .map((s) => s.value),
      [2.0, 3.0],
    );
  });
}
