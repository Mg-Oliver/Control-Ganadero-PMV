import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/reproduccion_model.dart';
import 'package:bovino_mvp/data/services/reproduccion_service.dart';

final hoy = DateTime(2026, 11, 12);
AnimalModel vaca({
  String id = 'v1',
  String sexo = 'Hembra',
  bool externo = false,
}) => AnimalModel(
  id: id,
  codigoSistema: id,
  areteManejo: id,
  sexo: sexo,
  razaEtiquetaDisplay: 'Holstein',
  tipoExplotacion: 'Lecheria',
  fechaNacimiento: DateTime(2020),
  origen: 'Otro',
  fincaId: 'f1',
  fechaEntrada: DateTime(2024),
  esExterno: externo,
);
EventoReproductivo evento(
  String id,
  TipoEventoReproductivo tipo,
  int dias, {
  String animalId = 'v1',
  String? servicioId,
  bool? positivo,
  String? metodo,
  DateTime? fpp,
  String? estado,
}) => EventoReproductivo(
  id: id,
  animalId: animalId,
  tipo: tipo,
  fecha: hoy.subtract(Duration(days: dias)),
  servicioId: servicioId,
  positivo: positivo,
  metodo: metodo,
  fechaProbableParto: fpp,
  estadoInicial: estado,
);
void main() {
  test('sin eventos no presupone vacío y los machos son N/A', () {
    expect(CicloAnimal(vaca(), [], hoy).estado, 'Sin registro');
    expect(CicloAnimal(vaca(sexo: 'Macho'), [], hoy).estado, 'N/A (Macho)');
  });
  test('secuencia parto, servicio, diagnóstico, secado y nuevo parto', () {
    final e = [evento('p', TipoEventoReproductivo.parto, 180)];
    expect(CicloAnimal(vaca(), e, hoy).estado, 'Vacía');
    e.add(
      evento(
        's',
        TipoEventoReproductivo.servicio,
        100,
        metodo: metodosConcepcion.first,
      ),
    );
    expect(CicloAnimal(vaca(), e, hoy).estado, 'Servida');
    e.add(
      evento(
        'd',
        TipoEventoReproductivo.diagnostico,
        60,
        servicioId: 's',
        positivo: true,
        fpp: hoy.add(const Duration(days: 20)),
      ),
    );
    final gestante = CicloAnimal(vaca(), e, hoy);
    expect(gestante.estado, 'Gestante');
    expect(gestante.diasGestacion, 100);
    expect(gestante.del, 180);
    expect(gestante.diasAbiertos, 80);
    expect(gestante.secadoPendiente, isTrue);
    e.add(evento('sec', TipoEventoReproductivo.secado, 40));
    expect(CicloAnimal(vaca(), e, hoy).estado, 'Seca');
    expect(CicloAnimal(vaca(), e, hoy).del, isNull);
    e.add(evento('p2', TipoEventoReproductivo.parto, 0));
    final parida = CicloAnimal(vaca(), e, hoy);
    expect(parida.estado, 'Vacía');
    expect(parida.fpp, isNull);
    expect(parida.del, 0);
    expect(parida.diasAbiertos, 0);
  });
  for (final dias in [29, 30, 45, 46]) {
    test('ventana de diagnóstico a $dias días', () {
      final c = CicloAnimal(vaca(), [
        evento('s', TipoEventoReproductivo.servicio, dias),
      ], hoy);
      expect(c.ecografiaEnVentana, dias >= 30 && dias <= 45);
      expect(c.ecografiaVencida, dias > 45);
    });
  }
  for (final dias in [-1, 0, 6, 7, 60, 61]) {
    test('límites FPP a $dias días', () {
      final c = CicloAnimal(vaca(), [
        evento(
          'inicial',
          TipoEventoReproductivo.estadoInicial,
          20,
          estado: 'Gestante',
          fpp: hoy.add(Duration(days: dias)),
        ),
      ], hoy);
      expect(c.partoInminente, dias >= 0 && dias < 7);
      expect(c.partoVencido, dias < 0);
      expect(c.secadoPendiente, dias >= 0 && dias <= 60);
    });
  }
  test('servicio posterior al celo del mismo día retira alerta', () {
    final celo = evento('c', TipoEventoReproductivo.celo, 0);
    expect(CicloAnimal(vaca(), [celo], hoy).celoPorServir, isTrue);
    expect(
      CicloAnimal(vaca(), [
        celo,
        evento('s', TipoEventoReproductivo.servicio, 0),
      ], hoy).celoPorServir,
      isFalse,
    );
  });
  test(
    'tasa usa solo servicios diagnosticados y el diagnóstico más reciente',
    () {
      final e = [
        evento(
          's1',
          TipoEventoReproductivo.servicio,
          200,
          metodo: metodosConcepcion.first,
        ),
        evento(
          'd1',
          TipoEventoReproductivo.diagnostico,
          170,
          servicioId: 's1',
          positivo: false,
        ),
        evento(
          's2',
          TipoEventoReproductivo.servicio,
          150,
          metodo: metodosConcepcion.first,
        ),
        evento(
          'd2',
          TipoEventoReproductivo.diagnostico,
          120,
          servicioId: 's2',
          positivo: true,
        ),
        evento(
          'correccion',
          TipoEventoReproductivo.diagnostico,
          119,
          servicioId: 's2',
          positivo: false,
        ),
        evento(
          's3',
          TipoEventoReproductivo.servicio,
          110,
          metodo: metodosConcepcion.first,
        ),
        evento(
          'd3',
          TipoEventoReproductivo.diagnostico,
          80,
          servicioId: 's3',
          positivo: true,
        ),
        evento(
          's4',
          TipoEventoReproductivo.servicio,
          5,
          metodo: metodosConcepcion.first,
        ),
      ];
      final resumen = ResumenReproductivo([vaca()], e, hoy);
      expect(resumen.resultados.length, 3);
      expect(resumen.tasa(), closeTo(100 / 3, .001));
      expect(resumen.tasa(metodosConcepcion[1]), isNull);
    },
  );
  test('KPIs vacíos no inventan valores y externos quedan excluidos', () {
    final r = ResumenReproductivo([vaca(externo: true)], [], hoy);
    expect(r.ciclos, isEmpty);
    expect(r.tasa(), isNull);
    expect(r.delPromedio, isNull);
    expect(r.diasAbiertosPromedio, isNull);
    expect(r.proximosPartos, 0);
  });
  test('eventos persisten y se restauran sin mezclar ejemplos', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReproduccionService();
    expect(await service.cargar(), isEmpty);
    final e = evento(
      's1',
      TipoEventoReproductivo.servicio,
      10,
      metodo: metodosConcepcion.first,
    );
    await service.guardar([e]);
    final restaurados = await ReproduccionService().cargar();
    expect(restaurados.single.id, 's1');
    expect(restaurados.single.metodo, metodosConcepcion.first);
    expect(restaurados.single.fecha, e.fecha);
  });
}
