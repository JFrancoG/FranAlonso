# ADR 0021 — Autorización de un principal para el almacén local

## Estado

Aceptado

## Contexto

Firebase puede restaurar una sesión conocida localmente, pero esa identidad no basta para
mostrar datos SwiftData. El almacén actual no está particionado por principal y una cuenta
distinta no debe poder reclamar ni leer filas creadas por otra identidad.

ADR 0019 mantiene el stream de Firebase como autoridad de sesión y ADR 0020 reserva la
biometría para desbloquear sesiones ya existentes. Email y contraseña deben seguir permitiendo
recuperar el acceso cuando la biometría falle o deje de estar disponible, sin convertir el
retorno aislado de `signIn` en autoridad de raíz.

El propietario confirmó que la aplicación nueva no contiene datos SwiftData reales previos:
los datos existentes viven únicamente en Firebase bajo el path de la aplicación legacy. El
esquema local publicado contiene 28 modelos y no incluye metadatos de propiedad.

## Drivers

- No mostrar ninguna fila local a un principal Firebase distinto del autorizado.
- Conservar el stream de sesión como autoridad para elegir la raíz protegida.
- Mantener email y contraseña como recuperación completa cuando la biometría no funciona.
- Guardar solo el UID opaco necesario para el vínculo, nunca credenciales ni tokens.
- Fallar cerrado ante datos locales previos, Keychain no fiable o lectura indeterminada.
- Evitar una migración SwiftData cuando el estado inicial confirmado no la necesita.

## Opciones consideradas

### UID en Keychain y comprobación de almacén vacío

El vínculo usa un item Keychain no synchronizable y accesible con el dispositivo desbloqueado.
Si el item falta, Data comprueba las 28 tablas con límite uno y solo un almacén completamente
vacío puede reclamarse mediante una inserción atómica.

Esta opción protege todas las filas existentes sin cambiar el esquema. Si el Keychain faltase
y las 28 tablas estuvieran vacías, el almacén podría vincularse de nuevo porque no habría datos
anteriores que exponer.

### Modelo SwiftData de propiedad

Un modelo persistente mantendría la propiedad incluso después de vaciar todas las tablas, pero
exige una nueva versión y migración del primer esquema publicado. No aporta protección adicional
para el requisito actual, que es impedir acceso cruzado a datos existentes.

### `UserDefaults`

No ofrece almacenamiento seguro para el UID y puede divergir del almacén. Se rechaza como
fuente de autorización.

### Confiar solo en Firebase Rules

Las Rules protegen el backend, no las filas SwiftData ya presentes en el dispositivo. No
resuelven la frontera local.

## Decisión

Domain define una capacidad `LocalPrincipalAuthorizer` y un único
`AuthorizeLocalPrincipalUseCase`. La operación recibe un `AuthenticationSession` y solo
completa cuando su UID está vinculado de forma segura al almacén actual. Sus errores cerrados
distinguen principal diferente, almacén no reclamable, almacenamiento seguro no disponible,
almacén ilegible y fallo inesperado.

Data implementa `KeychainLocalPrincipalDataSource`. El item usa
`kSecClassGenericPassword`, `service` y `account` constantes,
`kSecAttrAccessibleWhenUnlocked` y `kSecAttrSynchronizable = false`. Su valor contiene solo el
UID UTF-8 opaco. Logout no actualiza ni elimina el item.

La autorización sigue este orden:

1. Un binding legible y coincidente autoriza; uno distinto deniega.
2. Un error Keychain distinto de item ausente falla cerrado.
3. Si falta el binding, un actor SwiftData comprueba con límite uno los 28 modelos del esquema.
4. Cualquier fila, error o estado indeterminado deniega el claim.
5. Con todas las tablas vacías, `SecItemAdd` reclama el almacén.
6. Una carrera `errSecDuplicateItem` vuelve a leer y solo autoriza si el UID coincide.

Las operaciones bloqueantes de Keychain se ejecutan en una función `@concurrent`. La inspección
SwiftData pertenece a un `@ModelActor`; no cruza modelos vivos ni `ModelContext` entre actores.

La raíz exige siempre un principal publicado por el stream más una prueba local válida. Para
una sesión restaurada, la prueba es biometría correcta. Para un login reciente, el resultado de
`SignInUseCase` arma una prueba efímera para su UID, pero no abre el shell: el acceso continúa
solo cuando el stream publica exactamente ese mismo UID. Un `nil`, UID diferente, reemplazo,
cancelación o resultado obsoleto invalida la prueba.

`SessionViewModel` registra esa invalidez dentro del propio consumo ordenado del stream mediante
una revisión monótona de acceso local. Cada `nil` y cada reemplazo por un UID diferente avanzan
la revisión; una repetición del mismo UID no lo hace. La prueba efímera, una autorización en curso
y un acceso ya concedido capturan la revisión y dejan de ser válidos si esta cambia, aunque
SwiftUI agrupe actualizaciones de presentación.

Por tanto, si la biometría se estropea o deja de estar disponible, la persona puede cerrar la
sesión y autenticarse de nuevo con email y contraseña. Ese login confirmado por el stream
permite autorizar el almacén sin biometría.

## Consecuencias

### Positivas

- Ningún principal distinto puede leer filas locales existentes.
- Email y contraseña conservan una recuperación real sin almacenar credenciales.
- El flujo respeta la autoridad del stream y la finalidad local de la biometría.
- El esquema SwiftData 1.0.0 no cambia.
- Keychain, SwiftData, Firebase y LocalAuthentication permanecen detrás de límites sustituibles.

### Negativas y riesgos

- La primera reclamación consulta los 28 modelos y debe mantenerse alineada con el esquema.
- Un almacén completamente vacío y sin binding puede vincularse de nuevo; no se promete conservar
  identidad histórica cuando ya no queda ningún dato.
- Una restauración no cifrada o un fallo de Keychain puede bloquear un almacén con datos hasta
  disponer de una futura recuperación explícita.
- La decisión no demuestra token freshness, revocación ni autorización Firestore.

## Testing y validación

- RED/GREEN con Swift Testing y operaciones Keychain deterministas, nunca el Keychain live.
- Binding coincidente, principal distinto, item ausente, errores de lectura y dato inválido.
- Claim con almacén vacío, rechazo con cualquier familia de datos y error de inspección.
- Carrera add/duplicate/read, idempotencia, cancelación y resultado obsoleto.
- Login reciente coincidente frente a `nil` o UID diferente; sesión restaurada con biometría.
- Composición única después de Firebase, build y suite completa mediante Xcode MCP.
- Previews sin servicios live y auditorías independientes de iOS y accesibilidad.

## Migración o reversibilidad

No se modifica el esquema porque el propietario confirmó que no existen datos locales previos
sin binding. Si el producto exige que un almacén conserve su identidad incluso después de borrar
todas sus filas, se añadirá otro ADR, un modelo de propiedad y una migración posterior a 1.0.0.

Sustituir Firebase o Keychain conserva los contratos Domain. Una recuperación administrativa de
un binding perdido requiere una decisión separada que pruebe propiedad sin exponer datos.

## Relaciones

- Complementa ADR 0002, ADR 0019 y ADR 0020.
- Implementa la decisión de seguridad y composición de la subfase 06.7.
- No autoriza Rules, App Check, SyncEngine live, token freshness ni fase 07.

## Referencias

- [Keychain Services](https://developer.apple.com/documentation/security/keychain-services/)
- [`SecItemAdd`](https://developer.apple.com/documentation/security/secitemadd(_:_:))
- [`SecItemCopyMatching`](https://developer.apple.com/documentation/security/secitemcopymatching(_:_:))
- [`errSecDuplicateItem`](https://developer.apple.com/documentation/security/errsecduplicateitem)
- [`kSecAttrAccessibleWhenUnlocked`](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlocked)
- [Firebase Auth reference](https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Classes/Auth)
