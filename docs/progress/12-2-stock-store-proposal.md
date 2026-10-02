# 12.2 — Stock advisory del borrador

2026-10-02, PLU-87/Jesus Franco, hija PLU-85. Autorización: «abre issue y rama e implementa12.2».
Base limpia main/origin-main `a543125`; rama `codex/plu-87-sale-draft-stock-warnings`.

## Alcance

Reutilizar AnalyzeSaleStockImpactUseCase12.1, sin tocar su política. Añadir GetSaleStockQuantitiesUseCase
en Sales/Domain para leer una vez cada ProductID vinculado, en orden, mediante StockRepository existente;
sin writes/observaciones/tareas propias, con comprobación de cancelación antes/después de lecturas.
Las lecturas son snapshots locales secuenciales, no reserva ni snapshot atómico multi-producto.

SaleDraftStore conserva venta/cálculo aceptados y añade stockState idle/loading/ready([StockImpact])/failed
y stockError separado. Al publicar create/load/edit invalida proyección anterior y refresca automáticamente
en la tarea estructurada del caller. Ausencia de snapshot/lector, overflow y read failure quedan en failed sin tocar lastError
de aceptación ni convertir una escritura aceptada en error. Cancelación del análisis deja idle/sin error y no
revoca éxito durable. Líneas profesionales/vacío producen ready([]) sin consultar stock.
Lecturas no bloquean el actor pero la intención de edición retiene su exclusión hasta completar el refresh.

refreshStock() público async sin nueva mutación/operation; permite refrescos superpuestos con latest-wins.
Un generation independiente y el snapshot de venta original impiden publicar resultado/error de otra versión.
Edición aceptada/discard/ausencia/close invalidan generación y proyección; un refresh tardío nunca reabre sesión.
Actualización fallida conserva el último snapshot aceptado y sus avisos. No se recalcula negocio en el Store.

SaleDraftViewModel solo proyecta stockState/stockError y delega refresh en modo editable.
AppDependencies compone GetSaleStockQuantitiesUseCase con su StockRepository real compartido en live/local/demo
e interactive previews. Capacidad opcional explícita para constructores de prueba/preview finito existentes:
sin lector y con líneas físicas queda unavailable/failed explícito, nunca inventa stock cero o suficiencia.
Sin lector y sin líneas físicas:ready([]). Esta compatibilidad no omite la inyección en composición real.

## Alternativas y límites

Duplicar reglas en Store viola spec12.2. Observar automáticamente cada producto añadiría tareas/subscripciones
y política de agregación no requeridas: se refresca explícitamente o tras aceptar cambios, sin polling.
Rechazar el guardado si falla stock contradice los avisos no bloqueantes y éxito durable previo.
Otro Store duplicaría estado. No nuevo protocolo, dependencia, ADR, API Apple ni excepción concurrency.
Solo Domain nuevo/Store/ViewModel/composición y tests/docs; no Views/textos/previews visuales nuevos.
UI12.3/confirmación12.4/pago-movimientos-sync12.5–12.8/live/entrega conservan gates separados.

## Autoridad y evidencia

Constitución/spec12, ADR0003/0011, política Swift, Development Guide; contratos reales SaleDraftStore,
SaleDraftViewModel, StockRepository/DefaultStockRepository y AnalyzeSaleStockImpactUseCase.
Xcode MCP estable Service workspace-PfnUYLlMzY, Develop/planDevelop, Simulator iPadPro13(M5)27.2/SDK27.0.
Settings efectivosiOS27/Swift6/nonisolated/strictcomplete/warnings-as-errors.
Baseline reciente12.1:20/20, buildsDevelop26,681s/Production22,241s y PRE/POST PASS; fuente intacta desde entrega.
Se ejecutará regresión de Store/ViewModel/composición antes de validar cambio final.

## TDD

RED UseCase/estado nuevos ausentes. Oráculos independientes para lectura única por producto, cantidad,
eliminación del primero de productos repetidos, agotamiento exacto/cero/negativo, stock actualizado, añadir línea,
profesionales/vacío, error y recuperación, overflow y aceptación durable pese a fallo/cancelación stock.
Barreras deterministas para refresh superpuesto, edición/close/discard durante lectura; sin sleeps.
Pipeline in-memorySwiftData y App demuestra inyección real y ausencia de movimientos nuevos por análisis.
GREEN/regresión impactada/buildsDevelop/Production/diagnósticos, PRE/POST/estilo read-only con huellas iguales.
UI/accesibilidad N/A porque no se altera superficie visual; su presentación corresponde a12.3.

Revisión PRE independiente: PASS sin hallazgos, agente fresco stock_store_proposal, read-only operacional.
800 archivos, SHA256 anterior/posterior idéntico:
`3783a1b2235449df554dd2c1ee5b3f5a0228514c94afb43d7e8cf6c56c9004e6`.
Precisión del revisor aplicada: stock conocido insuficiente produce ready con aviso; solo ausencia de cantidad/lector
produce failure. Fuentes primarias: [CancellationError](https://developer.apple.com/documentation/swift/cancellationerror)
y [SE-0306, reentrancia](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md#actor-reentrancy).
Al inicio no existía autorización de entrega. Tras implementar/validar/auditar, entrega12.2 autorizada:
«commit, push y entrega.» (02/10). El siguiente alcance y live conservan gates separados.
