# Fase 12 — Venta y stock

Actualizado: 2026-10-02. [Spec](../specs/12_stock_sale_integration.md).
[Fase PLU-85](https://linear.app/plusprojects/issue/PLU-85): In Progress, sin cierre ni activación live.

## 12.1 — Análisis puro de impacto

[PLU-86](https://linear.app/plusprojects/issue/PLU-86), Done, Jesus Franco.
Rama `codex/plu-86-sale-stock-impact`, base limpia `0a9729c` en main/origin-main.
Autorización: «Abre issue y rama e implementa la subfase 12.1».
[Propuesta y revisión PRE](12-1-stock-impact-proposal.md): PASS independiente, huella idéntica.

`AnalyzeSaleStockImpactUseCase` en Sales/Domain delega en la política publicada `StockWarningPolicy`, sin duplicarla.
Recibe líneas y cantidades actuales por producto y devuelve impactos en orden para las líneas vinculadas;
acumula productos repetidos incluso intercalados, omite servicios profesionales y no modifica entradas.
Agotamiento exacto suficiente; stock cero/negativo produce aviso no bloqueante. Ausencia de stock, identidad
duplicada y overflow siguen siendo errores de datos. Operación síncrona, sin I/O, reservas ni efectos persistentes.

### Validación Xcode MCP

Service estable `workspace-PfnUYLlMzY`, FranAlonso.xcodeproj, iPad Pro13(M5) Simulator27.2,
SDK27.0, target27.0, Swift6/nonisolated/strict complete/approachable concurrency y warnings-as-errors.
Develop y plan FranAlonso-Develop restaurados tras verificar Production; destino original preservado.

- Baseline focal: política publicada10/10 PASS. Log previo existente Production01/10 distinguido del trabajo actual.
- RED: build-for-testing02/10 falló por `AnalyzeSaleStockImpactUseCase` ausente, con diagnósticos derivados.
  Log: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133412.txt`.
- GREEN:6 declaraciones nuevas/10 escenarios y9 declaraciones anteriores/10 escenarios: **20/20 PASS**,
  sin fallos, skips ni resultados no ejecutados. Oráculos literales de spec, sin mocks de cálculo ni comparación
  contra la política para fabricar resultados esperados. Inventario1359 habilitadas; no se ejecutó toda la app.
  Resultado nativo cerrado: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.02_13-35-07-+0200.xcresult`.
- Develop build-for-testing: PASS26,681s. Production build: PASS22,241s.
  Logs: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133454.txt`
  y `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133556.txt`.
  Cero warnings estructurados y cero warnings Swift/Clang. Los logs completos conservan el aviso histórico
  de appintentsmetadataprocessor: metadata omitida porque no existe dependencia AppIntents; no se declara cero
  avisos absolutos ni se introduce framework para silenciarlo.
- Diagnósticos de los dos archivos nuevos:0/0, ambos `success=true` mediante Xcode MCP.
- `validate_localizations.py`:561 entradas es/en,0 errores; catálogo sin cambios.
- Gobernanza: persisten únicamente los seis enlaces Desktop rotos conocidos de08.3, fuera del alcance.
- UI, previews y auditoría accesible N/A: no View, recurso visual, texto localizado ni flujo cambiado.

### Auditoría y estado

POST técnica y estilo Swift independientes: sin hallazgos en los dos Swift, recall2 archivos/0 candidatos
y revisión manual completa. Resultado nativo20/20 y logs finales contrastados por el revisor.
Huella operacional idéntica antes/después:799 archivos,
SHA256 `7b951260e6d2e720dc39b54e0fb27ea4af24d576e4aab70340dc5bebc7a78b2a`.
Único hallazgo P3 documental: Progress excedía8192bytes. Entrada nueva compactada, conservando detalle aquí;
Revisión documental focal posterior: PASS sin hallazgos; Progress8176≤8192bytes, historial intacto.
Huella documental antes/después idéntica:799 archivos,
SHA256 `1e8d67221418ce8a3e76cc46f29dcdd10945cdee90f624b3542802dbfc1f536c`.
Swift intacto, no requiere repetir builds/tests. Gobernanza final solo conserva seis enlaces08.3 históricos.
Entrega completa autorizada el02/10: «commit, push y entrega».
Se reutiliza la validación de esta sesión: los dos Swift conservan sus hashes, con cambios posteriores solo documentales.
Snapshots pueden quedar obsoletos:12.2 debe obtener/refrescar entradas sin mover la regla al Store.
12.2–12.8, pago atómico, movimientos y sync conservan gates separados. El análisis no acredita stock live.

### Entrega definitiva

[PR42](https://github.com/JFrancoG/FranAlonso/pull/42) MERGED el02/10.
Commit `01769e502f548c5cb5e42ca1353ee63333a0d323` → merge `029bc46b5cbc6bf1480cb61fc6241383ffe63b64`.
Árbol completo integrado idéntico al commit revisado; ningún cambio Swift/config tras validación.
Checks remotos y workflow runs vacíos, main sin reglas/protección requeridas: no se acredita CI remota.
Rama `codex/plu-86-sale-stock-impact` eliminada local/remota tras verificar ambos tips y ascendencia al main remoto.
PLU-86 Done; PLU-85 In Progress con12.1 entregada y12.2–12.8 pendientes. No se inicia12.2.
Este cierre solo modifica documentación; Xcode adicional N/A porque la fuente/config validada sigue intacta.


## 12.2 — Avisos de stock del Store

[PLU-87](https://linear.app/plusprojects/issue/PLU-87), Done, Jesus Franco, hija PLU-85.
Autorización02/10: «abre issue y rama e implementa12.2». Base limpia main/origin-main `a543125`;
rama `codex/plu-87-sale-draft-stock-warnings`. [Propuesta/PRE](12-2-stock-store-proposal.md): PASS independiente.
La entrega previa12.1 no extiende autorización a commit/push/PR/merge/cierre12.2.

### Implementación

`GetSaleStockQuantitiesUseCase` lee cada producto vinculado una vez por refresco, por orden de primera aparición,
mediante StockRepository existente; comprueba cancelación antes/después de las lecturas suspendidas.
Snapshot local secuencial, no atómico multi-producto y sin reserva, observaciones ni movimientos.
`SaleDraftStore` conserva venta/cálculo aceptados; proyecta por separado stockState idle/loading/ready/failed y
stockError. Create/load/edit aceptados invalidan avisos anteriores y refrescan en la tarea estructurada del caller,
delegando la regla a AnalyzeSaleStockImpactUseCase. Cantidad/eliminación/alta recalculan productos repetidos.
Stock conocido cero/negativo no bloquea; ausencia de lector/cantidad, overflow o fallo de lectura quedan en failed.
El error advisory no contamina lastError ni revoca el éxito durable. Cancelación advisory deja idle sin error.
Refresh público usa generación independiente y snapshot original: resultado/error obsoleto no sustituye el actual;
close/discard/ausencia invalidan la proyección. Edición rechazada conserva avisos del último borrador aceptado.
La edición conserva exclusión hasta completar el análisis; refresh manual no introduce operación de escritura.
ViewModel solo proyecta estado/delega refresh editable. Composición live/local/demo y preview interactivo inyectan
el mismo repositorio stock local. Constructores históricos/preview finito conservan capacidad opcional explícita:
con líneas físicas y sin lector -> failed/readerUnavailable; sin físicas -> ready([]), nunca stock inventado.
Sin modificación de View/texto/catálogo/configuración, sin pago/movimientos/sync ni activación live.

### Evidencia Xcode MCP

Service estable `workspace-PfnUYLlMzY`, Develop/planDevelop; Simulator iPadPro13(M5)27.2, SDK27.0,
iOS27/Swift6/nonisolated/strict complete/warnings-as-errors. Production verificado y Develop/destino restaurados.

- Baseline Store/concurrencia:49/49 PASS.
- RED antes de código: APIs UseCase/estado/refresh ausentes; fallo esperado de compilación de tests.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-135703.txt`.
- GREEN inicial16/16; final16 declaraciones/18 escenarios nuevos incluidos en regresión **153/153 PASS**,
  0 fallos/skips/expected failures/no ejecutados: Stock/Store/concurrencia/ViewModel/composición/demo/política/semántica.
  Oráculos literales independientes, barreras deterministas sin sleeps para latest-wins con éxito/error,
  edición/discard/close/cancelación tras aceptar. Recarga usa stock actual; refresh no reescribe venta;
  composición in-memorySwiftData verifica libro real compartido, cantidades actuales y solo movimientos explícitos.
  Resumen completo (MCP trunca inline a100):
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/30DF811C-B43A-40E9-8F5F-C20CA9887947.txt`.
  Resultado nativo cerrado real inspeccionado con xcresulttool (solo lectura):
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_14-03-30-+0200.xcresult`.
  107 declaraciones,24 parametrizadas/70 ejecuciones,153 resultados por dispositivo; runtimeWarnings vacíos.
  El xcresultBundlePath devuelto por MCP en ActionArtifacts no existe: se contrastó el bundle real de DerivedData.
- Develop build-for-testing22,128s + final incremental3,674s PASS; Production21,103s PASS.
  Logs `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-140157.txt`,
  `BuildProject-Log-20261002-140359.txt` y `BuildProject-Log-20261002-140434.txt` en la misma carpeta.
  Cero warnings Swift/Clang o estructurados; persiste aviso histórico appintentsmetadataprocessor de metadata
  omitida por ausencia de AppIntents.framework. No se declara cero avisos absolutos.
- Diagnósticos MCP de los6 Swift:0 cada uno, success=true. Dos fallos transitorios SourceEditor(error5) pasaron al reintentar.
- Catálogos561 es/en,0 errores; diff-check PASS. Gobernanza solo conserva seis links Desktop rotos08.3 históricos.
- Estilo recall6 archivos/1 candidato: firma edit con función aislada, previa al cambio; vertical preserva lectura.
  Inspección manual del diff y archivo nuevo, sin cambios oportunistas a estilo histórico.
- UI/previews/auditoría accesible N/A: no cambia pantalla ni presentación de avisos, asignada a12.3.
  Esta evidencia no valida VoiceOver ni la deuda previa ADR0029 y no cierra fase12.

### Auditoría y pendiente

POST independiente: sin hallazgos funcionales/arquitectura/datos/concurrencia. Un P3 lexical en7 closures
con efectos de tests (Task/finish/continuations) corregido expandiendo solo layout. Huella primera pasada
antes/después idéntica:802 archivos, SHA256 `1aaa2cf3d83a3ab3781e1fa843b65b12f20ad1bbd1deea72bdbc90ffba7439dc`.
Tras corrección, focal18/18 PASS (16 declaraciones/2 parametrizadas/4ejecuciones), native runtimeWarnings vacíos,
Develop build-for-testing3,926s y diagnóstico tests0 PASS. Código/config Production intactos desde validación;
no se repite Production ni regresión completa porque solo cambió whitespace en tests.
Resumen `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/9426CAB4-B851-4191-87CF-C91E674059CC.txt`.
Native real cerrado `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_14-10-43-+0200.xcresult`.
Build log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-141133.txt`.
Re-auditoría lexical/documental focal independiente: sin hallazgos, P3 resuelto, POST PASS.
Recall test1 archivo/0 candidatos más revisión manual. Huella focal antes/después idéntica:
802 archivos, SHA256 `349877866fafa698adcef8d3d748e31afdcd7610125db949ff2b78adc940a9ff`.
Solo documentación de resultado posterior; fuentes/config idénticas a las validadas y auditadas.
PRE/POST/estilo PASS; no hallazgos abiertos para12.2.
Entrega12.2 autorizada el02/10: «commit, push y entrega.».
PLU-87 Done tras integración verificada. Fase PLU-85 abierta;12.3–12.8 conservan sus gates.
Se reutiliza la validación de esta sesión: al iniciar entrega se reconstruyó virtualmente el snapshot documental
anterior y su huella completa coincide exactamente con la auditada (802files/349877…): Swift/config/tests intactos.
Cambios posteriores solo documentan autorización/changelog/entrega; Xcode adicional N/A por ausencia de cambios
al código o configuración. Sin nuevas dependencias, excepción arquitectónica ni activación live.


### Entrega definitiva12.2

[PR43](https://github.com/JFrancoG/FranAlonso/pull/43) MERGED el02/10.
Commit `463de375ebead1dce691b5c37534080273c691c7` → merge `cf05c9c525f2f43963480246c6201aaddafb9002`.
Árbol completo de origin/main idéntico al commit entregado; ningún cambio Swift/config/tests tras validación.
Checks/workflow runs remotos vacíos; main sin protección/reglas requeridas: no se acredita CI remota.
Rama `codex/plu-87-sale-draft-stock-warnings` eliminada local/remota tras verificar ambos tips463de37 y ascendencia
al main remoto. PLU-87 Done; PLU-85 In Progress con12.1–12.2 entregadas y12.3–12.8 pendientes.
Cierre documental en main siguiendo la entrega anterior: CHANGELOG/Progress/fase, validadores y diff-check;
Xcode adicional N/A por ausencia de cambios al código/configuración. Gobernanza solo conserva seis links08.3 históricos.
No activa live, no cierra fase12 ni inicia12.3.
