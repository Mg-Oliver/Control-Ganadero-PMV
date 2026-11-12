import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';
import '../../ui/controllers/inventario_controller.dart';
import '../models/animal_model.dart';
import '../models/finca_model.dart';
import '../models/genealogia_model.dart';
import '../models/lote_model.dart';

/// Servicio de generación y provisión de datos semilla ganaderos realistas
/// para desarrollo, pruebas zootécnicas integrales y demostración del MVP.
class SeedService {
  // UUIDs fijos para mantener integridad referencial relacional entre fincas, lotes, animales y genealogía
  static const fincaRocioId = '11111111-1111-1111-1111-111111111111';
  static const fincaSantaMariaId = '22222222-2222-2222-2222-222222222222';
  static const fincaRanchoVerdeId = '33333333-3333-3333-3333-333333333333';

  static const loteCebaTorosId = 'aaaa1111-1111-1111-1111-111111111111';
  static const loteCriaTernerasId = 'aaaa2222-2222-2222-2222-222222222222';
  static const loteLecheriaPardoId = 'aaaa3333-3333-3333-3333-333333333333';
  static const loteReproductoresId = 'aaaa4444-4444-4444-4444-444444444444';
  static const loteDoblePropSimbrahId = 'aaaa5555-5555-5555-5555-555555555555';
  static const loteNovillasVientreId = 'aaaa6666-6666-6666-6666-666666666666';

  /// Retorna las 3 fincas zootécnicas con coordenadas, fuentes hídricas y dimensiones reales.
  static List<FincaModel> getSeedFincas() {
    return const [
      FincaModel(
        id: fincaRocioId,
        identificador: 'FNC-ROC-01',
        nombre: 'Hacienda El Rocío',
        ubicacion: 'Herrera, Vía Pesé Km 12',
        superficieHectareas: 120.0,
        estado: 'Activa',
        fuentesAgua: ['Pozo', 'Quebrada'],
        observaciones:
            'Especializada en producción lechera de alta genética y cría de reemplazos Girolando.',
      ),
      FincaModel(
        id: fincaSantaMariaId,
        identificador: 'FNC-STM-02',
        nombre: 'Finca Santa María',
        ubicacion: 'Los Santos, Valle del Río La Villa',
        superficieHectareas: 85.5,
        estado: 'Activa',
        fuentesAgua: ['Rio', 'Pozo', 'Acueducto rural'],
        observaciones:
            'Sistema silvopastoril intensivo con pastoreo rotacional Voisin y banco de forrajes.',
      ),
      FincaModel(
        id: fincaRanchoVerdeId,
        identificador: 'FNC-RVD-03',
        nombre: 'Rancho Verde',
        ubicacion: 'Chiriquí, Meseta de Boquerón',
        superficieHectareas: 200.0,
        estado: 'Activa',
        fuentesAgua: ['Quebrada', 'Rio'],
        observaciones:
            'Centro de ceba estabulada y mejoramiento genético en razas cebuinas y sintéticas.',
      ),
    ];
  }

  /// Retorna los 6 lotes de manejo productivo vinculados a sus respectivas fincas madre.
  static List<LoteModel> getSeedLotes() {
    return const [
      LoteModel(
        id: loteCriaTernerasId,
        fincaId: fincaRocioId,
        identificador: 'LOT-ROC-CRIA',
        nombre: 'Manga Cría Terneras Girolando',
        propositoProductivo: 'Cria',
        metaGananciaPesoDiaria: 0.850,
        dietaAsignada:
            'Lactoreemplazador 4L/día + Concentrado Iniciador 20% proteína + Heno de Pangola a voluntad',
        estado: 'Activo',
        fincaNombre: 'Hacienda El Rocío',
        fincaIdentificador: 'FNC-ROC-01',
      ),
      LoteModel(
        id: loteLecheriaPardoId,
        fincaId: fincaRocioId,
        identificador: 'LOT-ROC-LECH',
        nombre: 'Manga Lechería Especializada Pardo Suizo',
        propositoProductivo: 'Lecheria',
        metaGananciaPesoDiaria: 0.900,
        dietaAsignada:
            'Pastoreo rotacional estrella africana + Silo de maíz 15kg + Concentrado balanceado 18%',
        estado: 'Activo',
        fincaNombre: 'Hacienda El Rocío',
        fincaIdentificador: 'FNC-ROC-01',
      ),
      LoteModel(
        id: loteDoblePropSimbrahId,
        fincaId: fincaSantaMariaId,
        identificador: 'LOT-STM-SIMB',
        nombre: 'Manga Doble Propósito Simbrah',
        propositoProductivo: 'Doble Proposito',
        metaGananciaPesoDiaria: 0.950,
        dietaAsignada:
            'Pasturas Brachiaria brizantha + Bloques multinutricionales con melaza y urea + Sal mineralizada 8% P',
        estado: 'Activo',
        fincaNombre: 'Finca Santa María',
        fincaIdentificador: 'FNC-STM-02',
      ),
      LoteModel(
        id: loteNovillasVientreId,
        fincaId: fincaSantaMariaId,
        identificador: 'LOT-STM-NOVI',
        nombre: 'Manga Novillas de Vientre',
        propositoProductivo: 'Cria',
        metaGananciaPesoDiaria: 0.800,
        dietaAsignada:
            'Pastoreo continuo diferido + Suplementación energética con pulidura de arroz y sal mineral',
        estado: 'Activo',
        fincaNombre: 'Finca Santa María',
        fincaIdentificador: 'FNC-STM-02',
      ),
      LoteModel(
        id: loteCebaTorosId,
        fincaId: fincaRanchoVerdeId,
        identificador: 'LOT-RVD-CEBA',
        nombre: 'Manga Ceba Intensiva Toros',
        propositoProductivo: 'Ceba',
        metaGananciaPesoDiaria: 1.150,
        dietaAsignada:
            'Ración total mezclada (TMR): Ensilaje de maíz 60% + Harina de soya + Grano de destilería (DDGS)',
        estado: 'Activo',
        fincaNombre: 'Rancho Verde',
        fincaIdentificador: 'FNC-RVD-03',
      ),
      LoteModel(
        id: loteReproductoresId,
        fincaId: fincaRanchoVerdeId,
        identificador: 'LOT-RVD-REPR',
        nombre: 'Manga Reproductores y Donadores',
        propositoProductivo: 'Cria',
        metaGananciaPesoDiaria: 0.800,
        dietaAsignada:
            'Pastoreo en potreros reservados Mombasa + Heno de alfalfa + Premezcla vitamínica y selenio orgánico',
        estado: 'Activo',
        fincaNombre: 'Rancho Verde',
        fincaIdentificador: 'FNC-RVD-03',
      ),
    ];
  }

  /// Retorna un conjunto integral de 28 animales con razas puras, cruces Modo A,
  /// genealogía entrelazada padre/madre, marcas de hierro y diversos estados zootécnicos.
  static List<AnimalModel> getSeedAnimales() {
    // 1. Toros Reproductores Puros (Fundadores de genealogía)
    final toroSansao = AnimalModel(
      id: 'bbbb0001-0001-0001-0001-000100010001',
      codigoSistema: 'GAN-000001',
      areteManejo: 'TR-101',
      nombreAlias: 'Sansão do Rocío',
      sexo: 'Macho',
      pesoActual: 840.0,
      esRazaPura: true,
      razaPuraNombre: 'Gyr Lechero',
      razaEtiquetaDisplay: 'Gyr Lechero',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2021, 4, 10),
      origen: 'Comprado en subasta',
      fincaId: fincaRocioId,
      potreroActual: 'Potrero Los Guayacanes',
      loteId: loteLecheriaPardoId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2022, 1, 15),
      precioCompra: 2150.0,
      marcasHierro: const MarcasHierro(
        ubicacionCuerpo: 'Pierna izquierda',
        marcasOrejas: 'Muesca superior oreja derecha',
        colorMarcas: 'Hierro caliente',
        observacionHierro: 'Hierro HR coronado',
      ),
      genealogia: const GenealogiaModel(
        id: 'gen-001',
        animalId: 'bbbb0001-0001-0001-0001-000100010001',
        padreExternoReferencia: 'Radar dos Poções #BR-8832',
        tipoPruebaPaterna: 'ADN',
        madreExternaReferencia: 'Urgência da Silvania #119',
        tipoPruebaMaterna: 'Inseminacion',
      ),
      fincaNombre: 'Hacienda El Rocío',
      fincaIdentificador: 'FNC-ROC-01',
      loteNombre: 'Manga Lechería Especializada Pardo Suizo',
      loteIdentificador: 'LOT-ROC-LECH',
    );

    final toroEmperador = AnimalModel(
      id: 'bbbb0002-0002-0002-0002-000200020002',
      codigoSistema: 'GAN-000002',
      areteManejo: 'TR-202',
      nombreAlias: 'Emperador Brahman',
      sexo: 'Macho',
      pesoActual: 920.0,
      esRazaPura: true,
      razaPuraNombre: 'Brahman Gris',
      razaEtiquetaDisplay: 'Brahman Gris',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2020, 8, 22),
      origen: 'Nacido en la finca',
      fincaId: fincaRanchoVerdeId,
      potreroActual: 'Potrero El Higuerón',
      loteId: loteReproductoresId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2020, 8, 22),
      marcasHierro: const MarcasHierro(
        ubicacionCuerpo: 'Paleta derecha',
        marcasOrejas: 'Zarcillo oreja izquierda',
        colorMarcas: 'Hierro candente',
        observacionHierro: 'Marca RV con estrella',
      ),
      genealogia: const GenealogiaModel(
        id: 'gen-002',
        animalId: 'bbbb0002-0002-0002-0002-000200020002',
        padreExternoReferencia: 'JDH Mr Manso 420 (Catálogo ABS)',
        tipoPruebaPaterna: 'ADN',
        madreExternaReferencia: 'Miss RV Corona 88',
        tipoPruebaMaterna: 'Monta natural',
      ),
      fincaNombre: 'Rancho Verde',
      fincaIdentificador: 'FNC-RVD-03',
      loteNombre: 'Manga Reproductores y Donadores',
      loteIdentificador: 'LOT-RVD-REPR',
    );

    final vacaMilagrosa = AnimalModel(
      id: 'bbbb0003-0003-0003-0003-000300030003',
      codigoSistema: 'GAN-000003',
      areteManejo: 'VC-301',
      nombreAlias: 'Milagrosa Holstein',
      sexo: 'Hembra',
      pesoActual: 620.0,
      esRazaPura: true,
      razaPuraNombre: 'Holstein',
      razaEtiquetaDisplay: 'Holstein',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2021, 2, 14),
      origen: 'Comprado en subasta',
      fincaId: fincaRocioId,
      potreroActual: 'Potrero Ordeño 1',
      loteId: loteLecheriaPardoId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2021, 9, 1),
      precioCompra: 1500.0,
      marcasHierro: const MarcasHierro(
        ubicacionCuerpo: 'Pierna izquierda',
        marcasOrejas: 'Tatuaje H-301',
        colorMarcas: 'Nitrógeno líquido',
        observacionHierro: 'Hierro frío criador original',
      ),
      fincaNombre: 'Hacienda El Rocío',
      fincaIdentificador: 'FNC-ROC-01',
      loteNombre: 'Manga Lechería Especializada Pardo Suizo',
      loteIdentificador: 'LOT-ROC-LECH',
    );

    // 2. Cria Girolando F1 (Hija directa del Toro Sansao + Vaca Milagrosa en la misma finca)
    final criaGirolando = AnimalModel(
      id: 'bbbb0004-0004-0004-0004-000400040004',
      codigoSistema: 'GAN-000004',
      areteManejo: 'CR-401',
      nombreAlias: 'Princesa Girolando',
      sexo: 'Hembra',
      pesoActual: 215.0,
      esRazaPura: false,
      composicionCruces: const [
        {'raza': 'Gyr Lechero', 'fraccion': '1/2'},
        {'raza': 'Holstein', 'fraccion': '1/2'},
      ],
      razaEtiquetaDisplay:
          'Girolando F1 (1/2 Gyr Lechero, 1/2 Holstein)',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2025, 6, 20),
      origen: 'Nacido en la finca',
      fincaId: fincaRocioId,
      potreroActual: 'Cuna Terneras 2',
      loteId: loteCriaTernerasId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2025, 6, 20),
      genealogia: GenealogiaModel(
        id: 'gen-004',
        animalId: 'bbbb0004-0004-0004-0004-000400040004',
        padreId: toroSansao.id,
        tipoPruebaPaterna: 'ADN',
        madreId: vacaMilagrosa.id,
        tipoPruebaMaterna: 'Inseminacion',
      ),
      fincaNombre: 'Hacienda El Rocío',
      fincaIdentificador: 'FNC-ROC-01',
      loteNombre: 'Manga Cría Terneras Girolando',
      loteIdentificador: 'LOT-ROC-CRIA',
    );

    // 3. Animales F1 Simbrah y Girolando 5/8
    final novillaSimbrah = AnimalModel(
      id: 'bbbb0005-0005-0005-0005-000500050005',
      codigoSistema: 'GAN-000005',
      areteManejo: 'SB-505',
      nombreAlias: 'Sultana Simbrah',
      sexo: 'Hembra',
      pesoActual: 460.0,
      esRazaPura: false,
      composicionCruces: const [
        {'raza': 'Simmental', 'fraccion': '1/2'},
        {'raza': 'Brahman Gris', 'fraccion': '1/2'},
      ],
      razaEtiquetaDisplay:
          'Simbrah F1 (1/2 Simmental, 1/2 Brahman Gris)',
      tipoExplotacion: 'Doble Proposito',
      fechaNacimiento: DateTime(2023, 11, 10),
      origen: 'Nacido en la finca',
      fincaId: fincaSantaMariaId,
      potreroActual: 'Potrero Silvopastoril 3',
      loteId: loteDoblePropSimbrahId,
      estadoActual: 'Activo',
      fechaEntrada: DateTime(2023, 11, 10),
      genealogia: GenealogiaModel(
        id: 'gen-005',
        animalId: 'bbbb0005-0005-0005-0005-000500050005',
        padreId: toroEmperador.id,
        tipoPruebaPaterna: 'Monta natural',
        madreExternaReferencia: 'Vaca Simmental Donadora #SM-701',
        tipoPruebaMaterna: 'Inseminacion',
      ),
      fincaNombre: 'Finca Santa María',
      fincaIdentificador: 'FNC-STM-02',
      loteNombre: 'Manga Doble Propósito Simbrah',
      loteIdentificador: 'LOT-STM-SIMB',
    );

    // 4. Animales Vendidos, Muerto y Descartado para probar casos límite
    final novilloVendido = AnimalModel(
      id: 'bbbb0006-0006-0006-0006-000600060006',
      codigoSistema: 'GAN-000006',
      areteManejo: 'CB-601',
      nombreAlias: 'Toro Campeón Venta',
      sexo: 'Macho',
      pesoActual: 580.0,
      esRazaPura: true,
      razaPuraNombre: 'Angus',
      razaEtiquetaDisplay: 'Angus',
      tipoExplotacion: 'Ceba',
      fechaNacimiento: DateTime(2022, 1, 10),
      origen: 'Comprado en subasta',
      fincaId: fincaRanchoVerdeId,
      potreroActual: null, // Desasociado por baja
      loteId: null, // Desasociado por baja
      estadoActual: 'Vendido',
      fechaEntrada: DateTime(2022, 6, 1),
      precioCompra: 800.0,
      fechaSalida: DateTime(2024, 12, 15),
      observaciones:
          'Precio de Venta: US\$ 1,450.00 | Vendido para engorde final en Agropecuaria del Norte.',
      fincaNombre: 'Rancho Verde',
      fincaIdentificador: 'FNC-RVD-03',
    );

    final vacaMuerta = AnimalModel(
      id: 'bbbb0007-0007-0007-0007-000700070007',
      codigoSistema: 'GAN-000007',
      areteManejo: 'VC-707',
      nombreAlias: 'Lluvia Pardo',
      sexo: 'Hembra',
      pesoActual: 490.0,
      esRazaPura: true,
      razaPuraNombre: 'Pardo Suizo',
      razaEtiquetaDisplay: 'Pardo Suizo',
      tipoExplotacion: 'Lecheria',
      fechaNacimiento: DateTime(2019, 5, 12),
      origen: 'Nacido en la finca',
      fincaId: fincaRocioId,
      potreroActual: null,
      loteId: null,
      estadoActual: 'Muerto',
      fechaEntrada: DateTime(2019, 5, 12),
      fechaSalida: DateTime(2024, 8, 30),
      observaciones:
          'Baja sanitaria: Muerte súbita por timpanismo agudo. Acta veterinaria #VET-993.',
      fincaNombre: 'Hacienda El Rocío',
      fincaIdentificador: 'FNC-ROC-01',
    );

    final toroDescartado = AnimalModel(
      id: 'bbbb0008-0008-0008-0008-000800080008',
      codigoSistema: 'GAN-000008',
      areteManejo: 'DC-808',
      nombreAlias: 'Barroso Descarte',
      sexo: 'Macho',
      pesoActual: 610.0,
      esRazaPura: true,
      razaPuraNombre: 'Nelore',
      razaEtiquetaDisplay: 'Nelore',
      tipoExplotacion: 'Cria',
      fechaNacimiento: DateTime(2018, 9, 3),
      origen: 'Comprado en subasta',
      fincaId: fincaSantaMariaId,
      potreroActual: null,
      loteId: null,
      estadoActual: 'Descartado',
      fechaEntrada: DateTime(2019, 2, 1),
      fechaSalida: DateTime(2025, 1, 20),
      observaciones:
          'Descarte reproductivo por baja motilidad espermática y lesión podal en pata trasera.',
      fincaNombre: 'Finca Santa María',
      fincaIdentificador: 'FNC-STM-02',
    );

    // 5. Otros 20 animales complementarios para completar 28 ejemplares con diversidad de razas y lotes
    final listaCompleta = <AnimalModel>[
      toroSansao,
      toroEmperador,
      vacaMilagrosa,
      criaGirolando,
      novillaSimbrah,
      novilloVendido,
      vacaMuerta,
      toroDescartado,
    ];

    final razasAdicionales = [
      ('Nelore', true, 'Cria', 'Macho', fincaRanchoVerdeId, loteReproductoresId),
      ('Pardo Suizo', true, 'Lecheria', 'Hembra', fincaRocioId, loteLecheriaPardoId),
      ('Holstein', true, 'Lecheria', 'Hembra', fincaRocioId, loteLecheriaPardoId),
      ('Brahman Gris', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Simmental', true, 'Doble Proposito', 'Hembra', fincaSantaMariaId, loteDoblePropSimbrahId),
      ('Angus', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Gyr Lechero', true, 'Lecheria', 'Hembra', fincaRocioId, loteCriaTernerasId),
      ('Nelore', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Pardo Suizo', true, 'Cria', 'Hembra', fincaSantaMariaId, loteNovillasVientreId),
      ('Brahman Gris', true, 'Cria', 'Hembra', fincaSantaMariaId, loteNovillasVientreId),
      ('Simmental', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Holstein', true, 'Lecheria', 'Hembra', fincaRocioId, loteLecheriaPardoId),
      ('Gyr Lechero', true, 'Cria', 'Macho', fincaRocioId, loteCriaTernerasId),
      ('Brahman Gris', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Angus', true, 'Ceba', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
      ('Nelore', true, 'Doble Proposito', 'Hembra', fincaSantaMariaId, loteDoblePropSimbrahId),
      ('Pardo Suizo', true, 'Lecheria', 'Hembra', fincaRocioId, loteLecheriaPardoId),
      ('Holstein', true, 'Cria', 'Hembra', fincaSantaMariaId, loteNovillasVientreId),
      ('Brahman Gris', true, 'Cria', 'Hembra', fincaSantaMariaId, loteNovillasVientreId),
      ('Simmental', true, 'Doble Proposito', 'Macho', fincaRanchoVerdeId, loteCebaTorosId),
    ];

    for (int i = 0; i < razasAdicionales.length; i++) {
      final info = razasAdicionales[i];
      final num = 9 + i;
      final arete = '${info.$4 == "Macho" ? "MC" : "HM"}-${100 + num}';
      final codigo = 'GAN-${num.toString().padLeft(6, "0")}';

      listaCompleta.add(
        AnimalModel(
          id: 'bbbb00${num.toString().padLeft(2, "0")}-0000-0000-0000-000000000000',
          codigoSistema: codigo,
          areteManejo: arete,
          nombreAlias: 'Ejemplar $num',
          sexo: info.$4,
          pesoActual: 320.0 + (i * 18.5) % 350.0,
          esRazaPura: info.$2,
          razaPuraNombre: info.$1,
          razaEtiquetaDisplay: info.$1,
          tipoExplotacion: info.$3,
          fechaNacimiento:
              DateTime(2022, 1, 1).add(Duration(days: i * 45)),
          fechaNacimientoExacta: i % 2 == 0,
          origen: i % 3 == 0 ? 'Comprado en subasta' : 'Nacido en la finca',
          fincaId: info.$5,
          potreroActual: 'Potrero ${1 + (i % 5)}',
          loteId: info.$6,
          estadoActual: (num == 24 || num == 25) ? 'Vendido' : 'Activo',
          fechaEntrada:
              DateTime(2023, 2, 1).add(Duration(days: i * 30)),
          fechaSalida: (num == 24 || num == 25)
              ? DateTime(2025, 2, 10)
              : null,
          observaciones: (num == 24 || num == 25)
              ? 'Precio de Venta: US\$ 1,050.00'
              : 'Ejemplar en monitoreo de ganancia de peso.',
        ),
      );
    }

    return listaCompleta;
  }

  /// Carga de forma optimista inmediata todo el set de seed en el controlador del inventario
  /// sin requerir obligatoriamente conexión activa a Supabase.
  static void cargarEnControlador(InventarioController controller) {
    final fincas = getSeedFincas();
    final lotes = getSeedLotes();
    final animales = getSeedAnimales();

    for (final f in fincas) {
      controller.registrarFincaOptimista(f);
    }
    for (final l in lotes) {
      controller.registrarLoteOptimista(l);
    }
    for (final a in animales) {
      controller.registrarAnimalOptimista(a);
    }
  }

  /// Si Supabase está conectado, repuebla las tablas relacionales en la nube.
  static Future<bool> repoblarEnSupabase() async {
    try {
      final client = SupabaseConfig.client;

      // Inserción de fincas
      for (final f in getSeedFincas()) {
        await client.from('fincas').upsert(f.toJson());
      }
      // Inserción de lotes
      for (final l in getSeedLotes()) {
        await client.from('lotes').upsert(l.toJson());
      }
      // Inserción de animales
      for (final a in getSeedAnimales()) {
        await client.from('animales').upsert(a.toJson());
        if (a.genealogia != null) {
          await client.from('genealogia').upsert(a.genealogia!.toJson());
        }
      }
      return true;
    } catch (e) {
      debugPrint('Aviso al sembrar en Supabase: $e');
      return false;
    }
  }
}

