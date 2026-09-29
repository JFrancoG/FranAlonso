# 10.6 — Selector de producto asociado

2026-09-30. Construcción progresiva bajo ADR 0022/0029. **No acredita validación integral.**
Implementación [PLU-66](https://linear.app/plusprojects/issue/PLU-66), deuda propia
[PLU-67](https://linear.app/plusprojects/issue/PLU-67), Backlog, Jesus Franco.
Recuperar tras feedback de Fran y estabilización del flujo, antes de uso real y cierre integral.
No absorbe PLU-65 ni deudas anteriores.

## Alcance y evidencia

ServiceFormScreen/Content/Feedback y nuevo ServiceLinkedProductSection. Picker de tipo y Picker
navigationLink para productos activos; vacío, carga, error/reintento, vínculo desconocido/no disponible,
selección/sustitución y conversión Profesional. VM observa con generación propia sin alterar borrador.
Se conserva validación contextual 10.3 al guardar y desactivación histórica. Rótulos y recursos ES/EN,
controles nativos y petición de 44 pt; petición de layout no demuestra medición operable.

PRE2 independiente PASS. 1.073 declaraciones/1.544 resultados PASS; Develop/Production PASS.
Previews y smoke focal inspeccionados; POST estándares y UI/accesibilidad favorables para demo, sin hallazgos nuevos.
Inspección estática no ejecuta AT ni mide contraste. La matriz parte del patrón 10.5 y reevalúa el delta;
las observaciones nuevas del selector se registran aquí, la deuda 10.5 conserva su alcance.

## Previews representativos

Xcode MCP, iPhone18ProMax/iOS27.2, 00:50–00:54. Registro completo `/tmp/franalonso-106-previews.json`.
22 renders incluyen iteraciones de diseño: índices0–2/6–14 anteriores al ajuste final de sección;
los finales15–21 sustituyen la etiqueta duplicada. No contar iteraciones como criterios aprobados.
Screen edit-product Large/XXX Large/AX5 (índices3–5) demuestra contenedor/carga; XXX/AX capturaron carga,
por lo que se complementó con Content EN determinista y sección seleccionada en los tres tamaños.
Nombres largos conservan multilínea; AX5 exige scroll y no prueba operación íntegra del formulario.

Artefactos finales en ActionArtifacts/default/RenderPreview:
- `Selected product ES - 2026-09-30 at 00.53.16.png`: AX5, Dark, Increased Contrast.
- `Selected product ES - 2026-09-30 at 00.53.31.png`: Large, Light; `00.53.31 2.png`: XXX Large.
- `Unavailable product ES - 2026-09-30 at 00.53.31.png`: Large, vínculo ausente y error accionable.
- `Read failure EN - 2026-09-30 at 00.53.32.png`: XXX Large, Dark; error/reintento y disponibilidad desconocida.
- `Empty catalogue EN - 2026-09-30 at 00.53.32.png`: Large, opciones de recuperación.
- `Product form EN - 2026-09-30 at 00.53.46.png`: Large, formulario completo en contexto.

Se observa una ayuda preexistente del impuesto en español en el preview EN, aunque xcstrings contiene ambas
traducciones correctas. No atribuir validación integral de idioma a este render: comprobar en runtime con PLU-65,
y conservar la regresión de textos nuevos en PLU-67. No se cambia aquí el campo fiscal previo.
Renders no prueban contraste medido, VoiceOver/foco/rotor, teclado software, ventanas ni AT física.

## Smoke y auditorías

Develop, iPhone18Pro Simulator/iOS27.0 (24A434), perfil de demo aislado; 00:56–00:58. Informe y ocho hitos
captura/jerarquía: `/tmp/franalonso-106-smoke.md`. Picker ida/vuelta conserva sesión; sustituir Champú por
Mascarilla, guardar/reabrir conserva vínculo y datos; Profesional→Producto queda sin selección, muestra
error al guardar y recupera eligiendo producto. PASS funcional. Sesión cerrada y esquemas/argumentos intactos.
No se recorrió en UI producto desactivado/histórico: suite de composición acredita la recuperación contextual.
Teclado software oculto, no prueba ese layout ni operación AT. Idioma ES/apariencia clara en este smoke.

Dos avisos runtime SwiftUI `Invalid frame dimension` sin impacto observado; baseline10.5 ya contiene ocho
ocurrencias en `Service Catalogue Smoke-00_14_30_256-logs.txt`, líneas395/561/673/681/693/797/805/823.
No atribuir causa ni declararlo resuelto; seguimiento de layout PLU-65 y regresión PLU-67 antes de uso real.
Los builds conservan el aviso AppIntents metadata conocido, sin warning Swift/Clang nuevo.

POST estándares y UI/accesibilidad independientes favorables para puerta funcional ADR0029, sin hallazgos nuevosP0–P3.
Huella operacional read-only:664archivosidénticos antes/después, `/tmp/franalonso-10-6-post1.json`, SHA256
`91f7360b9bf73fb80cfa12e52b4f6b66e9fb146eaabeaf643100a812eeea8046`.
La jerarquía de smoke da «Tipo, Tipo» al Picker: comprobar nombre/valor real con Inspector/VoiceOver en PLU-67,
sin inferir locución ni fallo AT no ejecutados. Todos los pendientes de matriz mantienen su resultado.

## Matriz WCAG 2.2 A/AA

Contexto estático: código 10.6, ES/EN, preferencias/apariencias soportadas por controles nativos;
no se atribuye dispositivo o versión a la lectura de código. Destinos reales indicados en previews y smoke.
Limitado significa construcción parcial, Pendiente falta de comprobación; N/A ausencia justificada del
mecanismo en este delta. No usar un render como prueba de foco, rotor, AT física o conformidad.

| ID | Aplicabilidad | Justificación/evidencia | Resultado | Método y pendiente | Disposición |
|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Pickers y botón de reintento nativos; etiquetas persistentes de tipo y producto. | Limitado | Estática; completar Inspector y VoiceOver. | PLU-67 antes de uso real y cierre integral. |
| 1.2.1 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.3 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.4 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.2.5 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.3.1 | Aplicable | Form/Section/Picker y etiquetas persistentes para tipo y producto; selección etiquetada. | Limitado | Estática; verificar relaciones y rotor en runtime. | PLU-67 antes de uso real y cierre integral. |
| 1.3.2 | Aplicable | Orden declarado: nombre, tipo, producto cuando corresponde, precio, moneda, impuesto, descuento. | Limitado | Estática; recorrido lineal VoiceOver y teclado pendiente. | PLU-67 antes de uso real y cierre integral. |
| 1.3.3 | Aplicable | Errores y acciones se nombran en texto; ninguna instrucción depende solo de color o posición. | Limitado | Estática; revisar comprensión en el recorrido real. | PLU-67 antes de uso real y cierre integral. |
| 1.3.4 | Aplicable | El delta no añade bloqueo de orientación; falta evidencia por orientación y ventana. | Pendiente | iPhone/iPad, portrait/landscape y multitarea. | PLU-67 antes de uso real y cierre integral. |
| 1.3.5 | N/A | Datos de catálogo comercial; no se solicitan datos personales con propósito de autofill. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.4.1 | Aplicable | Vínculo no disponible, carga, vacío y error tienen texto; selección usa semántica nativa. | Limitado | Estática; Differentiate Without Color pendiente. | PLU-67 antes de uso real y cierre integral. |
| 1.4.2 | N/A | No hay audio ni vídeo en estos flujos. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 1.4.3 | Aplicable | Se usan recursos textPrimary, textSecondary y errorInk; no hay medición del contraste resultante. | Pendiente | Medir texto en Light/Dark y contraste normal/incrementado. | PLU-67 antes de uso real y cierre integral. |
| 1.4.4 | Aplicable | Fuentes semánticas y texto multilínea; títulos compactos y controles alternativos en tamaño accesible. | Limitado | Renders Large/XXX Large/AX5 inspeccionados; operación integral AX5 pendiente. | PLU-67 antes de uso real y cierre integral. |
| 1.4.5 | Aplicable | Productos, estados y acciones usan Text; no hay imágenes de texto en el alcance. | Limitado | Estática y renders representativos; revisión integral pendiente. | PLU-67 antes de uso real y cierre integral. |
| 1.4.10 | Aplicable | List y Form desplazan verticalmente; las filas y etiquetas permiten varias líneas. | Limitado | Estática; ventanas estrechas, iPad y AX5 pendientes. | PLU-67 antes de uso real y cierre integral. |
| 1.4.11 | Aplicable | Controles nativos y colores semánticos; no se han medido estados, bordes ni símbolos esenciales. | Pendiente | Medir contraste no textual en las cuatro apariencias. | PLU-67 antes de uso real y cierre integral. |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de override de espaciado de autor. | N/A | Inspección de tecnología. | Reevaluar si aparece el mecanismo. |
| 1.4.13 | N/A | No hay contenido propio adicional activado por hover/foco; menús y diálogos exigen acción explícita. | N/A | Inspección de interacción; reevaluar si se añade hover/foco. | Reevaluar si aparece el mecanismo. |
| 2.1.1 | Aplicable | Acciones nativas; botón Listo permite cerrar el teclado decimal por toque. | Pendiente | Full Keyboard Access y teclado externo en cada campo/acción. | PLU-67 antes de uso real y cierre integral. |
| 2.1.2 | Aplicable | Formulario modal con cancelación explícita; el cierre por gesto está deshabilitado. | Pendiente | Verificar entrada/salida por teclado y Switch Control, incluidos diálogos. | PLU-67 antes de uso real y cierre integral. |
| 2.1.4 | N/A | No se añaden atajos propios de un solo carácter. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.2.1 | N/A | No hay límite temporal ni expiración de la edición o confirmación. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.2.2 | N/A | Sin medio/carrusel automático; progreso nativo de operación y observación local sin movimiento propio. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.3.1 | Aplicable | El código del alcance no añade destellos ni animaciones propias. | Limitado | Estática; inspección visual y preferencias pendiente. | PLU-67 antes de uso real y cierre integral. |
| 2.4.1 | Aplicable | Selector dentro de sección del formulario; destino nativo con lista de opciones. | Limitado | Estática; acceso al contenido y rotor pendientes. | PLU-67 antes de uso real y cierre integral. |
| 2.4.2 | Aplicable | Selector usa título localizado Producto asociado; conserva título del formulario al volver. | Limitado | Estática; anuncio de destino y contexto en runtime pendiente. | PLU-67 antes de uso real y cierre integral. |
| 2.4.3 | Aplicable | Intento fallido dirige foco accesible al selector; navegación de ida/vuelta gestionada nativamente. | Pendiente | Verificar foco inicial, errores, confirmaciones, sheet y retorno con AT. | PLU-67 antes de uso real y cierre integral. |
| 2.4.4 | Aplicable | Acciones explícitas elegir producto, cambiar tipo, reintentar productos y guardar. | Limitado | Estática; lista de acciones accesibles en runtime pendiente. | PLU-67 antes de uso real y cierre integral. |
| 2.4.5 | Aplicable | Selector potencialmente extenso dentro de un proceso de edición; lista de opciones nativa, sin búsqueda nueva. | Limitado | Estática; navegación/búsqueda y volumen en runtime pendientes. | PLU-67 antes de uso real y cierre integral. |
| 2.4.6 | Aplicable | FormFieldSection para tipo y label nativo del Picker de producto; etiquetas accesibles alineadas. | Limitado | Estática; árbol accesible y rotor pendientes. | PLU-67 antes de uso real y cierre integral. |
| 2.4.7 | Aplicable | Controles nativos; no hay evidencia de foco visible con teclado/puntero. | Pendiente | Full Keyboard Access y puntero en superficies compatibles. | PLU-67 antes de uso real y cierre integral. |
| 2.4.11 | Aplicable | Formulario desplazable; campos numéricos usan decimalPad y toolbar Listo. | Pendiente | Teclado software visible, scroll, sheets y confirmaciones en AX5. | PLU-67 antes de uso real y cierre integral. |
| 2.5.1 | N/A | Ninguna acción exige gesto multipunto o de trayectoria; el desplazamiento usa controles nativos. | N/A | Inspección de interacción. | Reevaluar si aparece el mecanismo. |
| 2.5.2 | Aplicable | Mutaciones mediante Button y confirmaciones explícitas, sin acciones propias al down-event. | Limitado | Estática; cancelación táctil real pendiente. | PLU-67 antes de uso real y cierre integral. |
| 2.5.3 | Aplicable | Nombres accesibles alineados con rótulos; Guardar/Cancelar conservan etiqueta al mostrarse como iconos AX. | Limitado | Estática; activación por nombre con Voice Control pendiente. | PLU-67 antes de uso real y cierre integral. |
| 2.5.4 | N/A | Sin acciones activadas por agitar o mover el dispositivo. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 2.5.7 | N/A | No se exige arrastre; selección, búsqueda, edición y cierre tienen controles simples. | N/A | Inspección de interacción. | Reevaluar si aparece el mecanismo. |
| 2.5.8 | Aplicable | Código solicita mínimo 44 pt en entradas/filas y acciones propias; no se ha medido superficie operable. | Limitado | Medir hit area real y separación, incluidas barras, menús y diálogos. | PLU-67 antes de uso real y cierre integral. |
| 3.1.1 | Aplicable | Recursos es/en; Locale del entorno se captura en la sesión y se usa en importes/anuncios. | Limitado | Estática; pronunciación, formatos y errores en ambos idiomas pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.1.2 | N/A | Copy monolingüe localizado; los nombres de servicio son contenido introducido por la persona. | N/A | Inspección de alcance; reevaluar contenido multilingüe propio. | Reevaluar si aparece el mecanismo. |
| 3.2.1 | Aplicable | Recibir foco no solicita carga, guardado, desactivación ni navegación. | Limitado | Estática; recorrido de foco con AT pendiente. | PLU-67 antes de uso real y cierre integral. |
| 3.2.2 | Aplicable | Elegir cambia solo el vínculo; cambiar a Profesional lo borra explícitamente, sin guardar. | Limitado | Estática; interacción y reintento en runtime pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.2.3 | Aplicable | Navegación nativa al selector y retorno al mismo borrador; no añade rutas globales. | Limitado | Estática; comparar navegación completa y retorno pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.2.4 | Aplicable | Acciones compartidas mantienen recursos, roles y posición del patrón de formularios. | Limitado | Estática; comprobación de identificación con AT pendiente. | PLU-67 antes de uso real y cierre integral. |
| 3.2.6 | N/A | No se añaden mecanismos de ayuda repetidos; las instrucciones pertenecen a cada campo. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 3.3.1 | Aplicable | Error de vínculo requerido/no disponible próximo al Picker; error conservado como general tras conversión Profesional. | Limitado | Estática; foco, anuncio y asociación programática reales pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.3.2 | Aplicable | Labels de tipo/producto persistentes y hint de elección/sustitución antes de guardar. | Limitado | Estática; lectura y operación del formulario pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.3.3 | Aplicable | Errores ofrecen elegir otro producto o convertir a Profesional; fallo de lectura ofrece reintento. | Limitado | Estática; casos inválidos, corrección y errores de guardado pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.3.4 | Aplicable | Descarte/desactivación requieren confirmación; guardar explícito, operaciones solapadas bloqueadas. | Limitado | Estática; cancelar/confirmar y conservar datos persistidos pendientes. | PLU-67 antes de uso real y cierre integral. |
| 3.3.7 | Aplicable | Emisiones no modifican borrador; selección/sustitución conservan datos comerciales y errores de escritura. | Limitado | Pruebas de estado/composición 10.6 y smoke focal PASS; recorrido integral con AT pendiente. | PLU-67 antes de uso real y cierre integral. |
| 3.3.8 | N/A | Este delta no cambia autenticación; la deuda de ese flujo conserva su ámbito original. | N/A | Inspección de alcance. | Reevaluar si aparece el mecanismo. |
| 4.1.2 | Aplicable | Picker de tipo y producto y Button de reintento nativos; tags estables y centinela del vínculo ausente. | Limitado | Estática; Inspector, VoiceOver y Voice Control pendientes. | PLU-67 antes de uso real y cierre integral. |
| 4.1.3 | Aplicable | Anuncio tras guardado fallido y fallo del catálogo mientras se edita Producto; sin mover foco por emisiones. | Limitado | Estática; comprobar anuncios reales, prioridad y ausencia de duplicados. | PLU-67 antes de uso real y cierre integral. |

## Recuperación

Registrar por comprobación dispositivo, versión/build, idioma, preferencias, método, artefacto,
resultado y revisor. Completar VoiceOver/VoiceControl/SwitchControl/FullKeyboardAccess e Inspector,
contraste Light/Dark estándar/aumentado, hit areas, DynamicType con teclado software, iPad/ventanas,
orientación y RTL aplicables. Defectos que impidan operar la demo, pérdida de datos, privacidad y
regresiones funcionales bloquean la puerta actual. No declarar estos pendientes resueltos por aplazarlos.
