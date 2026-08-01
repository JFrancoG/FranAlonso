# ADR 0020 — Desbloqueo biométrico local de una sesión existente

## Estado

Aceptado

## Contexto

La fase 06 necesita permitir que la persona propietaria del dispositivo vuelva a entrar en la aplicación mediante Face ID o
Touch ID cuando Firebase ya conoce una sesión válida localmente. Este desbloqueo no es un proveedor de identidad, no crea una
sesión, no refresca un token y no demuestra que una revocación remota haya sido consultada recientemente.

ADR 0019 mantiene email y contraseña como único mecanismo de acceso del MVP. La biometría debe complementar ese acceso sin
almacenar ni reconstruir credenciales. `LocalAuthentication` tampoco puede filtrarse a Domain o Presentation y debe poderse
sustituir por operaciones deterministas en tests.

`LAContext` conserva estado de una evaluación y no conforma a `Sendable`. Una tarea Swift cancelada debe terminar de forma
cooperativa y detener la petición de plataforma en curso, sin recurrir a GCD, escapes inseguros de concurrencia o estado global.
Face ID requiere además una purpose string específica y localizable en el bundle de la aplicación.

## Drivers

- Desbloquear únicamente una sesión que el proveedor ya conoce localmente.
- No ofrecer passcode del dispositivo, companion device ni fallback a una contraseña de aplicación dentro del prompt biométrico.
- Mantener Domain independiente de `LocalAuthentication` y conservar una inyección determinista para tests.
- Confinar cada `LAContext` no enviable y propagar correctamente la cancelación de Swift Concurrency.
- No cachear la disponibilidad biométrica, porque puede cambiar entre intentos.
- Localizar y explicar de forma específica el uso de Face ID.

## Opciones consideradas

### Capability concreta de Domain y adaptador `LocalAuthentication`

Un valor `BiometricAuthenticator` almacena operaciones `@Sendable` y expone solo disponibilidad y autorización. Data proporciona
la factory semántica `localAuthentication()` y confina un `LAContext` fresco por intento dentro de un actor privado. Expresa la
única capacidad requerida sin crear una jerarquía de implementaciones ni filtrar tipos de plataforma.

### Protocolo `BiometricAuthenticator`

Permitiría conformidades nominales, pero el límite solo necesita dos operaciones inyectables y no existe una familia real de
implementaciones. Añadiría un existencial y tipos conformantes ceremoniales sin mejorar la sustitución en tests.

### `deviceOwnerAuthentication`

Permitiría fallback al passcode del dispositivo. Amplía la política más allá del requisito biométrico de 06.4 y cambia la promesa
de producto, por lo que se rechaza.

### `LocalAuthenticationView`

Integra el prompt en SwiftUI, pero añade Presentation y permite políticas de autenticación más amplias en el SDK activo. 06.4 no
incluye pantallas y necesita una frontera Domain reemplazable, por lo que se rechaza.

## Decisión

Domain define un valor concreto `BiometricAuthenticator` con dos operaciones privadas `@Sendable`:

- `canAuthenticate() -> Bool`, que consulta la disponibilidad actual en cada llamada y nunca la cachea.
- `authenticate(localizedReason:) async throws`, que solo completa cuando la evaluación biométrica autoriza el acceso.

`BiometricAuthenticationError` cierra los fallos relevantes en `denied`, `cancelled`, `unavailable`, `configuration` y
`unexpected`. Un motivo localizado vacío es un error de configuración. La cancelación de la tarea o un `CancellationError` del
proveedor se propagan como `CancellationError`, no como un error biométrico.

Data añade `BiometricAuthenticator.localAuthentication()`. Cada intento crea un `LAContext` nuevo, oculta el fallback de
contraseña con `localizedFallbackTitle = ""`, comprueba y evalúa `.deviceOwnerAuthenticationWithBiometrics` con el mismo contexto
y conserva ese contexto dentro de un actor privado por intento.

La operación usa `withTaskCancellationHandler`. Su handler invalida el contexto activo y la operación comprueba cancelación antes
de delegar y después de la suspensión, antes de mapear el resultado. Así, una carrera entre `LAContext.invalidate()` y el callback
de plataforma no convierte una tarea cancelada en rechazo o cancelación de usuario.

Los errores `authenticationFailed` y una evaluación `false` se traducen a `denied`. Las cancelaciones de usuario, sistema,
fallback o aplicación se traducen a `cancelled` cuando la tarea Swift sigue activa. La falta de passcode, biometría disponible o
enrolada, el bloqueo biométrico y la ejecución no interactiva se traducen a `unavailable`. Los dominios y códigos no reconocidos
se traducen a `unexpected`.

`NSFaceIDUsageDescription` se declara en `Configuration/FranAlonso-Info.plist` y se localiza mediante
`FranAlonso/Resources/InfoPlist.xcstrings`. La explicación en español será: “Face ID desbloquea el acceso a la sesión ya iniciada
en este dispositivo.”

La capability no se compone en `AppDependencies` durante 06.4. Los ViewModels la consumirán en 06.5 y la raíz solo la usará en
06.7 después de confirmar que existe una sesión local conocida. Email y contraseña siguen siendo el flujo visual alternativo.

## Consecuencias

### Positivas

- Domain expresa una capacidad pequeña, testeable y ajena a APIs Apple.
- Cada intento parte de un contexto sin autorizaciones reutilizadas.
- La política no almacena credenciales ni amplía el acceso a passcode o companion devices.
- La cancelación detiene activamente la petición y conserva `CancellationError` en la frontera pública.
- El actor confina el único estado de plataforma no enviable sin escapes inseguros.

### Negativas y riesgos

- Un dispositivo sin biometría disponible o enrolada debe recurrir al login normal cuando exista la UI de 06.6.
- El estado biométrico puede cambiar entre la comprobación de disponibilidad y la evaluación; el adaptador debe mapear ambos pasos.
- La presencia de una sesión local puede estar obsoleta respecto a revocación remota; esta decisión no añade validación de token.
- La cancelación requiere una tarea auxiliar limitada al ciclo de vida del intento para invocar la invalidación asíncrona del actor.

## Testing y validación

- TDD con Swift Testing y operaciones inyectadas; ningún test solicita biometría real.
- Disponibilidad positiva y negativa, autorización, denegación, cancelación, indisponibilidad y errores no reconocidos.
- Motivo vacío, cancelación previa, `CancellationError` del proveedor y cancelación durante una evaluación suspendida.
- Prueba determinista de que la cancelación invalida exactamente una vez y termina públicamente con `CancellationError`.
- Comprobación de sendability, build sin warnings, tests focalizados y suite completa mediante Xcode MCP.
- Verificación del Info.plist construido y auditorías independientes de iOS y localización/accesibilidad.

## Migración o reversibilidad

La factory concreta puede sustituirse por otro adaptador sin cambiar los callers de Domain. Ampliar la política a passcode,
companion device o un proveedor remoto requiere un nuevo ADR y pruebas de producto y seguridad. Retirar el desbloqueo biométrico
solo exige dejar de inyectar la capability en 06.7; no existe dato persistido que migrar.

## Relaciones

- Complementa ADR 0007 y ADR 0019.
- Implementa la decisión necesaria para la subfase 06.4 y prepara 06.5–06.7 sin componerlas.
- No autoriza Firebase live, Rules, App Check, SyncEngine, Keychain, ViewModels, pantallas ni gating de raíz.

## Referencias

- [Política biométrica de LocalAuthentication](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithbiometrics)
- [Comprobación de disponibilidad](https://developer.apple.com/documentation/localauthentication/lacontext/canevaluatepolicy(_:error:))
- [Evaluación de políticas](https://developer.apple.com/documentation/localauthentication/lacontext/evaluatepolicy(_:localizedreason:reply:))
- [Login con Face ID o Touch ID](https://developer.apple.com/documentation/localauthentication/logging-a-user-into-your-app-with-face-id-or-touch-id)
- [Acceso a recursos protegidos y purpose strings](https://developer.apple.com/documentation/uikit/requesting-access-to-protected-resources)
- [`LAContext.invalidate()`](https://developer.apple.com/documentation/localauthentication/lacontext/invalidate())
- [`withTaskCancellationHandler`](https://developer.apple.com/documentation/swift/withtaskcancellationhandler(operation:oncancel:))
