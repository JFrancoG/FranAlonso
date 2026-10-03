# Fase13 — Facturación, PDF, correo y numeración

## 13.2 / PLU-97 — Implementada; entrega pendiente

03/10/2026: «abre issue y rama e implementa 13.2». [PLU-97](https://linear.app/plusprojects/issue/PLU-97)
In Progress / Jesus Franco; rama `codex/plu-97-billing-document-reservation`, base `ee97380` main/origin limpio.
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
PLU-97 conserva In Progress hasta verificar la entrega autorizada más abajo.

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
