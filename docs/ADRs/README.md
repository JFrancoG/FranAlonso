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

Los ADR 0001–0009 fueron revisados y aceptados por el propietario del producto el 14 de julio de 2026. El propietario aceptó el ADR 0010 el 23 de julio de 2026 al incorporar Foundation Models al MVP, preparar GPT-5.6 Luna para después y mantener GPT Realtime únicamente como opción. El mismo día aceptó el ADR 0011 al especializar los revisores y aprobar la frontera efímera de `ModelContext`; esta decisión sustituye el ADR 0001. El propietario aceptó los ADR 0012 y 0013 el 26 de julio de 2026 al aprobar respectivamente los alcances exactos de 05.8 y 05.9, y el ADR 0014 el 27 de julio de 2026 al autorizar el checkpoint Products de 05.10 con su motor inactivo y una puerta live separada. El 30 de julio de 2026 aceptó el ADR 0015 al aprobar el checkpoint Services con decimales canónicos, extracción del núcleo puro de retry y motor inactivo. Cualquier cambio posterior en estas decisiones requiere un nuevo ADR que las sustituya.
