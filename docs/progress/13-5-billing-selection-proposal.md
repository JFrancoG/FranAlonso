# 13.5 — Selección del documento y destinatario fiscal

03/10/2026. Autoriza «abre issue y rama e implementa13.5».
[PLU-100](https://linear.app/plusprojects/issue/PLU-100), In Progress/Jesus Franco;
`codex/plu-100-billing-selection-form`, base limpia main/origin/main `76835cb`.
Spec13, constitución, ADR0008/0011/0022/0029/0030 y política Swift vigentes.
13.1–13.4 entregadas: baseline2523/2523, ambos builds PASS; conserva los límites AppIntents,
Stock intermitente y seis enlaces históricos08.3. No repite validación histórica por rutina.

## Comportamiento y límites

Desde una venta pagada pendiente de documento en Jornada, abrir una sesión de selección ticket/factura.
Factura permite completar nombre/razón social, identificador fiscal, calle, código postal, ciudad y provincia.
Prefill opcional del cliente local asociado, comprobando identidad; nunca modifica el perfil del cliente.
Validación de aplicación: trim en los extremos y los seis campos no vacíos. Mantiene Unicode/case y
espacios internos; no impone checksum NIF, cinco dígitos, país ni aprobación jurídica.
Ticket no requiere ni captura destinatario fiscal. Preparar sella una única solicitud inmutable de la
venta pagada y sus datos; edición posterior no altera esa solicitud. Repetir preparar conserva sus IDs.
Cancelar/terminar la presentación no reserva número, no modifica/cierra la venta y mantiene Jornada.
Una sesión cancelada antes de emitir puede descartarse: no existe documento numerado ni efecto remoto.
La durabilidad entre reinicios se mantiene en13.10; no se promete ahora.

## Diseño y áreas exactas

- Domain Billing: `BillingFiscalField` con orden de validación estable y `BillingFiscalRecipientInput`
  editable de seis textos; `BillingFiscalRecipient` inmutable/Codable revalida al decodificar;
  `PrepareBillingDocumentRequestUseCase` valida antes de generar IDs/fecha mediante closures Sendable
  inyectables. `BillingDocumentRequest` añade snapshot opcional: nil conserva solicitudes históricas;
  nuevo flujo requiere snapshot para factura y excluye snapshot de ticket.
- Data Billing: DTO explícito de destinatario con claves exactas. Request payloadv1 histórico sin
  destinatario; payloadv2 con destinatario completo de factura; rechazar v1+campo, v2 ausente/null,
  campos desconocidos o contenido inválido. Document/binding/counter externos siguen v1. Comparación
  transaccional completa existente detecta cambios fiscales sin cambiar la política de numeración.
  Fixtures históricas requestVersion en BillingTransactionFixtures y FirestoreBillingDocumentReservationTests
  cambian únicamente2→3 para conservar el oráculo de versión desconocida. Su envelope histórico se
  decodifica y toDomain/toRecord lo rechaza; nunca llega a crear un registro válido.
- `BillingViewModel` existente mantiene fachada/Store13.4 e incorpora únicamente borrador de formulario
  previo a prepare, errores y prefill local asíncrono caller-owned. Ninguna Task en init: carga ignora
  resultados tardíos tras edición/cierre/cambio de sesión y exige clientID correcto. Store conserva la
  única solicitud sellada; borra borrador editable al preparar/cerrar. Capacidad de preparación comprueba
  que la sesión padre sigue vigente y la venta pagada coincide con el snapshot capturado.
- Sales Presentation: destino UUID+saleID, apertura únicamente para venta pagada pendiente disponible,
  reapertura repetida estable y cierre antiguo ignorado. Cambios focales en SaleDraftViewModel y cadena
  AppShell→Workday→SaleDraft→SaleWorkflowSection. Parent/Store siguen vivos y no realizan I/O al cancelar.
- App: factory concreta `AppDependencies+Billing`, obtiene el cliente de la fuente local actual y
  construye BillingViewModel con `UnavailableBillingDocumentReservationRepository` Data. Este adaptador
  explícitamente inactivo devuelve unavailable y respeta cancelación; no simula numeración ni activa
  Firebase. La pantalla no ofrece reserve/retry; su composición futura exige aprobación separada.
- SwiftUI: BillingScreen y componentes/formulario/confirmación separados, una View por archivo,
  previews deterministas. Form y selector nativos, labels persistentes, controles44pt, filas sin alturas
  rígidas. FocusState y AccessibilityFocusState por campo llevan al primer error; anuncio localizado,
  texto junto al campo, retorno al botón de entrada. Views renderizan y envían intenciones semánticas.
  Todos los textos nuevos en catálogo es/en y LocalizationInventory; ninguna PII en logs/telemetría.

## Alternativas y fuentes

No basta guardar clientID: editar el perfil después cambiaría el destinatario de un documento preparado.
Guardar snapshot dentro de request permite igualdad/idempotencia completas y evita una autoridad paralela.
Romper payloadv1 invalidaría solicitudes/replays anteriores; v2 explícita conserva esos datos sin inventarlos.
Reutilizar ClientProfile sin validar aceptaría direcciones parciales permitidas por su CRUD. No endurecerlo:
el formulario fiscal tiene su propia política de completitud. Una nueva máquina/Store duplicaría13.4;
se amplía la fachada y se conserva su allocation. Reservar al seleccionar anticiparía la emisión de subfases posteriores.

[AEAT, contenido de facturas](https://sede.agenciatributaria.gob.es/Sede/iva/facturacion-registro/facturacion-iva/contenido-facturas.html)
se consultó03/10/2026 como fuente primaria de identificación/domicilio. Los seis campos obligatorios son
una política de la aplicación, no una afirmación de suficiencia legal; revisión fiscal real sigue gateADR0008.
[Apple AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate)
leído mediante Cupertino MCP; focused(_:equals:) y accessibilityFocused(_:equals:) consultados mediante
Xcode DocumentationSearch. SDK/target reales verificados por Xcode MCP27.0 estable, sin cambiar configuración.

## TDD, validación y auditorías

Antes de código: PRE independiente read-only de este diseño, alternativas, fuentes y alcance congelado.
Después: RED compilable Swift Testing para validación/factura/ticket, snapshot/DTO/replay completo y
sesiones/borrador/cancelación/prefill tardío. GREEN mínimo; conservar regresión13.1–13.4/Sales.
Probar cada campo whitespace, trim sin regex, venta impagada/terminal, clientID ajeno, IDs estables,
ningún contacto de reserva/cierre, v1/v2 y conflicto fiscal/respuesta perdida con un solo commit.
Regresión posterior al smoke: un setter de TextField con valor idéntico conserva error/validationID;
solo una edición real los limpia. El prefill aceptado que cambia el borrador limpia la validación previa,
y el idéntico la conserva; nunca prepara automáticamente. Etiqueta accesible explícita coincide con el título
persistente del campo. Estos ajustes mantienen el scope aprobado y no introducen máquina/task nueva.
No XCTest/XCUITest. Root serializa todas las operaciones Xcode MCP; workers no lanzan builds/tests.
Auditoría independiente de estilo antes de validación final; builds Develop/Production y global apropiado.
Previews representativas Large/XXXL/AX5 es/en, formulario/error/preparado y entrada afectada; smoke táctil
Simulator si la capacidad está disponible. Matriz de55criterios por flujo, POST estándares/accesibilidad.
ADR0029: evidencia manual exhaustiva/AT/Inspector/contraste pendiente requiere deuda nueva vinculada,
responsable Jesus Franco, tras feedback/estabilización y antes del primer candidato para uso real.

No nuevo ADR, dependencia, unsafe, target, live/Rules, PDF/Storage/correo, persistencia13.10 ni cierre13.12.
Commit, push, PR, merge, Done y13.6 permanecen fuera de la autorización actual.
