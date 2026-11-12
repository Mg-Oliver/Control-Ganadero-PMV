import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reproduccion_model.dart';

class ReproduccionService {
  static const _key = 'reproduccion_eventos_v1';
  Future<List<EventoReproductivo>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (e) =>
              EventoReproductivo.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> guardar(List<EventoReproductivo> eventos) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      _key,
      jsonEncode(eventos.map((e) => e.toJson()).toList()),
    );
    if (!ok) throw StateError('No se pudo guardar el registro');
  }
}
