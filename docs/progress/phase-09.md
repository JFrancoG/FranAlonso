# Fase 09 — Productos e inventario físico

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
