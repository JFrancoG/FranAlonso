# ADR 0013 — Reintentos durables y cancelables de sincronización

## Estado

Aceptado

## Contexto

El motor de Clients ya ejecuta una pasada explícita de pull y push, conserva operaciones
idempotentes y puede reanudarse desde un cursor durable. Un fallo remoto recuperable todavía
termina la pasada inmediatamente y no conserva cuándo debe reintentarse. Reintentar en un
`Task` interno perdería el estado al finalizar el proceso, duplicaría propietarios del ciclo de
vida y dejaría trabajo potencialmente huérfano.

Firestore distingue fallos transitorios de errores que requieren corregir permisos,
configuración o datos. Sus operaciones Swift asíncronas no exponen un handle de cancelación
para una lectura o transacción ya iniciada, por lo que la cancelación solo puede ser cooperativa
en los puntos controlados por la aplicación y al recuperar el callback del SDK.

## Drivers

- Sobrevivir a reinicios sin convertir el ciclo de vida de una pantalla en scheduler.
- Repetir únicamente operaciones idempotentes y conservar su mismo `operationID`.
- Evitar esperas reales, reloj de pared y aleatoriedad en los tests.
- Mantener una única pasada explícita, sin trigger automático ni tareas no estructuradas.
- Hacer que la cancelación prevalezca antes de cualquier reconciliación o nueva escritura local.

## Opciones consideradas

### Confiar únicamente en los reintentos internos de Firestore

Reduce código propio, pero esos intentos son opacos, finitos y no sobreviven al resultado final
ni al reinicio del proceso. Tampoco gobiernan la próxima pasada explícita de sincronización.

### Mantener el backoff solo en memoria

Es simple, pero un reinicio elimina el presupuesto y puede provocar una ráfaga inmediata contra
el proveedor. Además, no satisface el requisito durable de 05.9.

### Crear y almacenar un `Task` por operación

Permitiría esperar en segundo plano, pero añade propietarios de ciclo de vida, coalescencia y
cancelación que no necesita una pasada explícita. Se rechaza para evitar tareas huérfanas y no
anticipar el trigger de sincronización.

### Persistir el siguiente intento por unidad y esperar dentro del caller

Conserva el estado entre procesos, mantiene la tarea estructurada bajo el caller de
`synchronize()` y permite sustituir reloj, espera y jitter en tests.

## Decisión

Clients persiste como máximo una fila `ClientSyncRetryModel` por unidad de reintento:
`.pull` o `.operation(operationID)`. La fila conserva el paso de backoff `1...6`, el instante
`notBefore` y la última categoría recuperable. No guarda payload de negocio.

Los errores `UNAVAILABLE`, `DEADLINE_EXCEEDED` y `ABORTED` son recuperables. Cada fallo
incrementa y satura el paso, toma una única muestra de jitter en `[1, 2]` y persiste antes de
esperar:

```text
base(step) = min(2^(step - 1), 30 segundos)
delay      = min(base(step) * jitter, 60 segundos)
```

Cada invocación permite como máximo tres intentos externos para `.pull` y, separadamente,
tres para cada `.operation(operationID)`. Los reintentos internos del SDK no cuentan porque
no son observables por el motor. El tercer fallo durable guarda el siguiente `notBefore` y
devuelve el error sin dormir. Una pasada posterior limita la espera pendiente al rango
`0...60` segundos para contener saltos del reloj de pared.

`PERMISSION_DENIED`, `RESOURCE_EXHAUSTED`, errores opacos, errores de decodificación,
política o persistencia son definitivos para esa invocación. Un error definitivo elimina un
backoff transitorio anterior, pero conserva cursor y operación pendientes para que una futura
pasada explícita pueda probar de nuevo después de corregir la causa. `RESOURCE_EXHAUSTED` se
clasifica conservadoramente como definitivo porque el mismo código puede representar cuota
agotada o capacidad transitoria.

`ClientSyncTiming` compone closures `@Sendable` para fecha actual, espera y jitter. Producción
usa `Date.now` para el deadline durable y `Task.sleep(for:clock:)` con reloj continuo para la
espera relativa cancelable. Tests inyectan tiempo manual y jitter determinista.

`ClientSyncEngine` mantiene un flag aislado por actor antes del primer `await`. Una segunda
llamada solapada falla con `alreadySynchronizing`; no se almacena ni se coalesce ningún `Task`.
El flag se libera con `defer` en éxito, error o cancelación.

La cancelación se comprueba antes y justo después de cada llamada remota, también dentro del
`catch` antes de clasificar o persistir un fallo. Las esperas propias lanzan
`CancellationError`. Una operación Firestore ya iniciada puede tardar hasta que el SDK invoque
su callback e incluso haber confirmado remotamente; en ese caso el estado local previo queda
intacto y la siguiente pasada converge mediante el mismo `operationID`.

La eliminación de una fila de retry se guarda en la misma frontera local que el batch y cursor,
el acknowledgement o el conflicto correspondiente. Un fallo de reconciliación conserva tanto
la operación como el retry anterior para una recuperación idempotente.

## Consecuencias

### Positivas

- Los reintentos recuperables sobreviven al reinicio y no bloquean hilos.
- Cada operación conserva identidad y presupuesto independientes.
- Reloj, jitter, espera y cancelación son deterministas en tests.
- El motor sigue sin trigger automático ni tareas con ciclo de vida propio.

### Negativas y riesgos

- La cancelación no puede interrumpir inmediatamente I/O Firestore que ya esté en vuelo.
- Cada intento externo de una transacción puede incluir hasta cinco intentos internos opacos
  del SDK.
- Los saltos del reloj de pared se mitigan mediante el límite de 60 segundos, pero no se
  eliminan.
- La clasificación conservadora de `RESOURCE_EXHAUSTED` puede requerir una nueva política si
  aparece evidencia operacional de capacidad transitoria.

## Testing y validación

- Clasificación parametrizada de errores recuperables y definitivos.
- Fórmula, jitter, saturación y estado persistido inválido.
- Pull y push reintentados sin cambiar `operationID`, con límite por unidad.
- Reinicio con `notBefore` pendiente y limpieza atómica en éxito.
- Acknowledgement y conflicto descubiertos por pull eliminan también el retry de la operación.
- Error definitivo sin espera y eliminación del backoff anterior.
- Llamadas solapadas, cancelación durante tiempo/espera y callback Firestore no cancelable.
- Migración file-backed desde el esquema exacto de seis modelos de 05.8.
- Suite completa, build y diagnósticos mediante Xcode MCP, sin red real.

## Migración o reversibilidad

La nueva entidad comienza vacía al abrir un store 05.8. El adaptador Vapor puede conservar el
mismo contrato de categorías y deadlines sin conocer Firestore. Cambiar categorías, fórmula,
presupuesto o propietario del trigger requiere un ADR posterior; retirar el mecanismo solo
exige dejar de producir filas y eliminar el modelo en una migración publicada posterior.

## Relaciones

- Complementa ADR 0002, ADR 0006, ADR 0007 y ADR 0012.
- Implementa la subfase 05.9.

## Referencias

- [Swift structured concurrency](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)
- [Swift actors and reentrancy](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md)
- [Swift clocks, instants and durations](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md)
- [Firestore error codes](https://firebase.google.com/docs/firestore/use-rest-api#Error_codes)
- [Firebase iOS Firestore errors 12.16.0](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/Firestore/Source/Public/FirebaseFirestore/FIRFirestoreErrors.h)
- [Google Cloud retry strategy](https://cloud.google.com/storage/docs/retry-strategy)
