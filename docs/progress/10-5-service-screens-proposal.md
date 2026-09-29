# Propuesta 10.5 — Lista y formulario adaptativos de servicios

2026-09-29. PLU-64, hija de PLU-59, Jesus Franco, In Progress. Rama `codex/phase-10-5-service-screens`
desde main/origin/main b4801df limpios. El propietario autoriza implementar10.5 después de la entrega10.4:
PR27 MERGED/86a1d09, PLU-63 Done y rama eliminada. Entrega Git10.5 y10.6 siguen pendientes de autorización.

## Autoridad y baseline

Constitución, spec10/índice, política Swift, ADR0002/0006/0011/0015/0018/0022/0029/0030; perfil maintenance.
Xcode MCP estable workspace-EYu6rxi7hg: Swift6 estricto, target26/SDK27, Develop/iPhone18Pro, configuración intacta.
10.4: PRE/POST PASS,1.058 declaraciones/1.516 resultados PASS, Develop22,729s/Production21,3s. Código conserva huella POST;
aviso AppIntents metadata y seis enlaces históricos08.3 conocidos. No repetir validación sin impacto.
Patrones concretos: ProductListScreen/FormScreen/Content/Row, FormFieldSection, feedback y fixtures09.4.
Apple: [Decimal currency](https://developer.apple.com/documentation/foundation/decimal/formatstyle/currency),
consultado por Cupertino: formato Decimal con moneda y Locale, sin Double. APIs SwiftUI nativas ya compiladas en09.4.

## Producto y navegación

Catálogo ofrece dos entradas nativas claras: Servicios y Productos. Nueva CatalogScreen con ViewModel observable propio
para navegación tipada; rutas .services/.products, path en VM. El shell conserva Tab/sidebar, sesión y acceso al inventario.
No añadir botones a una toolbar ya ocupada para mezclar ambos catálogos. Sin filtro de venta ni nuevas tabs.

ServiceListScreen usa10.4: estados carga/vacío/contenido/error, búsqueda local insensible a caja/diacríticos, ambos tipos
 y estados. Filas multilínea muestran nombre, tipo y precio con moneda, más texto de inactivo. Añadir abre alta profesional;
abrir fila edita esa identidad. Sheet conserva UUID y guardas contra cierres tardíos. Resultado se anuncia tras dismiss;
restauración nativa y foco de Añadir tras creación/desactivación, sin timers/reintentos de foco.

ServiceFormScreen/Content muestran nombre comercial, tipo, precio con impuestos incluidos, moneda EUR/USD, impuesto
(puntos porcentuales), descuento opcional. Inputs textuales usan draft10.4 exacto; no lógica comercial ni persistencia
en View. Impuesto inicial vacío, descuento vacío distinto de cero. Guardar permanece operable para revelar validación.
Errores de campo próximos a input y foco tras intento explícito; otros errores generales accionables sin detalles técnicos.
Carga fallida bloquea campos y ofrece retry. Progreso bloquea acciones solapadas; éxito local cierra y anuncia.
Cancelar con cambios confirma descarte; desactivar confirma que conserva historial y descarta cambios del borrador.
Desactivación histórica funciona aunque el producto ya no esté; todos los errores conservan borrador para retry.

Delimitación10.6: tipo solo lectura en10.5. Alta profesional; edición de ambos tipos conserva tipo/vínculo. Servicios
producto existentes muestran que mantienen producto asociado, sin UUID ni afirmar disponibilidad actual. No selector
inoperante ni opción de alta imposible. Cambiar tipo, elegir y sustituir vínculo se implementan en10.6. Error de vínculo
indisponible explica que no se guardó y permite cancelar/desactivar; no prometer sustitución todavía disponible.
Este incremento permite la ficha profesional completa y ambos tipos en lista/edición/demo, no todo el catálogo final.

## Estado, Locale y composición

Reusar VMs10.4 sin nuevas reglas de negocio. Estado efímero de request/confirmaciones/foco vive en Screen como09.4;
intenciones delegan save/deactivate/load/close al VM. FormContext efímero vía @Environment(modelContext), sin retenerlo.
Tareas caller-owned .task/.task(id:), sin Task interno, GCD, polling ni cambios Data. Cierre protege respuestas tardías.
Feedback específico Service traduce errores a recursos y campo de validación; precio negativo dirige al precio.

ServiceFormFactory pasa a (ServiceFormDestination, Locale)->ServiceFormViewModel. Screen captura Environment.locale
al crear VM, y la sesión lo mantiene fijo; previews ES/EN y parser comparten ese Locale. Ajuste mecánico de callsites/tests.
Precio de fila usa Decimal.FormatStyle.Currency(code:locale:); porcentajes como texto numérico con etiqueta %, no .percent
sobre valores21. No NSNumber/Double/formatter legado. Textos visibles ES/EN en Localizable.xcstrings.

## Demo y previews

AppPreviewModifier añade ServicePreviewFixtures después de ProductPreviewFixtures: profesional, producto asociado a
primario activo e inactivo; IDs fijos y seed idempotente que no sobrescribe ediciones. Listas de volumen snapshot puro.
DevelopDemoServiceScenario añade un profesional y un servicio producto coherente después del seed Product, mediante
la aceptación comercial real, IDs y operationIDs fijos. ProductScenario expone el ID estable usado; no duplica literales
sin relación. Contenedor en memoria, nuevo lanzamiento restaura escenario; fixture auth vacía intacta, Sale vacía/runtime nil.
Actualizar assertions antiguas que exigían Service vacío y el runbook08.8a. Sin durabilidad, Firebase ni motores live.

Cada View nueva incluye preview determinista con trait compartido. Variantes de lista vacía/uno/volumen/error y formulario
profesional/producto/error/carga fallida/progreso. Render representativo de CatalogScreen, ServiceListScreen y formulario
con Large/XXX Large/AX5 soportados, ES/EN, apariencias representativas; iPad/ventanas y RTL según impacto/ADR0029.

## Archivos y validación

Nuevos Services/Presentation/{Screens/ServiceListScreen,ServiceFormScreen; Views/ServiceRow,ServiceListContent,
ServiceFormContent; ViewModels/ServiceFormFeedback}, App/CatalogScreen+CatalogViewModel, App/Previews/ServicePreviewFixtures,
App/DevelopDemoServiceScenario. Cambios mínimos AppShellScreen, AppDependencies+ServiceForm y alias, AppPreviewModifier,
DevelopDemoComposition/ProductScenario, Localizable.xcstrings; tests de composición/Locale y callsites existentes.
Documentos spec10, Progress/phase10/propuesta, runbook y evidencia accesible10.5. Sin schema/DTO/sync ni cambios históricos UI.

TDD focal para efectos nuevos: seed de preview idempotente conserva edición; demo crea ambos tipos coherentes, flujo real
crear/editar/desactivar/reabrir/reset conserva aislamiento; Locale inyectado interpreta comas/puntos de su sesión y
rechaza otro separador sin guardar. Matrices Domain10.1–10.4 reutilizadas. No tests de texto estático/estructura de Views.
Build/tests por Xcode MCP, logs/xcresult cerrado, estilo cambiado y regresión proporcional. Smoke real demo: entrar a ambos
catálogos, buscar, alta inválida→válida, editar/descartar, conservar vínculo producto, desactivar y reabrir inactivo.

ADR0029: controles nativos, labels persistentes, 44pt, DynamicType, semántica/errores/anuncios desde construcción;
PRE antes de código, POST estándares y accesibilidad read-only con huella. Nueva issue de deuda integral vinculada aPLU64,
Jesus Franco, tras feedback/estabilización y antes de uso real. Matriz registra todos los criterios aplicables/condicionales;
no convertir evidencia AT/Inspector/contraste/ventanas pendiente en PASS. Deuda08/PLU54/57 sigue independiente.

## Alternativas, riesgos y reversibilidad

Raíz Catálogo con dos destinos mantiene inventario visible y evita toolbar saturada. Tipos fijos preservan separación10.6;
anticipar selector ampliaría alcance, y ofrecer una opción imposible de guardar empeoraría la demo. Reusar VMs10.4 evita
validación duplicada. Locale explícito evita discrepancia entre entorno visual y parsing. Riesgos: teclado/scrollAX,
confirmaciones, captura monetaria, vínculo histórico y restauración de foco. Previews y smoke cubren funcionamiento;
matriz manual exhaustiva se recupera por flujo. Retirar pantallas/seed revierte sin migración. Sin dependencias ni unsafe.

## PRE independiente

PASS sin hallazgos P0–P3. Reviewer/root verifican648archivosidénticos antes/después: `/tmp/franalonso-10-5-pre1.json`,
SHA256 `09d606e3c3bc693b371499d44c06aada7bb6f6e2fb3e81cad0be6c08236f7736`. Read-only operacional, sin builds/tests/escrituras.
Implementación autorizada por petición inicial. PLU-65 Backlog cubre deuda integral propia, JesusFranco, tras feedback y
estabilización antes de uso real. Catálogo posee el único NavigationStack tipado de su tab.

## Resultado de implementación — 2026-09-30

Alcance implementado y puerta funcional ADR0029 PASS; [registro completo](phase-10.md) y
[matriz accesible](../accessibility/evidence/10-5-service-screens.md). TDD RED5fallos/1PASS, global1.061declaraciones/
1.520resultadosPASS; builds, previews y smoke PASS. POST estándares favorable; P2 de mensaje accesible corregido
ES/EN y rerevisión focal favorable. Validación integral aplazada en PLU-65, sin declarar sus criterios resueltos.
PLU-64 sigue In Progress hasta entrega autorizada; rama con cambios locales sin commit/push. No se inicia10.6.
