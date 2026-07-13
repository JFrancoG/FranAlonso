# Fase 02 — Bootstrap del proyecto SwiftUI

## Objetivo

Crear el proyecto base con la plataforma y toolchain reales, SwiftUI, SwiftData, Firebase, Swift Testing, concurrencia estricta, warnings como errores, String Catalog y el kit de gobernanza.

## Prerrequisitos

Fase 01 aprobada, Bundle ID decidido, cuenta Firebase identificada y assets base disponibles.

## Decisiones de bootstrap

- Registrar Xcode, SDK, Swift y deployment target efectivos. Si el proyecto comienza en una beta, documentar la decisión y la estrategia de salida mediante ADR.
- Configurar strict concurrency según el toolchain real y documentar `SWIFT_DEFAULT_ACTOR_ISOLATION` por target. La arquitectura no depende de asumir un valor global.
- Crear solo targets necesarios. No crear target de UI tests; los tests unitarios/integración usan Swift Testing.
- Añadir por Swift Package Manager únicamente los productos Firebase Auth, Firestore y Storage que se utilicen.
- Mantener `GoogleService-Info.plist` y cualquier secreto según la política del repositorio; no publicar credenciales por defecto.
- Crear carpetas cuando exista un primer tipo real; no generar una jerarquía vacía completa.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 02.1 | Crear proyecto SwiftUI y registrar plataforma/toolchain. | `ProjectSanityTests` falla hasta poder cargar el composition root. | Arranca en los destinos acordados mediante Xcode MCP. |
| 02.2 | Activar warnings Swift/Clang como errores. | Introducir temporalmente un warning controlado y confirmar RED de build. | Build limpio tras retirarlo. |
| 02.3 | Configurar Swift y strict concurrency por target. | Fixture de aislamiento que falle con configuración incorrecta. | Settings documentados y cero diagnósticos. |
| 02.4 | Configurar Swift Testing y retirar XCTest/UI tests. | Test mínimo con `@Test` y `#expect`. | No quedan imports ni targets XCTest/XCUITest. |
| 02.5 | Crear `Localizable.xcstrings` y recursos base. | Test o revisión de recursos para claves críticas. | Sin cadenas visibles hardcodeadas. |
| 02.6 | Añadir módulos Firebase aprobados mediante SPM. | Test de composición con adaptadores falsos, sin Firebase real. | Productos resueltos y SDK encapsulado. |
| 02.7 | Crear `ModelContainer` de producción y factory en memoria. | CRUD in-memory con Swift Testing. | Contenedor aislado y guardado explícito. |
| 02.8 | Crear `AppDependencies` y `AppEnvironment` mínimos. | Test de composición con repositorios fake. | Ningún singleton o service locator. |
| 02.9 | Incorporar assets de consentimiento, ticket y factura. | Validación de nombres/recursos requeridos. | Assets cargan en previews. |
| 02.10 | Verificar `AGENTS.md`, ADRs, progreso y checklist de PR. | Revisión de enlaces y marcadores. | Gobernanza operativa en el repositorio. |

## Resultado de fase

Proyecto reproducible, sin warnings, con Swift Testing, contenedor SwiftData in-memory, Firebase limitado a adaptadores y reglas operativas instaladas.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md). Cada fila termina con subagente `$review-ios-standards`, corrección de hallazgos y segunda auditoría.
