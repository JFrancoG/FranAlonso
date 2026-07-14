# ADR 0005 — Warnings como errores

## Estado

Aceptado

## Contexto

Warnings de concurrencia, disponibilidad o APIs deprecadas suelen anticipar defectos. Posponer su corrección acumula deuda y hace que señales nuevas se pierdan entre ruido existente.

## Opciones consideradas

1. Permitir warnings y limpiarlos por release.
2. Fallar build ante cualquier warning desde bootstrap.

## Decisión

Activar warnings como errores para Swift y Clang en app, extensiones y tests. No desactivar categorías globalmente para ocultar incidencias locales.

## Consecuencias

- Cada subfase mantiene una línea base limpia.
- Actualizaciones de toolchain pueden requerir correcciones antes de continuar.

## Testing y validación

- Confirmación inicial con warning controlado.
- Todos los targets afectados compilan sin warnings mediante Xcode MCP.
