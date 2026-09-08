# Fase 08 — Clientes, consentimiento y foto

## Inicio — 2026-09-08

- El propietario autoriza comenzar fase 08, abrir issue/rama e implementar 8.01, equivalente a 08.1 de la spec.
- Padre [PLU-34](https://linear.app/plusprojects/issue/PLU-34) y ejecución
  [PLU-35](https://linear.app/plusprojects/issue/PLU-35), ambos `In Progress`.
- Rama `codex/plu-35-phase-08-1-client-crud-search`, desde `main` limpio en `c24f6e5`.
- PLU-25 conserva su cierre administrativo independiente pendiente; sus entregables están integrados.
- Xcode MCP conecta `windowtab1` al checkout correcto. Esquema activo `FranAlonso-Develop`; lista de 636
  declaraciones habilitadas. Último build consultado correcto y sin entradas en el resumen MCP; no es una ejecución nueva.
- Target iOS 26.0, Swift 6, aislamiento por defecto `nonisolated`, concurrencia estricta completa y warnings como
  errores. El log inspeccionado usa el SDK iPhoneSimulator26.5. No se modifica configuración.

## Propuesta 08.1

Autoridad: spec 08, constitución y ADR 0002, 0006, 0009, 0011, 0012 y 0018. Perfil de mantenimiento del proyecto.

1. Completar `ClientRepository` con lectura por ID, creación, edición y desactivación semánticas. Mantener las
   operaciones existentes para sus consumidores. Los nuevos casos de uso exponen esas intenciones sin SwiftData.
2. Un valor Domain de campos editables valida nombre no vacío tras trim y contiene nombre, identificador fiscal y
   dirección opcionales. Crear recibe identidad estable y fuerza `draft`; una identidad ya existente se rechaza.
   No se impone unicidad de nombre o identificador fiscal. Editar recibe ID y nuevos campos; Data recupera el perfil en su contexto y preserva identidad, estado y
   consentimiento. No promete CAS ni exclusión entre los contextos de las rutas actor y contextual.
3. `ClientLocalDataSource` acepta los comandos sin suspensiones entre lectura/comprobación/escritura y reutiliza
   `persistPendingUpsert`/`persistPendingDelete`. Actor y adaptador contextual comparten esta primitiva. No se introduce
   un ciclo read/modify/write con varios awaits desde Domain ni se duplica la cola local-first.
4. Desactivar excluye el cliente de lecturas operativas y crea el tombstone causal existente. Se conserva el
   `ClientModel` como último perfil histórico local, incluido consentimiento, en aceptación, ack, pull y conflicto.
   Las consultas excluyen los IDs presentes en pending delete o tombstone remoto. No hay cuarto `ClientStatus`.
   El formato remoto sigue sin PII/payload de negocio y no cambia ninguna forma SwiftData publicada.
5. La retención es local: un dispositivo que solo recibe el tombstone no obtiene un perfil histórico que nunca tuvo.
   No se promete archivo remoto ni recuperación de datos ya eliminados. Esos flujos necesitan otra decisión.
6. Búsqueda pura sobre snapshots locales visibles, por nombre o identificador fiscal, con comparación de usuario
   insensible a mayúsculas/diacríticos. Query vacía tras trim devuelve la colección y se conserva el orden de entrada.
   Las altas y los borradores pendientes permanecen visibles para gestión; esto no habilita su uso comercial.
7. Errores de alta duplicada, no encontrado, conflicto, desactivado y fallo local salen por el
   contrato Domain. Cancelación antes de aceptar la escritura no produce efectos; no se inventa un fallo tras commit.
   La observación publica solo tras aceptación durable y sigue leyendo exclusivamente SwiftData.

### Áreas afectadas y alternativas

- `Clients/Domain`: valor de edición, errores y casos de uso CRUD/búsqueda; contrato Repository.
- `Clients/Data`: Repository real/en memoria/fixture, actor, adaptador contextual y primitiva local.
- Tests Clients y conformidades de sus dobles; documentación y changelog.
- Se rechazan upsert indiferenciado como CRUD (puede crear al editar), búsqueda remota (rompe offline), nuevo status
  `inactive` (contradice spec), borrado físico del último perfil (pierde consentimiento) y tabla/flag de archivo nuevos
  (duplican metadata ya persistida y exigirían migración sin necesidad).
- No se introduce ADR nuevo: se concreta la retención local exigida por 08.1 conservando el protocolo remoto y las
  decisiones de identidad, conflicto y esquema. La revisión previa debe comprobar expresamente este encaje.

### TDD y validación prevista

- RED/GREEN: crear draft, rechazo duplicado, edición que conserva consentimiento, no encontrado, búsqueda vacía/nombre/fiscal/
  diacríticos/sin resultados, desactivación idempotente y errores/cancelación sin escritura.
- Integración con SwiftData in-memory: observación CRUD, cola atómica y paridad contextual; consentimiento retenido
  tras delete/ack/pull/conflicto, exclusión operativa y reapertura. Regresión de sync, no resurrección y tombstone sin PII.
- Xcode MCP para tests focales y regresión afectada, build y log; sin `xcodebuild`. No se declara nueva evidencia hasta
  ejecutarla. Auditoría final iOS y estilo Swift; UI/accesibilidad `N/A` porque no se toca Presentation ni recursos.
- Fuentes primarias consultadas: [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor) para
  confinamiento y acceso excluyente; [búsqueda de texto de usuario](https://developer.apple.com/documentation/foundation/nsstring/localizedstandardcontains(_:)).

### Exclusiones

08.2–08.9, ViewModels/formulario/UI de búsqueda, firma, PDF, Storage, upload, activación, foto, histórico remoto,
restauración y resolución de conflictos, motores live, dependencias, targets y migraciones. Commit/push/PR/merge,
cierre Linear y siguiente subfase no están autorizados.

## Evidencia de implementación

- Revisión previa independiente: P2 sobre CAS corregido. Huella operacional pre/post inicial: 418 archivos,
  `40be4b6d196c4018172e787976b4109eeddd6a259644d1872c41048610e109f8`. Reauditoría focal PASS sin hallazgos y
  pre/post idéntico: `ac5f84e4710d4db154856c7a6c53d32bcc1760efff3ff52270737a5492f25f2e` (418 archivos).
- `ClientProfile` valida nombre al construir/decodificar. CRUD expone errores Domain; toda identidad ya utilizada,
  incluso desactivada, rechaza una nueva alta con `alreadyExists`. El antiguo upsert conserva sus consumidores.
- La aceptación Data es síncrona dentro de cada contexto: perfil y cola comparten save/rollback. No se añade CAS
  entre contextos ni se activa sincronización. Repository y adaptador contextual publican después del commit.
- `ClientModel` retiene el último perfil local en las cuatro rutas de tombstone. Las lecturas consultan los marcadores
  ya existentes y excluyen el histórico. Payload remoto, forma SwiftData y metadata causal permanecen intactos.
- Se amplían dos contenedores mínimos de tests para incluir los marcadores que ahora requiere la lectura operativa;
  no cambian modelos ni esquema de producto. Los dobles de observación solo incorporan conformidades al contrato.

### TDD y regresión Xcode MCP

- RED de retención: 0/5, por ausencia del perfil en delete local, ack, pull, conflicto y reapertura file-backed.
  Informe `A2FD0D3D-DAA9-4017-9245-CA9110B18DFE.txt`.
- RED CRUD: símbolos/métodos ausentes (`ClientProfile`, `ClientError`, CRUD de Repository/adaptador y búsqueda).
  Logs `210A6744-466D-43CE-A890-BC7077573618.txt` y `9726726A-DC38-4D03-BAFB-4DF4DAD95517.txt`.
  El segundo reveló además un warning de Swift Testing por duplicar el display name de nombres escapados; se retiró
  solo el atributo redundante antes del GREEN.
- Primer focal: 46/48. Se corrigió el error de alta sobre identidad desactivada a `alreadyExists`. Un conteo del
  contexto tras rollback devolvió una fila mientras el contexto nuevo estaba vacío; se añadieron fetch real y lookup
  del producto en ese mismo contexto. Ambos devuelven vacío/nil y también pasa el conteo posterior. No se atribuye
  una causa no demostrada ni se cambia `includePendingChanges`. Focal correctivo: 2/2.
- La selección por método de Xcode llegó a ejecutar solo el primer argumento de algunos tests parametrizados.
  La validación definitiva usa suites completas: retención 5/5 y regresión de **22 suites / 168 resultados**, todos
  pasados, sin fallos, omitidos o no ejecutados. Incluye CRUD/búsqueda, persistencia, conflictos, cursor, retry,
  sincronización, DTO/Firestore sin red, observación y composición de Clientes.
- Informe definitivo: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/08333A6D-A925-40FA-B540-944A21D01F65.txt`.
  Consola: `test-console-log-2026-09-08T13-01-12+02-00.txt`, en la misma carpeta.
  Destino de esta ejecución: iPhone 11 físico con iOS 27.0; build con SDK iPhoneOS26.5.
- Los tests se ejecutaron con la fixture Develop signed-out ya aprobada, habilitada temporalmente. El scheme se
  restauró byte a byte y sus cinco argumentos vuelven a `NO`; su diff final es vacío.
- Build final `FranAlonso-Develop`: correcto en 3,580 s, log `BuildProject-Log-20260908-130205.txt` bajo
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/`.
  `GetBuildLog` MCP filtrado por warning devuelve cero entradas (`FBFEDC4C-3FFF-4385-96CA-DEDFA0D5E4AB.txt`)
  y Navigator cero issues. El log completo sí registra en la línea 10729 el aviso de tooling
  `Metadata extraction skipped. No AppIntents.framework dependency found.`, ya documentado en fase 07.
  No se declara cero warnings globales ni se atribuye el aviso a caché. Diagnósticos focales de `ClientProfile`,
  `ClientRepository`, `ClientLocalDataSource` y adaptador contextual: cero issues.
- No se repite la suite global ni se ejecuta una nueva pasada Production. La evidencia corresponde al esquema Develop
  conectado y al alcance afectado; no se presenta como ReleaseGate ni validación live.
- Revisión de estilo sobre 23 Swift nuevos/modificados: once ajustes de formato aplicados antes de la regresión final.
  Gobernanza y `git diff --check` pasan.
- SwiftUI, previews, localización y ADR 0022: `N/A` razonado. No cambia ninguna View, ViewModel, recurso ni semántica
  accesible; las pantallas existentes mantienen su observación local.

### Auditoría final independiente

- `ios-standards-reviewer` revisa los 23 Swift, límites Domain/Data, cuatro rutas de retención, tests, estilo,
  artefactos y paridad con Linear. Sin hallazgos P0–P3 de implementación o estilo.
- Único P2 documental: la afirmación de log sin warnings no reflejaba el aviso de extracción AppIntents.
  Corregida la distinción entre log completo y diagnósticos MCP/Navigator en este registro, Progress y Linear.
  Reauditoría focal PASS: P2 cerrado, sin nuevos hallazgos; no cambia código/configuración ni se repiten tests.
- Fallback operacional read-only, sin aislamiento técnico: el orquestador acredita 429 archivos con huellas
  pre/post idénticas `61ddaebd086818daa9729a62ce10ed188707d967a75ee995c60686f0a2cbbe46`.
- El auditor verifica los 168 resultados de 22 suites, build correcto y scheme idéntico a HEAD con cinco `NO`.
  La duración, Navigator y cuatro diagnósticos MCP constan por ejecución del orquestador; no se presentan como
  observación directa del auditor.
- Reauditoría focal también read-only: 429 archivos, huellas pre/post idénticas acreditadas por el orquestador
  `f6f57246335d5bf757487e8d56def18e040616201ceb3a81e1dd04c92868aa3b`.
  Gate final PASS, sin hallazgos abiertos. El registro posterior del veredicto no altera el código validado.

## Entrega parcial de 08.1 — 2026-09-08

- El propietario autoriza commit/push de 08.1 e inicio de 08.2. Commit
  [`1164c62`](https://github.com/JFrancoG/FranAlonso/commit/1164c626d8a0276682d9060e95cb0a0757c3cf91):
  `✨ feat(clients): add client CRUD and local search`, 26 rutas explícitas, sin configuración ni credenciales.
- Push a `origin/codex/plu-35-phase-08-1-client-crud-search` verificado por SHA remoto idéntico.
  Árbol e índice limpios antes de abrir la nueva rama. Se conserva la validación y auditoría del código de 08.1;
  solo cambiaron el registro de autorización y el título de changelog después de esas puertas.
- PLU-34/PLU-35 continúan `In Progress`; no se ha creado PR, integrado en main ni cerrado issues.

## Inicio de 08.2 — propuesta

- Inicio autorizado como 8.02; [PLU-36](https://linear.app/plusprojects/issue/PLU-36) en `In Progress`.
- Rama local `codex/plu-36-phase-08-2-client-view-models` creada sobre `1164c62`. Depende de 08.1 aún no integrada
  en main; una futura entrega debe conservar esa dependencia, sin mezclar ambas subfases en un diff contra main.
- `windowtab1` sigue conectado a este checkout. Target 26.0, Swift 6, `nonisolated`, concurrencia `complete`,
  warnings Swift/Clang como errores, sin cambios. Baseline heredado: Develop/iPhone 11 físico iOS 27.0,
  SDK iPhoneOS26.5, 168/168 de 22 suites y build correcto. La consulta MCP actual devuelve cero entradas de warning
  (`GetBuildLog/27F56422-7261-497B-8CB7-9932BDB02C91.txt`) y Navigator cero issues; el log completo conserva AppIntents.
  No se han ejecutado nuevos tests/builds: todavía no hay cambios ejecutables de 08.2.
- Autoridad: constitución, spec 08, ADR 0002/0006/0009/0011/0022, política Swift y navegación acordada.

### Comportamiento propuesto

1. Ampliar `ClientListViewModel`, manteniendo su `@Observable @MainActor` y los casos existentes de `State` para
   preservar la pantalla actual. Conservar un único snapshot fuente; derivar los resultados de `SearchClientsUseCase`
   y la query vigente sin guardar una segunda colección filtrada. Distinguir fuente vacía de búsqueda sin coincidencias.
   Cada nuevo snapshot se filtra con la query actual. Error/reintento/cancelación siguen siendo intenciones del ViewModel.
2. Navegación local con destino tipado alta/edición, identificable por una sesión estable. La intención de alta genera
   el ClientID una sola vez mediante generador inyectable; editar referencia el ID del cliente visible. El destino no
   transporta modelos SwiftData ni conserva un segundo estado de formulario. Cierre y resultado de guardado son
   intenciones semánticas; el cierre de una sesión antigua no afecta a otra posterior. Presentar la sheet es 08.3.
3. Añadir `ClientFormViewModel` `@Observable @MainActor`, con modo/ID de sesión inmutables, campos editables y estado
   finito de carga, edición, guardado, resultado o fallo. Crear comienza vacío; editar carga por `GetClientUseCase`.
   Un fallo de lectura no permite guardar valores vacíos como edición; el reintento es explícito. Se conservan campos
   ante fallo de escritura y cancelación. No se persiste cada pulsación ni se activa el cliente.
4. Preparar los campos mediante un `PrepareClientProfileUseCase` puro que convierte el borrador de formulario a
   `ClientProfile`: trim de campos, fiscal vacío a nil y dirección completamente vacía a nil; una dirección parcial
   se conserva sin inventar campos obligatorios. `ClientProfile` sigue garantizando nombre no vacío. Esta conversión
   de opcionales representa una política real de entrada y satisface el valor validado previo exigido por ADR 0011;
   no se duplica la validación ni se añade un UseCase que solo reenvía argumentos. Sin validación de DNI/NIF, unicidad
   de nombre ni requisito de dirección no presentes en Domain.
5. Guardar alta/edición y desactivar un cliente existente mediante closures de operación `@MainActor` con entradas
   Domain validadas y `ModelContext` efímero. La confirmación visual de desactivación pertenece a 08.3; el ViewModel
   recibe la intención ya confirmada. No almacena el contexto, no hace CRUD/mapping/save, ni llama también a los
   UseCases mutadores context-free. Data reutiliza exclusivamente `ClientContextualPersistenceAdapter` de 08.1.
6. La composición concreta se prepara en una factory de App para el formulario, que recibe destino y los roles
   `ClientPersistenceActor`/`ClientObservationSignal` ya propiedad del runtime. Compone Get con un Repository sobre
   esos roles y las closures con un adaptador contextual que comparte la señal. No crea otro contenedor, actor
   persistente o canal de observación. El wiring visual y la adaptación de `AppPreviewModifier` quedan en 08.3;
   no se presenta el repository in-memory one-shot de previews como CRUD reactivo.
7. Cargas/observaciones async propiedad del caller, sin `Task.detached` ni tareas que capturen ModelContext.
   Tokens de generación impiden que una operación reemplazada cambie el estado actual; la cancelación del caller
   sigue siendo cooperativa. El guardado bloquea envíos simultáneos, captura el borrador aceptado y conserva la
   identidad al reintentar. Cancelar antes de delegar no escribe; una respuesta durable de éxito sigue siendo éxito
   aunque el caller se cancele después. Cerrar no promete deshacer una escritura ya aceptada y un resultado tardío
   no reabre una sesión cerrada. La exclusión local del ViewModel no promete CAS entre contextos.
8. Errores semánticos finitos para validación/carga/guardado, sin textos visibles, PII ni mensajes de SDK.
   La View de 08.3 resolverá el copy desde `.xcstrings`. No se añade `ClientConsentStore` antes de 08.7.

### Ámbito y alternativas

- Cambios previstos: `Clients/Presentation/ViewModels/ClientListViewModel.swift`, nuevo `ClientFormViewModel`,
  destino tipado y valor de campos solo si simplifican el estado; `Clients/Domain/UseCases/PrepareClientProfileUseCase`;
  factory concreta bajo `App`; suites de ViewModels, preparación de campos y composición contextual; Progress/changelog.
- Se reutiliza el contrato de estados del listado, evitando modificar Views solo para preparar el estado futuro.
- Se descartan router global/NavigationPath, Store de formulario sin responsabilidad adicional, búsqueda remota o
  debounce artificial para una búsqueda local síncrona, duplicar escrituras por Repository y closure, y retener
  ModelContext en tareas/estado. No se necesita ADR, dependencia, opt-out ni migración nuevos.
- 08.3–08.9 quedan fuera: Views, bindings/sheet, recursos/localización, firma/PDF/Storage, ConsentStore, activación,
  foto/detalle, resolución de conflictos, restauración, motores live, targets y configuración.
- UI/previews/ADR 0022 son `N/A` en esta propuesta porque no cambia ninguna superficie ni semántica accesible actual;
  la integración visual de 08.3 debe completar esa evidencia antes de su cierre.

### TDD, fuentes y revisión

- RED/GREEN con Swift Testing: filtro sobre query/snapshot cambiantes; sin coincidencias frente fuente vacía;
  observación antigua/cancelada que no pisa la actual; identidad estable de alta y selección por ID; cierre de sesión
  obsoleta; carga de edición/missing/error/reintento; inválido sin escritura; normalización de opcionales;
  guardado concurrente rechazado; fallo conservando campos; cancelación previa y éxito durable tras cancelación;
  desactivación idempotente y resultado que no reabre formulario cerrado.
- Composición con SwiftData in-memory: el formulario escribe una sola operación y la observación del mismo contenedor
  publica el resultado; editar conserva consentimiento/estado y desactivar excluye el histórico. Dobles controlables,
  sin sleeps ni repetir tests de asignación. Una prueba de cancelación no debe esperar cooperación del doble si el
  caso quiere demostrar protección ante una respuesta obsoleta.
- Validación prevista por Xcode MCP: suites completas afectadas para cubrir todos los parámetros, build/diagnósticos
  y auditoría final iOS/estilo. No se declara nuevo ReleaseGate, Production o runtime visual por el baseline heredado.
- Fuentes Apple consultadas por Cupertino: [Observation](https://developer.apple.com/documentation/observation/observable())
  y [Task/cancelación cooperativa](https://developer.apple.com/documentation/swift/task#Task-Cancellation).
  Los tokens de generación son una decisión del proyecto para controlar resultados obsoletos; no una garantía implícita
  de MainActor ni un mecanismo de rollback.
- Revisión previa independiente PASS, sin hallazgos P0–P3: confirma alcance, normalización Domain, composición
  contextual, alternativas, cancelación y plan TDD. No sustituye la aprobación del propietario del alcance presentado.
- Revisor nuevo en sesión efímera con sandbox read-only impuesto, tras alcanzar el límite de hilos de collaboration.
  Aplica `franalonso-review-ios-standards`; sin ediciones, mutaciones Git, publicaciones, builds ni tests.
  Huellas pre/post verificadas por el orquestador: 429 archivos,
  `0babb2baf739aa8b5ed7746a4487d3bbcc19a03869ea1951d848c850cd2ccbe6`.
  Informe local: `/tmp/franalonso-082-proposal-review-result.md`; eventos:
  `/tmp/franalonso-082-proposal-review-events.jsonl`.
- El revisor verifica Git local y las fronteras fuente, y contrasta fuentes Apple oficiales por web porque Cupertino
  no recibió aprobación en su sandbox. Xcode MCP, remoto vivo y Linear están verificados por el orquestador, no por
  ejecución directa del revisor. El propietario aprueba después esta propuesta; la implementación se registra debajo.

## Implementación de 08.2 — 2026-09-08

- El propietario autoriza la propuesta exacta. Se mantiene `codex/plu-36-phase-08-2-client-view-models` y PLU-36
  `In Progress`; no se autoriza entrega ni 08.3.
- Se conserva la pantalla existente y su `State`; query y resultados se derivan de su único snapshot.
  Los destinos distinguen sesión de formulario y ClientID. Formulario, campos, preparación Domain y factory App
  incorporan exclusivamente los límites revisados, con contextos efímeros y señal de observación compartida.
- RED inicial por Xcode MCP: `PrepareClientProfileUseCase` no encontrado en las tres declaraciones de su suite.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/GetBuildLog/91D8D40B-0F38-49BB-A696-F188A0EC7598.txt`.
- Primer build de implementación no resuelve `ClientFormDestination` recién creado. El navigator ya lista los cinco
  archivos nuevos; se reescriben con los mismos bytes mediante `XcodeWrite` y el build posterior pasa en 10,874 s,
  sin cambios en project.pbxproj. No se atribuye una causa de indexación no demostrada.
- Primer GREEN: 5 suites completas / 41 resultados, todos pasados. Incluye las cuatro suites nuevas y los seis casos
  anteriores de `ClientListViewModelTests`. Informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/2846C8CE-A83E-41DB-9076-F71E41A08F36.txt`.
  Se amplía después la verificación de cancelación de lectura vigente y preservación de dirección/fiscal al editar.
- Fixture signed-out Develop temporal para tests, con copia de bytes originales en
  `/tmp/franalonso-082-develop-scheme.original`. Restaurada byte a byte contra HEAD antes del build final;
  cinco argumentos `NO`, diff vacío y SHA256 `102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`.
- Revisión independiente de estilo: 10 Swift inventariados, 28 ubicaciones de tests corregidas; reauditoría de los
  dos archivos afectados sin hallazgos, script 2 archivos/0 candidatos. Los ocho restantes no cambiaron después
  de su revisión. Sin normalización histórica.
- El fake de observación se amplía para suspender tanto al obtener el stream como dentro de `next()` mediante
  [AsyncThrowingStream(unfolding:)](https://developer.apple.com/documentation/swift/asyncthrowingstream/init(unfolding:)).
  Se prueban valor/error/fin/cancelación en ambas fronteras, sin sleeps ni polling. Focal final: **46/46**.
- Regresión definitiva por Xcode MCP: **26 suites completas / 208 resultados**, todos pasados; cero fallos,
  omitidos o no ejecutados. Incluye **40 casos nuevos**: preparación 5, coordinación de listado 13, formulario 20
  y composición contextual 2, además de los 168 casos de regresión Clients/composición de 08.1.
  Informe `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/927CD8D4-7501-4190-B377-BCB5885352A5.txt`.
  Consola `test-console-log-2026-09-08T14-26-01+02-00.txt` en la misma carpeta. Develop/iPhone 11 físico, iOS 27.0.
- Build final `FranAlonso-Develop` correcto en 3,958 s después de restaurar el scheme.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-142620.txt`.
  El log completo conserva el aviso conocido de extracción AppIntents en línea 10729. GetBuildLog MCP filtrado
  por warning devuelve cero entradas (`CA8DD88C-A06C-4C47-82F5-40E4F7EB0B7F.txt`), Navigator cero issues y los seis
  Swift de producción cero diagnósticos. No se declara cero warnings globales ni causa cacheada del aviso.
- Gobernanza, enlaces locales y `git diff --check` pasan. Sin cambios en Data, esquema, configuración, Views,
  localización ni semántica accesible; previews y auditoría de accesibilidad `N/A`. No se ejecuta una nueva suite
  global/Production, no se activa live y no se presenta esta regresión como ReleaseGate.
- Auditoría final independiente iOS: **PASS, sin hallazgos P0–P3** sobre diez Swift y tres documentos contra
  `1164c62`. Revisor nuevo en sesión efímera con sandbox read-only impuesto; aplica
  `franalonso-review-ios-standards`. No propone correcciones ni realiza escrituras, publicaciones o cambios de tracker.
  Huellas pre/post verificadas por el orquestador: **438 archivos**, idénticas,
  `1e5d3aa45950fab789cee0b1cb2fea2939d64a96a3c54e65bcfb8921a0bae1b4`.
  Informe local: `/tmp/franalonso-082-final-review-result.md`; eventos:
  `/tmp/franalonso-082-final-review-events.jsonl`.
- El revisor contrasta directamente fuentes, oráculos de los 40 casos nuevos, informes 46/46 y 208/208,
  selección de las 26 suites, `BUILD SUCCEEDED`, warning completo y restauración del scheme. Duración/destino,
  ceros de filtros MCP/Navigator/refreshes, remoto y Linear son evidencia del orquestador, no ejecución propia.
  Cupertino no obtiene aprobación en su sandbox; contrasta documentación Apple oficial por web. No solicita
  builds/tests: la primera lectura Git emite mensajes del shim Apple y las siguientes usan el binario Git directo.
  El PASS queda limitado a 08.2; la futura integración debe mantener contextos del mismo contenedor y tareas
  propiedad del caller. El registro documental de este dictamen se añade después de comprobar las huellas.

## Siguiente puerta

08.2 implementada, validada y auditada sin hallazgos abiertos. El propietario autoriza commit/push de 08.2 e inicio
de 08.3 el 2026-09-08; ejecución y verificación en curso. Commit/push de 08.1 completados;
PR/merge/cierre y subfases posteriores a 08.3 permanecen separados.
