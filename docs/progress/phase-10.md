# Fase 10 — Catálogo comercial de servicios

## Estado actual — 10.7 entregada — 2026-09-30

[PR30](https://github.com/JFrancoG/FranAlonso/pull/30) MERGED. Commit760a7e7e7781c2a7dd040d47a3d57ce12feea10d,
mergecf3ff20685debb487307a05da337e74e4d0247e9. Árbol completo idéntico al head validado; PLU-68 Done confirmado.
Rama local/remota eliminada tras ancestry y cero commits únicos. GitHub CLEAN/MERGEABLE, sin checks/reviews ni
protección/rulesets configurados. Se reutilizan PRE/POST,1.564resultados y builds: los seis Swift conservan la huella
validada y los cambios de entrega son documentales. Xcode nuevo N/A; aviso AppIntents y seis enlaces históricos08.3 intactos.
10.1–10.7 quedan entregadas funcionalmente. Fase10/PLU-59 sigue In Progress por la evidencia integral de PLU-65/67,
Jesus Franco, tras feedback/estabilización y antes del primer candidato para uso real. Sin activación live.
Siguiente planificado: adelanto textual FoundationModels/PLU-47 con propuesta/PRE y autorización propias; no iniciado.

## Historial de implementación — 10.7 — 2026-09-30

[PLU-68](https://linear.app/plusprojects/issue/PLU-68), In Progress, Jesus Franco, hija de PLU-59.
Rama `codex/phase-10-7-service-picker`, base main/origin/main3ddb84f limpia tras cierre10.6.
[Propuesta](10-7-service-picker-proposal.md), PRE independiente PASS;665archivos idénticos verificados reviewer/root,
SHA2569b21252115dc304882c32e41bd6d1c8a9feb3ac5752de00e56e91ceaae84fb87. Implementación autorizada.
Búsqueda, filtro activo/tipo y selección de Service inmutable; sin UI/SaleLine/stock/writes/live. TDD y POST PASS.
PLU-65/67 Backlog intactos; fase10 sigue abierta. Entrega10.7 completa autorizada; FoundationModels requiere autorización posterior.

### Validación10.7

- RED compilable: Develop con tests22,538s PASS. Nueve declaraciones/20resultados fallan por comportamiento ausente,
  cero PASS/skips/notRun. Selección, elegibilidad, estados, generaciones y composición; sin fallos de setup.
  Summary `RunSomeTests/A8B0F827-B9E3-4FD8-833C-46D9190B27F0.txt`, consola01:22:53. Tests intactos después de RED.
- GREEN global: **1.082 declaraciones /1.564 resultados PASS**, incluidos los20nuevos; cero fallos/skips/notRun,
  expectedFailures y runtimeWarnings. Una sola regresión global incluye variantes y composición previa, sin repetir focal.
  Summary `RunAllTests/F2B61E6F-C691-451B-97AC-D2EE7944ED4C.txt`; consola `test-console-log-2026-09-30T01-24-28+02-00.txt`.
  Resultado nativo original cerrado, finishTime presente: DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/
  `Test-FranAlonso-Develop-2026.09.30_01-24-28-+0200.xcresult`. Develop/iPhone18Pro/iOS27.0.
- Develop con tests14,655s y Production21,155s PASS. Logs completos `BuildProject-Log-20260930-012423.txt` y
  `BuildProject-Log-20260930-012511.txt`: sin warnings Swift/Clang ni errores, solo AppIntents metadata previo.
  Scheme/plan Develop e iPhone18Pro restaurados; configuración target26/Swift6/strict completa intacta.
- Seis Swift cambiados; style recall cero candidatos; revisión manual detectó123columnas en una llamada de test.
  Corregida a formato vertical y rerevisión focal PASS, sin diferencias de tokens. `git diff --check` limpio.
  Gobernanza solo seis enlaces históricos08.3 ausentes. Sin nuevas dependencias, unsafe ni XCTest/XCUITest.
- Composición usa repositorio real in-memory compartido, alta/edición/desactivación y recargas finitas. Streams controlados
  prueban reemplazo en vivo y generaciones sin sleeps/polling. No atribuye nuevo refresco continuo a SwiftData.
- UI/previews/accesibilidad nueva N/A: no cambian Views, recursos, textos ni interacciones renderizadas. PLU-65/67 mantienen
  deuda propia con Jesus Franco, tras feedback/estabilización y antes de uso real; no se cierra fase10.
- POST independiente: solo P3 de formato123columnas en AppDependenciesTests.swift499. Corregido y POST2 focal PASS,
  sin hallazgos restantes. Reviewer/root verifican670archivos idénticos antes/después en ambas revisiones:
  POST1 `/tmp/franalonso-10-7-post1.json`, SHA2564f3a787f6d9af2d806cec7ce83efb84ae02542ad1b7e8121f5eeab739f7c63ae;
  POST2 `/tmp/franalonso-10-7-post2.json`, SHA2566095c26b9a5cc1718ca6b21ac515043c6ac65bd8a46c6f5b46119fa88a5cbc04.
  Auditores read-only, sin builds ni mutaciones. Root/auditor confirman que el delta es exclusivamente whitespace.
- Build final Develop con tests23,807s PASS tras formato; log `BuildProject-Log-20260930-012939.txt`, solo AppIntents
  conocido. GetBuildLog warning0issues (`CC964DCE-5ECA-446A-9F58-D6BDD5D26C6D.txt`). Suite global/Production reutilizadas
  por igualdad semántica; sin repetir pruebas. Consola conserva faults esperados de pruebas previas SwiftData read-only/
  corrupción, no fallos del test ni runtimeWarnings en el resultado nativo.
- Tras verificar POST2 solo se actualizan estos registros y Linear. PLU-68 In Progress, cambios locales sin commit/push;
  entrega10.7 autorizada. Siguiente después de entregar: adelanto textual FoundationModels/PLU-47 según ADR0030.

## Entrega anterior — 10.6 entregada — 2026-09-30

[PR29](https://github.com/JFrancoG/FranAlonso/pull/29) MERGED. Commit5db50c342e26baa6e155a33064dc1321b7ee49b8,
merge3bb7155c6f6db9801c9c8168142126064492e433. Árbol completo idéntico al head validado. PLU-66 Done confirmado.
Rama local/remota eliminada tras ancestry y cero commits únicos. GitHub CLEAN/MERGEABLE, sin checks/reviews ni
protección/rulesets configurados. PRE/POST,1.544resultados, builds, previews y smoke reutilizados; nuevo Xcode N/A
por cierre documental. PLU-65/67 Backlog mantienen deuda integral, Jesus Franco, tras feedback/estabilización y antes
de uso real. Fase10 In Progress. Implementar10.7 autorizado; requiere propuesta/PRE antes de código.

## Historial de implementación — 10.6 — 2026-09-30

[PLU-66](https://linear.app/plusprojects/issue/PLU-66), In Progress, Jesus Franco, hija de PLU-59.
Rama `codex/phase-10-6-linked-product-selector`, base limpia01d0657 tras entrega10.5.
[Propuesta](10-6-linked-product-selector-proposal.md): PRE1 P2 de finalización snapshot corregido;
PRE2 PASS, 661archivos idénticos, SHA256 e57089c7c440035eff550b6e3c9d861a76396a9392b7c2df70e1626811a49d5c.
Picker nativo de tipo/producto, observación independiente, selección/sustitución y recuperación sin
perder borrador. Sin Domain/Data/esquema/sync/live. TDD, regresión, smoke y POST PASS para demo (ADR0029).
[Matriz10.6](../accessibility/evidence/10-6-linked-product-selector.md), PLU-67 Backlog propia.
El propietario autoriza entrega completa10.6 e implementación10.7; fase10 permanece abierta.

### Validación 10.6

- TDD: RED1 17 fallos/3 PASS sobre20 resultados; las tres guardas se reforzaron con una selección válida previa.
  RED2 con stub:17/17 fallos semánticos,12 declaraciones representadas; RunSomeTests omitió7 variantes.
  Los tests de composición se añadieron antes de GREEN. Informe `/tmp/franalonso-106-model.md`.
  Summaries RED `CA1365EB-A597-4850-B96C-F85903725B60.txt` y `5E14F838-83B5-494C-BBA9-90B2C2239E93.txt`.
- GREEN global Xcode MCP: **1.073 declaraciones / 1.544 resultados PASS**, cero fallos/skips/notRun/runtime warnings.
  Incluye las24 invocaciones nuevas: selección/sustitución/conversión, observación/error/retry/cancelación/cierre,
  composición contextual real, rechazo sin efectos al inactivar y recuperación por otro producto o Profesional.
  Summary `RunAllTests/E6F18335-294E-43E2-9FEC-DB8F827362EA.txt`; consola `test-console-log-2026-09-30T00-49-26+02-00.txt`.
  Native `.xcresult` cerrado: `Test-FranAlonso-Develop-2026.09.30_00-49-26-+0200.xcresult`, finishTime presente,
  DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test. Develop/iPhone18Pro/iOS27.0.
- Build Develop con tests PASS16,958s; Production PASS21,59s tras simplificar sección visual. GetBuildLog 0issues;
  logs completos revisados: solo aviso AppIntents metadata conocido, ningún warning Swift/Clang nuevo.
  Logs `BuildProject-Log-20260930-004912.txt` y `BuildProject-Log-20260930-005421.txt`. Develop restaurado.
- Previews de Screen y contenido en Large/XXX Large/AX5, ES/EN, Light/Dark y contraste aumentado representativo.
  Destino real de renders iPhone18ProMax/iOS27.2; no confundir con tests. Componentes permiten inspeccionar catálogo
  elegido, vacío, fallo y vínculo no disponible. Screen XXX/AX capturó carga; contenido determinista complementa.
  Se eliminó duplicación visual de la etiqueta de producto, conservando etiqueta nativa, nombres multilínea y44pt.
  [Matriz y artefactos](../accessibility/evidence/10-6-linked-product-selector.md).
- Después de la suite solo se ajustó presentación de la sección y añadió un preview determinista. Sin cambio de lógica,
  contratos ni tests; builds/previews/smoke validan ese delta, sin repetir la suite global.
- Estilo:11Swift cambiados, cero candidatos tras revisión; diff-check limpio. Gobernanza conserva únicamente los seis
  enlaces históricos08.3 ausentes. Sin XCTest/XCUITest ni UI tests nativos; sin dependencias, unsafe ni live.
- Smoke final Develop/iPhone18Pro/iOS27.0 PASS: entrar/salir del Picker conserva sesión y campos, sustituir
  Champú→Mascarilla, guardar/reabrir conserva nuevo vínculo; Profesional→Producto no restaura vínculo, guardar vacío
  muestra error, elegir y guardar recupera. Informe `/tmp/franalonso-106-smoke.md`, ocho hitos00:57:04–00:58:29.
  Sesión cerrada, argumentos demo NO, esquemas intactos. Build de InstallAndRun succeeded,0issues estructurados;
  log `GetBuildLog/E6A4A76E-3918-45FB-8455-AC7442AF3D68.txt`, solo AppIntents conocido en texto completo.
- Runtime conserva dos avisos SwiftUI `Invalid frame dimension`; ya existían ocho en smoke10.5, log final
  `Service Catalogue Smoke-00_14_30_256-logs.txt`, líneas395/561/673/681/693/797/805/823. Sin impacto observado;
  causa pendiente, seguimiento de layout PLU-65/67. No equivale a warnings Swift/Clang ni a runtimeWarnings de la suite.
  Recuperación de vínculo histórico probada en composición, sin recorrido UI específico; teclado software oculto.
- POST independientes estándares y UI/accesibilidad: PASS funcional, sin hallazgos nuevosP0–P3. Cada revisor y root
  verificaron664archivosidénticos, `/tmp/franalonso-10-6-post1.json`, SHA256
  `91f7360b9bf73fb80cfa12e52b4f6b66e9fb146eaabeaf643100a812eeea8046`. Operacionalmente read-only, sin builds ni ediciones.
  Confirmar en validación integral nombre/valor del Picker Tipo (jerarquía «Tipo, Tipo»), sin afirmar fallo AT.
- PLU-66 continúa In Progress hasta entrega autorizada. PLU-67 Backlog mantiene deuda integral propia con Jesus Franco,
  tras feedback/estabilización y antes del primer candidato real. No se cierra fase;10.7 comienza tras la entrega. Tras las auditorías
  solo se actualizan registros documentales y Linear; código/configuración/tests/recursos conservan la huella revisada.

## Entrega anterior — 10.5 entregada — 2026-09-30

[PR28](https://github.com/JFrancoG/FranAlonso/pull/28) MERGED. Commit792adba414da4e8afe72fce29ea637176534160e,
mergec2f1af0cc248a97ea541f7cef62cb2734e1a791b; árbol completo idéntico al head validado. PLU-64 Done confirmado.
Rama local/remota eliminada tras ancestry y cero commits únicos. GitHub CLEAN/MERGEABLE, sin checks/reviews ni
protección/rulesets configurados. Se reutilizan PRE/POST,1.520resultados, builds, previews y smoke; cierre documental
con Xcode N/A. PLU-65 Backlog mantiene evidencia integral pendiente y responsable Jesus Franco antes de uso real.
Fase10 In Progress. Implementación10.6 autorizada, propuesta/PRE propias antes de código.

## Historial de implementación — 10.5 — 2026-09-30

[PLU-64](https://linear.app/plusprojects/issue/PLU-64), hija de PLU-59, Jesus Franco, In Progress.
Rama `codex/phase-10-5-service-screens`, baseline b4801df. [Propuesta](10-5-service-screens-proposal.md), PRE PASS.
Catálogo con destinos Servicios/Productos; lista buscable y formulario comercial con errores, confirmaciones y Locale
por sesión. Alta profesional; edición conserva ambos tipos/vínculo. Selector y cambios de tipo quedan en 10.6.
Demo aislada con dos servicios coherentes; previews idempotentes. Sin cambios Domain/Data, schema, sync ni live.

### Validación 10.5

- TDD: 5 fallos/1 PASS sobre seis resultados (semillas ausentes y Locale ignorado). GREEN focal 5 PASS, pero Xcode omitió
  la variante en_US; por eso se ejecutó una sola regresión completa, sin ampliar tests tautológicos de Views.
- Xcode MCP Develop, iPhone18Pro/iOS27: **1.061 declaraciones / 1.520 resultados PASS**, cero fallos/skips/runtime warnings.
  `.xcresult` nativo cerrado `Test-FranAlonso-Develop-2026.09.30_00-04-10-+0200.xcresult`, finishTime presente.
  Summary MCP `RunAllTests/6E3012B0-E66D-4E28-A747-D92E877341FE.txt` y log `test-console-log-2026-09-30T00-04-10+02-00.txt`.
  El contenedor nativo está en DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test.
- Build Develop para tests PASS; Production PASS 21,301s. GetBuildLog sin issues; log completo Production conserva
  el aviso conocido AppIntents metadata. Sin warnings Swift/Clang nuevos; warnings-as-errors no cambiado.
- Renders representativos Catálogo/lista/formulario Large/XXX Large/AX5 y componentes; destino devuelto por previews:
  iPhone18ProMax/iOS27.2, distinto al simulador de tests. ES y EN, Light/Dark/contraste incrementado representativo.
  Capturas de carga no se cuentan como contenido; AX5 de lista se complementa con Content de250 elementos.
  [Matriz y artefactos](../accessibility/evidence/10-5-service-screens.md).
- Smoke táctil PASS por Xcode MCP Develop/iPhone18Pro/iOS27: login, ambas entradas de Catálogo, búsqueda, alta inválida→válida,
  edición/descarte/reapertura, edición del servicio producto y desactivación/reapertura inactivo. Sesión cerrada; argumentos
  de demo siguen NO en Git. Identidad exacta del vínculo acreditada por integración; UI solo muestra su conservación.
  Teclado hardware ocultó el teclado software: no se atribuye cobertura de ese layout ni AT a este smoke.
  Informe `/tmp/franalonso-105-smoke.md`, 14 pares jerarquía/captura, tiempos00:10:51–00:14:30; detalle en matriz.
- POST estándares PASS sin P0–P3; POST accesibilidad encontró un P2 de texto: el error de vínculo ofrecía Desactivar también
  al servicio ya inactivo. Corregido ES/EN para ofrecer Cancelar y volver al catálogo; rerevisión focal PASS sin hallazgos nuevos.
  Ambas auditorías verificaron660archivosidénticos, `/tmp/franalonso-10-5-post1.json`, SHA256
  `a5fe752d8505bd0bbcde18b913736c8a92a3bc85d00c405e17df0a4394c488d7`.
- Rerevisión accesible read-only sobre660archivos, `/tmp/franalonso-10-5-post2.json`, SHA256
  `9be48c48b23516b9262220b74a4eb0a5de1d3a6183bc3aeabf31d543ee5efabc`. Root dispone P2 corregido;
  puerta funcional ADR0029 PASS. Criterio3.3.3 sigue Limitado hasta su validación integral.
  BuildDevelop tras copy PASS16,081s y render focal del error PASS; no se repiten tests porque no cambia Swift/contratos.
  Registros finales posteriores son solo documentación; los20Swift y recursos conservan la huella POST2.
- Estilo:20Swift, dos candidatos multilinea justificados por tupla anidada/trailing closure, revisión manual.
  No XCUITest ni pruebas de UI nativas. Gobernanza: solo los seis enlaces históricos08.3 ausentes; diff-check limpio.

PLU-65 Backlog conserva deuda integral propia, Jesus Franco, tras feedback/estabilización antes de uso real.
PLU-64 permanece In Progress hasta entrega. El propietario autoriza commit/push/PR/merge/cierres10.5 e implementar10.6.
La fase sigue abierta. Tras entregar10.5 corresponde selector10.6 con propuesta/PRE, y después picker10.7,
y después PLU-47/FoundationModels según ADR0030. No anticipar venta11–13.

## Entrega anterior — 10.4 entregada — 2026-09-29

[PR27](https://github.com/JFrancoG/FranAlonso/pull/27) MERGED; commit5b9cc0d4a03db5db28cdb565fc5d8d84e3d55f78,
merge86a1d0967065881f52ff71e2e644e84f177515c1. Árbol integrado idéntico al head validado. PLU-63 Done tras integración.
Rama10.4 eliminada local/remota tras ancestry y cero commits únicos. GitHub CLEAN/MERGEABLE, sin checks/reviews ni
protección/rulesets configurados. Se reutilizan PRE/POST, 1.516 resultados y builds; Xcode nuevo N/A por cierre documental.
Fase10 sigue In Progress. El propietario autoriza implementar10.5, con propuesta/PRE antes de código. Límites previos intactos.

## Historial de implementación — 10.4 — 2026-09-29

[PLU-63](https://linear.app/plusprojects/issue/PLU-63), hija de PLU-59, In Progress, Jesus Franco.
Rama `codex/phase-10-4-service-view-models` desde main/origin/main 0c98eae limpios. Implementación autorizada.
[Propuesta 10.4](10-4-service-view-models-proposal.md): PRE independiente PASS, 636 archivos idénticos; huella en propuesta.
Lista y formulario @Observable @MainActor, sesiones estables, borrador comercial completo y entrada decimal exacta ES/EN.
Composición contextual comparte actor/señal en runtime, fixture y preview interactiva; snapshot rechaza mutaciones.
Sin Views, textos, recursos, cambios Domain/Data, schema, sync, live ni nuevas dependencias. UI corresponde a 10.5.

### TDD y validación 10.4

Xcode MCP estable, workspace-EYu6rxi7hg, Develop/iPhone18Pro/iOS27.0, Swift6 estricto/target26, configuración intacta.
28 declaraciones nuevas / 80 resultados: formulario 16, lista 11, borrador 48 y composición 5.
- RED compilable: build 18,94s PASS; 75 resultados con 48 fallos semánticos esperados y 27 PASS (rechazos de entrada
  también satisfechos por el stub). Summary `RunSomeTests/8B8364DD-ECBE-4B50-9B39-CF705F6737D1.txt`.
  Un error previo de visibilidad de enums en fixtures se corrigió antes; no se contabiliza como RED semántico.
- RED de composición: build 18,814s PASS, 4 fallos esperados y 1 PASS con factory de solo lectura;
  summary `RunSomeTests/11796BFC-BB47-4074-AD71-D0D1A57FBF55.txt`. GREEN conecta el adaptador contextual existente.
- GREEN focal de estado/entrada: 29/29 PASS; summary `RunSomeTests/8B080316-94C7-42D6-A6C6-886F653CBF57.txt`.
  Xcode omitió variantes parametrizadas; no se presenta como cobertura de los 75 resultados.
- GREEN global: **1.058 declaraciones / 1.516 resultados PASS**, cero fallos, skip, notRun, expectedFailures y runtimeWarnings.
  Incluye los 80 resultados nuevos. Summary `RunAllTests/3EA4D75B-8DA8-4987-9F90-18DB05546A67.txt` en ActionArtifacts/default.
  Resultado nativo original cerrado inspeccionado, finishTime presente:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_23-37-42-+0200.xcresult`.
- Builds Develop con tests 3,947s y final 22,729s; Production 21,3s PASS. Logs completos inspeccionados:
  `BuildProject-Log-20260929-233822.txt`, `BuildProject-Log-20260929-233855.txt`, `BuildProject-Log-20260929-233929.txt`.
  Sin warnings Swift/Clang ni errores; solo aviso AppIntents metadata previo. GetBuildLog warning sin issues estructurados.
  Scheme/plan Develop e iPhone18Pro restaurados. Después de la global solo cambió una línea de comentario DocC.

### Revisión y límites 10.4

Style audit de los 13 Swift cambiados: un candidato conservado por closure/tipo función de init; revisión manual sin
hallazgos, sin líneas >120. `git diff --check` limpio. Gobernanza: solo seis enlaces históricos 08.3 a capturas ausentes.
POST independiente PASS sin hallazgos P0–P3. UI/previews/accesibilidad nueva N/A: no cambian pantallas, textos ni interacción renderizada.
Deuda 08/PLU-54/57 intacta: Jesus Franco, recuperar tras feedback/estabilización y antes del primer candidato para uso real.
El éxito de mutación significa aceptación local. No prueba Firestore live, CAS entre contextos ni validación accesible integral.

POST por agente nuevo ios-standards-reviewer, operacionalmente read-only: 13 Swift y cuatro documentos revisados,
además de callpaths, autoridades y evidencias. Reviewer/root verifican 647 archivos tracked y untracked no ignorados
idénticos antes/después, sin altas/bajas/cambios. Manifest `/tmp/franalonso-10-4-post1.json`, SHA256
`2de90204134fa7379d9d1b6765323fee8d0a53734a38ca1d6edbd13911a24df6`.
Solo tras verificar la huella se registra este resultado en tres documentos y Linear; código/configuración/tests intactos.

Entrega completa de 10.4 e implementación de 10.5 autorizadas por el propietario. PLU-63/PLU-59 siguen In Progress hasta
confirmar la entrega. Tras entregar 10.4 corresponde 10.5,
lista/formulario adaptativos; selector 10.6 y picker 10.7. FoundationModels/PLU-47 conserva su lugar después de 10.7.

## Entrega anterior —10.3 —2026-09-29

[PR26](https://github.com/JFrancoG/FranAlonso/pull/26) MERGED; commit9e281b4c3394b4111ed680bfa76cc8f24b25221f,
merge3a771c2d4a5b6d4a9a19cf66bf0f328bc5682d31. Árbol completo idéntico al head validado/publicado.
Rama10.3 eliminada localmente y en origin tras ancestry y cero commits únicos. PLU-62 Done por integración GitHub–Linear.
GitHub CLEAN/MERGEABLE antes del merge; sin checks/reviews ni protección/rulesets configurados.
Se reutilizan PRE/POST,1.436 resultados y builds; Xcode nuevo N/A por cierre documental. Límites previos intactos.
El propietario autoriza implementar10.4 a continuación, con propuesta/PRE antes de código; fase10/PLU-59 sigue In Progress.

## Historial de implementación10.3 —2026-09-29

[PLU-62](https://linear.app/plusprojects/issue/PLU-62), hija dePLU-59, In Progress, Jesus Franco.
Rama `codex/phase-10-3-linkable-products` desde main/origin/main84a57e5. Implementación autorizada tras entregar10.2.
[Propuesta10.3](10-3-linkable-products-proposal.md): PRE independiente PASS,630 archivos idénticos; huella en propuesta.
Lectores Domain activos y validación al aceptar alta/edición por actor y ruta contextual, preservando históricos/desactivación.
Política compartida, errores neutrales y prioridad de identidad/conflicto; App comparte ProductRepository. InMemory vuelve
a comprobar identidad/estado tras consultar Product. Sin schema/DTO/sync/UI/live ni nuevas dependencias.
Fixtures10.1/10.2 siembran productos activos sin cola y comprueban su conservación; durabilidad solo siembra en primera vida.

### TDD y validación10.3

Xcode MCP estable, workspace-EYu6rxi7hg, Develop/iPhone18Pro/iOS27.0, Swift6 estricto/target26, configuración intacta.
17 declaraciones nuevas/36 resultados:12 de lectura/composición/in-memory y5 de persistencia con24 variantes.
- RED compilable: build18,154s PASS;36 resultados con23 fallos semánticos esperados y13 PASS. No filtrar inactivos ni validar
  disponibilidad permitía aceptar vínculos obsoletos. Summary `RunSomeTests/83B45B4F-E666-488A-9CBC-DE4EA971F4BC.txt`.
  Hubo antes un error de compilación del fixture por helper privado, corregido; no se contabiliza como RED semántico.
- GREEN focal:18/18 PASS, summary `RunSomeTests/7CF674F9-D369-4A0F-9E40-0C703C428EF5.txt`. Xcode omitió variantes
  parametrizadas en la selección focal; la global siguiente ejecutó todas. No se presenta18 como cobertura de36.
- GREEN global: **1.030 declaraciones/1.436 resultados PASS**,0fallos/skip/notRun/expectedFailures/runtimeWarnings.
  Summary `RunAllTests/DC3B0711-568D-466C-BB17-857D2434B8C1.txt` bajo ActionArtifacts/default.
  Resultado nativo original cerrado inspeccionado,1030PASS y finishTime presente:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_23-03-51-+0200.xcresult`.
- Builds Develop con tests16,429s y final3,965s; Production20,291s PASS. Logs completos inspeccionados:
  `BuildProject-Log-20260929-230302.txt`, `BuildProject-Log-20260929-230427.txt`, `BuildProject-Log-20260929-230455.txt`.
  Sin warnings Swift/Clang ni errores; solo aviso AppIntents metadata previo. GetBuildLog warning sin issues estructurados.
  Scheme/plan Develop e iPhone18Pro restaurados. Sin nueva ejecución por posteriores registros documentales.

### Revisión y límites10.3

Style audit14Swift:4 candidatos históricos válidos por closures/tipos función; sin hallazgos tras revisión manual del diff.
`git diff --check` limpio. Gobernanza: solo seis enlaces históricos08.3 a capturas ausentes; sin errores nuevos.
POST independiente PASS sin hallazgos P0–P3. UI/previews/accesibilidad nueva N/A por ausencia de cambios en pantallas, textos o interacción.
La deuda08/PLU-54/57 conserva responsable Jesus Franco y recuperación tras feedback/estabilización antes de uso real.
El test de rechazo verifica snapshot/cola/estado Product; no afirma evidencia negativa de señales sin seam determinista.
La ausencia de publicación se inspecciona en los callpaths: únicamente se publica tras aceptación exitosa.
La validación es local, sin garantía CAS entre contextos independientes ni reserva del producto para una operación futura.

POST por agente nuevo ios-standards-reviewer, operacionalmente read-only:14Swift/4docs y callpaths revisados.
Reviewer/root verifican635/635 archivos tracked y untracked no ignorados idénticos, sin altas/bajas/cambios.
Manifest `/tmp/franalonso-10-3-post1.json`, SHA256 `0b4c39ca5a7ff9e227bc33e5e3b154eb98ad534eb597a3a439a2ac9316b395c4`.
Inspeccionados RED/GREEN, los36 resultados nuevos, xcresult cerrado y logs. Solo después de verificar la huella se registra
el resultado en tres documentos y Linear; código/configuración/tests siguen idénticos al árbol validado y auditado.

Commit/push/PR/merge/cierre10.3 y10.4 pendientes de autorización; PLU-62/PLU-59 permanecen In Progress.
Siguiente paso tras entregar10.3:10.4, ViewModels de lista/formulario. PLU-47 sigue después de10.7; no se inicia aquí.

## Entrega10.3 autorizada —2026-09-29

El propietario autoriza commit, push, PR, merge, cierre de issue/rama e implementar10.4 después.
Preflight: main/origin/main84a57e5 idénticos; sin PR previa.14Swift/configuración/tests conservan la huella POST1;
solo cambian registros documentales. Se reutilizan PRE/POST,1.436 resultados y builds Develop/Production PASS.
Xcode nuevo N/A por cierre documental; aviso AppIntents, seis enlaces históricos08.3 y deuda accesible intactos.
PLU-62 todavía In Progress hasta confirmar merge.10.4 tendrá propuesta y PRE antes de código.

## Entrega anterior —10.2 —2026-09-29

[PR25](https://github.com/JFrancoG/FranAlonso/pull/25) MERGED; commit `25ef3531e9d9f813b7098ea671da918d42014dd4`,
merge `df0a5d63408edab5d7ddd231819244f05b1820a8`. Árbol completo idéntico al head publicado/validado. Rama10.2 eliminada
localmente y en origin tras ancestry y cero commits únicos. PLU-61 Done por integración GitHub–Linear; padrePLU-59 activo.
GitHub CLEAN/MERGEABLE antes del merge; sin checks/reviews ni protección/rulesets configurados. Reutilizados PRE/POST,
1.400 resultados y retest20/20, builds y límites ya registrados; Xcode nuevo N/A por cierre documental. Deuda accesible intacta.
El propietario autoriza iniciar e implementar10.3 a continuación, con propuesta/PRE antes de código.

## Historial de implementación10.2 —2026-09-29

[PLU-61](https://linear.app/plusprojects/issue/PLU-61), hija dePLU-59, In Progress, Jesus Franco.
Issue, rama e implementación autorizadas. Rama `codex/phase-10-2-service-sync` desde main/origin/main d9731f2 limpios.
[Propuesta10.2](10-2-service-sync-proposal.md): cinco escenarios CRUD/sync y reapertura durable con perfil Service completo.
PRE independiente PASS,626 archivos idénticos. Implementación solo en tests/helpers; no defecto productivo demostrado.
Cinco caracterizaciones PASS inicial; regresión1.013 declaraciones/1.400 resultados PASS y Develop con tests PASS.
POST1 detectó espera indefinida en test de ACK, corregida; retest20/20 PASS. POST2 PASS sin hallazgos restantes.
Sin UI/live ni nueva deuda accesible. Entrega Git y10.3 pendientes de autorización.

## Entrega anterior —10.1 —2026-09-29

[PR24](https://github.com/JFrancoG/FranAlonso/pull/24) MERGED, commit funcional
`5665dbb114ea1c4271193b99c7cc8f960280e709`, merge `fd4ed5aa898bc187ba5cd1df04e21bfb8e546c53`.
El árbol integrado completo es idéntico al head publicado. Código/configuración/tests conservan la huella POST;
se reutilizan1.008 declaraciones/1.395 resultados PASS, Develop/Production y PRE/POST independientes.
Solo cambiaron registros documentales de entrega/changelog después de validar. Xcode N/A para este cierre documental.

Rama `codex/phase-10-1-service-contracts` eliminada localmente y en origin tras verificar ancestry y0commits únicos.
GitHub confirmó CLEAN/MERGEABLE antes del merge; no checks/reviews remotos ni reglas de protección configuradas.
PLU-60 quedó Done por la integración GitHub–Linear tras el merge; fase10/PLU-59 y el proyecto siguen In Progress.
Changelog, Progress, issue y padre/proyecto se reconcilian con esta entrega. Solo quedan los límites previos registrados:
aviso AppIntents, seis enlaces históricos08.3 y deuda accesible de otras subfases;10.1 no cambia UI.

Siguiente puerta: preparar10.2, integración completa de CRUD con sync/ack/conflictos/tombstones/offline y reapertura
durable. No se inicia aquí ni se activa live.10.3–10.7 y adelanto FoundationModels/PLU-47 mantienen su orden aprobado.
Los apartados siguientes conservan el historial de preparación, implementación y revisión anterior a esta entrega.

## Inicio y preparación10.1 —2026-09-29

Inicio autorizado por el propietario: «Abre issue y rama y empieza10.1».
[PLU-59](https://linear.app/plusprojects/issue/PLU-59), fase10, y
[PLU-60](https://linear.app/plusprojects/issue/PLU-60),10.1, In Progress, Jesus Franco.
Rama `codex/phase-10-1-service-contracts` desde main/origin/main50ecc39 limpios e idénticos.
[Propuesta10.1](10-1-service-contracts-proposal.md) para contratos/entrada comercial/CRUD/búsqueda y aceptación local mínima.
PRE independiente PASS, sin hallazgos P0–P3. Aprobación concreta posterior: «si, adelante».

Inspección real: Service y valores monetarios de04, vertical Service05.10b y precedenteProduct09.1.
Se propone ServiceProfile sin identidad/estado: nombre no vacío y precio no negativo, cero válido; conservar datos históricos.
Precio con impuesto incluido, tipos/vínculos estructurales y decimales vigentes. CRUD comercial con desactivación,
estado actual preservado, búsqueda por nombre y errores neutrales. Validación de Product disponible permanece en10.3.
No se amplían schema/DTO/sync, UI, demo ni Foundation Models. Perfil maintenance y configuración actual conservados.

Baseline09.7 reutilizada:979 declaraciones/1.346 resultados PASS, Develop22,583s/Production20,338s, PRE/POST PASS.
PR23/b40e1f6, head51afed1, cierre50ecc39; código/configuración/tests idénticos a POST2.
Xcode MCP estable y GetTargetBuildSettings verificados: workspace-EYu6rxi7hg, Develop, SDK27.0/target26,
Swift6/strict complete/default nonisolated, warnings como errores. Sin cambio de esquema/destino ni nueva ejecución.
Nuevos builds/tests/previews N/A por preparación documental; aviso AppIntents y seis enlaces históricos08.3 conservados.
Consulta primaria Cupertino: localizedStandardContains. PRE revisó propuesta, alternativas, fuentes y límites.

Fase09/PLU-49 sigue In Progress por PLU-54/57; deuda08 intacta. Tras10.1–10.7 sigue PLU-47/adelanto textual16,
después11–13 para venta completa y08.9 tras feedback según ADR0030. Ningún servicio live ni entregaGit10 autorizado.

## Resultado PRE y puerta siguiente

Auditoría independiente ios-standards-reviewer: PASS limitado a la propuesta, sin hallazgos P0–P3.
Reviewer y root verifican615/615 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas.
Manifiesto `/tmp/franalonso-10-1-pre1.json`, SHA256 `481bd333f62daf02278909af206bebd300404eff7c313600d47597501536d83f`.
El reviewer contrasta documentación Apple de StringProtocol.localizedStandardContains y Foundation, callpaths Data,
dominio monetario y logs/summary de baseline09.7. No ejecuta Xcode ni escribe archivos. Después de verificar la huella,
solo se añade este registro documental y se reconcilia Linear. Gobernanza conserva únicamente seis enlaces históricos08.3.

La propuesta fue aprobada antes de código, incluidos precio normalizado>=0, cero válido, desactivación y
la adaptación local mínima. Registro de implementación y validación a continuación. UI/accesibilidad nueva N/A;
no equivale a cerrar la deuda existente. Commit/push, PR/merge/cierre y10.2 conservan autorizaciones separadas.


## Implementación10.1 —2026-09-29

Alcance aprobado implementado en19 archivos Swift nuevos/modificados: ServiceProfile, seis UseCases, contrato Repository,
regla tipo/vínculo compartida, repositorio in-memory y aceptación local en datasource/actor/repositorio/contextualadapter.
Dos dobles existentes adaptados únicamente a la conformidad ampliada. No cambia la composición de App ni la infraestructura
DTO/modelos/sync. Spec10 documenta los contratos aprobados. Nombre recortado/no vacío, precio normalizado>=0/cero válido,
exactitud decimal, tipos y vínculo estructural; los snapshots históricos siguen legibles.

Alta no reutiliza identidad conocida; edición reemplaza campos comerciales preservando ID/estado vigente. Desactivar
conserva vínculo/importes y no vuelve a encolar ni publicar si ya inactive sin conflicto, incluso tras ack. Tombstones y
conflictos bloquean mutaciones. Actor y ruta contextual usan la misma operación sin suspensión; errores neutrales,
rollback atómico, contexto sucio intacto y cancelación previa/tardía preservan la frontera de aceptación.
Búsqueda local insensible a caja/diacríticos conserva orden, tipos y estados.10.3 conserva disponibilidad del Product.

### TDD y evidencia Xcode MCP

Xcode estable, workspace-EYu6rxi7hg, iPhone18Pro/iOS27.0, scheme y plan FranAlonso-Develop.29 declaraciones nuevas,
49 resultados añadidos a la suite global. Tests de comportamiento comercial, Codable adversarial, legacy, transiciones,
exactitud de importes, homónimos, búsqueda, estado, causalidad, conflictos, tombstones, rollback y cancelación.

- RED compilable: buildForTesting PASS25,976s. Selección29 declaraciones:49 resultados,45 fallos semánticos y4PASS
  de caminos que ya coincidían; nombres/precios/vínculos no validados, búsqueda sin filtrar y CRUD aún sin aceptar.
  No fallos de configuración de fixtures ni compilación. Summary `RunSomeTests/8F6EEED0-376E-4217-8BB1-980D41A3D59E.txt`.
- GREEN focal:29 declaraciones/38 resultados seleccionados PASS. Summary
  `RunSomeTests/026A952F-61AC-4A10-9F95-1CA35D8A5C8E.txt`; resultado nativo cerrado inspeccionado, sin runtimewarnings.
  La selección focal de Xcode no ejecutó todas las variantes de argumentos; la suite global siguiente sí las incluye.
- GREEN global: **1.008 declaraciones/1.395 resultados PASS**,0fallos/skip/notRun/expectedFailures,0runtimewarnings.
  Summary `RunAllTests/8E5601DC-4DA8-465D-9BE4-53468B07D408.txt` bajo ActionArtifacts/default.
  La copia MCP del xcresult carecía de Info.plist; se inspeccionó el original cerrado, sin repetir tests:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_21-04-27-+0200.xcresult`.
  Summary nativo1008PASS y finishTime presente. No se confunde inventario, declaraciones y resultados parametrizados.
- Builds finales Develop11,043s y Production19,421s PASS. Logs completos inspeccionados:
  `BuildProject-Log-20260929-210513.txt` y `BuildProject-Log-20260929-210547.txt` bajo ActionArtifacts/default/BuildProject.
  Sin warnings Swift/Clang ni errores; únicamente aviso previo AppIntents metadata por ausencia de dependencia.
  GetBuildLog warning sin issues estructurados. Scheme/plan Develop e iPhone18Pro restaurados.

### Revisión y límites

Auditoría de estilo en19 archivos Swift: recall con3 candidatos (dos firmas con closures y predicado histórico intacto),
correctamente verticales por complejidad; literals JSON largos deliberados. Corregida una llamada nueva de124columnas.
`git diff --check` limpio. Gobernanza mantiene solo seis enlaces históricos08.3 a capturas ausentes; sin fallos nuevos.
POST independiente PASS, sin hallazgos P0–P3, sobre este árbol validado. UI/previews/accesibilidad nueva N/A porque no hay cambios en
pantallas, recursos, localización ni interacción. PLU-54/57 y deuda08 conservan dueño/disparador/evidencia existentes.

PLU-60 y PLU-59 permanecen In Progress. Implementación validada y auditada pendiente de entrega Git explícita;
no commit/push/PR/merge/cierre, siguiente subfase ni live.10.2 integrará CRUD con sync/ack/conflictos/tombstone/offline
completos y reapertura durable;10.3 productos vinculables,10.4–10.7 UI y selección. PLU-47/FoundationModels después.


### Resultado POST y entrega pendiente

Auditoría independiente nueva ios-standards-reviewer: **POST PASS, sin hallazgos P0–P3**. Inspeccionados19Swift y4docs,
callpaths afectados, fuentes Apple de búsqueda localizada/rollback/hasChanges y logs/summary/xcresult anteriores.
Modo operacional read-only: prohibición explícita de escribir/publicar, sin builds ni tests del auditor. Reviewer y root
verifican625/625 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas/cambios.
Manifiesto `/tmp/franalonso-10-1-post1.json`, SHA256 `67b7d7d153d3c2c45a7a3fbd026a34cc5d1ecbea3f497391970512c321bb9b26`.
Tras cerrar la huella, solo se añade el resultado documental a propuesta/Progress/fase10 y se reconcilia Linear.
Código/configuración/tests conservan exactamente el árbol validado; no se repite Xcode por este registro.

10.1 queda lista para commit/push y posterior PR/merge/cierre cuando se autoricen. PLU-60 y fase10/PLU-59 siguen
In Progress. Próxima subfase tras entregar10.1: preparar10.2 con integración CRUD/sync y durabilidad; no iniciada aquí.


## Entrega10.1 autorizada —2026-09-29

Petición posterior del propietario: «Commit y push, lanza PR, merge y cierra su rama».
Preflight de root y revisor independiente:19Swift/configuración/tests idénticos al POST; solo tres documentos registran
el resultado de la auditoría. Main/origin/main y base local coinciden en50ecc39. Sin PR previa para la rama.
Se reutilizan1.008 declaraciones/1.395 resultados, ambos builds y PRE/POST. Nuevas ejecuciones Xcode N/A por registros
documentales de entrega; aviso AppIntents y seis enlaces históricos08.3 permanecen documentados. Entrega en curso.


## Implementación y validación10.2 —2026-09-29

Solicitud: «Adelante abre issue y rama e implementa10.2». PLU-61 y rama creadas desde d9731f2 limpio y sincronizado.
PRE independiente PASS sin P0–P3,626 archivos idénticos (huella completa en propuesta); implementación posterior.
Tres archivos Swift nuevos y dos modificados, todos de tests. ServiceSyncRemoteFake, gate de ACK y reloj manual extraídos
para reutilización; semántica previa conservada, con registro de operaciones aplicadas e inyección de cambios remotos.
Sin diferencias en código de producción, configuración, modelos/DTO, schema, App ni recursos.

- CRUD completo converge a un único documento inactivo; tres operaciones causales se aplican una vez. Repetir sync o
  desactivar después del ACK no genera tombstone, revisión nueva ni otra operación.
- ACK del alta suspendido mientras el adapter contextual edita/desactiva: preserva perfil más reciente y ambos sucesores;
  siguiente pasada converge. Observación local y repositorio comparten actor/señal reales.
- Conflicto recibido por pull conserva snapshot, ambos lados y cadena; bloquea mutaciones de esa identidad mientras otra
  sigue operable. Tombstone elimina de observación/lookup, conserva conflicto e impide resurrección por CRUD/sync repetido.
- Offline falla push tres veces; retry1/2s y deadline posterior persisten. Reapertura de archivo único con esquema3.0/plan
  vigente conserva bytes payload/base, IDs/predecesores, snapshot, cursor y retry. Weak references prueban liberación de
  container/actor/engine. Recuperación espera4s en reloj manual, converge sin duplicados y una segunda reapertura confirma
  estado remoto/local final y ausencia de colas/retries/conflictos. No se mata la app ni se usa su store.
- Oráculos completos con cadenas decimales independientes del mapper/política; precio/moneda, impuesto/descuento, tipo y
  vínculo. Profesional→producto y producto→profesional; vínculo retenido al desactivar, nil/cero/fracción distinguidos.

### Evidencia Xcode MCP

Workspace-EYu6rxi7hg, Develop/plan Develop, iPhone18Pro/iOS27.0. No cambio de scheme ni destino.

- Build con tests PASS28,376s. Log `BuildProject/BuildProject-Log-20260929-222917.txt` bajo ActionArtifacts/default;
  sin errores/warnings Swift/Clang. Únicamente aviso AppIntents metadata ya conocido.
- Focal nueva **5/5 PASS inicial**. No se fabrica RED: el recorrido productivo ya estaba implementado.
  Summary `RunSomeTests/2081AFE5-D2B6-49C9-BAB3-3D06FE2765DE.txt`. Original nativo cerrado en DerivedData:
  `Logs/Test/Test-FranAlonso-Develop-2026.09.29_22-29-50-+0200.xcresult`; finishTime presente, sin runtimewarnings.
- Ajustes finales solo de layout/nombre de un test; regresión completa **1.013 declaraciones/1.400 resultados PASS**,
  cero fallos/skip/notRun/expectedFailures/runtimewarnings. Se usa global para cubrir la extracción compartida y todas las
  variantes Service/composición/migraciones: la selección parcial ya había omitido argumentos en10.1. No se repite después.
  Summary `RunAllTests/B859A782-CBEF-4D76-8528-9C2F1B8ABBCC.txt`. Original nativo cerrado inspeccionado:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_22-30-28-+0200.xcresult`.
  Resumen auxiliar `/tmp/franalonso-102-all-summary.json`. GetBuildLog final sin issues estructurados; log completo inspeccionado.
- Production reutiliza10.1 PASS19,421s: árbol de producción/configuración idéntico. Nuevo build Production N/A por cambio
  exclusivo de tests; no se afirma ejecución nueva. Previews/accesibilidad nueva N/A, sin UI ni recursos modificados.

Estilo: cinco Swift inspeccionados, tres candidatos del recall con closures justifican vertical; dos son históricos
intactos. Sin líneas nuevas>120 tras ajuste. Diff-check limpio. Gobernanza conserva únicamente seis enlaces históricos08.3.
POST independiente en curso, sin modificar archivos durante su huella. PLU-61 y padrePLU-59 siguen In Progress.
Pendientes commit/push y entrega posterior autorizada;10.3 productos vinculables será siguiente. Deuda08/PLU-54/57 intacta.


### POST1 y corrección del test de ACK

POST1 independiente detecta un P2: si synchronize termina antes de apply, el test podía esperar indefinidamente el gate.
Sin otros hallazgos. Auditor/root verifican629 archivos idénticos; manifiesto `/tmp/franalonso-10-2-post1.json`, SHA256
`078c075c170700092092ea8c552bb0efcbdd7b44801bd1ba825f7adbff3fba8c`. Se cierra la huella antes de corregir.

Corrección limitada a dos archivos de tests: gate distingue ACK alcanzado de sincronización terminada y conserva ese
estado si llega antes del waiter. Wrapper async let estructurado notifica finalización tanto al éxito como al error.
El test exige haber llegado al ACK y su cleanup libera gate y espera al hijo. API histórica waitUntilBlocked conservada.
No cambia ninguna ruta productiva.

Dos inyecciones negativas temporales verifican que el escenario falla y termina, sin colgarse: drenar la cola antes del
pase para provocar éxito temprano, y lanzar unexpected desde fetch para error temprano. Ambas terminan en la aserción
reachedAcknowledgement con1fallo intencional/1test, resultado nativo cerrado y sin runtimewarnings. No son RED productivo
ni fallos pendientes; sirven para verificar el hallazgo del harness. Summaries bajo RunSomeTests:
`4A169452-7225-4743-8045-8068B847E6A8.txt` y `00E5828F-1B6B-4DDC-9E61-5650093BA6CC.txt`.
Inyecciones retiradas y fuentes finales restauradas byte a byte antes de la regresión.

Retest final por impacto: **20/20 PASS**, sin parámetros omitidos, fallos/skip/notRun/runtimewarnings. Incluye cinco
escenarios nuevos más todas las pruebas ServiceSyncEngineTests y ServiceSyncRetryEngineTests que comparten helpers.
Summary `RunSomeTests/A82654F3-15BC-4E7B-A6DC-B51BF8F6E2D8.txt`; original cerrado
`Logs/Test/Test-FranAlonso-Develop-2026.09.29_22-37-56-+0200.xcresult` bajo DerivedData anterior.
GetBuildLog final PASS sin issues estructurados; únicamente AppIntents conocido en log completo. El global1.400 anterior
sigue como baseline y este retest acredita la corrección final; no se presenta el global como posterior a ella.
Estilo/diff-check limpios. POST2 independiente pendiente sobre el alcance corregido; sin nueva ejecución global ni Production.


### POST2 y estado final10.2

**POST2 PASS, sin hallazgos restantes; P2 del harness corregido.** Auditor independiente verifica cierre temprano de ACK,
ambas inyecciones negativas, retest20/20, estilo y log final. Los restantes ámbitos de POST1 conservan vigencia.
Modo operacional read-only:629/629 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas/cambios.
Manifest `/tmp/franalonso-10-2-post2.json`, SHA256 `dded9b8352ce3afe685b315205b002274232c1e42cf0c6c2d1fb92e14e46c1fe`.
Tras cerrar huella solo se registra el resultado en documentación y Linear; fuentes/configuración/tests permanecen intactos.

10.2 implementada, validada y auditada, lista para commit/push y posterior entrega cuando se autoricen.
PLU-61 y fase10/PLU-59 In Progress; rama local `codex/phase-10-2-service-sync`. No commit/push/PR/merge/cierre ni live.
Siguiente subfase10.3: productos vinculables activos y manejo de ausencia/eliminación. No iniciada en este alcance.


### Entrega10.2 autorizada —2026-09-29

El propietario autoriza commit/push, PR/merge, cierre de issue/rama si proceden y después implementar10.3.
Preflight: base main/origin/main d9731f2 idéntica, sin PR previa; cinco Swift coinciden con POST2, solo registros documentales
posteriores. Se reutilizan validaciones y revisión finales; nuevas ejecuciones Xcode N/A por metadata de entrega.
Changelog actualizado. No se modifica código durante el cierre. Entrega en curso;10.3 conserva PRE antes de implementación.

## Entrega 10.4 autorizada — 2026-09-29

Commit, push, PR, merge y cierres incluidos en la entrega solicitada, seguidos de implementación 10.5.
Preflight sin cambios ajenos: los 13 Swift conservan la huella POST; solo registros documentales posteriores.
Se reutilizan 1.516 resultados, builds Develop/Production y PRE/POST PASS. Xcode nuevo N/A por cierre documental.
Aviso AppIntents, seis enlaces históricos08.3 y deuda accesible intactos. Propuesta/PRE propias antes de código10.5.

## Entrega 10.5 autorizada — 2026-09-30

Se conserva la huella ejecutable y recursos POST2; únicamente registros documentales posteriores.
Se reutilizan1.520resultados, builds, previews, smoke y revisiones favorables. Xcode nuevo N/A para preparación documental.
PLU-65 Backlog conserva dueño/trigger y evidencia integral pendiente. La entrega incluye cierre funcional dePLU-64 y
rama, sin cerrar fase10 ni deuda accesible. La siguiente implementación autorizada es10.6, con PRE propia antes de código.
