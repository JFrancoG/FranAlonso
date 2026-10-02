# 12.1 — Propuesta de análisis de impacto de stock

2026-10-02. Autorización: «Abre issue y rama e implementa la subfase 12.1».
PLU-86, hija de PLU-85. Base limpia `main`/`origin/main` en `0a9729c`.
Rama `codex/plu-86-sale-stock-impact`.

## Contrato y alternativa

Añadir `AnalyzeSaleStockImpactUseCase` en Sales/Domain/UseCases con
`callAsFunction(lines: [SaleLine], availableQuantities: [ProductID: Int]) throws -> [StockImpact]`.
Es síncrono, puro y sin dependencias I/O. Delega en la política concreta `StockWarningPolicy` ya publicada
en Products/Domain. Esa política es la fuente única del cálculo: orden de entrada, solo líneas vinculadas,
consumo acumulado por producto, agotamiento exacto suficiente y proyección negativa como aviso no bloqueante.
Propaga errores por identidad duplicada, stock ausente y overflow; no interpreta ausencia como cero.
No filtra por estado: analiza los snapshots que aporta el caller. No modifica entradas ni stock real.

Alternativas: duplicar cálculo en Sales introduce divergencia; consultar repositorios añade I/O y pertenece a12.2;
usar directamente la política en Presentation omite la intención Domain exigida por spec12.1.
No hace falta protocolo, Store, actor o ADR nuevo: es una fachada semántica concreta sobre una política existente.

## Autoridad y baseline

Constitución, spec12, ADR0011/0003 y política Swift. Fuentes primarias locales:
`SaleLine.swift`, `StockWarningPolicy.swift` y `StockWarningPolicyTests.swift`; no se eligen APIs Apple nuevas.
Xcode MCP estable Service `workspace-PfnUYLlMzY`, proyecto FranAlonso.xcodeproj,
Develop/FranAlonso-Develop, iPad Pro13(M5) Simulator27.2/SDK27.0.
Settings efectivos: iOS27, Swift6, strict complete, nonisolated, approachable concurrency y warnings-as-errors.
Último log existente MCP: Production del01/10 correcto, sin warnings estructurados; no es build nuevo de12.1.
Baseline focal actual02/10: StockWarningPolicy10/10 PASS; inventario1353declaraciones.
Evidencia entregada11.9:2180ejecuciones y builds Develop/Production PASS en phase-11; no se repite toda la app.

## TDD y validación

Tests nuevos ejecutan el UseCase con oráculos literales independientes: suficiente/exacto/cero/negativo,
producto repetido e intercalado, línea profesional omitida, ausencia/vacío, errores de input y overflow acumulado.
RED por símbolo ausente, GREEN focalizado y regresión StockWarningPolicy. Dos builds vía Xcode MCP,
logs completos y diagnósticos del archivo nuevo. Auditorías PRE/POST independientes y estilo con huella idéntica
de todos los tracked/untracked no ignorados antes/después. UI/previews/accesibilidad N/A: no superficie visual.

## Límites

Solo UseCase nuevo, tests y documentación de12.1; política publicada intacta. Riesgo: snapshot puede quedar
obsoleto;12.2 deberá refrescar entradas. No reservas, mutación, movimientos, pago, persistencia, sync ni live.
Durante la implementación no se autorizó12.2–12.8 ni entrega. Cambios reversibles.
Entrega completa autorizada después el02/10: «commit, push y entrega»;12.2–12.8/live siguen fuera del alcance.

Revisión PRE independiente `stock_proposal_review`: PASS sin hallazgos P0–P3.
Huella operacional antes/después idéntica:796 archivos,
SHA256 `74fb84537c6ced22e5d78ade3c69ab68f98f5981772b40b43e4062cdd2bc8263`.
Implementación autorizada por la petición original, sin nueva excepción ni ampliación de alcance.
