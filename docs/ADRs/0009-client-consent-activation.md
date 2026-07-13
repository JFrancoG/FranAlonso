# ADR 0009 — Consentimiento obligatorio y activación offline-first

## Estado

Propuesto

## Contexto

El consentimiento firmado es obligatorio para activar un cliente, pero exigir subida remota antes de guardar perdería el formulario ante falta de red y contradice la persistencia local-first.

## Opciones consideradas

1. Bloquear cualquier guardado sin upload: simple, pierde trabajo offline.
2. Activar cliente local antes del upload: experiencia fluida, viola el requisito obligatorio.
3. Persistir borrador local y activar solo tras upload idempotente.

## Decisión

Modelar `draft`, `consentPendingUpload` y `active`. El formulario y firma se guardan localmente como borrador. Un upload con ID estable persiste el consentimiento; después una operación idempotente activa el cliente y sincroniza la referencia. Solo `active` puede usarse en operaciones de negocio. La foto opcional sigue un flujo separado y no bloqueante.

## Consecuencias

- No se pierde trabajo offline y nunca existe cliente operativo sin consentimiento.
- La UI debe explicar y permitir reintentar estados pendientes.
- Se requiere limpieza segura de borradores abandonados.

## Testing y validación

- Offline, upload repetido, caída entre upload/activación, cancelación, borrador reabierto y foto fallida.

## Relaciones

- Complementa ADR 0002 y ADR 0007.
