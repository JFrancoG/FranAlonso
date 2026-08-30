# Evidencia de accesibilidad — 07.6 shell adaptable

Fecha: 2026-08-30

Alcance: PLU-31 / subfase 07.6. Esta evidencia aplica ADR 0022 al shell autenticado, a su integración con
`AuthenticationRootScreen` y al chrome nuevo compartido por Jornada, Histórico, Clientes, Catálogo e Informes. Es un
objetivo interno basado en WCAG 2.2 A/AA aplicable, WCAG2ICT, convenciones Apple y comportamiento real de iOS; no es
una certificación ni una declaración legal de conformidad.

## Autoridad y cambio evaluado

- El shell usa `TabView(selection:)` con `.sidebarAdaptable` y selección inicial Jornada. Cada una de las cinco
  secciones posee su propio `NavigationStack`, de modo que la composición puede conservar el estado de navegación por
  sección cuando existan destinos reales.
- Clientes conserva su pantalla funcional. Jornada, Histórico, Catálogo e Informes muestran
  `UnavailableStateView` con título, SF Symbol y mensaje localizados; las pestañas permanecen visibles y seleccionables
  aunque todavía no tengan contenido funcional.
- Las cinco secciones exponen la misma acción nativa «Cerrar sesión» en toolbar. No se extrapola al chrome nuevo la
  evidencia manual de logout ya registrada para Clientes y los estados raíz en
  [`07-3-state-views.md`](07-3-state-views.md).
- `AuthenticationRootScreen` presenta el shell fuera de la pila pública y le aplica `.id(session.id)`. Los estados no
  autenticados siguen compartiendo un único `NavigationStack`; `ContentView` deja de ser una segunda raíz.
- No se activaron Firebase, Keychain, datos live ni composición remota. El intento de fixture no-live en iPad alcanzó
  «Sesión bloqueada», no el shell; no cuenta como evidencia runtime de esta subfase.
- RED/GREEN nuevo es `N/A` razonado: el cambio es composición declarativa sin lógica extraída y la selección inicial ya
  estaba cubierta. No se añadieron tests de View, snapshots, XCTest, XCUITest ni UI tests.

## Evidencia automática y visual

- Xcode MCP, esquema `FranAlonso-Develop`: diagnósticos 0 en `AppShellScreen` y `AuthenticationRootScreen`; build final
  correcto en 14,184 s; build log e Issue Navigator con 0 warnings. Focales: 22/22. Suite completa: 815/815.
- Xcode MCP, esquema `FranAlonso-Production`: build correcto en 18,167 s; suite completa: 793 outcomes, 787 passed,
  0 failed y 6 not run. Los seis no ejecutados corresponden a condiciones del plan y no se presentan como pasados.
- Previews renderizadas en iPhone 17e Simulator, iOS 26.5, con Large, XXX Large y AX 5 en portrait; iPad mini
  (A17 Pro) Simulator, iPadOS 26.5, con AX 5 en portrait y landscape. La matriz trazada incluye Light/Dark, contraste
  normal/incrementado y una variante de layout RTL sintético. iPad Large/XXX Large no se duplicó como preview; XXX
  Large y AX 5 quedaron comprobados posteriormente en runtime.
- Un primer render con labels genéricos de `Tab` expulsaba la barra y las safe areas en iPhone XXX Large/AX 5. Se
  sustituyó por el inicializador semántico `Tab(_:systemImage:value:content:)`; los rerenders afectados pasan con barra,
  contenido y safe areas conservados.
- Las cuatro previews de `AuthenticationRootScreen` renderizan sin error. Se inspeccionaron visualmente «Signed out» y
  «Authenticated»: la primera conserva la raíz pública y la segunda presenta el shell autenticado.
- Las previews demuestran composición, reflow visible y copy completo en las variantes registradas. No demuestran árbol
  accesible, foco, locución, activación, restauración de estado ni operación con tecnologías de asistencia.

## Evidencia manual y límites

La pasada manual del shell ha comenzado con VoiceOver. En el primer recorrido reportado por el owner, la barra realiza
exactamente una parada por pestaña y anuncia, en este orden: «Jornada, pestaña, seleccionado, 1 de 5», «Histórico,
pestaña, 2 de 5», «Clientes, pestaña, 3 de 5», «Catálogo, pestaña, 4 de 5» e «Informes, pestaña, 5 de 5». Los símbolos
no crean paradas separadas. El owner indica también una sola parada en los demás elementos, pero aún no ha detallado
sus locuciones ni el orden completo. La comprobación se realizó en un iPhone 14 con iOS 26.6. Esta observación
acredita nombres, rol, selección, posición y secuencia interna de la barra. El owner aclaró además la activación:
deslizar desde Jornada hasta Histórico mueve únicamente el foco y no cambia el contenido; el doble toque selecciona
Histórico y entonces cambia la sección. Esta aclaración sustituye una respuesta intermedia ambigua.

En la misma configuración, el doble toque sobre Clientes cambia a esa sección y VoiceOver anuncia «Seleccionado,
Clientes, pestaña, 3 de 5». Su título se anuncia «Clientes, encabezamiento» y la acción de toolbar «Cerrar sesión,
botón». El estado vacío continúa con «No hay clientes» y «Los clientes aparecerán aquí cuando estén disponibles», sin
una parada adicional para el símbolo. Esta evidencia queda limitada a esa selección y a ese estado de Clientes.
El doble toque posterior sobre Catálogo también cambia la sección y anuncia «Seleccionado, Catálogo, pestaña, 4 de
5». Su título se anuncia «Catálogo, encabezamiento» y la acción de toolbar «Cerrar sesión, botón»; todavía no se ha
activado el logout desde esta sección. Desde logout, el recorrido del contenido realiza exactamente una parada por
elemento, usa locuciones correctas y no crea una parada para el símbolo; el owner no aportó una transcripción literal.
El doble toque sobre Informes cambia después la sección y anuncia «Seleccionado, Informes, pestaña, 5 de 5». El owner
reporta también correctos el título, el logout y el contenido: una parada por elemento y ninguna para el símbolo. No se
aportó una transcripción literal de esas locuciones ni se activó el logout.
Finalmente, el doble toque sobre Jornada vuelve a esa sección y anuncia «Seleccionado, Jornada, pestaña, 1 de 5».
Queda así observada la activación de las cinco pestañas. El título, el logout y el contenido de Jornada se reportan
correctos, una vez por elemento y sin parada para el símbolo; no se aportó transcripción literal ni se activó el logout.
El recorrido posterior de Histórico confirma igualmente título, logout y contenido correctos, una sola parada por
elemento y ninguna para el símbolo. No se aportó transcripción literal ni se activó el logout.
Después, el doble toque sobre «Cerrar sesión» desde Histórico vuelve a Login y VoiceOver sitúa el foco en «Iniciar
sesión, encabezamiento». La acción se ejecuta una vez; este resultado no se extrapola a las otras cuatro secciones.
Tras autenticarse de nuevo, Jornada vuelve a ser la sección inicial y VoiceOver sitúa el foco en «Cerrar sesión,
botón». Se registra como comportamiento runtime observado; la app no fuerza el foco al título.
El doble toque sobre ese logout de Jornada vuelve también una vez a Login y sitúa el foco en «Iniciar sesión,
encabezamiento». Quedan sin activar los logout de Clientes, Catálogo e Informes.
El owner completa después los tres casos restantes: logout desde Clientes, Catálogo e Informes se ejecuta una sola vez,
vuelve a Login y sitúa el foco en «Iniciar sesión, encabezamiento». Quedan así cubiertas las cinco secciones.
Con VoiceOver desactivado y Control por voz activo, «Tocar Jornada», «Tocar Histórico», «Tocar Clientes», «Tocar
Catálogo» y «Tocar Informes» cambian a su destino correcto a la primera. Logout por voz aún no se ha ejecutado.
«Tocar Cerrar sesión» vuelve después una sola vez a Login desde una sección activa no identificada. La inspección
confirma que las cinco secciones reutilizan el mismo `signOutToolbar`; no se atribuyen cinco ejecuciones por voz.
Con Control por botón activo, el escaneo expone exactamente los seis controles esperados: las cinco pestañas y «Cerrar
sesión», todos como objetivos independientes y sin objetivos adicionales para los iconos. Las cinco pestañas se activan
a la primera y cambian al destino esperado. Logout vuelve a Login y el escaneo continúa allí sin trampa.
Con VoiceOver desactivado, teclado físico y Acceso total con teclado, el indicador visible alcanza por separado las
cinco pestañas y «Cerrar sesión», sin detenerse en sus iconos. También alcanza el control nativo de split que muestra u
oculta la barra lateral; se registra como séptima parada válida del contenedor adaptable, no como redundancia de la app.
Al enfocar sucesivamente cada pestaña y pulsar Espacio, las cinco cambian a su sección correcta a la primera.
El recorrido se realiza con las flechas, conforme a los ajustes de Acceso total con teclado del dispositivo. Al enfocar
«Cerrar sesión» y pulsar Espacio, la acción se ejecuta una vez, vuelve a Login y las flechas continúan moviendo allí el
foco sin trampa.
Sin tecnologías de asistencia, un toque directo sobre cada una de las cinco pestañas activa solo el destino elegido a
la primera, sin activación accidental de una pestaña contigua.
Un toque directo sobre «Cerrar sesión» ejecuta la acción una vez y vuelve correctamente a Login.
En una pestaña no seleccionada, apoyar y desplazar verticalmente fuera de la barra antes de levantar cancela el cambio.
Si el dedo termina horizontalmente sobre otra pestaña, se activa la pestaña bajo el punto final. Esto acredita
activación en el up-event y una vía de cancelación; no se interpreta como activación en el down-event.
En «Cerrar sesión», apoyar, arrastrar fuera y levantar conserva la sesión y no navega a Login.
No hay ratón/trackpad conectado al dispositivo físico. El intento con el ratón del Mac en Simulator no mostró el
puntero circular de iPadOS, por lo que se considera emulación de Touch y no se usa como evidencia de puntero.

Accessibility Inspector devuelve siete avisos, todos «Dynamic Type font sizes are unsupported»: los cinco nombres de
pestaña y los dos textos visibles de Jornada. Las capturas individualizan Jornada, Histórico, Clientes e Informes; el
owner confirma que el séptimo nombre es Catálogo y presenta el mismo aviso. No aparecen otras categorías en el audit.
La inspección de código encuentra exclusivamente `Tab`, `ContentUnavailableView`, `Label` y `Text` nativos, sin fuente
fija, fuente custom ni límite de `dynamicTypeSize`. Apple documenta que el valor de entorno cambia con la preferencia
del usuario y que los estilos/fuentes del sistema soportan Dynamic Type; su HIG exige comprobar además el resultado a
tamaños de accesibilidad. En ese punto los avisos se conservaron pendientes de contraste runtime AX 5, sin tratarlos
como defecto de código confirmado ni como pase automático.
Con Texto más grande al máximo en Simulator, el título y el mensaje de Jornada aumentan de tamaño y permanecen
completos, legibles y sin solape. Los dos avisos asociados a esos nodos quedaron clasificados como falsos positivos del
audit en esta configuración; la comprobación de los cinco labels nativos se ejecutó a continuación.
Al mismo tamaño máximo, los cinco nombres de pestaña permanecen completos y cada pestaña se puede seleccionar
correctamente. Los cinco avisos restantes quedan también clasificados como falsos positivos del audit en esta
configuración. Accessibility Inspector no aporta un defecto de Dynamic Type accionable para el shell.
Un segundo audit en iPad y apariencia oscura devuelve seis avisos de la misma categoría: las cuatro pestañas visibles
y los dos textos de Jornada. La quinta pestaña está fuera del área visible del contenedor y no entra en ese barrido.
No aparecen categorías nuevas; este resultado no sustituye la inspección de propiedades del elemento.
La inspección de propiedades de la pestaña Jornada confirma la etiqueta «Jornada», los rasgos seleccionado y
tabulador, la acción Activar y una única etiqueta de entrada. Accessibility Inspector identifica el componente nativo
como `_UIFloatingTabBarItemCell` y muestra en la jerarquía las cinco pestañas junto con los controles nativos del
contenedor. El identificador interno `calendar` no se anuncia al usuario. Los nodos internos repetidos que aparecen en
la jerarquía no generan paradas duplicadas en runtime, según el recorrido VoiceOver ya acreditado.
La inspección de propiedades de logout confirma la etiqueta «Cerrar sesión», el rasgo botón, la acción Activar y una
única etiqueta de entrada, sin value, hint ni identifier innecesarios. Accessibility Inspector identifica el control
nativo como `_UIButtonBarButton`; la jerarquía lo sitúa en la barra de navegación junto al encabezamiento Jornada.
La inspección del título de navegación confirma la etiqueta «Jornada» y el rasgo cabecera, sin value, hint ni
identifier innecesarios, sobre un `UILabel` nativo. La jerarquía lo conserva como encabezamiento junto a logout. Esta
evidencia corresponde al título de navegación y no sustituye la inspección del título central del estado indisponible.
La inspección del título central confirma la etiqueta «Jornada» y el rol texto estático, sin value, hint ni identifier
innecesarios, sobre un `SwiftUI.AccessibilityNode`. Su jerarquía expone exactamente el título y el mensaje como nodos
de texto separados y no crea un nodo accesible para el símbolo decorativo.
La inspección del mensaje confirma la etiqueta completa «Esta sección todavía no está disponible.» y el rol texto
estático, sin value, hint ni identifier innecesarios, sobre otro `SwiftUI.AccessibilityNode`. Con ello queda completa
la inspección estructural de tabs, logout, encabezamiento y estado indisponible, sin hallazgos.
El owner confirma posteriormente que Aumentar contraste, Reducir transparencia y Diferenciar sin color estaban
activados simultáneamente en el entorno de Inspector. En ese perfil combinado, tanto en apariencia clara como oscura,
la selección de Jornada, los cinco nombres de pestaña, los dos textos visibles y «Cerrar sesión» permanecen completos,
claramente distinguibles y sin pérdida visual. Esta evidencia prueba compatibilidad con la combinación, no tres pasadas
aisladas ni una medición numérica de contraste.
Con Reducir movimiento activado, cambiar repetidamente entre las cinco pestañas termina siempre en la sección correcta,
sin animaciones molestas, destellos ni pérdida de contenido.
En el recorrido global con VoiceOver, «Cerrar sesión» es el primer elemento por su posición superior; después aparecen
Jornada, Histórico, Clientes, Catálogo e Informes de izquierda a derecha y, a continuación, el contenido restante en
su orden visual. No hay saltos, inversión ni trampa.
Con el foco inicialmente en «Cerrar sesión» y el rotor ajustado a Encabezamientos, deslizar hacia abajo salta
directamente a «Jornada, encabezamiento». Si el foco ya está en Jornada, VoiceOver informa que no encuentra otro
encabezamiento, comportamiento esperado al ser el único del destino.
Tras dejar el foco en el mensaje de Jornada, cambiar a Clientes y regresar, VoiceOver coloca el foco en «Jornada,
pestaña, seleccionado». El foco queda en el control que produjo el cambio, visible y operativo; no queda perdido,
oculto ni retenido en el destino abandonado.
En iPad mini Simulator en portrait, las cinco pestañas, el control de barra lateral, logout y el contenido de Jornada
son completos y utilizables. Las últimas pestañas no aparecen simultáneamente: se alcanzan desplazando horizontalmente
el contenedor nativo de pestañas; en landscape quedan visibles sin ese desplazamiento. No hay pérdida ni solape.
Al girar 180° a portrait invertido, el resultado es idéntico: todos los elementos permanecen utilizables, sin recortes
ni solapes, y las últimas pestañas conservan el mismo desplazamiento horizontal nativo.
En landscape con el control de barra lateral a la izquierda, las cinco pestañas quedan visibles simultáneamente y el
control lateral, logout y contenido permanecen completos y utilizables, sin recortes ni solapes.
El landscape opuesto ofrece el mismo resultado correcto: cinco pestañas simultáneamente visibles y todos los demás
elementos completos y utilizables, sin recortes ni solapes. Quedan cubiertas las cuatro orientaciones de iPad.
En la ventana de multitarea mínima, las cinco pestañas siguen siendo accesibles mediante su desplazamiento horizontal
nativo y el control lateral, logout y contenido permanecen completos, utilizables y sin recortes ni solapes.
En esa ventana mínima, Acceso total con teclado mantiene el foco siempre visible y cada control enfocado completo; al
llegar a las últimas pestañas, el contenedor se desplaza para mostrarlas sin ocultar el indicador de foco.
En iPad a XXX Large —máximo del regulador con Tamaños de accesibilidad más grandes desactivado—, contenido, logout y
las cinco pestañas permanecen completos y utilizables; la barra conserva su desplazamiento horizontal nativo.

No quedan comprobaciones manuales adicionales para el shell actual. Los controles interactivos usan exclusivamente
superficies nativas sin reducción de hit area; los dos audits de Inspector no detectan avisos de contraste y la pasada
Light/Dark con el perfil combinado conserva la distinción visual. El puntero físico no es requisito de 2.5.8 y su
ausencia queda registrada como límite del entorno, no como evidencia pendiente.

Push/pop y sheets son `N/A` para este alcance: ninguna sección incorpora aún un destino secundario ni un flujo de
edición modal. RTL acredita solo inversión sintética del layout; el catálogo contiene únicamente español y no se ha
validado una localización RTL.

ADR 0026 limita iPhone a portrait sin necesidad esencial. Por ello 1.3.4 se registra como
`Aplicable/No pasa — excepción de producto aceptada`; la excepción no se presenta como conformidad y no rebaja ningún
otro criterio de ADR 0022.

## Registro ADR 0022

Leyenda:

- `Pasa`: el criterio aplicable tiene evidencia suficiente dentro de lo ejecutado.
- `Limitado`: existe evidencia parcial válida, pero falta una comprobación exigida para el shell nuevo.
- `Pendiente`: el criterio es aplicable y la comprobación manual correspondiente aún no se ha ejecutado.
- `N/A`: el criterio no aplica por la razón funcional o tecnológica indicada.
- `No pasa — excepción de producto aceptada`: incumplimiento explícito gobernado únicamente por ADR 0026.

Configuración común de preview: iPhone 17e e iPad mini (A17 Pro), iOS/iPadOS 26.5, 2026-08-29. Las referencias a
`Inspección` significan lectura del código SwiftUI y del catálogo de localización, no Accessibility Inspector.

| ID | Aplicabilidad y resultado | Método y artefacto | Hallazgo, límite y disposición |
|---|---|---|---|
| 1.1.1 | Aplicable · Pasa | Inspección + Preview + VoiceOver + Switch Control + teclado + Inspector | Las cinco pestañas y logout tienen nombres textuales; sus símbolos y el del estado indisponible no crean nodos ni paradas independientes. Inspector confirma tabs, logout, encabezamiento, título y mensaje. |
| 1.2.1 | N/A | Inspección | No hay audio o vídeo pregrabado. |
| 1.2.2 | N/A | Inspección | No hay audio sincronizado pregrabado. |
| 1.2.3 | N/A | Inspección | No hay vídeo pregrabado. |
| 1.2.4 | N/A | Inspección | No hay contenido sincronizado en directo. |
| 1.2.5 | N/A | Inspección | No hay vídeo pregrabado con audiodescripción. |
| 1.3.1 | Aplicable · Pasa | Inspección + Preview + VoiceOver + Inspector | VoiceOver anuncia nombre, rol, selección y posición de cada pestaña; los cinco bloques exponen correctamente título, logout y contenido, una vez por elemento y sin nodo de símbolo. Inspector confirma las relaciones programáticas de tabs, logout, encabezamiento y los dos textos del estado. |
| 1.3.2 | Aplicable · Pasa | VoiceOver + Switch Control + teclado | El recorrido global sigue logout → cinco tabs de izquierda a derecha → contenido en orden visual, sin saltos; Control por botón y teclado conservan una secuencia lógica y las tabs se activan con Espacio. |
| 1.3.3 | Aplicable · Pasa | Inspección + localización | Secciones, indisponibilidad y logout se identifican mediante texto; ninguna instrucción depende solo de posición, forma, color o sonido. |
| 1.3.4 | Aplicable · No pasa — excepción de producto aceptada | ADR 0026 + Preview + runtime iPad | iPhone permanece portrait-only sin necesidad esencial. iPad pasa sus cuatro orientaciones y la ventana de multitarea mínima sin pérdida. |
| 1.3.5 | N/A | Inspección | El shell no recopila datos personales ni añade campos de entrada. |
| 1.4.1 | Aplicable · Pasa | Inspección + Preview + runtime perfil combinado | La sección seleccionada usa semántica nativa y, con Diferenciar sin color dentro del perfil combinado, conserva texto, icono y estado seleccionado; ninguna señal depende únicamente del color. |
| 1.4.2 | N/A | Inspección | No hay audio automático. |
| 1.4.3 | Aplicable · Pasa | Preview + Inspector + runtime perfil combinado | Dos audits de Inspector, incluido oscuro, no detectan avisos de contraste; el shell usa texto y controles nativos sin color custom, y Light/Dark con las tres preferencias activas conserva selección, tabs, textos y logout claramente distinguibles y completos. |
| 1.4.4 | Aplicable · Pasa | Preview + Inspector + runtime Large/XXX Large/AX 5 | Jornada escala título y mensaje sin solape; las cinco tabs siguen completas y operables. Large se observó al iniciar el audit, AX 5 en runtime y XXX Large también en iPad. Los siete avisos son falsos positivos. |
| 1.4.5 | Aplicable · Pasa | Inspección | Todo el copy significativo es `Text`; los SF Symbols no codifican texto. |
| 1.4.10 | Aplicable · Pasa | Preview + runtime iPad orientaciones/multitarea | iPhone, las cuatro orientaciones iPad y la ventana mínima conservan contenido y acciones sin recortes ni solapes; las últimas tabs usan desplazamiento horizontal nativo cuando falta ancho. |
| 1.4.11 | Aplicable · Pasa | Preview + Inspector + runtime perfil combinado | Tabs, selección y toolbar son componentes nativos sin geometría o color custom; dos audits no detectan contraste insuficiente y Light/Dark con las tres preferencias activas conserva su distinción visual. |
| 1.4.12 | N/A | Inspección tecnológica | SwiftUI nativo no ofrece override de espaciado mediante markup, conforme a WCAG2Mobile. |
| 1.4.13 | N/A | Inspección | El shell no muestra popovers, tooltips ni contenido adicional al hover o al foco. |
| 2.1.1 | Aplicable · Pasa | Full Keyboard Access | Las flechas recorren los controles propios y el split nativo; Espacio activa las cinco pestañas y logout sin toque. |
| 2.1.2 | Aplicable · Pasa | Switch Control + Full Keyboard Access | Ambas tecnologías permiten entrar, operar pestañas y logout, volver a Login y continuar el recorrido sin trampa. |
| 2.1.4 | N/A | Inspección | No hay atajos de un solo carácter. |
| 2.2.1 | N/A | Inspección | El shell no impone límites de tiempo. |
| 2.2.2 | N/A | Inspección + runtime Reduce Motion | No hay movimiento o actualización automática persistente que requiera pausa; con Reducir movimiento, el switching conserva contenido y destino. |
| 2.3.1 | Aplicable · Pasa | Inspección + Preview + runtime Reduce Motion | No se introduce contenido intermitente, destellos ni animación creada por la app; el switching repetido tampoco los produce. |
| 2.4.1 | Aplicable · Pasa | Inspección + VoiceOver + rotor | Cinco destinos primarios nativos ofrecen acceso directo al contenido; desde logout, el rotor Encabezamientos salta directamente a «Jornada, encabezamiento». |
| 2.4.2 | Aplicable · Pasa | Preview + VoiceOver | Las cinco pestañas y los cinco destinos comunican sus títulos descriptivos; salvo Clientes, no se aportó transcripción literal completa. |
| 2.4.3 | Aplicable · Pasa | VoiceOver + Switch Control + teclado | El orden global observado respeta la posición visual: logout, cinco tabs de izquierda a derecha y contenido; las tres tecnologías operan sin saltos, nodos de icono ni trampa. |
| 2.4.4 | Aplicable · Pasa | Inspección + localización + VoiceOver + Voice Control | Las cinco pestañas tienen nombres inequívocos y Control por voz activa cada una por su nombre visible; el logout compartido se activa por «Tocar Cerrar sesión». |
| 2.4.5 | N/A | Inspección | Cinco destinos primarios no constituyen una colección extensa que requiera búsqueda o una segunda vía. |
| 2.4.6 | Aplicable · Pasa | Inspección + Preview + VoiceOver + rotor | Los cinco títulos y logout se reportan correctos; VoiceOver reconoce Jornada como encabezamiento y el rotor navega directamente hasta él. |
| 2.4.7 | Aplicable · Pasa | Full Keyboard Access | El indicador de foco es visible en las cinco pestañas, logout y el control split nativo; no se detiene en iconos redundantes. |
| 2.4.11 | Aplicable · Pasa | Teclado + Preview + runtime ventana mínima | En iPhone y en la ventana iPad mínima, pestañas, logout y split enfocados permanecen visibles y completos; la barra se desplaza para mostrar las últimas tabs. Sheets son N/A. |
| 2.5.1 | N/A | Inspección | No hay gestos multipunto o de trayectoria; todas las intenciones se expresan como controles simples. |
| 2.5.2 | Aplicable · Pasa | VoiceOver + Touch | Las pestañas activan en el up-event: salir verticalmente de la barra cancela y terminar sobre otra pestaña activa ese destino. En logout, levantar fuera conserva la sesión y no navega a Login. |
| 2.5.3 | Aplicable · Pasa | Inspección + Voice Control | Los nombres semánticos contienen el texto visible y Control por voz activa a la primera Jornada, Histórico, Clientes, Catálogo, Informes y Cerrar sesión. |
| 2.5.4 | N/A | Inspección | No hay activación por movimiento del dispositivo. |
| 2.5.7 | N/A | Inspección | No hay interacción de arrastre. |
| 2.5.8 | Aplicable · Pasa | Inspección + Touch + VoiceOver + Voice Control + Switch Control + teclado | `Tab` y `Button` aportan superficies nativas sin `frame` ni `contentShape` que reduzca el hit area; Touch no produce activación contigua y las cuatro modalidades adicionales operan cada objetivo. La ausencia de puntero físico no limita este criterio. |
| 3.1.1 | Aplicable · Pasa | Catálogo `.xcstrings` + Preview + VoiceOver | En iPhone 14/iOS 26.6 se anuncian sin incidencia las etiquetas y el contenido español de las cinco secciones; salvo Clientes, no se aportó transcripción literal completa. |
| 3.1.2 | N/A | Inspección | No hay cambios de idioma dentro del contenido. El RTL renderizado es solo layout sintético. |
| 3.2.1 | Aplicable · Pasa | VoiceOver + teclado | Enfocar una pestaña no cambia el contexto: VoiceOver requiere doble toque y Acceso total con teclado requiere Espacio; las cinco activaciones explícitas cambian al destino esperado. |
| 3.2.2 | N/A | Inspección | El shell no contiene entrada editable; elegir una pestaña es una acción de navegación explícita. |
| 3.2.3 | Aplicable · Pasa | Inspección + Preview + VoiceOver + Voice Control + Switch Control + teclado | El switching explícito funciona de forma consistente entre las cinco secciones mediante las cuatro modalidades; al regresar con VoiceOver, el foco queda previsiblemente en la pestaña seleccionada. No existe aún estado navegable interno que preservar. |
| 3.2.4 | Aplicable · Pasa | Inspección | Una sola declaración de cada `Tab` y un único `signOutToolbar` conservan nombre, símbolo, rol y comportamiento en las cinco secciones. |
| 3.2.6 | N/A | Inspección | No existe mecanismo de ayuda repetido. |
| 3.3.1 | N/A | Inspección | El shell no añade entrada ni un nuevo estado de error; «todavía no disponible» es un estado informativo. |
| 3.3.2 | N/A | Inspección | No hay campos editables que requieran labels o instrucciones. |
| 3.3.3 | N/A | Inspección | No existe entrada editable ni error de validación que corregir. |
| 3.3.4 | Aplicable · Pasa | VoiceOver | «Cerrar sesión» se activa una vez desde cada sección y vuelve a Login con foco en «Iniciar sesión, encabezamiento». No elimina datos de negocio ni requiere confirmación. |
| 3.3.7 | N/A | Inspección | El shell no solicita información ya aportada. |
| 3.3.8 | N/A | Inspección + evidencia 07.2/07.3 | El shell no introduce una prueba de autenticación; Login, biometría y fallback no cambian. |
| 4.1.2 | Aplicable · Pasa | Inspección + VoiceOver + Voice Control + Switch Control + teclado + Inspector | Pestañas y logout responden con las cuatro modalidades; Inspector confirma nombres, roles, estados y acciones, los textos estáticos carecen de propiedades innecesarias, no hay nodos de icono y el split nativo conserva objetivo propio. |
| 4.1.3 | N/A | Inspección | El shell no introduce carga, éxito, error ni otro mensaje dinámico; los estados asíncronos preexistentes no cambian. |

## Puerta ADR 0022

- Matriz completa: 55/55 criterios clasificados para el shell autenticado y su integración raíz.
- No hay hallazgos de build, test, diagnósticos o preview abiertos. El hallazgo visual de tabs en XXX Large/AX 5 quedó
  corregido y rerenderizado.
- La puerta manual está cerrada: 29 criterios están `Pasa`, ninguno `Pendiente` o `Limitado` y 1 registra el `No pasa`
  aceptado exclusivamente por ADR 0026; los 25 restantes son `N/A` motivados. No se presenta como certificación legal.
- La auditoría independiente read-only detectó inicialmente dos P2 documentales: cobertura iPad sobredeclarada y 1.4.4
  sin runtime `AX 5`. Tras corregir ambos, la repetición afectada devolvió `Sin hallazgos` y gate de correcciones `pass`.
- La repetición final de accesibilidad cerró tres P2 documentales sobre contraste/targets y un P3 de multitarea; tras
  reconciliar esas filas no requiere pruebas adicionales. El gate ADR 0022 pasa con la excepción 1.3.4 documentada.
