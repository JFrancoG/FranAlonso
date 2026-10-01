# 11.5 — Jornada y detalle operativo

2026-10-01. Construcción y validación progresiva según [ADR0022](../../ADRs/0022-native-ios-wcag22-accessibility.md)
y [ADR0029](../../ADRs/0029-progressive-accessibility-validation.md). No acredita validación integral.
[PLU-76](https://linear.app/plusprojects/issue/PLU-76) implementa el flujo; deuda propia
[PLU-77](https://linear.app/plusprojects/issue/PLU-77), Backlog, Jesus Franco, hija de fase11/PLU-71.
Recuperar tras feedback de Fran y estabilización de cada flujo, antes del primer candidato para uso real y cierre integral.
No absorbe deuda de08–10/16. La fase11 permanece activa; entrega Git11.5 autorizada y en curso.

## Construcción y evidencia retenida

Dos Screens y cinco subviews, una View/archivo y preview propio. Tablero conserva operaciones independientes y antiguas,
cliente opcional y awaitingDocument pagada. Detalle tiene un Store, cantidades acotadas y snapshots monetarios.
Cerrar conserva lo aceptado; retirar línea y descartar venta tienen confirmaciones nativas separadas.
Inspección en curso/pago/documento solo lectura. Navegación y resultados tardíos cercados por identidad de sesión.
Controles nativos, wrapping, mínimo44pt solicitado, estados textuales y errores sanitizados ES/EN;
no equivale a medir hit area o contraste ni a demostrar VoiceOver. Foco de retorno sin timers y anuncios declarados.

Focal nativa69 declaraciones/99 variantes PASS y regresión1.231/1.934 PASS por Xcode MCP,
iPad Pro13-inch(M5) Simulator27.2; bundles cerrados y parseados, cero fallos/skips/expected/runtimeWarnings.
Localización485 textos ES/EN, validador sin errores. Builds Develop-for-testing19.346s y Production21.066s PASS,
cero warnings Swift/Clang; avisos AppIntents metadata conocidos separados. Smoke detectó hit area parcial en
Button plain; PRE independiente aprobó contentShape interaction y build focal9.899s PASS. Retest táctil de la fila PASS; POST UI funcional PASS.
Los artefactos y límites se registran en [fase11](../../progress/phase-11.md).

## Matriz completa de55 criterios A/AA

Todas las filas se inspeccionan estáticamente el01/10/2026. Limitado conserva ese alcance; Pendiente requiere ejecución.
Método previsto: renders representativos y smoke táctil, seguidos por Inspector/mediciones y AT integral en PLU-77.
Dispositivo/build de la inspección estática N/A; destinos y artefactos reales de ejecución se registran por separado.
No se extrapola una captura de iPad a iPhone, ni una interacción táctil a operación por tecnología de asistencia.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método y recuperación |
|---|---|---|---|---|
| 1.1.1 | Aplicable | Labels nativos para iconos y acciones; contenido agrupado en filas. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.2.1 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.2.2 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.2.3 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.2.4 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.2.5 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.3.1 | Aplicable | List/Form/Section y encabezados programáticos; cantidad como control nativo. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.3.2 | Aplicable | Orden declarado: cliente, estado, snapshot, cantidad y totales. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.3.3 | Aplicable | Estado y errores se describen en texto, sin depender de posición/color. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.3.4 | Aplicable | No se añade bloqueo de orientación; faltan landscape/ventanas. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.3.5 | N/A | No se solicitan datos personales ni autofill; solo cantidades comerciales. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.4.1 | Aplicable | Borrador/en curso/pago/documento y errores tienen etiquetas textuales. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.2 | N/A | Sin audio ni vídeo en Jornada/detalle. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.4.3 | Aplicable | Colores semánticos existentes; ratios del render final sin medir. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.4 | Aplicable | Texto semántico multilínea; previews representativos Large/XXX Large/AX5. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.5 | Aplicable | Nombres, estados, cantidades e importes son Text reales. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.10 | Aplicable | List/Form desplazan verticalmente; filas y totales permiten wrapping. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.11 | Aplicable | Controles nativos; ratios de controles/estados sin medir. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni override de espaciado de autor. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 1.4.13 | N/A | No hay contenido adicional propio activado por hover o foco. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.1.1 | Aplicable | Button/Stepper nativos; recorrido FKA completo pendiente. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.1.2 | Aplicable | Cerrar y confirmaciones nativos; entrada/salida por teclado/SC pendiente. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.1.4 | N/A | No hay atajos propios de un solo carácter. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.2.1 | N/A | Sin límite temporal de edición o confirmación. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.2.2 | N/A | Sin medio/carrusel automático; observación local de acciones y progreso nativo. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.3.1 | Aplicable | Sin destellos ni animación propia en el delta. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.1 | Aplicable | Tres grupos con encabezados y detalle modal contextual. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.2 | Aplicable | Jornada, borrador y detalle tienen título localizado. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.3 | Aplicable | Retorno solicita fila origen o crear; fence de sesión y sin timers. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.4 | Aplicable | Abrir, crear, cerrar, retirar, conservar, descartar y reintentar explícitos. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.5 | Aplicable | Tablero clasificado por estado; navegación por listas y contexto de operación. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.6 | Aplicable | Encabezados Próximas/En curso/Pendientes e Importes/Servicios descriptivos. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.7 | Aplicable | Foco nativo de teclado; falta evidencia de visibilidad real. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.4.11 | Aplicable | Form desplazable y sheet/diálogos; falta recorrido del foco en AX5. | Pendiente | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.5.1 | N/A | No se requieren gestos multipunto ni trayectoria; controles simples nativos. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.5.2 | Aplicable | Button/Stepper nativos, sin evento down propio; confirmación antes de eliminar. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.5.3 | Aplicable | Rótulos de retirar y cantidad integrados en sus nombres accesibles con contexto. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 2.5.4 | N/A | No hay activación por movimiento. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.5.7 | N/A | No se exige arrastre; botones, Stepper y desplazamiento nativo. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 2.5.8 | Aplicable | Filas, Stepper y acciones solicitan44pt; hit areas nativas sin medir. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.1.1 | Aplicable | ES/EN y formatos por Locale, incluidos anuncios; pronunciación pendiente. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.1.2 | N/A | Copy localizado monolingüe; nombres de clientes/servicios son datos de negocio. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 3.2.1 | Aplicable | Recibir foco no inicia mutaciones ni navegación. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.2.2 | Aplicable | Cantidad se modifica con intención explícita; no navega al editar. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.2.3 | Aplicable | Pestaña estable, sheet tipada y patrón nativo de formularios. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.2.4 | Aplicable | Acciones nativas coherentes entre tablero y detalle. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.2.6 | N/A | Sin mecanismos de ayuda repetidos nuevos. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 3.3.1 | Aplicable | Error de acción/load localizado, estado visible y anuncio; sin error del proveedor. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.3.2 | Aplicable | Labels de cantidad/servicio; nueva creación explica conservación al cerrar. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.3.3 | Aplicable | Error ofrece reintento y conserva snapshot aceptado; ausencia se diferencia. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.3.4 | Aplicable | Retirar línea y descartar borrador confirmados por separado; cerrar conserva. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.3.7 | Aplicable | Detalle carga contenido aceptado; errores no piden reintroducir datos. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 3.3.8 | N/A | No cambia autenticación; conserva el gate protegido y deuda propia del flujo previo. | N/A | Inspección de alcance; reevaluar si aparece el mecanismo. |
| 4.1.2 | Aplicable | Button/Stepper/Form nativos con labels, valores, estado y readonly. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |
| 4.1.3 | Aplicable | Anuncio de aceptación/error y carga etiquetada; orden/entrega reales pendientes. | Limitado | Estática; completar evidencia integral por impacto en PLU-77 antes de uso real. |


## Renders representativos y smoke retenido

Manifiesto completo17 renders: `/tmp/plu76-previews-final.json`. Todos los snapshots existen y fueron inspeccionados.
Base: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.
Los renders prueban el contenido visible; no hit areas/contraste medidos, foco ni operación por AT.
WorkdayScreen permanece en carga inicial en el snapshot; Content preparado y smoke cubren el tablero.
SaleDraftScreen listo presenta fallback antes de completar lookup; nombres preparados en Content y resueltos en runtime.
Scroll fuera del viewport no equivale a recorte de layout. La selección de lengua no prueba Locale de formatos del sistema.

| Definición | Variante/lengua | Destino27.2 | Snapshot |
|---|---|---|---|
| Accepted draft | Large/es;Light Appearance | iPhone 18 Pro Max | `Accepted draft - 2026-10-01 at 20.42.23.png` |
| Several clients | AX 5/en;Dark Appearance | iPad Pro 13-inch (M5) | `Several clients - 2026-10-01 at 20.29.44.png` |
| Workday | Large/es;Light Appearance | iPad Pro 13-inch (M5) | `Workday - 2026-10-01 at 20.21.54.png` |
| Accepted draft | XXX Large/es;Light Appearance | iPhone 18 Pro Max | `Accepted draft - 2026-10-01 at 20.43.00.png` |
| Accepted draft | AX 5/en;Dark Appearance | iPhone 18 Pro Max | `Accepted draft - 2026-10-01 at 20.43.04.png` |
| In progress content | Large/es;Light Appearance | iPhone 18 Pro Max | `In progress content - 2026-10-01 at 20.43.08.png` |
| Awaiting payment content | XXX Large/en;Light Appearance | iPhone 18 Pro Max | `Awaiting payment content - 2026-10-01 at 20.43.12.png` |
| Awaiting document content | AX 5/es;Light Appearance | iPhone 18 Pro Max | `Awaiting document content - 2026-10-01 at 20.43.17.png` |
| Empty | Large/es;Light Appearance | iPhone 18 Pro Max | `Empty - 2026-10-01 at 20.43.54.png` |
| Several clients | XXX Large/es;Light Appearance | iPhone 18 Pro Max | `Several clients - 2026-10-01 at 20.43.55.png` |
| Workday | XXX Large/es;Light Appearance | iPhone 18 Pro Max | `Workday - 2026-10-01 at 20.44.07.png` |
| Workday | AX 5/en;Light Appearance | iPhone 18 Pro Max | `Workday - 2026-10-01 at 20.44.11.png` |
| Draft | Large/es;Light Appearance | iPhone 18 Pro Max | `Draft - 2026-10-01 at 20.44.23.png` |
| Draft | XXX Large/es;Light Appearance | iPhone 18 Pro Max | `Draft - 2026-10-01 at 20.44.24.png` |
| Draft | AX 5/en;Light Appearance | iPhone 18 Pro Max | `Draft - 2026-10-01 at 20.44.29.png` |
| Draft | Large/es;Light Appearance | iPhone 18 Pro Max | `Draft - 2026-10-01 at 20.58.32.png` |
| Several clients | AX 5/es;Dark Appearance | iPhone 18 Pro Max | `Several clients - 2026-10-01 at 20.58.44.png` |

Smoke funcional tras corrección: PASS. iPhone17 Simulator27.2, ES/portrait; informe completo
`/tmp/plu76-smoke-report.md` y31 juegos de hierarchy/screenshot/log existentes. Root cierra la sesión.
Crear/Close antes de aceptar sin write, Create/Close/reopen persistente dentro del proceso demo, cantidad2/48,40€,
retirar cancel/confirm0€, discard cancel/confirm,3readonly y tab roundtrip. No acredita persistencia entre procesos/live/AT.
La retirada usa popover nativo: cancelación táctil fuera del popover, sin botón Cancelar visible; operación AT pendiente.

Defectos y recuperación:

| Defecto | Evidencia anterior | Corrección y retest | Estado actual |
|---|---|---|---|
| Retirada durable sin confirmación, detectada en review UI | P2 estático; no se aplaza | confirmationDialog antes de request.remove; smoke cancelar conserva2/48,40, confirmar0 | Corregido funcionalmente; AT Pendiente |
| Hit area parcial de Button plain | Falla: centro no abre dos veces,20_50_38_578; texto hijo abre20_51_10_325 | PRE focal, contentShape interaction;21_00_44_248/21_01_17_717/21_01_37_991/21_02_09_756 abren al primer toque | Retest funcional PASS; medición/AT Limitado |

La matriz55 mantiene sus límites; estas correcciones no convierten una revisión parcial en Pasa integral.


## Dictamen independiente

workday_ui_post: PASS para gate funcional de demo ADR0029, sin hallazgos abiertos accionables.
El agente inspeccionó17 snapshots, fuente UI/VM/factories y56claves ES/EN,31 juegos de artefactos smoke,
seis jerarquías focales y tres screenshots después de contentShape. No ejecutó Xcode ni escribió archivos.
Root certifica JSON íntegro734 archivos idéntico antes/después,
`e194eb3268e1c9a09ae01cec3993c0b2840f6517ba4fac779dff17ebf4f99642`.
55 criterios:37Aplicable (29Limitado y8Pendiente),18N/A motivados. No hay Pasa integral.
PLU-77 conserva todos los pendientes; entrega funcional local validada no equivale a cierre integral ni entrega Git.
