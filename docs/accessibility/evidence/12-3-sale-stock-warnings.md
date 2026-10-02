# 12.3 — Avisos visuales de stock

2026-10-02, [PLU-88](https://linear.app/plusprojects/issue/PLU-88), Jesus Franco.
Gate evaluado: entrega funcional para demo según ADR0029, completada por PR44; sin cierre integral.
[ADR0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) /
[ADR0029](../../ADRs/0029-progressive-accessibility-validation.md).
Deuda específica [PLU-89](https://linear.app/plusprojects/issue/PLU-89), Backlog/Jesus Franco:
recuperar tras feedback y estabilización de este recorrido, siempre antes del primer candidato para uso real.
La deuda previa11 permanece separada. Falla, Pendiente y Limitado no equivalen a Pasa ni N/A integral.

## Alcance y métodos

SaleStockWarningView, SaleDraftLineRow, SaleDraftContent y SaleDraftScreen; proyección por identidad y
comunicación efímera en SaleDraftViewModel. Términos capturados → aviso → Stepper/acciones. Stock exacto0 no
advierte; déficit acumulado de producto repetido sí; profesional sin vínculo no presenta aviso. No bloqueo, pago,
confirmación12.4, movimiento ni sync. Unknown/loading/failed no publican impacto obsoleto ni afirman suficiencia.

- S: revisión fuente y catálogo es/en. Símbolo decorativo oculto; nombre contiene mensaje visible y servicio.
  Font subheadline, wrapping/fixedSize vertical, ErrorInk adaptativo, sin lineLimit. Alturas44pt existentes.
- T: baseline30/30; RED antes de implementar APIs/copy; GREEN37/37; regresión191/191 y recursos38/38.
  iPadPro13(M5) Simulator27.2/Develop, SDK/target27.0/Swift6,02/10. Ver bundles en [fase12](../../progress/phase-12.md).
  Tests de nuevas identidades, dedup, recuperación ready, estados desconocidos/close/inspect, total/controles.
  No test UI/AT nativo; pruebas de lógica no acreditan Announcement hablado ni orden de foco.
- P: diez PNG originales de Xcode MCP conservados en [manifest](assets/12-3/manifest.json), sin editar.
  Host iPhone18ProMax27.2; workspace seleccionado iPhone17, Develop; Large/XXX Large/AX5, es/en,
  cuatro apariencias representativas. Locale override cambia idioma, no prueba región/separador en inglés.
  Fixtures nuevas App/in-memory aisladas: stock1, qty1 exact0, qty2 repetida→-2 y profesional; nombres sintéticos.
  Trait prepara el modelo async. Constructor fileprivate solo para preview muestra el snapshot listo sin tarea load.
  Previews históricas intactas. Baseline pantalla antigua falló dyld/libSystem en host iPad privado; nueva UI renderiza
  en host descubierto, sin borrar simuladores/caches ni modificar target.
- R: smoke táctil funcional en Simulator completado; configuración y artefactos en el registro siguiente.
- Inspector, AT, dispositivo físico, scroll con AT/foco real y mediciones de contraste: **Pendiente**.
  Reduce Motion/Transparency, Differentiate Without Color, orientaciones/ventanas/iPad/RTL: **Pendiente**.
- Auditorías POST read-only: técnica/estilo sin hallazgos; UI fresca sin defectos nuevos de fuente/capturas.
  P2 documental: operabilidad de demo no respaldada por smoke; afirmación retirada y revisión focal PASS.
  Huella817archivos antes/después idéntica; detalle en fase12.

## Previews inspeccionados

| Artefacto | Estado/configuración | Observación real |
|---|---|---|
| [Pantalla Large](assets/12-3/12-3-screenLarge.png) | es Light normal | Exact0 sin aviso; aviso negativo aparece al final del viewport. |
| [Pantalla XXXL](assets/12-3/12-3-screenXXXL.png) | en Light normal | Título/control nativos legibles; advertencia queda debajo del viewport. |
| [Pantalla AX5](assets/12-3/12-3-screenAX5.png) | es Dark contrast aumentado | Título nativo truncado; Form requiere scroll. Falla visual parcial retenida. |
| [Aviso Large](assets/12-3/12-3-warningLarge.png) | es Light normal | Texto completo y símbolo. |
| [Aviso XXXL](assets/12-3/12-3-warningXXXL.png) | en Light contrast aumentado | Texto completo y permiso para continuar. |
| [Aviso AX5](assets/12-3/12-3-warningAX5.png) | es Dark normal | Texto completo, wrapping y símbolo; sin recorte dentro de celda. |
| [Aviso DarkHC](assets/12-3/12-3-warningDarkHC.png) | es Dark aumentado Large | Cuarta apariencia renderizada, sin ratio medido. |
| [Fila XXXL](assets/12-3/12-3-rowXXXL.png) | en Light normal | Términos, aviso y controles completos, cantidad2 no deshabilitada. |
| [Fila AX5](assets/12-3/12-3-rowAX5.png) | es Dark aumentado | Texto crece, aviso empieza visible; continuidad/acciones requieren scroll real. |
| [Contenido Large](assets/12-3/12-3-contentLarge.png) | es Light normal | Advertencia y Stepper2 visibles, fila exact0 sin aviso. |

La truncación del título nativo en AX5 y el recorrido en esa categoría permanecen en PLU-89.
El bloqueo inicial del Mac quedó superado para el smoke funcional con RocketSim. Las capturas de previews
no acreditan por sí solas scroll; el recorrido táctil siguiente sí se ejecutó en su configuración concreta.
La evidencia integral/foco/lectura exige ejecución posterior; no introduce reintentos de foco.

## Smoke táctil funcional

02/10, root. Simulator iPhone17 (0B3A9F32-B9D5-4ED5-A13F-CB66F7917E75), iOS27.2, Develop instalado desde
el build Xcode MCP ya validado; --franalonso-demo-workday, almacenamiento en memoria y datos sintéticos.
Portrait/light; content_size extra-Small consultado sin cambiar preferencias. RocketSim: taps HID/swipes,
lectura AX y PNG originales inspeccionados. CUA solo permitió omitir guardado de credencial sintética; la
entrada del teclado se corrigió y verificó. CUA volvió a detectar Mac bloqueado, RocketSim completó el flujo.
[Manifest runtime](assets/12-3/runtime/manifest.json) retiene hashes/configuración: cuatro PNG originales y
JSON de snapshots/transiciones con contexto/token local eliminado. No son tests UI nativos ni ejecución AT.

| Comprobación | Resultado observado | Evidencia |
|---|---|---|
| Profesional sin vínculo | Sin aviso al abrir; se conserva su cantidad1 y descuento10%. | [Reapertura](assets/12-3/runtime/reopen-transition.json), observación inicial del recorrido. |
| Físico y agotamiento exacto | Stock8; qty1 y qty8 sin aviso. | [Exact0 PNG](assets/12-3/runtime/exact-zero.png), [snapshot](assets/12-3/runtime/exact-zero.json). |
| Déficit editable | qty9→-1, qty10→-2; se puede seguir editando. | [Aviso-1](assets/12-3/runtime/deficit-minus-one.png), [transiciones](assets/12-3/runtime/quantity-editor-transition.json). |
| Desaparición/reaparición | Reducir10→9→8 retira aviso; aumentar8→9 lo recupera. | [Transiciones](assets/12-3/runtime/quantity-editor-transition.json). |
| Descuento y retorno | Aplicar10% conserva qty9 y aviso-1. | [Retorno PNG](assets/12-3/runtime/discount-return.png), snapshot repetido posterior. |
| Selector y retorno | Abrir/cancelar conserva estado; volver y añadir segunda línea funciona. | Observación táctil; [producto repetido](assets/12-3/runtime/repeated-product.json). |
| Producto repetido | Primera línea qty9→-1; segunda qty1→-2 acumulado. | [PNG](assets/12-3/runtime/repeated-product.png) / [snapshot](assets/12-3/runtime/repeated-product.json). |
| Cerrar/reabrir | Tres servicios, qty9/1, descuento10% y ambos avisos conservados. | [Transición](assets/12-3/runtime/reopen-transition.json) / [snapshot desplazado](assets/12-3/runtime/reopened.json). |
| Cancelar retirada | Popover abierto y dismiss por toque fuera; no se retiró la segunda línea. | Observación táctil, snapshot final igual4792dd62. |

PASS del smoke funcional de PLU-88; revisión focal independiente fresh_ui_post PASS sin hallazgos.
Huella root antes/después827archivos idéntica: detalle en fase12.
Entrega autorizada posteriormente02/10: «commit, push y entrega»; cierre integral sigue pendiente en PLU-89.
No se ejecutaron pago/confirmación12.4 ni lectura integral de movimientos; no se afirma habla, orden de foco,
AT, contraste medido ni scrollAX5. Deuda PLU-89 mantiene resultados y trigger originales.

## Registro de flujos

| Flujo | Evidencia actual | Resultado integral y recuperación |
|---|---|---|
| Cargar borrador deficitario | T/S; preview preparado con déficit | Pendiente: aviso hablado una vez y contexto leído con VoiceOver, PLU-89. |
| Aumentar/disminuir/eliminar/añadir línea | T/S; R cantidad, añadido repetido y cancelación de retirada; scroll táctil | Limitado: AT/scrollAX5 y retirada aceptada pendientes, PLU-89. |
| Refresco externo, fallo/unknown y recuperación | T barrera determinista; no impacto viejo/dedup retenida | Pendiente: publicación/lectura del estado en runtime y recuperación, PLU-89. |
| Selector/descuento → borrador | S; R selector cancelado y descuento10% aplicado conservan estado | Pendiente: orden de retorno/foco/habla real, cancelación y ausencia de duplicados, PLU-89. |
| Reaparición déficit / cierre / inspección | T; R desaparición/reaparición y cerrar/reabrir conservan estado | Pendiente: ausencia de habla tardía tras dismiss y nuevo recorrido, PLU-89. |

## Matriz completa de55criterios

Una fila por criterio y los flujos anteriores comparten el mismo alcance explícito. S/T/P son métodos parciales;
N/A solo describe ausencia justificada del mecanismo en este tramo y se reevalúa al ampliarlo.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | SF Symbol decorativo oculto; Label contiene aviso textual y servicio en nombre accesible. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.2.1 | N/A | Sin audio/vídeo pregrabado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.2 | N/A | Sin audio sincronizado pregrabado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.4 | N/A | Sin contenido audiovisual en directo. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.3.1 | Aplicable | Form/Section y términos agrupados; aviso propio independiente entre términos y controles. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.3.2 | Aplicable | Orden declarado: términos, advertencia, cantidad y acciones; lectura AT pendiente. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.3.3 | Aplicable | Stock insuficiente y permiso para continuar explícitos; no instrucción sensorial. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.3.4 | Aplicable | Sin nuevo bloqueo; landscape, iPad y ventanas relevantes pendientes. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.3.5 | N/A | Aviso sin entrada personal; cantidad comercial. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.1 | Aplicable | ErrorInk adaptativo acompañado de símbolo y texto, sin condición basada solo en color. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.4.2 | N/A | Sin reproducción de audio de la app; Announcement pertenece a AT. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.3 | Aplicable | Cuatro apariencias renderizadas; no se midieron ratios finales nativos. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.4.4 | Aplicable | Aviso completo aislado AX5; formulario/fila necesitan scroll; título truncado AX5. | Falla | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Título nativo AX5 truncado; recuperar en PLU-89. | root registro parcial |
| 1.4.5 | Aplicable | Mensaje, cantidad y contexto usan Text/String Catalog, sin imágenes de texto. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.4.10 | Aplicable | Form vertical; snapshots no prueban scroll completo ni ventanas estrechas. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.4.11 | Aplicable | Símbolo y controles requieren medición nativa final; símbolo también redundante con texto. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 1.4.12 | N/A | SwiftUI nativo sin markup que permita override de espaciado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 1.4.13 | N/A | Sin contenido adicional propio exclusivo de hover/foco. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.1.1 | Aplicable | Stepper y botones existentes; recorrido Full Keyboard Access pendiente. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.1.2 | Aplicable | Entrada/salida de sheets y foco requieren AT real. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.1.4 | N/A | Sin atajos de un carácter. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.2.1 | N/A | Sin límite temporal del aviso/edición. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.2.2 | Condicional | Progreso nativo de carga; preferencias y operación de cierre requieren runtime. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.3.1 | Aplicable | Sin animación o destello propio en el aviso; transiciones nativas conservadas. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.1 | Aplicable | Encabezados de formulario; rotor y acceso al aviso por navegación pendientes. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.2 | Aplicable | Título descriptivo localizado; truncado visualmente en snapshot AX5. | Falla | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Título nativo AX5 truncado; recuperar en PLU-89. | root registro parcial |
| 2.4.3 | Aplicable | Sin foco forzado al aviso; se conservan retornos de sheets, ejecución AT pendiente. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.4 | Aplicable | Nombres de acciones existentes mantienen servicio/contexto; aviso no es enlace. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.5 | N/A | Detalle de un borrador; no nueva navegación de colección extensa. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.4.6 | Aplicable | Label contextual incluye nombre del servicio; encabezados del borrador conservados. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.7 | Aplicable | Foco visible de teclado pendiente; componente no interactivo. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.4.11 | Aplicable | Scroll, barras, sheets y retorno con foco se verifican en runtime. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.5.1 | N/A | Sin gesto multipunto/trayectoria requerido. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.2 | Aplicable | Botones nativos sin down-event propio; cancelación real pendiente. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.5.3 | Aplicable | Nombre accesible contiene íntegro el texto visible y añade servicio; tests es/en. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 2.5.4 | N/A | Sin activación por movimiento. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.7 | N/A | Sin arrastre requerido; scroll nativo y acciones por botón. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 2.5.8 | Aplicable | Aviso no interactivo; alturas44pt de controles conservadas, superficies pendientes. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.1.1 | Aplicable | Tres claves es/en; número según locale del entorno; pronunciación pendiente. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.1.2 | Condicional | Nombres capturados de servicios pueden usar otro idioma; pronunciación pendiente. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.2.1 | Aplicable | Aviso no navega ni mueve foco; orden real de mensajes/foco pendiente. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.2.2 | Aplicable | Ediciones siguen disponibles con déficit, tests de capacidades y total aceptado. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.2.3 | Aplicable | Mismo formulario/acciones/orden; integración local de aviso. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.2.4 | Aplicable | Reutiliza ErrorInk y anuncio moderno existentes; sin acción o rasgo bloqueante. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.2.6 | N/A | Sin mecanismos propios de ayuda repetida en este tramo. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 3.3.1 | Aplicable | Déficit advisory textual no es error de aceptación; failed/unknown omite impacto viejo. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.3.2 | Aplicable | Cantidad y edición conservan labels; aviso dice que se puede continuar. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.3.3 | Aplicable | Errores locales/reintento existentes; fallo de stock no invalida venta. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.3.4 | Aplicable | Confirmación de borrado/discard existente; pago y confirmación de déficit son otras subfases. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.3.7 | Aplicable | No añade entrada ni solicita repetir datos capturados. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 3.3.8 | N/A | Este recorrido no incorpora autenticación. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Reevaluar si aparece mecanismo. | root registro parcial |
| 4.1.2 | Aplicable | Label agrupado no interactivo, símbolo oculto; Inspector y controles AT pendientes. | Limitado | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |
| 4.1.3 | Aplicable | Un mensaje propio por nueva identidad advertida, sin temporizadores; habla/foco runtime pendiente. | Pendiente | S/T/P parciales; métodos pendientes arriba. | 02/10/2026; configs S/T/P arriba. | Evidencia integral en PLU-89 antes de uso real. | root registro parcial |

## Entrega funcional verificada

[PR44](https://github.com/JFrancoG/FranAlonso/pull/44) MERGED02/10; d6d0b99 → c845c83, árbol integrado idéntico.
PLU-88 Done funcionaldemo; PLU-89 Backlog/Jesus conserva toda la evidencia integral y hallazgos pendientes,
con trigger tras feedback/estabilización y antes del primer candidato real. Matriz55 y resultados intactos.
La fase12 permanece abierta. Este cierre no acredita AT, dispositivo físico, habla/foco ni accesibilidad integral.
