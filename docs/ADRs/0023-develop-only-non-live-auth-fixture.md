# ADR 0023 — Fixture de autenticación no-live exclusiva de Develop

## Estado

Aceptado

## Contexto

ADR 0019 deja la habilitación del proveedor y el provisionado de cuentas tras una puerta
operativa separada. La entrega 07.1 necesita validar Password AutoFill y los estados reales de
la raíz autenticada, pero el proyecto no tiene todavía proveedor ni usuario de pruebas. Activar
Firebase Authentication live solo para esa evidencia ampliaría el alcance operativo y podría
crear identidad o tráfico en el proyecto real.

El Firebase Local Emulator Suite ofrece un Auth Emulator, pero en un iPhone físico necesita un
proceso externo accesible desde la red local del Mac, puerto, permisos de red local y una cuenta
sembrada. Además, cuando se usa el identificador de un proyecto real, cualquier producto no
emulado puede seguir alcanzando recursos live. Esa topología es adecuada para integración con
Firebase, no para una fixture autónoma de UI y accesibilidad.

La composición actual configura Firebase en `AppDelegate` antes de construir la raíz y
`AppRuntime` crea adaptadores Firebase de telemetría, Auth y factories remotas. Una fixture que
solo sustituyera `FirebaseAuthenticationDataSource` no demostraría ausencia de configuración o
tráfico live. También contaminaría el binding Keychain de ADR 0021 si autorizase un UID ficticio
contra el almacén Develop durable.

## Drivers

- Ejecutar Login, sesión restaurada, biometría, logout y shell autenticado sin Firebase ni red.
- Mantener Domain, Repository, Use Cases, ViewModels y pantallas reales en la ruta validada.
- Decidir la fixture antes de `FirebaseApp.configure()` y de cualquier composición remota.
- Excluirla por compilación de Production y de cualquier configuración distribuible.
- No persistir credenciales, UID ficticio, binding Keychain ni datos de negocio.
- Preservar el comportamiento live actual cuando la fixture no esté habilitada de forma exacta.
- Mantener la validación de Password AutoFill honesta respecto a la ausencia de Associated
  Domains.

## Opciones consideradas

### Firebase Auth Emulator

Ejercita el SDK Firebase y es útil para pruebas de integración del adaptador. Se rechaza para
PLU-27 porque añade proceso, red local, puerto y seed, no elimina por sí solo el riesgo de otros
productos live y no resuelve la asociación de dominios de Password AutoFill.

### Adaptador determinista en la frontera Data

Sustituye únicamente el proveedor de autenticación y conserva las capas superiores reales. Un
plan de arranque anterior a Firebase puede seleccionar además almacenamiento efímero,
telemetría nula y una composición sin factories remotas. Es la opción elegida.

### Inyección directa de estados de Preview en pantallas

Es útil para previews, pero evita Repository, Use Cases, stream de sesión y coordinación de
raíz. No demuestra el flujo runtime que bloquea 07.1.

### Usuario Firebase live no productivo

Permitiría probar el proveedor real, pero exige habilitación y datos live, depende de red y
mezcla una puerta operativa futura con evidencia de UI. Se rechaza para esta subfase.

## Decisión

Se añadirá una fixture determinista en Data y App, exclusiva del proceso
`Debug-Develop`. La selección será un `ApplicationLaunchPlan` inmutable resuelto una vez por
proceso antes del bootstrap. Solo podrá activarse cuando coincidan las tres puertas siguientes:

1. el código está compilado con `FRANALONSO_AUTH_FIXTURE`;
2. `AppEnvironment` y el bundle corresponden a Develop;
3. existe exactamente uno de los argumentos de lanzamiento soportados: sesión cerrada o sesión
   restaurada.

`FRANALONSO_AUTH_FIXTURE` se definirá únicamente en la configuración del target
`Debug-Develop`. No estará en `Release-Develop`, `Debug-Production` ni `Release-Production`.
Los argumentos estarán desactivados por defecto y solo en `LaunchAction` del esquema Develop.
Un argumento ausente, desconocido o conflictivo seleccionará la ruta normal y nunca una
fixture parcial.

Cuando el plan seleccione la fixture, `AppDelegate` publicará un estado terminal
`fixtureReady` sin llamar a `configureFirebase()`. La composición no creará `AppRuntime`,
`FirebaseApp`, Firebase Auth, adaptadores Firebase de telemetría, factories remotas ni motores
de sincronización. Usará un `ModelContainer` en memoria y dependencias locales con adaptadores
de telemetría nulos. La ruta normal conservará el almacén durable y el bootstrap Firebase
existentes.

`DevelopAuthenticationDataSource` implementará el contrato real `AuthenticationDataSource`.
Tendrá un UID fijo, opaco y exclusivo de fixture, más una credencial sintética documentada que
no representa un secreto ni una persona. En modo sesión cerrada publicará primero `nil`; solo la
credencial exacta completará `signIn` y publicará después el mismo UID. Cualquier otra credencial
devolverá `credentialsRejected` sin mutar el stream. `signOut` actualizará la fuente y publicará
`nil`; la raíz permanecerá en logout pendiente hasta que su observación consuma ese valor
autoritativo. En modo sesión restaurada, el primer valor será el UID de fixture y no se ejecutará
`signIn`.

Cada observador recibirá todos los cambios en orden, sin coalescing, y tendrá un ciclo de vida
independiente. La cancelación o finalización liberará solo su continuación. La composición
seguirá pasando por `DefaultAuthenticationRepository`, los Use Cases y
`AuthenticationRootViewModel`.

La autorización local no será un no-op: aceptará exclusivamente el UID fijo de fixture y
lanzará `LocalPrincipalAuthorizationError.differentPrincipal` para cualquier otro. No se
construirá `KeychainLocalPrincipalDataSource`. La sesión restaurada conservará
`BiometricAuthenticator.localAuthentication()` para validar el diálogo y el desbloqueo reales
del dispositivo.

No se sembrarán clientes, productos, servicios ni ventas. El shell autenticado usará el
almacén en memoria vacío. La aplicación no persistirá la credencial sintética, aunque iOS puede
guardarla o sincronizarla si la persona la añade manualmente a Passwords; la evidencia incluirá
su eliminación posterior. Sin Associated Domains, la validación de Password AutoFill se
registrará como limitada al selector/teclado del sistema y al rellenado correcto de los campos,
sin afirmar recomendación automática asociada a dominio.

## Consecuencias

### Positivas

- La evidencia de UI y accesibilidad no depende de Firebase, red, seeds ni cuentas live.
- Se ejercitan las capas y pantallas reales por encima de la frontera Data reemplazable.
- Production y las configuraciones Release no contienen la capacidad activable.
- El almacén durable y su binding Keychain no pueden recibir el UID ficticio.
- La fixture permite repetir de forma determinista signed-out, sesión restaurada y logout.

### Negativas y riesgos

- No valida el SDK Firebase, la consola, tokens, Rules, red ni errores reales del proveedor.
- Añade una ruta de composición App que debe mantenerse pequeña y cubierta contra regresiones.
- Una credencial de fixture guardada manualmente puede permanecer en Passwords/iCloud Keychain
  hasta que la persona la elimine.
- La ausencia de Associated Domains limita la evidencia de sugerencias automáticas de AutoFill.
- Un error en las tres puertas podría exponer una fixture fuera de Develop; se mitiga mediante
  exclusión de compilación y tests source-backed de toda la matriz.

## Testing y validación

- RED/GREEN con Swift Testing para las tres puertas: compile condition, entorno/bundle y
  argumento único; ausencia, valor desconocido o conflicto conservan la ruta normal.
- Tests source-backed demuestran que `FRANALONSO_AUTH_FIXTURE` existe solo en el target
  `Debug-Develop` y que ningún action del esquema Production contiene argumentos de fixture.
- Spies demuestran cero invocaciones de configuración Firebase, Auth, telemetría Firebase y las
  cuatro factories remotas cuando la fixture está activa.
- Tests end-to-end de `DevelopAuthenticationDataSource` → Repository → Use Cases → raíz:
  valores iniciales y transiciones ordenadas, observadores independientes, liberación por
  cancelación, credencial incorrecta sin mutación, acceso solo tras retorno de login más stream
  coincidente, sesión restaurada bloqueada sin `signIn`, logout pendiente hasta `nil` y rechazo
  de un UID distinto.
- La composición crea una sola raíz de autenticación y usa un contenedor SwiftData en memoria,
  telemetría nula, biometría real y ningún Keychain.
- Build y suite completa mediante Xcode MCP, sin warnings; auditorías independientes de iOS y
  accesibilidad sin edición.
- En iPhone físico: Login, Password AutoFill con alcance limitado documentado, sesión
  restaurada, biometría, shell vacío, logout, VoiceOver, Voice Control, Switch Control, Full
  Keyboard Access, foco y anuncios aplicables. Después se elimina cualquier entrada manual de
  Passwords creada para la fixture.

## Migración o reversibilidad

La fixture se elimina retirando sus argumentos, la condición exclusiva, el adaptador Data y la
composición App. Domain, Presentation, el esquema SwiftData y los contratos live no cambian.

Si una fase futura necesita validar Firebase Auth, se diseñará una puerta de integración
separada con demo project o Emulator Suite, seed/export reproducible y aislamiento explícito de
todos los productos no emulados. Este ADR no autoriza habilitar proveedores, crear usuarios,
consultar identidades ni escribir datos live.

## Relaciones

- Complementa ADR 0002, ADR 0007, ADR 0019, ADR 0020, ADR 0021 y ADR 0022.
- Desbloquea la evidencia pendiente de PLU-26/07.1 y la validación runtime de PLU-28/07.2.
- No sustituye el proveedor del MVP ni autoriza Firebase live, Associated Domains o motores de
  sincronización.

## Referencias

- [Conectar la app al Authentication Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth)
- [Instalar y configurar Local Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure)
- [Firebase Auth para Swift](https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Classes/Auth)
- [Password AutoFill](https://developer.apple.com/documentation/security/password-autofill)
- [About the Password AutoFill workflow](https://developer.apple.com/documentation/security/about-the-password-autofill-workflow)
- [Local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
