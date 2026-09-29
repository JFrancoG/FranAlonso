# 08.8a — Composición reutilizable de demo

## Estado y autoridad — 2026-09-29

Propuesta concreta de PLU-46, hija de PLU-34, preparada tras «Adelante con 08.8a». La petición autoriza avanzar dentro
del alcance publicado de ADR0030/spec08; las decisiones siguientes concretan su implementación. Revisiones PRE
independientes completadas antes de código. No inicia catálogo, Foundation Models, foto o servicios live.

Base: `main`, `7ecbf68618d3180197f848085559584d6a8966e3`, inicialmente limpio y sincronizado. PLU-46 Backlog,
responsable Jesus Franco; PLU-42 Done funcional satisface la dependencia. PLU-34 sigue In Progress; PLU-43/47 y
la deuda PLU-44/45/38 conservan sus límites. No se crea otra issue para el mismo trabajo.

Autoridad: [spec08](../specs/08_clients_consent.md), [índice](../specs/00_index.md),
[ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md), ADR0011/0018/0022/0023/0025/0028/0029,
constitución y política Swift. El vault Obsidian es este repositorio; no requiere otra copia.

Xcode MCP estable conectado a este proyecto (`workspace-EYu6rxi7hg`), esquema Develop, destino original iPhone11.
Build settings efectivos: deployment iOS26.0, SDK27.0, Swift6, strict concurrency complete, aislamiento por defecto
nonisolated, warnings Swift/Clang como errores. `FRANALONSO_AUTH_FIXTURE` está activo en Debug-Develop.
La validación propuesta usará iPad Air11M4/iOS27.0 Simulator, disponible, restaurando después esquema/destino.

Baseline reutilizable: árbol ejecutable/configuración idéntico a `91eb3a7` (comparación Git actual), suite08.8 de
1.094/1.094 resultados, build restaurado8,907s y retest2/2; aviso AppIntents previo, seis enlaces históricos rotos08.3.
No se ejecutan nuevos build/tests/previews al preparar documentos. La baseline no valida el código futuro ni live.

## Comportamiento propuesto

### Selección aislada antes de cualquier proveedor real

Dos argumentos exclusivos, desactivados por defecto y disponibles solo en LaunchAction del esquema Develop:

- `--franalonso-demo-clients`: recorrido normal.
- `--franalonso-demo-clients-response-lost`: el primer envío acepta el documento simulado pero pierde su respuesta;
  el reintento explícito recupera el mismo recibo.

Nuevo caso semántico `ApplicationLaunchPlan.demo(configuration)` y nueva composición `DevelopDemoComposition`,
separados de `DevelopAuthenticationFixture`. Reutilizar la condición existente, exclusiva de Debug-Develop; no añadir
otra condición que duplicaría las fronteras de autenticación/local. Todo código de demo nuevo queda bajo ese gate.

`ApplicationLaunchPlan.current` sigue siendo la única decisión inmutable compartida por App y delegate. Dentro de la
capacidad compilada, cualquier prefijo `--franalonso-demo-` desconocido, duplicado, dos modos, mezcla con argumentos
auth/clients o entorno/bundle incorrecto resuelve `invalidFixtureConfiguration`. No vuelve a live. Sin intención de
fixture/demo se conserva el arranque normal. Fuera del gate no existe una capacidad demo activable; se conserva la
ruta normal de ADR0023/0025, sin introducir un parser demo en Production/Release.

`AppDelegate` reutiliza el terminal `fixtureReady` para la demo y omite `configureFirebase`. `ApplicationComposition`
selecciona una factory demo antes de construir almacenamiento durable o `AppRuntime`. La composición devuelve
`runtime == nil`: no Firebase/Auth real, Keychain, telemetría real, factories remotas ni motores de sincronización.
No se aprovecha esta subfase para la extracción histórica propuesta de `ApplicationBootstrapState`.

### Escenario inicial y autenticación

- Cada composición crea un contenedor SwiftData en memoria y un escenario propio; sin singletons ni almacenamiento
  durable. Un `ModelContext` temporal, confinado a MainActor, siembra antes de crear los actores/observadores.
- Dos perfiles: «Cliente DEMO Alba» y «Cliente DEMO Bruno», ambos `draft`, con IDs y operationIDs fijos, sin DNI,
  dirección, fotos o documentos. `ClientProfile` y `ClientLocalDataSource.createClient` validan y generan la cola causal
  real. Un error de seed impide entregar la composición; nunca se expone un escenario parcial ni se abre la ruta live.
- Catálogo, ventas, documentos y almacén remoto simulado comienzan vacíos. No se prefabrican clientes activos ni firmas.
- Arranque signed-out. Reutilizar `DevelopAuthenticationDataSource` y su identidad/credencial sintética existentes,
  `DefaultAuthenticationRepository`, use cases y `AuthenticationRootViewModel`. El aislamiento pertenece al contenedor
  separado, no a inventar otro UID. El authorizer permite solo ese principal y nunca usa Keychain.
- El login recorre su UI normal; no se inyecta `.authenticated`, no se rellena automáticamente el formulario y no se
  cambia la política biométrica. La credencial de prueba queda en la guía técnica de demo, fuera de la UI de producto.
- Logout/login o reabrir un formulario conserva los cambios del mismo proceso. Terminar y lanzar de nuevo restaura los
  dos borradores, storage vacío y fallo inicial disponible. No hay botón de reset ni promesa de durabilidad entre procesos.

### Documentos y recuperación real sobre proveedor simulado

Reutilizar `InMemoryClientDocumentStorage`, cuyo `RemoteStore` ya correlaciona principal+document UUID, compara el
contenido completo, rechaza conflictos y conserva recibos idempotentes. Una instancia compartida por composición,
nunca por formulario. Modo normal sin fallos; modo de recuperación con una única `.responseLost` por proceso.

`ClientDocumentComposition` recibe el storage por inyección y conserva el default `UnavailableClientDocumentStorage`
de la composición normal. `AppDependencies.local` permite pasarlo a la composición documental. Mantener el mismo
actor de persistencia y señal entre formularios, catálogo bundled, render CoreGraphics y repositorios/use cases reales.
Las fixtures actuales no pasan ese argumento: continúan vacías y con Storage no disponible.

Recorrido: abrir/crear/editar cliente → revisar información → firma → conservar → envío → activación. En el modo de
error, el primer envío falla en la UI después de la aceptación simulada: el cliente sigue pendiente. Cerrar/reabrir y
reintentar conserva firma/documento y obtiene el recibo inicial; solo entonces activa. No se fuerza estado en Presentation.

La capacidad documental y de activación queda ligada a la sesión y revisión: logout la revoca, también tras login del
mismo principal. Nuevas capabilities solo se obtienen estando autorizado. El CRUD contextual conserva el ciclo actual
de `ClientFormScreen.onDisappear`; no se afirma una revocación nueva de todos sus closures ni se amplía su arquitectura.

### Identificación visual

La composición transporta la configuración demo hacia `FranAlonsoApp`; ninguna View interpreta argumentos del proceso.
Añadir un componente declarativo `DevelopDemoBanner` con texto localizado «Demo · Datos de ejemplo» y un aviso
«Los cambios se reinician al abrir la app». En el modo de error, indicar «Primer envío con error simulado».
Se presenta en el área segura superior de la raíz demo, separada del contenido y sin overlay que tape controles.
La raíz de autenticación y las pantallas de negocio permanecen las actuales; el banner no crea otra fachada ViewModel.

Texto nativo con wrapping, colores semánticos, sin altura fija, temporizadores, anuncios forzados ni acciones nuevas.
Preview determinista del componente y del encuadre con la raíz. Comprobar Login/listado y presentación de formulario,
revisión y firma: las sheets conservan sus pantallas; comprobar que no hay clipping ni acciones ocultas por el banner.
El marcador no afirma que un PDF o servidor real se haya producido. Los datos ya incluyen DEMO en su nombre.

## Cambios previstos y alternativas

| Área/archivos | Delta previsto |
|---|---|
| `App/ApplicationLaunchPlan.swift`, `ApplicationComposition.swift`, `AppDelegate.swift` | Nueva selección/factory aislada y terminal existente antes de Firebase. |
| Nuevos `App/DevelopDemoComposition.swift`, `App/DevelopDemoScenario.swift` | Propiedad por arranque, seed, autenticación y proveedores simulados. |
| `App/ClientDocumentComposition.swift`, `App/AppDependencies.swift` | Inyección del storage compartido, default normal intacto. |
| `App/FranAlonsoApp.swift`, nuevo `App/DevelopDemoBanner.swift`, `.xcstrings` | Configuración semántica y marcador localizado con preview. |
| Esquema compartido Develop | Dos argumentos `NO`; sin modificar TestAction ni Production. |
| Tests de launch/bootstrap/configuración y nuevas suites de composición/recorrido demo | Invariantes, aislamiento, recuperación y regresión. |
| Progress, fase08 y guía breve de ejecución | Evidencia, límites, argumentos y secuencia de demostración. |

Se descarta ampliar la fixture vacía existente: rompería su escenario de validación. Se descarta otro adapter de
storage: el actual ya satisface la simulación requerida. También se descartan un UID nuevo parametrizando Auth,
otro compile flag, un escenario durable, un reset dentro de la app y accesos directos que salten el login: añaden cambios
sin necesidad para este alcance. Mantener el flujo real permite que las fases09/10 amplíen la misma composición.

## TDD y validación de la futura implementación

1. RED focal para la selección demo y matriz inválida/conflictiva; spies prueban ausencia de Firebase y selección
   exclusiva de factory demo. Source-backed: compile gate completo, argumentos `NO`, exclusión de Production/Release.
2. Componer, editar/crear por la fachada real y recomponer: comprobar los dos drafts iniciales, persistencia dentro del
   proceso, aislamiento entre composiciones, seed sin activos/fotos/documentos y reset del almacén/fallo.
3. Autenticación real sintética, rechazo de principal ajeno, logout y revocación documental/activación de capacidades
   antiguas, incluso tras entrar de nuevo con el mismo principal. Las cinco fixtures antiguas conservan sus28 tablas vacías.
4. Recorrido documental normal y pérdida de respuesta con firma/artefacto inmutables, reapertura, recibo correlacionado
   y activación única; verificar aceptación simulada una sola vez. No duplicar la matriz completa del storage ya existente.
5. Regresión afectada de launch/bootstrap, fixtures, composición documental/activación y configuración. Build Develop
   y Production, inspección de logs completos; suite completa al final por tratarse de arranque/composición de la app.
6. Previews Large/XXX Large/AX5 soportadas del banner y encuadre, estados/apariencias representativos. Revisión de estilo,
   estándares y SwiftUI/accesibilidad independientes. Smoke táctil con Xcode MCP en ambos modos: login, editar/crear,
   firmar, conservar, enviar/reintentar, reapertura, logout/login y nuevo lanzamiento con reset.
7. Terminar sesiones de interacción y restaurar esquema/destino y argumentos desactivados. No usar xcodebuild ni UI tests.

Aplicar ADR0029: construcción accesible y validación funcional permanecen obligatorias. La matriz integral/Inspector/AT
nueva del marcador y su encuadre, si queda pendiente, tendrá evidencia, issue propia vinculada a PLU-46, responsable
Jesus Franco y recuperación tras feedback y estabilización del flujo, antes de uso real. No se mezcla con PLU-44/45/38
ni se declara conforme por previews. No repetir sus recorridos físicos aceptados sin impacto.

## Riesgos, fuentes y reversibilidad

El doble puede ocultar problemas de proveedor/red; su éxito no demuestra Firebase, Storage, sincronización o permisos.
Reset al relanzar es intencionado y visible, no recuperación durable. La aceptación perdida es simulada; las invariantes
y recuperación de la app son reales. Datos, firmas de prueba y payloads no se registran en logs/telemetría ni en Git.

La propuesta reutiliza APIs ya compiladas y contratos existentes. Fuente Apple contrastada mediante Cupertino:
[ModelConfiguration.isStoredInMemoryOnly](https://developer.apple.com/documentation/swiftdata/modelconfiguration/isstoredinmemoryonly),
almacenamiento efímero en memoria, disponible desde iOS17 y compatible con el target26. La fuente sustenta esa propiedad,
no prueba el aislamiento completo de la composición: esa garantía requiere tests y revisión del código.

Reversión: desactivar los argumentos elimina el acceso a demo; retirar su caso/composición/banner revierte la capacidad
sin migración de datos. No nuevas dependencias, opt-outs, cambios de target, APIs beta, live ni nuevos contratos Domain.
Quedan fuera09–10, PLU-47/Foundation Models,11–13,08.9 y la limpieza general del bootstrap.

## Revisión y autorización

Revisiones PRE independientes de estándares y UI/accesibilidad: PASS sin hallazgos. Root reproduce las529 rutas
idénticas antes/después, manifiesto `/tmp/franalonso-08-8a-proposal-review.json`, SHA-256 JSON canónico
`7bdbbb31a3efa8681dca4a924d5cf39406e92a71890568f5e44ad73ab7b2ac75`. Este registro se añade después de verificarlo.
La autorización «Adelante con 08.8a» se aplica a este alcance; commit/push, PR, merge, cierre de issue/rama y siguiente
subfase se mantienen separados. Se implementa en `codex/plu-46-reusable-demo`.
