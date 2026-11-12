# CONTEXTO DEL PROYECTO: MVP CONTROL GANADERO BOVINO

**Última actualización:** Noviembre 2026  
**Repositorio Remoto:** [Mg-Oliver/Control-Ganadero-PMV](https://github.com/Mg-Oliver/Control-Ganadero-PMV)  
**Despliegue Web (GitHub Pages):** [https://mg-oliver.github.io/Control-Ganadero-PMV/](https://mg-oliver.github.io/Control-Ganadero-PMV/)  
**Rama principal de código:** `main`  
**Rama de despliegue web:** `gh-pages`  
**Estado:** Fase 1 a Fase 7 completadas al 100% (42/42 tests aprobados, `flutter analyze` en 0 errores y 0 advertencias).

---

## 1. Visión y Propósito del Software
Aplicación multiplataforma (Web / Móvil / Desktop) diseñada con **Flutter** y respaldada por **Supabase (PostgreSQL)** para la administración zootécnica, sanitaria y genealógica de hatos ganaderos bovinos. 

El sistema reemplaza las planillas manuales de campo mediante un flujo ágil de captura de datos, un catálogo central interactivo con visualización dual (tarjetas + tabla completa), expediente individual con linaje visual y reglas de negocio automatizadas para evitar inconsistencias operativas.

---

## 2. Stack Tecnológico y Arquitectura

| Capa | Tecnología / Herramienta | Detalle |
| :--- | :--- | :--- |
| **Framework UI** | Flutter 3.x (Dart >= 3.8.0 < 4.0.0) | Material Design 3, diseño responsivo adaptable |
| **Backend & DB** | Supabase (PostgreSQL 15+) | Tablas relacionales, tipos ENUM, Triggers PL/pgSQL, RLS, Storage Buckets |
| **Gestión de Estado** | ChangeNotifier / Controller Pattern | `InventarioController` desacoplado con actualización optimista |
| **Almacenamiento Local** | `.env` con fallback en producción | `flutter_dotenv` + `String.fromEnvironment` (`--dart-define`) |
| **Testing Automatizado** | `flutter_test` | 18 pruebas automatizadas (unitarias e integración) |
| **CI / CD & Hosting** | GitHub Pages + Vercel Ready | Rama `gh-pages` con build web estático, `vercel.json` con SPA rewrites |

---

## 3. Estructura de Navegación (Menú Drawer Lateral — Fase 5)

La aplicación usa un menú drawer lateral (`AppDrawer`) que reemplaza el `TabBar` previo. El `AppBar` muestra el título dinámico de la sección activa y el ícono hamburguesa. El `IndexedStack` preserva el estado de las 5 pantallas sin destruirlas al cambiar de sección:

1. **Panel de Control (`DashboardScreen`):**
   - KPIs reactivos (total fincas, lotes, animales activos) via `ListenableBuilder` sobre `InventarioController`.
   - Accesos rápidos para crear Fincas, Lotes y Animales (navegan a Expediente).
   - Widget de seed data de demostración.
2. **Expediente (Creación):**
   - Panel de formularios reactivos para el alta de **Fincas**, **Lotes** y **Animales**.
   - Validación zootécnica en tiempo real, doble aretado, orígenes y marcas de hierro.
3. **Inventario (Catálogo General):**
   - Espacio de trabajo responsivo de 3 áreas:
     - **Sidebar Izquierdo:** Filtros dinámicos contextuales según la entidad activa (Finca, Lote o Animal), selector de sexo, estado, raza/cruces y buscador predictivo.
     - **Área Central Dual:** Grid superior de tarjetas compactas con KPIs rápidos + Tabla de datos exhaustiva inferior con scroll bidireccional y ordenamiento por columnas.
     - **Drawer Lateral Derecho:** Expediente deslizable en alta resolución con ficha biométrica, marcas de hierro y árbol genealógico interactivo navegable.
4. **Ciclo de Reproducción:**
   - Módulo preparado estructuralmente (pantalla placeholder reservada para la siguiente etapa de desarrollo).
5. **Configuración:**
   - Estado de conexión a Supabase (verificación asíncrona en tiempo real).
   - Información de versión y opciones generales placeholder.

---

## 4. Reglas de Negocio Zootécnicas Implementadas

* **Prevención de Ciclos en Linaje (`GenealogiaValidator`):**
  - Detección recursiva de referencias circulares: un animal no puede ser su propio padre o madre, ni un descendiente directo puede asignarse como progenitor.
  - Exclusión automática en tiempo de ejecución del propio individuo y de sus descendientes conocidos en los selectores de padre y madre.
* **Cálculo de Fracciones de Sangre (`BreedCrossCalculator`):**
  - Descomposición de cruces genéticos en octavos de sangre.
  - Simplificación matemática de fracciones (ej. 2/4 a 1/2, 4/8 a 1/2).
  - Generación de etiquetas zootécnicas compuestas estandarizadas (ej. *F1 Simbrah 1/2*).
* **Consistencia Territorial y Salidas (`PredioConsistencyHelper`):**
  - Desasociación automática de lotes al transferir un animal a una nueva finca madre.
  - Al cambiar el estado a *Vendido*, *Muerto*, *Robado* o *Descartado*, se exige la fecha de salida, se habilita el precio de venta y se liberan de inmediato el potrero y lote físico ocupado.
* **Resiliencia Visual (`BovineAvatarPlaceholder`):**
  - En caso de ausencia de fotos tomadas en potrero o fallos de conexión a internet, genera un avatar vectorial inteligente con monograma tipográfico y tonalidad según sexo y aptitud zootécnica.
* **Notificaciones Desacopladas (`AppFeedback`):**
  - Mensajería global con SnackBars estilizadas para advertencias zootécnicas, confirmaciones de guardado y alertas de red sin bloquear la pantalla.

---

## 5. Esquema de Base de Datos (Supabase / PostgreSQL)

Ubicación del script de creación: [`supabase/migrations/001_initial_schema.sql`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/supabase/migrations/001_initial_schema.sql)

* **`fincas`:** `id (UUID)`, `identificador (UNIQUE)`, `nombre`, `ubicacion`, `superficie_hectareas`, `estado (Activa/Inactiva)`, `fuentes_agua (Array)`, `fotos (Array)`.
* **`lotes`:** `id (UUID)`, `finca_id (FK)`, `identificador`, `nombre`, `proposito_productivo (Ceba, Cria, Lecheria)`, `meta_ganancia_peso_diaria (kg/día)`, `dieta_asignada`, `estado (Activo/Cerrado)`.
* **`animales`:** `id (UUID)`, `codigo_sistema (GAN-000001 autogenerado)`, `arete_manejo`, `arete_oficial`, `nombre_alias`, `sexo (Macho/Hembra)`, `peso_actual`, `es_raza_pura`, `composicion_cruces (JSONB)`, `raza_etiqueta_display`, `tipo_explotacion`, `fecha_nacimiento`, `origen`, `finca_id (FK)`, `lote_id (FK)`, `potrero_actual`, `estado_actual (Activo, Vendido, etc.)`, `marcas_hierro (JSONB)`, `fotos (Array)`.
* **`genealogia`:** `animal_id (FK UNIQUE)`, `padre_id (FK)`, `madre_id (FK)`, `padre_externo_referencia`, `madre_externa_referencia`, `tipo_prueba_paterna`, `tipo_prueba_materna`.
* **Disparador PL/pgSQL:** `trg_generar_codigo_animal` ejecuta la secuencia `secuencia_codigo_animal` para asignación de códigos consecutivos únicos.
* **Buckets de Storage:** `fincas_fotos` y `animales_fotos` con políticas de lectura pública e inserción.

---

## 6. Set de Datos Semilla (*Seed Data*)
Para demostraciones y pruebas sin necesidad de cargar datos manuales:
- **Botón en la AppBar:** Icono de base de datos (`Poblar Datos Semilla (Demo)`).
- **Carga en memoria y script SQL:** [`supabase/seed.sql`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/supabase/seed.sql) y [`lib/data/dev/seed_service.dart`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/lib/data/dev/seed_service.dart).
- Incluye:
  - **3 Fincas:** *Hacienda El Rocío*, *Finca Santa María*, *Rancho Verde*.
  - **6 Mangas:** Ceba intensiva, cría, lechería especializada Pardo Suizo, etc.
  - **28 Animales reales:** Brahman, Nelore, Holstein, Angus, cruces Simbrah y Girolando, con genealogías entrelazadas y marcas de hierro.

---

## 7. Entorno de Desarrollo Local y Soluciones Clave

1. **Desacoplamiento de OneDrive (Solución al error de permisos):**
   - La carpeta de compilación `build` se redirigió fuera de OneDrive hacia `C:\Users\maiky\.bovino_build` mediante una unión de directorio NTFS (`mklink /J`). Esto previene de forma permanente el bloqueo de archivos por sincronización de OneDrive en Windows.
2. **Aislamiento de plataforma iOS en Windows (`ios_backup`):**
   - Se renombró la carpeta efímera `ios` a `ios_backup` para evitar que las herramientas de Flutter en Windows intenten regenerar archivos de Xcode/Cocoapods que generaban bloqueos de lectura.
3. **Depuración en VS Code ([`.vscode/launch.json`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/.vscode/launch.json)):**
   - Configurado para ejecutar directamente en **Chrome**, **Windows Desktop** o **Edge** al presionar `F5`.

---

## 8. Documentos Complementarios en la Raíz
- **[`DESGLOSE_DE_TAREAS_Y_COTIZACION.md`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/DESGLOSE_DE_TAREAS_Y_COTIZACION.md):** Desglose formal de 10 tareas técnicas con liquidación de $50 USD para entrega a clientes/supervisores.
- **[`ESTADO_DEL_PROYECTO_Y_ROADMAP.md`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/ESTADO_DEL_PROYECTO_Y_ROADMAP.md):** Clasificación de tareas por nivel de complejidad (Bajo, Medio, Alto) y especificación técnica de tareas pendientes.
- **[`task.md`](file:///c:/Users/maiky/OneDrive/Documentos/Producto%20minimo%20viable%20%20lecheria/task.md):** Bitácora técnica del proyecto con todas las subtareas marcadas como completadas `[x]`.

---

## 9. Próximos Pasos (Roadmap Prioritario)
1. **Módulo de Ciclo de Reproducción Bovina (Pestaña 3):**
   - Detección de celos y alertas de retorno a los 21 días (regla AM-PM).
   - Registro de servicios/inseminaciones (Monta Natural vs IATF con datos de pajuela).
   - Diagnóstico de gestación (palpación rectal y ecografía).
   - Cálculo automático de Fecha Probable de Parto (FPP ~280-285 días) y alerta de secado (220 días).
   - Registro de partos con alta automática del ternero vinculado a madre y padre.
   - Tablero de KPIs reproductivos (Días abiertos, Intervalo Entre Partos - IEP, % de preñez).
2. **Historial de Pesajes y Curvas de Ganancia Diaria de Peso (GDP).**
3. **Modo Offline de campo** con sincronización diferida hacia Supabase.
4. **Exportación de reportes y fichas técnicas** en PDF y Excel/CSV.

