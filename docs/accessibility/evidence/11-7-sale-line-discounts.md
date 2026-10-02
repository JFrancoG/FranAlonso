# 11.7 — Descuentos de línea y global

2026-10-02. Registro parcial propio de [PLU-80](https://linear.app/plusprojects/issue/PLU-80).
[ADR0022](../../ADRs/0022-native-ios-wcag22-accessibility.md) y
[ADR0029](../../ADRs/0029-progressive-accessibility-validation.md); no cierre completo11.7 ni integral.
El global provisional amplía este registro por impacto; su regla comercial sigue pendiente de Fran.
PLU-77/79 mantienen su deuda separada.

## Alcance y evidencia

Fila editable/readonly con porcentaje o ausencia; editor manual, input localizado exacto0…100, Aplicar,
Retirar nil explícito, Cerrar sin solicitud, error de entrada, fallo local/reintento, progreso y retorno al borrador.
Cada View posee preview con trait compartido; ViewModel propio y capacidades App hacia Store/fachada existentes.

- S: construcción/revisión de fuentes y copyES/EN,02/10/2026. Sin dispositivo; no acredita árbol/AT.
- T: RED18declaraciones/40variantes (39Failed/1Passed); GREEN final nativo1263declaraciones/1999ejecuciones,
  incluidas18declaraciones/40variantes nuevasPassed. Develop/iPadPro13M5Simulator27.2,SDK27.0;
  0fallos/skips/runtimeWarnings nativos. [Fase11](../../progress/phase-11.md) conserva bundles/exports.
- Localización521entradas/0errores;16claves nuevas. Builds finalesDevelop/Production ceroSwift/Clangwarnings,
  2/1avisosAppIntents separados; consola de tests conserva avisos internos y sondas negativas esperadas.
- P:13previews nuevas0errores/render/inspecciónroot: editorESLight yENDark, errorES y borradorES en
  Large/XXX Large/AX5, másdiscovery; iPadPro13M5Simulator27.2,SDK27.0,02/10/2026.
  Manifiesto `/tmp/plu80-preview-manifest.json`. OverrideEN no prueba región/separador inglés.
  AX5ES: toolbarCerrar ausente de captura; AX5ENvisible. BorradorAX5 requiere scroll; verificar runtime.
- R: smoke inicial9/9checks/26capturas conservó P2 de primera apertura; corrección funcional enPLU-80.
  Dosbuttons ahora usanborderless explícito, sin modificar Stepper/semántica/44pt. PRE yPOSTtécnico/estilo focalPASS.
  Coldsmokecorregido9/9checks/22capturas: primeraapertura estable en2recapturas, cerrar conserva, retirarservicio
  ycancelar independientes, cantidad1→2→1, aplicar/reabrir12,5→21,17€, retirar sólodescuento→nil24,20€.
  phone17Simulator27.2/Develop/demoESportrait402×874pt/textoestándar,02/10/2026. NingúnPlatformAlert/competing
  enlogs corregidos; ruido de frameworks persiste. No se determina causa original ni ejecución de dosclosures.
  Retest3previews padreLarge/XXX/AX5esLight0errores; manifest `/tmp/plu80-corrected-preview-manifest.json`.
  [Fase11](../../progress/phase-11.md) detalla informes/manifests, límites y proofsource595 de ambos smokes.
  Tecladoenpantalla observado en input/error inicial; retirada con tecladoabierto/scroll pendiente.
  Popover de retirarservicio se canceló con fallbackexterior tras hitPoint sin efecto; no borrado confirmado.
  Sin evidenciaAT/física/durabilidadentreprocesos. POST UI focal independiente PASS, sin nuevos hallazgos;
  P2 resuelto para el gate funcional parcial del editor de línea ADR0029. No demuestra estabilidad universal.
- Inspector, ratios nativos, VoiceOver/VoiceControl/SwitchControl/FKA, teclado exhaustivo, orientaciones/preferencias/
  ventanas/RTL y muestra exhaustiva siguen pendientes. Deuda propia [PLU-81](https://linear.app/plusprojects/issue/PLU-81),
  Backlog/Jesus Franco; recuperar tras feedback/estabilización del recorrido antes del primer candidato real.
  PLU-80 incorpora ahora el global provisional; su implementación y validación se registran debajo.
  El POST anterior acredita sólo la línea; cierre integral pendiente.

## Matriz completa de55criterios

Limitado expresa únicamente construcción o método ejecutado. N/A sólo indica ausencia estática justificada del
mecanismo en este tramo; reevaluar al ampliarlo. No equivale a Pasa integral.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Texto real; sólo ProgressView decorativo oculto con estado textual equivalente. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.2.1 | N/A | Sin audio o vídeo pregrabado. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.2.2 | N/A | Sin audio sincronizado pregrabado. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.2.4 | N/A | Sin audiovisual en directo. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.2.5 | N/A | Sin vídeo con audiodescripción. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.3.1 | Aplicable | Form/Section, encabezados de servicio/global, label persistente, TextField y desgloses nativos. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.3.2 | Aplicable | Orden declarado: servicio cuando aplica, porcentaje/instrucción/error, recuperación, progreso y acciones. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.3.3 | Aplicable | Instrucción0…100 y retirada explícita sin referencias sensoriales. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.3.4 | Aplicable | No bloquear orientación salvo necesidad esencial documentada. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.3.5 | N/A | Entrada de porcentaje comercial, sin datos personales/autofill. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.4.1 | Aplicable | Error/estado textual y acciones con nombre; no depende sólo de color. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.2 | N/A | Sin reproducción automática de audio. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.4.3 | Aplicable | Estilos nativos; ratios del render final no medidos. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.4 | Aplicable | Fuentes semánticas y wrapping; Large/XXX/AX5 renderizados/inspeccionados; muestra runtime pendiente. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.5 | Aplicable | Nombre, porcentaje, instrucciones, estados y errores son Text. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.10 | Aplicable | Form y filas verticales desplazables; ventanas/teclado pendientes. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.11 | Aplicable | TextField, botones y estados requieren medición nativa final. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni override de espaciado. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 1.4.13 | N/A | Sin ayuda propia exclusiva de hover/foco. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.1.1 | Aplicable | Edición/aplicar/retirar/reintentar/cerrar con controles nativos. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.1.2 | Aplicable | Cerrar en toolbar; entrada/salida por tecnologías pendientes. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.1.4 | N/A | Sin atajos de un carácter. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.2.1 | N/A | Sin límite temporal de edición/reintento. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.2.2 | Condicional | Progreso nativo durante aceptación; evaluar movimiento y operación de cierre. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.3.1 | Aplicable | Sin animación propia o medio que destelle; progreso/transición nativos. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.1 | Aplicable | Título y encabezado del servicio identifican el editor; rotor pendiente. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.2 | Aplicable | Títulos localizados Descuento de línea/Line discount y Descuento global/Global discount. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.3 | Aplicable | Retorno solicitado al destino línea por ID o global; publicación/cierre testeados, focoAT pendiente. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.4 | Aplicable | Editar descuento, Aplicar, Retirar descuento, Reintentar y Cerrar describen intenciones. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.5 | N/A | Editor de un campo; no incorpora una colección extensa. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.4.6 | Aplicable | Encabezados de servicio/global, porcentaje con label e instrucciones persistentes y desgloses separados. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.7 | Aplicable | Foco nativo; visibilidad Full Keyboard Access pendiente. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.4.11 | Aplicable | Form/toolbar y teclado pueden ocultar foco; recorrido pendiente. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.5.1 | N/A | No exige gestos multipunto o trayectoria. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.5.2 | Aplicable | Button sin down-event propio; cerrar sin solicitud no escribe. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.5.3 | Aplicable | Nombre cualificado de edición incluye el texto visible y servicio. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 2.5.4 | N/A | Sin activación por movimiento. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.5.7 | N/A | No exige arrastre; botones y scroll nativo. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 2.5.8 | Aplicable | Se solicitan alturas44pt; superficie/bordes/separación pendientes. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.1.1 | Aplicable | 16claves nuevasES/EN; Locale de entrada capturado por sesión. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.1.2 | Condicional | Nombre comercial snapshot puede contener lengua distinta. | Pendiente | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.2.1 | Aplicable | Enfocar no solicita aceptación; acciones explícitas. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.2.2 | Aplicable | Editar texto no escribe; Aplicar/Retirar/Reintentar explícitos. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.2.3 | Aplicable | Sheet con título/Cerrar y retorno al mismo borrador. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.2.4 | Aplicable | Porcentaje/ausencia visibles y términos consistentes entre editor y línea. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.2.6 | N/A | No añade ayuda repetida transversal. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 3.3.1 | Aplicable | Entrada inválida y fallo local tienen texto; error de campo también en hint y anuncio solicitado. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.3.2 | Aplicable | Label Porcentaje (%), instrucción0…100 y retirada explícita. | Limitado | Manual S + Preview P; Test T cuando aplica. | S/T/P · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.3.3 | Aplicable | Corrección de porcentaje y retry congelado; fallo no exige reentrada. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.3.4 | Aplicable | Edición reversible sólo draft, validada antes de aceptar; no registra pago. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.3.7 | Aplicable | Retry conserva término; cerrar hijo preserva Store/venta del padre. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 3.3.8 | N/A | No modifica autenticación; deuda de ese flujo independiente. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Reevaluar si aparece el mecanismo. | root registro parcial |
| 4.1.2 | Aplicable | TextField/Button nativos, estado disabled y foco solicitado; árbol/AT pendientes. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |
| 4.1.3 | Aplicable | Se solicitan anuncios de aceptación/error/unavailable; entrega y ordenAT no probados. | Limitado | Manual S; Test T cuando aplica. | S/T · 02/10/2026 | Completar evidencia aplicable por impacto en PLU-81; antes de uso real. | root registro parcial |


## Ampliación global por impacto

El editor conserva el mismo motor de comando congelado y task del editor de línea; el destino decide el título,
la capacidad y la aceptación. La sección global nativa muestra porcentaje o ausencia, alcance a toda la venta y
acción específica. El resumen separa promociones de servicios, global y agregado. La inspección conserva los
importes y no presenta acciones de edición. Retorno de foco solicitado por destino, sin timers ni retry loops.

La matriz mantiene sus 55 filas y sus resultados: 45 Limitado y 10 Pendiente. La construcción global amplía la
justificación de estructura, orden, título, encabezados y retorno; no transforma las comprobaciones AT pendientes
en Pasa. PLU-81 conserva propietario Jesus Franco y recuperación tras feedback/estabilización del flujo, siempre
antes del primer candidato para uso real. Añadir global, coexistencia, retirada independiente, nuevos servicios,
inspección y anuncios a sus recorridos VoiceOver, Voice Control, Switch Control, FKA y teclado.

T global: 47 declaraciones /99 ejecuciones Passed dentro de 1.310 /2.098 final, bundle cerrado,0 runtimeWarnings
nativos; builds Develop/Production PASS y localización528/0. P global:20renders/0errores, todos inspeccionados
por root, manifest `/tmp/plu80-global-preview-manifest.json` con SHA256. Editor ESLight/ENDark, error, borrador
y readonly en Large/XXX/AX5; dos Screen Loading no acreditan contenido y se cubrieron con Content cargado.
AX5ES global no muestra toolbar Cerrar; falta recorrido runtime/AT con ese tamaño. Desgloses bajo fold requieren
scroll, EN no prueba región y ratios/Inspector no medidos. Los resultados de las55filas permanecen limitados.
Revisión técnica global independiente PASS; revisión UI global pendiente. Dos recapturas Screen de borrador
cargadas XXX/AX5 elevan la muestra a22 renders/0errores; las dos Loading anteriores permanecen registradas.
En XXX se ven ambos descuentos y el nombre largo completo. En AX5 el contenido global/importes cae bajo fold
y el toolbar no aparece en esa captura; scroll, foco y uso AT siguen pendientes, sin convertir filas a Pasa.

Smoke focal global:9 comprobaciones funcionales PASS en iPhone17 Simulator27.2, Develop ES estándar,
demo sintética en memoria. Apertura inicial y dos recapturas estables; Cerrar conserva, aplicar25 mantiene la
promoción10, retirar global mantiene la línea, retirar ambos recupera subtotal y entrada101 permite corrección20.
Añadir un servicio sin promoción conserva global20; venta en curso muestra ambos descuentos sin edición.
36 capturas/144 copias exactas, hashes origen/copia revalidados por root, PID93907 Running durante todo el flujo.
Manifest `/tmp/plu80-global-smoke-manifest.json`, informe `/tmp/plu80-global-smoke-report.md` y verificación
`/tmp/plu80-global-smoke-root-verification.json`; root inspeccionó PNGs representativos10/16/19/22/27/32/36.
No se acredita añadir desde catálogo un servicio con promoción: fixture actual sólo ofrece servicios sin descuento.
Domain/Store cubren ese contrato en Swift Testing; el recorrido UI sigue sin ejecutar. Cerrar funciona en tamaño
estándar ES, sin resolver AX5/AT. No se ejecutó matriz de tecnologías asistivas ni dispositivo físico.

POST UI independiente final: muestra22/22 PNG y144/144 copias revalidada e inspeccionada por el especialista.
P3 estático detectado en mensaje de indisponibilidad: el global remitía a «la línea». Corregido por root con
«Cierra este editor y revisa el borrador de venta.» / «Close this editor and review the sale draft.»;
retest independiente de esa recuperación/localización PASS para gate funcional demo ADR0029, sin nuevos P0–P3.
Informes `/tmp/plu80-global-ui-post-report.md` y `/tmp/plu80-global-ui-copy-retest-report.md`.
Cuatro FULLJSON770 idénticos en cada revisión:4ba21c40471f…c17dd2c y8af22ceae27c…657a1c4.
Sólo el catálogo cambió tras RunAll; otras605rutas de fuente/config exactas. Builds por impacto Develop-for-testing
21,841s/Production18,958s PASS,0errores/warnings Swift/Clang; avisos AppIntents separados. Catálogo528/0.
El mensaje corregido no se verificó con AT. Las55filas mantienen45Limitado/10Pendiente y PLU-81Backlog/JesusFranco,
recuperación tras feedback/estabilización antes del primer candidato real. PASS funcional no acredita integral.
