# Fase 03 — Clean Architecture, Observation y DI

## Objetivo

Implementar una vertical mínima que demuestre dependencias hacia Domain, composición en App, ViewModel observable obligatorio y Store opcional por complejidad.

## Flujo de dependencias

```text
App / Composition Root
        ↓ construye implementaciones
Presentation → Domain ← Data

View → ViewModel → Store opcional → UseCase → Repository protocol
                                                ↑
                                  DefaultRepository → DataSources

Mutación de contexto principal aprobada:
View ── ModelContext efímero ─→ ViewModel ── closure inyectada ─→ adaptador Data
                                      ↑ compuesta por App
```

La View no recibe repositorios o casos de uso arbitrarios como service locator. Obtiene un conjunto de dependencias tipado desde `@Environment` en el límite de composición y crea/conserva el ViewModel mediante el mecanismo de estado apropiado. La única excepción de infraestructura en Presentation es el `ModelContext` principal: una View puede capturarlo del entorno y pasarlo como parámetro efímero a la función `@MainActor` del ViewModel que coordina una mutación.

## Responsabilidades de presentación

### ViewModel

- `@Observable @MainActor` y fachada de una pantalla.
- Expone estado visual, navegación, selección y acciones semánticas.
- Recibe dependencias por inicializador.
- Conserva y coordina Stores cuando se hayan justificado.
- No importa Firebase ni tipos SwiftData salvo `ModelContext` en la frontera de operación aprobada; no almacena el contexto, no lo cruza entre actores y no implementa invariantes puras de Domain.
- Para esa frontera conserva una closure `@MainActor` inyectada que recibe un valor de Domain y el contexto. App la compone con un adaptador de Data; el ViewModel no conoce ese tipo concreto y Data no importa Presentation.

### View

- Representa estado y llama acciones semánticas del ViewModel; no contiene validación, filtrado, cálculo, persistencia, red o decisiones de negocio.
- Si una acción inserta, actualiza o borra con el contexto principal, obtiene `@Environment(\.modelContext)` y lo pasa al ViewModel sin invocar operaciones del contexto.
- Es el único tipo que conforma a `View` en su archivo, usa las formas trailing closure de SwiftUI y no declara `@ViewBuilder` redundante.
- Incluye un `#Preview` con el trait `PreviewModifier` compartido y datos de test navegables.

### Store opcional

- `@Observable @MainActor` y una única responsabilidad cohesiva.
- Orquesta casos de uso y contratos; mantiene tareas, carga, error y cancelación de su capacidad.
- Se introduce ante Massive ViewModel, reutilización real o necesidad de prueba aislada.
- No se crea en una pantalla simple ni duplica estado del ViewModel. Observation propaga las propiedades leídas por la View.

## Criterio operativo para extraer un Store

El número de líneas, propiedades o métodos no justifica por sí solo un Store. La extracción requiere que la responsabilidad candidata cumpla todos estos criterios:

1. Puede nombrarse como una capacidad cohesiva independiente de la pantalla, por ejemplo edición de cliente o gestión del borrador.
2. Posee estado mutable, transiciones, tareas, errores o cancelación propios que no pertenecen a la navegación o presentación global de la pantalla.
3. Tras extraerla, el ViewModel continúa siendo la fachada que coordina la pantalla y el Store conserva una única fuente de verdad para su capacidad.
4. El Store solo recibe UseCases o contratos de Domain; no recibe Views, tipos de SwiftData/Firebase ni el contenedor completo de dependencias.

Además, debe existir al menos una presión demostrable:

- la capacidad se reutiliza en más de una pantalla o flujo;
- su ciclo de vida, reintento o cancelación necesita evolucionar y probarse de forma aislada;
- el ViewModel ya coordina varias capacidades con motivos de cambio distintos; o
- probar su máquina de estados de forma independiente aporta cobertura que no sería clara desde la fachada de pantalla.

No son razones suficientes una posible reutilización futura, envolver un único UseCase, reducir visualmente el tamaño de un archivo o imitar la estructura de otra feature.

### Propiedad e inyección

| Tipo | Responsabilidad |
|---|---|
| `App` | Compone repositories, UseCases y, cuando aplica, la closure de mutación sobre el adaptador Data. |
| `Screen` | Recibe los UseCases y closures de operación necesarios y crea el ViewModel mediante `@State`. |
| `ViewModel` | Crea y conserva el Store, mantiene navegación/selección y es el único punto de Presentation que invoca la closure con el contexto recibido. |
| `Store` | Es dueño del estado, tareas y transiciones de su capacidad; no recibe `ModelContext`. |
| `View` | Lee estado y emite una única llamada semántica al ViewModel; solo pasa el `ModelContext` del entorno cuando la operación SwiftData lo requiere. |

El ViewModel puede exponer una propiedad calculada que lea estado observable del Store, pero nunca mantiene una copia mutable del mismo estado ni reenvía manualmente notificaciones.

### Ejemplo de extracción justificada

Si una futura pantalla de detalle incorpora una edición con borrador, guardado, reintento y cancelación independientes, el flujo de construcción sería:

```text
AppDependencies.saveClientInMainContext
    -> ClientDetailScreen(client:saveClient:)
    -> ClientDetailViewModel(client:saveClient:)
    -> ClientEditingStore(client:)
```

```swift
import SwiftData

typealias ClientMainContextMutation =
    @MainActor (Client, ModelContext) async throws -> Void

@Observable @MainActor
final class ClientEditingStore {
    struct Draft: Equatable {
        let id: Client.ID
        var displayName: String

        var client: Client {
            Client(id: id, displayName: displayName)
        }
    }

    enum Phase: Equatable {
        case editing
        case saving
        case saved
        case failed
    }

    private(set) var draft: Draft
    private(set) var phase: Phase = .editing

    init(client: Client) {
        draft = Draft(id: client.id, displayName: client.displayName)
    }

    func updateDisplayName(_ displayName: String) {
        guard phase != .saving else { return }
        draft.displayName = displayName
        phase = .editing
    }

    func beginSaving() -> Client? {
        guard phase != .saving else { return nil }
        phase = .saving
        return draft.client
    }

    func markSaved() {
        phase = .saved
    }

    func cancelSaving() {
        phase = .editing
    }

    func markFailed() {
        phase = .failed
    }
}

@Observable @MainActor
final class ClientDetailViewModel {
    enum Destination {
        case client(Client.ID)
    }

    let editingStore: ClientEditingStore
    private(set) var destination: Destination?
    var editingPhase: ClientEditingStore.Phase { editingStore.phase }
    private let saveClient: ClientMainContextMutation

    init(client: Client, saveClient: @escaping ClientMainContextMutation) {
        editingStore = ClientEditingStore(client: client)
        self.saveClient = saveClient
    }

    func save(modelContext: ModelContext) async {
        guard let client = editingStore.beginSaving() else { return }

        do {
            try Task.checkCancellation()
            try await saveClient(client, modelContext)
            try Task.checkCancellation()
            editingStore.markSaved()
            destination = .client(editingStore.draft.id)
        } catch is CancellationError {
            editingStore.cancelSaving()
        } catch {
            editingStore.markFailed()
        }
    }

    func retry(modelContext: ModelContext) async {
        await save(modelContext: modelContext)
    }
}
```

`ClientEditingStore` es la única fuente de verdad del borrador y de las fases de edición, guardado, éxito y error, pero nunca recibe el contexto. `ClientDetailViewModel` conserva la closure, recibe el `ModelContext` de la View en cada intento, mantiene concurrencia estructurada y coordina el éxito hacia navegación. `App` crea esa closure capturando un adaptador `@MainActor` de Data; ese adaptador transforma `Client` a su modelo, guarda localmente y registra la operación de sync. Si guardar requiere una invariante pura, el ViewModel llama primero al UseCase que produce el `Client` o comando validado. La View solo ejecuta `viewModel.save(modelContext:)` o `retry(modelContext:)` y lee el estado, sin copiarlo.

Los `SaveFeatureUseCase` context-free definidos en 04.8 continúan siendo contratos válidos para flujos que no dependen del contexto de una View. No se les añade `ModelContext` ni se ignora el parámetro recibido para llamarlos desde esta frontera: una mutación UI ligada al contexto principal usa la closure contextual específica. La fase que implemente el primer flujo mutador debe justificar cuál de ambas capacidades necesita cada caller y evitar persistir dos veces.

### Decisión para la vertical actual

`ClientListViewModel` conserva un único estado visual y orquesta un único `ObserveClientsUseCase`, incluida su cancelación. No existe una segunda capacidad, reutilización ni ciclo de vida independiente, por lo que 03.5 no introduce `ClientListStore` ni una carpeta `Stores` vacía. Si esa responsabilidad aparece en una fase posterior, la extracción deberá cumplir el criterio anterior y comenzar con pruebas Swift Testing de sus transiciones.

## Estructura de una funcionalidad

```text
Features/Clients/
├── Domain/
│   ├── Entities/Client.swift
│   ├── Repositories/ClientRepository.swift
│   └── UseCases/
│       ├── ObserveClientsUseCase.swift
│       └── SaveClientUseCase.swift
├── Data/
│   ├── DTOs/ClientDTO.swift
│   ├── Models/ClientModel.swift
│   ├── DataSources/
│   ├── Mappers/
│   │   ├── ClientDTO+Domain.swift
│   │   └── ClientModel+Domain.swift
│   ├── Repositories/DefaultClientRepository.swift
│   └── Sync/
│       ├── ClientSyncEngine.swift
│       └── ClientSyncPolicy.swift
└── Presentation/
    ├── Screens/ClientListScreen.swift
    ├── Views/ClientRow.swift
    ├── ViewModels/ClientListViewModel.swift
    └── Stores/ClientEditingStore.swift  # Solo si se justifica
```

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 03.1 | Crear entidad, contrato `Repository` y `UseCase` de una vertical mínima. | Caso de uso con repository fake. | Domain no importa UI/Data. |
| 03.2 | Crear implementación fake y composición en `AppDependencies`. | Resolución de dependencias controladas. | `@Environment` distribuye el contenedor tipado. |
| 03.3 | Crear ViewModel `@Observable @MainActor`. | Estado inicial, acción, error y cancelación. | ViewModel conoce Domain y, solo cuando aplica, `ModelContext` más una closure inyectada; nunca un tipo concreto de Data. |
| 03.4 | Crear Screen y View declarativas. | Sin test UI nativo; validar lógica en ViewModel. | Un `View` por archivo; previews con trait compartido para carga, vacío, contenido, error y Dynamic Type. |
| 03.5 | Documentar criterio y ejemplo de extracción de Store. | Test de tracking/estado con Store fake o real solo si se introduce. | Sin estado duplicado ni Store ceremonial. |
| 03.6 | Añadir comprobaciones especializadas al review. | Fixtures que cada revisor detecte en su ámbito. | `$review-ios-standards` cubre arquitectura y `$review-swiftui-accessibility` cubre Views. |

## Resultado de fase

Vertical funcional sin `Interactor` ni `ModelLogic`, con límites claros, DI por Environment e inicializadores, y una regla explícita para Stores.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
