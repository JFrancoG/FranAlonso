# 11.1 — Propuesta del ciclo local de borrador

Fecha: 2026-10-01. Autorización: «crea issue y rama y comienza a implementar11.1».
[PLU-72](https://linear.app/plusprojects/issue/PLU-72), hija de
[PLU-71](https://linear.app/plusprojects/issue/PLU-71); ambas In Progress, Jesus Franco.
Rama: `codex/plu-72-sale-draft-lifecycle`; base limpia `4175fb1`, igual a `origin/main`.

## Autoridad y baseline

Constitución, spec11.1, política Swift y ADR0011/0012/0013/0016/0018/0030.
Swift6, concurrencia complete, target efectivo iOS27, warnings Swift/Clang como errores.
Xcode MCP estable, `workspace-PfnUYLlMzY`, Develop; sin cambio de toolchain/configuración.
Base reciente: Develop/Production y106/106 resultados focales del asistente; no prueba este ciclo nuevo.
`Sale`/`SaleLine`, DTO, siete modelos Sales, actor, adapter, señal y cola causal existen desde05.10c.
No se necesita una nueva entidad SaleItem ni cambio de esquema.

## Contrato aprobado dentro de11.1

- `SaleRepository.sale(id:) -> Sale?`: lectura local individual; ausente/descartada devuelve nil.
- `createDraft(_ draft: Sale)`: acepta solo draft y rechaza identidad conocida, incluso pendiente/remota/tombstone.
- `updateDraft(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) -> Sale`: obtiene el estado local,
  exige draft y coincidencia con el snapshot esperado; conserva id/createdAt y usa una factory Domain validante.
  Permite cliente, orden, alta/baja y cantidad/descuento de líneas; no consulta ni refresca el catálogo.
  Una línea retenida conserva serviceID/name/unitPrice/taxRate/linkedProductID; un nuevo snapshot requiere nueva línea.
- `discardDraft(_ id: SaleID)`: reutiliza el tombstone durable de ADR0016; repetición/ausencia no generan otra operación.
  Ventas progresadas y conflictos no se borran.
- `Create/Get/Update/DiscardSaleDraftUseCase`: validación Domain/cancelación previa, repositorio como aceptación autoritativa.
  Get devuelve nil para ausencia y rechaza venta progresada. Errores nuevos neutrales de Domain; infraestructura no filtra PII.

Data comprueba y guarda sin suspensión en una sola primitiva contextual, compartida por actor y adapter.
La igualdad esperada protege copias obsoletas observables en ese contexto; **no promete CAS entre contextos independientes**.
`saveSale` genérico se conserva como seam de infraestructura05.10c; las nuevas operaciones draft no pasan por un get→await→save.
No se rediseña la política sync general ni se atribuye protección global al seam genérico.
Publicar observación únicamente tras el commit local. La cancelación previa no escribe; después de aceptar, devolver éxito local.

## Áreas previstas

Sales Domain: error draft, método de sustitución en Sale, repository y cuatro UseCases.
Sales Data: local source, actor, adapter, Default/InMemory repositories; reutilizar upsert/discard y rollback existentes.
App: componer cuatro UseCases en AppDependencies sobre el mismo repositorio.
Tests: suite de ciclo real sobre SwiftData y conformidades de dobles existentes; añadir cobertura de composición pertinente.
Docs: propuesta, phase11 y snapshot Progress; sin modificación de modelos/DTO/sync/remoto/UI.

## Alternativas y riesgos

1. Nueva persistencia/Store: duplica05.10c y anticipa11.3; descartada.
2. Get→save desde UseCase: introduce suspensión entre precondición y aceptación; descartada.
3. Comandos locales explícitos sobre primitives existentes: elegida, reversible y coherente con Products/Services.
4. CAS global o rediseño de todos los upserts: requeriría ampliar el contrato persistente/sync; fuera de11.1.

Riesgos: identidad reutilizada, copia obsoleta, venta progresada, tombstone/conflicto, operación duplicada y fallo local parcial.
No inventar un límite de líneas ni validar contra el catálogo vivo: son snapshots históricos.

## TDD y validación

Primero tests de pipeline: crear vacío/con líneas; recuperar desde contexto independiente; editar conservando identidad,
fecha exacta/orden/términos capturados; descartar y repetir; creación repetida y obsoleta; estados progressed parametrizados;
conflicto/tombstone; identidad de operación fallida y rollback; cancelación previa; paridad contextual/in-memory/composición.
Oráculos del contrato/fixture sintético, no tests que copien mappers ni meros contadores de delegación.
RED por comportamiento mediante stubs mínimos de las APIs nuevas, GREEN/regresión Sales y AppDependencies por Xcode MCP.
Build Develop-for-testing/Production, logs y `.xcresult` cerrado. UI/previews/AT N/A por ausencia de cambios de presentación.
PRE y POST independientes read-only con inventario+huella idénticos de tracked/untracked no ignorados.

Fuera:11.2–11.9, stock12, documento13, pantalla/Store/selector, dependencias, unsafe, migración, Rules/índices/live.
Commit/push/PR/merge/cierre requieren autorización posterior específica.
