import '../../core/services/categoria_rules_service.dart';
import 'genealogia_model.dart';

class MarcasHierro {
  final String ubicacionCuerpo;
  final String marcasOrejas;
  final String colorMarcas;
  final String observacionHierro;

  const MarcasHierro({
    this.ubicacionCuerpo = '',
    this.marcasOrejas = '',
    this.colorMarcas = '',
    this.observacionHierro = '',
  });

  bool get tieneDatos =>
      ubicacionCuerpo.trim().isNotEmpty ||
      marcasOrejas.trim().isNotEmpty ||
      colorMarcas.trim().isNotEmpty ||
      observacionHierro.trim().isNotEmpty;

  factory MarcasHierro.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MarcasHierro();
    return MarcasHierro(
      ubicacionCuerpo: (json['ubicacion_cuerpo'] as String?) ?? '',
      marcasOrejas: (json['marcas_orejas'] as String?) ?? '',
      colorMarcas: (json['color_marcas'] as String?) ?? '',
      observacionHierro: (json['observacion_hierro'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ubicacion_cuerpo': ubicacionCuerpo,
      'marcas_orejas': marcasOrejas,
      'color_marcas': colorMarcas,
      'observacion_hierro': observacionHierro,
    };
  }

  MarcasHierro copyWith({
    String? ubicacionCuerpo,
    String? marcasOrejas,
    String? colorMarcas,
    String? observacionHierro,
  }) {
    return MarcasHierro(
      ubicacionCuerpo: ubicacionCuerpo ?? this.ubicacionCuerpo,
      marcasOrejas: marcasOrejas ?? this.marcasOrejas,
      colorMarcas: colorMarcas ?? this.colorMarcas,
      observacionHierro: observacionHierro ?? this.observacionHierro,
    );
  }
}

class AnimalModel {
  final String id;
  final String codigoSistema;
  final String areteManejo;
  final String? areteOficial;
  final String? nombreAlias;
  final String sexo; // 'Macho' | 'Hembra'
  final double? pesoActual;
  final bool esRazaPura;
  final String? razaPuraNombre;
  final List<Map<String, String>> composicionCruces;
  final String razaEtiquetaDisplay;
  final String tipoExplotacion; // 'Ceba' | 'Cria' | 'Lecheria' | 'Doble Proposito'
  final DateTime fechaNacimiento;
  final bool fechaNacimientoExacta;
  final String origen; // 'Nacido en la finca' | 'Comprado en subasta' | ...
  final String? origenOtroDetalle;
  final String fincaId;
  final String? potreroActual;
  final String? loteId;
  final String estadoActual; // 'Activo' | 'Vendido' | 'Muerto' | ...
  final DateTime fechaEntrada;
  final double? precioCompra;
  final DateTime? fechaSalida;
  final MarcasHierro marcasHierro;
  final String? observaciones;
  final List<String> fotos;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int numeroPartos;

  // Campos relacionales opcionales (joins con fincas, lotes y genealogia)
  final String? fincaNombre;
  final String? fincaIdentificador;
  final String? loteNombre;
  final String? loteIdentificador;
  final GenealogiaModel? genealogia;

  const AnimalModel({
    required this.id,
    required this.codigoSistema,
    required this.areteManejo,
    this.areteOficial,
    this.nombreAlias,
    required this.sexo,
    this.pesoActual,
    this.esRazaPura = true,
    this.razaPuraNombre,
    this.composicionCruces = const [],
    required this.razaEtiquetaDisplay,
    required this.tipoExplotacion,
    required this.fechaNacimiento,
    this.fechaNacimientoExacta = true,
    required this.origen,
    this.origenOtroDetalle,
    required this.fincaId,
    this.potreroActual,
    this.loteId,
    this.estadoActual = 'Activo',
    required this.fechaEntrada,
    this.precioCompra,
    this.fechaSalida,
    this.marcasHierro = const MarcasHierro(),
    this.observaciones,
    this.fotos = const [],
    this.createdAt,
    this.updatedAt,
    this.numeroPartos = 0,
    this.fincaNombre,
    this.fincaIdentificador,
    this.loteNombre,
    this.loteIdentificador,
    this.genealogia,
  });

  String get edadFormateada {
    final ahora = DateTime.now();
    if (fechaNacimiento.isAfter(ahora)) return 'Recién nacido';

    int anios = ahora.year - fechaNacimiento.year;
    int meses = ahora.month - fechaNacimiento.month;
    if (ahora.day < fechaNacimiento.day) {
      meses--;
    }
    if (meses < 0) {
      anios--;
      meses += 12;
    }

    if (anios <= 0 && meses <= 0) {
      final dias = ahora.difference(fechaNacimiento).inDays;
      return '$dias ${dias == 1 ? "día" : "días"}';
    }
    if (anios <= 0) {
      return '$meses ${meses == 1 ? "mes" : "meses"}';
    }
    if (meses == 0) {
      return '$anios ${anios == 1 ? "año" : "años"}';
    }
    return '$anios ${anios == 1 ? "año" : "años"}, $meses ${meses == 1 ? "mes" : "meses"}';
  }

  String get categoriaZootecnica =>
      CategoriaRulesService.instance.determinarCategoria(
        fechaNacimiento: fechaNacimiento,
        sexo: sexo,
        numeroPartos: numeroPartos,
        tipoExplotacion: tipoExplotacion,
      );

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    final crucesRaw = json['composicion_cruces'] as List<dynamic>?;
    final cruces = crucesRaw?.map((item) {
          if (item is Map) {
            return item.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
          }
          return <String, String>{};
        }).toList() ??
        <Map<String, String>>[];

    final fincaMap = json['fincas'] is Map<String, dynamic>
        ? json['fincas'] as Map<String, dynamic>
        : null;
    final loteMap = json['lotes'] is Map<String, dynamic>
        ? json['lotes'] as Map<String, dynamic>
        : null;

    GenealogiaModel? genealogiaParsed;
    final genRaw = json['genealogia'];
    if (genRaw is Map<String, dynamic>) {
      genealogiaParsed = GenealogiaModel.fromJson(genRaw);
    } else if (genRaw is List && genRaw.isNotEmpty && genRaw.first is Map) {
      genealogiaParsed = GenealogiaModel.fromJson(
        Map<String, dynamic>.from(genRaw.first as Map),
      );
    }

    return AnimalModel(
      id: json['id'] as String,
      codigoSistema: (json['codigo_sistema'] as String?) ?? '',
      areteManejo: json['arete_manejo'] as String,
      areteOficial: json['arete_oficial'] as String?,
      nombreAlias: json['nombre_alias'] as String?,
      sexo: json['sexo'] as String,
      pesoActual: json['peso_actual'] != null
          ? double.tryParse(json['peso_actual'].toString())
          : null,
      esRazaPura: (json['es_raza_pura'] as bool?) ?? true,
      razaPuraNombre: json['raza_pura_nombre'] as String?,
      composicionCruces: cruces,
      razaEtiquetaDisplay: (json['raza_etiqueta_display'] as String?) ?? '',
      tipoExplotacion: json['tipo_explotacion'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'].toString()),
      fechaNacimientoExacta: (json['fecha_nacimiento_exacta'] as bool?) ?? true,
      origen: json['origen'] as String,
      origenOtroDetalle: json['origen_otro_detalle'] as String?,
      fincaId: json['finca_id'] as String,
      potreroActual: json['potrero_actual'] as String?,
      loteId: json['lote_id'] as String?,
      estadoActual: (json['estado_actual'] as String?) ?? 'Activo',
      fechaEntrada: json['fecha_entrada'] != null
          ? DateTime.parse(json['fecha_entrada'].toString())
          : DateTime.now(),
      precioCompra: json['precio_compra'] != null
          ? double.tryParse(json['precio_compra'].toString())
          : null,
      fechaSalida: json['fecha_salida'] != null
          ? DateTime.tryParse(json['fecha_salida'].toString())
          : null,
      marcasHierro: MarcasHierro.fromJson(
        json['marcas_hierro'] as Map<String, dynamic>?,
      ),
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
      numeroPartos: (json['numero_partos'] as int?) ?? 0,
      fincaNombre: fincaMap?['nombre'] as String?,
      fincaIdentificador: fincaMap?['identificador'] as String?,
      loteNombre: loteMap?['nombre'] as String?,
      loteIdentificador: loteMap?['identificador'] as String?,
      genealogia: genealogiaParsed,
    );
  }

  Map<String, dynamic> toJson({
    bool includeId = true,
    bool includeCodigo = true,
  }) {
    final map = <String, dynamic>{
      'arete_manejo': areteManejo,
      'arete_oficial': areteOficial,
      'nombre_alias': nombreAlias,
      'sexo': sexo,
      'peso_actual': pesoActual,
      'es_raza_pura': esRazaPura,
      'raza_pura_nombre': razaPuraNombre,
      'composicion_cruces': composicionCruces,
      'raza_etiqueta_display': razaEtiquetaDisplay,
      'tipo_explotacion': tipoExplotacion,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'fecha_nacimiento_exacta': fechaNacimientoExacta,
      'origen': origen,
      'origen_otro_detalle': origenOtroDetalle,
      'finca_id': fincaId,
      'potrero_actual': potreroActual,
      'lote_id': loteId,
      'estado_actual': estadoActual,
      'fecha_entrada': fechaEntrada.toIso8601String().split('T').first,
      'precio_compra': precioCompra,
      'fecha_salida': fechaSalida?.toIso8601String().split('T').first,
      'marcas_hierro': marcasHierro.toJson(),
      'observaciones': observaciones,
      'fotos': fotos,
      'numero_partos': numeroPartos,
    };
    if (includeId) {
      map['id'] = id;
    }
    if (includeCodigo && codigoSistema.isNotEmpty) {
      map['codigo_sistema'] = codigoSistema;
    }
    return map;
  }

  AnimalModel copyWith({
    String? id,
    String? codigoSistema,
    String? areteManejo,
    String? areteOficial,
    String? nombreAlias,
    String? sexo,
    double? pesoActual,
    bool? esRazaPura,
    String? razaPuraNombre,
    List<Map<String, String>>? composicionCruces,
    String? razaEtiquetaDisplay,
    String? tipoExplotacion,
    DateTime? fechaNacimiento,
    bool? fechaNacimientoExacta,
    String? origen,
    String? origenOtroDetalle,
    String? fincaId,
    String? potreroActual,
    String? loteId,
    String? estadoActual,
    DateTime? fechaEntrada,
    double? precioCompra,
    DateTime? fechaSalida,
    MarcasHierro? marcasHierro,
    String? observaciones,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? numeroPartos,
    String? fincaNombre,
    String? fincaIdentificador,
    String? loteNombre,
    String? loteIdentificador,
    GenealogiaModel? genealogia,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      codigoSistema: codigoSistema ?? this.codigoSistema,
      areteManejo: areteManejo ?? this.areteManejo,
      areteOficial: areteOficial ?? this.areteOficial,
      nombreAlias: nombreAlias ?? this.nombreAlias,
      sexo: sexo ?? this.sexo,
      pesoActual: pesoActual ?? this.pesoActual,
      esRazaPura: esRazaPura ?? this.esRazaPura,
      razaPuraNombre: razaPuraNombre ?? this.razaPuraNombre,
      composicionCruces: composicionCruces ?? this.composicionCruces,
      razaEtiquetaDisplay: razaEtiquetaDisplay ?? this.razaEtiquetaDisplay,
      tipoExplotacion: tipoExplotacion ?? this.tipoExplotacion,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fechaNacimientoExacta:
          fechaNacimientoExacta ?? this.fechaNacimientoExacta,
      origen: origen ?? this.origen,
      origenOtroDetalle: origenOtroDetalle ?? this.origenOtroDetalle,
      fincaId: fincaId ?? this.fincaId,
      potreroActual: potreroActual ?? this.potreroActual,
      loteId: loteId ?? this.loteId,
      estadoActual: estadoActual ?? this.estadoActual,
      fechaEntrada: fechaEntrada ?? this.fechaEntrada,
      precioCompra: precioCompra ?? this.precioCompra,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      marcasHierro: marcasHierro ?? this.marcasHierro,
      observaciones: observaciones ?? this.observaciones,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      numeroPartos: numeroPartos ?? this.numeroPartos,
      fincaNombre: fincaNombre ?? this.fincaNombre,
      fincaIdentificador: fincaIdentificador ?? this.fincaIdentificador,
      loteNombre: loteNombre ?? this.loteNombre,
      loteIdentificador: loteIdentificador ?? this.loteIdentificador,
      genealogia: genealogia ?? this.genealogia,
    );
  }
}
