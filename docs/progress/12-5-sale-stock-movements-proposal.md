# Propuesta exacta 12.5 — Creación idempotente de movimientos

02/10/2026, PLU-92/Jesus Franco, hijaPLU-85. Autorización: «abre issue y rama e implementa12.5».
Base main/origin-main limpia `eb82ccb61e69d7c4e6e54b5b71a3c07dd6ad58e6`; rama
`codex/plu-92-sale-stock-movements`. Sin commit/push/PR/merge/Done/live autorizados.

## Autoridad y estado real

Spec12/fila12.5 y diseño: identidad estable venta/línea, un movimiento por línea vinculada, replay sin descuentos extra.
ADR0002/0006: ledger append-only, payload distinto con misma identidad es conflicto. ADR0011/0018: Domain/Data separados,
esquema publicado preservado. ADR0003/0005 y políticaSwift: TDD/SwiftTesting, warnings como errores.
12.4/PR45 está entregada;299/299 y builds Develop/Production recientes. StockMovementModel ya guarda id/productID,
versión/blob/pending; StockLocalDataSource.append valida identidad y payload antes de elegibilidad del producto,
acepta stock negativo, rollback por fallo de save y no suspende. Actor compartido confina el contexto.
Xcode MCP estable usable, workspace-PfnUYLlMzY, Develop/iPadPro13(M5)Simulator27.2, SDK/target27.0,
Swift6/nonisolated/strict complete y warnings-as-errors. Ningún ejecutable tocado durante preparación.

## Cambio propuesto

1. Sales/Domain: política pura `SaleStockMovementPolicy` sobre una venta con pago registrado y paymentID esperado.
   Rechaza venta impagada o paymentID distinto antes de cualquier I/O. Extrae paidAt original incluso en closed/voided;
   no crea compensaciones. Recorre el snapshot comercial en orden, omite servicios profesionales sin producto,
   crea por línea vinculada delta `-quantity` (cantidad siempre positiva en SaleLine), fecha original y razón canónica
   interna `sale-payment`. Producto repetido conserva un evento por línea; no agrupa ni consulta catálogo actual.
2. Products/Domain: origen Codable `.sale(saleID:lineID:paymentID:)` con IDs tipados. Identity factory en Sales/Domain
   genera UUIDv8 determinista: SHA256 de UTF8 `FranAlonso.sale-stock.v1\0<sale UUID lowercase>\0<line UUID lowercase>`,
   primeros16bytes, byte6 version8 y byte8 variant10. PaymentID queda en payload, nunca en clave: otro pago no crea
   otro descuento para la misma línea. No usar Hasher, UUID aleatorio, reloj nuevo, XOR ni ID del producto.
   SHA256 viene del framework Apple CryptoKit; no dependencia externa ni inseguridad de concurrencia.
3. Products/Data: conservar forma SwiftData/VersionedSchema y bytes manuales v1; nuevos orígenes sale usan
   payloadVersion2. Lectura admite v1 solo manual y v2 solo sale; desconocido/incoherente falla cerrado.
   Un payload sale válido mantiene invariantes de StockMovement y se deduplica por igualdad completa en la primitiva existente.
4. Sales/Domain: `CreateSaleStockMovementsUseCase` recibe repository Stock y venta pagada/paymentID;
   prepara todo antes de escribir y delega cada evento a append existente, en orden. Retorna los eventos aceptados.
   Contrato explícito: aceptación durable por línea, progreso parcial ante fallo/cancelación, retry con mismo snapshot
   y metadata completa únicamente pendientes, sin modificar originales. Última aceptación conserva éxito aun si
   llega cancelación después del último commit; cancelación anterior o entre líneas conserva solo lo ya aceptado.
   Concurrencia segura al compartir el mismo StockPersistenceActor; no garantiza CAS entre writers/contextos independientes.

No se conecta esta operación al flujo actual de pago: hacerlo con dos commits independientes violaría el diseño de fase.
12.6 compondrá política y primitiva local en una frontera atómica pago+stock. La capacidad12.5 es ejecutable y se
verifica con repositorio/SwiftData reales, sin escribir venta/colaSales. No añade App consumer ceremonial ni otro Store.

## Alternativas y riesgos

- UUID aleatorio o derivado del paymentID: duplica descuentos al reconstruir o cambiar comando; descartado.
- XOR/mezcla simple venta/línea: colisiones construibles; descartado. SHA1/UUIDv5 innecesario frente SHA256/UUIDv8.
- Acumular por producto: pierde un evento por línea y trazabilidad; descartado.
- Nuevo batch repository/actor/transacción ahora: adelanta12.6 y aumenta superficie sin necesidad de idempotencia12.5;
  se reutiliza append existente y se declara progreso parcial, sin prometer atomicidad del conjunto.
- Conectar pago→movimientos secuencialmente: deja pago aceptado sin inventario ante fallo; descartado.
- Reusar payloadVersion1 para sale: pierde el significado publicado manual-only; versión2 sin migración de forma.
- Otra clave futura requiere versión/origen separado, nunca recalcular identidades publicadas. Colisión improbable
  falla identityConflict por payload, no sobrescribe. Registro desconectado no acredita integración visual del descuento.

## TDD y validación

RED primero: policy/usecase APIs ausentes o comportamiento aún no implementado, registrar distinción compilación/ejecución.
Oráculos independientes: UUIDs literales calculadas offline con Python hashlib/uuid a partir del contrato anterior;
deltas/cantidades/conteos literales de la spec, no expected calculado por policy bajo prueba.

- Mismo pago repetido, varios productos y producto repetido: un movimiento por línea, profesionales omitidos,
  deltas negativos exactos y fechas/origen. Orden/reordenamiento y metadatos posteriores no cambian IDs/payload original.
- Impagada/paymentID distinto rechazan sin escritura; snapshot de otro pago con misma venta/línea entra en conflicto.
- Payload cambiado con misma identidad conserva originales; identidad entre ventas y líneas no colisiona en vectores.
- Pipeline UseCase→DefaultStockRepository→ModelActor→SwiftData, lecturas por contextos frescos:
  cantidad inicial10 y consumos2+3+4 →1; repetir mantiene1/tresfilas y pending sin colaProduct/Sales adicional.
- Fallo parcial en append y cancelación antes/entre/después: retry recupera pendientes sin duplicar aceptados.
- Concurrencia dos callers/sharedwriter, ausencia/conflicto de producto, overflow heredado; historial no sobrescrito.
- Payload manualv1 literal anterior sigue legible/retry no reescribe; salev2 reabre store file-backed dos veces,
  payload e IDs inmutables, unsupported/incoherent version falla; esquema3.0.0 intacto.
- Baseline/focal StockDomain/Persistence y regresión StockDurability/Contextual/Composition/Observation,
  SalesPayment/Workflow/Stock + recursos según impacto. Develop build-for-testing, Production build y diag por Xcode MCP.
- Estilo manual y recall sobre Swift cambiado antes de validación final; POST técnico independiente read-only con hash.
  UI/previews/auditoría accesible N/A: no cambia View/ViewModel/Store/App consumer ni texto/localización; PLU89/91 intactas.
- validate_localizations, governance (solo6enlacesDesktop08.3 históricos), gitdiffcheck y privacidad.

## Fuentes primarias consultadas

- [Apple SHA256](https://developer.apple.com/documentation/cryptokit/sha256), leído mediante Cupertino:
  hash(data:) puro, digest256, disponible iOS13; compatible con target27. Compilación MCP verifica SDK efectivo.
- [RFC9562 §5.8 y §5.5](https://www.rfc-editor.org/rfc/rfc9562.html#section-5.8): SHA256 name-based pertenece
  UUIDv8, bits de versión/variante fijados; unicidad depende de la implementación, no es garantía absoluta.
- [Apple ModelContext.rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()):
  descarta inserciones/borrados pendientes y restaura cambios no aceptados. Se reutiliza contrato append existente.

PRE independiente requerido antes de código; resolver hallazgos válidos. No nueva decisión arquitectónica:
ID derivado y origen versionado concretan spec12/ADR0006 dentro de fronteras existentes, sin ampliar12.6.


## Estado tras entrega

La propuesta conserva el alcance revisado. Autorización posterior «commit y push, y entrega» completada:
[PR46](https://github.com/JFrancoG/FranAlonso/pull/46), commit523a19a → mergee76486f, árbol revisado idéntico.
PLU-92 Done; fasePLU-85 In Progress. Evidencia y correcciones de formato en [fase12](phase-12.md).
Capacidad local sin consumidor de pago hasta12.6 atómica; accesibilidad N/A12.5, deuda89/91 intacta, sin live.
