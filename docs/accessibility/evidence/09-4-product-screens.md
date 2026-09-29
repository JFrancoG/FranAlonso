# 09.4 — Lista, formulario y Catálogo de productos

2026-09-29. Entrega funcional para demo según ADR0029; **no validación integral**.
Implementación [PLU-53](https://linear.app/plusprojects/issue/PLU-53), evidencia pendiente
[PLU-54](https://linear.app/plusprojects/issue/PLU-54), Jesus Franco, hija de fase09/PLU-49.
Recuperar tras feedback de Fran y estabilización del flujo, siempre antes del primer candidato para uso real.
No se absorben PLU-38/43/44/45/48 ni se cierra fase08/09.

## Alcance y evidencia

ProductListScreen/Content/Row, ProductFormScreen/Content, entrada desde Catálogo en AppShellScreen, hojas de edición,
confirmaciones, mensajes de error/éxito y búsqueda. 41 recursos nuevos es/en; no idioma nuevo ni traducción global.
Controles nativos, etiquetas persistentes, política de 44 pt, nombre multilínea, estado Inactivo textual y colores semánticos.
Contexto efímero, cancelación estructurada, descarte/desactivación confirmados y cierre por gesto deshabilitado.

- Xcode MCP estable, Develop. Previews renderizadas realmente en **iPhone18ProMax iOS27.2**, aunque el destino
  de build/tests es iPhone18Pro Simulator27.0. Se registra el destino devuelto; no se atribuyen estas capturas a27.0.
- Large/XXX Large/AX5 en lista, formulario y shell; Light/Dark y contraste incrementado representativos. Lista0/250,
  sin resultados/error; formulario crear/editar inactivo, nombre inválido y ausencia con retry.
- ListaXXXcapturó carga transitoria; snapshot250XXX verifica contenido. Sin loops de render para disfrazar transitorios.
- Corregidos durante implementación: título de formulario cortado enAX5 (Nuevo/Editar compactos), placeholder demasiado
  largo (Nombre) e icono de vacío que procedía de Clientes (shippingbox). Retest de variantes afectadas inspeccionado.
- Inspector, medición de contraste y operación con VoiceOver/VoiceControl/SwitchControl/FKA: **Pendiente**.
  Previews, árbol estático y tests no prueban restauración/anuncios reales ni interacción de tecnologías de asistencia.
- Matriz integral de iPad/ventana/orientación, RTL/localización y preferencias: **Pendiente**. El delta no cambia la
  política de orientación vigente; la evidencia de iPhone no se extrapola a iPad.
- Tests:9fallos RED→GREENfocal7 (selección omite2variantes)→global1.199/1.199PASS, con las3terminales verificadas.
- Smoke táctil PASS, con retest focal de confirmaciones tras corregir el botón oculto; detalles abajo. POST especializado PASS funcional, sin hallazgos de código.
- Builds finales Develop 3,818 s y Production 20,909 s PASS; aviso AppIntents conocido, sin errores.
  Sesión y app del smoke detenidas; Develop/iPhone 18 Pro restaurados. Teclado software visible pendiente.

## Artefactos de preview inspeccionados

Prefijo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.

- list0: `ProductListScreen - line 131 - 2026-09-29 at 16.11.46.png`.
- listxxx: `ProductListScreen - line 131 - 2026-09-29 at 16.11.58.png`.
- listax: `ProductListScreen - line 131 - 2026-09-29 at 16.12.15.png`.
- form0: `Create - 2026-09-29 at 16.12.32.png`.
- formxxx: `Edit inactive - 2026-09-29 at 16.12.32.png`.
- formax_final: `Edit inactive - 2026-09-29 at 16.13.43.png`.
- list250: `250 products - 2026-09-29 at 16.14.11.png`.
- listempty_final: `0 products - 2026-09-29 at 16.15.31.png`.
- listnomatch: `No matches - 2026-09-29 at 16.14.12.png`.
- listerror: `Error - 2026-09-29 at 16.14.12.png`.
- forminvalid_final: `Invalid name - 2026-09-29 at 16.15.44.png`.
- formerror: `Load failure - 2026-09-29 at 16.14.28.png`.
- shell: `Workday - 2026-09-29 at 16.16.15.png`.
- shellxxx: `Workday - 2026-09-29 at 16.16.16.png`.
- shellax: `Workday - 2026-09-29 at 16.16.16 2.png`.

## Smoke táctil inspeccionado

Xcode MCP estable, iPhone 18 Pro Simulator 27.0, demo aislada; sin ajustes globales del simulador.
Prefijo `DeviceInteractionSynthesize/Verify Product Catalogue-` bajo el mismo directorio ActionArtifacts;
cada marca conserva `-screenshot.png` y `-hierarchy.txt`.

| Recorrido | Marca | Resultado |
|---|---|---|
| Catálogo inicial | 16_19_25_712 | Dos productos activos. |
| Búsqueda sin tilde / sin resultados y recuperación | 16_19_47_861 | Champu encuentra Champú; vacío de búsqueda recuperable. |
| Nombre vacío / corrección / alta | 16_20_11_458, 16_20_24_764 | Error visible; alta corregida persiste y reabre. |
| Gesto de cierre con borrador | 16_20_53_707 | Cierre bloqueado. |
| Cancelar y descartar | 16_21_26_987 | Cancelar conserva borrador; descartar conserva nombre guardado. |
| Desactivar sin guardar nombre | 16_22_53_117 | Conserva nombre persistido y marca Inactivo. |
| Editar y reabrir inactivo | 16_23_20_475, 16_23_32_804 | Guarda nombre sin reactivar. |
| Relanzamiento / reset | 16_24_23_154 | Restituye exactamente dos productos originales. |
| Descarte corregido | 16_27_32_978, 16_27_48_329 | Dos botones visibles; Seguir editando conserva borrador. |
| Desactivación corregida | 16_27_55_804, 16_28_03_847 | Dos botones visibles; Seguir editando conserva borrador. |
| Salida limpia final | 16_28_30_601 | Descartar deja catálogo original sin cambios. |

Hallazgo resuelto: el popover iOS 27 ocultaba la acción `role: .cancel`; el botón Seguir editando es ahora una acción
explícita que cierra solo el diálogo. El retest focal confirma ambos botones visibles y operables. No se repitió el CRUD.
El teclado software estaba oculto por la configuración del simulador; esta ejecución no acredita su layout visible.
No hubo crash, solapamientos ni recortes inesperados en el recorrido. Estos taps no prueban VoiceOver ni otras AT.

## Matriz de55criterios

Las filas Aplicable con Limitado conservan revisión/construcción/preview, **no un pase integral**.
N/A identifica ausencia justificada del mecanismo, no una prueba superada. Todas las filas remiten al ámbito anterior;
PLU-54 conserva la validación runtime restante. Fecha/configuración común:29/09/2026, previews18ProMax27.2.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método/pendiente | Disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.2.1 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.3 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.4 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.5 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.3.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.3.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.3.3 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.3.4 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.3.5 | N/A | Nombre de inventario, no dato personal con propósito autofill. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.3 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.4 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.5 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.10 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.11 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni override de espaciado de autor. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.13 | N/A | Sin contenido propio adicional que aparezca al hover/foco. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.1.1 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.1.2 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.1.4 | N/A | Sin atajos propios de un solo carácter. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.2.1 | N/A | Sin límites temporales ni caducidad en el formulario. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.2.2 | N/A | Sin carrusel/medio automático; carga nativa finita y observación local sin movimiento propio. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.3.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.3 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.4 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.5 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.6 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.7 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.4.11 | Aplicable | Requiere evidencia runtime o medición específica aún no realizada. | Pendiente | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.5.1 | N/A | Ninguna acción exige gesto multipunto o trayectoria. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.5.3 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 2.5.4 | N/A | Sin acciones activadas por movimiento. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.7 | N/A | No exige arrastre; búsqueda, guardado y cierre tienen controles simples. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.8 | Aplicable | Código solicita 44 pt; jerarquía de toolbar muestra frames de 36 pt, sin medir área operable efectiva. | Limitado | Medición real de hit area pendiente; no se acredita 44 pt medidos. | PLU-54 antes de uso real. |
| 3.1.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.1.2 | N/A | Copy monolingüe localizado; nombres son datos introducidos por la persona. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 3.2.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.2.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.2.3 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.2.4 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.2.6 | N/A | Sin mecanismos de ayuda repetidos nuevos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 3.3.1 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.3.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.3.3 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.3.4 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.3.7 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 3.3.8 | N/A | No cambia autenticación; evidencia/deuda del login permanece en su fase. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 4.1.2 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |
| 4.1.3 | Aplicable | Construcción nativa y previews arriba; completar operación/semántica runtime. | Limitado | Preview/revisión; Inspector/AT/Manual según criterio. | PLU-54 antes de uso real. |

## POST independiente

PASS de estándares y UI/accesibilidad para la puerta funcional ADR 0029, sin hallazgos P0–P3 de código.
La revisión especializada inspeccionó las 15 capturas y las confirmaciones corregidas; no ejecutó nuevas AT.
Root verificó 573/573 archivos idénticos tras cada auditoría; SHA-256 del manifiesto
`/tmp/franalonso-09-4-post.json`: `82ae2c4eed46474bb7da0c59d5fa4baa5d1151135221c474c7ddec53118f8bba`.
Solo se incorpora después el registro documental. La validación integral permanece pendiente.
La política de 44 pt no equivale a medición: frames de toolbar de 36 pt en jerarquía requieren comprobar superficie
táctil efectiva en PLU-54. El criterio 2.5.8 conserva Limitado.
