# Propuesta13.4 — BillingDocumentStore y BillingViewModel

03/10/2026. Alcance autorizado por «abre issue y rama e implementa13.4».
[PLU-99](https://linear.app/plusprojects/issue/PLU-99), Jesus Franco, In Progress;
rama `codex/plu-99-billing-document-state` desde main/origin/main limpio `8256d3b`.
13.1–13.3 entregadas. Esta autorización incluye implementar este alcance tras PRE favorable;
no incluye commit/push/PR/merge/Done,13.5 ni live.

## Autoridad y baseline

Constitución, spec13, ADR0008/0011 y política Swift. Profile maintenance por arquitectura aceptada;
sin ADR nuevo, dependencias, opt-outs ni cambio de target. Xcode MCP estable27.0 Service confirma
workspace-PfnUYLlMzY y FranAlonso.xcodeproj; Develop/plan Develop, iPadPro13(M5), Simulator27.2/SDK27.0.
GetTargetBuildSettings: Swift6, strict complete/default nonisolated, deployment27.0,
Swift/Clang warnings-as-errors. Baseline13.3:2493/2493 ejecuciones/1534declaraciones,
builds Develop/Production PASS; dos avisos AppIntents conocidos por build y seis enlaces08.3 pendientes.
No rerun previo de código idéntico. Stock histórico pasó, sin corrección de intermitencia.

## Comportamiento exacto

Dos observables @MainActor, genéricos por el Repository ya aprobado. ViewModel instancia y conserva
Store privado; estado y request/documento/ocupación/posibilidad de reservar son getters calculados,
sin copiar estado ni errores y sin timers, publishers, Task almacenadas o efectos en init.

Una única propiedad de estado Store:

- selection: aún no hay solicitud preparada.
- allocation(BillingDocumentLocalState): pendiente, fallida o numerada; reutiliza Domain existente.
- reserving(BillingDocumentRequest): un intento en curso del request exacto.
- closed(BillingDocumentLocalState?): presentación terminal con valor recuperable retenido.

La proyección localState de reserving es pendingNumber, sin número local; closed conserva el snapshot
para que el dueño pueda recuperarlo, pero no implementa persistencia13.10. Solo Store almacena esta
máquina. Token UUID privado @ObservationIgnored identifica intentos; no es una identidad comercial.

prepare(request) recibe el valor inmutable ya validado por Domain y no hace I/O ni genera ID/fecha.
Una sesión acepta una sola solicitud; repetirla exactamente es no-op, incluido después de número/fallo.
Una distinta se rechaza sin perder la anterior. prepare/reserve durante un intento se rechazan como busy;
closed rechaza acciones nuevas. Cambio de familia/fiscalidad antes de preparar pertenece al flujo13.5.

reserve() hace un único intento mediante ReserveBillingDocumentUseCase; un nuevo intento explícito
reutiliza siempre el request completo. No reintenta automáticamente. Estado numbered devuelve el mismo
documento sin otro contacto; no retrocede. Fallo unavailable/permissionDenied/conflict se proyecta a
BillingDocumentFailure correspondiente; invalidResponse se representa unavailable, sin publicar payloads.
El error neutral se propaga al caller y se conserva la solicitud. No hay lastError mutable duplicado.

Cancelación de la task antes/después del await conserva pendingNumber; incluso si el servidor comprometió,
no inventa ni descarta la solicitud. cancelReservation() invalida publication del intento y retorna a
pendingNumber; no promete cancelar la task propiedad del caller ni deshacer el servidor. Un retorno/error
antiguo tras cancel/retry/close arroja CancellationError y no modifica la nueva operación. close() termina
esta presentación e invalida respuestas, conservando el último localState. No cierra la venta ni consume número.

VM delega prepare/reserve/retry/cancelReservation/close; retry es una intención explícita hacia el mismo
intento Store. Sin rutas, navegación concreta ni composición App hasta que exista pantalla13.5.

## Fronteras y alternativas

Cambiar únicamente Billing/Presentation/Stores/BillingDocumentStore.swift,
Billing/Presentation/ViewModels/BillingViewModel.swift, nuevas fixtures/tests Swift Testing y tres docs
(propuesta,phase13,Progress). Domain/Data/Sales/App/configuración y14Swift13.1–13.3 permanecen byte-exact.
No Views/strings/previews, fiscal model/form, plantillas/firma, PDF/Storage/correo/SwiftData/cierre13.12,
Rules/deploy, bootstrap ni tráfico real. UI/accesibilidad N/A: modelos sin superficie visible;
deuda previa conserva issue/responsable/recuperación antes del primer candidato real.

Alternativas: ViewModel único descartado por responsabilidad cohesiva de reserva/cancelación y spec expresa.
Estado mutable duplicado o booleans independientes descartados por combinaciones incoherentes.
Task interna/unstructured y retry automático descartados: el caller posee el lifecycle async y el reintento
es explícito. Copiar Sales accepted-write-wins descartado: Billing UseCase cancela después del contacto remoto.
Reimplementar Domain states descartado; enum exterior solo añade lifecycle de presentación.
Existen seam Repository genérico y UseCase reales, sin protocolo/closure ceremonial adicional.

## TDD y validación

Primero stubs compilables y tests RED de comportamiento; GREEN después. Oráculo: request/docs sintéticos
fijos y ledger/gates deterministas en seam Repository, sin backend, sleeps ni producción.
Cubrir familia ticket/factura, prepare/no-I/O/sealed request, fallo neutral y retries exactos,
respuesta perdida tras commit/un único número, numbered monotónico/no segundo contacto,
busy sin mutación, task cancel previa/en curso/postcommit, cancel/close y éxito/error antiguos
solapados con nueva reserva, cierre terminal con retención, proyecciones VM y Observation tracking real.
Reutilizar Domain fixtures disponibles sin editar tests históricos; propiedad caller mediante tasks en tests.

Xcode MCP: build-for-testing Develop, RED focal, GREEN/regresión Billing y global definitiva cuando corresponda;
Production build y logs completos/diagnósticos. Descubrir IDs GetTestList y verificar matriz parametrizada
nativamente si RunSomeTests recorta argumentos. Sin xcodebuild ni claim de clean-build/CI/remoto/runtime UI.
PRE fresh read-only y POST fresh read-only más Audit estilo independiente, freeze tracked+untracked no ignorados.
Corregir hallazgos y repetir solo gate afectado; docs/Progress/Linear reconciliados como implementación local.

## Fuentes primarias actuales

Apple DocumentationSearch (MCP27.0,03/10/2026) para Task.checkCancellation: siempre lanza CancellationError;
Task.detached documenta propiedad explícita y recomienda structured children. Observation usa acceso a propiedades;
getters VM leen el Store observable dentro del tracking, probado con withObservationTracking en tests.

- [Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation())
- [Task.cancel](https://developer.apple.com/documentation/swift/task/cancel())
- [Managing model data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [withObservationTracking](https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:))
- [SE0304 structured concurrency](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)

Markdown oficial Apple leído mediante curl con verificación TLS normal el03/10/2026: withObservationTracking
(documenta acceso/onChange Sendable), Managing model data (getters calculados sobre observables) y Task.cancel
(cooperativa/idempotente, no detiene funciones arbitrarias). El web tool no aceptó text/markdown y urllib falló
por certificados; no se desactivó TLS. MCP y estos Markdown aportan evidencia primaria. Resultado legacy
ObservedObject de búsqueda no se adopta. Copias de evidencia en /tmp/franalonso-13-4-apple-*.md.

PRE independiente PASS sin hallazgosP0–P3;920archivos, freeze inicial/final/root
`ed7bc5e954faef3b46254793de2fef5c934b22f081db719ba7c3541852a32ee5`.
La autorización inicial del propietario cubre implementar este alcance tras PRE favorable.

## Riesgos y reversibilidad

La cancelación no demuestra rollback remoto: retener request es obligatorio. Protección por token para cada
await/catch impide contaminación de reintentos nuevos. La retención en memoria no acredita reinicio durable;
13.10 seguirá materialización/recuperación. Datos fiscales aún no modelados no se inventan. No se publican
estados render/upload/email ficticios. Todo nuevo código queda sin wiring y se revierte sin modificar históricos.
