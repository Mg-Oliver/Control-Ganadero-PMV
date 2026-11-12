import 'package:shared_preferences/shared_preferences.dart';
import '../constants/columna_tabla.dart';

enum VistaInventario { tarjetas, tabla }

class InventarioPrefsService {
  static const _keyVista = 'inventario_vista';
  static const _keyColumnas = 'inventario_columnas';

  static Future<VistaInventario> cargarVista() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyVista);
    if (raw == VistaInventario.tabla.name) return VistaInventario.tabla;
    return VistaInventario.tarjetas;
  }

  static Future<void> guardarVista(VistaInventario vista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVista, vista.name);
  }

  static Future<Set<ColumnaTabla>> cargarColumnas() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyColumnas);
    if (lista == null) return Set.of(kColumnasDefault);
    final resultado = <ColumnaTabla>{};
    for (final s in lista) {
      try {
        resultado.add(ColumnaTabla.values.firstWhere((e) => e.name == s));
      } catch (_) {}
    }
    // Siempre asegurar el ancla mínima
    resultado.add(ColumnaTabla.arete);
    return resultado.isEmpty ? Set.of(kColumnasDefault) : resultado;
  }

  static Future<void> guardarColumnas(Set<ColumnaTabla> columnas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyColumnas,
      columnas.map((e) => e.name).toList(),
    );
  }
}
