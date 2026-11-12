import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/toro_donante_model.dart';

class TorosDonantesService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  Future<List<ToroDonanteModel>> obtenerActivos() async {
    final response = await _supabase
        .from('toros_donantes')
        .select()
        .eq('activo', true)
        .order('nombre');

    return (response as List<dynamic>)
        .map((e) => ToroDonanteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ToroDonanteModel> crear(ToroDonanteModel toro) async {
    final response = await _supabase
        .from('toros_donantes')
        .insert(toro.toJson(includeId: false))
        .select()
        .single();

    return ToroDonanteModel.fromJson(response);
  }
}
