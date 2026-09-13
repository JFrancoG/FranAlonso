# 08.4 — Estudio de visibilidad del foco de teclado

Fecha: 2026-09-11. PLU-38. Propuesta, sin cambio ejecutable ni cierre del hallazgo.

## Problema observado

El propietario completa abrir, Deshacer, Borrar, Cancelar, Confirmar y volver a seleccionar Capturar firma
con teclado del Mac y Acceso total con teclado en iPad Air 11-inch (M4)/iPadOS 26.5. Sin embargo, el foco rosa
se confunde con borde/relleno de los botones. Su identificación al entrar en el grupo con flecha abajo fue difícil.
La captura individual [botón principal](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/main-button-focus.png>)
muestra el indicador. La captura anterior de Confirmar solo muestra el grupo y no acredita un indicador individual.

## Medición orientativa

PNG nativo1640×2360 sin perfil ICC; valores interpretados como sRGB, sin transformación ni edición de la imagen.
Muestreo vertical x=400: fondo #1C1C1E hasta y1268; banda exterior #E49ACE y1269–1272;
banda #B64896 y1273–1276; relleno #E49ACE desde y1277. Bandas inferiores simétricas.
La fórmula de luminancia relativa da:

| Comparación | Contraste aproximado |
|---|---:|
| Banda magenta / relleno rosa | 2,25:1 |
| Banda magenta / fondo oscuro | 3,53:1 |
| Banda exterior rosa / fondo oscuro | 7,95:1 |

Esta medición contextualiza la dificultad de percepción; el indicador tiene varias bandas y no se declara
incumplimiento normativo a partir de una sola pareja. No acredita Light, alto contraste ni el sheet.
Como ejemplo matemático, #0064B4 da2,82:1 contra relleno y2,82:1 contra fondo; #00C8F0 da1,07:1 contra relleno.
Cambiar solo de matiz no garantiza contraste. Estos colores no se han seleccionado para producción.

## APIs y límites verificados

Target real iOS26.0, Swift6.0. Investigación mediante Cupertino, Xcode DocumentationSearch e interfaces
públicas del SDK instalado (revisión independiente).

- [tint](https://developer.apple.com/documentation/swiftui/view/tint(_:)) depende del control, estilo y plataforma.
  PrimaryActionStyle ya lo usa para el relleno prominente. No se ha encontrado canal público documentado para
  elegir exclusivamente el color del halo FKA de un Button SwiftUI.
- [UIFocusHaloEffect](https://developer.apple.com/documentation/uikit/uifocushaloeffect) expone geometría,
  posición y contenedor, no color. No se asume que personalice el indicador de esta tecnología de asistencia.
- [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate) documenta
  seguimiento genérico de foco accesible. No prueba por sí solo seguimiento FKA aquí. No se usan símbolos internal.
- [Apple HIG teclados](https://developer.apple.com/design/human-interface-guidelines/keyboards) distingue foco
  ordinario de FKA. No añadir focusable ni suprimir el foco nativo como supuesto arreglo.
- [Ajustes FKA](https://support.apple.com/es-es/guide/ipad/ipad5f765d6f/ipados) permiten al usuario personalizar
  color, contraste y tamaño; no se impone cambiar preferencias como solución de la pantalla.

## Propuesta de experimento mínimo

1. Conservar Button y sus nombres, estados, acciones, interacción por Espacio e indicador nativo.
2. Ensayar primero una separación neutra de pocos puntos entre la decoración del botón y el indicador,
   adaptada a claro/oscuro. No recuperar la altura excesiva descartada por el propietario ni reducir44pt operables.
3. Como alternativa, probar un estilo local que dibuje el relleno primary por separado y reserve tint para
   un color contrastante. Que el halo adopte ese tint es una hipótesis a contrastar en runtime, no una garantía.
   Dos tint anidados sobre borderedProminent no representan dos canales independientes.
4. Limitar inicialmente el prototipo al acceso temporal y después a los controles de firma si el resultado
   es favorable. No cambiar AccentColor ni PrimaryActionStyle global por inferencia.
5. Capturar enfocado/sin foco, Light/Dark y contraste normal/incrementado para Confirmar y Deshacer; revisar
   separación, recorte y contraste con superficies adyacentes. Confirmar que el foco conserva preferencia del sistema.
6. Comprobar activación y retorno únicamente de los controles tocados; conservar toda evidencia manual anterior.
   Usar Xcode MCP para compilar/previews cuando exista cambio ejecutable. No añadir tests que reflejen decoración.

## Revisión y estado

Revisión independiente ios-accessibility-reviewer operacional read-only: 462 archivos, digest pre/post idéntico
verificado por el orquestador: b75aa9c3faa85f2882c010df46b78fa16817279acc27a4b06760c84afce79990.
Conclusión: P2 visual abierto; experimento local reversible recomendado. Ninguna opción está validada en runtime.
Estudio completado. No se ha modificado código ni preferencias. Build/tests N/A documental. 08.4 continúa abierta.

## Prototipo con separación probado — 2026-09-11

El propietario autoriza probar aire conservando color. Único archivo ejecutable cambiado en este ensayo:
SignatureManualValidationScreen.swift, botón Capturar firma del acceso temporal. Label con mínimo44pt,
padding horizontal16/vertical6, relleno brandPrimary y margen exterior6 sobre canvas; estilo plain,
tint brandPrimary y contentShape interaction capsule. Conserva acción, nombre y accessibilityFocused.
PrimaryActionStyle compartido y controles del sheet no se modifican.

RunProject oficial Xcode MCP, Signature-Manual/iPadAir11M4/26.5: PASS9,561s, PID17468.
Log completo: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260911-230619.txt`.
GetBuildLog no devuelve incidencias estructuradas; log completo contiene solo aviso AppIntents previo.
No tests decorativos nuevos ni regresión lógica repetida; comportamiento de captura no cambiado.

Previews inspeccionadas Large Light, XXXLarge Dark y AX5 Light High: texto/botón completos.
Destino efectivo iPadPro13M5/iOS27.0; no acredita foco ni runtime26.5. Copias fuera de Git:
`/Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/gap-preview-*.png`.

Runtime: `gap-prototype-focused-dark.png` muestra banda neutra #1C1C1E entre relleno y halo.
Muestreo PNG nativo x400: fondo hasta1229, banda rosa1230–1233, magenta1234–1237, separación1238–1241,
relleno desde1242. Los6pt de margen se traducen en2pt visibles en esta sección porque el indicador
ocupa parte del margen; no se afirma6pt de aire útil. `gap-prototype-light-after-update.png` muestra
Light sin foco individual; `gap-prototype-focused-light.png` capturó aún Dark durante transición.
Los nombres de archivos no acreditan su apariencia ni foco por sí solos.

Propietario: inicialmente percibe mejora en oscuro como borde oscuro; precisa que en claro sí ve aire y
que en oscuro se ve menos, pero se ve. Confirma después que Espacio abre la captura en este prototipo.
Se conserva margen6; el aumento a10 fue revisado como alternativa pero no aplicado tras esa aclaración.
Apariencia del simulador restaurada y verificada Dark. Preferencias FKA conservadas.

Revisión preejecutable independiente PASS, huella463 estable
`6cb9b08afacc4b6989bc74a9b45ecfb99e2461343657484b1f3681d39a00617a`.
Revisiones POST por nuevos agentes de estándares y accesibilidad/estilo: sin hallazgos en el prototipo.
Huella463 pre/post idéntica verificada por root:
`95f619059d75d60964279c039560044b67d176c1001a571c3936c37fe2849846`.

Resultado favorable limitado al acceso temporal: aire distinguible manualmente en ambos modos y
activación conservada. No cierra foco de Deshacer/Borrar/Confirmar/Cancelar del sheet ni08.4.
Siguiente paso: trasladar la solución a los controles de captura y comprobar su geometría y foco
sin recuperar la altura excesiva rechazada ni repetir los recorridos ya acreditados.

## Aclaración del foco dentro del grupo — 2026-09-11

El propietario precisa que dentro del grupo el marco continúa rodeando todo el contenido, mientras
el botón seleccionado recibe una superposición muy transparente. En Deshacer/Borrar se percibe;
en el botón principal interior apenas permite distinguir la selección. Su término «subfoco» describe
la apariencia observada, no una API ni una atribución técnica confirmada.

La prueba favorable del botón aislado del acceso temporal no resuelve este comportamiento. Se cambia
el siguiente paso: diagnosticar el indicador individual dentro del grupo antes de trasladar el margen
a los botones del sheet. No atribuirlo solo a contraste ni modificar la agrupación de accesibilidad
sin verificar el efecto sobre navegación y scroll.

La captura automática `group-subfocus-reported.png` recoge la pantalla de acceso tras cancelar,
sin indicador visible; no acredita el estado interior descrito. Se conserva el reporte manual y las
capturas anteriores del grupo. Sin nuevo cambio de código, build ni tests.

## Captura del indicador interior — 2026-09-12

Se recopilan doce PNG nativos con RocketSim durante navegación FKA manual en iPad Air11M4/iPadOS26.5 Dark, sin activar acciones. Archivos fuera de Git: `/Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/group-focus-sequence-00.png` a `-11.png`.
La toma04 muestra marco del ScrollView y rectángulo translúcido en Deshacer. La06 muestra el mismo marco exterior y selección de Confirmar. Comparación RGB con `group-before-keyboard-selection.png`: la región cambiada de Confirmar abarca x272–1367/y1523–1623; el relleno muestreado x600/y1570 sigue #E49ACE en ambos estados. La selección se confunde con su relleno. No se declara ratio normativo ni causa interna de iPadOS a partir de esta comparación.
La toma aislada `group-confirm-focused-20260912.png` no muestra indicadores; no sirve como evidencia de foco. La ocultación automática previamente observada puede explicar la pérdida, sin atribución confirmada.

Revisión diagnóstica read-only: no existe agrupación explícita en la View que retirar. Se preservan ScrollView, semántica, acciones y foco nativo. No se usan FocusState, APIs privadas ni preferencias forzadas. El siguiente ensayo limita el margen neutro al botón Confirmar dentro del sheet; el resultado del botón exterior no se extrapola como PASS.

## Piloto Confirmar con margen: descartado — 2026-09-12

Se ensaya únicamente Confirmar: label con mínimo44pt, margen exterior6pt sobre canvas y estilo plain. Conserva Button, acción, disabled, colores y ScrollView. Runtime confirma tamaño548×56pt, atenuación e inoperabilidad al pulsarlo vacío. RunProject PASS14,759s/PID78429; log `RunProject-Log-20260912-012313.txt`. Cuatro previews inspeccionadas en iPadPro13M5/iOS27: Empty Light/Large, Ink Dark/XXXLarge, Ink Light/AX5 High e Ink Dark/Large High; sin recorte del botón. No tests decorativos nuevos.

Gate PRE read-only independiente:463 archivos, digest idéntico e95596e21aef46a1b5cc8993f94a7c40040dfa1f9e54ebc2bc3b24598b9151f3. POST visual por agente nuevo y estándares/estilo por revisor PRE independiente del implementador (límite técnico al crear otro agente): sin hallazgos estáticos, digest463 idéntico 5083e5d5159bc4a5800e1cc76d36302b9aa9c0705f50838516fe2429e4ccf4ed. Estas revisiones no acreditan éxito del foco.

El propietario prueba la versión y responde «no, lo veo igual». Se descarta el piloto por falta de mejora perceptible; no se acredita Espacio a partir de esa respuesta ni se pide repetir otros recorridos. Se restaura exactamente el código anterior de Confirmar con primaryActionStyle; digest global previo a editar documentación vuelve a e95596e21aef46a1b5cc8993f94a7c40040dfa1f9e54ebc2bc3b24598b9151f3.
RunProject tras restauración PASS9,203s/PID80161, log `RunProject-Log-20260912-012628.txt`; ambos logs completos contienen solo aviso AppIntents conocido y ningún aviso Swift/Clang. El acceso temporal exterior conserva su ensayo anterior. P2 de foco interior sigue abierto: aumentar margen no queda recomendado como solución. Siguiente investigación: comparar el indicador de controles nativos dentro de scroll bajo los mismos ajustes FKA, antes de otra modificación de diseño.

## Ensayo de contorno accesible rectangular — 2026-09-12

Nuevo reporte: el propietario distingue las esquinas del resalte cuadrado sobre Deshacer/Borrar redondos,
pero en Confirmar percibe sobre todo las letras. El frame accesible previo ya abarca548×50,5pt.
Comparación de PNG anteriores: existen cambios en ambos bordes (59 píxeles en cada región de esquina
38×32), además del texto; no demuestra que el foco se limite al texto.

Ensayo autorizado de una línea en ClientSignatureCaptureScreen, después de primaryActionStyle:
`contentShape(.accessibility, .rect)`. Mantiene diseño, ancho, altura, hit-testing, acción y disabled.
[Apple](https://developer.apple.com/documentation/swiftui/contentshapekinds/accessibility) documenta
modificación de frame/path, indicador accesible y ordenación; no se considera exclusivamente visual.
No se reduce el ancho ni se recupera el margen descartado. FKA y orden VoiceOver requieren evidencia local.

PRE independiente read-only:463 archivos, digest idéntico
`0de8e0b521c372cdc3179e3af0cf7b64d6ec2e66e259fb952dd32c3764b195df`.
POST AX por agente nuevo y estándares/estilo por revisor PRE independiente del implementador
(reutilizado por límite de agentes): sin hallazgos del delta, 0 candidatos de estilo.
Digest463 POST idéntico verificado:
`d9e8f7acce64fdb7895a494131ca191a687cd8767f20211f875c712fa9f64096`.

RunProject Xcode oficial PASS11,431s/PID19402, Signature-Manual/iPadAir11M4/26.5.
Log completo `RunProject-Log-20260912-104101.txt`: solo aviso AppIntents conocido, sin Swift/Clang warnings.
Previews inspeccionadas Large Light, XXXLarge Dark, AX5 Light High en iPadPro13M5/iOS27; botón completo.
Runtime: un único Confirmar548×50,5pt; pulsarlo vacío no cambia estado/pantalla (hash cbcd545d).
No tests decorativos nuevos. Preparado trazo y solicitada comparación FKA de esquinas.
Pendientes: resultado visual Light/Dark, Espacio y recorrido VoiceOver local; no cierre de P2/08.4.

## Confirmación visual del contorno — 2026-09-12

El propietario confirma sobre el ensayo: «ahora se ve, es sutil pero al desbordar por las esquinas ya si se ve».
Se acredita mejora perceptible del indicador individual de Confirmar en la apariencia probada.
No se infiere validación de ambas apariencias, contraste normativo, Espacio ni orden VoiceOver de este reporte.
Se conserva la línea contentShape accessibility rect. Pendientes del delta: contraste/apariencia restante,
activación por Espacio y recorrido local VoiceOver entre controles vecinos. Sin nuevo cambio ejecutable;
build/tests N/A para registrar este resultado manual. 08.4 continúa abierta.

## Activación por teclado del contorno rectangular — 2026-09-12

El propietario confirma que, con Confirmar firma enfocado, Espacio confirma y vuelve correctamente
a la pantalla anterior en el ensayo con contentShape accessibility rect. PASS manual focal de activación
por teclado del control modificado; no implica haber comprobado el retorno del foco ni el orden VoiceOver.
Se conservan las pruebas anteriores. Pendientes: resalte en Light y recorrido VoiceOver local.
Sin nuevo cambio ejecutable; build/tests N/A para registrar evidencia manual. 08.4 abierta.

## Resalte en Light confirmado — 2026-09-12

El propietario confirma que el contorno rectangular se distingue en modo claro «mejor aún».
Con el reporte Dark previo y Espacio ya confirmado, queda acreditada la mejora perceptible en ambas
apariencias y la activación focal por teclado. No equivale a medición normativa de contraste ni cierre
completo de accesibilidad. Se mantiene pendiente únicamente el recorrido VoiceOver local para este delta.
Sin nuevo código; registro manual, build/tests N/A. 08.4 conserva los demás pendientes de su matriz.

## VoiceOver local del ajuste confirmado — 2026-09-12

El propietario confirma en iPhone14 físico/iOS26.6.1, versión ejecutada mediante RunProject
11,366s/PID16678, que VoiceOver recorre correctamente Área de firma → Deshacer → Borrar → Confirmar
y regreso, y anuncia «atenuado» en captura vacía. No reporta saltos ni duplicados.
PASS manual focal de orden y estado del control tras contentShape accessibility rect.
Junto a FKA Light/Dark y Espacio, quedan completadas las comprobaciones locales solicitadas para
este ajuste. Se conserva la solución; no requiere repetir los recorridos anteriores.
No equivale a medición normativa de contraste ni cierra los otros pendientes de 08.4.
Registro documental, sin nuevo código: build/tests N/A.
