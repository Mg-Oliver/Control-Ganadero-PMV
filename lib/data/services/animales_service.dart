import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/animal_model.dart';
import '../models/genealogia_model.dart';

class AnimalesService {
  final SupabaseClient? _client;
  AnimalesService({SupabaseClient? client}) : _client = client;
  SupabaseClient get _supabase => _client ?? SupabaseConfig.client;

  String? _columnaAusente(PostgrestException error, Iterable<String> columnas) {
    if (!['42703', 'PGRST204'].contains(error.code)) return null;
    return columnas.where((c) => error.message.contains(c)).firstOrNull;
  }

  Future<T> _escribirAnimal<T>(
    AnimalModel animal,
    Map<String, dynamic> datos,
    Future<T> Function(Map<String, dynamic>) escribir,
  ) async {
    final payload = Map<String, dynamic>.from(datos);
    while (true) {
      try {
        return await escribir(payload);
      } on PostgrestException catch (error) {
        final columna = _columnaAusente(error, ['es_externo', 'numero_partos']);
        if (columna == null || !payload.containsKey(columna)) rethrow;
        payload.remove(columna);
        payload['marcas_hierro'] = {
          ...animal.marcasHierro.toJson(),
          AnimalModel.metadataRegistroKey: {
            'es_externo': animal.esExterno,
            'numero_partos': animal.numeroPartos,
          },
        };
      }
    }
  }

  Future<T> _escribirGenealogia<T>(
    Map<String, dynamic> datos,
    Future<T> Function(Map<String, dynamic>) escribir,
  ) async {
    final payload = Map<String, dynamic>.from(datos);
    while (true) {
      try {
        return await escribir(payload);
      } on PostgrestException catch (error) {
        final columna = _columnaAusente(error, [
          'toro_donante_id',
          'toro_donante_snapshot',
        ]);
        // Solo omitir columnas opcionales vacías; nunca descartar un donante asignado.
        if (columna == null ||
            !payload.containsKey(columna) ||
            payload[columna] != null) {
          rethrow;
        }
        payload.remove(columna);
      }
    }
  }

  static const String _selectRelacional =
      '*, fincas(id, nombre, identificador), genealogia!genealogia_animal_id_fkey(*)';

  Future<List<AnimalModel>> obtenerPorFinca(
    String fincaId, {
    String? sexo,
  }) async {
    var query = _supabase.from('animales').select().eq('finca_id', fincaId);
    if (sexo != null && sexo.isNotEmpty) {
      query = query.eq('sexo', sexo);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => AnimalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AnimalModel>> consultarInventarioRelacional({
    String? fincaId,
    String? loteId,
    String? sexo,
    String? tipoExplotacion,
    String? estadoActual,
    bool? esRazaPura,
    String? razaPuraNombre,
    String? busqueda,
  }) async {
    List<AnimalModel> animales;

    try {
      var query = _supabase.from('animales').select(_selectRelacional);
      if (fincaId != null && fincaId.isNotEmpty) {
        query = query.eq('finca_id', fincaId);
      }
      if (sexo != null && sexo.isNotEmpty) {
        query = query.eq('sexo', sexo);
      }
      if (tipoExplotacion != null && tipoExplotacion.isNotEmpty) {
        query = query.eq('tipo_explotacion', tipoExplotacion);
      }
      if (estadoActual != null && estadoActual.isNotEmpty) {
        query = query.eq('estado_actual', estadoActual);
      }
      if (esRazaPura != null) {
        query = query.eq('es_raza_pura', esRazaPura);
      }
      if (esRazaPura == true &&
          razaPuraNombre != null &&
          razaPuraNombre.isNotEmpty) {
        query = query.eq('raza_pura_nombre', razaPuraNombre);
      }

      final response = await query.order('created_at', ascending: false);
      animales = (response as List<dynamic>)
          .map((e) => AnimalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback seguro si el nombre del constraint FK varía en la instancia
      final rawAnimales = await _supabase
          .from('animales')
          .select('*, fincas(id, nombre, identificador)')
          .order('created_at', ascending: false);
      final rawGenealogias = await _supabase.from('genealogia').select();

      final mapaGen = <String, GenealogiaModel>{};
      for (final g in (rawGenealogias as List<dynamic>)) {
        final genModel = GenealogiaModel.fromJson(g as Map<String, dynamic>);
        mapaGen[genModel.animalId] = genModel;
      }

      animales = (rawAnimales as List<dynamic>).map((e) {
        final base = AnimalModel.fromJson(e as Map<String, dynamic>);
        return base.copyWith(genealogia: mapaGen[base.id]);
      }).toList();
    }

    final q = (busqueda ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      animales = animales.where((a) {
        return a.areteManejo.toLowerCase().contains(q) ||
            (a.areteOficial ?? '').toLowerCase().contains(q) ||
            (a.nombreAlias ?? '').toLowerCase().contains(q) ||
            a.codigoSistema.toLowerCase().contains(q) ||
            a.razaEtiquetaDisplay.toLowerCase().contains(q);
      }).toList();
    }

    return animales;
  }

  Stream<List<Map<String, dynamic>>> streamCambios() {
    return _supabase.from('animales').stream(primaryKey: ['id']);
  }

  Future<List<AnimalModel>> buscarCandidatosParentesco({
    required String fincaId,
    required String sexo,
    String termino = '',
  }) async {
    final candidatos = await obtenerPorFinca(fincaId, sexo: sexo);
    final limpio = termino.trim().toLowerCase();
    if (limpio.isEmpty) return candidatos;

    return candidatos.where((animal) {
      final manejo = animal.areteManejo.toLowerCase();
      final oficial = (animal.areteOficial ?? '').toLowerCase();
      final alias = (animal.nombreAlias ?? '').toLowerCase();
      final codigo = animal.codigoSistema.toLowerCase();
      return manejo.contains(limpio) ||
          oficial.contains(limpio) ||
          alias.contains(limpio) ||
          codigo.contains(limpio);
    }).toList();
  }

  Future<AnimalModel> registrar(
    AnimalModel animal, {
    GenealogiaModel? genealogia,
  }) async {
    final includeId = animal.id.trim().isNotEmpty;
    final response = await _escribirAnimal<Map<String, dynamic>>(
      animal,
      animal.toJson(includeId: includeId, includeCodigo: false),
      (payload) => _supabase
          .from('animales')
          .insert(payload)
          .select('*, fincas(id, nombre, identificador)')
          .single(),
    );

    var nuevoAnimal = AnimalModel.fromJson(response);

    if (genealogia != null) {
      final tieneDatosGenealogia =
          genealogia.padreId != null ||
          genealogia.madreId != null ||
          (genealogia.padreExternoReferencia?.trim().isNotEmpty ?? false) ||
          (genealogia.madreExternaReferencia?.trim().isNotEmpty ?? false) ||
          (genealogia.rolFamiliarNacimiento?.trim().isNotEmpty ?? false) ||
          genealogia.tipoPruebaPaterna != 'Sin confirmar' ||
          genealogia.tipoPruebaMaterna != 'Sin confirmar';

      if (tieneDatosGenealogia) {
        try {
          final genInsertada = await _escribirGenealogia<Map<String, dynamic>>(
            genealogia
                .copyWith(animalId: nuevoAnimal.id)
                .toJson(includeId: false),
            (payload) =>
                _supabase.from('genealogia').insert(payload).select().single(),
          );
          nuevoAnimal = nuevoAnimal.copyWith(
            genealogia: GenealogiaModel.fromJson(genInsertada),
          );
        } catch (error, stack) {
          // Revierte únicamente el animal recién insertado si su genealogía no se guardó.
          try {
            await _supabase.from('animales').delete().eq('id', nuevoAnimal.id);
          } catch (_) {
            throw StateError(
              'Se creó el animal ${nuevoAnimal.codigoSistema}, pero no se completó su genealogía. Revise ese expediente antes de volver a registrarlo.',
            );
          }
          Error.throwWithStackTrace(error, stack);
        }
      }
    }

    return nuevoAnimal;
  }

  Future<AnimalModel> actualizar(AnimalModel animal) async {
    final json = animal.toJson();
    // Supabase no acepta columnas de solo lectura en el update
    json.remove('id');
    json.remove('codigo_sistema');
    json.remove('created_at');
    json.remove('fincas');
    json.remove('lotes');
    json.remove('genealogia');

    await _escribirAnimal<void>(animal, json, (payload) async {
      await _supabase.from('animales').update(payload).eq('id', animal.id);
    });

    if (animal.genealogia != null) {
      await _escribirGenealogia<void>(
        animal.genealogia!
            .copyWith(animalId: animal.id)
            .toJson(includeId: false),
        (payload) async {
          await _supabase
              .from('genealogia')
              .upsert(payload, onConflict: 'animal_id');
        },
      );
    }

    final response = await _supabase
        .from('animales')
        .select('*, fincas(id, nombre, identificador)')
        .eq('id', animal.id)
        .single();

    return AnimalModel.fromJson(
      response,
    ).copyWith(genealogia: animal.genealogia);
  }
}
