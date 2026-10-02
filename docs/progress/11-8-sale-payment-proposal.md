# 11.8 — Propuesta de aceptación local del pago (PLU-82)

## Autoridad y alcance

Spec11.8, constitución, ADR0002/0006/0016/0018/0021/0032 y política Swift vigente.
Perfil maintenance, Swift6 estricto, Swift Testing; Xcode MCP exclusivamente.
Autorizados issue, rama e implementación. No entrega Git ni live.

Implementar RegisterSalePaymentUseCase, contrato de repositorio, aceptación local en Data,
paridad InMemory y composición App. No nueva pantalla/ViewModel ni transiciones de servicio,
stock, documento o cierre. WorkdaySalesPolicy ya conserva awaitingDocument en awaitingClosure.
No cambios de esquema, DTO, reglas o motores.

## Propuesta

Caller conserva PaymentID y paidAt explícitos; el caso de uso exige PaymentMethod opcional
no nil (cash/card), comprueba cancelación y delega una operación de repositorio única.
No genera identidad/fecha ni ejecuta get-await-save.

El repositorio recibe el snapshot esperado y el comando estable. Una política Domain pura
valida Sale.registerPayment y compara el contenido comercial (id, cliente, creación, líneas,
descuento global). Para aceptar el primer pago, snapshot local y esperado deben coincidir.
Para reintentar un pago ya aceptado, exige términos comerciales y metadata de pago exactos;
devuelve el snapshot actual preservando documento/reversión posteriores, sin volver a persistir.
Metadata diferente conserva SaleError.conflictingPayment; snapshot comercial obsoleto produce
SalePaymentError.staleSale. Draft/inProgress conservan invalidSaleTransition.

SaleLocalDataSource verifica contexto limpio, conflicto, descarte y existencia, sin suspensión
entre lectura/comparación/mutación. Sale y pending causal se guardan juntos por
persistPendingUpsert existente, rollback ante fallo. No-op no reescribe blobs ni crea pending.
No se afirma CAS entre contextos independientes. Actor y adaptador contextual comparten esta
frontera. Publicación tras aceptación; cancelación posterior no transforma un pago guardado en
fracaso. Errores neutrales: methodRequired, notFound, staleSale, conflict, deleted,
persistenceUnavailable. Sin payload en logs.

## Alternativas

Get-await-save: rechazado por ventana de obsolescencia y replay que sobrescribe progreso.
Generar PaymentID/fecha dentro del caso: rechazado por duplicación en recuperación.
Nuevo modelo Payment/cola: innecesario; SaleStatus y pending existente conservan metadata exacta.
UI de cobro: fuera del paso normativo UseCase; requiere definición del flujo de servicios.

## TDD y evidencia

RED compilado mediante stubs cerrados; GREEN con Swift Testing: falta de método, cash/card,
transición inválida, replay exacto y divergente, snapshot obsoleto, cancelación, fallo/rollback,
cola causal, reapertura file-backed y composición/observación. Pago sin documento permanece en
Jornada. Paridad InMemory, Default/actor y contextual; terminales no se degradan en replay.
Build Develop-for-testing/Production, suite y diagnósticos nativos cerrados; PRE/POST read-only
con cuatro pruebas digest idénticas. Previews/AT N/A: ningún cambio Presentation/UI.

## Fuentes primarias y contratos

- [Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation())
- [ModelContext.save](https://developer.apple.com/documentation/swiftdata/modelcontext/save())
- [ModelContext.rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback())
- [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor)
- Sale.registerPayment, SaleLocalDataSource.persistPendingUpsert y ADR0016 establecen
  timestamp exacto, snapshot completo e inmutabilidad comercial tras pago.
