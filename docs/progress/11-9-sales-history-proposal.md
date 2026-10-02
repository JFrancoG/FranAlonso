# 11.9 — Histórico y detalle terminal

PLU-83 / `codex/plu-83-sales-history`, base main `73f5318` limpia/sincronizada, 2026-10-02.
Autorización humana: issue, rama e implementación local. Sin commit/push/PR/merge ni cierre operativo.
Xcode estable workspace-PfnUYLlMzY; target iOS27, Swift6 estricto, warnings como errores.

## Alcance y decisión

Histórico ocupa su sección existente del shell, independiente de Jornada. SalesHistoryViewModel y
SaleDetailViewModel son @Observable @MainActor, cada pantalla conserva una instancia mediante State.
Ambos observan ObserveSalesUseCase sobre el repositorio local compartido: sin nuevo Store, @Query,
repositorio ni esquema. Factories concretas en AppDependencies.

SalesHistoryPolicy (Domain) incluye exclusivamente closed/voided. Filtro todas/cerradas/anuladas y orden
más recientes/antiguas por fecha ORIGINAL de cierre; empate por SaleID ascendente, independiente del
orden del stream. Una anulación no mueve la posición original ni modifica importes comerciales.
La fecha efectiva de anulación sigue visible separadamente en detalle. Búsqueda Presentation por nombre
snapshot del servicio o referencia SaleID, sin depender de catálogo actual. Los nombres actuales de clientes
son labels opcionales; si no se resuelven, conservar asociación y mostrar cliente no disponible.

Navegación mediante sesión Identifiable estable (SaleDetailDestination); abrir solo una fila visible,
no duplicar presentación, ignorar dismiss obsoleto. Filtros/búsqueda no cierran detalle abierto;
un snapshot autoritativo que elimina o deja no terminal la venta sí lo invalida. Si cambia closed→voided,
el detalle conserva identidad y actualiza metadatos. Detalle ausente/no terminal comunica indisponibilidad.

Cada VM mantiene generaciones para impedir publicar snapshots, fallos, finalizaciones o labels obsoletos.
Tasks propiedad del caller/SwiftUI; cancelación vuelve a idle, cierre es terminal. Reintento explícito
conserva filtros/orden/búsqueda. Errores genéricos localizados, sin volcar errores/PII a UI/logs.
Detalle calcula importes con SaleCalculator sobre snapshot, nunca refresca catálogo; fallo de cálculo
es error recuperable, no total cero. Muestra líneas, descuentos, total original, pago/método/fecha/ID,
document ID/cierre y reversal ID/fecha si voided; anulación por icono + texto, nunca solo color.
Sin edición, borrar, cobro, anular ni emisión de documento desde Histórico.

## Fronteras normativas

11.9 requiere probar cierre/anulación: se prueban transiciones del agregado y su aparición/actualización
observable, trazabilidad y replays. ADR0006 exige compensación stock/ajuste financiero;12.8 posee
movimientos inversos y13.12 CloseSaleUseCase/pago+documento definitivo. Adelantar acciones mutantes aquí
rompería esos gates. Paid/awaitingDocument continúa en Jornada y nunca aparece en Histórico.
No stock, PDF, número inventado de negocio, correo, nuevas dependencias, unsafe, Firebase/live ni cambios
funcionales ajenos. Fixtures DEMO terminales solo en la composición aislada ya autorizada ADR0030.
No se acredita venta completa ni fase11 integral mientras existan gates/deudas previas.

## Alternativas

- Reutilizar SaleDraftViewModel: rechazada; otorga capacidades de borrador y no observa detalle terminal.
- GetSaleUseCase una sola vez: simple pero no refleja anulación/materialización mientras detalle abierto.
- Store común de Histórico: sin responsabilidad adicional; duplicaría estado/frontera de cada pantalla.
- Anulación desde UI: rechazada hasta integración compensatoria12.8 y documento/cierre13.12.

## Archivos y validación

Domain: política terminal y orden. Presentation: VMs, destino, pantallas, filas/trazabilidad.
App: factories/shell y fixtures sintéticas. Tests nuevos policy/VM/concurrencia/composición local.
.xcstrings español/inglés; previews deterministas por View, vacío/error/loading/closed/voided,
Large/XXX Large/AX5, claro/oscuro. Controles nativos, wrapping vertical, objetivo44pt, encabezados,
restauración de foco al origen si aún existe; fallback al filtro si desaparece. Sin loops/timers.

TDD compilado RED→GREEN: estados terminales/pagada sin documento, orden/tie, filtros/búsqueda,
sesión/dismiss, errores/retry/empty, cancellation/replacement/close, cliente no disponible/lectura tardía,
closed→voided/replay conservando pago/documento/importes. Observación local real prueba integración.
No tests UI/XCTest. Xcode MCP builds Develop+Production, suite y xcresult cerrado, diagnósticos;
previews/smoke runtime y auditorías independientes de estilo, técnica y UI. Matriz WCAG completa con
resultados limitados o pendientes honestos; deuda propia vinculada/Jesus Franco/tras feedback y
estabilización y antes del primer candidato real según ADR0029.

## Fuentes primarias y autoridad

Specs11/12/13, ADR0002/0006/0022/0029/0030/0031/0032, constitución, política Swift y código real.
Apple DocumentationSearch actual: [Observation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app),
[task](https://developer.apple.com/documentation/swiftui/view/task(id:name:priority:file:line:_:)),
[sheet item](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)).
MCP estable usa documentación instalada de Apple; APIs de composición ya compiladas en Jornada.
Riesgos: fechas locales son metadatos materializados, no autoridad contable; labels no son snapshot fiscal.
Cambio reversible de Presentation/factories; ningún formato persistente cambia.

## PRE independiente

PASS independiente, /tmp/plu83-pre-review.md; 776 archivos y cuatro FULL JSON idénticos
(root/revisor antes/después), digest276e8689db933c2ad0163f7853150dc676da04b72534268e24db52e363dac4b7.
Fixtures terminales solo muestras históricas DEMO materializadas: no emisión documental, cierre13.12
ni compensación12.8 acreditados. Aviso explícito en demo/runbook. La autorización de implementación ya fue recibida y
se continúa tras PRE dentro de este alcance sin solicitar confirmación repetida.
