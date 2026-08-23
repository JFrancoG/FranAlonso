# Phase 07 Progress

Última actualización: 2026-08-23

## Estado

| Subfase | Linear | Estado | Autoridad |
|---|---|---|---|
| 07.1 — tokens visuales y nombres semánticos | PLU-26 | `Done` | Entregada en `074ce5e` |
| 07.1a — fixtures Develop no-live | PLU-27 | `Done` | ADR 0023/0024; entregada en `074ce5e` |
| 07.2 — controles reutilizables | PLU-28 | `In Progress` | Commit, push y PR autorizados; merge/Done separados |
| Fase 07 | PLU-25 | `In Progress` | Continúa después de 07.2 |

La base aprobada al iniciar 07.2 fue `main == origin/main == 074ce5e`, con worktree limpio. El estado actual contiene
solo la implementación y documentación autorizadas de PLU-28. El owner autorizó commit, push y PR; merge, cambio a
`Done` y cierre de Linear continúan siendo puertas separadas.

## Decisiones vigentes

- ADR 0022 fija el objetivo interno de accesibilidad nativa basado en WCAG 2.2 A/AA aplicable, WCAG2ICT, convenciones
  Apple y runtime iOS. No declara certificación ni conformidad legal.
- ADR 0023/0024 mantienen las fixtures exclusivamente en `Debug-Develop`, cortadas antes de Firebase y sin datos
  persistentes o actividad live.
- 07.2 no requiere ADR nuevo: extrae composición SwiftUI nativa y aplica refinamientos visuales aprobados sin cambiar
  arquitectura, navegación, contratos de datos ni comportamiento live.
- Fila compartida y tarjeta quedan diferidas: no existe un segundo consumidor demostrado. `ClientRow`, tarjetas,
  formatters, validators y 07.3/07.4 permanecen fuera de alcance.
- Toda View conserva el límite declarativo: representa estado y envía intenciones; la lógica pertenece al ViewModel o
  a tipos de Presentation puros cuando no depende de la interfaz.

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

- Implementación, build, previews, focales, suite completa y validación manual aplicable: completados.
- TDD visual: `N/A` razonado; lógica accesible extraída: GREEN con Swift Testing.
- Sin blockers ni hallazgos abiertos. La auditoría iOS pasó sin P0–P3; la auditoría AX fresca certificó el contraste
  corregido y su único P3 documental quedó reconciliado con la build final de 13,424 s.
- Entregar mediante rama y PR; no declarar 07.2/PLU-28 `Done`, hacer merge ni cerrar Linear sin autorización separada.
