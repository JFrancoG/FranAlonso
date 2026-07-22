# Fase 04 — Modelo de dominio

## Objetivo

Definir entidades, value objects, políticas, contratos y casos de uso puros, sin SwiftUI, UIKit, SwiftData o Firebase.

## Decisiones de modelado

- IDs estables y tipados cuando eviten mezclar entidades.
- Valores que crucen aislamiento como structs inmutables `Sendable`.
- `Money` basado en `Decimal` y moneda explícita; no `Double` para importes.
- `Money` normaliza al construir según las unidades menores de la moneda con
  redondeo decimal `.plain` y rechaza operaciones entre monedas distintas.
- `TaxRate` y `Discount` representan porcentajes decimales en el intervalo
  cerrado `0...100`; rechazan valores fuera del rango y no numéricos.
- Las cantidades validan sus rangos en la construcción cuando se introduzcan.
- `SaleLine` conserva snapshots de descripción, precio, descuento, impuesto y vínculo de producto para que cambios posteriores del catálogo no alteren ventas históricas.
- `SaleLineStatus` representa `upcoming`, `inProgress` y `completed`; `SaleStatus` expresa `draft`, `inProgress`, `awaitingPayment`, `awaitingDocument`, `closed` y `voided`.
- El pago congela el payload comercial; documento, cierre y anulación compensatoria son metadatos/transiciones posteriores que no reescriben líneas o importes.
- Estados finitos mediante enums con associated values, no combinaciones de booleanos.
- Errores de dominio tipados; Presentation es quien los convierte en texto localizado.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 04.1 | Crear `Money`, `TaxRate`, `Discount` e IDs. | Rangos, redondeo y monedas incompatibles. | Sin `Double` ni estado inválido. |
| 04.2 | Crear `Client`, `BillingAddress`, `Product` y `Service`. | `Product` sin precio; servicio producto exige `linkedProductID`. | Invariantes compilables y Sendable. |
| 04.3 | Crear `Sale`, `SaleLine`, `SaleLineStatus`, `SaleStatus` y `PaymentMethod`. | Estados de servicio, pago pendiente, documento pendiente, cierre, anulación y transiciones inválidas. | Jornada y cierre expresados sin booleanos combinados; payload pagado inmutable y snapshots históricos completos. |
| 04.4 | Crear `SaleCalculator`. | Subtotal, descuentos, base, IVA y total con redondeo. | Política determinista. |
| 04.5 | Crear `StockWarningPolicy` y `StockImpact`. | Stock suficiente, cero, negativo y múltiples líneas. | Avisa sin bloquear. |
| 04.6 | Crear `BillingDocument` y conceptos de secuencia. | Ticket/factura, estados pendientes y series independientes. | Toda operación cerrada tiene documento; sin detalle Firestore en Domain. |
| 04.7 | Crear `Appointment` y reglas mínimas. | Inicio/fin, cancelación y referencias. | Alcance demo explícito. |
| 04.8 | Definir contratos Repository y UseCases necesarios por feature. | Dobles de test por capacidad. | Protocolos pequeños, propiedad de Domain. |

## Resultado de fase

Dominio puro, expresivo, `Sendable` y cubierto con Swift Testing, sin tipos de infraestructura.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluido el subagente `$review-ios-standards` y la segunda auditoría.
