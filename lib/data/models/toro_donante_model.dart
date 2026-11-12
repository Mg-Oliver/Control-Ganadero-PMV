class AncestroDonanteModel {
  final String nombre;
  final String codigo;
  final String raza;

  const AncestroDonanteModel({
    this.nombre = '',
    this.codigo = '',
    this.raza = '',
  });

  bool get tieneDatos =>
      nombre.trim().isNotEmpty ||
      codigo.trim().isNotEmpty ||
      raza.trim().isNotEmpty;

  factory AncestroDonanteModel.fromJson(Map<String, dynamic> json) {
    return AncestroDonanteModel(
      nombre: (json['nombre'] as String?) ?? '',
      codigo: (json['codigo'] as String?) ?? '',
      raza: (json['raza'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'codigo': codigo,
        'raza': raza,
      };
}

class GenealogiaDonanteModel {
  final AncestroDonanteModel padre;
  final AncestroDonanteModel madre;
  final AncestroDonanteModel abueloPaterno;
  final AncestroDonanteModel abuelaPaterna;
  final AncestroDonanteModel abueloMaterno;
  final AncestroDonanteModel abuelaMaterna;

  const GenealogiaDonanteModel({
    this.padre = const AncestroDonanteModel(),
    this.madre = const AncestroDonanteModel(),
    this.abueloPaterno = const AncestroDonanteModel(),
    this.abuelaPaterna = const AncestroDonanteModel(),
    this.abueloMaterno = const AncestroDonanteModel(),
    this.abuelaMaterna = const AncestroDonanteModel(),
  });

  bool get tieneDatos =>
      padre.tieneDatos ||
      madre.tieneDatos ||
      abueloPaterno.tieneDatos ||
      abuelaPaterna.tieneDatos ||
      abueloMaterno.tieneDatos ||
      abuelaMaterna.tieneDatos;

  factory GenealogiaDonanteModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GenealogiaDonanteModel();
    AncestroDonanteModel anc(String key) => AncestroDonanteModel.fromJson(
          (json[key] as Map<String, dynamic>?) ?? {},
        );
    return GenealogiaDonanteModel(
      padre: anc('padre'),
      madre: anc('madre'),
      abueloPaterno: anc('abuelo_paterno'),
      abuelaPaterna: anc('abuela_paterna'),
      abueloMaterno: anc('abuelo_materno'),
      abuelaMaterna: anc('abuela_materna'),
    );
  }

  Map<String, dynamic> toJson() => {
        'padre': padre.toJson(),
        'madre': madre.toJson(),
        'abuelo_paterno': abueloPaterno.toJson(),
        'abuela_paterna': abuelaPaterna.toJson(),
        'abuelo_materno': abueloMaterno.toJson(),
        'abuela_materna': abuelaMaterna.toJson(),
      };
}

class ToroDonanteModel {
  final String id;
  final String nombre;
  final String codigoPajuela;
  final String raza;
  final GenealogiaDonanteModel genealogia;
  final bool activo;
  final DateTime? createdAt;

  const ToroDonanteModel({
    required this.id,
    required this.nombre,
    required this.codigoPajuela,
    this.raza = '',
    this.genealogia = const GenealogiaDonanteModel(),
    this.activo = true,
    this.createdAt,
  });

  String get etiquetaDisplay => codigoPajuela.isNotEmpty
      ? '$nombre · $codigoPajuela'
      : nombre;

  factory ToroDonanteModel.fromJson(Map<String, dynamic> json) {
    return ToroDonanteModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoPajuela: json['codigo_pajuela'] as String,
      raza: (json['raza'] as String?) ?? '',
      genealogia: GenealogiaDonanteModel.fromJson(
        json['genealogia'] as Map<String, dynamic>?,
      ),
      activo: (json['activo'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final m = <String, dynamic>{
      'nombre': nombre,
      'codigo_pajuela': codigoPajuela,
      'raza': raza,
      'genealogia': genealogia.toJson(),
      'activo': activo,
    };
    if (includeId && id.isNotEmpty) m['id'] = id;
    return m;
  }
}
