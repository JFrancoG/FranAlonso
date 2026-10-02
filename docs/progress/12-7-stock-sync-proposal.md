# 12.7 — Propuesta de sincronización Stock

Autorización humana: «abre issue y rama e implementa12.7». [PLU-94](https://linear.app/plusprojects/issue/PLU-94/127-synchronize-immutable-stock-movements)
In Progress/Jesus Franco, hija PLU-85. Rama `codex/plu-94-stock-movement-sync` desde main/origin55691ba limpio.
No existe issue12.7 anterior; no duplicación. Entrega Git12.7 autorizada después por «Commit, push y entrega»; sin live/12.8/cierre integral.

## Alcance aprobado

[ADR 0033 aceptado](../ADRs/0033-immutable-stock-movement-sync.md) por el propietario el 02/10/2026:
«si, aprobado». PRE independiente PASS antes de código. La aprobación autoriza exactamente implementación y
validación 12.7; entrega Git, live, 12.8 y cierre integral mantienen sus gates separados.

Áreas implementadas: Products/Data/DTOs, DataSources, Sync y cuatro modelos; StockPersistenceActor comparte el writer
real con composición runtime. StockMovementModel solo añade reconocimiento pendiente sin cambiar su forma.
AppRuntime/bootstrap compone un motor inactivo y FirestoreEnvironment añade la ruta Stock. App/Persistence añade
StockSyncSchema/etapa3→4 y adopta el esquema después de la matriz. Tests de transporte/política/persistencia/engine,
retry/durabilidad/migración/composición; fixtures de esquema únicamente por impacto. Domain, Views, Store, VM,
UI/localización y reglas de pago12.6 permanecen fuera del cambio. No se deriva stock al descargar Sale.

## Baseline y validación

Git55691ba/origin/main sincronizados, sin trabajo ajeno; código12.6 integrado con paridad literal excepto el LF final
read-only ya registrado. Última evidencia válida:15/15 nuevas de pago y681ejecuciones nativas de regresión,
builds finales Develop20:57:22/Production20:56:54 PASS por Xcode MCP estable. Suites seleccionadas incluyen Stock y
Sales/Sync; no son evidencia12.7. Native bundles cerrados en phase-12.md; aviso AppIntents metadata conocido.
Xcode MCP conectado al workspace-PfnUYLlMzY y proyecto correcto; Develop activo. Build settings reales verificados:
iOS27/SDK27, Swift6/complete/nonisolated y warnings Swift/Clang como errores. Gobernanza conserva seis enlaces08.3.

TDD y criterios en ADR0033: primero RED real de sincronización ausente, luego política/transporte y reconciliación,
retry/restart, migración raw1/2/3 y composición sin tráfico. Validar por impacto, full logs y native resultados;
no ejecutar xcodebuild. PRE antes de código y POST técnico al terminar, estilo antes de validación final.
UI/previews/accesibilidad12.7 N/A mientras se conserve el ámbito. PLU-89/91 Backlog/Jesus y trigger previo intactos.

## Riesgos, alternativas y límites

Feed por contador replica el patrón probado pero Stock puede escribir más: contención se mide en gate live propio.
Full pull es alternativa/fallback explícito; no basar cursor en hora local/listener ni subir un total Product.
Conservar conflictos sin editar eventos; negativos válidos, overflow técnico bloqueante; Product desaparecido
conserva ledger sin recrear Product/Sale. No prometer transacción remota de todas las colecciones ni CAS multiwriter.
Cuatro tablas nuevas exigen migración antes de distribución, sin reset; todas las rutas de apertura reales deben usar
el plan. Sin dependencias nuevas, unsafe, telemetría sensible, scheduler o activación live.

PRE stock_sync_12_7_pre: PASS sin hallazgos.870archivos read-only, digest inicial/final/root idéntico:
`21b9b8f0c0dd1dcd5188166ce0c26d3d56f82f82ee533398529ff6e86a2f47a9`.
Baseline nativa y fuentes primarias inspeccionadas; no se ejecutaron nuevos builds/tests ni se cambiaron archivos.
Compartir StockPersistenceActor no serializa contextos de pago/UI independientes: no CAS multiwriter ni motor live.
Validar esa frontera antes de activación. La implementación conserva los límites del ADR.

## Estado actual

Implementada en la rama local, sin commit/push. Transporte server-only inmutable con create+contador,
replay/conflicto sin escritura; aceptación local indivisible con cursor/retry; motor single-flight y backoff durable.
Schema 4 adoptado después de matriz raw 1/2/3→4, preservación y dos aperturas. Composición inactiva con writer Stock
compartido y Products signal; los eventos de pago 12.6 convergen sin recalcular consumos ni alterar pendientes Sale.
49 ejecuciones nuevas y regresión completa 2.319 PASS por Xcode MCP; 1.465 declaraciones nativas, todos los
parámetros nuevos comprobados. Builds finales Develop/Production PASS, cero diagnósticos Swift/Clang. POST detectó un P2 en fixtures, corregido con Codable; focal PASS sin hallazgos.
Lista para entrega autorizada por separado; PLU-94 sigue In Progress.
UI/previews/accesibilidad 12.7 N/A: bootstrap solo añade construcción inactiva; deuda PLU-89/91 permanece abierta.


## Entrega autorizada

«Commit, push y entrega» autoriza completar la ruta establecida de PR, integración y cierre operativo 12.7.
26 Swift coinciden exactamente con el manifest final validado; ninguna adición ejecutable posterior. Se reutilizan
2.319 ejecuciones/49 nuevas, builds Develop/Production y PRE/POST/focal por paridad. Sin cambios locales ajenos.
Preparación de commit y PR; el resultado Git definitivo se registrará tras integración. Live y12.8 separados.
