# ADR 0004 — Serialización JSON exclusivamente tipada

## Estado

Propuesto

## Contexto

Diccionarios dinámicos y `JSONSerialization` trasladan errores de esquema a runtime, dificultan `Sendable` y filtran formas remotas a otras capas.

## Opciones consideradas

1. Diccionarios `[String: Any]`: flexibles, inseguros y no Sendable.
2. DTO `Codable` con estrategias explícitas: más modelado, contratos verificables.

## Decisión

DTO, fixtures y payloads usan `Codable`, `JSONEncoder` y `JSONDecoder`. Fechas, claves y compatibilidad se configuran explícitamente. Data traduce DTO a entidades mediante mappers. `JSONSerialization` queda prohibido.

## Consecuencias

- Errores de contrato detectables y tests de fixtures claros.
- Los cambios de esquema exigen actualizar DTO/mappers y compatibilidad.

## Testing y validación

- Fixtures válidos, campos ausentes, valores corruptos y migración de versiones.
- Búsqueda automática de `JSONSerialization` en el diff.
