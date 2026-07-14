# Fase 12 — Integración de venta y stock

## Objetivo

Advertir stock insuficiente sin bloquear y aplicar exactamente una vez el impacto de una venta cuando se registra su pago.

## Diseño

- `AnalyzeSaleStockImpactUseCase` calcula avisos antes de completar.
- `RegisterSalePaymentUseCase` orquesta el pago local y la creación de movimientos de stock mediante contratos de Domain.
- Cada movimiento derivado usa una clave estable basada en venta y línea; reintentar el mismo payment ID no duplica descuentos.
- La frontera local que marca la venta como pagada y registra movimientos debe ser atómica dentro de SwiftData.
- `SaleDraftStore` muestra avisos; `SaleDraftViewModel` coordina la confirmación desde el detalle de Jornada. No se crea otro Store para el mismo estado.
- El sync remoto replica venta y movimientos idempotentemente; no recalcula stock por observar dos veces la venta.
- Una anulación posterior usa un reversal ID estable y crea `StockMovement` compensatorios; no edita ni elimina los movimientos originales.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 12.1 | Implementar `AnalyzeSaleStockImpactUseCase`. | Stock suficiente, cero, negativo y líneas repetidas. | Resultado por línea, sin I/O. |
| 12.2 | Integrar avisos en `SaleDraftStore`. | Cambio de cantidad, eliminación y refresco. | Store no contiene la regla de negocio. |
| 12.3 | Implementar línea visual de advertencia. | Estado ya cubierto. | Rojo, accesibilidad y texto localizado. |
| 12.4 | Implementar confirmación no bloqueante. | Continuar, cancelar y repetir. | No registra eventos extra por mostrarla. |
| 12.5 | Implementar creación idempotente de `StockMovement`. | Payment ID repetido y múltiples líneas. | Exactamente un movimiento por línea. |
| 12.6 | Hacer atómico el pago local. | Fallo entre pago y movimientos. | Rollback o recuperación coherente. |
| 12.7 | Sincronizar movimientos y permitir stock negativo. | Push/pull repetido, conflicto y reinicio. | Sin doble descuento ni resurrección. |
| 12.8 | Compensar stock al anular una venta pagada. | Reversal repetido, múltiples líneas, fallo parcial y reinicio. | Movimientos inversos exactamente una vez; originales inmutables. |

## Resultado de fase

Pago, anulación y stock convergen de forma local y remota, con avisos no bloqueantes y movimientos iniciales/compensatorios idempotentes.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluido subagente `$review-ios-standards` y segunda auditoría.
