import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/animal_model.dart';
import '../models/genealogia_model.dart';

class AnimalesService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  static const String _selectRelacional =
      '*, fincas(id, nombre, identificador), lotes(id, nombre, identificador), genealogia!genealogia_animal_id_fkey(*)';

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
      if (loteId != null && loteId.isNotEmpty) {
        query = query.eq('lote_id', loteId);
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
          .select('*, fincas(id, nombre, identificador), lotes(id, nombre, identificador)')
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
    final response = await _supabase
        .from('animales')
        .insert(animal.toJson(includeId: includeId, includeCodigo: false))
        .select('*, fincas(id, nombre, identificador), lotes(id, nombre, identificador)')
        .single();

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
        final genInsertada = await _supabase
            .from('genealogia')
            .insert(
              genealogia
                  .copyWith(animalId: nuevoAnimal.id)
                  .toJson(includeId: false),
            )
            .select()
            .single();
        nuevoAnimal = nuevoAnimal.copyWith(
          genealogia: GenealogiaModel.fromJson(genInsertada),
        );
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

    await _supabase
        .from('animales')
        .update(json)
        .eq('id', animal.id);

    final response = await _supabase
        .from('animales')
        .select('*, fincas(id, nombre, identificador), lotes(id, nombre, identificador)')
        .eq('id', animal.id)
        .single();

    return AnimalModel.fromJson(response);
  }
}
