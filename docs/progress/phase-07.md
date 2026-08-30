# Phase 07 Progress

Última actualización: 2026-08-30

## Estado

| Subfase | Linear | Estado | Autoridad |
|---|---|---|---|
| 07.1 — tokens visuales y nombres semánticos | PLU-26 | `Done` | Entregada en `074ce5e` |
| 07.1a — fixtures Develop no-live | PLU-27 | `Done` | ADR 0023/0024; entregada en `074ce5e` |
| 07.2 — controles reutilizables | PLU-28 | `Done` | [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4); rebase merge `e8eca5a` |
| 07.3 — vistas de carga, vacío y error | PLU-29 | `Done` | [PR #5](https://github.com/JFrancoG/FranAlonso/pull/5); rebase merge `266489a` |
| 07.4 — confirmación y alerta de stock | Sin issue | `N/A`/diferida | Consumidor real asignado a 12.3–12.4 |
| 07.5 — selección tipada del shell | PLU-30 | `Done` | [PR #6](https://github.com/JFrancoG/FranAlonso/pull/6); rebase merge `a220a3d` |
| 07.6 — shell autenticado adaptable | PLU-31 | `In Progress` | Commit/push autorizados; PR pendiente |
| Fase 07 | PLU-25 | `In Progress` | 07.6 hasta push; PR pendiente; 07.7 no iniciada |

La base aprobada al iniciar 07.2 fue `main == origin/main == 074ce5e`, con worktree limpio. La
[PR #4](https://github.com/JFrancoG/FranAlonso/pull/4) quedó integrada por rebase en `main`: `24802e6` contiene la
implementación y `e8eca5a` el handoff. El cierre documental `fda767b` es la baseline limpia de 07.3.

## Decisiones vigentes

- ADR 0022 fija el objetivo interno de accesibilidad nativa basado en WCAG 2.2 A/AA aplicable, WCAG2ICT, convenciones
  Apple y runtime iOS. No declara certificación ni conformidad legal.
- ADR 0023/0024/0025 mantienen las fixtures exclusivamente en `Debug-Develop`, cortadas antes de Firebase y sin datos
  persistentes o actividad live. ADR 0025 hace fail-closed toda intención fixture explícita inválida.
- 07.2 no requiere ADR nuevo: extrae composición SwiftUI nativa y aplica refinamientos visuales aprobados sin cambiar
  arquitectura, navegación, contratos de datos ni comportamiento live.
- Fila compartida y tarjeta quedan diferidas: no existe un segundo consumidor demostrado. `ClientRow`, tarjetas,
  formatters, validators y 07.4 permanecen fuera de alcance.
- Toda View conserva el límite declarativo: representa estado y envía intenciones; la lógica pertenece al ViewModel o
  a tipos de Presentation puros cuando no depende de la interfaz.
- La extracción visual de 07.3 no requiere ADR nuevo. Su ampliación posterior de evidencia runtime sí queda gobernada
  por ADR 0025 y toca únicamente el plan de lanzamiento, composición Develop y DataSource local.
- 07.4 no crea una API especulativa. `StockWarningPolicy` permanece en Domain y la confirmación se implementará en
  12.3–12.4 junto con `SaleDraftStore`, `SaleDraftViewModel` y el detalle real de Jornada. Logout conserva su conducta.
- 07.5 materializa solo la selección principal ya acordada. Las rutas locales se crean cuando una feature demuestre
  más de un destino; el shell visual adaptable y sus `NavigationStack` permanecen en 07.6.

## Gate 07.4 — N/A/diferida

- El inventario de producción no contiene `alert`, `confirmationDialog` ni Presentation de Ventas. Los únicos botones
  destructivos visibles ejecutan logout y convertirlos en confirmación sería un cambio de producto independiente.
- La fase 12 ya posee la autoridad exacta: 12.3 presenta la advertencia y 12.4 coordina continuar, cancelar y repetir
  sin registrar efectos por mostrarla.
- Apple recomienda usar estas superficies modales con moderación en
  [HIG Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts). SwiftUI proporciona dismiss y
  orden por roles mediante
  [`confirmationDialog`](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:))
  y [`alert`](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)); no se
  añade un wrapper sin consumidor ni reutilización demostrada.
- Alternativas rechazadas: componente Shared sin uso, preview-only de stock, estado anticipado de Presentation y
  reutilizar logout. Todas inventan contrato o comportamiento antes de existir el flujo propietario.
- TDD, build, previews y matriz ADR 0022: `N/A` razonado por ser reconciliación documental sin código/configuración.
  Baseline preservada: 860/860, builds Develop/Production sin warnings y cero errores actuales en Xcode.
- Revisión independiente read-only: PASS condicionado, sin P0–P3, huellas pre/post idénticas sobre 414 archivos.
  Condición satisfecha al registrar 07.4 como diferida, sin issue propio, rama, copy, tests ni ADR.
- Riesgo residual: foco, anuncio, textos y acciones solo se diseñarán y validarán con el consumidor real en fase 12.
  El gate separado de 07.5 se ejecutó después con autoridad independiente.

## 07.5 — entregada

- El gate de propuesta read-only pasó sin hallazgos P0–P3 antes del código y acotó el alcance a la fachada mínima
  descrita por la spec: no existen destinos secundarios que justifiquen rutas tipadas locales en esta subfase.
- `App/Navigation/AppSection.swift` declara únicamente `workday`, `history`, `clients`, `catalog` y `reports` con
  `Hashable`; no repite `Equatable` ni declara `Sendable` explícito cuando la inferencia es suficiente.
- `App/AppShellViewModel.swift` es `@Observable @MainActor`, posee exclusivamente `selectedSection` y comienza en
  `.workday`. No absorbe lógica de features, navegación interna, sesión, dependencias ni un Store ceremonial.
- El `TabView` con `.sidebarAdaptable`, el shell visible, sus cinco `NavigationStack` y el estado preservado por
  sección permanecen en 07.6, junto con previews, copy y adaptación iPhone/iPad/multitarea. Push/pop y `.sheet(item:)`
  son `N/A` hasta que aparezcan un destino secundario o una edición identificada reales.
- RED: el test focal falló al compilar porque `AppShellViewModel` y `.workday` aún no existían. GREEN: la expectativa
  de selección inicial pasó 1/1 mediante Swift Testing. Se descartó el caso «asignar y leer la misma propiedad» porque
  no aportaba un oráculo independiente y solo comprobaría almacenamiento del lenguaje.
- La suite completa de `FranAlonso-Production` registra 793 tests: 761 pasan, 0 fallan y 32 no se ejecutan por el gate
  conocido `FRANALONSO_AUTH_FIXTURE`. El build final pasa en 8,596 s; su log y el Issue Navigator contienen cero
  warnings.
- La consulta focal `XcodeRefreshCodeIssuesInFile` devolvió `SourceEditor.SourceEditorCallableDiagnosticError error 5`
  para los tres archivos nuevos. No se atribuyen cero diagnósticos focales: Xcode sí indexa los archivos, el test los
  compila y ejecuta, y build log más Issue Navigator aportan la evidencia de cero warnings.
- Preview, localización, interacción y ADR 0022 son `N/A` razonado porque no cambia ninguna View, texto visible ni
  superficie accesible. Tampoco cambia configuración, persistencia, Firebase o actividad live.
- El validador de gobernanza y `git diff --check` pasan; la revisión de paths sensibles no encuentra secretos ni
  archivos inesperados. `docs/Progress.md` permanece por debajo de su límite de 8192 bytes.
- La auditoría iOS post-implementación detectó únicamente un P2 de paridad en la descripción de PLU-25. Tras actualizar
  solo ese texto en Linear, la repetición afectada devolvió `Sin hallazgos` y gate `pass`; PLU-25 y PLU-30 conservaron
  `In Progress`. La auditoría de accesibilidad es `N/A` por ausencia de View, copy o superficie interactiva.
- La [PR #6](https://github.com/JFrancoG/FranAlonso/pull/6) integra PLU-30 por rebase en `a220a3d`. PLU-30 queda
  `Done`; PLU-25 permanece `In Progress`, y activación live o comienzo de 07.6 requieren autorizaciones separadas.

## 07.6 — cierre validado; commit/push autorizados

- La propuesta corregida recibió revisión independiente read-only y pasó `Sin hallazgos`. El ajuste previo al código
  conserva un único `NavigationStack` para todos los estados no autenticados y extrae únicamente el shell protegido.
  El owner autorizó ese alcance exacto; PLU-31 y la rama local
  `codex/plu-31-076-adaptive-app-shell` nacen desde `main == origin/main == 2dd4746`.
- `App/AppShellScreen.swift` posee un `AppShellViewModel` en `@State` y enlaza `selectedSection` mediante
  `@Bindable`. El `TabView(selection:)` usa `.sidebarAdaptable` y cinco `Tab` semánticos localizados con identidad
  estable: Jornada, Histórico, Clientes, Catálogo e Informes.
- Cada sección conserva su propio `NavigationStack`. Clientes compone el `ClientListScreen` real con las dependencias
  del entorno; las otras cuatro raíces reutilizan `UnavailableStateView` como contenido inerte y no crean Screens,
  ViewModels, Stores, rutas o datos de fases futuras. Logout sigue siendo un `Button` nativo caller-owned que envía la
  intención a Authentication desde las cinco toolbars.
- `AuthenticationRootScreen` toma una instantánea síncrona de su estado, mantiene todos los casos públicos dentro de
  un stack común y presenta el shell fuera solo para `.authenticated(session)`. Conserva `.id(session.id)`, por lo que
  la selección y los stacks no pueden cruzar identidades. `ContentView` queda eliminado como wrapper ya sustituido.
- Push/pop, sheets y restauración de rutas internas permanecen `N/A`: no existe todavía un segundo destino o una
  edición identificada real. La persistencia de selección y estado local entre tabs depende del contenedor nativo y
  requiere comprobación runtime; no se inventa un test de almacenamiento o una ruta ficticia.
- RED/GREEN nuevo con Swift Testing es `N/A` razonado para esta composición declarativa. El requisito independiente
  de Jornada inicial ya está protegido por `AppShellViewModelTests`; la regresión focal posterior cubre además raíz de
  autenticación, Clientes y fixtures deterministas: 22/22 en `FranAlonso-Develop`.
- La primera matriz de previews encontró una regresión visual reproducible: construir labels de `Tab` como contenido
  genérico expandía el shell fuera del viewport de iPhone en `XXX Large` y `AX 5`, ocultando safe areas y barra. El
  inicializador semántico `Tab(_:systemImage:value:content:)` del SDK activo permite al estilo adaptable aplicar su
  layout especializado; los rerenders actuales conservan navegación, toolbar y contenido completos.
- Previews finales Xcode MCP: iPhone 17e/iOS 26.5 en `Large`, `XXX Large` y `AX 5` portrait; iPad mini (A17 Pro)/
  iPadOS 26.5 en `AX 5` portrait y landscape; Light/Dark, contraste normal/incrementado y LTR/RTL dentro de esa matriz
  trazada. En iPad portrait, el overflow de la top bar usa el affordance nativo; en landscape el sidebar muestra las
  cinco secciones y el copy completo refluye sin solapes. Las cuatro previews de raíz —signed out, denied,
  observation failed y authenticated— renderizan sin error. iPad `Large`/`XXX Large` no se duplicó como preview;
  `XXX Large` y `AX 5` quedaron comprobados posteriormente en runtime.
- Validación automática final: build Develop correcto en 14,184 s y suite 815/815; build Production correcto en
  18,167 s y plan de 793 con 787 pasados, 0 fallos y 6 no ejecutados por su gate de fixtures. Los dos Swift afectados
  reportan cero diagnósticos; build log e Issue Navigator reportan cero warnings.
- La evidencia ADR 0022 de [`07-6-app-shell.md`](../accessibility/evidence/07-6-app-shell.md) acredita Inspector,
  tecnologías de asistencia, Touch, foco, logout, Dynamic Type, preferencias, orientaciones iPad y multitarea mínima.
  RTL sigue siendo inversión sintética, no localización RTL. iPhone 1.3.4 continúa `A/No pasa — excepción de producto
  aceptada` por ADR 0026; no quedan pruebas manuales adicionales para el shell actual.
- El primer recorrido VoiceOver reportado de la barra realiza una única parada por pestaña: Jornada se anuncia como
  seleccionada `1 de 5`, seguida de Histórico, Clientes, Catálogo e Informes hasta `5 de 5`. Todas exponen rol de
  pestaña y los símbolos no crean paradas adicionales. La comprobación se realizó en iPhone 14/iOS 26.6. La evidencia
  confirma además que enfocar Histórico no cambia de sección y que el doble toque lo selecciona. Al seleccionar
  Clientes con doble toque, VoiceOver anuncia «Seleccionado, Clientes, pestaña, 3 de 5»; después identifica «Clientes,
  encabezamiento», «Cerrar sesión, botón» y los dos textos del vacío sin parada adicional para el símbolo. Las otras
  activaciones continúan con Catálogo: el doble toque cambia la sección y anuncia su selección `4 de 5`; su título se
  anuncia «Catálogo, encabezamiento» y el logout «Cerrar sesión,
  botón». La acción no se ha activado desde esa sección. El recorrido posterior realiza una parada por elemento, usa
  locuciones correctas y no crea una parada para el símbolo; no se aportó transcripción literal. Informes cambia
  también con doble toque y anuncia su selección `5 de 5`; título, logout y contenido se reportan correctos, una vez
  por elemento y sin parada para el símbolo, aunque sin transcripción literal. El doble toque final sobre Jornada
  vuelve a la sección y anuncia su selección `1 de 5`; título, logout y contenido se reportan correctos, una vez por
  elemento y sin parada para el símbolo, aunque sin transcripción literal. Histórico confirma después el mismo
  resultado para título, logout y contenido. La preservación aplicable, el orden global y la restauración de foco se
  validaron posteriormente. El doble toque posterior sobre logout desde Histórico vuelve una vez a Login y VoiceOver
  enfoca «Iniciar sesión, encabezamiento». Tras autenticarse de nuevo, Jornada vuelve a ser inicial y el foco cae en
  «Cerrar sesión, botón». Activarlo vuelve también una vez a Login con foco en su encabezamiento. El owner confirma el
  mismo resultado en Clientes, Catálogo e Informes: cada logout se ejecuta una vez y vuelve a «Iniciar sesión,
  encabezamiento». Quedan cubiertos los cinco logout con VoiceOver.
- Con VoiceOver desactivado y Control por voz activo, las cinco órdenes «Tocar <nombre de pestaña>» cambian al destino
  correcto a la primera. «Tocar Cerrar sesión» vuelve una vez a Login desde una sección activa no identificada; las
  cinco secciones comparten el toolbar y no se atribuyen cinco ejecuciones por voz.
- Control por botón expone exactamente seis objetivos interactivos independientes: cinco pestañas y logout, sin
  objetivos adicionales para los iconos. Las cinco pestañas se activan a la primera; logout vuelve a Login y el escaneo
  continúa allí sin trampa.
- Acceso total con teclado recorre con foco visible los seis controles propios sin paradas de icono y añade únicamente
  el control split nativo para mostrar u ocultar la barra lateral. Espacio activa las cinco pestañas a la primera;
  logout vuelve una vez a Login y las flechas continúan moviendo allí el foco sin trampa.
- Con las tecnologías de asistencia desactivadas, un toque sobre cada pestaña activa solo el destino elegido a la
  primera, sin activar una pestaña contigua. Logout se ejecuta una vez y vuelve a Login.
- En tabs, mover el dedo verticalmente fuera de la barra antes de levantar cancela; terminar horizontalmente sobre otra
  pestaña activa el destino final. En logout, levantar fuera conserva la sesión y no navega a Login. 2.5.2 pasa.
- No hay puntero físico conectado. Esto no limita 2.5.8: `Tab` y `Button` conservan superficies nativas sin `frame` ni
  `contentShape` reductores, Touch no activa objetivos contiguos y cuatro modalidades adicionales operan cada control.
- Accessibility Inspector muestra siete avisos idénticos de Dynamic Type: cinco labels de tabs y los dos textos de
  Jornada. Son nodos nativos sin fuente fija ni límite; en ese punto quedaron pendientes de contraste runtime AX 5.
  El audit no muestra otras categorías en las capturas aportadas.
- Con Texto más grande al máximo, título y mensaje de Jornada escalan y permanecen completos y sin solape. Sus dos
  avisos quedan como falsos positivos; los cinco labels nativos se comprobaron a continuación.
- Al mismo tamaño máximo, los cinco nombres de tabs permanecen completos y seleccionables. Los siete avisos quedan
  clasificados como falsos positivos de Inspector; no hay defecto de Dynamic Type accionable en el shell.
- El owner confirma que Aumentar contraste, Reducir transparencia y Diferenciar sin color estaban activos a la vez. En
  ese perfil combinado, tanto en apariencia clara como oscura, selección, tabs, textos y logout permanecen completos y
  claramente distinguibles. Los dos audits no detectan avisos de contraste y el shell no introduce colores custom;
  1.4.3 y 1.4.11 pasan sin duplicar la medición automática con ratios manuales.
- Con Reducir movimiento activo, cambiar repetidamente entre las cinco pestañas termina siempre en la sección correcta,
  sin animaciones molestas, destellos ni pérdida de contenido.
- El recorrido global con VoiceOver sigue la geometría: logout primero por su posición superior, después las cinco tabs
  de izquierda a derecha y finalmente el contenido en orden visual, sin saltos ni trampa. 1.3.2 y 2.4.3 pasan.
- Desde logout, el rotor Encabezamientos salta directamente a «Jornada, encabezamiento»; estando ya allí informa que no
  hay otro encabezamiento, como corresponde al único del destino. 2.4.1 y 2.4.6 pasan.
- Tras enfocar el mensaje de Jornada, cambiar a Clientes y regresar, VoiceOver queda en «Jornada, pestaña,
  seleccionado»: un destino visible, operativo y predecible, sin foco perdido ni retenido. No hay aún estado navegable
  interno que preservar; 3.2.3 pasa para el shell actual.
- En iPad mini Simulator portrait, tabs, control de barra lateral, logout y contenido son completos y utilizables. Las
  últimas tabs requieren desplazamiento horizontal dentro de su contenedor nativo; en landscape quedan visibles sin
  ese desplazamiento. No hay pérdida ni solape; las demás orientaciones y la ventana mínima se ejecutaron después.
- Portrait invertido reproduce exactamente el mismo resultado: elementos utilizables, sin recortes ni solapes, y el
  mismo desplazamiento horizontal nativo para las últimas tabs. El landscape opuesto y la ventana mínima se ejecutaron
  después.
- En landscape con el control lateral a la izquierda, las cinco tabs quedan visibles simultáneamente y control lateral,
  logout y contenido permanecen completos y utilizables, sin recortes ni solapes.
- El landscape opuesto ofrece el mismo resultado correcto. Las cuatro orientaciones iPad quedan cubiertas.
- En la ventana de multitarea mínima, las cinco tabs siguen accesibles mediante desplazamiento horizontal nativo y el
  control lateral, logout y contenido permanecen completos, utilizables y sin recortes ni solapes. 1.4.10 pasa.
- En esa ventana mínima, Acceso total con teclado mantiene el foco siempre visible y cada control completo; la barra se
  desplaza al alcanzar las últimas tabs sin ocultar el indicador. 2.4.11 pasa.
- En iPad XXX Large, con los tamaños de accesibilidad mayores desactivados, contenido, logout y las cinco tabs siguen
  completos y utilizables mediante el desplazamiento horizontal nativo. Large/XXX Large/AX 5 quedan cubiertos y 1.4.4
  pasa; los siete avisos de Inspector permanecen clasificados como falsos positivos para esta configuración.
- Un segundo audit en iPad oscuro devuelve seis avisos de la misma categoría: cuatro tabs visibles y los dos textos de
  Jornada; la quinta tab queda fuera del área visible. No aparecen categorías nuevas; los paneles de propiedades se
  inspeccionaron después.
- El panel de propiedades de Jornada confirma etiqueta, estado seleccionado, rol tabulador, acción Activar y una sola
  etiqueta de entrada sobre `_UIFloatingTabBarItemCell`; la jerarquía contiene las cinco tabs y controles nativos del
  contenedor. El identificador interno `calendar` no se anuncia y los nodos internos repetidos no producen paradas
  duplicadas en el recorrido VoiceOver.
- El panel de propiedades de logout confirma etiqueta «Cerrar sesión», rol botón, acción Activar y una sola etiqueta de
  entrada, sin value, hint ni identifier innecesarios, sobre el control nativo `_UIButtonBarButton`. La jerarquía lo
  sitúa en la barra de navegación junto al encabezamiento Jornada.
- El título de navegación Jornada expone etiqueta «Jornada» y rasgo cabecera, sin value, hint ni identifier
  innecesarios, mediante un `UILabel` nativo. Esta inspección no sustituye la del título central del estado
  indisponible.
- El título central Jornada expone etiqueta correcta y rol texto estático, sin value, hint ni identifier innecesarios,
  mediante un `SwiftUI.AccessibilityNode`. Su jerarquía presenta título y mensaje como dos nodos de texto separados y
  omite el símbolo decorativo.
- El mensaje expone la etiqueta completa «Esta sección todavía no está disponible.» y rol texto estático, sin value,
  hint ni identifier innecesarios, mediante otro `SwiftUI.AccessibilityNode`. La inspección estructural queda completa
  sin hallazgos. La matriz queda en 29 Pasa, 0 Limitado, 0 Pendiente, 25 N/A y 1 excepción
  ADR 0026.
- La fixture no-live permaneció cortada antes de Firebase y permitió comprobar el estado Session bloqueado en iPad,
  pero no alcanzó el shell; no se presenta como evidencia runtime de 07.6. No hubo Firebase/Keychain live, seed
  durable, sincronización, dependencia, cambio de target, commit, push, PR, merge o cierre de issue.
- Las auditorías iOS y accesibilidad no encontraron defectos de implementación. Tras reconciliar cobertura Dynamic
  Type, contraste, targets y multitarea, las repeticiones afectadas pasan con huellas pre/post idénticas sobre 417
  rutas. El gate iOS y ADR 0022 pasan; PLU-31 y PLU-25 continúan `In Progress` porque PR, merge y cierre no están
  autorizados, y 07.7 no está iniciada.

## Snapshot entregado de 07.1 y 07.1a

- PLU-26 añadió 18 tokens semánticos de color con Light, Dark, High Contrast Light y High Contrast Dark, símbolos
  SwiftUI y tests de inventario, ratios y duplicados. Login, Session y Clientes completaron la evidencia ADR 0022.
- Accessibility Inspector permitió corregir el contraste de prompts y CTA. Los avisos genéricos de Dynamic Type no se
  reprodujeron en AX 5: los textos y controles permanecieron completos y operables.
- PLU-27 añadió los argumentos Develop signed-out y restored-session; ADR 0024 incorporó el error determinista de
  Clientes. La composición fixture usa SwiftData en memoria, telemetría nula y adaptadores locales, y corta antes de
  `FirebaseApp.configure()`, Firebase Auth, factories remotas y motores de sincronización.
- La matriz de compilación limita `FRANALONSO_AUTH_FIXTURE` a app/tests `Debug-Develop`. Configuraciones Release y
  Production no contienen sus seams. Los argumentos están desactivados por defecto y fallan cerrados si son inválidos
  o conflictivos.
- Los recorridos físicos de Login, sesión restaurada, Face ID, Clientes vacío/error y logout pasaron en iPhone 11/14;
  iPad, orientaciones, ventana estrecha y tecnologías de asistencia se registran en la evidencia de 07.1.
- La validación entregada en `074ce5e` pasó build Develop/Production, cero warnings/issues warning+ y 830/830 outcomes.
  No hubo configuración, lectura, escritura ni usuario Firebase live.

## 07.2 — implementación autorizada

### Componentes compartidos

- `PrimaryActionStyle` es un `ViewModifier` privado expuesto por la extensión interna
  `View.primaryActionStyle()`. Se aplica al `Button` nativo completo y comparte foreground `onBrandPrimary`,
  `.borderedProminent`, tint `brandPrimary`, forma cápsula y tamaño `.large`.
- El modificador no contiene acción, gesto, estado, foco ni lógica. Los callers conservan `disabled`, acciones,
  accesibilidad y layout. Login y Session muestran CTA equivalentes, sin iconos, con unos 49 pt de altura visual.
- `FormFieldSection<Content: View>` conserva exactamente una `Section` nativa con el `VStack(alignment: .leading)`,
  label headline oculto de accesibilidad y contenido caller-owned. Su inicializador de composición vive en una
  extensión del mismo archivo y el componente tiene preview determinista con `AppPreviewModifier`.

### Login

- Las estructuras repetidas de Email y Contraseña usan `FormFieldSection`; ambas `Section` siguen separadas. Esta
  frontera es obligatoria para que Switch Control exponga Email y Contraseña como grupos independientes.
- `TextField` y `SecureField` conservan bindings, prompts, keyboard/content types, AutoFill, autocorrection,
  `accessibilityInputLabels`, superficie mínima, `contentShape`, gesto condicionado, submit, `FocusState` y `onSubmit`.
- Los labels visuales incorporan SF Symbols. El único botón solo-icono es el ojo, con nombre Mostrar/Ocultar
  contraseña y superficie mínima propia. Los botones de texto no llevan iconos.
- El CTA «Acceder» queda fuera de los contenedores de campo pero dentro del `Form`, centrado, más separado y con el
  estilo primario compartido. Acción, estado disabled y foco siguen caller-owned.
- La entrada inicial publica una notificación de cambio de pantalla una sola vez por instancia. Cada error nuevo recibe
  foco y se anuncia completo; la reactivación no vuelve a forzar la señal.

### Session

- El acceso biométrico usa el mismo estilo nativo cápsula `.large`, una sola línea y el nombre accesible largo
  «Acceder con biometría del dispositivo».
- El fallback permanece como botón de texto destructivo sin icono. `ViewThatFits` elige entre «Salir y acceder con
  email» y su copy corto localizado cuando el ancho lo exige. Su label usa `errorInk` sin perder el rol destructivo.
- Los estados visibles usan los tokens de texto `successInk`, `warningInk` y `errorInk`; sustituyen los colores nativos
  cuyo contraste Light no alcanzaba el objetivo interno de 4,5:1.
- La coordinación de anuncios biométricos se modela en un tipo puro de Presentation con Swift Testing. El error se
  anuncia completo antes de dejar a iOS decidir el foco posterior; no se usa UIKit, delay ni destino forzado.

## Validación automática final de 07.2

- Xcode MCP sobre `FranAlonso-Develop`, iPhone 17e Simulator/iOS 26.5: build final correcto en 13,424 s e Issue Navigator con
  cero warnings.
- Diagnósticos: cero issues en los Swift de producción afectados y en los tests consultables. La consulta aislada de
  `BiometricAnnouncementGateTests.swift` devolvió `SourceEditor error 5`; el mismo archivo compiló y ejecutó verde.
- Previews de `FormFieldSection`, Login y Session: Light/Dark; contraste normal/incrementado; Large, XXX Large y AX 5;
  portrait/landscape; LTR/RTL; estados enabled/disabled.
- Focales en simulador: 6/6 colores; 39/39 localización + anuncio biométrico; 58/58 root/Login/Session ViewModels; 28/28
  lanzamiento/configuración. Total: 131/131.
- Suite completa: 843/843 outcomes.
- Una ejecución de colores en iPhone 11 físico obtuvo 3/6: los tres casos source-backed no pueden leer la ruta fuente
  del Mac desde el sandbox del dispositivo. Su repetición en simulador pasó 6/6; se clasifica como límite ambiental.
- Los tres argumentos de fixture de `FranAlonso-Develop` quedaron desactivados (`NO`) al terminar.
- El rebase merge usó la misma base validada y preservó el árbol fuente; este checkpoint post-merge modifica solo
  documentación. Repetir build/tests/diagnósticos Xcode MCP es `N/A` razonado.
- La auditoría AX inicial halló un P1 de contraste en `.red`, `.orange` y el fallback destructivo nativos. Tras migrar
  esos estados a los inks semánticos, el build volvió a pasar, Issue Navigator quedó en cero warnings, los tests de
  color pasaron 6/6 y las tres superficies afectadas renderizaron sin errores en las cuatro apariencias.

## Evidencia manual ADR 0022 de 07.2

- La matriz completa está en
  [`../accessibility/evidence/07-2-reusable-controls.md`](../accessibility/evidence/07-2-reusable-controls.md).
- VoiceOver conserva nombres, roles y orden. Login comienza por «Iniciar sesión, encabezamiento»; Session recorre
  encabezamiento, estado, explicación, acceso biométrico, error cuando existe y fallback.
- Voice Control activa Email, Contraseña, Mostrar/Ocultar contraseña y Acceder por su nombre visible; Session activa
  ambos botones a la primera. Cada acción se ejecuta una sola vez.
- Switch Control agrupado expone tres grupos en Login —Email; Contraseña + ojo; Acceder— y dos controles independientes
  en Session. Las dos `Section` de campos no se fusionan.
- Full Keyboard Access alcanza y opera todos los controles con los comandos configurados en iOS 26. Flechas navegan;
  dentro de un campo, Tab abandona la edición; Espacio activa botones. No hay trampa ni foco oculto.
- AutoFill rellenó la cuenta sintética sin envío automático. Dynamic Type hasta AX 5, contraste, orientaciones, RTL y
  estados enabled/disabled conservaron contenido y función.
- Email, contraseña oculta, contraseña visible, ojo y CTA de Login pasaron centro y extremos. En Session, el acceso
  biométrico y el fallback pasaron las mismas comprobaciones; todos respondieron una vez y al destino esperado.
- Los CTA unificados conservan forma cápsula, altura visual aproximada de 49 pt y contraste. El fallback destructivo no
  dibuja fondo ni borde, pero el propietario activó su superficie en centro y extremos: respondió siempre a la primera
  y navegó exactamente una vez a Login.
- La variante corta del fallback tiene evidencia estática, tests de localización y cobertura de preview limitada; no se
  clasifica como observada manualmente porque no apareció durante los recorridos runtime.

## Limitaciones aceptadas

- En la transición contraseña visible → `SecureField`, volver a escribir puede sustituir el valor existente. Es el
  comportamiento del control SwiftUI nativo al recrearse; se descarta un wrapper UIKit antiguo para manipular selección.
- Después del anuncio biométrico completo, VoiceOver puede terminar en el fallback, el encabezamiento u otro nodo
  nativo según dispositivo. La app no interrumpe el anuncio ni fuerza el destino; 2.4.3 queda `Limitado` en ese retorno.
- En Login, reactivar con el nodo dinámico de error enfocado puede devolver el foco al encabezamiento. Cada error nuevo
  se anuncia completo una sola vez y no hay movimiento programático posterior.
- AutoFill queda `Limitado` por no disponer de Associated Domains, aunque el selector del sistema ofrece y rellena la
  cuenta sintética.

## Puerta y pendiente

### 07.3 — implementación autorizada

- `LoadingStateView` y `UnavailableStateView<Actions>` viven en `Shared/Presentation/Components`; conservan
  `ProgressView` y `ContentUnavailableView` nativos con recursos y acciones caller-owned.
- `ClientListContent`, `AuthenticationRootScreen` y `FranAlonsoApp` migran siete cargas y cinco estados no disponibles
  equivalentes. No cambian estados, copy, roles, `disabled`, acciones, comportamiento de retry ni composición de
  dependencias. Como corrección de accesibilidad autorizada durante el gate runtime, solo «Reintentar» pasa a `Text` de
  una línea, sin icono y con `primaryActionStyle()` en su caller.
- Los componentes no declaran `@MainActor` explícito ni contienen estado, lógica, foco, anuncios o decisiones de
  vacío/error. `UnavailableStateView` aplica únicamente `TextSecondary` a su descripción para satisfacer el contraste
  mínimo; Login y Session permanecen fuera de alcance.
- RED/GREEN es `N/A` razonado para composición visual. Los siete focales existentes pasan 71/71 —incluidos 6/6 de
  color— y la suite completa pasa 843/843.
- Xcode MCP ha indexado los dos archivos nuevos: los seis Swift afectados reportan cero diagnósticos, el build final
  pasa en 11,842 s y build log/Issue Navigator no contienen warnings.
- Las previews cubren Light/Dark, contraste normal/incrementado, Large/XXX Large/AX 5, portrait/landscape y LTR/RTL.
  En el destino iPad Simulator, carga, Clientes vacío/error y raíz/bootstrap quedan completos y sin solapes a pantalla
  completa; Clientes refluye también completo al ancho mínimo de multitarea.
- [`07-3-state-views.md`](../accessibility/evidence/07-3-state-views.md) clasifica 55/55 criterios para Clientes y
  raíz/bootstrap. Las comprobaciones manuales aplicables a Clientes, las nuevas fixtures raíz y adaptación iPad están
  completas; loading queda limitado por no disponer de una ruta suspendida estable y ADR 0026 registra 1.3.4 como
  `A/No pasa — excepción de producto aceptada`.
- VoiceOver recorre completos los estados vacío y error de Clientes y no crea una parada separada para los SF Symbols.
  En el error determinista, el foco inicial nativo comienza en «Cerrar sesión» y continúa por encabezamiento, título y
  descripción; la app no fuerza el foco de la barra de navegación.
- Voice Control activa «Cerrar sesión» por su nombre a la primera desde el error determinista y vuelve a Login.
- Switch Control resalta solo «Cerrar sesión» en ese estado, no crea objetivos redundantes y lo activa a la primera
  sin trampa, volviendo a Login.
- Full Keyboard Access muestra un marco azul solo sobre «Cerrar sesión»; flechas y Tab no incorporan contenido estático
  al circuito. Espacio lo activa a la primera y vuelve a Login sin trampa.
- El objetivo táctil del logout no cambia y conserva la validación física 07.1; no se repite una medición ajena al diff.
- 4.1.3 detectó que VoiceOver anunciaba solo logout al aparecer el error. Un anuncio textual propio duplicaba después
  el título nativo, tanto con prioridad normal como alta. La solución final publica un único `LayoutChanged` sin texto ni
  destino al transitar a `.failed`: VoiceOver dice el título una vez y conserva foco en logout. Las trazas temporales
  están retiradas; build Xcode MCP correcto en 7,348 s.
- El owner amplía PLU-29 y acepta ADR 0026: las cuatro configuraciones iPhone pasan a portrait-only y las cuatro iPad
  conservan sus orientaciones. No existe necesidad esencial; 1.3.4 queda `A/No pasa` como excepción de producto
  consciente, sin presentarse como conformidad.
- El test hospedado del `Info.plist` generado pasa en iPhone y en iPad; el test source-backed exige el valor exacto en
  cada una de las cuatro configuraciones de aplicación y rechaza claves extra. En runtime, iPhone no rota a landscape
  por ninguno de los dos lados y Login permanece completo y operativo. iPad rota en portrait, portrait invertido y
  ambos landscape.
- En iPad Simulator con AX 5, Login permanece completo y operativo en las cuatro orientaciones y en la ventana mínima;
  en esta última requiere desplazamiento sin perder Email, Contraseña, ojo ni Acceder. `observationFailed` conserva
  título, explicación y Retry completos y operables en portrait, landscape y ventana mínima; Retry vuelve a Login a la
  primera. El error de Clientes conserva igualmente título, descripción y logout, que vuelve a Login a la primera.
- VoiceOver no está disponible en Simulator según Apple. No se atribuye por tanto evidencia VoiceOver nueva al iPad;
  se conserva la evidencia física ya observada en iPhone y se registra la adaptación iPad solo por runtime visual,
  Inspector y AX 5.
- iPhone 11/iOS 26.6.1 en portrait y AX 5 muestra completos el error de Clientes y logout, sin cortes ni solapes y con
  todos los elementos operables. iPad full-size portrait/landscape pasa en previews AX 5; en la ventana de multitarea
  más estrecha, error y logout siguen completos sin necesitar scroll. «Cerrar sesión» responde a la primera, vuelve una
  sola vez a Login y la pantalla de destino conserva todo el contenido completo.
- Accessibility Inspector emitió dos falsos avisos de contraste en Session: al seleccionarlos, los rectángulos quedan
  desplazados sobre el fondo/chrome exterior de la ventana iPad y los pares casi blancos no existen en los tokens de la
  app. El aviso Dynamic Type de Session vuelve a señalar el exterior; los dos de Clientes delimitan las dos líneas del
  título nativo, que está visiblemente escalado y refluye completo en AX 5. Los cinco se cierran como no reproducidos
  como defectos de la app; no se cambia código.
- La pasada post-cápsula sobre `observationFailed` detecta un P1 real en el texto descriptivo: 3,44:1 a 14 pt sobre
  blanco. Tres avisos adicionales de Dynamic Type resaltan nodos nativos que sí escalan y refluyen hasta AX 5 y se
  clasifican como no reproducidos. El owner autorizó la corrección mínima y el `Text(message)` compartido ya aplica
  `TextSecondary`; la repetición del Inspector elimina el aviso de contraste y cierra el P1.
- El delta de contraste pasa diagnóstico focal, build Xcode MCP en 10,847 s sin warnings y tests de color 6/6. Las
  cuatro apariencias y Large/XXX Large/AX 5 conservan jerarquía y reflow.
- El owner aprobó sustituir la acción compacta con icono de `localAccessDenied` por una cápsula textual grande. El
  `Button(role: .destructive)` y `requestSignOut()` permanecen intactos; la cadena visual local usa `OnError/ErrorFill`
  y no crea una abstracción Shared sin reutilización demostrada. Diagnóstico cero, build Develop en 11,666 s sin
  warnings, focales 13/13 y previews finales Light/Dark × contraste normal/incrementado en Large/XXX Large/AX 5. La
  cápsula final también aparece a la primera, completa y sin solapes en runtime AX 5 de iPhone Simulator.
- Con VoiceOver, `localAccessDenied` recorre título → explicación → «Cerrar sesión, botón», sin parada para el símbolo.
  El doble toque conduce a Login, que anuncia «Iniciar sesión, encabezamiento» y mantiene allí el foco.
- Voice Control activa «Tocar Cerrar sesión» a la primera desde `localAccessDenied` y conduce a Login.
- Switch Control resalta únicamente «Cerrar sesión» en `localAccessDenied`; seleccionarlo conduce a Login sin trampa.
- Full Keyboard Access enfoca únicamente «Cerrar sesión» en `localAccessDenied`; Espacio lo activa y conduce a Login.
- En iPhone físico, centro y cuatro extremos visibles de la cápsula `localAccessDenied` responden a la primera y llevan
  a Login, acreditando la superficie operable de 44×44 pt.
- El Inspector final registra dos avisos Dynamic Type en Session y tres en `localAccessDenied`. Los rectángulos señalan
  título+símbolo, descripción y, en la segunda ruta, su cápsula; todos escalan y refluyen completos en AX 5, sin fuente
  fija ni avisos de contraste. La auditoría AX independiente cierra el hallazgo como no reproducido, PASS sin P0–P3.
- La intención inválida formada solo por `clients-fixture-observation-error` falla cerrada en bootstrap: muestra «No se
  pudo preparar el acceso» y su explicación completa en runtime AX 5, sin solapes ni composición live.
- VoiceOver sitúa el foco inicial del fallo bootstrap en su título y recorre después la explicación completa. El símbolo
  no añade una parada y la superficie no tiene controles aplicables a Voice Control, Switch Control o teclado.
- El Inspector bootstrap añade solo dos avisos Dynamic Type sobre título+símbolo y explicación. Ambos están visiblemente
  escalados y completos en AX 5, sin solapes, fuente fija ni avisos de contraste; se cierran como no reproducidos.
- En iPad Simulator a pantalla completa y AX 5, bootstrap mantiene título y explicación completos, sin cortes ni
  solapes, tanto en portrait como en landscape. En la ventana de ancho mínimo ambos siguen completos y sin solapes;
  `observationFailed` mantiene además «Reintentar» completo, visible y operable. 2.4.11 queda cerrado; la restricción
  iPhone de 1.3.4 se gobierna por la excepción explícita de ADR 0026.
- Al ser una superficie estática, bootstrap no tiene controles aplicables a Voice Control, Switch Control o Full
  Keyboard Access. Los cinco argumentos de fixture de `FranAlonso-Develop` quedan restaurados a `NO` antes del gate
  automático final.
- VoiceOver reprodujo un large title visualmente vacío después de `checkingSession` y `authorizingLocalAccess`, aunque
  el nodo seguía anunciado. Ambos recorridos atravesaban el loading compartido nuevo; al no requerir scroll,
  `LoadingStateView` centra directamente su `ProgressView`. Tras la corrección, Sesión conservó visible y grande el
  título en 3/3 relanzamientos y Clientes también lo mostró correctamente; el hallazgo queda cerrado.
- Loading runtime no tiene fixture suspendida. Se registrará como preview/no observado; ampliar ADR 0024 sería una
  ampliación material no autorizada.
- ADR 0025 añade `local-access-denied` y `observation-failed`, ambos desactivados por defecto. La primera ruta conserva
  biometría y rechazo real del authorizer; la segunda consume un fallo one-shot por instancia y recupera signed-out al
  reintentar. Una intención fixture ausente sigue live; cualquier intención inválida termina localmente y nunca live.
- RED/GREEN: el primer focal falló por los modos ausentes; tras la implementación, la ampliación pasó cero diagnósticos
  en 7/7 Swift, focales auth/config 84/84, build Develop en 11,410 s y suite 859/859. Con las cinco fixtures ya en `NO`,
  el gate final conserva cero diagnósticos en 13/13 Swift y en el test de configuración, build Develop en 3,034 s sin
  warnings, suite completa 860/860 y build Production en 18,741 s. Ambos logs de build e Issue Navigator quedan a cero
  warnings. El gate de orientación pasa 1/1 en iPhone y 2/2 en iPad para runtime y source-backed.
- ADR 0026 documenta e implementa la decisión portrait-only de iPhone dentro de la ampliación aceptada de PLU-29. iPad
  permanece adaptativo; la evidencia iPad no compensa la clasificación `A/No pasa` de iPhone.
- Las auditorías finales iOS y accesibilidad pasan sin hallazgos P0–P3. Ambas operan read-only y comprueban huellas
  pre/post idénticas sobre 414 archivos. Confirman la solución 4.1.3, loading `A/L`, la ausencia honesta de VoiceOver
  iPad y la excepción 1.3.4 de ADR 0026.
- PLU-29 queda `Done` tras integrar por rebase la [PR #5](https://github.com/JFrancoG/FranAlonso/pull/5):
  implementación `56133a2` y handoff `266489a`. PLU-25 continúa `In Progress`; 07.4 quedó diferida y 07.5 se gestiona en
  PLU-30.
- El P1 de contraste post-cápsula queda cerrado tras repetir el Inspector. El gate runtime de ADR 0026 y las auditorías
  finales están completos y entregados en `main`.
