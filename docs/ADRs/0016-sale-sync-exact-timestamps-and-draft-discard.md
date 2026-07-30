# ADR 0016 — Sync de Sale, timestamps exactos y descarte de borrador

## Estado

Aceptado

## Contexto

El checkpoint Sales de la subfase 05.10 debe persistir y replicar el agregado `Sale` ya
definido sin anticipar los flujos comerciales de las fases 11–13. Una venta conserva líneas
ordenadas con snapshots monetarios, cliente opcional y un estado que acumula metadatos de pago,
documento y reversión.

`Date` puede construirse con un intervalo no finito. Esos valores rompen el contrato total del
agregado: `Date(NaN)` no mantiene igualdad reflexiva y los encoders JSON no pueden serializarlo.
Además, Firestore representa timestamps con precisión de microsegundos, insuficiente para
preservar todos los valores binarios aceptados por Foundation `Date`.

ADR 0015 hizo que la representación decimal canónica perteneciera nominalmente a Services,
aunque su contrato es puro y Sales necesita exactamente la misma representación base diez.
El esquema publicado contiene veintiún modelos de Clients, Products y Services. Los motores de
las tres colecciones siguen compuestos pero inactivos y los namespaces nuevos continúan cerrados
por Security Rules.

## Drivers

- Preservar exactamente identidad, orden, decimales y fechas del agregado.
- Reejecutar siempre las fábricas y transiciones Domain al reconstruir una venta.
- Mantener SwiftData como fuente de verdad local con cambios causales y recuperables.
- Impedir que una venta pagada, cerrada o anulada pueda eliminarse como un borrador.
- Mantener Firestore sustituible e inactivo hasta una puerta live independiente.

## Opciones consideradas

### Timestamp nativo de Firestore

Es consultable y directo, pero redondea a microsegundos y puede alterar igualdad, idempotencia y
detección de conflictos.

### ISO-8601 o normalización del Domain a microsegundos

ISO-8601 añade una política textual que no garantiza el mismo valor binario. Normalizar el
Domain mutaría fechas finitas que hoy son válidas.

### Bit pattern hexadecimal del intervalo de referencia

Conserva exactamente el `Double` de `timeIntervalSinceReferenceDate`. Requiere validar forma
canónica y finitud, pero no impone una precisión inferior al Domain.

### Relaciones SwiftData para las líneas

Harían consultable cada línea, a costa de añadir identidad de persistencia y reglas de borrado
que el agregado no necesita. Un único blob para toda la venta, en cambio, impediría filtrar por
fecha o estado raíz.

### Mezcla por campos y borrado general

El merge automático puede formar una venta que ningún writer creó y debilita las transiciones.
Un borrado general destruiría trazabilidad comercial después del pago.

### Documento Firestore único con líneas anidadas

Conserva atomicidad y orden. Está limitado por tamaño e índices; por ello no puede activarse sin
medición, exención de índices para líneas y una puerta de contención.

## Decisión

### Invariante Domain

Toda fecha almacenada por `Sale` debe tener un `timeIntervalSinceReferenceDate` finito.
`SaleError.invalidTimestamp` se valida en `draft(createdAt:)`, `registerPayment(paidAt:)`,
`close(closedAt:)`, `void(voidedAt:)` y en la reconstrucción `Codable` de todos los metadatos.
La comprobación ocurre antes de mutar el estado.

### Transporte v1

`SaleDTO.payloadVersion` vale `1`. `SaleLineDTO` conserva el orden de las líneas, identificadores
como strings, cantidad como entero y enums mediante raw values estables. Dinero, impuesto y
descuento usan `CanonicalDecimalDTO`, un valor `Codable` single-value cuyo wire format sigue
siendo exactamente la cadena canónica definida por ADR 0015.

La implementación y los errores se mueven a
`Shared/Data/DTOs/CanonicalDecimalDTO.swift`. `ServiceDTO` adopta el nombre neutral sin alias
residual; su JSON v1 y sus strings SwiftData no cambian. Esta decisión sustituye únicamente la
propiedad y el nombre `ServiceDecimalDTO` fijados por ADR 0015.

`SaleTimestampDTO` codifica una cadena hexadecimal lowercase de dieciséis caracteres con el
`bitPattern` de `timeIntervalSinceReferenceDate`. Antes de codificar se normaliza `-0.0` a
`+0.0`. El decoder exige longitud, case, finitud, cero positivo y round trip canónico exactos.

`SaleStatusDTO` usa un objeto etiquetado por `kind`, nunca el formato sintetizado de un enum con
valores asociados ni una bolsa de opcionales:

- `draft`, `inProgress` y `awaitingPayment` no aceptan payload;
- `awaitingDocument` exige `payment { id, method, paidAt }`;
- `closed` exige `payment` y `document { id, closedAt }`;
- `voided` exige `payment`, `document` y `reversal { id, voidedAt }`.

Se rechazan claves adicionales, campos ausentes, kind desconocido y cualquier versión distinta
de uno. Cada blob durable pending, base, remoto o conflicto conserva su propia versión v1. Una
versión no soportada falla cerrada sin avanzar operación, revisión ni cursor.

La conversión a Domain construye líneas con `SaleLine.upcoming`, reproduce sus transiciones y
crea la venta con `Sale.draft`; después reproduce las transiciones de `Sale` hasta el status
transportado. Identificadores, decimales, fechas, líneas duplicadas o estados incoherentes
fallan con contexto de mapping preciso.

### SwiftData 21→28

El esquema añade exactamente siete modelos y preserva los veintiuno existentes:

1. `SaleModel`
2. `SalePendingUpsertModel`
3. `SalePendingDiscardModel`
4. `SaleRemoteStateModel`
5. `SaleSyncConflictModel`
6. `SaleSyncCursorModel`
7. `SaleSyncRetryModel`

`SaleModel` aplana identidad, cliente, creación, kind y metadatos de pago, documento y reversión
para consultas raíz. Guarda `linesPayloadVersion = 1` y `linesData` como el array ordenado
`[SaleLineDTO]` serializado con `Codable`, sin relaciones SwiftData. Una versión distinta falla
antes de reconstruir Domain.

La reapertura file-backed 21→28 debe conservar Clients, Products, Services y su metadata sin
cambios, y comenzar con las siete tablas Sales vacías.

### Causalidad, conflictos y descarte

La vertical mantiene fuentes local y remota, `SalePersistenceActor`, adaptador contextual
`MainActor`, observación, repositorios, registros remotos, política, retry durable y
`SaleSyncEngine` específicos. Solo reutiliza el decimal canónico y el kernel puro de retry.

El snapshot completo es la unidad de comparación; no hay auto-merge. La misma operation ID y el
mismo payload son no-op; la misma ID con otro payload es conflicto. Las mutaciones locales de una
venta forman una cadena causal ordenada y ramas concurrentes conservan ambos snapshots.

Después del pago, el contenido comercial y el método de pago son inmutables; únicamente pueden
anexarse metadatos permitidos por el ciclo de vida. El replay exacto es idempotente y metadata
distinta entra en conflicto.

Un tombstone interno representa solo el descarte de un borrador. La transacción remota debe leer
el documento y confirmar que continúa en `draft`; si ha progresado, falla cerrada y conserva el
conflicto. No se añade un `DeleteSaleUseCase` público en 05.10c. Las anulaciones son
compensatorias y nunca eliminan la venta original.

### Firestore y composición inactiva

Los documentos viven en `develop/collections/sales` o `production/collections/sales`; el
contador vive en `<environment>/collections/syncMetadata/sales`. Cada venta es un documento con
líneas anidadas, `payloadVersion = 1` y metadata causal. Documento y `changeSequence` se mutan en
una transacción. La secuencia ordena el feed; revisión, operation ID y predecesor gobiernan
idempotencia y conflicto. El bootstrap tolera documentos legacy sin secuencia y pulls
incrementales posteriores exigen una secuencia positiva mayor que el cursor durable.

`AppDependencies` expone los casos de uso Sales existentes y `AppRuntime` construye un único
motor después del bootstrap Firebase. Construirlo no accede a red y ningún caller invoca
`synchronize()`. Este ADR no cambia Rules, índices, datos ni tráfico live.

## Puerta obligatoria antes de activar tráfico live

La activación Sales exige otra propuesta y aprobación que documenten:

1. inventario completo de writers, Rules y contract tests;
2. prueba de contención y carga del contador con límites explícitos;
3. exención de indexado para `lines` y sus subcampos, leída de vuelta;
4. medición del documento y de sus entradas de índice con una venta máxima representativa;
5. smoke test reversible en el entorno autorizado.

Firestore limita un documento a 1 MiB, a 40.000 entradas de índice y a 8 MiB acumulados de
entradas. 05.10c no inventa un máximo de líneas. Si el documento no cabe con margen, la exención
no se demuestra o aparece una consulta remota sobre líneas, se revisará el almacenamiento antes
de activar. Si el contador no supera la puerta, el fallback es full pull sin cursor incremental.

## Consecuencias

### Positivas

- Sales conserva fechas y decimales exactos y revalida todas las invariantes Domain.
- La fuente local puede consultar fecha y estado sin romper atomicidad de las líneas.
- Conflictos y replays respetan el ciclo de vida comercial completo.
- Services conserva bytes y persistencia v1 mientras el decimal obtiene un propietario neutral.

### Negativas y riesgos

- El timestamp hexadecimal no permite consultas temporales directas en Firestore.
- Las líneas anidadas exigen controles de tamaño e índices antes de uso live.
- La vertical conserva duplicación intencionada para hacer explícitas sus políticas.
- Siete modelos adicionales amplían el esquema publicado y exigen migración inmediata.

## Testing y validación

- RED/GREEN para fechas finitas, precisión submicrosegundo, cero normalizado y formas inválidas.
- Round trips de todos los estados, líneas, identificadores y decimales con errores contextualizados.
- Fixtures Service v1 byte-exact, decode/re-encode, strings SwiftData y reapertura 21→28.
- CRUD, observación, aislamiento, versión de líneas, metadata plana y cadenas pending.
- Replay, ramas causales, conflicto completo y descarte exclusivo de borrador.
- Retry durable, reinicio, presupuesto, cancelación y recuperación tras interrupción.
- Rutas, shapes y plan atómico documento+contador con dobles deterministas.
- Composición inactiva sin llamadas remotas.
- Suites focales y completa, build sin warnings y diagnósticos mediante Xcode MCP.

## Migración o reversibilidad

Los siete modelos empiezan vacíos al abrir un store de veintiún modelos. Mientras el motor siga
inactivo, retirar adaptador y rutas no altera datos remotos. Los blobs y documentos están
versionados para que cualquier cambio futuro falle cerrado o añada una migración explícita.
`CanonicalDecimalDTO` puede volver a tener implementaciones por feature sin cambiar bytes. Un
backend Vapor puede conservar timestamp y decimal canónicos o convertirlos en su frontera sin
cambiar Domain.

## Relaciones

- Complementa ADR 0002, ADR 0006, ADR 0007, ADR 0012, ADR 0013 y ADR 0015.
- Sustituye únicamente la propiedad y nombre Service-owned del decimal en ADR 0015.
- Implementa el checkpoint Sales de 05.10 y aporta la base Data para 11.1.
- No autoriza CRUD/UI de fase 11, stock/pago de fase 12, facturación de fase 13, 05.11 ni tráfico live.

## Referencias

- [Apple Date](https://developer.apple.com/documentation/foundation/date)
- [Swift Double bitPattern](https://developer.apple.com/documentation/swift/double/bitpattern)
- [Firestore supported data types](https://firebase.google.com/docs/firestore/manage-data/data-types)
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Firestore transaction contention](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Firestore quotas](https://firebase.google.com/docs/firestore/quotas)
- [Firestore index overview](https://firebase.google.com/docs/firestore/query-data/index-overview)
- [Firestore best practices](https://firebase.google.com/docs/firestore/best-practices)
- [SwiftData ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
