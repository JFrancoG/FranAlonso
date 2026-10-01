# 11.3 — Store cohesivo del borrador de venta

2026-10-01. Usuario autoriza issue, rama e implementación local de11.3.
[PLU-74](https://linear.app/plusprojects/issue/PLU-74), hija de PLU-71, Jesus Franco; In Progress al presentar la propuesta.
Rama `codex/plu-74-sale-draft-store`, base main/origin limpia `5fade88`.

## Autoridad y baseline

Constitución, spec11, política Swift y ADR0011/0016/0018/0030/0031.
Perfil maintenance: Domain/Data/Presentation y Store justificado explícitamente en spec11.
Xcode MCP estable `workspace-PfnUYLlMzY`; Develop/plan Develop, destino inicial iPhone11.
Configuración efectiva iOS27, SDK27.0, Swift6/complete/default nonisolated; warnings Swift/Clang como errores.
Fuente547 idéntica a11.2: `0e473095954d921d4329178ee6de2a72124bf1ae2d8a0d2abfaf7770c944b2ee`.
Baseline reutilizado:1.797/1.797 variantes,1.149 declaraciones, Develop-for-testing/Production y PRE/POST PASS.
No acredita el incremento nuevo. GitHub/Linear y Xcode MCP comprobados; sin issue equivalente anterior.

## Alcance y comportamiento

- Store `@Observable @MainActor` en Sales/Presentation, sin efectos en init y con moneda explícita inmutable.
  Orquesta Create/Get/Update/DiscardSaleDraftUseCase11.1 y SaleCalculator11.2.
- Estado único `idle`, `editing(Sale, SaleCalculation)`, `discarded(SaleID)` o `closed`.
  Los getters draft/calculation leen ese mismo estado; no se duplican líneas, cliente o totales.
  Actividad opcional create/load/update/discard y último error semántico separado, sin strings visibles.
- Crear con id/fecha/cliente/líneas proporcionados; recuperar por id; añadir una SaleLine snapshot ya capturada,
  quitar por identidad, establecer cantidad, asociar/quitar cliente y establecer/quitar descuento por línea.
  El selector y captura desde catálogo se integran en11.6; no agrupar automáticamente servicios repetidos.
- Política concreta pura `SaleDraftEditingPolicy` en Domain: usa Sale.replacingDraft y SaleLine.upcoming,
  preservando id/createdAt/orden y todos los términos comerciales retenidos. Una identidad ausente rechaza.
  Qty/discount inválidos y duplicados/progresados conservan los errores Domain existentes; no modifica entidades.
- Todo candidato se construye y calcula ANTES de Create/Update. Un cálculo inválido no deja cambios durables.
  Tras aceptación, publicar conjuntamente Sale y cálculo; conservar estado aceptado ante error/cancelación previa.
  Update recibe el snapshot esperado sin get-await-save; la frontera11.1 detecta obsolescencia visible en su contexto,
  sin prometer CAS entre contextos independientes. Sin optimistic autosave, debounce o escrituras en background.
- Una única operación activa rechaza solapamientos, incluida lectura. Crear con draft cargado rechaza;
  load puede reemplazar el draft tras una lectura/cálculo válidos. Discard repetido es no-op.
  El repositorio continúa siendo fuente local; el Store conserva la proyección de la última aceptación.
- Métodos async estructurados: el caller posee y cancela su Task; Store no crea Tasks ni usa detached/handlers.
  CheckCancellation antes de delegar y después de lectura; nunca después de escritura aceptada.
  Close terminal invalida un token privado por operación, limpia presentación e impide operaciones nuevas.
  Un resultado tardío no reabre el Store. Close no deshace un write aceptado: ese método sigue devolviendo éxito
  durable al caller, pero no repuebla el Store cerrado. Cancelación antes de aceptar preserva el snapshot previo.

## Superficie prevista

Nuevos `Features/Sales/Domain/Policies/SaleDraftEditingPolicy.swift` y
`Features/Sales/Presentation/Stores/SaleDraftStore.swift`; estado/error concretos pueden vivir en el archivo del Store.
API: create(id:clientID:createdAt:lines:), load(id:), addLine(_:), removeLine(id:), setQuantity(_:for:),
setClient(_:), setDiscount(_:for:): async throws -> Sale aceptado, excepto discard(): async throws -> Void.
Close es síncrono y retorna Void. Load: async throws -> Sale?; ausencia válida retorna nil y publica idle sin error.
Lectura inválida/progresada, cálculo fallido o cancelación preservan estado previo; close tardío cerca la lectura
como CancellationError sin último error ni reapertura. Los writes aceptados conservan su éxito después de close.
Tests nuevos de Store y dobles aislados sobre SaleRepository; pipeline con persistencia SwiftData real en memoria.
Documentación: propuesta, Progress compacto, phase11, estado operativo spec11 y CHANGELOG si corresponde a entrega.
Sin composición App nueva: el futuro ViewModel11.4 instancia Store con los UseCases ya expuestos por AppDependencies.

## Alternativas y decisión

Estado copiado en ViewModel: duplicación y anticipa11.4; descartado. Mutaciones locales con save manual posterior:
requiere segunda baseline/dirty/reconciliación y contradice reutilizar aceptación11.1; descartado para este alcance.
Persistir antes de calcular: riesgo de cambio durable no presentable; descartado. Cola/debounce/cancel-restart:
mayor política y riesgo de aceptar writes tardíos; descartado. Operación única y publicación atómica elegidas.
La política Domain evita situar negocio en Presentation; no crea protocolo, infraestructura o dependencia.
Implementa ADR0011 y el contrato explícito spec11; no introduce excepción arquitectónica ni modifica ADR aceptados.
Retirada local de Store/política/tests sin migración ni cambios remotos. Review PRE puede acotar el diseño antes de código.

## TDD y validación

Tests primero contra oráculos literales/contratos, con scaffold compilable mínimo y RED de comportamiento real:
crear/recuperar vacío EUR/USD, añadir/quitar/qty/cliente/descuento con totales literales, identidad/orden/términos
conservados; rechazo qty<=0, duplicados, línea ausente/progresada, moneda/cálculo inválidos antes de escribir.
Fallo local/reintento y snapshot obsoleto conservan contenido/cálculo; create con identidad ocupada rechaza.
Discard elimina materialización y conserva tombstone en pipeline real, repetición no duplica.
Dobles con suspensiones explícitas, sin sleeps: operación busy y no segundo write; cancelación preaceptación,
lectura tardía cancelada, éxito postaceptación y close durante lectura/write sin reabrir presentación.
Tracking Observation de propiedades derivadas mediante withObservationTracking en test MainActor.
Fixtures/repos aislados por test, IDs/fechas deterministas; sin suite serialized, red real ni XCTest.
RED focal real, GREEN afectado y suite completa cuando justifique regresión; árboles xcresult cerrados/variantes revisados.
Builds Develop-for-testing/Production, logs completos, Source-style Audit antes del GREEN, POST nuevo read-only,
gobernanza/diff/enlaces y huellas completas antes/después de auditores.
UI/previews/localización/accesibilidad/dispositivo N/A por ausencia de pantalla nueva o modificada.

## Fuentes primarias examinadas

- [Observation en SwiftUI](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro),
  leído por Cupertino: tracking por propiedades consumidas, colecciones/opcionales y getters; no proporciona aislamiento.
- [Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation()),
  leído por Cupertino: lanza CancellationError si la tarea está cancelada.
- SaleRepository y UseCases11.1: éxito es aceptación local; Get requiere draft y no muta; Update compara expected.
- ServiceFormViewModel.save: patrón existente de preservar éxito después de aceptación y close que cerca resultados.

## Gates y límites

PRE independiente antes de código; usuario ya autoriza la implementación local concreta de11.3 dentro de spec.
En la aprobación local, commit/push/PR/merge/Done/eliminar rama conservaban su gate. PLU-71 sigue In Progress.
No iniciar11.4, integrar UI/selectores, descuentos globales11.7, pago11.8, stock12/documentos13 ni live.

PRE independiente favorable por `draft_store_pre`, sin hallazgos bloqueantes; precisiones de firmas/ausencia/close
registradas antes del código. Inventario702 íntegro e idéntico antes/después, confirmado por el orquestador:
`f13bc3be7ca13fa5e432d3f2150882051b66e32dc9e347b56a4f9e62c49b202b`.

Implementación exacta de esta propuesta completada localmente; RED/GREEN y builds nuevos acreditados en
[phase11](phase-11.md#implementación-y-tdd-113). Fuente551 validada
`90302546c9985a3aa461b7551c485bdae897872c07f26fc3586d558d2d844157`.
POST independiente favorable en el gate funcional; P3 de estado documental corregido en la conciliación final.
Entrega completa autorizada posteriormente y realizada: [PR35](https://github.com/JFrancoG/FranAlonso/pull/35)
MERGED como `d0a117e`, commit validado `16ba2c5`; PLU-74 Done y rama local/remota eliminada.
La fuente551 conserva su huella GREEN; siguiente11.4 y live no iniciados. [Cierre](phase-11.md#entrega113--2026-10-01).
