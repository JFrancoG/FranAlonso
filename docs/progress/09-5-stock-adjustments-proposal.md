# Propuesta 09.5 — Ajustes de stock idempotentes

2026-09-29. [PLU-55](https://linear.app/plusprojects/issue/PLU-55), Jesus Franco, hija de PLU-49.
Comienzo autorizado tras entregar 09.4; propuesta concreta aprobada por el propietario tras PRE2 PASS el29/09/2026.
Rama `codex/phase-09-5-stock-adjustments`, base `b4d2da2`, creada desde main/origin/main idénticos y limpios.
Implementación local autorizada; evidencia y estado actuales en [fase09](phase-09.md). La entrega posterior y el comienzo de 09.6 conservan su puerta separada.

## Autoridad, estado y baseline

Constitución, spec09/índice, política Swift y ADR0002/0006/0011/0014/0018/0021/0029/0030; spec12 delimita el futuro sync.
09.4 entregada mediante PR20/dfd73b0, commit092d72e intacto, PLU-53 Done funcional y ramas eliminadas.
Baseline reutilizable: 1.199/1.199 resultados, Develop/Production, previews, smoke y POST PASS. Aviso AppIntents conocido.
PLU-54 y deuda08 permanecen abiertas. Gobernanza conserva seis enlaces históricos de capturas08.3.

Xcode MCP estable conectado a `workspace-EYu6rxi7hg`, proyecto FranAlonso; Develop/iPhone18Pro Simulator27.0.
Target26, Swift6, strict complete, nonisolated, sin cambios de SDK/target/dependencias. Esta preparación es documental:
build/tests/previews nuevos N/A. En implementación sí se validan los cambios por Xcode MCP.

La inspección confirma que Product solo tiene id/name/status; no existen StockMovement ni su persistencia.
StockWarningPolicy ya permite proyecciones negativas y controla overflow. `Schema.franAlonso` usa ClientDocumentsSchema
v2.0.0 con30 modelos; el plan conserva la baseline v1.0.0 con28 modelos y la etapa1→2.

## Comportamiento propuesto

1. `StockMovementID` estable y `StockMovement` inmutable, Identifiable/Codable/Equatable según la política del repo.
   Payload completo: ProductID, delta entero firmado, motivo normalizado no vacío, fecha explícita finita y origen manual
   con referencia estable. En este flujo la referencia manual utiliza el ID del movimiento; no se inventa otra identidad.
   ID/fecha se suministran desde el caller y se conservan entre intentos; no se regeneran en UseCase/repository.
2. Delta positivo es entrada y negativo salida. Se rechaza delta cero; alcanzar saldo cero es válido. Se permite saldo
   negativo, coherente con inventario físico y avisos no bloqueantes de venta. No se introduce una advertencia UI en09.5.
3. Se permiten ajustes de productos activos e inactivos sin cambiar su estado. Producto ausente/tombstone rechaza un
   movimiento nuevo. Un conflicto pendiente de metadatos bloquea movimientos nuevos; no se modifica ni resuelve Product.
4. Append-only: movimiento ya aceptado con mismo ID y payload canónico es no-op exitoso, incluso tras otros movimientos,
   reinicio, posterior desactivación/tombstone o conflicto de Product. La comprobación de identidad precede a validar el
   estado actual del producto. Mismo ID con cualquier campo distinto devuelve conflicto neutral y preserva el original.
5. El resultado del ajuste es el movimiento aceptado, no un saldo histórico ficticio. La lectura de cantidad actual es
   separada y deriva exclusivamente de movimientos; un producto existente sin movimientos tiene cantidad cero.
   No se guarda un total mutable en Product ni se toca ProductDTO/sync. No hay edición/borrado de movimientos.
6. El balance derivado y el nuevo balance deben caber en Int. Acumulación pura con Int128 y conversión exacta final evita
   overflow intermedio dependiente del orden de fetch; ninguna aproximación Double/Decimal ni aritmética wrapping.
   La capacidad de un array y sus deltas Int acotan la suma dentro de Int128. Probar extremos y permutaciones.
7. Cancelación previa a aceptación no inserta. Una vez confirmado save, cancelación tardía no convierte éxito en error.
   Fallo de lectura/commit se transforma en error Domain neutral y conserva filas originales; nunca se loguea el payload.

## Fronteras y persistencia local

- Domain en Products: StockMovementID, StockMovement y origen manual, errores neutrales, política de cantidad,
  StockRepository y AdjustStockUseCase. El UseCase valida/produce el valor y delega la aceptación; no hace read-then-save.
- Repository expone append idempotente y lecturas concretas de movimiento/cantidad necesarias para verificar el contrato;
  no se crea un framework genérico de ledger, un Store ni un motor de sync.
- Data: StockMovementModel, mapping propio, StockLocalDataSource, StockPersistenceActor y StockRepositoryImpl.
  Un registro inmutable conserva payload/identidad y estado local pendiente de sincronización, conforme a ADR0002.
  Ese registro durable es la unidad pendiente; no hay envío, ack, cursor, retry remoto ni outbox separado en09.5.
- El modelo es aditivo y no tiene relaciones que muten modelos históricos. Persistir el payload mediante Codable y
  versión explícita, con ID/ProductID indexables; no duplicar un total derivado. La futura fase12 podrá añadir metadata.
- Una única instancia de writer `@ModelActor` por composición serializa todos los ajustes de este alcance. La primitiva
  Data comprueba ID/payload, elegibilidad Product, cantidad y commit sin suspensión. Contexto limpio al entrar;
  rollback solo de cambios propios, nunca de ediciones ajenas. Autosave desactivado en el contexto de escritura.
- No confiar en upsert por unicidad para resolver IDs diferentes: comparar payload antes de insertar. Tests de dos
  llamadas concurrentes al mismo writer acreditan una sola fila. No se promete CAS entre containers/procesos/writers
  independientes; cualquier nueva vía de escritura debe respetar la aceptación única antes de habilitarla.
- App compone la capacidad local concreta junto al repositorio Product existente; no activa motores. Si las pruebas de
  composición necesitan una nueva dependencia, se añade solo la operación específica, sin modificar pantallas/fixtures.
  09.6 diseñará su frontera contextual ADR0011: toda ruta adicional delegará en la misma primitiva Data y tendrá su
  validación de concurrencia; no se introduce ahora un adaptador MainActor sin caller ni se elude el contexto de la View.

La especificación12.7 conserva el sync de movimientos y12.5/12.6 su generación y atomicidad con pago. El estado pendiente
es durable pero no acredita convergencia remota. Nuevas escrituras de StockMovement no usan ProductSyncEngine.

## Esquema y migración

`StockMovementsSchema` v3.0.0 añade únicamente StockMovementModel a los30 modelos de ClientDocumentsSchema.
Se conserva exactamente v1 yv2; `PhaseFiveSchemaMigrationPlan` pasa a1→2→3, con etapa2→3 lightweight explícita.
Cambiar AppModelSchema al nuevo esquema solo después de demostrar la matriz de migración. No reset, reseed ni
export/import de stores existentes; un origen desconocido falla cerrado conservando sus datos.

Matriz obligatoria: crear stores raw de formas/versiones exactas v1 yv2, con negocio y metadata representativos;
migrar a3 y verificar identidad, payload bytes/versiones, pending/remote/conflicts/cursors/retries y documentos firmados.
No inventar movimientos históricos: el ledger comienza vacío. Después insertar ajustes, liberar contenedores/actores,
reabrir una segunda vez y verificar datos y deduplicación. Comprobar rechazo no destructivo de forma desconocida.
Los helpers/tests existentes de migración y ProductCRUDDurabilityTests sirven de patrón, sin reescribir sus oráculos.

ADR0021: ampliar `SwiftDataStorePristineDataSource` para consultar también StockMovementModel con límite uno.
Una sola fila de movimiento, incluso sin ProductModel, impide considerar vacío el almacén. Probar el flujo real de
autorización con binding ausente: rechazo `localStoreNotPristine` y cero llamadas a `addBinding`, con doble determinista
y sin Keychain live. Mantener el fallo cerrado ante errores de inspección y todos los controles existentes.

## Archivos/áreas previstos

- Nuevos Domain y Data específicos bajo `FranAlonso/Features/Products/`.
- `App/StockMovementsSchema.swift`, AppModelSchema y PhaseFiveSchemaMigrationPlan; composición concreta si es consumida.
- `Features/Authentication/Data/Adapters/SwiftDataStorePristineDataSource.swift` y sus tests: protección de la nueva tabla
  según ADR0021, sin cambiar las políticas de sesión ni Keychain.
- Nuevos tests de valores/política/UseCase, aceptación local, concurrencia del writer, reapertura y migraciónv1/v2.
- Ajustes mínimos de tests que fijan el esquema actual; conservar expresamente las formas históricas soportadas.
- Spec09 tras aprobación, Progress/phase09 y Linear. No recursos, Views, seeds de demo ni Product/Sale sync.

## TDD y validación

RED semántico sobre APIs provisionales compilables, implementación mínima, GREEN y regresión por impacto.

- Entrada/salida, saldo cero/negativo, delta cero, motivo vacío/normalización, fecha inválida y round-trip Codable.
- ID/fecha/origen estables; retry exacto antes/después de otra operación; colisión de cada campo preserva el original.
- Activo/inactivo, ausente/tombstone/conflicto; retry ya aceptado pese a cambios posteriores del producto.
- Extremos Int, overflow real y sumas reordenadas cuyo resultado es representable.
- Dos solicitudes concurrentes al writer, cancelación previa y tardía, fallo de commit sin fila/estado parcial,
  recuperación posterior, ausencia de cambios en cola Product y rechazo de contexto sucio sin perder cambios ajenos.
- Reapertura durable e idempotencia tras reinicio; migración rawv1/rawv2 y segunda reapertura con preservación completa.
- Almacén con una única fila StockMovement: no pristine, claim rechazado y cero escrituras seguras; no Keychain live.

Xcode MCP: focal con comprobación de todas las variantes; suite completa por cambio de esquema/composición;
Develop/Production, logs completos y aviso AppIntents separado. Estilo Swift y revisión POST independiente.
UI/accesibilidad nuevas N/A por ausencia de Views/textos; no se repite matriz09.4 ni se cierra su deuda.

## Alternativas, riesgos y reversibilidad

Domain más fake dejaría pendiente la garantía durable y movería persistencia/migración a09.6; se descarta para entregar
un ajuste local real. Guardar total en Product contradice ADR0006/0014. Crear ahora sync completo anticiparía12.7.
No hace falta un ADR nuevo: el registro append-only y la evolución aditiva ya están establecidos; los detalles de producto
anteriores requieren aprobación en esta propuesta antes del código. Si la implementación descubre otra frontera, se detiene.

Riesgos principales: doble ajuste, pérdida durante migración, overflow y aceptación contra un estado Product obsoleto.
Mitigación: writer único, primitiva sin suspensión, tests durables/migración, igualdad completa y cálculo exacto.
No se promete atomicidad global con writers Product de otros contextos; se conserva el alcance local de aceptación.
Una vez distribuido v3 no se elimina ni reordena del plan. Revertir la UI futura no elimina el registro ya persistido.

## Fuentes primarias consultadas

Cupertino MCP, documentos Apple completos leídos el29/09/2026; disponibilidad compatible con target26.

- [MigrationStage.lightweight](https://developer.apple.com/documentation/swiftdata/migrationstage/lightweight(fromversion:toversion:))
  permite declarar explícitamente origen/destino. Que la migración concreta sea válida se demostrará con stores raw.
- [ModelContext.rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()) descarta todos los
  cambios pendientes del contexto; por eso se exige contexto limpio y ownership de los cambios de la operación.
- [Int128](https://developer.apple.com/documentation/swift/int128), disponible desde iOS18, permite acumulación entera exacta
  sin elevar target; la conversión a Int y los casos de overflow se verifican en tests.

## PRE y aprobación

PRE1 detectó un P2: faltaba incluir la nueva tabla en la protección del almacén. Se añade ADR0021, el inspector y la
prueba de rechazo del claim con cero addBinding. Root verificó 574/574 archivos idénticos durante PRE1 y PRE2.
Retest focal **PASS, sin hallazgos abiertos**. Manifiesto `/tmp/franalonso-09-5-pre2.json`, SHA-256
`da353ae0ac18647157daefa5f415c32be5305fee20d88337f7b1edf3493f6aab`. Tras la revisión solo se añade este registro.
No se escribe código ejecutable antes de resolver el PRE y obtener
aprobación de esta propuesta concreta, especialmente las políticas de cero/inactivos y la migración persistente.

Aprobación explícita del propietario: «si, aprobado», el29/09/2026 tras PRE2. Autoriza implementar esta propuesta,
no su entrega Git ni09.6. Resultado y validación se registran en [fase09](phase-09.md).
