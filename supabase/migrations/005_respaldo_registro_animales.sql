-- Promueve el respaldo compatible a columnas propias cuando se actualice el esquema.
ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS es_externo BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS numero_partos INTEGER NOT NULL DEFAULT 0 CHECK (numero_partos >= 0);
UPDATE public.animales SET
  es_externo = COALESCE((marcas_hierro #>> '{_registro_animal_v1,es_externo}')::boolean, es_externo),
  numero_partos = COALESCE((marcas_hierro #>> '{_registro_animal_v1,numero_partos}')::integer, numero_partos),
  marcas_hierro = marcas_hierro - '_registro_animal_v1'
WHERE jsonb_typeof(marcas_hierro -> '_registro_animal_v1') = 'object';
