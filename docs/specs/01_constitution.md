# Fase 01 — Constitución del proyecto

## Objetivo

Fijar las reglas no negociables de producto, arquitectura, persistencia, concurrencia, testing y entrega antes de escribir código.

## Plataforma y herramientas

- Comprobar el deployment target, SDK, Xcode y versión de Swift del proyecto real antes de elegir APIs.
- Usar la opción moderna compatible con ese target. No elevarlo ni adoptar una beta como efecto lateral.
- Tratar warnings Swift y Clang como errores desde el bootstrap.
- Usar Xcode MCP primero para inspeccionar, compilar, ejecutar tests y leer diagnósticos. No usar `xcodebuild` o XcodeBuildMCP como sustitución silenciosa.
- Consultar Cupertino MCP cuando disponibilidad, aislamiento o patrón recomendado de una API Apple pueda haber cambiado.

## Evidencia y aprobación del cambio

- Ningún código o solución técnica se propone o implementa solo desde el conocimiento recordado del modelo. Se inspecciona primero el proyecto real y se contrasta la propuesta con fuentes primarias actuales: especificaciones y ADR aceptados del repositorio, seguidos por documentación oficial de Apple, Swift, Firebase o el proveedor aplicable. La propuesta cita esa evidencia; un resultado de búsqueda o una fuente secundaria sin contrastar no basta.
- Antes de escribir código ejecutable, un revisor independiente y de solo lectura comprueba que las fuentes citadas son aplicables y que se evaluaron alternativas viables; documentación y web aportan evidencia, mientras que esa revisión constituye la aprobación por pares. Esta puerta previa no sustituye las auditorías especializadas posteriores aplicables.
- No se refactoriza, sustituye ni altera código conocido como funcional fuera del cambio exacto ya aprobado por el propietario. Antes se presenta el cambio concreto, motivo, impacto de comportamiento, riesgos y alcance, y se espera confirmación explícita. Una petición que ya nombra y aprueba ese cambio exacto cuenta como confirmación; no autoriza limpiezas adyacentes.

## Arquitectura

Se aplica Clean Architecture por funcionalidad:

```text
View
  ↓ intenciones / ↑ estado
ViewModel (@Observable, @MainActor)
  ↓
Store opcional (@Observable, @MainActor)
  ↓
UseCase
  ↓
Repository (contrato de Domain)
  ↑
DefaultRepository → LocalDataSource / RemoteDataSource / SyncEngine
```

- `Domain` contiene entidades, value objects, contratos de repositorio, casos de uso y políticas puras. No importa SwiftUI, SwiftData, Firebase, UIKit ni detalles de red.
- `Data` contiene DTO, modelos SwiftData, sus conversiones, data sources, mappers justificados, implementaciones de repositorio, actores de persistencia y sincronización.
- `Presentation` contiene pantallas, vistas, ViewModels y Stores opcionales. No importa Firebase. Puede importar SwiftData únicamente para obtener `@Environment(\.modelContext)` en una View y recibir ese contexto como parámetro efímero en la función `@MainActor` pertinente del ViewModel; no expone otros tipos de persistencia.
- `App` es el composition root. Construye implementaciones y distribuye dependencias mediante `@Environment` e inicializadores.
- Cada pantalla mantiene un `ViewModel` `@Observable @MainActor` como fachada.
- Los tipos de referencia observables propios de Presentation usan el macro `@Observable`. No se introducen `ObservableObject`, `@Published`, `@StateObject` ni `@ObservedObject`; la vista conserva el modelo con `@State` y usa `@Bindable` solo cuando necesita proyectar bindings.
- Un Store se extrae únicamente cuando una responsabilidad cohesiva hace crecer el ViewModel, existe reutilización real o aporta una prueba aislada útil. No se duplica estado entre Store y ViewModel.
- No se crean protocolos, carpetas o Stores vacíos “por si acaso”.
- Una conversión concreta y determinista sin dependencias, configuración, versionado, política ni estrategias intercambiables vive en una extensión del DTO o modelo propiedad de Data. La reconstrucción usa `toDomain()` y el sentido inverso un inicializador de conversión sin etiqueta cuando preserva el valor. Domain no declara APIs que conozcan DTO o modelos persistentes. Solo se introduce un `Mapper` cuando posee una de esas responsabilidades reales y sus call sites la demuestran.
- Una View solo representa estado y llama acciones semánticas del ViewModel. No valida, filtra, calcula, persiste, consulta red ni decide negocio. Las invariantes puras permanecen en Domain/UseCases.
- Para insertar, actualizar o borrar mediante el contexto principal de SwiftData, la View captura `@Environment(\.modelContext)` y lo pasa a la función del ViewModel. La View no llama operaciones del contexto ni lo almacena; el ViewModel no lo conserva ni lo cruza a otro actor.
- Presentation expresa esa mutación como una closure inyectada `@MainActor` con una entrada de Domain y `ModelContext`. `App` la compone capturando un adaptador de Data; Data ejecuta mapping, operaciones del contexto y política local-first. Domain nunca recibe el contexto, Data no depende de Presentation y el ViewModel no conoce la implementación concreta.
- Cada archivo Swift contiene un único tipo que conforme a `View`. Cada subview extraída vive en su propio archivo.
- Los inicializadores y modificadores SwiftUI usan trailing closures y multiple trailing closures cuando la API no es ambigua. `@ViewBuilder` se reserva para fronteras reales con varios hijos o ramas heterogéneas; no se declara en `body`, helpers de una sola expresión ni para ocultar una View excesiva.
- Toda dimensión numérica explícita de contenido no textual significativo que deba acompañar Dynamic Type usa `@ScaledMetric(relativeTo:)`, salvo adaptación automática o tamaño deliberadamente independiente y justificado.
- Cada tipo `View` incluye al menos un `#Preview` en su archivo. Cada preview aplica el trait compartido respaldado por `PreviewModifier`, que instala un `ModelContainer` de test en memoria con datos deterministas, idempotentes y suficientes para navegar y validar la aplicación.
- Una capacidad probabilística devuelve lectura o borradores tipados a Presentation; nunca obtiene acceso directo a persistencia, red de negocio, bindings o ejecución de UseCases mutadores.

### Estructura objetivo

```text
FranAlonso/
├── App/
│   ├── FranAlonsoApp.swift
│   ├── AppDependencies.swift
│   ├── AppEnvironment.swift
│   └── Navigation/
├── Features/
│   └── Clients/
│       ├── Domain/
│       │   ├── Entities/
│       │   ├── Repositories/
│       │   └── UseCases/
│       ├── Data/
│       │   ├── Adapters/    # Integraciones concretas con SDK externos cuando aporten claridad
│       │   ├── DTOs/
│       │   ├── Models/
│       │   ├── DataSources/
│       │   ├── Mappers/      # Extensiones de conversión o Mapper justificado
│       │   ├── Repositories/
│       │   └── Sync/
│       └── Presentation/
│           ├── Screens/
│           ├── Views/
│           ├── ViewModels/
│           └── Stores/       # Solo cuando se justifique
├── Shared/
│   ├── Domain/
│   ├── Data/
│   ├── Presentation/
│   └── Support/
├── Resources/
└── Tests/
```

### Nomenclatura

| Responsabilidad | Nombre de ejemplo |
|---|---|
| Entidad de dominio | `Client.swift` |
| Contrato de repositorio | `ClientRepository.swift` |
| Implementación | `DefaultClientRepository.swift` |
| Caso de uso | `SaveClientUseCase.swift` |
| DTO Firestore | `ClientDTO.swift` |
| Modelo SwiftData | `ClientModel.swift` |
| Fuente local/remota | `ClientLocalDataSource.swift` / `ClientRemoteDataSource.swift` |
| Conversión concreta | `ClientDTO+Domain.swift` / `ClientModel+Domain.swift` |
| Mapper con dependencias o política | `VersionedClientMapper.swift` |
| Actor SwiftData | `ClientPersistenceActor.swift` |
| Sincronización | `ClientSyncEngine.swift` / `ClientSyncPolicy.swift` |
| Fachada de pantalla | `ClientListViewModel.swift` |
| Estado extraído por complejidad | `ClientEditingStore.swift` |
| Pantalla | `ClientListScreen.swift` |
| Doble de test | `ClientRepositoryFake.swift` / `ClientRemoteDataSourceStub.swift` |

Evitar `Interactor`, `ModelLogic`, `LocalModel`, `SyncService`, `Manager`, `Helper`, `Utils` y `Common` cuando oculten la responsabilidad real.

## Persistencia y sincronización

- SwiftData es la fuente de verdad local. La UI solo observa estado materializado localmente.
- Firestore es la fuente de verdad remota mientras permanezca la excepción Firebase.
- Las escrituras son local-first: guardar, marcar pendiente, actualizar UI y sincronizar después.
- Cada colección define identificador estable, revisión remota, metadatos de sincronización, tombstone, política de conflictos, backoff y recuperación.
- Ninguna política usa únicamente el reloj local como autoridad de conflictos.
- Repetir o reordenar una operación no duplica datos, no cambia el resultado final y no resucita eliminaciones.
- SwiftData fuera de MainActor se encapsula en un `@ModelActor`; entre actores viajan IDs, DTO o snapshots `Sendable`, nunca modelos SwiftData vivos.
- Los imports del SDK Firebase quedan confinados a adaptadores concretos propiedad de Data; `Infrastructure` no es un nombre de carpeta obligatorio. Las referencias históricas a `Data/Infrastructure` describen esa propiedad de capa, no una ruta literal. Auth, Firestore y Storage deben poder sustituirse por Vapor sin cambiar Domain o Presentation; Analytics y Crashlytics se sustituyen de forma independiente detrás de contratos propios.

## Concurrencia y código

- View, ViewModel y Store son `@MainActor`.
- Dominio, red, persistencia, sincronización y render pesado permanecen fuera de MainActor salvo razón demostrada.
- La configuración de default actor isolation se inspecciona y documenta por target; no se presupone.
- `nonisolated` se usa solo cuando sea semánticamente seguro, nunca para silenciar al compilador.
- Los `struct` y `enum` internos confían en la inferencia de `Sendable` solo cuando todas sus propiedades almacenadas o valores asociados lo permiten. Los actores conforman implícitamente y nunca repiten la declaración. Una conformidad explícita o condicional solo se añade cuando el compilador la exige en una frontera pública o genérica, con el motivo documentado y sin ocultar estado no enviable.
- El código propio se diseña desde las construcciones nativas de Swift, su biblioteca estándar y sus API Design Guidelines; no traslada mecánicamente patrones ceremoniales de otros lenguajes. Toda abstracción demuestra en su declaración y call sites una responsabilidad, invariante, frontera o reutilización real, y se prefiere la forma Swift directa cuando expresa el mismo contrato. Las listas de conformidad declaran solo el protocolo más específico y no repiten uno heredado, como `Equatable` junto a `Hashable`, salvo exigencia documentada de una frontera condicional o genérica.
- No se usa un `enum` propio sin casos meramente como namespace de miembros estáticos; se reconoce ese patrón cuando el tipo solo aparece como calificador en llamadas `Tipo.miembro`. La alternativa se elige por semántica: comportamiento en el tipo propietario o su extensión, un servicio o valor real usado en la composición, o una declaración libre con el acceso más restringido que permita su uso cuando no existe propietario. Un enum sin casos sigue siendo válido si su conjunto imposible de valores es el contrato modelado. No se sustituye mecánicamente por otro tipo sin estado.
- Todo código asíncrono o concurrente propio usa Swift Concurrency de extremo a extremo: `async`/`await`, tareas hijas estructuradas, actores o actores globales, `AsyncSequence`, cancelación cooperativa y continuaciones comprobadas únicamente en adaptadores aislados. No se introducen GCD directo, grupos o semáforos de Dispatch, `OperationQueue` ni concurrencia basada primero en callbacks.
- Queda prohibido añadir explícitamente `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)` o cualquier salida insegura equivalente para conseguir que compile la concurrencia estricta. Si las fuentes primarias actuales y todas las alternativas estáticamente seguras siguen sin ofrecer solución, se detiene la implementación y se propone la excepción exacta, alternativas descartadas, invariante de propiedad o sincronización, alcance, ADR y tests focalizados; se espera aprobación explícita antes de escribirla.
- No se usan APIs deprecated o no disponibles en el SDK activo. Por política del proyecto tampoco se introducen en código propio mecanismos directos del runtime Objective-C ni alternativas legacy de Foundation/Dispatch cuando exista reemplazo Swift compatible, incluidos `@objc` explícito, `Selector`/`#selector`, observación de `NotificationCenter` por selector, GCD/`DispatchQueue`, `DateFormatter` y `NSRegularExpression`. Esta lista expresa una prohibición del proyecto, no que todos esos símbolos estén deprecated. Cualquier uso inevitable requiere justificación con fuentes primarias y aprobación explícita previa.
- Las declaraciones primarias de `struct` no contienen inicializadores explícitos. Se usa el memberwise sintetizado cuando basta y se eliminan inicializadores que solo copian parámetros. Una factory estática con nombre se usa solo cuando comunica mejor un estado de dominio, preset o composición; en los demás casos, los inicializadores con validación, inyección, composición o requeridos por `Decodable` viven en extensiones del mismo archivo. Las invariantes se garantizan al construir: el almacenamiento impide que el memberwise sintetizado las eluda y no se sustituyen por una comprobación posterior `isValid` o `validate()`.
- Las APIs semánticas de producción nuevas o modificadas se documentan en inglés con DocC, con independencia de que sean `internal` o públicas. Se documentan tipos y contratos de Domain, Repository, UseCase y políticas; factories semánticas, inicializadores validantes, transiciones de estado y operaciones no obvias con errores, asincronía o mutación. Los comentarios explican invariantes, unidades, efectos, idempotencia, cancelación, parámetros, retorno y errores solo cuando aportan información que la declaración no expresa. No se documentan por sistema propiedades evidentes, boilerplate de vistas o `Codable`, helpers privados triviales ni tests.
- Serialización exclusiva mediante `Codable`, `JSONEncoder` y `JSONDecoder`.
- Todo texto visible reside en `Localizable.xcstrings`.
- Solo se permiten frameworks Apple, salvo `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalyticsCore` y `FirebaseCrashlytics` como excepción aprobada y acotada.

### Fuentes primarias de las reglas modernas

- [`Sendable` y conformidad implícita de valores](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) y [actores](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md).
- [`Hashable` hereda de `Equatable`](https://developer.apple.com/documentation/swift/hashable) y las [API Design Guidelines de Swift](https://www.swift.org/documentation/api-design-guidelines/) priorizan claridad en el punto de uso y ausencia de información redundante.
- [Enumeraciones](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/) modelan conjuntos de valores relacionados; [extensiones](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/extensions/) y [funciones](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/functions/) permiten situar el comportamiento en su propietario semántico o en el ámbito de archivo cuando no existe uno.
- [Migración incremental y `@preconcurrency`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md) y [`nonisolated(unsafe)`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0412-strict-concurrency-for-global-variables.md).
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) y [concurrencia estructurada](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md).
- [Migración de `ObservableObject` al macro `@Observable`](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).
- [`PreviewModifier`](https://developer.apple.com/documentation/swiftui/previewmodifier), [variantes de preview en Xcode](https://developer.apple.com/documentation/xcode/previewing-your-apps-interface-in-xcode#Test-different-view-configurations) y [`ScaledMetric`](https://developer.apple.com/documentation/swiftui/scaledmetric).
- [`EnvironmentValues.modelContext`](https://developer.apple.com/documentation/swiftui/environmentvalues/modelcontext), [multiple trailing closures](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0279-multiple-trailing-closures.md) y [result builders](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0289-result-builders.md).
- Alternativas Swift modernas: [mensajes tipados de `NotificationCenter`](https://developer.apple.com/documentation/foundation/notification-center-messages), [`Date.FormatStyle`](https://developer.apple.com/documentation/foundation/date/formatstyle) y [`Regex`](https://developer.apple.com/documentation/swift/regex).

## Observabilidad y privacidad

- Analytics registra únicamente eventos y parámetros de una allowlist versionada; no recibe nombres, correos, teléfonos, contenido de clientes, documentos, notas, importes ni otros payloads de negocio.
- Crashlytics recibe fallos, errores no fatales y claves diagnósticas no sensibles; sus logs y custom keys tampoco contienen PII o payloads de negocio.
- La aplicación no incorpora publicidad, IDFA ni `FirebaseAnalyticsIdentitySupport`.
- Analytics y Crashlytics no son fuentes de verdad y sus fallos nunca bloquean autenticación, persistencia, sincronización ni flujos de usuario.
- `GoogleService-Info.plist` permanece local, ignorado por Git y fuera de commits, parches, logs y documentación.
- Audio, transcripciones, prompts, respuestas y estado conversacional del asistente son efímeros: no entran en SwiftData, Firestore, archivos, portapapeles, Analytics, Crashlytics o logs.
- El asistente del MVP procesa voz e interpretación en el dispositivo, no tiene fallback cloud y se detiene al salir de primer plano. Cualquier proveedor remoto exige un ADR y consentimiento/base jurídica aplicables antes de datos reales.

## Testing

- TDD real con Swift Testing para tests unitarios y de integración.
- No se crean XCTest, XCUITest ni tests UI nativos.
- Auth, Firestore, Storage, Analytics y Crashlytics se sustituyen por dobles deterministas.
- SwiftData usa un `ModelContainer` en memoria por test o suite segura.
- Reloj, UUID, aleatoriedad y errores se inyectan cuando afectan al resultado.
- ViewModels cubren coordinación; Stores cubren transiciones, errores, cancelación y reintentos; sincronización cubre idempotencia, conflictos y recuperación.
- Cada pantalla afectada se renderiza e inspecciona mediante Xcode MCP en las variantes Dynamic Type soportadas `Large`, `XXX Large` y `AX 5`; la semántica accesible se revisa por separado y VoiceOver manual se registra cuando aplique.
- La telemetría prueba allowlists, exclusión de datos sensibles, consentimiento, activación, desactivación y tolerancia a fallos sin usar Firebase real.
- El asistente se prueba con contratos y dobles deterministas; micrófono y modelos reales se reservan para validación manual en dispositivo y nunca hacen no determinista la suite.

## Reglas de producto

- Todo lo cobrable es un `Service`; `Product` solo representa inventario físico.
- Un servicio de tipo producto requiere `linkedProductID`. Precio y descuento pertenecen al servicio o al snapshot de la venta, nunca a `Product`.
- El cálculo monetario usa `Decimal` mediante un value object `Money`; no usa `Double`.
- IVA y descuentos se modelan como valores o políticas explícitas y quedan congelados en cada `SaleLine`.
- Stock insuficiente muestra aviso y confirmación, pero no bloquea; el comportamiento y el stock negativo se prueban.
- Ticket y factura tienen series remotas, independientes y atómicas. No se asigna un número local definitivo.
- Jornada es la pantalla principal autenticada y solo muestra operaciones que requieren una acción. Una operación desaparece inmediatamente cuando todos sus servicios han terminado, el pago está registrado y se ha emitido ticket o factura; desde ese momento se consulta en Histórico.
- Los PDF se generan con frameworks Apple y el correo queda preparado para envío manual.
- La demo de citas no sustituye al sistema actual durante el MVP.
- La voz puede consultar, navegar y rellenar borradores, pero Fran revisa y guarda con el control visual normal; no existen efectos ni confirmaciones exclusivamente por voz.

## Subfases

| ID | Tarea | Resultado verificable |
|---|---|---|
| 01.1 | Verificar `AGENTS.md`, guía, progreso y checklist de PR. | Documentos coherentes y enlazados. |
| 01.2 | Reescribir ADR 0001: arquitectura, ViewModel y Store opcional. | Límites y consecuencias documentados. |
| 01.3 | Reescribir ADR 0002: fuentes de verdad y sincronización. | Invariantes local/remota explícitas. |
| 01.4 | Reescribir ADR 0003–0005: testing, Codable y warnings. | Excepciones y validación definidas. |
| 01.5 | Crear ADR 0006: conflictos, revisiones y tombstones. | Política segura por colección. |
| 01.6 | Crear ADR 0007: Firebase temporal y salida a Vapor. | Frontera reemplazable definida. |
| 01.7 | Crear ADR 0008: numeración atómica de documentos. | Idempotencia y recuperación definidas. |
| 01.8 | Crear ADR 0009: consentimiento offline y activación. | Estados, atomicidad y recuperación definidos. |
| 01.9 | Revisar y aceptar ADR 0001–0009. | Estados e índice actualizados antes de la fase 02. |

## Cierre obligatorio de cada subfase

Ejecutar íntegramente las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
