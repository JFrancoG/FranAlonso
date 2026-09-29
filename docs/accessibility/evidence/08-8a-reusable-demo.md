# Evidencia 08.8a — Demo reutilizable

Fecha: 2026-09-29. PLU-46, puerta funcional de ADR0029; no acredita accesibilidad integral ni servicios live.

**Done funcional** tras [PR #16](https://github.com/JFrancoG/FranAlonso/pull/16), merge `b334c04`;
árbol validado `0c76967` idéntico. PLU-48 conserva la validación integral; los resultados de esta matriz no cambian.

## Alcance y deuda

Nuevo marcador localizado de datos sintéticos, reset al relanzar y modo de error simulado, con encuadre de la raíz.
Texto nativo, fuentes semánticas, wrapping, agrupación accesible y colores del sistema de diseño. No añade acciones,
temporizadores ni lógica de negocio a las Views. Login y shell reales se conservan; las previews usan estados estables
directos de LoginScreen/AppShellScreen para evitar capturar el tránsito asíncrono de autenticación.

[PLU-48](https://linear.app/plusprojects/issue/PLU-48), Backlog, hija de PLU-34 y relacionada con PLU-46, registra
la validación integral nueva. Responsable Jesus Franco; retomar tras feedback de Fran y estabilización de este flujo,
siempre antes del primer candidato para uso real. VoiceOver, Voice Control, Switch Control, teclado/FKA, Inspector,
contraste medido, preferencias, orientación, ventana estrecha y RTL quedan pendientes por impacto.
La evidencia heredada de [08.7](08-7-consent-flow.md) y [08.8](08-8-client-activation.md) no cambia:
PLU-44/45/38 conservan sus fallos y pendientes; esta matriz no los absorbe ni los convierte en PASS.

## Previews y corrección del encuadre

Root inspecciona seis previews finales mediante Xcode MCP estable, esquema Develop. El pipeline renderiza realmente
iPad Pro13M5/iOS27.2; no es el iPadAir11M4/iOS27.0 utilizado por tests y smoke. Ningún error de render.
Directorio local: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.
Nombres exactos: `<nombre> - 2026-09-29 at <hora>.png`.

| Nombre | Hora | Variante | Observación |
|---|---|---|---|
| Login framing | 08.52.36 | Large clara | Aviso de error simulado, título, campos y Acceder completos. |
| Login framing | 08.52.37 | XXX Large oscura | Textos/controles completos y separados del aviso. |
| Login framing | 08.52.37 2 | AX5 clara, contraste aumentado | Aviso, título, campos y Acceder completos; layout vertical. |
| Shell framing | 08.52.35 | Large clara | Tabs, cierre de sesión, título y contenido visibles. |
| Shell framing | 08.52.36 | XXX Large oscura | Navegación bajo el aviso; overflow nativo de tabs visible. |
| Shell framing | 08.52.25 | AX5 oscura, contraste aumentado | Aviso y navegación separados; título/contenido completos. |

La primera versión con safeAreaInset tapaba el título de navegación en previews y runtime. Se sustituyó por VStack
con espacio propio sobre la raíz. La captura runtime `Reusable Demo Runtime Smoke-08_51_07_098-screenshot.png`
retiene el defecto original; no es evidencia final. La sesión se cerró antes del cambio.
El retest runtime de login/shell confirma títulos y tabs visibles (`Demo Functional Verification-08_53_20_884`
y `08_53_44_236`, en el directorio DeviceInteractionSynthesize).
Estas comprobaciones visuales/táctiles no prueban el orden o la locución de tecnologías de asistencia.

## Smoke funcional y validación técnica

Xcode MCP, iPadAir11M4/iOS27.0. **PASS táctil**, datos/firma sintéticos; sesiones cerradas. Normal: editar Alba,
revisar/firmar/conservar/enviar y alta; crear Carla; logout/login conserva los tres clientes, edición y documento/alta.
Nuevo proceso response-lost restaura dos borradores; el primer envío falla explícitamente. Reabrir y reintentar obtiene
enviado+activo sin nueva firma; otra reapertura conserva el resultado. No crashes ni nuevo bloqueo visual observado.
La acción de documento conservado pendiente se llama «Reintentar envío» también antes del primer envío manual;
solo al enviarlo en response-lost aparece el error. No fue necesario usar «Finalizar alta» en este escenario.

Artefactos locales bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/DeviceInteractionSynthesize/`.
Prefijo `Demo Functional Verification-`, sufijos `-screenshot.png`, `-hierarchy.txt` y `-logs.txt`:

| Marca | Evidencia |
|---|---|
| 08_53_20_884 / 08_53_44_236 | Login y shell sin solapamiento. |
| 08_56_04_371 | Documento enviado y cliente activo en modo normal. |
| 08_57_17_032 / 08_57_57_471 | Carla creada y tres clientes tras logout/login. |
| 08_58_47_415 | Documento y alta retenidos tras login. |
| 08_59_51_557 | Nuevo proceso: solo Alba/Bruno originales. |
| 09_01_24_132 / 09_01_33_895 | Conservado pendiente y error del primer envío. |
| 09_02_37_216 / 09_03_04_276 | Recuperación y última reapertura, misma firma/fecha. |

Root inspecciona capturas de alta normal/error/recuperación/reapertura. Los logs no registran nombres/credenciales
sintéticos; contienen diagnósticos nativos del simulador sobre AX, teclado y recursos hápticos. La ausencia de mensajes
Firebase no prueba por sí sola aislamiento: lo sustentan selección, composición y tests. Identidad del recibo y aceptación
única comprobadas en Swift Testing, no inferidas de las capturas. Rearmado del fallo por composición probado en tests;
no se repite una tercera firma manual. Simulación no acredita transporte ni persistencia entre procesos.

Suite final847 declaraciones /1.120 resultados PASS,121 suites,0 fallos/omitidos/runtimeWarnings del xcresult nativo.
Build Develop3,541s y Production20,723s PASS con aviso AppIntents conocido. PRE y POST estática/previews independientes
favorables tras corregir el estado formal de esta matriz; hashes y artefactos técnicos en [fase08](../../progress/phase-08.md).
Accesibilidad integral continúa pendiente en PLU-48; el smoke no cambia la clasificación de los criterios de AT.

## Registro de los 55 criterios

La aplicabilidad se refiere al nuevo marcador y a los flujos existentes bajo su encuadre. Las referencias heredadas
remiten a las matrices anteriores y no acreditan una repetición. `Limitado` distingue construcción/previews de AT.
Los N/A corresponden a funciones ausentes, nunca al aplazamiento de una prueba.

| ID | Aplicabilidad | Alcance o razón | Resultado08.8a |
|---|---|---|---|
| 1.1.1 | Aplicable | Marcador como texto nativo; inspección semántica runtime pendiente. | Limitado |
| 1.2.1 | N/A | Sin audio, vídeo ni medios sincronizados nuevos. | N/A |
| 1.2.2 | N/A | Sin audio, vídeo ni medios sincronizados nuevos. | N/A |
| 1.2.3 | N/A | Sin audio, vídeo ni medios sincronizados nuevos. | N/A |
| 1.2.4 | N/A | Sin audio, vídeo ni medios sincronizados nuevos. | N/A |
| 1.2.5 | N/A | Sin audio, vídeo ni medios sincronizados nuevos. | N/A |
| 1.3.1 | Aplicable | Aviso agrupado y navegación conservada; Inspector/rotor pendientes. | Limitado |
| 1.3.2 | Aplicable | Aviso precede raíz visualmente; orden AT pendiente. | Limitado |
| 1.3.3 | Aplicable | Reinicio/error expresados con texto, sin referencia espacial necesaria. | Limitado |
| 1.3.4 | Aplicable | Sin bloqueo de orientación; nuevas variantes pendientes. | Pendiente |
| 1.3.5 | Aplicable | Propósito de campos de login/cliente conservado. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 1.4.1 | Aplicable | Demo y modo de fallo se identifican por texto, no solo color. | Limitado |
| 1.4.2 | N/A | No se añade reproducción automática de audio. | N/A |
| 1.4.3 | Aplicable | Colores semánticos; medición del render final pendiente. | Limitado |
| 1.4.4 | Aplicable | Large/XXX Large/AX5 inspeccionados en login y shell. | Limitado |
| 1.4.5 | Aplicable | Marcador de texto nativo, no imagen de texto. | Limitado |
| 1.4.10 | Aplicable | Wrapping y espacio propio; ventana estrecha pendiente. | Limitado |
| 1.4.11 | Aplicable | No controles nuevos; contraste de navegación bajo encuadre pendiente. | Pendiente |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de espaciado de autor. | N/A |
| 1.4.13 | N/A | Marcador estático sin contenido al hover o al foco. | N/A |
| 2.1.1 | Aplicable | Teclado/FKA de controles existentes con nuevo encuadre pendiente. | Pendiente |
| 2.1.2 | Aplicable | Sin captura de teclado nueva; tránsito por AT pendiente. | Pendiente |
| 2.1.4 | N/A | Sin nuevos atajos de caracteres simples. | N/A |
| 2.2.1 | N/A | El aviso no impone tiempo; reset solo al terminar y relanzar proceso. | N/A |
| 2.2.2 | N/A | Marcador estático, sin movimiento/actualización automática que pausar. | N/A |
| 2.3.1 | Aplicable | Sin destellos ni animación añadidos. | Limitado |
| 2.4.1 | Aplicable | Acceso a navegación/contenido bajo aviso; AT pendiente. | Pendiente |
| 2.4.2 | Aplicable | Títulos visibles tras corregir encuadre; lectura AT pendiente. | Limitado |
| 2.4.3 | Aplicable | Nuevo orden/retorno bajo aviso pendiente; Falla heredada en PLU-44. | Pendiente; Falla heredada conservada |
| 2.4.4 | Aplicable | Sin enlaces nuevos; acciones existentes conservadas. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 2.4.5 | N/A | No se añade un conjunto de páginas ni nueva navegación al marcador. | N/A |
| 2.4.6 | Aplicable | Demo, reset y modo de fallo nombrados; títulos separados. | Limitado |
| 2.4.7 | Aplicable | Foco visible de controles bajo nuevo encuadre pendiente. | Pendiente |
| 2.4.11 | Aplicable | Solapamiento visual corregido; scroll/foco con AT pendiente. | Limitado |
| 2.5.1 | Aplicable | Marcador sin gesto; controles y firma existentes conservan sus contratos. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 2.5.2 | Aplicable | Marcador sin acciones; cancelación táctil existente conservada. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 2.5.3 | Aplicable | Sin nombres de control nuevos; Voice Control del encuadre pendiente. | Pendiente |
| 2.5.4 | N/A | Sin activación por movimiento. | N/A |
| 2.5.7 | Aplicable | Marcador sin arrastre; excepción de firma ADR0027 conservada. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 2.5.8 | Aplicable | Sin targets nuevos; comprobar navegación bajo encuadre con Inspector. | Pendiente |
| 3.1.1 | Aplicable | Tres claves es en xcstrings; locución pendiente. | Limitado |
| 3.1.2 | Aplicable | Documento conserva idioma propio independiente del aviso. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 3.2.1 | Aplicable | Aviso sin acciones ni cambio al foco. | Limitado |
| 3.2.2 | Aplicable | Aviso no cambia por entrada; modo fijado en composición. | Limitado |
| 3.2.3 | Aplicable | Encuadre uniforme de login/shell, navegación conservada. | Limitado |
| 3.2.4 | Aplicable | Mismos nombres/roles en la navegación existente. | Limitado |
| 3.2.6 | N/A | Sin nuevo mecanismo de ayuda repetido. | N/A |
| 3.3.1 | Aplicable | Modo de error conserva mensaje y reintento del flujo real. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 3.3.2 | Aplicable | Aviso describe datos de ejemplo, reset y primer fallo simulado. | Limitado |
| 3.3.3 | Aplicable | Reintento existente sin volver a firmar; AT pendiente en PLU-45. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 3.3.4 | Aplicable | Revisión/firma/conservación reales; evidencia previa no ampliada. Sin nueva ejecución; evidencia previa en matrices08.7/08.8. | Pendiente |
| 3.3.7 | Aplicable | Misma sesión conserva datos/documento; reset explícito al relanzar. | Limitado: Swift Testing, no AT |
| 3.3.8 | Aplicable | Login real bajo encuadre nuevo; no se añade prueba cognitiva. | Pendiente por impacto |
| 4.1.2 | Aplicable | Text y agrupación nativos; Inspector/AT pendientes. | Limitado |
| 4.1.3 | Aplicable | Aviso estático sin anuncio forzado; anuncios de flujo heredados fallan. | Pendiente; Falla heredada conservada |
