# ADR 0022 — Objetivo de accesibilidad nativa basado en WCAG 2.2 A/AA

## Estado

Aceptado

## Contexto

La fase 07 inicia las pantallas y el sistema visual. ADR 0011 exige revisión SwiftUI especializada y reconoce que los
previews no demuestran VoiceOver, foco ni rotor, pero no fija una matriz completa de criterios ni la evidencia mínima de
cierre. Posponer accesibilidad hasta el final produciría componentes incompatibles, remediaciones costosas y evidencia
inconsistente.

WCAG 2.2 es una norma web. Para software nativo se usa la orientación informativa de WCAG2ICT, junto con las convenciones
de interacción y tecnologías de asistencia de Apple. Esta decisión define un objetivo interno verificable: no constituye
certificación, declaración legal ni conformidad WCAG formal. Un requisito regulatorio o contractual futuro se evaluará
por separado contra la norma aplicable, como EN 301 549 cuando corresponda.

## Drivers

- Incorporar accesibilidad en cada componente y pantalla desde su primera implementación.
- Cubrir los criterios WCAG 2.2 de nivel A y AA que resulten aplicables a software nativo.
- Mantener una puerta auditable sin añadir XCUITest, UI tests nativos ni dependencias de terceros.
- Separar evidencia automatizable, inspección visual, revisión semántica y validación manual en runtime.
- Evitar cargar la matriz completa en todas las interacciones del agente.

## Opciones consideradas

1. Auditar toda la app al final de fase 07. Reduce trabajo inicial, pero permite que errores estructurales se propaguen.
2. Confiar solo en previews y lint. Es reproducible, pero no valida tecnologías de asistencia, foco ni operación real.
3. Implementar accesibilidad por construcción y exigir una auditoría independiente por pantalla. Añade una puerta de
   cierre, pero detecta fallos donde se originan y conserva evidencia localizada.

## Decisión

Se adopta la opción 3:

- El objetivo interno es satisfacer la correspondencia de todos los criterios WCAG 2.2 A/AA aplicables, interpretados
  para software no web mediante WCAG2ICT, más Apple Human Interface Guidelines y el comportamiento real de iOS 26.
- La matriz [`../accessibility/WCAG22_AA_IOS.md`](../accessibility/WCAG22_AA_IOS.md) clasifica cada criterio como
  aplicable, condicional o no aplicable y define evidencia mínima. Un `N/A` siempre incluye motivo.
- `$ios-accessibility-implementation` guía la construcción. `$franalonso-review-accessibility` realiza una auditoría
  independiente read-only y no sustituye la implementación.
- Cada pantalla se comprueba con Dynamic Type hasta AX 5, VoiceOver, Voice Control, Switch Control cuando el flujo lo
  requiera, Full Keyboard Access en superficies compatibles, orden y restauración de foco, anuncios y acciones.
- Se verifican Light/Dark con contraste normal e incrementado, diferenciación sin color, Increase Contrast, Reduce
  Motion, Reduce Transparency, Differentiate Without Color, orientación, iPad multitarea, tamaños de ventana y RTL.
- Como política propia, independiente de la unidad CSS de WCAG 2.5.8, el objetivo interactivo del proyecto es 44×44 pt.
  Las excepciones normativas y las excepciones de proyecto se documentan por separado. La medición usa la superficie
  realmente operable, su separación y el riesgo de activación accidental.
- Todo gesto multipunto, de trayectoria o arrastre dispone de alternativa de toque simple o controles equivalentes.
- Errores, cambios de estado y resultados importantes exponen semántica y anuncios sin depender únicamente de visión,
  color, sonido o tiempo.
- Xcode MCP aporta build, diagnósticos y previews soportados. Accessibility Inspector y las tecnologías de asistencia se
  registran como evidencia runtime/manual porque no están demostradas por una captura de preview.
- No se añaden XCTest, XCUITest, UI tests nativos ni librerías externas. La lógica accesible comprobable fuera de View usa
  Swift Testing.
- Tras la aceptación de este ADR, una pantalla no cumple Definition of Done mientras falte evidencia aplicable o exista
  un hallazgo abierto.

## Consecuencias

### Positivas

- Los componentes nacen con semántica, escalado, contraste, foco y alternativas de interacción coherentes.
- Cada fallo queda asociado a una pantalla y a un criterio verificable.
- La matriz detallada solo se carga al implementar o auditar UI, reduciendo contexto habitual.
- Se mantiene el modelo de testing del proyecto y se explicitan sus límites.

### Negativas y riesgos

- La validación manual consume tiempo y depende de registrar dispositivos, configuración y resultado.
- Algunos criterios son condicionales y deben reevaluarse cuando aparezcan audio, vídeo, timeouts o autenticación
  sensible.
- Cumplir una checklist no garantiza por sí solo una experiencia usable ni equivale a certificación externa.
- Las APIs y comportamientos de asistencia pueden cambiar; una duda exige documentación Apple actual y prueba real.

## Testing y validación

- Tests Swift Testing para nombres semánticos, reglas de estado, formatos, validación y lógica extraída cuando aplique.
- Render de variantes soportadas `Large`, `XXX Large` y `AX 5`, además de las cuatro apariencias de contraste/color.
- Accessibility Inspector sobre cada pantalla final y pasada manual con las tecnologías relevantes.
- Evidencia por pantalla con criterios, configuración, dispositivo/simulador, resultado, limitaciones y hallazgos.
- Auditoría independiente `$franalonso-review-accessibility` sin edición de archivos.

## Migración o reversibilidad

La regla se aplica a toda View nueva y a una View existente cuando se modifica. Una decisión futura puede ampliar la
automatización o adoptar tooling adicional mediante un nuevo ADR; no puede rebajar silenciosamente los criterios ya
aceptados.

## Relaciones

- Complementa ADR 0011; no altera la frontera `ModelContext` ni sustituye sus revisores.
- Concreta la puerta de accesibilidad de la fase 07 y de las pantallas posteriores.

## Referencias

- [Web Content Accessibility Guidelines 2.2](https://www.w3.org/TR/WCAG22/)
- [Guidance on Applying WCAG 2 to Non-Web Information and Communications Technologies](https://www.w3.org/TR/wcag2ict-22/)
- [Apple Human Interface Guidelines — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple Human Interface Guidelines — VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)
- [Apple Human Interface Guidelines — Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
