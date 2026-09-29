# Propuesta 09.3 — Estado de lista y formulario de productos

Fecha: 2026-09-29. [PLU-52](https://linear.app/plusprojects/issue/PLU-52), hija dePLU-49, responsable Jesus Franco.
El propietario autoriza «Despues comienza a implementar09.3» junto con la entrega09.1/09.2. Esa entrega está completada:
PR17/18 integradas, ramas eliminadas, main/origin/main b8efe87 idénticos y limpios antes de abrir esta rama.
Rama `codex/plu-52-phase-09-3-product-view-models`, base b8efe87. Autorizada implementación dentro de spec09;
PRE independiente obligatorio antes del código, sin nueva confirmación para las decisiones ordinarias de este alcance.
Commit/push/PR/merge/cierre de09.3 y09.4 conservan autorización separada.

## Autoridad y baseline

Constitución, spec09, índice, política Swift, ADR0011 (sustituye0001),0002/0003/0005/0006/0014/0029/0030.
Perfil maintenance: mantener arquitectura por feature, Domain puro, datos locales y target26.0, Swift6, strict complete,
nonisolated, warnings como errores. Xcode MCP estable, FranAlonso.xcodeproj/workspace-EYu6rxi7hg, Develop/iPhone18Pro27.0.
Baseline:875 declaraciones/125 suites,1.156/1.156 resultados, build Develop con tests9,731s, PRE/POST09.2 PASS.
Production09.1 PASS; aviso AppIntents conocido. Código integrado idéntico al validado salvo línea vacía final del helper.
No hay pruebas/UI nuevas en la preparación documental. Seis enlaces históricos08.3 conservados.

## Código existente y responsabilidades

ClientListViewModel aporta patrón de observación con generación; ClientFormViewModel aporta estados por operación y
closures contextuales, pero su consentimiento y campos no se copian. ProductRepository/UseCases09.1 y adaptador Data
ofrecen todas las capacidades. GetProductUseCase devuelve Product?; nil debe bloquear la edición como notFound.
AppRuntime ya posee actor/señal únicos de Products. AppDependencies distribuye ObserveProducts y necesita la capacidad
de crear formularios sobre esos mismos roles. No se crea Store, servicio genérico, repositorio o actor adicional.

## Comportamiento exacto

### Lista y navegación local

ProductListViewModel es @Observable @MainActor. State: idle, loading, empty, content([Product]), failed. Exponer query,
visibleProducts calculados por SearchProductsUseCase y hasNoSearchResults (distinto de colección vacía). Los inactivos
permanecen visibles. load() observa snapshots; fin sin valor→empty, cancelación→idle, error→failed. Cada carga tiene
generación; una respuesta/fin/error de una observación reemplazada no altera la actual. El caller posee la tarea;
no se crea Task en init ni scheduler interno.

ProductFormDestination separa UUID de sesión y ProductID estable, modo create/edit. beginCreatingProduct asigna ambos
una sola vez para la sesión, beginEditingProduct solo acepta una identidad en resultados visibles, doble apertura se
ignora. finishFormSession solo cierra la sesión coincidente, protegiendo reaperturas de cierres tardíos. UUID inyectable
para navegación determinista. No abrir Sheets/Views aún.

### Formulario

ProductFormViewModel es @Observable @MainActor; recibe destino, GetProductUseCase y closures create/update/deactivate.
Un único campo name; no crear ProductFormFields ceremonial. State: idle/loading/editing/saving/deactivating/saved(Product),
deactivated, failed(Operation, ProductError), closed; Operation load/save/deactivate. loadedProduct conserva la última
entidad aceptada. No texto localizado nuevo: son estados semánticos que09.4 convertirá a presentación.

Alta comienza editing. Editar comienza idle y solo es editable después de cargar la entidad. Ausencia→failed(load,notFound),
errores de lectura→failed(load,error), bloqueando mutaciones; reintentar lectura permitido, nueva carga no sobrescribe un
borrador ya editable. Se conserva el estado inactive del producto a través de Data. canEdit permite reintentar tras error
de mutación; canDeactivate exige modo edit, producto cargado activo y canEdit.

save(in:) valida una copia de name con PrepareProductProfileUseCase antes de delegar una única escritura. Nombre inválido
no llega a Data; al corregirlo a válido se limpia solo invalidName. Se captura el perfil antes del await. Resultado
saved/loadedProduct procede de la entidad aceptada, nunca del campo mutable leído al volver. No añadir historial de
borrador o lógica de cambios sin necesidad. Error conserva nombre/ID; desconocido→persistenceUnavailable, ProductError
se conserva. Escribir con error previo de carga o después de cierre/éxito no está permitido.

deactivate(in:) acepta la intención ya confirmada por el futuro caller; desactiva localmente, no borra ni hace sync.
Bloquear operaciones simultáneas y repetidas; un producto ya inactive no ofrece otra desactivación en el formulario.
La Data mantiene de todos modos su contrato idempotente ya probado en09.2.

Cancelación previa de guardar/desactivar no delega; CancellationError cooperativo vuelve a editing. Una respuesta
exitosa de escritura sigue siendo éxito aunque el caller esté cancelado: no se oculta una aceptación local durable.
Carga cancelada vuelve a idle y descarta resultados tardíos. close() invalida la generación, limpia borrador/entidad y
pasa a closed; no intenta deshacer un write aceptado. Carga reemplazada y respuestas tras cierre quedan invalidadas.

### Composición ADR0011

Presentation declara SaveOperation @MainActor(ProductID,ProductProfile,ModelContext) async throws -> Product y
DeactivateOperation @MainActor(ProductID,ModelContext) async throws -> Void. El ModelContext es solo parámetro efímero,
no se almacena ni cruza actores. App compone las closures capturando ProductContextualPersistenceAdapter y la señal
existente; lectura usa DefaultProductRepository con actor/señal existentes. No invocar además UseCases mutadores
context-free para la misma acción. Domain/Data permanecen intactos.

AppDependencies añade ProductFormFactory/makeProductForm. live, fixture local e interactive preview comparten sus roles
locales actuales; snapshot preview usa su repositorio finito y rechaza mutaciones explícitamente con
persistenceUnavailable. Ajustar callsites de inicializador en tests de composición; nunca fallback live implícito.
No cambios de seed, shell, login ni activación remota al construir dependencias.

## Archivos y TDD

- Nuevos ProductListViewModel.swift, ProductFormViewModel.swift y Navigation/ProductFormDestination.swift en Products/Presentation.
- Nuevo App/AppDependencies+ProductForm.swift; cambios acotados a AppDependencies.swift y callsites de tests.
- ProductListViewModelTests, ProductListCoordinationTests, ProductFormViewModelTests y ProductFormCompositionTests.
- Spec09 si necesita consolidar contratos aprobados, Progress, phase-09 y esta propuesta/evidencia; Linear en paridad.

RED ejecutable con APIs mínimas provisionales, antes de completar comportamiento; fallos de compilación/setup no
cuentan como RED. Tests por riesgo, oráculos independientes, sin redes reales, sleeps, polling ni cronómetros de pared.
Streams/gates deterministas y container in-memory aislado. No producir un catálogo de tests que repitan la implementación.

Casos mínimos: carga/contenido/vacío/fin sin valor/error; búsqueda por query actual y nuevo snapshot, inactivos; cancelar y
reemplazar observación sin publicaciones obsoletas; identidad estable por sesión y cierre antiguo. Formulario: carga
existente/ausente/error/retry; borrador conservado; nombre inválido y normalizado; create/update con ID/campo capturado;
rechazo neutral y retry; doble envío/desactivación; cancelación previa/cooperativa/tardía y cierre durante suspensión.
Composición real desde factory: alta observada, edición/desactivación causales sin perder inactive, preview interactiva y
snapshot solo lectura. Reutilizar pruebas CRUD/sync para política de datos; no duplicar sus matrices.

Validación: Xcode MCP RED/GREEN focal y regresión por impacto incluyendo AppDependencies/AppRuntime y Products;
comprobar variantes parametrizadas reales, fallback global solo si la selección vuelve a omitirlas. Builds Develop y
Production por composición compartida. Estilo sobre archivos tocados antes de validación final y POST independiente.
No pantallas, previews visuales ni texto visible afectados: UI/accesibilidad N/A en09.3; deuda08 preservada.

## Alternativas, fuentes y límites

Reutilizar ClientFormViewModel o crear ViewModel/Store genérico mezcla dominios y consentimiento: descartado.
Llamar al repositorio mutador desde Presentation o guardar ModelContext incumple ADR0011: descartado.
Construir ProductFormFields para un solo nombre o infraestructura de Tasks/errores no demostrada añade ceremonias.
Se conserva el patrón concreto ya compilado de Clientes, adaptando ausencia, inactive y perfil capturado.
Fuentes primarias del contrato: spec09, ADR0011, UseCases/repository/adapter Product y AppRuntime/AppDependencies reales.
Observation/concurrencia no adopta APIs nuevas; comprobar fuentes Apple si el PRE descubre una duda de disponibilidad.

Riesgos: formulario vacío editable tras ausencia; ID nuevo por retry; edición tardía perdida por recarga; respuesta de
sesión cerrada; marcar como cancelado un commit real; actor/señal duplicados y preview que escribe fuera de su contexto.
Reversibilidad: retirar nuevas fachadas/factory sin migración. Sin dependencia, unsafe, target nuevo, schema, sync,
stock/mínimos, campos comerciales, UI09.4, demo seed, Service, IA ni live. Una ampliación material exige nueva propuesta.

## PRE independiente

PASS sin hallazgos P0–P3 por ios-standards-reviewer, read-only operativo sin escritura/publicación. Root confirma
553/553 archivos tracked/no ignorados idénticos, manifiesto `/tmp/franalonso-09-3-pre-review.json`, SHA-256
`a669a9554f4783e10d364e34198f08ffa00a8f461242209d14c2ad1aba0b4718`. Fuentes Apple contrastadas:
[Observation](https://developer.apple.com/documentation/observation/observable()) y
[Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation()).
Implementación autorizada por la instrucción vigente del propietario; no requiere otra confirmación para este alcance.
