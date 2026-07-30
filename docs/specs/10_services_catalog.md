# Fase 10 — Catálogo comercial de servicios

## Objetivo

Gestionar todos los conceptos cobrables, incluidos los productos vendidos al público, sin mezclar catálogo comercial e inventario.

## Diseño

- `Service` contiene nombre comercial, tipo, `Money`, impuesto/descuento aplicable y estado.
- Un servicio de tipo producto requiere `linkedProductID`; un servicio profesional no lo admite.
- La lista de productos vinculables procede de un caso de uso de Domain y solo expone entidades activas.
- `ServiceListViewModel` y `ServiceFormViewModel` son fachadas simples. Un Store solo se extrae si el formulario acumula una responsabilidad independiente real.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 10.1 | Implementar contratos y casos de uso de Service. | CRUD, búsqueda, tipos y estado. | Reglas comerciales en Domain. |
| 10.2 | Integrar y completar la persistencia y sync de Service sobre la vertical base de 05.10b. | CRUD de 10.1, repetición, conflicto, tombstone y offline. | UI solo observa SwiftData; sin reimplementar la infraestructura base. |
| 10.3 | Implementar productos vinculables. | Solo activos, ausencia y producto eliminado. | Contrato entre features explícito. |
| 10.4 | Implementar ViewModels de lista y formulario. | Precio, descuento, tipo y vínculo obligatorio. | `@Observable @MainActor`. |
| 10.5 | Implementar lista y formulario adaptativos. | Lógica ya cubierta. | Previews profesional/producto/error. |
| 10.6 | Implementar selector de producto vinculado. | Selección, sustitución y vínculo inválido. | No guarda producto-service sin vínculo. |
| 10.7 | Implementar `ServicePickerViewModel` para ventas. | Búsqueda, filtros y snapshots. | No filtra tipos Data. |

## Resultado de fase

Catálogo comercial coherente, separado de inventario y listo para crear snapshots inmutables en ventas.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
