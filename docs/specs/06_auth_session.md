# Fase 06 — Autenticación, sesión y biometría

## Objetivo

Implementar autenticación Firebase, observación de sesión, logout y desbloqueo biométrico local sin filtrar el SDK a Domain o Presentation.

## Diseño

- Domain define `AuthenticationRepository`, `SignInUseCase`, `SignOutUseCase` y `ObserveSessionUseCase`.
- Data implementa `FirebaseAuthenticationDataSource` y `DefaultAuthenticationRepository`.
- `BiometricAuthenticator` encapsula LocalAuthentication como capacidad Apple sustituible en tests.
- Face ID/Touch ID desbloquea una sesión Firebase ya válida; no almacena ni reconstruye contraseñas.
- `LoginViewModel` y `SessionViewModel` son `@Observable @MainActor`.
- No se introduce Store: el alcance inicial es cohesivo. Solo se extraerá uno si el ViewModel acumula responsabilidades independientes demostrables.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 06.1 | Definir contratos, errores y casos de uso de autenticación. | Credenciales válidas, inválidas y cancelación. | Domain sin Firebase/LocalAuthentication. |
| 06.2 | Implementar fake y `DefaultAuthenticationRepository`. | Contract tests del repositorio. | Errores de infraestructura traducidos. |
| 06.3 | Implementar adaptador Firebase Auth en Data. | Data source stub para respuestas del SDK. | SDK encapsulado y sesión observable. |
| 06.4 | Implementar `BiometricAuthenticator`. | Disponible, autorizado, denegado, cancelado y no disponible. | Sin almacenamiento de contraseña. |
| 06.5 | Implementar `LoginViewModel` y `SessionViewModel`. | Estado inicial, loading, error, éxito, logout y cancelación. | `@Observable @MainActor`. |
| 06.6 | Implementar pantallas y previews. | Lógica cubierta en ViewModels. | Textos en xcstrings y estados completos. |
| 06.7 | Integrar sesión con la raíz y el composition root. | Estado autenticado/no autenticado. | Login o shell autenticado, sin acceso protegido sin sesión válida. |

## Resultado de fase

Autenticación y biometría testeables, con Firebase aislado y selección de la raíz gobernada por una sesión observable.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
