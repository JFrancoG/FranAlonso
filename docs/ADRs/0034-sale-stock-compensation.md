# ADR 0034 — Compensación de stock al anular una venta

## Estado

Aceptado por el propietario el03/10/2026: «si, aprobada». Implementación/validación12.8 autorizadas. Entrega Git autorizada03/10 por «commit, push y entrega»; sin live.

## Contexto

La spec12.8 exige movimientos inversos idempotentes y originales inmutables. `Sale.void` admite únicamente
closed→voided y replay exacto de reversal ID/fecha; no existe todavía aceptación de repositorio para esta transición.
ADR0033 fija transporte Stockv1 manual/sale, mientras StockMovementModel guarda manualv1 y consumov2.
Usar un ajuste manual perdería la relación verificable con pago, línea y consumo; ampliar v1 silenciosamente rompería
el contrato cerrado. La forma SwiftData4.0.0 puede conservarse: el cambio pertenece al payload Codable existente.

## Opciones y decisión aceptada

- Reescribir/eliminar el consumo o subir un total: contradice ADR0006 y pierde historia.
- Movimiento manual con razón textual: no permite validar la referencia compensada ni distinguir el replay.
- Anular y después agregar movimientos secuenciales: deja estados parciales durables tras fallo.
- **Origen compensatorio explícito y aceptación local conjunta**: añade un contrato verificable y reutiliza la
  frontera de staging/save de12.6 y el feed inmutable de12.7.

### Identidad, ciclo de vida y original

Añadir origen `saleReversal(saleID, lineID, paymentID, reversalID, originalMovementID)`. Un evento conserva Product,
unidades inversas positivas, razón estable `sale-reversal` y fecha efectiva voidedAt. La política pura usa los
snapshots capturados y exige el pago/reversal retenidos por Sale; no consulta precios ni catálogo actual.

Publicar una namespace distinta: UTF-8 `FranAlonso.sale-stock-reversal.v1`, NUL, UUID venta lowercase, NUL,
UUID línea lowercase. SHA256, primeros16bytes, versión8/varianteRFC10 como12.5. Una sola identidad compensatoria
por consumo original: reversalID pertenece al payload conflict-relevant, nunca a la derivación de la ID. Dos writers
offline con reversals diferentes compiten por la misma ID y generan conflicto, nunca dos restituciones sumables.
El origen referencia la ID original de saleConsumption; la construcción/decodificación compensatoria exige delta
positivo, ID derivada y referencia original coherentes. Nunca cambia la namespace/layout de consumos existentes.
El payload completo detecta divergencias y colisiones; UUIDv8 por sí solo no garantiza unicidad.

`VoidSaleUseCase` acepta expected Sale, reversal ID estable y fecha explícita vía `SaleRepository.voidSale`.
La primera aceptación exige snapshot completo actual igual al esperado y estado closed. Un replay permite la copia
closed previa o la misma voided, comparando íntegramente negocio, pago y cierre; exige reversal ID/fecha idénticos.
Draft/inProgress/awaitingPayment/awaitingDocument permanecen rechazados, sin ampliar Sale.void.

Antes de la mutación se exige cada consumo original local, equivalente al payload canónico de12.5, sin conflicto
Stock pendiente. Un original ausente/divergente/corrupto bloquea la anulación sin inventarlo ni repararlo.
La compensación nueva depende de ese historial, no de la elegibilidad actual del Product: admitir Product ausente,
inactivo o con conflicto de metadatos no lo restaura. Validar historial y saldo final con StockQuantityPolicy,
incluidos negativos y overflow; un conflicto de la ID compensatoria también bloquea la aceptación.

### Aceptación y recuperación

Una única primitiva SaleLocalDataSource sirve a SalePersistenceActor/DefaultSaleRepository y al adaptador contextual
MainActor. Contexto limpio antes de rollback, sin suspensión entre validación/staging/save, autosave desactivado y
restaurado; Sale voided, causal upsert y todas las compensaciones se guardan juntos una vez. Fallo/cancelación previa
revierte lo propio; cancelación posterior a commit no deshace aceptación. Publicar señales Sales/Products tras éxito.

Replay exacto no reescribe Sale, consumo original ni cola causal. Puede completar solo compensaciones faltantes de
una anulación histórica/prefijo, exigiendo todos los originales correctos y validando el lote antes del único save.
No marca reconocidos eventos pendientes, no barre historia automáticamente y no garantiza CAS entre contextos.

### Compatibilidad local y remota

StockMovementModel admite payload local3 únicamente para saleReversal; manual1 y consumo2 conservan formato y bytes.
No cambia propiedades/tablas, Schema4 ni etapas/orígenes del plan; probar reapertura real del ledger mixto.
Transporte StockMovementDTO conserva **v1 para manual/sale** y usa **v2 exclusivamente para saleReversal**;
rechazar cruces versión/origen, claves extra, referencias inválidas y versiones futuras. Mantener los registros
durables remotos/conflicto actuales, que contienen el DTO con su versión, sin recodificar los históricos.

El adaptador y StockSyncEngine existentes replican estos nuevos eventos con la misma transacción create+contador,
revision1, operationID=movementID, replay/conflicto completo y retry durable. No cambia SaleDTOv1 ni genera stock al
descargar Sale. Sale y Stock convergen independientemente: un receptor puede observar compensación antes que consumo
o snapshot Sale; conservar el evento validado sin inventar dependencias, permitiendo saldos transitorios negativos.
La aceptación remota de Stock sigue validando payload/metadata, no la existencia remota del consumo en otra llamada.
No se promete atomicidad remota entre colecciones ni orden global entre sus feeds.

## Consecuencias, límites y reversibilidad

La anulación de12.8 acredita su efecto Stock y conserva metadata comercial/reversal para el ajuste financiero trazable
de ADR0006; no acredita devolución monetaria, corrección fiscal ni cancelación integral de un BillingDocument.
No añadir UI/Store/VM, nuevas dependencias, unsafe, telemetría de payloads, Rules/índices, scheduler o activación live.
Ambos motores permanecen inactivos. Antes de live: además del gate0033, verificar inventario de writers y que todos
los lectores admiten v2; un lector antiguo falla cerrado, sin avanzar cursor por un evento desconocido.

El coste es un origen nuevo y compatibilidad adicional. Una vez escritos payloads3/v2, retirar su lector dejaría
historia ilegible: conservarlo y compensar mediante eventos posteriores, nunca downgrade/reset o reescritura.
La ausencia del original exige recuperación explícita o sincronización antes de reintentar, sin barrido automático.

## Testing y fuentes

Swift Testing TDD: ID literal independiente/namespace estable, múltiples líneas y Product repetido, servicios sin
stock, replay/metadata divergente, original ausente/corrupto/conflictivo, Product desaparecido, overflow conjunto,
fallo staged antes de save, contexto sucio, cancelación y señales; file-backed tras fallo/éxito y segunda reapertura.
Fixtures Codable v1/v2/local1/2/3, datos históricos intactos, versiones/orígenes erróneos; push/pull/reordenación,
replay/conflicto/retry/reinicio, sin doble restitución ni consumo recalculado. Dos dispositivos desde el mismo Sale.closed
con reversals distintos, entrega reordenada y reinicio: una ID compensatoria, un único +q remoto, conflicto durable
del payload divergente y ningún cambio al -q original. Builds/logs/resultados por Xcode MCP.

Complementa ADR0006/0011/0016/0018; sustituye únicamente el conjunto cerrado de orígenes/versiones de Stock en0033.
Fuentes primarias consultadas02/10/2026; docs Apple completas vía Cupertino (corpus mayo2026) y API existente:
- [ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext),
  [save](https://developer.apple.com/documentation/swiftdata/modelcontext/save()) y
  [rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()).
- [RFC9562, UUIDv8 y SHA256](https://www.rfc-editor.org/rfc/rfc9562.html#section-5.8).
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions).
Las garantías file-backed y de replay necesitan pruebas del proyecto; estas fuentes no acreditan implementación12.8.
