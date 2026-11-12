import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/categoria_rule_model.dart';

class CategoriaRulesService {
  static const String _prefKey = 'categoria_rules_custom';

  // Matriz de reglas predeterminadas
  static const List<CategoriaRuleModel> reglasDefault = [
    // Hembras — el parto tiene prioridad sobre la edad
    CategoriaRuleModel(
      sexo: 'Hembra',
      edadMinimoMeses: 0,
      edadMaximoMeses: -1,
      requiereParto: true,
      categoria: 'Vaca',
    ),
    CategoriaRuleModel(
      sexo: 'Hembra',
      edadMinimoMeses: 0,
      edadMaximoMeses: 4,
      categoria: 'Ternera',
    ),
    CategoriaRuleModel(
      sexo: 'Hembra',
      edadMinimoMeses: 5,
      edadMaximoMeses: -1,
      categoria: 'Novilla',
    ),
    // Machos
    CategoriaRuleModel(
      sexo: 'Macho',
      edadMinimoMeses: 0,
      edadMaximoMeses: 4,
      categoria: 'Ternero',
    ),
    CategoriaRuleModel(
      sexo: 'Macho',
      edadMinimoMeses: 5,
      edadMaximoMeses: 23,
      categoria: 'Novillo',
    ),
    CategoriaRuleModel(
      sexo: 'Macho',
      edadMinimoMeses: 24,
      edadMaximoMeses: -1,
      categoria: 'Toro',
    ),
  ];

  List<CategoriaRuleModel> _reglas;

  CategoriaRulesService([List<CategoriaRuleModel>? reglas])
      : _reglas = reglas ?? reglasDefault;

  // Singleton global para acceso reactivo desde AnimalModel y la UI
  static CategoriaRulesService _instance = CategoriaRulesService();
  static CategoriaRulesService get instance => _instance;
  static void updateInstance(CategoriaRulesService svc) => _instance = svc;

  List<CategoriaRuleModel> get reglas => List.unmodifiable(_reglas);

  // Evaluador principal
  String determinarCategoria({
    required DateTime fechaNacimiento,
    required String sexo,
    int numeroPartos = 0,
    String? tipoExplotacion,
  }) {
    final edadMeses = _calcularEdadMeses(fechaNacimiento, DateTime.now());

    // 1. Reglas condicionadas a parto (prioridad más alta, solo hembras)
    if (numeroPartos > 0) {
      for (final regla in _reglas) {
        if (!regla.requiereParto) continue;
        if (!_coincideSexo(regla.sexo, sexo)) continue;
        if (regla.tipoExplotacion != null &&
            regla.tipoExplotacion != tipoExplotacion) {
          continue;
        }
        return regla.categoria;
      }
    }

    // 2. Reglas por edad
    for (final regla in _reglas) {
      if (regla.requiereParto) continue;
      if (!_coincideSexo(regla.sexo, sexo)) continue;
      if (regla.tipoExplotacion != null &&
          regla.tipoExplotacion != tipoExplotacion) {
        continue;
      }
      if (edadMeses < regla.edadMinimoMeses) continue;
      if (regla.edadMaximoMeses != -1 && edadMeses > regla.edadMaximoMeses) {
        continue;
      }
      return regla.categoria;
    }

    // 3. Fallback adulto por sexo
    return sexo == 'Hembra' ? 'Vaca' : 'Toro';
  }

  // Conveniencia estática para usar sin instanciar (con reglas por defecto)
  static String evaluar({
    required DateTime fechaNacimiento,
    required String sexo,
    int numeroPartos = 0,
    String? tipoExplotacion,
    List<CategoriaRuleModel>? reglas,
  }) {
    return CategoriaRulesService(reglas).determinarCategoria(
      fechaNacimiento: fechaNacimiento,
      sexo: sexo,
      numeroPartos: numeroPartos,
      tipoExplotacion: tipoExplotacion,
    );
  }

  void personalizarReglas(List<CategoriaRuleModel> nuevasReglas) {
    _reglas = nuevasReglas;
  }

  void restaurarDefectos() {
    _reglas = reglasDefault;
  }

  Future<void> guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_reglas.map((r) => r.toJson()).toList());
    await prefs.setString(_prefKey, jsonStr);
  }

  static Future<CategoriaRulesService> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final list = (jsonDecode(jsonStr) as List)
            .map((e) => CategoriaRuleModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return CategoriaRulesService(list);
      }
    } catch (_) {
      // JSON inválido u otro error → fallback a reglas por defecto
    }
    return CategoriaRulesService();
  }

  static bool _coincideSexo(String reglaSexo, String sexoAnimal) {
    return reglaSexo == 'Ambos' || reglaSexo == sexoAnimal;
  }

  static int _calcularEdadMeses(DateTime nacimiento, DateTime ahora) {
    if (nacimiento.isAfter(ahora)) return 0;
    int meses =
        (ahora.year - nacimiento.year) * 12 + (ahora.month - nacimiento.month);
    if (ahora.day < nacimiento.day) meses--;
    return meses < 0 ? 0 : meses;
  }
}
