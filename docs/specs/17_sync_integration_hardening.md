# Fase 17 — Integración y endurecimiento

## Objetivo

Integrar el MVP, probar recuperación e idempotencia entre features y endurecer errores, seguridad, concurrencia y rendimiento antes de distribuir.

## Diseño

- `AppSyncEngine` orquesta SyncEngines de colección sin asumir orden de entrega ni exactamente una ejecución.
- Las dependencias entre colecciones se expresan mediante IDs y políticas, no pasando modelos SwiftData vivos.
- Login, foreground y recuperación de conectividad pueden solicitar sync; la coalescencia evita trabajos duplicados.
- La concurrencia se limita para no saturar Firestore, memoria o batería y respeta cancelación.
- Los errores de infraestructura se traducen a errores de dominio/presentación; los mensajes visibles son localizados.
- Las reglas Firestore/Storage y el aislamiento de datos se prueban con emulador o entorno controlado fuera de la suite unitaria, sin convertirlo en dependencia de cada test.
- El ciclo de vida global prueba que logout, bloqueo, background e interrupciones detienen la sesión de voz y que ningún dato conversacional entra en sync, almacenamiento o telemetría.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 17.1 | Implementar `AppSyncEngine`. | Colecciones parciales, repetición, orden distinto y cancelación. | Convergencia sin duplicados. |
| 17.2 | Integrar solicitud de sync tras login. | Múltiples eventos de sesión. | Coalescencia y UI local disponible. |
| 17.3 | Integrar foreground/conectividad. | Rafaga de eventos, offline y recuperación. | No bloquea MainActor. |
| 17.4 | Unificar traducción de errores por capas. | Infraestructura → Domain → estado localizado. | Sin tipos Firebase en Presentation. |
| 17.5 | Completar estados carga/vacío/error/reintento. | ViewModels/Stores afectados. | Previews y revisión manual. |
| 17.6 | Implementar observación y resolución explícita de conflictos. | Elegir local/remoto, revisión remota cambiante, reintento y cancelación. | `SyncConflictsViewModel` y Screen resuelven sin sobrescritura ciega. |
| 17.7 | Auditar strict concurrency y rendimiento. | Tests paralelos y cancelación. | Sin warnings, carreras ni escapes de concurrencia estricta no aprobados. |
| 17.8 | Verificar reglas Firestore y Storage. | Usuario no autenticado, dueño incorrecto y payload inválido. | Acceso mínimo necesario. |
| 17.9 | Crear seed de desarrollo idempotente. | Dos ejecuciones producen el mismo dataset. | Sin datos reales o sensibles. |
| 17.10 | Ejecutar recorrido manual integral. | No es test UI automatizado. | Voz→borrador revisable y cliente → venta → stock → documento → informe por los flujos normales. |
| 17.11 | Probar reinicio en fronteras críticas. | Cola sync, conflictos, consentimiento, venta, stock, numeración y sesión de voz. | Recuperación documentada. |

## Resultado de fase

MVP integrado, recuperable, seguro y sin deuda conocida de concurrencia o sincronización.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
