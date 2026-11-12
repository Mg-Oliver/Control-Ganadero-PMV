import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/poblacion_aggregator.dart';

class DistribucionPoblacionalChart extends StatelessWidget {
  final ResultadoAgregacion datos;
  final VoidCallback? onRegistrarAnimal;
  const DistribucionPoblacionalChart({
    super.key,
    required this.datos,
    this.onRegistrarAnimal,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.estaVacio) {
      return Column(
        children: [
          const Text('Sin animales activos para mostrar'),
          if (onRegistrarAnimal != null)
            TextButton(
              onPressed: onRegistrarAnimal,
              child: const Text('Registrar Animal'),
            ),
        ],
      );
    }
    final grupos = [...datos.machos, ...datos.hembras];
    const colores = [
      Color(0xFF0369A1),
      Color(0xFF7C3AED),
      Color(0xFF0E7490),
      Color(0xFFF97316),
      Color(0xFF047857),
      Color(0xFFEC4899),
      Color(0xFFD97706),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 65,
                      sectionsSpace: 3,
                      sections: [
                        for (var i = 0; i < grupos.length; i++)
                          PieChartSectionData(
                            value: grupos[i].cantidad.toDouble(),
                            color: colores[i % colores.length],
                            radius: 55,
                            title:
                                '${grupos[i].porcentaje.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${datos.totalHato}\nanimales',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                for (var i = 0; i < grupos.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: colores[i % colores.length],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${grupos[i].categoria} (${grupos[i].sexo}): ${grupos[i].cantidad}',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
