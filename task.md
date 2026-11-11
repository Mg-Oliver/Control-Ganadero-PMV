# Seguimiento de Tareas - MVP Control Ganadero

## Fase 1: Entorno, Arquitectura Flutter, Supabase y Modelos Base
- [x] 1.1 Creación del proyecto Flutter y dependencias en `pubspec.yaml`
- [x] 1.2 Configuración del árbol de carpetas limpio (Clean Architecture / Feature-First)
- [x] 1.3 Creación del script SQL de migración en Supabase (`supabase/migrations/001_initial_schema.sql`)
- [x] 1.4 Configuración de cliente Supabase y variables de entorno (`.env`)
- [x] 1.5 Implementación de constantes zootécnicas y catálogo de razas (`razas_catalog.dart`)
- [x] 1.6 Implementación de modelos de dominio Dart con serialización JSON (`Finca`, `Lote`, `Animal`, `Genealogia`)
- [x] 1.7 Servicio base de subida de imágenes a Supabase Storage (límite 3 fotos)
- [x] 1.8 Verificación de compilación (`flutter analyze`)

## Fase 2: Pantalla 1 - Módulo de Creación y Formularios Reactivos
- [x] 2.1 Componentes UI comunes (Selector de fotos máx. 3, Dropdown genérico, Input numérico/texto)
- [x] 2.2 Pantalla contenedora de Creación con botones de acceso rápido (`[+ Finca]`, `[+ Lote]`, `[+ Animal]`)
- [x] 2.3 Formulario reactivo y servicio de Fincas (con validaciones y subida de hasta 3 fotos a Storage)
- [x] 2.4 Formulario reactivo de Lotes (con selector forzoso de Finca asociada y persistencia)
- [x] 2.5 Formulario de Animales: Selector zootécnico de Raza (Pura vs Cruces Modo A con fracciones)
- [x] 2.6 Formulario de Animales: Cascada de selección Finca -> Lotes y origen condicional ('Otro')
- [x] 2.7 Formulario de Animales: Selector y buscador de Genealogía (interno en finca o referencia externa)
- [x] 2.8 Integración de subida de fotos del animal a bucket `animales_fotos` y guardado íntegro en Supabase
- [x] 2.9 Verificación con `flutter analyze` (cero errores y warnings)

### Notas técnicas de Fase 2
- **Preservación de contexto entre formularios**: `CreacionScreen` usa `IndexedStack` y modo de retorno asistido cuando el ganadero pulsa `[+ Nueva]` finca o `[+ Nuevo Lote]` desde el expediente animal, preseleccionando automáticamente la entidad recién creada al volver.
- **Trazabilidad Zootécnica Modo A**: `BreedCrossBuilder` soporta búsqueda filtrada por aptitud sobre `RazasCatalog`, constructor dinámico de fracciones en octavos y generación automática de etiquetas F1/sintéticas (`Simbrah F1`, `Girolando F1/5-8/3-4`, `Brangus F1`, etc.).
- **Carga atómica de fotos**: `StorageService.uploadMultiplePhotos` sube hasta 3 imágenes con reporte de progreso porcentual bajo el UUID v4 pregenerado antes de insertar en PostgreSQL (`fincas_fotos` y `animales_fotos`).

## Fase 3: Pantalla 2 - Módulo de Inventario, Filtros Avanzados y Drawer Lateral
- [x] 3.1 Modelo de estado y filtros para inventario (`InventarioState` / Controller para Fincas, Lotes, Animales)
- [x] 3.2 Sidebar lateral izquierdo: Navegación por secciones y acordeón de filtros dinámicos según entidad
- [x] 3.3 Tarjetas de resumen rápido (KPIs visuales, miniaturas de fotos, badges de estado y raza)
- [x] 3.4 Tabla de datos exhaustiva inferior con scroll bidireccional, ordenamiento por columnas y paginación
- [x] 3.5 Drawer lateral derecho: Despliegue del expediente completo (galería de fotos ampliable, genealogía interactiva y marcas de hierro)
- [x] 3.6 Métodos de consulta avanzada y filtros en `fincas_service.dart`, `lotes_service.dart` y `animales_service.dart`
- [x] 3.7 Integración completa en `InventarioScreen` con sincronización en tiempo real (Supabase Streams o recarga optimista)
- [x] 3.8 Verificación limpia con `flutter analyze` (0 errores, 0 advertencias) y pruebas de UI

### Notas técnicas de Fase 3
- **Arquitectura responsiva de 3 columnas**: `InventarioScreen` despliega en escritorio (`>= 1020px`) el `InventarioSidebar` fijo a la izquierda, el área central (buscador global, KPIs contextuales, grid de tarjetas y `EntityDataTable` bidireccional con ordenamiento y paginación) y el `ExpedienteDrawer` ocupando `1/3` del ancho a la derecha; en pantallas compactas (`< 1020px`) adapta los filtros a `Drawer` izquierdo y el expediente a hoja modal lateral derecha.
- **Consultas relacionales PostgREST sin ambigüedad**: `AnimalesService.consultarInventarioRelacional` explicita la clave foránea `genealogia!genealogia_animal_id_fkey(*)` junto con `fincas(nombre, identificador)` y `lotes(nombre, identificador)`, incluyendo un respaldo automático para prevenir errores `PGRST201` por múltiples referencias hacia `animales`.
- **Sincronización híbrida (Realtime + Optimista)**: `InventarioController` escucha streams de Supabase (`fincas`, `lotes`, `animales`) con `debounce` de `450ms` y recibe inserciones optimistas inmediatas desde `CreacionScreen` a través de `MainWorkspaceShell`.
- **Árbol genealógico interactivo**: `AnimalExpedienteView` enlaza progenitores internos directamente con su propio expediente manteniendo pila de historial (`navegarAProgenitor` / `regresarAnimalAnteriorEnDrawer`) y visor fotográfico con zoom (`InteractiveViewer`).

## Fase 4: Blindaje de Negocio, Casos Límite, Seed Data y Tests
- [x] 4.1 Reglas de Negocio Zootécnicas y Validación de Ciclos Genealógicos
  - [x] 4.1.1 Validador de ciclos genealógicos (`GenealogiaValidator`) y exclusión de descendientes en selectores
  - [x] 4.1.2 Consistencia en asignación y transferencias de predio (desasociación inmediata de lote huérfano)
  - [x] 4.1.3 Flujo de baja / salida de animales (`fecha_salida` obligatoria, `precio_venta`, inhabilitación de lote/potrero)
- [x] 4.2 Resiliencia de Red, Manejo de Fallos y Placeholders
  - [x] 4.2.1 Lógica de reintentos y timeouts en `StorageService`
  - [x] 4.2.2 Componente visual `BovineAvatarPlaceholder` para fallos de red y entidades sin fotos
  - [x] 4.2.3 Servicio desacoplado de notificaciones globales `AppFeedback`
- [x] 4.3 Generador de Datos Semilla Realistas (Seed Data)
  - [x] 4.3.1 Script SQL de seed íntegro (`supabase/seed.sql`) con 3 fincas, 6 lotes y 28 animales
  - [x] 4.3.2 Servicio Dart de seed data (`lib/data/dev/seed_service.dart`) y botón de repoblación con un clic
- [x] 4.4 Pruebas Unitarias y de Integración Automatizadas
  - [x] 4.4.1 Tests unitarios: `genealogia_validator_test.dart`, `breed_cross_builder_test.dart`, `transferencia_finca_test.dart`
  - [x] 4.4.2 Tests de widgets e integración: baja de animales y navegación por expediente en drawer
  - [x] 4.4.3 Verificación de suite completa con `flutter analyze` y `flutter test` (0 errores, 0 warnings)

### Notas técnicas de Fase 4
- **Detección y corte de ciclos en genealogía**: `GenealogiaValidator` recorre en árbol recursivo todos los descendientes y ancestros, impidiendo la asignación del propio animal o de sus descendientes conocidos como progenitores, tanto en validación previa como mediante filtrado reactivo en los selectores de `AnimalForm`.
- **Consistencia predial y bajas**: `PredioConsistencyHelper` anula automáticamente cualquier lote huérfano cuando un animal cambia de predio. Al pasar a estados de salida (`Vendido`, `Muerto`, `Robado`, `Descartado`), se liberan forzosamente el lote y el potrero físico, y se exige `fecha_salida` y `precio_venta` sin alterar el esquema SQL existente.
- **Resiliencia de Storage y Placeholders adaptativos**: `StorageService` implementa reintentos con timeout de 15s por intento. `BovineAvatarPlaceholder` se adapta responsivamente: como avatar compacto (72x72) con monograma y anillo de color según sexo/aptitud, o como banner estilizado con textura vectorial en el expediente.
- **Notificaciones globales desacopladas**: `AppFeedback` provee SnackBars flotantes y no bloqueantes para éxito, advertencias zootécnicas y errores de red conectadas a `MaterialApp.scaffoldMessengerKey`.
- **Seed Data integral**: `SeedService` y `supabase/seed.sql` proveen 3 fincas zootécnicas, 6 lotes especializados y 28 animales representativos (razas puras, cruces Modo A, reproductores élite y casos de baja), activables con un clic desde el AppBar de desarrollo.
- **Unificación de estructura**: El proyecto Flutter ahora reside directamente en la raíz del espacio de trabajo, permitiendo ejecutar `flutter run -d chrome` de forma directa e inmediata.

---

## Fase 5: Transformación del Shell de Navegación a Menú Lateral (Drawer)
- [ ] 5.1 Rediseño del `AppBar` superior: eliminación definitiva del `TabBar` fijo, adición de icono de menú hamburguesa a la izquierda para despliegue del drawer, título dinámico según sección activa y acciones contextuales (botón de datos semilla demo).
- [ ] 5.2 Estructura y diseño del `AppDrawer` / `NavigationDrawer` lateral:
  - [ ] 5.2.1 Header visual estilizado del drawer (logo/icono agropecuario, título "Control Ganadero Bovino" y versión/subtítulo).
  - [ ] 5.2.2 Opción 1: "Panel de control" (pantalla de inicio por defecto con métricas/KPIs o vista principal de resumen).
  - [ ] 5.2.3 Opción 2: "Inventario" (pantalla de catálogo con sidebar de filtros dinámicos, tarjetas y tabla exhaustiva).
  - [ ] 5.2.4 Opción 3: "Ciclo reproductivo" (vista placeholder informativa / en construcción para el módulo de reproducción).
  - [ ] 5.2.5 Separador visual (`Divider`) y opción al fondo: "Configuración" (pantalla placeholder de ajustes de sistema / conexión Supabase).
- [ ] 5.3 Gestión de navegación y preservación de estado:
  - [ ] 5.3.1 Implementar controlador o estado local en `MainWorkspaceShell` que gobierne el índice de la sección activa.
  - [ ] 5.3.2 Uso de `IndexedStack` (o enrutamiento equivalente) para conmutar entre las vistas principales sin destruir ni recrear el estado de las pantallas al alternar en el menú.
  - [ ] 5.3.3 Cierre automático asistido del Drawer al seleccionar cualquier opción de navegación.
- [ ] 5.4 Creación de vistas asociadas:
  - [ ] 5.4.1 Pantalla inicial "Panel de Control" (`DashboardScreen` con KPIs de resumen y accesos rápidos).
  - [ ] 5.4.2 Pantalla "Configuración" (`ConfiguracionScreen` con estado de conexión a Supabase y opciones generales).
- [ ] 5.5 Integración, resiliencia y verificación de calidad:
  - [ ] 5.5.1 Actualización de pruebas existentes en `test/widget_test.dart` y tests de integración para validar la navegación mediante el Drawer y los nuevos títulos.
  - [ ] 5.5.2 Verificación estricta con `flutter analyze` asegurando **0 errores y 0 advertencias**.
  - [ ] 5.5.3 Verificación de suite de pruebas con `flutter test` (100% aprobadas).


