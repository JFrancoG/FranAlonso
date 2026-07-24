# Fase 05 — SwiftData local, Firestore remoto y sincronización

## Objetivo

Implementar por colección el recorrido entre Domain y SwiftData/Firestore mediante conversiones propiedad de Data, manteniendo SwiftData como fuente de verdad local y una sincronización bidireccional, offline-first e idempotente.

## Prerrequisito de decisión

ADR 0002 y ADR 0006 aceptados. No se implementa `FeatureSyncPolicy` mientras la regla concreta de su colección no esté aprobada.

## Diseño obligatorio

Para cada feature sincronizada:

```text
Domain:      Entity + Repository + UseCases
Data local:  FeatureModel + LocalDataSource + FeaturePersistenceActor
Data remote: FeatureDTO + RemoteDataSource (Firebase encapsulado)
Data bridge: conversion extensions or a justified FeatureMapper + DefaultFeatureRepository
Sync:        FeatureSyncEngine + FeatureSyncPolicy
```

- Los DTO son `Codable`; no se usan diccionarios `Any` ni `JSONSerialization`.
- Las conversiones concretas, deterministas y sin dependencias viven en extensiones del `FeatureDTO` o `FeatureModel`: `toDomain()` reconstruye el valor Domain y un inicializador sin etiqueta realiza la conversión inversa. Un `FeatureMapper` solo existe si posee dependencias, configuración, versionado, política o estrategias intercambiables; Domain nunca conoce tipos Data.
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
| 05.1 | Implementar DTO `Codable` y la frontera de conversión de la primera colección. | Fixture válido, inválido y round trip. | Errores de decodificación preservan contexto. |
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

## Evidencia 05.1

- Clients es la primera colección porque ya dispone de entidad, estados de ciclo de vida y contrato de Repository en Domain.
- `ClientDTO`, `BillingAddressDTO` y `ClientStatusDTO` forman una frontera `Codable` neutral: no importan Firebase, SwiftData ni metadatos de sincronización.
- Las conversiones de `ClientDTO` conservan la identidad UUID canónica, la dirección opcional y las invariantes de consentimiento de cada estado. Los fallos semánticos siguen siendo errores tipados de Domain y los fallos estructurales conservan el `DecodingError` y su `codingPath` nativos.
- La revisión independiente de la propuesta no encontró hallazgos y el propietario aprobó el alcance exacto antes del código. El RED original falló por los símbolos DTO y conversión ausentes; GREEN pasó 9/9 pruebas nuevas y 6/6 pruebas Domain afectadas. El plan completo pasó 142/142 desde 129 declaraciones, el build Xcode MCP terminó en 8.748 segundos sin avisos y los tres archivos nuevos tuvieron 0 diagnósticos.
- Los chequeos estáticos no encuentran imports de infraestructura/UI, `JSONSerialization`, escapes inseguros de concurrencia, APIs de observación/GCD heredadas ni problemas de espacios. La auditoría final de arquitectura/data/concurrencia revisó el diff completo sin hallazgos; la auditoría SwiftUI/accesibilidad no aplica. La subfase 05.1 queda completa y la siguiente puerta es la propuesta 05.2.

## Evidencia 05.2

- `ClientModel` es el primer esquema SwiftData real: conserva el UUID estable como atributo único, aplana la dirección opcional sin crear una relación ceremonial y mantiene los valores persistidos de estado y consentimiento dentro de Data.
- Las extensiones de `ClientModel` materializan y actualizan modelos persistentes, devuelven únicamente valores Domain desconectados y rechazan estados desconocidos, direcciones parcialmente persistidas y combinaciones de consentimiento inválidas mediante los contratos ya probados en 05.1.
- `ClientLocalDataSource` no almacena ni cruza contextos: cada operación usa el `ModelContext` síncrono del caller. Su `upsert` es la primitiva interna reutilizable, guarda explícitamente, actualiza por identidad estable y respeta la restricción única; el borrado repetido es idempotente.
- `FranAlonsoApp` instala el `ModelContainer` de producción con manejo explícito del fallo de creación, mientras el inicializador de composición permite un contenedor en memoria determinista. El Repository live temporal permanece sin cambios hasta 05.6; no se añaden Firebase, sync, `@ModelActor`, migraciones ni metadatos remotos.
- `AppPreviewModifier` comparte un contenedor en memoria y dependencias sin servicios live. `AppPreviewFixtures` siembra dos Clients deterministas mediante el mismo `upsert`, por lo que el contexto cacheado puede sembrarse repetidamente sin duplicados. Todos los previews existentes usan el trait y `ClientListScreen` y `ClientRow` ya tienen preview en su propio archivo.
- La revisión independiente previa de la propuesta no encontró hallazgos y el propietario aprobó el alcance exacto. RED falló por los símbolos de modelo, DataSource, esquema, composición y preview ausentes. GREEN pasa 10/10 pruebas focalizadas; el plan completo pasa 151/151 desde 138 declaraciones y el build final de Xcode MCP termina en 9.107 segundos con 0 warnings o issues de Navigator.
- Antes de las correcciones de auditoría, los 14 archivos ejecutables afectados reportaron 0 diagnósticos. Tras mover el soporte de previews a `App/Previews` y los inicializadores a una extensión, los cuatro refrescos aislados consultados devolvieron `SourceEditorCallableDiagnosticError error 2`; el build y las suites focalizada y completa sí prueban que esos archivos compilan y ejecutan. Los chequeos estáticos no encuentran escapes de concurrencia, `JSONSerialization`, APIs legacy/prohibidas ni problemas de espacios. `ClientListScreen` se renderiza mediante las variantes descubiertas `Large`, `XXX Large` y `AX 5` sin corte visible; `ContentView` y un PDF representativo también renderizan con el trait compartido. La auditoría SwiftUI/accesibilidad terminó sin hallazgos; la auditoría de arquitectura detectó una P2 de capas y una P3 de construcción, confirmó ambas correcciones y, tras actualizar la evidencia exacta, devolvió un dictamen final sin hallazgos. La subfase 05.2 queda completa y la siguiente puerta es la propuesta 05.3 para el primer `@ModelActor`.

La numeración remota de tickets y facturas se implementa en la fase 13 bajo ADR propio; no forma parte de un SyncEngine genérico.

## Resultado de fase

UI local-first, Firebase encapsulado, persistencia aislada y sincronización repetible y recuperable con políticas documentadas.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
