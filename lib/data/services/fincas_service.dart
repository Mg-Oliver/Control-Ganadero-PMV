import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/finca_model.dart';

class FincasService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  Future<List<FincaModel>> obtenerTodas({bool soloActivas = false}) async {
    var query = _supabase.from('fincas').select();
    if (soloActivas) {
      query = query.eq('estado', 'Activa');
    }
    final response = await query.order('nombre', ascending: true);

    return (response as List<dynamic>)
        .map((e) => FincaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FincaModel>> consultarInventario({
    String? estado,
    Set<String>? fuentesAgua,
    double? minHectareas,
    double? maxHectareas,
    String? busqueda,
  }) async {
    var query = _supabase.from('fincas').select();

    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }
    if (minHectareas != null) {
      query = query.gte('superficie_hectareas', minHectareas);
    }
    if (maxHectareas != null) {
      query = query.lte('superficie_hectareas', maxHectareas);
    }

    final response = await query.order('created_at', ascending: false);
    var lista = (response as List<dynamic>)
        .map((e) => FincaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (fuentesAgua != null && fuentesAgua.isNotEmpty) {
      lista = lista
          .where((f) => fuentesAgua.every((agua) => f.fuentesAgua.contains(agua)))
          .toList();
    }

    final q = (busqueda ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((f) {
        return f.nombre.toLowerCase().contains(q) ||
            f.identificador.toLowerCase().contains(q) ||
            (f.ubicacion ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return lista;
  }

  Stream<List<Map<String, dynamic>>> streamCambios() {
    return _supabase.from('fincas').stream(primaryKey: ['id']);
  }

  Future<bool> existeIdentificador(String identificador) async {
    final response = await _supabase
        .from('fincas')
        .select('id')
        .eq('identificador', identificador.trim())
        .maybeSingle();

    return response != null;
  }

  Future<FincaModel> crear(FincaModel finca) async {
    final includeId = finca.id.trim().isNotEmpty;
    final response = await _supabase
        .from('fincas')
        .insert(finca.toJson(includeId: includeId))
        .select()
        .single();

    return FincaModel.fromJson(response);
  }
}
