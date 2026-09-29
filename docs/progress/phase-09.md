# Fase 09 — Productos e inventario físico

## Entrega y cierre 09.7 —2026-09-29

Commit `51afed1266f1f75a8b14a2edb4966bf0fc9a3757`, `✨ feat(stock): observe local low-stock state`, publicado.
[PR23](https://github.com/JFrancoG/FranAlonso/pull/23) MERGED mediante `b40e1f6b603f8ceeb6120f26c73d04fb8589d091`.
Árbol integrado idéntico al head validado; CLEAN/MERGEABLE, sin checks ni reviews remotos ni protección/rules en main.
Ramas local/remota eliminadas tras comprobar cero commits únicos. PLU-58 Done por entrega y cierre autorizados.
Se reutilizan1.346 resultados, Develop/Production y PRE/POST PASS: código/configuración/tests intactos respecto a POST2.
Solo cambian los registros documentales; nueva ejecución Xcode N/A. Aviso AppIntents y seis enlaces históricos08.3 conservados.

09.1–09.7 entregadas. Fase09/PLU-49 y proyecto siguen In Progress: PLU-54/57 mantienen validación integral de09.4/09.6,
Jesus Franco, tras feedback/estabilización y antes de uso real. UI/accesibilidad nueva09.7 N/A; ningún servicio live activado.
Siguiente puerta canónica: preparar10.1, contratos/casos de uso de Service, propuesta y PRE antes de implementar.
Fase10 no iniciada. Después de10.1–10.7, adelanto textual Foundation Models/PLU-47; siguen11–13 para la venta completa,
y08.9 tras feedback, conforme a ADR0030. El usuario pregunta por el siguiente paso; no autoriza aquí esa implementación.

## Entrega 09.7 autorizada —2026-09-29

El propietario autoriza commit/push, PR/merge y cierre de issue/rama si se conservan los gates de entrega.
Preflight: código, configuración y tests idénticos al manifiesto POST2; solo se añadieron registros documentales.
Se reutilizan1.346 resultados, Develop/Production y PRE/POST PASS. Xcode nuevo N/A para esta reconciliación documental.
Fase09/PLU-49 conserva deuda integral PLU-54/57; no se autoriza iniciar fase10 ni activar live.
El resultado Git se registrará después de verificarlo. El checkpoint siguiente conserva la evidencia previa.

## Implementación local 09.7 —2026-09-29

[PLU-58](https://linear.app/plusprojects/issue/PLU-58), Jesus Franco, In Progress, hija dePLU-49.
Rama `codex/phase-09-7-low-stock-observation`, base e16163b. El propietario aprueba expresamente implementar la
[propuesta PRE PASS](09-7-low-stock-observation-proposal.md). Implementación completa local; PRE/POST independientes PASS.
Entrega Git y cierre de issue/rama no autorizados. Fase09 sigue abierta; no se inicia fase10 ni activa ningún servicio live.

### Resultado y límites

- StockMinimum valida también Codable; LowStockState deriva bajo stock por comparación estricta, incluidos extremos.
  ObserveLowStockUseCase emite estado inicial/cambios distintos y recuperación, con mínimo explícito fijo por observación.
- DefaultStockRepository suscribe antes de leer el saldo, suprime cantidades iguales y propaga errores neutrales.
  ProductObservationSignal compartida con Product y el adaptador contextual; publica tras aceptación durable incluso
  ante cancelación tardía. AppRuntime/live/preview/demo comparten la señal y conservan el borrador padre.
- Cancelación del consumidor termina la tarea puente y upstream. Buffers newest1 pueden agrupar cambios: estado actual,
  no historial. Writes de procesos/contextos ajenos no están cubiertos. Sin polling ni reintento automático.
- No cambia Product, schema, migración, ViewModel, Views, textos ni recursos; no hay mínimo persistido, avisos visibles,
  notificaciones ni sync de movimientos. UI/previews/auditoría accesible nueva N/A por ausencia de cambios visuales.
  PLU-54/57, Jesus Franco, conservan evidencia integral tras feedback/estabilización y antes del primer uso real.

### TDD y validación

RED compilable:16 declaraciones/25 resultados,19 fallos semánticos y6 comparaciones ya correctas; cubre Domain/Data.
Build RED15,779s PASS. GREEN añade cobertura de corrupción, conflictos y composición; no se atribuye RED retrospectivo
a esas caracterizaciones. Correcciones de compilación limitaron capturas de iteradores en macros y construcción de fixtures.
Focused GREEN inicial20/22: dos oráculos releían next() después del error capturado y Swift volvió a lanzar el mismo error.
Se conserva el error neutral y ausencia de estado inventado, retirando solo esa relectura del iterador ya fallido;
producción intacta. Retest2/2 PASS. La aplicación exige nueva observación tras error, no reutiliza ese iterador.

GREEN global: **979 declaraciones/1.346 resultados PASS**, cero fallos/skip/expected failures/runtime warnings,
bundle nativo cerrado inspeccionado con xcresulttool. Nuevos casos:17 Domain,10 Data y4 composición.
Incluyen umbral/igualdad/extremos, invariante de decodificación, supresión de duplicados, error/cancelación upstream,
lector caliente con tombstone en otro contexto conocido, retry/rollback/cancelación tras commit, dos productos aislados,
señal retrasada y borrador padre conservado. Los casos parametrizados se verifican en suite global; selección focalizada
de Xcode MCP no enumera todos. No XCTest/XCUITest/UI tests nativos, sleeps, unsafe ni dependencias nuevas.

Xcode MCP estable, SDK27.0, target26, Swift6/strict complete/default nonisolated; warnings como errores sin cambios.
Develop build-for-testing previo a POST3,896s PASS; Production20,338s PASS. Diagnósticos estructurados0; logs conservan
únicamente el aviso conocido `Metadata extraction skipped, no AppIntents.framework dependency found`.
No se declara cero warnings absolutos. Develop/iPhone18Pro restaurados; ninguna sesión de interacción nueva.

Artefactos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- RED summary `RunSomeTests/FE835807-1851-433B-8143-913037844981.txt`, bundle
  `RunSomeTests/Test-FranAlonso-Develop-2026.09.29_19-57-45-+0200.xcresult`.
- GREEN summary `RunAllTests/F7BF97B6-31F2-4CA7-BC71-4ECC5E297808.txt`, bundle
  `RunAllTests/Test-FranAlonso-Develop-2026.09.29_20-05-27-+0200.xcresult`.
- Retest summary `RunSomeTests/D2087DD0-94EA-464E-9CDF-C016EDD42502.txt`.
- Builds `BuildProject/BuildProject-Log-20260929-200609.txt` y `BuildProject-Log-20260929-200636.txt`.

El detalle de AsyncThrowingStream se contrastó con [Apple AsyncIteratorProtocol](https://developer.apple.com/documentation/swift/asynciteratorprotocol)
y [Swift AsyncStreamBuffer](https://github.com/swiftlang/swift/blob/main/stdlib/public/Concurrency/AsyncStreamBuffer.swift):
la ruta que reanuda un next suspendido con error puede conservarlo para otra lectura. No se parchea la librería ni se
convierte esa diferencia de planificación en un requisito de negocio. El oráculo termina al comprobar el error terminal.

### POST y siguiente puerta

POST independiente de estándares: PASS, sin hallazgos abiertos de arquitectura, datos, concurrencia, privacidad ni
comportamiento. POST1 encontró solo P3 de estilo en cuatro closures con finish; corregido exclusivamente con saltos
de línea en tres archivos. El reviewer comprobó su equivalencia exacta reconstruyendo hashes previos. Retest de estilo
PASS y build-for-testing Develop22,583s PASS (`BuildProject/BuildProject-Log-20260929-201332.txt`), solo aviso AppIntents.
No se repiten suite/Production porque no cambia ningún token ejecutable; se conserva la evidencia1.346/1.346.

Reviewer y root verifican613/613 archivos idénticos antes/después de ambas revisiones, sin altas/bajas/cambios:
POST1 `/tmp/franalonso-09-7-post1.json`, SHA256 `bedf58db837800afb025bfd9ea708393bda100ba709efc2e87a998079f7c88d5`;
POST2 `/tmp/franalonso-09-7-post2.json`, SHA256 `8e24476f5c264d07a48a7d52112be2a7620bf91a06f8086bd6cc40f52dae7cb6`.
Revisión manual de16 Swift, recall0 candidatos y0 líneas>120. Diff--check limpio; sin paths sensibles ni opt-outs nuevos.
Auditoría UI/accesible nueva N/A por alcance sin Views/textos/recursos; PLU-54/57 conservan su evidencia integral.

Tras POST solo se añade este registro documental y se reconcilia Linear. Gobernanza mantiene únicamente los seis
enlaces históricos de capturas08.3 rotos; Progress dentro de8KiB. PLU-58/PLU-49 y proyecto In Progress: listos para
entrega Git09.7 cuando se autorice; la fase09 conserva su cierre integral pendiente. No se inicia fase10 ni se activa live.

## Preparación 09.7 —2026-09-29

[PLU-58](https://linear.app/plusprojects/issue/PLU-58), Jesus Franco, In Progress, hija dePLU-49.
Rama `codex/phase-09-7-low-stock-observation` desde main/origin/main e16163b limpios e idénticos.
Preparación autorizada: [propuesta](09-7-low-stock-observation-proposal.md) de observación por producto/mínimo explícito,
comparación estricta, invalidación local compartida y pruebas de stream/contextos. PRE PASS, sin hallazgos P0–P3.
Reviewer y root verifican607/607 archivos idénticos, manifiesto `/tmp/franalonso-09-7-pre1.json`, SHA256
`e7c0e2da5183d81f4e5232939571e59b600a530d8e4cb3c191a980d489653f6e`. Solo se añade después este registro documental.
Snapshot histórico de preparación, previo a aprobación e implementación registradas arriba; entonces sin código09.7.
Baseline09.6 reutilizado; Xcode MCP y configuración verificados. Nuevos build/tests/UI N/A por alcance documental.
La implementación recibió después su aprobación; entrega09.7, fase09 y deuda accesible siguen abiertas.

## Entrega y cierre funcional 09.6 —2026-09-29

Commit `824fad833c19d8b0b40a853560f6c2f95baeab01`, `✨ feat(stock): add adjustment screens`, publicado.
[PR22](https://github.com/JFrancoG/FranAlonso/pull/22) MERGED mediante `7f83cdf423865f778a7da4d38ddd232afd169a98`.
Árbol integrado idéntico al head validado; CLEAN/MERGEABLE, sin checks ni reviews remotos; main sin protección configurada.
Ramas local/remota eliminadas tras verificar cero commits únicos. PLU-56 Done funcional por autorización expresa.
PLU-57 Backlog conserva accesibilidad integral, Jesus Franco, tras feedback/estabilización y antes de uso real.
Se reutilizan1.315 resultados, Develop/Production,16previews, smoke y PRE/POST PASS: código/configuración intactos.
Aviso AppIntents y seis enlaces históricos08.3 conservados; sin activación live. Nuevo Xcode N/A para cierre documental.
Fase09/PLU-49 sigue abierta. El propietario solicita preparar09.7: propuesta/PRE y gate de implementación separados.

## Entrega 09.6 autorizada —2026-09-29

El propietario autoriza commit/push, PR/merge, cierre funcional de issue/rama y preparación de09.7.
Se reutiliza toda la validación09.6: código/configuración idénticos al manifiesto POST; solo cambió documentación.
PLU-57 mantiene la evidencia accesible integral pendiente; no hay activación live ni código09.7 autorizado.
El resultado Git se registrará después de verificarlo. El checkpoint siguiente conserva la evidencia previa.

## Implementación local 09.6 —2026-09-29

[PLU-56](https://linear.app/plusprojects/issue/PLU-56), Jesus Franco, In Progress, hija dePLU-49.
Rama `codex/phase-09-6-stock-adjustment-ui`, base8908ab6 main/origin/main limpios e idénticos. Inicio e implementación
solicitados explícitamente por el propietario. [Propuesta concreta](09-6-stock-adjustment-ui-proposal.md), PRE PASS,
sin hallazgos P0–P3; reviewer y root verifican591/591 archivos idénticos al manifiesto PRE. Implementación completa.
RED compilable:31 resultados,17 fallos semánticos y14 rechazos esperados correctos. GREEN global:
**958 declaraciones /1.315 resultados PASS**, cero fallos/skip/expected failures/runtime warnings. Bundle nativo cerrado
`RunAllTests/Test-FranAlonso-Develop-2026.09.29_18-40-32-+0200.xcresult`, summary `EAC3AAF7-2F9F-4E35-90E6-0F509BAB61CD.txt`,
bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`.
26 archivos Swift nuevos/tocados revisados: recall de estilo0 candidatos,0 líneas>120, diff--check limpio.
36 recursos nuevos es/en. [Evidencia de pantalla](../accessibility/evidence/09-6-stock-adjustment.md):16 previews
inspeccionadas en18ProMax27.2; smoke táctil PASS en18Pro27.0 (8→11→−3, borrador padre, cancelación y reset8/2).
Production20,776s PASS; ambos POST PASS funcionales, sin hallazgos P0–P3. Build Develop GREEN10,198s PASS,
aviso AppIntents conocido; correcciones de compilación restringidas a doubles de pruebas, sin opt-outs.

Implementación: cantidad y preparación Domain compartida con09.5; ViewModel y sesión propios, comando congelado,
guardado terminal antes de refrescar, adaptador contextual y composición real/preview/demo. Entrada desde ficha existente
activa/inactiva, conserva borrador padre y rechaza cierres antiguos. Demo seed8/2 y reset por composición.
No hay mínimos, historial, nuevas migraciones, dependencias ni activación live.
Build para RED16,891s PASS. `/tmp/franalonso-09-6-pre.json` SHA256
`1e3d1328d4c7e15386df3be8a0f2f432be8782e1384f2ca6df5346c930632042`.
[PLU-57](https://linear.app/plusprojects/issue/PLU-57): Backlog, Jesus Franco, validación integral nueva de hoja/entrada/retorno
tras feedback y estabilización, antes de uso real. PLU-54 conserva su alcance09.4. EntregaGit09.6 separada.

### POST y siguiente puerta

Auditorías independientes de estándares y UI/accesibilidad: **PASS funcional ADR0029, sin hallazgos P0–P3**.
Ambos reviewers y root verifican606/606 archivos idénticos, sin altas/bajas/cambios, frente a
`/tmp/franalonso-09-6-post2.json`, SHA256 `6b603ff317e487c371b03dfe5eff0952497974193837ec8866af664ffc5ce992`.
El especialista visual inspecciona las16 previews,14 jerarquías y3 capturas de smoke; no ejecuta AT adicionales.
Reloj fijo del test de retry es un límite aislado de cobertura de fecha; UUID variable y comparación del movimiento completo
protegen identidad/payload. No hay ruta observada de regeneración del comando congelado; sin defecto ni retest adicional.

Tras auditorías solo se incorpora este registro documental y la reconciliación de Linear. Código/configuración congelados.
Gobernanza: Progress dentro de8KiB, diff--check limpio; persisten únicamente los seis enlaces históricos rotos de08.3.
PLU-56 y fase09/PLU-49 permanecen In Progress: implementación local lista, entrega Git09.6 pendiente de autorización.
PLU-57 conserva validación integral propia y PLU-54/deuda08 permanecen abiertas. La fase no se cierra;09.7 no se inicia.
Sesión de interacción cerrada, app detenida y Develop/iPhone18Pro restaurados. No se ha activado ningún servicio live.

## Entrega y cierre 09.5 —2026-09-29

Commit `3b308c3a8a84c10e5686815814116117f41330a0`, `✨ feat(stock): add durable idempotent adjustments`, publicado.
[PR21](https://github.com/JFrancoG/FranAlonso/pull/21) MERGED mediante `70775d9003152d14437cd749aeb709f8b92c1862`.
Árbol integrado idéntico al head validado; CLEAN/MERGEABLE, sin checks ni reviews remotos obligatorios.
Ramas local/remota eliminadas tras comprobar cero commits únicos. PLU-55 Done; fase09/PLU-49 permanece abierta.
Se reutilizan1.268/1.268 resultados, Develop/Production y PRE/POST PASS: código/configuración intactos.
Aviso AppIntents y seis enlaces históricos08.3 conservados. UI/accesibilidad nuevas N/A; PLU-54 y deuda08 intactas.
El propietario autoriza implementar09.6 después del cierre; se prepara su propuesta/PRE antes del código.
Este cierre documental no requiere nuevas ejecuciones Xcode. No se activa ningún servicio live.

## Implementación local 09.5 —2026-09-29

[PLU-55](https://linear.app/plusprojects/issue/PLU-55), Jesus Franco, In Progress; rama `codex/phase-09-5-stock-adjustments`
desde b4d2da2. Propuesta concreta aprobada tras PRE2 PASS. Implementación y validación completas; PRE/POST PASS, sin hallazgos abiertos.
El propietario autoriza ahora commit/push, PR/merge, cierre de issue/rama e implementación09.6. No hay live ni cambios UI09.5.

### Resultado

- StockMovement inmutable/Codable, ID/fecha/origen estables, motivo normalizado no vacío y delta no cero.
- Cantidad derivada exacta con Int128; cero y negativo permitidos. Activos/inactivos ajustables; nuevo movimiento
  bloqueado ante ausente/tombstone/conflicto. Retry exacto precede elegibilidad y no ejecuta save; colisión no reemplaza.
- Modelo versionado pendiente de sync, una primitiva síncrona con contexto limpio y rollback propio, actor y repositorio.
  AppRuntime comparte un writer local. No se modifica Product/DTO/cola ni se compone transporte de stock.
- v3 añade solo StockMovementModel a los30 modelos de v2, conserva v1/v2 y plan1→2→3. AppModelSchema se cambió únicamente
  después de probar ambas migraciones raw, segunda reapertura, preservación de bytes/metadata/documentos y deduplicación.
- Inspector ADR0021 incluye StockMovement con fetchLimit1. Una fila huérfana deniega claim sin llamadas addBinding;
  la prueba usa un doble determinista, sin Keychain live.

### Validación

Xcode MCP estable, `workspace-EYu6rxi7hg`, Develop/iPhone18Pro Simulator27.0; target26 y Swift6 strict sin cambios.

| Paso | Evidencia |
|---|---|
| RED compilado |25 declaraciones/59 resultados:50 fallos semánticos esperados y9 casos ya verdes, que no se atribuyen a RED. |
| GREEN focal inicial |30/30 PASS; selección de Xcode omitió variantes parametrizadas, por lo que no prueba59/59. |
| Matriz antes de activarv3 |9/9 PASS: rawv1, rawv2, desconocido conservado, dos reaperturas completas,4 corrupciones y overflow previo. |
| Regresión global |**932 declaraciones/1.268 resultados PASS**,69 nuevos frente a1.199;0 fallos/skips/expected failures/runtime warnings. |
| Develop |PASS10,392s. |
| Production |PASS18,373s. Develop/iPhone18Pro restaurados. |

La suite global cubre todas las variantes: cinco colisiones, seis estados Product, cinco cambios posteriores, cuatro
cambios ya confirmados por otro contexto sobre un writer calentado, extremos/permutaciones y cuatro corrupciones.
Incluye cancelación previa/tardía, rollback y recuperación, contexto ajeno sucio, retry sin save y ambas migraciones.
Durabilidad, corrupción, cambio secuencial entre contextos y retry sin save se añadieron como caracterización posterior
al RED inicial; no se inventa un ciclo RED adicional. No se acredita CAS entre writers/procesos independientes.
Las dos rutas históricas de migración tienen entradas de test propias sobre el mismo helper para comprobar ambas antes
de activarv3, dada la omisión de variantes en RunSomeTests. La suite completa confirma después la matriz y la regresión.

Artefactos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- RED: `RunSomeTests/82E7227B-50C0-49E7-9742-69F6765ACE3E.txt`, consola17-45-11.
- GREEN inicial: `RunSomeTests/EF27D582-1367-4D2D-995C-323C303270C6.txt`, consola17-47-48.
- Matriz: `RunSomeTests/A3CAED69-875C-4858-AC22-51AC51E7036C.txt`, consola17-50-05.
- Global: `RunAllTests/4DF4704E-356A-4232-B85A-3213B0C815B5.txt`, consola17-50-42.
- Bundle cerrado global: `RunAllTests/Test-FranAlonso-Develop-2026.09.29_17-50-42-+0200.xcresult`, inspeccionado con xcresulttool.
- Builds: `BuildProject/BuildProject-Log-20260929-175132.txt` y `BuildProject-Log-20260929-175204.txt`.

Ambos logs completos conservan únicamente el aviso conocido de AppIntents sobre extracción omitida por no depender del
framework; el filtro GetBuildLog devuelve0. No se afirma cero warnings globales ni exportación DocC validada.
Estilo:23Swift inspeccionados, script de candidatos y revisión manual; cuatro candidatos justificados por closures o
restricciones genéricas. Diff-check limpio. Gobernanza conserva solo los seis enlaces históricos de capturas08.3.
Previews/UI/accesibilidad nuevas N/A: sin pantallas, recursos ni localización modificados; PLU-54 y deuda08 permanecen.

### Auditoría y estado final

Revisión POST independiente `ios-standards-reviewer`, perfil maintenance: **PASS, sin hallazgos** sobre23Swift y5documentos.
Auditoría operacional read-only: root comprobó **590/590 archivos idénticos** después del revisor, incluidos tracked y
untracked no ignorados. Manifiesto `/tmp/franalonso-09-5-post1.json`, SHA256
`c479fe743adce1b9f2be3acc88ca0297adcc567b1339b9e1be2a05090f059eea`. Este registro se añade tras verificar la huella;
no se modifica código/configuración después de los tests, builds y POST. Revisor contrastó fuentes Apple mediante
Cupertino y leyó resultados nativos/logs; no ejecutó ni modificó nada.

PLU-55, PLU-49 y proyecto reconciliados; siguen In Progress.09.5 está lista para entrega, con commit/push y demás puertas
Git pendientes. UI09.6 es el siguiente alcance tras entregar09.5; no se ha comenzado. PLU-54 y deuda08 permanecen abiertas.

## Inicio 09.5, 2026-09-29 —registro histórico

[PLU-55](https://linear.app/plusprojects/issue/PLU-55), Jesus Franco, hija de PLU-49, In Progress.
Rama local `codex/phase-09-5-stock-adjustments` desde main/origin/main b4d2da2 idénticos y limpios.
Inicio autorizado; [propuesta concreta](09-5-stock-adjustments-proposal.md) de AdjustStockUseCase y persistencia append-only.
PRE PASS y propuesta aprobada explícitamente el29/09. Implementación TDD local en curso: ledger y migración rawv1/v2→v3.
Único P2 resuelto: incluir la tabla en el inspector de almacén vacío y probar rechazo de claim con cero addBinding
según ADR0021. Root verificó 574/574 archivos idénticos en ambos pases; PRE2 SHA-256
`da353ae0ac18647157daefa5f415c32be5305fee20d88337f7b1edf3493f6aab`. Solo cambia después el registro documental.
Código intacto; se reutiliza baseline09.4 (1.199 resultados y ambos builds). Xcode nuevo, UI y accesibilidad N/A por docs.
Fase09 abierta, PLU-54 y deuda08 conservadas; sin live, commit/push09.5 ni comienzo09.6.

## Entrega y cierre funcional 09.4, 2026-09-29

Commit `092d72eb32e639513697af1d5254cbcad8f26823`, `✨ feat(products): add catalogue and product forms`, publicado.
[PR20](https://github.com/JFrancoG/FranAlonso/pull/20) MERGED mediante `dfd73b0c8364400f59cc77df5164b867ef51c48e`.
Árbol integrado idéntico al head validado; CLEAN/MERGEABLE, sin checks ni reviews remotos obligatorios.
Ramas local/remota eliminadas tras comprobar cero commits únicos respecto a main. PLU-53 Done funcional;
PLU-54 Backlog conserva accesibilidad integral, Jesus Franco, tras feedback/estabilización antes de uso real.
Se reutilizan 1.199/1.199 resultados, ambos builds, previews, smoke y PRE/POST: código/recursos intactos desde POST.
El transporte HTTPS/HTTP1.1 completó la entrega tras fallos de SSH, credencial almacenada y errores internos transitorios.
Aviso AppIntents y seis enlaces históricos 08.3 conservados. Esta reconciliación documental no requiere nuevo Xcode.
Fase09/PLU-49 abierta; autorizado comenzar 09.5 con propuesta/PRE antes de código. Historial inferior superado.

## Entrega 09.4 autorizada, 2026-09-29

El propietario autoriza commit/push, PR/merge, cierre funcional de issue/rama y comienzo de la siguiente subfase 09.5.
Se reutilizan 1.199/1.199 resultados, builds Develop/Production, smoke y PRE/POST: los 15 Swift y el catálogo de textos
coinciden byte a byte con el manifiesto POST. Solo se añade estado de entrega y changelog; Xcode nuevo N/A.
PLU-54 conserva toda la validación integral pendiente. La fase 09 permanece abierta; sin activación live.
El resultado Git se registrará después de comprobarlo. La entrada inferior conserva el checkpoint local previo.

## 09.4 — Implementación local, 2026-09-29

[PLU-53](https://linear.app/plusprojects/issue/PLU-53) In Progress, Jesus Franco, rama
`codex/plu-53-phase-09-4-product-screens` desde acd0514. [Propuesta](09-4-product-screens-proposal.md) PRE PASS:
el cierre por gesto siempre queda desactivado; root verificó 562/562 archivos idénticos en ambos pases.

### Alcance implementado

- Catálogo abre ProductListScreen: carga, lista, vacío, búsqueda sin coincidencias, error y reintento; inactivos visibles.
- ProductFormScreen crea/edita, valida nombre, conserva borrador ante errores, confirma descarte y desactivación;
  editar un inactivo no lo reactiva. Cierre mediante Cancelar o mutación confirmada; gesto de cierre deshabilitado.
- Reutiliza los ViewModels y factories de 09.3; solo añade detección de cambios del borrador y feedback localizado.
  Contexto SwiftData efímero según ADR 0011; Domain, Data, schema, sync y dependencias intactos.
- 41 recursos nuevos es/en, previews deterministas y dos productos sintéticos en la demo Develop. Se amplía el
  [runbook](08-8a-demo-runbook.md); cada relanzamiento con el argumento existente restablece clientes y productos.
- 15 archivos Swift nuevos/modificados. Sin stock, servicios, venta, Foundation Models ni activación live.

### TDD y validación

Xcode MCP estable, Develop/iPhone 18 Pro Simulator 27.0; target 26, Swift 6, strict complete y nonisolated intactos.

| Paso | Evidencia |
|---|---|
| RED | Build con tests 26,451 s PASS; 9/9 fallos semánticos previstos: seis variantes de borrador y tres recorridos de seed. |
| GREEN focal | Build con tests 20,055 s PASS; 7/7 resultados, selección incompleta de dos variantes terminales. |
| Global justificado | **902 declaraciones / 1.199 resultados PASS**, cero fallos, skips y expected failures en bundle nativo cerrado. Las tres terminales saved/deactivated/closed están presentes. |
| Previews | 15 capturas representativas inspeccionadas; Large, XXX Large, AX 5, Light/Dark y contraste incrementado. Lista 0/250, sin coincidencias/error; crear/editar inactivo y errores; shell. |
| Smoke táctil | Alta, validación/corrección, búsqueda sin tilde, no resultados/recuperación, bloqueo de gesto, descarte, desactivación, edición/reapertura de inactivo y reset PASS. Retest de las dos confirmaciones PASS. |
| Builds finales | Develop PASS 3,818 s; Production PASS 20,909 s. Develop/iPhone 18 Pro restaurados, sesión y app de smoke detenidas. |

El fallback global se limita a la selección parametrizada parcial reproducida. Las dos nuevas suites prueban borrador
tras errores/terminales y composición real preview/demo; no añaden UI tests, sleeps, red real ni serialización artificial.
El bundle cerrado confirma los resultados; los 1.191 anteriores siguen verdes. No se equiparan declaraciones y variantes.

Artefactos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- RED: `RunSomeTests/19C41087-0E06-4BBD-BDF5-5A21B79F852C.txt`, consola 16-06-17.
- GREEN focal: `RunSomeTests/FDA88837-AA4B-4A39-9F70-30F4B37DF394.txt`, consola 16-10-05.
- Global: `RunAllTests/7071DAC8-0E48-45E8-AED5-C89AF3FA0C97.txt`, consola 16-10-25.
- Bundle cerrado: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_16-10-25-+0200.xcresult`.
- Builds TDD: `BuildProject/BuildProject-Log-20260929-160554.txt` y `BuildProject-Log-20260929-160957.txt`.
- Builds finales: `BuildProject/BuildProject-Log-20260929-162856.txt` y `BuildProject-Log-20260929-162923.txt`.
- Previews y smoke: inventario en la [matriz de 55 criterios](../accessibility/evidence/09-4-product-screens.md).

Los logs completos conservan el aviso conocido `Metadata extraction skipped, no AppIntents.framework dependency found`.
No se afirma cero warnings globales, exportación DocC ni validación física. Los previews realmente usaron iPhone 18 Pro Max
con iOS 27.2, distinto del destino de build/tests/smoke. El teclado software quedó oculto por la configuración del simulador;
la operación con teclado visible y AT integral permanece pendiente.

### Correcciones visuales y revisión

Se corrigieron título y placeholder recortados en AX 5, y el icono de vacío; las variantes afectadas se renderizaron de nuevo.
El smoke detectó que el popover nativo ocultaba el botón de cancelación: «Seguir editando» ahora es una acción explícita
que cierra cada confirmación y conserva el borrador. La comprobación táctil focal confirma ambas acciones visibles y la conservación del borrador.

POST independientes de estándares y UI/accesibilidad: **PASS funcional, sin hallazgos P0–P3 de código**. Ambas revisiones
fueron operativamente read-only; root verificó **573/573 archivos idénticos** tras cada revisión. Manifiesto
`/tmp/franalonso-09-4-post.json`, SHA-256 `82ae2c4eed46474bb7da0c59d5fa4baa5d1151135221c474c7ddec53118f8bba`.
Después solo se completa este registro y Linear; no cambia código ni configuración. Estilo de 15 Swift revisado y
diff-check limpio; gobernanza mantiene únicamente los seis enlaces históricos de capturas 08.3.

Precisión accesible: 44 pt es la política/intención de construcción. El árbol del smoke devuelve frames de toolbar de
36 pt, lo que no determina su área táctil efectiva. Medición pendiente en PLU-54; criterio 2.5.8 conserva Limitado.

### Estado y límites

[PLU-54](https://linear.app/plusprojects/issue/PLU-54) Backlog conserva la nueva validación integral de 09.4: Jesus Franco,
tras feedback y estabilización, siempre antes del primer candidato para uso real. No absorbe la deuda de fase 08.
La implementación permanece local: 22 archivos nuevos/modificados, sin commit/push/PR/merge ni cierre de PLU-53.
Docs y Linear reconciliados; fase 09/PLU-49 abierta, PLU-53 In Progress y PLU-54 Backlog.
Entrega 09.4 y comienzo de 09.5 requieren autorización posterior. Las entradas inferiores son historial superado.

## Entrega y cierre09.3, 2026-09-29

Commit `58ee95f9cd5611439a5d069ad3aefa0ae8e824a0`, `✨ feat(products): coordinate list and form state`, publicado.
[PR19](https://github.com/JFrancoG/FranAlonso/pull/19) MERGED mediante `13b083972be14ea40cc2babfd929d34ee870c40e`.
Árbol integrado idéntico al head validado; CLEAN/MERGEABLE y sin checks/reviews obligatorios antes del merge.
Rama local/remota eliminadas tras comprobar cero commits únicos respecto a main. PLU-52 Done; fase09/PLU-49 abierta.
Reutilizados1.191/1.191 resultados, builds Develop/Production y PRE/POST;10Swift intactos desde POST.
Aviso AppIntents y seis enlaces históricos08.3 conservados. Sin live, UI/accesibilidad nuevas N/A en09.3.
Siguiente alcance autorizado09.4: lista/formulario y conexión a Catálogo, previa propuesta/PRE. Historial inferior superado.

## Entrega09.3 autorizada, 2026-09-29

El propietario autoriza commit/push, PR/merge y cierre de issue/rama09.3, seguido de implementación09.4.
Se reutilizan1.191/1.191 resultados, builds Develop/Production, estilo y PRE/POST: los10Swift coinciden byte a byte
con el manifiesto POST. Solo cambian documentos de estado/entrega y changelog. UI/accesibilidad N/A en09.3;
la fase09 sigue abierta y09.4 requiere su propuesta/PRE antes del código. El resultado Git se registrará tras verificarlo.

## Implementación09.3 local, 2026-09-29

[PLU-52](https://linear.app/plusprojects/issue/PLU-52) sigue In Progress, Jesus Franco; rama local
`codex/plu-52-phase-09-3-product-view-models`, base b8efe87. La autorización vigente incluye implementación09.3,
no su publicación/cierre ni09.4. [Propuesta aprobada y PRE PASS](09-3-product-view-models-proposal.md).

### Alcance implementado

- ProductListViewModel @Observable @MainActor: snapshots locales, búsqueda derivada y distinción vacío/sin coincidencias;
  conserva inactivos, representa errores/cancelación y protege cargas reemplazadas mediante generación.
- ProductFormDestination separa sesión y ProductID; alta conserva identidad, edición exige producto visible y un cierre
  antiguo no afecta una sesión nueva. No hay pantalla ni navegación visual nueva.
- ProductFormViewModel @Observable @MainActor: carga/ausencia/error/retry, nombre validado y capturado, escritura contextual,
  desactivación de activos y errores Domain neutrales. Impide solapamientos/repeticiones, conserva un commit confirmado
  ante cancelación tardía y descarta respuestas después de cerrar o sustituir una carga. No retiene ModelContext.
- ProductFormFactory en App comparte actor/señal existentes y crea adaptador contextual dentro de su closure MainActor.
  Composición live/local/preview interactiva; snapshots finitos leen su repositorio y rechazan toda mutación.
- Diez Swift nuevos/modificados: cinco de producción/presentación-composición y cinco de tests/callsites.
  Domain, Data, schema, sync, recursos/localización, shell y demo seed intactos. Sin Store ni dependencia nueva.

### TDD y validación

Xcode MCP estable Service, Develop/iPhone18Pro Simulator27.0, target26/Swift6/strict complete/nonisolated.

| Paso | Evidencia |
|---|---|
| RED inicial |7/7 fallos semánticos de lista/sesión y formulario sobre APIs provisionales compilables; build20,720s correcto. |
| GREEN ViewModels + RED composición |35 resultados:33 PASS,2 fallos esperados de escritura contra factory provisional solo lectura. Los nuevos casos de concurrencia se registran como regresión, no RED previo. |
| Corrección de compilación |Al conectar el adaptador, el compilador exigió construirlo en MainActor; se trasladó a la closure factory ya aislada. No cambia contrato ni es RED semántico. |
| GREEN focal final |21/21 PASS, pero solo3 ejecuciones dinámicas de3 declaraciones parametrizadas: insuficiente para35 resultados esperados. |
| Verificación completa |**896 declaraciones/129 suites,1.191/1.191 resultados PASS**, incluidos35 nuevos; cero fallos/skips/expected failures/runtime warnings en bundle nativo cerrado. |
| Build Develop |PASS10,375s, sin errores; aviso AppIntents conocido. |
| Build Production |PASS18,426s, sin errores; mismo aviso. Develop/iPhone18Pro restaurados. |

Fallback global justificado por selección parcial reproducida; comprobadas las8 variantes de observación reemplazada,
las6 interrupciones de mutación y las3 interrupciones de lectura. Los1.156 resultados previos siguen verdes.
No sleeps/polling/red real ni suite serializada; gates concretos y containers aislados. Los tests de composición recorren
crear→editar→desactivar→editar inactive, snapshot/observación y cola causal; preview interactiva y solo lectura.

Logs completos separan `Metadata extraction skipped, no AppIntents.framework dependency found`; GetBuildLog estructurado
puede mostrar0issues. No se afirma cero warnings globales ni validación DocC exportada. Sin xcodebuild, XCTest/XCUITest,
opt-outs unsafe o servicios live. UI/previews visuales/accesibilidad N/A: no hay Views/textos/recursos afectados.
La evidencia integral/deuda de fase08 permanece abierta; los formularios visuales y sus previews0/250 pertenecen a09.4.

Artefactos Xcode bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- RED7: `RunSomeTests/4ED38941-0090-49B8-8D48-A145D701B83F.txt`.
- GREEN VM/RED composición: `RunSomeTests/323D2B6B-809C-4C57-9496-E8CE25D1E497.txt`.
- GREEN focal: `RunSomeTests/BD3E5FA4-5B11-4067-A500-725F0E1DB024.txt`.
- Global: `RunAllTests/3473B340-1E20-44FA-A85C-E411DCEE4D73.txt`, consola15-02-48.
- Bundle nativo cerrado: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_15-02-48-+0200.xcresult`.
- Builds: `BuildProject/BuildProject-Log-20260929-150328.txt` y `BuildProject-Log-20260929-150413.txt`.

Estilo:10Swift revisados manualmente y con script; único candidato conserva vertical por closure/tipo función.
Gobernanza conserva solo seis enlaces históricos de08.3; diff-check limpio incluyendo los archivos nuevos.

### Auditoría y estado final

POST independiente por ios-standards-reviewer: **PASS, sin hallazgos P0–P3** sobre10Swift y4documentos. Inspeccionados
RED, paso de composición, bundle global cerrado, variantes parametrizadas y logs completos de ambos builds.
Revisión read-only operativa: root verificó **561/561 archivos tracked/no ignorados idénticos** antes/después;
manifiesto `/tmp/franalonso-09-3-post-review.json`, SHA-256
`7832a4039fefc66f4ce22d9e53b63777dc9a651dcc7c41ab8718ee2145b60e5b`.
Sin correcciones ejecutables ni retest posterior; solo registro documental y reconciliación Linear.

PLU-52, fase09/PLU-49 y proyecto permanecen In Progress, con implementación validada y entrega09.3 pendiente.
Documentación y Linear reconciliados. La rama conserva14archivos nuevos/modificados sin commit/push;09.4 no iniciada.
Siguiente puerta: autorización de entrega09.3; las pantallas y sus evidencias propias corresponden a09.4.

## Inicio09.3, 2026-09-29

[PLU-52](https://linear.app/plusprojects/issue/PLU-52), Jesus Franco, hija dePLU-49, In Progress.
Implementación autorizada por el propietario tras los merges09.1/09.2. Rama local
`codex/plu-52-phase-09-3-product-view-models` creada desde main/origin/main b8efe87 idénticos y limpios.
[Propuesta09.3](09-3-product-view-models-proposal.md): dos fachadas @Observable @MainActor, destino de formulario y
composición contextual ADR0011; no UI, Store, stock ni cambios Data/Domain. PRE independiente PASS sin hallazgos;553/553 archivos idénticos. Implementación autorizada en curso.
Baseline1.156/1.156 y builds/auditorías anteriores reutilizados; preparación documental, Xcode/UI/accesibilidad nuevos N/A.

## Entrega y cierre09.1–09.2, 2026-09-29

Autorización completa del propietario: commit/push09.2, PR y merge de09.1/09.2, cierre de ramas y posterior09.3.
09.2 publicada como `04e376078e75d56215a1b2ac3d530304028b6980`, `✅ test(products): verify CRUD sync and recovery`.
[PR17](https://github.com/JFrancoG/FranAlonso/pull/17) integra09.1/349f3b7 mediante
`7c9ab09fe4e71152ad23f24afa0faddf113f0fca`; [PR18](https://github.com/JFrancoG/FranAlonso/pull/18) integra09.2/04e3760
mediante `8ed0af5b9bc3e5a33a8c7f24190f56f19e990755`. Ambas MERGED, CLEAN/MERGEABLE antes del merge, sin checks remotos.
Se conservan merges explícitos y toda la historia; árbol de cada merge idéntico al head validado correspondiente.
Las dos ramas se eliminaron localmente y en origin después de confirmar cero commits únicos respecto a main.

PLU-50 yPLU-51 Done; fase09/PLU-49 In Progress. Docs y Linear reconciliados con la entrega real.
Se reutilizan1.156/1.156 resultados, build Develop con tests y POST09.2; Production09.1 permanece válido porque09.2
solo cambió tests/docs. Aviso AppIntents y seis enlaces históricos08.3 conservados; UI/accesibilidad N/A en estos deltas.
No servicios live ni cierre de deuda08. Esta reconciliación es documental: Xcode N/A por código/configuración intactos.
Siguiente alcance autorizado09.3: ProductListViewModel/ProductFormViewModel, con propuesta/PRE antes del código.
Los estados inferiores se conservan como historial, superados por este cierre.

## Entrega09.1–09.2 autorizada, 2026-09-29

El propietario solicita «Commit y push. Lanza PR y merge de09.1 y09.2, y cierra ramas. Despues comienza a implementar09.3».
Se autoriza publicar09.2, integrar primero09.1 y después09.2, cerrar sus issues/ramas y comenzar09.3 tras su PRE.
Esta autorización sustituye las puertas pendientes descritas en las entradas históricas inferiores. Se reutiliza la
validación reciente: cuatro Swift09.2 coinciden byte a byte con el POST; del helper compartido solo se retira una
línea vacía final detectada al incluir el archivo nuevo en el índice. Sin cambio semántico; resto documental.
El resultado definitivo de commits/PR/merge se registrará después de comprobarlo; fase09 permanece abierta.

## 09.2 — Implementación local, 2026-09-29

El propietario aprueba la [propuesta PRE PASS](09-2-product-sync-proposal.md) con «si, adelante».
[PLU-51](https://linear.app/plusprojects/issue/PLU-51) sigue In Progress, responsable Jesus Franco, hija dePLU-49.
Rama local `codex/plu-51-phase-09-2-product-sync`, dependiente de09.1/349f3b7, sin upstream ni publicación09.2.
Esta entrada sustituye los estados de preparación/aprobación pendiente del inicio histórico inferior.

### Alcance y resultado

Cinco escenarios de integración recorren los UseCases09.1, repositorio, persistencia SwiftData y motor Product reales,
con remoto determinista en la frontera existente: CRUD/repetición, desactivar durante ack por vía contextual, conflicto,
tombstone observado y recuperación durable. ProductCRUDSyncIntegrationTests aporta cuatro casos y
ProductCRUDDurabilityTests el recorrido en disco. ProductSyncTestSupport comparte solo remoto, gate y reloj previamente
privados; las dos suites originales conservan sus pruebas. Cinco archivos Swift de tests nuevos/modificados.

El caso durable falla en PUSH tres veces, comprueba retry por operation ID, libera actores/motor/contenedor mediante
referencias weak y reabre la misma URL con Schema.franAlonso2.0/PhaseFiveSchemaMigrationPlan. Verifica payloads/bytes,
IDs, bases, predecesores, snapshot inactive, retry y cursor; recupera y reabre una segunda vez para confirmar estado
remoto, cursor3, ausencia de colas/retries y un único documento remoto. Nunca toca el store de la app.

**PASS inicial de caracterización; ningún defecto productivo demostrado.** No se cambia producción, App, schema,
configuración, UI, recursos ni localización. No se fabrica un RED: la primera compilación detectó una colisión entre
helpers de tests al extraer RetryManualTiming, corregida con el nombre ProductRetryManualTiming. No fue un fallo
semántico del producto. La extracción no altera las pruebas existentes salvo referencias y formato de dos llamadas.

### Validación y límites

Xcode MCP estable Service, Develop/iPhone18Pro Simulator27.0, target26/Swift6/strict complete/nonisolated sin cambios.

| Comprobación | Resultado |
|---|---|
| Cinco escenarios nuevos |5/5 PASS al primer intento ejecutable. |
| Regresión focal |123 declaraciones/129 resultados PASS; selección incompleta de dos variantes parametrizadas. |
| Fallback global |**875 declaraciones/125 suites,1.156/1.156 resultados PASS**; cero fallos/skips/expected failures/runtime warnings en bundle nativo cerrado. |
| Build Develop con tests |PASS10,502s; final9,731s tras formato de dos llamadas, sin cambios semánticos posteriores al global. |
| Production |N/A nuevo: solo tests/documentación; producción/configuración idénticas a09.1, cuya evidencia sigue válida. |
| UI, previews y accesibilidad |N/A en09.2 por ausencia de pantallas/textos/recursos afectados; no revalida ni cierra deuda08. |

RunSomeTests omitió nuevamente remote=false y status=.inactive en ProductCRUDPersistenceTests. RunAllTests ejecutó
ambas, comprobadas en consola y resultado cerrado. Por ello se amplió la regresión una sola vez; no se alteró la
parametrización. Los1.151 resultados previos siguen pasando junto con los cinco nuevos.

Logs completos mantienen el aviso conocido `Metadata extraction skipped, no AppIntents.framework dependency found`;
GetBuildLog estructurado devuelve0 issues, sin acreditar cero warnings globales. Los diagnósticos de StoreKit sin
cuenta Sandbox del host de tests no son fallos del escenario; el resultado nativo no registra runtime warnings.
Sin xcodebuild, XCTest/XCUITest, pruebas UI, opt-outs unsafe, dependencias nuevas ni tráfico live de negocio.
No acredita transporte Firebase real ni cierre abrupto del proceso; acredita liberación y reapertura real en disco.

Artefactos Xcode bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- Nuevos: `RunSomeTests/A88A8A68-833F-4D1D-B6B5-B4CA4063589A.txt`.
- Focal: `RunSomeTests/11BEBEF5-D1F9-435B-ADB5-24FB0C77B6D2.txt`.
- Global: `RunAllTests/4E70A5A0-67F2-4094-AD9B-815A9AE34AC2.txt`, consola14-01-12.
- Bundle nativo cerrado: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_14-01-12-+0200.xcresult`.
- Build: `BuildProject/BuildProject-Log-20260929-135932.txt`; final `BuildProject-Log-20260929-140210.txt`.

Estilo revisado en los cinco Swift: tres candidatos del script conservan formato vertical por closures; nombre atómico
de un test de121 columnas aceptado frente al límite preferido120. No se reformatea código histórico ajeno.
Gobernanza conserva únicamente seis enlaces históricos rotos de capturas08.3; diff-check limpio.
POST independiente por agente fresco ios-standards-reviewer: **PASS, sin hallazgos P0–P3**. Auditoría operativamente
read-only, prohibición explícita de escribir/publicar. Root verifica552/552 archivos tracked/no ignorados idénticos antes
y después; manifiesto `/tmp/franalonso-09-2-post-review.json`, SHA-256
`4609bcd38bdbd8945d90f8b9051c5a138df04ef85df8f81cc24921eefa657151`.
Revisión de oráculos, durabilidad, concurrencia, estilo y evidencia nativa; sin correcciones POST ni retest adicional.
Este dictamen se registra después de verificar la huella. PLU-51, PLU-49 y proyecto se reconcilian con implementación
local validada, entrega pendiente; conservan In Progress. Las descripciones no equivalen a commit ni cierre.
Commit/push09.2, PR, merge, cierres y09.3 siguen pendientes de autorización.09.1 no se cierra al completar09.2.

## 09.2 — Inicio histórico, 2026-09-29

El propietario autoriza «commit y push. Despues inicia 09.2».09.1 se publica en
[349f3b7](https://github.com/JFrancoG/FranAlonso/commit/349f3b7e38b68cd0e40a10b6bc823e11d0c55aa4), SHA local/remoto
idénticos en `codex/plu-50-phase-09-1-product-contracts`, árbol limpio después del push. PR/merge/cierre no incluidos.
23 archivos publicados;18Swift coinciden con el POST final. CHANGELOG y descripción/comentario de PLU-50 reconciliados.

[PLU-51](https://linear.app/plusprojects/issue/PLU-51), responsable Jesus Franco, hija dePLU-49, In Progress.
Rama local dependiente `codex/plu-51-phase-09-2-product-sync` creada desde349f3b7.09.1/PLU-50 sigue In Progress hasta
su entrega final; comenzar09.2 no altera su rama ni equivale a integración en main. La futura entrega09.2 conservará
su delta/dependencia respecto a09.1. Solo documentación local en esta preparación; sin commit/push09.2.

[Propuesta09.2](09-2-product-sync-proposal.md): cinco recorridos con capas Product reales, remoto de prueba y oráculos
explícitos: CRUD/repetición, desactivar durante ack, offline/reapertura durable, conflicto y tombstone observados.
No se ha demostrado un defecto productivo; empezar por caracterización y corregir solo fallos reproducibles dentro
de los contratos aprobados. No reescribir infraestructura ni anticipar App/UI, stock, demo, migración o live.
PRE independiente PASS, sin P0–P3. Propuesta concreta pendiente de aprobación para implementar.

Baseline técnica09.1 reutilizada:1.151/1.151 resultados, retest1/1 y builds Develop/Production, PRE/POST PASS, aviso
AppIntents conocido. Xcode MCP estable conectado a FranAlonso.xcodeproj/Develop/iPhone18Pro Simulator27.0; no se altera.
Esquema SwiftData actual ClientDocumentsSchema2.0 y plan PhaseFiveSchemaMigrationPlan; no volver al histórico1.0.
Inicio documental: build/tests/previews/accesibilidad nuevos N/A, sin código o configuración modificados.
Revisión por agente fresco `ios-standards-reviewer`, operativamente read-only con prohibición de escribir/publicar.
Root verifica549/549 archivos tracked/untracked no ignorados idénticos antes/después: manifiesto
`/tmp/franalonso-09-2-pre-review.json`, SHA-256 canónico
`1db9d49cd79ec3653019296c2a9f1a2e6fcddf590ae0b99334331355fcd9e926`.
Valida los cinco oráculos, reapertura2.0, límites, alternativas y baseline. Resultado añadido tras comprobar la huella.
Gobernanza: solo seis enlaces históricos rotos de capturas08.3; diff-check limpio, Progress bajo8192bytes.
Linear reconciliado:09.1 publicada pendiente de PR/merge/cierre;09.2 propuesta revisada, pendiente de implementación.

## 09.1 — Implementación local, 2026-09-29

[PLU-49](https://linear.app/plusprojects/issue/PLU-49) y [PLU-50](https://linear.app/plusprojects/issue/PLU-50)
continúan In Progress, responsable Jesus Franco. Rama `codex/plu-50-phase-09-1-product-contracts`, base `7ec61a5`.
El propietario autoriza la [propuesta](09-1-product-contracts-proposal.md) revisada con «si, adelante, implementa».
Implementación, validación y POST independiente completados. El propietario autoriza «commit y push. Despues inicia09.2».
Publicación09.1 autorizada; PR, merge y cierre siguen pendientes.09.2 se preparará desde este checkpoint en rama dependiente.

### Alcance implementado

- `ProductProfile` normaliza el nombre exterior y rechaza vacío, también al decodificar. Product/DTO históricos intactos.
- Get/Create/Update/Deactivate, preparación y búsqueda sobre `ProductRepository`; errores Domain neutrales.
  Alta activa con identidad nueva; homónimos permitidos; editar conserva el estado actual, incluido inactive.
- Desactivar conserva ficha y referencias como inactive, mediante upsert causal; repetir no escribe ni encola.
  Ausencia, tombstone y conflicto conservan rechazos distintos; lookup no expone identidades borradas.
- Primitiva local sin suspensión compartida por actor/adaptador contextual; reutiliza la aceptación causal05.10.
  Publicación tras commit, rollback si falla el guardado y protección de cambios no guardados ajenos.
  Cancelación previa rechazada; cancelación posterior no transforma una aceptación en fallo.
- Búsqueda local parcial por nombre, insensible a caja/diacríticos, recorta consulta y conserva orden e inactivos.

18 archivos Swift nuevos/modificados:16 de Domain/Data/tests de Products y dos conformidades de dobles existentes.
Sin cambios en schema, DTO, transporte, motor de sync, App/composición, UI, recursos visuales o localización.
La [spec09](../specs/09_products_stock.md) incorpora las reglas aprobadas; no hay dependencia ni ADR nuevo.

### TDD y validación

Xcode MCP estable27.0 Service, workspace `workspace-EYu6rxi7hg`, iPhone18Pro Simulator/iOS27.0.
Target iOS26, Swift6, strict concurrency complete, nonisolated; warnings Swift/Clang como errores.
No `xcodebuild`, XCTest, XCUITest, tests UI, opt-outs unsafe ni servicios live.

| Paso | Resultado y alcance |
|---|---|
| RED Domain |14 declaraciones/20 resultados:18 fallos semánticos esperados,2 casos de búsqueda vacía ya pasaban; compilación correcta. |
| GREEN Domain |20/20 PASS: perfil/Decode, identidad, homónimos, edición, desactivación, búsqueda y cancelación previa. |
| RED Data |8 declaraciones/10 resultados:8 fallos esperados en rutas provisionales;2 rechazos negativos ya pasaban y no se presentan como RED. |
| GREEN combinado inicial |22 declaraciones/28 resultados PASS; selección focalizada omitía dos variantes, insuficiente para declarar30/30. |
| Regresión focal |100 declaraciones/106 resultados PASS: Products completo y AppDependencies; incluye nueva caracterización de cancelación tras aceptación. |
| Verificación completa |**870 declaraciones/123 suites,1.151/1.151 resultados PASS**,0 fallos/skips/expected failures/runtime warnings en `.xcresult` cerrado. |
| Build Develop |PASS10,886s, sin errores; aviso AppIntents previamente conocido en log completo. |
| Build Production |PASS18,339s, sin errores; mismo aviso AppIntents. Develop/iPhone18Pro restaurados. |
| Correcciones POST |Retest afectado1/1 PASS, bundle cerrado13-04-02 sin fallos/skips/runtime warnings; compilación de tests correcta. |

La ejecución global se justifica por una limitación de selección observada: `RunSomeTests` con identificadores exactos
de `GetTestList`, incluso limitando la selección a dos métodos, solo ejecutaba `remote=true` y `status=.active`.
`RunAllTests` ejecutó además `remote=false` y `status=.inactive`, verificados en consola y resultado nativo cerrado.
No se cambió la parametrización para ocultar esta ausencia. Los31 resultados nuevos pasan;1120 previos siguen verdes.
La prueba adicional de cancelación tardía caracteriza el contrato ya implementado, sin inventar un RED previo.

Aceptación cubierta: cola de tres upserts, observación de commits, conflicto activo/inactivo, borrado pendiente/remoto,
inactivo ya reconocido sin nueva cola, paridad contextual/actor, contexto ajeno sucio conservado y rollback en store
de solo lectura. La simulación de fallo durable provoca diagnósticos SwiftData esperados; no prueba transporte live.

Artefactos locales Xcode bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`:

- RED Domain `RunSomeTests/88789248-FF00-4D6C-900B-BD1E01181706.txt`; GREEN `9B09B780-30EA-4011-BE41-64149E7D0BE3.txt`.
- RED Data `RunSomeTests/B399EEB2-8697-4821-8E62-DF8272FB2D2B.txt`; regresión `0A618B37-6B6D-4A70-B328-D8677A18F164.txt`.
- Suite global `RunAllTests/EA35E24E-4F9F-4825-BB0A-318401C1EAC7.txt`, consola `test-console-log-2026-09-29T12-55-36+02-00.txt`.
- Bundle cerrado: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_12-55-36-+0200.xcresult`.
- Builds: `BuildProject/BuildProject-Log-20260929-125614.txt` y `BuildProject-Log-20260929-125649.txt`.
- Retest POST: `RunSomeTests/6B9D9DDE-FB69-4538-802A-F2D782540783.txt`; bundle de Develop13-04-02 en Logs/Test.

Los logs completos contienen `Metadata extraction skipped, no AppIntents.framework dependency found`, aunque el
filtro de issues de GetBuildLog devuelve0. No se afirma cero warnings globales ni validación DocC exportada.

### Revisión y límites

PRE independiente PASS, sin P0–P3;538/538 archivos idénticos antes/después, huella en la propuesta.
POST independiente por `ios-standards-reviewer`: **PASS final, sin hallazgos abiertos** sobre18Swift/cuatro documentos.
Primer pase detectó P2 en el test (indexar tras expectativa no abortiva) y P3 de formato (firma con closure horizontal).
Se cambiaron a `try #require` y firma vertical; revisión repetida solo sobre ambos cambios, retest afectado1/1 PASS.
No cambió comportamiento de producción; la suite global y ambos builds previos mantienen su alcance válido.

Auditoría operativamente read-only, sin sandbox de solo lectura disponible: agente fresco independiente, prohibición
explícita de escribir/publicar y root verifica548/548 archivos tracked/untracked no ignorados idénticos en ambos pases.
Manifiestos JSON canónicos y SHA-256:

- `/tmp/franalonso-09-1-post-review.json`: `a848ef3013ffced4f0457c9084b7ec666051385f11437cb3579ba2f77dda4b23`.
- `/tmp/franalonso-09-1-post-recheck.json`: `10582f9e09fda1891c613ed9131bb1b3c2d6bd19958d7c078bf41bd2c388497f`.

Registro de resultados añadido después de comprobar las huellas. Estilo: script de candidatos y revisión manual sobre
18Swift, sin hallazgos abiertos. Gobernanza conserva solo seis enlaces históricos rotos de capturas08.3; diff-check limpio,
Progress bajo8192bytes, sin rutas sensibles/configuración modificadas. Linear reconciliado con entrega pendiente.
Previews, smoke visual y auditoría UI/accesibilidad **N/A**:09.1 solo cambia Domain/Data/tests, sin pantallas afectadas.
Esto no cierra ni revalida la deuda accesible de fase08. No hay evidencia remota, producción live ni CAS entre contextos.

09.2 conserva integración y regresión completa de persistencia/sync;09.3–09.7 mantienen ViewModels, UI, ajustes y mínimos.
Seed de demo Product, Service, Foundation Models, ventas y fotografía quedan para sus subfases autorizadas.
PLU-49/50 continúan In Progress hasta sus respectivas entregas. Commit/push09.1 e inicio09.2 autorizados; PR, merge,
cierre y borrado de rama no incluidos. Publicación mediante `✨ feat(products): add CRUD and local search`, con CHANGELOG.
La identidad exacta del commit y paridad remota se verifican en Git/Linear después del push. Se reutiliza evidencia:
el árbol ejecutable/configuración coincide con el POST final; solo se añaden metadatos documentales de publicación.

## Inicio — 2026-09-29

Autorización «OK, abre issue y rama e inicia fase 09», tras08.8a Done funcional según ADR0030.
Se crearon PLU-49 y PLU-50 y la rama local desde `7ec61a5`; main/origin/main/remoto coincidentes y árbol limpio.
La preparación documental recibió PRE PASS antes de aprobar código. Baseline reutilizada:1.120/1.120 resultados,
Develop/Production y aviso AppIntents conocido, árbol de `0c76967` integrado en PR16; [evidencia08.8a](phase-08.md).
Build/tests/previews del inicio documental N/A. Gobernanza conservaba seis enlaces históricos rotos de capturas08.3.
Esta entrada histórica queda superada por la autorización e implementación de09.1 descritas arriba.
