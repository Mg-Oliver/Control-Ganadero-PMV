---
name: offline-first-sync
description: Arquitectura y patrones para recolección de datos en campo sin cobertura y sincronización diferida hacia Supabase
---

# Skill: Arquitectura Offline-First y Sincronización en Campo

Las fincas ganaderas frecuentemente se ubican en zonas rurales con señal de internet intermitente o nula. Esta skill define la estrategia para permitir captura local de datos sin conexión y sincronización automática.

## 1. Principio Fundamental
- **La UI nunca debe bloquearse esperando respuesta de red.**
- Las operaciones de creación (`INSERT`), actualización (`UPDATE`) y baja de animales deben guardarse primero localmente en un almacenamiento rápido de clave-valor o base de datos embebida (`hive` o `sqflite`).

## 2. Cola de Sincronización (Sync Queue)
Toda mutación de datos generada sin conexión se añade a una tabla de transacciones pendientes:
```json
{
  "id": "transaccion-uuid",
  "tabla": "animales",
  "operacion": "INSERT",
  "payload": { ... },
  "timestamp": "2026-11-11T13:00:00Z",
  "estado": "pendiente"
}
```

## 3. Estrategia de Resolución de Conflictos
1. **Last Write Wins (LWW) con timestamps UTC:** En caso de discrepancia entre una edición en campo y el servidor, prevalece la versión con `updated_at` más reciente.
2. **Identificadores UUID generados en el cliente:** Tanto los animales como los lotes y eventos deben nacer con un UUID v4 generado en Flutter, evitando colisiones de ID al sincronizar con Supabase.
3. **Indicador de Sincronización en la UI:** Mostrar un icono o badge sutil (nube verde sincronizada vs nube naranja con número de registros pendientes de subida) para dar certeza visual al operario.
