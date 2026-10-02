# 11.7 — Descuento global provisional para la demo

2026-10-02. PLU-80 In Progress/Jesus Franco, `codex/plu-80-sale-discounts`.
Continúa la implementación local autorizada. El editor de línea aceptado se conserva; la dirección humana elimina
la espera de una elección global definitiva: Fran decidirá tras la demo. PRE técnico independiente PASS.

## Comportamiento concreto

Un porcentaje global propio de la venta convive con la promoción snapshot de cada línea. Se aplica después de esa
promoción, antes de extraer IVA, con redondeo por etapa y línea: 100€, línea10% y global20% dejan72€.
El global vale también para nuevos servicios y una venta vacía; retirarlo conserva todas las promociones de línea.
Porcentaje exacto0…100, nil distinto de cero, vacío inválido y retirada explícita, sin nuevos límites arbitrarios.

La política `lineThenGlobalV1` se guarda con el término para que una decisión posterior no cambie ventas antiguas.
Todo cambio sólo en draft; consultar global/lineal/importes también en inspección readonly. Demo y producción
comparten reglas reales, sin nuevos motores, dependencias ni live. [ADR0032](../ADRs/0032-provisional-global-sale-discount.md)
documenta la evolución mínima y sus límites de compatibilidad.

## Ámbito y propiedad

- Domain: SaleGlobalDiscount con política cerrada V1; Sale/Codable/transiciones; candidatos de edición; cálculo
  secuencial reutilizando certificado ADR0031 y desgloses lineDiscountAmount/globalDiscountAmount/discountAmount.
  Repository/UpdateUseCase incorporan el término completo. Overload de edición anterior conserva expected.globalDiscount.
- Data: SaleDTO1/2 y global DTO canónico; local envelope2 sobre linesData existente; decode1 sin tocar bytes;
  repositorios/adaptadores de la aceptación actual y writer/reader Firestore por versión real de la operación.
  Sin nuevos campos @Model, esquema4, migración, transportes, reglas ni queries.
- Presentation/App: Store conserva la responsabilidad actual y calcula Sale completo en create/load/edit/inspect.
  Generalizar el editor de porcentaje de línea a SaleDiscountViewModel/Screen/Content, conservando su contrato ya
  probado y un ViewModel por sesión. Destino identificado `.line(id)`/`.global` sin copiar venta, una única sheet
  de descuento, capacidades compuestas en App y exclusión con selector de servicios. Cada View conserva su archivo.
  Sección global con porcentaje/ausencia y edición; instrucciones aclaran aplicación después de promociones y
  a servicios futuros. Totales muestran ambos importes y descuento agregado. Retorno de foco por destino, sin timers.
- Tests: Domain/cálculo/límites/Store y conformers; DTO/codec/reapertura/replay; navegación/composición global y
  recuperación. Recursos ES/EN, previews reales y registro de accesibilidad ampliado en PLU-81 por impacto.

## Ejecución y TDD

Dos trabajadores separados: Domain+Store+dobles de repositorio; Data+codecs+fixtures históricos.
Root posee Presentation restante/App/UI, recursos y documentación. Nadie revierte cambios de otros.
PRE read-only independiente antes de stubs o tests ejecutables. Después, tests funcionales y stubs mínimos para
RED compilable; workers esperan evidencia RED antes del GREEN. Xcode lo opera sólo root y siempre serializado.

Oráculos monetarios literales distinguen etapas y agregado, incluyendo signos, precisión38dígitos, overflow y
EUR/USD. Conservar nil/0/100, captura de promoción futura, retirada global y lineal independientes, estado pagado,
stale snapshot sólo-global y candidato inválido sin escritura. UI reutiliza requestID estable, comando congelado,
retry mismo término, éxito durable tras cancelación y close que cerca publicación sin cerrar el Store padre.

Codec tests usan fixtures v1 literales, no round trips derivados de writers nuevos. En disco, fila v1 auténtica
reabierta por schema3/plan actual, escritura sucesora v2 y segunda reapertura, preservando bytes/IDs/bases/revisiones
de operaciones antiguas. Unknownversion/policy/canonical fallan cerrados sin avanzar cursor ni aceptar writes.
Los fixtures raw de migraciones antiguas se fijan a1 si hoy usan SaleDTO/SaleModel writers actuales.

Después de GREEN focal, estilo independiente y regresión del plan completo, builds Develop/Production con logs
completos. Previews de editor global, error, contenido mixto y readonly Large/XXX/AX5 ES/EN; smoke convivencia,
aplicar/retirar/cancelar/reabrir y añadir servicio con promoción. POST técnico/UI con FULLJSON tracked+untracked
antes/después idénticos. Repetir sólo el ámbito cambiado. No nuevos tests UI nativos.

## Pendientes para la conversación con Fran

Confirmar si los descuentos se acumulan y en qué orden; si hay servicios/productos excluidos del global; y si admite
100% o límites comerciales distintos. La demo usa V1 sobre todas las líneas, rangos Domain vigentes y redondeo Money.
No se presenta esto como política comercial ratificada. Los cambios posteriores se implementarán después de esa
conversación, conservando el cálculo de snapshots V1 existentes.

## Evidencia y límites iniciales

Exploraciones read-only independientes de Domain y Data confirman la ruta y el riesgo concreto de
FirestoreSaleWriteDTO forzando currentPayloadVersion. No ejecutaron Xcode ni probaron el nuevo tramo.
Baseline de línea: 595 archivos fuente/config, digest7b114f62…, 1263declaraciones/1999ejecuciones, builds/smoke/PRE/POST PASS.
Eso no prueba global. Git conserva24rutas locales sin stage y HEAD ea78dc6; no commit/push/PR/merge/cierre/11.8/live.
Schema3/31tablas permanece, y no se promete soporte entre writers viejos/nuevos ni downgrade después de guardar2.

PRE independiente `ios-standards-reviewer`: sin hallazgos P0–P3; ámbito, alternativas, fuentes y TDD adecuados.
Informe `/tmp/plu80-global-pre-report.md`. Root/reviewer before/after FULLJSON759 íntegramente iguales,
`2bff3d3833898cfd2c6d4f9b2c5599f6a2ac703897d614f5a8076ec55c230054`.
ADR0032 aceptado técnicamente dentro de la autorización local; ratificación comercial posterior pendiente.
InMemorySaleRepository queda con trabajador Domain como seam; el trabajador Data lo excluye.
Editor/fachada congelan Discount?; la política Domain construye el término V1, Store pasa el snapshot completo.
Sin código global previo al PRE; comienza PhaseA de tests/stubs, todavía sin evidencia RED/GREEN global.


PhaseA compilable: BuildForTesting13,713s PASS,0errores. RED real47declaraciones/99ejecuciones:
32declaraciones fallan56variantes,15pasan43,0skip/noejecutados/expected. Bundle nativo cerrado con Info.plist,
`RunSomeTests/Test-FranAlonso-Develop-2026.10.02_08-31-26-+0200.xcresult`; exports
`/tmp/plu80-global-red-native-summary.json` y `tests.json`. Fallos por cálculo global ausente, globalnil,
writer1/codec2 no soportado y destino global ausente; no errores de preparación del container.
Workers liberados para GREEN después de inspeccionar el RED funcional. Root completa sección global, destino/foco,
editor común y desgloses; el agregado ahora se etiqueta Descuento total/Total discounts.


GREEN local completo. Regresión final cerrada 1.310 declaraciones / 2.098 ejecuciones Passed, incluidas
47 / 99 nuevas; builds Develop/Production PASS. Estilo independiente corregido y retest PASS.
20 previews renderizadas e inspeccionadas, dos Loading sin atribuir contenido y sustituidas por Content cargado.
Smoke y POST técnico final PASS; POST UI pendiente. Dos recapturas Screen cargadas XXX/AX5 elevan la
muestra a22 renders, sin borrar las capturas Loading. Detalle y límites en phase-11.md; política comercial provisional.

POST UI final: P3 de recuperación global corregido con copy neutral ES/EN y retest independiente PASS para
demo ADR0029. Catálogo528/0 y nuevos builds Develop/Production PASS; sólo ese catálogo cambia respecto al
proof del RunAll, otras605rutas fuente/config intactas. Implementación local validada; integralPLU-81 y
ratificación comercial pendientes, sin entrega Git/cierre operativo/live. Evidencia final en phase-11.md.
