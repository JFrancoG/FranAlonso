# 12.3 — Advertencia visual de stock

2026-10-02, PLU-88/Jesus Franco, hija PLU-85. Autorización: «abre issue y rama e implementa12.3».
Base main/origin-main limpia `a938332`; rama `codex/plu-88-sale-stock-warning-ui`.

## Alcance aprobado por la solicitud

Exponer desde SaleDraftViewModel los impactos con requiresWarning por identidad de línea, únicamente desde ready
editable/no cerrado. La View no filtra ni recalcula stock. Idle/loading/failed no presentan impactos viejos y su
omisión nunca afirma suficiencia. Read-only profesional/inspección no consulta ni presenta proyección de borrador.
SaleDraftContent pasa el impacto a SaleDraftLineRow; componente nuevo SaleStockWarningView bajo los términos
capturados y antes de controles: Label/SF Symbol exclamationmark.triangle.fill, Text localizadoes/en, ErrorInk
existente con cuatro apariencias. No dependencia solo del color; símbolo decorativo oculto, nombre accesible incluye
el nombre de servicio y texto visible, sin acción/rasgo de error bloqueante. Texto dinámico, wrapping sin lineLimit,
font subheadline y fixedSize vertical. Números con locale del entorno; stock proyectado acumulativo de12.1/12.2.

SaleDraftViewModel deduplica avisos accesibles por identidad de línea en ready: consumir un anuncio solo cuando
aparecen nuevas líneas advertidas. Estado efímero de comunicación, no duplicación de venta/cálculo. Loading/error
no borra deduplicación; ready sin avisos rearma; close/inspect no comunica. Test primero para proyección y dedup.
SaleDraftScreen usa el anuncio moderno existente, sin mover foco ni introducir timers/tareas: tras operación acepta
un único mensaje (warning nuevo o éxito actual); observación de stock/retorno de sheets cubre cambios delegados y
refresco fuera de la operación. Se difiere mientras haya request/sheet abierto y se consume al volver. Evitar anuncios
paralelos de éxito/stock; foco y sheets existentes se conservan. Runtime VoiceOver no se acredita por tests/previews.

Preview de componente/fila/contenido/pantalla con trait compartido y fixtures nuevas aisladas en App: stock1,
primera línea vinculadaqty1 (agotamiento exacto), segunda mismo productoqty2 (proyección-2), profesional sin vínculo.
Se usa ModelContainer in-memory/repositories reales y claves estables; no cambiar fixtures históricas ni datos demo
existentes. Previews navegables y estado simple sin advertencia. Archivos esperados: nuevo warningView, Row,
Content, Screen, VM, fixture/modifier App, catálogo, tests focales y docs.

## Autoridad, alternativas y fuentes

Constitución/spec12/ADR0003/0011/0022/0029/políticaSwift. Sin modificación Domain/Data/Store12.2/pago/sync.
Reutilizar ErrorInk frente a Color.red fijo, para contraste adaptativo. No recalcular déficit en View; se muestra
la cantidad proyectada ya publicada. No desactivar controles ni pedir confirmar: corresponde a12.4.
No nuevo Store/protocolo, dependency, unsafe, target, activación live ni entrega.
Fuentes Apple leídas mediante Cupertino: [Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement)
y [accessibilityLabel](https://developer.apple.com/documentation/swiftui/text/accessibilitylabel(_:)).
SDK/target reales27.0, Swift6/nonisolated/strictcomplete/warnings-as-errors. Xcode estable workspace-PfnUYLlMzY,
Develop/planDevelop, iPadPro13(M5) Simulator27.2. Solo runtime27.2 disponible; no elevar target ni instalar recursos.

## Validación y riesgo

12.2 fuente/config/tests intactos:153/153 +18/18, builds y PRE/POST PASS, PR43 integrada. Baseline actual preview
Draft falla antes de cualquier implementación por dyld/libSystem.B.dylib/shared cache ausente del runtime27.2;
no fallo de la nueva UI. Reintento seguro/destino alternativo, sin borrar caches ni simuladores.
TDD proyección por ID y supresión en estado no listo/inspect/closed, nuevos avisos, dedup/recuperación, no efectos de
negocio. Regresión Store/VM/stock/semántica, catálogos, buildsDevelop/Production, diagnósticos y diff.
Descubrir variantes soportadas primero; render/inspección Large/XXXL/AX5 de pantalla y componente representativos,
es/en y Light/Dark/contraste; no repetir matriz histórica ajena. Si entorno bloquea previews, registrar evidencia
limitada y no presentar el gate de render como completado. Sin reparación destructiva de entorno.

Matriz nueva12.3 con cada criterio A/AA y aplicabilidad. Bajo ADR0029 crear issue vinculada específica para evidencia
integral pendiente: Inspector/AT/contraste medido/ventanas/RTL/preferencias, responsableJesus, retomar tras feedback y
estabilización del flujo, siempre antes de candidato real. No transferir deuda11 previa. Operación de la demo e
integridad siguen obligatorias. Auditorías POST técnica y UI independientes con hash completo antes/después.
Progress tiene8191bytes: reemplazar/compactar entrada actual, conservar detalle en fase/matriz; no añadir historial.

PRE independiente: PASS sin hallazgos, agente fresco stock_warning_proposal_review, read-only operacional.
803files, SHA256 antes/después idéntico: `a2c49a5cadc7eb5fc45e544c5523cef980d79e5a24c72fdda541cd8b3a08b627`.
Baseline actual30/30PASS (Stock/Screensemantics). Preview de fila renderiza en iPhone18ProMax27.2 al seleccionar
iPhone17 como destino; pantalla original sigue fallando en su host iPad privado. Se usará host compatible descubierto.
El revisor conserva como pendiente el orden real de habla/foco: consumo de anuncios solo al comunicar, nunca al diferir.
 Commit/push/PR/merge/cierre,12.4 y live no autorizados.
