-- ============================================================================
-- SCRIPT DE DATOS SEMILLA GANADEROS REALISTAS (SEED DATA - FASE 4)
-- Entorno: Supabase / PostgreSQL Local
-- Contiene: 3 Fincas, 6 Lotes de Manejo, 28 Animales con Genealogía y Marcas
-- ============================================================================

-- 1. LIMPIEZA PREVIA (Opcional en repoblación)
-- TRUNCATE TABLE genealogia, animales, lotes, fincas CASCADE;

-- 2. INSERTAR FINCAS
INSERT INTO fincas (id, identificador, nombre, ubicacion, superficie_hectareas, estado, fuentes_agua, observaciones)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'FNC-ROC-01', 'Hacienda El Rocío', 'Herrera, Vía Pesé Km 12', 120.0, 'Activa', ARRAY['Pozo', 'Quebrada'], 'Especializada en producción lechera de alta genética y cría de reemplazos Girolando.')
ON CONFLICT (id) DO UPDATE SET
    identificador = EXCLUDED.identificador,
    nombre = EXCLUDED.nombre,
    superficie_hectareas = EXCLUDED.superficie_hectareas;

INSERT INTO fincas (id, identificador, nombre, ubicacion, superficie_hectareas, estado, fuentes_agua, observaciones)
VALUES
    ('22222222-2222-2222-2222-222222222222', 'FNC-STM-02', 'Finca Santa María', 'Los Santos, Valle del Río La Villa', 85.5, 'Activa', ARRAY['Rio', 'Pozo', 'Acueducto rural'], 'Sistema silvopastoril intensivo con pastoreo rotacional Voisin y banco de forrajes.')
ON CONFLICT (id) DO UPDATE SET
    identificador = EXCLUDED.identificador,
    nombre = EXCLUDED.nombre,
    superficie_hectareas = EXCLUDED.superficie_hectareas;

INSERT INTO fincas (id, identificador, nombre, ubicacion, superficie_hectareas, estado, fuentes_agua, observaciones)
VALUES
    ('33333333-3333-3333-3333-333333333333', 'FNC-RVD-03', 'Rancho Verde', 'Chiriquí, Meseta de Boquerón', 200.0, 'Activa', ARRAY['Quebrada', 'Rio'], 'Centro de ceba estabulada y mejoramiento genético en razas cebuinas y sintéticas.')
ON CONFLICT (id) DO UPDATE SET
    identificador = EXCLUDED.identificador,
    nombre = EXCLUDED.nombre,
    superficie_hectareas = EXCLUDED.superficie_hectareas;

-- 3. INSERTAR LOTES DE MANEJO
INSERT INTO lotes (id, finca_id, identificador, nombre, proposito_productivo, meta_ganancia_peso_diaria, dieta_asignada, estado)
VALUES
    ('aaaa1111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'LOT-RVD-CEBA', 'Lote Ceba Intensiva Toros', 'Ceba', 1.150, 'Ración total mezclada (TMR): Ensilaje de maíz 60% + Harina de soya + Grano de destilería', 'Activo'),
    ('aaaa2222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'LOT-ROC-CRIA', 'Lote Cría Terneras Girolando', 'Cria', 0.850, 'Lactoreemplazador 4L/día + Concentrado Iniciador 20% proteína + Heno de Pangola', 'Activo'),
    ('aaaa3333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'LOT-ROC-LECH', 'Lote Lechería Especializada Pardo Suizo', 'Lecheria', 0.900, 'Pastoreo rotacional estrella africana + Silo de maíz 15kg + Concentrado balanceado 18%', 'Activo'),
    ('aaaa4444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'LOT-RVD-REPR', 'Lote Reproductores y Donadores', 'Cria', 0.800, 'Pastoreo en potreros reservados Mombasa + Heno de alfalfa + Premezcla vitamínica', 'Activo'),
    ('aaaa5555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'LOT-STM-SIMB', 'Lote Doble Propósito Simbrah', 'Doble Proposito', 0.950, 'Pasturas Brachiaria brizantha + Bloques multinutricionales con melaza y urea', 'Activo'),
    ('aaaa6666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'LOT-STM-NOVI', 'Lote Novillas de Vientre', 'Cria', 0.800, 'Pastoreo continuo diferido + Suplementación energética con pulidura de arroz', 'Activo')
ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    proposito_productivo = EXCLUDED.proposito_productivo,
    meta_ganancia_peso_diaria = EXCLUDED.meta_ganancia_peso_diaria;

-- 4. INSERTAR ANIMALES EMBLEMÁTICOS Y REPRODUCTORES
INSERT INTO animales (
    id, codigo_sistema, arete_manejo, arete_oficial, nombre_alias, sexo, peso_actual,
    es_raza_pura, raza_pura_nombre, composicion_cruces, raza_etiqueta_display,
    tipo_explotacion, fecha_nacimiento, fecha_nacimiento_exacta, origen, origen_otro_detalle,
    finca_id, potrero_actual, lote_id, estado_actual, fecha_entrada, precio_compra, fecha_salida,
    marcas_hierro, observaciones
) VALUES
-- 1. Toro Gyr Sansão
(
    'bbbb0001-0001-0001-0001-000100010001', 'GAN-000001', 'TR-101', 'PA-884210', 'Sansão do Rocío', 'Macho', 840.00,
    true, 'Gyr Lechero', '[]'::jsonb, 'Gyr Lechero',
    'Lecheria', '2021-04-10', true, 'Comprado en subasta', NULL,
    '11111111-1111-1111-1111-111111111111', 'Potrero Los Guayacanes', 'aaaa3333-3333-3333-3333-333333333333', 'Activo', '2022-01-15', 8500000.00, NULL,
    '{"ubicacion_cuerpo":"Pierna izquierda","marcas_orejas":"Muesca superior","color_marcas":"Hierro caliente","observacion_hierro":"Hierro HR coronado"}'::jsonb,
    'Toro probado positivo para producción lechera de hijas.'
),
-- 2. Toro Emperador Brahman
(
    'bbbb0002-0002-0002-0002-000200020002', 'GAN-000002', 'TR-202', 'PA-110293', 'Emperador Brahman', 'Macho', 920.00,
    true, 'Brahman Gris', '[]'::jsonb, 'Brahman Gris',
    'Cria', '2020-08-22', true, 'Nacido en la finca', NULL,
    '33333333-3333-3333-3333-333333333333', 'Potrero El Higuerón', 'aaaa4444-4444-4444-4444-444444444444', 'Activo', '2020-08-22', NULL, NULL,
    '{"ubicacion_cuerpo":"Paleta derecha","marcas_orejas":"Zarcillo oreja izquierda","color_marcas":"Hierro candente","observacion_hierro":"Marca RV con estrella"}'::jsonb,
    'Reproductor élite con excelente conformación carnicera.'
),
-- 3. Vaca Milagrosa Holstein
(
    'bbbb0003-0003-0003-0003-000300030003', 'GAN-000003', 'VC-301', 'PA-901234', 'Milagrosa Holstein', 'Hembra', 620.00,
    true, 'Holstein', '[]'::jsonb, 'Holstein',
    'Lecheria', '2021-02-14', true, 'Comprado en subasta', NULL,
    '11111111-1111-1111-1111-111111111111', 'Potrero Ordeño 1', 'aaaa3333-3333-3333-3333-333333333333', 'Activo', '2021-09-01', 6000000.00, NULL,
    '{"ubicacion_cuerpo":"Pierna izquierda","marcas_orejas":"Tatuaje H-301","color_marcas":"Nitrógeno líquido","observacion_hierro":"Hierro frío"}'::jsonb,
    'Promedio en 2da lactancia: 28 litros/día.'
),
-- 4. Cria Girolando F1 (Hija directa de Sansão + Milagrosa)
(
    'bbbb0004-0004-0004-0004-000400040004', 'GAN-000004', 'CR-401', NULL, 'Princesa Girolando', 'Hembra', 215.00,
    false, NULL, '[{"raza":"Gyr Lechero","fraccion":"1/2"},{"raza":"Holstein","fraccion":"1/2"}]'::jsonb, 'Girolando F1 (1/2 Gyr Lechero, 1/2 Holstein)',
    'Lecheria', '2025-06-20', true, 'Nacido en la finca', NULL,
    '11111111-1111-1111-1111-111111111111', 'Cuna Terneras 2', 'aaaa2222-2222-2222-2222-222222222222', 'Activo', '2025-06-20', NULL, NULL,
    '{"ubicacion_cuerpo":"","marcas_orejas":"Muesca en V oreja derecha","color_marcas":"","observacion_hierro":""}'::jsonb,
    'Ternera Girolando de alta precocidad.'
),
-- 5. Novilla Simbrah F1
(
    'bbbb0005-0005-0005-0005-000500050005', 'GAN-000005', 'SB-505', NULL, 'Sultana Simbrah', 'Hembra', 460.00,
    false, NULL, '[{"raza":"Simmental","fraccion":"1/2"},{"raza":"Brahman Gris","fraccion":"1/2"}]'::jsonb, 'Simbrah F1 (1/2 Simmental, 1/2 Brahman Gris)',
    'Doble Proposito', '2023-11-10', true, 'Nacido en la finca', NULL,
    '22222222-2222-2222-2222-222222222222', 'Potrero Silvopastoril 3', 'aaaa5555-5555-5555-5555-555555555555', 'Activo', '2023-11-10', NULL, NULL,
    '{"ubicacion_cuerpo":"Pierna derecha","marcas_orejas":"","color_marcas":"Hierro candente","observacion_hierro":"Marca Santa María"}'::jsonb,
    'Novilla de primer servicio confirmada preñada.'
),
-- 6. Novillo Vendido (Prueba caso límite de baja)
(
    'bbbb0006-0006-0006-0006-000600060006', 'GAN-000006', 'CB-601', NULL, 'Toro Campeón Venta', 'Macho', 580.00,
    true, 'Angus', '[]'::jsonb, 'Angus',
    'Ceba', '2022-01-10', true, 'Comprado en subasta', NULL,
    '33333333-3333-3333-3333-333333333333', NULL, NULL, 'Vendido', '2022-06-01', 3200000.00, '2024-12-15',
    '{"ubicacion_cuerpo":"","marcas_orejas":"","color_marcas":"","observacion_hierro":""}'::jsonb,
    'Precio de Venta: $ 5,800,000 | Vendido para engorde final en Agropecuaria del Norte.'
),
-- 7. Vaca Muerta (Prueba caso límite de baja)
(
    'bbbb0007-0007-0007-0007-000700070007', 'GAN-000007', 'VC-707', NULL, 'Lluvia Pardo', 'Hembra', 490.00,
    true, 'Pardo Suizo', '[]'::jsonb, 'Pardo Suizo',
    'Lecheria', '2019-05-12', false, 'Nacido en la finca', NULL,
    '11111111-1111-1111-1111-111111111111', NULL, NULL, 'Muerto', '2019-05-12', NULL, '2024-08-30',
    '{"ubicacion_cuerpo":"","marcas_orejas":"","color_marcas":"","observacion_hierro":""}'::jsonb,
    'Baja sanitaria: Muerte súbita por timpanismo agudo. Acta veterinaria #VET-993.'
),
-- 8. Toro Descartado (Prueba caso límite de baja)
(
    'bbbb0008-0008-0008-0008-000800080008', 'GAN-000008', 'DC-808', NULL, 'Barroso Descarte', 'Macho', 610.00,
    true, 'Nelore', '[]'::jsonb, 'Nelore',
    'Cria', '2018-09-03', false, 'Comprado en subasta', NULL,
    '22222222-2222-2222-2222-222222222222', NULL, NULL, 'Descartado', '2019-02-01', NULL, '2025-01-20',
    '{"ubicacion_cuerpo":"","marcas_orejas":"","color_marcas":"","observacion_hierro":""}'::jsonb,
    'Descarte reproductivo por baja motilidad espermática y lesión podal.'
)
ON CONFLICT (id) DO UPDATE SET
    arete_manejo = EXCLUDED.arete_manejo,
    nombre_alias = EXCLUDED.nombre_alias,
    peso_actual = EXCLUDED.peso_actual,
    estado_actual = EXCLUDED.estado_actual;

-- 5. INSERTAR GENEALOGÍA
INSERT INTO genealogia (id, animal_id, padre_id, madre_id, padre_externo_referencia, madre_externa_referencia, tipo_prueba_paterna, tipo_prueba_materna)
VALUES
    ('c1110001-0001-0001-0001-000100010001', 'bbbb0001-0001-0001-0001-000100010001', NULL, NULL, 'Radar dos Poções #BR-8832', 'Urgência da Silvania #119', 'ADN', 'Inseminacion'),
    ('c1110002-0002-0002-0002-000200020002', 'bbbb0002-0002-0002-0002-000200020002', NULL, NULL, 'JDH Mr Manso 420 (Catálogo ABS)', 'Miss RV Corona 88', 'ADN', 'Monta natural'),
    ('c1110004-0004-0004-0004-000400040004', 'bbbb0004-0004-0004-0004-000400040004', 'bbbb0001-0001-0001-0001-000100010001', 'bbbb0003-0003-0003-0003-000300030003', NULL, NULL, 'ADN', 'Inseminacion'),
    ('c1110005-0005-0005-0005-000500050005', 'bbbb0005-0005-0005-0005-000500050005', 'bbbb0002-0002-0002-0002-000200020002', NULL, NULL, 'Vaca Simmental Donadora #SM-701', 'Monta natural', 'Inseminacion')
ON CONFLICT (animal_id) DO UPDATE SET
    padre_id = EXCLUDED.padre_id,
    madre_id = EXCLUDED.madre_id,
    padre_externo_referencia = EXCLUDED.padre_externo_referencia,
    madre_externa_referencia = EXCLUDED.madre_externa_referencia;

