class FincaModel {
  final String id;
  final String identificador;
  final String nombre;
  final String? ubicacion;
  final double? superficieHectareas;
  final String estado; // 'Activa' | 'Inactiva'
  final List<String> fuentesAgua;
  final String? observaciones;
  final List<String> fotos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FincaModel({
    required this.id,
    required this.identificador,
    required this.nombre,
    this.ubicacion,
    this.superficieHectareas,
    this.estado = 'Activa',
    this.fuentesAgua = const [],
    this.observaciones,
    this.fotos = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory FincaModel.fromJson(Map<String, dynamic> json) {
    return FincaModel(
      id: json['id'] as String,
      identificador: json['identificador'] as String,
      nombre: json['nombre'] as String,
      ubicacion: json['ubicacion'] as String?,
      superficieHectareas: json['superficie_hectareas'] != null
          ? double.tryParse(json['superficie_hectareas'].toString())
          : null,
      estado: (json['estado'] as String?) ?? 'Activa',
      fuentesAgua: (json['fuentes_agua'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      observaciones: json['observaciones'] as String?,
      fotos: (json['fotos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'identificador': identificador,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'superficie_hectareas': superficieHectareas,
      'estado': estado,
      'fuentes_agua': fuentesAgua,
      'observaciones': observaciones,
      'fotos': fotos,
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  FincaModel copyWith({
    String? id,
    String? identificador,
    String? nombre,
    String? ubicacion,
    double? superficieHectareas,
    String? estado,
    List<String>? fuentesAgua,
    String? observaciones,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FincaModel(
      id: id ?? this.id,
      identificador: identificador ?? this.identificador,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      superficieHectareas: superficieHectareas ?? this.superficieHectareas,
      estado: estado ?? this.estado,
      fuentesAgua: fuentesAgua ?? this.fuentesAgua,
      observaciones: observaciones ?? this.observaciones,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

