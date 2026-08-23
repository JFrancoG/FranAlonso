# Evidencia de accesibilidad — 07.2 controles reutilizables

Fecha: 2026-08-23

Alcance: PLU-28 / subfase 07.2. Esta evidencia aplica ADR 0022 a `FormFieldSection`, Login y sesión protegida. Es un
objetivo interno basado en WCAG 2.2 A/AA aplicable, WCAG2ICT, convenciones Apple y comportamiento real de iOS; no es una
certificación ni una declaración legal de conformidad.

## Autoridad y cambio evaluado

- Base inicial: `main == origin/main == 074ce5e`; PLU-28 `In Progress` sin blockers.
- `PrimaryActionStyle` permanece sobre botones SwiftUI nativos y comparte foreground semántico, prominent, tint,
  cápsula y `.large`. No contiene acción, gesto, estado, foco ni lógica.
- Los estados visibles usan `successInk`, `warningInk` y `errorInk`. El fallback mantiene `role: .destructive`, pero
  aplica `errorInk` en su label para no heredar el rojo nativo insuficiente sobre la fila Light.
- `FormFieldSection` conserva una sola `Section` nativa y contenido caller-owned. Login mantiene dos `Section` de campos
  separadas: es una condición expresa para no fusionar Email y Contraseña en Switch Control agrupado.
- Los labels de campos tienen SF Symbols visuales; el ojo es el único botón solo-icono. Los botones de texto no usan
  iconos. Los CTA «Acceder» de Login y Session comparten estilo y unos 49 pt de altura visual.
- El fallback destructivo de Session sigue siendo un botón nativo sin fondo/borde. `ViewThatFits` dispone de copy largo
  y corto localizado; la variante corta no llegó a aparecer en runtime y se conserva como evidencia `Limitado`.
- RED/GREEN es `N/A` para composición visual sin lógica. La coordinación biométrica pura sí está cubierta con Swift
  Testing; no se añadieron XCTest, XCUITest ni UI tests.

## Evidencia transversal

- Xcode MCP, `FranAlonso-Develop`, iPhone 17e Simulator/iOS 26.5: build final correcto en 13,424 s; Issue Navigator sin
  warnings; cero diagnósticos en los Swift de producción afectados.
- La consulta aislada de `BiometricAnnouncementGateTests.swift` devolvió `SourceEditor error 5`; compilación y ejecución
  del test fueron verdes, por lo que se registra como límite del editor.
- Previews de `FormFieldSection`, Login y Session: Light/Dark, contraste normal/incrementado, Large/XXX Large/AX 5,
  portrait/landscape, LTR/RTL y estados enabled/disabled.
- Focales: 6/6 `DesignSystemColorAssetTests`; 39/39 localización + coordinación biométrica; 58/58 root/Login/Session
  ViewModels; 28/28 lanzamiento/configuración. Total 131/131. Suite completa: 843/843.
- Una ejecución de colores en iPhone 11 físico obtuvo 3/6 porque tres casos source-backed no pueden leer la ruta fuente
  del Mac desde el sandbox del dispositivo. La repetición equivalente en simulador pasó 6/6; es una nota ambiental,
  no una regresión del producto.
- La primera auditoría AX midió un P1 de contraste en el error rojo de Login, el aviso naranja de Session y el fallback
  destructivo nativo. Se sustituyeron por los inks semánticos ya cubiertos por los umbrales 4,5:1/7:1. La corrección
  pasó build, Issue Navigator sin warnings, tests de color 6/6 y previews Light/Dark × contraste
  normal/incrementado para Login error, Session warning/fallback y Session error/fallback.
- Accessibility Inspector señaló avisos genéricos de Dynamic Type. No se suprimieron; previews y runtime AX 5
  confirmaron textos y controles completos, operables, sin recortes ni solapes. El target size se acredita mediante
  superficie real y activación manual, no solo por ausencia de un warning `Hit Region`.
- VoiceOver, Voice Control, Switch Control agrupado y Full Keyboard Access se completaron para ambos flujos. Los tres
  argumentos del esquema Develop quedaron desactivados (`NO`) al terminar.

| Superficie | Apariencias | Dynamic Type | Adaptación | Estado |
|---|---|---|---|---|
| FormFieldSection | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | Portrait/landscape; LTR/RTL | Pasa en previews |
| Login Idle/Loading/Error | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | Portrait/landscape; LTR/RTL | Pasa en previews y runtime aplicable |
| Session Locked/Unlocking/Error | Light/Dark; contraste normal/incrementado | Large/XXX Large/AX 5 | Portrait/landscape; LTR/RTL | Pasa en previews y runtime aplicable |

## Registro Login

Configuración manual principal: iPhone 11/14 físicos, iOS 26.6, `FranAlonso-Develop`, fixtures Develop cuando el flujo
lo requirió, 2026-08-22/23. Full Keyboard Access y variantes de preview: iPhone 17e Simulator/iOS 26.5. `Owner` designa
las comprobaciones realizadas por el propietario; `Impl.` la inspección y evidencia automática de implementación.

| ID | Aplicabilidad | Justificación | Resultado | Método | Configuración | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles requieren alternativa o exclusión decorativa. | Pasa | VoiceOver + inspección | Runtime + código | Labels persistentes; ojo con nombre Mostrar/Ocultar; decoración sin parada duplicada. | Owner + Impl. |
| 1.2.1 | N/A | No hay audio o vídeo pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.2 | N/A | No hay audio sincronizado pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.3 | N/A | No hay vídeo pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.4 | N/A | No hay contenido sincronizado en directo. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.5 | N/A | No hay vídeo con audiodescripción. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.3.1 | Aplicable | Jerarquía, labels, grupos y relaciones son programáticos. | Pasa | VoiceOver + Switch Control | Runtime | Encabezamiento; Email; Contraseña + ojo; CTA. Dos `Section` separadas. | Owner + Impl. |
| 1.3.2 | Aplicable | El orden accesible debe conservar el flujo visual. | Pasa | VoiceOver + FKA + Switch Control | Runtime | Iniciar sesión → Email → Contraseña → ojo → Acceder; tres grupos de primer nivel en Switch Control. | Owner |
| 1.3.3 | Aplicable | Ninguna instrucción depende solo de posición, forma, color o sonido. | Pasa | Revisión de copy | Código + runtime | Labels, prompts, estados y acciones son textuales. | Owner + Impl. |
| 1.3.4 | Aplicable | El flujo debe funcionar en orientaciones soportadas. | Pasa | Preview + manual | Matriz 07.2 | Portrait/landscape conservan contenido y acciones. | Owner + Impl. |
| 1.3.5 | Aplicable | Email y contraseña deben conservar propósito y AutoFill. | Limitado | AutoFill real | iPhone 11 físico | El selector rellenó ambos campos sin enviar; límite aceptado por ausencia de Associated Domains. | Owner |
| 1.4.1 | Aplicable | Estados y errores no deben depender solo del color. | Pasa | Contraste + runtime | Matriz 07.2 | Texto, enabled/disabled y error conservan identificación no cromática. | Owner + Impl. |
| 1.4.2 | N/A | No hay audio automático. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.4.3 | Aplicable | Texto y labels requieren contraste suficiente. | Pasa | Tests de color + previews | Cuatro apariencias | Pares semánticos cubiertos 6/6; contraste correcto en enabled/disabled. | Owner + Impl. |
| 1.4.4 | Aplicable | Contenido usable hasta AX 5. | Pasa | Preview + runtime AX 5 | Dark/portrait y matriz | Todos los textos completos y controles operables, sin solapes. | Owner + Impl. |
| 1.4.5 | Aplicable | No debe haber imágenes de texto. | Pasa | Inspección | Código | Todo el copy es `Text`; SF Symbols no codifican texto. | Impl. |
| 1.4.10 | Aplicable | Debe haber reflow sin pérdida funcional. | Pasa | Previews | Orientación/RTL/AX 5 | Sin scroll bidimensional ni acciones perdidas. | Impl. |
| 1.4.11 | Aplicable | Controles y estados requieren contraste no textual. | Pasa | Tests + previews | Cuatro apariencias | Campos, ojo, foco y CTA permanecen perceptibles. | Owner + Impl. |
| 1.4.12 | N/A | SwiftUI nativo no ofrece override de espaciado mediante markup. | Pasa | Inspección tecnológica | Código | N/A motivado conforme a WCAG2Mobile. | Impl. |
| 1.4.13 | N/A | No aparece contenido adicional por hover o foco. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.1.1 | Aplicable | Todos los controles deben ser operables sin toque. | Pasa | FKA + Switch Control | Simulator + físico | Campos, ojo y CTA alcanzables y operables. | Owner |
| 2.1.2 | Aplicable | El foco debe entrar, operar y salir sin trampa. | Pasa | FKA + Switch Control | Simulator + físico | Flechas navegan; Tab sale de edición; ninguna trampa. | Owner |
| 2.1.4 | N/A | No hay atajos de un solo carácter. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.2.1 | N/A | No hay límite temporal impuesto por la pantalla. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.2.2 | N/A | No hay movimiento o actualización automática persistente. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.3.1 | Aplicable | La pantalla no debe producir destellos. | Pasa | Inspección visual | Previews + runtime | No hay contenido intermitente o animación con destellos. | Owner + Impl. |
| 2.4.1 | Aplicable | La entrada al contenido debe ser eficiente. | Pasa | VoiceOver | Entradas directas y desde Session | El foco inicial llega a «Iniciar sesión, encabezamiento». | Owner |
| 2.4.2 | Aplicable | La pantalla debe comunicar un título descriptivo. | Pasa | VoiceOver | Runtime | «Iniciar sesión, encabezamiento». | Owner |
| 2.4.3 | Aplicable | El foco debe seguir una secuencia comprensible. | Limitado | VoiceOver + FKA + Switch Control | Runtime | Orden correcto; al reactivar con el nodo de error enfocado, iOS puede volver al encabezamiento. Límite aceptado. | Owner + Impl. |
| 2.4.4 | Aplicable | Cada acción debe ser comprensible por nombre y contexto. | Pasa | VoiceOver + Voice Control | Runtime | Email, Contraseña, Mostrar/Ocultar contraseña y Acceder son inequívocos. | Owner |
| 2.4.5 | N/A | No existe una colección extensa que requiera varias vías. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 2.4.6 | Aplicable | Encabezados y labels deben describir propósito. | Pasa | VoiceOver | Runtime | Labels persistentes; el email ya no expone rasgo de enlace. | Owner |
| 2.4.7 | Aplicable | El foco de teclado debe ser visible. | Pasa | FKA | Simulator | Marco visible sobre campos, ojo y CTA. | Owner |
| 2.4.11 | Aplicable | El control enfocado no debe quedar totalmente oculto. | Pasa | FKA | Simulator | Los cuatro controles permanecen visibles. | Owner |
| 2.5.1 | N/A | No hay gestos multipunto o de trayectoria. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.2 | Aplicable | La activación debe conservar cancelación y no duplicarse. | Pasa | Touch + Voice Control | Físico | Ojo y CTA responden una vez; el CTA muestra un solo error. | Owner |
| 2.5.3 | Aplicable | El nombre accesible debe contener el texto visible. | Pasa | Voice Control por nombre | Físico | «Tocar Email», «Tocar Contraseña», «Tocar Mostrar/Ocultar contraseña» y «Tocar Acceder» pasan. | Owner |
| 2.5.4 | N/A | No hay activación por movimiento del dispositivo. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.7 | N/A | No hay interacción de arrastre. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.8 | Aplicable | Política del proyecto: superficie operable mínima 44×44 pt. | Pasa | Touch centro/extremos | iPhone físico | Email, contraseña oculta/visible, ojo y CTA responden en centro y perímetro sin activación cruzada. CTA ~49 pt. | Owner + Impl. |
| 3.1.1 | Aplicable | El contenido debe exponerse en español correcto. | Pasa | VoiceOver | Runtime ES | Pronunciación y copy esperado. | Owner |
| 3.1.2 | N/A | No hay cambios de idioma dentro del contenido. | Pasa | Inspección | Localización | N/A motivado. | Impl. |
| 3.2.1 | Aplicable | Recibir foco no debe cambiar contexto. | Pasa | VoiceOver + FKA | Runtime | Navegar por los controles no envía el formulario. | Owner |
| 3.2.2 | Aplicable | Introducir datos no debe causar cambios inesperados. | Limitado | Teclado + ojo | iPhone físico | No hay envío automático; al volver visible → `SecureField`, la escritura puede sustituir el valor nativamente. | Owner |
| 3.2.3 | Aplicable | La navegación repetida debe conservar patrón. | Pasa | Comparación de recorridos | Runtime | Orden estable entre entradas, errores y reactivaciones salvo límite 2.4.3. | Owner |
| 3.2.4 | Aplicable | Acciones equivalentes deben identificarse coherentemente. | Pasa | Revisión visual/semántica | Login + Session | CTA primario compartido; nombre «Acceder» coherente. | Owner + Impl. |
| 3.2.6 | N/A | No existe mecanismo de ayuda repetido. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 3.3.1 | Aplicable | El error debe identificarse en texto y anunciarse. | Pasa | VoiceOver | Credenciales rechazadas | El error nuevo recibe foco y se anuncia completo una vez. | Owner |
| 3.3.2 | Aplicable | Las entradas requieren labels e instrucciones. | Pasa | VoiceOver | Runtime | «Email» y «Contraseña» persisten junto a sus prompts. | Owner |
| 3.3.3 | Aplicable | La sugerencia de error debe ser segura. | Pasa | Revisión de copy | Localización + runtime | Mensaje útil y resistente a enumeración; no revela qué credencial falló. | Owner + Impl. |
| 3.3.4 | N/A | Login no ejecuta una acción legal, financiera o destructiva. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 3.3.7 | Aplicable | No debe pedirse de nuevo entrada sin necesidad. | Limitado | Cambio visible/seguro | iPhone físico | El control nativo puede reemplazar la contraseña al recrear `SecureField`; límite aceptado sin UIKit. | Owner |
| 3.3.8 | Aplicable | La autenticación debe admitir mecanismos reconocibles. | Pasa | AutoFill + entrada estándar | iPhone físico | Campos nativos, Password AutoFill y pegado/entrada ordinaria disponibles. | Owner |
| 4.1.2 | Aplicable | Controles deben exponer nombre, rol, valor y estado. | Pasa | VoiceOver + Voice Control | Runtime | Campos, ojo y CTA conservan roles/estados; email no se anuncia como enlace. | Owner |
| 4.1.3 | Aplicable | Los mensajes importantes deben anunciarse sin mover foco innecesariamente. | Pasa | VoiceOver | Error nuevo | Una locución completa por error; la limitación de reactivación se registra en 2.4.3. | Owner |

## Registro Session

Configuración manual principal: iPhone 11/14 físicos, iOS 26.6, `FranAlonso-Develop`, sesión restaurada, Face ID cuando
aplicó, 2026-08-22/23. Full Keyboard Access y previews: iPhone 17e Simulator/iOS 26.5.

| ID | Aplicabilidad | Justificación | Resultado | Método | Configuración | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Iconos y controles requieren alternativa o exclusión decorativa. | Pasa | VoiceOver + inspección | Runtime + código | Iconografía decorativa sin parada; botones con nombres textuales. | Owner + Impl. |
| 1.2.1 | N/A | No hay audio o vídeo pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.2 | N/A | No hay audio sincronizado pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.3 | N/A | No hay vídeo pregrabado. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.4 | N/A | No hay contenido sincronizado en directo. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.2.5 | N/A | No hay vídeo con audiodescripción. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.3.1 | Aplicable | Jerarquía, estado y acciones deben ser programáticos. | Pasa | VoiceOver + Switch Control | Runtime | Encabezamiento, estado, explicación, biometría, error cuando existe y fallback son nodos comprensibles. | Owner |
| 1.3.2 | Aplicable | El orden accesible debe conservar el flujo visual. | Pasa | VoiceOver + FKA | Runtime | Sesión → bloqueada → explicación → Acceder → error → fallback. | Owner |
| 1.3.3 | Aplicable | El copy no debe depender solo de posición, forma, color o sonido. | Pasa | Revisión de copy | Código + runtime | Estado y acciones están expresados en texto. | Owner + Impl. |
| 1.3.4 | Aplicable | El flujo debe funcionar en orientaciones soportadas. | Pasa | Preview + manual | Matriz 07.2 | Portrait/landscape conservan contenido y acciones. | Owner + Impl. |
| 1.3.5 | N/A | No hay entradas de datos personales en Session. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.4.1 | Aplicable | Estado y acciones no deben depender solo del color. | Pasa | Runtime + previews | Matriz 07.2 | «Sesión bloqueada», explicación y disabled son distinguibles sin color. | Owner + Impl. |
| 1.4.2 | N/A | No hay audio automático. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 1.4.3 | Aplicable | Texto y labels requieren contraste suficiente. | Pasa | Tests de color + previews | Cuatro apariencias | Par primario semántico y textos conservan contraste. | Owner + Impl. |
| 1.4.4 | Aplicable | Contenido usable hasta AX 5. | Pasa | Preview + runtime AX 5 | Matriz 07.2 | Textos completos, botones de una línea y scroll vertical disponible. | Owner + Impl. |
| 1.4.5 | Aplicable | No debe haber imágenes de texto. | Pasa | Inspección | Código | Todo el copy es `Text`. | Impl. |
| 1.4.10 | Aplicable | Debe haber reflow sin pérdida funcional. | Pasa | Previews | Orientación/RTL/AX 5 | Sin scroll bidimensional ni acciones perdidas. | Impl. |
| 1.4.11 | Aplicable | Controles y estados requieren contraste no textual. | Pasa | Tests + previews | Cuatro apariencias | CTA, disabled y foco siguen perceptibles. | Owner + Impl. |
| 1.4.12 | N/A | SwiftUI nativo no ofrece override de espaciado mediante markup. | Pasa | Inspección tecnológica | Código | N/A motivado conforme a WCAG2Mobile. | Impl. |
| 1.4.13 | N/A | No aparece contenido adicional por hover o foco. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.1.1 | Aplicable | Ambos botones deben operarse sin toque. | Pasa | FKA + Switch Control | Simulator + físico | Acceder y fallback alcanzables y operables; Matching llega a Clientes. | Owner |
| 2.1.2 | Aplicable | El foco debe entrar, operar y salir sin trampa. | Pasa | FKA + Switch Control | Simulator + físico | Navegación libre entre ambos botones y salida a Clientes/Login. | Owner |
| 2.1.4 | N/A | No hay atajos de un solo carácter. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.2.1 | N/A | La pantalla no impone límite temporal. | Pasa | Inspección | Código | N/A motivado; el diálogo biométrico es del sistema. | Impl. |
| 2.2.2 | N/A | No hay movimiento o actualización automática persistente. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.3.1 | Aplicable | La pantalla no debe producir destellos. | Pasa | Inspección visual | Previews + runtime | No hay contenido intermitente o animación con destellos. | Owner + Impl. |
| 2.4.1 | Aplicable | La estructura debe facilitar el acceso al contenido. | Pasa | VoiceOver | Runtime | Cinco/seis paradas alcanzan contexto, estado, acciones y error. | Owner |
| 2.4.2 | Aplicable | La pantalla debe comunicar título y estado. | Pasa | VoiceOver | Runtime | «Sesión, encabezamiento» y «Sesión bloqueada». | Owner |
| 2.4.3 | Aplicable | El foco debe seguir una secuencia comprensible. | Limitado | VoiceOver + FKA + Switch Control | iPhone 11/14 | Orden normal correcto; tras cancelación se anuncia el error completo, pero el foco final nativo varía. | Owner + Impl. |
| 2.4.4 | Aplicable | Cada acción debe ser comprensible por nombre y contexto. | Pasa | VoiceOver + inspección | Runtime + localización | Acceso biométrico y salida a email son inequívocos; copy corto cubierto estáticamente. | Owner + Impl. |
| 2.4.5 | N/A | No existe una colección extensa que requiera varias vías. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 2.4.6 | Aplicable | Encabezados y labels deben describir propósito. | Pasa | VoiceOver | Runtime | Título, estado, explicación y acciones tienen nombres descriptivos. | Owner |
| 2.4.7 | Aplicable | El foco de teclado debe ser visible. | Pasa | FKA + Switch Control | Simulator + físico | Marco/resaltado visible sobre ambos botones. | Owner |
| 2.4.11 | Aplicable | El control enfocado no debe quedar totalmente oculto. | Pasa | FKA + Switch Control | Simulator + físico | Ambos botones permanecen visibles. | Owner |
| 2.5.1 | N/A | No hay gestos multipunto o de trayectoria. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.2 | Aplicable | La activación debe conservar cancelación y no duplicarse. | Pasa | Touch + Voice Control | Físico | Face ID se abre una vez; Cancelar responde; cada botón navega una sola vez. | Owner |
| 2.5.3 | Aplicable | El nombre accesible debe contener el texto visible. | Limitado | Voice Control + localización | Runtime + estático | «Tocar Acceder» y fallback largo pasan. El copy corto está cubierto por input label/localización, pero no fue visible en runtime. | Owner + Impl. |
| 2.5.4 | N/A | No hay activación por movimiento del dispositivo. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.7 | N/A | No hay interacción de arrastre. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 2.5.8 | Aplicable | Política del proyecto: superficie operable mínima 44×44 pt. | Pasa | Touch centro/extremos | iPhone físico | CTA primario ~49 pt; ambos botones responden en centro/extremos una vez. El fallback sin fondo navegó siempre a Login. | Owner + Impl. |
| 3.1.1 | Aplicable | El contenido debe exponerse en español correcto. | Pasa | VoiceOver | Runtime ES | Locución y copy esperado, incluida la cancelación biométrica. | Owner |
| 3.1.2 | N/A | No hay cambios de idioma dentro del contenido. | Pasa | Inspección | Localización | N/A motivado. | Impl. |
| 3.2.1 | Aplicable | Recibir foco no debe cambiar contexto. | Pasa | VoiceOver + FKA | Runtime | Recorrer no activa biometría ni navegación. | Owner |
| 3.2.2 | N/A | No hay entrada editable en Session. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 3.2.3 | Aplicable | La navegación repetida debe conservar patrón. | Pasa | Recorridos repetidos | iPhone 11/14 | Orden y acciones estables; variación post-error limitada en 2.4.3. | Owner |
| 3.2.4 | Aplicable | Acciones equivalentes deben identificarse coherentemente. | Pasa | Revisión visual/semántica | Login + Session | CTA primario compartido; acciones de texto sin iconos. | Owner + Impl. |
| 3.2.6 | N/A | No existe mecanismo de ayuda repetido. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 3.3.1 | Aplicable | El fallo biométrico debe identificarse en texto. | Pasa | VoiceOver | Cancelación biométrica | «El desbloqueo biométrico se ha cancelado» aparece y se anuncia completo una vez. | Owner |
| 3.3.2 | N/A | No hay campos editables que requieran instrucciones. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 3.3.3 | N/A | No existe entrada editable que corregir. | Pasa | Inspección | Código | N/A motivado. | Impl. |
| 3.3.4 | Aplicable | La salida de sesión debe ser identificable y deliberada. | Pasa | Touch + VoiceOver | iPhone físico | Estilo destructivo y nombre explícito; centro/extremos navegan exactamente una vez a Login. | Owner |
| 3.3.7 | N/A | Session no solicita datos ya introducidos. | Pasa | Inspección | Flujo | N/A motivado. | Impl. |
| 3.3.8 | Aplicable | La biometría requiere alternativa accesible reconocible. | Pasa | Face ID + fallback | Físico + Simulator | Biometría nativa y «Salir y acceder con email» permanecen disponibles y operables. | Owner |
| 4.1.2 | Aplicable | Controles deben exponer nombre, rol y estado. | Pasa | VoiceOver + Voice Control | Runtime | Ambos botones conservan rol, nombre largo y estado enabled/disabled. | Owner |
| 4.1.3 | Aplicable | Los mensajes importantes deben anunciarse sin mover foco innecesariamente. | Pasa | VoiceOver | iPhone 11/14 | Una locución completa por fallo antes del foco nativo; sin corte, duplicación ni destino forzado. | Owner |

## Puerta

- Matriz completa: 55/55 criterios clasificados para Login y 55/55 para Session; no quedan filas `Pendiente`.
- Los resultados `Limitado` son explícitos y aceptados: AutoFill sin Associated Domains; recreación visible → secure;
  reactivación con nodo dinámico de error; foco nativo postbiometría; y variante corta del fallback no observada en
  runtime.
- Build, diagnósticos, previews, focales, suite completa y validación manual aplicable están completados. La auditoría
  iOS final pasó sin P0–P3; la auditoría AX fresca certificó la corrección de contraste y su P3 documental quedó
  reconciliado con la build final de 13,424 s. No quedan hallazgos abiertos.
- PLU-28 queda `Done` tras el rebase merge de la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4) en `e8eca5a`.
  El merge conservó el árbol validado; el checkpoint posterior es solo documental y Xcode MCP es `N/A` razonado.
- Las dos `Section` de Login deben continuar separadas para Switch Control. El modificador compartido debe seguir
  preservando enabled/disabled y contraste; ambos riesgos están acreditados en el estado evaluado.
