# ADR 0002 — SwiftData como SoT local y Firestore como SoT remota

## Estado

Propuesto

## Contexto

La aplicación debe funcionar con conectividad inestable y compartir datos entre dispositivos. Consultar Firestore desde UI rompe el modo offline y crea dos estados observables competidores.

## Opciones consideradas

1. Firestore directo desde Presentation: simple inicialmente, sin SoT local coherente.
2. SwiftData sin sincronización: offline sólido, sin estado compartido.
3. Escritura local-first y sincronización bidireccional: mayor complejidad, pero experiencia offline y convergencia.

## Decisión

SwiftData es la única fuente observada por UI. Firestore es la autoridad remota compartida. Toda escritura se guarda localmente, se marca pendiente y se sincroniza. Todo cambio remoto se reconcilia y materializa localmente antes de aparecer en UI. Firebase queda en Data.

## Consecuencias

### Positivas

- UI reactiva y disponible offline.
- Backend sustituible mediante contratos.
- Reintentos no dependen del ciclo de vida de una pantalla.

### Negativas y riesgos

- Se necesitan cola persistente, cursores, conflictos, tombstones y migraciones.
- La convergencia puede ser eventual; la UI debe representar pendiente/error.

## Testing y validación

- ModelContainer en memoria; data sources remotos fake.
- Push/pull repetido, reinicio, orden alterado, offline y recuperación.

## Relaciones

- ADR 0006 define conflictos y borrados.
- ADR 0007 limita Firebase y prepara Vapor.
