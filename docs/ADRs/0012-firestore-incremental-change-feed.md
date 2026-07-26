# ADR 0012 — Feed incremental ordenado para Firestore

## Estado

Aceptado

## Contexto

La sincronización de Clients necesita reanudarse tras un reinicio sin descargar siempre la
colección completa. La revisión monotónica de ADR 0006 pertenece a cada documento y decide
conflictos, pero no ordena cambios entre documentos distintos. Un cursor basado solo en esa
revisión puede omitir una edición posterior de un documento cuya revisión sea menor que la
del último documento observado.

Firestore no proporciona un cursor portable a un futuro adaptador Vapor. Además, `orderBy`
excluye documentos sin el campo ordenado y un cursor basado solo en timestamp puede ser
ambiguo cuando varias escrituras comparten el mismo valor. La colección Clients tiene un
volumen de escritura bajo durante el MVP.

## Drivers

- Reanudar pulls sin omitir cambios ni depender del ciclo de vida del proceso.
- Mantener la revisión por documento como única autoridad de conflicto.
- Conservar contratos Data neutrales respecto a Firestore y sustituibles por Vapor.
- Evitar que documentos legacy sin metadatos desaparezcan del bootstrap inicial.

## Opciones consideradas

### Descarga completa en cada sincronización

No necesita cursor, pero no completa 05.8 y su coste crece con toda la colección.

### Revisión por documento

Ya gobierna conflictos, pero no forma un orden total entre documentos. Una edición posterior
de un documento con revisión baja puede quedar detrás de un cursor derivado de otro documento.

### Timestamp remoto con desempate

Reduce la coordinación, pero exige un cursor compuesto y una semántica durable para valores
duplicados. También complica los documentos legacy que carecen del campo.

### Snapshot listener de Firestore

Entrega cambios en vivo, pero su estado de reanudación pertenece al proveedor y no constituye
el cursor durable y portable requerido por la aplicación.

### Secuencia monotónica por colección

Proporciona un orden total simple y portable a cambio de serializar las escrituras nuevas en
un documento contador compartido.

## Decisión

Cada escritura sincronizada nueva de Clients reserva un `changeSequence` positivo y
monotónico en el mismo transaction commit que crea o reemplaza el documento del cliente.
El contador vive en
`<environment>/collections/syncMetadata/clients`, donde `<environment>` es `develop` o
`production`. Un contador ausente representa cero; un valor negativo, malformado o igual a
`Int64.max` falla cerrado sin modificar el cliente.

`changeSequence` ordena exclusivamente el feed incremental. La revisión por documento y el
último operation ID de ADR 0006 continúan siendo la autoridad para precondiciones,
idempotencia y conflictos. Un replay ya aplicado o un conflicto no consume una secuencia.

El primer pull sin cursor realiza un bootstrap completo que incluye documentos legacy sin
`changeSequence`. Tras aplicar todo el lote y guardar su estado local, persiste como cursor el
mayor `changeSequence` válido observado, o cero si ninguno existe. Los pulls posteriores
consultan documentos cuyo `changeSequence` sea mayor que el cursor, ordenados de forma
ascendente. El lote remoto y el cursor se guardan en una sola frontera local; un error conserva
ambos en su estado anterior.

Todo writer sincronizado posterior al bootstrap debe usar la transacción de cliente y contador.
Los tombstones participan en el mismo feed y no se purgan durante el MVP. Antes de activar el
motor, Security Rules debe autorizar conjuntamente la escritura válida del cliente y del
contador; 05.8 mantiene ambos namespaces cerrados.

Cuando un tombstone remoto vence a un upsert local pendiente, el cliente deja de formar parte
de la colección activa para que el borrado sea efectivo. Su snapshot local completo permanece
durable y legible en `ClientSyncConflictModel`; esa es la entidad en conflicto conservada por
ADR 0006 y la futura restauración explícita podrá partir de ella sin resurrección automática.

## Consecuencias

### Positivas

- El cursor sobrevive reinicios y solo avanza después del commit local completo.
- Cambios vivos y tombstones comparten un orden total independiente del reloj del dispositivo.
- El contrato puede reproducirse en Vapor sin exponer tokens propios de Firestore.

### Negativas y riesgos

- El contador compartido puede limitar throughput por contención. Se acepta para el volumen
  bajo de Clients del MVP y se medirá antes de replicarlo a colecciones de mayor escritura.
- Una escritura que omita el contador no aparecerá en el feed incremental. El motor permanece
  inactivo hasta que todos los writers autorizados y las Rules respeten esta transacción.
- Los tombstones retenidos aumentan almacenamiento; una política de purga requiere otro ADR.

## Testing y validación

- Bootstrap con documentos legacy, cursor cero y lote incremental ordenado.
- Reinicio y replay sin duplicados ni avance prematuro del cursor.
- Fallo al aplicar un lote: materialización y cursor permanecen sin cambios.
- Contador ausente, negativo, malformado y desbordado.
- Escritura atómica de cliente o tombstone junto con contador.
- Conflicto y replay idempotente sin consumir una nueva secuencia.

## Migración o reversibilidad

El adaptador Vapor puede conservar la semántica del contador o sustituirla por un log
transaccional manteniendo el contrato de lotes y cursor. Una estrategia distinta de feed crea
otro ADR y migra el cursor durable; no cambia las revisiones por documento.

## Relaciones

- Complementa ADR 0002, ADR 0006 y ADR 0007.
- Implementa el cursor durable requerido por la subfase 05.8.

## Referencias

- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Transaction contention and serializability](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Order and limit data](https://firebase.google.com/docs/firestore/query-data/order-limit-data)
- [Query cursors](https://firebase.google.com/docs/firestore/query-data/query-cursors)
