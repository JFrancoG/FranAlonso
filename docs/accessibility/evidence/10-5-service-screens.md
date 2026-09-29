# 10.5 — Catálogo, lista y formulario de servicios

2026-09-30. Registro de construcción y validación progresiva bajo [ADR 0022](../../ADRs/0022-native-ios-wcag22-accessibility.md)
y [ADR 0029](../../ADRs/0029-progressive-accessibility-validation.md). **No acredita validación integral** ni, por sí solo,
el cierre de la puerta funcional.

Implementación [PLU-64](https://linear.app/plusprojects/issue/PLU-64); deuda propia
[PLU-65](https://linear.app/plusprojects/issue/PLU-65/105-complete-deferred-service-screen-accessibility-validation),
Backlog, Jesus Franco, vinculada a fase 10/PLU-59. Recuperar tras feedback de Fran y estabilización de cada flujo,
siempre antes del primer candidato para uso real y del cierre integral. No absorbe deuda de fase 08 ni PLU-54/57.

## Alcance e inspección estática

CatalogScreen/CatalogViewModel, ServiceListScreen/Content/Row y ServiceFormScreen/Content/Feedback. Incluye entrada a los
dos catálogos, búsqueda, hoja de alta/edición, descarte, desactivación, progreso, errores y resultados tras el cierre.
El formulario mantiene tipo y vínculo como información: selección/sustitución corresponde a 10.6. Los nombres e importes
son datos de negocio; el vínculo no expone UUID ni afirma disponibilidad actual del producto.

Inspección del código de implementación, sin ejecución de tecnologías de asistencia:

- NavigationStack con destinos tipados, controles nativos y rótulos persistentes. Filas, inputs y acciones de lista/
  formulario solicitan 44 pt en código. Esa petición de layout **no equivale a medir** la superficie operable real.
- Filas multilínea con nombre, tipo, precio Decimal formateado según moneda/Locale e Inactivo textual. Recursos semánticos
  textPrimary, textSecondary y errorInk; no se han medido ratios de contraste de la composición resultante.
- Form con nombre, tipo, precio, moneda EUR/USD, impuesto y descuento. Inputs conservan el borrador textual; nombre/precio/
  impuesto/descuento reciben errores próximos y asociación mediante hint. Validación por intento explícito dirige foco.
- Teclado decimal nativo y botón Listo; scroll vertical y dismiss interactivo del teclado. Queda pendiente comprobar la
  superficie con teclado software visible y texto AX5; la existencia del botón no acredita toda la operación por teclado.
- Cancelar confirma descarte cuando procede; desactivar confirma conservación del historial y descarte de cambios sin
  guardar. El gesto de cierre no descarta el formulario. Guardado/desactivación bloquean acciones superpuestas.
- Resultado comunicado después del dismiss, restauración nativa y solicitud de foco en Añadir tras creación/desactivación;
  no hay timers ni reintentos de foco. Los anuncios programados no demuestran su entrega u orden reales.
- Copy es/en en String Catalog; Locale del formulario fijado por sesión. Previews deterministas con AppPreviewModifier
  declarados para Catálogo, lista/carga/vacío/uno/volumen/sin resultados/error y formulario/errores/progreso.

## Evidencia de ejecución

Xcode MCP: Develop/iPhone18Pro/iOS27, 1.061 declaraciones/1.520 resultados PASS, xcresult nativo cerrado.
Production build PASS21,301s; sin errores ni warnings Swift/Clang nuevos, aviso AppIntents metadata conocido.
Previews renderizados e inspeccionados en iPhone18ProMax/iOS27.2, destino devuelto por Xcode. La variante de localización
no se ofrece (lista vacía); ES de entorno y previews EN explícitos en Content/Row, sin inventar override soportado.

| Evidencia | Estado del registro | Condición para completarla |
|---|---|---|
| Build/tests Xcode MCP | PASS técnico. | [Evidencia 10.5](../../progress/phase-10.md), no demuestra AT. |
| Previews Large/XXX Large/AX5 | Render e inspección representativos PASS. | Catálogo/lista/formulario, Light/Dark y contraste incrementado; no matriz exhaustiva. |
| Smoke táctil de demo | PASS funcional, iPhone18Pro/iOS27. | Ambos catálogos, búsqueda, alta inválida/válida, editar/descartar y desactivar/reabrir; sin teclado software visible ni AT. |
| Inspector y medición de contraste/hit area | Pendiente, PLU-65. | Cuatro apariencias y superficie operable real. |
| VoiceOver/Voice Control/Switch Control/FKA | Pendiente, PLU-65. | Orden/restauración del foco, anuncios y operación del recorrido. |
| iPad, ventanas, orientación, RTL y preferencias | Pendiente, PLU-65. | Matriz por impacto; no extrapolar una captura de iPhone. |
| POST independiente | Estándares PASS; P2 de copy corregido y rerevisión UI funcional PASS. | Revisión read-only sobre660archivos; detalle en fase10. |

Puerta funcional ADR 0029 PASS tras corregir el P2 y verificar la rerevisión focal; validación integral pendiente.
PLU-65 conserva la matriz integral restante; aplazar no convierte Pendiente/Limitado/Falla en Pasa o N/A.

## Smoke funcional y corrección de revisión

Sesión Xcode MCP «Service Catalogue Smoke», iPhone18Pro/iOS27, 30/09/2026 00:10–00:14; cerrada al terminar.
Login sintético, Servicios/Productos, búsqueda «Corte», alta inválida→válida (12,50 EUR, impuesto21), descarte confirmado
y reapertura sin cambios, edición del servicio producto conservando tipo/precio/mensaje de vínculo, desactivación y
reapertura Inactivo: PASS funcional. La identidad exacta del producto se acredita por integración, no por el texto de UI.
Informe `/tmp/franalonso-105-smoke.md`. Capturas/jerarquías bajo
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/DeviceInteractionSynthesize/`, prefijo
`Service Catalogue Smoke-`, sufijos `-hierarchy.txt` / `-screenshot.png`:

| Estado | Marca del artefacto |
|---|---|
| Catálogo / Productos / Servicios | 00_10_51_657 / 00_11_00_273 / 00_11_14_899 |
| Buscar / error / alta guardada | 00_11_40_691 / 00_12_00_382 / 00_12_50_891 |
| Confirmación descarte / reapertura | 00_13_12_993 / 00_13_28_888 |
| Producto antes / editado / reabierto | 00_13_40_500 / 00_13_53_388 / 00_13_59_452 |
| Confirmación desactivar / lista inactivo / reabierto | 00_14_11_922 / 00_14_23_121 / 00_14_30_256 |

POST accesibilidad: único P2 en 3.3.3, el error de vínculo ofrecía desactivar aun estando inactivo. Se corrige en ES/EN
para indicar Cancelar y volver al catálogo, acción disponible en ambos estados. No se transfiere como defecto pendiente.
Rerevisión focal PASS sin hallazgos nuevos; root dispone el P2 corregido. Huella read-only660archivos POST2,
SHA256 `9be48c48b23516b9262220b74a4eb0a5de1d3a6183bc3aeabf31d543ee5efabc`, sin cambios Swift respecto a POST1.
3.3.3 permanece Limitado: esta corrección no acredita validación integral runtime ni el resto de estados con AT.
Build Develop PASS16,081s tras la corrección; solo aviso AppIntents conocido. Render focal ES inspeccionado:
`Linked product unavailable - 2026-09-30 at 00.17.49.png` en el directorio RenderPreview ya registrado, Large,
iPhone18ProMax/iOS27.2. El mensaje corregido es visible completo. EN verificado en recursos; sin cambios de Swift.
No se repite la suite: solo cambian dos valores localizados, sin cambiar claves, código ni contratos.
La disposición con teclado software visible queda pendiente en PLU-65 porque el smoke usó teclado hardware.

## Matriz completa de 55 criterios A/AA

Artefactos locales en `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.
Catálogo conserva títulos/rótulos multilínea; AX5 puede dividir palabras, sin truncado. La lista AX5 capturó carga
en dos renders: su contenido se inspeccionó en el preview determinista de250 elementos. Edit product XXX Large
capturó carga primero y contenido en el segundo. Formulario AX5 conserva scroll; el resto de campos fuera del viewport
no se considera validado operativamente por la captura. No se infieren ratios de contraste ni entrega de anuncios.

| Preview | Dynamic Type | Archivo PNG |
|---|---|---|
| Catalogue | Large | Catalogue - 2026-09-30 at 00.06.29.png |
| Catalogue | XXX Large | Catalogue - 2026-09-30 at 00.06.30.png |
| Catalogue | AX 5 | Catalogue - 2026-09-30 at 00.07.03.png |
| ServiceListScreen | Large | ServiceListScreen - line 135 - 2026-09-30 at 00.07.29.png |
| ServiceListScreen | XXX Large | ServiceListScreen - line 135 - 2026-09-30 at 00.07.29 2.png |
| ServiceListScreen | AX 5 | ServiceListScreen - line 135 - 2026-09-30 at 00.07.30.png |
| Create | Large | Create - 2026-09-30 at 00.07.56.png |
| Edit product | XXX Large | Edit product - 2026-09-30 at 00.07.56.png |
| Edit inactive | AX 5 | Edit inactive - 2026-09-30 at 00.07.57.png |
| ServiceListScreen | AX 5 | ServiceListScreen - line 135 - 2026-09-30 at 00.08.16.png |
| Saving | Large | Saving - 2026-09-30 at 00.08.29.png |
| 250 services | AX 5 | 250 services - 2026-09-30 at 00.08.43.png |
| Product | XXX Large | Product - 2026-09-30 at 00.08.58.png |
| Edit product | XXX Large | Edit product - 2026-09-30 at 00.09.13.png |


Cubre las tres pantallas y sus transiciones. Todas las filas comparten fecha 30/09/2026 y método estático salvo indicación
expresa. Dispositivo/iOS/build: **no atribuido para esta inspección de código**; los destinos
reales de ejecución se registran arriba. Revisores: implementador y agentes independientes; POST y rerevisión focal finalizados.

N/A clasifica ausencia justificada del mecanismo y exige reevaluación si cambia el alcance. Limitado significa solo
construcción/inspección estática en esta versión del registro, sin declarar una prueba runtime superada.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método y pendiente | Disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Labels nativos para acciones; iconos decorativos ocultos y filas agrupadas. | Limitado | Estática; completar Inspector y VoiceOver. | PLU-65 antes de uso real y cierre integral. |
| 1.2.1 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.3 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.4 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.5 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.3.1 | Aplicable | List, Form, Section y etiquetas persistentes; el tipo conserva nombre y valor accesibles. | Limitado | Estática; verificar relaciones y rotor en runtime. | PLU-65 antes de uso real y cierre integral. |
| 1.3.2 | Aplicable | Orden declarado: nombre, tipo, precio, moneda, impuesto, descuento y desactivación. | Limitado | Estática; recorrido lineal VoiceOver y teclado pendiente. | PLU-65 antes de uso real y cierre integral. |
| 1.3.3 | Aplicable | Errores y acciones se nombran en texto; ninguna instrucción depende solo de color o posición. | Limitado | Estática; revisar comprensión en el recorrido real. | PLU-65 antes de uso real y cierre integral. |
| 1.3.4 | Aplicable | El delta no añade bloqueo de orientación; falta evidencia por orientación y ventana. | Pendiente | iPhone/iPad, portrait/landscape y multitarea. | PLU-65 antes de uso real y cierre integral. |
| 1.3.5 | N/A | Datos de catálogo comercial; no se solicitan datos personales con propósito de autofill. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.4.1 | Aplicable | Inactivo y errores tienen texto; progreso tiene etiqueta; no se depende solo de color. | Limitado | Estática; Differentiate Without Color pendiente. | PLU-65 antes de uso real y cierre integral. |
| 1.4.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.4.3 | Aplicable | Se usan recursos textPrimary, textSecondary y errorInk; no hay medición del contraste resultante. | Pendiente | Medir texto en Light/Dark y contraste normal/incrementado. | PLU-65 antes de uso real y cierre integral. |
| 1.4.4 | Aplicable | Fuentes semánticas y texto multilínea; títulos compactos y controles alternativos en tamaño accesible. | Limitado | Renders Large/XXX Large/AX5 inspeccionados; operación integral AX5 pendiente. | PLU-65 antes de uso real y cierre integral. |
| 1.4.5 | Aplicable | Nombres, importes, estados y acciones usan Text; no hay imágenes de texto en el alcance. | Limitado | Estática y renders representativos; revisión integral pendiente. | PLU-65 antes de uso real y cierre integral. |
| 1.4.10 | Aplicable | List y Form desplazan verticalmente; las filas y etiquetas permiten varias líneas. | Limitado | Estática; ventanas estrechas, iPad y AX5 pendientes. | PLU-65 antes de uso real y cierre integral. |
| 1.4.11 | Aplicable | Controles nativos y colores semánticos; no se han medido estados, bordes ni símbolos esenciales. | Pendiente | Medir contraste no textual en las cuatro apariencias. | PLU-65 antes de uso real y cierre integral. |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de override de espaciado de autor. | N/A | Inspección de tecnología. | Reevaluar si aparece el mecanismo. |
| 1.4.13 | N/A | No hay contenido propio adicional activado por hover/foco; menús y diálogos exigen acción explícita. | N/A | Inspección de interacción; reevaluar si se añade hover/foco. | Reevaluar si aparece el mecanismo. |
| 2.1.1 | Aplicable | Acciones nativas; botón Listo permite cerrar el teclado decimal por toque. | Pendiente | Full Keyboard Access y teclado externo en cada campo/acción. | PLU-65 antes de uso real y cierre integral. |
| 2.1.2 | Aplicable | Formulario modal con cancelación explícita; el cierre por gesto está deshabilitado. | Pendiente | Verificar entrada/salida por teclado y Switch Control, incluidos diálogos. | PLU-65 antes de uso real y cierre integral. |
| 2.1.4 | N/A | No se añaden atajos propios de un solo carácter. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.2.1 | N/A | No hay límite temporal ni expiración de la edición o confirmación. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.2.2 | N/A | Sin medio/carrusel automático; progreso nativo de operación y observación local sin movimiento propio. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.3.1 | Aplicable | El código del alcance no añade destellos ni animaciones propias. | Limitado | Estática; inspección visual y preferencias pendiente. | PLU-65 antes de uso real y cierre integral. |
| 2.4.1 | Aplicable | Catálogo separa Servicios/Productos; lista buscable y formulario estructurado con secciones. | Limitado | Estática; acceso al contenido y rotor pendientes. | PLU-65 antes de uso real y cierre integral. |
| 2.4.2 | Aplicable | Títulos de Catálogo, Servicios y formulario localizado; Nuevo/Editar compactos en AX. | Limitado | Estática; anuncio de destino y contexto en runtime pendiente. | PLU-65 antes de uso real y cierre integral. |
| 2.4.3 | Aplicable | Validación dirige foco al campo; tras dismiss se solicita Añadir al crear/desactivar, sin timers. | Pendiente | Verificar foco inicial, errores, confirmaciones, sheet y retorno con AT. | PLU-65 antes de uso real y cierre integral. |
| 2.4.4 | Aplicable | Acciones explícitas Añadir, Guardar, Cancelar, Reintentar y Desactivar servicio. | Limitado | Estática; lista de acciones accesibles en runtime pendiente. | PLU-65 antes de uso real y cierre integral. |
| 2.4.5 | Aplicable | Colección potencialmente extensa con navegación Catálogo/Servicios y búsqueda local por nombre. | Limitado | Estática; navegación/búsqueda y volumen en runtime pendientes. | PLU-65 antes de uso real y cierre integral. |
| 2.4.6 | Aplicable | FormFieldSection conserva rótulo visual y cada input recibe su etiqueta accesible. | Limitado | Estática; árbol accesible y rotor pendientes. | PLU-65 antes de uso real y cierre integral. |
| 2.4.7 | Aplicable | Controles nativos; no hay evidencia de foco visible con teclado/puntero. | Pendiente | Full Keyboard Access y puntero en superficies compatibles. | PLU-65 antes de uso real y cierre integral. |
| 2.4.11 | Aplicable | Formulario desplazable; campos numéricos usan decimalPad y toolbar Listo. | Pendiente | Teclado software visible, scroll, sheets y confirmaciones en AX5. | PLU-65 antes de uso real y cierre integral. |
| 2.5.1 | N/A | Ninguna acción exige gesto multipunto o de trayectoria; el desplazamiento usa controles nativos. | N/A | Inspección de interacción. | Reevaluar si aparece el mecanismo. |
| 2.5.2 | Aplicable | Mutaciones mediante Button y confirmaciones explícitas, sin acciones propias al down-event. | Limitado | Estática; cancelación táctil real pendiente. | PLU-65 antes de uso real y cierre integral. |
| 2.5.3 | Aplicable | Nombres accesibles alineados con rótulos; Guardar/Cancelar conservan etiqueta al mostrarse como iconos AX. | Limitado | Estática; activación por nombre con Voice Control pendiente. | PLU-65 antes de uso real y cierre integral. |
| 2.5.4 | N/A | Sin acciones activadas por agitar o mover el dispositivo. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.5.7 | N/A | No se exige arrastre; selección, búsqueda, edición y cierre tienen controles simples. | N/A | Inspección de interacción. | Reevaluar si aparece el mecanismo. |
| 2.5.8 | Aplicable | Código solicita mínimo 44 pt en entradas/filas y acciones propias; no se ha medido superficie operable. | Limitado | Medir hit area real y separación, incluidas barras, menús y diálogos. | PLU-65 antes de uso real y cierre integral. |
| 3.1.1 | Aplicable | Recursos es/en; Locale del entorno se captura en la sesión y se usa en importes/anuncios. | Limitado | Estática; pronunciación, formatos y errores en ambos idiomas pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.1.2 | N/A | Copy monolingüe localizado; los nombres de servicio son contenido introducido por la persona. | N/A | Inspección de alcance; reevaluar contenido multilingüe propio. | Reevaluar si aparece el mecanismo. |
| 3.2.1 | Aplicable | Recibir foco no solicita carga, guardado, desactivación ni navegación. | Limitado | Estática; recorrido de foco con AT pendiente. | PLU-65 antes de uso real y cierre integral. |
| 3.2.2 | Aplicable | Editar campos conserva el borrador; guardar/desactivar exigen una acción explícita. | Limitado | Estática; interacción y reintento en runtime pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.2.3 | Aplicable | Catálogo ofrece dos destinos estables; lista/formulario reutilizan el patrón de productos. | Limitado | Estática; comparar navegación completa y retorno pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.2.4 | Aplicable | Acciones compartidas mantienen recursos, roles y posición del patrón de formularios. | Limitado | Estática; comprobación de identificación con AT pendiente. | PLU-65 antes de uso real y cierre integral. |
| 3.2.6 | N/A | No se añaden mecanismos de ayuda repetidos; las instrucciones pertenecen a cada campo. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 3.3.1 | Aplicable | Feedback asocia nombre/precio/impuesto/descuento a su campo; otros errores se muestran como generales. | Limitado | Estática; foco, anuncio y asociación programática reales pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.3.2 | Aplicable | Labels persistentes y ayudas para precio con impuestos, porcentajes y descuento opcional. | Limitado | Estática; lectura y operación del formulario pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.3.3 | Aplicable | Errores explican corrección de campos y reintento; vínculo no disponible no promete selector inexistente. | Limitado | Estática; casos inválidos, corrección y errores de guardado pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.3.4 | Aplicable | Descarte/desactivación requieren confirmación; guardar explícito, operaciones solapadas bloqueadas. | Limitado | Estática; cancelar/confirmar y conservar datos persistidos pendientes. | PLU-65 antes de uso real y cierre integral. |
| 3.3.7 | Aplicable | Carga rellena la ficha y errores conservan borrador; no se exige reintroducir campos correctos. | Limitado | Contrato 10.4 reutilizado; verificar el recorrido visual. | PLU-65 antes de uso real y cierre integral. |
| 3.3.8 | N/A | Este delta no cambia autenticación; la deuda de ese flujo conserva su ámbito original. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 4.1.2 | Aplicable | TextField, Picker, Button y NavigationLink nativos; estado inactivo y tipo como texto. | Limitado | Estática; Inspector, VoiceOver y Voice Control pendientes. | PLU-65 antes de uso real y cierre integral. |
| 4.1.3 | Aplicable | Anuncios de error, búsqueda sin resultados y resultado tras dismiss; progreso visible con etiqueta. | Limitado | Estática; comprobar anuncios reales, prioridad y ausencia de duplicados. | PLU-65 antes de uso real y cierre integral. |

## Recuperación de la deuda y límites

Jesus Franco coordina PLU-65 tras revisar con Fran cada flujo estabilizado. Registrar dispositivo, versión/build, idioma,
preferencias, método, artefacto, resultado y revisor para cada comprobación; corregir hallazgos por impacto y repetir solo
lo afectado. Si un defecto impide operar el recorrido de demo, incluido con la tecnología que necesite su participante,
bloquea la puerta funcional y no se difiere automáticamente.

Cambios posteriores de textos, selector de producto, navegación o componentes compartidos reabren la aplicabilidad y
validación correspondiente. El cierre funcional de PLU-64 no cierra PLU-65, la fase 10 ni deudas de otros flujos. Ninguna
captura, árbol estático o test de ViewModel demuestra por sí solo VoiceOver, foco, rotor o conformidad integral.
