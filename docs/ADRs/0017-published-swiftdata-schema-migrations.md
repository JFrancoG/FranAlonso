# ADR 0017 — Migraciones de todos los esquemas SwiftData publicados

## Estado

Sustituido por ADR 0018

## Contexto

La rama remota activa de fase 05 ha publicado ocho formas distintas del esquema SwiftData
durante el desarrollo. No son releases distribuidas en App Store, pero un checkout ejecutado en
cualquiera de esos checkpoints pudo crear un store local que debe seguir abriendo sin perder
datos de negocio ni metadata de sincronización.

Hasta 05.10c, cada ampliación inmediata se comprobó reabriendo el esquema anterior con el
nuevo, pero la aplicación todavía deja que SwiftData infiera la migración y no declara el orden
completo. Apple indica que cada esquema previamente publicado debe capturarse como
`VersionedSchema`, que el orden total pertenece a un `SchemaMigrationPlan` y que el
`ModelContainer` debe construirse con el esquema actual y ese plan.

La única forma persistida de un tipo existente que cambió en estos checkpoints es
`ClientPendingUpsertModel` entre 05.6 y 05.7. En 05.6, `clientID` y `operationID` eran únicos y
solo se persistían `payloadVersion` y `payloadData`. Desde 05.7, solo `operationID` sigue siendo
único y se añaden `predecessorOperationID`, `baseVersion` y `baseData` opcionales. La retirada de
la unicidad de `clientID` no está documentada expresamente por Apple como migración ligera.

## Drivers

- Abrir cada store publicado de fase 05 con el esquema actual sin pérdida ni reset.
- Expresar un orden total estable y verificable para las migraciones futuras.
- Probar la adopción retroactiva del plan tanto sobre esquemas antiguos sin versionar como
  sobre un store raw que ya contiene los veintiocho modelos actuales.
- Conservar el fallo cerrado existente ante un esquema desconocido o una migración imposible.
- Evitar una prueba circular que cree los stores de origen con los mismos `VersionedSchema`
  cuya compatibilidad pretende demostrar.

## Opciones consideradas

### Mantener la inferencia con un plan nulo

Ha funcionado para las ampliaciones inmediatas, pero no declara el historial completo ni
demuestra que una instalación creada en cualquiera de los ocho checkpoints pueda llegar al
esquema actual.

### Declarar únicamente los veintiocho modelos actuales como primera versión

Permite versionar el futuro, pero no reconoce ni valida explícitamente los stores publicados
antes de 05.10c y no satisface la matriz de 05.11.

### Exportar, importar, resetear o reseedear el store

Podría ocultar incompatibilidades a costa de una ruta destructiva y de transformaciones que no
son necesarias ni están autorizadas. También perdería la garantía de preservar metadata local.

### Versiones ordenadas con etapas ligeras sometidas a pruebas raw

Hace explícito cada checkpoint y usa la migración nativa mínima. La elegibilidad de cada etapa,
incluida la retirada de unicidad, se trata como hipótesis que debe demostrar la matriz y no como
una garantía previa.

## Decisión

Se definen ocho `VersionedSchema` en este orden:

| Checkpoint | Versión | Modelos | Cambio acumulado |
|---|---:|---:|---|
| 05.2 | `5.2.0` | 1 | `ClientModel` |
| 05.6 | `5.6.0` | 2 | pending upsert legacy |
| 05.7 | `5.7.0` | 4 | cadena causal, estado remoto y conflicto |
| 05.8 | `5.8.0` | 6 | pending delete y cursor |
| 05.9 | `5.9.0` | 7 | retry durable |
| 05.10a | `5.10.1` | 14 | Products |
| 05.10b | `5.10.2` | 21 | Services |
| 05.10c | `5.10.3` | 28 | Sales |

Las versiones reutilizan los tipos actuales cuando su forma persistida no cambió. El esquema
05.6 declara su propia forma histórica exacta de `ClientPendingUpsertModel`; las versiones
posteriores usan el tipo actual. Los `enum` sin casos que conforman a `VersionedSchema` y
`SchemaMigrationPlan` modelan contratos sin valores instanciables, no namespaces de miembros
estáticos.

`PhaseFiveSchemaMigrationPlan` contiene las ocho versiones y siete etapas consecutivas
`.lightweight`. Cada etapa es una hipótesis sometida a la matriz file-backed. Si el primer gate
devuelve `unknownSchema`, no reconoce un store raw o demuestra que 05.6→05.7 no es ligera, el
plan no se conecta a producción y se detiene la implementación. Ese resultado no autoriza por
sí solo una etapa custom, export/import, reset, borrado, reseed ni fallback silencioso.

`Schema.franAlonso` continúa siendo la API del esquema actual y se construye desde la versión
05.10c. `FranAlonsoApp` pasa explícitamente el plan a
`ModelContainer.production(for:migrationPlan:)`. Los previews y stores nuevos en memoria usan
el esquema actual y no necesitan ejecutar migraciones.

El comportamiento de fallo sigue siendo el existente: la creación del contenedor propaga el
error y no borra ni repara el store automáticamente. Esta decisión no añade UI, telemetría,
backup, acceso Firestore, cambios de Rules o índices, ni activa ningún SyncEngine.

Desde este ADR, cada cambio de forma SwiftData publicado debe añadir una nueva versión, su etapa
desde la versión anterior y una prueba raw de todos los orígenes todavía soportados antes de
que ese esquema se publique.

## Consecuencias

### Positivas

- El historial local queda explícito, ordenado y verificable.
- Una sola API compone el esquema actual con un plan probado desde todos los checkpoints.
- Los stores antiguos y la adopción retroactiva sobre el store actual se cubren sin tráfico ni
  mutaciones remotas.
- Las futuras modificaciones del esquema tienen una regla de publicación concreta.

### Negativas y riesgos

- El código conserva ocho declaraciones de esquema y una forma histórica específica.
- El reconocimiento de stores originalmente no versionados depende del comportamiento real de
  SwiftData y debe probarse con archivos raw.
- La retirada de unicidad en 05.6→05.7 puede no ser elegible para migración ligera; el primer
  gate decide si esta propuesta puede continuar.
- Una matriz file-backed amplia incrementa el tiempo de la suite de integración.

## Testing y validación

Antes de componer el plan en producción se prueban dos puertas prioritarias:

1. un store raw 05.6 con la forma histórica exacta abre hasta 05.10c, conserva IDs, versión y
   bytes, interpreta la base legacy como ausente y permite después varias operaciones para el
   mismo Client manteniendo único cada `operationID`;
2. un store raw actual de veintiocho modelos con datos Sales abre con el esquema y plan actuales
   sin alterar su contenido.

Después se crean stores raw no versionados mediante `Schema([...])` para 05.2, 05.6, 05.7,
05.8, 05.9, 05.10a y 05.10b. Cada origen contiene datos representativos de todas sus tablas.
Tras abrirlo con el esquema y plan productivos se verifican los valores de negocio, payloads,
versiones, causalidad, revisiones, conflictos, cursores y retries; las tablas posteriores al
origen deben comenzar vacías. Una segunda reapertura compara el mismo estado y demuestra
idempotencia de aperturas posteriores, no recuperación tras una interrupción interna.

Los tests usan un directorio temporal único por caso, no acceden a red y conservan las
regresiones inmediatas 4→6, 6→7, 7→14, 14→21 y 21→28. La validación final exige pruebas focales,
suite completa, build y diagnósticos mediante Xcode MCP, chequeos estáticos y auditoría
independiente de iOS.

## Migración o reversibilidad

Mientras el primer gate no pase, la composición productiva permanece sin plan. Después de
publicarlo, retirar o reordenar versiones dejaría stores soportados sin ruta y requiere otro
ADR. Una etapa custom solo puede proponerse con evidencia del fallo ligero, transformación
determinista, alcance exacto y tests propios. Nunca se revierte mediante borrado automático del
store.

## Relaciones

- Sustituido por ADR 0018 después de que el primer gate raw demostrara que los checkpoints
  históricos compartían el identificador persistido `1.0.0` y no podían distinguirse de forma
  segura mediante este plan retrospectivo.
- Complementa ADR 0002 y ADR 0006.
- Ordena los esquemas introducidos por ADR 0012, ADR 0013, ADR 0014, ADR 0015 y ADR 0016.
- Implementa la subfase 05.11.
- No autoriza tráfico live, Rules, índices, activación de motores, PR, merge ni cierre de fase.

## Referencias

- [Model your schema with SwiftData — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [SwiftData: Dive into inheritance and schema migration — WWDC25](https://developer.apple.com/videos/play/wwdc2025/291/)
- [VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema)
- [SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
- [MigrationStage](https://developer.apple.com/documentation/swiftdata/migrationstage)
- [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
