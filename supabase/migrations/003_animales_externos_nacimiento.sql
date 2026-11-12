-- Los externos conservan su finca de referencia para gestionar la genealogía,
-- pero no pertenecen a sus existencias ni ocupan mangas.
ALTER TABLE public.animales ADD COLUMN IF NOT EXISTS es_externo BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS animales_es_externo_idx ON public.animales(es_externo);
ALTER TABLE public.animales ADD CONSTRAINT animales_externos_sin_manga CHECK (NOT es_externo OR lote_id IS NULL);
ALTER TYPE public.tipo_prueba_parentesco ADD VALUE IF NOT EXISTS 'Transferencia de embriones';
