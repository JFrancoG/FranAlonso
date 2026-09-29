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

## Contratos de presentación —09.3

Alcance autorizado el29/09/2026 y revisado independientemente:

- Lista y formulario usan fachadas @Observable @MainActor separadas; la lista observa snapshots locales y mantiene
  visibles los inactivos. Consulta derivada, vacío y sin coincidencias son estados distintos.
- Cada formulario tiene identidad de sesión distinta del ProductID estable; reintentos conservan identidad y un cierre
  antiguo no cierra una reapertura. La ausencia en edición bloquea escrituras; nunca se convierte en alta vacía.
- Guardar valida y captura el nombre antes de suspender. El contexto del caller es efímero según ADR0011; App comparte
  actor/señal y compone las mutaciones mediante el adaptador existente. Snapshot preview rechaza escritura explícitamente.
- Respuestas de cargas reemplazadas o sesiones cerradas no alteran presentación. Se excluyen mutaciones solapadas;
  cancelación previa no escribe y una aceptación durable sigue siendo éxito ante cancelación tardía.
- Desactivar se ofrece para un producto existente activo; inactive conserva edición y observación. Cerrar no deshace
  commits. Pantallas, textos, confirmaciones visuales y previews corresponden a09.4.

## Contratos de ajustes —09.5

[Propuesta aprobada](../progress/09-5-stock-adjustments-proposal.md) el29/09/2026 tras PRE PASS:

- Movimiento inmutable con ID y fecha explícitos, delta entero no cero, motivo normalizado obligatorio y referencia
  manual igual a su ID. Saldo cero/negativo permitido; se ajustan activos e inactivos sin modificar su estado.
- Ausente/tombstone/conflicto de producto bloquea movimientos nuevos. Retry del mismo ID/payload canónico devuelve
  el movimiento original antes de comprobar elegibilidad; cualquier diferencia de payload produce conflicto neutral.
- Cantidad derivada de movimientos mediante acumulación Int128 y conversión exacta a Int; sin total mutable en Product.
- Registro local versionado pendiente de sync, writer único y aceptación sin suspensión; sin CAS entre writers
  independientes ni atomicidad global con Product. Cancelación previa no acepta; cancelación tras commit mantiene éxito.
- Esquema3 aditivo conserva1/2, documentos y metadata; migración raw y segunda reapertura obligatorias antes de activarlo.
  Una fila StockMovement impide reclamar un almacén no vinculado según ADR0021.
- AppRuntime comparte el writer local. UI/contexto de09.6, mínimos09.7 y sync/venta12 conservan sus puertas propias.

## Subfases

### Alcance de pantallas — 09.4

Catálogo abre lista y formulario de productos sobre los ViewModels09.3. Activos e inactivos permanecen visibles/editables,
sin reactivación ni campos comerciales. Cancelar con cambios exige descarte explícito; la hoja no se cierra por gesto.
Desactivar requiere confirmación que explica el descarte del nombre no guardado. Estados de carga, vacío, búsqueda
sin coincidencias y error con retry forman parte del recorrido; textos localizados y previews0/250 con variantes accesibles.
La demo aislada existente incorpora dos productos sintéticos al arrancar y conserva su reset por proceso, sin live.
ADR0029 rige la evidencia progresiva de estas pantallas; PLU-54 conserva la validación integral restante.

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
