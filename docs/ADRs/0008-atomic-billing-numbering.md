# ADR 0008 — Numeración remota atómica e idempotente

## Estado

Aceptado

## Contexto

Ticket y factura necesitan series independientes. Separar “obtener siguiente número” y “confirmarlo” deja una ventana de caída que puede duplicar consumo o perder relación con el documento.

## Opciones consideradas

1. Número local provisional convertido en definitivo: conflicto entre dispositivos.
2. `getNext` y `confirm`: dos pasos con frontera insegura.
3. Transacción remota que asigna número y crea documento usando request ID idempotente.

## Decisión

Firestore procesa un `documentRequestID` estable en una transacción: si ya existe, devuelve el mismo documento; si no, incrementa la serie y crea el documento remoto de forma atómica. Ticket y factura tienen contadores separados. Sin red, la petición queda pendiente localmente y no recibe número definitivo.

## Consecuencias

- No hay duplicados por reintento y una caída posterior puede recuperar el documento remoto.
- Crear documento numerado exige conectividad; la UI debe representar pendiente y reintento.
- La validez fiscal y retención deben revisarse con la asesoría responsable antes de producción.

## Testing y validación

- Solicitudes concurrentes, request repetido, caída tras commit, series independientes, permiso denegado y recuperación local.

## Relaciones

- Complementa ADR 0002 y 0006.
