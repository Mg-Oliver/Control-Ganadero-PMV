-- Se conservan animales y mangas; únicamente se retira su asociación.
UPDATE public.animales SET lote_id = NULL WHERE lote_id IS NOT NULL;
CREATE OR REPLACE FUNCTION public.desvincular_manga_animal()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.lote_id := NULL;
  RETURN NEW;
END;
$$;
CREATE TRIGGER animales_sin_manga
BEFORE INSERT OR UPDATE OF lote_id ON public.animales
FOR EACH ROW EXECUTE FUNCTION public.desvincular_manga_animal();
