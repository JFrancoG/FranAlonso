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
```

La View no recibe repositorios o casos de uso arbitrarios como service locator. Obtiene un conjunto de dependencias tipado desde `@Environment` en el límite de composición y crea/conserva el ViewModel mediante el mecanismo de estado apropiado.

## Responsabilidades de presentación

### ViewModel

- `@Observable @MainActor` y fachada de una pantalla.
- Expone estado visual, navegación, selección y acciones semánticas.
- Recibe dependencias por inicializador.
- Conserva y coordina Stores cuando se hayan justificado.
- No importa Firebase o SwiftData ni implementa reglas de negocio.

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
| `App` | Compone repositories y UseCases concretos. |
| `Screen` | Recibe los UseCases necesarios en su inicializador y crea el ViewModel mediante `@State`. |
| `ViewModel` | Crea y conserva el Store con esos UseCases; mantiene navegación, selección y coordinación de pantalla. |
| `Store` | Es dueño del estado, tareas y acciones de su capacidad. |
| `View` | Lee el estado del ViewModel o del Store conservado y emite intenciones semánticas. |

El ViewModel puede exponer una propiedad calculada que lea estado observable del Store, pero nunca mantiene una copia mutable del mismo estado ni reenvía manualmente notificaciones.

### Ejemplo de extracción justificada

Si una futura pantalla de detalle incorpora una edición con borrador, guardado, reintento y cancelación independientes, el flujo de construcción sería:

```text
AppDependencies.saveClient
    -> ClientDetailScreen(client:saveClient:)
    -> ClientDetailViewModel(client:saveClient:)
    -> ClientEditingStore(client:saveClient:)
```

```swift
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
    private let saveClient: SaveClientUseCase

    init(client: Client, saveClient: SaveClientUseCase) {
        draft = Draft(id: client.id, displayName: client.displayName)
        self.saveClient = saveClient
    }

    func updateDisplayName(_ displayName: String) {
        guard phase != .saving else { return }
        draft.displayName = displayName
        phase = .editing
    }

    func save() async {
        guard phase != .saving else { return }
        phase = .saving

        do {
            try Task.checkCancellation()
            try await saveClient(draft.client)
            try Task.checkCancellation()
            phase = .saved
        } catch is CancellationError {
            phase = .editing
        } catch {
            phase = .failed
        }
    }

    func retry() async {
        await save()
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

    init(client: Client, saveClient: SaveClientUseCase) {
        editingStore = ClientEditingStore(
            client: client,
            saveClient: saveClient
        )
    }

    func save() async {
        await editingStore.save()

        if editingStore.phase == .saved {
            destination = .client(editingStore.draft.id)
        }
    }
}
```

`ClientEditingStore` es la única fuente de verdad del borrador y de las fases de edición, guardado, éxito y error. Su método `save()` mantiene concurrencia estructurada: quien lo invoca conserva la tarea y la cancelación vuelve a un estado editable; `retry()` reutiliza la misma transición sin duplicar reglas. `ClientDetailViewModel` conserva una responsabilidad diferente al coordinar el éxito hacia navegación. La View lee `viewModel.editingStore.draft` y `viewModel.editingPhase`, sin copiar estado mutable.

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
│   ├── Mappers/ClientMapper.swift
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
| 03.3 | Crear ViewModel `@Observable @MainActor`. | Estado inicial, acción, error y cancelación. | ViewModel solo conoce Domain. |
| 03.4 | Crear Screen y View declarativas. | Sin test UI nativo; validar lógica en ViewModel. | Previews de carga, vacío, contenido y error. |
| 03.5 | Documentar criterio y ejemplo de extracción de Store. | Test de tracking/estado con Store fake o real solo si se introduce. | Sin estado duplicado ni Store ceremonial. |
| 03.6 | Añadir comprobación de límites y nomenclatura al review. | Fixture que el revisor detecte. | `$review-ios-standards` informa desviaciones. |

## Resultado de fase

Vertical funcional sin `Interactor` ni `ModelLogic`, con límites claros, DI por Environment e inicializadores, y una regla explícita para Stores.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md). Cada fila termina con subagente `$review-ios-standards`, corrección y segunda auditoría.
