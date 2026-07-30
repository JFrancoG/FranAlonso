# ADR 0019 — Email y contraseña para la autenticación del MVP

## Estado

Aceptado

## Contexto

La fase 06 exige autenticación, observación de sesión y cierre de sesión, pero su
especificación inicial no seleccionaba el mecanismo de acceso. ADR 0007 autoriza
`FirebaseAuth` como implementación temporal y reemplazable de identidad y sesión remota, sin
decidir si el producto debe usar email y contraseña, teléfono o un proveedor federado.

La aplicación necesita un primer acceso compatible con el backend actual y con una futura
sustitución por Vapor. Las credenciales no pueden persistirse, entrar en telemetría ni filtrarse
fuera de la operación de autenticación. La UI tampoco debe revelar si una cuenta concreta
existe. Firebase puede conservar localmente un principal conocido y publicar cambios de estado,
pero esa presencia no demuestra por sí sola que el token se haya validado de nuevo contra el
servidor.

El método async de email y contraseña de Firebase no ofrece cancelación de la petición
subyacente. Una tarea cancelada después de delegar puede coexistir con un login completado y un
cambio global de sesión, por lo que el contrato Domain no puede prometer una cancelación atómica
que el proveedor no soporta.

## Drivers

- Proporcionar el acceso más pequeño que cubre el MVP sin capacidades, callbacks o flujos
  adicionales de plataforma.
- Mantener Firebase fuera de Domain y Presentation y conservar una salida viable a Vapor.
- Evitar almacenamiento, serialización, logging o telemetría de contraseñas.
- Evitar enumeración de cuentas mediante mensajes de login indistinguibles.
- Exponer una observación de identidad honesta respecto a caché, revocación y cancelación.
- Mantener fuera de 06.1 toda configuración live, autorización Firestore y activación de sync.

## Opciones consideradas

### Email y contraseña

Encaja con el backend actual, no exige capabilities Apple ni callbacks de aplicación y puede
mantener el mismo contrato al sustituir Firebase por Vapor. Requiere provisionar cuentas y
proteger el flujo contra enumeración; no aporta recuperación o alta de usuario por sí solo.

### Sign in with Apple

Evita manejar una contraseña propia en el cliente, pero añade capability, entitlement,
configuración del proveedor, nonce y un flujo de identidad distinto. No existe un requisito MVP
que justifique ese alcance.

### Autenticación por teléfono

Añade verificación telefónica, callbacks y configuración APNs asociada. El proyecto no tiene
esas capacidades preparadas y la fase no requiere vincular identidad a un número de teléfono.

### Contrato genérico para múltiples proveedores

Un enum de credenciales o estrategia de proveedor anticiparía variantes sin ningún caller real.
Ocultaría diferencias de flujo y seguridad que deben decidirse explícitamente cuando exista el
requisito.

## Decisión

El único mecanismo de acceso del MVP será email y contraseña. Las cuentas se provisionan fuera
de la aplicación; alta, recuperación de contraseña, teléfono y proveedores federados quedan
fuera de alcance.

Domain define un `AuthenticationSession` que expone únicamente un `id` estable y opaco del
principal autenticado. El identificador no es un token, secreto ni ID de una ejecución concreta
de sesión. La ausencia de valor en el stream representa el estado signed-out. Un valor presente
representa el principal conocido localmente por el proveedor; no demuestra un refresh reciente,
autorización Firestore ni vigencia frente a una revocación remota.

`AuthenticationRepository` expone `signIn(email:password:)`, `signOut()` y una observación
`AsyncStream<AuthenticationSession?>`. Domain y Presentation no conocen tipos Firebase. El
stream de sesión será la autoridad para elegir la raíz en 06.7; el retorno de `signIn` solo
confirma el resultado de esa intención.

`SignInUseCase` comprueba cancelación antes de validar la entrada, rechaza email o contraseña
vacíos y después delega. No comprueba otra vez la cancelación ni ejecuta un logout compensatorio
tras la delegación: desde ese punto, el resultado del Repository es autoritativo. Un
`CancellationError` emitido por el Repository se propaga intacto. La semántica de una carrera
durante el adaptador Firebase se especificará y probará en 06.3.

`AuthenticationError` distingue credenciales inválidas, cuenta deshabilitada, indisponibilidad
temporal, configuración, almacenamiento seguro y fallo inesperado sin exponer códigos Firebase.
Presentation mostrará el mismo mensaje genérico para credenciales inválidas y cuenta
deshabilitada. Email y contraseña son parámetros efímeros: no conforman un valor `Codable`, no
se persisten y no se envían a logs o telemetría.

La fase 06 no cambia la topología Firebase existente. La habilitación del proveedor, la
protección contra enumeración y el provisionado de cuentas requieren una puerta operativa
separada y verificada antes de cualquier validación live.

## Consecuencias

### Positivas

- El primer flujo de acceso es pequeño, explícito y sustituible por Vapor.
- Domain modela solo identidad y sesión, sin tokens, claims ni tipos del SDK.
- Las contraseñas no adquieren una representación persistible o serializable propia.
- La política de mensajes reduce la capacidad de inferir si una cuenta existe.
- La cancelación describe únicamente garantías que la implementación puede cumplir.

### Negativas y riesgos

- El MVP no ofrece alta ni recuperación de contraseña dentro de la aplicación.
- Develop y Production conservan el pool de Authentication del proyecto Firebase actual.
- Una sesión cargada localmente puede quedar obsoleta hasta que el proveedor refresque el token
  o ejecute una operación remota.
- Cancelar la tarea tras delegar no garantiza impedir un login remoto ya iniciado.
- La política de revocación offline, el bloqueo biométrico y el aislamiento de datos locales
  entre identidades deben cerrarse antes de la integración de raíz.

## Testing y validación

- RED/GREEN de 06.1 con un actor fake determinista y sin Firebase real.
- Credenciales válidas, email vacío, contraseña vacía, cancelación previa y propagación de
  errores.
- Logout correcto y fallo de almacenamiento seguro.
- Observación ordenada de signed-out a sesión autenticada.
- Comprobación de sendability, imports de Domain, build sin warnings y tests mediante Xcode MCP.
- Auditoría independiente de arquitectura, concurrencia, testing, ADR y evidencia.

## Migración o reversibilidad

Un nuevo proveedor exige otro ADR que defina su flujo, privacidad, capacidades y cambios de
contrato. La sustitución por Vapor puede conservar email, contraseña y el identificador opaco sin
cambiar Domain o Presentation. Retirar email/password después de distribuirlo requiere una ruta
de migración de identidad y no se realizará como cambio de configuración silencioso.

## Relaciones

- Complementa ADR 0007.
- Implementa la decisión previa necesaria para la subfase 06.1.
- No autoriza Data, UI, biometría, Firebase Console, Rules, App Check, tráfico live, migraciones
  locales ni activación de `SyncEngine`.

## Referencias

- [Inicio de sesión con contraseña en iOS](https://firebase.google.com/docs/auth/ios/password-auth)
- [Referencia Swift de Firebase Auth](https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Classes/Auth)
- [Protección contra enumeración de email](https://cloud.google.com/identity-platform/docs/admin/email-enumeration-protection)
- [`Task.checkCancellation()`](https://developer.apple.com/documentation/swift/task/checkcancellation())
