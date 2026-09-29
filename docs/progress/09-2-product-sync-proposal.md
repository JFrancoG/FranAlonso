# Propuesta 09.2 — Integración de persistencia y sincronización de Product

Fecha: 2026-09-29. [PLU-51](https://linear.app/plusprojects/issue/PLU-51), hija de
[PLU-49](https://linear.app/plusprojects/issue/PLU-49). Inicio autorizado con «commit y push. Despues inicia 09.2».
Revisión independiente PRE PASS; el propietario aprueba la implementación con «si, adelante» el 29/09/2026.

Implementación local completada: cinco caracterizaciones PASS inicial, sin cambios productivos;1.156/1.156 resultados
y build Develop con tests PASS; POST independiente PASS sin hallazgos. [Evidencia y estado actual](phase-09.md); las referencias a preparación inferior
conservan el contexto de la revisión PRE. Entrega Git y09.3 no autorizadas.

## Estado, autoridad y dependencia Git

09.1/PLU-50 está publicada en `origin/codex/plu-50-phase-09-1-product-contracts` mediante
[349f3b7](https://github.com/JFrancoG/FranAlonso/commit/349f3b7e38b68cd0e40a10b6bc823e11d0c55aa4), local/remoto idénticos.
PR, merge y cierre no autorizados. La rama local `codex/plu-51-phase-09-2-product-sync` parte de ese commit, con árbol
limpio; es dependiente de09.1 y no implica integración en main. Una futura entrega de09.2 debe distinguir su delta desde
349f3b7 y conservar primero la dependencia09.1. No reescribir ni borrar ramas como efecto lateral de la preparación.

[Spec09](../specs/09_products_stock.md), constitución, guía, política Swift y ADR0002/0006/0011/0014/0018/0029/0030
conservan autoridad.09.2 conecta los comandos de09.1 con la vertical05.10 ya existente; no vuelve a construirla.
La preparación se limita a documentación, issue y rama. PLU-49/50/51 siguen In Progress; fase08 y su deuda se conservan.

Baseline reutilizada de09.1:870 declaraciones/123 suites,1.151 resultados PASS; retest POST1/1; builds Develop10,886s
y Production18,339s PASS con aviso AppIntents conocido. PRE/POST independientes favorables. Los18Swift publicados
coinciden byte a byte con el manifiesto POST final; [artefactos y límites](phase-09.md). Sin ejecución nueva de tests.
Xcode MCP estable Service conectado a FranAlonso.xcodeproj, `workspace-EYu6rxi7hg`, Develop/iPhone18Pro Simulator27.0;
SDK27.0, target26.0, Swift6, strict concurrency complete, nonisolated, warnings Swift/Clang como errores. Sin cambios.

## Código real y hueco de integración

- ProductRepository y casos de uso09.1 ya expresan alta activa, lectura, edición de nombre, búsqueda y desactivación a
  inactive. ProductProfile garantiza entrada válida. Product/DTO mantienen su forma histórica.
- ProductLocalDataSource comparte aceptación sin suspensión, cola causal, protección de tombstones/conflictos,
  rollback y cuidado de contextos ajenos. Repository/actor y adaptador contextual reutilizan esa ruta.
- ProductSyncEngine ya hace pull incremental, reconciliación local, push causal, ack, conflicto y retry durable.
  Su sync es explícito y estructurado; no hay scheduler ni activación automática autorizados.
- AppRuntime ya comparte ProductPersistenceActor y ProductObservationSignal entre dependencias y motor inactivo.
  AppRuntimeTests comprueba composición única y ausencia de I/O al construir. No hay gap demostrado en App.
- ProductCRUDPersistenceTests prueba comandos locales; ProductSyncEngineTests y otras suites siembran mayormente
  operaciones técnicas mediante persistPendingUpsert. Falta probar el recorrido de esos comandos por el motor real.
- Las pruebas llamadas restart recrean actores/motores sobre un contenedor in-memory. Las migraciones sí abren stores
  en disco, pero con filas sembradas a mano. Ninguna sustituye la reapertura de una cadena originada por CRUD09.1.
- Schema.franAlonso usa actualmente ClientDocumentsSchema; PhaseFiveSchemaMigrationPlan contiene baseline1.0 y
  documentos2.0. La reapertura09.2 empleará ese esquema/plan actual sin alterar modelos, versiones ni etapas.

## Propuesta exacta

Completar cinco escenarios de integración con Swift Testing, capas Product reales y proveedor remoto determinista en
la frontera ProductRemoteDataSource existente. Preferir ampliar recorridos existentes cuando ello evite duplicación.

| Escenario | Acción y oráculo independiente |
|---|---|
| CRUD y repetición | Crear, renombrar y desactivar con comandos09.1; sincronizar dos veces. Un documento remoto live con ID/nombre esperados y status inactive; tres operaciones causales distintas aplicadas una vez, cola vacía y ningún tombstone. Desactivar después del ack tampoco modifica revisión ni añade operación. |
| Desactivación durante ack | Suspender tras commit remoto de un alta y antes de su ack local; desactivar mediante adaptador contextual usando el mismo contenedor/señal. El ack anterior conserva el snapshot inactive y su sucesor pendiente; otra pasada converge a inactive. |
| Offline y reapertura durable | Aceptar una cadena CRUD local mientras el remoto de prueba falla; agotar presupuesto con reloj/jitter/sleep deterministas. Liberar todos los consumidores y abrir la misma URL con un nuevo ModelContainer. Conservar snapshot inactive, payloads, IDs, predecesores, bases y retry. Recuperar el remoto y converger sin duplicados, limpiando pending/retry. |
| Conflicto recibido por el motor | Crear cambios mediante CRUD y presentar revisión remota concurrente. Persistir ambos lados del conflicto, conservar cadena/snapshot local y detener sus sucesores. Update/deactivate devuelven ProductError.conflict sin operación adicional; otra identidad permanece operable. |
| Tombstone remoto observado | Introducir mediante sync un tombstone para una identidad con cambios CRUD. El stream local la excluye y lookup devuelve nil; create rechaza alreadyExists, update/deactivate deleted. Se conserva evidencia local del conflicto; repetir sync no restaura ni duplica. |

El caso offline debe incluir al menos un fallo de push de una operación, además del comportamiento de pull ya cubierto
por suites existentes, para demostrar que el operation ID y su retry sobreviven juntos. La recuperación verifica también
cursor y estado remoto, no solo el número de filas. Una segunda reapertura después de converger confirma estado final
estable y ausencia de colas/retries reaparecidos. No se simula un cierre matando procesos ni se usa el store de la app.

El recorrido actor/contextual y la observación comparten actor/señal reales. Los snapshots se comparan con datos
sintéticos esperados, no solo con conteos de señales: sync puede publicar tras pull y cada ack. Gates de concurrencia
con continuations/AsyncSequence, sin sleeps de sincronización, polling, deadlines de pared ni GCD.

## Cambio esperado y TDD

La hipótesis actual es **integración ya funcional que necesita evidencia**, sin defecto productivo demostrado.
La tarea no exige modificar producción si pasa. Caracterizaciones nuevas que pasan al primer intento se registran
honestamente como PASS inicial, sin fabricar RED ni presentar una estructura creada por el test como evidencia.
Si un escenario revela un fallo, conservar el RED reproducible y corregir solo la ruta Product causal directamente
responsable, seguida de GREEN y regresión afectada. No cambiar el oráculo para acomodar un defecto.

Se propone autorizar estas correcciones acotadas cuando sean necesarias para cumplir contratos ya aprobados09.1 y
ADR0002/0006/0014. Una regla de producto nueva, cambio de arquitectura, schema, API pública adicional, dependencia,
excepción unsafe o activación live exige volver a propuesta; no queda absorbida en esta autorización.

Áreas previstas:

- Nuevos `ProductCRUDSyncIntegrationTests.swift` y/o `ProductCRUDDurabilityTests.swift`, o ampliación equivalente de
  ProductSyncEngineTests/ProductSyncRetryEngineTests para compartir sus recorridos sin duplicarlos.
- Helpers concretos de tests: remoto con estado, gate de ack, reloj manual y store temporal. Algunos ya existen como
  privados; extraer únicamente los usados por más de una suite. No construir un framework genérico de sync de pruebas.
- Producción solo ante RED válido: ProductLocalDataSource, ProductPersistenceActor, DefaultProductRepository,
  ProductContextualPersistenceAdapter o ProductSyncEngine, dentro de su contrato vigente. Sin cambios preventivos.
- docs/Progress.md, phase-09.md y esta propuesta/evidencia; Linear actualizado con cada resultado real.

No se añaden factories de formulario en AppDependencies: solo hay observación Product actualmente y las fachadas de
pantalla pertenecen a09.3/09.4. Aquí la regla «UI solo observa SwiftData» se comprueba mediante el stream del repositorio
sobre el contenedor suministrado y su señal compartida, sin crear una pantalla para la prueba.

## Reutilización, validación y fuentes

Fuentes primarias del comportamiento actual: ProductRepository, ProductLocalDataSource (ack/descendientes, materialización
y conflicto), ProductSyncEngine, AppRuntime y AppDependencies. Sus contratos proceden de los ADR aceptados citados.
No se adopta API nueva ni cambia una decisión de proveedor: la propuesta usa las mismas fronteras compiladas.

Reutilizar como regresión ProductCRUDUseCaseTests/ProductCRUDPersistenceTests, ProductSyncEngineTests,
ProductSyncRecoveryTests, ProductSyncRetryEngineTests/PersistenceTests/PolicyTests, ProductSyncPersistenceTests/PolicyTests,
DefaultProductRepositoryTests, ProductLocalDataSourceTests, ProductPersistenceActorTests y adaptador remoto/DTO.
Composición: AppDependenciesTests/AppRuntimeTests. Compatibilidad en disco: PhaseFiveSchemaMigrationPlanTests y
ClientDocumentsSchemaMigrationTests; se mantienen como evidencia complementaria, no se reescribe la migración.

Xcode MCP ejecutará primero los nuevos escenarios; verificar todas las variantes reales en `.xcresult` cerrado.
La selección focal de09.1 omitió parámetros: si reaparece, usar ejecución sin selección parcial como fallback y registrar
la razón. Regresión por impacto; no repetir suite global si la selección es completa y no hay otro riesgo que lo justifique.
Build Develop y logs completos; Production si cambian rutas productivas comunes/configuración/composición. Warnings
Swift/Clang como errores; separar el aviso AppIntents conocido. POST independiente de estándares y estilo de Swift.

Para este inicio documental: build/tests/previews nuevos N/A, gobernanza y diff-check sí aplican. UI/accesibilidad N/A:
no hay pantallas, texto visible, recursos o previews afectados. No se acredita accesibilidad integral ni servicios live.

## Alternativas y riesgos

- Reescribir persistencia/sync: descartado, ya están integradas las primitivas; añadiría riesgos sin hueco demostrado.
- Repetir tests unitarios de05.10 o solo comprobar delegación: no demuestra el recorrido de comandos ni la durabilidad.
- Introducir un scheduler o red real para probar offline: fuera del gate live y menos determinista; usar remoto inyectado.
- Declarar09.2 terminada por los31 resultados nuevos de09.1: insuficiente para sync y reapertura de comandos.

Riesgos que los tests deben evitar: confundir inactive con tombstone; convertir edición idéntica reconocida en un no-op
no exigido por09.1; usar ProductSyncPolicy como único oráculo del remoto fake; retener el primer contenedor vía stream
o Task y llamar a eso reapertura; o validar solo señales sin leer el estado local. Oráculos explícitos de payload,
revisión, IDs y aplicaciones; liberar observadores y tareas antes de reabrir. El store temporal tiene URL única por test,
se limpia al terminar y nunca comparte datos con otras suites, la app o un usuario real.

Excluidos: nuevos campos, migraciones, resolución UI de conflictos, restauración/reactivación, CAS entre contextos,
ViewModels/pantallas, stock/mínimos, seed demo, Service, IA, ventas y tráfico live. Los motores de la app siguen inactivos.
Retirar estos tests/helpers no cambia ningún dato ni proveedor. Cualquier corrección productiva se documentará con
su RED/contrato y su riesgo concreto antes de cerrar la subfase.

## Revisión y puerta siguiente

PRE independiente read-only por `ios-standards-reviewer`: **PASS, sin hallazgos P0–P3** sobre esta propuesta y las rutas
directamente afectadas. Confirma viabilidad de los cinco escenarios, límites y oráculos; contrasta esquema/plan con
[ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) y
[ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration), y revisa la baseline
nativa sin ejecutar Xcode. Root verifica549/549 archivos idénticos antes/después, manifiesto
`/tmp/franalonso-09-2-pre-review.json`, SHA-256
`1db9d49cd79ec3653019296c2a9f1a2e6fcddf590ae0b99334331355fcd9e926`.
Este registro se añade después de verificar la huella. El propietario aprueba este alcance con «si, adelante».
Implementación y validación09.2 autorizadas; commit/push de09.2, PR, merge, cierres, activación live y09.3 conservan
autorización separada. Implementar09.2 no cierra09.1/PLU-50.
