# Fase 12 — Venta y stock

Actualizado: 2026-10-02. [Spec](../specs/12_stock_sale_integration.md).
[Fase PLU-85](https://linear.app/plusprojects/issue/PLU-85): abierta, sin cierre ni activación live.

## 12.1 — Análisis puro de impacto

[PLU-86](https://linear.app/plusprojects/issue/PLU-86), In Progress, Jesus Franco.
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
Entrega completa autorizada el02/10: «commit, push y entrega». Commit/push/PR/merge y cierre de issue/rama en curso.
Se reutiliza la validación de esta sesión: los dos Swift conservan sus hashes, con cambios posteriores solo documentales.
Snapshots pueden quedar obsoletos:12.2 debe obtener/refrescar entradas sin mover la regla al Store.
12.2–12.8, pago atómico, movimientos y sync conservan gates separados. El análisis no acredita stock live.
