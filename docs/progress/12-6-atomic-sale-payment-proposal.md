# 12.6 — Pago local atómico

Autorización inicial: abrir issue/rama e implementar12.6; entrega posterior autorizada «commit, push y entrega».
[PLU-93](https://linear.app/plusprojects/issue/PLU-93/126-make-local-sale-payment-atomic-with-stock-movements),
Jesus Franco, Done, hija PLU-85 In Progress. Rama `codex/plu-93-atomic-sale-payment` desde main `90f1eca9`, eliminada.
Autoridad: constitución, spec12, ADR0002/0003/0005/0006/0011/0016/0018 y política Swift.

## Frontera propuesta y alternativas

`RegisterSalePaymentUseCase` mantiene su contrato Domain de aceptación local vía `SaleRepository.registerPayment`.
La implementación SwiftData y la ruta contextual comparten `SaleLocalDataSource.registerPayment`; esta frontera
invoca las políticas Domain existentes de aceptación y derivación. No se expone ModelContext a Domain.
La capacidad secuencial12.5 permanece disponible para recuperación por línea, sin componerla en el pago.

Un único contexto limpio y confinado prepara los movimientos antes de mutar, prepara el causal upsert y la venta,
inserta todos los movimientos nuevos y guarda una sola vez. Sin suspensión hasta aceptación. Error o cancelación
antes del guardado revierte todo lo propio; el rechazo de contexto sucio ocurre antes de rollback para conservar
edición ajena. Desactivar/restaurar temporalmente autosave durante esta frontera para
hacer explícita la ausencia de guardados implícitos. Cancelación posterior a commit devuelve éxito.
Extraer el staging privado de causal upsert del wrapper que sigue guardando para los demás flujos.
Extraer preparación Stock compartida con append: identidad y payload completo antes de elegibilidad del Product,
validación del historial y saldo conjunto por Product, sin insertar ni guardar. Devuelve modelos nuevos solo dentro
Data/confinamiento. El caller es dueño del commit. No duplicar negocio o representación persistida.

Alternativas descartadas: llamar primero pago y después el UseCase secuencial (produce estado parcial durable);
coordinar dos PersistenceActors (no comparten transacción); protocolo unit-of-work genérico (abstracción sin otra
responsabilidad); cambiar esquema o reservas (no necesarios). `transaction(block:)` guarda al concluir; envolver
helpers que ya guardan no elimina sus commits. Un solo save explícito con staging y rollback permite inyección
acotada del fallo de commit de pago y prueba del estado staged, sin alterar otros saves.

## Idempotencia, recuperación y observación

Pago nuevo deriva las líneas capturadas, con cantidades negativas permitidas. Stock insuficiente sigue siendo aviso,
no condición de rechazo. Product ausente/conflictivo, historial corrupto/overflow o identidad divergente son fallos
de integridad de persistencia y se presentan mediante el error neutral de pago existente.
Exact replay conserva paid/closed/voided, snapshots y bytes sin reescribir venta ni causal queue; agrega únicamente
movimientos faltantes y equivalentes a la política12.5. Puede recuperar un pago histórico anterior12.6 o un prefijo12.5.
Movimientos preexistentes equivalentes no requieren Product actual; divergent identity cancela aceptación completa.
No editar/eliminar originales ni compensar anulaciones (12.8). No barrido/migración automática de pagos históricos.

Repository y contextual adapter publican SaleObservationSignal y ProductObservationSignal tras commit exitoso;
App comparte las señales reales con Product/Stock y Sales en runtime, demo y preview. No publicar en fallo.
InMemorySaleRepository es doble Domain, no ruta productiva SwiftData. No añadir Stores, UI, textos o navegación.
Auditoría UI N/A si el diff conserva ese ámbito; deuda PLU-89/91 intacta y gates accesibles previos conservados.

## TDD y evidencia requerida

Baseline Xcode MCP Develop:25 declaraciones seleccionadas de pago y contextual Stock PASS (resultado parametrizado
nativo se contará aparte). Swift6/complete, target27.0 y warnings Swift/Clang como errores verificados.
RED real con API vigente: pago de venta mixta no crea todavía los tres movimientos esperados.
GREEN: pago y causal successor + tres consumos, dos líneas del mismo Product y servicio profesional sin consumo;
ambas rutas reales, negativos, exact replay sin duplicación, recuperación de prefijo y paid/closed/voided.
Fallo inyectado después de staging antes del save: inspeccionar venta/upsert/todos movimientos staged y lectura
independiente aún original; rollback limpio sin rastros, retry estable, store file-backed reabierto dos veces.
Colisión completa, Product inválido/conflictivo, overflow conjunto, contexto sucio, cancelación antes/después de
aceptación y publicación de señales sobre estado ya durable. Regresión de pagos, Stock, sync, workflow y composición.
Builds Develop y Production por Xcode MCP, logs y xcresult nativo cerrado; estilo manual antes del POST.
Revisión independiente PRE antes de código y POST técnico sobre snapshot congelado, digest íntegro antes/después.

Sin CAS entre writers independientes, transacción remota ni live. No cambia la forma SwiftData3.0.0 ni el payload.

## Fuentes primarias

Documentos completos Cupertino, leídos 2026-10-02:
- [ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext): cambios pendientes en memoria.
- [save](https://developer.apple.com/documentation/swiftdata/modelcontext/save()): persiste cambios pendientes juntos.
- [rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()): descarta cambios no guardados.
- [transaction](https://developer.apple.com/documentation/swiftdata/modelcontext/transaction(block:)): guarda al terminar.
La atomicidad file-backed exige evidencia de fallo/reapertura, además de estas garantías de API.

PRE y POST independientes PASS; dos P3 de estilo corregidos y reauditoría focal PASS.
Implementación y validación final en phase-12.md. Autorización posterior «commit, push y entrega» recibida;
[PR47](https://github.com/JFrancoG/FranAlonso/pull/47) MERGED:1490486 → 8c2152b, tree idéntico al revisado.
Main local/origin sincronizados y ramas eliminadas tras ancestry; PLU-93 Done, fase12 y deuda89/91 abiertas.
Normalización de un LF final en test revisada read-only sin impacto semántico; evidencia ejecutable reutilizada.
Cierre documental en phase-12.md, sin ampliar a12.7/12.8/live ni acreditar accesibilidad integral.
