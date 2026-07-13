# Fase 11 — Motor de ventas

## Objetivo

Crear ventas con líneas snapshot, cliente opcional, descuentos, efectivo/tarjeta e IVA, preservando consistencia monetaria e idempotencia.

## Estado de presentación

La nueva venta reúne edición de líneas, selección de cliente/servicios, descuentos, cálculo, pago y tareas asíncronas. Esa complejidad justifica:

- `NewSaleViewModel` `@Observable @MainActor` como fachada, navegación y presentación.
- `SaleDraftStore` `@Observable @MainActor` como propietario del borrador y sus transiciones.
- El ViewModel instancia y conserva el Store con los casos de uso recibidos.
- El ViewModel expone propiedades calculadas o el Store observable; no copia líneas, totales o errores.
- Las reglas monetarias permanecen en `SaleCalculator` y casos de uso de Domain.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 11.1 | Implementar repositorio y casos de uso de borrador. | Crear, recuperar, editar y descartar. | SwiftData es SoT local. |
| 11.2 | Completar `SaleCalculator`. | IVA, descuentos, redondeo, cero y límites. | `Decimal` y snapshots consistentes. |
| 11.3 | Implementar `SaleDraftStore`. | Añadir/quitar/cambiar cantidad, cliente y descuento. | Estado cohesivo y cancelación. |
| 11.4 | Implementar `NewSaleViewModel`. | Coordinación, navegación, confirmación y composición del Store. | Sin estado duplicado. |
| 11.5 | Implementar pantalla de nueva venta. | Lógica ya cubierta en Store/ViewModel. | Previews vacío, contenido y error. |
| 11.6 | Integrar selector de servicios. | Snapshot congelado al añadir línea. | Cambios futuros del catálogo no alteran la línea. |
| 11.7 | Integrar descuentos. | Global, por línea, límites e incompatibilidades. | Política explícita y testeada. |
| 11.8 | Implementar pago y `CompleteSaleUseCase`. | Sin método, repetición, cancelación y fallo local. | Completion ID estable e idempotente. |
| 11.9 | Implementar `SalesHistoryViewModel`, `SaleDetailViewModel`, histórico y detalle. | Filtros, orden, navegación, error, cancelación y venta incompleta/completa. | Cada pantalla tiene fachada y observa SwiftData mediante contratos. |

## Resultado de fase

Venta local-first con snapshots monetarios inmutables, Store justificado y finalización idempotente.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), con subagente `$review-ios-standards` y segunda auditoría.
