# 13.5 — Selección de documento y destinatario fiscal

03/10/2026, [PLU-100](https://linear.app/plusprojects/issue/PLU-100), implementación local validada; POST funcional PASS bajo ADR0029.
Objetivo de accesibilidad: [ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md).
Validación progresiva para demo: [ADR 0029](../../ADRs/0029-progressive-accessibility-validation.md).
Deuda específica [PLU-101](https://linear.app/plusprojects/issue/PLU-101), Backlog, responsable Jesus Franco.
Recuperación tras feedback de Fran y estabilización de **cada recorrido**, siempre antes del primer candidato para uso real.
Esta evidencia no acredita entrega Git, cierre integral, tecnologías de asistencia, dispositivo físico, conformidad legal
ni activación live. La deuda previa [PLU-91](https://linear.app/plusprojects/issue/PLU-91) conserva su alcance.

## Alcance y configuración

Un flujo completo afectado: Jornada → detalle de venta pagada y pendiente de documento → sheet Documento → elección
Ticket/Factura → destinatario fiscal → error/corrección → solicitud preparada → cierre/cancelación → detalle/Jornada.
Incluye el componente de entrada `SaleWorkflowSection`, el detalle `SaleDraftScreen`, `BillingScreen` y sus contenidos
de selección, campos fiscales y resumen preparado. La matriz de 55 criterios evalúa ese flujo, incluidos sus cruces
entre pantallas; no interpreta cada preview como una pantalla accesible aprobada.

La factura captura nombre o razón social, identificación fiscal, dirección, código postal, ciudad y provincia. La
validación comprueba contenido no vacío tras trim; es una política de completitud de la aplicación y no verifica
identificadores, obligaciones fiscales ni validez legal. Ticket no necesita destinatario. Preparar congela una solicitud
y muestra un resumen; no reserva número, emite PDF, envía correo ni cierra la venta. Cancelar no altera la venta ni
el perfil del cliente; la venta permanece pagada y pendiente en Jornada. La solicitud preparada todavía no es durable
tras descartar esta sesión; esa recuperación corresponde a subfases posteriores.

Referencias de configuración para todas las filas:

- **S13.5**: fuentes finales tras corregir la escritura de campo sin cambio y explicitar el nombre accesible del
  TextField; catálogo con título corregido `Documento`/`Document`, 03/10/2026; base
  `76835cb660fb0e727dd408290ac123297065414a`. El [manifest](assets/13-5/manifest.json) registra SHA256 actuales de los
  32 Swift nuevos/modificados y del catálogo, y conserva por separado los hashes anteriores de las capturas.
  Estilo focal PASS comunicado por root: huella 966 archivos
  `fdb1349ad3c00a6d76037608701c59eaa1c71ffd099cce3bf19f32863b0660cd`.
  No contiene textos introducidos, datos de cuenta ni payloads de negocio.
- **T13.5**: Swift Testing/Xcode MCP, Develop/03/10/2026: RED inicial7/7 esperado→GREEN173/173;
  regresión setter RED1/1→GREEN1/1; regresión prefill tardío RED1FAIL/1PASS→GREEN3/3 con setter.
  Focal final155/155 PASS, parámetros parcialmente seleccionados. Global previo2580/2580PASS; **global final
 2581/2582 falla en Stock en tres intentos**, sin cambio en esa fuente ni causa atribuida; retestStock1/1PASS.
  Native xcresult completo prueba **28declaraciones nuevas/59casos completos PASS**,1578declaraciones/2582ejecuciones.
  Builds finales Develop11.15s/Production18.983s PASS,0Swift-Clang/errores,2/1AppIntents conocidos.
  Localizaciones607/0errores,30textos nuevos es/en. Logs/bundles/IDs y límites en [fase13](../../progress/phase-13.md).
- **P13.5**: **20 PNG originales** Xcode MCP RenderPreview, Develop, 03/10/2026: 18 representativos entre 14:33 y
  14:37, y 2 recapturas de error tras setter/label a las 15:02:43, previas al ajuste de prefill.
  Destino seleccionado del workspace: iPhone 17; **host renderizado real: iPhone 18 Pro Max, iOS 27.2**, portrait.
  Overrides exactos en el manifest: `Large`, `XXX Large`, `AX 5`; es/en; Light/Dark; contraste estándar/aumentado.
  Se eligieron combinaciones representativas, no el producto completo de preferencias. Fixtures sintéticas in-memory.
  Las 18 capturas representativas preceden a la última corrección semántica de S13.5 y se reutilizan por impacto,
  sin atribuirles un render posterior. Las 2 recapturas de error Large/AX5 también preceden al P2 de prefill:
  se reutilizan tras ese ajuste por impacto no visual; no se presentan como renders de la fuente posterior al P2.
- **R13.5**: smoke táctil funcional **PASS** tras fix, RocketSim, iPhone 17 Simulator27.2,
  `com.plusprojects.FranAlonso.develop`, launch `--franalonso-demo-workday` fresco PID2172, build Xcode MCP
  corregido12.543s/15:00:01; es/Light/Dynamic Type por defecto/teclado software, 03/10/2026.
  [Observaciones sanitizadas](assets/13-5/runtime-observations.json) y manifest conservan procedencia/hashes;
  51 artefactos originales quedan en `/tmp/franalonso-13-5-runtime`, sin copiar URL/token al repo.
  Root inspeccionó PNG originales [error con cursor/mensaje](assets/13-5/runtime-34-retest-error.png),
  [factura seis datos](assets/13-5/runtime-42-retest-invoice-prepared.png),
  [ticket preparado](assets/13-5/runtime-44-retest-ticket-prepared.png) y
  [retorno a Jornada](assets/13-5/runtime-47-retest-final-jornada.png).
  Revisor runtime: `billing_13_5_runtime`; interpretación final/root. Prueba recorrido táctil y labels AX,
  sin demostrar habla/rotor/foco de AT, Inspector, ratios, AX5 integral ni dispositivo físico.

## Evidencia estática y funcional

Las Views usan `Form`, `Section`, `Picker` de menú y `TextField` nativos; una conformidad View por archivo y previews
deterministas. Los seis campos tienen etiqueta persistente con `FormFieldSection`, nombre accesible explícito del
TextField, entrada vertical, hint de obligación
y mensaje textual del campo inválido. Nombre y domicilio exponen `textContentType` compatibles; identificación fiscal
no inventa un propósito de autofill. La copia de error no depende del color.

`BillingScreen` solicita foco de teclado y accesible en el primer campo inválido y publica un anuncio localizado;
preparar limpia ese foco y anuncia el resultado. El detalle conserva una intención de retorno al botón de selección.
Es evidencia de intención declarada: falta observar posición, orden, habla y restauración reales con AT. La carga local
del cliente muestra estado textual; aceptar su respuesta, editar, cambiar tipo y cerrar se cercan por la sesión vigente.

La regresión focal comprobó que un setter de Binding con el mismo texto borraba el error requerido y la identidad de
validación: RED 1/1 con tres aserciones esperadas fallidas en `F7A2DE00-064F-4A0E-BCA1-9B95007A41A3.txt`.
El guard de igualdad conserva error e intención de foco; una edición efectiva sigue limpiándolos. GREEN 1/1 y 0 issues
en `E11760B2-9899-4D07-85EA-EFC40D75EACA.txt`, resumen generado 12:59:48Z, 03/10/2026. Los originales y sus hashes
figuran en el manifest. Esa prueba acredita estado del ViewModel, no el foco, nombre o anuncio efectivos del TextField.

Los tests focales cubren completitud/normalización, ticket sin datos fiscales, compatibilidad v1/v2, rechazo de payloads
inválidos, identidad del destinatario en replay, edición/cancelación sin reserva, prefilling tardío y callbacks obsoletos,
inmutabilidad al preparar y permanencia de la venta. Esos oráculos no demuestran nombres accesibles, rotor o tacto.
POST independiente del ámbito funcional PASS; la evidencia integral sigue pendiente, sin declaración global verde.

El POST inicial detectó P2 de validación obsoleta al completar una carga suspendida tras Preparar inválido.
La corrección limpia error/validationID solo ante input distinto; dos casos gated prueban cambio/identidad,
request nil y cero reserva/escritura. Esa carrera no se aplaza a PLU-101. Previews/smoke normales se reutilizan
por impacto sin afirmar que se ejecutaron tras este último cambio no visual; AT de la respuesta tardía sigue pendiente.
El P3 documental se corrige eliminando el payload sintético duplicado de runtime-observations y actualizando manifest.

## Previews originales

[Manifest y hashes](assets/13-5/manifest.json). Cada enlace conserva el PNG original byte por byte, sin edición.
La observación visual siguiente fue comunicada por root tras inspeccionar los 18 PNG; el agente documental registra
ese resultado sin atribuirle inspección de VoiceOver, Accessibility Inspector ni scroll completo.
Root decidió reutilizar esas capturas: el guard afecta interacción y el label explícito afecta semántica, sin cambio
de layout previsto. Se añaden las dos recapturas finales del error conservando las 18 anteriores, sin editar ningún PNG.

| Superficie/estado | Large es, Light estándar | XXX Large en, Dark aumentado | AX 5 es | Observación y límite |
|---|---|---|---|---|
| Selección Ticket | [PNG](assets/13-5/selection-Large-es-Light.png) | [PNG](assets/13-5/selection-XXXL-en-Dark.png) | [Dark estándar](assets/13-5/selection-AX5-es-Dark.png) | Large/XXXL completos. AX5 requiere scroll; el valor del selector se ajusta. No prueba acceso a todos los controles tras scroll. |
| Formulario Factura | [PNG](assets/13-5/invoice-Large-es-Light.png) | [PNG](assets/13-5/invoice-XXXL-en-Dark.png) | [Light aumentado](assets/13-5/invoice-AX5-es-Light.png) | Large muestra nombre, identificación, dirección y código postal; últimos campos bajo el primer frame. AX5 muestra cabecera/instrucciones; campos y acción tras scroll pendientes. |
| Error de Factura | [PNG](assets/13-5/error-Large-es-Light.png) | [PNG](assets/13-5/error-XXXL-en-Dark.png) | [Light aumentado](assets/13-5/error-AX5-es-Light.png) | Large/es muestra error textual de identificación fiscal. AX5 no muestra campo/error en el primer frame; foco y visibilidad tras scroll pendientes. |
| Factura preparada | [PNG](assets/13-5/prepared-Large-es-Light.png) | [PNG](assets/13-5/prepared-XXXL-en-Dark.png) | [Light aumentado](assets/13-5/prepared-AX5-es-Light.png) | El resumen crece en Large/XXXL. AX5 muestra cabecera/mensaje; lectura del snapshot completo tras scroll pendiente. |
| Entrada del componente pagado | [PNG](assets/13-5/entry-Large-es.png) | [PNG](assets/13-5/entry-XXXLarge-en.png) | [Dark estándar](assets/13-5/entry-AX5-es.png) | Componente completo en los tres tamaños, nuevo botón sin recorte en estos frames. |
| Detalle pagado | [PNG](assets/13-5/sale-Large-es.png) | [PNG](assets/13-5/sale-XXXLarge-en.png) | [Dark estándar](assets/13-5/sale-AX5-es.png) | Entrada bajo el primer frame en los tres tamaños. Título histórico del detalle recortado AX5: Falla ya registrada en PLU-91, conservada sin traslado. |

Recapturas de error sobre la revisión posterior a setter/label y anterior al ajuste de prefill;
root las inspeccionó el 03/10/2026 a las 15:02:43. Se reutilizan después del prefill por impacto no visual:

| Configuración | Artefacto final | Resultado visual y límite |
|---|---|---|
| Large/es/Light/contraste estándar | [PNG final](assets/13-5/final-error-Large-es-Light.png) | Error fiscal requerido visible en texto y título Documento completo. No prueba asociación o habla con AT. |
| AX5/es/Light/contraste aumentado | [PNG final](assets/13-5/final-error-AX5-es-Light.png) | Título Documento completo; primer frame con cabecera/instrucciones. Error/campos bajo scroll; foco real y recorrido AX5 completo pendientes. |

El título nuevo más largo de Documento se corrigió en el catálogo antes de estas capturas. Las recapturas son la
evidencia vigente; no se conserva como aprobada la imagen anterior con recorte. La corrección no resuelve el título
histórico del detalle ni valida lectura completa del formulario AX5. El locale override prueba texto renderizado,
no pronunciación, formato regional ni traducción de datos introducidos por una persona.

## Smoke táctil final

R13.5 conserva observaciones originales, retest y límites. El primer intento encontró que el error desaparecía al
recibir foco y que los campos no tenían label AX. Tras la corrección focal y un arranque fresco, el retest conserva
el error antes de editar y los seis nombres españoles aparecen en el snapshot AX de RocketSim. Eso permite evaluar
el árbol consultado y foco de entrada visible, sin atribuir pruebas de habla, rotor o foco VoiceOver.

| Comprobación | Observación concreta | Artefacto conservado |
|---|---|---|
| Entrada, cancelar y reabrir | Ticket por defecto; cancelar retorna al mismo detalle pagado y permite reabrir. Observación previa a la corrección, reutilizada porque navegación no cambió; factura final abre desde el mismo detalle. | Observaciones y referencias originales 19/32 en [manifest](assets/13-5/manifest.json). |
| Factura inválida | Error fiscal textual persiste con cursor y teclado visibles, antes de introducir datos; seis campos con label AX. | [PNG final](assets/13-5/runtime-34-retest-error.png); snapshot33 original referenciado por ruta/hash, sin contenido copiado. |
| Corrección y datos | Corregir el primer campo limpia el error; los seis valores sintéticos se leen de vuelta en su campo correcto. Se hace scroll dentro del cuerpo visible antes de enfocar campos cubiertos. | Observaciones sanitizadas; snapshots35–40 originales referenciados por hashes. |
| Factura preparada | Resumen muestra exactamente los seis valores comprobados; desaparecen campos y selector editables. La inmutabilidad de la solicitud se prueba además con T13.5. | [PNG](assets/13-5/runtime-42-retest-invoice-prepared.png); snapshot41 original referenciado por hash. |
| Cerrar y preparar Ticket | Cerrar conserva detalle pagado pendiente de documento. Reabrir vuelve a Ticket; preparar Ticket muestra resumen sin formulario/destinatario fiscal. | [PNG Ticket](assets/13-5/runtime-44-retest-ticket-prepared.png); snapshot43 original referenciado por hash. |
| Cierre y retorno a Jornada | Jornada conserva la misma venta sintética pagada y pendiente de documento, sin modal abierto. | [PNG Jornada](assets/13-5/runtime-47-retest-final-jornada.png); snapshot46 original referenciado por hash. |

Las imágenes son originales sin editar y exclusivamente DEMO. La copia JSON elimina `preview_url` con token local y
el payload duplicado de destinatario; el `currentInput` contaminado del intento histórico no se importa. Las referencias
a snapshots/commands originales permanecen como rutas y hashes en el manifest, sin copiar su contenido a Git ni
los artefactos de autenticación. El manifest runtime original tiene 51 archivos y hash
`80875320f4dd5e67649f9e09576afe1e0f01f97f712a2056bc49ff8c84c461e2`.

El smoke no demuestra ausencia de llamadas a repositorio: esos oráculos pertenecen a T13.5. El flag de teclado de
RocketSim discrepó de una captura y no se usó como oráculo. Hubo entrada contaminada al enfocar campos tapados en
intentos históricos; se descartó con un arranque fresco y readback de cada campo. El cierre final se desambiguó de
Cerrar sesión por orden de lectura, sin cerrar sesión. AT, AX5 completo, otras apariencias, orientación y físico siguen
pendientes. No se realizó inspección de colas, numeración, PDF ni activación real.

## Flujos y recuperación

| Recorrido | Evidencia parcial | Pendiente concreto en PLU-101 |
|---|---|---|
| Entrada desde venta pagada → sheet | S13.5/T13.5/P13.5/R13.5; sesión única y callbacks obsoletos cercados; apertura táctil comprobada | Apertura y retorno con VoiceOver, Voice Control, Switch Control y teclado; botón bajo scroll del detalle. |
| Ticket → preparar → cerrar | S13.5/T13.5/P13.5/R13.5; sin destinatario, número ni cierre de venta; resumen táctil comprobado | Lectura de tipo/resultado, AX5 completo y anuncio real. |
| Factura → prefilling/edición | S13.5/T13.5/P13.5/R13.5; prefilling de nombre y seis campos comprobados, sin sobrescritura de edición | Autofill real, orden con AT, teclado y datos largos; seis campos alcanzables AX5. |
| Factura inválida → corregir | S13.5/T13.5/P13.5/R13.5; error persistente, cursor/teclado y corrección táctiles comprobados Large | Error tras desplazamiento AX5, anuncio sin pérdida de contexto y foco AT no oculto por teclado/sheet. |
| Preparar → resumen inmutable | S13.5/T13.5/P13.5/R13.5; seis valores exactos visibles, snapshot fiscal congelado por tests | Lectura completa, grupos/valores y anuncio del resultado con AT. |
| Cancelar/cerrar → detalle/Jornada | S13.5/T13.5/R13.5; cero reserva por tests y venta retenida; cierre/retorno táctil comprobado | Retorno al control correcto con AT y manejo de carga/respuestas tardías accesible. |

## Matriz de 55 criterios A/AA

Matriz del flujo completo definido arriba. `N/A` describe un mecanismo ausente; nunca sustituye un aplazamiento.
`Limitado`, `Pendiente` y `Falla` conservan su significado. Las referencias S13.5/T13.5/P13.5/R13.5 resuelven método,
artefacto y dispositivo/configuración/fecha en los apartados anteriores. Revisor documental: `billing_13_5_a11y_evidence`;
observación de previews: root. Esta tabla no sustituye la auditoría independiente POST ni su dictamen.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Icono de campo y controles nativos necesitan alternativa/semántica; progreso visual se acompaña de texto. | Limitado | Manual S13.5; Preview P13.5; Inspector/VoiceOver pendientes. | P13.5, 03/10/2026. | Verificar iconos decorativos y nombres en árbol accesible; PLU-101. | Registro documental; visual root. |
| 1.2.1 | N/A | Flujo sin audio/vídeo pregrabado. | Limitado | Manual S13.5, inspección de mecanismo. | S13.5, 03/10/2026. | Sin medio que evaluar; reevaluar si se introduce. | Registro documental. |
| 1.2.2 | N/A | Sin audio sincronizado pregrabado. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Sin medio que subtitular; reevaluar por impacto. | Registro documental. |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Sin vídeo que describir; reevaluar por impacto. | Registro documental. |
| 1.2.4 | N/A | Sin contenido audiovisual en directo. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Sin directo; reevaluar por impacto. | Registro documental. |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Sin vídeo que describir; reevaluar por impacto. | Registro documental. |
| 1.3.1 | Aplicable | Form/Section y encabezados agrupan selección, campos y resumen; cada TextField declara label y el resumen combina label/valor. | Limitado | Manual S13.5 final; Preview P13.5 reutilizado; Inspector/VoiceOver pendientes. | S13.5/P13.5, 03/10/2026. | Relaciones reales entre label, campo, hint y error pendientes; PLU-101. | Registro documental; visual root. |
| 1.3.2 | Aplicable | Orden declarado tipo → datos → preparar; resumen conserva orden de los seis campos. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Recorrido lineal, saltos y foco real entre superficies pendientes; PLU-101. | Registro documental; visual root. |
| 1.3.3 | Aplicable | Instrucciones y error nombran tipo/campo/acción, sin depender de posición o color. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Revisar comprensión del flujo con AT; PLU-101. | Registro documental; visual root. |
| 1.3.4 | Aplicable | No hay nuevo bloqueo de orientación; sheet/form requieren adaptación real. | Pendiente | Manual S13.5; runtime landscape/iPad pendiente. | S13.5; P13.5 solo portrait, 03/10/2026. | Landscape, iPad y multitarea/ventanas pendientes; PLU-101. | Registro documental. |
| 1.3.5 | Aplicable | Campos personales usan content types de nombre y domicilio; fiscal no inventa autofill. | Limitado | Manual S13.5; Test T13.5; entrada real pendiente. | S13.5/T13.5, 03/10/2026. | Autofill del sistema y experiencia de entrada real pendientes; PLU-101. | Registro documental. |
| 1.4.1 | Aplicable | Error, obligación y tipo se expresan textualmente; no hay señal propia solo por color. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Differentiate Without Color real pendiente; PLU-101. | Registro documental; visual root. |
| 1.4.2 | N/A | No se reproduce audio automático de la app; anuncio es petición al sistema de AT. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Sin audio propio que controlar; reevaluar por impacto. | Registro documental. |
| 1.4.3 | Aplicable | Texto y estados requieren contraste mínimo medido en sus apariencias. | Pendiente | Preview P13.5 parcial; medición/Inspector pendientes. | P13.5, 03/10/2026. | Ningún ratio inferido de PNG; cuatro apariencias finales pendientes; PLU-101. | Registro documental; visual root. |
| 1.4.4 | Aplicable | Contenido nuevo crece hasta AX5, pero capturas iniciales no cubren todos los campos/acciones; título histórico recortado. | Falla | Preview P13.5; Manual S13.5. | Large/XXX Large/AX5 P13.5, 03/10/2026. | Recorte previo del título del detalle sigue en PLU-91. Uso completo del nuevo formulario/resumen AX5 limitado, recuperar en PLU-101. | Registro documental; visual root. |
| 1.4.5 | Aplicable | Etiquetas, mensajes y snapshot se renderizan como texto real; no imágenes de texto propias. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Conservar texto real en cambios futuros; revisión integral pendiente en PLU-101. | Registro documental; visual root. |
| 1.4.10 | Aplicable | Form vertical y TextField vertical permiten adaptación; parte de datos queda bajo el primer frame. | Limitado | Manual S13.5; Preview P13.5. | P13.5 portrait, 03/10/2026. | Scroll AX5 completo, teclado, iPad y ventanas estrechas pendientes; PLU-101. | Registro documental; visual root. |
| 1.4.11 | Aplicable | Selector, campos, botones y foco necesitan contraste no textual verificable. | Pendiente | Preview P13.5 parcial; medición/Inspector pendientes. | P13.5, 03/10/2026. | Medir estados/controles en cuatro apariencias; PLU-101. | Registro documental; visual root. |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de override de esas propiedades de espaciado. | Limitado | Manual S13.5, tecnología de UI. | S13.5, 03/10/2026. | N/A por tecnología, no por falta de prueba; reevaluar si cambia. | Registro documental. |
| 1.4.13 | N/A | Sin contenido adicional propio mostrado exclusivamente al hover o foco; hints no presentan popover propio. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Reevaluar al introducir ayuda contextual por hover/foco. | Registro documental. |
| 2.1.1 | Aplicable | Selector, campos, preparar y cerrar/cancelar deben operarse con Full Keyboard Access. | Pendiente | Manual S13.5; Teclado pendiente. | S13.5, 03/10/2026. | Recorrido completo con teclado, menú y scroll pendiente; PLU-101. | Registro documental. |
| 2.1.2 | Aplicable | Entrada/salida de sheet, menú y teclado requieren ausencia de trampa. | Pendiente | Teclado/Switch Control pendientes; S13.5. | S13.5, 03/10/2026. | Verificar escape, cancelación y salida desde cada campo; PLU-101. | Registro documental. |
| 2.1.4 | N/A | No se añaden atajos de un carácter. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Reevaluar si aparecen atajos propios. | Registro documental. |
| 2.2.1 | N/A | No se impone límite temporal a selección, edición, error o resumen. | Limitado | Manual S13.5; Test T13.5 de sesión. | S13.5/T13.5, 03/10/2026. | Carga asíncrona no introduce plazo al usuario; reevaluar futuros timeouts. | Registro documental. |
| 2.2.2 | Condicional | La carga local muestra progreso nativo acompañado de texto; duración/animación dependen de runtime. | Pendiente | Manual S13.5; Test T13.5; preferencias pendientes. | S13.5/T13.5, 03/10/2026. | Verificar Reduce Motion y carga lenta/cierre accesible; PLU-101. | Registro documental. |
| 2.3.1 | Aplicable | Sin destellos ni animación propia; se mantienen transiciones y progreso nativos. | Limitado | Manual S13.5; Preview P13.5 estático. | P13.5, 03/10/2026. | Transiciones runtime y preferencias pendientes; PLU-101. | Registro documental; visual root. |
| 2.4.1 | Aplicable | Encabezados de fiscal/resumen ofrecen estructura; entrada al detalle y sheet requieren foco eficiente. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Rotor, foco inicial y acceso al botón bajo scroll pendientes; PLU-101. | Registro documental; visual root. |
| 2.4.2 | Aplicable | Título localizado Documento/Document; detalle conserva su título previo. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Anuncio de destino pendiente; recorte AX5 histórico conservado en PLU-91. | Registro documental; visual root. |
| 2.4.3 | Aplicable | Foco a primer inválido y retorno se solicitan con identidad; setter sin cambio conserva la intención de validación. | Limitado | Manual S13.5 final; Test T13.5 regresión RED1/GREEN1; VoiceOver/Teclado pendientes. | S13.5/T13.5, 03/10/2026. | Orden real y restauración tras menú/error/preparado/cierre pendientes; PLU-101. | Registro documental. |
| 2.4.4 | Aplicable | Seleccionar documento, tipo, preparar y cancelar/cerrar se nombran con contexto textual. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Lista real de acciones/nombres con AT pendiente; PLU-101. | Registro documental; visual root. |
| 2.4.5 | N/A | Este tramo es un formulario acotado de dos tipos y seis campos, sin colección extensa nueva. | Limitado | Manual S13.5, alcance del flujo. | S13.5, 03/10/2026. | No exime navegación de Jornada; reevaluar si crece la colección. | Registro documental. |
| 2.4.6 | Aplicable | Encabezados/labels persistentes nombran propósito; resumen conserva cada label. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Rotor y relación real label/valor pendientes; PLU-101. | Registro documental; visual root. |
| 2.4.7 | Aplicable | Campos y controles requieren foco de teclado visible. | Pendiente | Teclado/Inspector pendientes; S13.5. | S13.5, 03/10/2026. | Comprobar foco en cuatro apariencias y menú/sheet; PLU-101. | Registro documental. |
| 2.4.11 | Aplicable | Primer inválido puede quedar fuera del frame y cubierto por teclado o barras. | Pendiente | Preview P13.5; Teclado/VoiceOver pendientes. | AX5 P13.5, 03/10/2026. | No inferir auto-scroll del foco declarado; verificar campo/error no totalmente ocultos; PLU-101. | Registro documental; visual root. |
| 2.5.1 | N/A | Ninguna función nueva requiere gesto multipunto ni trayectoria; controles y scroll nativos. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Reevaluar si se añaden gestos requeridos. | Registro documental. |
| 2.5.2 | Aplicable | Buttons nativos sin down-event propio; cancelar no prepara/reserva por tests y retorna al detalle en smoke. | Limitado | Manual S13.5/R13.5; Test T13.5. | R13.5 Large/es/Light iPhone17/27.2, 03/10/2026. | Activación y cierre táctiles comprobados; operación/cancelación con AT pendiente en PLU-101. | Registro documental; runtime agent/root. |
| 2.5.3 | Aplicable | Nombre de campo explícito usa su label visible; botón/selector conservan nombre textual nativo. | Limitado | Manual S13.5 final; Preview P13.5 reutilizado. | S13.5/P13.5, 03/10/2026. | Seis labels de TextField observadas en AX/R13.5; Inspector y Voice Control por nombre pendientes; PLU-101. | Registro documental; visual root. |
| 2.5.4 | N/A | Sin activación por movimiento del dispositivo. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Reevaluar si se introduce agitar/mover. | Registro documental. |
| 2.5.7 | N/A | Sin función que requiera arrastrar; edición/selección se operan con controles nativos. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Scroll no añade una tarea de arrastre propia; reevaluar por impacto. | Registro documental. |
| 2.5.8 | Aplicable | Campos, selector y preparar declaran mínimo44pt; toolbar y superficie efectiva requieren medir. | Limitado | Manual S13.5; Preview P13.5; medición pendiente. | P13.5, 03/10/2026. | Evaluar 24 CSS px con WCAG2ICT y, por separado, política44×44pt; PLU-101. | Registro documental; visual root. |
| 3.1.1 | Aplicable | Texto nuevo es/en en catálogo; locale de anuncio se toma del entorno. | Limitado | Test T13.5 localizaciones; Manual S13.5; Preview P13.5. | es/en P13.5, 03/10/2026. | Pronunciación y lengua real con AT pendientes; PLU-101. | Registro documental; visual root. |
| 3.1.2 | Condicional | Nombre/domicilio introducidos o prefilling pueden contener otro idioma. | Pendiente | Manual S13.5; pronunciación pendiente. | S13.5, 03/10/2026. | Evaluar cambios de idioma expresables y lectura de datos; PLU-101. | Registro documental. |
| 3.2.1 | Aplicable | Enfocar no prepara ni cambia pantalla por lógica propia. | Limitado | Manual S13.5; Test T13.5. | S13.5/T13.5, 03/10/2026. | Operación real al entrar/salir de campo/menú pendiente; PLU-101. | Registro documental. |
| 3.2.2 | Aplicable | Cambiar tipo muestra campos/instrucciones; editar no emite documento; preparar exige acción explícita. | Limitado | Manual S13.5; Test T13.5; Preview P13.5. | S13.5/T13.5/P13.5, 03/10/2026. | Comunicación accesible del cambio de tipo y desaparición de campos pendiente; PLU-101. | Registro documental; visual root. |
| 3.2.3 | Aplicable | Nuevo sheet mantiene navegación/cancelación nativas y Form coherente con el detalle. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Recorrido comparado con AT y restauración pendiente; PLU-101. | Registro documental; visual root. |
| 3.2.4 | Aplicable | Controles fiscales, tipo y cancelar/cerrar usan títulos y función consistentes. | Limitado | Manual S13.5; Test T13.5 de catálogo; Preview P13.5. | P13.5/T13.5, 03/10/2026. | Nombres/roles efectivos pendientes en Inspector/AT; PLU-101. | Registro documental; visual root. |
| 3.2.6 | N/A | El tramo no incorpora mecanismos propios repetidos de ayuda/contacto; instrucciones están junto al formulario. | Limitado | Manual S13.5. | S13.5, 03/10/2026. | Reevaluar al añadir ayuda compartida; no N/A por aplazamiento. | Registro documental. |
| 3.3.1 | Aplicable | Primer vacío tiene mensaje/hint/foco/anuncio declarados; setter sin cambio conserva error; retest visual/AX confirma persistencia antes de editar. | Limitado | Manual S13.5/R13.5; Test RED1/GREEN1; 2 Preview error P13.5 finales. | R13.5 Large/es/Light iPhone17/27.2 y P13.5, 03/10/2026. | Error final visible Large con cursor/teclado; AX5 inicial no muestra error. Asociación y habla AT pendientes; PLU-101. | Registro documental; runtime agent/root. |
| 3.3.2 | Aplicable | Seis etiquetas persistentes y obligación explicada; ticket informa que no necesita datos fiscales. | Limitado | Manual S13.5; Preview P13.5. | P13.5, 03/10/2026. | Lectura/operación de todos los campos con AT pendiente; PLU-101. | Registro documental; visual root. |
| 3.3.3 | Aplicable | Error solicita completar campo concreto; corrección táctil limpia error y conserva valor; sin checksum/consejo fiscal. | Limitado | Manual S13.5/R13.5; Test T13.5; Preview error P13.5. | R13.5 Large/es/Light iPhone17/27.2, 03/10/2026. | Corrección funcional comprobada; corrección, foco y resultado con AT pendientes; PLU-101. | Registro documental; runtime agent/root. |
| 3.3.4 | Aplicable | Preparar verifica datos y muestra seis valores; no emite/reserva por tests; cerrar conserva venta pagada pendiente. | Limitado | Test T13.5; Manual S13.5/R13.5; Preview P13.5. | R13.5 Large/es/Light iPhone17/27.2, 03/10/2026. | Revisión/cierre táctiles comprobados; revisión con AT y futura emisión/legal requieren evaluación; PLU-101. | Registro documental; runtime agent/root. |
| 3.3.7 | Aplicable | Prefilling local opcional no pisa edición; error conserva entrada, snapshot evita relectura mutable del cliente. | Limitado | Test T13.5; Manual S13.5. | S13.5/T13.5, 03/10/2026. | Verificar prefilling/edición completos y no reentrada innecesaria con AT; PLU-101. | Registro documental. |
| 3.3.8 | N/A | El nuevo tramo no añade autenticación, prueba cognitiva ni recuperación de credenciales. | Limitado | Manual S13.5, alcance. | S13.5, 03/10/2026. | No aprueba autenticación existente; reevaluar si cambia el gate. | Registro documental. |
| 4.1.2 | Aplicable | Nombre explícito de seis TextFields confirmado en snapshot AX; resumen muestra seis labels/valores, sin edición. | Limitado | Manual S13.5/R13.5 con AX RocketSim; Preview P13.5; Inspector/AT pendientes. | R13.5 Large/es/Light iPhone17/27.2, 03/10/2026. | Snapshot consultado confirma nombres; Inspector, roles/estados/acciones completos y operación AT pendientes; PLU-101. | Registro documental; runtime agent/root. |
| 4.1.3 | Aplicable | Carga textual y anuncio declarado de error/indisponibilidad/preparación; setter sin cambio retiene validación. | Pendiente | Manual S13.5 final; Test T13.5 regresión RED1/GREEN1; VoiceOver pendiente. | S13.5/T13.5, 03/10/2026. | Verificar habla, repetición de errores y resultado sin pérdida de foco/contexto; PLU-101. | Registro documental. |

## Política de objetivos y pendientes integrales

La política del proyecto de **44×44 pt** es independiente del criterio WCAG 2.5.8 y su unidad de 24 CSS px. Los mínimos
de altura declarados y una captura no acreditan superficie operable, ancho, separación ni riesgo de activación accidental.
No se ha concedido excepción nueva: medir campos, selector, preparar, entrada y toolbar en runtime, documentando por
separado cualquier excepción normativa y cualquier excepción de proyecto en PLU-101.

PLU-101 debe recuperar: Inspector; VoiceOver (orden, rotor, foco inicial/retorno, errores, carga y resultado); Voice
Control por nombre; Switch Control cuando lo requiera el flujo; Full Keyboard Access y foco no oculto; autofill real;
contraste textual/no textual medido en cuatro apariencias; Increase Contrast, Reduce Motion, Reduce Transparency y
Differentiate Without Color; portrait/landscape; iPad/multitarea/ventanas; RTL y datos largos; recorrido completo AX5
con scroll y teclado; dispositivo físico. Cada ensayo debe registrar configuración/build, resultado y artefacto; un
participante de demo que necesite AT exige comprobar esa tecnología antes de su demo según ADR0029.

El recorte histórico del título AX5 del detalle permanece **Falla en PLU-91**. Esta subfase solo recuperará por PLU-101
la evidencia de la nueva selección, formulario, errores, resumen y cruces de foco. Ningún resultado previo se declara
corregido, cerrado ni transferido. El uso completo AX5 y la matriz exhaustiva quedan pendientes, aunque los previews
representativos hayan renderizado correctamente. Antes del primer candidato para uso real se completará toda evidencia
aplicable, se corregirán los defectos y se obtendrá revisión independiente.

## Dictamen POST del ámbito funcional

Ambos revisores independientes dan PASS de implementación/funcionalADR0029 tras resolver el P2 de prefill y
los P3 de sanitización/procedencia. Code/validación revisados en freeze973 `43b4571ed242ef1ef6d463d83767666e07152fc88101b60ead3689413e11e84b`;
metadata y UI/accesibilidad focal en freeze973 inicial/final/revisores/root idéntico
`7f7d1aa7040c4c0cb2cce8fa791258fe8052b8e3d5e7aeed4fe46fb58d741d1b`, sin hallazgos nuevosP0–P3.
Solo se registra este resultado después del freeze; fuentes32Swift/configuración/PNG intactos.
La global final sigue fallando2581/2582 en Stock; no acredita regresión global verde ni entrega. Los55criterios
conservan44Limitado/10Pendiente/1Falla histórica, sin convertir aplazamientos enPASS. PLU-101/PLU-91 y
recuperación integral antes del candidato real intactos. Nuevos renders/interacción/AT: N/A para metadata.
