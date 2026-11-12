import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../data/models/animal_model.dart';
import '../../../../core/constants/app_colors.dart';

class MetricasGanaderas extends StatelessWidget {
  final List<AnimalModel> animales;
  final String Function(String) nombreFinca;
  const MetricasGanaderas({
    super.key,
    required this.animales,
    required this.nombreFinca,
  });

  Map<String, int> _agrupar(
    Iterable<AnimalModel> lista,
    String Function(AnimalModel) clave,
  ) {
    final grupos = <String, int>{};
    for (final a in lista) {
      final k = clave(a);
      grupos[k] = (grupos[k] ?? 0) + 1;
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final internos = animales.where((a) => !a.esExterno).toList();
    final activos = internos.where((a) => a.estadoActual == 'Activo');
    final hoy = DateTime.now();
    final movimientos = <String, int>{};
    for (var i = 5; i >= 0; i--) {
      final mes = DateTime(hoy.year, hoy.month - i);
      final siguiente = DateTime(mes.year, mes.month + 1);
      const meses = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      final etiqueta = '${meses[mes.month - 1]} ${mes.year}';
      movimientos['$etiqueta · Entradas'] = internos
          .where(
            (a) =>
                !a.fechaEntrada.isBefore(mes) &&
                a.fechaEntrada.isBefore(siguiente),
          )
          .length;
      movimientos['$etiqueta · Salidas'] = internos
          .where(
            (a) =>
                a.fechaSalida != null &&
                !a.fechaSalida!.isBefore(mes) &&
                a.fechaSalida!.isBefore(siguiente),
          )
          .length;
    }
    final graficos = [
      _Barras(
        titulo: 'Animales activos por finca',
        datos: _agrupar(activos, (a) => nombreFinca(a.fincaId)),
      ),
      _Barras(
        titulo: 'Tipo de explotación del hato activo',
        datos: _agrupar(activos, (a) => a.tipoExplotacion),
      ),
      _Barras(
        titulo: 'Entradas y salidas · últimos 6 meses',
        datos: movimientos,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final grafico in graficos)
            SizedBox(
              width: constraints.maxWidth >= 1000
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth,
              child: grafico,
            ),
        ],
      ),
    );
  }
}

class _Barras extends StatelessWidget {
  final String titulo;
  final Map<String, int> datos;
  const _Barras({required this.titulo, required this.datos});
  @override
  Widget build(BuildContext context) {
    final maximo = datos.values.fold(1, math.max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            if (datos.isEmpty) const Text('Sin datos disponibles'),
            for (final item in datos.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.key)),
                        Text('${item.value}'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Semantics(
                      label: '${item.key}: ${item.value} animales',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.value / maximo,
                          minHeight: 10,
                          color: item.key.endsWith('Salidas')
                              ? Colors.orange
                              : AppColors.primary,
                          backgroundColor: AppColors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
