# 07.7 — Catálogo español existente

Fecha: 2026-09-08. Issue: [PLU-32](https://linear.app/plusprojects/issue/PLU-32/077-complete-the-existing-spanish-localization-catalog).
Rama: `codex/plu-32-077-spanish-localization`. Base: `601517d`.

## Alcance y autoridad

El propietario aprobó la propuesta tras revisión independiente preimplementación. El único P1 de aquella revisión
concretó la configuración no-live de tests/snippets y quedó cerrado antes del cambio. Linear se reautenticó y se
verificaron PLU-25 In Progress, los seis hijos anteriores Done y la ausencia de otro issue de 07.7.

Se elimina exclusivamente `bootstrap.welcome.title`, que describía una bienvenida temporal sin consumidor.
Las otras 68 entradas, valores, comentarios y metadatos son idénticos a HEAD; ningún Swift, View, preview, asset,
configuración de producto ni comportamiento cambia. El español sigue siendo el único idioma (`es`, regiones `es/Base`).
No se añaden idiomas, plurales, rutas, pantallas ni abstracciones.

Los archivos de producto y referencias principales son
[Localizable.xcstrings](../../../FranAlonso/Resources/Localizable.xcstrings),
[AppShellScreen](../../../FranAlonso/App/AppShellScreen.swift),
[AuthenticationRootScreen](../../../FranAlonso/App/AuthenticationRootScreen.swift),
[LoginContent](../../../FranAlonso/Features/Authentication/Presentation/Views/LoginContent.swift),
[SessionContent](../../../FranAlonso/Features/Authentication/Presentation/Views/SessionContent.swift) y
[ClientListContent](../../../FranAlonso/Features/Clients/Presentation/Views/ClientListContent.swift).

## Comprobaciones actuales del catálogo

| Grupo | Claves | Resultado |
|---|---:|---|
| app.shell | 6 | Consumidas; español translated, valor y comentario presentes |
| authentication.login | 15 | Consumidas; español translated, valor y comentario presentes |
| authentication.session | 25 | Consumidas; español translated, valor y comentario presentes |
| authentication.bootstrap | 3 | Consumidas; español translated, valor y comentario presentes |
| authentication.root | 13 | Consumidas; español translated, valor y comentario presentes |
| clients.list | 6 | Consumidas; español translated, valor y comentario presentes |

La comparación estructural contra HEAD confirma que solo desaparece la clave huérfana. La búsqueda por claves y
símbolos generados en los Swift de la aplicación encuentra consumidor para las 68 restantes. No se encontró copy
estático visible fuera del catálogo en los constructores SwiftUI revisados. `ClientRow` representa nombres de usuario,
que son datos y no copy traducible.

Los placeholders visuales siguen siendo `nombre@ejemplo.com` e `Introduce tu contraseña`, con labels persistentes
Email y Contraseña. Login resuelve el prompt de email con el locale de entorno; Session hace lo propio con el motivo
biométrico y sus anuncios. Los casos de interpolación, plurales, sustituciones y formatos son `N/A`: no existen en las
cadenas consumidas actuales. No se han creado ejemplos artificiales para acreditar esos casos.

La lectura offline con plistlib de `es.lproj/Localizable.strings` demuestra igualdad exacta de claves y valores con el
catálogo fuente en los bundles recién compilados:

| Bundle | Claves/valores | Nombre de aplicación |
|---|---|---|
| Debug-Develop-iphoneos | 68/68; sin faltantes ni extras | Fran DEV |
| Debug-Develop-iphonesimulator | 68/68; sin faltantes ni extras | Fran DEV |
| Debug-Production-iphoneos | 68/68; sin faltantes ni extras | Fran Alonso |

Se inspeccionó también `InfoPlist.xcstrings`, sin editarlo. En los tres bundles, `es.lproj/InfoPlist.strings` contiene
solo `NSFaceIDUsageDescription`; CFBundleDisplayName y CFBundleName, todavía new en la fuente, no se emiten como
overrides localizados. La observación preventiva sobre el nombre queda resuelta para estos bundles: la distinción
Develop/Production se conserva. No se cambia mecánicamente su estado ni el copy Face ID aprobado.

## Validación Xcode MCP y aislamiento

- Xcode 26.6 (`17F113`, ProductBuildVersion y DTXcodeBuild de los bundles), SDK iOS 26.5, Swift toolchain 6.3.3
  y modo Swift 6.0; target iOS 26.0. El DTXcodeBuild del propio host Xcode no identifica su versión distribuida.
- Build Debug-Develop/iPhoneOS correcto en 13,309 s; sin diagnósticos Swift/Clang ni incidencias en Issue Navigator.
- `AuthenticationPresentationLocalizationTests`: 18/18 pasan, cero fallos, omitidos o no ejecutados.
  Cuatro declaraciones descubiertas mediante GetTestList, incluidos sus casos parametrizados; scheme/plan FranAlonso-Develop,
  destino iPhone 17e Simulator/iOS 26.5.
- Build Debug-Production/iPhoneOS correcto en 31,459 s; sin diagnósticos Swift/Clang ni incidencias en Issue Navigator.
- RED/GREEN nuevo `N/A`: retirada de un recurso sin consumidor, sin comportamiento nuevo. No se añaden tests
  que reproduzcan el JSON ni aserciones sobre un conteo fijo de claves.
- No se repite la suite completa: la regresión focal cubre los mappings afectados por la infraestructura de
  localización. Las cifras históricas de 07.6 no se presentan como una ejecución de 07.7.
- Swift diagnostics por archivo `N/A`: ningún Swift cambia. Los builds y su codegen compilan los consumidores.
- Production se limita a build y lectura offline; no se ejecutaron su aplicación, host de tests ni snippets.

Los dos logs completos contienen un aviso de `appintentsmetadataprocessor`:
`Metadata extraction skipped. No AppIntents.framework dependency found.` Aparece en la línea 3721 del log Develop
y la 6889 del log Production. GetBuildLog filtrado por warning no lo enumeró, pero los archivos completos sí lo
conservan. Por tanto, no se acredita un build absolutamente libre de warnings. La auditoría detectó y corrigió esa
imprecisión documental.

El diagnóstico posterior encuentra el mismo aviso antes de 07.7: el artefacto local
`Logs/Build/3A46DAE5-A2CE-4F64-92F9-6D0D7AF8DB94.xcactivitylog` de DerivedData registra el texto exacto el
2026-08-30 a las 12:32:20.019. La puerta entregada de [07.1](07-1-color-tokens.md), líneas 584–585, ya lo clasifica
como tooling de Xcode en `074ce5e`; el [histórico 06.1–06.3](../../progress/phases-00-06.md), líneas 85–87,
también separa este aviso de los diagnósticos Swift/Clang y los issues estructurados.

`ExtractAppIntentsMetadata` se ejecuta sin dependencia AppIntents; no existen imports ni consumidores AppIntent,
AppShortcuts o AppEntity en la aplicación. La retirada de una clave sin consumidor no modifica ese pipeline. Se
conserva la clasificación histórica para este aviso exacto, sin conceder una excepción general ni presentar el log
como libre de warnings. No se añade una dependencia sin consumidor ni se suprime el diagnóstico: el xcspec instalado
expone `LM_FILTER_WARNINGS` como `--quiet-warnings`, que solo ocultaría la señal. No se cambia configuración.
La revisión iOS focal final confirma esta evaluación sin hallazgos P0–P3: el gate técnico del alcance 07.7 pasa.

Antes de los tests se capturó el scheme original y se comprobó en disco la identidad Develop, condición
FRANALONSO_AUTH_FIXTURE, TestAction Debug-Develop y herencia de argumentos de Run. El editor de schemes de Xcode
conservaba los cinco argumentos desactivados pese a un cambio externo; se activó allí explícitamente solo
`--franalonso-auth-fixture-signed-out` y se verificó el archivo guardado antes de iniciar el host.
La selección visible y GetTestList confirmaron Develop; la resolución de esa intención recorre la fixture aprobada,
previa a Firebase y al almacén durable. Tras los tests, los cinco argumentos volvieron a NO mediante Xcode y
`cmp` confirmó que el scheme recuperó exactamente sus bytes originales.

No se ejecutó RunCodeSnippet: se utilizó la alternativa offline aprobada. Esta evidencia demuestra el recurso
compilado, no una resolución Foundation nueva de cada una de las 68 cadenas en runtime. Las pruebas de mapping
comprueban error → recurso estable, no sustituyen esa distinción.

Tras desbloquear el Mac, se restaura la selección original FranAlonso-Develop / iPhone 11 y se verifica en la barra
de Xcode. No se ejecuta la app; el control Stop permanece desactivado. `cmp` confirma de nuevo los bytes originales
del scheme y sus cinco argumentos NO. El pendiente operativo de restauración queda resuelto.

Artefactos locales de Xcode (sesión 2026-09-08, directorio ActionArtifacts):

- BuildProject/BuildProject-Log-20260908-092639.txt — Develop.
- RunSomeTests/E348BF68-4C82-4803-B40A-5A11006AC506.txt — 18 resultados.
- BuildProject/BuildProject-Log-20260908-093747.txt — Production.
- GetBuildLog/3744BF63-5FA5-4F7A-90B8-D51E763D1D22.txt — warnings Develop.
- GetBuildLog/3D1A00FC-74F6-4BA1-8297-930EDB07B4AD.txt — warnings Production.

## Truncamiento, RTL y evidencia por pantalla

La equivalencia de todos los recursos consumidos y Swift permite reutilizar las matrices anteriores. La retirada
no cambia una superficie accesible. La repetición de previews, Inspector y tecnologías de asistencia para el delta
es `N/A: sin alcance SwiftUI`, según el límite de
[franalonso-review-accessibility](../../../.agents/skills/franalonso-review-accessibility/SKILL.md).
No se atribuye una ejecución visual/manual nueva a 07.7. La cobertura exacta heredada es:

| Pantalla/flujo | Evidencia conservada | Límites |
|---|---|---|
| Login, Session y FormFieldSection | [07.2](07-2-reusable-controls.md): cuatro apariencias, Large/XXX Large/AX 5, portrait/landscape y LTR/RTL en previews; registros por criterio y tecnología | No es una matriz runtime de cada combinación ni prueba de traducción RTL |
| Login iPad | [07.3](07-3-state-views.md): iPad Simulator AX 5, cuatro orientaciones y ventana mínima; scroll conserva Email, Contraseña, ojo y Acceder | VoiceOver iPad no ejecutado |
| Clientes, raíz y bootstrap | [07.3](07-3-state-views.md): cuatro apariencias y tres tamaños en previews; AX 5 iPad full-screen/RTL; runtime de error Clientes, Retry y bootstrap en ventana mínima | Loading estable conserva A/L; no se convierte en Pasa |
| Shell y cinco secciones | [07.6](07-6-app-shell.md): iPhone 17e/iOS 26.5 Large/XXX Large/AX 5 portrait; iPad mini/iPadOS 26.5 AX 5 portrait/landscape; cuatro apariencias y RTL sintético | No se duplicaron previews iPad Large/XXX Large; sus comprobaciones runtime siguen separadas |
| Shell iPad/ventana/preferencias | [07.6](07-6-app-shell.md): cuatro orientaciones, ventana mínima, foco FKA y scroll horizontal nativo de tabs; Light/Dark con Increase Contrast, Reduce Transparency y Differentiate Without Color simultáneos | La combinación no equivale a tres pasadas aisladas ni medición numérica |
| Idioma y nombres operables | Registros 3.1.1, 2.5.3 y 4.1.2 de [07.2](07-2-reusable-controls.md), [07.3](07-3-state-views.md), [07.6](07-6-app-shell.md) | 3.1.2 sigue N/A; no se afirma pronunciación árabe/hebrea ni VoiceOver iPad nuevo |

Los registros completos de los 55 criterios A/AA y de cada flujo permanecen en esas evidencias. Para el delta no
hay criterios con nueva aplicabilidad: no cambia texto expuesto, rol, valor, estado, acción, foco, geometría ni color.
No se reemplazan las matrices históricas con un pase global de 07.7.

Se mantienen explícitos los límites de 07.2: AutoFill sin Associated Domains, reemplazo nativo al volver a SecureField,
foco al reactivar error/tras biometría y fallback corto «Salir» no observado en runtime. También se conservan loading
A/L y ausencia de VoiceOver iPad de 07.3. La orientación histórica Pasa de 07.2 queda superada en iPhone por
[ADR 0026](../../ADRs/0026-iphone-portrait-only-product-exception.md): `No pasa — excepción de producto aceptada`.

Los controles con `lineLimit(1)`, las variantes cortas de Session y los iconos direccionales conservan sus consumidores
y textos. La evidencia RTL es inversión sintética del layout español. No prueba una localización RTL lingüística,
texto bidireccional completo ni traducciones nuevas. Convertir un límite anterior en Pasa necesitaría evidencia
adicional y no forma parte de esta retirada de clave.

## Inventario de consumidores

Los nombres de archivo y líneas siguientes corresponden al árbol actual, cuyo Swift coincide con la base `601517d`.
Incluyen usos en previews deterministas cuando comparten la misma clave. Cada clave conserva además consumidor de
producto, no únicamente preview.

| Clave | Consumidores Swift |
|---|---|
| `app.shell.tab.catalog` | `AppShellScreen.swift:49`, `AppShellScreen.swift:54` |
| `app.shell.tab.clients` | `AppShellScreen.swift:36` |
| `app.shell.tab.history` | `AppShellScreen.swift:25`, `AppShellScreen.swift:30` |
| `app.shell.tab.reports` | `AppShellScreen.swift:60`, `AppShellScreen.swift:65` |
| `app.shell.tab.workday` | `AppShellScreen.swift:14`, `AppShellScreen.swift:19` |
| `app.shell.unavailable.message` | `AppShellScreen.swift:81` |
| `authentication.login.email.label` | `FormFieldSection.swift:57`, `FormFieldSection.swift:60`, `FormFieldSection.swift:71`, `FormFieldSection.swift:74`, `LoginContent.swift:26`, `LoginContent.swift:30`, `LoginContent.swift:39`, `LoginContent.swift:40` |
| `authentication.login.email.prompt` | `LoginContent.swift:136` |
| `authentication.login.error.configuration` | `LoginContent.swift:244` |
| `authentication.login.error.credentials-rejected` | `LoginContent.swift:240` |
| `authentication.login.error.secure-storage` | `LoginContent.swift:246` |
| `authentication.login.error.temporarily-unavailable` | `LoginContent.swift:242` |
| `authentication.login.error.unexpected` | `LoginContent.swift:248` |
| `authentication.login.password.hide` | `LoginContent.swift:143` |
| `authentication.login.password.label` | `LoginContent.swift:53`, `LoginContent.swift:160`, `LoginContent.swift:172`, `LoginContent.swift:187`, `LoginContent.swift:188` |
| `authentication.login.password.prompt` | `LoginContent.swift:162`, `LoginContent.swift:174` |
| `authentication.login.password.show` | `LoginContent.swift:144` |
| `authentication.login.signing-in` | `LoginContent.swift:99` |
| `authentication.login.submit` | `LoginContent.swift:76` |
| `authentication.login.succeeded` | `LoginContent.swift:103` |
| `authentication.login.title` | `LoginScreen.swift:22` |
| `authentication.session.biometric.reason` | `SessionScreen.swift:42` |
| `authentication.session.biometric.unavailable` | `SessionContent.swift:64` |
| `authentication.session.biometric.unlock` | `SessionContent.swift:85`, `SessionContent.swift:88` |
| `authentication.session.biometric.unlock.short` | `SessionContent.swift:79`, `SessionContent.swift:87` |
| `authentication.session.checking` | `SessionContent.swift:29` |
| `authentication.session.email-fallback` | `SessionContent.swift:119`, `SessionContent.swift:129`, `SessionContent.swift:131` |
| `authentication.session.email-fallback.short` | `SessionContent.swift:122`, `SessionContent.swift:132` |
| `authentication.session.error.biometric-cancelled` | `SessionContent.swift:290` |
| `authentication.session.error.biometric-denied` | `SessionContent.swift:288` |
| `authentication.session.error.biometric-unavailable` | `SessionContent.swift:292` |
| `authentication.session.error.configuration` | `SessionContent.swift:296` |
| `authentication.session.error.observation-ended` | `SessionContent.swift:278` |
| `authentication.session.error.secure-storage` | `SessionContent.swift:298` |
| `authentication.session.error.temporarily-unavailable` | `SessionContent.swift:294` |
| `authentication.session.error.unexpected` | `SessionContent.swift:300` |
| `authentication.session.locked.message` | `SessionContent.swift:55` |
| `authentication.session.locked.title` | `SessionContent.swift:48` |
| `authentication.session.observation-error.title` | `SessionContent.swift:152` |
| `authentication.session.signed-out.message` | `SessionContent.swift:41` |
| `authentication.session.signed-out.title` | `SessionContent.swift:36` |
| `authentication.session.signing-out` | `SessionContent.swift:102` |
| `authentication.session.title` | `SessionScreen.swift:24` |
| `authentication.session.unlocked.message` | `SessionContent.swift:145` |
| `authentication.session.unlocked.title` | `SessionContent.swift:140` |
| `authentication.session.unlocking` | `SessionContent.swift:98` |
| `authentication.bootstrap.failed.message` | `FranAlonsoApp.swift:81` |
| `authentication.bootstrap.failed.title` | `FranAlonsoApp.swift:79` |
| `authentication.bootstrap.preparing` | `FranAlonsoApp.swift:53`, `FranAlonsoApp.swift:64`, `FranAlonsoApp.swift:71` |
| `authentication.root.access-denied.title` | `AuthenticationRootScreen.swift:61` |
| `authentication.root.authorizing-local-access` | `AuthenticationRootScreen.swift:56` |
| `authentication.root.checking-session` | `AuthenticationRootScreen.swift:47` |
| `authentication.root.error.different-principal` | `AuthenticationRootScreen.swift:106` |
| `authentication.root.error.local-store-not-pristine` | `AuthenticationRootScreen.swift:108` |
| `authentication.root.error.local-store-unavailable` | `AuthenticationRootScreen.swift:112` |
| `authentication.root.error.secure-storage` | `AuthenticationRootScreen.swift:110` |
| `authentication.root.error.unexpected` | `AuthenticationRootScreen.swift:114` |
| `authentication.root.observation-failed.message` | `AuthenticationRootScreen.swift:83`, `UnavailableStateView.swift:64`, `UnavailableStateView.swift:76` |
| `authentication.root.observation-failed.title` | `AuthenticationRootScreen.swift:81`, `UnavailableStateView.swift:62`, `UnavailableStateView.swift:74` |
| `authentication.root.retry` | `AuthenticationRootScreen.swift:88`, `UnavailableStateView.swift:67`, `UnavailableStateView.swift:79` |
| `authentication.root.sign-out` | `AppShellScreen.swift:97`, `AuthenticationRootScreen.swift:68` |
| `authentication.root.signing-out` | `AuthenticationRootScreen.swift:78` |
| `clients.list.empty.message` | `UnavailableStateView.swift:56`, `ClientListContent.swift:17` |
| `clients.list.empty.title` | `UnavailableStateView.swift:54`, `ClientListContent.swift:15` |
| `clients.list.error.message` | `ClientListContent.swift:27` |
| `clients.list.error.title` | `ClientListContent.swift:25` |
| `clients.list.loading` | `LoadingStateView.swift:15`, `LoadingStateView.swift:19`, `ClientListContent.swift:12` |
| `clients.list.title` | `ClientListScreen.swift:11` |

## Auditorías y entrega

La auditoría independiente de accesibilidad devuelve Sin hallazgos P0–P3 y `N/A: sin alcance SwiftUI`. Verifica el
inventario y la reutilización exacta de los registros de 55 criterios, sin atribuir previews ni ejecución manual nueva.

La auditoría iOS encuentra un P2 de evidencia de warnings y un P3 de versión Xcode; ambas descripciones se corrigen.
La repetición focal cierra P2/P3 sin hallazgos nuevos: pasa la revisión documental, con los pendientes de calidad y
operación intactos. Ninguna de las dos auditorías detecta un defecto nuevo de producto.
Los dos agentes independientes operaron con prohibición explícita de escritura y publicación, sin sandbox impuesto.
El orquestador comprobó huellas pre/post idénticas de los 417 archivos tracked y untracked no ignorados:
`959f54e522dfd4244f1e2fa1586fd78bdd813acd62b118349236c2752b7eb29d`.
La repetición iOS conserva 417 archivos y huella pre/post
`ae1b2ce51c87c6eac51bc9f882bd1b66d5452377c5beb99a5825c4f82f4dd6ad`, antes de registrar este resultado.

Gobernanza, enlaces documentales locales y `git diff --check` pasan. La selección original de Xcode ya está restaurada.
El aviso App Intents queda diagnosticado como tooling preexistente, con clasificación entregada en 07.1.
La revisión iOS final pasa sin P0–P3 y el
orquestador verifica 417 archivos con huellas pre/post idénticas:
`4a0676efdcfb75e4ca75ffc0b515182f8f362045d57bf63ae3a6232b037bb97e`, antes de registrar este resultado.
Se conserva el aviso explícito y no se declara un log con cero warnings.
El owner autoriza commit/push del checkpoint 07.7 en su rama. La validación de esta sesión se reutiliza sin repetir
builds/tests: el recurso de producto permanece idéntico al auditado y solo se actualiza el registro de entrega.
PLU-25 y PLU-32 permanecen In Progress; PR, merge, Done e implementación de 08.1 conservan puertas separadas.
