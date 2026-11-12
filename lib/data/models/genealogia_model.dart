class GenealogiaModel {
  final String id;
  final String animalId;
  final String? padreId;
  final String? madreId;
  final String? padreExternoReferencia;
  final String? madreExternaReferencia;
  final String? rolFamiliarNacimiento;
  final String tipoPruebaPaterna; // 'Visual / Monta natural' | 'Inseminacion' | 'ADN' | 'Sin confirmar'
  final String tipoPruebaMaterna;
  final DateTime? createdAt;
  // Campos para Inseminación Artificial (IA) con toro donante
  final String? donanteId;
  final Map<String, dynamic>? donanteSnapshot;

  const GenealogiaModel({
    required this.id,
    required this.animalId,
    this.padreId,
    this.madreId,
    this.padreExternoReferencia,
    this.madreExternaReferencia,
    this.rolFamiliarNacimiento,
    this.tipoPruebaPaterna = 'Sin confirmar',
    this.tipoPruebaMaterna = 'Sin confirmar',
    this.createdAt,
    this.donanteId,
    this.donanteSnapshot,
  });

  factory GenealogiaModel.fromJson(Map<String, dynamic> json) {
    return GenealogiaModel(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      padreId: json['padre_id'] as String?,
      madreId: json['madre_id'] as String?,
      padreExternoReferencia: json['padre_externo_referencia'] as String?,
      madreExternaReferencia: json['madre_externa_referencia'] as String?,
      rolFamiliarNacimiento: json['rol_familiar_nacimiento'] as String?,
      tipoPruebaPaterna:
          (json['tipo_prueba_paterna'] as String?) ?? 'Sin confirmar',
      tipoPruebaMaterna:
          (json['tipo_prueba_materna'] as String?) ?? 'Sin confirmar',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      donanteId: json['toro_donante_id'] as String?,
      donanteSnapshot:
          json['toro_donante_snapshot'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'animal_id': animalId,
      'padre_id': padreId,
      'madre_id': madreId,
      'padre_externo_referencia': padreExternoReferencia,
      'madre_externa_referencia': madreExternaReferencia,
      'rol_familiar_nacimiento': rolFamiliarNacimiento,
      'tipo_prueba_paterna': tipoPruebaPaterna,
      'tipo_prueba_materna': tipoPruebaMaterna,
      'toro_donante_id': donanteId,
      'toro_donante_snapshot': donanteSnapshot,
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  GenealogiaModel copyWith({
    String? id,
    String? animalId,
    String? padreId,
    String? madreId,
    String? padreExternoReferencia,
    String? madreExternaReferencia,
    String? rolFamiliarNacimiento,
    String? tipoPruebaPaterna,
    String? tipoPruebaMaterna,
    DateTime? createdAt,
    String? donanteId,
    Map<String, dynamic>? donanteSnapshot,
  }) {
    return GenealogiaModel(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      padreId: padreId ?? this.padreId,
      madreId: madreId ?? this.madreId,
      padreExternoReferencia:
          padreExternoReferencia ?? this.padreExternoReferencia,
      madreExternaReferencia:
          madreExternaReferencia ?? this.madreExternaReferencia,
      rolFamiliarNacimiento:
          rolFamiliarNacimiento ?? this.rolFamiliarNacimiento,
      tipoPruebaPaterna: tipoPruebaPaterna ?? this.tipoPruebaPaterna,
      tipoPruebaMaterna: tipoPruebaMaterna ?? this.tipoPruebaMaterna,
      createdAt: createdAt ?? this.createdAt,
      donanteId: donanteId ?? this.donanteId,
      donanteSnapshot: donanteSnapshot ?? this.donanteSnapshot,
    );
  }
}
