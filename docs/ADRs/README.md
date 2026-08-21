# Architecture Decision Records

Los ADR se escriben antes de implementar una decisión no trivial y no se reescriben una vez aceptados; cualquier cambio posterior crea otro ADR que lo sustituye.

## Estados

`Propuesto` → `Aceptado` → `Sustituido` o `Obsoleto`. También puede quedar `Rechazado`.

## Índice

| ADR | Decisión | Estado |
|---|---|---|
| [0001](0001-clean-architecture-observable.md) | Clean Architecture, ViewModel y Store opcional | Sustituido por 0011 |
| [0002](0002-swiftdata-local-sot-firestore-remote-sot.md) | SwiftData local y Firestore remoto | Aceptado |
| [0003](0003-swift-testing-only.md) | Swift Testing sin tests UI nativos | Aceptado |
| [0004](0004-no-jsonserialization.md) | Codable como única serialización JSON | Aceptado |
| [0005](0005-warnings-as-errors.md) | Warnings como errores | Aceptado |
| [0006](0006-sync-conflicts-tombstones.md) | Conflictos, revisiones y tombstones | Aceptado |
| [0007](0007-firebase-temporary-vapor-exit.md) | Excepción temporal Firebase y salida a Vapor | Aceptado |
| [0008](0008-atomic-billing-numbering.md) | Numeración atómica e idempotente | Aceptado |
| [0009](0009-client-consent-activation.md) | Consentimiento y activación offline-first | Aceptado |
| [0010](0010-on-device-assistant-provider-strategy.md) | Asistente local en el MVP y proveedor remoto pos-MVP | Aceptado |
| [0011](0011-swiftui-boundaries-specialized-reviews.md) | Límites SwiftUI y revisiones especializadas | Aceptado |
| [0012](0012-firestore-incremental-change-feed.md) | Feed incremental ordenado para Firestore | Aceptado |
| [0013](0013-durable-sync-retry-scheduling.md) | Reintentos durables y cancelables de sincronización | Aceptado |
| [0014](0014-product-sync-feed-and-retry.md) | Feed incremental y reintentos de Product | Aceptado |
| [0015](0015-service-sync-decimal-and-shared-retry-kernel.md) | Sync de Service, decimal exacto y núcleo compartido de retry | Aceptado |
| [0016](0016-sale-sync-exact-timestamps-and-draft-discard.md) | Sync de Sale, timestamps exactos y descarte de borrador | Aceptado |
| [0017](0017-published-swiftdata-schema-migrations.md) | Historial y migraciones de todos los esquemas SwiftData publicados | Sustituido por 0018 |
| [0018](0018-swiftdata-baseline-from-phase-five-ten-c.md) | Baseline SwiftData oficial desde 05.10c | Aceptado |
| [0019](0019-mvp-email-password-authentication.md) | Email y contraseña para la autenticación del MVP | Aceptado |
| [0020](0020-local-biometric-session-unlock.md) | Desbloqueo biométrico local de una sesión existente | Aceptado |
| [0021](0021-local-store-principal-authorization.md) | Autorización de un principal para el almacén local | Aceptado |
| [0022](0022-native-ios-wcag22-accessibility.md) | Objetivo de accesibilidad nativa basado en WCAG 2.2 A/AA | Aceptado |
| [0023](0023-develop-only-non-live-auth-fixture.md) | Fixture de autenticación no-live exclusiva de Develop | Aceptado |
| [0024](0024-develop-only-clients-error-fixture.md) | Error determinista de Clientes exclusivo de Develop | Aceptado |

El propietario aceptó el ADR 0024 el 21 de agosto de 2026 como suplemento de ADR 0023: añade un fallo determinista de
Clientes subordinado a sesión restaurada y hace fail-closed cualquier intención inválida de esa fixture.

Los ADR 0001–0009 fueron revisados y aceptados por el propietario del producto el 14 de julio de 2026. El propietario aceptó el ADR 0010 el 23 de julio de 2026 al incorporar Foundation Models al MVP, preparar GPT-5.6 Luna para después y mantener GPT Realtime únicamente como opción. El mismo día aceptó el ADR 0011 al especializar los revisores y aprobar la frontera efímera de `ModelContext`; esta decisión sustituye el ADR 0001. El propietario aceptó los ADR 0012 y 0013 el 26 de julio de 2026 al aprobar respectivamente los alcances exactos de 05.8 y 05.9, y el ADR 0014 el 27 de julio de 2026 al autorizar el checkpoint Products de 05.10 con su motor inactivo y una puerta live separada. El 30 de julio de 2026 aceptó el ADR 0015 al aprobar el checkpoint Services con decimales canónicos, extracción del núcleo puro de retry y motor inactivo. Ese mismo día aceptó el ADR 0016 al aprobar el checkpoint Sales con fechas exactas, snapshot local, descarte exclusivo de borrador y motor inactivo; ADR 0016 sustituye únicamente la propiedad y el nombre Service-owned del decimal fijados por ADR 0015. También el 30 de julio de 2026 aceptó inicialmente el ADR 0017. Su primer gate demostró que las versiones retrospectivas no existían en disco; tras confirmar que los checkpoints internos anteriores no contenían datos que debieran conservarse, el propietario aceptó el ADR 0018, que sustituye al 0017 y declara 05.10c/`1.0.0` como primera baseline oficial. Ese mismo día aceptó el ADR 0019 al elegir email y contraseña como único acceso del MVP, con cuentas provisionadas externamente, mensajes resistentes a enumeración y cancelación limitada a las garantías reales del proveedor. La configuración live conserva una puerta operativa separada. El 1 de agosto de 2026 aceptó el ADR 0020 al aprobar el desbloqueo biométrico de una sesión local existente mediante un contexto fresco y cancelable, sin passcode, companion device ni almacenamiento de credenciales. El 2 de agosto de 2026 aceptó el ADR 0021 al confirmar que la app nueva no contiene datos SwiftData reales previos, exigir un binding Keychain fail-closed y mantener email/password como recuperación cuando la biometría no funciona. El 11 de agosto de 2026 aceptó el ADR 0022 como objetivo interno de accesibilidad nativa basado en la correspondencia aplicable de WCAG 2.2 A/AA, WCAG2ICT, convenciones Apple y comportamiento real de iOS 26, sin declarar certificación WCAG ni conformidad legal. El 21 de agosto de 2026 aceptó el ADR 0023 para disponer de una fixture determinista exclusiva de `Debug-Develop`, cortada antes de Firebase y sin estado durable ni composición remota. Cualquier cambio posterior en estas decisiones requiere un nuevo ADR que las sustituya.
