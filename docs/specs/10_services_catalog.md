# Fase 10 — Catálogo comercial de servicios

## Objetivo

Gestionar todos los conceptos cobrables, incluidos los productos vendidos al público, sin mezclar catálogo comercial e inventario.

## Diseño

- [ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md): conserva la dependencia de09 y añade al
  perfil aislado de demo servicios sintéticos con vínculos coherentes a productos. La composición remota sigue inactiva.
- Tras la entrega funcional de10.1–10.7, el formulario manual permite el adelanto textual acotado de
  [spec16](16_on_device_voice_assistant.md). Es una propuesta editable de servicio profesional, no guardado automático.
  El adelanto requiere su implementación/evidencia propias; terminar catálogo no lo entrega implícitamente.

- `Service` contiene nombre comercial, tipo, `Money`, impuesto/descuento aplicable y estado.
- Un servicio de tipo producto requiere `linkedProductID`; un servicio profesional no lo admite.
- La lista de productos vinculables procede de un caso de uso de Domain y solo expone entidades activas.
- `ServiceListViewModel` y `ServiceFormViewModel` son fachadas simples. Un Store solo se extrae si el formulario acumula una responsabilidad independiente real.

## Contratos aprobados de10.1

- `ServiceProfile` es la entrada comercial editable, sin identidad ni estado. Recorta espacios exteriores del nombre y
  rechaza nombres vacíos. Su precio `Money` normalizado admite cero y rechaza negativos; conserva las monedas vigentes,
  precio con impuesto incluido, `TaxRate` validado y descuento opcional (ausente distinto de cero).
- Construcción y Codable validan la relación tipo/vínculo. Los snapshots `Service` históricos mantienen sus reglas
  previas; existencia y actividad del Product vinculado se validan en10.3.
- Alta con ID explícito nace activa y no reutiliza una identidad conocida. Se permiten nombres iguales con IDs distintos.
  Consulta devuelve activos/inactivos; ausentes y borrados devuelven nil. Edición conserva identidad y estado vigente.
- Desactivar conserva todos los campos y referencias. Repetir sobre inactive sin conflicto no escribe ni publica una
  nueva mutación, incluso después del ack. Borrados y conflictos impiden edición/desactivación; no hay restauración.
- Búsqueda local por nombre parcial, insensible a caja/diacríticos; query vacía devuelve el corpus en su orden, incluyendo
  ambos tipos y estados. Los filtros para venta pertenecen a10.7.
- La aceptación local mínima comparte comprobación y escritura sin suspensión entre actor y ruta contextual: snapshot y
  cola causal se guardan juntos, los fallos se traducen a Domain y no se descartan cambios ajenos. Cancelación previa no
  escribe; cancelación posterior al commit conserva éxito. No se promete CAS entre contextos independientes.
- 10.2 conserva la integración completa CRUD→sync, conflictos remotos, tombstones, offline y reapertura durable, sobre la
  vertical05.10b existente.10.1 no cambia schema, DTO, motor, composición live ni UI.

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
