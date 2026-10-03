# Fase13 — Facturación, PDF, correo y numeración

## 13.4 / PLU-99 — Entregada; Done

03/10/2026: «commit, push y entrega» autoriza el circuito establecido completo.
[PR53](https://github.com/JFrancoG/FranAlonso/pull/53) MERGED a main;
feature `7498ccd6e8d385767f57c17641c41291bc5ef4f3` → merge `268efd3b18e21983de2e67e3198edabb7d83b137`.
Árbol completo integrado idéntico al feature validado, tree `fd312337a8fbd218e32d96afaf8a24ee3cc03399`.
Rama `codex/plu-99-billing-document-state` eliminada local/remota después de comprobar
ascendencia, head remoto exacto y cero commits únicos; main/origin/main sincronizados al merge.
[PLU-99](https://linear.app/plusprojects/issue/PLU-99) Done verificado tras actualización explícita
03/10/2026 11:21:23 UTC; no se atribuye ese cambio a automatización GitHub–Linear.

Revisión independiente final de entrega PASS sin hallazgosP0–P3, nueve archivos previstos;
freeze925 inicial/final/revisor/root `d9503ba0945cb074fe8f4887e4c755df07a7e901df3d44dbe966e7637d423949`.
Rerevisión remota focal PASS: diff PR/local idéntico SHA256
`80c6d57cf6e754739ec2bf7eff0aa9442559531eed45dfda90fd1f832bfdbc35`, mismo head/base;
CLEAN/MERGEABLE antes del merge, sin protección/rulesets/workflows/checks remotos configurados.
Revisión GitHub COMMENTED desde cuenta propietaria basada en agente read-only; no representa
aprobación humana distinta. Se integró con match-head7498ccd, sin force-push.

Se reutilizan2523/2523 ejecuciones /1550declaraciones,16nuevas/30casos completos, ambos builds y
PRE/POST/estilo por identidad exacta de los cinco Swift y toda fuente/configuración histórica.
El revisor relee bundle xcresult completo y logs, sin nuevos builds/tests por metadatos de entrega.
Cierre documental limitado a Progress/phase13/CHANGELOG; Xcode nuevo N/A por ausencia de cambios ejecutables.
Auditoría documental final focal PASS sin hallazgosP0–P3 sobre tres documentos:
925archivos, huella inicial/final/revisor/root
`332925a77efa3c9bb3dcee43e64c58002e5a2a47a611df460229346f1da7ffd9`.
Después del freeze solo se registra este resultado; fuentes/configuración mantienen el manifest validado.
AppIntents, intermitencia Stock y seis enlaces históricos08.3 conservan sus límites descritos debajo.
UI/accesibilidad N/A; deuda previa mantiene responsable/recuperación antes del primer candidato real.
Fase13/proyecto abiertos, sin parent/milestone13;13.1–13.4 entregadas.13.5 selección/formulario fiscal
es el siguiente gate separado con propuesta/PRE/autorización propias, sin iniciar; live permanece inactivo.
Los snapshots de implementación y autorizaciones iniciales conservados debajo son históricos.

## 13.4 — Historial de implementación local

03/10/2026: «abre issue y rama e implementa13.4».
[PLU-99](https://linear.app/plusprojects/issue/PLU-99), Jesus Franco, In Progress;
rama `codex/plu-99-billing-document-state` desde main/origin/main limpio `8256d3b`.
[Propuesta exacta y fuentes](13-4-billing-presentation-proposal.md), spec13/ADR0008/0011.
PRE independiente PASS sin hallazgosP0–P3 antes de código:920archivos,
huella inicial/final/root `ed7bc5e954faef3b46254793de2fef5c934b22f081db719ba7c3541852a32ee5`.
No nuevo ADR/dependencias/configuración; Swift histórico Billing13.1–13.3 y Sales/App intactos.

### Implementación13.4

Dos Swift nuevos en Presentation: BillingDocumentStore y BillingViewModel @Observable @MainActor,
genéricos por el Repository aprobado. VM instancia Store privado; todos sus estados/proyecciones leen
Store mediante getters, sin copia/lastError mutable, Task interna ni efectos en init.
Única máquina selection/allocation(BillingDocumentLocalState)/reserving(request)/closed(snapshot retenido).
Una sesión sella request validada sin generar ID/fecha ni I/O; misma request no-op, otra/busy/closed rechazan.
Reserve usa UseCase13.2 y un intento explícito; numbered devuelve el mismo documento sin otro contacto.
Errores neutrales conservan request; invalidResponse se presenta unavailable, sin payloads/logs.
Cancelación previa/al volver del await deja pendingNumber aun desde failed. CancelReservation cerca
publicación; no cancela task del caller ni promete rollback remoto. Tokens privados impiden que éxito,
catch o defer antiguos contaminen un reintento activo. Close terminal retiene request/documento y no cierra venta.

Tres Swift Testing nuevos:16declaraciones/30casos. Seam Repository real con planes consumidos antes
de suspender y gates compartidos, sin sleeps/red. Incluye pipeline real Store→UseCase→Repository13.3→
ledger transaccional histórico para respuesta perdida, cancelación postcommit y replay con un solo commit.
Doble gate completa éxito/error antiguos mientras el nuevo sigue bloqueado, sin cancelar la task antigua
(para comprobar fencing Store); Observation confirmation demuestra tracking real de getters VM.
También familias, request sellada, errores privados/respuesta ajena, no auto retry, busy, precontact cancel
desde pending/failed, numbered monotónico, close selection/pending/failed/numbered y delegación fachada.
Fixtures sintéticas; el fake no acredita backend/Rules ni reinicio durable13.10.

### TDD y validación13.4

RED compilable11/11 FAIL por stub noRequest y falta de invalidación Observation:
`RunSomeTests/481D6E82-61C5-45FD-B322-FEB4EB94006D.txt`; build-for-testing27.002s PASS.
GREEN focal25/25 PASS, selección parametrizada parcial de16declaraciones:
`RunSomeTests/3C5E7C2D-1D56-4A0D-92C9-367EB6600CD0.txt`.
Primer global2523/2523 PASS12:29:08 antes de dos cambios puramente de layout.

Estilo independiente:5Swift/693líneas, recall1candidato,2P3 en tests corregidos:
ledger init horizontal117columnas y atributoTest95columnas. Freeze925
`26504356a949ef52fd6344a98c3fe384e6899356b8ab2c43e57a6dcfbca573de` antes/después/root.
Reauditoría focal PASS sin hallazgos; resto del Audit vigente, recall0candidatos;925archivos,
huella inicial/final/root `6d639a7896a7f71c5d563a16e7c12a11f76e021839f70c19b90f38dcb1d16eb1`.

Build-for-testing Develop definitivo12:31:37 /13.086s PASS,
`BuildProject-Log-20261003-123137.txt`; Production12:32:52 /33.143s PASS,
`BuildProject-Log-20261003-123252.txt`. Logs completos: dos avisos AppIntents conocidos por build,
cero diagnósticos estructurados Swift/Clang; incrementales, sin claim clean-build/cero warnings globales.
Xcode MCP27.0 estable Service, workspace-PfnUYLlMzY; target27/Swift6 strict complete/default nonisolated,
SDK27.0/Simulator27.2 iPadPro13(M5). Develop/plan/destino inicial restaurados, sin archivos temporales de esquema.

Global12:31:45:2522/2523 PASS, fallo histórico StockSyncDurabilityTests línea118,
weak ModelContainer todavía vivo; no se tocó Stock ni se atribuye corrección/causa.
Retest focal1/1 PASS, `RunSomeTests/29B5435C-7753-4EDD-B581-556A9DADC8CE.txt`.
Global definitivo12:33:45: **2523/2523ejecuciones PASS**, **1550declaraciones**,
cero failed/skipped/expected/notRun. Summary `RunAllTests/F22EED90-EA36-4C74-AF0C-613762AB27E8.txt`.
Bundle ActionArtifacts íntegro `Test-FranAlonso-Develop-2026.10.03_12-33-45-+0200.xcresult`;
xcresulttool confirma2523ejecuciones/1550declaraciones,16declaraciones nuevas/30casos completos y
runtimeWarnings vacío. Export `/tmp/franalonso-13-4-final-summary.json` y `...-tests.json`.

### Auditoría y límites13.4

POST independiente de estándares PASS sin hallazgosP0–P3:8archivos (5Swift/3docs),pipeline
Domain/Data,contratos,token/catch/defer,oráculos,fuentes Apple,evidencia nativa completa y límites.
925archivos,huella inicial/final/revisor/root idéntica
`5272c60c1a76797928d3c782bf93eb0feefcd1ddd97308933312b42e9304a4a3`.
Solo se registra este resultado después del audit; fuentes/config mantienen el manifest validado.
Implementación local lista; PLU-99 In Progress hasta una entrega Git autorizada.
Diffcheck PASS; validador de gobernanza solo conserva seis enlaces históricos08.3 a Desktop
(exit1), sin nuevos problemas; no se declara PASS global de gobernanza. Progress conserva el límite≤8192bytes.
UI/previews/accesibilidad N/A: no Views/pantalla/texto/navegación visible tocados. Deuda previa y
responsable/recuperación antes de uso real permanecen intactos; no se acredita matriz accesible nueva.
No composición App, formulario/modelo fiscal13.5, plantillas/firma, PDF/Storage/correo, SwiftData13.10,
cierre13.12, Rules/deploy/bootstrap ni live. Nada se cierra de fase/proyecto; entrega Git/Done no autorizada.

### Manifest13.4 — Fuente definitiva validada

- `BillingDocumentStore.swift`: `7ec497a8aa9ba633f2f9774ba7a294b3de37c59353abbd411112d8f515334bb5`.
- `BillingViewModel.swift`: `e705b3174e469e93aa96fe7045ce0114ceda7f9cfec12dc06acb85f25bfd07ca`.
- `BillingDocumentStoreTests.swift`: `e40846723e9a253953265a6128dc8f31449b36966ecd6aa7caf72a7ad6def19b`.
- `BillingViewModelTests.swift`: `d6117a74e7b5ecc8709c574f2180e867238da967fa33227e536c583291c5f54b`.
- `BillingPresentationFixtures.swift`: `8213bd2cf6b792bf5e1cb38a1e920ec493c135f55b5b83cf010e6d9a2c52c2ff`.

## 13.3 / PLU-98 — Entregada; Done

03/10/2026: «abre issue y rama e implementa 13.3». [PLU-98](https://linear.app/plusprojects/issue/PLU-98)
Done / Jesus Franco tras [PR52](https://github.com/JFrancoG/FranAlonso/pull/52);
rama `codex/plu-98-atomic-billing-reservation` eliminada, baseline main/origin `965827a` limpio.
[Propuesta exacta, fuentes y compatibilidad](13-3-billing-transaction-proposal.md). PRE independiente PASS antes
de código, sin hallazgos P0–P3:913archivos, digest inicial/final/revisor/root
`9594a8cd6327c921e1d9607fdfdb7d3fa7bc396814b5f7ded3eba807caa8f756`.
Ocho Swift13.1/13.2 byte-exact contra965827a y sus manifests históricos; configuración/dependencias intactas.

### Implementación y TDD 13.3

Cuatro Swift nuevos en Billing/Data: DTO versionados exactos, política y seam transaccional, Repository genérico,
actor Firebase. Tres claves en una transacción: asociación requestID→documentID, documento inmutable y contador
independiente ticket/invoice. Reads antes de cualquier write; la política de producción se recalcula por intento.
Replay de request íntegro validado retorna número/fecha originales sin writes, incluso con contador corrupto.
Conflicto de contenido/identidad no consume número; huérfanos, versiones, fechas/pago/números y overflow fallan
cerrado. Solo primera creación escribe los tres registros juntos. No reparación ni numeración local.

Venta reutiliza SaleDTO v2/SaleTimestampDTO exactos; no se cambia Sales. Los envelopes Billing rechazan claves
desconocidas. El actor usa runTransaction async del SDK12.19.2 aprobado y provider obligatorio Sendable de cliente
ya configurado, sin default, SDK retenido en estado, cambios de configuración, fresh-instance promise ni opt-outs.
Bloque SDK síncrono obligatorio, sin efectos de aplicación; resultado Data Codable nuevo mediante sending Any?.
@ServerTimestamp<Date> nil genera el transform en el commit. Lectura server posterior exige snapshot existente,
sin cache/writes pendientes, fecha resuelta y versión/request/serie/número exactos al plan confirmado. Ningún reloj
local decide issuedAt. Pérdida de respuesta/cancelación después de commit se recupera con el mismo request;
Repository no reintenta automáticamente y solo expone errores neutrales/CancellationError. Sin logs ni payloads.

Dos Swift Testing nuevos:18declaraciones/66ejecuciones. Fake con transporte Codable, snapshot/versiones y barrera
determinista fuerza contención/intentos obsoletos y reejecuta la política real; commits completos sin await entre writes.
Interrupción previa/postcommit, cancelación posterior con éxito/error tardío, replay tras recrear Repository,
identidades, independencia, corrupción y precisión (decimal mayor que2^53, orden de líneas, pago y bits de fechas).
Codec SDK real Encoder/Decoder local: sentinel es serverTimestamp, solo fecha resuelta confirma, metadata/path y
campos extra inválidos rechazan. Sin bootstrap Firebase ni red. El fake no acredita servidor/Rules reales.

RED compilable inicial:15/15 FAIL, unavailable intencional; `RunSomeTests/138EFFDF-A57B-4E94-BA3A-1A6619D400C7.txt`.
RED de campos desconocidos:4/4 FAIL, junto con7casos core PASS; `RunSomeTests/CF21FFA9-AFA3-49E9-8FCD-5E1DD6EE41F7.txt`.
RED codec SDK:10/10 FAIL por stub unavailable; `RunSomeTests/74FB37AD-38C8-4118-8918-143FAA5F893F.txt`.
GREEN focal:47/47 PASS, selección parcial de argumentos por Xcode; `RunSomeTests/5F9AF095-D8C9-44E5-89A3-1E7EC59D81D3.txt`.
No se atribuye cobertura66 al focal. Primer global11:01:02:2493/2493 PASS, incluidos66nuevos, confirmado nativamente;
`RunAllTests/DEB0EF12-707D-4691-987A-1D5908FA8468.txt`. Después se normalizaron únicamente cinco bloques de estilo.

### Validación definitiva 13.3

MCP Xcode27.0 estable (27A266), workspace-PfnUYLlMzY; Develop/plan Develop inicial restaurados,
iPad Pro13(M5) Simulator27.2/SDK27.0. Target27.0, Swift6 complete/default nonisolated, warnings como errores.
Build-for-testing Develop11:05:39 /28.706s PASS, `BuildProject-Log-20261003-110539.txt`;
Production11:07:26 /28.572s PASS, `BuildProject-Log-20261003-110726.txt`.
Cero diagnósticos estructurados Swift/Clang; logs completos solo los dos avisos conocidos AppIntents por build.
Builds incrementales; no clean-build ni cero warnings globales. Sin tests nativos UI/XCTest ni xcodebuild.

RunAllTests definitivo11:05:57: **2493/2493ejecuciones PASS**, **1534/1534declaraciones**, cero
failed/skipped/expected/notRun. Summary `RunAllTests/72BF9DA2-C01B-4FDC-B091-EB64DC8D542F.txt`.
Bundle `Test-FranAlonso-Develop-2026.10.03_11-05-57-+0200.xcresult`: copia ActionArtifacts sin Info.plist;
se leyó el original íntegro en DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test por xcresulttool.
Confirmó2493ejecuciones/1534declaraciones,18/18declaraciones y66/66ejecuciones nuevas con todos los grupos:
2/2/4/1/2/3/2/4/13/6/6/1/6/1/1/1/9/2. También Stock histórico PASS, sin corregir su intermitencia previamente registrada.

### Auditorías y gobernanza 13.3

Estilo independiente:6Swift, script1candidato (init actor válido por parámetro closure), pase manual detectó3P3
en5bloques. Corregidos dos bodies de closures throwing/await en fixture y tres if del helper SDK a multiline;
misma lógica/expectativas. Auditoría inicial read-only:919archivos, digest inicial/final/root
`7ee40785cca0023b75c198851476cea0ddfa38491abbf6484836ddb6834196fc`.
Reauditoría de estilo PASS:6Swift leídos completos,5bloques corregidos, único candidato lexical justificado.
POST independiente PASS sin hallazgosP0–P3:revisó autoridad,6Swift/3docs,SDK fijado, provider/configure-before-use,
puente NSError/Swift, paths/transacción/DTOs, TDD, counts nativos completos, dos logs, manifests y límites.
Ambas auditorías operacionales read-only:919archivos, huella inicial/final/revisor/root idéntica
`cbd22b7ed26a3c70da1ceb9593194a4f38ab94cef2bcc519dca6f70277a3ef2d`.

Diagnóstico adicional RunCodeSnippet11:12:47 no ejecutó código: DYLD no pudo cargar `/usr/lib/libSystem.B.dylib`
en dispositivo privado de Previews. `RunCodeSnippet/RunCodeSnippet-ErrorDetails-20261003-111247.txt`.
No cuenta como prueba runtime de bridge ni como preview; no se altera entorno para corregirlo en este alcance.
SDK/Swift contrastados estáticamente: NSError original conservado y camino de transacción inspeccionado sin log
del Status. No hay hallazgo demostrado ni modificación de producción por esa hipótesis.
Gobernanza conserva únicamente seis enlaces Desktop históricos rotos08.3; diffcheck PASS. Scope exacto9archivos
(6Swift+3docs), sin secretos/PII/logs, dependencias, target/settings, Rules/índices/deploy ni cambios históricos.

UI/previews/localización/accesibilidad N/A: solo Data/tests, sin pantallas ni recursos; deuda previa conserva dueño
y recuperación tras feedback/estabilización, antes del primer candidato real. Sin App/composición/demo ni tráfico.
13.4 Store/VM,13.10 SwiftData, PDF/Storage/correo, cierre13.12 y ajuste13.13 siguen fuera. Backend/Rules reales,
conservación de contadores, permisos/writers y tamaño/contención requieren puerta live separada; esta evidencia
no acredita emisión fiscal o integración real. Snapshot tras implementación y antes de entrega: PLU-98 In Progress,
validada con PRE/POST/estilo PASS y pendiente de autorización Git/Done. El resultado definitivo aparece abajo;
fase13/proyecto siguen abiertos. Registro de dictámenes/estado documental: Xcode N/A por paridad literal.

### Manifest Swift 13.3 probado

```text
BillingDocumentRecordDTO.swift 5ca6fb658c4ae6c6dc9425e971a00dc079171d7a295cf3badf966e6e2fa9ce04
BillingTransactionDataSource.swift 2e8e0f588d196ddbbdafdc31c8b3b1b2299f242865569abf441fb7d4abe3d2ff
FirebaseBillingTransactionDataSource.swift 7f4b3413b19e0a4190b4965a50285f16d085f5631c32d27b6ca915837a5c6c20
FirestoreBillingDocumentReservationRepository.swift 12630a822c54321213ac43b8b14cb95e739ddef3af1587f9a178cc73ac452000
BillingTransactionFixtures.swift 2bb4d999f399494715baeac32f127cfb3d0eed08dda386a7681f06186772d712
FirestoreBillingDocumentReservationTests.swift 214b70a4a20fe324d1f5e2f55e1e224e6d4bab31c28c19b0c1033ccaa2b751ab
```

### Autorización de entrega 13.3

03/10/2026: el propietario solicita «commit, push y entrega». Autoriza el mismo recorrido completo establecido
para13.1/13.2: commit del alcance exacto, push, PR/revisión/merge, reconciliación PLU-98 Done y limpieza de rama
tras verificar ancestry. No autoriza13.4, cierre de fase13 ni live.
Se reutilizan2493/2493ejecuciones,1534declaraciones,66/66casos nuevos, ambos builds y PRE/POST/estilo PASS:
los seis Swift nuevos y ocho históricos mantienen los bytes/hashes exactos probados. Solo documentación/changelog
de entrega adicional: Xcode N/A por paridad literal. Revisión focal previa a entrega PASS sin hallazgosP0–P3:
919archivos, huella inicial/final/revisor/root `a71bd67cfa426e4ce7319fad522e8a7454d1fcd417b14c84dd35b111de3cfc3e`.
Confirmó6hashes y8históricos exactos, nativo2493/1534/66/18, dos logs, estilo y4documentos. Resultado Git pendiente.
PLU-98 In Progress / Jesus Franco; sin comentarios concurrentes ni parent/milestone13 existentes, proyecto In Progress.
Avisos AppIntents, seis enlaces Desktop históricos08.3, intermitencia Stock no corregida y límite DYLD del diagnóstico
adicional conservados. No servidor/Rules reales, UI, materialización SwiftData, PDF/correo, cierre13.12 ni activación.

### Entrega verificada 13.3

[PR52](https://github.com/JFrancoG/FranAlonso/pull/52) MERGED03/10/2026 11:49:58 Madrid:
feature `e18b92a7d50b5eda8d21024f86de82af40573f52` → merge `9bdc2216d06ee66ec5ffb047fc6f06e4d1198e23`.
Árbol completo del merge idéntico al head revisado; seis Swift nuevos y ocho históricos byte-exact al manifest.
Revisión independiente PR PASS sin hallazgosP0–P3: diff remoto/local de diez archivos idéntico,92200bytes,
SHA256 `c474fc32ca162315c3686629521e63b73059d51c31e3e9d1e06f1899f43eab18`.
919archivos, huella inicial/final/revisor/root `1d03381768ab39bcb5ff90b598bbf4cb3db397c35e56203c5ff38a514e75b280`.
Dictamen publicado COMMENTED con cuenta propietaria, sin atribuir aprobación a otro colaborador humano.
Head protegido con match-head-commit, CLEAN/MERGEABLE. Sin checks/workflows remotos ni protección/rulesets;
no se declara CI verde. Main local fast-forward al merge; ramas local/remota eliminadas tras ancestry y cero
commits únicos, y HEAD remoto de feature verificado antes de borrarlo.

PLU-98 pasó automáticamente a Done tras merge; completedAt09:50:00.070 UTC verificado. Proyecto In Progress,
sin parent/milestone13 existente. Fase13 abierta;13.4 exige autorización propia. Deuda accesible previa mantiene
responsables y recuperación tras feedback/estabilización, antes del primer candidato real. UI/accesibilidad13.3 N/A.
Se reutilizan2493/2493ejecuciones,1534declaraciones,66/66casos nuevos, ambos builds y PRE/POST/estilo PASS.
Este cierre cambia únicamente Progress,phase13 y CHANGELOG: Xcode adicional N/A por paridad literal de14Swift.
Avisos AppIntents/enlaces históricos, intermitencia Stock sin diagnóstico y límite DYLD conservados. Sin server/Rules
reales, composición/tráfico, SwiftData13.10, PDF/correo, cierre13.12, live ni implementación13.4.
Descripción/comentario de entrega PLU-98 y snapshot de proyecto se reconcilian con este resultado definitivo.

Reauditoría final documental PASS sin hallazgosP0–P3:919archivos, huella inicial/final/revisor/root
`2392bc00f47a84f011e9502b7ec5a7271c7a43868b388b3463c252b9abb3193d`.
Confirmó Git/PR/review/árbol `c913428aca95de0739a369be776cced72d11486d`, ancestry/ramas eliminadas,
PLU-98 Done/proyecto In Progress y tres documentos. Reconciliación externa prevista tras este commit documental.
Este registro posterior del dictamen no altera ningún Swift; Xcode N/A por paridad literal.

## 13.2 / PLU-97 — Entregada; Done

03/10/2026: «abre issue y rama e implementa 13.2». [PLU-97](https://linear.app/plusprojects/issue/PLU-97)
Done / Jesus Franco tras [PR51](https://github.com/JFrancoG/FranAlonso/pull/51);
rama `codex/plu-97-billing-document-reservation` eliminada, base `ee97380` main/origin limpio.
[Propuesta exacta](13-2-billing-reservation-proposal.md). PRE independiente PASS sin hallazgos antes de código:
909 archivos, digest inicial/final/revisor/root `944ec711df66681414ada01a85be93be70b35fc44fd6312a5e00b0a41c8de620`.
Baseline 13.1 reutilizado inicialmente por paridad literal: 2393 ejecuciones, Billing 34/22, ambos builds y
PRE/POST PASS. Los cinco Swift de 13.1 conservan exactamente el manifest histórico incluido al final.
Esa solicitud no autorizaba entrega Git/Done. La autorización posterior de entrega se registra abajo;
13.3 y live conservan gates propios. Fase 13 abierta; deuda accesible previa intacta.

### Implementación y TDD 13.2

Nuevo contrato `BillingDocumentReservationRepository: Sendable`: reserva atómica número/documento, replay del
request íntegro, conflicto de identidades/contenido y series independientes para ticket/factura. Errores neutrales.
Nuevo `ReserveBillingDocumentUseCase` genérico: una llamada por intento, correlación completa de la respuesta,
cancelación antes y después del contacto, propagación de errores neutrales y traducción del fallo desconocido.
El llamante conserva el request para recuperar explícitamente un commit cuya respuesta se perdió. No genera
identidades, fechas o números; no cachea, reintenta automáticamente, muta estado local ni cierra la venta.
La autoridad real, transacción e idempotencia Firestore pertenecen a 13.3; el doble actor no las acredita.

Tests escritos primero, 11 declaraciones / 34 ejecuciones: replay tras recrear UseCase, series intercaladas,
nueve variantes de conflicto, identidad de documento reutilizada, diez variantes de respuesta mal correlacionada,
cuatro errores neutrales, error desconocido, respuesta perdida y cancelación previa/postcommit/nativa.
Gates deterministas sin sleeps; se drenan tareas y continuations también en RED.
Dos fallos de setup se corrigieron antes del RED ejecutable: initializer del actor en extensión y ambigüedad de
macro Swift Testing para arrays de enteros. Esta última se resolvió conservando cuatro oráculos individuales
41/42/91/92; no se retiraron expectativas ni tests históricos.

RED compilable 03:01:58: **34/34 FAIL**, por el stub que devuelve unavailable;
summary `RunSomeTests/AFE343DA-2D50-4A15-9612-A813564B9C5E.txt`.
GREEN focal 03:02:57: **13/13 PASS**, selección parcial de argumentos por Xcode;
summary `RunSomeTests/44FF0F32-7366-4B03-9670-D843AAE6E567.txt`.
No se atribuye cobertura completa al GREEN parcial; la matriz completa se verificó en la suite global.
Estos bundles focales no quedaron disponibles para lectura nativa; se conserva la evidencia MCP/summary completa.

### Validación definitiva 13.2

Xcode MCP oficial estable, Xcode 27.0 (27A266), `workspace-PfnUYLlMzY`; Develop/plan Develop,
iPad Pro 13-inch (M5) Simulator 27.2 / SDK 27.0. Target 27.0, Swift 6 complete/default nonisolated;
warnings Swift/Clang como errores. Configuración y archivos históricos sin cambios.
Build-for-testing Develop 03:21:12 / 24.212 s PASS (`BuildProject-Log-20261003-032112.txt`);
Production 03:09:34 / 31.277 s PASS (`BuildProject-Log-20261003-030934.txt`).
Cero diagnósticos estructurados Swift/Clang; logs completos: únicamente dos avisos conocidos AppIntents por build.
Builds incrementales; no se afirma clean-build ni cero warnings globales. Scheme/plan/destino inicial conservados.

RunAllTests definitivo 03:21:12: **2427/2427 ejecuciones PASS**, 1516 declaraciones;
cero failed/skipped/expected/notRun. Summary `RunAllTests/F29C6B05-EBBC-44C5-8072-81F12FB90B87.txt`, bundle
`RunAllTests/Test-FranAlonso-Develop-2026.10.03_03-21-12-+0200.xcresult` en ActionArtifacts/default.
xcresulttool confirma 1516/1516 declaraciones y 2427/2427 ejecuciones; nueva suite 11/11 declaraciones,
34/34 ejecuciones y todos los grupos parametrizados completos (10/9/2/4/2/2).
UI/previews/localización/accesibilidad 13.2 N/A: solo Domain, sin pantallas ni texto visible.
Sin acreditación de backend real, durabilidad Billing, PDF, correo, cierre 13.12 o live.

### Intermitencia histórica de Stock observada

Primer RunAllTests 03:06:12: 2426/2427 PASS; 34/34 nuevos PASS. Único fallo en
`StockSyncDurabilityTests.swift:118`: weak ModelContainer no nil después de un acknowledge/reopen.
Summary `RunAllTests/54F69667-5D94-4A05-93B4-759F2B9C4A56.txt`; bundle nativo confirma 1515/1516 declaraciones.
Se reprodujo focalmente en Develop y Production, sin modificar ese test ni sus helpers o producción Stock.

Abrir el worktree baseline exacto `ee97380` necesitó autorización nativa Xcode: no se abrió ni se ejecutó allí;
checkout limpio archivado. Alternativa aceptada previamente por el revisor: excluir temporalmente de compilación
solo los tres Swift nuevos mediante `#if false`, build Develop 03:20:23 / 28.879 s PASS y mismo test 0/1 PASS,
fallando otra vez en la línea 118 (`RunSomeTests/7223FD1A-7938-4809-B53B-C497266CF0F2.txt`).
Control de aislamiento funcional: demuestra que el fallo puede aparecer sin ejecutar las incorporaciones 13.2;
no representa un checkout baseline exacto ni demuestra la causa de la retención.
Restauración en finally de los bytes exactos; huella completa 912 archivos volvió al digest POST de abajo.
La ejecución definitiva posterior pasó también ese test, sin alterar ninguna expectativa.
Se registra la intermitencia; no se declara corregida, no se omite el test y su diagnóstico queda separado de 13.2.

### Estilo, POST y gobernanza 13.2

Estilo independiente: tres Swift; script cero candidatos, pase manual detectó un patrón en dos closures
`try await` en línea. Normalizadas a multiline sin cambiar comportamiento ni expectativas; reauditoría focal PASS
antes de builds definitivos. Huella inicial 912 archivos `17323b4a8e5ffcd739a52434d967d5b482a2d7c211b2a449278f0c9c817b2282`;
tras corrección, inicial/final/root `f49069b3cabcdec6d5be0ff1f04d6159b20307ca73e494a9fb761ff55544bd57`.
POST independiente `billing_13_2_post`: código/evidencia PASS, sin hallazgos P0–P3, huella operacional read-only
912 archivos inicial/final/root idéntica al digest anterior. Verificó PRE, RED/GREEN, primera regresión con fallo
histórico, builds completos y manifest. Reauditoría documental/de validación final PASS sin hallazgos P0–P3:
912 archivos, huella inicial/final/revisor/root
`ba18be5eb8873fe66b18c7542a106c0ecb0814edf8d2d929b75121202e599b2e`.
Verificó el control y restauración exacta, 2427/2427 ejecuciones / 1516 declaraciones finales, los 34 nuevos
completos, Stock Passed, ambos logs y los tres documentos. La causa de su intermitencia continúa sin diagnosticar.
Sin imports UI/persistencia/SDK, opt-outs, GCD, JSONSerialization, dependencias o cambios de target en el alcance.
Gobernanza: únicamente seis enlaces Desktop históricos rotos de 08.3, conservados; diffcheck PASS.
No hay cambio de código posterior al manifest. Actualizaciones documentales adicionales: Xcode N/A por paridad.
PLU-97 permaneció In Progress hasta la entrega autorizada y verificada más abajo.

### Manifest Swift 13.2 probado

SHA256 de los únicos tres Swift nuevos; todas las directivas del control temporal retiradas:

```text
BillingDocumentReservationRepository.swift 00f9422f0cbc1ecbe86a7aad907911000b0af4c3930942053e0a8eaecfd11116
ReserveBillingDocumentUseCase.swift ad757cccab7c127c4e7bb818e6b7bc2b524969e4184808e22477dca6987a9098
ReserveBillingDocumentUseCaseTests.swift 4e6b8654c71f6c095880d1b2adcb62a1477d710bbf486ec2533bb89461c8c899
```

### Autorización de entrega 13.2

03/10/2026: el propietario solicita «commit, push y entrega». Autoriza el mismo recorrido completo establecido
para 13.1: commit del alcance exacto, push, PR/revisión/merge, reconciliación PLU-97 Done y limpieza de rama
tras comprobar ancestry. No autoriza 13.3, cierre de fase 13 ni live.
Se reutilizan 2427/2427 ejecuciones, 1516 declaraciones, 34/34 casos nuevos y ambos builds/PRE/POST/estilo PASS:
los tres Swift 13.2 y cinco Swift 13.1 mantienen los hashes exactos probados/auditados.
Solo se añade documentación/changelog de entrega: Xcode adicional N/A por paridad literal.
Revisión focal previa a entrega PASS sin hallazgos P0–P3: 912 archivos, huella inicial/final/root
`50774cfbf5bc5a0ce4d2117fd88702896d1d8c5ac076d01e7ca7705429d87631`.
Confirmó ocho Swift exactos y audit de estilo de los tres nuevos: cero candidatos, pase manual PASS.
Resultado Git definitivo pendiente. El propietario reconectó Linear tras la reautenticación requerida;
PLU-97 In Progress / Jesus Franco, sin comentarios concurrentes ni parent/milestone13 y proyecto In Progress.
No se declara Done hasta comprobar entrega y estado. La intermitencia observada en Stock sigue sin corrección.

### Entrega verificada 13.2

[PR51](https://github.com/JFrancoG/FranAlonso/pull/51) MERGED 03/10/2026 10:04:19 Madrid:
feature `09b5e193dd35d6bc0b3df49f920d895a98d85acd` → merge `29b4b8a9a6aa9f8e00898d110a06126dc573b567`.
Árbol completo integrado idéntico al head revisado; tres Swift nuevos y cinco históricos exactos al manifest probado.
Revisión independiente de PR PASS sin hallazgos P0–P3: diff remoto/commit local idénticos, siete archivos previstos;
912 archivos, digest inicial/final/root `2ffe7e98ca0f6d97ac24ddba2ca4b26547d9e1ac34b7c7691fbe11ebc48cce49`.
Dictamen registrado como COMMENTED en GitHub, sin atribuir aprobación a otro colaborador.
Head fijado con match-head-commit antes de merge; CLEAN/MERGEABLE, sin checks/workflows remotos ni protección/rulesets.
No se declara CI verde. Main local fast-forward; ramas local/remota eliminadas tras ancestry y cero commits únicos.

PLU-97 pasó automáticamente a Done tras el merge; estado verificado con completedAt 08:04:20 UTC.
Proyecto In Progress; sin parent/milestone de fase 13 existentes. Fase 13 permanece abierta y 13.3 requiere su propio inicio.
Reconciliación de descripción/comentario de entrega y snapshot de proyecto basada en este resultado verificado.
UI/previews/localización/accesibilidad 13.2 N/A; deuda previa conserva responsables y condiciones de recuperación.
Se reutilizan 2427/2427 ejecuciones, 1516 declaraciones, 34 casos nuevos, ambos builds y PRE/POST/estilo PASS.
Este cierre modifica solo documentación/changelog: Xcode adicional N/A por paridad literal de los ocho Swift.
Intermitencia del test histórico de Stock sin corrección ni causa atribuida; avisos AppIntents conocidos conservados.
Diffcheck y enlaces del alcance PASS; gobernanza mantiene únicamente seis enlaces Desktop históricos rotos de 08.3.
Sin backend real, persistencia Billing, PDF/correo, cierre 13.12, live ni implementación 13.3.

Reauditoría final documental PASS sin hallazgos P0–P3: 912 archivos, huella inicial/final/root
`ebef4124d6ec654bd42621ab5d7129d436de6b64417e2bccd496d0e8a9d0f67f`.
Verificó PR/merge, tres árboles idénticos, ancestry/ramas eliminadas, PLU-97 Done y los cuatro documentos.
Descripción y comentario de entrega reconciliados; snapshot de proyecto actualizado sin cambiar In Progress.
Registro posterior de este resultado exclusivamente documental; ocho Swift probados intactos, Xcode N/A.

## 13.1 / PLU-96 — Entregada; Done

03/10/2026: autorización «Abre issue y rama e implementa la subfase13.1».
[PLU-96](https://linear.app/plusprojects/issue/PLU-96), Done/Jesus Franco tras la entrega verificada más abajo;
`codex/plu-96-billing-domain-states`, baseline `38b49f4` en main/origin/main sin cambios locales.
[Propuesta y límites](13-1-billing-domain-proposal.md). [PR50](https://github.com/JFrancoG/FranAlonso/pull/50)
integrada; rama local/remota eliminada. Fase13 abierta,13.2 conserva autorización propia.

## Puerta de inicio

Constitución, spec13, ADR0003/0004/0008/0011/0030 y política Swift revisados. Billing04.6 tenía estados
pending/numbered pero permitía construcción mediante solo saleID sin validar pago. No hay DTO, esquema SwiftData
ni consumidor productivo de esas fábricas. Sale ya conserva documento obligatorio en closed/voided y rechaza cierre
antes del pago; esa lógica y su serialización no cambian13.1.

PRE independiente `billing_13_1_pre` PASS sin hallazgosP0–P3 antes del código. Modo operacional read-only:
904archivos Git tracked/untracked no ignorados, digest inicial/final/root idéntico
`8c40dc936bd9975b654a59b5b732d71881fad66f76e5643c5b6eb9e4ad504568`.
Apple Codable leído completo por el revisor; custom decode/encode contrastados con Xcode DocumentationSearch.
Spec04 alineada con la separación solicitud local/documento remoto de13.1.

## Baseline actual

Xcode27.0(27A266), MCP oficial estable Service `workspace-PfnUYLlMzY`; Develop, planFranAlonso-Develop,
iPad Pro13-inch(M5) Simulator27.2/SDK27.0. Target27.0, Swift6 complete/nonisolated y warnings Swift/Clang como errores.
Inventario1491declaraciones. Billing/SaleDomain/Workday:35/35ejecuciones PASS,0failed/skipped/expected/notRun.
`RunSomeTests/E1DF7396-A39F-4895-84B5-50C50270DD06.txt`, bundle01:45:48Madrid03/10.
Build baseline:0diagnósticos Swift/Clang; aviso conocido AppIntents metadata en app y test target.

## Implementación y TDD

`BillingDocumentRequest` valida la venta pagada en awaitingDocument y conserva el snapshot exacto/identidades/familia.
Rechaza venta impagada/terminal y fecha no finita tanto al construir como al decodificar; precedencia causal por estado.
`BillingDocument` es el registro numerado confirmado: serie compatible, entero positivo y fecha finita preservada.
No compara relojes independientes ni reserva/incrementa números ni acredita PDF final.
`BillingDocumentLocalState` separa pendingNumber/failed/numbered;
fallos neutrales sin strings de infraestructura, reintento con idéntica solicitud, recuperación desde failed y replay
exacto idempotente. Conflictos de request/snapshot/número/fecha no reemplazan el estado; numbered no vuelve a pendiente.

Se conservan/adaptan los8casos anteriores y se añaden14declaraciones de comportamiento. El codec preparatorio04.6
sin solicitud pagada se rechaza explícitamente; no existe store/DTO Billing publicado ni datos reales que migrar.
Sale.close/DTO/schema y política de Jornada intactos: confirmar número no cierra la venta.13.12 verificará documento final.

Tests primero y superficie mínima compilable: primer build detectó un `try` ausente en un payload de test; corregido
sin cambiar expectativas. RED ejecutable01:56:59:34ejecuciones,17PASS/17FAIL,9declaraciones con fallo, por las nuevas
invariantes deliberadamente ausentes. No fueron fallos de setup. Summary `559ADC25-F104-427C-ABBF-65CECC438FBF.txt`.
Tras implementación, GREEN focal01:57:50:26/26PASS; inspección del log detectó selección parcial de algunos argumentos
por Xcode. Ese resultado no acredita toda la matriz: resuelto mediante RunAllTests posterior.

## Primera validación por Xcode MCP

Misma conexión/SDK/destino. Build-for-testing Develop02:01:20/12.121s PASS:
`BuildProject-Log-20261003-020120.txt`; Production02:02:23/27.334s PASS:
`BuildProject-Log-20261003-020223.txt`.0diagnósticos estructurados Swift/Clang.
Logs completos inspeccionados: únicamente2avisos conocidos AppIntents metadata por build (app y target test).
Builds incrementales, sin afirmación de clean-build ni de cero warnings globales. Develop/plan/destino inicial restaurados.

RunAllTests02:01:20:2393/2393ejecuciones PASS,1505declaraciones en inventario,
0failed/skipped/expected/notRun. Summary `2934C230-40D2-4566-8CEF-3D019CEEF2EA.txt`;
bundle `Test-FranAlonso-Develop-2026.10.03_02-01-20-+0200.xcresult`, en ActionArtifacts/default/RunAllTests.
Inspección nativa con xcresulttool confirma Billing34/34ejecuciones de22declaraciones y los8grupos parametrizados
completos (2/3/2/3/3/3/2/2casos). Regresión incluye Sale, Jornada, pago/stock, persistencia/sync y resto de suite.
No prueba emisión fiscal, Firestore/Storage/correo reales, recuperación durable Billing ni cierre13.12.

## Estilo, auditoría y gobernanza

Auditoría independiente `billing_style`:5Swift; script0candidatos, pase manual detectó1guard fragmentado118columnas.
Compactado y reauditoría focal PASS antes de validación final. Digest read-only inicial/final908archivos:
`328b4047f8559b4f4e90b1706a497cdac7b864df7010693ad8bfb6b334e83ce0`;
revisión tras corrección `14895f8f037cdf97683ae9d2a73f3bc8ea4a1ca9a077c7cf295c8226f681caa3`.
Sin imports UI/persistencia/Firebase/PDFKit, opt-outs, GCD, JSONSerialization ni dependencias nuevas en el alcance.
UI/previews/localización/accesibilidad13.1 N/A: solo Domain sin pantalla ni texto visible.
Gobernanza repetida: únicamente6enlaces históricos rotos08.3, idénticos al baseline; diffcheckPASS.
Primera POST:1P2 de comparación de relojes, corregido debajo; sin otros hallazgos. Reauditoría focal PASS.
La deuda accesible previa mantiene sus issues/responsables/trigger.
Fase13 abierta; solo13.1 autorizada. Entrega13.1 verificada debajo; live y13.2–13.13 conservan gates separados.

## P2 corregido y validación definitiva

`billing_13_1_post` comprobó causalidad de pago, captura local paymentDate() y
[timestamp del servidor](https://firebase.google.com/docs/firestore/manage-data/add-data#server_timestamp).
Las comparaciones requestedAt/issuedAt>=paidAt suponían una autoridad de reloj común no garantizada. Podían impedir
solicitud desde otro dispositivo o recuperación de una asignación ya confirmada. Propuso y aprobó read-only antes del
ajuste conservar fechas finitas exactamente y usar awaitingDocument como prueba causal del pago.
Gate inicial: corregirP2;908archivos, digest inicial/final/root idéntico
`920bcca25225e6fe008946370753facaac99152ceb0038f01859ff9dd334a2a0`.

Tests del desfase escritos antes de retirar comparaciones: RED2/2FAIL02:11:17 con invalidChronology,
summary `D4A45E0F-D664-4665-BF11-0EF2A571F650.txt`; GREEN2/2PASS02:12:05,
summary `70272543-0ED1-4EA3-9988-627BC04EC853.txt`. Dos expectativas temporales del diseño inicial sustituidas por
el contrato causal revisado; no se debilita el gate de pago ni se fabrican fechas. Retirado invalidChronology;
constructor/decoder/aceptación/replay prueban paidAt200/requestedAt199 o issuedAt199 según el reloj originario.

Estilo independiente repetido sobre cambios de entidades/tests:5Swift/0candidatos/manualPASS,
0líneas>120; digest908files `1f3d8c0653bed4609b394e752844992a47dfa0885e0b4b25344eaf3f8de99630`.
Después: Build-for-testing Develop02:13:37/3.554s PASS (`BuildProject-Log-20261003-021337.txt`),
Production02:14:22/28.643s PASS (`BuildProject-Log-20261003-021422.txt`);0diagnósticos estructurados Swift/Clang.
Logs completos conservan únicamente los avisos conocidos AppIntents; build incremental, sin certificado clean-build.
Scheme Develop/plan/destino inicial restaurados.

RunAllTests definitivo02:13:37:2393/2393PASS,0failed/skipped/expected/notRun;1505declaraciones.
Summary `28266BE4-F100-45E9-B262-81F8752A57A1.txt`, bundle
`Test-FranAlonso-Develop-2026.10.03_02-13-37-+0200.xcresult`, ActionArtifacts/default/RunAllTests.
xcresulttool confirma Billing34/34ejecuciones de22declaraciones con todos los argumentos completos, incluidos desfases.
Manifest siguiente corresponde exclusivamente al código definitivo probado. Reauditoría POST focal PASS.

## POST definitivo y estado de entrega

`billing_13_1_post` verificó la corrección, RED2/GREEN2, bundle definitivo2393/1505 y Billing34/22/todos argumentos,
manifest5Swift y ambos logs. P2 resuelto; sin hallazgosP0–P3 restantes. Revisión operacional read-only908archivos,
digest inicial/final/root idéntico `5995db168f7d5f1e4aabf3495eaf7d7e31da9796546e7212f4e3e345a4450878`.
Actualización posterior exclusivamente documental: paridad literal de5Swift probados/auditados; Xcode adicionalN/A.
Tras POST, PLU-96 permanecía In Progress/Jesus; documentación y descripción reconciliadas. Rama local lista para entrega;
sin commit/push/PR/merge/Done en ese momento. Fase13 abierta,13.2 y live conservan sus gates.

## Autorización de entrega03/10/2026

El propietario solicita «commit, push y entrega». Autoriza el recorrido completo de13.1 ya establecido:
commit del alcance exacto, push de rama, PR/revisión/merge, PLU-96 Done y limpieza de rama tras comprobar ancestry.
Resultado Git definitivo pendiente; PLU-96 aún In Progress. No autoriza13.2, cierre de fase13 ni live.
Se reutilizan2393ejecuciones/1505declaraciones, Billing34/22, buildsDevelop/Production y PRE/POST PASS:
los5Swift conservan SHA256 exactos del manifest probado/auditado. Estilo scoped repetido:5Swift/0candidatos,
sin cambios posteriores de código ni hallazgos nuevos. Solo documentación/changelog; Xcode adicionalN/A.

## Entrega verificada13.1

[PR50](https://github.com/JFrancoG/FranAlonso/pull/50) MERGED03/10/2026 02:36:39Madrid:
feature `ad7c344b59bf0e24289cde52e9404a00b444d4f5` → merge `646fe84ac5705c3ac2126bd6595200a70426d56a`.
Árbol completo del merge idéntico al head revisado;5Swift exactos al manifest probado/auditado.
PR CLEAN/MERGEABLE con head fijado antes de merge; sin workflows/checks remotos ni protección de main.
No se declara CI verde. Main local fast-forward; ramas local/remota eliminadas tras ancestry y0commits únicos.

PLU-96 pasó automáticamente a Done tras el merge; estado verificado y descripción/comentario de entrega reconciliados.
Proyecto In Progress, sin parent/milestone13 existente; no se cierra fase13.13.2 es el siguiente gate independiente.
UI/previews/localización/accesibilidad13.1 N/A; deuda previa conserva issues/responsables/trigger.
Se reutiliza la validación literal anterior:2393/2393, Billing34/22, buildsDevelop/Production, PRE/POST y estilo PASS.
Este cierre cambia solo documentación/changelog: Xcode adicionalN/A. Diffcheck/enlaces del alcance PASS;
gobernanza conserva únicamente6enlaces Desktop históricos08.3, y AppIntents mantiene sus avisos conocidos.
Sin backend, PDF, persistencia Billing, correo, cierre13.12, live ni implementación13.2.

## Manifest Swift definitivo probado

SHA256 por archivo; los tres primeros viven en Billing/Domain/Entities, los dos últimos en FranAlonsoTests:

```text
BillingDocument.swift 01689d22c7c6c236713df0e9cd504e007f4b0c1a8beac7a82674d024a231c430
BillingDocumentRequest.swift c806e7eaf78b3fe3c896d32d1fc04ba7428acf05dbbdc313c2c058ca4b22dce9
BillingDocumentLocalState.swift 2b7a0ca80f25cab8bf4c706ec5df3df577af310abeda5777295c9f5ce0b6a2a1
BillingDocumentTests.swift b8836eaffed88f135253a795468749b153a5d2de945f254af0c2f0c5b10bf873
BillingDocumentRequestTests.swift f7b870233c36eb9dcd96451f900e78953e0c01d14509f40518982ce8e2cd52ed
```
