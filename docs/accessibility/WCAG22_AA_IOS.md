# WCAG 2.2 A/AA para iOS nativo

Esta matriz aplica WCAG 2.2 a software nativo siguiendo WCAG2ICT. No convierte puntos CSS en puntos iOS de forma
mecánica ni acredita certificación. Para cada pantalla afectada se copia la plantilla final, se decide aplicabilidad y se
adjunta evidencia. `N/A` sin motivo no es válido.

## Criterios perceptibles

| Criterio | Aplicación iOS | Evidencia mínima |
|---|---|---|
| 1.1.1 Contenido no textual (A) | Imágenes, iconos y controles informativos tienen nombre/alternativa; decoración se oculta. | Árbol accesible, VoiceOver. |
| 1.2.1 Solo audio/vídeo pregrabado (A) | Condicional; proporcionar alternativa equivalente según el tipo de medio. | Medio y alternativa, o `N/A` motivado. |
| 1.2.2 Subtítulos pregrabados (A) | Condicional a audio sincronizado pregrabado. | Subtítulos revisados, o `N/A` motivado. |
| 1.2.3 Audiodescripción o alternativa (A) | Condicional a vídeo pregrabado. | Audiodescripción/alternativa, o `N/A` motivado. |
| 1.2.4 Subtítulos en directo (AA) | Condicional a contenido sincronizado en directo. | Subtítulos en directo, o `N/A` motivado. |
| 1.2.5 Audiodescripción pregrabada (AA) | Condicional a vídeo pregrabado. | Audiodescripción sincronizada, o `N/A` motivado. |
| 1.3.1 Información y relaciones (A) | Jerarquía, grupos, encabezados, listas, tablas, labels y valores son programáticos. | Inspector y navegación VoiceOver. |
| 1.3.2 Secuencia significativa (A) | Orden accesible conserva significado y flujo visual. | Recorrido lineal y foco. |
| 1.3.3 Características sensoriales (A) | Instrucciones no dependen solo de posición, forma, color o sonido. | Revisión de copy y flujo. |
| 1.3.4 Orientación (AA) | No bloquear orientación salvo necesidad esencial documentada. | Portrait, landscape y multitarea. |
| 1.3.5 Propósito de entrada (AA) | Campos personales exponen propósito/autofill compatible cuando aplica. | Content type y entrada real. |
| 1.4.1 Uso del color (A) | Color nunca es la única señal de estado, error, selección o acción. | Differentiate Without Color y revisión visual. |
| 1.4.2 Control de audio (A) | Audio automático superior a tres segundos se pausa, detiene o controla de forma independiente. | Flujo runtime o `N/A`. |
| 1.4.3 Contraste mínimo (AA) | Texto y texto en imágenes alcanzan 4.5:1; texto grande, 3:1, salvo excepciones normativas. | Medición por apariencia. |
| 1.4.4 Redimensionar texto (AA) | Contenido usable hasta AX 5/200% sin pérdida de información o función. | Previews y runtime AX 5. |
| 1.4.5 Imágenes de texto (AA) | Usar texto real salvo que la presentación sea esencial. | Inspección de assets. |
| 1.4.10 Reflow (AA) | Sin scroll bidimensional innecesario; contenido se adapta a ventana y multitarea. | iPhone, iPad y ventanas estrechas. |
| 1.4.11 Contraste no textual (AA) | Controles, estados y gráficos esenciales alcanzan 3:1 frente a colores adyacentes. | Medición en cuatro apariencias. |
| 1.4.12 Espaciado de texto (AA) | Condicional: solo aplica a UI implementada mediante markup que permita al usuario modificar esas propiedades; `N/A` motivado para SwiftUI nativo. | Inspección de tecnología y mecanismo de override; si aplica, contenido exigente. |
| 1.4.13 Contenido al hover/foco (AA) | Popovers o ayudas adicionales son descartables, alcanzables y persistentes cuando aplican. | Puntero, teclado y foco. |

## Criterios operables

| Criterio | Aplicación iOS | Evidencia mínima |
|---|---|---|
| 2.1.1 Teclado (A) | Toda función compatible se opera con Full Keyboard Access sin requerir toque. | Recorrido por teclado. |
| 2.1.2 Sin trampa de teclado (A) | El foco puede entrar, operar y salir de cada superficie. | Teclado y Switch Control. |
| 2.1.4 Atajos de caracteres (A) | Atajos de una tecla pueden desactivarse, reasignarse o limitarse al foco. | Configuración o `N/A`. |
| 2.2.1 Tiempo ajustable (A) | Límites de tiempo se eliminan, ajustan o extienden salvo excepción esencial. | Flujo temporizado o `N/A`. |
| 2.2.2 Pausar, detener, ocultar (A) | Movimiento o actualización automática dispone de control. | Reduce Motion y controles. |
| 2.3.1 Tres destellos o menos (A) | Ningún contenido supera el umbral de destellos. | Revisión de animaciones/medios. |
| 2.4.1 Evitar bloques (A) | Navegación repetida ofrece acceso eficiente al contenido principal mediante estructura y foco. | Rotor, encabezados y foco inicial. |
| 2.4.2 Título (A) | Pantalla y destino comunican un título descriptivo. | Navigation title y anuncio. |
| 2.4.3 Orden del foco (A) | El foco sigue una secuencia comprensible. | VoiceOver, teclado y Switch Control. |
| 2.4.4 Propósito del enlace (A) | Acciones y enlaces son comprensibles por su nombre y contexto programático. | Lista de acciones accesibles. |
| 2.4.5 Múltiples vías (AA) | Condicional a colecciones extensas; ofrecer navegación, búsqueda o jerarquía equivalente. | Mapa de navegación o `N/A`. |
| 2.4.6 Encabezados y etiquetas (AA) | Encabezados y labels describen tema o propósito. | Rotor y árbol accesible. |
| 2.4.7 Foco visible (AA) | El foco de teclado/puntero es visible y no queda oculto. | Full Keyboard Access. |
| 2.4.11 Foco no oculto mínimo (AA) | Un elemento enfocado no queda totalmente oculto por contenido propio. | Teclado con sheets, barras y scroll. |
| 2.5.1 Gestos de puntero (A) | Gestos multipunto o de trayectoria tienen alternativa simple. | Touch, Voice Control y acciones. |
| 2.5.2 Cancelación del puntero (A) | La acción no se confirma al down-event sin cancelación/undo equivalente. | Interacción real. |
| 2.5.3 Etiqueta en el nombre (A) | El nombre accesible contiene el texto visible relevante. | Voice Control por nombre. |
| 2.5.4 Activación por movimiento (A) | Agitar/mover tiene alternativa UI y puede desactivarse. | Ajustes y flujo o `N/A`. |
| 2.5.7 Movimiento de arrastre (AA) | Arrastrar tiene controles o gesto simple equivalente. | Touch, VoiceOver y Switch Control. |
| 2.5.8 Tamaño de objetivo mínimo (AA) | Evaluar sus 24 CSS px y excepciones mediante WCAG2ICT; aplicar además la política independiente de 44×44 pt. | Superficie operable, separación, activación y excepciones separadas. |

## Criterios comprensibles

| Criterio | Aplicación iOS | Evidencia mínima |
|---|---|---|
| 3.1.1 Idioma de la página (A) | La app y el contenido exponen el idioma correcto a las tecnologías de asistencia. | Localización y pronunciación VoiceOver. |
| 3.1.2 Idioma de las partes (AA) | Cambios de idioma en contenido se identifican cuando son programáticamente expresables. | Pronunciación o `N/A`. |
| 3.2.1 Al recibir foco (A) | Enfocar no provoca cambios inesperados de contexto. | Teclado y VoiceOver. |
| 3.2.2 Al introducir datos (A) | Cambiar un valor no navega o confirma inesperadamente sin aviso. | Formularios y controles. |
| 3.2.3 Navegación consistente (AA) | Patrones repetidos conservan orden y ubicación relativos. | Comparación entre pantallas. |
| 3.2.4 Identificación consistente (AA) | Componentes con igual función mantienen nombre, icono y comportamiento. | Catálogo y árbol accesible. |
| 3.2.6 Ayuda consistente (A) | Mecanismos de ayuda repetidos mantienen posición/orden relativo. | Navegación o `N/A`. |
| 3.3.1 Identificación de errores (A) | Error identificado en texto y asociado programáticamente al campo/acción. | Estado, foco y anuncio. |
| 3.3.2 Etiquetas o instrucciones (A) | Entradas tienen label persistente e instrucciones necesarias. | Formulario y VoiceOver. |
| 3.3.3 Sugerencia ante errores (AA) | Ofrecer corrección conocida sin comprometer seguridad o propósito. | Casos de validación. |
| 3.3.4 Prevención de errores (AA) | Acciones legales, financieras o destructivas son reversibles, verificadas o confirmadas. | Flujo y tests de política. |
| 3.3.7 Entrada redundante (A) | No pedir de nuevo información ya aportada salvo necesidad o seguridad. | Flujo completo. |
| 3.3.8 Autenticación accesible mínima (AA) | No exigir prueba cognitiva sin alternativa, ayuda o mecanismo reconocido. | Login y recuperación. |

## Criterios robustos

| Criterio | Aplicación iOS | Evidencia mínima |
|---|---|---|
| 4.1.2 Nombre, función y valor (A) | Controles propios exponen nombre, rol, valor, estado y acciones correctas. | Inspector, VoiceOver y Voice Control. |
| 4.1.3 Mensajes de estado (AA) | Cambios importantes se anuncian sin mover foco innecesariamente. | VoiceOver en carga, éxito y error. |

## Matriz de dispositivo y preferencias

Validar lo aplicable en:

- iPhone e iPad; portrait, landscape y tamaños de multitarea/ventana relevantes.
- Light y Dark con contraste normal e incrementado.
- Dynamic Type `Large`, `XXX Large` y `AX 5` cuando Xcode los soporte.
- VoiceOver, Voice Control, Switch Control y Full Keyboard Access según el flujo.
- Increase Contrast, Reduce Motion, Reduce Transparency y Differentiate Without Color.
- Español y localizaciones disponibles, textos largos, plurales, placeholders y RTL cuando corresponda.

## Registro obligatorio por criterio y flujo

Cada pantalla, componente reutilizable o flujo completo afectado incluye una fila para **cada** criterio A/AA de esta
matriz. Se evalúan también flujos que cruzan pantallas: autenticación, navegación, sheets, errores, estados asíncronos,
confirmaciones y restauración de foco.

Estados de aplicabilidad: `Aplicable`, `Condicional`, `N/A`. Resultados: `Pendiente`, `Pasa`, `Falla`, `Limitado`.
Métodos: `Test`, `Preview`, `Inspector`, `VoiceOver`, `Voice Control`, `Switch Control`, `Teclado`, `Manual`.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 |  |  |  |  |  |  |  |

## Plantilla de evidencia por pantalla o flujo

```markdown
### <Pantalla, componente o flujo> — <fecha>

- Alcance/cambio:
- Dispositivo, iOS y build:
- Registro por criterio: <enlace o tabla completa con todas las filas A/AA>
- Previews y apariencias:
- Accessibility Inspector:
- VoiceOver / Voice Control / Switch Control / teclado:
- Movimiento, contraste, color, orientación, ventana y RTL:
- Tests automatizados:
- Hallazgos, correcciones y limitaciones:
- Revisor read-only y resultado:
```

## Fuentes

- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [WCAG2ICT 2.2](https://www.w3.org/TR/wcag2ict-22/)
- [WCAG2Mobile 2.2 — 1.4.12 Text Spacing](https://www.w3.org/TR/wcag2mobile-22/#text-spacing)
- [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple HIG VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)
- [Apple HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
