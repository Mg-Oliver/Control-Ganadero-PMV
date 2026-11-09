class LoteModel {
  final String id;
  final String fincaId;
  final String identificador;
  final String nombre;
  final String propositoProductivo; // 'Ceba' | 'Cria' | 'Lecheria'
  final double metaGananciaPesoDiaria;
  final String? dietaAsignada;
  final String estado; // 'Activo' | 'Cerrado'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos relacionales opcionales (join con fincas)
  final String? fincaNombre;
  final String? fincaIdentificador;

  const LoteModel({
    required this.id,
    required this.fincaId,
    required this.identificador,
    required this.nombre,
    required this.propositoProductivo,
    this.metaGananciaPesoDiaria = 0.0,
    this.dietaAsignada,
    this.estado = 'Activo',
    this.createdAt,
    this.updatedAt,
    this.fincaNombre,
    this.fincaIdentificador,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    final fincaMap = json['fincas'] is Map<String, dynamic>
        ? json['fincas'] as Map<String, dynamic>
        : null;

    return LoteModel(
      id: json['id'] as String,
      fincaId: json['finca_id'] as String,
      identificador: json['identificador'] as String,
      nombre: json['nombre'] as String,
      propositoProductivo: json['proposito_productivo'] as String,
      metaGananciaPesoDiaria: json['meta_ganancia_peso_diaria'] != null
          ? double.tryParse(json['meta_ganancia_peso_diaria'].toString()) ?? 0.0
          : 0.0,
      dietaAsignada: json['dieta_asignada'] as String?,
      estado: (json['estado'] as String?) ?? 'Activo',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      fincaNombre: fincaMap?['nombre'] as String?,
      fincaIdentificador: fincaMap?['identificador'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'finca_id': fincaId,
      'identificador': identificador,
      'nombre': nombre,
      'proposito_productivo': propositoProductivo,
      'meta_ganancia_peso_diaria': metaGananciaPesoDiaria,
      'dieta_asignada': dietaAsignada,
      'estado': estado,
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  LoteModel copyWith({
    String? id,
    String? fincaId,
    String? identificador,
    String? nombre,
    String? propositoProductivo,
    double? metaGananciaPesoDiaria,
    String? dietaAsignada,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fincaNombre,
    String? fincaIdentificador,
  }) {
    return LoteModel(
      id: id ?? this.id,
      fincaId: fincaId ?? this.fincaId,
      identificador: identificador ?? this.identificador,
      nombre: nombre ?? this.nombre,
      propositoProductivo: propositoProductivo ?? this.propositoProductivo,
      metaGananciaPesoDiaria:
          metaGananciaPesoDiaria ?? this.metaGananciaPesoDiaria,
      dietaAsignada: dietaAsignada ?? this.dietaAsignada,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fincaNombre: fincaNombre ?? this.fincaNombre,
      fincaIdentificador: fincaIdentificador ?? this.fincaIdentificador,
    );
  }
}
