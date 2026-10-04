# 13.13 — Ajuste administrativo de series

## Autorización de entrega posterior

04/10/2026: «commit y push, y entrega» autoriza el circuito establecido completo de Git y cierre operativo.
Implementación y evidencia aceptadas se reutilizan por identidad exacta de las 23 fuentes.
[PR62](https://github.com/JFrancoG/FranAlonso/pull/62) integrada el04/10/2026 a14:12:43UTC;
feature9362c2e → merge0b50c1a, árbol18832b18dfc61f1035bd0c96b036459a07dd7e47 exacto.
PLU-111 Done automático verificado; rama eliminada local/remota tras ascendencia y cero commits únicos.
Revisión remota y editorial independiente PASS/SinP0–P3; [registro completo](phase-13.md).
El alcance original y sus exclusiones permanecen vigentes. Fase13, deuda accesible y live siguen separados.

Preflight independiente de entrega `billing_13_13_delivery`: PASS/SinP0–P3, alcance28 paths.
23 fuentes exactas al manifest validado; artefactos originales, límites y autorización contrastados.
1168 archivos inicial/final/revisor/root idénticos
`e5c2ce0b825dec72242bb5ab7dd8d9922981e4b21989bbc15d5dc1bddc361357`.
Revisión remota posterior aceptada; no es cierre integral.

04/10/2026 Europe/Madrid. PLU-111, Jesus Franco, In Progress.
Autorización: «abre issue y rama e implementa 13.13». Rama `codex/plu-111-billing-series-administration`,
base main/origin/main `62693ce912e423dbc94365de32ef3bbcdfb89901`, limpia y sin divergencia al inicio.
Plan Approved para implementación local por petición expresa y PRE independiente PASS/SinP0–P3.
PRE billing_13_13_pre,1145files inicial/final/revisor/root idénticos
`af9cbf491a0f3235f6734e1fa9060609dd0bf76eb8574dc68f37ceef8c957ff1` antes de registrar dictamen.
Autoriza sólo el alcance presentado; sin entregaGit/Done/live/fase14.

## Autoridad y baseline

Constitución, spec13/fila13.13, ADR0006/0008/0011/0021/0029/0030 y DEVELOPMENT_GUIDE.
La fila pide autorización, límites y auditoría; no prescribe pantalla, IAM, reinicio anual ni política fiscal.
ADR0006 conserva documentos emitidos inmutables; ADR0008 conserva asignación remota atómica e idempotente.
AuthenticationSession contiene sólo UID; LocalPrincipalAuthorizer acredita almacén local, no privilegio administrativo.
No hay UI/configuración administrativa existente. Ajustes en menú de cuenta es ubicación futura de navegación,
no obligación de incorporar un destino nuevo. Fase14 es informes, fuera de esta autorización.

Baseline13.12 entregado por PR61/main62693ce:35Swift manifest9493e3f4… exactos,3026/3026PASS,
builds Develop/Production y revisiones aceptados por identidad. No acredita tests13.13 todavía.
Xcode MCP estable/Service workspace-DSfPhPVzqA conectado a FranAlonso.xcodeproj, Develop/testplanDevelop,
destino inicialiPhone18Pro27.0, SDK27.0; target app/tests27.0, Swift6strictcomplete/defaultnonisolated.
Para tests se seleccionará iPhone17(27.2) anunciado disponible y se restaurará el destino inicial;
el runtime27.0 falló en13.12 y no se volverá a atribuirle evidencia.
8links históricos externos y2/1avisos AppIntents conservan límites, sin warningsSwift/Clang certificados nuevos.
PLU-101/108/110 conservan deuda propia; proyecto/fase13 In Progress sin parent/milestone13 real.

## Comportamiento exacto

Implementar una capacidad administrativa Billing no expuesta a UI, invocable explícitamente por caller autorizado.
La solicitud validada e inmutable contiene operationID UUID estable, serie ticket/invoice, expectedLastNumber,
targetLastNumber y motivo tipado`seriesAlignment`. No texto libre/PII ni actor proporcionado en la solicitud.
Todos los valores serializados son Codable y construcción/decoding protege las mismas invariantes.

Política mínima conservadora de implementación, no política fiscal productiva: expected>=0,
expected<target<Int64.max. Avance exclusivo, sin no-op, retroceso/reset/año o desbordamiento;
retiene margen para emitir el siguiente número. No se limita el salto por un máximo de negocio inventado.
Un counter ausente equivale a0 para inicialización explícita. Counter malformado/negativo/serie equivocada falla cerrado.
Cambiar sólo cabeza futura; nunca documento, binding, venta, stock, PDF ni número ya emitido.

Autorización administrativa requerida por contrato propio sustituible`BillingSeriesAdministrationAuthorizer`:
retorna únicamente principal opaco después de comprobar autoridad para la operación actual. No acepta booleano UI,
AuthenticationSession ni binding local como permiso. Repository real requiere la capacidad inyectada;
comprueba antes de contactar la transacción y después de cada suspensión antes de publicar el resultado,
conservando el mismo principal. Negación/revocación/reemplazo/lectura indeterminada falla cerrado.

La implementación normal de autorización es unavailable/denegada y la factory App devuelve un repository inactivo,
sin resolver Auth/Firestore ni conceder privilegios. No se provisiona un rol ni se decide un nombre de customclaim.
La implementación de una autoridad live fresca, su provisión y enforcement remoto pertenecen al gate live separado.
La interfaz no constituye una prueba de seguridad productiva: un futuro servidor/Rules debe validar rol y UID.
SDK adapter sólo opera con autoridad explícitamente inyectada; construcción inerte, nunca bootstrap implícito.

Transacción Data lee audit(operationID) y counter seleccionado antes de escribir. Replay se evalúa primero:
audit válido con request y principal idénticos retorna exactamente la fecha/principal/valores originales sin writes,
aunque después una reserva u otro ajuste avance el counter. MismoID con payload/principal distinto es conflicto;
audit corrupto o fecha no resuelta es invalidResponse. No sustituir auditoría existente.
Si no hay audit, comparar cabeza real==expected; divergencia produce conflicto y exige nueva decisión explícita.
Crear counter v1 intacto y audit inmutable juntos. Ambas familias usan el MISMO path de counter que reservas13.3,
por lo que el SDK reevalúa el plan ante contención ajuste↔reserva. Ningún efecto en callbacks repetibles.

Audit versionado registra operationID/request, antes/después, principal de autoridad y tiempo servidor.
Usar @ServerTimestamp exclusivamente en envelopeFirebase; no reloj del dispositivo como fecha autoritativa.
Tras create, releer audit desde servidor, rechazar caché/writes pendientes/ausencia/correlación inválida.
Errores/cancelación después del commit no prueban rollback: retry explícito con mismo request y autoridad vigente
recupera la aceptación. No reintento en Domain, IDs/reloj nuevos, ni publicación con autorización revocada.
Revocar durante una operación no promete impedir un commit ya efectuado; la respuesta se deniega y audit permanece.
Auditoría de negocio remota no es Analytics/log. No tokens, payload de venta, firma ni datos identificativos de cliente.

## Áreas/archivos previstos

- Billing/Domain: BillingSeriesAdjustmentRequest, BillingSeriesAdjustmentReceipt, BillingSeriesAdjustmentReason,
  BillingSeriesAdjustmentError, BillingSeriesAdministrationAuthorizer, BillingSeriesAdjustmentRepository,
  AdjustBillingSeriesUseCase. Tipos puros, contratos semánticos DocC en inglés.
- Billing/Data: DTORequest/Audit, BillingSeriesAdjustmentTransactionDataSource/Snapshot/Plan,
  FirestoreBillingSeriesAdjustmentRepository, FirebaseBillingSeriesAdjustmentTransactionDataSource,
  UnavailableBillingSeriesAdjustmentRepository/Authorizer. Frontera reemplazable; sin SwiftData nuevo.
- App/Composition/Dependencies/AppDependencies+Billing.swift: factory administrativa inactiva explícita;
  no modificación del flujo normal o demo, ni construcción del SDK.
- Tests nuevos Domain, Repository/Transaction, Authorization, Integration/Fixtures; sólo seams deterministas.
  CounterDTOv1 y reservas13.3 conservan exactamente su formato/política; no modificar tests históricos.
- docs/Progress.md, docs/progress/phase-13.md, esta propuesta y CHANGELOG para implementación local.

## Alternativas y riesgos

Se rechazan edición directa de counter sin audit, batch sin lectura CAS, rollback/renumeración,
booleans/local login como administración, fecha cliente y mezclar audit en counterDTOv1.
Se elige extensión de la transacción y contratos existentes, sin excepción arquitectónica/ADR nuevo:
no cambia authority local-first, el único contador definitivo ya es remoto bajo ADR0008.
Una nueva UI/IAM/Rules/migración excedería alcance y necesita propuesta propia.
Riesgos: permisos live no definidos ni validados, gaps de numeración con revisión fiscal pendiente,
pérdida de respuesta trascommit, conflicto por reservas concurrentes, respuesta manipulada/corrupta,
revocación/reemplazo durante suspensión y confusión entre fake ledger y garantías servidor.
SDK build/transform payload tests no prueban permisos/contención reales de Firestore.

## TDD y validación

1. Añadir APIs compilables inertes + tests de comportamiento. RED focal por conducta, no por falta de símbolos/setup.
2. Request/usecase: límites negativos/no-op/retroceso/max, Codable inválido, resultado incoherente,
   errores/cancelación antes/después; autoridad negada/cambiada/revocada sin publicación ni contacto no autorizado.
3. Pipeline real repository→plan→ledger Codable: ticket/invoice independientes, CAS/inicialización,
   auditoría+counter juntos, replay no writes/fecha original, mismatch/unknownpayload/counter corrupto,
   pérdida de respuesta/cancelación trascommit y recuperación con mismoID.
4. Ledger optimista comparte counter con BillingTransactionPlan/Billing reservation repository real;
   contención determinista antes de commit sin sleeps, ajuste↔reserva y dos ajustes, no números duplicados,
   rechazo staleexpected; ledger simula SDK, nunca se atribuye resultado a backendlive.
5. GREEN focal + regresiónreservas/auth/billing afectada; global final una vez por frontera compartida.
   BuildsDevelopForTesting/Production y diagnósticos de cada Swift cambiado mediante XcodeMCP,
   localización/gobernanza/diff, auditoría técnica independiente y audit FULL de estilochangedSwift.

UI/previews/Inspector/runtime/AX nueva: N/A por ausencia de nueva superficie/composición activada;
no altera matriz55 ni deuda101/108/110 y no acredita accesibilidad integral.
Sin commit/push/PR/merge/Done, fase14, dependencia/unsafe/target/schema nuevo, servicio remoto live,
correo real, emisión fiscal ni cierre integral de fase13.

## Evidencia TDD inicial

Los contratos compilables inertes y sus pruebas se registraron mediante XcodeWrite después del PRE.
El primer build de tests detectó siete usos de optional chaining sobre `BillingDocument.number`,
que es un valor no opcional. Se corrigió ese setup sin cambiar los oráculos antes de ejecutar RED.
DevelopForTesting (17.238 s) y Production (21.173 s) compilaron mediante Xcode MCP estable.
Los logs conservan dos/un avisos de extracción de metadatos AppIntents, sin warnings de Swift/Clang.

RED ejecutó las 40 declaraciones y sus 95 casos: 94 fallaron por la conducta ausente
(Domain49, Transaction26, Authorization12 e Integration7); pasó el caso de composición inactiva.
Artifact `AE52B561-5E82-410B-8AC4-A7B7CDA97953.txt`,
console `test-console-log-2026-10-04T14-58-43+02-00.txt`.
El fallo de entrada a los gates confirma que la implementación inerte aún no contacta esas fronteras.
GREEN quedó autorizado a continuación; los mismos oráculos se conservan.

## Implementación y validación local

Domain, Data y la factory administrativa inactiva están implementados. Los 95 oráculos iniciales se conservaron.
Se añadieron ocho guardas del envelope SDK y del path compartido después de GREEN; no se atribuye RED a esas guardas.
La ejecución focal pasó 55 casos por selección parcial de argumentos. El global final ejecutó las 44 declaraciones
y los 103 casos nuevos completos: 49 Domain, 26 Transaction, 12 Authorization, 7 Integration, 8 SDK y 1 composición.
Resultado global: **3129/3129 PASS**, cero fallos, skips o casos no ejecutados.
Artifact `FE5A3DF2-9A0F-4C5A-B48E-193C14D790ED.txt`; console `test-console-log-2026-10-04T15-19-54+02-00.txt`.

Estilo independiente FULL23 y reauditoría de los cinco archivos corregidos: PASS/SinP0–P3.
Se resolvieron 19 construcciones P3 sólo con whitespace; los otros 18 Swift permanecieron exactos.
Freeze inicial/final/revisor/root: 1167 archivos, `883e6ed9020f897a9741f91bcdcdab846f352fab0c23039d8ec02125915e9fa8`.
El global y los builds finales siguen al formato: Production 17.807 s, DevelopForTesting 29.010 s, PASS.
Logs `BuildProject-Log-20261004-151705.txt`/`151832.txt`: un/dos avisos conocidos de AppIntents,
sin warnings Swift/Clang. Los 23 Swift se inspeccionaron por Xcode MCP; 22 no tienen diagnósticos.
El editor conserva en IntegrationTests:3 «Module 'FranAlonso' was not compiled for testing» tras el cambio de esquema,
también después de refrescar/build/global. El compilador Develop usa `-enable-testing` y `-warnings-as-errors`,
compila ese archivo y ejecuta sus siete casos: todos PASS. Se registra como limitación del índice del editor,
sin declarar cero diagnósticos absolutos ni modificar configuración para ocultarlo.

[Manifest final de las 23 fuentes](13-13-billing-series-source-manifest.json), SHA-256
`a679f5a866b3e5da6f32420793536390c0a02f1d0550e5e375d6814ad2819591`.
POST técnico independiente `billing_13_13_post`: PASS/SinP0–P3 para la implementación local.
1168 archivos inicial/final/revisor/root idénticos:
`b447226409533d9e26d043718ac292af3cf29a3b26c9df29e6b45c9415de00c4`.
Sólo se registran después el dictamen y la reconciliación; las 23 fuentes conservan cada hash probado.
Xcode restaurado a Develop/testplanDevelop/iPhone18Pro; los tests corresponden a iPhone17(27.2).
Gobernanza retorna exit1 exclusivamente por ocho links históricos fuera de este alcance; no existen incidencias nuevas.
PLU-111 Done funcional tras la entrega posterior; fase13 y proyecto siguen In Progress.

## Fuentes primarias actuales

Consultadas04/10/2026. DeveloperKnowledge dio403 ServiceUsage deshabilitado; fallback weboficial sin cambiar proyecto/APIs.
- [Firebase transactions](https://firebase.google.com/docs/firestore/manage-data/transactions):
  all-or-nothing, lecturas antes de writes, callback repetible y fallooffline; Swiftasync runTransaction.
- [Firebase customclaims](https://firebase.google.com/docs/auth/admin/custom-claims):
  privilegios se provisionan en entorno servidor de confianza; un UID/localbool no es autorizaciónadministrativa.
- [Firestore SecurityRulesconditions](https://firebase.google.com/docs/firestore/security/rules-conditions):
  auth/condiciones y getAfter permiten validar operaciones conjuntas; no Rules/deploy en13.13.
- ContratoSDK instalado ya usado por FirebaseBillingTransactionDataSource13.3, con @ServerTimestamp/Codable,
  closure sending Any y referenciasSendable declaradas por SDK; no opt-outs locales nuevos.
