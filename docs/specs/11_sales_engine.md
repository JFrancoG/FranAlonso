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

Jornada local-first sin trabajo cerrado ocupando espacio, Histórico separado, snapshots monetarios inmutables, Store justificado y finalización idempotente.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
