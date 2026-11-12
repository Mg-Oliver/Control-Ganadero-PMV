import 'animal_model.dart';

enum TipoEventoReproductivo {
  estadoInicial('Estado inicial'),
  celo('Celo'),
  servicio('Servicio'),
  diagnostico('Diagnóstico de gestación'),
  secado('Secado'),
  parto('Parto');

  final String etiqueta;
  const TipoEventoReproductivo(this.etiqueta);
}

const estadosReproductivos = ['Vacía', 'Servida', 'Gestante', 'Seca'];
const metodosConcepcion = [
  'IA Semen Sexado',
  'Monta Natural',
  'IA Convencional',
  'Transferencia de Embrión (TE)',
];

class EventoReproductivo {
  final String id, animalId;
  final TipoEventoReproductivo tipo;
  final DateTime fecha;
  final String? metodo, servicioId, estadoInicial;
  final bool? positivo;
  final DateTime? fechaProbableParto;
  final String notas;
  const EventoReproductivo({
    required this.id,
    required this.animalId,
    required this.tipo,
    required this.fecha,
    this.metodo,
    this.servicioId,
    this.estadoInicial,
    this.positivo,
    this.fechaProbableParto,
    this.notas = '',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'animal_id': animalId,
    'tipo': tipo.name,
    'fecha': fecha.toIso8601String(),
    'metodo': metodo,
    'servicio_id': servicioId,
    'estado_inicial': estadoInicial,
    'positivo': positivo,
    'fpp': fechaProbableParto?.toIso8601String(),
    'notas': notas,
  };
  factory EventoReproductivo.fromJson(Map<String, dynamic> j) =>
      EventoReproductivo(
        id: j['id'] as String,
        animalId: j['animal_id'] as String,
        tipo: TipoEventoReproductivo.values.byName(j['tipo'] as String),
        fecha: DateTime.parse(j['fecha'] as String),
        metodo: j['metodo'] as String?,
        servicioId: j['servicio_id'] as String?,
        estadoInicial: j['estado_inicial'] as String?,
        positivo: j['positivo'] as bool?,
        fechaProbableParto: j['fpp'] == null
            ? null
            : DateTime.parse(j['fpp'] as String),
        notas: j['notas'] as String? ?? '',
      );
}

class CicloAnimal {
  final AnimalModel animal;
  final List<EventoReproductivo> eventos;
  final DateTime hoy;
  CicloAnimal(this.animal, List<EventoReproductivo> registros, DateTime fecha)
    : hoy = DateTime(fecha.year, fecha.month, fecha.day),
      eventos = _ordenar(registros, animal.id);
  static List<EventoReproductivo> _ordenar(
    List<EventoReproductivo> registros,
    String id,
  ) {
    final lista =
        registros.asMap().entries.where((e) => e.value.animalId == id).toList()
          ..sort((a, b) {
            final c = a.value.fecha.compareTo(b.value.fecha);
            return c == 0 ? a.key.compareTo(b.key) : c;
          });
    return lista.map((e) => e.value).toList();
  }

  EventoReproductivo? ultimo(TipoEventoReproductivo tipo) =>
      eventos.where((e) => e.tipo == tipo).lastOrNull;
  String get estado {
    if (animal.sexo == 'Macho') return 'N/A (Macho)';
    var estado = 'Sin registro';
    for (final e in eventos) {
      switch (e.tipo) {
        case TipoEventoReproductivo.estadoInicial:
          estado = e.estadoInicial ?? 'Sin registro';
        case TipoEventoReproductivo.celo:
          break;
        case TipoEventoReproductivo.servicio:
          estado = 'Servida';
        case TipoEventoReproductivo.diagnostico:
          estado = e.positivo == true ? 'Gestante' : 'Vacía';
        case TipoEventoReproductivo.secado:
          estado = 'Seca';
        case TipoEventoReproductivo.parto:
          estado = 'Vacía';
      }
    }
    return estado;
  }

  bool get prenada => estado == 'Gestante' || estado == 'Seca';
  DateTime? get fpp {
    if (!prenada) return null;
    return eventos
        .where((e) => e.fechaProbableParto != null)
        .lastOrNull
        ?.fechaProbableParto;
  }

  int? get diasGestacion {
    if (!prenada) return null;
    final diagnostico = eventos
        .where(
          (e) =>
              e.tipo == TipoEventoReproductivo.diagnostico &&
              e.positivo == true,
        )
        .lastOrNull;
    final servicio = eventos
        .where((e) => e.id == diagnostico?.servicioId)
        .firstOrNull;
    return servicio == null ? null : hoy.difference(servicio.fecha).inDays;
  }

  int? get diasParaParto => fpp?.difference(hoy).inDays;
  int? get del {
    final parto = ultimo(TipoEventoReproductivo.parto);
    return parto == null || estado == 'Seca'
        ? null
        : hoy.difference(parto.fecha).inDays;
  }

  int? get diasAbiertos {
    final parto = ultimo(TipoEventoReproductivo.parto);
    if (parto == null) return null;
    final diagnostico = eventos
        .where(
          (e) =>
              e.tipo == TipoEventoReproductivo.diagnostico &&
              e.positivo == true &&
              !e.fecha.isBefore(parto.fecha),
        )
        .lastOrNull;
    final servicio = eventos
        .where((e) => e.id == diagnostico?.servicioId)
        .firstOrNull;
    final fin = prenada && servicio != null ? servicio.fecha : hoy;
    final dias = fin.difference(parto.fecha).inDays;
    return dias < 0 ? null : dias;
  }

  EventoReproductivo? get servicioPendiente {
    final servicio = ultimo(TipoEventoReproductivo.servicio);
    if (servicio == null || estado != 'Servida') return null;
    return eventos.any(
          (e) =>
              e.tipo == TipoEventoReproductivo.diagnostico &&
              e.servicioId == servicio.id,
        )
        ? null
        : servicio;
  }

  int? get diasPostServicio => servicioPendiente == null
      ? null
      : hoy.difference(servicioPendiente!.fecha).inDays;
  bool get ecografiaEnVentana =>
      diasPostServicio != null &&
      diasPostServicio! >= 30 &&
      diasPostServicio! <= 45;
  bool get ecografiaVencida =>
      diasPostServicio != null && diasPostServicio! > 45;
  bool get secadoPendiente =>
      estado == 'Gestante' &&
      diasParaParto != null &&
      diasParaParto! >= 0 &&
      diasParaParto! <= 60;
  bool get partoInminente =>
      diasParaParto != null && diasParaParto! >= 0 && diasParaParto! < 7;
  bool get partoVencido => diasParaParto != null && diasParaParto! < 0;
  bool get celoPorServir {
    final celo = ultimo(TipoEventoReproductivo.celo);
    if (celo == null ||
        DateTime(celo.fecha.year, celo.fecha.month, celo.fecha.day) != hoy ||
        prenada) {
      return false;
    }
    final idx = eventos.indexOf(celo);
    return !eventos
        .skip(idx + 1)
        .any((e) => e.tipo == TipoEventoReproductivo.servicio);
  }
}

class ResumenReproductivo {
  final List<CicloAnimal> ciclos;
  ResumenReproductivo(
    List<AnimalModel> animales,
    List<EventoReproductivo> eventos,
    DateTime hoy,
  ) : ciclos = animales
          .where((a) => !a.esExterno && a.estadoActual == 'Activo')
          .map((a) => CicloAnimal(a, eventos, hoy))
          .toList();
  Iterable<CicloAnimal> get hembras =>
      ciclos.where((c) => c.animal.sexo == 'Hembra');
  double? _promedio(Iterable<int?> valores) {
    final validos = valores.whereType<int>().toList();
    return validos.isEmpty
        ? null
        : validos.reduce((a, b) => a + b) / validos.length;
  }

  double? get delPromedio => _promedio(hembras.map((c) => c.del));
  double? get diasAbiertosPromedio =>
      _promedio(hembras.map((c) => c.diasAbiertos));
  int get proximosPartos => hembras
      .where(
        (c) =>
            c.diasParaParto != null &&
            c.diasParaParto! >= 0 &&
            c.diasParaParto! <= 30,
      )
      .length;
  int get celosHoy => hembras.where((c) => c.celoPorServir).length;
  List<({String metodo, bool positivo})> get resultados {
    final salida = <({String metodo, bool positivo})>[];
    for (final c in hembras) {
      for (final servicio in c.eventos.where(
        (e) => e.tipo == TipoEventoReproductivo.servicio,
      )) {
        final diagnostico = c.eventos
            .where(
              (e) =>
                  e.tipo == TipoEventoReproductivo.diagnostico &&
                  e.servicioId == servicio.id,
            )
            .lastOrNull;
        if (diagnostico?.positivo != null && servicio.metodo != null) {
          salida.add((
            metodo: servicio.metodo!,
            positivo: diagnostico!.positivo!,
          ));
        }
      }
    }
    return salida;
  }

  double? tasa([String? metodo]) {
    final datos = resultados
        .where((r) => metodo == null || r.metodo == metodo)
        .toList();
    return datos.isEmpty
        ? null
        : 100 * datos.where((r) => r.positivo).length / datos.length;
  }
}
