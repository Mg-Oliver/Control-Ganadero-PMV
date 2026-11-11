---
name: task-manager
description: Protocolo estricto para la ejecución autónoma de tareas guiada por el archivo task.md
---

# Skill: Task Manager Autónomo (`task.md`)

Esta skill define el comportamiento obligatorio de Claude para gestionar y ejecutar tareas en el proyecto mediante `task.md`.

## Flujo de Trabajo Paso a Paso

```mermaid
flowchart TD
    A[Leer task.md] --> B[Identificar siguiente tarea pendiente [ ]]
    B --> C[Implementar cambios de código requeridos]
    C --> D[Ejecutar flutter analyze]
    D -->|Hay errores o warnings| E[Corregir código hasta 0 issues]
    E --> D
    D -->|0 errores y 0 warnings| F[Ejecutar flutter test]
    F -->|Falla algún test| G[Ajustar código o agregar caso de prueba]
    G --> F
    F -->|100% Tests pasados| H[Actualizar task.md: cambiar [ ] por [x]]
    H --> I{¿Hay más tareas pendientes en la fase?}
    I -->|Sí| B
    I -->|No| J[Reportar fase completada al usuario]
```

## Reglas Obligatorias
1. **Nunca marques `[x]` sin verificar:** Antes de cambiar cualquier checkbox a `[x]`, DEBES haber corrido `flutter analyze` (resultado: `No issues found!`) y `flutter test` (resultado: `All tests passed!`).
2. **Edición quirúrgica de `task.md`:** No borres descripciones ni subtareas existentes. Únicamente reemplaza el espacio `[ ]` por una `[x]` en la línea específica concluida.
3. **Reporte continuo:** Cada vez que se culmine una subtarea, notifica al usuario qué archivo se modificó, qué regla se aplicó y que la prueba técnica fue superada.
4. **Adición de nuevas fases:** Cuando el usuario solicite una nueva funcionalidad (ej. Fase 5: Reproducción), agrega el bloque estructurado al final de `task.md` con casillas `[ ]` antes de escribir la primera línea de código.
