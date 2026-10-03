# 13.2 — Reserva idempotente y contrato remoto

## Autoridad y alcance

03/10/2026: «abre issue y rama e implementa 13.2». Baseline main `ee97380` limpio/sincronizado,
13.1 entregada por PR50/PLU-96 Done. Spec13, constitución y ADR0003/0004/0008/0011/0030;
política Swift y skills de inicio/implementación/TDD/Xcode. La autorización inicial excluía entrega Git/Done;
la posterior «commit, push y entrega» permitió el cierre registrado en fase 13. Sin 13.3 ni live.
[PLU-97](https://linear.app/plusprojects/issue/PLU-97), Done / Jesus Franco tras [PR51](https://github.com/JFrancoG/FranAlonso/pull/51);
`codex/plu-97-billing-document-reservation` creada desde ese baseline y eliminada tras verificar integración.

## Propuesta concreta

- Añadir `BillingDocumentReservationRepository: Sendable` en Billing/Domain/Repositories con una única operación
  `reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument`. Frontera remota deliberada y sustituible.
  La autoridad usa requestID estable como identidad, conserva el request íntegro y compara/asigna número/crea documento
  atómicamente. Replay exacto devuelve el documento original; contenido distinto con misma identidad da conflicto,
  sin reemplazar registro ni consumir otra posición. Ticket/factura tienen series independientes. Una identidad de
  documento ya vinculada a otra solicitud también debe dar conflicto. Error/cancelación no prueban ausencia de commit.
- Error neutral `BillingDocumentReservationError`: unavailable, permissionDenied, conflict, invalidResponse;
  sin payloads ni SDK/strings de infraestructura. CancellationError conserva su significado nativo.
- Añadir `ReserveBillingDocumentUseCase<Repository: BillingDocumentReservationRepository>` en Domain/UseCases.
  Dependencia genérica fija por instancia, privada e inyectada; no existencial innecesario ni aislamiento MainActor.
  Recibe solo el request13.1 ya validado, conserva todas sus identidades/snapshot y delega exactamente una llamada.
  Comprueba cancelación antes de contactar y después de await; rechaza respuesta cuyo request no coincida exactamente.
  Propaga errores neutrales/cancelación; fallo desconocido se traduce a unavailable sin filtrar detalles del proveedor.
  No compara relojes, no genera UUID/fecha/número, no cachea ni reintenta automáticamente, no cierra venta ni muta estado.
- No se crea adaptador de producción13.2. La atomicidad e idempotencia real son obligaciones documentadas del contrato
  cuya implementación Firestore/pruebas de transacción pertenecen a13.3. El doble actor de test verifica el pipeline del
  UseCase con autoridad controlada; no acredita remotamente esa obligación. Una nueva instancia del UseCase puede
  recuperar un commit cuya respuesta se perdió usando el mismo request que retiene su llamante.

## Alternativas, riesgos y compatibilidad

Separar getNext/confirm contradice ADR0008. Asignar/cachear números en el UseCase introduce segunda autoridad,
no recupera reinicios y rompe13.3. Un closure genérico sin contrato explícito pierde las obligaciones atómicas.
Se elige protocolo de capacidad remota y UseCase pequeño, siguiendo ClientDocumentStorage/UploadConsentUseCase;
13.1 sigue intacta y no hay API preparatoria Billing con consumidores que migrar.
La respuesta coincide en requestID/documentID/saleID/familia/fecha/snapshot completo; no solo en identificador.
No puede demostrarse el replay de un proveedor defectuoso con un UseCase sin estado: la autoridad13.3 debe cumplirlo.
La reserva puede haberse confirmado aunque falle/cancele await; el llamante conserva el request para recuperación.
Los adapters futuros se componen en App sin activar live. Sin dependencia/unsafe/target/ADR nuevo.

## TDD, archivos y evidencia prevista

Dos archivos Domain nuevos (contrato con error y UseCase); nueva suite `ReserveBillingDocumentUseCaseTests.swift`
y sus dobles acotados, esta propuesta, fase13 y Progress. No tocar los5Swift13.1 ni Sales.
Tests primero con superficie mínima compilable y RED ejecutable: replay estable tras recrear UseCase, series
independientes, mismo requestID con payload diferente, respuesta mal correlacionada variando cada componente,
fallos neutrales/desconocidos, recuperación de commit con respuesta perdida, cancelación previa sin contacto y
cancelación posterior a commit sin éxito tardío. Gates deterministas con actores/continuations, sin sleeps/red real.
Oráculo de identidad/payload/serie/counters y efectos del pipeline; no tests de conformidad/tipos/mera construcción.
Baseline13.1:2393ejecuciones/1505declaraciones, Billing34/22, buildsDevelop/Production, PRE/POST PASS.
MCP estable `workspace-PfnUYLlMzY`, SDK27.0, Develop/planDevelop, iPadPro13(M5) Simulator27.2;
Swift6 completo/default nonisolated, target27.0 y warnings Swift/Clang como errores.
RED/GREEN focal, regresión Billing y suite global por incorporación de frontera async; builds ambos esquemas,
diagnósticos/logs completos y manifest de código. Estilo y POST independientes, gobernanza/diff/enlaces.
UI/previews/localización/accesibilidadN/A; deuda previa conserva su estado y responsables.

## Fuentes primarias

Spec13 y [ADR0008](../ADRs/0008-atomic-billing-numbering.md), entidades13.1 y fronteras Clients reales.
[Apple Task cancellation](https://developer.apple.com/documentation/swift/task#Task-Cancellation), contrastado con
DocumentationSearch del Xcode MCP actual: cancelación cooperativa y checks explícitos antes/después de await.
La reserva Firestore real queda fuera; no se adopta API Apple nueva incierta.

## PRE

PRE independiente `billing_13_2_pre`: PASS sin hallazgosP0–P3 antes de código. Huella operacional read-only
inicial/final/revisor/root idéntica,909archivos SHA256
`944ec711df66681414ada01a85be93be70b35fc44fd6312a5e00b0a41c8de620`.
Fuente Apple contrastada por el revisor; baseline5Swift13.1 y logs/summary previos verificados independientemente.

## Resultado implementado

Alcance aprobado materializado en los dos Domain y la suite nueva. RED 34/34 FAIL;
suite definitiva 2427/2427 PASS, incluidos los 34 nuevos desde 11 declaraciones y sus argumentos completos.
Builds Develop/Production PASS; PRE, estilo y POST de código/evidencia sin hallazgos.
La intermitencia histórica de Stock, el control reversible sin código 13.2 y su restauración exacta se registran en
[fase 13](phase-13.md). El test histórico pasó en la ejecución definitiva; no se afirma una corrección de su causa.
La implementación real Firestore y sus pruebas atómicas permanecen en 13.3.
Entrega posterior autorizada y verificada: PR51 MERGED, PLU-97 Done y ramas local/remota eliminadas.
