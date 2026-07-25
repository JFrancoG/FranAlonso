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
| 05.6 | Implementar `DefaultFeatureRepository` local-first y el adaptador contextual `@MainActor` sobre la misma primitiva Data. | Escritura local sin esperar ni depender de convergencia remota; paridad entre ambas rutas y una sola operación pendiente. | Presentation no consulta Firestore ni duplica persistencia. |
| 05.7 | Implementar primer `FeatureSyncEngine`, componer el adaptador remoto live tras el bootstrap del proveedor y aplicar la política ya aceptada de su colección. | Push/pull repetido y orden alterado. | Mismo estado final, sin duplicados. |
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

## Evidencia 05.3

- `ClientPersistenceActor` es el primer `@ModelActor` de una colección real. El macro le asigna su propio `ModelContext`; el actor no expone el contexto ni modelos persistentes y solo cruza su frontera con `Client`, `[Client]` y `ClientID`, valores Domain desconectados cuya `Sendable` se infiere de sus miembros internos.
- La propuesta se contrastó con la documentación instalada y publicada de Apple para [`ModelActor`](https://developer.apple.com/documentation/swiftdata/modelactor), su [`modelContext`](https://developer.apple.com/documentation/swiftdata/modelactor/modelcontext) y el soporte de [concurrencia de SwiftData](https://developer.apple.com/documentation/swiftdata/concurrencysupport), además de [SE-0302](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) para la transferencia segura de valores. La alternativa de conservar contextos en un servicio ordinario se rechazó porque no expresa ni aplica ese aislamiento; crear una segunda implementación CRUD dentro del actor se rechazó porque duplicaría la primitiva Data ya validada.
- El actor reutiliza `ClientLocalDataSource` para `fetchAll`, `upsert` y `delete`, por lo que no duplica mapping, identidad estable, guardado explícito ni idempotencia. No cambia la composición del Repository temporal, no añade Firebase, sincronización, metadatos, migraciones ni UI.
- La revisión independiente previa detectó que la propuesta debía cubrir el borrado del actor y documentar su contrato DocC. Ambos puntos se incorporaron antes de la aprobación exacta del propietario y antes de escribir código ejecutable.
- RED añadió primero los tres tests del actor y el build focal falló únicamente con `Cannot find 'ClientPersistenceActor' in scope` en sus tres usos. GREEN pasa 3/3 pruebas del actor y 7/7 pruebas del DataSource local afectado; el plan completo pasa 154/154 desde 141 declaraciones y el build de Xcode MCP termina en 9.659 segundos sin warnings ni issues de Navigator.
- Los refrescos aislados de los dos archivos nuevos devuelven el error no bloqueante `SourceEditorCallableDiagnosticError error 2`, mientras el compilador real y las suites prueban que ambos se compilan y ejecutan. Los chequeos estáticos no encuentran escapes inseguros de concurrencia, APIs legacy/prohibidas ni problemas de espacios. La auditoría final de arquitectura/data/concurrencia detectó un P3 por dos baselines obsoletos en `Progress.md`; tras actualizarlos a Xcode `17F113` y 141 declaraciones/154 resultados, la re-auditoría completa terminó sin hallazgos. SwiftUI/accesibilidad es `N/A` porque no cambia ninguna View, recurso visual, preview, localización o superficie accesible. La subfase 05.3 queda completa y la siguiente puerta es la propuesta fuenteada 05.4 para el contrato y fake de `RemoteDataSource`.

## Evidencia 05.4

- `ClientRemoteDataSource: Sendable` define únicamente la lectura server-backed de `[ClientDTO]` y el upsert remotamente confirmado de un `ClientDTO`. `ClientRemoteDataSourceError` expresa permisos, indisponibilidad y fallos opacos sin exponer tipos del proveedor; un payload inválido conserva su `DecodingError` y `codingPath` nativos.
- La lectura exige no caer silenciosamente a caché, pero no se presenta como autoridad de revisión o conflictos: Firebase documenta que una lectura de servidor aún puede incorporar escrituras pendientes por compensación de latencia. El éxito de `upsert` significa acuse remoto; no se inventa un fallo offline inmediato cuando el SDK puede mantener la operación pendiente. Cursor, revisiones, tombstones, recuperación, backoff y cancelación siguen en 05.7–05.9.
- La propuesta se contrastó con Firebase 12.16.0 resuelto y su documentación oficial sobre [persistencia offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline), [mapeo Swift `Codable`](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping), [fuentes de lectura](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/Firestore/Source/Public/FirebaseFirestore/FIRFirestoreSource.h), [acuse de escritura](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/Firestore/Source/Public/FirebaseFirestore/FIRDocumentReference.h) y [errores Firestore](https://github.com/firebase/firebase-ios-sdk/blob/12.16.0/Firestore/Source/Public/FirebaseFirestore/FIRFirestoreErrors.h). La revisión previa encontró dos P2 de semántica, ambos se corrigieron antes de que la re-revisión terminara sin hallazgos y antes de la aprobación exacta del propietario.
- RED añadió primero cinco tests y falló porque `ClientRemoteDataSource` y `ClientRemoteDataSourceError` no existían. GREEN pasa 5/5 pruebas focales mediante un actor fake privado y determinista, 9/9 pruebas afectadas de conversión DTO y el plan completo 159/159 desde 146 declaraciones, sin Firebase real.
- El build Xcode MCP termina en 8.249 segundos con 0 warnings o issues de Navigator; ambos archivos nuevos reportan 0 diagnósticos tras el build. Los chequeos estáticos no encuentran imports de proveedor/UI/persistencia, `JSONSerialization`, escapes inseguros de concurrencia, APIs legacy/prohibidas ni problemas de espacios. La auditoría final independiente de arquitectura/data/concurrencia revisó el diff completo sin hallazgos; SwiftUI/accesibilidad es `N/A`. La subfase 05.4 queda completa y la siguiente puerta es la propuesta fuenteada 05.5 para el adaptador Firestore real.

## Evidencia 05.5

- `FirestoreClientRemoteDataSource` implementa el contrato neutral dentro de Clients/Data y es dueño de la ruta específica de Clients. `FirestoreEnvironment` vive en `Shared/Data/Firebase`, contiene solo los entornos aprobados `develop` y `production` y exige seleccionarlos explícitamente; el adaptador compone desde ellos las rutas `develop/collections/clients` y `production/collections/clients`. No existe entorno por defecto y la composición live en App queda diferida a 05.7, junto al primer `ClientSyncEngine` y después del bootstrap de Firebase.
- `fetchAll()` usa `getDocuments(source: .server)`, decodifica con `data(as: ClientDTO.self)` y conserva el ID de cada documento hasta comprobar que coincide exactamente con el `id` del payload. Una discrepancia produce `DecodingError.dataCorrupted` con `codingPath == ["id"]`; un payload malformado conserva su error y ruta nativos.
- `upsert(_:)` usa el ID estable como nombre de documento, sobrescribe el documento completo mediante `setData(from:completion:)` y espera el acuse remoto a través de una única continuación comprobada en la frontera callback del SDK. Permisos e indisponibilidad se traducen al error neutral; la cancelación nativa o de Firestore conserva `CancellationError`; el resto se vuelve `unexpected`.
- La propuesta inicial perdió el ID de ruta al convertir inmediatamente cada snapshot a DTO; la revisión previa lo señaló y la corrección pasó una segunda revisión sin hallazgos. Tras la aclaración y aprobación del propietario sobre los namespaces nuevos, una revisión fresca del delta confirmó ambas rutas, la ausencia de selección implícita de producción y el límite sin composición live, también sin hallazgos.
- RED añadió primero diez declaraciones Swift Testing y falló por los símbolos del entorno y adaptador ausentes. GREEN pasa 11/11 resultados focales parametrizados, 24/24 resultados seleccionados de adaptador/contrato/DTO y el plan completo 170/170 desde 156 declaraciones. Su build Xcode MCP original terminó en 8.827 segundos con 0 warnings de log o Navigator y ambos archivos entonces nuevos tuvieron 0 diagnósticos. Tras la corrección estructural, pasan las 10/10 declaraciones seleccionadas del adaptador y el plan completo 170/170 —incluidos ambos argumentos de entorno—, y el build termina en 8.406 segundos con 0 warnings de log o Navigator. El entorno compartido nuevo y el archivo de tests tienen 0 diagnósticos; el refresco aislado del adaptador conserva dos diagnósticos contradictorios de símbolo ausente pese a compilar y ejecutar correctamente. Los chequeos estáticos de imports, serialización, concurrencia insegura, APIs prohibidas y espacios están limpios.
- No se leyó ni modificó el cliente creado manualmente en `develop`. Antes del primer acceso controlado se comprobarán su ID documental y forma Codable, y no se ejecutará un overwrite hasta comprender cualquier campo no modelado. Reglas, smoke test live, composición de Repository, sincronización, reintentos, cancelación operativa, revisiones, cursores y tombstones siguen fuera de 05.5. La auditoría final independiente original revisó el diff completo, repitió la suite 170/170 y terminó sin hallazgos. La corrección estructural solicitada por el owner para separar el entorno Firebase compartido de la ruta específica de Clients superó sin hallazgos tanto su revisión previa como la re-auditoría final independiente; esta última clasifica los dos diagnósticos aislados contradictorios como estado obsoleto de Source Editor porque build, pertenencia al target, tests y Navigator están limpios. SwiftUI/accesibilidad es `N/A`. La subfase 05.5 queda completa localmente y la siguiente puerta es la propuesta fuenteada 05.6.

La numeración remota de tickets y facturas se implementa en la fase 13 bajo ADR propio; no forma parte de un SyncEngine genérico.

## Resultado de fase

UI local-first, Firebase encapsulado, persistencia aislada y sincronización repetible y recuperable con políticas documentadas.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
