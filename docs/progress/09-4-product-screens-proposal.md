# Propuesta 09.4 — Lista y formulario de productos

2026-09-29. PLU-53, Jesus Franco, hija de PLU-49. El propietario autoriza implementación09.4 después de entregar09.3.
PR19 MERGED13b0839, head58ee95f intacto; rama eliminada. Base main/origin/main acd0514 limpia y sincronizada antes de
crear `codex/plu-53-phase-09-4-product-screens`. No requiere nueva confirmación para decisiones ordinarias de este alcance.
Entrega09.4 y siguiente09.5 conservan autorización separada.

## Autoridad y baseline

Constitución, spec09/índice, política Swift y ADR0011/0022/0029/0030. Perfil maintenance, target26, Swift6, strict complete,
nonisolated; sin nuevas dependencias o ajustes de proyecto. Xcode MCP estable, workspace-EYu6rxi7hg, Develop/iPhone18Pro27.
09.3:1.191/1.191 resultados PASS, builds Develop/Production PASS, PRE/POST PASS. Aviso AppIntents conocido y seis enlaces
históricos08.3 pendientes. La entrega reutilizó código byte a byte; preparación09.4 documental, sin runtime nuevo todavía.

## Comportamiento exacto

- Catálogo conserva su pestaña y toolbar de sesión; sustituir placeholder por NavigationStack/ProductListScreen, título
  Productos. Sin pantalla intermedia ni nuevo tab; Service se incorpora en fase10.
- Lista nativa con búsqueda, botón Añadir producto y filas completas operables de44pt mínimo. Nombre multilínea,
  inactivo indicado con texto/símbolo, nunca solo color; ambos estados siguen editables. Reutilizar ProductListViewModel
  y su identidad de sesión. Carga, vacío, sin coincidencias, contenido y error con reintento explícitos.
- Sheet identificada por sesión; Binding protege cierres antiguos. Observación en tarea del caller; el cierre de
  formulario no reinicia artificialmente la lista. Anuncio localizado de guardado/desactivación y errores; restauración
  nativa de foco más destino explícito de Añadir tras alta. No bucles/timers de foco; runtime AT integral queda pendiente.
- Formulario nativo con campo Nombre etiquetado, multilineal y sin autofill de persona. Título Nuevo producto/Editar
  producto; botones Cancelar/Guardar, iconos etiquetados en AX grande si lo exige espacio, objetivos44pt. Error próximo
  al campo y error de carga con retry; ausente jamás permite alta implícita. Mostrar estado Inactivo sin reactivación.
- Reutilizar ProductFormViewModel, mutaciones con ModelContext efímero del entorno y tareas ligadas a peticiones.
  Bloquear controles durante mutación y mantener `.interactiveDismissDisabled()` siempre, también con borrador editable;
  solo Cancelar confirmado o resultado aceptado cierran la hoja. Cierre explícito invalida respuestas. Guardado/desactivación confirmados
  cierran solo su sesión. No persistencia, validación ni negocio en Views.
- Añadir únicamente `hasUnsavedChanges` al ViewModel: nombre actual frente a nombre cargado/vacío inicial, solamente
  cuando el borrador es editable. Cancelar con cambios ofrece Descartar/Seguir editando. Desactivación requiere diálogo
  nativo explícito y avisa que descarta cambios de nombre sin guardar; cancelar confirmación conserva el borrador.
  No swipe destructivo, eliminación física, reactivación ni historial de edición.
- ProductFormFeedback concentra mappings localizados de errores/progreso. Todos los textos nuevos en xcstrings es/en;
  nombres sintéticos son datos, no recursos UI. Componentes existentes FormFieldSection/LoadingStateView/
  UnavailableStateView y tokens semánticos; un View por archivo y preview propio con trait común.

## Previews y demo

ProductPreviewFixtures: IDs/datos constantes, nombre largo y producto inactive. Snapshots puros0/250 para volumen,
sin insertar250 filas en el contexto compartido. Sembrar dos productos idempotentemente en AppPreviewModifier para
previews interactivas coherentes con lectura/escritura del mismo container. No mutar snapshot preview readonly.

Añadir dos productos sintéticos activos a DevelopDemoComposition dentro del perfil Debug-Develop existente, mediante
escenario Product específico y ProductLocalDataSource.createProduct, IDs/operationIDs constantes, antes de componer.
Nuevo lanzamiento recrea escenario; edición/desactivación/alta usan capas reales y memoria aislada. No cambiar fixtures
vacías de autenticación, proveedores, flags, cloud, Keychain, live ni condiciones de acceso. Actualizar runbook08.8a para
indicar el catálogo disponible, sin prometer stock/Service. Previews se mantienen independientes del seed de demo.

## Áreas y validación

- Products/Presentation/Screens y Components: lista, contenido, fila, formulario y contenido de formulario.
- ProductFormViewModel/Feedback y pruebas focales de borrador. Mantener lo demás de09.3.
- AppShellScreen, App/Previews, AppPreviewModifier, DevelopDemoComposition/escenario Product y tests afectados.
- Localizable.xcstrings, evidencia accesible09.4, spec09 si consolida contratos, Progress/phase09/runbook y Linear.

TDD Swift Testing: RED ejecutable de hasUnsavedChanges y seed/demo/preview antes de implementar ese comportamiento;
sin contar fallos de compilación como RED. Probar edición/reversión/error/terminal, idempotencia de preview y demo
crear→editar→desactivar→reset sobre container real, conservando aislamiento y entidades Service/Sale vacías.
No tests de render ni de mero mapping literal; comportamiento09.3 ya probado se reutiliza.

Build/tests por Xcode MCP, selección focal y comprobación de variantes; fallback global solo si selección omite casos.
Builds Develop/Production por composición común. Estilo Authoring/Audit en Swift tocado. Renderizar e inspeccionar ambas
pantallas Large/XXX Large/AX5 con estados/apariencias representativos; snapshots0/250, error y sin resultados adicionales.
Smoke táctil en demo: entrar Catálogo, buscar, alta inválida→válida, editar/descartar, cancelar/confirmar desactivación,
editar inactivo, reabrir y reset. No UI tests nativos. PRE antes de código y POST estándares/accesibilidad independientes.

## Accesibilidad progresiva y límites

ADR0029: construcción accesible, previews y smoke funcional obligatorios. Registrar55criterios y cada condicional;
Inspector, medición de contraste y matriz runtime de VoiceOver/VoiceControl/SwitchControl/FKA, preferencias/iPad/RTL
quedan en issue nueva de fase09, responsable Jesus Franco, relacionada con PLU-53. Recuperar tras feedback/estabilización
del flujo y antes del primer candidato para uso real. Conservar Pendiente/Limitado; no absorber deuda08 ni cerrar fase09.

## Alternativas, fuentes y riesgos

Reutilizar controles nativos y patrones ClientListScreen/ClientFormScreen del repo reduce infraestructura. Se prefiere
confirmationDialog nativo para dos decisiones cortas frente a copiar el sheet extenso de consentimiento. Solo cambiar
si preview/runtime demuestra bloqueo funcional. No crear Store/router genérico ni catálogo comercial provisional.
Fuentes: contratos09.3, spec09, ADR0011/0022/0029/0030 y componentes nativos ya compilados. Verificar documentación Apple
actual ante cualquier API dudosa; no se propone API nueva/deprecated ni elevar target.
Riesgos: pérdida de borrador al cancelar/desactivar, sheet obsoleta, inactive invisible, nombre truncado en AX5,
preview inconsistente y seed filtrado a fixtures/live. Mitigación: tests semánticos, confirmaciones y smoke; reversión
sin migración. Fuera: Domain/Data/schema/sync, stock/mínimos, Service/precios, IA, ventas, foto y nuevas dependencias.

## PRE independiente

PASS tras precisar cierre interactivo permanentemente deshabilitado (únicoP2 documental resuelto).
Root verificó562/562 archivos idénticos en ambos pases; PRE2 `/tmp/franalonso-09-4-pre2.json`, SHA256
`f5566b475dd31e5e8d6f2c09c4734af89cf4258753a5be9617f7dbf8e9833a7e`.
Fuentes Apple: [interactiveDismissDisabled](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:))
y [confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)).
Implementación autorizada; deuda accesible nueva [PLU-54](https://linear.app/plusprojects/issue/PLU-54), Jesus Franco.
