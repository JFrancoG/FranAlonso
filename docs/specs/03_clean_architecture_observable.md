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
