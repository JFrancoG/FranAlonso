# Evidencia de accesibilidad — 08.3 listado, búsqueda y formulario de clientes

Fecha del registro inicial: 2026-09-08. Estado actual: **muestreo representativo completado, con límites y excepción ADR0026; cierre operativo completado por PR#10**.

Alcance: [PLU-37](https://linear.app/plusprojects/issue/PLU-37), subfase 08.3. Este documento aplica
[ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) y la
[matriz WCAG 2.2 A/AA para iOS](../WCAG22_AA_IOS.md) a las dos pantallas modificadas y al recorrido que las cruza.
Es un objetivo interno basado en WCAG2ICT y convenciones Apple, no una certificación ni una declaración legal de
conformidad. La evidencia previa de componentes o del shell no acredita automáticamente sus nuevas composiciones.

## Cierre de entrega — 2026-09-10

PR#10 integrada en main (1377cc4), PLU-37 Done. Cierre autorizado tras completar el muestreo
representativo y las revisiones. Se conservan los límites documentados y la excepción ADR0026;
el cierre no equivale a conformidad global. Los pendientes operativos de las entradas siguientes
son históricos. Sin nuevas pruebas manuales pendientes del alcance acordado.

## Estado reconciliado — 2026-09-10

Este bloque y las tablas R/ADR actualizadas describen el estado vigente. Las secciones fechadas
posteriores conservan el historial de cada sesión; sus pendientes se consideran sustituidos cuando
hay confirmación posterior explícita. A/L expresa el límite del muestreo, no una orden de repetir
cada recorrido o todas las combinaciones.

- R09 completado por reporte: reintentos de guardado y lectura, conservación/carga de datos y retorno.
  Harness retirados; AppDependencies+ClientForm.swift coincide byte a byte con HEAD.
- Nueva confirmación: presentación ajustada al contenido, título centrado, botones delimitados;
  VoiceOver recorre, cancela con retorno y confirma con resultado final completo. Reintentar ahora
  usa el estilo primario. Build125405 y RunProject125546 PASS con AppIntents previo.
- **Comprobación acotada completada:** capturas del propietario de las13:40–13:41 de iPad en ventana
  estrecha con texto ampliado. La nueva sheet muestra ambos botones completos tras desplazar; el
  propietario confirma apariencia correcta. No quedan nuevas pruebas manuales pendientes del muestreo
  acordado. Las imágenes no acreditan pulsaciones, locuciones ni la categoría exacta de Dynamic Type.
- ADR0026 mantiene la excepción aceptada de orientación iPhone; no se declara conformidad completa.
- Artefactos históricos eliminados: sus rutas se conservan como texto marcado no disponible.
  No se recrean capturas ni se presenta su inspección histórica como verificación actual. Los
  reportes del propietario y resultados textuales se conservan con sus límites; no se pide repetirlos.
- La base está publicada en5533948/4527b03; las correcciones actuales se incluyen en la entrega
  commit/push autorizada el2026-09-10. Sin cierre de subfase, PR/merge, live ni avance a08.4.

## Comprobación visual final — 2026-09-10, 13:40–13:41

El propietario aporta seis capturas y confirma «yo lo veo todo bien». Se inspeccionan listado,
formulario y nueva confirmación en una ventana estrecha de iPad con texto ampliado. La confirmación
conserva título centrado y texto multilínea; la secuencia final muestra desplazamiento vertical hasta
Cancelar y Desactivar completos, delimitados y sin solaparse. El contenido que sale por el borde
superior al desplazar no representa truncamiento horizontal. Queda resuelta la comprobación visual
pendiente de la nueva presentación. No se atribuye a estas imágenes una activación de los botones;
el retorno al cancelar y VoiceOver conservan su evidencia previa.

Capturas originales locales, aportadas por el propietario:

- [13.40.20](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.40.20.png>)
- [13.40.38](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.40.38.png>)
- [13.41.01](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.41.01.png>)
- [13.41.20](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.41.20.png>)
- [13.41.46](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.41.46.png>)
- [13.41.57](</Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 13.41.57.png>)

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
vez, que no se interrumpa al cerrar la sheet ni que el foco termine en un elemento correcto. Las comprobaciones efectivas y sus límites se recogen en R03–R09; no se amplían desde la inspección.

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

El manifiesto local de 19 capturas — `/tmp/franalonso-083-preview-manifest.json` (artefacto local no disponible) identificaba las rutas devueltas por
RenderPreview; su archivo temporal ya no está disponible. La tabla distingue las capturas anteriores a las correcciones de las que las verifican. Todas las
observaciones visuales que siguen fueron comunicadas por el orquestador; el agente documental no las presenta como
una operación propia con tecnologías de asistencia.

Xcode mostraba Canvas **Automatic — iPhone 17 Pro**. No quedó acreditada la versión de iOS efectiva de cada preview;
no se deduce del SDK 26.5 ni del simulador usado después para R01. Las variantes siguientes corresponden a las
solicitudes de RenderPreview registradas por el orquestador; la lista `supportedPreviewVariantOverrides` del
manifiesto describe capacidades, no una confirmación de la variante efectiva. Las capturas son portrait y solo
acreditan su viewport visible. No existe todavía cobertura completa de todas las combinaciones por pantalla.

| ID | Superficie y variante solicitada | Artefacto inspeccionado | Resultado visual y límite |
|---|---|---|---|
| P01 | Pantalla alta; Large / Light solicitados; contraste efectivo no registrado | RenderPreview_result_2026-09-08T135406Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135406Z@3x.png` (artefacto local no disponible) | Alta y campos visibles. La captura no demuestra el recorrido completo ni AT. |
| P02 | Pantalla edición; AX 5 / Dark / contraste incrementado | RenderPreview_result_2026-09-08T135813Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135813Z@3x.png` (artefacto local no disponible) | Solo capturó carga. Título inline «Editar clien…» truncado; pendiente verificar la pantalla cargada a AX 5. No acredita campos. |
| P03a | Listado vacío; Large / Light / contraste normal | RenderPreview_result_2026-09-08T135855Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135855Z@3x.png` (artefacto local no disponible) | Estado vacío visible. |
| P03b | Listado con nombre largo; XXX Large / Dark / contraste normal | RenderPreview_result_2026-09-08T135901Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135901Z@3x.png` (artefacto local no disponible) | Nombre largo con crecimiento vertical. Solo viewport visible. |
| P03c | Listado de 80 clientes; AX 5 / Light / contraste incrementado | RenderPreview_result_2026-09-08T135907Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135907Z@3x.png` (artefacto local no disponible) | Filas multilínea visibles. No acredita desplazamiento u operación de las 80 filas. |
| P03d | Sin coincidencias; Large / Light / contraste normal | RenderPreview_result_2026-09-08T135913Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T135913Z@3x.png` (artefacto local no disponible) | Estado vacío por búsqueda visible. Anuncio no escuchado. |
| P03e | Error de listado; AX 5 / Dark / contraste incrementado | RenderPreview_result_2026-09-08T140004Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140004Z@3x.png` (artefacto local no disponible) | Título, mensaje y Reintentar visibles. No se operó el reintento en esta captura. |
| P03f | Carga de listado; Large / Light / contraste normal | RenderPreview_result_2026-09-08T140010Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140010Z@3x.png` (artefacto local no disponible) | Indicador y texto visibles. No acredita duración, transición ni anuncio. |
| P04a-antes | Contenido edición larga; AX 5 / Dark / contraste incrementado | RenderPreview_result_2026-09-08T140023Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140023Z@3x.png` (artefacto local no disponible) | Obsoleta para evaluar el código corregido: label de nombre recortado, hallazgo que motivó el ajuste compartido. |
| P04b | Validación de nombre; XXX Large / Light / contraste incrementado | RenderPreview_result_2026-09-08T140024Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140024Z@3x.png` (artefacto local no disponible) | Mensaje completo junto al campo. No acredita hint oído ni foco accesible. |
| P04c | Fallo inicial del formulario; Large / Dark / contraste normal | RenderPreview_result_2026-09-08T140108Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140108Z@3x.png` (artefacto local no disponible) | Mensaje y Reintentar visibles; recuperación runtime pendiente. |
| P04d-antes | Fallo de guardado; Large / Light / contraste incrementado | RenderPreview_result_2026-09-08T140110Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140110Z@3x.png` (artefacto local no disponible) | Obsoleta: el error quedaba fuera del primer viewport. Sustituida por P04d tras adelantar la sección de error. |
| P04e-antes | Guardando; Large / Light / contraste normal | RenderPreview_result_2026-09-08T140111Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140111Z@3x.png` (artefacto local no disponible) | Obsoleta: el progreso quedaba fuera del primer viewport. Sustituida por P04e tras adelantar esa sección. |
| P04f | Contenido alta; XXX Large / Light / contraste normal | RenderPreview_result_2026-09-08T140113Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140113Z@3x.png` (artefacto local no disponible) | Aviso de borrador y campos visibles. Solo acredita el viewport. |
| P04a-caché | Contenido edición larga; AX 5 / Dark / contraste incrementado | RenderPreview_result_2026-09-08T140146Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140146Z@3x.png` (artefacto local no disponible) | Obsoleta: render anterior a recompilar, todavía recortado. No se usa como evidencia de la corrección. |
| P04a | Contenido edición larga; AX 5 / Dark / contraste incrementado | RenderPreview_result_2026-09-08T140258Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140258Z@3x.png` (artefacto local no disponible) | Después del build: label obligatorio completo gracias a crecimiento vertical. No acredita campos inferiores ni toolbar de Screen. |
| P04d | Fallo de guardado; Large / Light / contraste incrementado | RenderPreview_result_2026-09-08T140902Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140902Z@3x.png` (artefacto local no disponible) | Error visible en la primera sección del formulario. No acredita anuncio ni recuperación. |
| P04e | Guardando; Large / Light / contraste normal | RenderPreview_result_2026-09-08T140904Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140904Z@3x.png` (artefacto local no disponible) | Progreso visible en la primera sección del formulario. No acredita el estado transitorio con AT. |
| P04g | FormFieldSection compartido; AX 5 / Light / contraste normal | RenderPreview_result_2026-09-08T140925Z@3x.png — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T140925Z@3x.png` (artefacto local no disponible) | Label completo; valor de correo de una sola línea conserva el recorte nativo. No acredita todas las pantallas consumidoras. |

### Correcciones de auditoría y renders posteriores

La auditoría independiente señaló dos P2: título inline recortado a AX 5 (1.4.4) y contraste del texto de progreso
en P04e (1.4.3). El primero es independiente de la carga; no bastaba esperar al formulario. Se usa título nativo
grande y se aplica `TextPrimary` al label de progreso. Build Xcode MCP **PASS, 7,686 s**, Develop/iPhone 11,
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-163708.txt`.
GetBuildLog warning sin entradas (`875B3B13-AF51-496F-A54B-2DDDCF449D0C.txt`); el log completo mantiene AppIntents
en línea 10917. Los dos ajustes son visuales; no se repiten los tests lógicos 259/259, y se comprueban build y renders.

Se añaden **7 capturas**, **26 en total**, en el
manifiesto correctivo local — `/tmp/franalonso-083-corrective-preview-manifest-final.json` (artefacto local no disponible). P02 queda sustituida para
evaluar el título, y P04e para el contraste del texto. Sus límites históricos permanecen documentados.

| ID | Variante solicitada | Artefacto inspeccionado | Resultado y límite |
|---|---|---|---|
| C01 | Screen edición, AX 5 / Dark / contraste incrementado | 143801 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143801Z@3x.png` (artefacto local no disponible) | Título «Editar cliente» completo. Captura carga; no acredita formulario cargado ni navegación/scroll con AT. |
| C02 | Screen edición, Large / Light / contraste normal | 143803 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143803Z@3x.png` (artefacto local no disponible) | Título completo, Cancelar/Guardar y campos precargados visibles; provincia comienza al pie del viewport. |
| C03 | Guardando, Large / Light / contraste normal | 143816 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143816Z@3x.png` (artefacto local no disponible) | Texto de progreso visible y oscuro sobre blanco. |
| C04 | Guardando, Large / Light / contraste incrementado | 143818 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143818Z@3x.png` (artefacto local no disponible) | Texto de progreso negro sobre blanco. |
| C05 | Guardando, Large / Dark / contraste normal | 143819 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143819Z@3x.png` (artefacto local no disponible) | Texto de progreso blanco sobre superficie oscura. |
| C06 | Guardando, Large / Dark / contraste incrementado | 143821 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T143821Z@3x.png` (artefacto local no disponible) | Texto de progreso blanco sobre superficie oscura. |
| C07 | Consumidor compartido LoginContent, AX 5 / Light / contraste normal | 144034 — `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/RenderPreview_result_2026-09-08T144034Z@3x.png` (artefacto local no disponible) | Labels Email y Contraseña completos. No se atribuye a Login una nueva pasada funcional ni AT. |

Muestreo raster de C03–C06: PNG RGB sin ICC interpretado como sRGB, región del texto `(51,238)–(344,273)` en
capturas 689×1500, color de fondo modal y color de texto frecuente. Ratios aproximados **18,71 / 21,00 / 17,01 /
15,49:1**, respectivamente; el antialiasing no se interpreta como color de diseño. Registro reproducible de valores
y rutas: muestra de contraste — `/tmp/franalonso-083-progress-contrast.json` (artefacto local no disponible). Es evidencia de esas capturas, **no
Inspector ni medición completa de todos los textos/controles del formulario**. La reauditoría focal confirma la corrección de ambos P2.

**P05 — Matriz visual:** Large / XXX Large / AX 5 y Light / Dark con contraste normal / incrementado tienen muestras
anteriores, sin una pasada de todas sus combinaciones en cada Screen cargada. **P06 — Adaptación adicional:** orientaciones y ventana mínima iPad confirmadas por el propietario
(ver R07); layout RTL sintético comprobado en Cierre de evidencia. RTL sintético no equivale a disponer de
una localización RTL.

| ID | Técnica o recorrido requerido | Evidencia actual | Resultado y límite |
|---|---|---|---|
| R01 | Entrada y activación por CUA: alta, buscar, editar, cancelar, validar, guardar, confirmar/cancelar desactivación | Registro runtime del orquestador, iPhone 17e / iOS 26.5, portrait, fixture signed-out activada en la UI de Xcode | Recorrido CUA histórico completado con reportes físicos posteriores: alta, búsqueda, edición, guardado, descarte y desactivación operados. Los intentos iniciales de scroll no acreditaban desactivación, pero no son un pendiente actual; R03/R07/R09 contienen evidencia posterior. No se extrapola a tecnologías no operadas. |
| R02 | Accessibility Inspector: listado, campos, toolbar, errores y confirmación | Informes Audit 1 y Audit 2 aportados el 09-09; detalle en registro inferior. Inspection obtiene nombre, rol, acción y jerarquía de Desactivar cliente | Informes históricos triados; nueva sesión: formulario con 1 contraste bajo toolbar, 2 detecciones de fondo y 2 Dynamic Type; listado expuesto con 6 Dynamic Type, sin avisos Contrast/Hit Region/Element Detection. Véase reconciliación final; no equivale a informe limpio. |
| R03 | VoiceOver: recorrido completo, rotor, foco, anuncios y restauración | Reportes del propietario el 09-09, iPhone 14 / iOS 26.6.1 | Muestreo VoiceOver confirmado por propietario 09–10/09: etiquetas/valores, validación, guardado completo, retorno contextual a fila, búsqueda y rotor por encabezamientos. La sheet actual empieza por tirador nativo; recorre título/mensaje/acciones, Cancelar devuelve foco a Desactivar cliente y confirmar termina con Cliente desactivado completo y No hay clientes. Locución parcial durante transición: observación no bloqueante sin causa atribuida. La antigua alerta queda solo en histórico. R09 confirma recuperación de lectura y retorno. Sin audio/Inspector ni extrapolación a otros modos del rotor. |
| R04 | Voice Control: activación por nombre y entrada/edición de campos | Iniciado por el propietario el 09-09, iPhone 14 / iOS 26.6.1 | Parcial. Mostrar nombres identifica Añadir, buscador, fila, botones y campos con obligatorio/opcional. Alta por voz confirmada: abrir Añadir, activar Nombre, dictar y Guardar; cliente aparece en listado. Edición de Localidad y descarte al cancelar/reabrir confirmados. Desactivación por voz incluida confirmación y desaparición de fila, a la primera. Muestreo representativo completado; búsqueda por voz no ejecutada. Sin audio/Inspector. |
| R05 | Switch Control: escaneo, entrada, confirmación, cancelación y retorno | Reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1, configuración guiada pantalla completa/seleccionar ítem y exploración automática | Muestreo representativo: dos grupos (acciones/buscador y pestañas); selecciona Añadir, abre formulario, recorre controles y Cancelar, vuelve al listado. Sin bloqueo reportado. Entrada de texto y confirmación destructiva no ejecutadas; sin Inspector. |
| R06 | Full Keyboard Access: recorrido, edición, foco visible y salida | Reporte guiado del propietario, 09-09; se indicó iPhone 17e / iOS 26.5 Simulator, teclado del Mac y Acceso total mediante teclado | Muestreo representativo completado: Tab/cursores muestran primer foco, cursores recorren todas las acciones; abre Añadir, escribe, cancela y continúa navegando en listado sin bloqueo. Ajustes no inspeccionados directamente. No acredita dispositivo físico, todos los recorridos, confirmación destructiva ni estados de fallo. No repetir CRUD completo. |
| R07 | Runtime Large / XXX Large / AX 5; iPhone portrait e iPad orientaciones/ventanas | R01 más reportes físicos del propietario en iPhone 14 / iOS 26.6.1 con texto máximo | Formulario/listado a texto máximo y con teclado, orientaciones y ventana mínima iPad confirmados por propietario; iPad Air11-inch(M4)/26.5 identificado por CUA. RTL sintético de ambas pantallas inspeccionado, sin localización RTL. Nueva sheet: preview AX5 inspeccionada y comprobación representativa del propietario en iPad estrecho con texto ampliado completada mediante las capturas13:41:46 y13:41:57: tras desplazar, Cancelar y Desactivar aparecen completos. Las imágenes no identifican la categoría exacta de Dynamic Type ni acreditan pulsaciones. Véase registro13:40–13:41. |
| R08 | Increase Contrast, Reduce Motion, Reduce Transparency y Differentiate Without Color | Reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1, las cuatro opciones indicadas juntas | Muestreo combinado confirmado: listado y apertura/cancelación del formulario legibles y operables, transiciones sin problemas. Sin medición de ratios ni inspección directa de ajustes; no se atribuyen todas las combinaciones. Restauración de preferencias habituales indicada, no confirmada. |
| R09 | Carga sostenida, fallos de lectura/escritura y reintentos del formulario con AT | P04c/P04d/P04e y fallo de guardado inyectado temporalmente, autorizado y retirado | Fallo de guardado: anuncio, conservación del nombre y reintento exitoso confirmados. Fallo inicial de lectura: acceso a Reintentar, datos cargados/recorribles con VoiceOver y Cancelar→fila de origen confirmados 10/09. Locución inicial exacta no transcrita; no inventarla. Ambos harness retirados; último build/run125405/125546 PASS. Reintentar delimitado con estilo primario y preview posterior. Carga sostenida solo tiene evidencia visual/estática; no invalida los recorridos de recuperación comprobados. |

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
indicadas. Reconciliación vigente: **2026-09-10**; cada evidencia conserva su fecha y método originales. Configuración de inspección: fuentes actuales de 08.3 y catálogo español;
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
| 1.3.1 | A/L | A/L | A/L | Form y etiquetas persistentes inspeccionados; R03 confirma encabezados y etiquetas/valores. R09 confirma acceso a Reintentar y campos cargados recorribles con VoiceOver. Muestreo representativo. |
| 1.3.2 | A/L | A/L | A/L | R03 confirma secuencia de listado, formulario y confirmación; R05/R06 recorrido representativo y salida. No repetir CRUD por cada tecnología. |
| 1.3.3 | A/Pasa | A/Pasa | A/Pasa | Inspección del copy: buscar, reintentar, nombre obligatorio, guardar/cancelar y desactivar se explican mediante texto. Ninguna instrucción exige reconocer solo posición, forma, color o sonido. |
| 1.3.4 | A/No pasa | A/No pasa | A/No pasa | ADR 0026: iPhone solo portrait sin necesidad esencial. Excepción de producto aceptada, no normativa. R07 acredita por reporte orientaciones y ventana mínima en iPad; no compensa la restricción de iPhone. |
| 1.3.5 | N/A | A/L | A/L | L: el buscador no solicita datos personales para completar un perfil. F/X: nombre y dirección declaran textContentType compatible; fiscal conserva label sin propósito de autofill inventado. Propietario confirma inserción mediante sugerencia del teclado. Menú Contacto abre ficha sin insertar; vía no acreditada, causa desconocida. |
| 1.4.1 | A/L | A/L | A/L | Copy/roles y contornos de botones no dependen solo del color; R08 confirma preferencias combinadas. R09 confirma recuperación de fallos por texto/acción. No extrapolar a carga sostenida. |
| 1.4.2 | N/A | N/A | N/A | No se reproduce audio automático; las locuciones de la tecnología de asistencia no son audio de contenido impuesto por la app. |
| 1.4.3 | A/L | A/L | A/L | Muestreo listado: buscador6,97:1. Formulario: error5:1, postal/Desactivar en cuatro apariencias. Diálogo antiguo4,113:1 a16pt confirmado defectuoso y sustituido. Nueva sheet ErrorInk/Surface5,244/5,001/7,367/8,411; Reintentar OnBrandPrimary/BrandPrimary4,945/9,812/10,554/12,280 (assets). Previews inspeccionadas; no se declara informe Inspector limpio ni medición completa de estados. |
| 1.4.4 | A/L | A/L | A/L | Previews Large/XXX Large/AX 5 y retest físico a texto máximo confirman etiquetas, título tras scroll, entrada con teclado y Guardar/Cancelar. Límites puntuales de render generado constan en histórico; no se exige repetir todos los valores por campo. |
| 1.4.5 | A/Pasa | A/Pasa | A/Pasa | Inspección: todo el copy significativo se representa mediante texto real; los SF Symbols no contienen texto que deba sustituirlo. |
| 1.4.10 | A/L | A/L | A/L | R07 confirma teclado, campos finales, texto máximo, orientaciones iPad y ventana mínima. RTL sintético de lista y formulario inspeccionado en Cierre de evidencia; no acredita localización RTL. |
| 1.4.11 | A/L | A/L | A/L | Icono postal en cuatro apariencias, toolbar15,88:1; foco real Añadir3,577:1 exterior/4,271:1 interior. Bordes nueva sheet contra Surface: Cancelar4,555/5,206/10,042/11,183 y Desactivar5,244/5,001/7,367/8,411 (assets). R02/R08 delimitan muestreo; no inventario exhaustivo. |
| 1.4.12 | N/A | N/A | N/A | SwiftUI nativo; no existe UI mediante markup con override de espaciado de texto accesible al usuario, según la aplicabilidad de la matriz del proyecto. |
| 1.4.13 | N/A | N/A | N/A | No se añade contenido al hover o al recibir foco. La confirmación requiere una activación explícita y se evalúa como superficie modal en los criterios de foco, teclado y prevención de errores. |
| 2.1.1 | A/L | A/L | A/L | R05/R06 confirman recorrido representativo y salida con teclado/Control por botón en formulario/listado anteriores al nuevo modal. R09 operado con VoiceOver para lectura y guardado. No atribuir teclado a nueva sheet ni exigir repetir CRUD. |
| 2.1.2 | A/L | A/L | A/L | R05/R06 confirman entrada, recorrido y cancelación sin bloqueo. No se atribuye operación de estados asíncronos R09. |
| 2.1.4 | N/A | N/A | N/A | No hay atajos propios activados por una sola letra, número o signo sin modificador. Las teclas del teclado de entrada son edición nativa. |
| 2.2.1 | N/A | N/A | N/A | No se exige completar búsqueda, edición o confirmación en un tiempo límite ni se descartan campos por timeout de UI. La tarea asíncrona no impone un plazo de interacción. |
| 2.2.2 | N/A | N/A | N/A | No hay carrusel, contenido móvil ni actualización periódica autónoma que deba pausarse. La observación local representa mutaciones y los indicadores nativos representan operaciones en curso; Reduce Motion se verifica adicionalmente en R08. |
| 2.3.1 | A/L | A/L | A/L | Inspección: no se añaden medios intermitentes ni animaciones propias. R08 confirma transiciones con preferencias combinadas; progreso asíncrono mantiene límite R09. |
| 2.4.1 | A/L | A/L | A/L | Inspección: títulos nativos y acceso directo mediante buscador/lista; formulario usa secciones. R03 confirma encabezamiento Editar cliente mediante rotor y acceso al formulario/listado; no acredita todos los modos del rotor. |
| 2.4.2 | A/L | A/L | A/L | R03 confirma Editar cliente como encabezamiento, expandido y colapsado; R07 confirma título completo a texto máximo tras corrección. |
| 2.4.3 | A/L | A/L | A/L | R03 confirma retornos contextuales del flujo y nueva sheet; Cancelar confirmación→botón origen, desactivar→lista vacía. R09 confirma Cancelar tras recuperar lectura→fila. R05/R06 conservan alcance histórico. |
| 2.4.4 | A/L | A/L | A/L | Nombres/activación del flujo habitual confirmados R03/R04; Reintentar de lectura y guardado operados por VoiceOver en R09. |
| 2.4.5 | A/L | N/A | A/L | Listado ofrece lista y búsqueda; R03 confirma coincidencia accesible, apertura, Sin coincidencias y restauración al borrar. Formulario aislado no es colección de destinos. |
| 2.4.6 | A/L | A/L | A/L | R03 confirma etiquetas obligatorio/opcional y valores; rotor encuentra Editar cliente. R04 identifica controles por sus nombres. No es auditoría de todos los modos del rotor. |
| 2.4.7 | A/L | A/L | A/L | R06 confirma foco visible y recorrido con cursores por acciones, alta y salida. No se inspeccionaron directamente ajustes ni todos los estados. |
| 2.4.11 | A/L | A/L | A/L | R06/R07 confirman navegación, teclado abierto y campos finales, texto máximo y ventana mínima. No se acredita combinación exhaustiva ni estados R09. |
| 2.5.1 | N/A | N/A | N/A | No se exige gesto multipunto ni trayectoria precisa; las acciones propias son Button y entrada nativa. El desplazamiento ordinario de lista/formulario no incorpora un gesto custom de trayectoria. |
| 2.5.2 | A/L | A/L | A/L | Propietario confirma apoyar Añadir, salir y levantar sin activación; toque normal posterior abre. Muestreo físico de Añadir completado; no extrapolar a todas las acciones. |
| 2.5.3 | A/L | A/L | A/L | R04 confirma nombres de listado/formulario y alta, edición/cancelación y desactivación por voz; coincide con copy localizado. Muestreo representativo completado. |
| 2.5.4 | N/A | N/A | N/A | No se activa funcionalidad mediante agitar, inclinar o mover el dispositivo. |
| 2.5.7 | N/A | N/A | N/A | No hay reordenación ni operación propia que exija arrastrar. Cancelar ofrece salida explícita de la sheet; el scroll nativo no se trata como una acción de negocio por arrastre. |
| 2.5.8 | A/L | A/L | A/L | Listado/formulario: minHeight44, Inspector sin Hit Region en viewports muestreados y toolbar visible44pt. Los48pt de confirmación medidos corresponden al diálogo antiguo, no a la sheet actual. Esta declara52pt con contentShape y bordes; Reintentar conserva minHeight44 y estilo nativo grande. Operación VO confirmada, sin medición AX completa de nuevos targets. Política44×44pt separada de24CSSpx. |
| 3.1.1 | A/L | A/L | A/L | Catálogo español y locuciones de R03 confirmadas por propietario. No hay localización RTL; el override sintético solo comprueba layout. |
| 3.1.2 | N/A | N/A | N/A | El copy controlado de estas pantallas está solo en español, sin segmentos de otro idioma. Nombres e identificadores introducidos por la persona no añaden una localización ni una política de detección de idioma. |
| 3.2.1 | A/L | A/L | A/L | R03/R05/R06 recorren foco y acciones sin activación involuntaria reportada. Guardar y desactivar requieren intención explícita. |
| 3.2.2 | A/L | A/L | A/L | R01/R03 confirman filtrado local, Sin coincidencias/restauración y edición sin guardado implícito. Guardar/desactivar explícitos. |
| 3.2.3 | A/L | A/L | A/L | R03 confirma recorrido y retornos contextuales de alta/edición/cancelación/desactivación; búsqueda conservada según R01. Sin regresiones reportadas. |
| 3.2.4 | A/L | A/L | A/L | R03/R04 identifican controles; nueva sheet y Reintentar confirmados por VoiceOver R03/R09. Estilo visible de Reintentar corregido posteriormente sin cambio de nombre/acción. |
| 3.2.6 | N/A | N/A | N/A | No se introduce un mecanismo de ayuda repetido entre estas pantallas. Labels, instrucciones y errores se evalúan en sus criterios específicos. |
| 3.3.1 | A/L | A/L | A/L | R03 confirma error de nombre y corrección al escribir. R09 confirma fallo de guardado y recuperación, y recuperación de lectura inicial; la locución inicial exacta de esta última no se transcribió. |
| 3.3.2 | A/L | A/L | A/L | R03/R04 confirman buscador, etiquetas obligatorio/opcional y valores. Prompts redundantes eliminados; etiquetas persistentes conservadas. |
| 3.3.3 | N/A | A/L | A/L | R03 confirma instrucción de nombre y guardado posterior. R09 confirma reintentos de guardado y lectura inicial; la consulta siempre es válida. |
| 3.3.4 | N/A | A/L | A/L | Propietario confirma descarte de edición, confirmación destructiva, cancelación exterior/escape y desactivación por VoiceOver/voz. No repetir en todas las tecnologías. |
| 3.3.7 | N/A | A/L | A/L | R01 y propietario confirman precarga, descarte, conservación al guardar y consulta. R09 confirma conservación del nombre tras fallo de guardado y recuperación con VoiceOver. |
| 3.3.8 | N/A | N/A | N/A | Esta subfase no incorpora prueba cognitiva ni modifica autenticación, recuperación o biometría. La evidencia previa de Login no se presenta como una prueba nueva. |
| 4.1.2 | A/L | A/L | A/L | R03/R04 confirman nombres, roles y valores habituales; nueva sheet y Reintentar/campos R09 recorribles con VoiceOver. No extrapolar informe Inspector previo a controles nuevos. |
| 4.1.3 | A/L | A/L | A/L | R03 confirma anuncios completos de guardado/desactivación, nombre inválido y Sin coincidencias. R09 confirma fallo de guardado/reintento; recuperación de lectura operada, sin transcripción exacta de anuncio inicial. Locución transitoria cortada antes de éxito final de desactivación: observación no bloqueante. |

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
| IMG_1245.PNG — `/Users/jesusf/Downloads/IMG_1245.PNG` (artefacto local no disponible) | Nombre con placeholder truncado; fiscal con placeholder menor; Nuevo cliente colapsado truncado. |
| IMG_1246.PNG — `/Users/jesusf/Downloads/IMG_1246.PNG` (artefacto local no disponible) | Calle truncada, postal menor; labels persistentes completos. |
| IMG_1247.PNG — `/Users/jesusf/Downloads/IMG_1247.PNG` (artefacto local no disponible) | Localidad/provincia con placeholders truncados; labels completos. |
| IMG_1249.PNG — `/Users/jesusf/Downloads/IMG_1249.PNG` (artefacto local no disponible) | Edición alcanza Desactivar cliente; título colapsado truncado y provincia recortada en placeholder. |

El arreglo anterior C01/C02 no acreditaba el título tras scroll. Se retiran prompts que solo duplicaban la
etiqueta existente, manteniendo título semántico y accessibilityLabel explícito en los seis TextField.
Cancelar/Guardar pasan a símbolos en tamaños AX, con nombres localizados, área mínima declarada y large content viewer.
No cambian ejes de entrada ni se reduce el tamaño de letra. Fiscal/postal con valores largos requieren prueba propia.

Fuentes: [TextField con prompt separado](https://developer.apple.com/documentation/swiftui/textfield/init(_:text:prompt:axis:)),
[large content viewer](https://developer.apple.com/documentation/swiftui/view/accessibilityshowslargecontentviewer(_:)).
Build PASS y método en [fase 08](../../progress/phase-08.md#corrección-visual-tras-capturas-ax-5--2026-09-09).
Manifiesto de renders: /tmp/franalonso-083-ax5-preview-manifest.json — `/tmp/franalonso-083-ax5-preview-manifest.json` (artefacto local no disponible).

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

## Cierre histórico de evidencia para commit/push — 2026-09-09

Resumen al publicar la implementación; la reconciliación final inferior lo actualiza. La entrega Git publica la implementación;
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

## Comprobaciones focales posteriores a publicación — 2026-09-09

- Cancelación táctil: propietario confirma mantener Añadir, desplazar fuera y levantar no abre el
  formulario; toque normal posterior sí lo abre. Muestreo del botón Añadir, no de todos los controles.
- Autorrelleno: propietario confirma sugerencias y menú Autorrellenar → Contacto disponibles. Seleccionar
  contacto abre su ficha, pero tocar el dato no lo inserta; pulsación larga permite copiar. Inserción
  automática no acreditada. Código inspeccionado: name, streetAddressLine1, postalCode, addressCity y
  addressState declarados; sin selector de contactos propio ni lógica que rechace el texto insertado.
  No se atribuye aún causa a SwiftUI, iOS o configuración. Sin código modificado ni nuevas pruebas Xcode.

- Autorrelleno, confirmación posterior: tocar una sugerencia del teclado sí inserta el dato, según el
  propietario. Vía de sugerencias validada representativamente; no se atribuye edición posterior ni todos
  los campos. El selector Contactos conserva la incidencia de no inserción, sin causa determinada.

Preparación temporal autorizada de fallo de guardado (09-09): únicamente factoryComposed dentro de
FRANALONSO_AUTH_FIXTURE; primer guardado por formulario espera 3s cancelables y falla antes de escritura,
segundo usa adaptador original. No cambios live/Views/Domain. Backup byte a byte en
`/tmp/fa083-before-save-failure-AppDependencies.swift`, restaurar después de sesión; NO publicar harness.
Propuesta y revisión independiente final PASS; huellas pre/post verificadas. Build MCP PASS8,958s,
log200846, aviso AppIntents10912. Snippet de verificación: primer intento no compila por importFoundation
omitido; segundo con imports corregidos agota timeout60s. No acredita conteos/resultado runtime.
Pendiente prueba guiada VoiceOver de guardado/fallo/reintento. No cubre fallo de carga inicial.

Retest VoiceOver del fallo de guardado: propietario escucha «No se ha podido completar la operación.
Inténtalo de nuevo». Confirma nombre conservado y segundo Guardar exitoso, anuncio Cliente guardado,
retorno al listado con una sola fila. Guardado fallido y recuperación acreditados por reporte manual;
no se extrapola a fallo de lectura inicial, desactivación ni conteos internos de la cola.
Harness temporal retirado: AppDependencies.swift restaurado byte a byte al backup y HEAD.
La app ya instalada mantiene el harness hasta la siguiente ejecución de la versión restaurada.

## Medición directa en Simulator — 2026-09-09 20:24–20:26

iPad Air 11-inch (M4), iOS26.5, app restaurada relanzada por propietario, formulario editando y
viewport final. Capturas mediante Save Screen de Simulator: 2360×1640, Display P3 convertido a sRGB
con perfil ICC antes de calcular luminancia WCAG. Capturas locales Desktop/Simulator Screenshot -
iPad Air 11-inch (M4) - 2026-09-09 at 20.24.33.png, 20.25.41.png, 20.25.53.png y 20.26.04.png.
Muestreo de píxeles interiores frecuentes de texto y fondo uniforme, sin usar el oscurecimiento Inspector.

| Apariencia | Desactivar cliente | Etiqueta postal | Icono postal |
|---|---|---|---|
| Dark normal | #FF6B63/#2C2C2E: 5,001:1 | blanco/#2C2C2E: 13,937:1 | #9E9E9F/#2C2C2E: 5,206:1 |
| Light normal | #B42419/blanco: 6,548:1 | negro/blanco: 21:1 | #66666B/blanco: 5,710:1 |
| Light incrementado | #8B1E1D/blanco: 9,125:1 | negro/blanco: 21:1 | #333438/blanco: 12,433:1 |
| Dark incrementado | #FF9B96/#363638: 5,960:1 | blanco/#363638: 12,058:1 | #D1D1D6/#363638: 7,925:1 |

Ratios suficientes en el muestreo; no equivalen a medir buscador/foco/errores/todos los controles.
Apariencia y contraste restablecidos mediante el mismo par de toggles del menú Features; la selección
inicial normal es consistente con el color ErrorInk medido. No cambios de código ni datos.

Inspector pide descartar resultados anteriores al cambiar proceso; aceptado porque informes previos
están registrados. Nuevo Audit1: 1 contraste, 2 Dynamic Type, 2 Element Detection. Options verificadas:
Hit Region, Contrast, Element Description/Detection, Clipped Text, Traits y Dynamic Type activadas.
Sin avisos Hit Region en este viewport: evidencia automatizada del muestreo de objetivos, no medición
exhaustiva de todos los targets ni sustitución de la política propia44pt. El contraste1,09 compara
#222225/#29292B bajo toolbar, no texto plenamente expuesto. Primer aviso DynamicType inspecciona
Provincia(opcional), nodo SwiftUI; mantiene contradicción con escalado validado en código/previews y
reporte físico a texto máximo, sin causa demostrada. No se declara auditoría limpia. Inspection por
puntero no captura propiedades; no se inventan dimensiones AX. Activación de Desactivar abre diálogo;
se cancela sin ejecutar desactivación.


## Reconciliación histórica — 2026-09-09, posterior a las pruebas focales

Esta sección y R09 actualizan los pendientes históricos. No queda código temporal de inyección de fallos.
La versión restaurada fue compilada mediante MCP (PASS 8,527 s, log 20260909-201909) y relanzada.
No se repiten los recorridos de tecnologías de asistencia ya confirmados por el propietario.

- Completado: cancelación táctil representativa de Añadir, inserción por sugerencia del teclado y
  fallo de guardado/reintento con VoiceOver, preservando el nombre y retornando con una fila.
- Contrastado: Desactivar, etiqueta e icono postal en cuatro apariencias, según tabla anterior.
- Inspector formulario: las dos detecciones muestran Jornada y el icono de Catálogo detrás del modal.
  No son contenido que deba exponerse a AT mientras el modal está abierto. El aviso de contraste toma
  texto bajo toolbar; no demuestra contraste insuficiente de texto plenamente visible.
- Dynamic Type del formulario identifica Provincia y Desactivar. Fuente adaptable y prueba física a
  tamaño máximo aportan evidencia contraria al aviso. Se aumentó un paso y se restauró un paso en
  Simulator; esta maniobra no se presenta como medición geométrica de esos dos controles.
- Inspector listado, modal cancelado sin guardar: Audit 2 emite seis avisos Dynamic Type, ninguno de
  Contrast, Hit Region ni Element Detection con las mismas opciones activas. Atribución individual completada: Histórico, Catálogo, fila de cliente, Informes, Clientes y Jornada.
  Son cinco etiquetas de sidebar y una fila; Histórico inspeccionado como UILabel y fila como botón
  SwiftUI con label/hint correctos. Queda contraste de escalado por esas dos clases de control. No se declara informe limpio.

Pendientes acotados para cerrar evidencia:
1. Lectura inicial fallida del formulario y activación de Reintentar con VoiceOver: es un estado distinto
   al guardado fallido ya validado. Requiere fixture temporal autorizada antes de provocar ese estado.
2. Contrastar escalado de sidebar/fila y completar muestras de contraste de buscador/error/
   foco y geometría de toolbar/confirmación. Atribución de los seis avisos ya completada. Trabajo del agente; no requiere repetir pruebas generales.
3. Revisión independiente focal completada: sin defecto ejecutable nuevo confirmado; mantiene los dos
   bloques anteriores. Reutilizar estilos/fondos equivalentes; no repetir CRUD, guardado ni cuatro
   apariencias de ErrorInk. Correcciones P3: fecha del último build y atribución actualizadas.
   Huella pre/post de 446 archivos idéntica: bc2d4bf052799f630ccd72d9a5004ac24987831682516e705c1a690f8a696dc4.

ADR 0026 conserva excepción de orientación iPhone. Subfase In Progress; ningún PR/merge/cierre/live.


## Bloque 1: comprobaciones del agente — 2026-09-09 23:50–23:58

Simulator iPad Air 11-inch (M4), iOS 26.5. Sin cambios ejecutables, sin guardar/desactivar datos.
Capturas Save Screen 2360×1640, escala del iPad 2 píxeles/punto; conversión ICC Display P3→sRGB.
Archivos locales en Desktop, prefijo `Simulator Screenshot - iPad Air 11-inch (M4) - 2026-09-09 at `:

- `23.50.34.png` / `23.51.02.png`: preferencia inicial y dos incrementos de texto. Tinta de fila
  crece de 180×28 a 209×34 px; Histórico de 126×24 a 145×29 px (umbral RGB mínimo >180,
  cajas nativas fila 635,310–875,395 e Histórico 150,280–360,380). Confirma escalado en las dos
  clases de los seis avisos; no seis pruebas repetidas. Dos decrementos restauran la preferencia.
- `23.53.52.png`: listado sin resaltados Inspector. Buscador #A3A3A3 sobre #191919 =6,970:1;
  icono toolbar #F4F3F4 sobre #191919 =15,885:1. Superficie circular visible de Cerrar sesión y
  Añadir: 88×88 px =44×44 pt, con separación visible. Son dimensiones renderizadas, no bounds AX
  ni una prueba de activar Cerrar sesión. Se combinan con Hit Region sin avisos y prueba táctil previa.
- `23.53.37.png`: error obligatorio plenamente expuesto, #FF6B63/#2C2C2E =5,001:1. Mismo estilo
  ErrorInk/fondo del formulario ya medido en cuatro apariencias; no repetir cuatro series equivalentes.
- `23.55.32.png`: confirmación nativa. Acción visible aproximadamente 512×96 px =256×48 pt;
  Cancelar/Guardar del formulario tienen aproximadamente 88 px/44 pt de alto y ancho superior.
  Cancelación por región externa confirmada nuevamente; no se ejecuta Desactivar.

Hallazgo de contraste adicional al medir el diálogo: texto nativo Desactivar #FF4246 frente al fondo
muestreado #292C2A =4,113:1. No usa ErrorInk del botón del formulario. No se declara Pasa para texto
normal; falta verificar tamaño/peso efectivo o disposición del control nativo antes de clasificar/corregir.
Captura y source `.confirmationDialog` con `Button(role: .destructive)` permiten reproducirlo.

Foco: Tab/cursor con CUA no produjo un indicador de navegación medible; sí se observó caret en búsqueda
 y nombre inválido. No se usa el resaltado verde/naranja del Inspector como foco de la app. Se conserva
la prueba funcional de teclado del propietario; contraste del indicador sigue sin captura válida.
Ajustes del Simulator consultados sin modificar: apartado motor no muestra Acceso total con teclado.
Capture Keyboard probado temporalmente y restaurado a 0. Inspector cerrado para quitar overlays;
app restaurada al listado, cliente conservado. No se declara bloque 1 completamente aprobado.

Revisión focal independiente del bloque 1: escalado dispuesto con evidencia contraria al aviso;
geometría visible + Hit Region + pruebas previas se consideran muestreo proporcionado. Potencial P2
abierto en contraste de confirmación: obtener tipografía efectiva; si no se acredita texto grande,
proponer corrección para 4,5:1. No hay excepción automática por ser nativo. Única ayuda solicitada para
foco: captura normal de Añadir enfocado con la configuración de teclado ya usada, sin Inspector y sin
activar nada. Huella pre/post revisión, 446 archivos, idéntica:
`db33843f7d9ccd0dd9849b8a9fc0ab9f3a7f4a58afc140ed47148fcf6af69fe8`.
Fuente/tamaño del diálogo no expuestos por CUA ni herramienta de depuración Xcode disponible;
no se altera código para afirmar un resultado no observado. Governanza y diff-check PASS.


## Foco aportado por propietario — 2026-09-10 00:32–00:36

Capturas normales del propietario, apariencia clara. La primera es la muestra solicitada: Añadir
con indicador de teclado visible; no es un overlay de Inspector. Archivos locales:
- `/Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 0.32.50.png` (796×916).
- `/Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 0.33.14.png` (formulario).
- `/Users/jesusf/Desktop/Captura de pantalla 2026-09-10 a las 0.36.06.png` (confirmación).

Primera captura, ICC convertido a sRGB: banda de foco #C243A4 frente a fondo exterior muestreado
#E4E4E9 =3,577:1, frente al interior #F8F8F9 =4,271:1. Banda oscura #6B1557 frente al exterior
=8,862:1. Muestreo suficiente del indicador solicitado, unido al recorrido funcional previo; se retira
la petición de captura de foco. No extrapola a toda apariencia ni mide targets a partir de este recorte.
Las otras capturas muestran contexto de foco en formulario/confirmación; no demuestran la tipografía
efectiva del diálogo ni resuelven su ratio oscuro4,113:1. No solicitar nuevas capturas del mismo foco.
Pendientes: disposición de contraste del diálogo por el agente y lectura inicial fallida/Reintentar
con VoiceOver. Sin cambios ejecutables; validación documental N/A build/tests.


## Corrección de contraste de confirmación — 2026-09-10 00:54

Xcode Debug View Hierarchy expuso el UILabel de Desactivar: .SFUI-Medium 16 pt, systemRedColor.
El ratio oscuro previo 4,113:1 no alcanza 4,5:1; queda confirmado el defecto y sustituida la
incertidumbre tipográfica anterior. Una prueba mínima de foregroundStyle en confirmationDialog
fue ignorada por el sistema y retirada antes de implementar la alternativa revisada.

ClientFormScreen presenta ahora ClientDeactivationConfirmationView en popover nativo, con adaptación
vertical a sheet, Cancelar explícito, rol destructivo y colores opacos ErrorInk/Surface. Reutiliza
recursos, estado y operación existentes. Foco inicial limitado a VoiceOver, título encabezamiento,
labels pulsables de altura mínima 44 pt más padding y contenido desplazable cuando falta altura.
Propuesta y revisión estática final independientes por close083_accessibility: PASS. El revisor
no escribió archivos ni operó UI; no se aporta digest pre/post completo para esta segunda revisión.

Build Xcode MCP PASS 13,683 s, log BuildProject-Log-20260910-005002.txt; único warning encontrado:
AppIntents metadata extraction skipped, ya existente. No se afirma cero warnings globales.
Previews renderizadas e inspeccionadas: Large Light, AX 5 Dark, XXX Large Light Increased Contrast,
Large Dark Increased Contrast; texto sin truncamiento. Artefactos RenderPreview_result_2026-09-09T
225036Z, 225045Z, 225143Z y 225144Z (@3x.png), directorio ActionArtifacts/default/RenderPreview.
Ratios calculados de los assets opacos ErrorInk/Surface: Light 5,244; Dark 5,001; Light High 7,367;
Dark High 8,411. Estas medidas de recursos y previews no son auditoría Inspector del nuevo popover.

Runtime iPhone 17e/iOS 26.5, sesión sintética: encabezamiento, mensaje y ambos botones expuestos;
Cancelar conserva formulario y datos; reabrir y confirmar cierra formulario y vuelve a No hay clientes.
Captura nativa: /Users/jesusf/Desktop/Simulator Screenshot - iPhone 17e - 2026-09-10 at 00.53.40.png.
Pendiente VoiceOver focal del nuevo modal (entrada, Cancelar/retorno y confirmación/anuncio), además
R09 lectura inicial fallida/Reintentar. No repetir CRUD completo ni el fallo de guardado ya validado.
Fixture signed-out del scheme permanece local. Sin PR, merge, cierre ni avance de subfase.


## Corrección de posición tras IMG_1250 — 2026-09-10

El propietario rechaza la disposición del popover: arriba a la izquierda, sobre la barra del formulario.
La comprobación anterior de contraste/semántica no acreditaba una presentación visual adecuada.
Sustituido por sheet nativa con detents medium/large y large para tamaños de accesibilidad, ancho
flexible y alineación superior. Mantiene colores, roles, Cancelar, escape y operación existente.
Propuesta independiente focal PASS. Build MCP PASS 8,469 s, BuildProject-Log-20260910-082837.txt;
único warning encontrado AppIntents metadata ya existente. Previews de presentación real inspeccionadas
062920/062928: hoja inferior estándar y hoja grande AX5; en AX5 contenido desplazable para acciones.
No se acreditan todavía presentación iPad, cierre interactivo ni retorno/anuncios VoiceOver de la sheet.
IMG_1250 muestra foco en encabezamiento del popover anterior; no extrapolar ese foco a esta versión.
Siguiente paso: confirmar apariencia corregida y retest VO focal; R09 lectura/reintento sigue pendiente.


## Jerarquía, botones y altura tras IMG_1251 — 2026-09-10

El propietario rechaza título poco destacado, botones sin delimitación y vacío inferior de la sheet.
Corregido en ClientDeactivationConfirmationView: título title2 bold, botones headline delimitados
por contornos redondeados y área mínima de 52 pt. Cancelar usa borde TextSecondary y Desactivar
ErrorInk sobre Surface. Ratios calculados contra Surface (Light/Dark/Light High/Dark High):
borde Cancelar 4,555/5,206/10,042/11,183; borde Desactivar 5,244/5,001/7,367/8,411.

La prueba de form.fitted aislado no redujo la altura de iPhone. Se usa onGeometryChange sobre
contenido intrínseco con padding para detent height, estado exclusivamente visual redondeado;
AX conserva large y ScrollView. No se añade lógica de negocio ni tests unitarios de geometría.
Fuente Apple consultada: https://developer.apple.com/documentation/swiftui/view/presentationsizing(_:).
Build MCP085713 PASS7,232 s; único warning encontrado AppIntents metadata previo. Preview normal
Dark065745 inspeccionada: hoja compacta, título jerárquico y botones delimitados. Los overrides
sobre una sheet no acreditan AX5 si la captura conserva el tamaño normal; no inferir por el nombre.
Propuesta y revisión estática final independientes PASS. Huellas pre/post del alcance Swift idénticas:
View07691027ff52aac0c265b166625bbe5345dad9ea37aec5acf201f92cddcb409d;
Screen29a65239af2a59a7b815a3b21f77a9fd2514f1fd9d9d183a37a2032ada216c55.
Pendientes aceptación visual física, adaptación iPad y VoiceOver focal/R09; sin cierre ni entrega.

Preview AX5 explícita065911 inspeccionada: título y contenido grandes sin truncamiento horizontal;
Desactivar queda parcialmente fuera del viewport inicial, con ScrollView declarado. Alcance por
desplazamiento y VoiceOver pendiente de runtime; no se afirma desde esta imagen.


### Ajuste final solicitado: título centrado — 2026-09-10

Propietario acepta la disposición con ajuste de centrado del título. Añadidos exclusivamente
multilineTextAlignment(.center) y frame(maxWidth: .infinity) al título; conserva semántica/foco.
Propuesta focal independiente PASS; build Xcode MCP092935 PASS8,092 s, aviso AppIntents previo.
No repetir pruebas funcionales por alineación. VoiceOver focal/R09 siguen pendientes.


### VoiceOver de confirmación actual — reporte del propietario 2026-09-10

Recorre todos los elementos de la sheet correctamente. Empieza por «Tirador de la hoja, media
pantalla, botón, toca dos veces para cerrar la hoja»; restantes elementos correctos según reporte.
El componente declara presentationDragIndicator(.visible): el tirador pertenece a la presentación
nativa. No se acredita foco inicial en título aunque exista AccessibilityFocusState. El recorrido
por el tirador no bloquea el contenido. No se infiere todavía ejecución del cierre, retorno de foco
ni confirmación/anuncio de la versión actual. Próximo paso focal: Cancelar y retorno al formulario.


VoiceOver, propietario 2026-09-10: Cancelar en la sheet actual cierra únicamente la confirmación
y devuelve el foco a Desactivar cliente del formulario. Confirmado por reporte manual; no acredita
aún confirmar/desactivar y anuncio de esta versión. Siguiente paso focal: confirmar una vez.


### Confirmación efectiva con VoiceOver — propietario, 2026-09-10

Al cerrar la confirmación comienza una locución «cliente desa…» que se interrumpe; después se
cierra el formulario y en el listado escucha «Cliente desactivado» completo y «No hay clientes».
Resultado final, desactivación y retorno contextual confirmados por reporte. Se registra la
interrupción transitoria como observación no bloqueante, sin atribuir causa ni duplicado de éxito.
Inspección actual: una única emisión explícita de éxito en ClientListScreen.restoreFormFocus/onDismiss.
Revisión independiente focal read-only: no defecto adicional demostrado; no modificar sincronización
ni repetir el recorrido cuando el resultado final completo y el destino están confirmados.
R09 lectura inicial fallida/reintento sigue pendiente. Solo documentación; build/tests N/A.


### R09 preparado para prueba guiada — 2026-09-10 12:43

Autorización «preparala entonces». Harness TEMPORAL en App/AppDependencies+ClientForm.swift:
InitialReadFailureRepository privado, aislado por actor, falla primer client(id:) por formulario
con persistenceUnavailable y luego delega. Task.checkCancellation precede al consumo del fallo.
Gates FRANALONSO_AUTH_FIXTURE + ApplicationLaunchPlan.authenticationFixture. Lista y adapter
mutador intactos; alta normal, abrir edición produce error y Reintentar carga perfil existente.
No valida VoiceOver por sí mismo. Propuesta independiente PASS; prueba manual pendiente.

Xcode MCP27: Develop, iPhone14 de Jesús/iOS26.6.1, SDK27, argumento signed-out activo.
Build124238 PASS8,429s, único warning encontrado AppIntents metadata previo. RunProject124255
PASS3,577s, app lanzada PID15053. No se modifican plist/pbxproj locales ajenos ni scheme.

Restaurar únicamente AppDependencies+ClientForm.swift tras la prueba y recompilar:
original /tmp/franalonso-r09-clientform-original.swift
SHA256 25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182.
Harness preparado SHA256 7890ff55aab238baf41afbf4ba123606a50fceff42b6e75df081bbe70531ad28.
Excluir este archivo temporal de cualquier entrega; comprobar que no hay cambios posteriores ajenos
antes de restaurar. No commit/push/PR/cierre/live.

Revisión final del harness PASS read-only; SHA preparado idéntico pre/post. Gobernanza detecta
enlaces históricos a artefactos temporales/capturas que ya no existen localmente; no se declara PASS.
Reconciliación de esos enlaces pendiente antes de entrega; diff-check pasa.


### R09 confirmado y harness retirado — 2026-09-10 12:55

Propietario confirma Reintentar → campos cargados con datos y recorribles por VoiceOver; Cancelar
→ listado con foco en el cliente abierto. Recorrido R09 de lectura fallida/reintento/retorno confirmado
por reporte manual, sin atribuir anuncio inicial exacto no transcrito. No repetir prueba.

Harness restaurado byte a byte desde copia verificada: AppDependencies+ClientForm.swift SHA original
25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182, diff contra HEAD vacío.
Mejora visual prometida tras IMG1252: Reintentar usa primaryActionStyle existente (cápsula rellena),
conserva texto, minHeight44, acción y disabled. Ratios de assets OnBrandPrimary/BrandPrimary
4,945/9,812/10,554/12,280. Propuesta y revisión final focal read-only PASS.
Build MCP125405 PASS8,46s, warning AppIntents previo. Preview Load failure12:55:29 inspeccionada,
iPhone18Pro/iOS27, control visiblemente delimitado; primer render agotó tiempo y reintento pasó.
RunProject125546 PASS8,152s en iPhone14: app relanzada sin inyección del error.
Solo resta reconciliar evidencia/límites y entrega autorizada; no se declara subfase cerrada.
Los enlaces históricos a artefactos eliminados siguen pendientes de reconciliación documental.
