---
name: supabase-data-sync
description: Reglas para la creación de esquemas, migraciones, triggers, políticas RLS y sincronización de datos con Supabase
---

# Skill: Supabase Data & Migration Protocol

Esta skill guía la evolución del esquema de base de datos en Supabase (PostgreSQL) garantizando integridad referencial, seguridad RLS y retrocompatibilidad.

## 1. Convenciones de Nomenclatura y Esquemas
- Tablas y columnas en minúsculas con guiones bajos (`snake_case`): `fincas`, `lotes`, `animales`, `eventos_reproductivos`.
- Claves primarias siempre `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()`.
- Claves foráneas siempre terminan en `_id` (`finca_id`, `lote_id`, `madre_id`).
- Timestamps obligatorios en toda tabla: `created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL` y `updated_at`.

## 2. Creación de Nuevas Migraciones
Toda nueva funcionalidad que requiera tablas o columnas debe plasmarse en un nuevo archivo SQL en `supabase/migrations/` (ej. `002_reproduccion_schema.sql`):
1. **Definición de ENUMs:** Si se agregan estados reproductivos (`tipo_servicio`, `resultado_palpacion`, `tipo_parto`).
2. **Definición de Tablas:** Con restricciones `CHECK` (ej. pesos >= 0, fechas lógicas).
3. **Políticas RLS:** Toda tabla debe habilitar Row Level Security:
   ```sql
   ALTER TABLE nueva_tabla ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Lectura y escritura publica" ON nueva_tabla FOR ALL USING (true) WITH CHECK (true);
   ```
4. **Actualización de `seed.sql`:** Todo cambio estructural debe acompañarse de registros de ejemplo en `supabase/seed.sql` y en `lib/data/dev/seed_service.dart`.

## 3. Disparadores Automáticos (Triggers)
- Usar funciones PL/pgSQL para generación secuencial de códigos (`GAN-000001`) o actualización automática de `updated_at`.
- Para sincronización en tiempo real, habilitar `REPLICA IDENTITY FULL` si se van a consumir Supabase Realtime Streams.

