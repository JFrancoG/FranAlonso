# Fase 02 — Bootstrap del proyecto SwiftUI

## Objetivo

Crear el proyecto base con la plataforma y toolchain reales, SwiftUI, SwiftData, Firebase, Swift Testing, concurrencia estricta, warnings como errores, String Catalog y el kit de gobernanza.

## Prerrequisitos

Fase 01 aprobada, Bundle ID decidido, cuenta Firebase identificada y assets base disponibles.

## Decisiones de bootstrap

- Registrar Xcode, SDK, Swift y deployment target efectivos. Si el proyecto comienza en una beta, documentar la decisión y la estrategia de salida mediante ADR.
- Configurar strict concurrency según el toolchain real y documentar `SWIFT_DEFAULT_ACTOR_ISOLATION` por target. La arquitectura no depende de asumir un valor global.
- Crear solo targets necesarios. No crear target de UI tests; los tests unitarios/integración usan Swift Testing.
- Añadir por Swift Package Manager únicamente los productos aprobados que se utilicen: `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalyticsCore` y `FirebaseCrashlytics`.
- Usar `FirebaseCore` solo para el bootstrap; mantener Auth, Firestore y Storage detrás de adaptadores sustituibles por Vapor, y Analytics/Crashlytics detrás de contratos de telemetría sustituibles de forma independiente.
- Mantener `GoogleService-Info.plist` exclusivamente en local, ignorado por Git y nunca staged. Validar con `git check-ignore` y versionar el `Package.resolved` compartido.
- Definir una allowlist de eventos y parámetros antes de emitir Analytics. No enviar PII, contenido de clientes, documentos, notas, importes u otros payloads de negocio.
- No añadir `FirebaseAnalyticsIdentitySupport`, IDFA ni capacidades publicitarias; la aplicación no tiene una finalidad publicitaria.
- Configurar Crashlytics sin datos sensibles, con subida de dSYM y una prueba controlada de crash/no-fatal antes de considerarlo operativo.
- Crear carpetas cuando exista un primer tipo real; no generar una jerarquía vacía completa.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 02.1 | Crear proyecto SwiftUI y registrar plataforma/toolchain. | `ProjectSanityTests` falla hasta poder cargar el composition root. | Build y tests mediante Xcode MCP; arranque de humo en simuladores representativos mediante la interfaz de Xcode mientras el MCP oficial no exponga una acción Run. |
| 02.2 | Activar warnings Swift/Clang como errores. | Introducir temporalmente un warning controlado y confirmar RED de build. | Build limpio tras retirarlo. |
| 02.3 | Configurar Swift y strict concurrency por target. | Fixture de aislamiento que falle con configuración incorrecta. | Settings documentados y cero diagnósticos. |
| 02.4 | Configurar Swift Testing y retirar XCTest/UI tests. | Test mínimo con `@Test` y `#expect`. | No quedan imports ni targets XCTest/XCUITest. |
| 02.5 | Crear `Localizable.xcstrings` y recursos base. | Test o revisión de recursos para claves críticas. | Sin cadenas visibles hardcodeadas. |
| 02.6 | Añadir y configurar los módulos Firebase aprobados mediante SPM. | Composición con fakes; allowlists, consentimiento y fallos de telemetría sin Firebase real. | Productos exactos y `Package.resolved` versionados, plist local ignorado, SDK encapsulado, dSYM configurado y build limpio mediante Xcode MCP. |
| 02.7 | Crear `ModelContainer` de producción y factory en memoria. | CRUD in-memory con Swift Testing. | Contenedor aislado y guardado explícito. |
| 02.8 | Crear `AppDependencies` y `AppEnvironment` mínimos. | Test de composición con dobles deterministas de capacidades reales ya existentes; el primer repository fake pertenece a 03.1/03.2. | Ningún singleton, service locator ni abstracción ceremonial. |
| 02.9 | Incorporar plantillas PDF A4 de consentimiento, ticket y factura con nombres semánticos estables. | Validación de nombres, carga, número de páginas y tamaño A4. | PDF reales cargan en previews; el consentimiento queda marcado como borrador hasta la revisión jurídica. |
| 02.10 | Verificar `AGENTS.md`, ADRs, progreso y checklist de PR. | Revisión de enlaces y marcadores. | Gobernanza operativa en el repositorio. |

## Resultado de fase

Proyecto reproducible, sin warnings, con Swift Testing, contenedor SwiftData in-memory, backend Firebase limitado a adaptadores, telemetría privada y sustituible, y reglas operativas instaladas.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md) al cerrar cada fila.
