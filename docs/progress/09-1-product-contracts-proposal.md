# Propuesta 09.1 — Contratos y operaciones de producto

Fecha: 2026-09-29. Fase [PLU-49](https://linear.app/plusprojects/issue/PLU-49), subfase
[PLU-50](https://linear.app/plusprojects/issue/PLU-50). Propuesta aprobada el29/09 con «si, adelante, implementa», tras PRE PASS.
La implementación de09.1 está autorizada; entrega Git y cierres conservan su puerta separada.

## Autoridad, inicio y baseline

El propietario solicita «OK, abre issue y rama e inicia fase 09». Se crean las issues de fase y primera subfase,
asignadas a Jesus Franco, y la rama `codex/plu-50-phase-09-1-product-contracts`, desde `7ec61a5`.
`main`, `origin/main` y remoto coinciden, árbol limpio antes del inicio. No se autoriza entrega Git ni cierre.
La [spec09](../specs/09_products_stock.md) conserva el orden09.1–09.7; no se agrupan todas las subfases en una entrega.

Aplican constitución, guía de desarrollo, política Swift y ADR0002/0006/0011/0014/0018/0029/0030.
ADR0030 permite comenzar tras08.8a funcional sin esperar08.9 o el cierre integral de fase08.
Product es inventario; precio, descuento e impuestos pertenecen a Service. Stock deriva de movimientos.

Baseline técnica reutilizada: árbol ejecutable de `0c76967`, integrado por PR16/`b334c04`, sin cambios de código
hasta `7ec61a5`. Xcode MCP:847 declaraciones/121 suites,1.120 resultados PASS; Develop3,541s y Production20,723s
PASS. Aviso AppIntents conocido; no se afirma cero warnings globales. Evidencia completa en [fase08](phase-08.md).
Para esta preparación documental, tests/build/previews nuevos N/A; se repetirán los afectados al implementar.

Conexión actual comprobada: Xcode MCP estable27.0, Service `workspace-EYu6rxi7hg`, ruta FranAlonso.xcodeproj,
esquema FranAlonso-Develop, destino activo iPhone18Pro Simulator/iOS27.0, SDK Simulator-iOS27.0. No se cambia destino
ni se lanza la app. Configuración en disco: iOS26.0, Swift6, strict concurrency complete, aislamiento por defecto
nonisolated y warnings Swift/Clang como errores. No se cambia toolchain, target, esquema ni dependencias.

## Código real y hueco

`Product.swift` ya contiene identidad, nombre y estado active/inactive. `ProductRepository` ofrece observar y guardar
snapshots; `ObserveProductsUseCase` y `SaveProductUseCase` delegan esa superficie. No hay lectura individual ni
operaciones explícitas de crear, editar o desactivar, entrada validada, búsqueda o errores propios de Domain.

La vertical05.10 existe: DefaultProductRepository, ProductPersistenceActor, ProductLocalDataSource,
ProductContextualPersistenceAdapter, DTO/mapping, cola causal, observación, conflictos, tombstones, feed y retry.
`persistPendingUpsert` acepta localmente producto y operación en una frontera, evita resurrección y bloquea conflicto.
El borrado técnico existe, pero elimina el snapshot y es distinto de pasar a inactive. El motor permanece inactivo.

El precedente08.1 de Clients valida el patrón de entrada editable y mutaciones locales sin suspensiones. No se copia
su desactivación: Client no posee inactive y retiene información firmada mediante otra política.

## Comportamiento aprobado

1. Añadir `ProductProfile` como entrada editable con solo nombre: trim de whitespace/newline exterior y rechazo del
   resultado vacío. Conservar espacios interiores y grafía. Construcción y Decodable garantizan la misma invariante.
   No endurecer retroactivamente Product/DTO: siguen representando snapshots ya admitidos; los nuevos comandos
   reciben el perfil validado. No se añade SKU, código, precio, unidad, mínimo ni cantidad.
2. Leer por ProductID: devuelve snapshot activo o inactivo; identidad ausente o tombstone devuelve nil. No hace red.
3. Crear con ProductID explícito y perfil: nace active. Rechazar identidad previamente usada en modelo, cola,
   estado remoto o tombstone; no convertir una creación repetida en edición. La identidad se genera en el consumidor,
   de forma inyectable, y los reintentos de transporte mantienen sus operation IDs en Data.
4. Duplicados significan identidad, no nombre: permitir nombres iguales para IDs distintos. La spec no exige
   unicidad comercial; no inventar un índice único por nombre ni una regla de SKU. Una futura regla necesita decisión.
5. Editar solo nombre de un producto existente: preservar su ID y estado actuales, también inactive. Ausente no crea;
   tombstone no se restaura; conflicto pendiente rechaza la mutación. No exigir que el caller reenvíe un snapshot viejo
   capaz de sobrescribir el estado actual.
6. Desactivar significa active→inactive: conservar ID/nombre y referencias, persistir upsert causal. Un inactive
   existente devuelve éxito sin nueva operación ni escritura; desconocido devuelve notFound; tombstone no se recrea.
   El conflicto pendiente sigue bloqueando mutaciones. No hay borrado físico, restauración ni reactivación en09.1.
7. Observación y gestión conservan productos activos e inactivos; no cambiar el fetchAll actual ni ocultar inactivos.
   `SearchProductsUseCase` filtra los snapshots suministrados por nombre con búsqueda parcial localizada insensible
   a caja/diacríticos, recorta query y conserva orden. Query vacía devuelve todos los suministrados. La disponibilidad
   comercial y sus filtros pertenecen a los flujos posteriores, no a una eliminación silenciosa del inventario.
8. Errores Domain: nombre inválido, identidad existente, no encontrado, borrado previo, conflicto y fallo local
   neutral. No filtrar errores SwiftData/Firebase a futuros ViewModels. Conservar CancellationError; comprobar
   cancelación antes de aceptar y no presentar como fallo una escritura ya confirmada por cancelación tardía.

## Diseño y frontera09.1/09.2

Ampliar ProductRepository y añadir Get/Create/Update/DeactivateProductUseCase, PrepareProductProfileUseCase y
SearchProductsUseCase. Las intenciones semánticas no se implementan mediante lectura async seguida de save:
la comprobación y mutación deben compartir una primitiva Data sin suspensión que consulte el estado actual.
Mantener las rutas save/observe existentes para consumidores y regresiones; su endurecimiento global queda fuera.

Completar en09.1 la adaptación local mínima de las conformidades reales y de prueba. ProductLocalDataSource
comparte validación de existencia/conflicto/tombstone y persistPendingUpsert; ProductPersistenceActor y el adaptador
contextual delegan en esa misma primitiva. DefaultProductRepository publica invalidación después del commit exitoso;
la desactivación repetida no fabrica una mutación causal. InMemoryProductRepository expresa las mismas reglas
observables para pruebas/previews, sin presentarlo como garantía SwiftData o remoto.

No se promete compare-and-swap entre contextos ni se reescribe el núcleo de persistencia/sync.09.2 conserva la
integración y regresión completa de repetición, conflicto, tombstones, offline y reapertura sobre estas operaciones;
no consiste en volver a construir05.10. Incluir las pequeñas rutas locales ahora evita conformidades con stubs o
contratos que solo funcionen con un doble. Este límite se somete a revisión y aprobación junto a la propuesta.

Áreas previstas:

- Products/Domain/Repositories: ProductRepository y ProductError nuevo.
- Products/Domain/ValueObjects: ProductProfile nuevo; UseCases: seis operaciones indicadas arriba.
- Products/Data: las cinco rutas locales/repositorio/actor/adaptador/in-memory existentes, sin modelos nuevos.
- FranAlonsoTests: pruebas semánticas de perfil/CRUD/búsqueda y aceptación local; adaptar únicamente dobles afectados.
- Docs de progreso y spec09 para dejar explícitas las decisiones aprobadas. No modificar ADR aceptados históricos.

## Alternativas consideradas

- Solo casos de uso sobre save genérico: no distingue creación/edición ni protege de lecturas obsoletas. Rechazada.
- Protocolo paralelo o métodos provisionales que fallen hasta09.2: multiplica fronteras o entrega capacidad ficticia.
  Se elige ampliar la frontera existente con la mínima aceptación local real.
- Desactivar con tombstone como Clients: pierde la diferencia ya modelada entre inactive y eliminado. Rechazada.
- Unicidad por nombre: impediría homónimos y requiere una regla no existente; no se adopta por defecto.
- Integrar toda09 ahora: diluye gates y mezcla UI/movimientos con contratos. Se mantiene secuencia canónica.

## TDD y validación de la implementación

Swift Testing con oráculos de comportamiento; no tests de getters, número de campos o delegación trivial nuevos.

- Perfil vacío/whitespace y decodificación adversarial rechazados; nombre válido normalizado al aceptar un alta.
- Alta seguida de lectura; identidad repetida no altera el original; IDs distintos con mismo nombre se conservan.
- Edición ausente no crea; edición de inactive conserva inactive y cambia solo nombre.
- Desactivación conserva ficha, lectura y referencias; segundo intento no añade operación; desconocido falla.
- Búsqueda vacía, trim, parcial, caja/diacríticos, sin resultado y orden usando un corpus sintético independiente.
- Cancelación antes de aceptación no escribe; error local y conflicto son distinguibles; tombstone no se resucita.
- Integración mínima in-memory SwiftData: producto+operación juntos, rollback en fallo y observación solo tras commit;
  paridad actor/contextual, no nueva causalidad por desactivación repetida ni pérdida de cambios de estado vigentes.

Registrar RED real, GREEN focal y regresión Product afectada mediante Xcode MCP. Build Develop y logs completos;
Production si el diff cruza configuración/composición común. Reutilizar suites05.10 en lugar de clonar sus pruebas;
ampliar solo por riesgo de los cambios. Suite global solo si el impacto real lo justifica. Revisión POST de estándares
independiente y estilo sobre Swift tocado. UI/accesibilidad N/A en09.1 porque no se cambian pantallas ni recursos.

## Fuentes y riesgos

Autoridad de producto: spec09, ADR0002/0006/0011/0014/0018/0030; precedente vigente ClientRepository,
ClientProfile y SearchClientsUseCase. Fuente primaria consultada con Cupertino para la única API de búsqueda:
[localizedStandardContains](https://developer.apple.com/documentation/foundation/nsstring/localizedstandardcontains(_:))
confirma coincidencia localizada insensible a caja y diacríticos; no usarla como igualdad única de identidad.
No hay elección de API nueva de persistencia o sincronización; se reutilizan las primitivas probadas del proyecto.

Riesgos: confundir inactivo/eliminado; anunciar unicidad que solo detecta IDs; aceptar una edición de estado viejo;
romper snapshots históricos al validar entradas nuevas; o presentar evidencia local como sync/live. Las reglas y
pruebas anteriores los delimitan. No cambia forma persistida ni requiere migración; si aparece esa necesidad, detener
para su propuesta según ADR0018. Sin dependencia, excepción unsafe, target nuevo ni ADR arquitectónico nuevo previsto.

09.2–09.7, seed de demo de productos, ViewModels/pantallas, ajustes/mínimos, Service, Foundation Models, ventas,
fotografía, activación live y deuda accesible de fase08 quedan fuera de esta implementación. Se recuperan por sus
subfases; la fase08 sigue abierta. Retirar los comandos nuevos no requiere modificar datos o proveedores remotos.

## Revisión y aprobación

Revisión PRE independiente read-only por `ios-standards-reviewer`: **PASS, sin hallazgos P0–P3**, limitada a la
propuesta y rutas Product directamente afectadas. Verifica viabilidad de aceptación local mínima, semántica de
estado/identidad, límites, fuentes y oráculos. Inspecciona summary y logs previos; no ejecuta Xcode ni relee el bundle.
Root contrasta538/538 rutas tracked/untracked no ignoradas idénticas antes/después: manifiesto
`/tmp/franalonso-09-1-pre-review.json`, SHA-256 JSON canónico
`16427bb3c343301aab968289ad135ed05a9a9eb073140dcb8bdc2ad82688e0bd`.
Este registro de resultado se añade después de verificar la huella; no modifica la propuesta técnica auditada.

El propietario aprueba estas reglas y el límite09.1 con «si, adelante, implementa». La implementación y su validación
quedan autorizadas. TDD y POST se registran en phase-09.md; commit/push/PR/merge/cierre no se incluyen.
