# Phase 07 Progress

## Estado

- Fase: 07 — Design system, localización y navegación.
- 07.1 — tokens visuales y nombres semánticos (PLU-26): entrega publicada en `5284ef1`; cierre en espera de la fixture
  de autenticación no-live de PLU-27 y su último gate de teclado.
- 07.1a — fixture de autenticación no-live (PLU-27): ADR 0023 y suplemento ejecutable aprobados; implementación y
  validación automática completas, ambos recorridos físicos pasan y Full Keyboard Access de sesión/Clientes queda
  limitado por ausencia de teclado externo.
- 07.2 — componentes reutilizables (PLU-28): preflight completado y aclaración de fila/tarjeta `N/A` aprobada; código
  ejecutable y validación runtime bloqueados por PLU-27; solo puede continuar su preflight read-only.

## Evidencia

### 2026-08-21 — Preflight de PLU-27 y ADR 0023 propuesto

- Se compararon Firebase Auth Emulator, un adaptador determinista Data, inyección directa de previews y un usuario live.
  Para este gate de UI/accesibilidad se propone el adaptador: el Emulator exigiría proceso y red local en dispositivo,
  seed y aislamiento adicional; un proyecto real tampoco impide que productos no emulados contacten recursos live.
- La fixture propuesta se compila solo en el target `Debug-Develop` mediante `FRANALONSO_AUTH_FIXTURE` y exige además
  entorno/bundle Develop más exactamente un argumento de lanzamiento. `Release-Develop` y ambas configuraciones
  Production quedan excluidas; argumentos ausentes, desconocidos o conflictivos mantienen la ruta normal.
- El plan de arranque se resuelve antes del bootstrap. En fixture, `AppDelegate` no llama a `configureFirebase()` y la
  composición no crea `AppRuntime`, Firebase Auth, telemetría Firebase, factories remotas ni sync engines. Usa
  `ModelContainer` en memoria, dependencias locales, telemetría nula y shell vacío.
- `DevelopAuthenticationDataSource` preservará el contrato y la cadena reales hasta `AuthenticationRootViewModel`.
  Ofrecerá modos signed-out y sesión restaurada, transiciones ordenadas, observadores independientes y una credencial
  sintética. El authorizer aceptará solo el UID exacto y rechazará cualquier otro con `.differentPrincipal`; la
  biometría seguirá siendo LocalAuthentication real y no se construirá Keychain.
- La revisión exige tests de corte cero antes de Firebase/telemetría/factories, matriz de compilación, lifecycle de cada
  stream y la cadena end-to-end: login más stream coincidente, sesión restaurada bloqueada, logout pendiente hasta
  `nil`, credencial errónea sin mutación y rechazo de UID distinto.
- ADR 0023 documentó como `Propuesto` alcance, amenazas, triple puerta, validación y rollback; su aceptación posterior
  no habilita proveedor, usuarios, lecturas/escrituras live, Associated Domains ni motores de sincronización.
- La plataforma asignó permisos de escritura al agente revisor a pesar de su rol read-only. El agente no escribió y el
  diff permaneció idéntico, pero la exigencia de revisión técnicamente read-only no puede darse por satisfecha sin una
  decisión explícita de gobernanza o soporte de sandbox.
- El propietario aceptó ADR 0023 y el fallback operacional el 21 de agosto de 2026: un agente fresco puede revisar sin
  sandbox impuesto solo con prohibición explícita de escritura/publicación y una huella determinista idéntica de todos
  los archivos Git tracked y untracked no ignorados antes/después. Cualquier cambio invalida la revisión.
- La primera repetición operacional cubrió 394 archivos y conservó exactamente las huellas de estado
  `15afb584b5fdf5515913507be58078dbf4e37322c2db17bcb3613fbf069e033e` y de contenido
  `003551a2d3404239818e701916f9c0ef6429643f3729b68d1787245916669693`. Su gate fue `correct before proceeding`: pidió
  probar la exclusión binaria completa, congelar constantes/inventario, demostrar las 28 tablas vacías y unificar el
  bloqueo de PLU-28. Los hallazgos se incorporan en el suplemento siguiente antes de repetir la auditoría.
- La segunda pasada conservó las huellas `15afb584b5fdf5515913507be58078dbf4e37322c2db17bcb3613fbf069e033e`
  y `c4223975cb0be13ac972d0d6bab898579e0cfd5cbb397a11cb8638efa1052560`; confirmó todos los requisitos y detectó solo
  una frase condicional residual sobre PLU-28. Tras corregirla, un tercer agente fresco devolvió `Sin hallazgos` y
  `PASS`; sus huellas pre/post coinciden exactamente en estado
  `15afb584b5fdf5515913507be58078dbf4e37322c2db17bcb3613fbf069e033e`, contenido
  `8f8ad6bf210e32e7aab2ca151024583ce8426dd3735ac1e6072dd767264f66b0` y 394 archivos.

### Suplemento ejecutable exacto de PLU-27 — aprobado e implementado

#### Constantes y autoridad de arranque

- Argumentos exactos: `--franalonso-auth-fixture-signed-out` y
  `--franalonso-auth-fixture-restored-session`; ambos desactivados por defecto y presentes solo en `LaunchAction` de
  `FranAlonso-Develop`.
- UID fijo: `fixture-auth-principal-v1`. Credencial sintética no secreta: email
  `accessibility@franalonso.invalid` y contraseña `FranAlonso-Fixture-Only`.
- La puerta runtime compara exactamente `AppEnvironment == "develop"` desde Info.plist y
  `Bundle.main.bundleIdentifier == "com.plusprojects.FranAlonso.develop"`; no usa el `AppEnvironment` de SwiftUI.
- `ApplicationLaunchPlan.current` es la única decisión inmutable del proceso y la comparten `AppDelegate` y
  `FranAlonsoApp`. Un resolver puro e inyectable cubre argumentos ausentes, desconocidos, duplicados o conflictivos.

#### Exclusión de compilación y composición

- `FRANALONSO_AUTH_FIXTURE` existe solo en las configuraciones de target app y tests `Debug-Develop`; no se define en
  proyecto, `Release-Develop`, `Debug-Production` ni `Release-Production`, conforme a
  [Active Compilation Conditions](https://developer.apple.com/documentation/xcode/build-settings-reference).
- `DevelopAuthenticationDataSource.swift` y `DevelopAuthenticationFixture.swift` quedan envueltos íntegramente en
  `#if FRANALONSO_AUTH_FIXTURE`. En `ApplicationLaunchPlan.swift`, `AppDelegate.swift`, `FranAlonsoApp.swift`,
  `ApplicationComposition.swift` y `AppDependencies.swift`, cada caso, constante y rama de fixture queda dentro del
  mismo guard; fuera de él solo compila la ruta live actual.
- `ApplicationComposition` selecciona antes de construir dependencias. Su seam inyectable separa `makeLive` y
  `makeFixture`; el test de fixture exige cero llamadas a configuración Firebase, fábrica live, Firebase Auth,
  Analytics, Crashlytics y las cuatro factories remotas. La ruta fixture no referencia ni crea `AppRuntime`.
- `AppDelegate` recibe la operación reemplazable de configuración solo para demostrar que fixture publica
  `fixtureReady` con cero llamadas; la ruta live sigue siendo la única que puede ejecutar `configureFirebase()`.

#### Inventario cerrado

- Crear producción: `FranAlonso/App/ApplicationLaunchPlan.swift`, `FranAlonso/App/ApplicationComposition.swift`,
  `FranAlonso/App/DevelopAuthenticationFixture.swift` y
  `FranAlonso/Features/Authentication/Data/Adapters/DevelopAuthenticationDataSource.swift`.
- Modificar producción/configuración: `FranAlonso/App/AppDelegate.swift`, `FranAlonso/App/FranAlonsoApp.swift`,
  `FranAlonso/App/AppDependencies.swift`, `FranAlonso.xcodeproj/project.pbxproj` y
  `FranAlonso.xcodeproj/xcshareddata/xcschemes/FranAlonso-Develop.xcscheme`.
- Crear tests: `FranAlonsoTests/ApplicationLaunchPlanTests.swift`,
  `FranAlonsoTests/DevelopAuthenticationDataSourceTests.swift` y
  `FranAlonsoTests/DevelopAuthenticationFixtureCompositionTests.swift`; los tests dependientes del símbolo quedan
  guardados por la misma condición.
- Modificar tests: `FranAlonsoTests/FirebaseBootstrapStateTests.swift`,
  `FranAlonsoTests/AppDependenciesTests.swift` y `FranAlonsoTests/BuildEnvironmentConfigurationTests.swift`.
- Permanecen sin cambios: Domain, Use Cases, Repository, ViewModels, Views, `AppRuntime`, adaptadores Firebase,
  `KeychainLocalPrincipalDataSource`, LocalAuthentication, esquema/migraciones SwiftData, xcconfig, plist Firebase,
  Info.plist, entitlements, localización, recursos, navegación y cualquier archivo de PLU-28.

#### Pruebas y evidencia obligatorias

- El test source-backed exige los guards completos de los dos archivos exclusivos y de todas las ramas compartidas;
  condición solo en app/tests `Debug-Develop`; argumentos exactos y desactivados en Develop; ausencia de argumentos,
  condición y símbolos de fixture en todas las configuraciones/actions Production y Release.
- El test de composición ejecuta `SwiftDataStorePristineDataSource.isPristine()` inmediatamente después de crear el
  container fixture y exige `true`, cubriendo las 28 tablas publicadas, no solo la lista visible de Clientes.
- La cadena end-to-end conserva los casos ya fijados por ADR 0023: orden sin coalescing, observadores independientes,
  cancelación/liberación, credencial incorrecta sin mutación, retorno de login más stream coincidente, sesión restaurada
  bloqueada sin `signIn`, logout pendiente hasta `nil` y rechazo `.differentPrincipal` para otro UID.
- Xcode MCP valida tests focales, suite completa y build sin warnings en `FranAlonso-Develop`, además de build y
  diagnósticos de `FranAlonso-Production`. La evidencia física sigue separada y posterior a la implementación.

### 2026-08-21 — Implementación automática de PLU-27

- El propietario aprobó expresamente el suplemento ejecutable y la implementación. Linear pasó PLU-27 de Backlog a
  `In Progress`; no se autorizó commit, push, PR, merge, cierre ni actividad Firebase live.
- RED: las pruebas nuevas fueron descubiertas por Xcode, pero `RunSomeTests` no pudo compilar porque aún no existían
  `ApplicationLaunchPlan`, `ApplicationComposition`, `DevelopAuthenticationFixture` ni
  `DevelopAuthenticationDataSource`. El build log confirmó únicamente esos contratos ausentes.
- GREEN inicial: los modos signed-out/restored, triple gate, credencial exacta, rechazo sin mutación, orden sin
  coalescing, observadores independientes, cancelación, UID exacto, 28 tablas vacías, cadena completa hasta root y
  corte previo a Firebase pasaron 23/23. `FranAlonso-Develop` compiló sin warnings y la suite pasó 812/812.
- La implementación decide una vez mediante `ApplicationLaunchPlan.current`. En fixture, `AppDelegate` publica
  `fixtureReady` sin ejecutar `configureFirebase`; `ApplicationComposition` no crea `AppRuntime`; usa SwiftData en
  memoria, repositorios locales reales, telemetría nula, LocalAuthentication real y shell sin seed de negocio.
- La primera auditoría iOS postimplementación conservó exactamente las huellas de estado
  `bfa83892ae6fcfd22190b408c718932ae6b8913d36970fb7b33820960d7e9728` y contenido
  `048ea89758c7359988a685589c006ea03bad1e87e977137303d8c12c284ff3fc` sobre 401 archivos. Detectó dos P1 y dos P2:
  seams auxiliares aún compilados en Production, Production todavía no informada al revisor, liberación incompleta en
  tests y Progress atrasado. Accesibilidad devolvió `N/A: sin alcance SwiftUI`, sin reclasificar evidencia runtime.
- Se guardaron también `AppDependencies.local`, la raíz directa de composición y su almacenamiento en App. La prueba
  source-backed exige ahora que cada seam compartido permanezca dentro de `FRANALONSO_AUTH_FIXTURE`.
- La cobertura de lifecycle añade abandono antes de iterar y `break` con liberación por fin de alcance, ambos con conteo
  cero y conservación de un observador independiente. La primera forma del test de `break` retenía deliberadamente el
  stream fuera de su alcance y falló; al modelar el fin real del consumidor, ambas pruebas pasan 2/2.
- GREEN corregido: 26/26 outcomes focales y 815/815 en la suite Develop; build Develop correcto y cero warnings. Tras
  endurecer el guard, el primer build Production detectó que `live(modelContainer:)` aún delegaba al seam excluido; se
  restauró su composición live directa y la repetición pasó sin warnings ni issues warning+.
- `git diff --check` y `scripts/governance/validate_governance.py` pasan. Xcode quedó restaurado en
  `FranAlonso-Develop`. No se ejecutó `xcodebuild`, no se activó Firebase Auth, no se creó usuario, no se leyó/escribió
  dato live y no se añadió payload de negocio.
- La reauditoría iOS detectó un test consumidor sin guard y el cierre documental desactualizado. Tras corregirlos,
  Production compiló el bundle de tests sin `FRANALONSO_AUTH_FIXTURE` y pasó 1/1; Develop conservó y pasó el test
  condicionado 1/1. La pasada final mantuvo huellas idénticas sobre 401 archivos, devolvió `Sin hallazgos` y gate `PASS`.
- La auditoría final posterior endureció la matriz negativa: el test enumera las doce configuraciones de proyecto, app
  y tests, y busca el token `FRANALONSO_AUTH_FIXTURE` dentro de cada bloque. Solo app/tests `Debug-Develop` lo permiten;
  también rechaza el token en `Develop.xcconfig` y `Production.xcconfig`, por lo que condiciones heredadas o valores
  compuestos en cualquier otra configuración hacen fallar la prueba. Los IDs extraídos del proyecto deben coincidir
  exactamente con la allowlist y cada bloque debe existir, por lo que una configuración añadida, eliminada o sustituida
  también rompe el gate.
- Validación posterior al endurecimiento: diagnóstico del archivo sin issues, test focal 1/1, suite Develop 815/815,
  build correcto en 6,08 s y cero issues warning+ mediante Xcode MCP. El test refuerza evidencia existente; no cambia
  comportamiento de producción y por ello el RED ejecutable es `N/A`.
- Reauditoría final: iOS y accesibilidad devuelven `Sin hallazgos P0–P3` con huellas operacionales pre/post idénticas
  sobre 401 archivos. El gate técnico de implementación es `PASS`; ADR 0022 permanece `LIMITADO` por las comprobaciones
  manuales enumeradas en Pendiente.
- Quedan los dos pases físicos: signed-out para Login/AutoFill y acceso autenticado/logout; restored-session para
  biometría, autorización, shell vacío y logout, junto con VoiceOver, Voice Control, Switch Control, teclado/foco y
  demás filas aplicables.

### 2026-08-21 — Validación física final y corrección Dynamic Type de PLU-27

- iPhone 11/iOS 26.6 ejecutó los dos modos Develop sin Firebase live. Signed-out autenticó con la credencial sintética,
  mostró Clientes vacío y logout regresó a Login. Restored-session mostró el bloqueo, Face ID desbloqueó hasta Clientes
  y tanto logout como el fallback de email regresaron a Login.
- Password AutoFill quedó validado con alcance limitado: el selector de Passwords apareció tras Face ID, rellenó ambos
  campos y permitió el acceso con la credencial correcta. Sin Associated Domains no se afirma sugerencia automática por
  dominio. La entrada temporal fue eliminada al terminar.
- VoiceOver, Voice Control y Switch Control con agrupación por defecto pasan en Login, sesión protegida, biometría,
  Clientes y logout; acciones y campos permanecen separados, con nombres y roles correctos.
- RED físico AX 5: `Sesión bloqueada` y el botón biométrico se truncaban en portrait. El propietario aprobó incorporar
  `SessionContent` al alcance correctivo de PLU-27. GREEN: textos multilínea, botón full-width y composición adaptativa
  pasan en iPhone 11 e iPhone 14, portrait/landscape y tamaño estándar/AX 5; el icono decorativo queda centrado y oculto
  del árbol accesible.
- Accessibility Inspector emitió un único warning genérico de Dynamic Type sobre el nodo informativo de biometría no
  disponible. El elemento resaltado escala, envuelve el texto completo y no presenta truncamiento ni solape en AX 5;
  se registra como no reproducido, sin supresión y sin convertirlo en pase general de Inspector.
- Xcode MCP final: `SessionContent.swift` sin diagnósticos, build Develop correcto, cero warnings/issues warning+ y
  815/815 outcomes. Previews con y sin biometría pasan en Large, XXX Large y AX 5, portrait/landscape y Dark + Increased
  Contrast. La corrección visual usa RED/GREEN manual porque el proyecto no permite UI tests nativos.
- Full Keyboard Access de sesión protegida y Clientes no pudo ejecutarse por ausencia de teclado externo; se conserva
  como `Limitado`. Login mantiene el pase previo con teclado hardware. Ambos argumentos de fixture quedaron desactivados.

### 2026-08-21 — Preflight y propuesta revisada de 07.2

- El preflight comenzó con Git limpio en `main == origin/main == 5284ef1`. Xcode MCP mantiene el esquema
  `FranAlonso-Develop`, cero issues warning+ y la última validación confiable del mismo commit: build correcto y
  788/788 outcomes. `GetTestList` enumera 616 declaraciones habilitadas; esa cifra no sustituye los outcomes
  parametrizados de la ejecución.
- Linear creó [PLU-27](https://linear.app/plusprojects/issue/PLU-27/071a-establish-non-live-auth-fixture) para la fixture
  no-live y [PLU-28](https://linear.app/plusprojects/issue/PLU-28/072-implement-demonstrated-reusable-buttons-and-fields)
  para 07.2. PLU-27 bloquea toda implementación y validación runtime de PLU-28; no bloquea su análisis read-only.
- El inventario real encuentra dos acciones primarias en Login/Session y dos estructuras `Section` + label + campo en
  Login. `ClientRow` tiene un único consumidor y no existe todavía una tarjeta de producto; la primera tarjeta prevista
  pertenece a Jornada.
- La propuesta mínima usa un `ViewModifier`/extensión para el estilo de acción primaria sin envolver `Button`, y un
  `FormFieldSection` limitado a una `Section`, un label visible y un único contenido. TextField/SecureField, bindings,
  validación, foco, submit, AutoFill, área operable, gestos y accesibilidad permanecen en `LoginContent`.
- No se crean filas/tarjetas compartidas, formatters ni validadores artificiales. TDD queda `N/A` solo para composición
  visual sin lógica; la validación exige tests de color focales, suite completa, previews, Inspector y repetición expresa
  de Switch Control agrupado, VoiceOver, Voice Control, Full Keyboard Access y área operable.
- El revisor iOS acepta en contenido `FormFieldSection`, el `ViewModifier`, la ausencia de tests ceremoniales y diferir
  `GroupBox` hasta un consumidor real. La aclaración de `docs/specs/07_design_system_navigation.md` ya está aprobada y
  aplicada. PLU-27 no impide el preflight read-only, pero bloquea toda implementación y validación runtime de 07.2.
- Archivos de producto propuestos tras resolver el gate: `PrimaryActionStyle.swift`, `FormFieldSection.swift`,
  `LoginContent.swift` y `SessionContent.swift`. Se excluyen Domain, Data, App, configuración, dependencias,
  localización, navegación, activación live y las subfases 07.3/07.4.

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

- Completar Full Keyboard Access en sesión protegida/Clientes, iPad/multitarea, tolerancia de espaciado de texto y un
  error físico de Clientes cuando estén disponibles sus precondiciones.
- Repetir únicamente la auditoría iOS y de accesibilidad tras esta reconciliación documental.
- No iniciar implementación de PLU-28 ni cerrar PLU-26/PLU-27 hasta resolver o aceptar explícitamente ese límite.

## Bloqueos

No quedan defectos físicos conocidos en Login, sesión protegida ni Clientes. La validación automática, previews,
Inspector y tecnologías de asistencia ejecutadas están reconciliados; AutoFill conserva el límite esperado de
Associated Domains. Permanecen limitadas las comprobaciones de Full Keyboard Access en sesión/Clientes, iPad/multitarea,
espaciado de texto equivalente y error físico de Clientes. PLU-27/PLU-26 siguen abiertos y bloquean
implementación/runtime de PLU-28; el preflight read-only de 07.2 continúa siendo válido.
