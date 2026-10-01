# Propuesta 11.4 — Fachadas de Jornada y detalle

Estado: implementada y validada localmente; PRE/estilo/POST PASS. Entrega Git autorizada en curso.
Autorización del usuario el 2026-10-01; [evidencia RED/GREEN y revisiones](phase-11.md).
[PLU-75](https://linear.app/plusprojects/issue/PLU-75), hija de PLU-71; rama `codex/plu-75-workday-viewmodels`.
Base limpia local/origin `b16621d474b340579039fe6bdd213a3c4981ec13`; 11.1–11.3 entregadas.

## Autoridad y baseline

Spec11, constitución, política Swift y ADR0011/0016/0030. Perfil `maintenance`: arquitectura por feature,
Domain puro y ViewModels `@Observable @MainActor`; Store11.3 conserva el borrador aceptado y su cálculo.
Xcode MCP stable Service: `workspace-PfnUYLlMzY`, FranAlonso.xcodeproj, Develop/planDevelop, destino iPhone11.
Settings efectivos: iOS27.0, Swift6, strict complete, default nonisolated, warnings Swift/Clang como errores.
Baseline11.3 reutilizada: 1.840/1.840 variantes, 1.175 declaraciones, Develop/Production y PRE/POST PASS;
fuente551 `90302546c9985a3aa461b7551c485bdae897872c07f26fc3586d558d2d844157` intacta al inicio.
No acredita UI, tecnologías de asistencia ni live. Las seis capturas históricas rotas08.3 permanecen fuera del cambio.

## Comportamiento exacto

- `WorkdaySalesPolicy` pura clasifica `draft` como próximo, `inProgress` como en curso,
  `awaitingPayment`/`awaitingDocument` como pendiente de cierre. Excluye `closed`/`voided` inmediatamente.
  No filtra por fecha ni fusiona ventas del mismo cliente. Orden determinista por creación ascendente e identidad.
- `WorkdayViewModel` observa la SoT mediante ObserveSalesUseCase, conserva un único snapshot clasificado y estado
  carga/vacío/contenido/error. Caller posee la tarea estructurada; generación cerca streams reemplazados y close terminal.
  Selección y destino tipado poseen identidad de sesión distinta del SaleID; crear/abrir repetidos no duplican sesiones.
  No abre identidades ausentes/terminales; desaparición o cambio incompatible de modo invalida selección/destino.
  Dismissal tardío de una sesión anterior no cierra otra nueva.
- `SaleDraftDestination` distingue crear, editar borrador e inspeccionar operación. No transmite copias de ventas.
  El ViewModel fija una sola identidad/fecha para crear y conserva exactamente un SaleDraftStore construido con UseCases.
- `SaleDraftViewModel` proyecta el Store y delega crear/cargar/añadir/quitar/cantidad/cliente/descuento de línea/descarte.
  No duplica borrador, líneas, totales o errores del Store. Close termina el Store sin descartar datos persistidos.
  No añade checks post-write que conviertan aceptación durable en fallo por cancelación.
- En modo inspección, `GetSaleUseCase` neutral lee el snapshot local por ID sin mutación; solo estados operativos se
  muestran en lectura junto al cálculo Domain. No se pasan a Store.load ni admiten edición/descarte.
  Una carrera de progreso al cargar modo borrador falla cerrada con requiresDraft; Jornada reconciliará el destino.
  Inspección tiene recarga explícita, error/reintento y cancelación/resultados tardíos cercados.

## Áreas y alternativas

Producción nueva: Domain/Policies/WorkdaySalesPolicy.swift, Domain/UseCases/GetSaleUseCase.swift,
Presentation/Navigation/SaleDraftDestination.swift y Presentation/ViewModels/WorkdayViewModel.swift,
SaleDraftViewModel.swift. Tests Swift Testing focales de policy/lectura/tablero/fachada/concurrencia.
Sin modificar Store11.3, Data, esquema o composición App hasta disponer de consumidores UI reales11.5.

Se descarta duplicar estado monetario en el VM, permitir al Store editar estados progresados o persistir desde
Presentation: rompen autoridad/invariantes. Pasar un snapshot en el destino evita una lectura pero nace obsoleto;
se elige lectura local neutral solo para inspección. Los borradores leen una vez por el Store existente, sin doble lectura.
No se introduce otro Store ceremonial para Jornada. No se añaden mutaciones de inicio/completar/pago en este gate.

## TDD, riesgos y validación

Primero RED nativo de criterios de clasificación/navegación y composición de fachada sobre scaffolding mínimo;
después implementación y GREEN. Oráculos de identidad/orden/estados desde contratos; importes Decimal de cadenas.
Dobles actor deterministas en la frontera SaleRepository; continuations/streams controlados, sin sleeps ni backend real.
Probar pagada visible, terminal ausente, múltiples clientes/ventas sin cliente, final sin valores, error/reintento,
cancelación, sustitución de observaciones, sesiones antiguas, readonly sin writes y close durante aceptación durable.
No reejecutar tests que solo repiten el Store; sí probar composición real Store/UseCases a través de la fachada.

Builds Develop-for-testing y Production por Xcode MCP, suites afectadas y regresión final proporcional;
inspección completa de logs y xcresult. Estilo Swift en modo Audit independiente antes del GREEN final y POST fresco.
Huella completa tracked/untracked no ignorados antes/después de cada auditoría para fallback read-only.
UI/previews/localización/accesibilidad/físico N/A al no modificar pantallas. Riesgo de snapshot de inspección obsoleto
acotado por recarga explícita; actualización continua del detalle se reconsiderará con la UI11.5 sin alterar este gate.

## Exclusiones y autorización

No UI11.5, selector11.6, descuento global11.7, pago11.8, Histórico11.9, stock12, documento13, dependencias,
unsafe, cambio de target, persistencia o live. La solicitud autoriza issue/rama e implementación local de11.4;
commit/push/PR/merge/cierre y11.5 conservan gates propios. No se necesita un ADR nuevo para aplicar contratos vigentes.

Autorización posterior del usuario el 2026-10-01: commit, push, PR, merge y cierre de issue/rama de11.4.
11.5 no está implementada: las fachadas y destinos pertenecen a11.4; las pantallas y composición App serán11.5.

## Fuentes primarias

- [Apple Observation](https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:)):
  tracking de getters calculados que leen el Store; consultado mediante Cupertino.
- [Apple Observation en SwiftUI](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).
- [Apple Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation()):
  cancelación cooperativa en lecturas; las escrituras aceptadas mantienen el contrato11.1/11.3.
- Código real: SaleRepository, ObserveSalesUseCase, GetSaleDraftUseCase, SaleDraftStore y ServiceListViewModel.

## Revisión

PRE independiente `viewmodels_pre`: sin hallazgos, PASS antes de código ejecutable.
Inventario707 completo idéntico antes/después: `b2b06903659aa155a481b272267d7c0cd64e8bcdab8a1bfd7c55a52c7ba6ab42`.
Fuente551 intacta al inicio y durante PRE; revisor no escribió/publicó ni ejecutó build/tests.

POST independiente `viewmodels_post`: sin hallazgos, PASS sobre los cinco archivos productivos y seis de tests.
Inventario718 completo idéntico antes/después: `6418774b186de9172343151849b654a751a8189cefaa239a194854678818acc2`.
Fuente/configuración562 validada: `cb84502ae0f20bb078216ecf33b8d93b1598b344848ccc9c7103fec6b2060872`.
GREEN focal38/66 y regresión1.213/1.906, todo Passed; builds Develop-for-testing/Production y estilo PASS.
La inspección conserva recarga explícita. Sin UI modificada; composición App con consumidores reales en11.5.
