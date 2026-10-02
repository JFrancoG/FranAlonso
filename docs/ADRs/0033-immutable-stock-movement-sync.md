# ADR 0033 — Sincronización de movimientos de stock inmutables

## Estado

Aceptado por el propietario el02/10/2026: «si, aprobado». Implementación12.7 autorizada; sin live.
Entrega Git12.7 autorizada posteriormente por «Commit, push y entrega».

## Contexto

12.6 acepta pago, operación causal Sale y consumos juntos en SwiftData. `StockMovementModel` conserva payloads
manualv1/salev2 y `isPendingSync`, pero no tiene fuente remota, conflictos, cursor ni retry. Products sincroniza
metadatos, nunca cantidades; Sales ya replica su snapshot sin producir eventos de stock al observarlo.
ADR0012/0014/0015/0016 no autorizan extender sus feeds a Stock. ADR0006 exige append-only y conflicto por payload
divergente; ADR0018 exige una versión nueva antes de ampliar la forma persistida3.0.0.

## Drivers

- Repetir push/pull y reiniciar sin duplicar consumos ni perder pendientes.
- Mantener originales y saldo negativo; no restaurar Products/Sales borrados ni recalcular consumos al descargar ventas.
- Comparar identidad y payload completo, con fechas exactas y contrato remoto reemplazable.
- Conservar conflictos y retry durables, sin tráfico live ni scheduler automático.

## Opciones consideradas

- **Sincronizar el total Product**: pierde trazabilidad y permite doble descuento; contradice ADR0006.
- **Derivar consumos al recibir Sale**: duplica responsabilidades y confunde snapshots históricos/replay con un pago nuevo.
- **Full pull en cada pasada**: evita el contador, pero crece con todo el ledger append-only; fallback si el gate live
  no valida contención del feed. No añade por sí mismo idempotencia ni resuelve conflictos.
- **Timestamp/listener**: introduce desempate o estado del proveedor; no reemplaza el progreso durable portable.
- **Feed propio y eventos inmutables**: mantiene el patrón del repositorio con política Stock específica y contador
  separado; el volumen Stock puede ser mayor que el catálogo y exige prueba operativa antes de activación.

## Decisión

### Transporte y aceptación remota

Crear una vertical Data específica de Stock con DTO, política pura, fuente remota, persistencia y `StockSyncEngine`.
Solo reutilizar el kernel de retry aceptado por ADR0015. No genericizar motores ni modificar Domain de Sale.
`StockMovementDTO` transporta UUIDs canónicos, delta entero firmado64bits, razón, fecha exacta y origen etiquetado
manual/sale. Reutilizar el contrato de bit pattern de `SaleTimestampDTO` sin cambiarlo ni moverlo en12.7;
este acoplamiento entre Features/Data está acotado a una representación ya probada. El DTO tiene versión propia1,
independiente de los blobs locales manualv1/salev2; reconstruye mediante el inicializador validante de StockMovement.
Payloads incompletos, versiones futuras, path/ID distintos o metadata inválida fallan cerrados.

El documento vive en `<environment>/collections/stockMovements/<movementID>` y conserva payload inmutable,
revision1, operationID igual a movementID y `changeSequence` positiva. Creación y contador propio
`<environment>/collections/syncMetadata/stockMovements` se guardan en una transacción. ID+payload equivalentes son
alreadyApplied sin escribir ni consumir secuencia; misma ID con payload distinto devuelve conflicto sin sobrescribir.
No hay update/delete ni tombstone Stock: las correcciones pertenecen a movimientos compensatorios12.8.
La ausencia remota no borra filas locales. Una ausencia no autoriza republicar un evento previamente reconocido
como remoto: el estado remoto durable conserva esa identidad y el ledger se retiene, sin resurrección automática.

### Pull, conflictos y fronteras locales

Bootstrap completo exige metadata válida: no existen documentos Stock legacy autorizados. El incremental consulta
secuencias mayores que el cursor. Validar IDs y secuencias únicas/coherentes y nextCursor igual al máximo observado
o al cursor anterior en lote vacío. Un lote, cursor y limpieza de retry se aceptan en un único save sin suspensión;
fallo/cancelación previa produce rollback. No avanzar cursor por una versión o metadata inválida.

Un evento equivalente ya local conserva bytes, no suma otra vez y permite reconocer el pendiente. Un evento nuevo
se agrega al ledger; un payload divergente conserva el original y un conflicto local/remoto durable, nunca lo mezcla.
El conflicto válido puede avanzar el cursor junto al registro de conflicto y bloquea únicamente el push de esa ID.
La ausencia de Product o un tombstone Product no elimina historia ni crea/restaura metadatos: el pull puede guardar
el evento para preservar el ledger; el lector de cantidad conserva su contrato actual de exigir Product presente.
Comprobar el historial y la suma final por Product con StockQuantityPolicy; admitir negativos, rechazar overflow
sin lote parcial. Reconocer un push exige payload completo y metadata equivalentes; nunca marcar limpio por ID sola.
Publicar Products solo después de cada aceptación local durable, también si un push posterior falla.

### Retry, composición y esquema

Una pasada explícita single-flight hace pull y luego push de pendientes no conflictivos; no almacena Task.
Usa scopes pull/operation(movementID), clasificación y presupuesto de tres intentos externos de ADR0013,
backoff/jitter del kernel compartido y cancelación cooperativa antes/después de I/O. Si el remoto aceptó y el caller
canceló antes del acknowledgement local, el movimiento sigue pendiente y el próximo replay reconoce el mismo evento.
Limpiar retry junto al acknowledgement/conflicto/lote, con rollback conjunto ante error local.
Sales y Stock convergen mediante motores independientes y pendientes durables; no prometer atomicidad remota entre
venta y ledger ni una única transacción entre colecciones. El motor Stock se compone después del bootstrap,
con el mismo writer/Products signal del runtime, pero ningún caller invoca synchronize automáticamente.

Añadir `StockRemoteStateModel`, `StockSyncConflictModel`, `StockSyncCursorModel` y `StockSyncRetryModel`.
`StockSyncSchema` versión4.0.0 conserva íntegra la forma3.0.0 y añade solo esas cuatro tablas vacías mediante
migración lightweight3→4. No cambia payloads/shape de StockMovementModel: solo métodos para transición pendiente.
Mantener orígenes1/2/3, etapas existentes y modelos históricos; activar Schema.franAlonso4 solo tras la matriz raw
file-backed de todos los orígenes soportados, segunda reapertura y preservación de datos/metadata/ledger pendientes.

## Consecuencias

Positivas: ledger portable e idempotente, conflictos explícitos, restart recuperable, negativos admitidos sin mezclar
metadatos Product con inventario. Negativas: cuatro tablas nuevas, mayor superficie de migración y un contador Stock
que puede ser hotspot. No se usa la tasa de cambios de Products como prueba del volumen Stock.
No se resuelve la discrepancia por UI en12.7: se conserva como conflicto durable para resolución explícita posterior;
los originales append-only no se reemplazan. No se adelanta el flujo de compensación12.8.

## Testing y validación

Swift Testing TDD: round trip manual/sale y precisión exacta; replay/conflicto y plan documental+contador;
pull/push repetidos/reordenados, saldo negativo, Product ausente/tombstone sin resurrección, overflow conjunto,
fallo de commit y callback tardío/cancelación, retry y conflictos tras reopen file-backed. Verificar convergencia de
Sale y eventos creados por12.6 sin recalcularlos. Migración raw1/2/3→4 conserva cada fila y vuelve a abrir estable.
Composición inactiva sin llamadas remotas; regresión Stock/pago/Product/Sales/sync/schema por Xcode MCP.
PRE/POST independientes, estilo, builds Develop/Production, native xcresult y gobernanza. UI/accesibilidad N/A.

## Migración o reversibilidad

No reset, reseed ni export/import automáticos. Antes de distribuir4, el adaptador inactivo puede retirarse sin tocar
datos remotos; tras distribuir4, se conserva esa forma en el plan y cualquier retirada necesita migración posterior.
Un adaptador Vapor puede mantener registros y feed sin exponer tipos Firestore a Domain.

## Gate live separado

No modificar/desplegar Rules/índices/datos ni iniciar tráfico. Antes de activación: inventario de writers,
Rules append-only y contract tests de emulador, medición Stock real de contención/latencia/presupuesto bajo el pico
esperado y margen, tamaño/indexado, límites operativos aprobados y smoke reversible. Si el contador no supera la
puerta, adoptar full pull mediante decisión previa a live; no activar silenciosamente una estrategia alternativa.

## Relaciones y fuentes

Complementa ADR0002/0006/0007/0013/0015/0016/0018; define un feed nuevo sin cambiar los feeds aceptados de otras
colecciones. Implementa12.7, sin12.8/UI/live/entrega Git/cierre integral accesible.
Fuentes oficiales leídas02/10/2026:
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions).
- [Ordering and field existence](https://firebase.google.com/docs/firestore/query-data/order-limit-data).
- [Transaction contention](https://firebase.google.com/docs/firestore/transaction-data-contention).
- API/contratos SwiftData de ADR0018 y timestamp exacto aceptado en ADR0016.
- [MigrationStage lightweight](https://developer.apple.com/documentation/swiftdata/migrationstage/lightweight(fromversion:toversion:)).
- [ModelContext rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()).
