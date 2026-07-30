# ADR 0018 — Baseline SwiftData oficial desde 05.10c

## Estado

Aceptado

## Contexto

ADR 0017 propuso representar los ocho checkpoints internos de fase 05 como versiones `5.x`
retroactivas. El primer gate file-backed creó la forma raw exacta de 05.6 mediante
`Schema([...])` y demostró que el store no era reconocido por ese plan. La misma forma migró
correctamente al etiquetarla experimentalmente como `5.6.0`, por lo que la transformación
ligera era viable y el fallo pertenecía a la identidad histórica del esquema.

Los checkpoints 05.2–05.10c se escribieron todos con la versión implícita `1.0.0`, aunque sus
formas persistidas eran distintas. Un único `SchemaMigrationPlan` no puede asignar varias
estructuras diferentes al mismo identificador ni decidir cuál se encuentra en disco. Abrir
primero un esquema inferido sin plan también funcionó en el experimento, pero permitiría que
SwiftData aceptara una estructura desconocida y aplicara eliminaciones ligeras sin una
clasificación previa, contradiciendo el fallo cerrado de ADR 0017.

El propietario confirma que ninguna build 05.2–05.10b fue distribuida mediante App Store,
TestFlight, ad hoc o instalaciones internas con datos locales que deban conservarse. La única
forma que pasa a ser contrato de producto es la forma exacta de veintiocho modelos publicada en
05.10c, ya persistida con versión `1.0.0`.

## Drivers

- Adoptar versionado explícito sin cambiar la identidad del store actual.
- Preservar todos los datos de negocio y metadata de las veintiocho tablas de 05.10c.
- Fallar ante un esquema desconocido sin reset, reseed, export/import o fallback silencioso.
- Evitar infraestructura de clasificación y migración para stores que no forman parte del
  producto distribuido.
- Exigir que cada futura forma persistida se capture antes de distribuirla.

## Opciones consideradas

### Mantener las ocho versiones retroactivas de ADR 0017

No es viable: siete formas históricas diferentes y la forma actual comparten la identidad
persistida `1.0.0`, mientras el plan propuesto esperaba versiones `5.x` que nunca se escribieron.

### Abrir primero sin plan y adoptar después el plan

El experimento reconoce el store 05.6, pero no puede demostrar que un esquema desconocido sea
uno de los checkpoints esperados. Una migración ligera inferida puede eliminar propiedades o
entidades, por lo que esta ruta podría perder datos antes de aplicar una política de soporte.

### Clasificar metadata y hashes para migrar cada forma interna

Podría preservar los checkpoints mediante una allowlist exacta y un puente o plan por origen,
pero añade lectura de metadata de Core Data, clasificación, rutas específicas y una matriz de
recuperación sin existir un store de producto que lo necesite. Si aparece ese requisito, exige
otro ADR y evidencia de cada origen real antes de implementar.

### Publicar 05.10c como primera baseline oficial

Conserva la versión `1.0.0` ya escrita, permite adoptar inmediatamente el plan y establece una
frontera inequívoca para evolucionar el esquema desde ahora.

## Decisión

La forma exacta de 05.10c se declara como `PhaseFiveBaselineSchema`, un `VersionedSchema` con
versión `1.0.0` y los veintiocho modelos actuales de Clients, Products, Services y Sales.

`PhaseFiveSchemaMigrationPlan` contiene únicamente esa baseline y ninguna etapa. La ausencia de
etapas es intencional: 05.11 adopta el contrato versionado sobre la misma forma e identidad que
el store actual; no transforma datos. `Schema.franAlonso` se construye desde la baseline y
`FranAlonsoApp` pasa explícitamente el plan a `ModelContainer.production`.

Los stores 05.2–05.10b quedan como checkpoints internos no soportados por la ruta productiva.
Sus pruebas inmediatas de reapertura permanecen como evidencia histórica de las ampliaciones
realizadas, pero no representan orígenes del plan oficial. No se añade apertura genérica,
clasificación por heurística, reparación, borrado, reset, reseed ni export/import automático.

Desde esta decisión, cualquier cambio de forma SwiftData debe, antes de distribuirse:

1. conservar `PhaseFiveBaselineSchema` sin mutar sus modelos;
2. declarar un nuevo `VersionedSchema` con un identificador superior y tipos que congelen la
   forma anterior cuando sea necesario;
3. añadir una etapa explícita y justificar si es ligera o custom;
4. probar mediante un store raw cada origen de producto todavía soportado, con datos de negocio
   y metadata representativos y una segunda reapertura estable;
5. componer el nuevo esquema y plan solo después de que la matriz pase.

La creación del contenedor continúa fallando cerrada. Esta decisión no añade UI, telemetría,
backup, acceso Firestore, cambios de Rules o índices, ni activa ningún SyncEngine.

## Consecuencias

### Positivas

- El store actual adopta una identidad versionada explícita sin transformación ni pérdida.
- El historial soportado es pequeño, inequívoco y comprobable.
- Las futuras migraciones parten de una baseline que ya existía realmente en disco.
- Se evita una ruta genérica que pudiera aceptar estructuras desconocidas.

### Negativas y riesgos

- Los checkpoints internos anteriores a 05.10c no pueden abrirse mediante el plan productivo.
- Si aparece un store antiguo con datos irremplazables, será necesaria una decisión separada y
  una migración controlada por origen.
- Toda futura modificación de un modelo requiere disciplina de versionado antes de distribuir.

## Testing y validación

El gate de adopción crea un store raw con `Schema([...])`, una fila representativa en cada una de
las veintiocho tablas y la versión implícita `1.0.0`. Después lo abre con
`Schema.franAlonso` y `PhaseFiveSchemaMigrationPlan`, comprueba cada snapshot, operación
pendiente, estado remoto, conflicto, cursor y retry, y repite la apertura para demostrar que el
contenido permanece estable.

Un test separado fija que el plan contiene exactamente una versión `1.0.0`, veintiocho modelos
y cero etapas. La validación final exige pruebas focales, suite completa, build y diagnósticos
mediante Xcode MCP, chequeos estáticos y auditoría independiente de iOS.

## Migración o reversibilidad

Antes de distribuir una segunda versión, retirar el plan conserva la forma actual pero elimina
el contrato de evolución y requiere otro ADR. Después de publicar una versión posterior, no se
puede retirar ni reordenar ningún origen soportado. Nunca se revierte mediante borrado automático
del store.

## Relaciones

- Sustituye ADR 0017.
- Complementa ADR 0002 y ADR 0006.
- Implementa la subfase 05.11.
- No autoriza tráfico live, Rules, índices, activación de motores, PR, merge ni cierre de fase.

## Referencias

- [Model your schema with SwiftData — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [SwiftData: Dive into inheritance and schema migration — WWDC25](https://developer.apple.com/videos/play/wwdc2025/291/)
- [Schema initializer](https://developer.apple.com/documentation/swiftdata/schema/init(_:version:)-8jo9o)
- [VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema)
- [SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
- [MigrationStage](https://developer.apple.com/documentation/swiftdata/migrationstage)
- [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
