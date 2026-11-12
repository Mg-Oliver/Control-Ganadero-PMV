class CategoriaRuleModel {
  final String sexo; // 'Macho' | 'Hembra' | 'Ambos'
  final int edadMinimoMeses; // inclusive
  final int edadMaximoMeses; // inclusive; -1 = sin máximo
  final bool requiereParto; // si true, se activa solo cuando numeroPartos > 0
  final String? tipoExplotacion; // null = aplica a todos
  final String categoria;

  const CategoriaRuleModel({
    required this.sexo,
    required this.edadMinimoMeses,
    required this.edadMaximoMeses,
    this.requiereParto = false,
    this.tipoExplotacion,
    required this.categoria,
  });

  factory CategoriaRuleModel.fromJson(Map<String, dynamic> json) {
    return CategoriaRuleModel(
      sexo: json['sexo'] as String,
      edadMinimoMeses: json['edad_minimo_meses'] as int,
      edadMaximoMeses: json['edad_maximo_meses'] as int,
      requiereParto: (json['requiere_parto'] as bool?) ?? false,
      tipoExplotacion: json['tipo_explotacion'] as String?,
      categoria: json['categoria'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sexo': sexo,
      'edad_minimo_meses': edadMinimoMeses,
      'edad_maximo_meses': edadMaximoMeses,
      'requiere_parto': requiereParto,
      'tipo_explotacion': tipoExplotacion,
      'categoria': categoria,
    };
  }

  CategoriaRuleModel copyWith({
    String? sexo,
    int? edadMinimoMeses,
    int? edadMaximoMeses,
    bool? requiereParto,
    String? tipoExplotacion,
    String? categoria,
  }) {
    return CategoriaRuleModel(
      sexo: sexo ?? this.sexo,
      edadMinimoMeses: edadMinimoMeses ?? this.edadMinimoMeses,
      edadMaximoMeses: edadMaximoMeses ?? this.edadMaximoMeses,
      requiereParto: requiereParto ?? this.requiereParto,
      tipoExplotacion: tipoExplotacion ?? this.tipoExplotacion,
      categoria: categoria ?? this.categoria,
    );
  }
}
