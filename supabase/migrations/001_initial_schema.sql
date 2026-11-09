-- ==============================================================================
-- FASE 1: ESQUEMA BASE DE DATOS GANADERO (SUPABASE / POSTGRESQL)
-- ==============================================================================

-- EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUMS
CREATE TYPE estado_finca AS ENUM ('Activa', 'Inactiva');
CREATE TYPE fuente_agua AS ENUM ('Quebrada', 'Pozo', 'Rio', 'Acueducto rural');
CREATE TYPE proposito_lote AS ENUM ('Ceba', 'Cria', 'Lecheria');
CREATE TYPE estado_lote AS ENUM ('Activo', 'Cerrado');
CREATE TYPE sexo_animal AS ENUM ('Macho', 'Hembra');
CREATE TYPE tipo_explotacion AS ENUM ('Ceba', 'Cria', 'Lecheria', 'Doble Proposito');
CREATE TYPE origen_animal AS ENUM ('Nacido en la finca', 'Comprado en subasta', 'Arriendo', 'Otro');
CREATE TYPE estado_animal AS ENUM ('Activo', 'Vendido', 'Muerto', 'Descartado', 'Robado');
CREATE TYPE tipo_prueba_parentesco AS ENUM ('Visual / Monta natural', 'Inseminacion', 'ADN', 'Sin confirmar');

-- TABLA FINCAS
CREATE TABLE fincas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identificador TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    ubicacion TEXT,
    superficie_hectareas NUMERIC(10, 2) CHECK (superficie_hectareas >= 0),
    estado estado_finca DEFAULT 'Activa' NOT NULL,
    fuentes_agua fuente_agua[] DEFAULT '{}'::fuente_agua[],
    observaciones TEXT,
    fotos TEXT[] DEFAULT '{}'::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- TABLA LOTES
CREATE TABLE lotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    finca_id UUID NOT NULL REFERENCES fincas(id) ON DELETE CASCADE,
    identificador TEXT NOT NULL,
    nombre TEXT NOT NULL,
    proposito_productivo proposito_lote NOT NULL,
    meta_ganancia_peso_diaria NUMERIC(5, 3) DEFAULT 0.000 CHECK (meta_ganancia_peso_diaria >= 0),
    dieta_asignada TEXT,
    estado estado_lote DEFAULT 'Activo' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(finca_id, identificador)
);

-- SECUENCIA Y TRIGGER CÓDIGO ANIMAL
CREATE SEQUENCE IF NOT EXISTS secuencia_codigo_animal START 1;

CREATE OR REPLACE FUNCTION generar_codigo_animal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.codigo_sistema IS NULL OR NEW.codigo_sistema = '' THEN
        NEW.codigo_sistema := 'GAN-' || LPAD(nextval('secuencia_codigo_animal')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TABLA ANIMALES
CREATE TABLE animales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_sistema TEXT UNIQUE NOT NULL,
    arete_manejo TEXT NOT NULL,
    arete_oficial TEXT,
    nombre_alias TEXT,
    sexo sexo_animal NOT NULL,
    peso_actual NUMERIC(8, 2) CHECK (peso_actual >= 0),
    es_raza_pura BOOLEAN DEFAULT TRUE NOT NULL,
    raza_pura_nombre TEXT,
    composicion_cruces JSONB, -- [{"raza": "Brahman", "fraccion": "1/2"}]
    raza_etiqueta_display TEXT NOT NULL,
    tipo_explotacion tipo_explotacion NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    fecha_nacimiento_exacta BOOLEAN DEFAULT TRUE NOT NULL,
    origen origen_animal NOT NULL,
    origen_otro_detalle TEXT,
    finca_id UUID NOT NULL REFERENCES fincas(id) ON DELETE RESTRICT,
    potrero_actual TEXT,
    lote_id UUID REFERENCES lotes(id) ON DELETE SET NULL,
    estado_actual estado_animal DEFAULT 'Activo' NOT NULL,
    fecha_entrada DATE NOT NULL DEFAULT CURRENT_DATE,
    precio_compra NUMERIC(12, 2) CHECK (precio_compra >= 0),
    fecha_salida DATE,
    marcas_hierro JSONB DEFAULT '{"ubicacion_cuerpo":"","marcas_orejas":"","color_marcas":"","observacion_hierro":""}'::JSONB,
    observaciones TEXT,
    fotos TEXT[] DEFAULT '{}'::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_generar_codigo_animal
BEFORE INSERT ON animales
FOR EACH ROW
EXECUTE FUNCTION generar_codigo_animal();

-- TABLA GENEALOGIA
CREATE TABLE genealogia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID UNIQUE NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
    padre_id UUID REFERENCES animales(id) ON DELETE SET NULL,
    madre_id UUID REFERENCES animales(id) ON DELETE SET NULL,
    padre_externo_referencia TEXT,
    madre_externa_referencia TEXT,
    rol_familiar_nacimiento TEXT,
    tipo_prueba_paterna tipo_prueba_parentesco DEFAULT 'Sin confirmar',
    tipo_prueba_materna tipo_prueba_parentesco DEFAULT 'Sin confirmar',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- BUCKETS Y POLÍTICAS DE ACCESO
INSERT INTO storage.buckets (id, name, public) VALUES ('fincas_fotos', 'fincas_fotos', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('animales_fotos', 'animales_fotos', true) ON CONFLICT DO NOTHING;

ALTER TABLE fincas ENABLE ROW LEVEL SECURITY;
ALTER TABLE lotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE animales ENABLE ROW LEVEL SECURITY;
ALTER TABLE genealogia ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura y escritura fincas" ON fincas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Lectura y escritura lotes" ON lotes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Lectura y escritura animales" ON animales FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Lectura y escritura genealogia" ON genealogia FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Storage lectura fincas" ON storage.objects FOR SELECT USING (bucket_id = 'fincas_fotos');
CREATE POLICY "Storage insercion fincas" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'fincas_fotos');
CREATE POLICY "Storage lectura animales" ON storage.objects FOR SELECT USING (bucket_id = 'animales_fotos');
CREATE POLICY "Storage insercion animales" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'animales_fotos');

