# Fase 08 — Clientes, consentimiento y foto


## Estado vigente reconciliado — 2026-09-10

Este resumen sustituye los pendientes históricos de las sesiones fechadas inferiores. Detalle por
criterio y técnica en [evidencia08.3](../accessibility/evidence/08-3-client-screens.md).

- Base08.3 publicada5533948 y documentación4527b03; HEAD/remoto4527b03 verificados. La nueva
  confirmación, ClientFormScreen, estilo de Reintentar en ClientFormContent y documentación siguen
  incluidas en el commit de correcciones autorizado el2026-09-10. La publicación previa no incluía estas correcciones.
- R09 lectura/reintento/campos/Cancelar→fila confirmado por propietario; fallo de guardado ya validado.
  Harness retirados, AppDependencies+ClientForm.swift restaurado byteexactoHEAD. Build125405 PASS8,46s,
  RunProject125546 PASS8,152s, Develop/iPhone14/26.6.1 mediante MCP27. Aviso previo AppIntents persiste.
- Nueva sheet validada por propietario en apariencia habitual y VoiceOver: lectura, Cancelar/retorno,
  confirmación con anuncio final completo. Locución parcial transitoria no bloqueante, sin causa atribuida.
  Reintentar con cápsula visible y preview12:55:29 inspeccionada.
- Comprobación acotada completada: seis capturas del propietario de las13:40–13:41 muestran listado,
  formulario y nueva sheet en iPad/ventana estrecha con texto ampliado. La secuencia13:41:46→13:41:57
  acredita que al desplazar ambos botones aparecen completos. El propietario confirma apariencia correcta.
  No se infiere pulsación ni locución de las capturas; Cancelar/VoiceOver ya tienen evidencia anterior.
  Sin nuevas pruebas manuales pendientes en el muestreo acordado; ADR0026 sigue como excepción aceptada.
- Correcciones publicadas en69acaa4. Posteriormente el propietario autoriza publicar también
  plist/pbxproj para dejar el árbol limpio; scheme ya coincide con Git. Revisión estática independiente
  PASS, build MCP141420 PASS4,129s y valores efectivos del plist generado verificados.
  PR/merge/cierre/activaciónlive/08.4 siguen fuera de esta entrega.
- Reauditorías documentales focales de estándares iOS y accesibilidad PASS, sin hallazgos abiertos
  en esta reconciliación. Gobernanza y diff-check PASS; build/tests N/A por cambio documental.
- Se reclasifican34 enlaces a artefactos eliminados como rutas históricas no disponibles, conservando
  su identidad y resultado comunicado. No se recrea evidencia ni se exige repetir pruebas por perder
  un archivo temporal. Se retiran de la matriz los pendientes ya resueltos, sin declarar cobertura global.

Las secciones siguientes son el registro cronológico: las limitaciones se leen con su fecha y no
sustituyen este estado vigente ni las tablas R/ADR reconciliadas.

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
- Se habilitó temporalmente signed-out en el archivo del scheme, que se restauró byte a byte con cinco argumentos
  `NO` y diff vacío. Rectificación al validar 08.3: no quedó acreditada su activación efectiva en el host de este run
  de 08.1; los tests construyen sus propias composiciones aisladas. Véase la nota de fixture de 08.3.
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
- Argumento signed-out temporal en el archivo del scheme, con copia de bytes originales en
  `/tmp/franalonso-082-develop-scheme.original`. Restaurada byte a byte contra HEAD antes del build final;
  cinco argumentos `NO`, diff vacío y SHA256 `102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`.
  Rectificación al validar 08.3: la activación efectiva de esa fixture en el host de 08.2 no quedó acreditada;
  los tests construyen composiciones aisladas. Véase la nota de fixture de 08.3.
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

## Publicación de 08.2 — 2026-09-08

- El propietario autoriza commit/push de 08.2 y avanzar con 08.3. Commit
  `64736583b4717c92cdd7445f004e76a3f9aab7f8` — `✨ feat(clients): coordinate client list and form state`.
  Se incluyen trece rutas explícitas; changelog incluido, staged diff y gobernanza comprobados.
- Push con upstream `origin/codex/plu-36-phase-08-2-client-view-models`; `git ls-remote` devuelve el mismo SHA.
  Árbol limpio tras publicar. No se repiten build/tests porque solo cambió el registro documental de autorización.
  PLU-36 conserva `In Progress`; sin PR/merge/cierre. 08.1 y 08.2 continúan apiladas y no integradas en main.

## Inicio de 08.3 — propuesta

- [PLU-37](https://linear.app/plusprojects/issue/PLU-37), hija de PLU-34, `In Progress`.
  Rama `codex/plu-37-phase-08-3-client-screens`, desde `6473658` limpio; sin código ejecutable nuevo.
- Xcode MCP conectado a este checkout (`windowtab1`). Superficie core de 21 herramientas; no hay herramientas
  extendidas de lanzamiento, cambio de destino ni interacción accesible anunciadas. La operabilidad de Inspector y
  tecnologías de asistencia debe verificarse en la implementación; no se presume de herramientas históricas.
- Configuración comprobada: target iOS 26.0, Swift 6, strict concurrency complete, aislamiento por defecto
  nonisolated y warnings Swift/Clang como errores. Xcode instalado 26.6, Swift 6.3.3, SDK iPhoneOS 26.5.
- Baseline heredado y vigente de 08.2: 26 suites/208 resultados, build Develop y auditorías PASS con el aviso
  AppIntents documentado. No se acredita nuevo render, runtime, accesibilidad ni Production de 08.3.

### Alcance concreto

1. Integrar `ClientListScreen` con búsqueda nativa `.searchable`, alta desde toolbar y edición desde filas Button.
   `ClientListContent` recibe los resultados derivados de `visibleClients` y `hasNoSearchResults`; distingue carga,
   fuente vacía, contenido filtrado, sin coincidencias y error con reintento. Ni Screen ni contenido filtran datos.
   La búsqueda conserva la query al regresar del formulario y no introduce debounce ni peticiones remotas.
2. Presentar una única `.sheet(item:)` con `ClientFormDestination`. El binding delega el cierre mediante el ID de
   sesión capturado; no escribe directamente en `private(set)` ni deja que un callback antiguo cierre otra sesión.
   El formulario conserva su ViewModel en `@State` por identidad; no se reconstruye al editar un campo.
3. Crear `ClientFormScreen` y contenido declarativo de formulario con controles SwiftUI nativos. Nombre obligatorio,
   identificador fiscal opcional y dirección opcional (calle, código postal, localidad, provincia). Labels persistentes,
   propósito de entrada/autofill cuando corresponda y teclado operable. No se inventan validaciones fiscales.
   El alta comunica que guarda un borrador; no se ofrece activación ni se afirma disponer de consentimiento.
4. Representar carga inicial, edición, validación, guardando/desactivando, fallo de lectura o mutación y resultado.
   Nombre inválido se asocia al campo y propone corrección. Los errores se traducen desde errores semánticos finitos
   a recursos de Presentation; no se muestran strings de SDK. Reintentar carga no permite guardar un perfil vacío.
   Guardar/cancelar son acciones explícitas; cancelar descarta los cambios sin guardar. Se impide el cierre interactivo
   que pudiera descartar accidentalmente el formulario y se bloquean sus acciones incompatibles durante una mutación.
5. Desactivar solo un cliente existente cargado mediante confirmación nativa explícita y acción destructiva localizada.
   Guardado/desactivación cierran tras aceptación local y el listado se actualiza por su observación existente.
   La confirmación no promete eliminación remota ni borrado del histórico/consentimiento retenido.
6. Las tareas pertenecen al Screen mediante `.task`/`.task(id:)`, siguiendo el patrón existente de `LoginScreen`.
   Las intenciones usan identificadores de solicitud efímeros; ninguna tarea ni propiedad conserva `ModelContext`.
   El Screen lo obtiene del entorno y lo pasa a `save(in:)` o `deactivate(in:)`; toda persistencia queda en Data.
   Cerrar invalida la sesión; una cancelación no promete revertir una escritura ya aceptada. Se reutilizan los guards
   y tokens de 08.2; solo se amplía lógica semántica si la integración demuestra una necesidad cubierta primero por test.
7. App expone una capacidad de creación de formularios que captura únicamente los roles ya compuestos para Clients.
   Runtime y composición local Develop comparten actor/señal entre lectura, observación y adaptador contextual.
   La Screen recibe esa capacidad, sin acceder a `AppRuntime` ni construir repositories. Las composiciones inyectadas
   de tests reciben capacidades explícitas; no se introduce una segunda ruta de escritura o un fallback live.
8. El preview navegable estándar comparte su `ModelContainer` in-memory entre lecturas y escrituras, con telemetría
   fake e instancias de actor/señal únicas para ese contexto. `AppPreviewModifier` conserva seed idempotente fuera de
   cualquier View; se evita el repositorio one-shot paralelo actual. Los previews snapshot de 0/1/80 clientes usan
   valores sintéticos deterministas, sin resembrar diferentes escenarios sobre el mismo contexto estático cacheado.
   Los helpers existentes de previews solo de lectura no se presentan como prueba de CRUD reactivo.
9. Cada View nueva/modificada mantiene un tipo View por archivo y preview propio con trait compartido. Se usan los
   componentes/tokens existentes; los nuevos textos y anuncios viven en `Localizable.xcstrings`, español vigente.
   No se añade idioma, dependencia, router, Store, migración, target, permiso ni configuración de producto.
10. Accesibilidad por construcción según ADR 0022: nombres alineados con texto, estructura/encabezados, 44×44 pt
    operables, contenido largo hasta AX 5, errores asociados, resultados anunciados y orden/restauración de foco al
    abrir/cerrar sheet o confirmación. Se empieza por comportamiento nativo y se corrigen fallos de foco observados;
    no se mueve foco por cada tecla de búsqueda. iPad mantiene adaptación; iPhone conserva la excepción 1.3.4 de ADR 0026.

### Archivos y alternativas

- Clients/Presentation: `ClientListScreen`, `ClientListContent`, `ClientRow`, nuevos `ClientFormScreen` y contenido
  del formulario; helpers semánticos de Presentation solo si evitan lógica en View. Ajustes mínimos de ViewModels
  limitados a necesidades de integración demostradas y testeadas, sin rehacer las reglas de 08.2.
- App: `AppDependencies`, `AppDependencies+ClientForm`, `AppShellScreen`, `AppPreviewModifier` y fixtures de preview.
  Composición/test callers afectados; `Localizable.xcstrings`; tests de composición/presentación nuevos pertinentes;
  Progress, changelog y registro de accesibilidad de fase 08.
- Se eligen List/Form/searchable/sheet/confirmationDialog nativos. Se descartan buscador o navegación custom,
  un formulario global en el shell, construir un ViewModel en cada render, pasar modelos SwiftData vivos o almacenar
  el contexto, y sustituir observación local por recargas manuales tras cada cierre.
- El cambio del preview navegable es necesario para demostrar que guardar y observar usan la misma fuente local.
  Se conserva la capacidad de previews snapshot para estados específicos; no se crean fixtures runtime de fallos
  o latencia sin revisión expresa de ADR 0023/0024. La fixture estándar existente basta para el recorrido local feliz.
- Quedan fuera firma/consentimiento/PDF/Storage, `ClientConsentStore`, activación, foto/detalle de 08.9, histórico
  remoto, live, restauración/deep links, rediseño del shell y cambios funcionales de otras features.

### TDD, validación, fuentes y riesgos

- La lógica de 08.2 ya tiene 40 casos nuevos. No se añaden UI tests ni tests que repitan el árbol de SwiftUI.
  RED/GREEN focal para la nueva composición expuesta: crear/editar/desactivar mediante la capacidad pública y
  comprobar snapshot del mismo contenedor, ausencia de doble escritura y preservación de configuración no-live.
  Cualquier nuevo mapping o coordinación con comportamiento real recibe un oráculo independiente.
- Regresión por suites completas de ViewModels/Clients, composición App/previews, localización y shell afectado.
  Build y diagnósticos Xcode MCP; no se declara ReleaseGate global sin ejecutarlo ni se repite por ritual la suite total.
- Previews: listado con 0/1/80 clientes, sin coincidencias, error y carga; formulario alta, edición con contenido largo,
  validación, fallo inicial, fallo de guardado y ocupado. Render e inspección de variantes soportadas Large/XXX Large/AX 5,
  Light/Dark y contraste normal/incrementado, RTL, iPad/ventana estrecha y preferencias de accesibilidad pertinentes.
- Runtime manual/Inspector sobre listado, formulario y flujo transversal: alta → búsqueda → edición → cancelación →
  validación → guardar → desactivar, apertura/reapertura y foco. Registrar VoiceOver, Voice Control, Switch Control y
  Full Keyboard Access de forma separada. La fixture Develop estándar usa SwiftData in-memory sin live; la fixture de
  error de listado no se recupera al reintentar. Loading sostenido/fallos de formulario carecen de fixture runtime actual:
  previews/tests no acreditan su recorrido AT. Esa evidencia queda pendiente si no puede demostrarse, sin cerrar la subfase.
- Cada pantalla y flujo conserva todas las filas de la matriz ADR 0022, con aplicabilidad, resultado y evidencia precisa.
  Auditorías finales independientes iOS/estilo y SwiftUI/accesibilidad; solo se repite el ámbito afectado por correcciones.
- Fuentes consultadas por Cupertino, Apple oficial:
  [sheet(item:)](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)),
  [searchable](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)-18a8f) y
  [AccessibilityNotification.Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement).
  Sustentan presentación por identidad, buscador nativo y anuncios; el control de sesión/cancelación es decisión del
  proyecto, no garantía automática de esas APIs. Autoridad local: spec 08, ADR 0011/0022/0026 y navegación aprobada.
- Riesgos principales: instancias de formulario recreadas, cierres obsoletos, contexto distinto al observado, contaminación
  del preview cacheado y pérdida de foco/acciones con AX 5. Se cubren por identidad, composición, tests y evidencia manual.
  Reversibilidad: el cambio es Presentation/composición/recursos; no hay migración ni operación remota.
- Revisión independiente previa: **PASS, sin hallazgos P0–P3**. Revisor nuevo en sesión efímera con sandbox
  read-only impuesto, sin escrituras, mutaciones Git/tracker, builds/tests/previews ni subagentes. Git directo evita
  el shim Apple. Huellas pre/post verificadas por el orquestador: **438 archivos**, idénticas,
  `a2104da6c1313a0768f8c9c72d6bf842864d3990ce6d69f1625fe6b5b733bd6f`.
  Informe: `/tmp/franalonso-083-proposal-review-result.md`; eventos:
  `/tmp/franalonso-083-proposal-review-events.jsonl`.
- El revisor confirma viabilidad de composición, identidad, cancelación, previews, TDD y límites de accesibilidad;
  contrasta directamente baseline 208/208, build y aviso AppIntents. Conexión Xcode, duración, remoto y Linear son
  evidencia del orquestador. Consulta Apple oficial por web al no obtener aprobación para Cupertino en su sandbox.
  No acredita implementación o runtime nuevos. El propietario aprueba después el alcance concreto presentado.

## Implementación de 08.3 — 2026-09-08

- El propietario aprueba la propuesta. Se inicia implementación en PLU-37 y su rama existente; sin autorización
  de entrega, cierre, 08.4 o live.
- RED focal Xcode MCP: `ClientScreenCompositionTests` no compila porque `AppDependencies` todavía no expone
  `makeClientForm`; los demás errores de inferencia son cascadas. Log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/GetBuildLog/02FFE988-2450-4877-9CFB-1143169676F1.txt`.
- Integrados listado, búsqueda, sheet por identidad y formulario nativo de alta/edición, validación, cancelación,
  guardado y confirmación de desactivación. App expone la factory sobre los roles existentes; la observación y el
  contexto de escritura comparten contenedor. Los previews navegables usan esa composición reactiva; las variantes
  snapshot e inyectadas rechazan escritura explícitamente. Sin cambios Domain/Data, migración ni motores live.
- Ocho casos nuevos de composición prueban CRUD observado, una operación pendiente por mutación y denegación de
  escritura en capacidades de solo lectura. Primer GREEN **20/20** en tres suites, informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/4C445747-9053-4F3E-A2DD-B7E16421D532.txt`.
- La primera regresión se canceló: el test histórico de preview esperaba que terminase un stream que ahora permanece
  reactivo. Se retiró esa expectativa obsoleta, conservando comprobaciones de seed/snapshot e idempotencia, y se limitó
  la suite a un minuto. El nuevo caso de composición acredita las actualizaciones sucesivas. Reejecución completa
  de **32 suites / 259 resultados pasados**, sin fallos, omitidos ni no ejecutados; selección de 197 declaraciones
  con casos parametrizados. Develop/iPhone 11 físico iOS 27.0. Informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/374AC178-95F3-462D-B95E-D4DD746CE2A3.txt`;
  selección exacta en `/tmp/franalonso-083-regression-suites.json`. No es ReleaseGate global ni Production.
- Primer build correcto en 11,897 s; build de simulador verificado en 22,365 s, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-161108.txt`.
  Build final tras restaurar configuración: **PASS, 12,07 s**, Develop/iPhone 11, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-162602.txt`.
  GetBuildLog warning devuelve cero entradas (`1480064F-5641-49AD-8CB2-6EFFA02F4E12.txt`) y Navigator cero issues.
  El log completo conserva el aviso AppIntents en línea 10950; no se declara cero warnings agregados. Los logs de
  host/simulador también contienen diagnósticos de Firebase sin configurar, dSYM y teclado/hápticos del runtime;
  no se presentan como una sesión Production validada ni se corrigen mediante cambios ajenos a 08.3.
- Se produjeron e inspeccionaron **19 capturas** de previews, incluidas capturas iniciales reemplazadas y una pantalla
  de edición que solo llegó a carga. Listado 0/1/80, sin coincidencias, fallo y carga; formulario alta, edición larga,
  validación, fallo inicial/de guardado y progreso; Large/XXX Large/AX 5 y variantes claras/oscuras/de contraste
  descritas individualmente en el [registro accesible](../accessibility/evidence/08-3-client-screens.md).
  Se corrigió el recorte del label obligatorio en AX 5 mediante dos ajustes de crecimiento vertical del componente
  compartido, y se situaron errores/progreso antes de los campos para que resulten visibles. El render posterior al
  build confirma el label completo; el preview propio compartido también conserva el label. No acredita todos sus
  consumidores ni las combinaciones visuales todavía pendientes.
- Runtime CUA en iPhone 17e/iOS 26.5: alta sintética, nombre vacío rechazado, búsqueda, edición, cancelación sin
  persistir, reapertura con consulta conservada y guardado de campo fiscal recuperado al reabrir. La desactivación
  UI no quedó demostrada: las acciones de scroll/drag CUA no desplazaron el viewport; no se atribuye todavía un
  defecto a Form. Inspector pudo seleccionar Fran DEV, pero Run Audit no produjo un informe. Después se cerró
  el pipe nativo CUA; la reconexión permitió detener la app y restaurar configuración.
- Corrección de evidencia de fixture: editar externamente el argumento en `.xcscheme` no actualizó el estado
  cacheado del IDE. Los tests pasan usando sus propias composiciones aisladas, pero no se acredita la fixture del
  host de los runs de **08.1, 08.2 y 08.3**. La auditoría contrasta inicialización Firebase en las consolas históricas
  de 08.1 (13:01:12, líneas 373–383) y 08.2 (14:26:01, líneas 435–445); no permite reconstruir la ruta exacta del host,
  ni deducir tráfico o escrituras live. La restauración de los archivos sí está acreditada. Los primeros lanzamientos
  de 08.3 tampoco acreditan la fixture. El recorrido de Clientes anterior sí se hizo
  después de verificar en Edit Scheme el argumento signed-out activado y los otros cuatro desactivados, sobre la
  fixture Develop existente. Al terminar se verificaron **los cinco argumentos desactivados en el IDE**, se restauró
  el scheme byte a byte desde `/tmp/franalonso-083-develop-scheme.original` (SHA-256
  `102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`) y se devolvió el destino al iPhone 11.
- Registro ADR 0022 con **55 filas por listado, formulario y flujo transversal**. La evidencia de tecnologías de
  asistencia, foco/anuncios completos, contraste medido, preferencias, iPad/ventanas/RTL y desactivación UI permanece
  pendiente. La excepción de orientación iPhone de ADR 0026 no autoriza cerrar los demás pendientes. Las pruebas
  lógicas y los previews no se convierten en pasadas runtime accesibles. Auditorías finales independientes en curso.

### Auditorías independientes y correcciones focales

- Dos revisores nuevos, `ios-standards-reviewer` e `ios-accessibility-reviewer`, en modo operacional estrictamente
  read-only: sin ediciones, publicaciones, cambios Git/tracker o ejecuciones Xcode. Orquestador verifica **446 archivos**
  tracked y no ignorados, pre/post idénticos: `886d7286850e9f2f4ebc43252fd703e0f9d1ef815e0158a0abe93d7e7c1f76f4`.
  Manifiestos `/tmp/franalonso-083-final-audit-before.json` y `/tmp/franalonso-083-final-audit-after.json`.
- iOS: sin hallazgos técnicos/estilo en **17 Swift**, cinco candidatos léxicos justificados (cuatro tuplas UUID y un
  inicializador con closure ViewBuilder). Contrasta directamente RED, 20/20, 259/259 y build/log final. Único P2:
  ampliar la rectificación de fixture al histórico 08.1/08.2. Corregido en ambos apartados y en la nota de 08.3;
  no se deducen tráfico ni escrituras live a partir de inicialización Firebase.
- Accesibilidad: confirma 55 criterios exactos L/F/X, 34 recursos nuevos sin cambios en los anteriores, estructura
  declarativa y los 19 renders iniciales. Dos P2: título inline recortado en AX 5 y contraste raster insuficiente del
  label de progreso en claro. Corregidos mediante título nativo grande y token `TextPrimary` en ese label.
- Build tras esos dos ajustes visuales: **PASS, 7,686 s**, Develop/iPhone 11, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-163708.txt`.
  GetBuildLog warning sin entradas (`875B3B13-AF51-496F-A54B-2DDDCF449D0C.txt`); AppIntents persiste en línea 10917.
  No se repiten los tests lógicos: solo cambian presentación de título y color. Se añaden siete renders, **26 capturas
  en total**: título completo Large/AX 5, progreso en cuatro apariencias y labels Email/Contraseña del consumidor
  LoginContent completos a AX 5. Muestreo raster del progreso supera 4,5:1 en las cuatro capturas, con método y límites
  en el registro accesible; no se presenta como Inspector ni contraste general de pantalla.
- Reauditorías focales: **iOS PASS, P2 documental cerrado; accesibilidad cierra los dos P2 visuales, sin nuevos
  hallazgos P0–P3**. El especialista inspecciona los siete renders correctivos y reproduce los cuatro ratios del
  label de progreso. Orquestador verifica de nuevo **446 archivos** pre/post idénticos:
  `7eed94728aa868f98313e5b9680765ed498812e08fa8dca30cdc9a54e8e940f2`, manifiestos
  `/tmp/franalonso-083-reaudit-before.json` y `/tmp/franalonso-083-reaudit-after.json`. Sin escrituras o ejecuciones
  Xcode por los revisores. El registro de los dictámenes se añade después de verificar las huellas.
- La auditoría accesible mantiene el gate ADR 0022 bloqueado por evidencia aplicable no ejecutada; cerrar los
  hallazgos visuales no permite cerrar 08.3. Gobernanza, enlaces y diff-check pasan; el diff conserva 34 recursos
  nuevos sin cambios de los existentes, y no incluye configuración, credenciales o archivos de entorno.
- Linear: PLU-34/PLU-37 reflejan implementación y validación parcial, `In Progress`; las notas de PLU-35/PLU-36
  distinguen la restauración del scheme de la activación no acreditada del host. Sin cambios de estado ni entrega.

### Prueba guiada en iPhone 14 y recuperación del error de nombre

- 2026-09-08: recorrido realizado y comunicado por el propietario, iPhone 14 / iOS 26.6.1,
  Xcode 26.6 / Develop, fixture signed-out habilitada para la sesión manual. Confirma listado vacío,
  Guardar vacío mantiene el formulario y muestra el error con foco en nombre; cumplimenta los seis campos,
  desplaza hasta Provincia y guarda: sheet cerrada y una sola fila. No acredita tecnologías de asistencia.
- Defecto descubierto: el error de nombre permanecía al escribir un nombre válido y al perder foco.
  Corrección acotada en `ClientFormViewModel.fields`: solo retira `.failed(.save, .invalidDisplayName)`
  cuando cambia el nombre y el constructor Domain `ClientProfile` lo acepta. No normaliza el texto escrito,
  no guarda y conserva errores ajenos, espacios inválidos y estados ocupados/cerrados.
- Propuesta independiente read-only PASS; 446 archivos pre/post idénticos, SHA-256
  `a716b92c447483f9120ddd0e0acb0dc1127f984ac748332bed297932d2a60f10`.
- TDD mediante Xcode MCP, Develop / iPhone 14: RED **21 pasados / 1 fallo esperado por la regresión**
  (no marcado como expected failure), en la expectativa de `.editing` antes de volver a guardar.
  Artefacto `RunSomeTests/DA820EDF-566F-427A-89F6-3D55223C2170.txt`.
  GREEN **32/32**, suites `ClientFormViewModelTests`, `ClientFormCompositionTests` y
  `ClientScreenCompositionTests`, 0 fallos/omitidos/no ejecutados; incluye dos casos nuevos parametrizados.
  Artefacto `RunSomeTests/D943B43D-CCD6-41C8-A782-61A2B3E5FF5A.txt`.
  Ambos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`.
- Build posterior **PASS, 4,08 s**: `BuildProject/BuildProject-Log-20260908-190516.txt` en la misma base.
  Navigator/GetBuildLog sin issues; aviso AppIntents persiste en línea 10729 del log completo.
  No se repiten las 32 suites históricas: cambio focal cubierto por estas tres suites.
- El scheme signed-out y destino iPhone 14 quedan configurados para continuar la prueba del usuario;
  sustituyen la restauración histórica al iPhone 11. Los datos de esta fixture son temporales.
  El propietario confirma después que el error desaparece al escribir en el iPhone 14.
  Confirma también guardar el cliente, reabrirlo, cambiar su nombre y cancelar: el nombre original
  permanece en el listado y al reabrir el formulario. Prueba posterior confirma guardar una edición con
  nombre «Cliente editado 08.3» y ciudad «Sevilla»: ambos valores se conservan al reabrir y el listado
  mantiene una sola fila para ese cliente. Evidencia AT de esta sesión aún pendiente. Resultado manual comunicado por el propietario, sin nueva ejecución de código.

- El propietario comunica que confirmó Desactivar y el cliente desapareció del listado: desactivación UI
  acreditada por reporte manual en iPhone 14. En otra apertura, el diálogo no mostró Cancelar; una pulsación
  en Cancelar de la edición cerró el diálogo y la segunda cerró el formulario. No se infiere todavía
  conservación del cliente tras esa cancelación ni acceso con AT.
  El código sí declara el botón con rol cancel. Apple describe que las action sheets ancladas de iOS 26
  omiten Cancelar y se cierran tocando fuera ([WWDC25, 284](https://developer.apple.com/videos/play/wwdc2025/284/)).
  Es compatible con el reporte, sin inspección directa de su presentación. En la prueba posterior, el
  propietario confirma que tocar fuera cierra solo la confirmación, deja el formulario abierto y conserva
  el cliente al cerrar la edición y volver al listado. Cancelación de desactivación confirmada por reporte
  manual; AT sigue pendiente. Se corrige la instrucción manual, sin cambiar código nativo.

- Reauditorías focales finales iOS y accesibilidad: **PASS, sin hallazgos P0–P3**. Inspección estática confirma
  mensaje/hint derivados del mismo estado y ausencia de nuevas solicitudes de foco por pulsación.
  Orquestador acredita 446 archivos pre/post idénticos, SHA-256
  `017d8ba56e758bceff8ad569b7fad33e659af9c857355cff7bdbfc942d8ca2e9`, manifiestos
  `/tmp/franalonso-083-name-fix-final-before.json` y `/tmp/franalonso-083-name-fix-final-after.json`.
  PLU-37 actualizado con la sesión y corrección, conserva `In Progress`. Confirmación visual posterior del propietario: el error desaparece al escribir.
  Registro documental de este resultado; build/tests N/A, sin cambios de código.

- El propietario confirma búsqueda por «editado», estado sin coincidencias con «zzzinexistente083»
  y recuperación del cliente al borrar la consulta, en iPhone 14 / iOS 26.6.1. Evidencia manual sin AT. Registro documental, build/tests N/A.

### Corrección visual tras capturas AX 5 — 2026-09-09

- El propietario aporta cuatro capturas originales (1170×2532) del iPhone 14 / iOS 26.6.1 en oscuro,
  tras solicitar el tamaño de accesibilidad máximo: `/Users/jesusf/Downloads/IMG_1245.PNG`, `IMG_1246.PNG`,
  `IMG_1247.PNG`, `IMG_1249.PNG`. Inspección visual confirma placeholders duplicados truncados en nombre,
  calle, localidad y provincia; fiscal/postal se ven menores. Título colapsado Nuevo/Editar también truncado.
  Se alcanzan los seis campos y Desactivar. No demuestra entrada con teclado, activación ni AT a ese tamaño.
- La evidencia correctiva anterior C01/C02 cubría el título expandido, no el colapsado: se reabre ese límite.
  Corrección acotada en dos Views: los seis TextField conservan título y accessibilityLabel localizados y
  reciben prompt explícito vacío; ejes, bindings, content types, foco y submit no cambian. No se limita Dynamic Type.
  En tamaños accesibles, Cancelar/Guardar usan xmark/checkmark con área mínima 44×44, nombres localizados
  y large content viewer con texto/símbolo. Otros tamaños conservan acciones textuales; título nativo grande.
- Propuesta independiente de accesibilidad PASS, sin hallazgos bloqueantes. 446 archivos pre/post idénticos,
  SHA-256 `eb6878ffca93a1210e964a2850ba4a6d336ac815212b772006b3091fef15f8e4`, manifiestos
  `/tmp/franalonso-083-ax5-proposal-before.json` y `-after.json`.
- Build Xcode MCP Develop / iPhone 14 **PASS, 10,967 s**:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260909-003114.txt`.
  Navigator/GetBuildLog sin issues; aviso AppIntents persiste en línea 11617. No se repiten tests de negocio:
  solo layout/semántica de Views, sin cambio de lógica; spec 08.3 mantiene lógica cubierta en ViewModels.
- Se inspeccionan un render anterior y cinco correctivos, manifiesto `/tmp/franalonso-083-ax5-preview-manifest.json`:
  alta Large/XXX Large claro y AX 5 oscuro; edición AX 5 oscuro y campos con valor AX 5 claro. Título expandido,
  acciones y label/nombre visibles correctos. Los renders solo cubren el viewport inicial, no título colapsado,
  seis campos completos a AX 5, tamaños reales de objetivos, teclado ni nombres/operación con AT.
- Xcode tenía aviso de sesión terminada por desconexión del iPhone 14; se cierra el aviso, sin relanzar la app
  ni cambiar scheme/destino/fixture. Verificación física de esta corrección pendiente. No se declara resuelto
  el título colapsado por los renders iniciales ni se cierra ADR 0022. Sin commit/push/cierre/live.

- Reauditorías finales focales iOS/estilo y accesibilidad **PASS, sin nuevos hallazgos P0–P3**.
  Dos Swift auditados; especialista inspecciona A01–A05. Título colapsado y operación runtime siguen abiertos.
  446 archivos pre/post idénticos, SHA-256 `ec23ec1cd6f6d5b0e93c8d34888a0e56e804ba768e597d0f3e10ede02e530083`,
  manifiestos `/tmp/franalonso-083-ax5-final-before.json` y `/tmp/franalonso-083-ax5-final-after.json`.
  PLU-37 sincronizado sin cambio de estado; dictámenes registrados después del cotejo de huellas.

- Confirmación posterior del propietario (09-09), tras el guion de relanzar, mantener texto máximo, abrir
  Nuevo cliente, recorrer campos y escribir nombre: «Ahora si, todo correcto y completo». Confirma visualmente
  la corrección de los campos y el título después del scroll en iPhone 14 / iOS 26.6.1. Evidencia comunicada
  por el propietario, sin captura posterior ni inspección directa. No acredita todos los campos con valores
  largos, Guardar/Cancelar con símbolos, long press, foco/anuncios ni tecnologías de asistencia a AX 5.
  Registro documental únicamente, build/tests N/A. Los límites de renders anteriores permanecen históricos.

- Continuación del propietario a texto máximo (09-09): conserva el nombre, escribe Sevilla en Localidad
  y Provincia con teclado abierto, pulsa ✓ Guardar y reabre el cliente; confirma acceso a ambos campos,
  guardado y conservación de los datos. Reporte manual en iPhone 14 / iOS 26.6.1, sin nueva captura.
  No acredita valores largos en todos los campos, Cancelar con ×, long press, foco/anuncios o AT.
  Solo registro documental, build/tests N/A.

- El propietario confirma Cancelar con × a texto máximo (09-09): cambia Localidad de Sevilla a Madrid,
  pulsa ×, vuelve al listado y reabre; conserva Sevilla. Acción y descarte confirmados por reporte manual
  en iPhone 14 / iOS 26.6.1. No acredita long press, valores largos en todos los campos, foco/anuncios o AT.
  Registro documental únicamente, build/tests N/A. Siguiente prueba guiada: VoiceOver en el listado.

- Inicio de VoiceOver comunicado por el propietario (09-09), iPhone 14 / iOS 26.6.1. Se pidió restaurar
  tamaño habitual; categoría exacta no registrada. Anuncios reportados: «Añadir cliente, botón»;
  «Buscar clientes, campo de búsqueda, toca dos veces para editar»; fila con nombre del cliente, «botón,
  abre el formulario de este cliente». Se omite el valor del nombre del registro de evidencia.
  Nombres, roles e instrucciones de esos tres elementos confirmados por reporte, sin audio ni Inspector.
  No acredita apertura, entrada, rotor, foco/restauración, errores o mutaciones con VoiceOver. R03 parcial.
  Registro documental, build/tests N/A; siguiente paso: abrir el cliente y escuchar campos/botones.

- Continuación VoiceOver del propietario (09-09): al abrir el cliente, foco inicial en «Cancelar, botón»;
  después «Guardar, botón», «Editar cliente, encabezamiento», todos los campos y «Desactivar cliente, botón».
  Cada TextField anuncia su etiqueta, obligatorio/opcional, valor si existe, rol campo de texto e instrucción
  de doble toque para editar; informa también del rotor para palabras mal escritas. No se registran valores.
  Cuando el encabezado está colapsado, se lee entre Cancelar y Guardar, conforme al orden visual comunicado.
  Apertura, foco inicial y recorrido lineal confirmados por reporte en iPhone 14 / iOS 26.6.1, sin audio/Inspector.
  La mención del rotor no acredita su uso. No demuestra aún validación, mutaciones ni restauración al salir.
  Registro documental, build/tests N/A; siguiente prueba: retorno y error de nombre vacío con VoiceOver.

- VoiceOver, retorno y nombre obligatorio (reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1):
  Cancelar edición restaura el foco en la fila del cliente desde la que se abrió. Añadir cliente y Guardar
  vacío lleva al nombre; anuncia «Nombre obligatorio, campo de texto, edición en curso, carácter, punto
  de inserción al principio. Escribe el nombre del cliente para poder guardarlo».
  Se acreditan por reporte el retorno de cancelación, foco de validación e instrucción de corrección escuchada.
  Sin audio/Inspector, no se infiere ausencia de duplicados o interrupciones no reportadas. Recuperación al
  escribir, guardado/desactivación y sus retornos, y uso del rotor siguen pendientes. Build/tests N/A, documentación.

- VoiceOver, recuperación y guardado (propietario, 09-09, iPhone 14 / iOS 26.6.1): al escribir
  desaparece el error y al guardar escucha «Cliente guardado». Regresa al listado, pero el foco queda en
  «Cerrar sesión»: defecto de retorno confirmado. Corrección acotada a ClientListScreen: tras cerrar un
  alta, solicita foco VoiceOver en Añadir cliente, con identidad de sesión comprobada y flag consumido
  en onDismiss; edición conserva su retorno nativo. Propuesta independiente PASS, 446 archivos idénticos
  pre/post, SHA-256 `b8dd332c6e29f36a76c92af7c9fa539fb6813c43f90635d8a11f6998bc6f51d5`.
  Build Xcode MCP PASS (8,706 s), Develop / iPhone 14: `BuildProject-Log-20260909-023110.txt`;
  Navigator/GetBuildLog sin issues, log completo mantiene aviso AppIntents (línea 11610).
  Preview de listado inspeccionada: `RenderPreview_result_2026-09-09T003147Z@3x.png`, estado de carga;
  no acredita foco ni anuncios. Tests unitarios no repetidos: ajuste exclusivo de ciclo UI/foco, sin lógica
  de negocio nueva. Pendiente retest físico: alta guardada/cancelada → Añadir, edición cancelada → fila,
  nueva sesión sin foco obsoleto y anuncio completo sin interrupción. Defecto y puerta ADR 0022 abiertos.

- Reauditorías focales finales de retorno VoiceOver: accesibilidad e iOS/estilo PASS, sin hallazgos.
  Read-only operacional verificado por el orquestador: 446 archivos idénticos, SHA-256
  `cb18d5179a9794f3c8ba94ebdc420a7863f5ca93e6c106ee6406f5c5e6cc3d18`.
  PASS estático; el defecto runtime permanece abierto hasta el retest del propietario.

- Retest VoiceOver del propietario (09-09): el ajuste anterior FALLA. Al guardar escucha «Cliente guar…»
  cortado por el retorno al listado, cuyo foco sigue en «Cerrar sesión». Tras esa prueba añade
  `ToolbarSpacer(.fixed, placement: .primaryAction)` para separar Cerrar sesión y Añadir; se conserva
  exactamente. No se atribuye el fallo anterior al separador ni se acredita todavía su efecto táctil.
  Nueva corrección en ClientFormScreen/ClientListScreen: resultado explícito `Completion` por closure
  `@MainActor`; el listado comprueba identidad, conserva resultado efímero y cierra mediante su ViewModel.
  `onDismiss` consume el resultado, solicita foco VoiceOver en Añadir para alta/desactivación y anuncia
  éxito con prioridad `.high`, solo después del cierre. Cancelar/guardar edición mantiene retorno nativo.
  Sin retrasos, UIKit, cambio de datos o anuncio de éxito previo al cierre. La causa exacta del fallo de foco
  anterior no está demostrada. Apple: [Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement),
  [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate).
  Propuesta independiente PASS; 446 archivos pre/post idénticos, SHA-256
  `6762c1286eb036abf5774e1481ec452e8a9a6f75518853f12212e31702680668`.
  Xcode MCP build PASS (8,95 s), Develop / iPhone 14: `BuildProject-Log-20260909-083959.txt`.
  Navigator/GetBuildLog sin issues; log completo conserva aviso AppIntents en línea 11610.
  Previews inspeccionadas, prefijo `RenderPreview_result_2026-09-09T`, sufijo `Z@3x.png`: listado Large
  `064035` (contenido) y AX 5 `064055` (carga); formulario Large `064108`, XXX Large `064143` y AX 5
  `064115`, viewport inicial. Listado XXX Large falla dos veces en código generado preview-thunk:
  `ambiguous use of __designTimeSelection`, junto al Button de toolbar; no se modifica el separador para
  sortearlo. Primera petición XXX Large del formulario y AX 5 compartieron ruta; `064143` sustituye la
  evidencia XXX Large. Las capturas no prueban cierre, foco, locución ni separación junto a Cerrar sesión.
  Sin tests unitarios nuevos ni repetición de negocio: solo coordinación de presentación; spec 08.3
  mantiene esa lógica cubierta en ViewModels. Defectos de foco/anuncio y ADR 0022 abiertos hasta retest:
  guardar/cancelar alta → Añadir, cancelar/guardar edición → fila, desactivar → Añadir y anuncios completos.

- Reauditorías finales de la nueva finalización explícita: iOS/estilo y accesibilidad PASS estático,
  sin hallazgos P0–P3. Read-only operacional verificado: 446 archivos idénticos, SHA-256
  `a9ed1f28d1f457b2cc9dfdd149c7ccf59ddf309e18e0997672510bf83207161a`.
  No acredita resolución runtime: foco y locución pendientes del retest del propietario.

- Retest posterior del propietario (09-09, iPhone 14 / iOS 26.6.1): «Cliente guardado» se escucha completo;
  al volver sigue anunciando «Cerrar sesión, botón». El anuncio completo queda confirmado por reporte;
  el defecto de foco sigue abierto. Ajuste mínimo posterior: `.accessibilityDefaultFocus($addButtonIsFocused, true)`
  en la raíz del listado, configurando Añadir como destino predeterminado de VoiceOver cuando el sistema
  evalúa foco inicial/de retorno. API nativa iOS 26 verificada en SDK y
  [Apple](https://developer.apple.com/documentation/swiftui/view/accessibilitydefaultfocus(_:_:)).
  Propuesta independiente PASS, sin regresión inevitable identificada; no demuestra corrección runtime.
  Huellas pre/post idénticas de 446 archivos: `eb926847e90b368e7aacb4a64187e5caddee477a7c9c7d9c5ab0c53412e202c1`.
  Se mantienen secuencia de anuncio y ToolbarSpacer del propietario. Build Xcode MCP PASS (8,724 s):
  `BuildProject-Log-20260909-085614.txt`; Navigator/GetBuildLog sin issues, aviso AppIntents en línea 11535.
  Previews listado XXX Large `RenderPreview_result_2026-09-09T065652Z@3x.png` y AX 5
  `RenderPreview_result_2026-09-09T065657Z@3x.png` inspeccionadas, contenido visible. Large falla dos veces
  con la ambigüedad de `__designTimeSelection` en código generado del preview; queda como limitación.
  No cambian geometría ni negocio; tests unitarios no repetidos. Retest de foco pendiente: alta → Añadir,
  cancelación/guardado de edición → fila de origen, desactivación → destino estable. El foco predeterminado
  también debe comprobarse al entrar al listado y durante búsqueda; capturas no acreditan AT. ADR 0022 abierto.

- Reauditoría focal de foco predeterminado PASS estático; 446 archivos idénticos pre/post, SHA-256
  `c0124cf0efc173f2dd9b4922785c1342bd3a128840bc35db8b0f8340237ebbc5`. Defecto de foco pendiente de retest.

- Retest final de alta y cancelación de edición con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  tras guardar el alta el foco queda en la fila del cliente recién creado. El propietario confirma después
  que abrir ese cliente y Cancelar devuelve el foco a la misma fila. Ese destino conserva el contexto del
  alta y se acepta como resultado válido; no se exige desplazarlo a Añadir si iOS restaura la fila creada.
  El anuncio completo «Cliente guardado» ya fue confirmado en el retest anterior. Queda verificado por reporte
  el retorno contextual en estos dos recorridos, sin audio/Inspector ni atribución causal del comportamiento
  a un modificador concreto. No se extrapola a guardado de edición, alta cancelada, desactivación o búsqueda.
  Siguiente prueba: modificar un campo opcional, Guardar con VoiceOver y comprobar anuncio, foco y valor al reabrir.
  Solo documentación; build/tests N/A. ADR 0022 y 08.3 siguen abiertos por el resto de evidencia pendiente.

- Guardado de edición con VoiceOver confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  modifica Localidad, guarda, escucha «Cliente guardado» completo, vuelve el foco a la misma fila y al
  reabrir se conserva el cambio. No se registra el valor introducido. Resultado por reporte, sin audio ni
  Inspector; no acredita otros recorridos. Siguiente prueba: apertura y recorrido de la confirmación de
  desactivación con VoiceOver, sin ejecutar todavía la acción destructiva. Build/tests N/A, documentación.

- Confirmación de desactivación con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): al abrirla
  anuncia «alerta», lee título, contenido y «Desactivar, botón». Tras pedir cancelar mediante el gesto de
  escape, el propietario informa foco en «Desactivar cliente, botón» del formulario. Se acredita la lectura
  del diálogo y el retorno al control de origen tras cancelar; no se infiere desactivación efectiva ni
  eliminación del cliente. Siguiente prueba: confirmar la desactivación del cliente de prueba y comprobar
  anuncio, desaparición de su fila y destino del foco. Reporte sin audio/Inspector; build/tests N/A documental.

- Desactivación y estado vacío con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): confirma
  «Cliente desactivado» completo y, al volver, escucha «Los clientes aparecerán aquí cuando estén disponibles».
  Después de abrir Añadir y cancelar sin rellenar, informa «No hay clientes». Desde ese estado confirma
  que alcanza Añadir cliente con tres deslizamientos a la izquierda y puede abrirlo de nuevo. Son destinos
  contextuales válidos para una lista vacía; no se exige retorno a Añadir. El estado vacío comunicado tras
  desactivar es coherente con la retirada del último cliente; no se infiere inspección de persistencia.
  Reportes sin audio/Inspector; búsqueda con VoiceOver y resto de tecnologías/criterios siguen pendientes.
  Siguiente prueba: búsqueda con coincidencia y sin resultados sobre un cliente de prueba.
  Build/tests N/A: actualización documental, sin cambios de código ni cierre de subfase.

- Búsqueda con VoiceOver confirmada por el propietario (09-09, iPhone 14 / iOS 26.6.1): crea un cliente
  de prueba, busca parte del nombre y alcanza/abre su fila sin dificultad. Al introducir una consulta sin
  resultados escucha «Sin coincidencias»; al borrar la consulta vuelve a aparecer el cliente. Se verifica
  por reporte búsqueda con coincidencia, anuncio de ausencia y restauración de resultados; no se infiere
  foco concreto tras cada cambio ni ausencia de interrupciones no reportadas. Sin audio/Inspector.
  Continúa la comprobación del rotor por encabezamientos. Build/tests N/A, actualización documental.

- Rotor VoiceOver por encabezamientos confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  dentro del formulario encuentra «Editar cliente» y se anuncia como encabezamiento. Se acredita este
  recorrido del rotor, no todos sus modos ni encabezamientos de otras pantallas. Reporte sin audio/Inspector.
  Continúa Control por voz en el listado; no se extrapola evidencia entre tecnologías de asistencia.
  Build/tests N/A: actualización documental, sin código ni cierre del gate ADR 0022.

- Control por voz iniciado por el propietario (09-09, iPhone 14 / iOS 26.6.1). «Mostrar nombres» en
  listado expone «Añadir cliente», «campo de búsqueda» y el nombre del cliente sobre su fila. Al abrir
  Añadir por voz, el formulario muestra Cancelar, Guardar y etiquetas de campos con obligatorio/opcional,
  según reporte hasta el final. Se omiten valores de clientes del registro. Confirma después alta completa
  usando solo voz: activar Nombre obligatorio, dictar nombre de prueba, activar Guardar y aparición en listado.
  Se acreditan nombres y operación de ese recorrido, no edición/cancelación, búsqueda ni desactivación por voz.
  Sin audio/Inspector. Siguiente prueba: abrir, editar un campo opcional y cancelar por voz, comprobando descarte.
  Build/tests N/A documental; ADR 0022 sigue abierto, sin extrapolar evidencia a otras tecnologías.

- Control por voz, edición cancelada y desactivación (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  confirma abrir el cliente, introducir Localidad, Cancelar y comprobar al reabrir que el cambio se descarta.
  Confirma también desactivación por voz, incluida la confirmación, y desaparición del cliente del listado,
  todo a la primera. Se completa el muestreo representativo de Control por voz: identificación, alta,
  entrada, edición/descartado y acción destructiva confirmada. Sin audio/Inspector; no se atribuyen otros
  recorridos no ejecutados. El propietario pide rigor proporcional y evitar pruebas repetitivas.
  Plan restante agrupado: Inspector y variantes/preferencias pendientes; recorrido breve de teclado y
  Control por botón cuando se disponga de esa configuración; estados de fallo/carga conservan su límite
  de fixture. No repetir CRUD completo con cada tecnología ni todas las combinaciones visuales. R07 se
  actualiza con la evidencia física AX 5 ya comunicada. ADR 0022 permanece abierto sin convertir pendientes
  en Pasa ni N/A por reducir repeticiones. Build/tests N/A: documentación únicamente.

- Teclado del Mac en Simulator (propietario, 09-09): no dispone de teclado externo para el iPhone físico.
  Se indicó iPhone 17e / iOS 26.5, conectar el teclado del Mac y activar Acceso total mediante teclado
  dentro de iOS. En ese contexto guiado informa que Tab o cursores hacen aparecer el primer foco, pero
  para avanzar usa los cursores; alcanza todas las acciones. Confirma después abrir Añadir con teclado,
  escribir un nombre, activar Cancelar, volver al listado y continuar moviendo el foco sin dificultad.
  Muestreo representativo de navegación, foco visible, entrada y salida completado por reporte. No se
  atribuye al iPhone físico ni a todos los recorridos de Full Keyboard Access; ajustes no inspeccionados
  directamente por el orquestador, sin captura/Inspector. No repetir CRUD por teclado. Control por botón,
  Inspector y adaptación/preferencias conservan sus pendientes. Build/tests N/A documental; ADR 0022 abierto.

- Control por botón, muestreo representativo (propietario, 09-09, iPhone 14 / iOS 26.6.1): tras la
  configuración guiada de pantalla completa/seleccionar ítem y exploración automática, observa dos grupos:
  Cerrar sesión/Añadir/Buscar y las pestañas. Confirma entrar al grupo, abrir Añadir, recorrer el formulario
  incluido Cancelar y volver al listado. Se acredita por reporte exploración, selección, apertura y salida
  sin bloqueo; no se infiere entrada de texto, confirmación destructiva ni todos los recorridos de esta AT.
  Sin audio/Inspector. No repetir CRUD con Control por botón. Sigue una prueba combinada de preferencias
  visuales y movimiento. Build/tests N/A documental; resto de evidencia ADR 0022 permanece abierto.

- Preferencias combinadas confirmadas por el propietario (09-09, iPhone 14 / iOS 26.6.1): tras indicar
  Aumentar contraste, Reducir transparencia, Diferenciar sin color y Reducir movimiento simultáneamente,
  confirma listado y apertura/cancelación del formulario legibles, botones utilizables y transiciones sin
  problemas. Muestreo conjunto por reporte; no acredita medición de ratios, cada combinación ni inspección
  directa de ajustes. Se indicó restaurar preferencias habituales al terminar; restauración no confirmada.
  Continúa adaptación mínima en iPad (ADR 0026 conserva iPad adaptativo); Inspector y otras variantes no
  observadas conservan límites. Build/tests N/A documental; sin cambios de código ni cierre de subfase.

- Adaptación iPad confirmada por el propietario (09-09): listado/formulario correctos en todas las
  orientaciones probadas y en la ventana más pequeña permitida, incluidos recorrido de campos y acceso a
  Cancelar/Guardar. La inspección CUA posterior identifica el simulador real como iPad Air 11-inch (M4),
  iOS 26.5 (se había sugerido Pro 11; no se atribuye el resultado a ese modelo). Captura CUA muestra la
  ventana estrecha en landscape con Editar cliente, Cancelar/Guardar y campos finales/Desactivar visibles,
  sin solapamiento observado. Tamaño exacto de ventana no medido; no demuestra RTL ni todas las variantes.
- Nuevo intento Accessibility Inspector (Xcode.app, no beta), 09-09: seleccionada Fran DEV en el simulador,
  Run Audit no proporciona filas ni captura. El modo Inspection tampoco obtiene elemento/propiedades al
  usar el puntero sobre el formulario. Se desactiva el puntero y se deja la pestaña Audit con Fran DEV.
  No se interpreta vacío como cero incidencias. Pendiente comprobación manual de Run Audit por el propietario;
  no se modifica código ni se repiten recorridos funcionales. Build/tests N/A documental; ADR 0022 sigue abierto.

- Inspector, 09-09, capturas del propietario entre 18:55 y 19:02: ya se obtienen informes.
  Audit 1, ventana mínima: cuatro avisos de contraste y uno de Dynamic Type, con resaltados fuera
  de la ventana; atribución no confirmada. Audit 2, ventana ampliada: tres avisos de contraste
  (1,00: #000200/#000100; 1,01: #2B2B2D/#2C2C2E; 1,49: #2C2C2E/#000300) y uno de texto
  potencialmente inaccesible. Los resaltados corresponden a fondo superior, Calle y número,
  Desactivar cliente y Jornada detrás del modal, respectivamente. Los nueve avisos del Inspector
  son el agregado de ambos informes, no nueve hallazgos nuevos. El segundo no reproduce el aviso
  Dynamic Type; no se interpreta como corrección acreditada.
  Inspection confirma Desactivar cliente con nombre, rol botón, acción Activate y jerarquía dentro
  del formulario modal. El ratio informado no incluye el rojo del texto y no acredita su contraste
  real. Inspection no recupera propiedades del aviso Calle y número. Atribución y medición real
  pendientes; no se descartan avisos como falsos positivos ni se cambian colores por estas capturas.
  Evidencia original local: Desktop/Captura de pantalla 2026-09-09 a las 18.55.27.png y serie
  19.01.01.png–19.02.56.png. Sin cambios ejecutables; build/tests N/A documental.

- Corrección focal autorizada 09-09: `ClientFormContent` aplica `.foregroundStyle(.errorInk)`
  únicamente al texto Desactivar cliente. Conserva rol destructivo, acción, disabled y 44 pt.
  Revisión independiente previa y final estática: PASS. Ratios del asset frente a blanco/#2C2C2E:
  normal 6,57/5,00:1; contraste incrementado 9,12/6,89:1. No son una medición del modal final.
  Build Xcode MCP PASS (9,115 s), log BuildProject-Log-20260909-191906.txt; persiste aviso
  AppIntents metadata extraction skipped, línea 10886, sin errores. Previews Edit long profile
  Light/Dark generados e inspeccionados: RenderPreview_result_2026-09-09T172001Z@2x.png y
  RenderPreview_result_2026-09-09T172016Z@2x.png. Texto completo; muestreo ICC convertido a sRGB
  consistente con ErrorInk. El preview oscuro usa #1C1C1E, distinto del modal #2C2C2E.
  Sin repetir tests de negocio ni CRUD por un delta de color. Retest visual del modal actualizado
  pendiente; no cierra los otros avisos Inspector ni ADR 0022. Sin commit/push.

- Retest visual del propietario, 09-09 a las 19:23: confirma «Se ve bien» tras ejecutar la
  corrección. Captura local `/Users/jesusf/Desktop/Captura de pantalla 2026-09-09 a las 19.23.57.png`:
  Desactivar cliente completo y legible sobre la superficie oscura del formulario. Retest visual
  focal completado; no se repite la acción destructiva. No acredita nueva auditoría Inspector
  ni cierra los restantes avisos o la puerta general ADR 0022. Build/tests N/A documental.

## Reconciliación previa a commit/push — 2026-09-09

- El propietario autoriza publicar tras reconciliar evidencia, triar Inspector y revisión final.
- Snapshot y matriz actualizados: R03–R08 tienen muestreo representativo; no son pendientes globales.
- Triaje por aviso, RTL sintético y límites reales constan en el cierre del registro accesible 08.3.
- Dos revisores independientes sin nuevos defectos ejecutables; 446 archivos pre/post idénticos,
  SHA-256 `da8d69ef75a69414034f8db18df2cde9ca03f17848f4b9088c51f673aa590f14`.
- Se excluye del commit el único cambio temporal del scheme Develop (fixture signed-out activada),
  conservándolo localmente para no alterar la sesión. ToolbarSpacer del propietario se incluye.
- La publicación no cierra ADR 0022: R09 con AT y medición completa no textual/objetivos siguen limitados.
  PLU-37 permanece In Progress; no PR/merge/Done/08.4/live.

## Siguiente puerta

Completar la evidencia accesible pendiente de 08.3. Implementación, auditorías y regresión focalizada
disponibles; subfase abierta según ADR 0022. Commit/push de 08.2 ya completados; entrega de 08.3 y subfases posteriores
separadas. Commit/push de implementación 08.3 completados en `553394833376c565ee0a259e35b931e283e59948`;
remoto `codex/plu-37-phase-08-3-client-screens` verificado idéntico. 24 archivos publicados; fixture local excluida.
PR, merge, cierre y live no autorizados.

Reauditorías documentales finales PASS; huella de 446 archivos idéntica pre/post:
`cf1610776435e4981e72eed52e47366073664c9f645f30c18baa52a1876a5e4d`. Gobernanza y staged diff-check PASS.

Pruebas focales posteriores: cancelación táctil de Añadir confirmada por propietario. Autorrelleno
ofrece sugerencias/menú, pero selección en ficha de Contactos no inserta; causa no determinada.
Propósitos semánticos de campos inspeccionados y coherentes; inserción automática aún pendiente.

Autorrelleno: propietario confirma inserción al tocar la sugerencia del teclado. Vía nativa de
sugerencias operativa; incidencia del selector Contactos separada, sin causa atribuida.

Preparación temporal autorizada de fallo de guardado (09-09): únicamente factoryComposed dentro de
FRANALONSO_AUTH_FIXTURE; primer guardado por formulario espera 3s cancelables y falla antes de escritura,
segundo usa adaptador original. No cambios live/Views/Domain. Backup byte a byte en
`/tmp/fa083-before-save-failure-AppDependencies.swift`, restaurar después de sesión; NO publicar harness.
Propuesta y revisión independiente final PASS; huellas pre/post verificadas. Build MCP PASS8,958s,
log200846, aviso AppIntents10912. Snippet de verificación: primer intento no compila por importFoundation
omitido; segundo con imports corregidos agota timeout60s. No acredita conteos/resultado runtime.
Pendiente prueba guiada VoiceOver de guardado/fallo/reintento. No cubre fallo de carga inicial.

Retest VoiceOver del fallo de guardado: propietario escucha «No se ha podido completar la operación.
Inténtalo de nuevo». Confirma nombre conservado y segundo Guardar exitoso, anuncio Cliente guardado,
retorno al listado con una sola fila. Guardado fallido y recuperación acreditados por reporte manual;
no se extrapola a fallo de lectura inicial, desactivación ni conteos internos de la cola.
Harness temporal retirado: AppDependencies.swift restaurado byte a byte al backup y HEAD.
La app ya instalada mantiene el harness hasta la siguiente ejecución de la versión restaurada.

Medición runtime iPad20:24–20:26: cuatro apariencias, Desactivar5,001/6,548/9,125/5,960:1,
etiquetas≥12,058:1 e iconos≥5,206:1 en muestreo ICC. HitRegion activado sin avisos en viewport final.
Informe aún con1contraste bajo toolbar,2DT y2detección; no conformidad global. Apariencia restaurada.
Detalle y límites en registro accesible, sin cambio ejecutable.


### Reconciliación posterior a pruebas focales — 2026-09-09

Cancelación táctil de Añadir, inserción por sugerencia y fallo de guardado/reintento con VoiceOver
completados. Harness retirado y versión restaurada relanzada. Matriz R09 actualizada: lectura inicial
fallida/Reintentar sigue sin evidencia runtime. Contraste Desactivar/etiqueta/icono postal suficiente
en cuatro apariencias. Inspector: detecciones del formulario corresponden a Jornada/Catálogo bajo
modal; listado sin Contrast/Hit Region/Element Detection, seis Dynamic Type por atribuir. Pendientes
concretos y revisión independiente en la reconciliación vigente del registro 08.3; no repetir recorridos
manuales completados. No cambios ejecutables ni nueva autorización de PR/merge/cierre.

Atribución del listado completada: cinco etiquetas de sidebar y fila cliente. Revisión focal independiente
sin nuevo defecto ejecutable; huella de 446 archivos estable. Pendientes: lectura inicial fallida/Reintentar
con VoiceOver y comprobaciones del agente de escalado sidebar/fila, buscador/foco y geometría toolbar/
confirmación. Reutilizar estilos equivalentes. No repetir las pruebas manuales ya acreditadas.


### Bloque 1 — 2026-09-09 23:50–23:58

Escalado sidebar/fila confirmado mediante dos incrementos y restaurado. Buscador6,97:1, icono15,88:1,
error5:1; superficies visibles toolbar44pt/confirmación48pt. Capturas/mediciones en registro08.3.
Nuevo dato por disponer: rojo nativo del diálogo4,11:1; falta verificar tipografía/clasificación antes
de corregir. Foco de teclado sin captura válida con CUA; no confundir overlaysInspector. No cambios
ejecutables ni datos; app en listado, preferencias restauradas. Bloque1 aún no globalmente aprobado.

Revisión focal independiente confirma muestreo de escalado/geometría suficiente y conserva potencial
P2 contraste nativo4,11:1 hasta acreditar tipografía grande o corregir. Foco: solicitar únicamente
captura de Añadir enfocado sin Inspector; no repetir navegación. Huella446 idéntica, gobernanza PASS.


### Foco de teclado — 2026-09-10

Propietario aporta tres capturas; primera acredita foco Añadir solicitado. Medición ICC→sRGB: banda
3,577:1 exterior/4,271:1 interior; banda oscura8,862:1 exterior. Petición de captura resuelta, sin
repetir recorrido. Las otras dos aportan contexto, no resuelven tipografía/contraste oscuro del diálogo.
Pendientes: disposición de contraste nativo y prueba VO de lectura inicial/Reintentar.


## Corrección de contraste de confirmación — 2026-09-10 00:54

Xcode Debug View Hierarchy expuso el UILabel de Desactivar: .SFUI-Medium 16 pt, systemRedColor.
El ratio oscuro previo 4,113:1 no alcanza 4,5:1; queda confirmado el defecto y sustituida la
incertidumbre tipográfica anterior. Una prueba mínima de foregroundStyle en confirmationDialog
fue ignorada por el sistema y retirada antes de implementar la alternativa revisada.

ClientFormScreen presenta ahora ClientDeactivationConfirmationView en popover nativo, con adaptación
vertical a sheet, Cancelar explícito, rol destructivo y colores opacos ErrorInk/Surface. Reutiliza
recursos, estado y operación existentes. Foco inicial limitado a VoiceOver, título encabezamiento,
labels pulsables de altura mínima 44 pt más padding y contenido desplazable cuando falta altura.
Propuesta y revisión estática final independientes por close083_accessibility: PASS. El revisor
no escribió archivos ni operó UI; no se aporta digest pre/post completo para esta segunda revisión.

Build Xcode MCP PASS 13,683 s, log BuildProject-Log-20260910-005002.txt; único warning encontrado:
AppIntents metadata extraction skipped, ya existente. No se afirma cero warnings globales.
Previews renderizadas e inspeccionadas: Large Light, AX 5 Dark, XXX Large Light Increased Contrast,
Large Dark Increased Contrast; texto sin truncamiento. Artefactos RenderPreview_result_2026-09-09T
225036Z, 225045Z, 225143Z y 225144Z (@3x.png), directorio ActionArtifacts/default/RenderPreview.
Ratios calculados de los assets opacos ErrorInk/Surface: Light 5,244; Dark 5,001; Light High 7,367;
Dark High 8,411. Estas medidas de recursos y previews no son auditoría Inspector del nuevo popover.

Runtime iPhone 17e/iOS 26.5, sesión sintética: encabezamiento, mensaje y ambos botones expuestos;
Cancelar conserva formulario y datos; reabrir y confirmar cierra formulario y vuelve a No hay clientes.
Captura nativa: /Users/jesusf/Desktop/Simulator Screenshot - iPhone 17e - 2026-09-10 at 00.53.40.png.
Pendiente VoiceOver focal del nuevo modal (entrada, Cancelar/retorno y confirmación/anuncio), además
R09 lectura inicial fallida/Reintentar. No repetir CRUD completo ni el fallo de guardado ya validado.
Fixture signed-out del scheme permanece local. Sin PR, merge, cierre ni avance de subfase.


## Corrección de posición tras IMG_1250 — 2026-09-10

El propietario rechaza la disposición del popover: arriba a la izquierda, sobre la barra del formulario.
La comprobación anterior de contraste/semántica no acreditaba una presentación visual adecuada.
Sustituido por sheet nativa con detents medium/large y large para tamaños de accesibilidad, ancho
flexible y alineación superior. Mantiene colores, roles, Cancelar, escape y operación existente.
Propuesta independiente focal PASS. Build MCP PASS 8,469 s, BuildProject-Log-20260910-082837.txt;
único warning encontrado AppIntents metadata ya existente. Previews de presentación real inspeccionadas
062920/062928: hoja inferior estándar y hoja grande AX5; en AX5 contenido desplazable para acciones.
No se acreditan todavía presentación iPad, cierre interactivo ni retorno/anuncios VoiceOver de la sheet.
IMG_1250 muestra foco en encabezamiento del popover anterior; no extrapolar ese foco a esta versión.
Siguiente paso: confirmar apariencia corregida y retest VO focal; R09 lectura/reintento sigue pendiente.


## Jerarquía, botones y altura tras IMG_1251 — 2026-09-10

El propietario rechaza título poco destacado, botones sin delimitación y vacío inferior de la sheet.
Corregido en ClientDeactivationConfirmationView: título title2 bold, botones headline delimitados
por contornos redondeados y área mínima de 52 pt. Cancelar usa borde TextSecondary y Desactivar
ErrorInk sobre Surface. Ratios calculados contra Surface (Light/Dark/Light High/Dark High):
borde Cancelar 4,555/5,206/10,042/11,183; borde Desactivar 5,244/5,001/7,367/8,411.

La prueba de form.fitted aislado no redujo la altura de iPhone. Se usa onGeometryChange sobre
contenido intrínseco con padding para detent height, estado exclusivamente visual redondeado;
AX conserva large y ScrollView. No se añade lógica de negocio ni tests unitarios de geometría.
Fuente Apple consultada: https://developer.apple.com/documentation/swiftui/view/presentationsizing(_:).
Build MCP085713 PASS7,232 s; único warning encontrado AppIntents metadata previo. Preview normal
Dark065745 inspeccionada: hoja compacta, título jerárquico y botones delimitados. Los overrides
sobre una sheet no acreditan AX5 si la captura conserva el tamaño normal; no inferir por el nombre.
Propuesta y revisión estática final independientes PASS. Huellas pre/post del alcance Swift idénticas:
View07691027ff52aac0c265b166625bbe5345dad9ea37aec5acf201f92cddcb409d;
Screen29a65239af2a59a7b815a3b21f77a9fd2514f1fd9d9d183a37a2032ada216c55.
Pendientes aceptación visual física, adaptación iPad y VoiceOver focal/R09; sin cierre ni entrega.

Preview AX5 explícita065911 inspeccionada: título y contenido grandes sin truncamiento horizontal;
Desactivar queda parcialmente fuera del viewport inicial, con ScrollView declarado. Alcance por
desplazamiento y VoiceOver pendiente de runtime; no se afirma desde esta imagen.


### Ajuste final solicitado: título centrado — 2026-09-10

Propietario acepta la disposición con ajuste de centrado del título. Añadidos exclusivamente
multilineTextAlignment(.center) y frame(maxWidth: .infinity) al título; conserva semántica/foco.
Propuesta focal independiente PASS; build Xcode MCP092935 PASS8,092 s, aviso AppIntents previo.
No repetir pruebas funcionales por alineación. VoiceOver focal/R09 siguen pendientes.


### VoiceOver de confirmación actual — reporte del propietario 2026-09-10

Recorre todos los elementos de la sheet correctamente. Empieza por «Tirador de la hoja, media
pantalla, botón, toca dos veces para cerrar la hoja»; restantes elementos correctos según reporte.
El componente declara presentationDragIndicator(.visible): el tirador pertenece a la presentación
nativa. No se acredita foco inicial en título aunque exista AccessibilityFocusState. El recorrido
por el tirador no bloquea el contenido. No se infiere todavía ejecución del cierre, retorno de foco
ni confirmación/anuncio de la versión actual. Próximo paso focal: Cancelar y retorno al formulario.


VoiceOver, propietario 2026-09-10: Cancelar en la sheet actual cierra únicamente la confirmación
y devuelve el foco a Desactivar cliente del formulario. Confirmado por reporte manual; no acredita
aún confirmar/desactivar y anuncio de esta versión. Siguiente paso focal: confirmar una vez.


### Confirmación efectiva con VoiceOver — propietario, 2026-09-10

Al cerrar la confirmación comienza una locución «cliente desa…» que se interrumpe; después se
cierra el formulario y en el listado escucha «Cliente desactivado» completo y «No hay clientes».
Resultado final, desactivación y retorno contextual confirmados por reporte. Se registra la
interrupción transitoria como observación no bloqueante, sin atribuir causa ni duplicado de éxito.
Inspección actual: una única emisión explícita de éxito en ClientListScreen.restoreFormFocus/onDismiss.
Revisión independiente focal read-only: no defecto adicional demostrado; no modificar sincronización
ni repetir el recorrido cuando el resultado final completo y el destino están confirmados.
R09 lectura inicial fallida/reintento sigue pendiente. Solo documentación; build/tests N/A.


### R09 preparado para prueba guiada — 2026-09-10 12:43

Autorización «preparala entonces». Harness TEMPORAL en App/AppDependencies+ClientForm.swift:
InitialReadFailureRepository privado, aislado por actor, falla primer client(id:) por formulario
con persistenceUnavailable y luego delega. Task.checkCancellation precede al consumo del fallo.
Gates FRANALONSO_AUTH_FIXTURE + ApplicationLaunchPlan.authenticationFixture. Lista y adapter
mutador intactos; alta normal, abrir edición produce error y Reintentar carga perfil existente.
No valida VoiceOver por sí mismo. Propuesta independiente PASS; prueba manual pendiente.

Xcode MCP27: Develop, iPhone14 de Jesús/iOS26.6.1, SDK27, argumento signed-out activo.
Build124238 PASS8,429s, único warning encontrado AppIntents metadata previo. RunProject124255
PASS3,577s, app lanzada PID15053. No se modifican plist/pbxproj locales ajenos ni scheme.

Restaurar únicamente AppDependencies+ClientForm.swift tras la prueba y recompilar:
original /tmp/franalonso-r09-clientform-original.swift
SHA256 25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182.
Harness preparado SHA256 7890ff55aab238baf41afbf4ba123606a50fceff42b6e75df081bbe70531ad28.
Excluir este archivo temporal de cualquier entrega; comprobar que no hay cambios posteriores ajenos
antes de restaurar. No commit/push/PR/cierre/live.


### R09 confirmado y harness retirado — 2026-09-10 12:55

Propietario confirma Reintentar → campos cargados con datos y recorribles por VoiceOver; Cancelar
→ listado con foco en el cliente abierto. Recorrido R09 de lectura fallida/reintento/retorno confirmado
por reporte manual, sin atribuir anuncio inicial exacto no transcrito. No repetir prueba.

Harness restaurado byte a byte desde copia verificada: AppDependencies+ClientForm.swift SHA original
25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182, diff contra HEAD vacío.
Mejora visual prometida tras IMG1252: Reintentar usa primaryActionStyle existente (cápsula rellena),
conserva texto, minHeight44, acción y disabled. Ratios de assets OnBrandPrimary/BrandPrimary
4,945/9,812/10,554/12,280. Propuesta y revisión final focal read-only PASS.
Build MCP125405 PASS8,46s, warning AppIntents previo. Preview Load failure12:55:29 inspeccionada,
iPhone18Pro/iOS27, control visiblemente delimitado; primer render agotó tiempo y reintento pasó.
RunProject125546 PASS8,152s en iPhone14: app relanzada sin inyección del error.
Solo resta reconciliar evidencia/límites y entrega autorizada; no se declara subfase cerrada.
Los enlaces históricos a artefactos eliminados siguen pendientes de reconciliación documental.

## Entrega de correcciones autorizada — 2026-09-10

El propietario autoriza revisar el diff, commit y push. Alcance: ClientFormScreen, ClientFormContent,
ClientDeactivationConfirmationView, tres registros documentales y CHANGELOG. Configuración local
plist/pbxproj/scheme excluida; harness fuera del diff. Se conservan build125405, ejecución125546,
auditorías focales y evidencia manual ya obtenidos: no hay código nuevo desde esas validaciones.
Gobernanza y diff-check se repiten para la entrega. Hash y remoto se verifican tras publicar en Linear;
este registro queda identificado por su propio commit. Sin PR, merge ni cierre de PLU-37.

## Entrega de configuración autorizada — 2026-09-10

Tras publicar69acaa4, el propietario solicita commit/push de la configuración pendiente para dejar
el árbol limpio. Solo quedan plist y pbxproj; el scheme ya coincide con HEAD, sin intervención en
esta entrega. Se conserva el traslado de CFBundleDisplayName y NSFaceIDUsageDescription a las cuatro
configuraciones del target; valores idénticos, sin nuevos permisos ni cambios de privacidad.

Revisión independiente read-only de estándares PASS: equivalencia estática de las cuatro
configuraciones y plist. Build oficial Xcode MCP141420 PASS4,129s, Develop/Simulator. Lectura del
plist generado: nombre Fran DEV, descripción FaceID original y flags Analytics false/true conservados.
El log incluye el aviso previo de extracción AppIntents; no se afirma cero warnings ni build de
Production. Sin cambio lógico: tests y nueva auditoría UI N/A. Gobernanza y staged diff comprobados
antes del commit. Commit/push autorizados; PR/merge/cierre e inicio08.4 no forman parte de esta entrega.
