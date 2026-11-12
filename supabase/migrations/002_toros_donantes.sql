-- 002_toros_donantes.sql
-- Tabla de toros donantes y pajuelas para Inseminación Artificial (IA)

CREATE TABLE IF NOT EXISTS toros_donantes (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre          TEXT        NOT NULL,
  codigo_pajuela  TEXT        NOT NULL,
  raza            TEXT        NOT NULL DEFAULT '',
  genealogia      JSONB       NOT NULL DEFAULT '{}',
  activo          BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para búsqueda rápida de donantes activos
CREATE INDEX IF NOT EXISTS idx_toros_donantes_activo ON toros_donantes (activo);

-- Extender la tabla genealogia con soporte para toro donante (IA)
ALTER TABLE genealogia
  ADD COLUMN IF NOT EXISTS toro_donante_id UUID REFERENCES toros_donantes(id),
  ADD COLUMN IF NOT EXISTS toro_donante_snapshot JSONB;

-- RLS para toros_donantes
ALTER TABLE toros_donantes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated read toros_donantes"
  ON toros_donantes FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated insert toros_donantes"
  ON toros_donantes FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated update toros_donantes"
  ON toros_donantes FOR UPDATE
  USING (auth.role() = 'authenticated');
