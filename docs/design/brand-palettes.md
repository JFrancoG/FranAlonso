# Identidad cromática

Estado: dirección principal elegida por Fran Alonso el 14 de julio de 2026.

## Uso del logotipo

El wordmark de Fran Alonso permanece monocromo:

- Negro sobre fondos claros.
- Blanco sobre fondos oscuros.
- El color de marca se reserva para acciones, navegación, selección y estados; no recolorea el logotipo.

Las plantillas documentales de 02.9 emplean una aproximación vectorial monocroma provisional. Si Fran Alonso facilita el wordmark original, se reemplazará sin cambiar los nombres semánticos de los recursos. Este documento conserva la decisión cromática y sus alternativas, pero no sustituye los assets definitivos de producción.

## Dirección seleccionada: Ciruela premium

Ciruela premium es la paleta de producción. Combina una ciruela cálida con un acento oro y mantiene una base neutra que no compite con el wordmark.

| Token | Light | Dark | Increased Contrast Light | Increased Contrast Dark |
|---|---:|---:|---:|---:|
| Canvas | `#F7F8FA` | `#1C1C1E` | `#FFFFFF` | `#000000` |
| Surface | `#E2E6EB` | `#2C2C2E` | `#E5E7EB` | `#1C1C1E` |
| Text Primary | `#1C1C1E` | `#FFFFFF` | `#000000` | `#FFFFFF` |
| Text Secondary | `#66666B` | `#9E9E9F` | `#333438` | `#D1D1D6` |
| Brand Primary | `#B65A9E` | `#E49ACE` | `#6B205D` | `#F4B2DF` |
| Brand Primary Ink | `#7B2F70` | `#E49ACE` | `#6B205D` | `#F4B2DF` |
| On Brand Primary | `#000000` | `#000000` | `#FFFFFF` | `#000000` |
| Brand Secondary | `#D6A84B` | `#F0C96A` | `#5B4000` | `#FFD980` |
| Brand Secondary Ink | `#765400` | `#F0C96A` | `#5B4000` | `#FFD980` |

## Estados semánticos

Cada estado usa color, icono y etiqueta. El significado nunca depende únicamente del tono.

| Modo | Éxito Fill / Ink / On | Aviso Fill / Ink / On | Error Fill / Ink / On |
|---|---|---|---|
| Light | `#34C759` / `#1C7135` / `#000000` | `#FF9500` / `#825500` / `#000000` | `#FF3B30` / `#B42318` / `#000000` |
| Dark | `#30D158` / `#30D158` / `#000000` | `#FF9F0A` / `#FF9F0A` / `#000000` | `#FF453A` / `#FF6B63` / `#000000` |
| Increased Contrast Light | `#075018` / `#075018` / `#FFFFFF` | `#5E3C00` / `#5E3C00` / `#FFFFFF` | `#8B1E1E` / `#8B1E1E` / `#FFFFFF` |
| Increased Contrast Dark | `#7EE787` / `#7EE787` / `#000000` | `#FFD37A` / `#FFD37A` / `#000000` | `#FF9B96` / `#FF9B96` / `#000000` |

## Alternativas conservadas

Estas direcciones quedan documentadas para una posible evolución futura. No se incluyen como tokens de producción mientras no se apruebe un cambio de identidad.

### Lavanda editorial

| Modo | Primary / Ink / On | Secondary / Ink |
|---|---|---|
| Light | `#A56EFF` / `#6F35CE` / `#1C1C1E` | `#4D9EEB` / `#1769AA` |
| Dark | `#A56EFF` / `#AD7CFF` / `#1C1C1E` | `#4D9EEB` / `#4D9EEB` |
| Increased Contrast Light | `#53209E` / `#53209E` / `#FFFFFF` | `#004A80` / `#004A80` |
| Increased Contrast Dark | `#D6C0FF` / `#D6C0FF` / `#000000` | `#8CC8FF` / `#8CC8FF` |

### Azul studio

| Modo | Primary / Ink / On | Secondary / Ink |
|---|---|---|
| Light | `#4D9EEB` / `#1769AA` / `#000000` | `#A56EFF` / `#6F35CE` |
| Dark | `#4D9EEB` / `#72B8FF` / `#000000` | `#A56EFF` / `#AD7CFF` |
| Increased Contrast Light | `#004A80` / `#004A80` / `#FFFFFF` | `#53209E` / `#53209E` |
| Increased Contrast Dark | `#8CC8FF` / `#8CC8FF` / `#000000` | `#D6C0FF` / `#D6C0FF` |

## Accesibilidad e implementación

- Texto normal: contraste mínimo `4.5:1`.
- Texto grande o en negrita y elementos no textuales: mínimo `3:1`.
- Increased Contrast usa un objetivo propio de `7:1` para texto normal.
- Las combinaciones definidas se validaron matemáticamente en los cuatro modos.
- En producción, los colores se implementarán como color sets con variantes de luminosidad y contraste dentro de `Assets.xcassets/Colors`.
- La API semántica, si los símbolos generados del catálogo no bastan, vivirá en `Shared/Presentation/DesignSystem/FranAlonsoPalette.swift`.

Referencias: [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color) y [Apple HIG — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
