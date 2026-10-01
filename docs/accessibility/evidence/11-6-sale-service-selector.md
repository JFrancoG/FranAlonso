# 11.6 — Selección de servicios para el borrador

2026-10-01. Registro propio de [PLU-78](https://linear.app/plusprojects/issue/PLU-78), según
[ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md),
[ADR 0029](../../ADRs/0029-progressive-accessibility-validation.md) y la
[matriz canónica](../WCAG22_AA_IOS.md). El gate funcional para demo no acredita cierre integral.
Entrega Git en [PR38](https://github.com/JFrancoG/FranAlonso/pull/38), PLU-78 Done funcional el02/10/2026.
No se trasladan resultados de 11.5 a este flujo.

Deuda propia: [PLU-79](https://linear.app/plusprojects/issue/PLU-79), **Backlog**, responsable **Jesus Franco**, hija de
fase 11/PLU-71 y relacionada con PLU-78. Recuperar la evidencia pendiente tras feedback de Fran y estabilización de
este recorrido, antes del primer candidato para uso real. No absorbe PLU-77, PLU-65, PLU-67 ni deuda de otros flujos.

## Alcance y construcción

Entrada desde un borrador editable ya aceptado; sheet de servicios activos; búsqueda por nombre y filtro de tipo;
selección de una unidad; aceptación, error y reintento; cierre o retorno al mismo borrador. La inspección de ventas en
curso/pago/documento conserva la ausencia de esta entrada. La selección congela los términos comerciales antes de
suspender; el reintento conserva identidad y snapshot. La fila del catálogo muestra nombre, tipo y precio; la línea
aceptada conserva la representación existente de `SaleLine`.

`Button`, `Menu` con `Picker`, `List`, `Section`, `searchable` y toolbar nativos; texto real localizado ES/EN, fuentes semánticas y
wrapping. Filas con contenido agrupado, hint de incorporación, mínimo de altura de 44 pt y `contentShape` de
interacción. Estados y recuperación textuales; ProgressView decorativo oculto sólo cuando hay texto equivalente.
Filtro superior fuera de las filas de List; AX usa disposición vertical y conserva altura intrínseca.
Instrucción, estados, errores y catálogo permanecen desplazables. Se solicita retorno de foco a «Añadir servicio» al cerrar la sheet y anuncios de alta/error. Su entrega por tecnologías
de asistencia no está demostrada. No hay timers de foco ni dependencia nueva.

## Evidencia registrada y sus límites

- **S — Manual, revisión estática:** fuente del selector, entrada en `SaleDraftScreen`/`SaleDraftContent`, ViewModels,
  factory de App y recursos ES/EN, el 01/10/2026. Dispositivo/iOS: N/A; inspección de código, no árbol accesible runtime.
- **T — Test:** Swift Testing por Xcode MCP estable 27.0, scheme/plan Develop, iPad Pro 13-inch (M5), Simulator iOS 27.2,
  el 01/10/2026. Regresión nativa cerrada: **1.245 declaraciones / 1.959 variantes PASS**, cero fallos, skips, expected
  failures y runtime warnings; incluye **14 declaraciones / 25 variantes nuevas**. Resumen y árbol:
  `/tmp/plu78-regression-native-summary.json`, `/tmp/plu78-regression-native-tree.json`; selección nueva:
  `/tmp/plu78-new-regression-nodes.json`. Prueban snapshots, aceptación, identidad, cancelación, sesiones y composición;
  no prueban operación o anuncios por AT.
- **P — Preview, muestra representativa final:** 18 snapshots por Xcode MCP, iPad Pro13M5 e iPhone18ProMax,
  Simulator27.2, 01/10/2026. Content y Screen de selector/detalle en Large/XXX Large/AX5, ES/EN, Light/Dark;
  además vacío, error de catálogo/incorporación, sin coincidencias y fila de producto. Manifiesto con requests,
  overrides y resultados reales: `/tmp/plu78-previews-final.json`; inspección visual de cada snapshot por root.
  Los cuatro estados secundarios reproducen NavigationStack/título reales tras PRE y re-render PASS con Menu visible. Las capturas de Screens pueden observar carga inicial o contenido aceptado; no acreditan
  todos los estados/lenguas/contrastes/ventanas/orientaciones ni scroll efectivo o tecnología de asistencia.
- Builds finales funcionales Develop-for-testing **12,679 s** y Production **15,559 s**, PASS: cero diagnósticos
  Swift/Clang; notices conocidos AppIntents separados. Logs `BuildProject-Log-20261001-235540.txt` y
  `BuildProject-Log-20261001-235619.txt` bajo ActionArtifacts/default/BuildProject. Localización:505entradas/0errores,
  20claves nuevas ES/EN. Estas comprobaciones no prueban pronunciación ni accesibilidad integral.
- PRE independiente PASS; JSON completo735 intacto
  `a8705ba560f51217749d625a6916b7fbe1073eef99247266a109612c3d17756f`.
  Estilo focal final PASS, whole746 intacto `e52b75ec2bb616d1380a096a63b84ff3047940175092c8b1209889af2f033177`.
  PRE focal de filtro, adaptación y contexto; resultados reales en [propuesta](../../progress/11-6-service-selection-proposal.md).
- **R — Manual smoke funcional:**14comprobaciones/45eventos, iPhone17Simulator27.2, ES/texto estándar, demo en memoria
  aislada. Cancel/reopen conserva padre; búsqueda/noMatches, filtros, alta de profesional/producto, repetición,
  cantidades, actualización de catálogo y términos congelados; consulta readonly. Report/manifest:
  `/tmp/plu78-smoke-report.md`, `/tmp/plu78-smoke-manifest.json`. No prueba AT/físico/durabilidad entre procesos.
  Falla inicial conservada: Picker standalone330×31pt no abre en su centro; trailing funciona. Tras PRE, Menu label44
  con shape interno: retest8checks/18eventos PASS, tres filtros y alta/cancel/reopen; artefactos
  `/tmp/plu78-filter-retest-report.md` y `/tmp/plu78-filter-retest-manifest.json`. La disposición final pasa Canvas,
  tras intentos negativos de layout/separador; no se atribuye causa interna al framework.
  Retest final de disposición:10checks/23capturas PASS, Menu370×44/centro,3filtros, búsqueda/clear, alta35€/qty1,
  cancel/reopen y catálogo alcanzable. `/tmp/plu78-final-smoke-report.md` y `/tmp/plu78-final-smoke-manifest.json`,
  92rutas/0ausentes. Teclado hardware con foco; teclado en pantalla no observado. CUA no ofrece Simulator y no se
  cambiaron preferencias. Teclado visible/viewport/AT quedan pendientes enPLU-79; no se atribuyen como PASS.
  Sesiones cerradas y ejecuciones propias detenidas; Xcode Develop/planDevelop/iPadPro13M5 restaurado.
- POST técnico favorable, P3 ubicación nativa corregido; copias MCP actuales verificadas/exports iguales.
  UI POST detecta omisión estática de anuncio unavailable(P2) y3títulos sin traitheader(P3): corregidos tras PRE focal,
  estilo/builds/4previews afectados PASS. Se solicita anuncio para unavailable sin demostrar su entrega por AT;
  retest independiente focal técnico/UI PASS. Dictámenes y proofs en fase11.
- Geometría runtime: opciones nativas de menú250×35.7pt, superficie propia370×44 con centro operativo. Bordes,
  separación/excepciones y política44pt requieren Inspector/disposición enPLU79. Jerarquía exterior etiquetada/interior
  sinlabel no acredita dos paradas o anuncio incorrecto enVoiceOver; traversal real pendiente.

`Limitado` conserva el método efectivamente usado. En las filas `N/A`, expresa únicamente la comprobación estática del
alcance actual; no es un resultado integral. Si aparece el mecanismo excluido se reevaluará su aplicabilidad.
`Pendiente` requiere la ejecución indicada. Las referencias S/T/P remiten a los artefactos y configuraciones anteriores.
El revisor de la tabla registra evidencia; no sustituye al revisor independiente POST.

## Matriz completa de 55 criterios A/AA

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Icono de añadir tiene Label; fila contiene nombre, tipo y precio; sólo se oculta progreso decorativo con texto equivalente. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Árbol accesible y lectura VoiceOver pendientes en PLU-79. | selection_evidence |
| 1.2.1 | N/A | El selector no contiene audio ni vídeo pregrabado. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añade ese medio. | selection_evidence |
| 1.2.2 | N/A | No hay audio sincronizado pregrabado. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añade ese medio. | selection_evidence |
| 1.2.3 | N/A | No hay vídeo pregrabado que requiera alternativa o audiodescripción. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añade ese medio. | selection_evidence |
| 1.2.4 | N/A | No hay contenido audiovisual sincronizado en directo. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añade ese medio. | selection_evidence |
| 1.2.5 | N/A | No hay vídeo pregrabado que requiera audiodescripción. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añade ese medio. | selection_evidence |
| 1.3.1 | Aplicable | List/Section y encabezados estructuran instrucciones, filtro, estados y servicios; fila agrupada. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Inspector, rotor y navegación VoiceOver pendientes en PLU-79. | selection_evidence |
| 1.3.2 | Aplicable | Orden declarado: filtro, instrucciones, estado de incorporación, errores, catálogo; nombre/tipo/precio en cada fila. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Confirmar secuencia real con VoiceOver y teclado en PLU-79. | selection_evidence |
| 1.3.3 | Aplicable | Las instrucciones explican una unidad y posterior cambio de cantidad; no dependen de posición, color o sonido. | Limitado | Manual S, copy ES/EN. | S · 01/10/2026 | Verificar comprensión durante el recorrido accesible en PLU-79. | selection_evidence |
| 1.3.4 | Aplicable | El cambio no introduce bloqueo de orientación; la sheet debe seguir siendo operable en ambas orientaciones. | Pendiente | Manual S; Manual runtime previsto. | S · 01/10/2026 | Landscape, multitarea y ventanas relevantes pendientes en PLU-79. | selection_evidence |
| 1.3.5 | N/A | La entrada nueva busca nombres comerciales y filtra tipos; no solicita datos personales ni autofill. | Limitado | Manual S, alcance de entradas. | S · 01/10/2026 | Reevaluar si se solicitan datos personales. | selection_evidence |
| 1.4.1 | Aplicable | Carga, incorporación, vacío, ausencia de coincidencias y errores tienen texto; el tipo se nombra. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Differentiate Without Color pendiente en PLU-79. | selection_evidence |
| 1.4.2 | N/A | No se reproduce audio automático. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se incorpora audio. | selection_evidence |
| 1.4.3 | Aplicable | Texto con estilos semánticos existentes; no hay ratios medidos del render final. | Pendiente | Manual S; medición/Inspector previstos. | S · 01/10/2026 | Medir texto en Light/Dark y contraste normal/incrementado en PLU-79. | selection_evidence |
| 1.4.4 | Aplicable | Fuentes semánticas, texto multilínea y fila vertical; muestra Large, XXX Large y AX 5. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Falta runtime AX 5 y completar estados/lenguas por impacto en PLU-79. | selection_evidence |
| 1.4.5 | Aplicable | Nombres, tipos, importes, instrucciones y errores son Text; no son imágenes de texto. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Conservar texto real y verificar todos los estados finales en PLU-79. | selection_evidence |
| 1.4.10 | Aplicable | List desplaza verticalmente y las filas permiten wrapping; muestra de iPhone e iPad. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Ventanas estrechas, landscape y teclado abierto pendientes en PLU-79. | selection_evidence |
| 1.4.11 | Aplicable | Picker, búsqueda, toolbar y estados necesitan contraste no textual evaluado en su render final. | Pendiente | Manual S; medición/Inspector previstos. | S · 01/10/2026 | Medir controles/estado en las cuatro apariencias en PLU-79. | selection_evidence |
| 1.4.12 | N/A | SwiftUI nativo; no hay markup que permita sobrescribir propiedades de espaciado del autor. | Limitado | Manual S, tecnología de la UI. | S · 01/10/2026 | Reevaluar si se añade UI mediante markup. | selection_evidence |
| 1.4.13 | N/A | No hay contenido adicional propio que aparezca sólo al hover o recibir foco. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | El menú se activa explícitamente; reevaluar si se añaden ayudas al foco/hover. | selection_evidence |
| 2.1.1 | Aplicable | Selección, filtro, búsqueda, cierre y recuperación usan controles nativos compatibles. | Pendiente | Manual S; Teclado previsto. | S · 01/10/2026 | Recorrido completo Full Keyboard Access pendiente en PLU-79. | selection_evidence |
| 2.1.2 | Aplicable | La sheet tiene Cerrar y acciones nativas; su salida no debe atrapar el foco. | Pendiente | Manual S; Teclado/Switch Control previstos. | S · 01/10/2026 | Probar entrada, operación y salida de búsqueda, menú y sheet en PLU-79. | selection_evidence |
| 2.1.4 | N/A | No se introducen atajos de un solo carácter. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se añaden atajos. | selection_evidence |
| 2.2.1 | N/A | No hay límite temporal de búsqueda, selección o reintento. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se introduce un timeout de interacción. | selection_evidence |
| 2.2.2 | Condicional | La observación puede actualizar el catálogo y hay progreso nativo durante carga/incorporación. | Pendiente | Manual S; Manual runtime previsto. | S · 01/10/2026 | Evaluar actualización automática, operación de Cerrar y Reduce Motion en PLU-79; no declarar N/A sin comprobar el flujo. | selection_evidence |
| 2.3.1 | Aplicable | No se añade animación propia ni contenido que destelle; transiciones/progreso son nativos. | Limitado | Manual S. | S · 01/10/2026 | Revisar render/transición con preferencias reales en PLU-79. | selection_evidence |
| 2.4.1 | Aplicable | Título, secciones y encabezado Servicios ofrecen estructura para acceder al catálogo. | Limitado | Manual S. | S · 01/10/2026 | Rotor, foco inicial y navegación eficiente pendientes en PLU-79. | selection_evidence |
| 2.4.2 | Aplicable | La sheet se titula Añadir servicio/Add service de forma localizada. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Confirmar anuncio del destino al presentarlo en PLU-79. | selection_evidence |
| 2.4.3 | Aplicable | Retorno solicita foco en Añadir servicio; la sesión del hijo no cierra el Store padre. | Pendiente | Manual S; Test T para identidad/cierre. | S/T · 01/10/2026 | VoiceOver, teclado y Switch Control deben demostrar orden y retorno de foco en PLU-79. | selection_evidence |
| 2.4.4 | Aplicable | Añadir, Cerrar, Recargar y Reintentar describen acciones; fila combina nombre/tipo/precio con hint. | Limitado | Manual S, nombres y contexto. | S · 01/10/2026 | Comprobar lista de acciones y comprensión por AT en PLU-79. | selection_evidence |
| 2.4.5 | Aplicable | Catálogo navegable con búsqueda por nombre y filtros Todos/Profesional/Producto. | Limitado | Manual S; Test T. | S/T · 01/10/2026 | Evaluar catálogo extenso y navegación accesible en PLU-79. | selection_evidence |
| 2.4.6 | Aplicable | Instrucción, filtro de tipo, título y encabezados/errores describen su propósito. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Rotor y árbol final de estados pendientes en PLU-79. | selection_evidence |
| 2.4.7 | Aplicable | Se conserva foco nativo; no hay evidencia de su visibilidad con teclado. | Pendiente | Manual S; Teclado previsto. | S · 01/10/2026 | Comprobar foco visible en búsqueda, menú, filas, cierre y reintento en PLU-79. | selection_evidence |
| 2.4.11 | Aplicable | Sheet desplazable con búsqueda, toolbar y menú; podrían ocultar el elemento enfocado. | Pendiente | Manual S; Teclado previsto. | S · 01/10/2026 | Recorrer AX 5 con teclado, barras y scroll en PLU-79. | selection_evidence |
| 2.5.1 | N/A | Ninguna función requiere gesto multipunto o trayectoria; hay botones y controles nativos. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se incorpora un gesto complejo. | selection_evidence |
| 2.5.2 | Aplicable | La selección usa Button sin down-event propio; cerrar permite abandonar el selector. | Limitado | Manual S; Test T de cancelación. | S/T · 01/10/2026 | Cancelación táctil y alternativas por AT pendientes en PLU-79. | selection_evidence |
| 2.5.3 | Aplicable | Labels y nombre agrupado contienen el texto visible de las acciones y del servicio. | Limitado | Manual S. | S · 01/10/2026 | Activación por nombre con Voice Control pendiente en PLU-79. | selection_evidence |
| 2.5.4 | N/A | No existe activación por movimiento del dispositivo. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se incorpora movimiento. | selection_evidence |
| 2.5.7 | N/A | No se exige arrastrar para seleccionar, filtrar, recuperar o cerrar; desplazamiento nativo. | Limitado | Manual S, ausencia del mecanismo. | S · 01/10/2026 | Reevaluar si se incorpora una operación de arrastre. | selection_evidence |
| 2.5.8 | Aplicable | Entrada, filas y Menu solicitan mínimo44pt; centro del Menu responde tras corregir el Picker standalone. | Limitado | Manual S; Preview P; Manual R y retest focal. | S/P/R · Simulator27.2 · 01/10/2026 | Falla inicial documentada arriba y corregida con retest funcional; medir bordes/superficie, opciones nativas35.7pt, separación y excepciones WCAG2ICT/política44pt en PLU-79. No equivale a Pasa normativo ni a Inspector. | selection_evidence; root retest |
| 3.1.1 | Aplicable | Copy nuevo ES/EN e importes/anuncios usan Locale; el validador confirma inventario de textos. | Limitado | Manual S; Test T/localización. | S/T · 01/10/2026 | Pronunciación y lengua de controles/estados con VoiceOver pendientes en PLU-79. | selection_evidence |
| 3.1.2 | Condicional | El nombre comercial es dato del catálogo y puede contener otra lengua; no se garantiza contenido monolingüe. | Pendiente | Manual S; VoiceOver previsto. | S · 01/10/2026 | Probar contenido mixto y decidir identificación programática aplicable en PLU-79. | selection_evidence |
| 3.2.1 | Aplicable | Recibir foco no solicita selección, no acepta líneas ni abre otra pantalla. | Limitado | Manual S. | S · 01/10/2026 | Verificar foco real con VoiceOver y teclado en PLU-79. | selection_evidence |
| 3.2.2 | Aplicable | Query/filtro sólo cambian lo visible; tocar una fila incorpora una unidad como explica la instrucción. | Limitado | Manual S; Test T. | S/T · 01/10/2026 | Verificar expectativas y operación por AT en PLU-79. | selection_evidence |
| 3.2.3 | Aplicable | Sheet contextual con título, búsqueda, filtro y Cerrar nativos; retorno al mismo borrador. | Limitado | Manual S; Test T de sesiones. | S/T · 01/10/2026 | Comparar recorrido runtime/AT con patrones existentes en PLU-79. | selection_evidence |
| 3.2.4 | Aplicable | Nombre/tipo/precio usan formatos y textos del catálogo; cierre y recuperación tienen nombres coherentes. | Limitado | Manual S. | S · 01/10/2026 | Verificar identificación accesible entre catálogo y borrador en PLU-79. | selection_evidence |
| 3.2.6 | N/A | No se añaden mecanismos de ayuda repetidos en este flujo. | Limitado | Manual S, alcance actual. | S · 01/10/2026 | Reevaluar si se incorpora ayuda. | selection_evidence |
| 3.3.1 | Aplicable | Error de catálogo e incorporación se distinguen con texto sanitizado y acción de recuperación; se solicitan anuncios. | Limitado | Manual S; Test T de error/reintento. | S/T · 01/10/2026 | Asociación, lectura y entrega de anuncios pendientes en PLU-79. | selection_evidence |
| 3.3.2 | Aplicable | Búsqueda y filtro tienen labels; la instrucción explica cantidad inicial y ajuste posterior. | Limitado | Manual S; Preview P. | S/P · 01/10/2026 | Revisar label persistente/contexto con búsqueda activa y VoiceOver en PLU-79. | selection_evidence |
| 3.3.3 | Aplicable | Recargar recupera catálogo; Reintentar conserva línea congelada, sin exigir elegir de nuevo. | Limitado | Manual S; Test T. | S/T · 01/10/2026 | Recorrido de error y recuperación por AT pendiente en PLU-79. | selection_evidence |
| 3.3.4 | Aplicable | Se incorpora al borrador reversible; Store valida antes de aceptar y conserva éxito durable; no confirma cobro/stock. | Limitado | Manual S; Test T de aceptación/snapshot. | S/T · 01/10/2026 | Verificar revisión/retirada posterior y comunicación accesible en PLU-79; no extender a pago. | selection_evidence |
| 3.3.7 | Aplicable | El reintento reutiliza snapshot e identidad; cerrar el hijo conserva el borrador aceptado. | Limitado | Manual S; Test T. | S/T · 01/10/2026 | Recorrido completo accesible sin reentrada redundante pendiente en PLU-79. | selection_evidence |
| 3.3.8 | N/A | La selección no añade ni cambia autenticación; conserva los gates del flujo previo. | Limitado | Manual S, alcance actual. | S · 01/10/2026 | No cierra deuda de autenticación; reevaluar si este flujo la incorpora. | selection_evidence |
| 4.1.2 | Aplicable | Button/Picker/búsqueda nativos; fila agrupada, filtro con valor y acciones deshabilitadas según estado. | Limitado | Manual S. | S · 01/10/2026 | Inspector y operación VoiceOver/Voice Control pendientes en PLU-79; comprobar traversal real de Button exterior/interior. | selection_evidence |
| 4.1.3 | Aplicable | Alta y errores solicitan Announcement; carga expone ProgressView; incorporación tiene texto equivalente. | Limitado | Manual S; Test T de estados. | S/T · 01/10/2026 | Orden, anuncio efectivo y retorno de foco al dismiss pendientes en PLU-79. | selection_evidence |

## Recuperación integral y dictamen funcional

PLU-79 debe completar Inspector, mediciones de contraste, VoiceOver, Voice Control, Switch Control, Full Keyboard
Access, foco/anuncios y superficies realmente operables; preferencias Increase Contrast, Differentiate Without Color,
Reduce Motion y Reduce Transparency; orientaciones, ventanas/multitarea, ES/EN con nombres largos y contenido mixto,
RTL cuando corresponda y estados restantes. Conservar los resultados reales y revalidar por impacto después del feedback.
Previews y tests no sustituyen estas pasadas.

Smoke funcional y POST técnico/UI final PASS para implementación local de demo segúnADR0029.
El retest independiente valida construcción y evidencia por impacto, con whole746JSON intacto
`bf27ceb314e985aaaa3dcd5f620244102c7c0236aab0110a1dfb08770518ee7d`.
Conserva las45filas Limitado y10Pendiente, deudaPLU79 y gate integral abierto. No acredita certificación, Pasa
integral, entrega Git ni fase completa. Cierre del registro funcional:02/10/2026; evidencias ejecutadas el01/10.


Entrega funcional Git autorizada el02/10/2026 y en preparación; conserva el dictamen funcional PASS, matriz55,
PLU79/responsable y gate integral abierto. No se cambian resultados ni se atribuye nueva evidencia accesible.

Entrega Git completada el02/10/2026: PR38 MERGED, `fcb0a6e` → `9f38731`, árbol/fuente586 idénticos;
rama local/remota eliminada y PLU-78 Done funcional. Revisión independiente focal de entrega PASS.
Este cierre sólo reconcilia metadata: matriz55, 45Limitado/10Pendiente, PLU-79 Backlog/Jesus Franco,
su recuperación antes del candidato real y fase11 In Progress permanecen intactos.
