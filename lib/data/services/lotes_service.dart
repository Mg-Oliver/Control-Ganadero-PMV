import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/lote_model.dart';

class LotesService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  Future<List<LoteModel>> obtenerPorFinca(
    String fincaId, {
    bool soloActivos = false,
  }) async {
    var query = _supabase
        .from('lotes')
        .select('*, fincas(id, nombre, identificador)')
        .eq('finca_id', fincaId);
    if (soloActivos) {
      query = query.eq('estado', 'Activo');
    }
    final response = await query.order('nombre', ascending: true);

    return (response as List<dynamic>)
        .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LoteModel>> consultarInventario({
    String? fincaId,
    String? proposito,
    String? estado,
    String? busqueda,
  }) async {
    var query =
        _supabase.from('lotes').select('*, fincas(id, nombre, identificador)');

    if (fincaId != null && fincaId.isNotEmpty) {
      query = query.eq('finca_id', fincaId);
    }
    if (proposito != null && proposito.isNotEmpty) {
      query = query.eq('proposito_productivo', proposito);
    }
    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }

    final response = await query.order('created_at', ascending: false);
    var lista = (response as List<dynamic>)
        .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final q = (busqueda ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((l) {
        return l.nombre.toLowerCase().contains(q) ||
            l.identificador.toLowerCase().contains(q) ||
            (l.fincaNombre ?? '').toLowerCase().contains(q) ||
            (l.dietaAsignada ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return lista;
  }

  Stream<List<Map<String, dynamic>>> streamCambios() {
    return _supabase.from('lotes').stream(primaryKey: ['id']);
  }

  Future<bool> existeIdentificadorEnFinca({
    required String fincaId,
    required String identificador,
  }) async {
    final response = await _supabase
        .from('lotes')
        .select('id')
        .eq('finca_id', fincaId)
        .eq('identificador', identificador.trim())
        .maybeSingle();

    return response != null;
  }

  Future<LoteModel> crear(LoteModel lote) async {
    final includeId = lote.id.trim().isNotEmpty;
    final response = await _supabase
        .from('lotes')
        .insert(lote.toJson(includeId: includeId))
        .select('*, fincas(id, nombre, identificador)')
        .single();

    return LoteModel.fromJson(response);
  }
}
