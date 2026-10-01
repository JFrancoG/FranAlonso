# 11.6 — Selector de servicios en el borrador de venta

Estado actual02/10/2026: PLU-78 Done funcional segúnADR0029,
[PR38](https://github.com/JFrancoG/FranAlonso/pull/38) MERGED (`fcb0a6e` → `9f38731`), árbol idéntico y rama eliminada.
PLU-79 Backlog/Jesus Franco y fasePLU-71 activa. El registro inicial y las decisiones se conservan a continuación.

2026-10-01. [PLU-78](https://linear.app/plusprojects/issue/PLU-78), In Progress/Jesus Franco;
rama `codex/plu-78-sale-service-selection` desde main limpio/sincronizado `0d9b06f`.
El usuario autoriza abrir issue/rama e implementar11.6. No entrega Git, cierre, siguiente subfase ni live.

## Autoridad y baseline

Constitución, spec11/11.6, contratos10.7, política Swift, ADR0011/0016/0018/0022/0029/0030/0031 y guía de desarrollo.
Perfil maintenance; Swift6, concurrencia complete, aislamiento default nonisolated, iOS27 y warnings como errores.
Xcode MCP estable, Service `workspace-PfnUYLlMzY` apunta a este proyecto; Develop/planDevelop,
iPad Pro13-inch(M5) Simulator27.2 activos. Restaurar esa selección al finalizar.
11.5 entregada por PR37: fuente/configuración576 `5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`,
regresión1.231 declaraciones/1.934 variantes, builds Develop/Production, PRE/estilo/POST/entrega PASS.
Reutilizar baseline exacta; no atribuir esa evidencia a11.6. PLU-71 activa y PLU-77 conserva deuda11.5.

## Resultado y contrato

- Borrador creado/recuperado y editable muestra Añadir servicio. Inspección readonly, sesión cerrada, creación aún
  no aceptada y operación ocupada no permiten abrir ni incorporar. El selector es una sheet con identidad propia.
- Catálogo local observado sobre el mismo ServiceRepository de App: búsqueda por nombre y filtros Todos/Profesional/
  Producto, activos exclusivamente; loading/vacío/sin coincidencias/fallo y reintento diferenciados. Cancelar no escribe.
- Tocar un servicio solicita explícitamente añadir una unidad. La intención captura antes del primer await ID/nombre,
  precio y moneda exactos, IVA, descuento opcional (nil distinto de0) y linkedProductID. SaleLine ya representa esos
  campos; no añadir type/status del catálogo ni modificar schema. Cantidad posterior usa los controles de11.5.
- Selección se resuelve por ID contra el último snapshot visible10.7. No promete CAS entre actores de Services/Sales,
  revalidación de Product/stock, reserva ni vigencia de una inactivación todavía no observada. Cambios posteriores del
  catálogo no refrescan líneas aceptadas. Una nueva selección del mismo servicio crea otra identidad independiente.
- SaleLine recibe una factory pura de captura de Service activo, cantidad positiva e identidad suministrada. No nuevo
  UseCase/Repository/actor/Store ni aritmética: aceptación por SaleDraftViewModel.addLine→Store→UpdateSaleDraftUseCase.
- Nuevo SaleServicePickerViewModel coordina únicamente vida del selector e incorporación: conserva ServicePickerViewModel
  de10.7 como fuente del catálogo, sin copiarlo ni copiar venta/totales. App inyecta capacidades MainActor canAdd/addLine
  de la fachada conservada. Captura un intento SaleLine con ID estable; requested/adding/failure/accepted/closed
  excluyen dobles toques y cercan resultados tardíos. Retry crea request ID nuevo, conserva línea/términos originales.
- Las tareas pertenecen a Screen mediante task(id:); observación y escritura independientes. Cerrar selector invalida
  su publicación y cancela tareas del caller, sin descartar ni cerrar el Store padre. Aceptación durable conserva éxito
  después de cancelar/cerrar; no convertir un éxito aceptado en fallo reintentable. Fallo preaceptación conserva venta.
- SaleDraftViewModel posee destino identificable y finish por UUID vigente. App fabrica el selector sobre catálogo
  compartido y fachada padre; Workday/SaleDraft pasan factories concretas. Ninguna View captura datos comerciales,
  filtra, calcula o persiste. Sheet navega/cierra por resultado semántico; no presenta UUID al usuario.

## UI y accesibilidad

Controles SwiftUI nativos, nombres/tipo/importe y texto explicando incorporación de una unidad. Filas Button con hit area
completa y mínimo44pt, wrapping y jerarquía; label visible coincide con nombre accesible, decoración oculta.
Searchable y Picker nativo, no precio editable/editor extra. Estado textual de carga/incorporación/error y retry.
Retorno de foco al botón Añadir tras cerrar sheet; anuncios de aceptación/error sin timers ni bucles de foco.
Una View por archivo y preview propio con trait in-memory compartido. Screen más Content y fila de selección nuevos;
Content parametrizado permite renders deterministas de estados sin esperar observación al primer frame.
Nueva matriz55 completa, deuda propia vinculada/Jesus Franco según ADR0029; recuperar tras feedback/estabilización del
flujo, antes del primer candidato para uso real. No hereda PASS integral ni absorbe PLU-77/65/67.

## Áreas previstas

- Sales/Domain: `SaleLine+ServiceSelection.swift`, factory de snapshot, sin cambiar representación/DTO.
- Sales/Presentation: nuevo `SaleServicePickerViewModel`, destino del selector, Screen/Content/fila; fachada/detalle
  editable y propagación de factories en Workday. Sin otra copia del borrador.
- App: factory en extensión Sales, shell y previews de selección sobre el catálogo/demo ya sembrados.
- Localizable.xcstrings ES/EN, inventario, tests focales, matriz, propuesta, Progress/spec/fase/Linear.
- Data, modelos persistentes, schema, sync, configuración de build y fixtures de arranque permanecen fuera del cambio.

## Alternativas y riesgos

1. Duplicar catálogo/venta en un Store nuevo: descartado; ya existen las fuentes y la aceptación local causal.
2. Resolver Service y construir la línea en View: descartado por ADR0011; la intención pertenece al ViewModel/Domain.
3. Añadir estados de escritura al ServicePickerViewModel genérico: descartado;10.7 es read-only y reutilizable,
   la aceptación de Sales tiene sesión/errores/retry propios. El coordinador nuevo expresa esa responsabilidad real.
4. Reconsultar catálogo antes de cada retry: descartado; cambiaría los términos de una intención ya capturada y no
   garantiza atomicidad entre actores. La política visible10.7 y snapshot estable delimitan la garantía real.
5. Editar cantidad/precio antes de añadir: no necesario para11.6; unidad inicial y editor de cantidad existente bastan.

Riesgos comprobables: aceptar dos veces un doble toque; UUID cambiado al retry; cerrar Store al abrir sheet anidada;
resucitar picker cerrado con resultado tardío; moneda incompatible; catálogo observado modificado; ocupación o cierre
de fachada entre request y aceptación. Tests y smoke separan lectura, captura, aceptación durable y publicación UI.
No excepción arquitectónica/unsafe, dependencia, target, activación cloud ni ampliación material.

## TDD y validación

Swift Testing con tests-de-verdad: RED funcional sobre contratos nuevos (stubs mínimos compilables), no falla de setup;
GREEN y suites afectadas. Oráculos literales/pipeline real, ModelContainer in-memory, señales/continuations sin sleeps.
Casos: snapshots profesional/producto EUR/USD y descuento nil/0; cambio de catálogo tras capturar/aceptar/reabrir;
ID no visible/cancel sin write; double tap/retry mismo ID; fallo local/términos preservados; readOnly/closed/noDraft/busy;
cancelación anterior y aceptación tardía cerrada sin republicación; composición App con mismos repositorios.
Reutilizar tests10.7 y Store/fachadas para invariantes ya cubiertas; no tests ceremoniales de copia, enum o conformidad.

Xcode MCP: RED focal, GREEN focal y regresión de Sales/Services/App; full plan final si el impacto de composición lo
justifica. Builds Develop/Production con logs completos, warnings Swift/Clang cero y notices metadata separados.
Estilo independiente changed Swift antes de validación final; POST técnico y UI frescos read-only con JSON completo
tracked+untracked no ignorados idéntico antes/después. Root conserva huella y solo escribe fuera de esas auditorías.
Previews representativos Large/XXX/AX5 ES/EN: detalle con botón, selector contenido profesional/producto, vacío/error/
sin resultados y filas largas. No acreditan AT/Inspector/contraste físico.
Smoke Simulator: crear→abrir/cancelar (sin write)→buscar/filtrar→añadir profesional/producto→dos líneas independientes→
cerrar/reabrir→editar catálogo y verificar snapshot, cambiar cantidad existente; abrir sheet no cierra detalle.
Reconciliar docs/Linear como implementación local In Progress; no commit/push/PR/merge/cierre autorizado en este turno.

## Fuentes primarias

Cupertino MCP leído: [Apple modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations)
para presentación declarativa por Binding/item. APIs task/id, Observation y controles nativos ya compatibles en la
fuente validada y SDK real; validar compilación/ejecución del nuevo ciclo, sin extrapolar eventos de desaparición.
Fuentes/invariantes de persistencia y precisión de ADR0016/0018/0031 y contratos10.7 vigentes, sin cambiar políticas.

## Gate PRE

selection_pre, agente nuevo ios-standards-reviewer, PASS sin hallazgos antes de código. JSON completos735 idénticos
antes/después y verificados por root: `a8705ba560f51217749d625a6916b7fbe1073eef99247266a109612c3d17756f`.
Revisadas alternativas, fuentes y contratos reales; sin excepción ni ampliación material. La instrucción actual
autoriza la implementación11.6 descrita. Orden de desaparición de sheet y éxito tardío quedan como comprobaciones
obligatorias; documentación Apple no demuestra esos eventos runtime. Tests/builds/smoke11.6 todavía pendientes.

## Corrección focal propuesta: superficie del filtro

Smoke Simulator01-10 demuestra que el Picker menú standalone informa un hitPoint central330×31pt sin respuesta;
el valor trailing abre las opciones. Se propone Menu nativo con label propio: nombre, valor actual y chevron,
envoltura adaptable, frame mínimo44pt y contentShape interaction sobre toda la label. Picker nativo inline dentro
del Menu conserva selección mutuamente exclusiva y Binding existente; sin nuevo estado, lógica, navegación ni textos.
Alternativas: frame/contentShape solo fuera del Picker no garantiza su hit area interna; navigationLink añade un
destino para tres opciones; segmented dificulta AX5. No se amplía la subfase ni se toca negocio/Data.
Fuentes primarias Cupertino leídas: [Menu](https://developer.apple.com/documentation/swiftui/menu) y
[MenuPickerStyle](https://developer.apple.com/documentation/swiftui/menupickerstyle); permiten label propia y controles
nativos en menús. No prueban área efectiva: requiere PRE independiente antes de código, build/style y retest del
hitPoint central, filtro y selección, seguido por POST UI. Reutilizar tests de negocio si su fuente permanece intacta.


PRE focal selection_filter_pre PASS sin hallazgos adicionales; whole746JSON íntegros verificados por root,
`f6eee87e30ea9c31d2c8a2d4066173d25afe35cb0a8bb12ad49d681534202103`. Corrección implementada sólo en Content;
label adaptable con frame/shape internos, Picker.inline y mismos recursos/Binding. Estilo focal PASS whole746:
`3398847253ef2909477b9c99ca1eb7826bd3f2d6285e97233a011cc9246215ce`. Builds finales Develop-for-testing23.962s y
Production19.288s PASS; retest real y previews posteriores pendientes. Ninguna semántica de negocio ni test cambia.


## Adaptación focal ante fallo de previews

Tras retest táctil PASS8checks/18eventos del Menu, RenderPreview falla con AttributeGraph: source attribute invalid
(saw DisplayList, expected LayoutComputer). Reproducido en iPhone18ProMax e iPadPro13M5, fuente sin cambios;
no se atribuye causa al framework ni se extrapola éxito runtime estándar a AX5. Se propone sustituir exclusivamente
ViewThatFits por disposición explícita según DynamicTypeSize.isAccessibilitySize: VStack para AX y HStack con texto
multilínea para tamaños estándar. Se conservan Menu/Picker/Binding, shape/frame44, labels/valores y texto; no negocio.
Alternativa: insistir en previews sin cambiar fuente ya falló en varios procesos/destinos; no constituye evidencia.
Usar entorno de texto para layout es presentación declarativa. Requiere revisión independiente focal antes del patch,
style/build/previews Large/XXX/AX5 y retest central posterior; ningún cambio de contratos exige otra regresión lógica.


## Resultado de las adaptaciones focales

PRE de Dynamic Type PASS antes del cambio; whole746 idéntico
`83302830cae8341b3a536e1d806062f1f8d5db1d221cb119078427d40db60150`.
Cambiar ViewThatFits por disposición según isAccessibilitySize no resolvió el fallo de Canvas. Tampoco lo hizo
ocultar el separador tras otro PRE focal. Ambos resultados negativos se conservan; no demuestran una causa interna.
La disposición explícita AX vertical se mantiene por su legibilidad. El modifier de separador experimental se retiró.

PRE de ubicación PASS: whole746 idéntico `120e9586dcbcd4e8a4828e8865d415af6c130e9167bd792498aa71fdfa8c9661`.
Menu pasa fuera de las filas de List a un VStack superior con padding; instrucción, estados, errores y catálogo
permanecen desplazables. Se conservan Picker/Binding, label/valor, mínimo44 y shape. Se descarta Section.header por
introducir semántica/pinning innecesarios. Esta composición sí renderiza: iPadLarge y iPhoneLarge/XXX/AX5 ES/EN,
Light/Dark, sin crash ni recorte del filtro. Estilo focal PASS con whole746 idéntico
`e52b75ec2bb616d1380a096a63b84ff3047940175092c8b1209889af2f033177`.
La correlación del cambio y los renders no atribuye una causa interna a AttributeGraph.

PRE de contexto de previews PASS sobre ese mismo whole746: los cuatro estados Content secundarios se alinean con
NavigationStack/título del selector real, conservando fixtures y bindings. Su contexto standalone omitía el Menu en
las capturas; es un P3 de representatividad, sin defecto funcional demostrado. Cuatro renders propios tras el ajuste PASS, Menu visible; fixtures intactos.
Estado final y auditorías al cierre en [fase11](phase-11.md); ninguna corrección altera contratos o amplía11.6.

Estilo de los cuatro previews PASS, whole746 íntegro `c325d8274c81c3c34bdd067933890cf042ce1b8d700b2a79a4b06fb56a7dc49e`.

PRE correctivo de POST UI PASS: anuncio unavailable por mismo onChange/announce y encabezados de3títulos del
catálogo, sin cambio de estado/textos/foco. Construcción implementada, estilo/builds/previews focales PASS; retestUI
independiente pendiente. La entrega de anuncios y geometría/traversal de controles nativos siguen enPLU79.


## Dictamen local final — 2026-10-02

POST técnico y UI focal PASS sin hallazgos restantes para el gate funcional ADR0029; proof whole746 intacto
`bf27ceb314e985aaaa3dcd5f620244102c7c0236aab0110a1dfb08770518ee7d`.
Construcción/validación técnica/previews/smoke terminados. Entrega Git pendiente; PLU78 In Progress, fasePLU71 activa,
PLU79 Backlog/Jesus Franco con validación integral antes del candidato real. Fuente/evidencia detalladas en fase11.


Entrega autorizada el02/10/2026: el usuario solicita commit, push, PR, merge y cierre dePLU78/rama.
La preparación sólo actualiza documentación/changelog; fuente586 íntegra igual a validación final.
DeudaPLU79 y fasePLU71 permanecen abiertas; no autoriza11.7 ni live.

Entrega completada el02/10/2026: commit/push `fcb0a6e`, PR38 MERGED como `9f38731`, árbol y fuente586 idénticos.
Rama local/remota eliminada tras verificar ancestry y ausencia de commits únicos. Revisión focal de entrega PASS,
proof whole746 intacto `03cd4722a43626051376e394d9bf9639d7b98163ad512a1020b100bde2ecfb88`.
PLU-78 Done funcional, fase11 In Progress, PLU-79 conserva matriz/recuperación antes del candidato real.
Cierre documental en main, sin cambios ejecutables; evidencia y límites en [fase11](phase-11.md).
