# Fase 09 — Productos e inventario físico

## Objetivo

Gestionar productos como inventario sin precios ni descuentos y registrar ajustes de stock auditables e idempotentes.

## Diseño

- [ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md): iniciar tras la entrega funcional de08.8a
  y08.8, sin esperar fotografía08.9 ni cierre integral de fase08. Cada subfase conserva su propia puerta de inicio.
- Incorporar escenarios sintéticos de producto/stock al perfil de demo mantenido en spec08 cuando estén implementados
  estos flujos. No reactivar motores live ni cambiar las fixtures de autenticación vacías; el seed no prueba sync real.

- `ProductRepository` y casos de uso viven en Domain; SwiftData/Firestore en Data.
- `Product` no contiene precio de compra, precio de venta o descuento.
- Cada ajuste crea un `StockMovement` con ID estable, motivo, cantidad, fecha y referencia de origen.
- Aplicar dos veces el mismo movimiento no cambia el stock dos veces.
- Listado y formulario comienzan con ViewModels simples; no se crea Store sin complejidad demostrada.

## Contratos de producto — 09.1

Alcance concreto aprobado el29/09/2026 tras revisión independiente:

- Entrada editable de nombre no vacío, recortando whitespace exterior también al decodificar; conservar grafía y espacios
  interiores. Product/DTO históricos no se endurecen retroactivamente por esta entrada nueva.
- Alta activa con identidad explícita nueva. Duplicados por ProductID; nombres iguales con IDs distintos permitidos.
- Lectura y gestión incluyen activos e inactivos; ausente o tombstone devuelve ausencia. Edición cambia solo nombre y
  preserva identidad/estado vigentes, sin crear ausentes ni restaurar tombstones; conflictos bloquean mutaciones.
- Desactivar pasa a inactive conservando ficha y referencias. Repetir sobre inactive no escribe ni crea operación;
  desconocido falla. Borrado técnico/tombstone, restauración y reactivación son flujos distintos, fuera de09.1.
- Búsqueda local parcial por nombre, insensible a caja/diacríticos, conserva orden e inactivos; query vacía devuelve todos.
- Aceptación local mínima reutiliza una primitiva Data sin suspensión para comprobar/mutar; actor y adaptador contextual
  comparten esa ruta y publican después del commit. Cancelación previa impide aceptar; la tardía no oculta un commit.
- Errores Domain neutrales; sin tipos/payloads del proveedor.09.2 mantiene la integración y regresión completa de sync;
  no se promete compare-and-swap entre contextos ni se añade esquema o infraestructura nueva.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 09.1 | Implementar contratos y casos de uso de producto. | CRUD, búsqueda, desactivación y duplicados. | Product sin campos comerciales. |
| 09.2 | Integrar y completar la persistencia y sync de Product sobre la vertical base de 05.10. | CRUD de 09.1, repetición, conflicto, tombstone y offline. | UI solo observa SwiftData; sin reimplementar la infraestructura base. |
| 09.3 | Implementar `ProductListViewModel` y `ProductFormViewModel`. | Carga, vacío, búsqueda, edición, error y cancelación. | Cada pantalla tiene su fachada; sin Store ceremonial. |
| 09.4 | Implementar lista y formulario. | Validaciones en Domain/ViewModels. | Previews con 0 y 250 productos. |
| 09.5 | Implementar `AdjustStockUseCase`. | Entrada, salida, cero, negativo e ID repetido. | Movimiento idempotente. |
| 09.6 | Implementar UI de ajuste. | Estado y acciones del ViewModel. | Motivo obligatorio y texto localizado. |
| 09.7 | Implementar `ObserveLowStockUseCase`. | Bajo, igual y sobre mínimo. | Resultado local y determinista. |

## Resultado de fase

Inventario físico sin información comercial, ajustes trazables y sincronización segura.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
