# Estado del Proyecto: Tareas Realizadas y Roadmap Futuro
## Sistema de Control y Monitoreo Ganadero Bovino (Flutter & Supabase)

Este documento detalla el desglose técnico de todas las tareas ejecutadas en el desarrollo del sistema clasificadas por **Nivel de Complejidad (Bajo, Medio y Alto)**, así como las **Tareas Pendientes**, con especial enfoque en el **Módulo del Ciclo de Reproducción Bovina**.

---

## PARTE 1: Tareas Realizadas (Completadas al 100%)

### 🟢 Nivel Bajo (Configuración, UI Base y Componentes Reutilizables)
Tareas orientadas a la parametrización del entorno, diseño de constantes temáticas y componentes visuales estándar:

1. **Estructuración y Tematizado Global:**
   - Definición de paleta de colores corporativos agropecuarios (`AppColors.primary`, `secondary`, `background`, `surface`) en `lib/core/constants/app_colors.dart`.
   - Configuración de tema Material Design 3 con soporte responsive en `main.dart`.
2. **Catálogos Estáticos y Enumeraciones Zootécnicas:**
   - Creación de catálogos de razas puras bovinas con aptitud zootécnica (Carne, Leche, Doble Propósito) en `lib/core/constants/razas_catalog.dart`.
   - Definición de enums para tipos de explotación, fuentes hídricas, propósitos de lote y estados del animal.
3. **Componentes Atómicos de Formulario:**
   - Implementación de campos de texto reutilizables con bordes redondeados y estilo unificado (`CustomTextField`).
   - Desarrollo de selectores desplegables estándar con validación visual (`CustomDropdown` y `CustomFormDropdown`).
4. **Formateadores de Entrada de Datos:**
   - Máscaras y helpers para números con decimales (superficie en hectáreas, peso en kilogramos, precios de compra/venta) en `lib/core/utils/formatters.dart`.
5. **Aislamiento de Configuración de Entorno:**
   - Integración de `flutter_dotenv` y creación de plantillas seguras `.env` y `.env.example` para credenciales de API.
6. **Estructura de Navegación por Pestañas:**
   - Barra superior con `TabBar` sincronizada para alternar entre **Expediente**, **Catálogo** y **Ciclo de Reproducción**.

---

### 🟡 Nivel Medio (Formularios Reactivos, Integración Supabase y Componentes de Resumen)
Tareas que involucran manejo de estado local, consumo de APIs remotas, validaciones complejas de entrada y renderizado de datos:

1. **Integración del Cliente Supabase y Servicios CRUD:**
   - Implementación de la capa de acceso a datos para Fincas (`fincas_service.dart`), Lotes (`lotes_service.dart`) y Animales (`animales_service.dart`).
   - Manejo de consultas parametrizadas, ordenamientos y relaciones foráneas.
2. **Formulario de Registro de Fincas:**
   - Captura de identificador único, nombre, ubicación geográfica y hectáreas totales.
   - Selector multiselección con chips de fuentes de agua (Quebrada, Pozo, Río, Acueducto rural).
3. **Formulario de Manejo de Lotes:**
   - Registro dependiente de la finca madre con validación de identificador único por predio.
   - Configuración de propósitos productivos (Ceba, Cría, Lechería), dietas asignadas y meta de ganancia diaria de peso.
4. **Formulario Zootécnico Integral de Animales:**
   - Doble aretado (número de manejo y arete oficial de trazabilidad nacional).
   - Selector de sexo, edad calculada según fecha de nacimiento exacta o estimada.
   - Estructuración JSONB de marcas de hierro (ubicación en el cuerpo, marcas y cortes de oreja).
5. **Servicio de Carga de Fotografías y Almacenamiento:**
   - Integración de `image_picker` para captura desde cámara o galería (`ImagePickerStrip`, `PhotoUploaderWidget`).
   - Conexión con los buckets de almacenamiento de Supabase (`fincas_fotos`, `animales_fotos`) con lógica de reintentos (`StorageService`).
6. **Grid Superior de Tarjetas de Resumen Rápido:**
   - Tarjetas compactas (`AnimalCard`, `FincaCard`, `LoteCard`) con visualización de peso, código único, tags de raza/cruce y semáforos de estado.
7. **Tabla de Datos Exhaustiva Inferior:**
   - Renderizado con scroll bidireccional (horizontal y vertical) para visualización en pantallas compactas y de escritorio.
   - Ordenamiento por columnas alfabéticas, numéricas y cronológicas.
8. **Generador y Cargador de Datos Semilla (*Seed Data*):**
   - Script SQL (`supabase/seed.sql`) y servicio interno (`SeedService`) para poblar la base de datos con 3 fincas, 6 lotes y 28 animales reales con un solo clic.

---

### 🔴 Nivel Alto (Algoritmos Zootécnicos, Arquitectura de Linaje, UI Dual y Pruebas Automatizadas)
Tareas de alta ingeniería de software que exigen algoritmos especializados, prevención de inconsistencias biológicas, sincronización reactiva y suites de pruebas:

1. **Esquema Relacional Avanzado en PostgreSQL / Supabase:**
   - Diseño del modelo de datos con integridad referencial en cascada, enums nativos, tablas pivote y disparador PL/pgSQL (`trg_generar_codigo_animal`) para la asignación secuencial automática de códigos de animal (`GAN-000001`).
   - Configuración de políticas de seguridad por fila (Row Level Security - RLS).
2. **Detector de Ciclos y Referencias Circulares en Linaje (`GenealogiaValidator`):**
   - Algoritmo de validación recursiva que impide que un animal sea su propio progenitor o que un descendiente directo sea asignado como padre o madre.
   - Filtrado dinámico de candidatos para excluir al propio individuo y toda su descendencia de los selectores genealógicos.
3. **Calculador Zootécnico de Cruces y Octavos de Sangre (`BreedCrossCalculator`):**
   - Motor para descomposición de composiciones genéticas complejas (ej. Cruces 1/2, 3/4, 5/8).
   - Algoritmo de simplificación de fracciones matemáticas (ej. reducir 2/4 a 1/2, 4/8 a 1/2) y generación de etiquetas zootécnicas estandarizadas (ej. *F1 Simbrah 1/2*).
4. **Helper de Consistencia Territorial y Salida de Animales (`PredioConsistencyHelper`):**
   - Detección y corrección de lotes huérfanos al transferir un animal de finca.
   - Reglas de negocio para estados de salida (*Vendido*, *Muerto*, *Robado*, *Descartado*): liberación obligatoria de potreros/lotes y exigencia de fecha y precio de salida.
5. **Arquitectura Central de Catálogo (Workspace Dual de 3 Columnas):**
   - Coordinación reactiva entre el Sidebar izquierdo (filtros), el Área Central (tarjetas + tabla) y el Drawer derecho (expediente).
   - Controlador de estado unificado (`InventarioController`) con recarga optimista sin recargar toda la pantalla.
6. **Drawer Lateral Interactivo con Navegación Genealógica:**
   - Expediente lateral con visualización de árbol genealógico familiar navegable (padre, madre, abuelos paternos y maternos).
   - Pila de navegación interna con botón de retroceso histórico para explorar ancestros sin perder el registro original.
7. **Componente de Resiliencia UI (`BovineAvatarPlaceholder`):**
   - Renderizado vectorial adaptativo que genera monogramas inteligentes y fondos cromáticos según el sexo y raza del animal en caso de fallos de red o ausencia de imagen.
8. **Suite Completa de Pruebas Automatizadas y QA:**
   - 18 pruebas unitarias y de integración pasando al 100% (`test/unit/` y `test/integration/`).
   - Verificación con `flutter analyze` reportando **0 errores y 0 advertencias**.

---

## PARTE 2: Tareas Pendientes y Roadmap Futuro

### 🔴 Módulo Central Pendiente: Ciclo de Reproducción Bovina
El módulo de reproducción es la pieza clave para la gestión biológica y productiva de hembras en edad reproductiva. Actualmente cuenta con la pestaña reservada y requiere la implementación de las siguientes subtareas:

#### 1. Detección y Registro de Celos (Estros)
- [ ] **Formulario de Registro de Celo:**
  - Selección de la hembra (filtrada exclusivamente: hembras activas mayores a edad mínima de pubertad/servicio).
  - Fecha y hora exacta de detección.
  - Signos clínicos observados: monta pasiva, flujo vaginal transparente, inquietud, vulva inflamada, caída en producción de leche.
  - Turno de detección (AM / PM) para aplicar la regla universal AM-PM de inseminación.
- [ ] **Alerta de Repetición de Celo:**
  - Notificación automática a los 18-24 días posteriores (promedio 21 días) para vigilar posible retorno al celo de vacas servidas.

#### 2. Servicios e Inseminación (Monta Natural vs IATF)
- [ ] **Registro de Servicio / Monta:**
  - Modalidad: Inseminación Artificial a Tiempo Fijo (IATF), Inseminación Convencional o Monta Natural en Potrero.
  - Asignación de progenitor: selección de toro activo de la finca o referencia externa de pajuela (toro de catálogo, número de pajuela, casa genética).
  - Registro del inseminador / técnico responsable y lote de semen utilizado.
  - Protocolo hormonal aplicado (si aplica IATF: progestágenos, GnRH, prostaglandinas).

#### 3. Diagnóstico de Gestación (Palpaciones y Ecografías)
- [ ] **Registro de Chequeo Ginecológico:**
  - Método: Palpación rectal (a partir de 45-60 días post-servicio) o Ecografía / Ultrasonido (a partir de 28-35 días).
  - Resultado: *Preñada (Gestante)*, *Vacía*, o *Dudosa / Repetir chequeo*.
  - Cálculo automático de días de gestación confirmados.
  - Marcado de condición ovárica/uterina en hembras vacías (quistes, cuerpo lúteo, endometritis).

#### 4. Monitoreo de Gestación, Alertas de Secado y Parto
- [ ] **Calculador de Fecha Probable de Parto (FPP):**
  - Cálculo automático de la fecha estimada de parto basado en la curva de gestación bovina (280 a 285 días según raza Bos taurus o Bos indicus).
- [ ] **Alerta de Período de Secado:**
  - En vacas lecheras, recordatorio programado a los 220 días de gestación (~60 días antes del parto) para suspender el ordeño y aplicar tratamiento de vaca seca.

#### 5. Registro de Partos y Alta Automática de Crías
- [ ] **Formulario de Evento de Parto:**
  - Fecha del parto y tipo de evento (Normal/Eutócico, Asistido, Cesárea, Distócico o Aborto).
  - Condición de la madre post-parto (retención de placenta, mastitis, prolapso).
- [ ] **Vigencia y Alta Automática del Neonato:**
  - Número de crías (simple o mellizos).
  - Si la cría nace viva, activar flujo inmediato para registrar automáticamente el nuevo ternero en la tabla `animales` con:
    - Madre asignada automáticamente (`madre_id`).
    - Padre asignado del servicio previo (`padre_id` o `padre_externo_referencia`).
    - Finca heredada de la madre.
    - Peso al nacer y sexo del ternero.
- [ ] **Registro de Abortos:**
  - Registro de causas sospechosas (brucelosis, diarrea viral bovina, trauma) y reinicio del estatus reproductivo a hembra vacía.

#### 6. Tablero de Indicadores y KPIs Reproductivos
- [ ] **Dashboard de Métricas Clave:**
  - **Días Abiertos:** promedio de días transcurridos entre el parto y la siguiente concepción confirmada.
  - **Intervalo Entre Partos (IEP):** proyección y cálculo en meses del lapso entre partos sucesivos.
  - **Servicios por Concepción (S/C):** número promedio de inseminaciones requeridas para lograr una preñez.
  - **Tasa de Preñez y Natalidad del Hato (%):** porcentaje global de vacas gestantes sobre el total de vientres aptos.

---

### 🟡 Otras Tareas Pendientes Generales del Sistema

#### 1. Módulo de Pesajes y Curvas de Ganancia Diaria de Peso (GDP)
- [ ] Historial cronológico de pesajes por animal con gráfico interactivo de tendencia.
- [ ] Cálculo automático de la Ganancia Diaria de Peso real (kg/día) vs la meta fijada en el lote asignado.

#### 2. Soporte Offline / Modo Campo
- [ ] Almacenamiento local mediante SQLite (`sqflite`) o `hive` para registrar eventos en corrales o potreros sin conexión a internet.
- [ ] Cola de sincronización bidireccional automática al recuperar la conectividad con Supabase.

#### 3. Reportes y Exportación de Documentos
- [ ] Exportación de fichas individuales de animales en formato PDF con fotografía, genealogía y código QR / código de barras.
- [ ] Exportación del inventario completo y catálogo en formato Excel / CSV para auditorías gubernamentales o asociaciones ganaderas.

#### 4. Gestión de Sanidad y Calendario de Vacunación
- [ ] Registro de planes vacunales (Fiebre Aftosa, Brucelosis, Carbunco, Rabia) y desparasitaciones.
- [ ] Alertas de vencimiento de medicamentos y períodos de retiro en leche y carne.

