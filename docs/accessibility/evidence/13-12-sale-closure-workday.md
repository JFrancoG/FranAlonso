# 13.12 — Cierre y transición Jornada → Histórico

04/10/2026 Europe/Madrid. [PLU-109](https://linear.app/plusprojects/issue/PLU-109), Done funcional, Jesus Franco.
[PR61](https://github.com/JFrancoG/FranAlonso/pull/61) integrada en main`2f8c970`; fuentes/criterios intactos.
Registro de construcción y validación local, bajo [ADR0022](../../ADRs/0022-native-ios-wcag22-accessibility.md)
y [ADR0029](../../ADRs/0029-progressive-accessibility-validation.md). Deuda nueva transferida antes del cierre a
[PLU-110](https://linear.app/plusprojects/issue/PLU-110), Backlog/Jesus Franco, relacionada conPLU-109:
recuperar tras feedback y estabilización de cada recorrido, antes del primer candidato para uso real.
[PLU-101](https://linear.app/plusprojects/issue/PLU-101) conserva formulario fiscal y
[PLU-108](https://linear.app/plusprojects/issue/PLU-108) conserva Mail nativo; esta subfase no las resuelve ni transfiere.
Entrega Git funcional completada; cierre integral pendiente. Sin activación live, correo real o conformidad legal.

## Flujo y métodos

Jornada → venta pagada pendiente de documento → Documento → Ticket/Factura → preparación durable →
generación/reintento → PDF local confirmado → cierre explícito → retirada/dismiss en Jornada → Histórico.
Normal conserva pending/error sin motores remotos; demo usa series sintéticas separadas, PDF marcado DEMO y Storage simulado.
Reentrada recupera identidad/documento; cancelación y callbacks tardíos no fabrican éxito. Subida o correo pendientes
no reabren Jornada según spec11. El PDF exportado conserva su propia evaluación accesible/fiscal pendiente.

S13.12 = POST técnico P2 resuelto y UI correctivo PASS funcionalADR0029; dos P3 de formato corregidos y revisión focal técnica/estilo PASS.
T13.12 =85casos nuevos/56declaraciones PASS en global3026/3026; RED9 de corrección→GREENfocal6parcial→global; ambos builds y35Swift0diagnósticos (10actuales+25por identidad).
El primer global falló únicamente en teardown weakModelContainer histórico, luego focal1/global3017PASS;
no acredita estabilidad. [Detalle y artifacts](../../progress/phase-13.md).
P13.12 =21previews:15retenidas y6recapturas de elección/error observadas por root; host iPhone18ProMax27.2, Develop/destino seleccionado iPhone17.
R13.12 = smoke inicial67snapshots con fallo funcional/Retry; corrección probada por tests y retest final69snapshots PASS Ticket/Factura sinRetry; EndSession Session stopped.
No se ha observado Inspector, AT, foco/habla real, contraste medido, teclado físico ni dispositivo físico en13.12.
Un test del ViewModel no acredita foco/anuncio efectivos. [Manifest35Swift](assets/13-12/source-manifest.json)
conserva fuentes actuales9493e3f4…; [manifest antes del formato](assets/13-12/source-manifest-before-format.json) conserva35probadas409eed81… (solo dos ajustes whitespace posteriores); [manifest anterior](assets/13-12/source-manifest-before-recovery-fix.json) conserva las del smoke previo; [manifest de previews](assets/13-12/previews-manifest.json) conserva originales/hash/config.
644textos es/en completos/0errores, 556Localizable+87Templates+1InfoPlist;21nuevos y2copys existentes ajustados.
El último copy prepared.message se valida después del global con builds,8focales de localización y3recapturas;
los selectors focales de parámetros son parciales, no se atribuyen38casos a esos8.

## Previews y PDF observados

Cada fila conserva el primer frame original. El scroll no observado permanece limitado; ningún snapshot acredita AT.
Large/es/Light estándar; XXX Large/en/Dark estándar; AX5/es/Light aumentado, portrait. Las filas extra fijan sus variantes.

| Superficie | Large | XXX Large | AX5 | Observación |
|---|---|---|---|---|
| Pantalla con PDF retenido | [PNG](assets/13-12/screen-closable-Large-es-Light.png) | [PNG](assets/13-12/screen-closable-XXXL-en-Dark.png) | [PNG](assets/13-12/screen-closable-AX5-es-Light.png) | Título/Cerrar completos; datos crecen. Progreso y cierre bajo el primer frame en los3tamaños. |
| Selección | [PNG](assets/13-12/selection-Large-es-Light.png) | [PNG](assets/13-12/selection-XXXL-en-Dark.png) | [PNG](assets/13-12/selection-AX5-es-Light.png) | Texto/selector adaptan y siguen legibles; Preparar bajo scrollAX5. |
| Progreso aislado con PDF/subida pendiente | [PNG](assets/13-12/progress-closable-Large-es-Light.png) | [PNG](assets/13-12/progress-closable-XXXL-en-Dark.png) | [PNG](assets/13-12/progress-closable-AX5-es-Light.png) | Large/XXXL muestran mensaje/número/cierre/requisito. AX5 crece y acción queda bajo scroll. |

| Estado adicional | Configuración/PNG | Observación |
|---|---|---|
| Error de recuperación corregido | [Large/es/Dark aumentado](assets/13-12/recovery-error-Large-es-Dark.png), [XXXL/en/Dark](assets/13-12/recovery-error-XXXL-en-Dark.png), [AX5/es/Light aumentado](assets/13-12/recovery-error-AX5-es-Light.png) | Mensaje detenido correcto; Large/XXXL muestran retry. AX5 muestra parte del mensaje y requiere scroll. [P3 original](assets/13-12/recovery-error-Large-es-Dark-before-copy.png) conservado. |
| Ticket+factura retenidos | [Large/es/Dark aumentado](assets/13-12/recovery-choice-Large-es-Dark.png), [XXXL/en/Dark](assets/13-12/recovery-choice-XXXL-en-Dark.png), [AX5/es/Light aumentado](assets/13-12/recovery-choice-AX5-es-Light.png) | Elección y acción explícita visibles completas Large/XXXL, sin formulario fiscal/preparación. AX5 crece; controles bajo scroll no observado. |
| Número pendiente | [PantallaXXXL/es/Light estándar](assets/13-12/pending-number-XXXL-es-Light.png) | Estado debajo del primer frame de datos fiscales. |
| Número pendiente/error aislado | [XXXL/en/Light aumentado](assets/13-12/progress-pending-XXXL-en-Light.png) | Mensaje/retry y cierreDisabled visibles completos. |
| Generación | [Large/en/Dark aumentado](assets/13-12/generating-Large-en-Dark.png) | Pantalla completa renderizada; progreso queda bajo el primer frame. Busy se valida por T/S, no se atribuye observación visual del indicador. |
| Cierre aceptado | [XXXL/en/Dark estándar](assets/13-12/accepted-XXXL-en-Dark.png) | Fixture determinista; mensaje queda bajo el primer frame. Dismiss real se comprueba en R/T. |
| Factura | [AX5/es/Light aumentado](assets/13-12/invoice-AX5-es-Light.png) | Tipo/instrucciones crecen; campos y acción requieren scroll. |
| Error fiscal | [Large/es/Light aumentado](assets/13-12/invoice-error-Large-es-Light.png) | Mensaje fiscal debajo del campo vacío y label persistente; asociación/habla real AT pendientes. |

QA PDF read-only independiente billing_13_12_pdf_review: ticket11+factura14=25páginas observadas,
marca DEMO/MUESTRA/SIN VALIDEZ FISCAL legible en todas, sin solapes/recortes; servicios1–24 una vez/en orden.
[Manifest PDF](assets/13-12/pdf-manifest.json), seis originales representativos:
[ticket1](assets/13-12/pdf-ticket-page-01.png), [6](assets/13-12/pdf-ticket-page-06.png),
[11](assets/13-12/pdf-ticket-page-11.png), [factura1](assets/13-12/pdf-invoice-page-01.png),
[7](assets/13-12/pdf-invoice-page-07.png), [14](assets/13-12/pdf-invoice-page-14.png).
TicketSHA1f2069bd9ef7c10e0f13a747d716da32cbb81529f05f281e8b6ae8d503fc3852, generado10:51:40/global.
FacturaSHA8014eec820e1c09d4ac1adcabaa25a81fd39170f51046209448639674ba9c057, captura fresca10:59:17/focal2PASS.
Factura anterior10:25 no se atribuye al global:14renders nuevos son byteidénticos a los14inspeccionados,
PDFbytes diferentes. PDF sin etiquetar, lector/validez fiscal pendientes; esta QA solo acredita composición visual.

## Smoke final R13.12

DeviceInteraction oficial, iPhone17/iOS27.2, Develop y argumento exacto `--franalonso-demo-workday`;
04/10/2026, es/Light/portrait/defaultDynamicType. Root no usó Xcode durante la sesión del worker.
[Manifest final](assets/13-12/runtime-manifest.json) retiene13PNG/13jerarquías de69snapshots originales,
SHA del manifest completo27f4227cf51f12888d7826a7569a37ce1173d50ac1133220f23267f4ea683cbd.
El worker/root verifican hashes individuales; source35Swift previo dfdb6215… conservado en manifest anterior. EndSession confirma Session stopped.
El smoke antecede a la corrección POST de10Swift: no acredita interacción de elección de ambas familias. Ese caso se valida
por T/P/S actuales; se conservan el smoke y sus límites sin atribuirle ejecución sobre el manifest final9493e3f4…; 409eed81… corresponde a las pruebas/previews previas al ajuste exclusivo de formato.

| Recorrido | Evidencia original conservada | Resultado limitado |
|---|---|---|
| Ticket primera entrada/cancelación | [9](assets/13-12/runtime-09-ticket-first-open-no-retry.png) | Formulario habilitado sin error/Retry;10cancel mantiene venta,11reabre. Cancelar ajustado. |
| Ticket preparado/reentrada | [14](assets/13-12/runtime-14-ticket-prepared-reentry-no-retry.png) | Mismo estado preparado/número pendiente; no fabrica cierre. |
| Ticket PDF/reentrada | [17](assets/13-12/runtime-17-ticket-generated-reentry-900001-no-retry.png) |900001 visible; generarDisabled, cierreEnabled; noRetry. |
| Ticket cierre/Jornada/Histórico | [19](assets/13-12/runtime-19-ticket-workday-removal-stable.png), [20](assets/13-12/runtime-20-ticket-history-new-closed-row.png), [22](assets/13-12/runtime-22-ticket-history-read-only-traceability.png) | Retira pagada16:19 y preserva pendiente pago16:18. Histórico nuevoCerrada, detalle readonly/trazabilidad. |
| Factura primera entrada/error | [44](assets/13-12/runtime-44-invoice-recovery-first-open-no-retry.png), [48](assets/13-12/runtime-48-invoice-required-tax-id-error.png) | SinRetry; error fiscal textual y seis valores sintéticos corregidos en56. |
| Factura preparada/reentrada/PDF | [60](assets/13-12/runtime-60-invoice-prepared-reentry-pending.png), [64](assets/13-12/runtime-64-invoice-generated-reentry-950001-no-retry.png) | Reentrada conserva preparación;950001 visibletras generación/reentrada, generarDisabled/cierreEnabled. |
| Factura cierre/Jornada/Histórico | [66](assets/13-12/runtime-66-invoice-workday-removal-stable.png), [67](assets/13-12/runtime-67-invoice-history-new-closed-row.png), [69](assets/13-12/runtime-69-invoice-history-read-only-traceability.png) | Cierre retira operación y crea histórico readonly con documento; sinRetry. |

Los paths exactos del manifest prevalecen sobre etiquetas resumidas. Capturas transitorias18/26/39/65 no se usan
como resultado estable. Callback/orden UI y mismoPDF real se acreditan por T/identidad Data; R muestra número/estado,
no bytes internos ni contador de reservas. Toolbar AXframeh36 no demuestra hitarea44pt ni PASS2.5.8.
La sesión devolvió Sessionnotfound tras primera factura31–33, causa no demostrada. Sesión nueva y relanzar fixture
con argumento exacto permitieron repetir factura44–69 completa. No se atribuye incidente a root/producto/actor.
Cada proceso demo reinicia su memoria por contrato; este smoke no acredita durabilidad tras relanzar. DataT sí
usa disco/relectura independiente. Entrada por inyección de texto: no acredita teclado físico/FKA ni Autofill.

## Matriz55 A/AA

Registro por flujo sobre S/T/P y R parcial; N/A significa ausencia de mecanismo, nunca aplazamiento.
Limitado/Pendiente/Falla no son Pasa integral. Configuración S/T/P/R descrita arriba;04/10/2026.
Los39criterios aplicables/condicionales conservan26Limitado/12Pendiente/1Falla histórica;
16N/A motivados con resultado Limitado de alcance. Revisores: root y billing_13_12_accessibility; POST UI correctivo PASS funcional/Limitado. Matriz sin cambios de resultado.

| ID | Aplicabilidad | Justificación | Resultado | Método/artefacto | Configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Progreso e iconos necesitan semántica; los estados deben tener alternativa textual. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.2.1 | N/A | Sin audio o vídeo pregrabado. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.2.2 | N/A | Sin audio sincronizado pregrabado. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.2.4 | N/A | Sin audiovisual en directo. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.3.1 | Aplicable | Form/Section, resumen y progreso deben conservar grupos, labels y relaciones. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.3.2 | Aplicable | Orden elección → revisión → generación → cierre → Histórico. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.3.3 | Aplicable | Instrucciones, estado y error deben nombrar acciones sin depender de color/posición. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.3.4 | Aplicable | Sheet y destinos deben adaptarse a orientación y tamaño de ventana. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.3.5 | Aplicable | Campos fiscales heredados conservan propósito/autofill cuando aplica. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.1 | Aplicable | Estado pendiente/error/aceptado necesita texto además de color. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.2 | N/A | Sin audio automático. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.4.3 | Aplicable | Contraste del texto de estado y acciones requiere medición. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.4 | Aplicable | Crecimiento hastaAX5 parcial; título histórico del detalle sigue recortado. | Falla | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Falla históricaPLU-91 conservada sin traslado; scroll/recorrido nuevoAX5 pendientePLU-110. | root/registro parcial. |
| 1.4.5 | Aplicable | UI usa texto real; PDF final se valida por separado, sin acreditar accesibilidad del documento exportado. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.10 | Aplicable | Resumen, progreso y acción de cierre requieren reflow en ventanas estrechas. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.11 | Aplicable | Controles y estados necesitan contraste medido en cuatro apariencias. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 1.4.12 | N/A | SwiftUI nativo; no markup que permita modificar espaciado. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 1.4.13 | N/A | Sin nuevo contenido que aparezca por hover/foco. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.1.1 | Aplicable | Generar, reintentar, cerrar y abandonar requieren operación por teclado. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.1.2 | Aplicable | El foco debe poder entrar y salir de la sheet y el destino histórico. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.1.4 | N/A | Sin nuevos atajos de carácter. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.2.1 | N/A | Sin límite de tiempo para revisar o cerrar; cancelación de tarea no es plazo impuesto a la persona. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.2.2 | Aplicable | Progreso/cambios automáticos deben respetar preferencias y no impedir revisión. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.3.1 | Aplicable | Progreso y transición de pantallas no deben introducir destellos. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.1 | Aplicable | Jerarquía y foco deben facilitar acceso al contenido y a las acciones. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.2 | Aplicable | Documento, Jornada e Histórico necesitan título descriptivo y lectura correcta. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.3 | Aplicable | Foco de sheet/cierre/retirada en Jornada debe conservar secuencia y contexto. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.4 | Aplicable | Acciones de generar/cerrar/reintentar deben comunicar su propósito. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.5 | N/A | Tramo secuencial de tarea, sin nueva colección extensa; Jornada/Histórico mantienen su navegación. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.4.6 | Aplicable | Títulos y etiquetas deben describir revisión, estado y aceptación. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.7 | Aplicable | Foco visible requiere comprobación con Full Keyboard Access. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.4.11 | Aplicable | Foco no totalmente oculto por teclado, barras o sheet; comprobar tras scroll. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.5.1 | N/A | Sin gesto multipunto o trayectoria requerido. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.5.2 | Aplicable | Acciones financieras explícitas requieren cancelación del puntero y aceptación controlada. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.5.3 | Aplicable | Nombre accesible debe contener etiqueta visible de acción. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 2.5.4 | N/A | Sin activación por movimiento. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.5.7 | N/A | Sin arrastre requerido; controles y scroll nativos. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 2.5.8 | Aplicable | Medir 24 CSS px mediante WCAG2ICT y política independiente44×44pt. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.1.1 | Aplicable | Textos nuevos es/en necesitan localización y pronunciación correctas. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.1.2 | Condicional | Datos capturados pueden contener otro idioma; evaluar pronunciación cuando expresable. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.2.1 | Aplicable | Enfocar no debe iniciar generación o aceptación. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.2.2 | Aplicable | Elegir tipo o editar no debe cerrar la venta; requiere acción explícita. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.2.3 | Aplicable | Cancelación/retorno y entrada de Documento conservan navegación consistente. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.2.4 | Aplicable | Acciones repetidas deben mantener nombre y función. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.2.6 | N/A | Sin nuevo mecanismo repetido de ayuda. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 3.3.1 | Aplicable | Errores de generación/cierre necesitan texto, asociación y anuncio. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.3.2 | Aplicable | Selección y revisión fiscal necesitan etiquetas e instrucciones persistentes. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.3.3 | Aplicable | Error recuperable debe ofrecer una acción de reintento comprensible. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.3.4 | Aplicable | Cierre financiero exige pago y documento/PDF correlacionados y aceptación explícita. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.3.7 | Aplicable | Reentrada/retry recuperan request/PDF y fecha, evitando datos o reserva duplicados. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 3.3.8 | N/A | No modifica autenticación ni añade prueba cognitiva; consume capability de sesión existente. | Limitado | S13.12, inspección del mecanismo ausente. | 04/10/2026; configuraciones S/T/P/R arriba. | Reevaluar por impacto si se incorpora mecanismo. | root/registro parcial. |
| 4.1.2 | Aplicable | Controles y progreso necesitan nombre, rol, valor, estado y acciones. | Limitado | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |
| 4.1.3 | Aplicable | Carga/error/aceptación y retirada de Jornada necesitan anuncios sin perder contexto. | Pendiente | S13.12/T13.12/P13.12; R13.12 táctil limitado. | 04/10/2026; configuraciones S/T/P/R arriba. | Evidencia integral/AT pendientePLU-110 antes de uso real. | root/registro parcial. |

## Recuperación de evidencia integral

PLU-110/Jesus Franco, Backlog: recuperar tras feedback y estabilización de Ticket y Factura, antes del primer candidato real.
Incluye observar interacción de la elección entre ambas familias; el smoke conservado antecede a ese fix.
VoiceOver, VoiceControl, SwitchControl, FKA/teclado físico, Inspector, ratios finales en cuatro apariencias, orientación,
iPad/ventanas/RTL, ReduceMotion/Transparency, DifferentiateWithoutColor, datos largos y scrollAX5 completo pendientes.
La jerarquía de DeviceInteraction solo acredita el árbol expuesto observado, no el habla/foco/rotor de AT ni hitarea44pt.
Cierre y regeneración/reintento financiero deben revisar la capability, mismo documento y fecha; T no prueba interacción AT.
El título históricoAX5 permanece Falla enPLU-91; formulario fiscalPLU-101/MailPLU-108 conservan su alcance previo.
Sin cierre integral, privacidad física13.6, servicio remoto real ni correo real. Entrega Git funcional completada.
POST UI correctivo PASS funcional/Limitado; técnico/estilo final PASS con P2 y2P3 resueltos. R táctil previo PASS/limitado, sin AT integral.
