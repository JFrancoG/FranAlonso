# Fase 11 — Jornada y motor de ventas

## Objetivo

Construir la Jornada operativa y crear ventas con líneas snapshot, cliente opcional, descuentos, efectivo/tarjeta e IVA, preservando consistencia monetaria e idempotencia.

## Estado de presentación

Jornada es la pantalla principal autenticada y presenta las operaciones que aún requieren acción: servicios próximos, en curso o terminados pendientes de pago o documento. El Histórico es una sección distinta y presenta operaciones terminales cerradas o anuladas; las anuladas se diferencian visualmente y conservan toda su trazabilidad.

- `WorkdayViewModel` `@Observable @MainActor` como fachada del tablero, selección y navegación.
- `SaleDraftViewModel` `@Observable @MainActor` como fachada del detalle operativo.
- `SaleDraftStore` `@Observable @MainActor` como propietario del borrador y sus transiciones.
- El ViewModel instancia y conserva el Store con los casos de uso recibidos.
- El ViewModel expone propiedades calculadas o el Store observable; no copia líneas, totales o errores.
- Las reglas monetarias permanecen en `SaleCalculator` y casos de uso de Domain.

Solo se puede registrar el pago cuando todos los servicios han terminado y solo se puede solicitar el documento después del pago. Una operación pagada continúa en Jornada mientras no tenga ticket o factura emitido. Cuando el documento tiene número definitivo y PDF final, desaparece inmediatamente del tablero y pasa a Histórico. La subida o el correo pendientes no reabren Jornada.

## Subfases

Para la demo de [ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md), ejecutar esta fase después de09–10
y del adelanto textual de16. Usar la composición aislada de08.8a con datos sintéticos; pagos, snapshots y reglas reales.
El formulario de venta no depende de fotografía/detalle08.9. La venta completa de la demo incluye stock12 y documento
final/cierre13; registrar el pago no permite declarar cerrada la operación ni resuelta toda la demo.

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 11.1 | Integrar y completar el repositorio y los casos de uso de borrador sobre la vertical Data/sync base de 05.10c. | Crear, recuperar, editar y descartar sin duplicar infraestructura. | SwiftData es SoT local. |
| 11.2 | Completar `SaleCalculator`. | IVA, descuentos, redondeo, cero y límites. | `Decimal` y snapshots consistentes. |
| 11.3 | Implementar `SaleDraftStore`. | Añadir/quitar/cambiar cantidad, cliente y descuento. | Estado cohesivo y cancelación. |
| 11.4 | Implementar `WorkdayViewModel` y `SaleDraftViewModel`. | Próximo, en curso, pendiente de cierre, selección, navegación y composición del Store. | Fachadas separadas y sin estado duplicado. |
| 11.5 | Implementar Jornada y detalle operativo. | Lógica ya cubierta en Store/ViewModels. | Previews vacío, múltiples clientes, en curso y pendiente de cierre. |
| 11.6 | Integrar selector de servicios. | Snapshot congelado al añadir línea. | Cambios futuros del catálogo no alteran la línea. |
| 11.7 | Integrar descuentos. | Global, por línea, límites e incompatibilidades. | Política explícita y testeada. |
| 11.8 | Implementar `RegisterSalePaymentUseCase`. | Sin método, repetición, cancelación, fallo local y documento pendiente. | Payment ID estable; el pago no oculta la operación sin documento. |
| 11.9 | Implementar `SalesHistoryViewModel`, `SaleDetailViewModel`, Histórico y detalle. | Filtros, orden, navegación, error, cancelación, cierre y anulación compensatoria. | Operaciones `closed` y `voided`; anuladas diferenciadas y trazables; sección independiente de Jornada. |

## Resultado de fase

Estado operativo de11.1: [PLU-72](https://linear.app/plusprojects/issue/PLU-72), fase [PLU-71](https://linear.app/plusprojects/issue/PLU-71).
11.1 entregada: PLU-72 Done, [PR33](https://github.com/JFrancoG/FranAlonso/pull/33), merge `794478e`.
PRE/POST favorables; fuente validada `8cc3181` intacta. [Evidencia](../progress/phase-11.md).
11.2 entregada: [PLU-73](https://linear.app/plusprojects/issue/PLU-73) Done,
[PR34](https://github.com/JFrancoG/FranAlonso/pull/34), merge `ad5eeb5`, validado `5ac7f45`; rama eliminada.
[ADR 0031](../ADRs/0031-sale-decimal-coefficient-certification.md), TDD GREEN, builds y PRE/POST PASS.
11.3 entregada: [PLU-74](https://linear.app/plusprojects/issue/PLU-74) Done,
[PR35](https://github.com/JFrancoG/FranAlonso/pull/35), merge `d0a117e`, validado `16ba2c5`; rama eliminada.
1.840/1.840 variantes, builds Develop/Production y PRE/estilo/POST/entrega favorables.
11.4 entregada: [PLU-75](https://linear.app/plusprojects/issue/PLU-75) Done,
[PR36](https://github.com/JFrancoG/FranAlonso/pull/36), merge `d9d1ed1`, validado `08898f7`; rama eliminada.
[Propuesta](../progress/11-4-workday-viewmodels-proposal.md) PRE PASS.
TDD GREEN: 38 declaraciones/66 variantes nuevas, regresión 1.906/1.906; builds Develop/Production y estilo/POST PASS.
POST/entrega favorables y fuente intacta.
11.5 entregada funcionalmente: [PLU-76](https://linear.app/plusprojects/issue/PLU-76) Done, Jesus Franco;
[PR37](https://github.com/JFrancoG/FranAlonso/pull/37), merge `c01ff04`, validado `ad53cf2`; rama eliminada.
[Propuesta](../progress/11-5-workday-screens-proposal.md) con PRE PASS.
Jornada/detalle, factories y demo aislada;1.934 variantes y builds PASS. Previews/smoke y retest focal PASS; POST técnico/UI PASS para gate funcional ADR0029.
Deuda integral propia [PLU-77](https://linear.app/plusprojects/issue/PLU-77), Jesus Franco, antes de uso real.
Entrega/árbol integrado verificados;11.7–11.9 conservan sus gates y live sigue inactivo.
11.6 entregada funcionalmente: [PLU-78](https://linear.app/plusprojects/issue/PLU-78) Done, Jesus Franco;
[PR38](https://github.com/JFrancoG/FranAlonso/pull/38), merge `9f38731`, validado `fcb0a6e`; rama local/remota eliminada.
[Propuesta](../progress/11-6-service-selection-proposal.md) PRE PASS.
Selección activa10.7 con Store existente, captura inmutable y retry de la misma unidad/ID; sin schema/Data/stock/live.
1.245 declaraciones/1.959 ejecuciones PASS; builds y muestraLarge/XXX/AX5. Previews/smoke y POST técnico/UI PASS para gate funcional ADR0029;
Revisión de entrega PASS; árbol integrado y fuente586 idénticos. Deuda integral [PLU-79](https://linear.app/plusprojects/issue/PLU-79)
Backlog/Jesus Franco, tras feedback/estabilización y antes del primer candidato real.
11.7 entregada funcionalmente: [PLU-80](https://linear.app/plusprojects/issue/PLU-80), Done/Jesus Franco,
[PR39](https://github.com/JFrancoG/FranAlonso/pull/39), merge `073a180`, commit validado `08e7550`;
rama local/remota eliminada; [propuesta](../progress/11-7-sale-discounts-proposal.md).
Editor de línea local: PRE/estilo/POST técnico/UI PASS; 1.263 declaraciones/1.999 ejecuciones y builds Develop/Production.
Smoke corregido 9/9 PASS, incluido retest de primera apertura. Gate funcional parcial ADR0029;
deuda integral propia [PLU-81](https://linear.app/plusprojects/issue/PLU-81), Backlog/Jesus Franco,
tras feedback y estabilización del recorrido, antes del primer candidato real.
Dirección global provisional recibida: acumulable con promociones para demo, pendiente de ratificación por Fran.
[Propuesta global](../progress/11-7-global-discount-proposal.md)/[ADR0032](../ADRs/0032-provisional-global-sale-discount.md)
Global provisional entregado: PRE/estilo y 1.310 declaraciones/2.098 ejecuciones PASS; builds Develop/Production.
Smoke global y POST técnico/UI PASS para gate funcional demo ADR0029. Árbol integrado idéntico al commit validado;
ratificación comercial y accesibilidad integral PLU-81 pendientes. Fuente/config606 intacta; sin live.
11.8 entregada funcionalmente: [PLU-82](https://linear.app/plusprojects/issue/PLU-82) Done/Jesus Franco,
[PR40](https://github.com/JFrancoG/FranAlonso/pull/40), commit validado`fdbe120`, merge`f4d2f1f`;
árbol completo idéntico y rama local/remota eliminada. [Propuesta](../progress/11-8-sale-payment-proposal.md).
RegisterSalePaymentUseCase con aceptación local/replay recuperable;21declaraciones/34ejecuciones nuevas,
regresión1331declaraciones/2132ejecuciones nativas, builds y PRE/estilo/POST/entrega independientes PASS.
Sin nueva UI de cobro; la venta pagada permanece en Jornada hasta documento. Fuente/config610 intacta.
La fase11 y deuda77/79/81 siguen abiertas.11.9 iniciada por autorización independiente; sin activación live.
11.9 entregada funcionalmente: [PLU-83](https://linear.app/plusprojects/issue/PLU-83) Done/Jesus Franco,
[PR41](https://github.com/JFrancoG/FranAlonso/pull/41), commit validado`e13e468`, merge`ab70985`; rama eliminada.
Histórico/detail terminal read-only, filtros/orden/query, navegación/retry y trazas.
PRE/estilo,1353declaraciones/2180ejecuciones nativas, builds Develop/Production y smoke12/12PASS; POST técnico/UI funcional PASS.
[Matriz propia](../accessibility/evidence/11-9-sales-history.md)/[PLU-84](https://linear.app/plusprojects/issue/PLU-84)
Backlog/Jesus, tras feedback/estabilización antes del primer candidato real. Cierre/compensación12.8/13.12
conservan gates; muestras DEMO materializadas no acreditan esos flujos. Entrega Git verificada; fuente628 intacta, fase11/deuda84 abiertas.

Jornada local-first sin trabajo cerrado ocupando espacio, Histórico separado, snapshots monetarios inmutables, Store justificado y finalización idempotente.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
