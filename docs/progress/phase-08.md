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

## Siguiente puerta

08.1 implementada, validada y auditada localmente. El propietario autoriza commit/push de 08.1 e inicio de 08.2
el 2026-09-08; ejecución y verificación en curso. PLU-34/PLU-35 continúan `In Progress`.
PR, merge, cierre de issues y cierre administrativo PLU-25 permanecen independientes.
