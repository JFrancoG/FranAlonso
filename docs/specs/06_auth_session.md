# Fase 06 — Autenticación, sesión y biometría

## Objetivo

Implementar acceso Firebase con email y contraseña, observación de sesión, logout y desbloqueo biométrico local sin filtrar el SDK a Domain o Presentation.

## Diseño

- El único acceso del MVP es email y contraseña, conforme al [ADR 0019](../ADRs/0019-mvp-email-password-authentication.md). Las cuentas se provisionan externamente; alta, recuperación, teléfono y proveedores federados quedan fuera de alcance.
- Domain define `AuthenticationRepository`, `SignInUseCase`, `SignOutUseCase` y `ObserveSessionUseCase`.
- `AuthenticationSession` expone solo el identificador opaco y estable del principal. La ausencia de sesión representa signed-out; una sesión observada es la identidad conocida localmente por el proveedor, no prueba un token recién validado ni autorización Firestore.
- Email y contraseña son parámetros efímeros: nunca se serializan, persisten, registran o envían a telemetría. Credenciales inválidas y cuenta deshabilitada usan el mismo mensaje visible para evitar enumeración.
- `SignInUseCase` comprueba cancelación antes de validar y delegar. Tras delegar, el resultado del Repository es autoritativo; la carrera de una operación Firebase ya iniciada pertenece al contrato de 06.3.
- Data implementa `FirebaseAuthenticationDataSource` y `DefaultAuthenticationRepository`.
- `BiometricAuthenticator` encapsula LocalAuthentication como capacidad Apple sustituible en tests.
- Face ID/Touch ID desbloquea una sesión Firebase ya válida; no almacena ni reconstruye contraseñas.
- La raíz exige un principal publicado por el stream y una prueba local válida. Una sesión restaurada usa biometría; un login reciente puede usar email/password solo cuando el stream confirma exactamente el mismo UID.
- El almacén local se vincula a un UID opaco mediante Keychain. Si el binding falta, solo las 28 tablas completamente vacías permiten un claim atómico; cualquier fila o error falla cerrado, conforme al [ADR 0021](../ADRs/0021-local-store-principal-authorization.md).
- Un `nil`, UID distinto, reemplazo, cancelación o resultado obsoleto invalida la prueba efímera del login. Esa invalidez se registra atómicamente al consumir el stream y no depende de que SwiftUI entregue cada actualización visual. Por ello, email/password sigue siendo la recuperación si la biometría falla sin convertir el resultado aislado de `signIn` en autoridad.
- `LoginViewModel` y `SessionViewModel` son `@Observable @MainActor`.
- No se introduce Store: el alcance inicial es cohesivo. Solo se extraerá uno si el ViewModel acumula responsabilidades independientes demostrables.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 06.1 | Definir contratos, errores y casos de uso de autenticación. | Email/password válido, entradas vacías, error neutral y cancelación previa. | Domain sin Firebase/LocalAuthentication. |
| 06.2 | Implementar fake y `DefaultAuthenticationRepository`. | Contract tests del repositorio. | Errores de infraestructura traducidos. |
| 06.3 | Implementar adaptador Firebase Auth en Data. | Data source stub para respuestas del SDK. | SDK encapsulado y sesión observable. |
| 06.4 | Implementar `BiometricAuthenticator`. | Disponible, autorizado, denegado, cancelado y no disponible. | Sin almacenamiento de contraseña. |
| 06.5 | Implementar `LoginViewModel` y `SessionViewModel`. | Estado inicial, loading, error, éxito, logout y cancelación. | `@Observable @MainActor`. |
| 06.6 | Implementar pantallas y previews. | Lógica cubierta en ViewModels. | Textos en xcstrings y estados completos. |
| 06.7 | Integrar sesión con la raíz y el composition root. | Bootstrap, login confirmado, sesión restaurada, binding local, retry, logout y resultados obsoletos. | Login o shell autorizado, sin acceso protegido sin sesión observada y vinculada. |

## Resultado de fase

Autenticación y biometría testeables, con Firebase aislado y selección de la raíz gobernada por una sesión observable.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
