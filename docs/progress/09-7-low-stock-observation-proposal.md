# Propuesta 09.7 — Observación local de bajo stock

2026-09-29. [PLU-58](https://linear.app/plusprojects/issue/PLU-58), Jesus Franco, hija de PLU-49.
Preparación solicitada por el propietario después de entregar09.6. Rama `codex/phase-09-7-low-stock-observation`
desde `e16163b`, main/origin/main idénticos y limpios. Propuesta aprobada por el propietario con «adelante implementa09.7». Autoriza implementación; entregaGit separada.

## Autoridad y baseline

Constitución, spec09 fila09.7, política Swift, ADR0002/0006/0011/0029/0030. Perfil maintenance; no nueva arquitectura.
La spec exige ObserveLowStockUseCase, casos bajo/igual/sobre mínimo y resultado local determinista. Las decisiones
siguientes, aprobadas por el propietario, concretan el mínimo explícito sin pantallas de avisos ni configuración persistida.

09.6 entregada: commit824fad8, PR22/7f83cdf, PLU-56 Done funcional, rama eliminada y cierre documental e16163b publicado.
Baseline reutilizable:958 declaraciones/1.315 resultados PASS, Develop/Production,16previews, smoke y PRE/POST PASS.
Código/configuración idénticos al árbol validado; aviso AppIntents y seis enlaces históricos08.3 conocidos.
Xcode MCP estable conectado a workspace-EYu6rxi7hg; scheme Develop, SDK27.0, target26, Swift6, strict complete,
aislamiento predeterminado nonisolated, warnings Swift/Clang como errores. Sin cambios de toolchain ni dependencias.

## Comportamiento propuesto

- Observar un ProductID y un mínimo entero explícito no negativo, fijo durante cada observación. No inventar un mínimo
  predeterminado ni añadir un campo a Product. El caller futuro decidirá el umbral; cambiarlo exige nueva observación.
- Emitir LowStockState inmutable con productID, cantidad vigente y mínimo; isLow se deriva de `quantity < minimum`.
  Igualdad y superior no son bajo stock. Mínimo cero válido; stock cero y negativo siguen siendo cantidades válidas.
  Comparación directa sin restas: no se desborda con Int.min/Int.max. La identidad del estado es el ProductID, sin UUID nuevo.
- StockMinimum garantiza Int>=0 al construir y decodificar; mínimo inválido falla antes de suscribir o consultar Data.
  Domain mantiene Codable/Equatable donde tienen significado, sin persistir esos valores por añadir conformidades.
- Snapshot inicial y actualizaciones de cantidades locales aceptadas. Se emite todo estado distinto, tanto bajo como
  recuperado, no solo alertas positivas: el consumidor debe poder retirar un aviso. Suprimir duplicados consecutivos.
- La observación mantiene el estado más reciente, no entrega garantizada de cada transición intermedia. Buffers acotados
  newest1 pueden agrupar invalidaciones; nunca son un historial. Una señal tardía recarga la fuente actual.
- Producto existente sin movimientos: cantidad0. Activos, inactivos y metadatos en conflicto siguen siendo legibles,
  coherente con quantity(for:) actual. Ausente/tombstone termina con StockError.productNotFound, nunca inventa cero.
  Corrupción/overflow/almacenamiento conservan los errores Domain existentes; no se filtran tipos del proveedor.
- Error terminal requiere nueva observación explícita; cancelar el consumidor termina tareas y suscripción. No polling,
  timers, reintento automático, NotificationCenter, persistencia adicional ni tráfico de red.

## Fronteras y archivos previstos

Dentro de Features/Products, sin nuevas capas genéricas:

- Domain/ValueObjects: StockMinimum validado y LowStockState con comparación derivada, sin duplicar campos calculados.
- Domain/UseCases/ObserveLowStockUseCase: transforma el flujo de cantidades del repositorio en estado de bajo stock.
  Contrato AsyncThrowingStream de valores con cancelación propagada; ningún ModelContext/modelo persistente cruza aquí.
- Domain/Repositories/StockRepository: añade observeQuantity(for:) junto a la lectura quantity(for:) existente.
  StockError añade únicamente invalidMinimum si hace falta representar el rechazo neutral del valor nuevo.
- Data/Repositories/DefaultStockRepository: por invalidación llama StockPersistenceActor.quantity(for:), ya probado,
  y emite cantidades distintas. Registrar la suscripción antes de la carga inicial evita el hueco lectura/suscripción.
  Mantener el patrón local de AsyncThrowingStream, tarea productora cancelada en onTermination y buffer newest1.
  Toda tarea puente tiene propietario, fin y propagación de cancelación; no Task.detached ni opt-outs unsafe.
- Reutilizar ProductObservationSignal: ya representa invalidación de la feature Products y no lleva payloads. La misma
  instancia notifica productos y movimientos; también cubre metadatos/tombstones que invalidan quantity(for:).
  No renombrar la infraestructura ni crear una segunda señal que requiera combinar dos suscripciones.
- DefaultStockRepository.append y StockContextualPersistenceAdapter.append publican tras aceptación correcta.
  Mantener intacta la primitiva síncrona StockLocalDataSource.append y su rollback. Una aceptación durable conserva éxito
  ante cancelación tardía y publica sin una nueva comprobación cancelable que oculte el commit. Retry exacto puede
  invalidar de nuevo, pero la observación suprime el saldo idéntico; un error no publica éxito.
- AppRuntime, AppDependencies y AppDependencies+StockAdjustment pasan explícitamente la MISMA señal al repositorio
  y adaptador contextual, también en local/preview interactiva/demo. Seed previo a exponer el contenedor conserva8/2.
  Snapshot read-only conserva su rechazo de escritura. No conectar todavía este caso de uso a una pantalla ni sesión.
- Tests: nuevo ObserveLowStockUseCaseTests, observación real de DefaultStockRepository y regresión contextual/composición;
  adaptar solo las conformidades y constructores de StockRepository afectados. DocC para estos contratos semánticos.

La señal solo cubre writes conocidos de la composición. No acredita observación entre procesos o contextos ajenos,
CAS entre writers, stock sync ni transporte live. La coherencia de lecturas entre actor y contexto UI se debe probar con
la persistencia real en memoria; si falla, investigar el contexto lector sin introducir reload/reset destructivo.
Los observadores de catálogo recibirán también invalidaciones de stock: deben recargar sin modificar formularios abiertos.

## Alternativas y riesgos

1. Consulta puntual: menor infraestructura, pero no cumple la intención reactiva de Observe ni retira estado tras un ajuste.
2. Mínimo persistido por producto, catálogo agregado y UI configurable: más producto visible, pero exige schema/DTO/sync,
   migración y superficie accesible no definidos por09.7. Se reserva para una ampliación expresa de alcance.
3. Observación por producto y mínimo explícito: incremento acotado elegido; deja origen/configuración futura del mínimo
   pendiente. No simula un aviso visible en la demo ni declara esa UI completada.

No reutilizar StockWarningPolicy: proyecta consumo de venta/saldo negativo, no stock bajo mínimo. Tampoco se modifica
la regla de venta insuficiente ni fase12. Compartir invalidación añade recargas al catálogo; preferible a duplicar buses
sin necesidad actual, con tests de borrador/colección y coalescencia. Reversibilidad: sin nuevos datos o migraciones.
No se propone ADR nuevo porque se conserva la arquitectura, persistencia y contratos de aceptación existentes.

## TDD y aceptación

Implementación solo después de aprobación del alcance; tests-de-verdad antes de crear tests. Swift Testing, RED semántico
compilable → GREEN, Xcode MCP; no XCTest/XCUITest, sleeps ni dependencias nuevas. Pruebas deterministas con handshakes.

- Bajo/igual/sobre, mínimo0, negativo y extremos; mínimo negativo rechazado al construir/decodificar.
- Estado inicial0 en producto existente; flujo entrada/salida cruza umbral en ambos sentidos; valores repetidos suprimidos.
- Retry idéntico no duplica saldo ni emisión semántica; cambio de nombre/inactivo no cambia cantidad. Ausente/tombstone
  finaliza con productNotFound; conflicto de metadatos conserva lectura y no amplía permisos de escritura.
- Error de commit no produce saldo nuevo; fallo de lectura termina sin fabricar estado. Cancelación previa/tardía conserva
  la aceptación09.5/09.6 y libera el observador cuando el consumidor se cancela.
- Dos observadores y productos distintos no se contaminan; invalidaciones retrasadas/agrupadas recargan estado actual,
  sin exigir observar cada transición intermedia. Registrar observador antes de lectura inicial y coordinar writes en test.
- Escribir mediante actor/repository y mediante adapter UI actualiza la MISMA observación real. Prueba de composición debe
  detectar señales distintas; product/tombstone cambiado desde otro contexto conocido se refleja en actor lector caliente.
- Regresión de lista y borrador padre con invalidación de stock. Integridad/idempotencia/rollback existentes conservadas.

Validación posterior: foco Domain/Data y regresiónProducts/composición; suite global por cambio de contrato compartido,
Develop/Production, revisión de estilo y POST independiente. UI/previews/accesibilidad nuevas N/A si solo cambia este
alcance sin Views/recursos; comprobar que no se amplíe al implementar. PLU-54/57 conservan evidencia integral pendiente.
No crear deuda accesible vacía. Completar09.7 no cierra integralmente fase09 ni inicia automáticamente fase10.

## Fuentes primarias y código contrastado

Consultadas29/09/2026 mediante Cupertino, documentación Apple completa; API compatible con target26:

- [AsyncThrowingStream.onTermination](https://developer.apple.com/documentation/swift/asyncthrowingstream/continuation/ontermination):
  cancelación de iteración invoca terminación; usarla para cancelar la tarea puente y limpiar la suscripción.
- [bufferingNewest](https://developer.apple.com/documentation/swift/asyncthrowingstream/continuation/bufferingpolicy/bufferingnewest(_:)):
  conserva los valores más recientes y descarta antiguos al completar buffer; por ello no se promete historial de eventos.
- Código real: StockRepository, DefaultStockRepository, StockLocalDataSource.quantity, ProductObservationSignal,
  DefaultProductRepository.observeProducts y AppDependencies+StockAdjustment. StockWarningPolicy pertenece a ventas.

## PRE y puerta siguiente

PRE independiente ios-standards-reviewer: PASS, sin hallazgos P0–P3; perfil maintenance. Reviewer y root verifican
607/607 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas. Manifiesto
`/tmp/franalonso-09-7-pre1.json`, SHA256 `e7c0e2da5183d81f4e5232939571e59b600a530d8e4cb3c191a980d489653f6e`.
Fuentes Apple contrastadas independientemente. Este registro se añade después de la verificación de huella.
El propietario aprueba la implementación tras PRE PASS. Implementación y TDD completados localmente; entregaGit09.7
no autorizada. [Evidencia posterior](phase-09.md):1.346 resultados PASS, lector caliente entre contextos, señal única,
cancelación y borrador conservado. StockMinimum.ValidationError mantiene el rechazo neutral sin ampliar StockError
con un caso que la UI actual no puede recibir. POST independiente PASS tras corregir cuatro closures solo de formato;
la fase09 conserva su cierre integral. El propietario autoriza después commit/push, PR/merge y cierre de issue/rama;
entrega completada en PR23/merge b40e1f6, PLU-58 Done y ramas eliminadas. Registro y siguiente puerta en phase-09.md.
