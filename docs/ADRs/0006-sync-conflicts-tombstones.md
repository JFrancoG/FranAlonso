# ADR 0006 — Conflictos, revisiones y tombstones

## Estado

Propuesto

## Contexto

La entrega remota puede repetirse, llegar fuera de orden o coincidir con ediciones de varios dispositivos. El reloj local no es una autoridad fiable y un borrado físico puede reaparecer desde un cliente atrasado.

## Opciones consideradas

1. Last-write-wins por `updatedAt` local: sencillo, sensible a relojes y orden.
2. Transacción para toda edición: consistente, costosa y poco offline-first.
3. Revisión remota monotónica, operación idempotente y política por colección.

## Decisión

Cada registro sincronizable mantiene ID estable, revisión remota, estado local, operation ID y tombstone. El servidor asigna la revisión/tiempo autoritativo. Una mutación declara la revisión sobre la que se creó; si la revisión remota ya avanzó, se aplica la política concreta siguiente. Los conflictos no resolubles conservan ambos snapshots y pasan a estado `conflict`; nunca se descarta silenciosamente la edición local.

### Política por colección del MVP

| Colección | Edición concurrente | Borrado frente a edición | Inmutabilidad/idempotencia |
|---|---|---|---|
| Clients | No auto-merge de campos de negocio; conservar local+remoto para resolución explícita. | Tombstone gana; restaurar exige operación explícita sobre revisión posterior. | Consentimiento/activación siguen ADR 0009. |
| Products | Conflicto explícito para metadatos. El stock no se resuelve editando el total. | Tombstone gana; restauración explícita. | Stock deriva de `StockMovement`. |
| Services | Conflicto explícito; no mezclar automáticamente precio, impuesto o vínculo. | Tombstone gana; ventas históricas conservan snapshots. | Repetir la misma operation ID es no-op. |
| Sales/SaleLines | Draft concurrente pasa a conflicto; una venta completada es inmutable. | Una venta completada no se borra: se anula mediante operación compensatoria. | Mismo completion ID con mismo payload es no-op; payload distinto es conflicto. |
| StockMovements | Append-only. Mismo ID y payload es no-op; payload distinto es conflicto. | No se borran; corregir mediante movimiento compensatorio. | ID estable derivado de origen cuando proceda. |
| BillingDocuments | Inmutable tras asignación remota. | No se borra ni renumera; corrección mediante flujo administrativo documentado. | ADR 0008 gobierna request ID y series. |

No se purgan tombstones automáticamente durante el MVP. Un ADR posterior definirá compactación solo cuando exista evidencia de que todos los participantes relevantes han observado el borrado.

### Flujo de resolución explícita

- Data persiste un registro local de conflicto con entity ID, revisión base, revisión remota vigente y snapshots local/remoto suficientes para decidir.
- Domain expone `ObserveSyncConflictsUseCase` y `ResolveSyncConflictUseCase` sin tipos SwiftData o Firebase.
- Presentation usa `SyncConflictsViewModel` `@Observable @MainActor` y `SyncConflictResolutionScreen` para elegir conservar local o remoto. No se implementa merge de campos en el MVP.
- Conservar remoto descarta la operación local pendiente y materializa la revisión seleccionada.
- Conservar local crea una operación nueva condicionada a la revisión remota observada. Si esa revisión volvió a cambiar, no sobrescribe: actualiza el conflicto y solicita otra resolución.
- Una entidad en conflicto permanece legible, muestra estado pendiente y bloquea únicamente nuevas ediciones de esa entidad hasta resolver; el resto de la colección sigue operativo.

## Consecuencias

- Reintentos y reordenamientos convergen sin duplicar o resucitar.
- Aumentan metadatos, casos de prueba y necesidad de compactación de tombstones.
- Algunos conflictos requieren intervención explícita y UI de resolución antes de volver a editar esa entidad.

## Testing y validación

- Dos dispositivos editando cada colección; borrado contra edición; operaciones compensatorias; payload diferente con mismo ID; elección local/remota; revisión que cambia durante la resolución; push/pull repetido; cursor atrasado; reinicio y reloj local incorrecto.

## Relaciones

- Complementa ADR 0002.
