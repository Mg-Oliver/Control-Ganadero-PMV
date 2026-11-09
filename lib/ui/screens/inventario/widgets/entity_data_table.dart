import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../controllers/inventario_controller.dart';
import 'cards/animal_card.dart';

class EntityDataTable extends StatefulWidget {
  final InventarioController controller;

  const EntityDataTable({
    super.key,
    required this.controller,
  });

  @override
  State<EntityDataTable> createState() => _EntityDataTableState();
}

class _EntityDataTableState extends State<EntityDataTable> {
  final _horizontalScrollCtrl = ScrollController();

  @override
  void dispose() {
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final total = c.totalResultadosCoincidentes;
    final rowsPerPage = c.rowsPerPage;
    final totalPages = total == 0 ? 1 : ((total - 1) ~/ rowsPerPage) + 1;
    final safePage = c.currentPage.clamp(0, totalPages - 1);
    final startIdx = total == 0 ? 0 : safePage * rowsPerPage;
    final endIdx = math.min(startIdx + rowsPerPage, total);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ENCABEZADO DE LA TABLA EXHAUSTIVA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Matriz Exhaustiva de Datos (Clic en fila para abrir expediente)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  total == 0
                      ? '0 registros'
                      : 'Mostrando ${startIdx + 1}–$endIdx de $total',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // CUERPO CON SCROLL BIDIRECCIONAL
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Text(
                  'Sin filas para mostrar en la tabla.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Scrollbar(
              controller: _horizontalScrollCtrl,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollCtrl,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 460),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildActiveDataTable(c, startIdx, endIdx),
                  ),
                ),
              ),
            ),

          // BARRA DE PAGINACIÓN RESPONSIVA
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filas por página:',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: rowsPerPage,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                      ],
                      onChanged: (val) {
                        if (val != null) c.cambiarFilasPorPagina(val);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Página ${safePage + 1} de $totalPages',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Página anterior',
                      visualDensity: VisualDensity.compact,
                      onPressed: safePage > 0
                          ? () => c.cambiarPagina(safePage - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      tooltip: 'Página siguiente',
                      visualDensity: VisualDensity.compact,
                      onPressed: safePage < totalPages - 1
                          ? () => c.cambiarPagina(safePage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDataTable(
    InventarioController c,
    int startIdx,
    int endIdx,
  ) {
    switch (c.seccionActiva) {
      case InventarioSeccion.fincas:
        return _buildFincasTable(c, startIdx, endIdx);
      case InventarioSeccion.lotes:
        return _buildLotesTable(c, startIdx, endIdx);
      case InventarioSeccion.animales:
        return _buildAnimalesTable(c, startIdx, endIdx);
    }
  }

  Widget _buildFincasTable(InventarioController c, int startIdx, int endIdx) {
    final slice = c.fincasFiltradas.sublist(startIdx, endIdx);
    final sortIdx = c.sortColumnIndex <= 4 ? c.sortColumnIndex : null;

    return DataTable(
      showCheckboxColumn: false,
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAF9)),
      sortColumnIndex: sortIdx,
      sortAscending: c.sortAscending,
      columns: [
        DataColumn(
          label: const Text('Identificador'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Nombre Finca'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Ubicación'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Superficie (ha)'),
          numeric: true,
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Estado'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        const DataColumn(label: Text('Fuentes de Agua')),
        const DataColumn(label: Text('Lotes / Animales')),
        const DataColumn(label: Text('Observaciones')),
        const DataColumn(label: Text('Fotos')),
      ],
      rows: slice.map((f) {
        final selected = c.selectedFinca?.id == f.id;
        final lotes = c.obtenerLotesDeFinca(f.id).length;
        final anims = c.obtenerAnimalesDeFinca(f.id).length;

        return DataRow(
          selected: selected,
          onSelectChanged: (_) => c.seleccionarFinca(f),
          cells: [
            DataCell(
              Text(
                f.identificador,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(Text(f.nombre)),
            DataCell(Text(f.ubicacion ?? '-')),
            DataCell(
              Text(
                f.superficieHectareas != null
                    ? f.superficieHectareas!.toStringAsFixed(2)
                    : '-',
              ),
            ),
            DataCell(_chipEstadoSimple(
              f.estado,
              f.estado == 'Activa' ? AppColors.success : AppColors.textSecondary,
            )),
            DataCell(
              Text(
                f.fuentesAgua.isEmpty ? 'Ninguna' : f.fuentesAgua.join(', '),
              ),
            ),
            DataCell(Text('$lotes lotes • $anims cabezas')),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  f.observaciones ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text('${f.fotos.length}/3')),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLotesTable(InventarioController c, int startIdx, int endIdx) {
    final slice = c.lotesFiltrados.sublist(startIdx, endIdx);
    final sortIdx = c.sortColumnIndex <= 5 ? c.sortColumnIndex : null;

    return DataTable(
      showCheckboxColumn: false,
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAF9)),
      sortColumnIndex: sortIdx,
      sortAscending: c.sortAscending,
      columns: [
        DataColumn(
          label: const Text('Identificador'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Nombre Lote'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Finca Madre'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Propósito'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Meta GDP (kg/día)'),
          numeric: true,
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Estado'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        const DataColumn(label: Text('Animales')),
        const DataColumn(label: Text('Dieta Asignada')),
      ],
      rows: slice.map((l) {
        final selected = c.selectedLote?.id == l.id;
        final anims = c.obtenerAnimalesDeLote(l.id).length;

        return DataRow(
          selected: selected,
          onSelectChanged: (_) => c.seleccionarLote(l),
          cells: [
            DataCell(
              Text(
                l.identificador,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(Text(l.nombre)),
            DataCell(Text(l.fincaNombre ?? c.nombreFincaPorId(l.fincaId))),
            DataCell(Text(l.propositoProductivo)),
            DataCell(Text(l.metaGananciaPesoDiaria.toStringAsFixed(3))),
            DataCell(_chipEstadoSimple(
              l.estado,
              l.estado == 'Activo' ? AppColors.success : AppColors.textSecondary,
            )),
            DataCell(Text('$anims cabezas')),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  l.dietaAsignada ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnimalesTable(InventarioController c, int startIdx, int endIdx) {
    final slice = c.animalesFiltrados.sublist(startIdx, endIdx);
    final sortIdx = c.sortColumnIndex <= 9 ? c.sortColumnIndex : null;

    return DataTable(
      showCheckboxColumn: false,
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAF9)),
      sortColumnIndex: sortIdx,
      sortAscending: c.sortAscending,
      columns: [
        DataColumn(
          label: const Text('Código'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Arete Manejo'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Nombre / Alias'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Sexo'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Raza / Genética'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Peso (kg)'),
          numeric: true,
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Finca Actual'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Estado'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Fecha Entrada'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        DataColumn(
          label: const Text('Nacimiento / Edad'),
          onSort: (i, asc) => c.ordenarPorColumna(i, asc),
        ),
        const DataColumn(label: Text('Arete Oficial')),
        const DataColumn(label: Text('Explotación')),
        const DataColumn(label: Text('Lote / Potrero')),
        const DataColumn(label: Text('Origen')),
        const DataColumn(label: Text('Precio Compra'), numeric: true),
        const DataColumn(label: Text('Fotos')),
      ],
      rows: slice.map((a) {
        final selected = c.selectedAnimal?.id == a.id;
        final fincaNom = a.fincaNombre ?? c.nombreFincaPorId(a.fincaId);
        final loteNom = a.loteNombre ?? c.nombreLotePorId(a.loteId);
        final potrero = (a.potreroActual != null && a.potreroActual!.isNotEmpty)
            ? ' • ${a.potreroActual}'
            : '';

        return DataRow(
          selected: selected,
          onSelectChanged: (_) => c.seleccionarAnimal(a),
          cells: [
            DataCell(
              Text(
                a.codigoSistema,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            DataCell(
              Text(
                a.areteManejo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(Text(a.nombreAlias ?? '-')),
            DataCell(Text(a.sexo)),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  a.razaEtiquetaDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Text(
                a.pesoActual != null ? a.pesoActual!.toStringAsFixed(2) : '-',
              ),
            ),
            DataCell(Text(fincaNom)),
            DataCell(
              _chipEstadoSimple(
                a.estadoActual,
                AnimalCard.colorPorEstado(a.estadoActual),
              ),
            ),
            DataCell(Text(Formatters.formatearFecha(a.fechaEntrada))),
            DataCell(
              Text(
                '${Formatters.formatearFecha(a.fechaNacimiento)} (${a.edadFormateada})',
              ),
            ),
            DataCell(Text(a.areteOficial ?? '-')),
            DataCell(Text(a.tipoExplotacion)),
            DataCell(Text('$loteNom$potrero')),
            DataCell(Text(a.origen)),
            DataCell(
              Text(
                a.precioCompra != null
                    ? Formatters.formatearMoneda(a.precioCompra)
                    : '-',
              ),
            ),
            DataCell(Text('${a.fotos.length}/3')),
          ],
        );
      }).toList(),
    );
  }

  Widget _chipEstadoSimple(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
