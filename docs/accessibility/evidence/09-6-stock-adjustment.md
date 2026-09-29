# 09.6 — Ajuste de stock y entrada desde ficha

2026-09-29. Puerta funcional ADR0029; **validación integral pendiente**.
Implementación [PLU-56](https://linear.app/plusprojects/issue/PLU-56), deuda propia
[PLU-57](https://linear.app/plusprojects/issue/PLU-57), Jesus Franco, hija dePLU-49.
Recuperar tras feedback y estabilización del flujo, antes del primer candidato para uso real. PLU-54 y deuda08 permanecen.

## Alcance y estado de la evidencia

StockAdjustmentScreen/Content, entrada y retorno de ProductFormScreen/Content y cableado desde Catálogo.
Controles nativos, etiquetas persistentes, saldo negativo textual, dirección Entrada/Salida, validación y cancelación explícitas.
Éxito terminal separado de la recarga de saldo; fallo de recarga no rehabilita el envío. No hay historial ni mínimo09.7.

PRE PASS; construcción revisada durante implementación. Previews y smoke inspeccionados; POST especializado PASS funcional.
Inspector, medición de contraste/hit area, VoiceOver, VoiceControl, SwitchControl y FKA permanecen pendientes enPLU-57.
La matriz de orientación/iPad/ventana/localización/RTL y preferencias requiere evidencia integral; no se extrapolan capturas.

## Evidencia ejecutada

- Suite completa: **958 declaraciones / 1.315 resultados PASS**; cero fallos, omisiones, fallos esperados o warnings runtime en el bundle nativo cerrado. Incluye 47 resultados nuevos respecto de09.5.
- RED previo:31 resultados,17 fallos semánticos esperados,14 rechazos correctos. Build Develop para GREEN10,198s PASS; aviso AppIntents conocido.
- **16 previews renderizadas e inspeccionadas**, iPhone18ProMax iOS27.2 devuelto por Xcode; build/tests en iPhone18Pro27.0. Large/XXX Large/AX5, Light/Dark y contraste incrementado representativos.
- Las variantes XXX/AX de las pantallas completas capturaron carga transitoria. Los snapshots deterministas de Content verifican sus controles reales; no se repitieron renders para ocultar el transitorio.
- Títulos/acciones AX compactos; saldo y nombres envuelven. EnAX5 el formulario exige desplazamiento vertical; no se afirma desde una captura la operación de controles fuera del viewport.
- Smoke táctil PASS. Production20,776s PASS; aviso AppIntents conocido. Sesión/app cerradas y Develop/iPhone18Pro restaurados. POST especializado PASS funcional; Inspector/tecnologías de asistencia conservan Pendiente/Limitado.

Artefactos de preview bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`:

| Caso | Archivo |
|---|---|
| screenLarge | `Adjustment - 2026-09-29 at 18.41.36.png` |
| screenXXX | `Adjustment - 2026-09-29 at 18.41.51.png` |
| screenAX | `Adjustment - 2026-09-29 at 18.41.51 2.png` |
| parentLarge | `Edit inactive - 2026-09-29 at 18.42.07.png` |
| parentXXX | `Edit inactive - 2026-09-29 at 18.42.15.png` |
| parentAX | `Edit inactive - 2026-09-29 at 18.42.16.png` |
| contentXXX | `Editing - 2026-09-29 at 18.42.44.png` |
| contentAX | `Editing - 2026-09-29 at 18.42.44 2.png` |
| invalid | `Invalid units - 2026-09-29 at 18.42.44.png` |
| negative | `Saved negative - 2026-09-29 at 18.42.45.png` |
| refreshError | `Accepted refresh failed - 2026-09-29 at 18.42.45.png` |
| parentContentXXX | `Stock entry - 2026-09-29 at 18.43.37.png` |
| parentContentAX | `Stock entry - 2026-09-29 at 18.43.37 2.png` |
| saving | `Saving - 2026-09-29 at 18.43.51.png` |
| loadError | `Load failure - 2026-09-29 at 18.43.51.png` |
| savedLarge | `Saved negative - 2026-09-29 at 18.43.52.png` |


## Smoke funcional

Xcode MCP estable, iPhone18Pro Simulator27.0, demo aislada, sin cambiar ajustes globales.
Agente de interacción lee la skill Apple exportada e inspecciona jerarquía/captura antes de actuar.
Prefijo `Verify Stock Adjustment-` bajo
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/DeviceInteractionSynthesize/`;
cada marca tiene `-hierarchy.txt`, `-screenshot.png` y `-logs.txt`.

| Recorrido | Marca | Resultado |
|---|---|---|
| Seed Champú | 18_47_17_703 | Saldo8; nombre padre Borrador sin guardar. |
| Unidades vacías y0 | 18_47_25_046,18_47_40_344 | Error textual, editable. |
| Motivo vacío | 18_48_00_517 | Error y foco de teclado; no afirma VoiceOver. |
| Entrada+3 | 18_48_15_983 | Ajuste registrado, saldo11, solo Finalizar. |
| Finalizar y reabrir | 18_48_29_896,18_48_37_223 | Borrador padre intacto; saldo11 vigente. |
| Salida14 | 18_49_37_048 | Saldo−3 y explicación textual; reapertura conserva−3. |
| Cancelar/Seguir editando | 18_50_07_844,18_50_17_666 | Ambas acciones visibles; conserva unidades5. |
| Descartar ajuste | 18_50_39_974 | Cierra solo stock; padre conserva Borrador. |
| Descartar padre | 18_51_12_369 | Catálogo mantiene nombre original. |
| Reinicio demo | 18_52_19_624,18_53_00_222 | Restituye exactamente8/2 unidades. |

No hubo crash, bloqueo ni defecto visual bloqueante observado. El hitPoint central del Picker no abrió menú;
el hitPoint del valor Entrada sí. Medición de superficie/operación AT pendiente enPLU-57, no se afirma área efectiva44pt.
Teclado software oculto por configuración existente: este smoke no acredita su layout visible.
Avisos del runtime Apple AX/InputUI/háptica/CoreSimulator y timeout del proveedor de imagen en diálogo; no se atribuyen
a código de la app ni se ocultan. Captura transitoria vacía del cierre de diálogo resuelta con recaptura sin acción.
Fallo de lectura posterior al guardado cubierto por pruebas con inyección y preview, no reproducido artificialmente en smoke.
Sesión detenida y proceso54601 parado por root al finalizar. No permanece ninguna interacción activa.

## Matriz de55criterios

Aplicabilidad evaluada de nuevo sobre este flujo. Limitado acredita construcción/revisión; no un pase integral.
No se reutilizan capturas ni resultados09.4 para los controles nuevos. N/A justifica ausencia del mecanismo.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método/pendiente | Disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos decorativos ocultos; botones con texto/nombre accesible. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.2.1 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.2 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.3 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.4 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.2.5 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.3.1 | Aplicable | Form/Section/Picker/LabeledContent nativos y encabezado de éxito. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.3.2 | Aplicable | Orden declarativo producto, saldo, error, dirección, unidades y motivo. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.3.3 | Aplicable | Instrucciones textuales sin depender de posición o forma. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.3.4 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 1.3.5 | N/A | Unidades y motivo de inventario, no datos personales con propósito autofill. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.1 | Aplicable | Errores, guardado y saldo negativo expresados con texto. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.4.2 | N/A | No hay audio ni vídeo en este flujo. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.3 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 1.4.4 | Aplicable | Fuentes del sistema; título compacto y controles44pt en AX. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.4.5 | Aplicable | Texto real SwiftUI, no imágenes de texto. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.4.10 | Aplicable | Form desplazable y textos multilínea; comprobar renders representativos. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 1.4.11 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 1.4.12 | N/A | Controles nativos SwiftUI, sin markup de autor para espaciado. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 1.4.13 | N/A | No se añade contenido propio al hover o foco. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.1.1 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 2.1.2 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 2.1.4 | N/A | No hay atajos de carácter único. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.2.1 | N/A | El ajuste no tiene límite temporal ni caducidad. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.2.2 | N/A | Sin medios automáticos; progreso nativo de operación finita, sin animación propia. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.3.1 | Aplicable | Sin flashes ni animación propia. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.1 | Aplicable | Agrupación nativa; validación/foco semántico sin bucles. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.2 | Aplicable | Título Ajustar stock/Stock; nombre del producto visible. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.3 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 2.4.4 | Aplicable | Acciones explícitas Registrar/Reintentar/Actualizar existencias/Finalizar. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.5 | Aplicable | Acceso desde ficha existente y cancelación explícita. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.6 | Aplicable | Etiquetas persistentes Tipo de ajuste, Unidades y Motivo. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.4.7 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 2.4.11 | Aplicable | Requiere runtime o medición específica aún no realizada. | Pendiente | Inspector/AT/manual según criterio. | PLU-57 antes de uso real. |
| 2.5.1 | N/A | Ninguna acción exige gesto multipunto ni trayectoria. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.2 | Aplicable | Botones nativos; confirmación explícita del descarte. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.5.3 | Aplicable | Nombre accesible coincide con acción visible; iconos AX conservan nombre. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 2.5.4 | N/A | No hay acciones activadas por movimiento. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.7 | N/A | No requiere arrastre: botones para cancelar, registrar, reintentar y finalizar. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 2.5.8 | Aplicable | Código solicita44pt; pendiente medir área táctil efectiva de controles del sistema. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.1.1 | Aplicable | Recursos nuevos es/en en xcstrings y números formateados por locale. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.1.2 | N/A | Copy monolingüe localizado; nombre y motivo son contenido introducido por la persona. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 3.2.1 | Aplicable | Foco no envía el ajuste. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.2.2 | Aplicable | Editar campos no guarda; envío explícito. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.2.3 | Aplicable | Hoja con cancelación y confirmación nativas, coherente con ficha padre. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.2.4 | Aplicable | Texto y símbolos consistentes con formularios existentes. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.2.6 | N/A | No se añaden mecanismos de ayuda repetidos. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 3.3.1 | Aplicable | Errores Domain localizados; foco solicitado para unidades/motivo. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.3.2 | Aplicable | Etiquetas persistentes y error con formato esperado. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.3.3 | Aplicable | Error textual explica corrección; conserva borrador editable antes de aceptar. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.3.4 | Aplicable | Revisión previa editable y envío explícito; idempotencia evita duplicación. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.3.7 | Aplicable | Reintento conserva ID/fecha/payload; borrador padre conservado. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 3.3.8 | N/A | No cambia autenticación; conserva su evidencia/deuda previa. | N/A | Inspección de alcance/código. | Reevaluar si aparece el mecanismo. |
| 4.1.2 | Aplicable | Controles nativos con label/value/estado; comprobar Inspector/AT. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |
| 4.1.3 | Aplicable | Anuncios de error/aceptación/fallo de recarga; operación AT pendiente. | Limitado | Código; completar preview/smoke/Inspector/AT según criterio. | PLU-57 antes de uso real. |

## POST independiente

PASS para la puerta funcional ADR0029, sin hallazgos P0–P3. El especialista revisa código,36 recursos es/en,
16 imágenes de preview,14 jerarquías y3 capturas representativas;55 criterios sin omisiones/duplicados.
No ejecuta nuevas interacciones, Inspector ni tecnologías de asistencia. Las limitaciones anteriores permanecen.
Reviewer y root:606/606 archivos idénticos frente a `/tmp/franalonso-09-6-post2.json`, SHA256
`6b603ff317e487c371b03dfe5eff0952497974193837ec8866af664ffc5ce992`; solo después se añade el registro documental.
