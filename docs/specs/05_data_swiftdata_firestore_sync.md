# Fase 05 — SwiftData local, Firestore remoto y sincronización

## Objetivo

Implementar por colección el recorrido Domain ↔ Mapper ↔ SwiftData/Firestore, manteniendo SwiftData como fuente de verdad local y una sincronización bidireccional, offline-first e idempotente.

## Prerrequisito de decisión

ADR 0002 y ADR 0006 aceptados. No se implementa `FeatureSyncPolicy` mientras la regla concreta de su colección no esté aprobada.

## Diseño obligatorio

Para cada feature sincronizada:

```text
Domain:      Entity + Repository + UseCases
Data local:  FeatureModel + LocalDataSource + FeaturePersistenceActor
Data remote: FeatureDTO + RemoteDataSource (Firebase encapsulado)
Data bridge: FeatureMapper + DefaultFeatureRepository
Sync:        FeatureSyncEngine + FeatureSyncPolicy
```

- Los DTO son `Codable`; no se usan diccionarios `Any` ni `JSONSerialization`.
- Los modelos SwiftData y sus metadatos de sync permanecen en Data.
- Las escrituras guardan primero en SwiftData, crean una operación pendiente persistida y actualizan la UI local.
- La descarga se decodifica, reconcilia y guarda localmente antes de avanzar el cursor.
- Cada operación tiene ID idempotente; los upserts usan el ID estable de entidad.
- Conflictos usan revisión remota o criterio monotónico acordado. `updatedAt` del reloj local no decide por sí solo.
- Los borrados usan tombstones con política de retención; una descarga atrasada no puede resucitarlos.
- Los reintentos recuperables usan backoff con jitter y sobreviven al reinicio.
- Los modelos SwiftData vivos y `ModelContext` no cruzan actores.
- Para una mutación ligada al contexto principal, Data ofrece un adaptador `@MainActor` que recibe un valor de Domain y el `ModelContext`; App inyecta su método como closure en Presentation. El adaptador conserva mapping, operaciones del contexto, guardado local-first y cola de sync sin hacer que Domain conozca SwiftData o Data importe Presentation.
- Cuando ese adaptador y `DefaultFeatureRepository` ofrezcan la misma escritura desde callers distintos, ambos usan una única primitiva interna de Data; mapping, aceptación local, operación pendiente e idempotencia no se implementan dos veces.
- Al introducir el primer esquema SwiftData real, se crea el `PreviewModifier` compartido con un `ModelContainer` en memoria y sembrado determinista, idempotente y navegable; no se anticipa con un modelo ceremonial.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 05.1 | Implementar DTO `Codable` y mapper de la primera colección. | Fixture válido, inválido y round trip. | Errores de decodificación preservan contexto. |
| 05.2 | Implementar `FeatureModel`, `LocalDataSource`, la primitiva interna de escritura y el `PreviewModifier` compartido para el primer esquema real. | CRUD con `ModelContainer` en memoria. | Guardado explícito, restricciones únicas y fixtures de preview navegables. |
| 05.3 | Implementar `FeaturePersistenceActor` con `@ModelActor`. | Acceso concurrente y verificación desde otro contexto. | Cruce solo mediante IDs/snapshots Sendable. |
| 05.4 | Implementar contrato y fake de `RemoteDataSource`. | Respuestas, permisos, offline y payload inválido. | Tests sin Firebase real. |
| 05.5 | Implementar adaptador Firestore en `Data`. | Contract tests compartidos con el fake cuando proceda. | Ningún tipo Firebase sale de Data. |
| 05.6 | Implementar `DefaultFeatureRepository` local-first y el adaptador contextual `@MainActor` sobre la misma primitiva Data. | Escritura local aunque falle remoto; paridad entre ambas rutas y una sola operación pendiente. | Presentation no consulta Firestore ni duplica persistencia. |
| 05.7 | Implementar primer `FeatureSyncEngine` y la política ya aceptada de su colección. | Push/pull repetido y orden alterado. | Mismo estado final, sin duplicados. |
| 05.8 | Añadir tombstones, cursor y cola persistente. | Borrado concurrente, reinicio y fallo intermedio. | No resurrección y reanudación segura. |
| 05.9 | Añadir backoff, clasificación de errores y cancelación. | Reloj inyectado, errores recuperables/definitivos. | Sin espera real ni tareas huérfanas. |
| 05.10 | Replicar la vertical en Clients, Products, Services y Sales. | Tests de política específicos por colección. | No abstraer hasta existir duplicación real. |
| 05.11 | Probar migraciones de esquema publicadas. | Datos representativos en contenedor aislado. | Sin pérdida de datos locales o metadatos. |

La numeración remota de tickets y facturas se implementa en la fase 13 bajo ADR propio; no forma parte de un SyncEngine genérico.

## Resultado de fase

UI local-first, Firebase encapsulado, persistencia aislada y sincronización repetible y recuperable con políticas documentadas.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
