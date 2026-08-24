# ADR 0025 — Errores deterministas de raíz de autenticación exclusivos de Develop

## Estado

Aceptado

## Contexto

ADR 0023 introdujo una fixture de autenticación no-live con sesión cerrada y sesión restaurada. ADR 0024 añadió un
fallo determinista de Clientes y, para evitar una activación live accidental, hizo fail-closed cualquier intención
inválida de esa dimensión. Sin embargo, una intención explícita de fixture de autenticación desconocida, duplicada,
conflictiva o usada fuera de la identidad Develop todavía vuelve a live.

La evidencia de 07.3 necesita recorrer en runtime los estados `localAccessDenied` y `observationFailed` de la raíz real.
Las previews muestran su composición visual, pero no atraviesan DataSource, Repository, Use Cases, biometría, reemplazo
de observación ni logout. Provocar esos estados mediante Firebase ampliaría la puerta live y dejaría de ser
determinista; inyectarlos directamente en Presentation evitaría los contratos que deben validarse.

La superficie de fallo de bootstrap no necesita otro modo. Un argumento de Clientes standalone ya resuelve
`invalidFixtureConfiguration` antes de Firebase, compone almacenamiento local en memoria y llega al mismo builder
`bootstrapFailure` que el fallo real de bootstrap. Esta ruta demuestra la superficie compartida, pero no un fallo de
Firebase.

## Drivers

- Ejercitar `localAccessDenied(.differentPrincipal)` mediante sesión restaurada, biometría y autorización reales.
- Ejercitar `observationFailed` y demostrar que `Reintentar` sustituye la observación y recupera signed-out.
- Hacer fail-closed toda intención explícita de fixture inválida, sin cambiar el arranque live cuando no existe tal
  intención.
- Mantener la capacidad exclusiva de `Debug-Develop`, desactivada por defecto y cortada antes de Firebase.
- Conservar intactos Domain, Presentation, copy, localización, SwiftData durable, Keychain y las rutas live.
- Evitar estado global, temporizadores, sleeps, UI tests o inyección directa de estado SwiftUI.

## Opciones consideradas

### Dos modos en la fixture de autenticación existente

Amplía solo la composición Develop y el adaptador Data. Conserva la cadena de producción por encima de esa frontera y
permite verificar acciones reales. Es la opción elegida.

### Modos explícitos de bootstrap pendiente y fallido

Permitirían alcanzar exactamente cada caso del enum de bootstrap, pero ampliarían `ApplicationLaunchPlan`, delegate y
composición sin aportar otra superficie visual. Se rechazan para 07.3.

### Estado de Preview o Presentation inyectado en runtime

Evitaría tocar Data, pero omitiría Repository, Use Cases, observación, biometría y transiciones reales. Se rechaza.

### Firebase, red o almacenamiento durable

No serían deterministas y ampliarían una puerta live no autorizada. Se rechazan.

## Decisión

Se añaden dos argumentos bajo la condición existente `FRANALONSO_AUTH_FIXTURE`, únicamente en `Debug-Develop` y
desactivados por defecto en el esquema Develop:

- `--franalonso-auth-fixture-local-access-denied`;
- `--franalonso-auth-fixture-observation-failed`.

`ApplicationLaunchPlan` seguirá siendo la única decisión inmutable consumida antes del bootstrap. La ausencia total de
argumentos con prefijo de fixture conservará `.live`. La presencia de cualquier intención de fixture exigirá entorno
`develop`, bundle `com.plusprojects.FranAlonso.develop` y una combinación soportada exacta. Un valor desconocido,
duplicado, conflictivo, una mezcla incompatible o una identidad incorrecta resolverá
`invalidFixtureConfiguration`, nunca live.

Esta decisión sustituye únicamente la regla de ADR 0023 que enviaba a live una intención de autenticación inválida.
Conserva sus dos modos anteriores, sus puertas de compilación, la ruta live sin intención de fixture y todas sus
garantías de aislamiento. Conserva también la combinación exacta de Clientes y su terminal fail-closed de ADR 0024.

`DevelopAuthenticationFixture` añadirá dos configuraciones semánticas:

- `localAccessDenied`: comienza con la sesión restaurada y conserva `BiometricAuthenticator.localAuthentication()`.
  Tras un desbloqueo correcto, un authorizer Develop sin estado rechazará el principal fijo con
  `LocalPrincipalAuthorizationError.differentPrincipal`. El logout seguirá pasando por el DataSource y publicará
  `nil`, devolviendo la raíz a signed-out.
- `observationFailed`: comienza signed-out y configura el DataSource para finalizar únicamente su primera observación
  sin publicar un valor. `SessionViewModel` alcanzará `observationFailed`; `Reintentar` iniciará una segunda observación
  estable que publicará `nil` y recuperará signed-out.

El consumo del fallo transitorio pertenecerá a cada instancia actor de `DevelopAuthenticationDataSource`. No habrá
estado estático o global. El primer stream fallido no se almacenará entre los observadores persistentes y no dejará una
continuación pendiente; el actor serializará qué observación consume el fallo.

La terminal bootstrap existente se utilizará solo como evidencia de la superficie compartida
`bootstrapFailure`. Se documentará como configuración inválida local, no como simulación o validación de Firebase.

No cambian Views, ViewModels, Domain, `AppDelegate`, `ApplicationComposition`, `FranAlonsoApp`, Firebase, Keychain,
esquema SwiftData, copy, localización ni orientación. iPhone e iPad conservan las orientaciones actuales: una
preferencia portrait no satisface la excepción de necesidad esencial de ADR 0022 y WCAG 2.2, criterio 1.3.4.

## Consecuencias

### Positivas

- Los dos errores de raíz y sus acciones quedan repetibles en runtime sin red ni estado durable.
- Un error tipográfico en cualquier intención fixture no puede activar Firebase o el almacén live.
- Retry y logout se validan atravesando las capas reales existentes.
- Production y configuraciones Release no contienen la capacidad activable.

### Negativas y riesgos

- Crece la matriz de argumentos y debe mantenerse cubierta source-backed.
- El fallo one-shot presupone una única observación raíz inicial; si hubiera dos consumidores simultáneos, solo el
  primero consumiría el fallo y el segundo observaría recuperación.
- La terminal bootstrap no valida Firebase, red, códigos del proveedor ni recuperación del bootstrap real.
- Estas fixtures no sustituyen pruebas futuras de integración live o con emulador expresamente autorizadas.

## Testing y validación

- RED/GREEN con Swift Testing para ambos argumentos, configuraciones y matriz fail-closed completa.
- Tests del DataSource: primer stream termina, segundo emite `nil`, estado one-shot por instancia, observadores continuos
  y liberación de continuaciones sin regresión.
- Tests de composición: almacenamiento en memoria prístino, `runtime == nil`, raíz presente y cero factory live para
  todos los modos.
- Ruta `localAccessDenied`: restored → unlock → rechazo de autorización → error de raíz → logout → signed-out.
- Ruta `observationFailed`: primer load termina → Retry → segunda observación → signed-out.
- Regresión de la terminal bootstrap inválida: cero Firebase, composición local y raíz ausente.
- Tests source-backed: argumentos solo en Develop, todos `NO`, ausentes de Production y condición de compilación sin
  cambios.
- Diagnósticos, builds Develop y Production, focales y suite completa mediante Xcode MCP, sin warnings.
- Evidencia manual ADR 0022 en pasos pequeños para los tres estados runtime; todos los argumentos vuelven a `NO` al
  terminar. No se clasifica como validado ningún comportamiento no observado.

## Migración o reversibilidad

Se revierte retirando los dos argumentos, sus configuraciones, el comportamiento one-shot y los tests asociados. La
ruta live, Domain, Presentation, Firebase, datos durables y esquema SwiftData no requieren migración.

## Relaciones

- Sustituye únicamente el comportamiento fail-open de intenciones de autenticación inválidas fijado por ADR 0023.
- Complementa ADR 0024 y conserva su combinación de Clientes.
- Complementa ADR 0022 para la evidencia runtime de 07.3.
- No autoriza Firebase live, red, seeds, cuentas, persistencia, orientación bloqueada ni una pantalla nueva.

## Referencias

- [WCAG 2.2, criterio 1.3.4 Orientation](https://www.w3.org/TR/WCAG22/#orientation)
- [Understanding SC 1.3.4: Orientation](https://www.w3.org/WAI/WCAG22/Understanding/orientation.html)
- [UISupportedInterfaceOrientations](https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations)
- [Managing your app's information property list](https://developer.apple.com/documentation/bundleresources/managing-your-app-s-information-property-list)
