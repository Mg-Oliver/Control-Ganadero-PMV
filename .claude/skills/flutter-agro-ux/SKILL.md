---
name: flutter-agro-ux
description: Principios de diseño UI/UX especializados para software agropecuario y uso en campo
---

# Skill: UI/UX para Software Ganadero y Agropecuario

Esta skill establece las directrices de interfaz de usuario para que el software sea intuitivo, rápido y operable bajo condiciones reales de campo (luz solar directa, uso con guantes, pantallas táctiles de tablets y teléfonos móviles).

## 1. Ergonomía Visual y Contraste
- **Legibilidad bajo sol:** Utilizar contrastes altos entre texto y fondo. Los identificadores de los animales (arete de manejo, arete oficial) deben renderizarse con tipografía en negrita (`FontWeight.bold` o `FontWeight.w800`) y tamaño mínimo de 15px.
- **Semáforos de Estado Zootécnico:**
  - `Activo`: Verde esmeralda (`Colors.green.shade700` o badge con fondo suave verde).
  - `Vendido`: Gris neutro (`Colors.blueGrey`).
  - `Muerto`: Rojo ladrillo (`Colors.red.shade700`).
  - `Preñada`: Azul profundo (`Colors.indigo.shade700`).
  - `En Celo / Alerta`: Ámbar / naranja vibrante (`Colors.orange.shade800`).

## 2. Componentes de Entrada Optimizados para Campo
- **Touch Targets Amplios:** Ningún botón de acción principal o fila de selección debe tener una altura menor a 48px para facilitar el toque con dedos sucios o con guantes.
- **Teclados Numéricos Directos:** Todo campo de arete numérico, peso (kg) o superficie debe especificar `keyboardType: TextInputType.numberWithOptions(decimal: true)`.
- **Selección Rápida de Chips:** Preferir `ChoiceChip` o `SegmentedButton` en lugar de desplegables profundos cuando las opciones sean 4 o menos (ej. Sexo: [Macho] [Hembra], Propósito: [Ceba] [Cría] [Leche]).

## 3. Arquitectura de 3 Columnas y Drawer Lateral
- En pantallas de escritorio / tablet (ancho >= 1000px), mantener la estructura de 3 zonas:
  1. *Sidebar izquierdo:* Filtros dinámicos plegables en acordeón.
  2. *Área central:* Resumen en tarjetas compactas + Tabla completa inferior con scroll bidireccional.
  3. *Drawer derecho:* Expediente técnico sin pérdida de contexto (ficha biométrica, galería y árbol genealógico).
- En pantallas compactas (< 1000px), el Drawer debe abrirse como modal inferior o modal lateral deslizable completo.

