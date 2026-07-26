# ADR 0014 — Feed incremental y reintentos de Product

## Estado

Aceptado

## Contexto

La subfase 05.10 replica en Products la vertical local-first ya publicada para Clients. El
snapshot Product disponible en Domain contiene únicamente `id`, `name` y `status`; el stock se
deriva de futuros `StockMovement` y no forma parte de esta colección.

ADR 0012 acepta para Clients una secuencia monotónica por colección, pero advierte que el
documento contador compartido puede generar contención y exige medir antes de extenderlo a
colecciones de mayor escritura. ADR 0013 acepta reintentos durables para Clients, sin crear un
scheduler ni tareas con ciclo de vida propio.

La frecuencia baja de cambios manuales de metadatos Product es una hipótesis de diseño del MVP,
no una medición operativa. Los namespaces nuevos siguen denegados por Security Rules y ningún
motor de sincronización está activo.

## Drivers

- Replicar una vertical Product idempotente y recuperable sin anticipar StockMovement o Sales.
- Conservar un cursor portable y durable que no dependa del reloj del dispositivo.
- Mantener las políticas, modelos y motores específicos por colección hasta observar duplicación
  real entre Clients y Products.
- Impedir que una hipótesis de volumen autorice por sí sola tráfico live.
- Mantener Firebase sustituible por un futuro adaptador Vapor.

## Opciones consideradas

### Descarga completa en cada pasada

Evita el contador y su contención, pero su coste crece con toda la colección. Se conserva como
fallback si la evaluación previa a la activación no valida el contador.

### Timestamp remoto y desempate por ID

Reduce la coordinación en un documento compartido, pero introduce un cursor compuesto, depende
de semántica específica del proveedor y necesita una estrategia adicional para documentos
legacy sin el campo ordenado.

### Snapshot listener de Firestore

Entrega cambios en vivo, pero su token y ciclo de vida pertenecen al proveedor y no sustituyen
un cursor durable portable entre procesos ni al futuro backend Vapor.

### Secuencia monotónica propia de Products

Reproduce el contrato probado de Clients con un contador independiente. Simplifica el orden
total y la reanudación, pero serializa las mutaciones Product nuevas sobre un documento.

### Abstracción genérica para todas las colecciones

Reduciría duplicación aparente, pero todavía no existen dos implementaciones completas que
demuestren qué partes comparten realmente semántica. Además, Services y Sales necesitan
decisiones de feed y conflicto propias.

## Decisión

Products implementa una vertical explícita y específica con DTO, modelos SwiftData, fuentes
local y remota, Repository, política, reintentos y `ProductSyncEngine`. No se crea un motor,
repositorio, persistencia o mecanismo de reintento genérico durante este checkpoint.

Cada mutación remota nueva de metadatos Product reserva un `changeSequence` positivo en el mismo
commit transaccional que el documento Product. El contador independiente vive en
`<environment>/collections/syncMetadata/products`. `changeSequence` ordena solamente el feed;
la revisión por documento y el operation ID continúan gobernando precondiciones, conflictos e
idempotencia según ADR 0006 y ADR 0012.

El alcance remoto contiene exclusivamente `id`, `name` y `status`. `StockMovement`, inventario
derivado, Services y Sales quedan excluidos. Los tombstones participan en el feed y vencen a un
upsert ordinario; su restauración requerirá una intención futura explícita.

Products replica la clasificación, el presupuesto y el backoff durable de ADR 0013 mediante
tipos propios. Cada unidad conserva su operation ID, no crea ni almacena `Task` y permanece bajo
la llamada estructurada a `synchronize()`.

`FirestoreCollection` modela solamente los consumidores existentes `.clients` y `.products`.
`FirestoreEnvironment` construye la ruta de colección y la ruta documental de metadatos. Los
casos Services y Sales se añadirán únicamente cuando existan sus adaptadores y decisiones.

El motor Product puede componerse después de confirmar el bootstrap Firebase, pero permanece
inactivo. Su construcción no lee ni escribe red. No se modifican Security Rules en 05.10a.

## Puerta obligatoria antes de activar tráfico live

La activación Product requiere una propuesta y aprobación posteriores que documenten:

1. Todos los writers autorizados y que cada uno actualiza documento y contador conjuntamente.
2. Rules compatibles y contract tests de emulador para la escritura atómica.
3. Una prueba controlada con el pico esperado y un margen explícito, registrando contención,
   reintentos agotados y latencia de transacción.
4. Los límites operativos aceptados para esas métricas y el resultado observado.
5. Un smoke test reversible en el entorno autorizado, sin usar datos manuales desconocidos.

Si la prueba muestra contención significativa o agota el presupuesto aceptado, el contador no
se activa. El fallback es mantener un pull completo sin cursor incremental; adoptar un log
distribuido u otra estrategia requiere un ADR nuevo.

## Consecuencias

### Positivas

- Products puede probar localmente reanudación, idempotencia, tombstones y retry sin tráfico.
- El contador, cursor y retry de Product quedan aislados de Clients y de colecciones futuras.
- La ausencia de abstracción genérica mantiene visibles las diferencias reales entre políticas.
- La activación live no puede inferirse de que el código y los tests locales existan.

### Negativas y riesgos

- Se duplica intencionadamente estructura ya presente en Clients.
- El contador podría ser un hotspot; todavía no existe evidencia operacional que lo descarte.
- Un writer que omita el contador no aparece en el feed incremental.
- Cada modelo nuevo amplía el esquema SwiftData y exige compatibilidad inmediata comprobada.

## Testing y validación

- Conversión Product válida, inválida y round trip mediante `Codable`.
- Escritura local-first con operación pendiente durable y observación posterior al commit.
- Replay, conflicto, tombstone, cursor, reinicio y retry específicos de Products.
- Contador ausente, negativo, malformado y agotado; documento y contador en un único plan.
- Rutas exactas para Develop y Production sin selección implícita.
- Cancelación antes y después de I/O remoto, sin espera ni aleatoriedad real en tests.
- Composición del motor inactivo sin acceso de red.
- Reapertura file-backed del esquema exacto 05.9 con el esquema Products, preservando datos y
  metadatos Clients.

## Migración o reversibilidad

Los modelos Product comienzan vacíos al abrir un store 05.9. La compatibilidad se verifica antes
de publicar el esquema ampliado. Mientras el motor esté inactivo, retirar el adaptador y sus
rutas no altera datos remotos. Cambiar el feed antes de su activación conserva la posibilidad de
un bootstrap completo; después de activarlo exigirá otro ADR y una migración explícita del
cursor.

## Relaciones

- Complementa ADR 0002, ADR 0006, ADR 0007, ADR 0012 y ADR 0013.
- Implementa el checkpoint Products de la subfase 05.10.
- No autoriza Services, Sales, StockMovement ni activación live.

## Referencias

- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Transaction contention](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Query cursors](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [Order and limit data](https://firebase.google.com/docs/firestore/query-data/order-limit-data)
- [Understand reads and writes at scale](https://firebase.google.com/docs/firestore/understand-reads-writes-scale)
