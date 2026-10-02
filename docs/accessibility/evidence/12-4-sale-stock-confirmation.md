# 12.4 — Progreso de venta y confirmación de stock

02/10/2026, [PLU-90](https://linear.app/plusprojects/issue/PLU-90), Jesus Franco.
Gate: implementación funcional para demo, ADR0029; entrega Git pendiente de autorización.
[ADR0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) /
[ADR0029](../../ADRs/0029-progressive-accessibility-validation.md).
Deuda específica [PLU-91](https://linear.app/plusprojects/issue/PLU-91), Backlog/Jesus Franco.
Recuperación tras feedback y estabilización por flujo, siempre antes del primer candidato para uso real.
PLU-89 permanece separada. No se acredita cierre integral, AT, dispositivo físico ni conformidad legal.

## Alcance y evidencia

Jornada abre sesión operativa; el mismo detalle inicia venta/servicios, completa líneas, elige efectivo/tarjeta y
registra pago11.8. Términos dejan de ser editables al iniciar; un único Store conserva el snapshot aceptado.
Solicitud refresca stock; suficiente/exacto0 continúa, déficit o desconocido presenta sheet. Mostrar/Cancelar
/repetir no altera venta, cola ni stock. Continuar consume comando con identidad/fecha congeladas una vez;
retry conserva comando; close y callbacks obsoletos quedan cercados. Pago permanece pendiente de documento.
Movimientos12.5, atomicidad12.6, sync12.7/12.8, documento13 y live excluidos.

- S: fuente, catálogo13claves es/en, un View/archivo, previews propios con modifier compartido.
  Botones44pt, texto multiline, sheet scrollable, controles nativos. Retorno de foco sin temporizadores.
- T: RED de compilación por APIs ausentes antes de código; GREEN23/23 nuevas ejecuciones20declaraciones.
  Regresión299/299,173declaraciones,16suites incl. recursos38/38; bundle nativo cerrado sin runtime warnings.
  Xcode MCP Develop/Production, iPadPro13(M5)Simulator27.2; Swift6/strict complete, SDK/target27.0. Diagnósticos Swift/Clang0; aviso conocido
  appintentsmetadataprocessor en log completo. Detalle en [fase12](../../progress/phase-12.md).
- P: diez PNG originales Xcode MCP, sin editar: [manifest](assets/12-4/manifest.json), SHA256/configuración.
  Workspace iPhone17, host real iPhone18ProMax27.2; fixtures sintéticas in-memory; es/en, Large/XXX Large/AX5.
  iPad preview host falla dyld/libSystem antes de código; destino original iPad restaurado tras capturas.
  Confirmación Large/es/Light normal completa; XXXL/en/Dark aumentado completa con onBrandPrimary;
  AX5/es/Light aumentado necesita scroll. Unknown/en/Dark normal explica permiso explícito.
  Detalle Large/XXXL/AX5 requiere scroll hacia workflow; título AX5 truncado. Componente workflow Large/es
  y XXXL/en completos; AX5/es/Dark normal placeholder de método truncado: Falla retenida en PLU-91.
  Locale override cambia idioma, no demuestra formato regional ni pronunciación.
- R: smoke táctil funcional PASS, configuración y registro siguientes.
- Inspector, VoiceOver/Voice Control/Switch Control, teclado, habla/orden/foco, contraste medido, físico,
  preferencias, orientación/iPad/ventanas/RTL y scrollAX5: Pendiente en PLU-91.

## Flujos

| Flujo | Evidencia | Resultado integral y recuperación |
|---|---|---|
| Borrador → inicio → líneas terminadas | S/T; aceptación/stale/replay durable y sesión retenida | Limitado; AT/foco real en PLU-91. |
| Método → solicitud suficiente/exacto0 | S/T/P; no confirmación extra, método obligatorio | Limitado; runtime y AT en PLU-91. |
| Déficit/unknown → mostrar/cancelar/repetir | S/T/P; cero efectos de negocio antes de consentimiento | Limitado; foco/scroll/lectura AT en PLU-91. |
| Continuar → pago → documento pendiente | S/T; cash/card, una aceptación y permanencia en Jornada | Limitado; habla/orden AT en PLU-91. |
| Retry/close/stale/callback tardío | T; mismo ID/fecha, sin duplicado/reapertura/sobrescritura | Limitado; retorno real con AT en PLU-91. |

## Matriz55criterios

Una fila por A/AA; N/A describe ausencia del mecanismo con motivo, no aplazamiento. Limitado/Pendiente/Falla
no son Pasa; ejecución integral se recupera en PLU-91 con owner/trigger arriba.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Símbolo decorativo oculto; aviso textual con nombre de servicio; botones y Picker nativos. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.2.1 | N/A | Sin audio/vídeo pregrabado. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.2 | N/A | Sin audio sincronizado pregrabado. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.4 | N/A | Sin contenido audiovisual en directo. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.3.1 | Aplicable | Form/Section agrupan términos, workflow y método; sheet separa explicación, servicios y acciones. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.3.2 | Aplicable | Orden declarado explicación, avisos, Continuar y Cancelar; recorrido AT pendiente. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.3.3 | Aplicable | Déficit o imposibilidad de comprobar se expresan en texto; acciones no dependen de posición/color. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.3.4 | Aplicable | Sin nuevo bloqueo; landscape, iPad y ventanas relevantes pendientes. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.3.5 | N/A | Aviso sin entrada personal; cantidad comercial. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.1 | Aplicable | ErrorInk adaptativo acompañado de símbolo y texto, sin condición basada solo en color. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.4.2 | N/A | Sin reproducción de audio de la app; Announcement pertenece a AT. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.3 | Aplicable | Cuatro apariencias representativas; botón usa onBrandPrimary; ratios finales pendientes. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.4.4 | Aplicable | Texto de sheet crece AX5; título nativo de detalle y placeholder de Picker truncados AX5. | Falla | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Título/Picker AX5 truncados; recuperar en PLU-91. | root registro parcial |
| 1.4.5 | Aplicable | Mensaje, cantidad y contexto usan Text/String Catalog, sin imágenes de texto. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.4.10 | Aplicable | Form/ScrollView verticales; scroll AX5 y ventanas estrechas pendientes. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.4.11 | Aplicable | Símbolo y controles requieren medición nativa final; símbolo también redundante con texto. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 1.4.12 | N/A | SwiftUI nativo sin markup que permita override de espaciado. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.13 | N/A | Sin contenido adicional propio exclusivo de hover/foco. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.1.1 | Aplicable | Botones de progreso/pago, Picker y cancelación nativos; Full Keyboard Access pendiente. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.1.2 | Aplicable | Entrada/salida de sheets y foco requieren AT real. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.1.4 | N/A | Sin atajos de un carácter. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.2.1 | N/A | Sin límite temporal del aviso/edición. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.2.2 | Condicional | Progreso nativo de carga; preferencias y operación de cierre requieren runtime. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.3.1 | Aplicable | Sin animación o destello propio en el aviso; transiciones nativas conservadas. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.1 | Aplicable | Encabezados de formulario; rotor y acceso al aviso por navegación pendientes. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.2 | Aplicable | Título sheet Revisar stock completo; título nativo de detalle truncado AX5. | Falla | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Título/Picker AX5 truncados; recuperar en PLU-91. | root registro parcial |
| 2.4.3 | Aplicable | Retorno declarativo al botón de pago con AccessibilityFocusState; ejecución AT pendiente. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.4 | Aplicable | Nombres de acciones existentes mantienen servicio/contexto; aviso no es enlace. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.5 | N/A | Detalle de un borrador; no nueva navegación de colección extensa. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.4.6 | Aplicable | Encabezado Servicios y pago; acciones de iniciar/completar incluyen nombre del servicio. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.7 | Aplicable | Foco visible con teclado pendiente; botones y Picker interactivos. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.4.11 | Aplicable | Scroll, barras, sheets y retorno con foco se verifican en runtime. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.5.1 | N/A | Sin gesto multipunto/trayectoria requerido. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.2 | Aplicable | Botones nativos sin down-event propio; cancelación idempotente sin aceptar pago. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.5.3 | Aplicable | Texto visible de acciones es nombre nativo; contexto de servicio incluido en progreso. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 2.5.4 | N/A | Sin activación por movimiento. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.7 | N/A | Sin arrastre requerido; scroll nativo y acciones por botón. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.8 | Aplicable | Acciones con altura mínima44pt; superficie efectiva de Picker/toolbar pendiente. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.1.1 | Aplicable | 13 nuevas claves es/en y recursos compilados verificados; pronunciación pendiente. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.1.2 | Condicional | Nombres capturados de servicios pueden usar otro idioma; pronunciación pendiente. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.2.1 | Aplicable | Sheet se abre por solicitud explícita; retorno de foco y anuncios AT pendientes. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.2.2 | Aplicable | Elegir método no paga; Registrar prepara; déficit/desconocido requiere Continuar explícito. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.2.3 | Aplicable | Mismo formulario/acciones/orden; integración local de aviso. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.2.4 | Aplicable | Reutiliza ErrorInk y anuncio moderno existentes; sin acción o rasgo bloqueante. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.2.6 | N/A | Sin mecanismos propios de ayuda repetida en este tramo. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 3.3.1 | Aplicable | Stock desconocido explícito y sin suficiencia falsa; errores de aceptación mantienen snapshot. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.3.2 | Aplicable | Método etiquetado, pago disabled sin elegir; explicación previa a Continuar. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.3.3 | Aplicable | Cancelar permite revisar; stale obliga recarga; error de pago admite retry del mismo comando. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.3.4 | Aplicable | Pago explícito; déficit/unknown requiere revisión y consentimiento; duplicados/stale rechazados. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.3.7 | Aplicable | Términos, método y comando conservados; no solicita reintroducir datos en retry. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 3.3.8 | N/A | Este recorrido no incorpora autenticación. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 4.1.2 | Aplicable | Botones/Picker nativos; bindings semánticos, nombres contextuales; Inspector/AT pendientes. | Limitado | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |
| 4.1.3 | Aplicable | Anuncio de pago aceptado y stock existente; habla/orden/foco real pendientes. | Pendiente | S/T/P parciales; R y límites abajo. | 02/10/2026; configuraciones arriba. | Evidencia integral en PLU-91 antes de uso real. | root registro parcial |

## Smoke táctil funcional

02/10, root; iPhone17Simulator27.2, Develop del build Xcode MCP, --franalonso-demo-workday.
Datos sintéticos en memoria; portrait/light/content_size extra-Small consultados, sin cambiar preferencias.
RocketSim HID taps/swipes, snapshots AX y dos PNG originales inspeccionados. Autenticación usa fixture
sintética existente; no backend/live/PII ni credencial persistida en evidencia.
[Manifest runtime](assets/12-4/runtime/manifest.json) conserva configuración/hashes y JSON sin contexto/token local.

| Comprobación | Observación | Artefacto |
|---|---|---|
| Progreso real | Bruno, profesional +Champú qty9 stock8, inicia venta/inicia/termina ambas líneas; conserva sesión, qty/descuentos/total161,42€; cambia a pendiente de pago. | [Progreso](assets/12-4/runtime/progress.json) |
| Solicitud con déficit | Método efectivo; Registrar presenta sheet -1 con Cancelar/Continuar; venta sigue pendiente de pago. | [Snapshot](assets/12-4/runtime/confirmation.json), [PNG](assets/12-4/runtime/confirmation.png) |
| Cancelar y repetir | Cancelar retorna al detalle, mismo total161,42€/método y pendiente de pago; otra solicitud vuelve a mostrar sheet. | [Transiciones](assets/12-4/runtime/cancel-repeat-pay.json) |
| Continuar | Sheet desaparece; pago registrado pendiente de ticket/factura, sin otro botón de pago; conserva total y permanece en Jornada. | [Transiciones](assets/12-4/runtime/cancel-repeat-pay.json), [PNG](assets/12-4/runtime/paid.png) |
| Cerrar/reabrir | Jornada muestra Pagada · pendiente de documento; reapertura retiene líneas terminadas, qty9 y descuentos. | [Reapertura](assets/12-4/runtime/reopened.json) |

PASS funcional concreto. La ausencia de operaciones por presentación/cancelación y duplicación de pago se
acredita con oráculos SwiftData T; el smoke no inspecciona colas/movimientos. Suficiente/exacto0/unknown, tarjeta,
fallos/retry/close se prueban T; no se simularon todos esos estados visualmente. No prueba habla, foco real, AT,
scrollAX5 ni persistencia tras reiniciar la fixture (la demo se reinicia por contrato). PLU-91 retiene pendientes.

Auditorías POST independientes: confirmation_post_standards focal PASS sin hallazgos;
confirmation_post_accessibility_fresh PASS funcional ADR0029, conservando2P2 AX5 selector/título truncados
y Falla/Pendiente/Limitado en PLU-91. No aprobación integral. Revisor UI inspeccionó10previews+2PNG/4JSONruntime,
55criterios/5flujos y estado/deuda en Linear. Huella root856archivos antes/después idéntica
`04b562137fd0907129d40ccd2cb09001f897d3a10d1ab2e0a3b085db3ca2fa46`, sin cambios por revisores.
Reconciliación documental posterior registra estos dictámenes; no cambia ejecutables ni evidencia validada.
