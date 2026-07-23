# ADR 0011 — Límites SwiftUI y revisiones especializadas

## Estado

Aceptado

## Contexto

El cierre anterior ejecutaba dos auditorías completas con `$review-ios-standards`. La repetición detectaba correcciones, pero duplicaba la revisión de arquitectura y no reservaba un ámbito experto para composición SwiftUI, Dynamic Type, previews y accesibilidad.

El propietario exige además que una View no contenga negocio, que toda acción delegue en su ViewModel y que una mutación de SwiftData capture el `ModelContext` del entorno y lo entregue a la función pertinente del ViewModel. Esta frontera contradice la prohibición absoluta de SwiftData en Presentation del ADR 0001 y debe quedar explícita, acotada y reversible.

## Opciones consideradas

1. Mantener dos auditorías generalistas y SwiftData fuera de Presentation: conserva el aislamiento anterior, pero repite trabajo y no implementa la frontera solicitada.
2. Separar los revisores y ocultar siempre `ModelContext` detrás de Domain: mejora la revisión, pero no cumple la interacción View-ViewModel aprobada.
3. Separar las auditorías y permitir exclusivamente un `ModelContext` efímero en la frontera View-ViewModel: cumple el flujo solicitado, mantiene Domain puro y limita el acoplamiento a SwiftData.

## Decisión

Esta decisión sustituye el ADR 0001 y conserva su arquitectura por feature, ViewModel obligatorio y Store opcional, con las siguientes precisiones:

- Domain continúa libre de SwiftUI, SwiftData, Firebase y UIKit. Las invariantes puras permanecen en entidades, políticas y UseCases.
- Data conserva modelos persistentes, DTO, mappers, data sources, repositories y políticas de persistencia/sincronización.
- Una View solo representa estado y llama acciones semánticas del ViewModel. No valida, filtra, calcula, persiste, consulta red ni decide negocio.
- Cuando una acción inserta, actualiza o borra mediante el contexto principal de SwiftData, la View obtiene `@Environment(\.modelContext)` y lo pasa a la función `@MainActor` pertinente del ViewModel. La View no invoca operaciones del contexto ni lo almacena. El ViewModel lo trata como parámetro efímero, no lo conserva y no lo cruza entre actores.
- La frontera concreta es una closure de operación `@MainActor` que Presentation declara con una entrada de Domain y un `ModelContext`. `App` la compone capturando un adaptador de Data; el ViewModel la invoca y Data conserva el mapping, `insert`/`delete`/`save`, la cola local-first y los tipos persistentes. Domain no recibe `ModelContext`, Data no importa Presentation y el ViewModel no conoce la implementación concreta. Si existen invariantes puras, el ViewModel obtiene primero el valor o comando validado mediante el UseCase de Domain y solo después entrega ese resultado a la closure.
- Si el adaptador contextual y un Repository context-free coexisten, ambos delegan en una única primitiva interna de escritura de Data para compartir mapping, aceptación local, cola e idempotencia. No duplican esa política ni se invocan ambos para la misma mutación.
- Cada archivo Swift contiene un único tipo que conforme a `View`. SwiftUI usa trailing closures cuando no existe ambigüedad y `@ViewBuilder` solo en fronteras reales con varios hijos o ramas heterogéneas.
- Las dimensiones numéricas explícitas de contenido no textual significativo que deban acompañar Dynamic Type usan `@ScaledMetric(relativeTo:)`, evitando doble escalado del sistema y justificando tamaños deliberadamente fijos.
- Cada `View` incluye un `#Preview` en su archivo y cada preview aplica el trait compartido respaldado por `PreviewModifier`, con un `ModelContainer` de test en memoria y datos deterministas, idempotentes y navegables.
- El cierre ejecuta siempre `$review-ios-standards` para arquitectura, datos, concurrencia, testing y gobernanza. Si existe alcance SwiftUI, ejecuta en paralelo `$review-swiftui-accessibility`; sin UI, esa puerta es `N/A`. Tras correcciones se repite solo el ámbito afectado y ambos únicamente ante cambios cruzados.

## Consecuencias

### Positivas

- Los dos revisores tienen responsabilidades distintas y comprobables.
- Dynamic Type y accesibilidad visual reciben evidencia de previews reales, incluida la matriz soportada `Large`, `XXX Large` y `AX 5` mediante Xcode MCP.
- La View queda libre de negocio y operaciones de persistencia, aunque siga proporcionando el contexto ligado a su entorno.
- El contexto no se almacena ni cruza aislamiento, reduciendo el riesgo de usarlo desde el actor equivocado.

### Negativas y riesgos

- Presentation conoce el tipo `ModelContext` en una frontera estrecha y queda parcialmente acoplada a SwiftData.
- Las mutaciones del contexto principal añaden una closure de operación específica a la composición y no reutilizan sin más el contrato Repository puro de Domain.
- Las snapshots no validan VoiceOver, foco o rotor; esa evidencia sigue siendo semántica y, cuando aplique, manual.
- `PreviewModifier.makeSharedContext()` comparte y cachea contexto, por lo que un sembrado no idempotente puede contaminar previews.
- Las Views existentes deben migrar al trait compartido cuando exista el primer esquema SwiftData real; no se crea un modelo ceremonial para anticiparlo.

## Testing y validación

- Las invariantes, UseCases, ViewModels y persistencia mantienen Swift Testing; no se añaden XCTest o XCUITest.
- Xcode MCP descubre primero las variantes soportadas y renderiza las pantallas afectadas en `Large`, `XXX Large` y `AX 5` cuando estén disponibles.
- `$review-ios-standards` y `$review-swiftui-accessibility` devuelven hallazgos separados y de solo lectura.

## Migración o reversibilidad

El código existente se adapta al tocar cada superficie UI y, como máximo, antes de cerrar la fase 07. El `PreviewModifier` compartido se implementa cuando la fase 05 introduzca el primer modelo SwiftData real. Una decisión futura puede sustituir el parámetro `ModelContext` por una capacidad inyectada sin cambiar Domain.
