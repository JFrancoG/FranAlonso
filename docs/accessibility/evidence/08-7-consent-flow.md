# Evidencia 08.7 — Lectura, revisión, firma y recuperación

Fecha inicial: 2026-09-13. Actualización manual: 2026-09-28. PLU-41. Implementación y revisión estática/visual completadas; validación runtime parcial con fallos de foco y anuncio pendientes. No acredita conformidad jurídica ni certificación.

## Disposición vigente tras ADR 0029 — 2026-09-28

[PLU-44](https://linear.app/plusprojects/issue/PLU-44) organiza la validación integral aplazada de este registro,
relacionada con la entrega funcional PLU-41 y bajo fase 08. Responsable: Jesus Franco. Retomar tras incorporar el
feedback de Fran y estabilizar cada flujo F01–F05; completar antes del primer candidato para uso real. Conforme a
[ADR 0029](../../ADRs/0029-progressive-accessibility-validation.md), esta deuda no bloquea por sí sola la entrega
funcional para demo, pero sí el cierre integral y el uso real. PLU-41 publicada en rama el29/09, sin integrar ni cerrar.

- **Fallos conocidos:** foco de entrada/restauración (2.4.3), anuncio interrumpido (4.1.3) y descubribilidad del
  error/reintento reportada. Las correcciones locales no acreditan su resolución. La entrada sigue fallando en el
  último binario; cancelación, confirmación/anuncio y reintento conservan su retest pendiente y los fallos previos.
- **Evidencia pendiente/limitada:** Inspector, rotor/semántica, transiciones y tecnologías aplicables restantes,
  mediciones de contraste nativo, preferencias/variantes y operación accesible de F01–F05 según las filas inferiores.
- **Evidencia conservada:** FKA del botón principal en cuatro apariencias, legibilidad textual, lectura AX5/ventana
  mínima y las acciones/recorridos parciales ya aceptados. Repetir solo por impacto del cambio, sin extender su alcance.
- **Fuera del aplazamiento:** integridad, invalidación, recuperación y errores funcionales siguen siendo gate de PLU-41;
  la recuperación en una fixture en memoria no prueba un reinicio durable. PLU-38 conserva sus pendientes propios.

Esta disposición cambia la secuencia de validación, no los resultados de las 55 filas ni las evidencias históricas.
Las instrucciones de retest/cierre de las anotaciones anteriores se interpretan con este nuevo momento de recuperación;
ningún `Falla`, `Pendiente` o `Limitado` se convierte en `Pasa` o `N/A` por aplazarse.

## Smoke funcional de preparación — 2026-09-28

Subagente con skill Apple device-interaction; iPad Air11M4 Simulator27.0, portrait, fixture signed-out no-live,
datos sintéticos. Jerarquía y captura inspeccionadas después de cada interacción. Sin nuevas pruebas de AT.

- Lectura/revisión personal, abrir captura y cancelar: Firmar vuelve visible/habilitado en la misma posición y=709.
- Dibujar/confirmar, conservar y provocar envío no disponible: firma, estado conservado y error textual visibles.
- Reintentar de nuevo y guardar/reabrir/reanudar: una ficha, mismo nombre/firma/fecha y reintento operable.
- Al aparecer error, Reintentar baja80,5pt fuera del viewport inicial; scroll corto lo muestra y permite activarlo.
  Operación táctil favorable no resuelve foco ni descubribilidad con AT: PLU-44 conserva esos pendientes.
- Invalidación y cancelar salida con cambios no repetidos en esta pasada. Se conserva la evidencia previa sin
  ampliar su alcance; el último recorrido sigue pendiente donde no hubo confirmación. Reabrir dentro del mismo
  proceso no demuestra reinicio durable. Se reutilizan previews previas Large/XXX Large/AX5 por impacto.

Artefactos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/DeviceInteractionSynthesize/`,
prefijo `Consent Functional Smoke-`, sufijos `-hierarchy.txt` y `-screenshot.png`:
`23_21_04_853` cancelación; `23_21_45_517` firma; `23_21_54_045` conservación; `23_22_01_125` error;
`23_22_16_386` reintento; `23_23_01_142` recuperación. No se convierten filas de la matriz a PASS.
La corrección posterior de aceptación concurrente cambia solo Data y sus tests; este smoke corresponde a la UI
limpia anterior a ese guard. Los dos recorridos integrados de formulario y la suite final validan el guard.

## Pasada física en curso — 2026-09-28

Método: ejecución por el usuario en iPhone 11 físico y resultados comunicados en el chat; sin observación
directa ni grabación por el agente. Versión exacta de iOS no registrada. Estos resultados no cierran
criterios completos de la matriz ni acreditan las tecnologías todavía no probadas.

- F01: consultar información con nombre vacío abre el documento. El usuario confirma recorrido completo
  con VoiceOver sin elementos omitidos o nombres extraños percibidos; rotor de encabezados no comprobado.
- F01: código postal sintético `28001` conservado al consultar y volver; VoiceOver regresa a
  «Consultar información, botón». La instrucción inicial de introducir correo se corrigió: ese campo no
  existe en este formulario y no se atribuye evidencia a él.
- F02: revisión personal muestra el nombre sintético `Prueba 087`. Al abrir, VoiceOver anuncia y enfoca
  «Volver a la ficha, botón», aunque la pantalla solicita foco en el título. Pendiente de diagnóstico/retest.
- F02: cancelar captura sin firma regresa al documento, pero VoiceOver enfoca «Volver a la ficha, botón»
  en vez de la acción para firmar. Fallo de restauración de foco confirmado por el usuario.
- F02: tras dibujar con VoiceOver temporalmente desactivado, reactivarlo y confirmar la firma, comienza
  un anuncio no identificado que se corta rápidamente; VoiceOver anuncia «Volver a la ficha, botón» y
  permanece allí. No se acredita el anuncio completo de guardado ni el foco en la acción de aceptación.
  Fallos pendientes relativos a 2.4.3 y 4.1.3; causa técnica todavía no determinada.

- F03: el usuario confirma que cambiar el nombre sintético a `Prueba 087 Modificada` actualiza el documento
  y exige firmar otra vez; no permite conservar el texto nuevo con la firma anterior.
- F02: tras una nueva firma y el paso de conservación, el usuario observa como única acción del documento
  «Reintentar envío». Esto concuerda con el estado retenido de la implementación, pero no se confirmó
  literalmente el mensaje de conservación ni una locución completa. El usuario percibe lectura de nombre
  y apellidos y otros datos; no identifica visualmente el foco final. No se marca PASS de anuncio/foco.
- F04: al pulsar «Reintentar envío», el usuario observa salto hacia arriba y conserva disponible la acción.
  Inicialmente no localiza ningún cambio; después confirma un aviso de error situado muy arriba.
  La presencia del error queda acreditada por su reporte, no su texto literal. Revisar descubribilidad
  del error y desplazamiento asociado; integridad del documento recuperado aún pendiente.

- F04: tras guardar la ficha, volver al listado, abrirla y reanudar el documento, el usuario confirma
  nombre modificado, firma y acción «Reintentar envío» recuperados sin refirmar. Evidencia dentro de la
  misma ejecución de la app; no acredita persistencia tras terminar el proceso de la fixture en memoria.
- F05: editar el nombre a `Cambio sin guardar` e intentar salir presenta confirmación; el usuario
  identifica una única acción visible, «Salir sin guardar». Tras activarla, reabrir la ficha y reanudar
  el documento, confirma que permanecen el nombre anterior y la firma. Cancelar la confirmación y
  descartar un borrador de documento son recorridos distintos aún no probados en esta pasada.

- Control por voz: el usuario confirma que «Tocar Volver a la ficha» y «Tocar Consultar información»
  activan ambas acciones por su nombre, sin tocar la pantalla. No se extiende a otras acciones.
- Texto de accesibilidad al máximo (AX5, según los pasos indicados): el usuario confirma lectura íntegra
  del documento en iPhone 11, sin cortes percibidos. No se acredita con esta respuesta cada acción final.
- Con ese tamaño, «Volver a la ficha» se representa mediante icono de cerrar. El usuario confirma que
  VoiceOver anuncia «Volver a la ficha, botón» y que el doble toque regresa al formulario.
- Orientación: el usuario informa de que la app permanece en portrait en iPhone. No se registra PASS
  horizontal; comportamiento/configuración de orientación y recorrido en iPad pendientes de comprobar.

### Pasada en simulador de iPad — 2026-09-28

Método: ejecución por el usuario y confirmaciones en el chat. Modelo y versión exacta del simulador
no registrados; evidencia independiente de la pasada física anterior y de las previews del 13 de septiembre.

- Revisión de documento con nombre sintético `Prueba iPad 087`: el usuario confirma giro a horizontal,
  recorrido hasta el final y texto/botones completos sin superposición.
- Ventana de la app reducida al mínimo permitido por la multitarea: el usuario confirma que todos los
  textos y botones se ven completos. No se ha medido el ancho en puntos.
- Misma ventana mínima y texto de accesibilidad al máximo, siguiendo las instrucciones de AX5:
  el usuario confirma lectura y acceso a los botones sin cortes ni superposiciones.
- Acceso total con teclado: el usuario confirma acceso a las acciones de volver a la ficha y consultar
  información. Precisa que navega con cursores y entra en grupos con Intro; para activar botones se
  utiliza Espacio. Confirma apertura de captura y cancelación con retorno al documento sin ratón.
- Foco con teclado: el usuario confirma que se ve, pero en «He revisado el texto; firmar» apenas se
  distingue sobre el fondo morado; en «Revisar la versión actual» y «Descartar borrador del documento»,
  de fondos más claros, se distingue mejor. Refiere sutileza del resaltado de elementos dentro de grupos
  también en una prueba anterior, sin atribuir aquí evidencia independiente a aquella prueba.
  Hallazgo pendiente de diagnóstico y medición respecto a 2.4.7/1.4.11; no se declara incumplimiento
  cuantificado ni se considera suficiente la mera posibilidad de alcanzar/activar la acción.
  Captura aportada: `/Users/jesusf/Desktop/Captura de pantalla 2026-09-28 a las 18.17.20.png` identifica
  las acciones y apariencia; no se usa por sí sola para medir el contraste del indicador enfocado.
- Al activar Aumentar contraste, el usuario percibe algo más el foco del botón principal porque su texto
  pasa de oscuro a claro y el cambio se aprecia. Mejora subjetiva, sin medición ni cierre del hallazgo.
- Tras pasar a modo oscuro, el usuario informa de que el foco del mismo botón no se aprecia y su texto
  vuelve a ser oscuro. Se había indicado mantener Aumentar contraste, pero no hay captura/verificación
  directa de los ajustes. Aunque el paso propuesto incluía desactivar Acceso total con teclado, el reporte
  describe explícitamente el botón al tomar foco; el estado exacto del ajuste no se da por verificado.
  No se registra PASS de apariencia oscura ni de contraste. Pendiente distinguir legibilidad del texto
  sin foco de la perceptibilidad del indicador, medir el render nativo y corregir/revalidar lo aplicable.
- Aclaración final del usuario: el texto del botón principal se lee bien siempre, con y sin foco y en
  todos los modos probados. El hallazgo se limita al indicador de foco: solo percibe un cambio ligero
  del texto cuando es claro. Los otros botones muestran el foco mejor en claro y oscuro. Esta aclaración
  descarta la sospecha de ilegibilidad textual anterior; no sustituye mediciones de contraste.

### Corrección local posterior — pendiente de retest

- Acciones principales del consentimiento con estilo nativo bordered, tamaño grande y peso semibold;
  no se modifica PrimaryActionStyle compartido ni el componente de captura 08.4.
- Foco VoiceOver centralizado en ClientConsentScreen, default contextual con accessibilityDefaultFocus
  (iOS 26), consumido una sola vez al coincidir fin de operación y cierre efectivo de captura.
  Resultados/error relevantes con anuncio de prioridad alta; sin temporizadores.
- Error/progreso junto a las acciones. Reintentar envío conserva identidad y presencia durante la operación,
  pero permanece deshabilitado mientras envía. La existencia usa hasUploadAction y la ejecución canUpload.
- RED conductual del test de envío suspendido: 1 fallo esperado; GREEN de Store: 19 resultados PASS
  (incluidos parámetros), sin fallos/omitidos. Build final Xcode MCP PASS 11,324 s; aviso AppIntents conocido.
- Dos revisores independientes read-only: estándares PASS; UI/estilo PASS estático y visual con seis
  previews finales. Huellas pre/post idénticas; artefactos y fuentes en phase-08.md.
- Ningún resultado manual anterior se atribuye a esta corrección. Repetir entrada/cancelar/confirmar y
  anuncio con VoiceOver, reintento y foco FKA en cuatro apariencias. Inspector/contraste medido y las
  restantes variantes no ejecutadas continúan pendientes. No se cierra 08.7.

### Retest manual del foco FKA tras la corrección — 2026-09-28

En el simulador de iPad, tras relanzar la versión corregida, el usuario confirma que distingue el foco
de «He revisado el texto; firmar» con el nuevo estilo. Confirma después las cuatro combinaciones:
claro/oscuro con contraste normal/incrementado, moviendo el foco entre los botones sin firmar.
Se cierra el hallazgo manual de perceptibilidad de esa acción en estas configuraciones; no constituye
medición de ratios ni validación de todas las acciones/tecnologías. Retest VoiceOver y envío aún pendientes.

### Retest de entrada VoiceOver tras la corrección — 2026-09-28

Siguiendo la instrucción de ejecutar la versión nueva en iPhone11, crear `Retest 087` y activar VoiceOver
antes de revisar, el usuario reporta «Nombre obligatorio» casi interrumpido, seguido de «Volver a la ficha,
botón». El foco permanece en ese botón superior izquierdo, antes de «Información del cliente».
La corrección con accessibilityDefaultFocus no resuelve este caso observado: el hallazgo de foco inicial
sigue abierto. No se interpreta la locución como un error real de validación del nombre sin diagnóstico.
El retest de cancelación también falla: el usuario vuelve a oír «Volver a la ficha, botón».
Confirmación de captura, anuncios finales y reintento en esta versión aún no comprobados.

### Diagnóstico y segunda corrección focal — 2026-09-28

Revisión independiente identifica dos interferencias: el formulario reanuncia errores previos y solicita foco detrás
del documento presentado; las acciones de revisión desaparecen al pasar a captura. Se conserva el error del formulario,
pero su pantalla ya no emite feedback mientras el consentimiento está presentado. Firmar y Revisar la versión actual
permanecen en el árbol durante captura, deshabilitados. Sin esperas arbitrarias ni cambios en el estilo FKA validado.

Inspección directa mediante Xcode DeviceInteraction, iPad A16/iOS27.2, ventana475×634,5, datos sintéticos:
antes del arreglo, cancelar mueve Firmar de y502,5 a y641 y deja el texto fuera del viewport; una recaptura confirma
que persiste. Tras conservar Firmar, el botón queda completamente visible y habilitado (y418,5 antes, y492,5 después).
El salto residual74pt coincide con la eliminación de Revisar la versión actual; se conserva también ese control en
el último delta. Su estabilidad final aún no se ha comprobado en runtime. No se atribuye `Focused` a VoiceOver ni
se infiere locución de la jerarquía. El foco físico sigue pendiente; 2.4.3 y4.1.3 mantienen Falla.

Artefactos `DeviceInteractionSynthesize/Consent Focus Inspection-` bajo el directorio ActionArtifacts indicado abajo:
baseline `20_07_10_861`, `20_07_46_718`, `20_07_59_079`; retest parcial `20_11_42_077`, `20_11_55_528`,
`20_12_08_569` (jerarquías y screenshots). Sesión cerrada; build final y auditorías detalladas en fase08.

Pendiente completar las variantes restantes de F04–F05 y el resto de la matriz; corregir los fallos
y repetir las transiciones afectadas antes del cierre.

### Retest físico de la segunda corrección y diagnóstico pendiente — 2026-09-28

El propietario ejecuta el binario nuevo en iPhone11, crea Retest087 y activa Revisar y firmar con VoiceOver.
Entrada: «Volver a la ficha, botón». Abre captura sin dibujar y cancela: vuelve a anunciar el mismo botón.
Ambas transiciones siguen fallando; la mejora estructural del scroll no demuestra corrección de foco.

Se prepara instrumentación temporal Debug-Develop, habilitada por `--franalonso-consent-focus-diagnostics`.
Registra eventos de ciclo de vida, peticiones y binding de foco, enums de presentación y booleanos; sin datos de negocio.
El binding diagnóstico del botón Volver modifica el árbol instrumentado: no se considera observación externa ni arreglo.
Sin timers ni cambios de coordinación. PRE/POST independientes favorables para diagnóstico, no cierre funcional.
Build17,515s; RunProject físico3,392s correcto, sesión `7bbdf2d380`. Traza del recorrido aún pendiente.
Retirar instrumentación y argumento antes de entrega, conservando la fixture activada por el propietario.

### Traza física y experimento de región — 2026-09-28

Entrada y cancelación instrumentadas siguen anunciando «Volver a la ficha, botón» según el propietario.
Consola filtrada de sesión7bbdf2d380, 33eventos, guardada sin payload en
`/tmp/franalonso-consent-focus-trace-20260928.txt`: 22binding=nil; 24–25 procesa cancelación y vuelve a review
con canCapture=true; 26–27 aplaza feedback; 28onDismiss; 29–30 pide foco capture; 33binding=capture.
No falta la petición de retorno ni se hace sobre un valor ya idéntico. No se observa consent.disappeared.
El binding no acredita el destino audible. Los timestamps de stdout llegan agrupados y no prueban duraciones;
el observador registra el estado leído, no los argumentos old/new de cada cambio.

Experimento aislado aprobado por revisión independiente: mover únicamente accessibilityDefaultFocus de NavigationStack
al VStack que contiene los destinos, siguiendo la estructura del ejemplo Apple. Instrumentación y secuencia se conservan.
Build9,195s, RunProject físico3,350s, nueva sesión `7bbdf2eb80`; locución/foco de esta variante aún pendientes.
No se considera corrección demostrada ni se cierran los fallos.

### Resultado de región y restauración con evento nativo — 2026-09-28

La variante de región en VStack también falla en entrada y cancelar: el propietario oye Volver a la ficha.
Traza sesión7bbdf2eb80/PID14297, 29eventos, `/tmp/franalonso-consent-focus-scoped-trace-20260928.txt`:
entrada2binding=back; cancelar24onDismiss, 26petición capture, 29binding=back. Ya coincide con la locución,
pero no demuestra si capture llegó a recibir foco brevemente. No se infieren duraciones de timestamps agrupados.

Nueva remediación sometida a PRE/POST: observar ElementFocusedMessage de UIKit mediante NotificationCenter tipado
MainActor (iOS26). Consumir una única intención con el primer evento real, incluso elemento desconocido/nil;
corregir solo si corresponde al retorno de esta instancia. Otro elemento, otra acción, desaparición o desactivar
VoiceOver descartan la intención. No hay bucle de corrección, espera ni foco diferido al navegar posteriormente.
Identificador efímero de UI comparado localmente; sin labels, payloads ni identificadores de negocio en logs.

Política pura validada con Swift Testing: RED2fallos/3controles, GREEN5PASS. Build físico14,306s y
RunProject3,434s correctos, nueva sesión7bbdf01e00/PID14409. Auditorías estáticas de UI y estándares favorables.
No prueban que UIKit exponga el identificador esperado ni que VoiceOver acepte la petición. Retest físico pendiente;
2.4.3 y4.1.3 siguen Falla. Instrumentación temporal conserva su obligación de retirada antes de entrega.

### Reconocimiento del elemento nativo — 2026-09-28

Primera entrada con observador nativo: el propietario oye Volver a la ficha y observa un destello breve.
Sesión7bbdf01e00/PID14409, cinco eventos: preparación, aparición, dos native.otherFocused y binding=back;
no hay focus.requested. Traza en `/tmp/franalonso-consent-native-entry-trace-20260928.txt`. No se atribuye
el destello a un foco transitorio sin evidencia.

Inspección pública por LLDB del elemento actualmente enfocado: no conforma nominalmente a
UIAccessibilityIdentification, pero el getter público accessibilityIdentifier sobre AnyObject devuelve un identificador
con el prefijo de nuestro retorno. Solo se consultaron tipo y booleanos, sin etiquetas ni valores de identificador.
Se corrige el clasificador usando el getter opcional de message.element, conservando comparación exacta y consumo único.
El elemento consultado después no prueba qué contenían los dos eventos anteriores.

PRE/POST UI y estándares favorables; build físico9,103s y RunProject3,500s correctos.
Nueva ejecución PID14573, referencia7bbdf2d380 reutilizada por Xcode: distinguirla de la ejecución anterior con esa
referencia por PID. Retest del propietario: «volver a la ficha botón». La traza de esta misma ejecución contiene
native.otherFocused (3), native.returnFocused (4) y binding=back (5), sin focus.requested. El getter reconoce
ahora el retorno, pero el primer evento ya consumió la intención. No conocemos el elemento del evento3;
no se atribuye a navegación voluntaria ni a una transición automática. Entrada sigue Falla; cancelación pendiente
en este binario, sin repetir pruebas de legibilidad o teclado ya aceptadas.

## Flujo completo y superficies

Esta matriz evalúa conjuntamente ClientFormScreen, ClientConsentScreen y sus componentes de documento,
acciones y recuperación, incluidos pasos y sheets entre pantallas. La captura reutilizada conserva su
[matriz 08.4](08-4-signature-capture.md); se prueban aquí sus transiciones nuevas, sin repetir controles ya aceptados.

- F01: formulario inválido o válido → consultar información → volver; revisión personal → lectura completa.
- F02: revisión sin foto o fixture con decisión opcional → captura → cancelar/confirmar → revisión de firma → conservar.
- F03: volver a editar → invalidación según datos incluidos → reabrir; selección de varios borradores/perfil diferente.
- F04: fallo de guardado/render/envío → acción recuperable; documento aceptado; logout y retirada de contenido.
- F05: confirmación de descarte de ediciones o de borrador; conserva ficha y cola aceptadas.

Métodos: las pruebas Swift Testing verifican estado y efectos; las previews verifican solo render estático.
Inspector, VoiceOver, Voice Control, Switch Control y Full Keyboard Access nuevos permanecen pendientes hasta ejecutarlos.
No se atribuye evidencia física ni medición de contraste a una preview. Los pendientes propios de PLU-38 siguen separados.

## Registro por criterio del recorrido completo F01–F05

Todas las filas se aplican al recorrido unido y a sus superficies cuando contienen la función indicada.
N/A describe únicamente elementos ausentes de este cambio; no certifica el resto de la aplicación.

| ID | Aplicabilidad | Justificación y alcance | Resultado | Método y artefacto | Hallazgo y disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Lector con texto nativo; firma con alternativa de estado. Validar árbol accesible. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.2.1 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | Estática | Sin recorrido aplicable |
| 1.2.2 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | Estática | Sin recorrido aplicable |
| 1.2.3 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | Estática | Sin recorrido aplicable |
| 1.2.4 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | Estática | Sin recorrido aplicable |
| 1.2.5 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | Estática | Sin recorrido aplicable |
| 1.3.1 | Aplicable | Secciones, encabezados y metadatos del texto firmado. Validar rotor. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.3.2 | Aplicable | Orden formulario, lector, decisiones, captura y resultado. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.3.3 | Aplicable | Instrucciones y errores textuales. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.3.4 | Aplicable | Validar orientación y ventana de lector y recuperación. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.3.5 | Aplicable | Los campos personales de 08.3 se conservan; verificar integración. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.1 | Aplicable | Decisiones y errores deben incluir texto/estado, además de color. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.2 | N/A | No se reproduce audio automático. | Limitado | Estática | Sin recorrido aplicable |
| 1.4.3 | Aplicable | Medir texto en las cuatro apariencias del render nativo nuevo. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.4 | Aplicable | Large/XXX Large/AX5 del texto íntegro y de todas las acciones. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.5 | Aplicable | Texto jurídico nativo; firma vectorial esencial, no imagen del texto. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.10 | Aplicable | Scroll vertical, ancho estrecho e iPad multitarea. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.11 | Aplicable | Medir controles, firma y foco en cuatro apariencias. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de espaciado de autor. | Limitado | Estática | Sin recorrido aplicable |
| 1.4.13 | N/A | No se incorpora contenido al hover ni ayudas dependientes del foco. | Limitado | Estática | Sin recorrido aplicable |
| 2.1.1 | Aplicable | Teclado en acciones y transición; la trayectoria conserva excepción ADR0027. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.1.2 | Aplicable | Entrar/salir de lector, captura y confirmación sin trampa. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.1.4 | N/A | No se añaden atajos de caracteres simples. | Limitado | Estática | Sin recorrido aplicable |
| 2.2.1 | N/A | Lectura y decisión sin límite de tiempo. | Limitado | Estática | Sin recorrido aplicable |
| 2.2.2 | Aplicable | Estado asíncrono finito, cancelable; sin avance automático de lectura. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.3.1 | Aplicable | Sin destellos ni medios parpadeantes añadidos. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.4.1 | Aplicable | Encabezados del texto largo y foco inicial del lector. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.4.2 | Aplicable | Título visible y accesible en lector y selección recuperada. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.4.3 | Aplicable | Foco de entrada, ida/vuelta de firma, error y confirmación. | Falla | VoiceOver físico reportado por el usuario el28/09 | Corrección local validada estáticamente; retest runtime pendiente |
| 2.4.4 | Aplicable | Acciones distinguen revisar, firmar, conservar y enviar. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.4.5 | N/A | Recorrido secuencial acotado; listado y búsqueda de clientes no cambian. | Limitado | Estática | Sin recorrido aplicable |
| 2.4.6 | Aplicable | Encabezados íntegros y opciones recuperadas distinguibles. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.4.7 | Aplicable | Foco visible con teclado en cada acción. | Limitado | FKA iPad reportado por el usuario el28/09 | Hallazgo del botón principal resuelto: retest en cuatro apariencias favorable; alcance restante no inferido |
| 2.4.11 | Aplicable | Scroll y sheets no ocultan el elemento enfocado. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.5.1 | Aplicable | Buttons nativos; trayectoria de firma según ADR0027, sin nueva excepción. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.5.2 | Aplicable | Acciones por activación nativa, captura cancelable. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.5.3 | Aplicable | Probar Voice Control con el nombre visible de las acciones nuevas. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.5.4 | N/A | No hay activación por movimiento del dispositivo. | Limitado | Estática | Sin recorrido aplicable |
| 2.5.7 | Aplicable | Nuevas acciones no requieren arrastre; tinta conserva ADR0027. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 2.5.8 | Aplicable | 44x44 pt y separación de todas las acciones nuevas; medición runtime. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.1.1 | Aplicable | App es; contenido conserva idioma del snapshot. Probar pronunciación. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.1.2 | Aplicable | Idioma de documento independiente de locale de controles. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.2.1 | Aplicable | Enfocar no guarda, firma ni navega. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.2.2 | Aplicable | Decisiones explícitas; scroll/tiempo no acreditan lectura. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.2.3 | Aplicable | Patrones nativos consistentes con formulario/captura existentes. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.2.4 | Aplicable | Misma acción con misma etiqueta en cada estado. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.2.6 | N/A | No se incorpora un mecanismo de ayuda repetido. | Limitado | Estática | Sin recorrido aplicable |
| 3.3.1 | Aplicable | Validación, persistencia, render, conflicto y envío con error textual. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.3.2 | Aplicable | Metadatos y decisión opcional con instrucciones persistentes. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.3.3 | Aplicable | Acción recuperable junto al error; conflicto terminal sin reintento engañoso. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.3.4 | Aplicable | Revisión previa, firma, aceptación y descarte explícitos. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.3.7 | Aplicable | Recuperación conserva perfil/tinta válidos; no pide refirmar sin invalidación. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 3.3.8 | N/A | No cambia la entrada de autenticación; solo se revoca contenido al perder acceso. | Limitado | Estática | Sin recorrido aplicable |
| 4.1.2 | Aplicable | Nombre, botón, estado y valor de las decisiones. Inspector/VoiceOver. | Limitado | POST estática y previews cuando aplica | Runtime específico pendiente; no equivale a cierre |
| 4.1.3 | Aplicable | Anuncios de guardado, error y retorno de captura sin mover foco innecesariamente. | Falla | VoiceOver físico reportado por el usuario el28/09 | Anuncio interrumpido; coordinación/prioridad corregidas, retest pendiente |

## Artefactos y entorno

- Xcode MCP: FranAlonso-Develop, iPad Air 11-inch (M4)/26.5; SDK27.0 ya seleccionado. Sin cambio de destino/esquema.
- Tests y TDD: [fase08](../../progress/phase-08.md): 806 declaraciones/116 suites/1.059 resultados PASS, cero fallos/omitidos;
  build final15,651s por Xcode MCP. Aviso AppIntents previo; no se afirma cero warnings globales.
- Previews/apariencias/RTL: 20 imágenes inspeccionadas por revisor independiente. Destino efectivo iPad Pro13M5/iOS27.
  Large, XXX Large, AX5, cuatro apariencias, landscape y350pt/RTL; no equivalen al runtime iPadAir/iOS26 de tests.
- Inspector: pendiente para el nuevo recorrido.
- Runtime: evidencia parcial de F01–F05, voz, teclado, AX5 y ventana registrada arriba el28/09. Retest de foco/anuncios
  y reintento tras corrección pendiente, además de variantes y tecnologías aún no ejecutadas. Sin repetir captura08.4.
- Revisor independiente: post087_standards, dos ámbitos separados con sus skills específicos. El entorno impidió crear
  otro agente (agent thread limit reached), por lo que se reutilizó el mismo revisor POST que nunca implementó ni editó.
  Estándares PASS tras corregir P1/P2; UI PASS estático/visual tras corregir truncamiento P2 y fila duplicada P3.
  Huellas de515rutas pre/post comprobadas por root; detalle en fase08. Sin cierre ADR0022.

## Pasada manual acotada prevista

1. Abrir información sin nombre; leer título/secciones por VoiceOver y volver conservando ediciones.
2. Con nombre sintético, revisar y abrir firma; cancelar y confirmar en sendos intentos. Comprobar foco al volver
   y lectura del mismo texto al revisar la tinta. Conservar el documento y comprobar anuncio/estado.
3. Volver, cambiar nombre y revisar: la firma pendiente anterior no permite aceptar el texto nuevo.
4. Reabrir el cliente; comprobar recuperación y error de envío sin perder el documento. Storage normal sigue no disponible.
5. En AX5 y ventana estrecha, recorrer todo el texto y alcanzar las acciones. Repetir solo la navegación nueva con
   Voice Control, Switch Control y teclado; preferencias y cuatro apariencias se registran por separado.

## Evidencia visual consolidada

Directorio de las imágenes de Xcode MCP:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.
Todas las siguientes se inspeccionaron; dispositivo iPad Pro13-inch M5/iOS27, fecha2026-09-13.

| Archivo | Configuración y alcance |
|---|---|
| Review - 2026-09-13 at 22.08.47.png | Baseline lector real; ya sin spinner. |
| Review - 2026-09-13 at 22.09.16.png | XXX Large, Dark estándar. |
| Review - 2026-09-13 at 22.09.17.png | AX5, Light incrementado. |
| Review - 2026-09-13 at 22.09.41.png | Large, Dark incrementado, landscape. |
| Photo decision - 2026-09-13 at 22.09.41.png | Large, Light; variante opcional. |
| Signed - 2026-09-13 at 22.09.42.png | Large, Light. |
| Retained - 2026-09-13 at 22.09.43.png | Large, Dark. |
| Recovery - 2026-09-13 at 22.10.01.png | AX5, Dark incrementado. |
| Error - 2026-09-13 at 22.10.01.png | XXX Large, Light incrementado. |
| Narrow RTL - 2026-09-13 at 22.10.02.png | 350pt, Large, Light. |
| Narrow RTL - 2026-09-13 at 22.10.36.png | P2 histórico: nombre truncado en350pt/AX5; sustituido por retest22:17:15. |
| Review actions - 2026-09-13 at 22.10.50.png | AX5, Light; acciones del pie inspeccionadas separadamente del scroll largo. |
| Recovery choices - 2026-09-13 at 22.11.05.png | Large, Light. |
| Retained ink - 2026-09-13 at 22.11.19.png | AX5, Dark incrementado. |
| Signed document - 2026-09-13 at 22.12.12.png | Large, Dark; componente de documento. |
| Native information - 2026-09-13 at 22.12.26.png | Large, Light; texto público sin firma personal asociada. |
| Create - 2026-09-13 at 22.13.01.png | FormContent Large, Light; consulta y revisión. |
| Narrow RTL - 2026-09-13 at 22.17.15.png | Retest PASS350pt/RTL/AX5/Dark incrementado: nombre y versión completos. |
| Review - 2026-09-13 at 22.17.15.png | Retest Large/Light estándar: metadatos verticales. |
| Edit long profile - 2026-09-13 at 22.17.32.png | Large/Light estándar: las tres acciones, incluida Reanudar documento. |

La preview de carga inicial21:55 no se cuenta: mostraba únicamente spinner. El host ahora prepara los datos mediante
PreviewModifier.makeSharedContext async antes de renderizar, contrastado con documentación Apple por Cupertino.
Las partes fuera del viewport no se declaran recorridas; el desplazamiento, foco y operación reales siguen pendientes.
