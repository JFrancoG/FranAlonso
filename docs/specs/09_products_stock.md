# Fase 09 — Productos e inventario físico

## Objetivo

Gestionar productos como inventario sin precios ni descuentos y registrar ajustes de stock auditables e idempotentes.

## Diseño

- `ProductRepository` y casos de uso viven en Domain; SwiftData/Firestore en Data.
- `Product` no contiene precio de compra, precio de venta o descuento.
- Cada ajuste crea un `StockMovement` con ID estable, motivo, cantidad, fecha y referencia de origen.
- Aplicar dos veces el mismo movimiento no cambia el stock dos veces.
- Listado y formulario comienzan con ViewModels simples; no se crea Store sin complejidad demostrada.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 09.1 | Implementar contratos y casos de uso de producto. | CRUD, búsqueda, desactivación y duplicados. | Product sin campos comerciales. |
| 09.2 | Implementar persistencia y sync de Product. | Repetición, conflicto, tombstone y offline. | UI solo observa SwiftData. |
| 09.3 | Implementar `ProductListViewModel` y `ProductFormViewModel`. | Carga, vacío, búsqueda, edición, error y cancelación. | Cada pantalla tiene su fachada; sin Store ceremonial. |
| 09.4 | Implementar lista y formulario. | Validaciones en Domain/ViewModels. | Previews con 0 y 250 productos. |
| 09.5 | Implementar `AdjustStockUseCase`. | Entrada, salida, cero, negativo e ID repetido. | Movimiento idempotente. |
| 09.6 | Implementar UI de ajuste. | Estado y acciones del ViewModel. | Motivo obligatorio y texto localizado. |
| 09.7 | Implementar `ObserveLowStockUseCase`. | Bajo, igual y sobre mínimo. | Resultado local y determinista. |

## Resultado de fase

Inventario físico sin información comercial, ajustes trazables y sincronización segura.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluido subagente `$review-ios-standards` y segunda auditoría.
