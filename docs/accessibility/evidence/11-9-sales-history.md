# 11.9 — Histórico, detalle terminal y navegación — 2026-10-02

Gate solicitado: **funcional demo ADR0029**, no validación integral ni certificación.
Alcance: SalesHistoryScreen/Content/Filters/Row, SaleDetailScreen/Content/LineRow/TraceSection,
títulos, estado, búsqueda, orden, errores/retry, sheets, retorno de foco y aviso demo/framing histórico.
Issue funcional [PLU-83](https://linear.app/plusprojects/issue/PLU-83); deuda propia
[PLU-84](https://linear.app/plusprojects/issue/PLU-84) Backlog/Jesus Franco. Recuperar tras feedback
con Fran y estabilizar este flujo, antes del primer candidato real. No cierra77/79/81 ni fase11.

## Construcción y correcciones

Una View/archivo, VM Observable MainActor por pantalla, tareas caller-owned y generaciones;
controles nativos Menu/Picker, labels persistentes, encabezados, agrupación por línea/traza,
objetivos44pt y wrapping vertical. Anulada: texto+icono y traza separada, importes originales retenidos.
Sin nueva acción de cobro, cierre, anular, editar ni borrar. Datos y muestras todos sintéticos.
El detalle no ofrece abrir PDF ni inventa numeración: document ID solo referencia materializada.

Solape/corte nativo de Picker a AX5 detectado en preview12:07:40; corregido con controles cuyos
labels/valores crecen verticalmente. Retest12:14:37 (3) y Filters12:13:39 sin solape.
El título largo del detalle se truncó en AX5; abreviado a Detalle/Details, retest AX5 claro12:27:27 sin recorte.
Previews no prueban desplazamiento/foco/AT ni contraste cuantitativo.

## Evidencia y límites

- XcodeMCP estable/SDK27, render real iPhone18ProMax/iOS27.2 (fallback aunque destino iPhone17).
- Previews HistoryContent: Large12:14:37/claro, XXXLarge12:14:37(2)/claro, AX5 12:14:37(3)/oscuro.
- DetailContent: Voided/Large12:14:49/claro, Closed/XXX12:14:50/oscuro, Voided/AX5 12:14:50/claro.
- FiltersAX5/oscuro12:13:39; rutas exactas en `/tmp/plu83-preview-evidence.json`.
- Screen History inicial12:02:16 captura loading/iPadPro13M5/27.2; no se interpreta como contenido.
- Dos intentos siguientes fallaron antes de lanzar por dyld/libSystem.B.dylib del dispositivo de preview
  iPad. Cambio de destino y preview fresh iPhone recuperó pipeline; no defecto atribuido al código.
- Smoke Simulator iPhone17/27.2:12/12 PASS, informe `/tmp/plu83-smoke-review.md`; sesión cerrada.
  Primera apertura/cierre/reapertura, filtros/orden original/búsqueda/reset, Jornada excluye terminales
  y conserva pagada sin documento; traza completa de anulada con pago/documento/reversión e importes17,42EUR.
- Retest título Detalle AX5/claro12:27:27 y TraceSectionAX5/oscuro12:27:48: wraps sin corte;
  viewport parcial no acredita recorrido runtime completo a AX5.
- TDD y tests VM/política/concurrencia/local SwiftData; suite nativa cerrada1353declaraciones/2180ejecuciones PASS,
  builds Develop-for-testing/Production sin warnings. Evidencia exacta en `docs/progress/phase-11.md`.
- VoiceOver, Voice Control, Switch Control, teclado, Inspector, ratios nativos en cuatro apariencias,
  Reduce Motion/Transparency, Increase Contrast/Without Color, orientación/ventanas/RTL:
  pendientes en PLU-84. Ningún smoke táctil acredita ejecución física AT.

### Hallazgos del POST UI y disposición ADR0029

POST inicial `/tmp/plu83-post-ui-review.md` CORRECT: faltaba render del nuevo aviso histórico dentro
del framing real. Se añaden previews propios deterministas banner=true/login/shell con trait compartido.
Large claro12:47:57/58, XXX oscuro shell12:46:47/login12:49:46, AX5 shell claro12:46:33/loginoscuro12:46:47.
Large standalone/login y XXX shell mantienen aviso completo. Shell Large12:47:58 capturó parte
del banner fuera del borde superior; no se declara PASS de ese render y se retiene en PLU-84, mientras
el smoke runtime default confirma aviso completo. LoginXXX12:49:46 también captura el banner
fuera del borde superior: evidencia parcial retenida en PLU-84; no PASS de ese snapshot. AX5 conserva viewport principal pero
recorta visualmente el nuevo aviso (Falla1.4.4/1.4.10), registrado en PLU-84. Se aplaza conforme aADR0029
como defecto accesible conocido hasta feedback/estabilización antes del primer candidato real.
Título/reset del banner preexistente también recortan aAX5; su deuda PLU-48 no se transfiere ni se cierra.
No se acredita recorrido físico/teclado de login aAX5; el smoke12/12 con tamaño predeterminado sigue válido.
P3 concreto4.1.3: SaleDetailScreen anuncia error/ausencia, no closed→voided; gap retenido Limitado/PLU-84,
sin afirmar fallo de VO no ejecutado. Renders del encuadre no prueban lectura completa con AT.

## Matriz completa por flujo

H=Histórico (incluye filtros/búsqueda/filas); D=detalle/traza; N=navegación/carga/error/retry/cierre.
Cada fila aplica a ambos destinos y al cruce indicado; N/A expresa ausencia de capacidad en11.9.
Revisor root estático/preview; POST UI inicial CORRECT por falta de evidencia del aviso nuevo. Retest focal PASS funcional ADR0029; integral pendiente. Configuración arriba.
En filas N/A, Pasa acredita exclusivamente inspección de ausencia de esa capacidad.
Limitado/Pendiente conserva la falta de ejecución integral; no se convierte en aprobado por el gate demo.

| ID | Aplicabilidad H/D/N | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable H/D/N | Iconos decorativos acompañan texto; nombres/roles AT aún pendientes H/D/N. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.2.1 | N/A H/D/N | Sin audio ni vídeo pregrabado. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.2.2 | N/A H/D/N | Sin medios sincronizados. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.2.3 | N/A H/D/N | Sin vídeo. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.2.4 | N/A H/D/N | Sin emisiones en directo. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.2.5 | N/A H/D/N | Sin vídeo pregrabado. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.3.1 | Aplicable H/D/N | H: secciones y labels; D: encabezados y líneas agrupadas; N: estados nativos. Jerarquía AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.3.2 | Aplicable H/D/N | Orden visual H por cierre, D estado/líneas/importes/traza; orden AT completo pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.3.3 | Aplicable H/D/N | Copy no depende de posición/color; referencias y fechas explícitas. | Pasa | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 1.3.4 | Aplicable H/D/N | H/D/N no fijan orientación; recorrido horizontal y ventanas pendientes. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.3.5 | N/A H/D/N | Búsqueda de servicios/referencia, sin campos personales. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.4.1 | Aplicable H/D/N | Anulada usa texto+icono; Differentiate Without Color runtime pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 1.4.2 | N/A H/D/N | Sin audio automático. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.4.3 | Aplicable H/D/N | Ratios del render nativo final no medidos; pendientes cuatro apariencias. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.4.4 | Aplicable H/D/N | H/D wraps representativos; aviso demo histórico en framing real trunca texto aAX5, con viewport principal conservado. | Falla | Preview framing AX5 12:46:33/47; registro arriba | 2026-10-02; config del registro arriba | Defecto nuevo aviso retenido PLU-84/ADR0029; baseline PLU-48 separado. | root + POST UI independiente |
| 1.4.5 | N/A H/D/N | Sin imágenes de texto. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.4.10 | Aplicable H/D/N | H/D wraps representativos; aviso demo histórico en framing real trunca texto aAX5, con viewport principal conservado. | Falla | Preview framing AX5 12:46:33/47; registro arriba | 2026-10-02; config del registro arriba | Defecto nuevo aviso retenido PLU-84/ADR0029; baseline PLU-48 separado. | root + POST UI independiente |
| 1.4.11 | Aplicable H/D/N | Ratios del render nativo final no medidos; pendientes cuatro apariencias. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 1.4.12 | N/A H/D/N | SwiftUI nativo sin markup ni override de espaciado. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 1.4.13 | N/A H/D/N | Sin ayudas adicionales al hover/foco. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 2.1.1 | Aplicable H/D/N | Controles nativos H/D/N; recorrido completo de teclado y Full Keyboard Access pendiente. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.1.2 | Aplicable H/D/N | Sheet nativa con Cerrar; salida con teclado/AT y ausencia de trampa pendiente. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.1.4 | N/A H/D/N | Sin atajos de un carácter. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 2.2.1 | N/A H/D/N | Sin límite temporal. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 2.2.2 | Aplicable H/D/N | Carga con ProgressView y stream sin animación propia; conducta AT durante actualización pendiente. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.3.1 | Aplicable H/D/N | Sin animaciones o medios propios con destellos. | Pasa | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 2.4.1 | Aplicable H/D/N | H/D: secciones y encabezados; rotor/salto de bloques y N retorno pendientes. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.2 | Aplicable H/D/N | Título Histórico/Detalle localizado; anuncio AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 2.4.3 | Aplicable H/D/N | Intención de retorno a origen/filtro; no se afirma restauración física. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.4 | Aplicable H/D/N | Filas Button con servicio/cliente/estado/cierre; propósito AT y lectura agrupada pendientes. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.5 | Aplicable H/D/N | Consulta read-only por búsqueda/filtro/lista; alternativas AT completas pendientes. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.6 | Aplicable H/D/N | Estado/Orden persistentes; H Histórico y D Detalle; verificación semántica AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.7 | Aplicable H/D/N | Foco nativo y AccessibilityFocusState; indicadores visibles con teclado/AT pendientes. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.4.11 | Aplicable H/D/N | H List/D Form scroll y sheet nativa; foco no oculto en teclado/AX5 pendiente. | Pendiente | Pendiente; PLU-84 | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.5.1 | Aplicable H/D/N | Button/Menu/Picker/Cerrar y scroll nativos; equivalencia Switch/Voice Control pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.5.2 | Aplicable H/D/N | Sin gesto propio de pulsación; activación Button nativa; cancelación con AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.5.3 | Aplicable H/D/N | Texto visible Estado/Orden usado en label accesible; filas con texto nativo; Voice Control pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 2.5.4 | N/A H/D/N | Sin activación por movimiento. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 2.5.7 | N/A H/D/N | Sin drag obligatorio; scroll y controles nativos. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 2.5.8 | Aplicable H/D/N | Controles/filas con mínimo44pt; verificación nativa de todos los targets pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 3.1.1 | Aplicable H/D/N | 33 claves nuevas es/en y LocalizedStringResource con locale en anuncios; pronunciación AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 3.1.2 | N/A H/D/N | Copy es/en; nombres capturados sin idioma conocido, no se inventa locale. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 3.2.1 | Aplicable H/D/N | Foco no emite intención de navegación; apertura sólo onSelect; recorrido AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 3.2.2 | Aplicable H/D/N | Filtro/orden/query no cierran el detalle; pruebas VM; anuncio de actualización AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 3.2.3 | Aplicable H/D/N | Tab existente/sheet nativa; comparación estática y smoke, AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 3.2.4 | Aplicable H/D/N | Cerrar/Reintentar y estilos existentes; revisión enfocada, AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 3.2.6 | N/A H/D/N | Sin mecanismos de ayuda repetidos en este flujo. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 3.3.1 | Aplicable H/D/N | Error genérico localizado, retry; no logs de error/PII. AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 3.3.2 | Aplicable H/D/N | Labels persistentes Estado/Orden y prompt explícito búsqueda. AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 3.3.3 | Aplicable H/D/N | Reintentar carga/restablecer filtros; prueba VM y smoke, AT pendiente. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Pendiente AT si Limitado; PLU-84 | root + POST UI independiente |
| 3.3.4 | N/A H/D/N | Consulta sin mutaciones financieras/legales/destructivas. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 3.3.7 | N/A H/D/N | Sin solicitud redundante de datos. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 3.3.8 | N/A H/D/N | Sin nueva autenticación; login fixture solo precondición de smoke. | Pasa | Inspección11.9 | 2026-10-02; config del registro arriba | Ausencia comprobada; no prueba AT aplicable. | root + POST UI independiente |
| 4.1.2 | Aplicable H/D/N | Button/Menu/Picker nativos y labels/value explícitos filtros; Inspector/AT roles/valores pendientes. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |
| 4.1.3 | Aplicable H/D/N | Anuncio nativo de error/ausencia; cambios closed→voided y recorrido AT pendientes. | Limitado | Static/Preview/Test; registro arriba | 2026-10-02; config del registro arriba | Retomar PLU-84 | root + POST UI independiente |

## Handoff de revisión

POST técnico PASS y UI CORRECT→retest PASS funcional; informes `/tmp/plu83-post-technical-review.md`,
`/tmp/plu83-post-technical-retest-review.md`, `/tmp/plu83-post-ui-review.md` y `/tmp/plu83-post-ui-retest-review.md`.
Cada revisión operacionalmente read-only ratificada mediante4FULL JSON iguales,795archivos; retests
digest`e8bac25864134d472049f111431c507bb30c1446c41e5e6a59ac2366893824f3`.
55filas:2Falla,20Limitado,12Pendiente,21Pasa (ausencias N/A incluidas); no evidencia AT/Inspector inventada.
Gate de entrega funcional demo ADR0029, con deuda PLU-84 vigente; entrega Git verificada en [PR41](https://github.com/JFrancoG/FranAlonso/pull/41); PLU-83 Done funcional.
PLU-84/deuda integral y fase11 permanecen abiertas; esta entrega no cambia los resultados de la matriz.
