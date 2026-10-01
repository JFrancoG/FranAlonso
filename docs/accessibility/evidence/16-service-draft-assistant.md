# Fase 16 — Borrador escrito de un servicio profesional

Actualizado el 2026-10-01; construcción inicial el 2026-09-30. Registro de construcción y validación progresiva bajo
[ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) y
[ADR 0029](../../ADRs/0029-progressive-accessibility-validation.md).
**No acredita validación integral ni cierre de la puerta funcional.**

Implementación [PLU-47](https://linear.app/plusprojects/issue/PLU-47), In Progress; responsable Jesús Franco.
Deuda propia [PLU-70](https://linear.app/plusprojects/issue/PLU-70), Backlog, hija de PLU-47 y asignada a Jesús Franco.
Recuperar la evidencia tras feedback de Fran y estabilización del recorrido, siempre antes del primer candidato para uso
real y del cierre integral. No absorbe PLU-65/PLU-67 ni la deuda de otras pantallas o fases.

## Alcance e inspección estática

ServiceDraftAssistantSection, su integración en ServiceFormContent/ServiceFormScreen, los mensajes de
ServiceDraftAssistantState y el estado efímero de ServiceFormViewModel. Solo alta de un servicio profesional en la demo
aislada existente. El formulario manual, su validación y su acción Guardar siguen siendo el recorrido de persistencia.
Las matrices [10.5](10-5-service-screens.md) y [10.6](10-6-linked-product-selector.md) conservan su evidencia y pendientes;
su validación anterior no se extrapola a esta nueva sección ni a sus transiciones.

Inspección de la implementación, sin ejecución de tecnologías de asistencia:

- Section nativa con encabezado, rótulo persistente, TextField vertical y descripción localizada del uso de datos
  ficticios. La entrada, mensajes y botones permiten varias líneas; los valores propuestos se agrupan con su etiqueta.
- Generar propuesta es una acción explícita. Generando muestra progreso y Cancelar generación; la revisión muestra solo
  los campos presentes y ofrece Aplicar al borrador/Rechazar propuesta. Aplicar no anuncia un alta ni un guardado.
- Aplicación reversible mediante Deshacer aplicación hasta la siguiente edición, petición o interrupción. El estado
  aplicado recuerda revisar todos los campos y guardar por el control habitual; una propuesta parcial conserva los
  valores existentes de campos no propuestos.
- Errores de aclaración, generación y longitud, así como los estados de disponibilidad, proporcionan mensajes es/en y
  recuperación manual. Los mensajes no exponen prompts, salidas del modelo ni detalles del proveedor.
- La pantalla solicita anuncios mediante AccessibilityNotification cuando cambia el mensaje del asistente. La presencia
  de estas llamadas no acredita entrega, prioridad, inteligibilidad ni ausencia de interrupciones en VoiceOver.
- La entrada solicita una altura mínima de 44 pt; los botones solicitan 44×44 pt. No se ha medido la superficie operable.
  El foco de la descripción se comparte con el formulario para que Listo lo retire; submit y acciones también lo
  retiran. Esta construcción no acredita Full Keyboard Access ni la visibilidad del foco con teclado software.
- Edición, rechazo, cancelación, guardado, cierre e interrupción invalidan resultados tardíos. El descarte de información
  efímera no sustituye el borrador manual. No se añaden micrófono, Speech, TTS, navegación del asistente ni audio de fondo.
- Previews deterministas de sección y formulario completo usan AppPreviewModifier y un proveedor fijo cuando necesitan
  interacción. No realizan inferencia real y no validan calidad, latencia ni disponibilidad física del modelo.

## Evidencia disponible y límites

La evidencia técnica y sus artefactos se consolidan en [fase 16](../../progress/phase-16.md). Este registro conserva el
estado comunicado por la implementación al redactarlo; no atribuye a una ejecución un destino, build o artefacto que
todavía no esté registrado. Construcción inicial el30/09/2026 y ajustes/revisión técnica el01/10. Revisión independiente
de UI: P2 de foco de Listo corregido; reauditoría focal PASS. Evidencia y huellas en fase 16.

| Evidencia | Estado del registro | Límite y siguiente comprobación |
|---|---|---|
| Pruebas focales Xcode MCP | Inicial160/160; retest actual106/106 resultados,34 declaraciones PASS. | Nativo cerrado, iPhone11/iOS27.2; etapas/admisión, parser y ViewModel, recuperación y persistencia solo tras Guardar. Artefactos por versión en fase16. No ejecutan AT ni acreditan operación táctil. |
| Sección «Assistant idle ES Large» | Render inspeccionado sin fallos visuales observados en ese estado. | iPhone 18 Pro Max/iOS 27.2; artefacto registrado en fase 16. No demuestra desplazamiento, teclado, transiciones ni AT. |
| Previews y formulario completo | Siete renders inspeccionados; detalle y PNG en fase 16. | Sección idle ES Large, revisión ES AX 5, error EN XXX Large Dark; pantalla ES Large/XXX Large/AX 5 y contenido Large. Sin solapes observados; scroll/teclado/AT no demostrados por captura. Progreso/aplicado conservan solo preview declarada. |
| Fallback en simulador | Error localizado y formulario manual disponible observados, sin mutación, crash ni solapes en ese intento. | La disponibilidad devolvió available, pero la inferencia falló con operationNotAllowed: «Simulator is not supported». Guardado manual y reapertura con valores correctos comprobados; asistente ausente en edición. Configuración y artefactos registrados en fase 16; no acredita inferencia real. |
| Smoke del recorrido con inferencia real | PID1869:13/13 casos semánticos PASS en primera generación; Reject conserva BaseDEMO/7EUR/IVA21/descuento0. Cancel actual limitado: la revisión estaba finalizada en el frame posterior a la acción. 14 generaciones únicas,0 retries/diagnósticos/Apply/Save. PID1844:9PASS/1FAIL genérico; Apply/Undo preservaron21/0. Fallos anteriores conservados. | iPhone16/iOS27.2beta, DeviceHub, UIEN/locale en_ES, Dark/tamaño3/AToff, datos sintéticos. Reuso por impacto de Apply/Undo y preflights de1844, Save/reopen y CancelLoading de1019; no se atribuyen al run actual. Background físico durante loading y cierre en carrera sin acreditar; tests controlados separados. No acredita AT ni cancelación inmediata del SDK. |
| Inspector, contraste y superficie operable | Pendiente. | Composición final en las cuatro apariencias, controles habilitados/deshabilitados y contenido desplazado. |
| VoiceOver/Voice Control/Switch Control/FKA | Pendiente, sin validación física del nuevo recorrido. | Operación, orden/restauración de foco y anuncios, incluidos botones que desaparecen tras las acciones. |
| iPad, orientación, ventanas, RTL y preferencias | Pendiente. | Completar por impacto; no extrapolar las capturas iPhone. |
| POST independiente | Fuente actual PRE/POST técnico, estilo y documentación PASS;106/34 favorables el01/10. UI: P2 de Listo corregido y reauditoría PASS, reutilizados porque no cambia Presentation. Reconciliación final revisada; precisión observacional de Cancel corregida. | PID1869 resuelve los fallos semánticos observados dentro de su corpus; no demuestra detección general. Limitación Cancel actual retenida con reuso por impacto; no trasladada a PLU-70. Retirada previa de foco/cursor/toolbar observada; teclado software/AT permanecen pendientes. |

El intento de simulador acredita el fallback y el guardado manual con reapertura; no acredita las tecnologías de
asistencia ni la inferencia física. El retest focal de Listo acredita resignación del foco en descripción/nombre;
no acredita geometría de teclado software, que no se desplegó en este simulador. Un defecto que impida operar
la demo con la tecnología necesaria para su participante, o afecte a integridad,
privacidad o recuperación, bloquea la puerta funcional y no puede aplazarse como simple falta de matriz exhaustiva.

## Matriz completa de 55 criterios A/AA

Cubre el nuevo recorrido y sus transiciones dentro del formulario existente. `Limitado` significa construcción o
evidencia técnica/visual parcial; `Pendiente`, ausencia de la comprobación necesaria. No hay resultados `Pasa` derivados
de las previews. `N/A` identifica ausencia justificada de un mecanismo y exige reevaluación si cambia el alcance.

Todas las filas comparten fecha 30/09/2026 y responsable Jesús Franco. Para inspección estática no se atribuye
dispositivo/iOS/build. Las ejecuciones posteriores deben registrar configuración, artefacto y revisor de forma concreta.
La disposición «Deuda propia» remite a PLU-70, recuperable antes de uso real y cierre integral. El vínculo no sustituye
la evidencia ni constituye por sí solo aprobación de entrega. Los pendientes necesarios para la demo permanecen en PLU-47.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método y pendiente | Disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Progreso y acciones tienen texto; la pantalla conserva controles nativos con etiquetas. | Limitado | Estática; Inspector y VoiceOver sobre estados y controles de la pantalla. | Deuda propia; bloquea demo si impide operar. |
| 1.2.1 | N/A | El recorrido es textual; no incorpora audio ni vídeo pregrabado. | N/A | Inspección de alcance. | Reevaluar al añadir voz o medios. |
| 1.2.2 | N/A | No existe contenido audiovisual sincronizado pregrabado. | N/A | Inspección de alcance. | Reevaluar al añadir medios. |
| 1.2.3 | N/A | No existe vídeo pregrabado que requiera alternativa. | N/A | Inspección de alcance. | Reevaluar al añadir medios. |
| 1.2.4 | N/A | No hay contenido audiovisual en directo. | N/A | Inspección de alcance. | Reevaluar al añadir medios. |
| 1.2.5 | N/A | No existe vídeo pregrabado. | N/A | Inspección de alcance. | Reevaluar al añadir medios. |
| 1.3.1 | Aplicable | Section con encabezado, etiqueta persistente y pares etiqueta/valor agrupados en la propuesta. | Limitado | Estática; relaciones, agrupación y rotor mediante Inspector/VoiceOver. | Deuda propia. |
| 1.3.2 | Aplicable | Orden declarado: descripción, instrucciones, feedback, propuesta y acciones, seguido del formulario. | Limitado | Estática; lectura lineal al aparecer/desaparecer cada estado. | Deuda propia. |
| 1.3.3 | Aplicable | Las instrucciones nombran datos y acciones, sin depender solo de ubicación, color o forma. | Limitado | Estática; comprensión del recorrido real en es/en. | Deuda propia. |
| 1.3.4 | Aplicable | La sección no introduce bloqueo de orientación. | Pendiente | iPhone/iPad portrait/landscape y multitarea, con teclado visible. | Deuda propia. |
| 1.3.5 | N/A | Se describe un servicio comercial ficticio; no se solicita información personal para autofill. | N/A | Inspección de propósito de entrada. | Reevaluar si se solicitan datos personales. |
| 1.4.1 | Aplicable | Progreso, fallos, disponibilidad y aplicación se expresan mediante texto; errorInk es una señal adicional. | Limitado | Estática; verificar Differentiate Without Color en todos los estados. | Deuda propia. |
| 1.4.2 | N/A | No se reproduce audio ni se incorpora síntesis de voz. | N/A | Inspección de alcance. | Reevaluar al añadir TTS o audio. |
| 1.4.3 | Aplicable | Texto nativo y colores semánticos; la composición no tiene mediciones propias de contraste. | Pendiente | Medir texto en Light/Dark con contraste normal/incrementado. | Deuda propia. |
| 1.4.4 | Aplicable | Texto multilínea y fuentes semánticas; pantalla inspeccionada en Large/XXX Large/AX 5 y sección en estados representativos. | Limitado | Completar operación AX 5 con teclado y propuesta, incluidos controles fuera del viewport. | PLU-47 para previews funcionales; deuda propia para matriz integral. |
| 1.4.5 | Aplicable | Etiquetas, mensajes y valores se muestran como texto nativo, sin imágenes de texto. | Limitado | Estática y preview Large; inspeccionar estados restantes. | Deuda propia. |
| 1.4.10 | Aplicable | Form vertical, TextField de eje vertical y contenido multilínea. | Limitado | Formulario completo AX 5 inspeccionado; pendiente operación, ventanas estrechas e iPad. | PLU-47 para previews funcionales; deuda propia para matriz integral. |
| 1.4.11 | Aplicable | Botones, indicador de progreso y foco emplean presentación nativa; no se han medido sus contrastes. | Pendiente | Medir controles y estados esenciales en cuatro apariencias. | Deuda propia. |
| 1.4.12 | N/A | SwiftUI nativo, sin markup con propiedades de espaciado de autor modificables. | N/A | Inspección de tecnología. | Reevaluar si se introduce markup. |
| 1.4.13 | Condicional | La sección no añade ayuda por hover; la pantalla conserva visor de contenido grande para acciones de barra. | Pendiente | Evaluar el visor y cualquier contenido adicional al usar puntero/foco en el formulario. | Deuda propia; mantener ámbito previo de 10.5. |
| 2.1.1 | Aplicable | Entrada y acciones nativas; existe submit para retirar foco de escritura. | Pendiente | Full Keyboard Access; generar, cancelar, aplicar, rechazar, deshacer y Guardar sin toque. | Deuda propia; bloquea demo si requiere esta tecnología. |
| 2.1.2 | Aplicable | Formulario modal con cancelación explícita; los estados cambian controles disponibles. | Pendiente | Teclado/Switch Control: entrada, salida y retorno desde descripción, propuesta y confirmaciones. | Deuda propia. |
| 2.1.4 | N/A | No se añaden atajos propios de un solo carácter. | N/A | Inspección de alcance. | Reevaluar si aparecen atajos. |
| 2.2.1 | N/A | No se impone un plazo para introducir, revisar o aplicar; la espera de inferencia permite cancelación. | N/A | Inspección de interacción; la interrupción de escena es de ciclo de vida, no un timeout. | Reevaluar si se añade expiración temporal. |
| 2.2.2 | Condicional | Durante generación hay un indicador nativo y una acción Cancelar; no se conoce la duración real. | Limitado | Estática; comprobar espera prolongada, cancelación y Reduce Motion en runtime. | Deuda propia; cancelación funcional en PLU-47. |
| 2.3.1 | Aplicable | El delta no añade destellos ni animaciones propias. | Limitado | Estática; comprobar progreso y transiciones en runtime con preferencias de movimiento. | Deuda propia. |
| 2.4.1 | Aplicable | Encabezado de sección y campos del formulario estructuran el acceso a descripción y datos manuales. | Limitado | Estática; rotor y acceso al formulario después de la propuesta. | Deuda propia. |
| 2.4.2 | Aplicable | Se conserva el título de alta y se identifica la sección de borrador con Apple Intelligence. | Limitado | Estática; verificar anuncio inicial y contexto al volver al formulario. | Deuda propia. |
| 2.4.3 | Aplicable | Aplicar/rechazar/cancelar/deshacer eliminan o sustituyen controles; los anuncios no fijan su foco real. | Pendiente | VoiceOver, teclado y Switch Control: foco tras cada transición, error, interrupción y cierre. | Deuda propia; bloquea demo si se pierde operabilidad. |
| 2.4.4 | Aplicable | Generar, aplicar, rechazar, cancelar y deshacer tienen nombres explícitos. | Limitado | Estática; lista de acciones accesibles y comprensión fuera del contexto visual. | Deuda propia. |
| 2.4.5 | N/A | El delta añade un único recorrido en el formulario existente, sin colección extensa ni nuevos destinos. | N/A | Inspección de navegación. | Mantener la evidencia de búsqueda/catálogo en 10.5. |
| 2.4.6 | Aplicable | Encabezado, descripción y valores propuestos conservan etiquetas persistentes. | Limitado | Estática y preview Large; Inspector y rotor para propuesta parcial y errores. | Deuda propia. |
| 2.4.7 | Aplicable | Entrada y botones usan foco nativo; no hay observación de foco visible con teclado/puntero. | Pendiente | Full Keyboard Access y puntero en las superficies compatibles. | Deuda propia. |
| 2.4.11 | Aplicable | Se añade una entrada multilínea antes de los campos; el teclado y contenido largo pueden reducir el viewport. | Pendiente | Teclado software visible, scroll, propuesta extensa, AX 5 y confirmaciones; verificar Listo del formulario. | Deuda propia; bloqueo si oculta la acción necesaria para la demo. |
| 2.5.1 | N/A | Ninguna acción propia requiere gesto multipunto o de trayectoria; las operaciones tienen botones. | N/A | Inspección de interacción. | Reevaluar si aparecen gestos propios. |
| 2.5.2 | Aplicable | Las intenciones se envían mediante Button; aplicar es reversible y no guarda. | Limitado | Estática y tests de reversibilidad; cancelación táctil de botones pendiente. | Deuda propia. |
| 2.5.3 | Aplicable | Texto visible y nombres accesibles coinciden; la descripción recibe el mismo rótulo. | Limitado | Estática; activación por nombre mediante Voice Control en es/en. | Deuda propia. |
| 2.5.4 | N/A | No se incorporan acciones por agitar o mover el dispositivo. | N/A | Inspección de alcance. | Reevaluar al añadir movimiento. |
| 2.5.7 | N/A | No se exige arrastrar para proponer, revisar, aplicar o cancelar. | N/A | Inspección de interacción. | Reevaluar si aparecen arrastres propios. |
| 2.5.8 | Aplicable | Input solicita 44 pt de altura y botones 44×44 pt; la medida declarada no demuestra hit area real. | Limitado | Medición de superficie operable y separación en todos los estados y tamaños. | Deuda propia. |
| 3.1.1 | Aplicable | Copy es/en en xcstrings; formato de propuesta y anuncios usan el Locale de la sesión/pantalla. | Limitado | Estática; pronunciación, números, moneda y mensajes con VoiceOver en es/en. | Deuda propia. |
| 3.1.2 | Condicional | La descripción y nombre propuesto pueden contener datos escritos en otro idioma; no se marcan fragmentos individuales. | Pendiente | Evaluar contenido sintético mixto y pronunciación; distinguir texto propio de datos de usuario. | Deuda propia; documentar límite si procede. |
| 3.2.1 | Aplicable | Recibir foco no solicita inferencia ni aplica o guarda una propuesta. | Limitado | Estática; recorrer campos y botones con tecnologías de asistencia. | Deuda propia. |
| 3.2.2 | Aplicable | Editar invalida estado efímero y conserva el formulario; generar, aplicar y guardar son acciones distintas. | Limitado | Tests de estado y respuestas tardías; comprobar comprensión de la invalidación en runtime. | Deuda propia; regresión funcional en PLU-47. |
| 3.2.3 | Aplicable | La sección vive en el alta existente y no introduce rutas globales ni cambia el guardado manual. | Limitado | Estática; entrada/retorno al catálogo y cierre del formulario con AT. | Deuda propia; conservar ámbito de 10.5. |
| 3.2.4 | Aplicable | Se reutilizan etiquetas de nombre/precio/impuesto/descuento y controles del formulario. | Limitado | Estática; identificar acciones y campos en revisión y edición manual con AT. | Deuda propia. |
| 3.2.6 | N/A | No se añade un mecanismo de ayuda repetido entre pantallas; las instrucciones pertenecen a esta sección. | N/A | Inspección de alcance. | Reevaluar al añadir ayuda compartida. |
| 3.3.1 | Aplicable | Feedback localizado distingue aclaración, longitud, generación y disponibilidad; error de generación visible en el simulador. | Limitado | Estática y fallback visual parcial; asociación, orden de lectura y anuncio real de cada error pendientes. | Deuda propia. |
| 3.3.2 | Aplicable | Label persistente y guía de un servicio, precio/moneda, campos opcionales y datos ficticios. | Limitado | Estática y preview Large; instrucciones completas con AT y tamaños accesibles. | Deuda propia. |
| 3.3.3 | Aplicable | Mensajes ofrecen reformular/acortar, reintentar, activar Apple Intelligence o continuar manualmente según el caso. | Limitado | Tests y fallback visible en simulador; completar recorrido manual y comprensión de cada escenario con AT. | Deuda propia; recuperación funcional en PLU-47. |
| 3.3.4 | Aplicable | Propuesta parcial revisable; aplicar no persiste, deshacer tiene límite explícito y solo Guardar invoca persistencia. | Limitado | 160/160 focales incluyen aplicación/reversión y persistencia tras Save; falta recorrido manual/AT. | PLU-47 para integridad y smoke; deuda propia para operación accesible integral. |
| 3.3.7 | Aplicable | Campos no propuestos conservan valores; fallo/disponibilidad no destruyen borrador manual; cancelar/rechazar descartan entrada efímera por política. | Limitado | Tests de conservación; verificar reintento y no repetición indebida de datos manuales con AT. | Deuda propia; mantener política de privacidad de spec 16. |
| 3.3.8 | N/A | El delta no cambia autenticación ni introduce prueba cognitiva de acceso. | N/A | Inspección de alcance. | Autenticación conserva su evidencia y deuda propias. |
| 4.1.2 | Aplicable | TextField, Button y ProgressView nativos; etiquetas y estado habilitado derivan del estado presentado. | Limitado | Inspector, VoiceOver y Voice Control para nombre, rol, valor y disponibilidad real. | Deuda propia. |
| 4.1.3 | Aplicable | La pantalla publica anuncios localizados al cambiar el mensaje del asistente; no se han escuchado en runtime. | Limitado | VoiceOver: carga, propuesta, aplicación, fallos, disponibilidad y transiciones sin mensaje; comprobar prioridades y duplicados. | Deuda propia; bloquea demo si impide comprender el resultado. |

## Recuperación y puerta integral pendiente

1. Mantener PLU-70 vinculada a PLU-47 y a este registro, con Jesús Franco como responsable; actualizarla con evidencia y
   hallazgos concretos sin cerrar sus pendientes por la entrega funcional.
2. Conservar la evidencia funcional aceptada de previews, recorrido sintético con inferencia real y revisiones
   independientes; Cancel actual continúa Limitado, con reuso por impacto. Revalidar ante cambios relevantes.
3. Tras estabilización, completar Inspector, contraste y hit areas; VoiceOver, Voice Control, Switch Control y Full
   Keyboard Access; teclado software, AX 5, iPad/ventanas, orientación, RTL y preferencias aplicables.
4. En cada comprobación registrar dispositivo, versión/build, idioma, preferencias, método, artefacto, resultado y
   revisor. Revalidar por impacto si cambia la sección, su copy, el foco o la composición del formulario.

PLU-47 está Done funcional tras [PR32](https://github.com/JFrancoG/FranAlonso/pull/32), merge `f1c781d`, validado `f727621`.
Este registro no cierra ninguna subfase completa de fase 16 ni la validación integral. La cancelación física actual
permanece limitada; recuperación previa y tests se reutilizan solo por impacto. Fase 16 conserva fallos por versión,
alcance y límites de cada comprobación. PLU-70 mantiene su propietario y puerta anterior a uso real.
