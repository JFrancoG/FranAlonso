# 13.3 — Transacción Firestore de numeración y documento

## Autoridad y baseline

03/10/2026: «abre issue y rama e implementa 13.3». [PLU-98](https://linear.app/plusprojects/issue/PLU-98)
In Progress / Jesus Franco, relacionada con PLU-97, sin parent/milestone13 existente.
Rama `codex/plu-98-atomic-billing-reservation` desde main/origin `965827a` limpio y sincronizado.
Constitución, spec13, ADR0002/0004/0006/0007/0008/0011/0012/0016 y política Swift gobiernan el alcance.
13.1/13.2 permanecen intactas. Autorización de implementación; entrega Git/Done y live son gates separados.

MCP Xcode27.0 estable, workspace-PfnUYLlMzY, Develop/plan Develop, iPad Pro13(M5) Simulator27.2/SDK27.0.
Target27.0, Swift6 complete/default nonisolated, approachable concurrency; warnings Swift/Clang como errores.
Baseline literal13.2:2427 ejecuciones/1516 declaraciones, ambos builds/PRE/POST/estilo PASS; intermitencia histórica
Stock y dos avisos AppIntents conservados. Firebase12.19.2 ya aprobado; sin cambio de dependencia/configuración.
Rules actuales deniegan develop/production; no se consultan ni escriben datos remotos.

## Propuesta concreta

- Añadir en Billing/Data un Repository genérico del contrato13.2 y una frontera transaccional Sendable estrecha.
  El data source recibe claves/DTO y una planificación síncrona @Sendable: snapshot tipado de asociación request,
  documento y contador → plan de replay o creación. La política ejecutada en cada intento pertenece a producción,
  no al fake. El Repository convierte errores y DTO antes de Domain, con cancelación antes/después de await.
- Un actor Firestore concreto ejecuta el overlay async `runTransaction` del SDK12.19.2. Un provider obligatorio
  @Sendable recupera un cliente SDK ya configurado por operación; no se retiene Firestore en estado del actor,
  ni se promete una instancia nueva ni se reconfigura/termina el cliente. Transaction queda en su bloque síncrono;
  las referencias SDK son Sendable y son los únicos handles conservados después de enviar el receiver local.
  El provider ordinario no declara un retorno `sending`: Firebase puede devolver una instancia cacheada.
  No se añade un bridge
  de continuations, GCD, unchecked, preconcurrency o unsafe. El único bloque del SDK es la API obligatoria para
  planificar una transacción y queda tras el contrato async; no es el modelo de concurrencia de la aplicación.
- Rutas nuevas e inactivas siguiendo `<environment>/collections`: billingRequests/<requestID>,
  billingDocuments/<documentID>, billingCounters/<ticket|invoice>. Claves UUID canónicas de Domain; entornos
  develop/production mediante FirestoreEnvironment existente, sin modificar sus rutas ni App/composición.
  Asociación y documento se protegen independientemente y comparten el contador de su familia.
- Leer las tres claves antes de escribir. Replay exige asociación y documento coherentes, request completo idéntico,
  serie/número/fecha confirmada válidos: cero writes y documento/fecha originales. Request distinto con igual ID
  o document ID ocupado por otro request: conflict sin consumo. Asociación/documento huérfanos, versión/identidad
  incoherentes o número inválido: invalidResponse sin reparación. Contador ausente representa cero como ADR0012;
  contador negativo, malformado o Int64.max falla cerrado. No reconstruir un contador desde documentos existentes.
  Un contador borrado no puede detectarse por lecturas puntuales de requests nuevos: Rules/writers/inventario y
  conservación de contadores son requisitos de la puerta live; aquí no se activa tráfico ni se acredita ese gate.
- Primera asignación crea juntos asociación, documento completo y contador incrementado en un solo commit.
  Documentos append-only bajo ADR0006/0008. Nunca getNext/confirm, FieldValue.increment separado ni número local.
  Los retries del SDK recalculan desde el nuevo snapshot; el bloque no muta aplicación ni genera identidades.
- DTO Billing versionado reutiliza SaleDTO v2 y SaleTimestampDTO exacto aceptados por ADR0016: conserva venta,
  decimales, orden, pago, requestedAt y todos los IDs, revalidando Domain al leer y rechazando claves Billing
  desconocidas. La comparación del request se hace sobre Domain validado, sin alterar contratos históricos Sales.
  Esta reutilización de Data evita
  duplicar el contrato comercial; no modifica Sales ni hace que Domain conozca DTO. Fecha issuedAt generada en el
  mismo commit con @ServerTimestamp<Date> en un envelope confinado al adaptador. El DTO neutral lleva timestamp
  exacto ya resuelto; JSON/Codable nunca intenta serializar el sentinel Firebase.
- El bloque devuelve un token/plan Codable como Data nuevo mediante `sending Any?`; la frontera dinámica queda
  exclusivamente en el SDK. Replay puede devolver DTO resuelto. Creación espera el commit y lee el documento
  con source.server para resolver issuedAt, exige snapshot existente, sin cache ni writes pendientes, fecha presente
  y versión/request/serie/número exactos al plan confirmado. La fuente server también puede incorporar writes
  locales pendientes; metadata se comprueba explícitamente. Fallo de lectura o pérdida
  de respuesta después del commit conserva la reserva remota; reintento explícito del request la recupera sin número
  nuevo. La lectura posterior no asigna ni modifica nada. El servidor controla issuedAt y no se comparan relojes.
- Errores Firebase se traducen a unavailable/permissionDenied/conflict/invalidResponse; CancellationError nativo.
  Un NSError interno de dominio/código acotado cruza el errorPointer obligatorio del SDK sin payload ni userInfo.
  No logs/telemetría ni PII/secretos. La cancelación cooperativa puede llegar después de commit; no promete rollback.

## Alternativas, riesgos y exclusiones

Documento por requestID sin asociación de documentID permite doble propietario; documento por documentID sin
índice requestID permite que un payload cambiado asigne otro documento. Tres registros en una transacción protegen
ambas identidades. Batch sin lecturas/precondiciones no protege contención. Se usa el overlay async actual en vez
del callback/continuation histórico, sin refactorizar otras features. Copiar SaleDTO o serializar Domain sin transporte
exacto duplica política o pierde control del contrato externo. Fecha del dispositivo como autoridad contradice ADR0006.

Contador compartido limita throughput y Firestore/documentos tienen cuotas; Rules que impidan alteraciones,
medición de tamaño/indexado, contención real, autorizaciones y contrato de writers deben revisarse antes de live.
Los fakes y builds no acreditan servidor, Rules, entorno real ni emisión fiscal. No se añade emulator/config/deploy
como efecto lateral. Retirar estos archivos sin composición ni tráfico no altera datos.
Sin UI/Store/VM13.4, SwiftData13.10, PDF/Storage/correo, cierre13.12, ajuste administrativo13.13, demo wiring,
nuevas dependencias/ADR/unsafe/target, cambios de Rules/índices o activación live. Accesibilidad/previews N/A.

## TDD y archivos

Cuatro Swift nuevos en Billing/Data: DTO, seam/plan/política transaccional, Repository y actor Firebase con envelope
privado/rutas. Nueva suite Swift Testing para pipeline real Repository→política→fake transaccional y frontera Codable.
La forma puede dividirse en archivos cohesivos si ayuda sin ampliar responsabilidades. No tocar ocho Swift13.1/13.2.

RED compilable con superficie mínima: primera asignación/replay tras recrear Repository; familias independientes;
igual request ID con payload distinto; document ID ocupado; interrupción previa sin writes, posterior y cancelación
tras commit recuperables; concurrencia distinta/mismo request/colisión documentID. Fake con snapshot/versiones y
gate determinista que fuerza intentos obsoletos y reejecuta la política, no solo actor que serializa reservas.
Oráculos de documento/fecha/contador/asociación y estado completo; corrupción, overflow, versiones, fechas/pago,
identidad y precisión exacta rechazan sin writes. Inyectar transporte/clock remoto fake; sin sleeps/backend real.
Probar el codec SDK serverTimestamp/DTO con fixtures locales cuando aporte evidencia, sin bootstrap/red.
GREEN focal, regresión Billing/Sales DTO, suite global y builds ambos esquemas por nueva frontera async/SDK.
Logs/xcresult completos, estilo Audit y POST independientes read-only con huellas; gobernanza/diff/secrets.
Progress resumido, fase13 detallada y Linear reconciliados; no Done ni entrega Git sin autorización posterior.

## Fuentes primarias

- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions): atomicidad, reads antes
  de writes, reevaluación con contención, no efectos en el bloque y fallo offline.
- [Firestore Swift runTransaction](https://firebase.google.com/docs/reference/swift/firebasefirestore/api/reference/Classes/Firestore):
  overlay async y `sending Any?`, errorPointer y commit completo.
- SDK12.19.2 local, `Firestore/Swift/Source/AsyncAwait/Firestore+AsyncAwait.swift`,
  `Firestore/Swift/Source/Codable/ServerTimestamp.swift` y headers FIRDocumentReference/FIRDocumentSnapshot.
  @ServerTimestamp Date? nil codifica sentinel; valor resuelto decodifica fecha. SDK solo en envelope Data.
- [Snapshot metadata](https://firebase.google.com/docs/reference/swift/firebasefirestore/api/reference/Classes/SnapshotMetadata)
  y `FIRFirestoreSource.h:34–41` del SDK fijado: source.server conserva latency compensation; no confirmar
  un snapshot con hasPendingWrites/isFromCache. Correlacionar también versión/request/serie/número tras el commit.
- ADR0008, ADR0016 y SaleDTO/SaleTimestampDTO reales; datos/Firebase confinados por ADR0007.

Developer Knowledge MCP devolvió403 por API deshabilitada en su proyecto configurado; se usaron fuentes oficiales
web y SDK local sin habilitar servicios ni cambiar entorno.

## PRE independiente

billing_13_3_pre: PASS sin hallazgosP0–P3 antes de código. Revisión operacional read-only,913archivos,
digest inicial/final/revisor/root idéntico `9594a8cd6327c921e1d9607fdfdb7d3fa7bc396814b5f7ded3eba807caa8f756`.
SDK y fuentes oficiales contrastados; confinamiento Firestore sujeto a builds estrictos sin opt-outs.
El counter snapshot tipado permite replay incluso si el contador está agotado/malformado; solo una nueva
asignación exige contador válido. No se modifica el contador durante replay. Esta precisión mantiene el alcance.

## Refinamiento de compatibilidad dentro del alcance

El SDK no declara Firestore Sendable. El primer build del receiver almacenado falló con `Sending self.firestore
risks causing data races`; la alternativa de closure privada/helper estático también falló con el overlay async.
Se descartó un provider con retorno `sending Firestore` por no corresponder a la cache real del SDK. La implementación
final usa un provider ordinario `@Sendable () -> Firestore`, obligatorio y sin default, que obtiene el cliente ya
configurado una vez por operación, sin retenerlo ni usarlo tras await. Build estricto19.528s PASS del03/10/2026
10:47 (`BuildProject-Log-20261003-104727.txt`); builds finales de ambos esquemas en phase-13.md. No se cambia aislamiento/flags
ni se introduce bridge/unsafe. POST contrasta ese refinamiento y su contrato de configure-before-use.

La evidencia primaria12.19.2 está acotada al camino transaccional; no se afirma thread safety general de Firestore:
[cache sincronizada del componente](https://github.com/firebase/firebase-ios-sdk/blob/8c29ca981990a32e626c8617544fa65d22b1834f/Firestore/Source/API/FSTFirestoreComponent.mm#L84),
[configuración protegida por mutex](https://github.com/firebase/firebase-ios-sdk/blob/8c29ca981990a32e626c8617544fa65d22b1834f/Firestore/core/src/api/firestore.cc#L247),
[transacciones en el worker SDK](https://github.com/firebase/firebase-ios-sdk/blob/8c29ca981990a32e626c8617544fa65d22b1834f/Firestore/core/src/core/firestore_client.cc#L549),
[bloques transaccionales concurrentes](https://github.com/firebase/firebase-ios-sdk/blob/8c29ca981990a32e626c8617544fa65d22b1834f/Firestore/Source/API/FIRFirestore.mm#L402).
