# CLAUDE.md - Guía de Operación y Desarrollo Autónomo

Este archivo es la directiva maestra para Claude Code / Claude en este repositorio. Define los estándares de arquitectura, comandos de desarrollo y el **protocolo estricto guiado por `task.md`**.

---

## 1. Protocolo Obligatorio: Ejecución Guiada por `task.md`

Toda interacción de desarrollo o modificación del proyecto debe regirse obligatoriamente por el archivo `task.md`:

1. **Lectura inicial:** Antes de generar código, inspecciona siempre `task.md` en la raíz para identificar las tareas pendientes (`- [ ]`).
2. **Ejecución secuencial:** Trabaja una subtarea a la vez. No saltes tareas ni agrupes cambios no relacionados sin haber verificado la subtarea previa.
3. **Verificación técnica obligatoria:** Al finalizar cada subtarea, ejecuta los comandos de verificación:
   - `flutter analyze`: Debe arrojar **0 errores y 0 advertencias** (`No issues found!`).
   - `flutter test`: Todas las pruebas deben pasar (100%).
4. **Actualización de estado:** En cuanto la subtarea esté verificada y funcionando, actualiza su estado en `task.md` de `- [ ]` a `- [x]` de forma inmediata.
5. **No dar por terminada una fase** hasta que todas las casillas de esa sección estén marcadas con `[x]` y los tests pasen limpios.

---

## 2. Comandos de Desarrollo y Verificación

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Análisis estático (Regla de oro: 0 errores, 0 advertencias)
flutter analyze

# 3. Suite de pruebas unitarias y de integración
flutter test

# 4. Compilación Web para producción
flutter build web --release

# 5. Ejecución en navegador local
flutter run -d chrome
```

> **IMPORTANTE PARA WINDOWS / ONEDRIVE:**
> - El directorio `build/` está mapeado como unión NTFS a `C:\Users\maiky\.bovino_build` para evitar bloqueos de OneDrive. No borres ni recrees esa unión a menos que sea estrictamente necesario.
> - La carpeta iOS se encuentra aislada como `ios_backup/` para prevenir errores de herramientas de macOS en entornos Windows. No la renombres a `ios` en Windows.

---

## 3. Arquitectura del Código

El proyecto sigue una arquitectura limpia desacoplada por capas:

```
lib/
├── core/                   # Núcleo del sistema
│   ├── config/             # Configuración Supabase y variables de entorno
│   ├── constants/          # AppColors, RazasCatalog, enums zootécnicos
│   ├── services/           # AppFeedback (SnackBars globales desacopladas)
│   └── utils/              # Validadores de linaje, calculador de cruces, helpers
├── data/                   # Capa de datos y persistencia
│   ├── dev/                # SeedService (datos de prueba para demos)
│   ├── models/             # Modelos inmutables (Animal, Finca, Lote, Genealogia)
│   └── services/           # Clientes CRUD remotos (Fincas, Lotes, Animales, Storage)
├── ui/                     # Capa de presentación (Flutter)
│   ├── common/             # Widgets atómicos (TextFields, Dropdowns, AvatarPlaceholder)
│   ├── controllers/        # InventarioController (ChangeNotifier con recarga optimista)
│   └── screens/            # Pantallas principales
│       ├── creacion/       # Pestaña 1: Formularios de Expediente (Finca, Lote, Animal)
│       ├── inventario/     # Pestaña 2: Catálogo general (3 columnas: Sidebar, Dual View, Drawer)
│       └── reproduccion/   # Pestaña 3: Módulo de Ciclo de Reproducción Bovina
```

---

## 4. Reglas de Negocio Zootécnicas Inviolables

1. **Genealogía sin ciclos:** Ningún animal puede ser su propio padre o madre, ni un descendiente directo puede ser progenitor. Todo cambio genealógico debe validarse con `GenealogiaValidator`.
2. **Genética y cruces:** Toda composición de cruces se calcula en fracciones de sangre simplificadas con base 8 o porcentual mediante `BreedCrossCalculator` (ej. 1/2, 3/4, 5/8).
3. **Consistencia de predio:** Si un animal cambia de finca, su lote anterior se anula de inmediato. En bajas de inventario (*Vendido*, *Muerto*, etc.), se exige `fecha_salida` y se liberan `potrero_actual` y `lote_id`.
4. **Resiliencia UI:** Toda vista con fotos debe implementar `BovineAvatarPlaceholder` como fallback para evitar pantallas rotas por falta de internet o ausencia de imagen.

---

## 5. Skills Especializadas

En `.claude/skills/` se encuentran guías especializadas para las siguientes fases:
- **`reproduccion-bovina`:** Fisiología del ciclo estral, IATF, cálculo de fecha probable de parto (FPP), eventos de parto y alta automática de crías.
- **`flutter-agro-ux`:** Patrones de interfaz para condiciones de campo ganadero (alto contraste solar, target táctil amplio, scroll bidireccional).
- **`supabase-data-sync`:** Mantenimiento de esquemas SQL, disparadores de código automático, políticas RLS y buckets de Storage.
- **`task-manager`:** Guía detallada para el ciclo autónomo de lectura y actualización de `task.md`.
- **`offline-first-sync`:** Estrategias de persistencia local y sincronización diferida para zonas rurales sin cobertura.

