# ADR 0007 — Firebase temporal y salida a Vapor

## Estado

Propuesto

## Contexto

Firestore/Auth/Storage son necesarios para el backend actual, aunque la política general evita dependencias externas y está prevista una migración futura a Vapor.

## Opciones consideradas

1. No usar SDK externo y construir backend ahora: retrasa el MVP.
2. Acoplar Firebase a toda la app: rápido, migración costosa.
3. Aprobar Firebase como excepción encapsulada detrás de contratos.

## Decisión

Firebase Auth, Firestore y Storage son la única excepción externa aprobada. Solo se añaden módulos usados. Sus tipos permanecen en Data/Infrastructure; Domain y Presentation dependen de contratos propios. La semántica de repositorio no reproduce innecesariamente la API Firebase.

## Consecuencias

- MVP aprovecha backend actual sin contaminar capas superiores.
- Se mantiene código adaptador y tests contractuales adicionales.

## Testing y validación

- Fakes deterministas y contract tests de implementaciones.
- Revisión de imports Firebase fuera de Data.

## Migración o reversibilidad

Crear adaptadores Vapor que implementen los mismos contratos, validar con contract tests, migrar datos/sync y retirar productos Firebase sin cambiar Domain o Presentation.
