# ADR 0007 — Firebase acotado, telemetría y salida a Vapor

## Estado

Propuesto

## Contexto

Auth, Firestore y Storage son necesarios para el backend actual. FirebaseCore inicializa el SDK y Analytics/Crashlytics aportan observabilidad, aunque la política general evita dependencias externas y está prevista una migración del backend a Vapor.

## Opciones consideradas

1. No usar SDK externo y construir backend y observabilidad ahora: retrasa el MVP.
2. Acoplar Firebase a toda la app: rápido, migración costosa y riesgo de privacidad.
3. Aprobar productos Firebase concretos, con backend y telemetría encapsulados detrás de fronteras distintas.

## Decisión

La excepción externa aprobada queda limitada a estos productos SwiftPM:

| Producto | Responsabilidad autorizada |
|---|---|
| `FirebaseCore` | Bootstrap y configuración del SDK. |
| `FirebaseAuth` | Identidad y sesión remota. |
| `FirebaseFirestore` | Fuente remota y sincronización. |
| `FirebaseStorage` | Binarios y documentos remotos. |
| `FirebaseAnalyticsCore` | Analítica base sin capacidad IDFA. |
| `FirebaseCrashlytics` | Crashes, no-fatals y diagnóstico de estabilidad. |

Solo se añaden productos usados. Los imports y tipos Firebase permanecen en Data/Infrastructure; Domain y Presentation dependen de contratos propios. Auth, Firestore y Storage comparten contratos reemplazables por Vapor. Analytics y Crashlytics usan contratos de telemetría independientes, no modelan reglas de negocio y nunca son fuentes de verdad.

Analytics usa una allowlist versionada y Crashlytics limita logs/custom keys a diagnóstico no sensible. Ninguno recibe PII, contenido de clientes, documentos, notas, importes ni payloads de negocio. La recogida debe poder desactivarse. La aplicación no integra publicidad, IDFA ni `FirebaseAnalyticsIdentitySupport`. `GoogleService-Info.plist` permanece local e ignorado por Git.

## Consecuencias

- El MVP aprovecha backend y observabilidad actuales sin contaminar capas superiores.
- Backend y telemetría tienen ciclos de sustitución independientes.
- Analytics/Crashlytics añaden obligaciones de privacidad, configuración de recogida, revisión de datos y subida de símbolos.
- Se mantiene código adaptador y tests contractuales adicionales.

## Testing y validación

- Fakes deterministas y contract tests de backend y telemetría.
- Tests de allowlists, consentimiento, activación, desactivación y tolerancia a fallos.
- Revisión de imports Firebase fuera de Data/Infrastructure y búsqueda de PII en eventos, logs y custom keys.
- Validación de productos SwiftPM, `Package.resolved`, exclusión del plist, linker settings y subida de dSYM mediante Xcode MCP.

## Migración o reversibilidad

Crear adaptadores Vapor para Auth, Firestore y Storage, validar con contract tests y migrar datos/sync sin cambiar Domain o Presentation. FirebaseCore se retira cuando ya no quede ningún producto Firebase. Analytics y Crashlytics pueden conservarse o sustituirse por otros adaptadores de observabilidad sin bloquear la salida del backend a Vapor.
