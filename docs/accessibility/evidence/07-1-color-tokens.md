# Evidencia de accesibilidad — 07.1 tokens visuales

Fecha: 2026-08-21
Alcance: PLU-26 / subfase 07.1. Catálogo de 18 colores semánticos y AccentColor con Light, Dark, High Contrast Light y
High Contrast Dark, más las remediaciones puntuales de entrada, agrupación y contraste del CTA en Login. No cambian
navegación, copy ni lógica de negocio.

## Evidencia transversal

- Tests: 6/6 del catálogo y 788/788 del plan completo mediante Xcode MCP; la pasada final incluye la regresión de
  orientación y la nueva clasificación explícita de Firebase Auth 12.18.0.
- Build: correcto mediante Xcode MCP tras los cambios; cero warnings en build log y cero issues warning+ en Navigator.
- Contraste: valores sRGB exactos, AccentColor idéntico a BrandPrimaryInk, pares de texto con umbral 4.5:1 y acento no
  textual con umbral 3:1 verificados por Swift Testing. El CTA usa explícitamente `BrandPrimary`/`OnBrandPrimary`.
- Previews: Light/Dark × Large/XXX Large/AX 5 inspeccionados en Login, sesión bloqueada, error raíz y carga de clientes. También se inspeccionaron Light/Dark Large en Login loading, Session unlocking, raíz local-denied/authenticated y lista empty/content/error.
- Limitación histórica del 11 de agosto: RenderPreview no exponía Increase Contrast. El 20 de agosto la superficie sí
  ofreció `Contrast` y se inspeccionó Login post-parche en Dark + Increased Contrast + AX 5, además de la variante
  estándar, sin recortes ni cambios visuales inesperados.
- Accessibility Inspector y tecnologías de asistencia: Inspector post-separación detectó un P1 de contraste del CTA en
  Dark y su repetición post-corrección ya no lo reproduce. La pasada final no emite avisos de contraste ni `Hit Region` y
  conserva cinco avisos genéricos de Dynamic Type no corroborados por código, previews ni runtime AX 5. Switch Control agrupado pasa en
  iPhone 11 y iPhone 14; VoiceOver y Voice Control pasan en el iPhone 14 sobre la separación en dos `Section`. Full
  Keyboard Access pasa en el simulador final. La regresión física de las tres tecnologías pasa también tras ampliar el
  área operable de los campos.
- Fuente de verdad: ADR 0022 y docs/accessibility/WCAG22_AA_IOS.md. Esto es evidencia del objetivo interno, no certificación WCAG ni conformidad legal.
- Auditorías independientes: la pasada física detectó un P1 de Switch Control en Login y la primera postimplementación
  confirmó su corrección en ambos dispositivos. La reauditoría postcontraste no encuentra P0–P3 y acepta el CTA para
  continuar; el cierre sigue bloqueado únicamente por evidencia runtime aplicable incompleta.
- Pasada runtime del 12 de agosto: Accessibility Inspector auditó `Fran DEV` en un iPad Air 11 pulgadas (M4), iOS 26.5,
  sin warnings en Login. Light/Dark con Increase Contrast y landscape se inspeccionaron en ejecución sin recortes,
  solapes ni pérdida del árbol accesible visible (`Iniciar sesión`, email, contraseña y `Acceder`). Los ajustes del
  simulador se restauraron a Light, contraste normal y portrait al terminar.
- Primer intento físico: Xcode 26.6 detectó `iPhone14 de Jesús` con iOS 26.6, pero no pudo montar la developer disk image
  mientras el dispositivo estaba bloqueado (`kAMDMobileImageMounterDeviceLocked`, CoreDeviceError 12040). Apple indica
  que VoiceOver no está disponible en Simulator. El bloqueo se resolvió después y los resultados físicos actuales se
  registran a continuación.
- VoiceOver físico: tras desbloquear el dispositivo, Xcode preparó el iPhone14 con iOS 26.6 y ejecutó `Fran DEV`. El
  propietario recorrió Login únicamente con VoiceOver en el orden `Iniciar sesión`, email, contraseña y `Acceder`, y
  confirmó una única locución por elemento, orden comprensible, nombre y tipo correctos. Resultado: pasa para Login;
  los otros flujos y las demás tecnologías de asistencia siguen pendientes.
- Voice Control físico (2026-08-20): con VoiceOver desactivado y `Mostrar nombres`, el propietario dijo `Tocar Email` y
  el foco se desplazó a contraseña; al decir `Tocar Contraseña`, el foco se desplazó al título `Iniciar sesión`.
  Resultado baseline: **Falla** para Login en 2.5.3; la secuencia se detuvo antes de Switch Control.
- Remediación aprobada e implementada (2026-08-21): `TextField` y `SecureField` conservan sus labels principales y añaden
  `accessibilityInputLabels` localizados con los textos visibles `Email` y `Contraseña`. Diagnóstico de archivo, build,
  plan 786/786 y previews estándar/Dark + Increased Contrast + AX 5 pasan.
- Voice Control físico post-parche (2026-08-21): en un iPhone 11, con VoiceOver apagado y sin introducir credenciales,
  `Tocar Email` enfocó Email y `Tocar Contraseña` enfocó Contraseña. Resultado: **Pasa** para Login en 2.5.3; la versión
  confirmada por CoreDevice es iOS 26.6, build 23G5057c.
- VoiceOver físico post-parche (2026-08-21): en el mismo iPhone 11, Login se recorrió hacia delante y hacia atrás con
  orden estable, una locución por elemento, nombres y funciones correctos y sin saltos ni duplicados. Resultado: pasa
  el smoke de Login; CoreDevice confirma iOS 26.6, build 23G5057c.
- Full Keyboard Access baseline (2026-08-21): el teclado software mostró `Done`, que avanzó al siguiente campo, pero no
  ofrece `Tab` ni `Mayúsculas + Tab`; esta observación inicial no validó ni invalidó la operación completa por teclado.
- Switch Control físico (2026-08-21): con exploración automática, pantalla completa `Seleccionar ítem` y `Agrupar ítems`
  activo, Email/Contraseña formaron un grupo que no permitió entrar ni operar los campos; Acceder y el teclado software
  se exploraron aparte. Al desactivar `Agrupar ítems`, el recorrido separó correctamente Email, Contraseña, Acceder y
  cada elemento del teclado. Dispositivo: iPhone 11, iOS 26.6 (23G5057c). Resultado: **Falla** 2.1.2/2.4.3 con agrupación
  activa; el control sin agrupación pasa.
- Reproducción cruzada de Switch Control (2026-08-21): iPhone 14, iOS 26.6 (23G71), con `Agrupar ítems` activo presenta
  el mismo grupo inseparable Email/Contraseña. La coincidencia en dos modelos y builds confirma que el P1 no está acotado
  al iPhone 11.
- Revisión independiente: P1 por inoperabilidad del Login con una configuración soportada. Causa probable en la frontera
  `Form`/primera `Section`; `accessibilityInputLabels` es improbable como causa de agrupación. Gate:
  `correct before proceeding`.
- Revisión independiente de propuesta: PASS para pedir aprobación de separar Email y Contraseña en dos `Section`
  nativas. Se descarta `.accessibilityElement(children: .contain)` porque añade jerarquía agrupada sin evidencia física
  de resolver la entrada al grupo. El cambio debe conservar campos, AutoFill, foco e input labels y validarse después
  con Switch Control agrupado en ambos dispositivos; todavía no es PASS de accesibilidad.
- Implementación post-P1 (2026-08-21): Email y Contraseña viven en dos `Section` nativas; sin `.contain` ni cambios en
  campos, AutoFill, `FocusState`, input labels, CTA o ViewModel. Xcode MCP: cero diagnósticos del archivo, build correcto,
  cero warnings/issues warning+ y previews Idle inspeccionadas en Large, XXX Large, AX 5 Dark + Increased Contrast y
  Large landscape, sin recortes ni pérdida de acciones. En el destino físico pasan 778/786 tests; los ocho fallos leen
  rutas fuente del Mac no disponibles en el sandbox del iPhone. La repetición posterior en iPhone 17 Simulator/iOS 26.5
  pasa 786/786, sin fallos, skips, expected failures o casos sin ejecutar, y cierra esa limitación.
- Switch Control post-corrección (2026-08-21): iPhone 11, iOS 26.6 (23G5057c), con `Agrupar ítems` activo. Email y
  Contraseña ya se operan por separado. Resultado: **Pasa** en este dispositivo; la repetición cruzada posterior se
  registra a continuación.
- Switch Control post-corrección cruzado (2026-08-21): iPhone 14, iOS 26.6 (23G71), con `Agrupar ítems` activo. Presenta
  el mismo comportamiento correcto que el iPhone 11: Email y Contraseña son operables por separado. Resultado: **Pasa**;
  el P1 cruzado queda corregido. Las regresiones posteriores de VoiceOver y Voice Control se registran a continuación.
- VoiceOver post-corrección (2026-08-21): iPhone 14, iOS 26.6 (23G71). Login se recorre hacia delante y atrás en el orden
  `Iniciar sesión → Email → Contraseña → Acceder`, sin uniones ni saltos. Resultado: **Pasa** para esta regresión de
  Login; la regresión posterior de Voice Control se registra a continuación.
- Voice Control post-corrección (2026-08-21): iPhone 14, iOS 26.6 (23G71). `Tocar Email` y `Tocar Contraseña` enfocan
  su propio campo a la primera, sin introducir credenciales. Resultado: **Pasa** para Login y 2.5.3.
- Auditoría read-only postimplementación: sin P0/P1/P3 en Swift; confirma el alcance mínimo y la conservación de
  `disabled`, AutoFill, `FocusState` y orden. Gate: **PASS para validación física restante**. El P2 de trazabilidad emitido
  mientras el dispositivo era desconocido queda resuelto por la confirmación del propietario del iPhone 11/iOS 26.6
  (23G5057c); no equivale a cierre de accesibilidad.
- Accessibility Inspector post-separación (2026-08-21): en `Fran DEV`, iPhone 17 Simulator/iOS 26.5, Dark normal,
  detectó un P1 real de 1.4.3 en el CTA: 2,14:1 entre `#E49ACE` y `#FFFFFF`. También emitió tres avisos genéricos de
  Dynamic Type sobre dos `UITextField` nativos y un `SwiftUI.AccessibilityNode`.
- Revisión independiente de la propuesta de contraste: `correct before proceeding`. Aprobó conservar el botón nativo
  `.borderedProminent` y aplicar explícitamente `BrandPrimary`/`OnBrandPrimary`; los cuatro ratios son 4,95:1, 9,81:1,
  10,55:1 y 12,28:1. Clasificó los avisos Dynamic Type como limitación no corroborada, no como tres defectos demostrados.
- Corrección y repetición de Inspector (2026-08-21): el `Label` del CTA usa `.foregroundStyle(.onBrandPrimary)` y el
  botón `.tint(.brandPrimary)`. Build, diagnósticos, Navigator y plan 786/786 pasan. Las cuatro apariencias y AX 5 se
  inspeccionan sin pérdida. Inspector en el mismo Login Dark ya no emite contraste y conserva solo los tres avisos
  Dynamic Type; los avisos no se silencian y permanecieron limitados hasta la comprobación runtime siguiente.
- Dynamic Type runtime AX 5 (2026-08-21): `Fran DEV`, iPhone 17 Simulator/iOS 26.5, tamaños ampliados activos al 100 %.
  Título, labels, campos y CTA escalan sin recortes, solapes ni pérdida de controles; Email y Contraseña reciben foco sin
  introducir credenciales. Los tres avisos genéricos del Inspector no se reproducen en ejecución y 1.4.4 pasa para Login.
  El iPhone 17 y `Clone 1 of iPhone 17` se restauraron a tamaños ampliados desactivados y 50 %; `Fran DEV` quedó visible.
- Orientación runtime y contrato (2026-08-21): se detectó que las cuatro configuraciones iPhone del target declaraban
  solo portrait. Se añadieron portrait, landscape left y landscape right, cubiertos por
  `hostedApplicationSupportsIPhonePortraitAndLandscape`. En iPhone 17 Simulator/iOS 26.5, Login conserva título, campos y
  CTA en portrait y ambas orientaciones landscape, y vuelve correctamente a portrait.
- Full Keyboard Access final (2026-08-21): con el teclado hardware del Mac conectado al iPhone 17 Simulator, el foco
  visible avanza `Email → Contraseña → Acceder` con `Tab` y retrocede `Acceder → Contraseña → Email` con
  `Mayúsculas + Tab`, sin paradas extra ni trampas. `Espacio` activa el CTA vacío y muestra su error local. Resultado:
  **Pasa** para Login en 2.1.1, 2.1.2, 2.4.3, 2.4.7 y 2.4.11.
- Área operable final (2026-08-21): RED manual confirmó que Email y Contraseña solo aceptaban interacción en una franja
  vertical aproximada de 22 pt aunque Inspector no avisaba de `Hit Region`. GREEN aplica a cada control
  `.frame(minHeight: 44)`, `.contentShape(.interaction, Rectangle())` y un `TapGesture` local que conserva `disabled` y
  enfoca ese mismo campo. Centro y ocho puntos del perímetro pasan 9/9 en ambos campos; el borde inferior del CTA también
  activa. La colocación de cursor sigue siendo nativa (`abcd` + toque cerca del inicio + `x` produce `xabcd`). Resultado:
  **Pasa** para Login en 2.5.8; no se usaron credenciales.
- Hallazgos P2 de auditoría final (2026-08-21): los prompts nativos renderizaban aproximadamente 1,78:1 en Light y seis
  filas de evidencia física estaban sobreclasificadas tras el último gesto. Ambos prompts usan ahora `TextSecondary`, par
  ya cubierto por los umbrales 4,5:1/7:1 del test de catálogo; las seis filas quedan `Limitado` hasta repetir la pasada
  física. Inspector final no emite contraste ni `Hit Region`; sus cinco avisos genéricos de Dynamic Type no se reproducen
  en preview ni en runtime AX 5 final.
- Compatibilidad Firebase 12.18.0 (2026-08-21): `passwordDoesNotMeetRequirements` se clasifica explícitamente como
  `credentialsRejected` para preservar el contrato estable y evitar filtrar existencia de cuenta. La fixture focal pasa.
- Validación final (2026-08-21): diagnósticos de `LoginContent.swift` y del adaptador Firebase sin issues, build correcto,
  cero warnings en build log, cero issues warning+ en Navigator y 788/788 tests. Previews Light, AX 5 Dark + Increased
  Contrast y landscape sin recortes ni pérdida de acciones. FKA, su alto contraste, Dynamic Type y overrides de Xcode se
  restauraron a cero; el simulador quedó en portrait con Login vacío.
- Reauditorías finales (2026-08-21): accesibilidad e iOS no detectan P0–P3 en las correcciones. Los prompts, la
  reclasificación conservadora de las seis filas, la compatibilidad Firebase 12.18.0 y la paridad de Linear quedan
  aceptados. Gate automático: **PASS**; gate 07.1/ADR 0022: **BLOCKED** por la evidencia manual restante.
- Reauditoría read-only postcontraste: sin P0–P3. Verifica estáticamente el par, ratios, controles nativos y conservación
  de labels, AutoFill, foco, `disabled`, agrupación y delegación. La corrección fue aceptable para continuar. En ese corte,
  el gate quedó bloqueado por Full Keyboard Access, anuncios, AutoFill real, 44×44 pt y demás flujos/ventanas; FKA y el
  área operable se resolvieron después en la evidencia final anterior.
- Regresión física final (2026-08-21): iPhone 14, iOS 26.6 (23G71), sobre la superficie táctil final. VoiceOver recorre
  `Iniciar sesión → Email → Contraseña → Acceder` en ambos sentidos; Email y Contraseña se activan y editan en su propio
  foco a la primera. El CTA vacío presenta el error local y devuelve el foco a Email. Voice Control activa Email,
  Contraseña y Acceder a la primera. Switch Control, con `Agrupar ítems` activo por defecto, expone y opera los tres
  elementos por separado. Resultado: **Pasa** la regresión final de Login para las seis filas antes limitadas.
- Autorrelleno (2026-08-21): al enfocar ambos campos no apareció una sugerencia. El dispositivo no dispone de una
  credencial de prueba y el proyecto no tiene configurado todavía un método de acceso ni un usuario registrado. La
  inspección confirma `.textContentType(.username)` y `.textContentType(.password)`; la prueba end-to-end queda
  `Limitado`, no `Falla`. No se activó Firebase Auth ni se creó un usuario live fuera de 07.1.

## Bootstrap y raíz de autenticación

- Alcance/cambio: AccentColor en ProgressView, Retry y acciones destructivas; sin cambios semánticos.
- Dispositivo, iOS y build: Xcode Preview en destino activo del esquema FranAlonso-Develop; SDK iOS 26.5; modelo exacto no devuelto por MCP.
- Previews y apariencias: ver evidencia transversal; sin recortes ni solapes en las variantes ejecutadas.
- Inspector y tecnologías de asistencia: pendientes; las filas afectadas no se marcan como superadas.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles informativos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.2.1 | N/A | Sin audio o vídeo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio o vídeo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.2 | N/A | Sin audio sincronizado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio sincronizado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.4 | N/A | Sin directo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin directo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.3.1 | Aplicable | Jerarquía, labels y grupos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.2 | Aplicable | Orden visual y accesible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.3 | Aplicable | Copy no sensorial. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 1.3.4 | Aplicable | Orientación y ventana. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Landscape y multitarea pendientes. | Implementación; auditor pendiente |
| 1.3.5 | N/A | Propósito de entrada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Propósito de entrada no aplica a este flujo. | Implementación; auditor pendiente |
| 1.4.1 | Aplicable | Estados no dependen sólo del color. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.2 | N/A | Sin audio automático. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio automático no existe en el alcance. | Implementación; auditor pendiente |
| 1.4.3 | Aplicable | Contraste de texto. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.4 | Aplicable | Dynamic Type. | Limitado | RenderPreview Large/XXX Large/AX 5; runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Previews sin recorte; uso runtime AX 5 pendiente. | Implementación; auditor pendiente |
| 1.4.5 | Aplicable | Texto real. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.10 | Aplicable | Reflow. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | iPhone/ventana estrecha pendientes. | Implementación; auditor pendiente |
| 1.4.11 | Aplicable | Contraste de controles. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.12 | Aplicable | Espaciado de texto. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Ajuste explícito de espaciado no expuesto por MCP. | Implementación; auditor pendiente |
| 1.4.13 | N/A | Sin contenido hover/foco. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin contenido hover/foco no existe en el alcance. | Implementación; auditor pendiente |
| 2.1.1 | Aplicable | Operación por teclado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.2 | Aplicable | Salida del foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.4 | N/A | Sin atajos de carácter. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin atajos de carácter no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.1 | N/A | Sin límite temporal. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin límite temporal no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.2 | N/A | Sin movimiento auto que requiera control. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento auto que requiera control no existe en el alcance. | Implementación; auditor pendiente |
| 2.3.1 | Aplicable | Sin destellos. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 2.4.1 | Aplicable | Estructura eficiente. | Pendiente | Manual pendiente | Xcode Preview · destino activo · 2026-08-11 | Requiere validación runtime antes del cierre. | Implementación; auditor pendiente |
| 2.4.2 | Aplicable | Título descriptivo. | Pendiente | Preview + anuncio runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Título visible; anuncio por tecnología de asistencia pendiente. | Implementación; auditor pendiente |
| 2.4.3 | Aplicable | Orden de foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.4 | Aplicable | Acciones comprensibles. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.4.5 | N/A | Colección no extensa. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Colección no extensa no existe en el alcance. | Implementación; auditor pendiente |
| 2.4.6 | Aplicable | Encabezados y labels. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.7 | Aplicable | Foco visible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.11 | Aplicable | Foco no oculto. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.5.1 | N/A | Sin gesto multipunto o trayectoria. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin gesto multipunto o trayectoria no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.2 | Aplicable | Activación estándar. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.5.3 | Aplicable | Nombre coincide con texto. | Pendiente | Inspección estática + Voice Control pendiente | Xcode Preview · destino activo · 2026-08-11 | Coincidencia visual observada; activación por nombre pendiente. | Implementación; auditor pendiente |
| 2.5.4 | N/A | Sin movimiento del dispositivo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento del dispositivo no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.7 | N/A | Sin arrastre. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin arrastre no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.8 | Aplicable | Objetivos interactivos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.1.1 | Aplicable | Idioma español. | Pendiente | Inspección estática + VoiceOver pendiente | Xcode Preview · destino activo · 2026-08-11 | Copy en español; pronunciación runtime pendiente. | Implementación; auditor pendiente |
| 3.1.2 | N/A | Sin cambio de idioma. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin cambio de idioma no existe en el alcance. | Implementación; auditor pendiente |
| 3.2.1 | Aplicable | Foco sin cambio inesperado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.2.2 | N/A | Entrada sin navegación inesperada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Entrada sin navegación inesperada no aplica a este flujo. | Implementación; auditor pendiente |
| 3.2.3 | Aplicable | Patrones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.4 | Aplicable | Acciones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.6 | N/A | Sin mecanismo de ayuda. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin mecanismo de ayuda no existe en el alcance. | Implementación; auditor pendiente |
| 3.3.1 | Aplicable | Errores textuales. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.2 | N/A | Labels e instrucciones. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Labels e instrucciones no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.3 | N/A | Sugerencia de corrección. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sugerencia de corrección no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.4 | Aplicable | Acción destructiva. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.7 | N/A | Sin entrada redundante. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin entrada redundante no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.8 | N/A | Autenticación reconocible. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Autenticación reconocible no aplica a este flujo. | Implementación; auditor pendiente |
| 4.1.2 | Aplicable | Nombre, función y valor. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 4.1.3 | Aplicable | Mensajes de estado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |

## Login

- Alcance/cambio: AccentColor en foco y progreso; el CTA usa el par semántico `BrandPrimary`/`OnBrandPrimary` y los
  estados de éxito/error conservan colores del sistema. Los campos añaden nombres de entrada localizados y viven en dos
  `Section` nativas. Cada campo expone un área operable mínima de 44 pt y un gesto local que conserva el foco nativo,
  `disabled`, AutoFill, copy y lógica.
- Dispositivo, iOS y build: Xcode Preview en destino activo del esquema FranAlonso-Develop; SDK iOS 26.5; modelo exacto no devuelto por MCP.
- Previews y apariencias: ver evidencia transversal; sin recortes ni solapes en las variantes ejecutadas.
- Inspector y tecnologías de asistencia: el P1 de contraste post-separación queda corregido y no reaparece en Inspector;
  cinco avisos genéricos de Dynamic Type no se reproducen en runtime AX 5. VoiceOver, Voice Control y Switch Control
  agrupado pasan en las repeticiones físicas de la separación en dos `Section`. Full Keyboard Access y el área operable
  mínima y la regresión física de las tres tecnologías pasan sobre el parche final.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles informativos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.2.1 | N/A | Sin audio o vídeo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio o vídeo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.2 | N/A | Sin audio sincronizado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio sincronizado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.4 | N/A | Sin directo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin directo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.3.1 | Aplicable | Jerarquía, labels y grupos. | Pasa | Inspector final + VoiceOver/Switch Control final | iPhone 17 Simulator · 26.5; iPhone 14 · 26.6 (23G71) · 2026-08-21 | Título, Email, Contraseña y Acceder se exponen por separado; Switch Control agrupado conserva tres controles operables. | Propietario; auditor P2 corregido |
| 1.3.2 | Aplicable | Orden visual y accesible. | Pasa | Full Keyboard Access + VoiceOver/Switch Control final | iPhone 17 Simulator · 26.5; iPhone 14 · 26.6 (23G71) · 2026-08-21 | El orden coincide por teclado, VoiceOver en ambos sentidos y Switch Control sobre la superficie final. | Propietario; auditor P2 corregido |
| 1.3.3 | Aplicable | Copy no sensorial. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 1.3.4 | Aplicable | Orientación y ventana. | Pasa | Test de contrato + runtime portrait/ambos landscape | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Las cuatro configuraciones iPhone admiten portrait y ambas orientaciones landscape; Login conserva contenido y acciones al rotar y restaurar. Multitarea iPad se mantiene como evidencia de ventana separada. | Implementación; auditor final pendiente |
| 1.3.5 | Aplicable | Propósito de entrada. | Limitado | Inspección de código + intento runtime sin fixture | iPhone 14 · iOS 26.6 (23G71) · 2026-08-21 | `.username`/`.password` identifican el propósito; no hay proveedor ni usuario de pruebas con que verificar Autorrelleno end-to-end. | Implementación; propietario |
| 1.4.1 | Aplicable | Estados no dependen sólo del color. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.2 | N/A | Sin audio automático. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio automático no existe en el alcance. | Implementación; auditor pendiente |
| 1.4.3 | Aplicable | Contraste de texto. | Pasa | Test, previews e Inspector post-corrección | iPhone 17 Simulator · iOS 26.5 · Light/Dark · 2026-08-21 | CTA corregido con ratios 4,95–12,28:1; prompts corregidos con `TextSecondary`, par cubierto a 4,5:1/7:1. Inspector final no emite contraste. | Implementación; auditor P2 corregido; reauditoría pendiente |
| 1.4.4 | Aplicable | Dynamic Type. | Pasa | RenderPreview Large/XXX Large/AX 5 + Inspector + runtime AX 5 | iPhone 17 Simulator · iOS 26.5 · tamaños ampliados 100 % · 2026-08-21 | Título, labels, campos y CTA escalan; Email/Contraseña reciben foco; sin recortes, solapes ni pérdida. Los tres avisos genéricos del Inspector no se reproducen en runtime. | Implementación; revisión independiente sin P0–P3 |
| 1.4.5 | Aplicable | Texto real. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.10 | Aplicable | Reflow. | Pasa | RenderPreview AX 5 + runtime portrait/landscape | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Login refluye sin recortes, solapes ni pérdida de título, campos o CTA en AX 5 y ambas orientaciones landscape. | Implementación; auditor final pendiente |
| 1.4.11 | Aplicable | Contraste de controles. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.12 | Aplicable | Espaciado de texto. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Ajuste explícito de espaciado no expuesto por MCP. | Implementación; auditor pendiente |
| 1.4.13 | N/A | Sin contenido hover/foco. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin contenido hover/foco no existe en el alcance. | Implementación; auditor pendiente |
| 2.1.1 | Aplicable | Operación por teclado. | Pasa | Full Keyboard Access final | iPhone 17 Simulator · iOS 26.5 · teclado hardware conectado · 2026-08-21 | `Tab`, `Mayúsculas + Tab` y `Espacio` recorren y activan los tres controles sin depender del puntero. | Implementación; auditor final pendiente |
| 2.1.2 | Aplicable | Salida del foco. | Pasa | Full Keyboard Access + Switch Control final | iPhone 17 Simulator · iOS 26.5; iPhone 14 · iOS 26.6 (23G71) · 2026-08-21 | No hay trampa por teclado ni por Switch Control agrupado sobre la superficie final. | Propietario; auditor P2 corregido |
| 2.1.4 | N/A | Sin atajos de carácter. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin atajos de carácter no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.1 | N/A | Sin límite temporal. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin límite temporal no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.2 | N/A | Sin movimiento auto que requiera control. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento auto que requiera control no existe en el alcance. | Implementación; auditor pendiente |
| 2.3.1 | Aplicable | Sin destellos. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 2.4.1 | Aplicable | Estructura eficiente. | Pendiente | Manual pendiente | Xcode Preview · destino activo · 2026-08-11 | Requiere validación runtime antes del cierre. | Implementación; auditor pendiente |
| 2.4.2 | Aplicable | Título descriptivo. | Pendiente | Preview + anuncio runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Título visible; anuncio por tecnología de asistencia pendiente. | Implementación; auditor pendiente |
| 2.4.3 | Aplicable | Orden de foco. | Pasa | Full Keyboard Access + VoiceOver/Switch Control final | iPhone 14 · iOS 26.6 (23G71); iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | El orden final coincide por teclado, VoiceOver en ambos sentidos y Switch Control agrupado. | Propietario; auditor P2 corregido |
| 2.4.4 | Aplicable | Acciones comprensibles. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.4.5 | N/A | Colección no extensa. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Colección no extensa no existe en el alcance. | Implementación; auditor pendiente |
| 2.4.6 | Aplicable | Encabezados y labels. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.7 | Aplicable | Foco visible. | Pasa | Full Keyboard Access final | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | El anillo de foco visible acompaña Email, Contraseña y Acceder en ambos sentidos. | Implementación; auditor final pendiente |
| 2.4.11 | Aplicable | Foco no oculto. | Pasa | Full Keyboard Access + previews AX 5/landscape | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Ningún elemento enfocado queda oculto por contenido creado por la app. | Implementación; auditor final pendiente |
| 2.5.1 | N/A | Sin gesto multipunto o trayectoria. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin gesto multipunto o trayectoria no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.2 | Aplicable | Activación estándar. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.5.3 | Aplicable | Nombre coincide con texto. | Pasa | Voice Control final + inspección estática | iPhone 14 · iOS 26.6 (23G71) · 2026-08-21 | `Tocar Email`, `Tocar Contraseña` y `Tocar Acceder` activan el control correcto a la primera. | Propietario; auditor P2 corregido |
| 2.5.4 | N/A | Sin movimiento del dispositivo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento del dispositivo no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.7 | N/A | Sin arrastre. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin arrastre no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.8 | Aplicable | Objetivos interactivos. | Pasa | Código + barrido manual RED/GREEN + Inspector | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Los campos exponen 44 pt mínimos y pasan centro + perímetro 9/9; CTA activa desde su borde. Inspector no emite `Hit Region`. | Implementación; revisión independiente de propuesta |
| 3.1.1 | Aplicable | Idioma español. | Pendiente | Inspección estática + VoiceOver pendiente | Xcode Preview · destino activo · 2026-08-11 | Copy en español; pronunciación runtime pendiente. | Implementación; auditor pendiente |
| 3.1.2 | N/A | Sin cambio de idioma. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin cambio de idioma no existe en el alcance. | Implementación; auditor pendiente |
| 3.2.1 | Aplicable | Foco sin cambio inesperado. | Pasa | Full Keyboard Access + entrada manual | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Foco y activación no provocan cambios de contexto inesperados. | Implementación; auditor final pendiente |
| 3.2.2 | Aplicable | Entrada sin navegación inesperada. | Pasa | Full Keyboard Access + entrada manual | iPhone 17 Simulator · iOS 26.5 · 2026-08-21 | Escribir y colocar el cursor permanece en el campo; solo el CTA ejecuta la acción explícita. | Implementación; auditor final pendiente |
| 3.2.3 | Aplicable | Patrones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.4 | Aplicable | Acciones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.6 | N/A | Sin mecanismo de ayuda. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin mecanismo de ayuda no existe en el alcance. | Implementación; auditor pendiente |
| 3.3.1 | Aplicable | Errores textuales. | Pasa | VoiceOver + validación vacía | iPhone 14 · iOS 26.6 (23G71) · 2026-08-21 | El CTA vacío presenta el error de validación y devuelve el foco al primer campo con error. | Propietario |
| 3.3.2 | Aplicable | Labels e instrucciones. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.3 | Aplicable | Sugerencia de corrección. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.4 | N/A | Acción destructiva. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Acción destructiva no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.7 | Aplicable | Sin entrada redundante. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.8 | Aplicable | Autenticación reconocible. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 4.1.2 | Aplicable | Nombre, función y valor. | Pasa | Inspector final + VoiceOver/Voice Control final | iPhone 17 Simulator · iOS 26.5; iPhone 14 · iOS 26.6 (23G71) · 2026-08-21 | Nombre, función, orden y activación se confirman sobre la superficie final. | Propietario; auditor P2 corregido |
| 4.1.3 | Aplicable | Mensajes de estado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |

## Sesión protegida

- Alcance/cambio: AccentColor en desbloqueo y progreso; acciones destructivas y errores conservan colores del sistema.
- Dispositivo, iOS y build: Xcode Preview en destino activo del esquema FranAlonso-Develop; SDK iOS 26.5; modelo exacto no devuelto por MCP.
- Previews y apariencias: ver evidencia transversal; sin recortes ni solapes en las variantes ejecutadas.
- Inspector y tecnologías de asistencia: pendientes; las filas afectadas no se marcan como superadas.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles informativos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.2.1 | N/A | Sin audio o vídeo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio o vídeo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.2 | N/A | Sin audio sincronizado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio sincronizado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.4 | N/A | Sin directo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin directo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.3.1 | Aplicable | Jerarquía, labels y grupos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.2 | Aplicable | Orden visual y accesible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.3 | Aplicable | Copy no sensorial. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 1.3.4 | Aplicable | Orientación y ventana. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Landscape y multitarea pendientes. | Implementación; auditor pendiente |
| 1.3.5 | N/A | Propósito de entrada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Propósito de entrada no aplica a este flujo. | Implementación; auditor pendiente |
| 1.4.1 | Aplicable | Estados no dependen sólo del color. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.2 | N/A | Sin audio automático. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio automático no existe en el alcance. | Implementación; auditor pendiente |
| 1.4.3 | Aplicable | Contraste de texto. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.4 | Aplicable | Dynamic Type. | Limitado | RenderPreview Large/XXX Large/AX 5; runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Previews sin recorte; uso runtime AX 5 pendiente. | Implementación; auditor pendiente |
| 1.4.5 | Aplicable | Texto real. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.10 | Aplicable | Reflow. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | iPhone/ventana estrecha pendientes. | Implementación; auditor pendiente |
| 1.4.11 | Aplicable | Contraste de controles. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.12 | Aplicable | Espaciado de texto. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Ajuste explícito de espaciado no expuesto por MCP. | Implementación; auditor pendiente |
| 1.4.13 | N/A | Sin contenido hover/foco. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin contenido hover/foco no existe en el alcance. | Implementación; auditor pendiente |
| 2.1.1 | Aplicable | Operación por teclado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.2 | Aplicable | Salida del foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.4 | N/A | Sin atajos de carácter. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin atajos de carácter no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.1 | N/A | Sin límite temporal. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin límite temporal no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.2 | N/A | Sin movimiento auto que requiera control. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento auto que requiera control no existe en el alcance. | Implementación; auditor pendiente |
| 2.3.1 | Aplicable | Sin destellos. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 2.4.1 | Aplicable | Estructura eficiente. | Pendiente | Manual pendiente | Xcode Preview · destino activo · 2026-08-11 | Requiere validación runtime antes del cierre. | Implementación; auditor pendiente |
| 2.4.2 | Aplicable | Título descriptivo. | Pendiente | Preview + anuncio runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Título visible; anuncio por tecnología de asistencia pendiente. | Implementación; auditor pendiente |
| 2.4.3 | Aplicable | Orden de foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.4 | Aplicable | Acciones comprensibles. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.4.5 | N/A | Colección no extensa. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Colección no extensa no existe en el alcance. | Implementación; auditor pendiente |
| 2.4.6 | Aplicable | Encabezados y labels. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.7 | Aplicable | Foco visible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.11 | Aplicable | Foco no oculto. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.5.1 | N/A | Sin gesto multipunto o trayectoria. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin gesto multipunto o trayectoria no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.2 | Aplicable | Activación estándar. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.5.3 | Aplicable | Nombre coincide con texto. | Pendiente | Inspección estática + Voice Control pendiente | Xcode Preview · destino activo · 2026-08-11 | Coincidencia visual observada; activación por nombre pendiente. | Implementación; auditor pendiente |
| 2.5.4 | N/A | Sin movimiento del dispositivo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento del dispositivo no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.7 | N/A | Sin arrastre. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin arrastre no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.8 | Aplicable | Objetivos interactivos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.1.1 | Aplicable | Idioma español. | Pendiente | Inspección estática + VoiceOver pendiente | Xcode Preview · destino activo · 2026-08-11 | Copy en español; pronunciación runtime pendiente. | Implementación; auditor pendiente |
| 3.1.2 | N/A | Sin cambio de idioma. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin cambio de idioma no existe en el alcance. | Implementación; auditor pendiente |
| 3.2.1 | Aplicable | Foco sin cambio inesperado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.2.2 | N/A | Entrada sin navegación inesperada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Entrada sin navegación inesperada no aplica a este flujo. | Implementación; auditor pendiente |
| 3.2.3 | Aplicable | Patrones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.4 | Aplicable | Acciones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.6 | N/A | Sin mecanismo de ayuda. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin mecanismo de ayuda no existe en el alcance. | Implementación; auditor pendiente |
| 3.3.1 | Aplicable | Errores textuales. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.2 | N/A | Labels e instrucciones. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Labels e instrucciones no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.3 | N/A | Sugerencia de corrección. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sugerencia de corrección no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.4 | Aplicable | Acción destructiva. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.7 | N/A | Sin entrada redundante. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin entrada redundante no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.8 | Aplicable | Autenticación reconocible. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 4.1.2 | Aplicable | Nombre, función y valor. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 4.1.3 | Aplicable | Mensajes de estado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |

## Área autenticada y lista de clientes

- Alcance/cambio: AccentColor en progreso y controles del contenedor; estados loading, empty, content y error.
- Dispositivo, iOS y build: Xcode Preview en destino activo del esquema FranAlonso-Develop; SDK iOS 26.5; modelo exacto no devuelto por MCP.
- Previews y apariencias: ver evidencia transversal; sin recortes ni solapes en las variantes ejecutadas.
- Inspector y tecnologías de asistencia: pendientes; las filas afectadas no se marcan como superadas.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Dispositivo/iOS/configuración/fecha | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles informativos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.2.1 | N/A | Sin audio o vídeo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio o vídeo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.2 | N/A | Sin audio sincronizado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio sincronizado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.3 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.4 | N/A | Sin directo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin directo no existe en el alcance. | Implementación; auditor pendiente |
| 1.2.5 | N/A | Sin vídeo pregrabado. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin vídeo pregrabado no existe en el alcance. | Implementación; auditor pendiente |
| 1.3.1 | Aplicable | Jerarquía, labels y grupos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.2 | Aplicable | Orden visual y accesible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 1.3.3 | Aplicable | Copy no sensorial. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 1.3.4 | Aplicable | Orientación y ventana. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Landscape y multitarea pendientes. | Implementación; auditor pendiente |
| 1.3.5 | N/A | Propósito de entrada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Propósito de entrada no aplica a este flujo. | Implementación; auditor pendiente |
| 1.4.1 | Aplicable | Estados no dependen sólo del color. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.2 | N/A | Sin audio automático. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin audio automático no existe en el alcance. | Implementación; auditor pendiente |
| 1.4.3 | Aplicable | Contraste de texto. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.4 | Aplicable | Dynamic Type. | Limitado | RenderPreview Large/XXX Large/AX 5; runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Previews sin recorte; uso runtime AX 5 pendiente. | Implementación; auditor pendiente |
| 1.4.5 | Aplicable | Texto real. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 1.4.10 | Aplicable | Reflow. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | iPhone/ventana estrecha pendientes. | Implementación; auditor pendiente |
| 1.4.11 | Aplicable | Contraste de controles. | Pasa | Test DesignSystemColorAssetTests | Xcode MCP · iOS 26.5 SDK · 2026-08-11 | Cuatro apariencias verificadas con umbral aplicable. | Implementación; auditor pendiente |
| 1.4.12 | Aplicable | Espaciado de texto. | Limitado | RenderPreview iPad portrait | Xcode Preview · destino activo · 2026-08-11 | Ajuste explícito de espaciado no expuesto por MCP. | Implementación; auditor pendiente |
| 1.4.13 | N/A | Sin contenido hover/foco. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin contenido hover/foco no existe en el alcance. | Implementación; auditor pendiente |
| 2.1.1 | Aplicable | Operación por teclado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.2 | Aplicable | Salida del foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.1.4 | N/A | Sin atajos de carácter. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin atajos de carácter no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.1 | N/A | Sin límite temporal. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin límite temporal no existe en el alcance. | Implementación; auditor pendiente |
| 2.2.2 | N/A | Sin movimiento auto que requiera control. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento auto que requiera control no existe en el alcance. | Implementación; auditor pendiente |
| 2.3.1 | Aplicable | Sin destellos. | Pasa | Inspección estática + RenderPreview | Xcode Preview · destino activo · 2026-08-11 | Sin dependencia exclusiva de color, recorte ni imagen de texto observada. | Implementación; auditor pendiente |
| 2.4.1 | Aplicable | Estructura eficiente. | Pendiente | Manual pendiente | Xcode Preview · destino activo · 2026-08-11 | Requiere validación runtime antes del cierre. | Implementación; auditor pendiente |
| 2.4.2 | Aplicable | Título descriptivo. | Pendiente | Preview + anuncio runtime pendiente | Xcode Preview · destino activo · 2026-08-11 | Título visible; anuncio por tecnología de asistencia pendiente. | Implementación; auditor pendiente |
| 2.4.3 | Aplicable | Orden de foco. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.4 | Aplicable | Acciones comprensibles. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.4.5 | N/A | Colección no extensa. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Colección no extensa no existe en el alcance. | Implementación; auditor pendiente |
| 2.4.6 | Aplicable | Encabezados y labels. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.7 | Aplicable | Foco visible. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.4.11 | Aplicable | Foco no oculto. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 2.5.1 | N/A | Sin gesto multipunto o trayectoria. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin gesto multipunto o trayectoria no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.2 | Aplicable | Activación estándar. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 2.5.3 | Aplicable | Nombre coincide con texto. | Pendiente | Inspección estática + Voice Control pendiente | Xcode Preview · destino activo · 2026-08-11 | Coincidencia visual observada; activación por nombre pendiente. | Implementación; auditor pendiente |
| 2.5.4 | N/A | Sin movimiento del dispositivo. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin movimiento del dispositivo no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.7 | N/A | Sin arrastre. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin arrastre no existe en el alcance. | Implementación; auditor pendiente |
| 2.5.8 | Aplicable | Objetivos interactivos. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.1.1 | Aplicable | Idioma español. | Pendiente | Inspección estática + VoiceOver pendiente | Xcode Preview · destino activo · 2026-08-11 | Copy en español; pronunciación runtime pendiente. | Implementación; auditor pendiente |
| 3.1.2 | N/A | Sin cambio de idioma. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin cambio de idioma no existe en el alcance. | Implementación; auditor pendiente |
| 3.2.1 | Aplicable | Foco sin cambio inesperado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 3.2.2 | N/A | Entrada sin navegación inesperada. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Entrada sin navegación inesperada no aplica a este flujo. | Implementación; auditor pendiente |
| 3.2.3 | Aplicable | Patrones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.4 | Aplicable | Acciones consistentes. | Pasa | Inspección estática + previews | Xcode Preview · destino activo · 2026-08-11 | Sin regresión observada en el cambio de tokens. | Implementación; auditor pendiente |
| 3.2.6 | N/A | Sin mecanismo de ayuda. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin mecanismo de ayuda no existe en el alcance. | Implementación; auditor pendiente |
| 3.3.1 | Aplicable | Errores textuales. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.2 | N/A | Labels e instrucciones. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Labels e instrucciones no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.3 | N/A | Sugerencia de corrección. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sugerencia de corrección no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.4 | Aplicable | Acción destructiva. | Pendiente | Inspección estática + AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Flujo runtime pendiente. | Implementación; auditor pendiente |
| 3.3.7 | N/A | Sin entrada redundante. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Sin entrada redundante no aplica a este flujo. | Implementación; auditor pendiente |
| 3.3.8 | N/A | Autenticación reconocible. | Pasa | Inspección estática | Xcode Preview · destino activo · 2026-08-11 | Autenticación reconocible no aplica a este flujo. | Implementación; auditor pendiente |
| 4.1.2 | Aplicable | Nombre, función y valor. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |
| 4.1.3 | Aplicable | Mensajes de estado. | Pendiente | Inspector/AT pendiente | Xcode Preview · destino activo · 2026-08-11 | Árbol, foco o anuncio requieren ejecución manual. | Implementación; auditor pendiente |

## Puerta de cierre

La implementación automática y visual soportada está en verde, incluido Firebase 12.18.0, orientación iPhone,
Full Keyboard Access, objetivos operables de 44 pt y la regresión física final de Login. Accessibility Inspector confirma
resuelto el P1 de contraste del CTA y de los prompts, no emite `Hit Region` y sus cinco avisos genéricos de Dynamic Type
no se reproducen en runtime AX 5. El plan final pasa 788/788. ADR 0022 impide cerrar mientras Autorrelleno y los demás
flujos/ventanas autenticados no puedan validarse. No existe todavía método de acceso ni usuario de pruebas; la subfase
queda en espera de esa fixture autorizada, sin activar Firebase live dentro de 07.1.
