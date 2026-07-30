# ADR 0015 — Sync de Service, decimal exacto y núcleo compartido de retry

## Estado

Aceptado

## Contexto

El checkpoint Services de la subfase 05.10 debe replicar la vertical local-first publicada para
Clients y Products sin anticipar los flujos completos de la fase 10. El snapshot Domain de
`Service` contiene identidad, nombre, tipo, vínculo opcional a Product, precio, impuesto,
descuento opcional y estado. Su invariante exige un `linkedProductID` para un servicio de tipo
producto y lo prohíbe para un servicio profesional.

Firestore solo ofrece enteros de 64 bits y dobles IEEE-754 como tipos numéricos. En Firebase
12.16.0, el encoder Swift representa `Decimal` como `NSDecimalNumber`, mientras la frontera
Firestore convierte los `NSNumber` de coma flotante mediante `doubleValue`. Ese recorrido no
puede conservar todos los valores base diez aceptados por Foundation `Decimal`.

Clients y Products ya contienen, tras sustituir los nombres de feature, valores y cálculo puro
de retry idénticos. Sus contratos remotos, persistencia, clasificación de errores, políticas de
conflicto y motores siguen expresando responsabilidades específicas de cada colección.

La frecuencia baja de cambios manuales del catálogo Service es una hipótesis del MVP, no
evidencia operacional. Los namespaces nuevos continúan cerrados por Security Rules y ningún
SyncEngine está activo.

## Drivers

- Conservar exactamente precio, impuesto y descuento sin pasar por `Double`.
- Revalidar en Domain todos los valores y la relación entre tipo y Product vinculado.
- Replicar persistencia, causalidad, tombstones, cursor y retry sin mezclar campos en conflicto.
- Extraer únicamente la duplicación pura ya demostrada por Clients y Products.
- Mantener Firebase sustituible y bloquear cualquier tráfico live hasta una puerta separada.

## Opciones consideradas

### Números Firestore

Es la representación más directa, pero el camino `Decimal` → `NSDecimalNumber` → `doubleValue`
puede perder precisión y no satisface el contrato monetario base diez.

### Unidades menores enteras

Conservan de forma exacta las monedas actuales de dos decimales, pero no representan impuesto y
descuento con su precisión `Decimal` sin introducir además una escala nueva y todavía inexistente.

### Cadenas decimales canónicas

Conservan los dígitos base diez y permiten una validación cerrada, a costa de no ordenar ni
calcular esos valores como números desde Firestore. Ninguna consulta de este checkpoint necesita
ordenarlos o agregarlos remotamente.

### Duplicar por tercera vez todos los tipos de retry

Mantiene aislamiento nominal, pero ignora que los valores, invariantes y cálculo puro son ya
idénticos entre dos consumidores reales.

### Genericizar la vertical completa

Reduciría más líneas, pero ocultaría DTO, persistencia, errores, causalidad y conflictos que sí
dependen del snapshot y de las invariantes de cada colección.

### Descarga completa, timestamp o listener

La descarga completa se conserva como fallback si el contador no supera la puerta live. Un
timestamp requiere desempate y semántica durable adicional; un listener expone ciclo de vida y
estado de reanudación propios de Firestore.

## Decisión

Services implementa una vertical Data explícita con `ServiceDTO`, siete modelos SwiftData,
fuentes local y remota, Repository, política, cursor, tombstones, retry y `ServiceSyncEngine`.
El snapshot se compara completo y nunca mezcla automáticamente nombre, tipo, vínculo, precio,
impuesto, descuento o estado.

`ServiceDTO` mantiene DTO anidados específicos de Service. `ServiceDecimalDTO` es un wrapper
`Codable` de valor único cuya representación externa es una cadena. El encoder canónico usa
`Decimal.FormatStyle` con locale `en_US_POSIX`, agrupación desactivada y entre uno y treinta y
ocho dígitos significativos. La decodificación:

1. lee una cadena;
2. la parsea con el mismo estilo;
3. vuelve a formatear el resultado con el único encoder canónico;
4. exige igualdad byte a byte con la entrada.

Solo la salida canónica del formatter es válida. Se rechazan, entre otras, agrupadores,
exponentes, `+` inicial, espacios, ceros iniciales, ceros fraccionarios redundantes y `-0`.
`Money`, `TaxRate`, `Discount` y `Service` vuelven a ejecutar sus inicializadores validantes al
reconstruir Domain. Si la normalización de unidades menores de `Money` cambiara el importe
remoto, el mapping lo rechaza en vez de aceptar silenciosamente otro snapshot. Un identificador,
enum, decimal, porcentaje o vínculo inválido falla cerrado sin avanzar operación, revisión o
cursor.

`ServiceModel` aplana exclusivamente UUID, strings de enums y strings decimales canónicas. Los
otros seis modelos conservan upsert, delete, estado remoto, conflicto, cursor y retry de forma
separada. La compatibilidad inmediata abre un store creado con el esquema publicado de catorce
modelos Clients+Products mediante el nuevo esquema de veintiún modelos, preserva todos los datos
y metadatos existentes y comienza con las siete tablas Service vacías.

Se extraen a `Shared/Data/Sync` solo estos contratos neutrales ya duplicados:

- `SyncRetryScope`
- `SyncRetryCategory`
- `SyncErrorClassification`
- `SyncRetryState`
- `SyncTiming`
- `SyncBackoffPolicy`
- `SyncRetryPolicyError`

La clasificación de `ClientRemoteDataSourceError`, `ProductRemoteDataSourceError` y
`ServiceRemoteDataSourceError` permanece junto al error específico de cada feature. Cada
colección conserva su fila SwiftData, orquestación de tres intentos, callbacks de persistencia,
comprobaciones de cancelación y SyncEngine explícitos. No se genericizan Repository,
PersistenceActor, observación, DTO, motor ni política de conflictos. La extracción no cambia
identidades de almacenamiento, fórmula, categorías, presupuesto o semántica de Clients y
Products; sus suites existentes actúan como regresión. `SyncRetryScope` no incluye la colección
porque cada feature conserva su propia tabla de retry y nunca comparte una fila durable.

Cada mutación Service nueva reserva un `changeSequence` positivo en el mismo commit transaccional
que el documento. El contador independiente vive en
`<environment>/collections/syncMetadata/services`; los documentos viven en
`develop/collections/services` o `production/collections/services`. La secuencia solo ordena el
feed. La revisión por documento y el operation ID gobiernan idempotencia y conflictos.

Un tombstone vence a una edición ordinaria y una restauración exige una intención futura
explícita. La misma operation ID con igual payload es no-op; con payload diferente es conflicto.
Las ventas históricas quedan fuera y conservarán sus propios snapshots inmutables.

El vínculo Product se transporta y conserva, pero 05.10b no consulta Products para verificar que
exista o esté activo. Esa regla entre features pertenece a 10.3.

El motor Service se compone únicamente después del bootstrap Firebase y permanece inactivo.
Construirlo no realiza red y ningún caller invoca `synchronize()`. Este ADR no cambia Security
Rules, datos existentes ni tráfico Firestore.

## Puerta obligatoria antes de activar tráfico live

La activación Service exige otra propuesta y aprobación que documenten:

1. inventario completo de writers y actualización conjunta de documento y contador;
2. Rules compatibles y contract tests de emulador;
3. prueba controlada de contención/carga con límites explícitos;
4. resultado observado dentro de esos límites;
5. smoke test reversible en el entorno autorizado.

Si el contador no supera esa puerta, el fallback es un pull completo sin cursor incremental.
Cualquier otro feed requiere otro ADR.

## Consecuencias

### Positivas

- Los decimales conservan su representación exacta y se validan con un único contrato.
- Services obtiene convergencia, recuperación y compatibilidad sin activar red.
- La extracción de retry reduce duplicación probada sin esconder reglas de colección.
- La frontera Product–Service permanece en Domain y en la fase que la implementará.

### Negativas y riesgos

- Las cadenas decimales no permiten consultas numéricas directas en Firestore.
- La vertical conserva duplicación intencionada en motores, persistencia y conflictos.
- El contador puede sufrir contención y un writer que lo omita no aparecerá en el feed.
- Añadir siete modelos amplía un esquema ya publicado y exige prueba file-backed inmediata.

## Testing y validación

- Round trips exactos, locales distintos, límites de treinta y ocho dígitos y formas no canónicas.
- Rechazo del importe remoto cuando la normalización monetaria cambiaría su valor.
- Errores con coding path para payloads, enums, identificadores, rangos y vínculos inválidos.
- CRUD, pending chains, observación y aislamiento SwiftData con contenedores en memoria.
- Replay, conflicto de snapshot completo, tombstones, cursor, retry, reinicio y cancelación.
- Regresión de Clients y Products tras extraer el kernel de retry.
- Rutas exactas, identidad documental y plan atómico documento+contador con dobles deterministas.
- Composición de un motor Service inactivo sin llamadas remotas.
- Reapertura file-backed 14→21 con preservación total y tablas Service vacías.
- Suites focales y completa, build sin warnings y diagnósticos mediante Xcode MCP.

## Migración o reversibilidad

Los modelos Service comienzan vacíos al abrir el esquema publicado Clients+Products. Mientras el
motor permanezca inactivo, retirar adaptador y rutas no altera datos remotos. El formato decimal
se versiona dentro de las filas/payloads durables; cambiarlo exige compatibilidad explícita. El
adaptador Vapor puede conservar cadenas canónicas o convertirlas en su frontera sin cambiar
Domain. La extracción de retry puede revertirse por feature sin migrar sus filas, porque los
identificadores y valores persistidos no cambian.

## Relaciones

- Complementa ADR 0002, ADR 0006, ADR 0007, ADR 0012 y ADR 0013.
- Sustituye únicamente la decisión de ADR 0014 de conservar tipos y cálculo puro de retry
  duplicados por feature; el resto de ADR 0014 permanece vigente.
- Implementa el checkpoint Services de la subfase 05.10.
- No autoriza Sales, validación Product–Service de 10.3 ni activación live.

## Referencias

- [Firestore supported data types](https://firebase.google.com/docs/firestore/manage-data/data-types)
- [Swift Codable mapping for Firestore](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping)
- [Firebase 12.16.0 Decimal encoder](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/FirebaseSharedSwift/Sources/third_party/FirebaseDataEncoder/FirebaseDataEncoder.swift)
- [Firebase 12.16.0 NSNumber conversion](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/Firestore/Source/API/FSTUserDataReader.mm)
- [Decimal.FormatStyle](https://developer.apple.com/documentation/foundation/decimal/formatstyle)
- [NSDecimalMaxSize](https://developer.apple.com/documentation/foundation/nsdecimalmaxsize)
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Transaction contention](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Query cursors](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [SwiftData ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
