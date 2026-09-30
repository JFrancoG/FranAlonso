# 10.7 — Selección de servicios para ventas

## Entrega — 2026-09-30

[PR30](https://github.com/JFrancoG/FranAlonso/pull/30) integrada en cf3ff20; commit760a7e7, PLU-68 Done y rama
eliminada local/remota. Árbol validado intacto; evidencia reutilizada. Fase10 conserva PLU-65/67 pendientes.
El apartado siguiente conserva el contexto de inicio; FoundationModels no se inicia con esta entrega.

## Estado y autorización de inicio

2026-09-30. PLU-68 In Progress, Jesus Franco, hija de PLU-59. Implementación autorizada por el propietario tras
entregar10.6/PR29; rama `codex/phase-10-7-service-picker`, base limpia main/origin/main3ddb84f.
El propietario autoriza commit/push/PR/merge/cierre10.7 con «commit, push y entrega».
El adelanto FoundationModels conserva su autorización posterior.

## Autoridad y baseline

Constitución, spec10 (búsqueda/filtros/snapshots), spec04 (valores comerciales), spec11.6 (congelar SaleLine al añadir),
spec12 (stock insuficiente no bloqueante); ADR0002/0006/0011/0015/0018/0022/0029/0030 y política Swift vigente.
No cambia target26, SDK27, Swift6/strict complete/default nonisolated ni warnings-as-errors, verificados por Xcode MCP.
Workspace workspace-EYu6rxi7hg. Baseline10.6:1.544resultados PASS, Develop/Production PASS; aviso AppIntents conocido,
seis enlaces históricos08.3 ausentes. No se repiten pruebas de UI porque10.7 no cambia pantalla ni texto visible.
Fuentes primarias internas: Service, SearchServicesUseCase, ObserveServicesUseCase, ServiceListViewModel, SaleLine y
AppDependencies. No se introduce API Apple incierta; se reutiliza Observation/AsyncThrowingStream del patrón compilado.

## Contrato propuesto

- Caso de uso puro Domain `FilterSelectableServicesUseCase` aplica elegibilidad Service.status.active y filtro por
  tipo (`all`, `professional`, `product`), conserva orden y reutiliza SearchServicesUseCase para nombre parcial,
  espacios exteriores, caja y diacríticos. No cambia la búsqueda administrativa que admite inactivos.
- `ServicePickerViewModel @Observable @MainActor`: una colección observada, query y filtro editables (all inicial),
  `visibleServices` derivada, estados idle/loading/empty/content/failed. Empty significa ningún servicio activo;
  content con visibleServices vacía y hasNoSearchResults distingue cero coincidencias por query o filtro.
- Observación async propiedad de la tarea caller. Cada ejecución limpia catálogo anterior, marca loading e invalida
  generaciones antiguas. Snapshots actualizan colección; no se crea Task interno. Error limpia y marca failed;
  cancelación limpia y vuelve idle. Finalización normal conserva último snapshot incluso vacío; sin emisión marca failed.
  Query/filtro se conservan al reintentar. Una observación reemplazada no publica ni cambia estado por error/cancelación.
- `selectService(id:) -> Service?` síncrono acepta solo IDs en visibleServices y estado content. Devuelve valor Service
  completo e inmutable del último snapshot observado: identidad, nombre, tipo, vínculo, Money/moneda, impuesto,
  descuento opcional (nil distinto de cero), estado. Cambios observados antes de elegir se reflejan; cambios posteriores
  no modifican la copia entregada. IDs ajenos/inactivos/filtrados/retirados/carga/error/idle/empty devuelven nil.
- No reserva ni reconsulta Product/stock al elegir; la disponibilidad de Service no afirma vigencia de Product ni stock.
  La política de admisión y congelación de SaleLine es de11.6. No añade filtro de moneda; conserva EUR/USD exactos.
- App ofrece factory de picker sobre su `observeServices` ya compartido para runtime, fixture y previews, sin repo nuevo.

## Áreas y alternativas

Nuevos Domain/UseCases/FilterSelectableServicesUseCase.swift (filtro anidado semántico),
Presentation/ViewModels/ServicePickerViewModel.swift y sus tests. AppDependencies+ServicePicker.swift si mejora cohesión,
pruebas de composición sobre catálogo compartido. Spec10 y registros Progress/fase10 actualizados.
Reutilizar Service evita un DTO duplicado; crear SaleLine ahora adelantaría11.6. Filtrar en Domain evita reglas comerciales
en Presentation. No Store para una sola responsabilidad, ni nueva capa de infraestructura/streams genéricos.

## TDD y validación

RED compilable con stubs: elegibilidad/tipos/query/orden, vacío vs sin coincidencias, selección vigente y completa,
retirada/inactivación/cambios comerciales, copia retenida, descuento nil/cero y moneda; estados de error/retry,
finalización sin emisión/con snapshot, cancelación y generaciones reemplazadas. Pruebas controladas por continuations
sin sleeps/polling. Composición real sobre repositorio in-memory compartido prueba alta/edición/desactivación mediante recargas finitas, sin duplicar
motor monetario ni infraestructura de persistencia. GREEN focal, regresión global si necesaria para variantes parametrizadas,
builds Develop/Production con logs completos y resultado nativo cerrado; estilo, diff-check y gobernanza; POST read-only.
UI/previews/AT nuevos N/A por ausencia de Views/textos/interacción nueva. PLU-65/67 conservan deuda integral con Jesus Franco,
recuperar tras feedback y estabilización antes del primer candidato real. No se cierra fase10.

## Exclusiones y riesgos

Sin Views/navegación, strings, cantidades, SaleLine, checkout, venta11–13, FoundationModels, cambios Data/schema/sync,
Firebase live, dependencias, unsafe ni nuevos Store. Snapshot es lectura local, no aceptación de una venta ni reserva.
La mayor frontera es una selección obsoleta: el ID se resuelve de nuevo contra el catálogo visible actual al ejecutar la intención.

## PRE

PRE independiente PASS sin P0–P3. Reviewer/root verifican665archivos idénticos antes/después; manifiesto
`/tmp/franalonso-10-7-pre1.json`, SHA256
`9b21252115dc304882c32e41bd6d1c8a9feb3ac5752de00e56e91ceaae84fb87`. Sin builds ni mutaciones del revisor.
Composición por recargas finitas acredita grafo compartido; el stream controlado acredita emisiones continuas del ViewModel,
no nueva validación del refresco SwiftData. No se requiere nueva aprobación dentro del alcance autorizado.

## Implementación y validación

Completados Domain/VM/factory App; seis Swift y documentación, sin modificación Data/UI. TDD RED20/20,
GREEN global1.082declaraciones/1.564resultados PASS, builds Develop/Production PASS; solo AppIntents previo.
Native xcresult cerrado y logs completos inspeccionados; esquema Develop restaurado. Detalle en [fase10](phase-10.md).
Estilo: seis Swift, P3 de123columnas corregido a vertical, tokens idénticos. POST independiente y rerevisión focal PASS;
670archivos idénticos por revisión. POST1 SHA2564f3a787f6d9af2d806cec7ce83efb84ae02542ad1b7e8121f5eeab739f7c63ae;
POST2 SHA2566095c26b9a5cc1718ca6b21ac515043c6ac65bd8a46c6f5b46119fa88a5cbc04. Build final Develop con tests23,807s
PASS tras formato; global/Production se reutilizan. Gobernanza conserva solo seis enlaces históricos08.3. Sin Views/textos,
UI/previews/AT nuevos N/A; deuda PLU-65/67 intacta. PLU-68 In Progress hasta completar la entrega10.7 autorizada.
