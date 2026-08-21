# Phase 07 Progress

## Estado

- Fase: 07 — Design system, localización y navegación.
- Subfase activa: 07.1 — tokens visuales y nombres semánticos (PLU-26).
- Código y recursos: implementación local, auditorías y regresión física final de Login validadas; cierre en espera de
  una fixture de autenticación autorizada para Autorrelleno y flujos autenticados.

## Evidencia

### 2026-08-21 — Orientación, teclado completo y targets operables de Login

- Se detectó que las cuatro configuraciones iPhone del target solo admitían portrait. Se añadieron portrait, landscape
  left y landscape right y un test de regresión sobre `UISupportedInterfaceOrientations`.
- En iPhone 17 Simulator/iOS 26.5, Login conserva título, Email, Contraseña y Acceder en portrait, landscape left y
  landscape right, y vuelve correctamente a portrait. Las previews Large, XXX Large, AX 5 Dark + Increased Contrast y
  landscape no presentan recortes, solapes ni pérdida de acciones.
- Full Keyboard Access pasa con teclado hardware conectado: `Tab` recorre `Email → Contraseña → Acceder`,
  `Mayúsculas + Tab` recorre el orden inverso y `Espacio` activa el CTA vacío y muestra su error local. El foco permanece
  visible y no existen paradas extra ni trampas.
- La medición manual RED detectó que cada campo solo era operable en una franja vertical aproximada de 22 pt aunque
  Accessibility Inspector no emitía `Hit Region`. Tras añadir 44 pt mínimos, `contentShape` y un gesto local condicionado
  por `disabled`, Email y Contraseña pasan centro + ocho puntos del perímetro (9/9 cada uno), el CTA activa desde su borde
  y la colocación nativa del cursor se conserva.
- La auditoría final detectó dos P2 de accesibilidad: prompts nativos a aproximadamente 1,78:1 en Light y seis filas
  físicas sobreclasificadas después del último gesto. Los prompts usan ahora `TextSecondary`; el test de catálogo cubre
  ese par a 4,5:1/7:1. La regresión física final registrada debajo cierra las seis limitaciones.
- El revisor iOS detectó un P2 de compatibilidad con Firebase Auth 12.18.0. El nuevo
  `passwordDoesNotMeetRequirements` se clasifica explícitamente como `credentialsRejected` y queda cubierto por la
  fixture parametrizada, sin ampliar Domain ni UI.
- Validación final Xcode MCP: `LoginContent.swift` y el adaptador Firebase sin diagnósticos, build correcto, cero warnings
  en build log, cero issues warning+ en Navigator y 788/788 tests, sin fallos, skips, expected failures ni casos sin
  ejecutar. Inspector final no emite contraste ni `Hit Region`; conserva cinco avisos genéricos de Dynamic Type que no se
  reproducen en preview ni runtime AX 5.
- Los ajustes temporales quedaron restaurados: Full Keyboard Access y su alto contraste desactivados, overrides de Xcode
  a cero, tamaños ampliados desactivados, simulador en portrait y Login vacío.
- Regresión física final en iPhone 14/iOS 26.6 (23G71): VoiceOver recorre
  `Iniciar sesión → Email → Contraseña → Acceder` hacia delante y atrás, y Email/Contraseña se activan y editan en su
  propio foco a la primera. El CTA vacío muestra el error local y devuelve el foco a Email. Voice Control activa Email,
  Contraseña y Acceder a la primera. Switch Control, con `Agrupar ítems` activo por defecto, expone y opera los tres
  elementos por separado. Resultado: las seis filas físicas limitadas pasan sobre la superficie táctil final.
- Autorrelleno no produjo sugerencias porque no existe un método de autenticación configurado ni ningún usuario de
  pruebas registrado. Los campos conservan `.textContentType(.username)` y `.textContentType(.password)`; el resultado
  runtime queda `Limitado`, no `Falla`. No se activó un proveedor live ni se creó una cuenta fuera del alcance.
- Las reauditorías finales de accesibilidad e iOS no detectan P0–P3 en las correcciones. Aceptan prompts, matriz,
  clasificación Firebase y trazabilidad con Linear. Gate automático: **PASS**; PLU-26/07.1 permanece `In Progress` por
  la fixture de autenticación necesaria para Autorrelleno y los flujos autenticados restantes de ADR 0022.

### 2026-08-21 — Remediación de Voice Control y Firebase 12.18.0

- El propietario aprobó el parche exacto de Login y la actualización de Firebase. `TextField` y `SecureField` añaden
  `accessibilityInputLabels` con las mismas claves localizadas que sus textos visibles, sin cambiar layout, copy, lógica
  ni foco programático.
- Xcode resolvió Firebase y GoogleAppMeasurement 12.18.0 en `Package.resolved`; se conservaron el URL canónico y los seis
  productos aprobados. La regla Git global HTTPS→SSH fue restaurada sin cambio persistente.
- Tras apartar de forma recuperable los artefactos Build obsoletos de 12.16.0, Xcode MCP compila el iPhone 17 Simulator
  con iOS 26.5: cero warnings en build log y cero issues warning+ en Navigator.
- Los cinco tests que leen archivos del repositorio fallaron únicamente al ejecutarse en el iPhone físico y pasaron 5/5
  en simulador. El plan completo recién descubierto pasa 786/786 con cero fallos, skips o casos sin ejecutar.
- Login Idle se inspeccionó post-parche en estándar y Dark + Increased Contrast + AX 5, sin recortes ni cambios visuales
  inesperados. El diagnóstico de `LoginContent.swift` devuelve cero issues.
- La repetición física post-parche en un iPhone 11 pasó: `Tocar Email` enfocó Email y `Tocar Contraseña` enfocó
  Contraseña. Login pasa 2.5.3 para este alcance; no se introdujeron credenciales. CoreDevice confirma iOS 26.6, build
  23G5057c.
- El smoke post-parche de VoiceOver en el mismo iPhone 11 pasó al recorrer Login hacia delante y hacia atrás: orden
  estable, una locución por elemento, nombres y funciones correctos y sin saltos ni duplicados.
- Full Keyboard Access no pudo ejecutarse porque no hay teclado externo disponible. El teclado software solo mostró
  `Done`, que avanzó al siguiente campo; no ofrece `Tab` ni `Mayúsculas + Tab`, por lo que esta observación no valida ni
  invalida 2.1.1/2.1.2. La evidencia queda limitada por hardware.
- Switch Control con exploración automática, botón de pantalla completa `Seleccionar ítem` y `Agrupar ítems` activo
  agrupó Email/Contraseña, pero no permitió entrar ni operar los campos. Acceder y el teclado software sí fueron grupos
  independientes. Con `Agrupar ítems` desactivado, el recorrido pasó uno a uno por Email, Contraseña, Acceder y cada
  elemento del teclado.
- El resultado se reprodujo también en el iPhone 14 con iOS 26.6 (23G71). La coincidencia con el iPhone 11/iOS 26.6
  (23G5057c) descarta razonablemente una peculiaridad exclusiva de un modelo o build y confirma el P1 cruzado.
- El revisor read-only clasificó el comportamiento como P1: falla 2.1.2/2.4.3 con la configuración agrupada soportada y
  la causa probable es la frontera generada por `Form`/primera `Section`, no `accessibilityInputLabels`. El P2 documental
  señalado se corrige en esta actualización. Gate: `correct before proceeding`.
- Una revisión read-only fresca compara el cambio sugerido por el propietario con contenedores `.contain` y da PASS
  para pedir aprobación de la opción mínima: separar Email y Contraseña en dos `Section` nativas, conservar campos,
  AutoFill, `FocusState`, input labels y CTA, y aceptar solo la separación visual adicional que se valide en previews.
  El PASS es de propuesta, no de accesibilidad ni cierre.
- El propietario aprobó y se implementó esa opción exacta. Xcode MCP devuelve cero diagnósticos en `LoginContent.swift`,
  build correcto, cero warnings/issues warning+ y previews Idle sin recortes ni pérdida de acciones en Large, XXX Large,
  AX 5 con Dark + Increased Contrast y Large landscape. En el destino físico pasan 778/786 tests; los ocho fallos son
  lecturas source-backed de rutas del Mac no disponibles en el sandbox del iPhone, por lo que se repetirán en simulador.
- La primera repetición física post-corrección pasa con `Agrupar ítems` activo en el iPhone 11/iOS 26.6 (23G5057c):
  Email y Contraseña ya son operables por separado. Este resultado se mantuvo acotado al dispositivo hasta la repetición
  posterior en el iPhone 14; las regresiones de VoiceOver/Voice Control continúan pendientes.
- La repetición post-corrección pasa también con `Agrupar ítems` activo en el iPhone 14/iOS 26.6 (23G71), con el mismo
  comportamiento correcto que en el iPhone 11. El P1 cruzado de Switch Control queda corregido; VoiceOver/Voice Control
  post-corrección y las demás puertas de ADR 0022 siguen pendientes.
- VoiceOver post-corrección pasa en el mismo iPhone 14 hacia delante y atrás con el orden
  `Iniciar sesión → Email → Contraseña → Acceder`, sin uniones ni saltos. La regresión queda cerrada para Login en este
  dispositivo; la regresión posterior de Voice Control se registra a continuación.
- Voice Control post-corrección pasa también en el iPhone 14/iOS 26.6 (23G71): `Tocar Email` y `Tocar Contraseña`
  enfocan su propio campo a la primera. La regresión de 2.5.3 queda cerrada para Login sin introducir credenciales.
- Tras seleccionar iPhone 17 Simulator/iOS 26.5, el plan completo post-corrección pasa 786/786 mediante Xcode MCP:
  cero fallos, skips, expected failures o casos sin ejecutar. Esto cierra la limitación de los ocho tests source-backed
  que no podían leer rutas del Mac desde el sandbox del iPhone físico.
- Accessibility Inspector post-separación detectó un P1 real en Dark: el CTA nativo combinaba `#E49ACE` con blanco y
  obtenía 2,14:1. Una revisión read-only aprobó la corrección mínima: conservar `.borderedProminent` y aplicar el par
  semántico `BrandPrimary`/`OnBrandPrimary`, cuyos ratios son 4,95:1, 9,81:1, 10,55:1 y 12,28:1 en las cuatro
  apariencias.
- Tras aplicar ese par, Xcode MCP vuelve a compilar sin diagnósticos ni warnings y el plan pasa 786/786. Se inspeccionan
  Light/Dark, contraste normal/incrementado y AX 5 sin recortes ni pérdida de la acción. Accessibility Inspector en
  iPhone 17 Simulator/iOS 26.5 Dark ya no presenta el aviso de contraste.
- Inspector conserva tres avisos genéricos `Dynamic Type font sizes are unsupported`: dos sobre los campos nativos y
  uno sobre `SwiftUI.AccessibilityNode`. El código no fija fuente ni tamaño, y las previews Large/XXX Large/AX 5 no
  muestran pérdida; se registraron como limitación no corroborada hasta completar la pasada runtime AX 5.
- Dynamic Type runtime AX 5 pasa en `Fran DEV`, iPhone 17 Simulator/iOS 26.5: Ajustes confirma tamaños ampliados activos
  al 100 % y Login escala título, labels, campos y CTA sin recortes, solapes ni pérdida de controles. Email y Contraseña
  reciben foco sin introducir credenciales. Los tres avisos genéricos del Inspector no se reproducen y 1.4.4 pasa para
  Login. El iPhone 17 y su clon se restauraron a tamaños ampliados desactivados y 50 %, con `Fran DEV` visible al terminar.
- La reauditoría read-only postcontraste no detecta P0–P3. Confirma los cuatro ratios, los controles nativos y la
  conservación de labels, AutoFill, foco, `disabled`, agrupación y delegación. El parche queda aceptable para continuar;
  el gate sigue `BLOCKED` solo para cerrar ADR 0022/07.1 por la evidencia runtime aplicable pendiente.
- La auditoría read-only postimplementación no detecta P0/P1/P3 en el parche y confirma que ambas `Section` conservan
  sincronizados `disabled`, AutoFill, foco y orden. Da PASS para avanzar a la validación física restante. Su único P2,
  la falta inicial de dispositivo exacto para el pase, queda resuelto por la confirmación posterior del propietario:
  iPhone 11/iOS 26.6 (23G5057c).

### 2026-08-20 — Hallazgo físico de Voice Control en Login

- En el iPhone14 con iOS 26.6 y `Fran DEV`, Voice Control mostró los nombres visibles, pero `Tocar Email` desplazó el
  foco a contraseña y `Tocar Contraseña` lo desplazó al título `Iniciar sesión`.
- Login queda en **Falla** para 2.5.3. La secuencia manual se detuvo antes de Switch Control y la subfase permanece
  abierta; VoiceOver conserva su resultado aprobado independiente.
- La inspección estática localiza como candidato la asociación entre los labels visibles separados y los campos nativos.
  El 21 de agosto el propietario aprobó el parche mínimo revisado; su implementación y evidencia automática se registran
  arriba. La repetición física post-parche pasó después en un iPhone 11.

### 2026-08-12 — Evidencia runtime manual de 07.1

- Accessibility Inspector auditó `Fran DEV` en iPad Air 11 pulgadas (M4), iOS 26.5, sin warnings en Login.
- Login se inspeccionó en ejecución con Increase Contrast Light/Dark y landscape, sin recortes, solapes ni pérdida del
  árbol accesible visible. El simulador se restauró después a Light, contraste normal y portrait.
- Xcode 26.6 detectó el iPhone14 físico con iOS 26.6, pero el despliegue falló porque el dispositivo estaba bloqueado
  (`kAMDMobileImageMounterDeviceLocked`, CoreDeviceError 12040). VoiceOver no está disponible en Simulator según Apple;
  las tecnologías de asistencia y los flujos físicos restantes siguen siendo la puerta de cierre.
- Tras desbloquearlo, Xcode completó la preparación y ejecutó `Fran DEV` en el iPhone14. El propietario validó Login con
  VoiceOver: orden `Iniciar sesión`, email, contraseña y `Acceder`, una locución por elemento y nombres/tipos correctos.

### 2026-08-11 — 07.1 tokens visuales y nombres semánticos

- Tras la propuesta revisada y la aprobación explícita del propietario, PLU-26 pasó a `In Progress` sobre el baseline
  publicado `10e817d`.
- RED: seis tests focales fallaron exclusivamente porque no existían los 18 símbolos `Color` y `ShapeStyle` esperados.
  GREEN: el catálogo focal pasa 6/6 y el plan completo pasa 786/786 mediante Xcode MCP.
- Se añadieron 18 colores semánticos con Light, Dark, High Contrast Light y High Contrast Dark y se alineó
  `AccentColor` con `BrandPrimaryInk`. Los valores sRGB coinciden exactamente con `docs/design/brand-palettes.md`.
- Los tests verifican inventario, cuatro apariencias, equivalencia del acento, umbrales WCAG de texto/no texto y la
  generación de símbolos de SwiftUI. El build Xcode MCP es correcto, con cero warnings en build log y cero issues
  warning+ en Navigator. El diagnóstico aislado del test devolvió `SourceEditor error 5`; compilación y ejecución son
  correctas.
- Xcode MCP renderizó e inspeccionó Light/Dark × Large/XXX Large/AX 5 en Login, sesión bloqueada, error raíz y carga de
  clientes, además de estados Light/Dark Large de carga, desbloqueo, acceso local, autenticado, vacío, contenido y error.
  No se observaron recortes ni solapes.
- La matriz completa por flujo vive en `docs/accessibility/evidence/07-1-color-tokens.md`. RenderPreview no expone
  Increase Contrast y no se han ejecutado Accessibility Inspector ni tecnologías de asistencia; esas filas permanecen
  `Pendiente` o `Limitado` conforme a ADR 0022.
- La auditoría iOS no encontró defectos P0-P3. La primera auditoría de accesibilidad detectó sobreclasificación de cuatro
  criterios y un rechazo incompleto de traits duplicados; ambos se corrigieron. La reauditoría sobre el estado estable
  confirmó el rechazo lanzable de duplicados/combinaciones desconocidas y la clasificación conservadora de las cuatro
  tablas, sin hallazgos de implementación adicionales. Tras la corrección, los seis tests focales vuelven a pasar 6/6.

### 2026-08-11 — Optimización previa a 07.1

- Se preservó el histórico anterior en `docs/progress/phases-00-06.md` y se redujo `docs/Progress.md` a un snapshot.
- El propietario aceptó ADR 0022 como objetivo interno de accesibilidad basado en WCAG 2.2 A/AA, WCAG2ICT y
  convenciones Apple; no constituye certificación WCAG ni declaración de conformidad legal.
- Se definieron skills bajo demanda, revisores read-only y controles deterministas para evitar cargar instrucciones
  especializadas en cada interacción.
- Un revisor independiente read-only pidió corregir autoridad, lenguaje de conformidad, trazabilidad, propiedad de reglas,
  dependencias de revisión y estado operativo antes de crear controles ejecutables; esos hallazgos se resolvieron.
- Se corrigieron esos hallazgos y dos P2 de la revisión final: propiedad de reglas de producto y generación de bytecode en
  el test del hook. Una pasada final ejecutada en sandbox técnico `read-only` devolvió `Sin hallazgos` y gate `PASS`.
- Validación final local: `validate_governance.py` correcto, hook 3/3 tests correcto, `git diff --check` limpio y cero
  archivos `__pycache__`. Build/tests Xcode son `N/A`: no cambió código ni configuración del producto.
- Xcode MCP confirmó `windowtab1` sobre `FranAlonso.xcodeproj`. Obsidian confirmó el vault `FranAlonso` abierto en la raíz
  del repositorio, por lo que no existe copia externa que sincronizar.
- Linear creó el milestone `Phase 07 — Design system, localization, and navigation`, [PLU-25](https://linear.app/plusprojects/issue/PLU-25/implement-phase-07-design-system-localization-and-navigation)
  y [PLU-26](https://linear.app/plusprojects/issue/PLU-26/071-implement-visual-tokens-and-semantic-names), ambos en
  Backlog; también publicó un estado de proyecto `onTrack` sin iniciar 07.1.
- La aceptación de ADR 0022 se sincronizó en el proyecto, milestone, PLU-25 y PLU-26; ambas issues permanecen en
  Backlog y la propuesta revisada de 07.1 sigue siendo la siguiente puerta.

## Pendiente

- Repetir VoiceOver, Voice Control y Switch Control en dispositivo físico sobre la superficie táctil final.
- Completar anuncios de estado, AutoFill aplicable y flujos/ventanas restantes de ADR 0022.

## Bloqueos

El P1 de Switch Control agrupado y los contrastes del CTA/prompts están corregidos. Full Keyboard Access, orientación y
objetivos operables de Login pasan en el estado final; los cinco avisos genéricos de Dynamic Type no se reproducen en
runtime AX 5. La subfase permanece abierta por la regresión física posterior al último parche y por la evidencia
aplicable de anuncios, AutoFill, flujos y ventanas restantes.
