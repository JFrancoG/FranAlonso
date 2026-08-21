# ADR 0024 — Error determinista de Clientes exclusivo de Develop

## Estado

Aceptado

## Contexto

ADR 0023 proporciona dos estados deterministas de autenticación no-live y deja el shell autenticado sobre un almacén
en memoria vacío. La validación de 07.1 ya cubre Login, sesión restaurada, biometría, Clientes vacío y logout, pero no
puede alcanzar el estado de error real de Clientes sin introducir red, Firebase o una mutación de Presentation.

Convertir el error en un tercer modo de autenticación mezclaría responsabilidades. Permitir que un argumento de
Clientes desconocido o conflictivo vuelva silenciosamente a la ruta live sería aún más peligroso: una intención
explícita de fixture podría acabar configurando Firebase y el almacén durable por un error tipográfico.

## Drivers

- Ejercitar el estado de error real de Clientes mediante Repository, Use Case y ViewModel existentes.
- Mantener intactos Domain, Presentation, copy localizada y los dos modos de autenticación de ADR 0023.
- Conservar las garantías no-live, efímeras y exclusivas de `Debug-Develop`.
- Hacer fail-closed cualquier intención inválida de fixture de Clientes.
- Evitar seeds, Firebase, red, factories remotas y cambios en el esquema SwiftData.

## Opciones consideradas

### Tercer modo de autenticación

Se rechaza porque el fallo de Clientes es independiente del estado de autenticación y produciría combinaciones futuras
difíciles de modelar.

### Estado de error inyectado en Presentation

Se rechaza porque evitaría el contrato `ClientRepository`, `ObserveClientsUseCase` y la transición real de
`ClientListViewModel`.

### Repositorio Data determinista subordinado a sesión restaurada

Mantiene las capas reales y sustituye solo la frontera Data de Clientes. Es la opción elegida.

## Decisión

Se añade el argumento exacto `--franalonso-clients-fixture-observation-error`, disponible únicamente bajo
`FRANALONSO_AUTH_FIXTURE` y desactivado por defecto en `LaunchAction` del esquema Develop. Solo es válido junto con una
única instancia de `--franalonso-auth-fixture-restored-session`.

El plan de lanzamiento modelará por separado el modo de autenticación y el modo de Clientes. No se añadirá un tercer
modo de autenticación. Cuando no exista ningún argumento con prefijo `--franalonso-clients-fixture-`, ADR 0023 conserva
exactamente su comportamiento: un único argumento de autenticación conocido selecciona su fixture; cualquier ausencia,
valor desconocido, duplicado o conflicto de autenticación selecciona live.

La presencia de cualquier argumento con prefijo de fixture de Clientes expresa una intención no-live. Solo la
combinación formada por una sesión restaurada exacta y un error de observación exacto, ambos una sola vez, será válida.
Cualquier otra combinación —argumento standalone, signed-out, auth ausente, valor desconocido, duplicado o conflictivo
en cualquiera de las dos dimensiones— resolverá `invalidFixtureConfiguration` y nunca live.

`AppDelegate` transformará ese plan inválido en el estado terminal `fixtureConfigurationFailed` sin invocar
`configureFirebase()`. `ApplicationComposition` construirá para él un `ModelContainer` en memoria, dependencias locales
con telemetría nula, `runtime == nil`, raíz de autenticación ausente y cero factories live. `FranAlonsoApp` presentará el
mismo `ContentUnavailableView` localizado ya utilizado por el fallo de bootstrap; no se añade copy ni una View nueva.

La combinación válida inyectará `DevelopClientErrorRepository` en la composición local de ADR 0023. Este repositorio
Data, stateless y completamente protegido por `#if FRANALONSO_AUTH_FIXTURE`, finalizará inmediatamente
`observeClients()` con `Failure.unavailable` y lanzará el mismo error en `saveClient(_:)`. La ruta atravesará
`ClientRepository`, `ObserveClientsUseCase` y `ClientListViewModel`, que alcanzará su estado `failed` existente. La
fixture estándar seguirá usando `DefaultClientRepository` sobre SwiftData en memoria y conservará Clientes vacío.

## Consecuencias

### Positivas

- El error de Clientes es repetible en dispositivo sin tocar Firebase, red ni datos durables.
- Se valida el comportamiento de producción por encima de una frontera Data reemplazable.
- Un argumento de Clientes mal formado queda aislado en una terminal local y no puede activar live.
- No cambian Domain, Presentation, localización ni el modelo de autenticación aceptado.

### Negativas y riesgos

- Aumenta la matriz de resolución y requiere pruebas explícitas de duplicados, conflictos y valores desconocidos.
- El fallo sintético no demuestra códigos, latencia ni recuperación de Firebase real.
- La terminal de configuración reutiliza copy de bootstrap, por lo que diagnostica de forma segura sin detallar el
  argumento incorrecto en UI o logs.

## Testing y validación

- Swift Testing del resolver para la combinación válida y todas las configuraciones inválidas de Clientes.
- Tests de `DevelopClientErrorRepository` para observación y guardado.
- Spies que demuestran cero configuración Firebase y cero construcción live en la terminal inválida.
- Composición inválida en memoria, prístina, sin runtime ni raíz de autenticación.
- Composición válida con sesión restaurada real y transición de Clientes hasta `ClientListViewModel.failed`.
- Regresión de los dos modos de ADR 0023 y de la lista vacía estándar.
- Tests focales, suite completa, builds Develop y Production y diagnósticos mediante Xcode MCP, sin warnings.
- En iPhone físico: sesión restaurada, biometría, error de Clientes, VoiceOver, Voice Control, Switch Control, Full
  Keyboard Access, Dynamic Type y ventana cuando apliquen, y logout. Después quedan todos los argumentos desactivados.
- Auditorías read-only de estándares iOS y accesibilidad sin hallazgos abiertos.

## Migración o reversibilidad

Se elimina retirando el argumento, el modo de Clientes, el repositorio Data y sus seams protegidos. Las rutas live y las
pantallas no requieren migración.

## Relaciones

- Complementa ADR 0023 y conserva sus dos modos de autenticación y sus garantías no-live.
- Complementa ADR 0022 para cerrar la evidencia runtime del estado de error de Clientes.
- No autoriza Firebase live, seeds, cuentas, persistencia, motores de sincronización ni una nueva pantalla.
