import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovino_mvp/core/services/categoria_rules_service.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/categoria_rule_model.dart';

void main() {
  // Devuelve una fecha de nacimiento que hace exactamente [meses] meses.
  // Ajusta el día hacia atrás si el mes resultante tiene menos días.
  DateTime haceNMeses(int meses) {
    final ahora = DateTime.now();
    int anio = ahora.year;
    int mes = ahora.month - meses;
    while (mes <= 0) {
      mes += 12;
      anio--;
    }
    final diasEnMes = DateTime(anio, mes + 1, 0).day;
    final dia = ahora.day <= diasEnMes ? ahora.day : diasEnMes;
    return DateTime(anio, mes, dia);
  }

  group('7.4.1 — Categorización Machos', () {
    late CategoriaRulesService svc;

    setUp(() => svc = CategoriaRulesService());

    test('0 meses → Ternero', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now(),
          sexo: 'Macho',
        ),
        'Ternero',
      );
    });

    test('2 meses → Ternero', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(2),
          sexo: 'Macho',
        ),
        'Ternero',
      );
    });

    test('4 meses → Ternero (límite superior del rango)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(4),
          sexo: 'Macho',
        ),
        'Ternero',
      );
    });

    test('5 meses → Novillo (límite inferior del rango)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(5),
          sexo: 'Macho',
        ),
        'Novillo',
      );
    });

    test('12 meses → Novillo (etapa intermedia)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(12),
          sexo: 'Macho',
        ),
        'Novillo',
      );
    });

    test('23 meses → Novillo (límite superior del rango)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(23),
          sexo: 'Macho',
        ),
        'Novillo',
      );
    });

    test('24 meses → Toro (límite inferior del rango adulto)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(24),
          sexo: 'Macho',
        ),
        'Toro',
      );
    });

    test('36 meses → Toro', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(36),
          sexo: 'Macho',
        ),
        'Toro',
      );
    });

    test('Partos en macho no cambian la categoría', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(6),
          sexo: 'Macho',
          numeroPartos: 3,
        ),
        'Novillo',
      );
    });
  });

  group('7.4.2 — Categorización Hembras', () {
    late CategoriaRulesService svc;

    setUp(() => svc = CategoriaRulesService());

    test('0 meses → Ternera', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now(),
          sexo: 'Hembra',
        ),
        'Ternera',
      );
    });

    test('2 meses → Ternera', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(2),
          sexo: 'Hembra',
        ),
        'Ternera',
      );
    });

    test('4 meses → Ternera (límite superior del rango)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(4),
          sexo: 'Hembra',
        ),
        'Ternera',
      );
    });

    test('5 meses sin partos → Novilla', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(5),
          sexo: 'Hembra',
        ),
        'Novilla',
      );
    });

    test('18 meses sin partos → Novilla', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(18),
          sexo: 'Hembra',
        ),
        'Novilla',
      );
    });

    test('36 meses sin partos → Novilla (hembra adulta sin parto)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(36),
          sexo: 'Hembra',
        ),
        'Novilla',
      );
    });

    test('1 parto → Vaca (independiente de la edad)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(8),
          sexo: 'Hembra',
          numeroPartos: 1,
        ),
        'Vaca',
      );
    });

    test('1 parto con 2 meses → Vaca (parto fuerza categoría adulta)', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(2),
          sexo: 'Hembra',
          numeroPartos: 1,
        ),
        'Vaca',
      );
    });

    test('3 partos → Vaca', () {
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(24),
          sexo: 'Hembra',
          numeroPartos: 3,
        ),
        'Vaca',
      );
    });
  });

  group('7.4.3 — Personalización y fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Reglas personalizadas reemplazan las predeterminadas', () {
      final svc = CategoriaRulesService();
      svc.personalizarReglas([
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: 6,
          categoria: 'Becerro',
        ),
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 7,
          edadMaximoMeses: -1,
          categoria: 'Torete',
        ),
      ]);

      // Ahora las reglas son las personalizadas
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 60)),
          sexo: 'Macho',
        ),
        'Becerro',
      );
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 365)),
          sexo: 'Macho',
        ),
        'Torete',
      );
    });

    test('restaurarDefectos retorna a reglas originales tras personalización', () {
      final svc = CategoriaRulesService();
      svc.personalizarReglas([]);
      svc.restaurarDefectos();

      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 60)),
          sexo: 'Macho',
        ),
        'Ternero',
      );
    });

    test('Fallback a reglas predeterminadas cuando JSON es inválido', () async {
      SharedPreferences.setMockInitialValues({
        'categoria_rules_custom': 'json_malformado_{{{',
      });
      final svc = await CategoriaRulesService.cargar();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 60)),
          sexo: 'Macho',
        ),
        'Ternero',
      );
    });

    test('Fallback a reglas predeterminadas cuando preferencias están vacías',
        () async {
      final svc = await CategoriaRulesService.cargar();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 760)),
          sexo: 'Macho',
        ),
        'Toro',
      );
    });

    test('Serialización JSON de CategoriaRuleModel es reversible', () {
      const regla = CategoriaRuleModel(
        sexo: 'Hembra',
        edadMinimoMeses: 0,
        edadMaximoMeses: 4,
        requiereParto: false,
        categoria: 'Ternera',
      );
      final json = regla.toJson();
      final restored = CategoriaRuleModel.fromJson(json);

      expect(restored.sexo, regla.sexo);
      expect(restored.edadMinimoMeses, regla.edadMinimoMeses);
      expect(restored.edadMaximoMeses, regla.edadMaximoMeses);
      expect(restored.requiereParto, regla.requiereParto);
      expect(restored.categoria, regla.categoria);
    });

    test('Reglas por tipo de explotación específica aplican correctamente', () {
      final svc = CategoriaRulesService([
        const CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 0,
          edadMaximoMeses: -1,
          tipoExplotacion: 'Lecheria',
          categoria: 'Vaquilla Lechera',
        ),
        const CategoriaRuleModel(
          sexo: 'Hembra',
          edadMinimoMeses: 0,
          edadMaximoMeses: -1,
          categoria: 'Hembra General',
        ),
      ]);

      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 400)),
          sexo: 'Hembra',
          tipoExplotacion: 'Lecheria',
        ),
        'Vaquilla Lechera',
      );
      expect(
        svc.determinarCategoria(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 400)),
          sexo: 'Hembra',
          tipoExplotacion: 'Ceba',
        ),
        'Hembra General',
      );
    });
  });

  // ─── 16.1.1 — Reglas por tipo de explotación ─────────────────────────────

  group('16.1.1 — Reglas personalizadas por tipo de explotación', () {
    // Reglas estilo Lechería: ternera hasta 3 m, novilla hasta 25 m, vaca >25 m
    CategoriaRulesService svcLecheria() => CategoriaRulesService([
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 0,
            edadMaximoMeses: -1,
            requiereParto: true,
            tipoExplotacion: 'Lecheria',
            categoria: 'Vaca Lechera',
          ),
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 0,
            edadMaximoMeses: 3,
            tipoExplotacion: 'Lecheria',
            categoria: 'Ternera Lechera',
          ),
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 4,
            edadMaximoMeses: 25,
            tipoExplotacion: 'Lecheria',
            categoria: 'Novilla Lechera',
          ),
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 26,
            edadMaximoMeses: -1,
            tipoExplotacion: 'Lecheria',
            categoria: 'Vaca Lechera',
          ),
          // Reglas genéricas para otros tipos
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 0,
            edadMaximoMeses: 4,
            categoria: 'Ternera',
          ),
          const CategoriaRuleModel(
            sexo: 'Hembra',
            edadMinimoMeses: 5,
            edadMaximoMeses: -1,
            categoria: 'Novilla',
          ),
        ]);

    test('Lechería 2 meses sin partos → Ternera Lechera', () {
      final svc = svcLecheria();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(2),
          sexo: 'Hembra',
          tipoExplotacion: 'Lecheria',
        ),
        'Ternera Lechera',
      );
    });

    test('Lechería 10 meses sin partos → Novilla Lechera', () {
      final svc = svcLecheria();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(10),
          sexo: 'Hembra',
          tipoExplotacion: 'Lecheria',
        ),
        'Novilla Lechera',
      );
    });

    test('Lechería 30 meses sin partos → Vaca Lechera (edad > umbral)', () {
      final svc = svcLecheria();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(30),
          sexo: 'Hembra',
          tipoExplotacion: 'Lecheria',
        ),
        'Vaca Lechera',
      );
    });

    test('Lechería 8 meses con 1 parto → Vaca Lechera (parto fuerza adulta)',
        () {
      final svc = svcLecheria();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(8),
          sexo: 'Hembra',
          numeroPartos: 1,
          tipoExplotacion: 'Lecheria',
        ),
        'Vaca Lechera',
      );
    });

    test('Sin tipo de explotación cae en reglas genéricas', () {
      final svc = svcLecheria();
      expect(
        svc.determinarCategoria(
          fechaNacimiento: haceNMeses(10),
          sexo: 'Hembra',
        ),
        'Novilla',
      );
    });

    test('CategoriaRulesService.evaluar estático usa reglas pasadas como arg',
        () {
      const reglasEspeciales = [
        CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: -1,
          categoria: 'Buey Ceba',
        ),
      ];
      expect(
        CategoriaRulesService.evaluar(
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 400)),
          sexo: 'Macho',
          reglas: reglasEspeciales,
        ),
        'Buey Ceba',
      );
    });

    test('Reglas Cría: terneros hasta 6 m, destete 7-12 m, levante 13+ m', () {
      final svcCria = CategoriaRulesService([
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 0,
          edadMaximoMeses: 6,
          tipoExplotacion: 'Cria',
          categoria: 'Ternero Lactante',
        ),
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 7,
          edadMaximoMeses: 12,
          tipoExplotacion: 'Cria',
          categoria: 'Destete',
        ),
        const CategoriaRuleModel(
          sexo: 'Macho',
          edadMinimoMeses: 13,
          edadMaximoMeses: -1,
          tipoExplotacion: 'Cria',
          categoria: 'Levante Cría',
        ),
      ]);

      expect(
        svcCria.determinarCategoria(
          fechaNacimiento: haceNMeses(3),
          sexo: 'Macho',
          tipoExplotacion: 'Cria',
        ),
        'Ternero Lactante',
      );
      expect(
        svcCria.determinarCategoria(
          fechaNacimiento: haceNMeses(9),
          sexo: 'Macho',
          tipoExplotacion: 'Cria',
        ),
        'Destete',
      );
      expect(
        svcCria.determinarCategoria(
          fechaNacimiento: haceNMeses(18),
          sexo: 'Macho',
          tipoExplotacion: 'Cria',
        ),
        'Levante Cría',
      );
    });
  });

  // ─── 16.1.2 — Autocompletado de nombre_alias ─────────────────────────────

  group('16.1.2 — Autocompletado de nombre_alias', () {
    // Espeja la lógica del formulario al persistir el animal:
    //   nombreAlias = alias.trim().isNotEmpty ? alias.trim() : arete.trim()
    String resolverAlias(String alias, String arete) =>
        alias.trim().isNotEmpty ? alias.trim() : arete.trim();

    test('alias con texto → se conserva el alias', () {
      expect(resolverAlias('Marquesa', 'ART-001'), 'Marquesa');
    });

    test('alias vacío → fallback a areteManejo', () {
      expect(resolverAlias('', 'ART-001'), 'ART-001');
    });

    test('alias de solo espacios → fallback a areteManejo', () {
      expect(resolverAlias('   ', 'ART-002'), 'ART-002');
    });

    test('alias con espacios al borde → se recorta y usa alias', () {
      expect(resolverAlias('  Sultán  ', 'ART-003'), 'Sultán');
    });

    test('AnimalModel con nombreAlias nulo → display muestra areteManejo', () {
      final animal = AnimalModel(
        id: 'a1',
        codigoSistema: 'BV-001',
        areteManejo: 'ART-999',
        nombreAlias: null,
        sexo: 'Macho',
        razaEtiquetaDisplay: 'Holstein',
        tipoExplotacion: 'Lecheria',
        fechaNacimiento: DateTime(2023),
        origen: 'Nacido en la finca',
        fincaId: 'f1',
        estadoActual: 'Activo',
        fechaEntrada: DateTime(2023),
      );
      expect(animal.nombreAlias ?? animal.areteManejo, 'ART-999');
    });

    test('AnimalModel con nombreAlias asignado → display muestra alias', () {
      final animal = AnimalModel(
        id: 'a2',
        codigoSistema: 'BV-002',
        areteManejo: 'ART-888',
        nombreAlias: 'El Campeón',
        sexo: 'Macho',
        razaEtiquetaDisplay: 'Angus',
        tipoExplotacion: 'Ceba',
        fechaNacimiento: DateTime(2022),
        origen: 'Comprado en subasta',
        fincaId: 'f1',
        estadoActual: 'Activo',
        fechaEntrada: DateTime(2022),
      );
      expect(animal.nombreAlias ?? animal.areteManejo, 'El Campeón');
    });

    test('Resultado de resolverAlias nunca es vacío si areteManejo tiene texto',
        () {
      final resultado = resolverAlias('', 'MIN-01');
      expect(resultado.isNotEmpty, isTrue);
      expect(resultado, 'MIN-01');
    });
  });
}
