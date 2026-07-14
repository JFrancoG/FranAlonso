# Fase 01 — Constitución del proyecto

## Objetivo

Fijar las reglas no negociables de producto, arquitectura, persistencia, concurrencia, testing y entrega antes de escribir código.

## Plataforma y herramientas

- Comprobar el deployment target, SDK, Xcode y versión de Swift del proyecto real antes de elegir APIs.
- Usar la opción moderna compatible con ese target. No elevarlo ni adoptar una beta como efecto lateral.
- Tratar warnings Swift y Clang como errores desde el bootstrap.
- Usar Xcode MCP primero para inspeccionar, compilar, ejecutar tests y leer diagnósticos. No usar `xcodebuild` o XcodeBuildMCP como sustitución silenciosa.
- Consultar Cupertino MCP cuando disponibilidad, aislamiento o patrón recomendado de una API Apple pueda haber cambiado.

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
- `Data` contiene DTO, modelos SwiftData, data sources, mappers, implementaciones de repositorio, actores de persistencia y sincronización.
- `Presentation` contiene pantallas, vistas, ViewModels y Stores opcionales. No importa Firebase o SwiftData.
- `App` es el composition root. Construye implementaciones y distribuye dependencias mediante `@Environment` e inicializadores.
- Cada pantalla mantiene un `ViewModel` `@Observable @MainActor` como fachada.
- Un Store se extrae únicamente cuando una responsabilidad cohesiva hace crecer el ViewModel, existe reutilización real o aporta una prueba aislada útil. No se duplica estado entre Store y ViewModel.
- No se crean protocolos, carpetas o Stores vacíos “por si acaso”.

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
│       │   ├── DTOs/
│       │   ├── Models/
│       │   ├── DataSources/
│       │   ├── Mappers/
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
| Mapper | `ClientMapper.swift` |
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
- Los imports del SDK Firebase quedan dentro de `Data / Infrastructure`. Auth, Firestore y Storage deben poder sustituirse por Vapor sin cambiar Domain o Presentation; Analytics y Crashlytics se sustituyen de forma independiente detrás de contratos propios.

## Concurrencia y código

- View, ViewModel y Store son `@MainActor`.
- Dominio, red, persistencia, sincronización y render pesado permanecen fuera de MainActor salvo razón demostrada.
- La configuración de default actor isolation se inspecciona y documenta por target; no se presupone.
- `nonisolated` se usa solo cuando sea semánticamente seguro, nunca para silenciar al compilador.
- Se aplica `Sendable`, cancelación y concurrencia estructurada. `@unchecked Sendable` requiere bloqueo probado, ADR y tests.
- Serialización exclusiva mediante `Codable`, `JSONEncoder` y `JSONDecoder`.
- Todo texto visible reside en `Localizable.xcstrings`.
- Solo se permiten frameworks Apple, salvo `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalyticsCore` y `FirebaseCrashlytics` como excepción aprobada y acotada.

## Observabilidad y privacidad

- Analytics registra únicamente eventos y parámetros de una allowlist versionada; no recibe nombres, correos, teléfonos, contenido de clientes, documentos, notas, importes ni otros payloads de negocio.
- Crashlytics recibe fallos, errores no fatales y claves diagnósticas no sensibles; sus logs y custom keys tampoco contienen PII o payloads de negocio.
- La aplicación no incorpora publicidad, IDFA ni `FirebaseAnalyticsIdentitySupport`.
- Analytics y Crashlytics no son fuentes de verdad y sus fallos nunca bloquean autenticación, persistencia, sincronización ni flujos de usuario.
- `GoogleService-Info.plist` permanece local, ignorado por Git y fuera de commits, parches, logs y documentación.

## Testing

- TDD real con Swift Testing para tests unitarios y de integración.
- No se crean XCTest, XCUITest ni tests UI nativos.
- Auth, Firestore, Storage, Analytics y Crashlytics se sustituyen por dobles deterministas.
- SwiftData usa un `ModelContainer` en memoria por test o suite segura.
- Reloj, UUID, aleatoriedad y errores se inyectan cuando afectan al resultado.
- ViewModels cubren coordinación; Stores cubren transiciones, errores, cancelación y reintentos; sincronización cubre idempotencia, conflictos y recuperación.
- La telemetría prueba allowlists, exclusión de datos sensibles, consentimiento, activación, desactivación y tolerancia a fallos sin usar Firebase real.

## Reglas de producto

- Todo lo cobrable es un `Service`; `Product` solo representa inventario físico.
- Un servicio de tipo producto requiere `linkedProductID`. Precio y descuento pertenecen al servicio o al snapshot de la venta, nunca a `Product`.
- El cálculo monetario usa `Decimal` mediante un value object `Money`; no usa `Double`.
- IVA y descuentos se modelan como valores o políticas explícitas y quedan congelados en cada `SaleLine`.
- Stock insuficiente muestra aviso y confirmación, pero no bloquea; el comportamiento y el stock negativo se prueban.
- Ticket y factura tienen series remotas, independientes y atómicas. No se asigna un número local definitivo.
- Los PDF se generan con frameworks Apple y el correo queda preparado para envío manual.
- La demo de citas no sustituye al sistema actual durante el MVP.

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

Ejecutar íntegramente [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluida la auditoría con un subagente `$review-ios-standards` y la segunda revisión tras corregir hallazgos.
