# Evidencia de accesibilidad — 08.3 listado, búsqueda y formulario de clientes

Fecha del registro inicial: 2026-09-08. Estado: **evidencia parcial; puerta ADR 0022 abierta**.

Alcance: [PLU-37](https://linear.app/plusprojects/issue/PLU-37), subfase 08.3. Este documento aplica
[ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) y la
[matriz WCAG 2.2 A/AA para iOS](../WCAG22_AA_IOS.md) a las dos pantallas modificadas y al recorrido que las cruza.
Es un objetivo interno basado en WCAG2ICT y convenciones Apple, no una certificación ni una declaración legal de
conformidad. La evidencia previa de componentes o del shell no acredita automáticamente sus nuevas composiciones.

## Autoridad y superficies evaluadas

- **L — Listado:** `ClientListScreen`, `ClientListContent` y `ClientRow`. Incluye carga, fuente vacía, lista con
  contenido largo y 80 clientes, búsqueda, ausencia de coincidencias, fallo/reintento, alta desde toolbar y edición
  desde una fila. La búsqueda nativa consume resultados derivados del ViewModel; no introduce validación sintáctica
  de la consulta ni una petición remota por tecla.
- **F — Formulario:** `ClientFormScreen`, `ClientFormContent` y `ClientFormFieldsContent`. Incluye alta como borrador,
  edición de nombre obligatorio y cinco campos opcionales, carga, validación, fallos, guardado, desactivación y su
  confirmación. Guardar y Cancelar son explícitos; el cierre interactivo está deshabilitado. El formulario representa
  los estados y errores semánticos del ViewModel, sin mostrar errores de SDK.
- **Componente compartido afectado:** `FormFieldSection` recibe el ajuste mínimo de crecimiento vertical necesario
  para conservar completo su label a AX 5. La corrección pertenece a la composición de F/X y requiere revisar las
  demás superficies que reutilizan el componente; no se extrapola a ellas un pase por el render del formulario.
- **X — Flujo transversal:** shell → Clientes → alta → validación → guardar → búsqueda → edición → cancelar →
  reapertura → guardar cambios → confirmar/cancelar desactivación → regreso al listado. Incluye identidad de sheet,
  foco de entrada y retorno, conservación de consulta/campos, anuncios, acciones ocupadas y actualización observada.
  La integración nueva se evalúa con el chrome compartido; no se reabre funcionalmente autenticación ni las otras
  secciones del shell.
- La [spec 08](../../specs/08_clients_consent.md) y la
  [propuesta aprobada](../../progress/phase-08.md#inicio-de-083--propuesta) delimitan el cambio. Firma, consentimiento,
  activación, foto, detalle, Storage y capacidades live quedan fuera de esta subfase.
- [ADR 0026](../../ADRs/0026-iphone-portrait-only-product-exception.md) mantiene iPhone solo portrait como excepción de
  producto aceptada. **1.3.4 se registra Aplicable/No pasa**, sin alegar necesidad esencial ni usar N/A. iPad conserva
  la exigencia de todas sus orientaciones y ventanas; esa evidencia no compensa la restricción iPhone.

## Fuentes inspeccionadas

La palabra **Inspección** en este registro significa lectura del código y del catálogo. No significa Accessibility
Inspector, árbol accesible observado, locución ni operación runtime.

- [Listado y sheet](../../../FranAlonso/Features/Clients/Presentation/Screens/ClientListScreen.swift),
  [estados del listado](../../../FranAlonso/Features/Clients/Presentation/Views/ClientListContent.swift) y
  [fila Button](../../../FranAlonso/Features/Clients/Presentation/Views/ClientRow.swift).
- [Pantalla del formulario](../../../FranAlonso/Features/Clients/Presentation/Screens/ClientFormScreen.swift),
  [contenido](../../../FranAlonso/Features/Clients/Presentation/Views/ClientFormContent.swift),
  [campos](../../../FranAlonso/Features/Clients/Presentation/Views/ClientFormFieldsContent.swift) y
  [mensajes semánticos](../../../FranAlonso/Features/Clients/Presentation/ViewModels/ClientFormFeedback.swift).
- [FormFieldSection](../../../FranAlonso/Shared/Presentation/Components/FormFieldSection.swift),
  [LoadingStateView](../../../FranAlonso/Shared/Presentation/Components/LoadingStateView.swift),
  [UnavailableStateView](../../../FranAlonso/Shared/Presentation/Components/UnavailableStateView.swift) y
  [catálogo español](../../../FranAlonso/Resources/Localizable.xcstrings).

La inspección encuentra controles SwiftUI nativos, texto localizado, labels de entrada persistentes y `textContentType`
para nombre y dirección cuando existe un propósito compatible. El identificador fiscal conserva label explícito sin
inventar un tipo de autofill o una validación fiscal. Los campos y filas declaran altura mínima de 44 pt; esto no
demuestra por sí solo las dimensiones completas ni la superficie realmente operable de cada objetivo.

El nombre inválido tiene mensaje textual, hint condicional y solicitudes de foco de teclado/accesible. El código emite
notificaciones para cambios y resultados importantes. Estas declaraciones no acreditan que el anuncio se oiga una sola
vez, que no se interrumpa al cerrar la sheet ni que el foco termine en un elemento correcto. Todo ello queda pendiente
de operación real con cada tecnología pertinente.

## Evidencia de compilación y lógica

Evidencia comunicada por el orquestador, Xcode MCP, `FranAlonso-Develop`, 2026-09-08:

- Primer build de la implementación: **PASS, 11,897 s**. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-155134.txt`.
- Build después de corregir el recorte del label compartido: **PASS, 13,979 s**. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-160220.txt`.
- GREEN focal: **20/20 resultados** en `ClientScreenCompositionTests`, `ClientFormCompositionTests` y
  `AppDependenciesTests`; incluye **8 casos nuevos** de composición. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/4C445747-9053-4F3E-A2DD-B7E16421D532.txt`.
- Regresión focal de **32 suites: 259/259 resultados aprobados; 0 fallidos, omitidos o no ejecutados**, en iPhone 11
  físico. Incluye casos parametrizados; no son 259 declaraciones `@Test`. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/374AC178-95F3-462D-B95E-D4DD746CE2A3.txt`.
  Un intento anterior se canceló cuando el test de previews esperaba la terminación de una observación que ahora es
  continua. Se retiró esa expectativa obsoleta y se añadió un límite temporal a la suite; la repetición completa
  acredita el resultado final. Los nuevos tests de composición comprueban las actualizaciones sucesivas.
- Build del simulador verificado, **iPhone 17e / iOS 26.5**, **PASS, 22,365 s**, con salida
  `Debug-Develop-iphonesimulator`. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-161108.txt`.
- Build final de Develop tras restaurar el destino iPhone 11: **PASS, 12,07 s**. Artefacto:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-162602.txt`.
- Los casos nuevos comprueban que crear, editar y desactivar mediante la capacidad pública actualiza la observación
  del mismo contenedor y produce una sola operación pendiente por mutación; las composiciones de solo lectura
  rechazan escritura sin mutar el contexto. No prueban interacción UI, foco, hit areas ni tecnologías de asistencia.
- El argumento signed-out editado inicialmente en el archivo del scheme no había actualizado su checkbox en Xcode.
  Por ello no se atribuye al host de esos tests una ejecución in-memory a partir del archivo; los tests construyen
  sus propias fixtures aisladas. Para el recorrido R01 posterior sí se comprobó la activación en la UI del IDE y
  se relanzó la app con esa configuración.
- No se declara ReleaseGate global, Production ni cero warnings agregados: los logs incluyen avisos de App Intents
  y del host/herramientas ya identificados. Un build o test aprobado no equivale a una pasada accesible.

## Manifiesto de previews y runtime

El [manifiesto local de 19 capturas](/tmp/franalonso-083-preview-manifest.json) conserva las rutas devueltas por
RenderPreview. La tabla distingue las capturas anteriores a las correcciones de las que las verifican. Todas las
observaciones visuales que siguen fueron comunicadas por el orquestador; el agente documental no las presenta como
una operación propia con tecnologías de asistencia.

Xcode mostraba Canvas **Automatic — iPhone 17 Pro**. No quedó acreditada la versión de iOS efectiva de cada preview;
no se deduce del SDK 26.5 ni del simulador usado después para R01. Las variantes siguientes corresponden a las
solicitudes de RenderPreview registradas por el orquestador; la lista `supportedPreviewVariantOverrides` del
manifiesto describe capacidades, no una confirmación de la variante efectiva. Las capturas son portrait y solo
acreditan su viewport visible. No existe todavía cobertura completa de todas las combinaciones por pantalla.

| ID | Superficie y variante solicitada | Artefacto inspeccionado | Resultado visual y límite |
|---|---|---|---|
| P01 | Pantalla alta; Large / Light solicitados; contraste efectivo no registrado | [RenderPreview_result_2026-09-08T135406Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135406Z@3x.png) | Alta y campos visibles. La captura no demuestra el recorrido completo ni AT. |
| P02 | Pantalla edición; AX 5 / Dark / contraste incrementado | [RenderPreview_result_2026-09-08T135813Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135813Z@3x.png) | Solo capturó carga. Título inline «Editar clien…» truncado; pendiente verificar la pantalla cargada a AX 5. No acredita campos. |
| P03a | Listado vacío; Large / Light / contraste normal | [RenderPreview_result_2026-09-08T135855Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135855Z@3x.png) | Estado vacío visible. |
| P03b | Listado con nombre largo; XXX Large / Dark / contraste normal | [RenderPreview_result_2026-09-08T135901Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135901Z@3x.png) | Nombre largo con crecimiento vertical. Solo viewport visible. |
| P03c | Listado de 80 clientes; AX 5 / Light / contraste incrementado | [RenderPreview_result_2026-09-08T135907Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135907Z@3x.png) | Filas multilínea visibles. No acredita desplazamiento u operación de las 80 filas. |
| P03d | Sin coincidencias; Large / Light / contraste normal | [RenderPreview_result_2026-09-08T135913Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135913Z@3x.png) | Estado vacío por búsqueda visible. Anuncio no escuchado. |
| P03e | Error de listado; AX 5 / Dark / contraste incrementado | [RenderPreview_result_2026-09-08T140004Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140004Z@3x.png) | Título, mensaje y Reintentar visibles. No se operó el reintento en esta captura. |
| P03f | Carga de listado; Large / Light / contraste normal | [RenderPreview_result_2026-09-08T140010Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140010Z@3x.png) | Indicador y texto visibles. No acredita duración, transición ni anuncio. |
| P04a-antes | Contenido edición larga; AX 5 / Dark / contraste incrementado | [RenderPreview_result_2026-09-08T140023Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140023Z@3x.png) | Obsoleta para evaluar el código corregido: label de nombre recortado, hallazgo que motivó el ajuste compartido. |
| P04b | Validación de nombre; XXX Large / Light / contraste incrementado | [RenderPreview_result_2026-09-08T140024Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140024Z@3x.png) | Mensaje completo junto al campo. No acredita hint oído ni foco accesible. |
| P04c | Fallo inicial del formulario; Large / Dark / contraste normal | [RenderPreview_result_2026-09-08T140108Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140108Z@3x.png) | Mensaje y Reintentar visibles; recuperación runtime pendiente. |
| P04d-antes | Fallo de guardado; Large / Light / contraste incrementado | [RenderPreview_result_2026-09-08T140110Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140110Z@3x.png) | Obsoleta: el error quedaba fuera del primer viewport. Sustituida por P04d tras adelantar la sección de error. |
| P04e-antes | Guardando; Large / Light / contraste normal | [RenderPreview_result_2026-09-08T140111Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140111Z@3x.png) | Obsoleta: el progreso quedaba fuera del primer viewport. Sustituida por P04e tras adelantar esa sección. |
| P04f | Contenido alta; XXX Large / Light / contraste normal | [RenderPreview_result_2026-09-08T140113Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140113Z@3x.png) | Aviso de borrador y campos visibles. Solo acredita el viewport. |
| P04a-caché | Contenido edición larga; AX 5 / Dark / contraste incrementado | [RenderPreview_result_2026-09-08T140146Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140146Z@3x.png) | Obsoleta: render anterior a recompilar, todavía recortado. No se usa como evidencia de la corrección. |
| P04a | Contenido edición larga; AX 5 / Dark / contraste incrementado | [RenderPreview_result_2026-09-08T140258Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140258Z@3x.png) | Después del build: label obligatorio completo gracias a crecimiento vertical. No acredita campos inferiores ni toolbar de Screen. |
| P04d | Fallo de guardado; Large / Light / contraste incrementado | [RenderPreview_result_2026-09-08T140902Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140902Z@3x.png) | Error visible en la primera sección del formulario. No acredita anuncio ni recuperación. |
| P04e | Guardando; Large / Light / contraste normal | [RenderPreview_result_2026-09-08T140904Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140904Z@3x.png) | Progreso visible en la primera sección del formulario. No acredita el estado transitorio con AT. |
| P04g | FormFieldSection compartido; AX 5 / Light / contraste normal | [RenderPreview_result_2026-09-08T140925Z@3x.png](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140925Z@3x.png) | Label completo; valor de correo de una sola línea conserva el recorte nativo. No acredita todas las pantallas consumidoras. |

### Correcciones de auditoría y renders posteriores

La auditoría independiente señaló dos P2: título inline recortado a AX 5 (1.4.4) y contraste del texto de progreso
en P04e (1.4.3). El primero es independiente de la carga; no bastaba esperar al formulario. Se usa título nativo
grande y se aplica `TextPrimary` al label de progreso. Build Xcode MCP **PASS, 7,686 s**, Develop/iPhone 11,
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-163708.txt`.
GetBuildLog warning sin entradas (`875B3B13-AF51-496F-A54B-2DDDCF449D0C.txt`); el log completo mantiene AppIntents
en línea 10917. Los dos ajustes son visuales; no se repiten los tests lógicos 259/259, y se comprueban build y renders.

Se añaden **7 capturas**, **26 en total**, en el
[manifiesto correctivo local](/tmp/franalonso-083-corrective-preview-manifest-final.json). P02 queda sustituida para
evaluar el título, y P04e para el contraste del texto. Sus límites históricos permanecen documentados.

| ID | Variante solicitada | Artefacto inspeccionado | Resultado y límite |
|---|---|---|---|
| C01 | Screen edición, AX 5 / Dark / contraste incrementado | [143801](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143801Z@3x.png) | Título «Editar cliente» completo. Captura carga; no acredita formulario cargado ni navegación/scroll con AT. |
| C02 | Screen edición, Large / Light / contraste normal | [143803](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143803Z@3x.png) | Título completo, Cancelar/Guardar y campos precargados visibles; provincia comienza al pie del viewport. |
| C03 | Guardando, Large / Light / contraste normal | [143816](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143816Z@3x.png) | Texto de progreso visible y oscuro sobre blanco. |
| C04 | Guardando, Large / Light / contraste incrementado | [143818](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143818Z@3x.png) | Texto de progreso negro sobre blanco. |
| C05 | Guardando, Large / Dark / contraste normal | [143819](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143819Z@3x.png) | Texto de progreso blanco sobre superficie oscura. |
| C06 | Guardando, Large / Dark / contraste incrementado | [143821](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143821Z@3x.png) | Texto de progreso blanco sobre superficie oscura. |
| C07 | Consumidor compartido LoginContent, AX 5 / Light / contraste normal | [144034](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T144034Z@3x.png) | Labels Email y Contraseña completos. No se atribuye a Login una nueva pasada funcional ni AT. |

Muestreo raster de C03–C06: PNG RGB sin ICC interpretado como sRGB, región del texto `(51,238)–(344,273)` en
capturas 689×1500, color de fondo modal y color de texto frecuente. Ratios aproximados **18,71 / 21,00 / 17,01 /
15,49:1**, respectivamente; el antialiasing no se interpreta como color de diseño. Registro reproducible de valores
y rutas: [muestra de contraste](/tmp/franalonso-083-progress-contrast.json). Es evidencia de esas capturas, **no
Inspector ni medición completa de todos los textos/controles del formulario**. La reauditoría focal confirma la corrección de ambos P2.

**P05 — Matriz visual:** Large / XXX Large / AX 5 y Light / Dark con contraste normal / incrementado tienen muestras
anteriores, sin una pasada de todas sus combinaciones en cada Screen cargada. **P06 — Adaptación adicional:** orientaciones y ventana mínima iPad confirmadas por el propietario
(ver R07); layout RTL sintético comprobado en Cierre de evidencia. RTL sintético no equivale a disponer de
una localización RTL.

| ID | Técnica o recorrido requerido | Evidencia actual | Resultado y límite |
|---|---|---|---|
| R01 | Entrada y activación por CUA: alta, buscar, editar, cancelar, validar, guardar, confirmar/cancelar desactivación | Registro runtime del orquestador, iPhone 17e / iOS 26.5, portrait, fixture signed-out activada en la UI de Xcode | Parcial: login sintético → Clientes vacío → alta → Guardar con nombre vacío muestra error → introducir nombre sintético y guardar actualiza la lista → buscar `08.3` conserva la fila → editar fiscal y Cancelar descarta el cambio al reabrir → editar, Guardar y reabrir conserva el dato; consulta conservada tras regresar. No acredita Touch en dispositivo físico, cancelación al levantar fuera ni AT. Desactivación/confirmación pendientes: los intentos de scroll/drag de CUA no movieron el viewport; no se atribuye a un defecto de la app sin demostrarlo. |
| R02 | Accessibility Inspector: listado, campos, toolbar, errores y confirmación | Informes Audit 1 y Audit 2 aportados el 09-09; detalle en registro inferior. Inspection obtiene nombre, rol, acción y jerarquía de Desactivar cliente | Parcial: nueve avisos acumulados en dos informes; pendiente atribución y contraste real. No equivalen a nueve defectos confirmados ni a cero incidencias. |
| R03 | VoiceOver: recorrido completo, rotor, foco, anuncios y restauración | Reportes del propietario el 09-09, iPhone 14 / iOS 26.6.1 | Parcial. Nombres/roles de Añadir, buscador y fila; apertura y recorrido del formulario con etiquetas/valores confirmados. Guardar vacío enfoca el nombre y anuncia la corrección; error desaparece al escribir. Anuncio «Cliente guardado» completo confirmado. Tras los ajustes, alta guardada enfoca la fila recién creada; abrirla y Cancelar restaura esa misma fila. Retornos contextuales válidos en esos recorridos. Guardar edición anuncia el éxito completo, devuelve foco a la misma fila y conserva el cambio al reabrir, confirmado por el propietario. Diálogo de desactivación anuncia alerta, título, contenido y botón Desactivar; cancelarlo devuelve foco a Desactivar cliente del formulario. Desactivación anuncia éxito completo y retorna al mensaje de lista vacía. Cancelar alta vacía vuelve a No hay clientes; Añadir se alcanza con tres deslizamientos a la izquierda y puede reabrirse. Búsqueda parcial permite alcanzar/abrir la coincidencia; consulta sin resultados anuncia Sin coincidencias y borrar restaura el cliente. Rotor por encabezamientos encuentra y anuncia Editar cliente; otros modos no probados. Sin audio ni Inspector. |
| R04 | Voice Control: activación por nombre y entrada/edición de campos | Iniciado por el propietario el 09-09, iPhone 14 / iOS 26.6.1 | Parcial. Mostrar nombres identifica Añadir, buscador, fila, botones y campos con obligatorio/opcional. Alta por voz confirmada: abrir Añadir, activar Nombre, dictar y Guardar; cliente aparece en listado. Edición de Localidad y descarte al cancelar/reabrir confirmados. Desactivación por voz incluida confirmación y desaparición de fila, a la primera. Muestreo representativo completado; búsqueda por voz no ejecutada. Sin audio/Inspector. |
| R05 | Switch Control: escaneo, entrada, confirmación, cancelación y retorno | Reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1, configuración guiada pantalla completa/seleccionar ítem y exploración automática | Muestreo representativo: dos grupos (acciones/buscador y pestañas); selecciona Añadir, abre formulario, recorre controles y Cancelar, vuelve al listado. Sin bloqueo reportado. Entrada de texto y confirmación destructiva no ejecutadas; sin Inspector. |
| R06 | Full Keyboard Access: recorrido, edición, foco visible y salida | Reporte guiado del propietario, 09-09; se indicó iPhone 17e / iOS 26.5 Simulator, teclado del Mac y Acceso total mediante teclado | Muestreo representativo completado: Tab/cursores muestran primer foco, cursores recorren todas las acciones; abre Añadir, escribe, cancela y continúa navegando en listado sin bloqueo. Ajustes no inspeccionados directamente. No acredita dispositivo físico, todos los recorridos, confirmación destructiva ni estados de fallo. No repetir CRUD completo. |
| R07 | Runtime Large / XXX Large / AX 5; iPhone portrait e iPad orientaciones/ventanas | R01 más reportes físicos del propietario en iPhone 14 / iOS 26.6.1 con texto máximo | Parcial. Tras correcciones confirma recorrido de campos, título completo tras scroll, entrada de nombre y Localidad/Provincia con teclado abierto, guardado y descarte mediante acciones compactas. iPad: propietario confirma orientaciones y ventana mínima; CUA posterior identifica iPad Air 11-inch (M4)/iOS 26.5 y muestra formulario estrecho sin solapamientos visibles. No repetir esos recorridos. RTL y otras variantes sin evidencia siguen pendientes. |
| R08 | Increase Contrast, Reduce Motion, Reduce Transparency y Differentiate Without Color | Reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1, las cuatro opciones indicadas juntas | Muestreo combinado confirmado: listado y apertura/cancelación del formulario legibles y operables, transiciones sin problemas. Sin medición de ratios ni inspección directa de ajustes; no se atribuyen todas las combinaciones. Restauración de preferencias habituales indicada, no confirmada. |
| R09 | Carga sostenida, fallos de lectura/escritura y reintentos del formulario con AT | Solo renders P04c/P04d/P04e | Pendiente. No existe fixture runtime aprobada para fallos/latencia del formulario; los previews no sustituyen esta evidencia. |

La fixture Develop estándar aprobada compone datos locales in-memory. R01 comenzó después de comprobar el argumento
signed-out activo en **Edit Scheme → Run → Arguments**, con los otros cuatro argumentos de fixtures desactivados,
y relanzar la app. Una ejecución anterior, cuando el IDE conservaba el argumento desactivado, llegó a Login con error
de configuración; no acredita el recorrido local ni se presenta como prueba in-memory. Todos los datos introducidos
en R01 son sintéticos. El registro no prueba persistencia entre relanzamientos, porque la fixture es efímera.

Al terminar, la conexión nativa de CUA se cerró y se reconectó. La app fixture quedó detenida; el argumento signed-out
se verificó desactivado en la UI del IDE y se restauró el scheme original byte a byte, SHA-256
`102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`, junto con el destino iPhone 11.
Estos límites de la sesión no demuestran una imposibilidad general de completar Inspector, scroll o tecnologías de
asistencia. La evidencia no ejecutada continúa pendiente.

La fixture existente de error del listado no se recupera al reintentar. Si no se pueden demostrar carga sostenida o
fallos del formulario con las capacidades actuales, se conserva esa limitación y la puerta abierta; no se introduce
una fixture nueva o una activación live como efecto lateral de esta validación.

Hallazgos visuales corregidos: el primer contenido de edición AX 5 recortaba el label del nombre. Dos declaraciones
`.fixedSize(horizontal: false, vertical: true)` en `FormFieldSection` permiten su altura natural y el rerender **P04a**
posterior al build confirma el label completo. **P04g** verifica además el label del componente compartido aislado;
**C07** comprueba los dos labels del consumidor LoginContent a AX 5. El título señalado en P02 queda completo en C01/C02.
La revisión visual de estos consumidores no se extrapola a sus recorridos AT. El error general y el progreso de
guardado se adelantaron a los campos; P04d y C03–C06 confirman su visibilidad. El contenido cargado completo a AX 5
continúa pendiente, aunque C01 sí acredita el título corregido.

## Registro ADR 0022 por pantalla y flujo

La tabla contiene las **55 filas** de la matriz vigente y tres evaluaciones separadas por fila: **L** listado,
**F** formulario y **X** flujo transversal. La evidencia compartida solo se atribuye a las superficies expresamente
indicadas. Fecha común: **2026-09-08**. Configuración de inspección: fuentes actuales de 08.3 y catálogo español;
configuración runtime: **R01/R06/R07**, con sus límites expresos. Autor del registro: agente documental a partir de
los resultados comunicados por el orquestador; auditoría y reauditoría focal independientes completadas, con **dos P2 cerrados**. Estas condiciones se aplican a cada fila mientras no exista una referencia P/R más específica.

Leyenda de las celdas:

- `A/L`: Aplicable · Limitado; hay inspección o lógica parcial, pero falta evidencia exigida.
- `A/Pend`: Aplicable · Pendiente; no se ha operado la comprobación requerida.
- `A/Pasa`: Aplicable · Pasa dentro del aspecto verificable por inspección indicado; no amplía cobertura runtime.
- `A/No pasa`: Aplicable · No pasa — excepción de producto aceptada exclusivamente por ADR 0026.
- `N/A`: No aplicable por la razón explícita de esa fila; no se cuenta como prueba ejecutada.

| ID | L | F | X | Justificación, método, evidencia y disposición |
|---|---|---|---|---|
| 1.1.1 | A/L | A/L | A/L | R03/R04 confirman nombres de acciones y campos; controles nativos y decoración oculta por inspección. Cobertura representativa, no inventario Inspector exhaustivo. |
| 1.2.1 | N/A | N/A | N/A | No hay audio o vídeo pregrabado en ninguna de estas superficies. |
| 1.2.2 | N/A | N/A | N/A | No hay audio sincronizado pregrabado que requiera subtítulos. |
| 1.2.3 | N/A | N/A | N/A | No hay vídeo pregrabado que requiera alternativa o audiodescripción. |
| 1.2.4 | N/A | N/A | N/A | No hay contenido audiovisual sincronizado en directo. |
| 1.2.5 | N/A | N/A | N/A | No hay vídeo pregrabado que requiera audiodescripción sincronizada. |
| 1.3.1 | A/L | A/L | A/L | Form y etiquetas persistentes inspeccionados; R03 confirma encabezado y etiquetas/valores sin duplicados reportados. No extrapola a R09. |
| 1.3.2 | A/L | A/L | A/L | R03 confirma secuencia de listado, formulario y confirmación; R05/R06 recorrido representativo y salida. No repetir CRUD por cada tecnología. |
| 1.3.3 | A/Pasa | A/Pasa | A/Pasa | Inspección del copy: buscar, reintentar, nombre obligatorio, guardar/cancelar y desactivar se explican mediante texto. Ninguna instrucción exige reconocer solo posición, forma, color o sonido. |
| 1.3.4 | A/No pasa | A/No pasa | A/No pasa | ADR 0026: iPhone solo portrait sin necesidad esencial. Excepción de producto aceptada, no normativa. R07 acredita por reporte orientaciones y ventana mínima en iPad; no compensa la restricción de iPhone. |
| 1.3.5 | N/A | A/L | A/L | L: el buscador no solicita datos personales para completar un perfil. F/X: nombre y dirección declaran textContentType compatible; fiscal conserva label sin propósito de autofill inventado. Entrada/autofill real pendiente en R01/R03/R06. |
| 1.4.1 | A/L | A/L | A/L | Copy y rol destructivo no dependen solo de color; R08 confirma preferencias combinadas. Estados asíncronos conservan límite R09. |
| 1.4.2 | N/A | N/A | N/A | No se reproduce audio automático; las locuciones de la tecnología de asistencia no son audio de contenido impuesto por la app. |
| 1.4.3 | A/Pend | A/L | A/L | C03–C06 y el muestreo raster apoyan el contraste del label de progreso corregido en cuatro apariencias; no son Inspector. Faltan mediciones del resto del texto normal, secundario, error y controles en sus fondos finales; R02/R08. |
| 1.4.4 | A/L | A/L | A/L | Previews Large/XXX Large/AX 5 y retest físico a texto máximo confirman etiquetas, título tras scroll, entrada con teclado y Guardar/Cancelar. Límites puntuales de render generado constan en histórico; no se exige repetir todos los valores por campo. |
| 1.4.5 | A/Pasa | A/Pasa | A/Pasa | Inspección: todo el copy significativo se representa mediante texto real; los SF Symbols no contienen texto que deba sustituirlo. |
| 1.4.10 | A/L | A/L | A/L | R07 confirma teclado, campos finales, texto máximo, orientaciones iPad y ventana mínima. RTL sintético de lista y formulario inspeccionado en Cierre de evidencia; no acredita localización RTL. |
| 1.4.11 | A/Pend | A/Pend | A/Pend | Pendientes contraste no textual y distinción de búsqueda, objetivos, foco, estados deshabilitados y acción destructiva en sus fondos reales; R02/R08. El rol nativo no es una medición. |
| 1.4.12 | N/A | N/A | N/A | SwiftUI nativo; no existe UI mediante markup con override de espaciado de texto accesible al usuario, según la aplicabilidad de la matriz del proyecto. |
| 1.4.13 | N/A | N/A | N/A | No se añade contenido al hover o al recibir foco. La confirmación requiere una activación explícita y se evalúa como superficie modal en los criterios de foco, teclado y prevención de errores. |
| 2.1.1 | A/L | A/L | A/L | R06 confirma foco y acceso a acciones, alta, entrada y cancelación con teclado del Mac en Simulator; R05 aporta exploración y salida por Control por botón. Muestreo representativo, R09 no ejecutado. |
| 2.1.2 | A/L | A/L | A/L | R05/R06 confirman entrada, recorrido y cancelación sin bloqueo. No se atribuye operación de estados asíncronos R09. |
| 2.1.4 | N/A | N/A | N/A | No hay atajos propios activados por una sola letra, número o signo sin modificador. Las teclas del teclado de entrada son edición nativa. |
| 2.2.1 | N/A | N/A | N/A | No se exige completar búsqueda, edición o confirmación en un tiempo límite ni se descartan campos por timeout de UI. La tarea asíncrona no impone un plazo de interacción. |
| 2.2.2 | N/A | N/A | N/A | No hay carrusel, contenido móvil ni actualización periódica autónoma que deba pausarse. La observación local representa mutaciones y los indicadores nativos representan operaciones en curso; Reduce Motion se verifica adicionalmente en R08. |
| 2.3.1 | A/L | A/L | A/L | Inspección: no se añaden medios intermitentes ni animaciones propias. R08 confirma transiciones con preferencias combinadas; progreso asíncrono mantiene límite R09. |
| 2.4.1 | A/L | A/L | A/L | Inspección: títulos nativos y acceso directo mediante buscador/lista; formulario usa secciones. R03 confirma encabezamiento Editar cliente mediante rotor y acceso al formulario/listado; no acredita todos los modos del rotor. |
| 2.4.2 | A/L | A/L | A/L | R03 confirma Editar cliente como encabezamiento, expandido y colapsado; R07 confirma título completo a texto máximo tras corrección. |
| 2.4.3 | A/L | A/L | A/L | R03 confirma foco de validación, retorno a fila tras editar, fila nueva tras alta y estado vacío tras desactivar. R05/R06 confirman salida sin bloqueo. No extrapolar a R09. |
| 2.4.4 | A/L | A/L | A/L | R03/R04 confirman nombres y activación de acciones del flujo habitual. Reintentos asíncronos mantienen límite R09. |
| 2.4.5 | A/L | N/A | A/L | Listado ofrece lista y búsqueda; R03 confirma coincidencia accesible, apertura, Sin coincidencias y restauración al borrar. Formulario aislado no es colección de destinos. |
| 2.4.6 | A/L | A/L | A/L | R03 confirma etiquetas obligatorio/opcional y valores; rotor encuentra Editar cliente. R04 identifica controles por sus nombres. No es auditoría de todos los modos del rotor. |
| 2.4.7 | A/L | A/L | A/L | R06 confirma foco visible y recorrido con cursores por acciones, alta y salida. No se inspeccionaron directamente ajustes ni todos los estados. |
| 2.4.11 | A/L | A/L | A/L | R06/R07 confirman navegación, teclado abierto y campos finales, texto máximo y ventana mínima. No se acredita combinación exhaustiva ni estados R09. |
| 2.5.1 | N/A | N/A | N/A | No se exige gesto multipunto ni trayectoria precisa; las acciones propias son Button y entrada nativa. El desplazamiento ordinario de lista/formulario no incorpora un gesto custom de trayectoria. |
| 2.5.2 | A/Pend | A/Pend | A/Pend | Pendiente Touch real: apoyar, salir del objetivo y levantar debe cancelar cuando corresponda, sin alta/guardado/desactivación accidental; R01. Button nativo es base de implementación, no una prueba ejecutada. |
| 2.5.3 | A/L | A/L | A/L | R04 confirma nombres de listado/formulario y alta, edición/cancelación y desactivación por voz; coincide con copy localizado. Muestreo representativo completado. |
| 2.5.4 | N/A | N/A | N/A | No se activa funcionalidad mediante agitar, inclinar o mover el dispositivo. |
| 2.5.7 | N/A | N/A | N/A | No hay reordenación ni operación propia que exija arrastrar. Cancelar ofrece salida explícita de la sheet; el scroll nativo no se trata como una acción de negocio por arrastre. |
| 2.5.8 | A/L | A/L | A/L | Inspección: filas/campos y varias acciones declaran minHeight 44; toolbar y confirmación son nativas. Falta medir la superficie operable completa, anchura, separación y activación de cada objetivo; R01/R02. La política 44×44 pt se evalúa separada de 24 CSS px y sus excepciones. |
| 3.1.1 | A/L | A/L | A/L | Catálogo español y locuciones de R03 confirmadas por propietario. No hay localización RTL; el override sintético solo comprueba layout. |
| 3.1.2 | N/A | N/A | N/A | El copy controlado de estas pantallas está solo en español, sin segmentos de otro idioma. Nombres e identificadores introducidos por la persona no añaden una localización ni una política de detección de idioma. |
| 3.2.1 | A/L | A/L | A/L | R03/R05/R06 recorren foco y acciones sin activación involuntaria reportada. Guardar y desactivar requieren intención explícita. |
| 3.2.2 | A/L | A/L | A/L | R01/R03 confirman filtrado local, Sin coincidencias/restauración y edición sin guardado implícito. Guardar/desactivar explícitos. |
| 3.2.3 | A/L | A/L | A/L | R03 confirma recorrido y retornos contextuales de alta/edición/cancelación/desactivación; búsqueda conservada según R01. Sin regresiones reportadas. |
| 3.2.4 | A/L | A/L | A/L | R03/R04 confirman identificación de acciones y campos del flujo habitual; Inspection confirma nombre/rol de Desactivar. R09 no observado. |
| 3.2.6 | N/A | N/A | N/A | No se introduce un mecanismo de ayuda repetido entre estas pantallas. Labels, instrucciones y errores se evalúan en sus criterios específicos. |
| 3.3.1 | A/L | A/L | A/L | R03 confirma nombre inválido, foco, instrucción y recuperación al escribir; errores asíncronos/reintentos pendientes R09. |
| 3.3.2 | A/L | A/L | A/L | R03/R04 confirman buscador, etiquetas obligatorio/opcional y valores. Prompts redundantes eliminados; etiquetas persistentes conservadas. |
| 3.3.3 | N/A | A/L | A/L | R03 confirma instrucción de corrección del nombre y guardado posterior. Errores de persistencia conservan límite R09; query siempre válida. |
| 3.3.4 | N/A | A/L | A/L | Propietario confirma descarte de edición, confirmación destructiva, cancelación exterior/escape y desactivación por VoiceOver/voz. No repetir en todas las tecnologías. |
| 3.3.7 | N/A | A/L | A/L | R01 y propietario confirman precarga, descarte, conservación al guardar y consulta. Tests de fallos no sustituyen R09 con AT. |
| 3.3.8 | N/A | N/A | N/A | Esta subfase no incorpora prueba cognitiva ni modifica autenticación, recuperación o biometría. La evidencia previa de Login no se presenta como una prueba nueva. |
| 4.1.2 | A/L | A/L | A/L | R03/R04 confirman nombres, roles y valores del flujo habitual; Inspection confirma Desactivar. R09 y medición completa de objetivos quedan limitados. |
| 4.1.3 | A/L | A/L | A/L | R03 confirma anuncios completos de guardado/desactivación, error de nombre y Sin coincidencias. Carga/fallos asíncronos mantienen límite R09. |

## Sesión guiada del propietario — iPhone 14

2026-09-08, iOS 26.6.1 informado por el propietario, Xcode 26.6 / Develop y fixture signed-out.
Evidencia comunicada por el usuario, sin captura ni operación de tecnologías de asistencia por el agente:

- Listado vacío; Guardar sin nombre mantiene la sheet, muestra el error y dirige el foco al campo.
- Rellena los seis campos, alcanza Provincia mediante scroll y guarda: vuelve al listado con una sola fila.
  Esta pasada sí alcanza el final del formulario; la limitación CUA de R01 no se reproduce en este recorrido.
- Detecta error persistente después de escribir un nombre válido y cambiar de foco. Se corrige en el ViewModel
  reutilizando la validación Domain; la desaparición del error y su hint depende del mismo estado existente.
  TDD RED reprodujo el fallo; GREEN 32/32 y build PASS documentados en
  [fase 08](../../progress/phase-08.md#prueba-guiada-en-iphone-14-y-recuperación-del-error-de-nombre).
- El propietario repite el caso y confirma: «ha desaparecido al escribir». Corrección visual confirmada
  por su reporte en el iPhone 14. No acredita anuncio VoiceOver, foco accesible, recuperación con AT,
  Dynamic Type extremo ni desactivación. Ninguna fila de conformidad cambia a Pasa por este reporte parcial.

- El propietario confirma guardar el cliente, editar su nombre y cancelar: conserva el nombre original
  tanto en el listado como al reabrir el formulario. Descarte de cambios confirmado en esta sesión;
  no acredita operación con AT ni la confirmación/cancelación de desactivación.

- Reporte posterior: confirma Desactivar y el cliente desaparece del listado. Desactivación efectiva mediante
  UI confirmada por el propietario. En otra apertura no aparece Cancelar dentro del diálogo; tocar Cancelar
  de la edición una vez descarta el diálogo y una segunda vez cierra el formulario. No acredita aún que el
  cliente se conserve tras ese recorrido, foco/anuncios o una vía de cancelación con AT.
- Inspección: el diálogo declara `Button(role: .cancel)` con Text localizado. Apple describe para action sheets
  ancladas en iPhone con iOS 26 la cancelación implícita al tocar fuera, sin botón Cancelar visible
  ([WWDC25](https://developer.apple.com/videos/play/wwdc2025/284/), apartado Presentations).
  El reporte es compatible con ese comportamiento; no se afirma haber observado el tipo de presentación.
  Prueba posterior del propietario: tocar fuera cierra la confirmación, el formulario permanece abierto
  y el cliente sigue en el listado tras cerrar la edición. Cancelación de desactivación confirmada por
  reporte manual en iPhone 14; no acredita foco/anuncios ni operación con tecnologías de asistencia.
  Se ajusta el guion; sin cambios de código ni nuevas pruebas automáticas. AT sigue pendiente.

- El propietario confirma guardar la edición con nombre «Cliente editado 08.3» y ciudad «Sevilla»:
  nombre actualizado en el listado, ambos valores conservados al reabrir y una sola fila para el cliente.
  Evidencia manual en iPhone 14 / iOS 26.6.1; no acredita foco, anuncios ni operación con AT.

- El propietario confirma búsqueda por «editado», estado sin coincidencias con «zzzinexistente083»
  y recuperación del cliente al borrar la consulta, en iPhone 14 / iOS 26.6.1. Evidencia manual sin AT. No acredita anuncios ni foco durante el filtrado.

## Capturas de texto máximo y corrección — 2026-09-09

Capturas del propietario, iPhone 14 / iOS 26.6.1, oscuro, tamaño máximo solicitado en el guion:

| Captura original | Hallazgo visible |
|---|---|
| [IMG_1245.PNG](/Users/jesusf/Downloads/IMG_1245.PNG) | Nombre con placeholder truncado; fiscal con placeholder menor; Nuevo cliente colapsado truncado. |
| [IMG_1246.PNG](/Users/jesusf/Downloads/IMG_1246.PNG) | Calle truncada, postal menor; labels persistentes completos. |
| [IMG_1247.PNG](/Users/jesusf/Downloads/IMG_1247.PNG) | Localidad/provincia con placeholders truncados; labels completos. |
| [IMG_1249.PNG](/Users/jesusf/Downloads/IMG_1249.PNG) | Edición alcanza Desactivar cliente; título colapsado truncado y provincia recortada en placeholder. |

El arreglo anterior C01/C02 no acreditaba el título tras scroll. Se retiran prompts que solo duplicaban la
etiqueta existente, manteniendo título semántico y accessibilityLabel explícito en los seis TextField.
Cancelar/Guardar pasan a símbolos en tamaños AX, con nombres localizados, área mínima declarada y large content viewer.
No cambian ejes de entrada ni se reduce el tamaño de letra. Fiscal/postal con valores largos requieren prueba propia.

Fuentes: [TextField con prompt separado](https://developer.apple.com/documentation/swiftui/textfield/init(_:text:prompt:axis:)),
[large content viewer](https://developer.apple.com/documentation/swiftui/view/accessibilityshowslargecontentviewer(_:)).
Build PASS y método en [fase 08](../../progress/phase-08.md#corrección-visual-tras-capturas-ax-5--2026-09-09).
Manifiesto de renders: [/tmp/franalonso-083-ax5-preview-manifest.json](/tmp/franalonso-083-ax5-preview-manifest.json).

- A01 alta AX 5 oscuro: título expandido, símbolos y nombre obligatorio completos, campo vacío sin prompt repetido.
- A02/A03 alta XXX Large/Large claro: títulos y acciones textuales completos; campos visibles sin duplicación.
- A04 edición AX 5 oscuro: carga completada, título expandido completo, nombre de ejemplo multilínea legible.
- A05 campos AX 5 claro: nombre de ejemplo/label completos y fiscal label visible; resto fuera de viewport.
- Renders inspeccionados, sin Inspector/runtime. No acreditan título colapsado corregido, seis campos operables,
  affordance del campo vacío, nombres/hints efectivos, foco, long press ni activación de símbolos. Pendiente repetir
  esos puntos con el propietario y las tecnologías de asistencia aplicables; no se marca conformidad Pasa.

- Confirmación posterior del propietario el 09-09: «Ahora si, todo correcto y completo», tras el guion de
  relanzar, conservar texto máximo, abrir Nuevo cliente, recorrer campos y escribir nombre. Se acredita por
  reporte manual legibilidad del recorrido, localización/edición del nombre y título completo tras scroll.
  Sin nueva captura ni Inspector. No acredita valores largos en los seis campos, activación de símbolos,
  long press, foco/anuncios o tecnologías de asistencia. Es evidencia parcial R07; no un pase global AX 5.

- Continuación del propietario a texto máximo (09-09): conserva el nombre, escribe Sevilla en Localidad
  y Provincia con teclado abierto, pulsa ✓ Guardar y reabre el cliente; confirma acceso a ambos campos,
  guardado y conservación de los datos. Reporte manual en iPhone 14 / iOS 26.6.1, sin nueva captura.
  No acredita valores largos en todos los campos, Cancelar con ×, long press, foco/anuncios o AT.
  Solo registro documental, build/tests N/A.

- El propietario confirma Cancelar con × a texto máximo (09-09): cambia Localidad de Sevilla a Madrid,
  pulsa ×, vuelve al listado y reabre; conserva Sevilla. Acción y descarte confirmados por reporte manual
  en iPhone 14 / iOS 26.6.1. No acredita long press, valores largos en todos los campos, foco/anuncios o AT.
  Registro documental únicamente, build/tests N/A. Siguiente prueba guiada: VoiceOver en el listado.

- Inicio de VoiceOver comunicado por el propietario (09-09), iPhone 14 / iOS 26.6.1. Se pidió restaurar
  tamaño habitual; categoría exacta no registrada. Anuncios reportados: «Añadir cliente, botón»;
  «Buscar clientes, campo de búsqueda, toca dos veces para editar»; fila con nombre del cliente, «botón,
  abre el formulario de este cliente». Se omite el valor del nombre del registro de evidencia.
  Nombres, roles e instrucciones de esos tres elementos confirmados por reporte, sin audio ni Inspector.
  No acredita apertura, entrada, rotor, foco/restauración, errores o mutaciones con VoiceOver. R03 parcial.
  Registro documental, build/tests N/A; siguiente paso: abrir el cliente y escuchar campos/botones.

- Continuación VoiceOver del propietario (09-09): al abrir el cliente, foco inicial en «Cancelar, botón»;
  después «Guardar, botón», «Editar cliente, encabezamiento», todos los campos y «Desactivar cliente, botón».
  Cada TextField anuncia su etiqueta, obligatorio/opcional, valor si existe, rol campo de texto e instrucción
  de doble toque para editar; informa también del rotor para palabras mal escritas. No se registran valores.
  Cuando el encabezado está colapsado, se lee entre Cancelar y Guardar, conforme al orden visual comunicado.
  Apertura, foco inicial y recorrido lineal confirmados por reporte en iPhone 14 / iOS 26.6.1, sin audio/Inspector.
  La mención del rotor no acredita su uso. No demuestra aún validación, mutaciones ni restauración al salir.
  Registro documental, build/tests N/A; siguiente prueba: retorno y error de nombre vacío con VoiceOver.

- VoiceOver, retorno y nombre obligatorio (reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1):
  Cancelar edición restaura el foco en la fila del cliente desde la que se abrió. Añadir cliente y Guardar
  vacío lleva al nombre; anuncia «Nombre obligatorio, campo de texto, edición en curso, carácter, punto
  de inserción al principio. Escribe el nombre del cliente para poder guardarlo».
  Se acreditan por reporte el retorno de cancelación, foco de validación e instrucción de corrección escuchada.
  Sin audio/Inspector, no se infiere ausencia de duplicados o interrupciones no reportadas. Recuperación al
  escribir, guardado/desactivación y sus retornos, y uso del rotor siguen pendientes. Build/tests N/A, documentación.

- VoiceOver, recuperación y guardado (propietario, 09-09, iPhone 14 / iOS 26.6.1): al escribir
  desaparece el error y al guardar escucha «Cliente guardado». Regresa al listado, pero el foco queda en
  «Cerrar sesión»: defecto de retorno confirmado. Corrección acotada a ClientListScreen: tras cerrar un
  alta, solicita foco VoiceOver en Añadir cliente, con identidad de sesión comprobada y flag consumido
  en onDismiss; edición conserva su retorno nativo. Propuesta independiente PASS, 446 archivos idénticos
  pre/post, SHA-256 `b8dd332c6e29f36a76c92af7c9fa539fb6813c43f90635d8a11f6998bc6f51d5`.
  Build Xcode MCP PASS (8,706 s), Develop / iPhone 14: `BuildProject-Log-20260909-023110.txt`;
  Navigator/GetBuildLog sin issues, log completo mantiene aviso AppIntents (línea 11610).
  Preview de listado inspeccionada: `RenderPreview_result_2026-09-09T003147Z@3x.png`, estado de carga;
  no acredita foco ni anuncios. Tests unitarios no repetidos: ajuste exclusivo de ciclo UI/foco, sin lógica
  de negocio nueva. Pendiente retest físico: alta guardada/cancelada → Añadir, edición cancelada → fila,
  nueva sesión sin foco obsoleto y anuncio completo sin interrupción. Defecto y puerta ADR 0022 abiertos.

- Reauditorías focales finales de retorno VoiceOver: accesibilidad e iOS/estilo PASS, sin hallazgos.
  Read-only operacional verificado por el orquestador: 446 archivos idénticos, SHA-256
  `cb18d5179a9794f3c8ba94ebdc420a7863f5ca93e6c106ee6406f5c5e6cc3d18`.
  PASS estático; el defecto runtime permanece abierto hasta el retest del propietario.

- Retest VoiceOver del propietario (09-09): el ajuste anterior FALLA. Al guardar escucha «Cliente guar…»
  cortado por el retorno al listado, cuyo foco sigue en «Cerrar sesión». Tras esa prueba añade
  `ToolbarSpacer(.fixed, placement: .primaryAction)` para separar Cerrar sesión y Añadir; se conserva
  exactamente. No se atribuye el fallo anterior al separador ni se acredita todavía su efecto táctil.
  Nueva corrección en ClientFormScreen/ClientListScreen: resultado explícito `Completion` por closure
  `@MainActor`; el listado comprueba identidad, conserva resultado efímero y cierra mediante su ViewModel.
  `onDismiss` consume el resultado, solicita foco VoiceOver en Añadir para alta/desactivación y anuncia
  éxito con prioridad `.high`, solo después del cierre. Cancelar/guardar edición mantiene retorno nativo.
  Sin retrasos, UIKit, cambio de datos o anuncio de éxito previo al cierre. La causa exacta del fallo de foco
  anterior no está demostrada. Apple: [Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement),
  [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate).
  Propuesta independiente PASS; 446 archivos pre/post idénticos, SHA-256
  `6762c1286eb036abf5774e1481ec452e8a9a6f75518853f12212e31702680668`.
  Xcode MCP build PASS (8,95 s), Develop / iPhone 14: `BuildProject-Log-20260909-083959.txt`.
  Navigator/GetBuildLog sin issues; log completo conserva aviso AppIntents en línea 11610.
  Previews inspeccionadas, prefijo `RenderPreview_result_2026-09-09T`, sufijo `Z@3x.png`: listado Large
  `064035` (contenido) y AX 5 `064055` (carga); formulario Large `064108`, XXX Large `064143` y AX 5
  `064115`, viewport inicial. Listado XXX Large falla dos veces en código generado preview-thunk:
  `ambiguous use of __designTimeSelection`, junto al Button de toolbar; no se modifica el separador para
  sortearlo. Primera petición XXX Large del formulario y AX 5 compartieron ruta; `064143` sustituye la
  evidencia XXX Large. Las capturas no prueban cierre, foco, locución ni separación junto a Cerrar sesión.
  Sin tests unitarios nuevos ni repetición de negocio: solo coordinación de presentación; spec 08.3
  mantiene esa lógica cubierta en ViewModels. Defectos de foco/anuncio y ADR 0022 abiertos hasta retest:
  guardar/cancelar alta → Añadir, cancelar/guardar edición → fila, desactivar → Añadir y anuncios completos.

- Reauditorías finales de la nueva finalización explícita: iOS/estilo y accesibilidad PASS estático,
  sin hallazgos P0–P3. Read-only operacional verificado: 446 archivos idénticos, SHA-256
  `a9ed1f28d1f457b2cc9dfdd149c7ccf59ddf309e18e0997672510bf83207161a`.
  No acredita resolución runtime: foco y locución pendientes del retest del propietario.

- Retest posterior del propietario (09-09, iPhone 14 / iOS 26.6.1): «Cliente guardado» se escucha completo;
  al volver sigue anunciando «Cerrar sesión, botón». El anuncio completo queda confirmado por reporte;
  el defecto de foco sigue abierto. Ajuste mínimo posterior: `.accessibilityDefaultFocus($addButtonIsFocused, true)`
  en la raíz del listado, configurando Añadir como destino predeterminado de VoiceOver cuando el sistema
  evalúa foco inicial/de retorno. API nativa iOS 26 verificada en SDK y
  [Apple](https://developer.apple.com/documentation/swiftui/view/accessibilitydefaultfocus(_:_:)).
  Propuesta independiente PASS, sin regresión inevitable identificada; no demuestra corrección runtime.
  Huellas pre/post idénticas de 446 archivos: `eb926847e90b368e7aacb4a64187e5caddee477a7c9c7d9c5ab0c53412e202c1`.
  Se mantienen secuencia de anuncio y ToolbarSpacer del propietario. Build Xcode MCP PASS (8,724 s):
  `BuildProject-Log-20260909-085614.txt`; Navigator/GetBuildLog sin issues, aviso AppIntents en línea 11535.
  Previews listado XXX Large `RenderPreview_result_2026-09-09T065652Z@3x.png` y AX 5
  `RenderPreview_result_2026-09-09T065657Z@3x.png` inspeccionadas, contenido visible. Large falla dos veces
  con la ambigüedad de `__designTimeSelection` en código generado del preview; queda como limitación.
  No cambian geometría ni negocio; tests unitarios no repetidos. Retest de foco pendiente: alta → Añadir,
  cancelación/guardado de edición → fila de origen, desactivación → destino estable. El foco predeterminado
  también debe comprobarse al entrar al listado y durante búsqueda; capturas no acreditan AT. ADR 0022 abierto.

- Reauditoría focal de foco predeterminado PASS estático; 446 archivos idénticos pre/post, SHA-256
  `c0124cf0efc173f2dd9b4922785c1342bd3a128840bc35db8b0f8340237ebbc5`. Defecto de foco pendiente de retest.

- Retest final de alta y cancelación de edición con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  tras guardar el alta el foco queda en la fila del cliente recién creado. El propietario confirma después
  que abrir ese cliente y Cancelar devuelve el foco a la misma fila. Ese destino conserva el contexto del
  alta y se acepta como resultado válido; no se exige desplazarlo a Añadir si iOS restaura la fila creada.
  El anuncio completo «Cliente guardado» ya fue confirmado en el retest anterior. Queda verificado por reporte
  el retorno contextual en estos dos recorridos, sin audio/Inspector ni atribución causal del comportamiento
  a un modificador concreto. No se extrapola a guardado de edición, alta cancelada, desactivación o búsqueda.
  Siguiente prueba: modificar un campo opcional, Guardar con VoiceOver y comprobar anuncio, foco y valor al reabrir.
  Solo documentación; build/tests N/A. ADR 0022 y 08.3 siguen abiertos por el resto de evidencia pendiente.

- Guardado de edición con VoiceOver confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  modifica Localidad, guarda, escucha «Cliente guardado» completo, vuelve el foco a la misma fila y al
  reabrir se conserva el cambio. No se registra el valor introducido. Resultado por reporte, sin audio ni
  Inspector; no acredita otros recorridos. Siguiente prueba: apertura y recorrido de la confirmación de
  desactivación con VoiceOver, sin ejecutar todavía la acción destructiva. Build/tests N/A, documentación.

- Confirmación de desactivación con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): al abrirla
  anuncia «alerta», lee título, contenido y «Desactivar, botón». Tras pedir cancelar mediante el gesto de
  escape, el propietario informa foco en «Desactivar cliente, botón» del formulario. Se acredita la lectura
  del diálogo y el retorno al control de origen tras cancelar; no se infiere desactivación efectiva ni
  eliminación del cliente. Siguiente prueba: confirmar la desactivación del cliente de prueba y comprobar
  anuncio, desaparición de su fila y destino del foco. Reporte sin audio/Inspector; build/tests N/A documental.

- Desactivación y estado vacío con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): confirma
  «Cliente desactivado» completo y, al volver, escucha «Los clientes aparecerán aquí cuando estén disponibles».
  Después de abrir Añadir y cancelar sin rellenar, informa «No hay clientes». Desde ese estado confirma
  que alcanza Añadir cliente con tres deslizamientos a la izquierda y puede abrirlo de nuevo. Son destinos
  contextuales válidos para una lista vacía; no se exige retorno a Añadir. El estado vacío comunicado tras
  desactivar es coherente con la retirada del último cliente; no se infiere inspección de persistencia.
  Reportes sin audio/Inspector; búsqueda con VoiceOver y resto de tecnologías/criterios siguen pendientes.
  Siguiente prueba: búsqueda con coincidencia y sin resultados sobre un cliente de prueba.
  Build/tests N/A: actualización documental, sin cambios de código ni cierre de subfase.

- Búsqueda con VoiceOver confirmada por el propietario (09-09, iPhone 14 / iOS 26.6.1): crea un cliente
  de prueba, busca parte del nombre y alcanza/abre su fila sin dificultad. Al introducir una consulta sin
  resultados escucha «Sin coincidencias»; al borrar la consulta vuelve a aparecer el cliente. Se verifica
  por reporte búsqueda con coincidencia, anuncio de ausencia y restauración de resultados; no se infiere
  foco concreto tras cada cambio ni ausencia de interrupciones no reportadas. Sin audio/Inspector.
  Continúa la comprobación del rotor por encabezamientos. Build/tests N/A, actualización documental.

- Rotor VoiceOver por encabezamientos confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  dentro del formulario encuentra «Editar cliente» y se anuncia como encabezamiento. Se acredita este
  recorrido del rotor, no todos sus modos ni encabezamientos de otras pantallas. Reporte sin audio/Inspector.
  Continúa Control por voz en el listado; no se extrapola evidencia entre tecnologías de asistencia.
  Build/tests N/A: actualización documental, sin código ni cierre del gate ADR 0022.

- Control por voz iniciado por el propietario (09-09, iPhone 14 / iOS 26.6.1). «Mostrar nombres» en
  listado expone «Añadir cliente», «campo de búsqueda» y el nombre del cliente sobre su fila. Al abrir
  Añadir por voz, el formulario muestra Cancelar, Guardar y etiquetas de campos con obligatorio/opcional,
  según reporte hasta el final. Se omiten valores de clientes del registro. Confirma después alta completa
  usando solo voz: activar Nombre obligatorio, dictar nombre de prueba, activar Guardar y aparición en listado.
  Se acreditan nombres y operación de ese recorrido, no edición/cancelación, búsqueda ni desactivación por voz.
  Sin audio/Inspector. Siguiente prueba: abrir, editar un campo opcional y cancelar por voz, comprobando descarte.
  Build/tests N/A documental; ADR 0022 sigue abierto, sin extrapolar evidencia a otras tecnologías.

- Control por voz, edición cancelada y desactivación (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  confirma abrir el cliente, introducir Localidad, Cancelar y comprobar al reabrir que el cambio se descarta.
  Confirma también desactivación por voz, incluida la confirmación, y desaparición del cliente del listado,
  todo a la primera. Se completa el muestreo representativo de Control por voz: identificación, alta,
  entrada, edición/descartado y acción destructiva confirmada. Sin audio/Inspector; no se atribuyen otros
  recorridos no ejecutados. El propietario pide rigor proporcional y evitar pruebas repetitivas.
  Plan restante agrupado: Inspector y variantes/preferencias pendientes; recorrido breve de teclado y
  Control por botón cuando se disponga de esa configuración; estados de fallo/carga conservan su límite
  de fixture. No repetir CRUD completo con cada tecnología ni todas las combinaciones visuales. R07 se
  actualiza con la evidencia física AX 5 ya comunicada. ADR 0022 permanece abierto sin convertir pendientes
  en Pasa ni N/A por reducir repeticiones. Build/tests N/A: documentación únicamente.

- Teclado del Mac en Simulator (propietario, 09-09): no dispone de teclado externo para el iPhone físico.
  Se indicó iPhone 17e / iOS 26.5, conectar el teclado del Mac y activar Acceso total mediante teclado
  dentro de iOS. En ese contexto guiado informa que Tab o cursores hacen aparecer el primer foco, pero
  para avanzar usa los cursores; alcanza todas las acciones. Confirma después abrir Añadir con teclado,
  escribir un nombre, activar Cancelar, volver al listado y continuar moviendo el foco sin dificultad.
  Muestreo representativo de navegación, foco visible, entrada y salida completado por reporte. No se
  atribuye al iPhone físico ni a todos los recorridos de Full Keyboard Access; ajustes no inspeccionados
  directamente por el orquestador, sin captura/Inspector. No repetir CRUD por teclado. Control por botón,
  Inspector y adaptación/preferencias conservan sus pendientes. Build/tests N/A documental; ADR 0022 abierto.

- Control por botón, muestreo representativo (propietario, 09-09, iPhone 14 / iOS 26.6.1): tras la
  configuración guiada de pantalla completa/seleccionar ítem y exploración automática, observa dos grupos:
  Cerrar sesión/Añadir/Buscar y las pestañas. Confirma entrar al grupo, abrir Añadir, recorrer el formulario
  incluido Cancelar y volver al listado. Se acredita por reporte exploración, selección, apertura y salida
  sin bloqueo; no se infiere entrada de texto, confirmación destructiva ni todos los recorridos de esta AT.
  Sin audio/Inspector. No repetir CRUD con Control por botón. Sigue una prueba combinada de preferencias
  visuales y movimiento. Build/tests N/A documental; resto de evidencia ADR 0022 permanece abierto.

- Preferencias combinadas confirmadas por el propietario (09-09, iPhone 14 / iOS 26.6.1): tras indicar
  Aumentar contraste, Reducir transparencia, Diferenciar sin color y Reducir movimiento simultáneamente,
  confirma listado y apertura/cancelación del formulario legibles, botones utilizables y transiciones sin
  problemas. Muestreo conjunto por reporte; no acredita medición de ratios, cada combinación ni inspección
  directa de ajustes. Se indicó restaurar preferencias habituales al terminar; restauración no confirmada.
  Continúa adaptación mínima en iPad (ADR 0026 conserva iPad adaptativo); Inspector y otras variantes no
  observadas conservan límites. Build/tests N/A documental; sin cambios de código ni cierre de subfase.

- Adaptación iPad confirmada por el propietario (09-09): listado/formulario correctos en todas las
  orientaciones probadas y en la ventana más pequeña permitida, incluidos recorrido de campos y acceso a
  Cancelar/Guardar. La inspección CUA posterior identifica el simulador real como iPad Air 11-inch (M4),
  iOS 26.5 (se había sugerido Pro 11; no se atribuye el resultado a ese modelo). Captura CUA muestra la
  ventana estrecha en landscape con Editar cliente, Cancelar/Guardar y campos finales/Desactivar visibles,
  sin solapamiento observado. Tamaño exacto de ventana no medido; no demuestra RTL ni todas las variantes.
- Nuevo intento Accessibility Inspector (Xcode.app, no beta), 09-09: seleccionada Fran DEV en el simulador,
  Run Audit no proporciona filas ni captura. El modo Inspection tampoco obtiene elemento/propiedades al
  usar el puntero sobre el formulario. Se desactiva el puntero y se deja la pestaña Audit con Fran DEV.
  No se interpreta vacío como cero incidencias. Pendiente comprobación manual de Run Audit por el propietario;
  no se modifica código ni se repiten recorridos funcionales. Build/tests N/A documental; ADR 0022 sigue abierto.

- Inspector, 09-09, capturas del propietario entre 18:55 y 19:02: ya se obtienen informes.
  Audit 1, ventana mínima: cuatro avisos de contraste y uno de Dynamic Type, con resaltados fuera
  de la ventana; atribución no confirmada. Audit 2, ventana ampliada: tres avisos de contraste
  (1,00: #000200/#000100; 1,01: #2B2B2D/#2C2C2E; 1,49: #2C2C2E/#000300) y uno de texto
  potencialmente inaccesible. Los resaltados corresponden a fondo superior, Calle y número,
  Desactivar cliente y Jornada detrás del modal, respectivamente. Los nueve avisos del Inspector
  son el agregado de ambos informes, no nueve hallazgos nuevos. El segundo no reproduce el aviso
  Dynamic Type; no se interpreta como corrección acreditada.
  Inspection confirma Desactivar cliente con nombre, rol botón, acción Activate y jerarquía dentro
  del formulario modal. El ratio informado no incluye el rojo del texto y no acredita su contraste
  real. Inspection no recupera propiedades del aviso Calle y número. Atribución y medición real
  pendientes; no se descartan avisos como falsos positivos ni se cambian colores por estas capturas.
  Evidencia original local: Desktop/Captura de pantalla 2026-09-09 a las 18.55.27.png y serie
  19.01.01.png–19.02.56.png. Sin cambios ejecutables; build/tests N/A documental.

- Corrección focal autorizada 09-09: `ClientFormContent` aplica `.foregroundStyle(.errorInk)`
  únicamente al texto Desactivar cliente. Conserva rol destructivo, acción, disabled y 44 pt.
  Revisión independiente previa y final estática: PASS. Ratios del asset frente a blanco/#2C2C2E:
  normal 6,57/5,00:1; contraste incrementado 9,12/6,89:1. No son una medición del modal final.
  Build Xcode MCP PASS (9,115 s), log BuildProject-Log-20260909-191906.txt; persiste aviso
  AppIntents metadata extraction skipped, línea 10886, sin errores. Previews Edit long profile
  Light/Dark generados e inspeccionados: RenderPreview_result_2026-09-09T172001Z@2x.png y
  RenderPreview_result_2026-09-09T172016Z@2x.png. Texto completo; muestreo ICC convertido a sRGB
  consistente con ErrorInk. El preview oscuro usa #1C1C1E, distinto del modal #2C2C2E.
  Sin repetir tests de negocio ni CRUD por un delta de color. Retest visual del modal actualizado
  pendiente; no cierra los otros avisos Inspector ni ADR 0022. Sin commit/push.

- Retest visual del propietario, 09-09 a las 19:23: confirma «Se ve bien» tras ejecutar la
  corrección. Captura local `/Users/jesusf/Desktop/Captura de pantalla 2026-09-09 a las 19.23.57.png`:
  Desactivar cliente completo y legible sobre la superficie oscura del formulario. Retest visual
  focal completado; no se repite la acción destructiva. No acredita nueva auditoría Inspector
  ni cierra los restantes avisos o la puerta general ADR 0022. Build/tests N/A documental.

## Cierre de evidencia para commit/push — 2026-09-09

Este resumen sustituye los pendientes históricos anteriores. La entrega Git publica la implementación;
no declara la subfase terminada ni cierra ADR 0022, Linear o la fase 08.

- R03–R08: muestreo representativo completado de VoiceOver, Control por voz, Control por botón,
  teclado, texto máximo, preferencias combinadas e iPad. Los límites concretos de cada fila se conservan;
  no se exige repetir CRUD con cada tecnología ni todas las combinaciones.
- RTL sintético: previews existentes de lista con cliente largo y formulario largo con override temporal
  rightToLeft, aprobados por revisión independiente previa. Renders Xcode inspeccionados
  `RenderPreview_result_2026-09-09T173519Z@2x.png` y `RenderPreview_result_2026-09-09T173537Z@2x.png`:
  alineación y símbolos adaptados, texto español completo, campos conservan dirección de su contenido.
  Ambos archivos restaurados byte a byte; no se añade localización ni configuración de producto.
- Disposición Inspector Audit 1: cuatro contrastes y Dynamic Type con resaltados fuera de la ventana mínima.
  Evidencia no atribuible con seguridad a controles de la app; se conserva como limitación del informe,
  no como defecto confirmado ni como falso positivo demostrado. Dynamic Type de la app tiene evidencia
  independiente de renders y retest físico; no se afirma que el aviso haya sido corregido.
- Disposición Audit 2: contraste del fondo superior y detección de Jornada señalan contenido detrás del
  modal, no operable en esa presentación; no justifican modificarlo. Calle y número aparece bajo la barra
  tras scroll y el muestreo compara fondos, no el texto plenamente expuesto; no acredita contraste del campo.
  Desactivar compara gris/negro sin rojo: el ratio del informe no representa su texto. La medición independiente
  detectó contraste bajo, corregido con ErrorInk y validado en previews y retest del propietario.
  Triaje completado sin afirmar informe limpio o contraste global aprobado.
- Límites vigentes: R09 (carga/fallo asíncrono/reintento con AT), medición completa de contraste no textual
  y superficies operables. No se convierten a Pasa ni a N/A. La restricción iPhone portrait conserva
  A/No pasa con excepción de producto ADR 0026. Estas limitaciones impiden declarar DoD completo. Véanse también los límites restantes por criterio
  (contraste textual, cancelación táctil y autofill); este resumen no los convierte a Pasa.
- Revisiones independientes finales: 19 Swift sin defectos nuevos de arquitectura/privacidad/concurrencia/
  estilo; UI sin defectos ejecutables adicionales confirmados. Hallazgos P2 de documentación y preparación
  de entrega corregidos: snapshot reducido, matriz reconciliada y fixture temporal excluida del staging.
  Huella pre/post de 446 archivos idéntica: `da8d69ef75a69414034f8db18df2cde9ca03f17848f4b9088c51f673aa590f14`.
