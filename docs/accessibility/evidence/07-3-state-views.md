# Evidencia de accesibilidad — 07.3 vistas de estado

Fecha: 2026-08-23/24

Alcance: PLU-29 / subfase 07.3. Esta evidencia aplica ADR 0022 a `LoadingStateView`,
`UnavailableStateView`, los estados de Clientes y los estados de raíz/bootstrap que los consumen. Es un objetivo
interno basado en WCAG 2.2 A/AA aplicable, WCAG2ICT, convenciones Apple y comportamiento real de iOS; no es una
certificación ni una declaración legal de conformidad.

## Autoridad y cambio evaluado

- Base inicial: `main == origin/main == fda767b`; PLU-25 y PLU-29 `In Progress`, sin blockers.
- `LoadingStateView` conserva un `ProgressView` nativo con copy caller-owned. `UnavailableStateView<Actions>` conserva
  un `ContentUnavailableView` nativo con título, SF Symbol, descripción y acciones caller-owned.
- `LoadingStateView` centra directamente su `ProgressView` mediante un frame flexible. `UnavailableStateView` usa
  scroll vertical nativo, centrado cuando el contenido cabe y con rebote solo cuando su tamaño lo requiere. Es una
  adaptación defensiva para AX 5 en una ventana iPad estrecha o multitarea; el overflow y su desplazamiento ya están
  observados y no introducen estado, foco, anuncio o lógica. La descripción aplica únicamente el token semántico
  `TextSecondary` para satisfacer el contraste mínimo en todas las apariencias.
- `ClientListContent`, `AuthenticationRootScreen` y `FranAlonsoApp` conservan sus estados, transiciones, copy, símbolos
  de estado, roles y acciones. Como corrección de accesibilidad autorizada durante el gate runtime, únicamente la
  acción «Reintentar» elimina su icono redundante, usa `Text` de una línea y aplica `primaryActionStyle()` en el caller.
  ADR 0025 amplía solo `ApplicationLaunchPlan`, la composición Develop y su DataSource local para hacer observables dos
  errores raíz. Login, Session, `ClientRow`, navegación, Domain y servicios live permanecen fuera del cambio.
- RED/GREEN es `N/A` para una extracción visual sin lógica. No se añadieron tests de View, snapshots, XCTest,
  XCUITest ni UI tests.
- La ampliación runtime de fixtures sí usa RED/GREEN con Swift Testing y no modifica ninguna View o ViewModel; la
  corrección visual posterior de «Reintentar» mantiene RED/GREEN `N/A` por no introducir lógica ni estado.

Fuentes primarias consultadas: [ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview),
[ProgressView](https://developer.apple.com/documentation/swiftui/progressview),
[ScrollView](https://developer.apple.com/documentation/swiftui/scrollview),
[defaultScrollAnchor](https://developer.apple.com/documentation/swiftui/view/defaultscrollanchor(_:for:)) y
[scrollBounceBehavior](https://developer.apple.com/documentation/swiftui/view/scrollbouncebehavior(_:axes:)). Para el
hallazgo runtime se contrastaron también [navigationTitle](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)-5di1u)
y la semántica accesible de [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar); Apple
documenta visualización y locución del título, no su ocultación mientras VoiceOver permanece activo. Apple también
indica en [Performing accessibility testing for your app](https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app)
que VoiceOver requiere un dispositivo físico y no está disponible en Simulator.

## Evidencia automática y visual

- Xcode MCP, esquema y plan `FranAlonso-Develop`, destino iPad Simulator activo: los seis Swift afectados tienen cero
  diagnósticos; build final correcto en 11,842 s; build log e Issue Navigator sin warnings.
- Siete focales: 71/71 outcomes de color, Clientes, raíz de autenticación, bootstrap, fixture Develop, repositorio de
  error y localización; `DesignSystemColorAssetTests` aporta 6/6. Suite completa: 843/843.
- Ampliación ADR 0025: cero diagnósticos en los siete Swift tocados; build Develop correcto en 11,410 s sin warnings;
  focales auth/config 84/84 y suite completa 859/859. Con los cinco argumentos desactivados, el gate final conserva cero
  diagnósticos en 13/13 Swift y en el test de configuración, build Develop en 3,034 s sin warnings, suite completa
  860/860 y build Production en 18,741 s; ambos logs e Issue Navigator quedan sin warnings.
- ADR 0026 pasa el test hospedado del `Info.plist` generado en iPhone y en iPad. El test source-backed exige la política
  exacta dentro de cada una de las cuatro configuraciones de aplicación y conserva los recuentos globales para rechazar
  claves extra.
- Previews de los dos componentes y de los estados reales de Clientes/raíz: Light/Dark, contraste
  normal/incrementado, Large/XXX Large/AX 5, portrait/landscape y LTR/RTL.
- En tamaños ordinarios, loading y estados no disponibles permanecen centrados. Con un destino iPad Simulator
  seleccionado, las previews AX 5 a pantalla completa de loading, Clientes vacío/error, raíz/bootstrap y el componente
  con y sin acción pasan en portrait/landscape, Light/Dark, contraste normal/incrementado y una variante RTL: todo el
  copy y las acciones quedan completos, centrados y sin cortes ni solapes.
- A pantalla completa en iPad el contenido cabe y el scroll no necesita activarse. `UnavailableStateView` conserva el
  scroll vertical nativo para una ventana iPad más estrecha. En la comprobación manual de Clientes a ancho mínimo todo
  siguió completo sin overflow; «Reintentar» también permanece completo, visible y operable en ese ancho mínimo.
- El owner amplía PLU-29 y acepta conscientemente ADR 0026: sin necesidad esencial, iPhone queda portrait-only e iPad
  conserva portrait, landscape y ventana. La restricción contradice el objetivo 1.3.4 de ADR 0022 y se registra
  `A/No pasa — excepción de producto aceptada`, nunca `A/P`, `N/A` o necesidad esencial.
- No existe fixture suspendida que mantenga loading visible; continúa `Limitado`. ADR 0025 sí aporta rutas runtime para
  `localAccessDenied`, `observationFailed` y la superficie bootstrap compartida. El recorrido funcional de
  `observationFailed`, `localAccessDenied` y la superficie bootstrap ya están observados. VoiceOver recorre esta
  última en orden; al no contener controles, Voice Control, Switch Control y teclado no tienen operación aplicable.
- Los cinco argumentos de `FranAlonso-Develop.xcscheme` estaban desactivados (`NO`) al registrar la baseline automática.
  La comprobación manual del error activa temporalmente la pareja exacta
  `--franalonso-auth-fixture-restored-session` + `--franalonso-clients-fixture-observation-error`. Tras completar el
  gate manual, los cinco argumentos quedan restaurados a `NO` antes de la validación automática final.

## Evidencia manual y límites

- Con `--franalonso-auth-fixture-observation-failed` como única intención fixture, aparece «No se pudo comprobar la
  sesión» con la acción «Reintentar». Activarla una vez reemplaza la observación terminada, conduce una sola vez a
  Login y deja esa pantalla operativa. Esta primera comprobación se realizó sin tecnología de asistencia.
- Después de aplicar la cápsula final, VoiceOver mantiene el foco inicial en «No se pudo comprobar la sesión». El
  recorrido continúa con la locución completa «El acceso protegido se ha cerrado hasta volver a comprobar la sesión»
  y termina en «Reintentar, botón». Título, descripción y acción son tres paradas separadas, en orden lógico, y el SF
  Symbol de estado no crea una parada adicional. Activar «Reintentar» con el doble toque conduce a Login; VoiceOver
  anuncia «Iniciar sesión, encabezamiento» y deja allí el foco.
- Después de aplicar la cápsula final, con VoiceOver desactivado y Voice Control activo, «Tocar Reintentar» activa la
  acción a la primera, conduce una sola vez a Login y deja esa pantalla operativa.
- Después de aplicar la cápsula final, un ciclo completo de Switch Control resalta únicamente «Reintentar». El título,
  la descripción y el SF Symbol permanecen como contenido estático y no crean objetivos redundantes. Seleccionar ese
  único objetivo lo activa a la primera y conduce a Login, sin trampa.
- Después de aplicar la cápsula final, en iPhone Simulator con Full Keyboard Access, solo «Reintentar» recibe el marco
  azul. Las flechas conservan el foco en ese único control y no introducen el contenido estático en el circuito.
  Espacio lo activa a la primera y conduce a Login, sin trampa ni activación causada únicamente por recibir el foco.
- En iPhone físico, la acción automática compacta se sustituyó por la cápsula sin icono elegida por el owner, usando el
  estilo primario ya existente sobre el `Button` nativo y sin cambiar su acción ni la lógica. Con tecnologías de
  asistencia desactivadas, el centro y los cuatro extremos visibles de la nueva cápsula respondieron a la primera y
  condujeron a Login en todos los intentos. El mismo recorrido sobre «Cerrar sesión» pasó después en sus cinco puntos;
  ambas acciones raíz acreditan su perímetro funcional.
- En AX 5, tanto iPad como iPhone Simulator conservan título, descripción y «Reintentar» completos y sin solapes. El
  overflow usa el `ScrollView` vertical previsto, la acción permanece alcanzable y conduce a Login correctamente.
- Tras aplicar ADR 0026, iPhone Simulator permanece en portrait al intentar ambos giros y Login conserva todo su
  contenido operativo. iPad Simulator rota correctamente en portrait, portrait invertido y ambos landscape. Login
  permanece completo y operativo en AX 5 en las cuatro orientaciones y en la ventana mínima; esta requiere scroll sin
  perder Email, Contraseña, ojo o Acceder.
- En el mismo iPad con AX 5, `observationFailed` mantiene título, explicación y Retry completos y operables en portrait,
  landscape y ventana mínima; Retry vuelve a Login a la primera. El error de Clientes mantiene igualmente título,
  descripción y logout completos y operables en las tres variantes; logout vuelve a Login a la primera.
- VoiceOver no está disponible en Simulator según la documentación de Apple. No se clasifica como ejecutada una nueva
  pasada VoiceOver de iPad; la evidencia VoiceOver física de iPhone se conserva sin extrapolarla al dispositivo no
  observado.
- Con la fixture `localAccessDenied`, completar la biometría conduce a la primera al estado «Acceso local bloqueado».
  Antes del ajuste visual de la acción, en iPhone Simulator con AX 5, el título, la explicación «Los datos de este
  dispositivo están vinculados a otra cuenta» y «Cerrar sesión» permanecen completos, visibles y sin solapes.
- Con la cápsula final y VoiceOver activo, el foco inicial aparece en «Acceso local bloqueado». El recorrido observado
  continúa con «Los datos de este dispositivo están vinculados a otra cuenta» y termina en «Cerrar sesión, botón». Las
  tres locuciones son completas, mantienen el orden visual y el SF Symbol no crea una parada adicional. Activar
  «Cerrar sesión» mediante doble toque conduce a Login, donde VoiceOver anuncia «Iniciar sesión, encabezamiento» y
  mantiene allí el foco.
- Con VoiceOver desactivado y Voice Control activo, «Tocar Cerrar sesión» activa la cápsula final a la primera y
  conduce a Login.
- En Switch Control, un ciclo completo resalta únicamente la cápsula «Cerrar sesión»; título, explicación y símbolo no
  crean objetivos redundantes. Seleccionarla conduce a Login sin trampa.
- Con Full Keyboard Access, únicamente «Cerrar sesión» recibe el marco azul. Las flechas no incorporan contenido
  estático al circuito y Espacio activa el botón, que conduce a Login sin trampa ni acción causada solo por el foco.
- En iPhone físico, con tecnologías de asistencia desactivadas y tamaño de texto estándar, cinco recorridos probaron el
  centro y los cuatro extremos visibles de la cápsula «Cerrar sesión». Todos respondieron a la primera y condujeron a
  Login, acreditando una superficie realmente operable de al menos 44×44 pt sin objetivos adyacentes.
- Con `--franalonso-clients-fixture-observation-error` como única intención, la configuración inválida falla cerrada y
  muestra la superficie bootstrap «No se pudo preparar el acceso». En iPhone Simulator con AX 5, el título y la
  explicación «Cierra y vuelve a abrir la aplicación. Si el problema continúa, contacta con soporte» permanecen
  completos y sin solapes; no se compone ni activa una ruta live.
- Con VoiceOver activo, el foco inicial del fallo bootstrap aparece en «No se pudo preparar el acceso». El segundo y
  último elemento es la explicación completa «Cierra y vuelve a abrir la aplicación. Si el problema continúa, contacta
  con soporte». El símbolo no crea una parada separada y no existen controles que requieran Voice Control, Switch
  Control o Full Keyboard Access en esta superficie estática.
- iPhone 11 con iOS 26.6.1, fixture de sesión restaurada y VoiceOver: el estado vacío expone «Clientes,
  encabezamiento» → «Cerrar sesión, botón» → «No hay clientes» → «Los clientes aparecerán aquí cuando estén
  disponibles». El SF Symbol no crea una parada separada.
- En tres recorridos, el título grande «Clientes» no se dibujó una vez aunque VoiceOver conservó y resaltó el nodo por
  encima del contenido. En otro recorrido ocurrió lo mismo con «Sesión». Las previews integradas de ambas pantallas
  muestran el título correctamente en Light y Dark con contraste incrementado, por lo que el hallazgo se mantiene
  abierto como anomalía runtime de navegación/VoiceOver y no se presenta como contraste validado.
- Sin abandonar la pantalla afectada, desactivar VoiceOver hizo reaparecer inmediatamente el título. Esto descarta copy
  ausente y contraste estático, pero no permite aceptar la pérdida visual mientras la tecnología está activa.
- Dos capturas runtime confirman que el rectángulo accesible del large title permanece en la esquina superior izquierda
  sin glyph visible, tanto en Session como en Clientes. Los contenidos y controles restantes conservan su presentación.
- Mover el foco de VoiceOver al siguiente elemento no repinta el título; solo desactivar VoiceOver lo recupera. Por
  tanto, el cursor no estaba ocultando el glyph.
- Ambos recorridos atraviesan el loading compartido nuevo: `checkingSession → Session` y
  `authorizingLocalAccess → Clientes`. Como la carga es breve, no tiene acciones y cabe completa en iPad full-size con
  AX 5 portrait/landscape,
  `LoadingStateView` elimina su `ScrollView` y centra el `ProgressView` con un frame flexible. El scroll de
  `UnavailableStateView` se conserva para acciones que exceden el viewport.
- Tras la corrección, con VoiceOver activo, «Sesión» apareció visible y como título grande en 3/3 relanzamientos;
  «Clientes» también apareció correctamente visible y grande. El hallazgo queda cerrado sin cambiar navegación,
  estilo del título ni orden accesible.
- Con la pareja exacta `restored-session + clients observation error`, VoiceOver recorrió «Fran DEV, Cerrar sesión,
  botón» → «Clientes, encabezamiento» → «No se pudieron cargar los clientes» → «Inténtalo de nuevo más
  tarde». El texto se leyó completo y el SF Symbol de advertencia no creó una parada separada. El foco inicial nativo
  quedó en la acción de toolbar; la app no fuerza foco ni reordena la barra de navegación.
- Con VoiceOver desactivado y Voice Control activo, «Tocar Cerrar sesión» activó el único control del estado de error
  a la primera y devolvió a Login.
- En el error de Clientes, un ciclo completo de Switch Control resaltó únicamente «Cerrar sesión». El encabezamiento,
  el título, la descripción y el SF Symbol permanecieron como contenido estático y no crearon objetivos redundantes.
  Seleccionar ese único objetivo lo activó a la primera y devolvió a Login, sin trampa.
- En iPhone Simulator con Full Keyboard Access, flechas y Tab mantuvieron un marco azul visible únicamente sobre
  «Cerrar sesión». Ningún texto ni símbolo estático entró en el circuito de controles. Espacio lo activó a la
  primera y devolvió a Login, sin trampa ni cambio de contexto al recibir solo el foco.
- La superficie de «Cerrar sesión» no cambia en 07.3. Su validación física previa de tamaño, activación separada y
  retorno a Login se conserva en [`07-1-color-tokens.md`](07-1-color-tokens.md); Voice Control, Switch Control y Full
  Keyboard Access se repitieron sobre el nuevo estado de error.
- En un relanzamiento físico del error con VoiceOver activo, sin tocar ni deslizar, iOS anunció únicamente «Fran DEV,
  Cerrar sesión, botón» y mantuvo el foco en ese botón. El error sigue disponible en el recorrido manual, pero su
  aparición no se anunciaba automáticamente. El owner autorizó la ampliación estrecha tras la revisión read-only.
- Un `Announcement` textual normal y otro de prioridad alta produjeron el título dos veces. Trazas temporales sin PII
  demostraron una sola publicación propia; anunciar temporalmente la descripción aisló el orden «Inténtalo…» → título
  nativo → logout. Las trazas y el copy diagnóstico se retiraron.
- La corrección final observa una vez la transición a `.failed` y publica
  `AccessibilityNotification.LayoutChanged()` sin texto ni elemento de destino. VoiceOver anunció exactamente una vez
  «No se pudieron cargar los clientes» y después «Cerrar sesión, botón», donde conservó el foco. No cambian ViewModel,
  componente compartido, copy o navegación. Build Xcode MCP correcto en 7,348 s; 4.1.3 pasa.
- En el mismo iPhone 11/iOS 26.6.1, portrait y AX 5, el error conserva completos título, descripción y logout, sin
  cortes ni solapes y con todos los elementos operables. En el destino iPad Simulator, las previews a pantalla completa
  de carga, vacío, error y raíz/bootstrap pasan también en AX 5 portrait/landscape.
- En iPad Simulator, AX 5 y ventana de multitarea al ancho mínimo, el error de Clientes conserva completos título,
  descripción y logout, sin cortes ni solapes. El contenido cabe y no activa scroll. «Cerrar sesión» responde a la
  primera, ejecuta una sola navegación a Login y allí todo el contenido sigue completo.
- Accessibility Inspector reportó dos avisos de contraste y uno de Dynamic Type en Session, además de dos avisos de
  Dynamic Type en el error de Clientes. Al seleccionar ambos avisos de contraste, sus capturas resaltan rectángulos
  desplazados sobre el fondo exterior y el chrome de la ventana iPad, no texto ni controles de FranAlonso. Los pares
  muestreados (`#F0F0F5/#F1F1F6` y `#FFFFFF/#F2F2F7`) no existen en los assets o estilos propios; los tokens reales
  siguen cubiertos 6/6 y la preview Session AX 5/Light/contraste incrementado permanece legible. Ambos se clasifican
  como atribución espacial errónea del Inspector en modo ventana, sin cambio de código. El aviso Dynamic Type de
  Session vuelve a resaltar el exterior/chrome. Los dos de Clientes resaltan el título nativo, dividido en sus dos
  líneas AX 5: el texto está visiblemente escalado, refluye completo y no usa fuente fija ni límite de líneas. Los cinco
  avisos quedan cerrados como no reproducidos como defectos de la app; no se suprimen ni motivan cambios de código.
- La repetición del Inspector sobre la raíz `observationFailed` con la cápsula final reporta un aviso real
  `Contrast nearly passed`: el `Text(message)` descriptivo usa 14 pt regular y mide 3,44:1 entre `#8A8A8E` y
  `#FFFFFF`, por debajo del umbral 4,5:1. El owner autorizó aplicar `TextSecondary` al `Text(message)` compartido y la
  repetición del Inspector ya no reporta contraste: el P1 queda cerrado. Permanecen tres avisos de Dynamic Type que
  resaltan la acción «Reintentar», el `Label` de título y símbolo y la descripción; los tres nodos son nativos, no usan
  fuente fija y su escalado y reflow están observados hasta AX 5, por lo que no se reproducen como defectos de Dynamic
  Type.
- Tras aplicar `TextSecondary`, Xcode reporta cero diagnósticos en `UnavailableStateView`, build correcto en 10,847 s
  y build log/Issue Navigator sin warnings. `DesignSystemColorAssetTests` pasa 6/6. Las cuatro apariencias permanecen
  legibles; Large/XXX Large muestran todo el contenido y AX 5 refluye sin solapes dentro del `ScrollView` vertical. La
  preview raíz Large conserva completa la cápsula final.
- Tras sustituir la acción compacta de `localAccessDenied` por el `Button(role: .destructive)` textual, grande y en
  cápsula, `AuthenticationRootScreen` reporta cero diagnósticos, el build Develop pasa en 11,666 s sin warnings y los
  focales de colores/fixture/root pasan 13/13. Las previews finales Light/Dark con contraste normal/incrementado cubren
  Large, XXX Large y AX 5: «Cerrar sesión» permanece en una línea, completo, operable y sin solapes. La comprobación
  runtime en iPhone Simulator confirma que la cápsula final aparece a la primera y permanece completa y sin solapes en
  AX 5. VoiceOver, Voice Control, Switch Control y Full Keyboard Access la activan correctamente; centro y cuatro
  extremos visibles responden en dispositivo físico.
- La auditoría final del Inspector para Session y `localAccessDenied` reporta solo cinco avisos `Dynamic Type font sizes
  are unsupported`: dos resaltan título+símbolo y descripción de Session; tres resaltan título+símbolo, descripción y
  cápsula de `localAccessDenied`. Las capturas AX 5 muestran los cinco nodos nativos escalados, completos y con reflow;
  ninguno usa fuente fija y `lineLimit(1)` no impide el escalado del botón. No aparece ningún aviso de contraste. La
  revisión independiente concluye PASS sin P0–P3 y los clasifica como no reproducidos, sin cambio de código.
- El Inspector del fallo bootstrap reproduce únicamente dos avisos `Dynamic Type font sizes are unsupported`, sobre
  título+símbolo y explicación. Las capturas AX 5 muestran ambos nodos nativos escalados, completos y con reflow; no
  usan fuente fija, no se solapan y no aparece ningún aviso de contraste. Se clasifican igualmente como no
  reproducidos, sin cambio de código.
- En iPad Simulator a pantalla completa y AX 5, la superficie bootstrap conserva título y explicación completos, sin
  cortes ni solapes, tanto en portrait como en landscape.
- En la ventana iPad de ancho mínimo y AX 5, título y explicación bootstrap siguen completos y sin solapes; el scroll
  vertical nativo preserva el reflow.
- Con `observationFailed` como única fixture, «Reintentar» permanece completo, visible y operable en esa misma ventana
  iPad de ancho mínimo y AX 5.
- El gate final con las cinco fixtures en `NO` conserva cero diagnósticos en 13/13 Swift y en el test de configuración,
  build Develop en 3,034 s sin warnings y suite completa 860/860. Las previews finales conservan AX 5, contraste
  incrementado, landscape y RTL completos y centrados. Production compila en 18,741 s sin warnings; ambos logs de
  build e Issue Navigator quedan a cero warnings.

| Superficie | Apariencias | Dynamic Type | Adaptación | Estado actual |
|---|---|---|---|---|
| Loading compartido | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | iPhone portrait; iPad portrait/landscape; LTR/RTL | Pasa en previews; runtime estable limitado |
| Clientes vacío/error | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | iPhone portrait físico; iPad portrait/landscape y ventana estrecha | AT, AX 5 físico y acción iPad pasan; ADR 0026 limita iPhone a portrait |
| Raíz/bootstrap no disponible | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | iPhone portrait; iPad portrait/landscape/ventana; LTR/RTL | Runtime, AT y adaptación iPad pasan; ADR 0026 limita iPhone a portrait |

## Registro ADR 0022

Leyenda: `A/P` = Aplicable/Pasa; `A/Pend.` = Aplicable/Pendiente de comprobación manual; `A/L` =
Aplicable/Limitado por una ruta no observable de forma determinista; `N/A` conserva una justificación tecnológica o
funcional. Ningún `A/Pend.` o `A/L` se presenta como validado.

| ID | Clientes | Raíz/bootstrap | Método, hallazgo y disposición |
|---|---|---|---|
| 1.1.1 | A/P | A/P | Los SF Symbols de Clientes y de los errores raíz no crean paradas redundantes en VoiceOver. |
| 1.2.1 | N/A | N/A | No hay audio o vídeo pregrabado. |
| 1.2.2 | N/A | N/A | No hay audio sincronizado pregrabado. |
| 1.2.3 | N/A | N/A | No hay vídeo pregrabado. |
| 1.2.4 | N/A | N/A | No hay contenido sincronizado en directo. |
| 1.2.5 | N/A | N/A | No hay vídeo con audiodescripción. |
| 1.3.1 | A/P | A/P | Clientes y raíz exponen programáticamente sus títulos, descripciones y acciones aplicables. |
| 1.3.2 | A/P | A/P | VoiceOver conserva el orden visual de Clientes y de los tres errores raíz. |
| 1.3.3 | A/P | A/P | Títulos, descripciones y acciones son textuales; no dependen de posición, color, forma o sonido. |
| 1.3.4 | A/No pasa | A/No pasa | ADR 0026 limita iPhone a portrait sin necesidad esencial y acepta la excepción de producto; iPad permanece adaptativo. |
| 1.3.5 | N/A | N/A | Estas superficies no recopilan datos personales. |
| 1.4.1 | A/P | A/P | Vacío, error y carga se distinguen mediante copy, estructura y símbolo, no solo por color. |
| 1.4.2 | N/A | N/A | No hay audio automático. |
| 1.4.3 | A/P | A/P | `TextSecondary` corrige el 3,44:1 de la descripción; la repetición del Inspector ya no reporta contraste. |
| 1.4.4 | A/P | A/P | Los errores `observationFailed`, `localAccessDenied` y bootstrap permanecen completos y operables en AX 5. |
| 1.4.5 | A/P | A/P | Todo el copy significativo es `Text`; los SF Symbols no codifican texto. |
| 1.4.10 | A/P | A/P | Clientes y los tres errores raíz refluyen completos en AX 5, sin cortes ni solapes. |
| 1.4.11 | A/P | A/P | No se añaden colores o bordes custom; componentes y foco usan semántica nativa. |
| 1.4.12 | N/A | N/A | SwiftUI nativo no ofrece override de espaciado mediante markup, conforme a WCAG2Mobile. |
| 1.4.13 | N/A | N/A | No aparece contenido adicional por hover o foco. |
| 2.1.1 | A/P | A/P | Full Keyboard Access activa Clientes, Retry y `localAccessDenied`; bootstrap no contiene controles. |
| 2.1.2 | A/P | A/P | Teclado/Switch salen sin trampa desde Clientes y las rutas raíz interactivas; bootstrap no contiene controles. |
| 2.1.4 | N/A | N/A | No hay atajos de un solo carácter. |
| 2.2.1 | N/A | N/A | No hay límite temporal impuesto por la pantalla. |
| 2.2.2 | N/A | N/A | No hay actualización automática persistente que requiera pausa o control. |
| 2.3.1 | A/P | A/P | Previews y código no contienen destellos ni animación intermitente creada por la app. |
| 2.4.1 | A/P | A/P | Clientes y raíz conservan recorridos cortos; bootstrap contiene solo dos nodos de contenido. |
| 2.4.2 | A/P | A/P | VoiceOver anuncia Clientes y los títulos descriptivos de los tres errores raíz. |
| 2.4.3 | A/P | A/P | VoiceOver conserva el orden y foco inicial significativo de Clientes y raíz. |
| 2.4.4 | A/P | A/P | Voice Control activa por nombre logout, Retry y salida `localAccessDenied`; bootstrap no contiene controles. |
| 2.4.5 | N/A | N/A | No existe una colección extensa de páginas que requiera varias vías. |
| 2.4.6 | A/P | A/P | VoiceOver confirma nombres descriptivos en Clientes y los tres errores raíz. |
| 2.4.7 | A/P | A/P | Full Keyboard Access muestra foco visible en Clientes, Retry y `localAccessDenied`; bootstrap no contiene controles. |
| 2.4.11 | A/P | A/P | Los controles de Clientes y raíz permanecen completos, visibles y operables también en ventana iPad estrecha. |
| 2.5.1 | N/A | N/A | No hay gestos multipunto o de trayectoria. |
| 2.5.2 | A/P | A/P | Switch Control activa las acciones de Clientes, Retry y `localAccessDenied`; bootstrap no contiene controles. |
| 2.5.3 | A/P | A/P | Voice Control activa por sus nombres visibles las acciones de Clientes y ambos errores raíz interactivos. |
| 2.5.4 | N/A | N/A | No hay activación por movimiento del dispositivo. |
| 2.5.7 | N/A | N/A | No hay interacción de arrastre. |
| 2.5.8 | A/P | A/P | «Reintentar» y «Cerrar sesión» raíz pasan centro y cuatro extremos físicos; bootstrap no contiene objetivos táctiles. |
| 3.1.1 | A/P | A/P | VoiceOver pronuncia correctamente el copy español de Clientes y raíz. |
| 3.1.2 | N/A | N/A | No hay cambios de idioma dentro del contenido. |
| 3.2.1 | A/P | A/P | Full Keyboard Access no activa Clientes, Retry ni `localAccessDenied` al recibir foco; bootstrap no contiene controles. |
| 3.2.2 | N/A | N/A | No hay entrada editable. |
| 3.2.3 | A/P | A/P | Vacío/error conservan navegación; Retry y logout raíz llegan a Login con foco en su encabezamiento. Bootstrap es terminal y no navega. |
| 3.2.4 | A/P | A/P | Acciones existentes conservan nombres, roles y estilo de sus callers. |
| 3.2.6 | N/A | N/A | No existe mecanismo de ayuda repetido. |
| 3.3.1 | vacío N/A; error A/P | A/P | VoiceOver lee completos el error de Clientes y los tres errores raíz. |
| 3.3.2 | N/A | N/A | No hay campos editables que requieran labels o instrucciones. |
| 3.3.3 | N/A | N/A | No existe entrada editable que corregir. |
| 3.3.4 | A/P | A/P | Logout destructivo conserva su rol; Retry y salida raíz completan su activación runtime prevista. |
| 3.3.7 | N/A | N/A | Estas superficies no solicitan reintroducir datos. |
| 3.3.8 | N/A | N/A | No son superficies de autenticación editable ni mecanismos de acceso. |
| 4.1.2 | A/P | A/P | VoiceOver e Inspector confirman estructura, nombres y roles de Clientes y raíz. |
| 4.1.3 | vacío N/A; error A/P; loading A/L | errores A/P; loading A/L | Clientes anuncia su error una vez; los errores raíz comunican estado y restauran foco; loading estable no es observable. |

## Puerta ADR 0022 — resultado runtime

- Matriz completa: 55/55 criterios clasificados para Clientes y raíz/bootstrap.
- El owner autorizó la ampliación exacta de 4.1.3 tras revisión independiente. `ClientListScreen` publica un único
  `AccessibilityNotification.LayoutChanged()` sin texto ni destino al transitar a `.failed`; la locución nativa se
  produce una vez y el foco permanece en logout. 4.1.3 queda `A/P`.
- Los avisos del Inspector quedan cerrados como no reproducidos: señalan nodos nativos que escalan y refluyen completos
  en AX 5, sin fuente fija, solapes ni contraste fallido. Las rutas raíz interactivas y bootstrap ya completaron su
  evidencia funcional, de tecnologías aplicables y adaptación iPad; loading continúa `A/L`.
- ADR 0026 registra 1.3.4 como `A/No pasa — excepción de producto aceptada`: iPhone se limita a portrait sin necesidad
  esencial e iPad conserva sus orientaciones. La excepción sustituye de forma limitada el bloqueo de cierre de ADR 0022,
  pero no transforma la decisión en conformidad.
- La pasada post-cápsula detectó un P1 real de contraste en la descripción de raíz. El owner autorizó la recomendación
  independiente, el `Text(message)` aplica `TextSecondary` y la repetición del Inspector elimina el aviso; 1.4.3 queda
  `A/P`. Los tres avisos Dynamic Type restantes no se reproducen en previews ni runtime AX 5.
- Las auditorías finales iOS y accesibilidad pasan sin hallazgos P0–P3, en modo operacionalmente read-only y con huellas
  pre/post idénticas sobre 414 archivos. Confirman 4.1.3, loading `A/L`, VoiceOver iPad no ejecutado y 1.3.4
  `A/No pasa` mediante ADR 0026. PLU-29 continúa `In Progress` a la espera de autorización de entrega.
