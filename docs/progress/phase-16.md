# Fase 16 — Asistente local

## PLU-47 — Borrador textual de servicio — inicio 2026-09-30

[PLU-47](https://linear.app/plusprojects/issue/PLU-47) In Progress. El propietario confirma «adelante con el borrador de
servicios de Foundation models». Rama `codex/plu-47-foundation-models-service-draft`, base limpia `main`/`e605a7c`.
Reutiliza la issue de ADR0030; no empieza 11.1 ni cierra ninguna subfase completa de 16. Entrega Git y cierre pendientes
de autorización separada. Autoridad: spec16, ADR0010/0011/0022/0029/0030, constitución y política Swift.

## Propuesta inicial de implementación

- Integrar una sección en el formulario existente de alta de un servicio profesional. Descripción escrita, generación
  explícita, propuesta parcial visible, aplicar/rechazar y edición normal; guardar conserva el botón y UseCase existentes.
  No interpretar formularios de producto ni editar servicios persistidos en este incremento.
- Contrato puro `ServiceDraftInterpreter`: disponibilidad por locale y propuesta asíncrona. `ServiceDraftProposal`
  contiene únicamente nombre, precio con moneda, impuesto y descuento opcionales validados. Ausente significa no
  propuesto, nunca un valor por defecto. El adaptador no recibe repositorios, closures mutadoras ni contexto persistente.
- Adaptador `FoundationModelsServiceDraftInterpreter` en Assistant/Data/Adapters; `SystemLanguageModel.default`,
  `supportsLocale`, sesión nueva por solicitud y DTO `@Generable` con resultado cerrado servicio profesional/aclaración.
  Instrucciones estáticas y texto no confiable exclusivamente en Prompt. Sin tools, transcript guardado ni fallback cloud.
- El DTO extrae fragmentos literales de nombre/precio/impuesto/descuento. Validación Data exige presencia literal y
  asociación semántica: precio etiquetado con moneda explícita EUR/euros/€ o USD; IVA/tax y descuento/discount con etiqueta
  y porcentaje. Parseo Decimal completo, sin Double, exponentes, agrupaciones, prefijos ni redondeo silencioso.
  Un fragmento inválido, respuesta ambigua/múltiple o propuesta vacía produce aclaración; valores ausentes quedan nil.
  El modelo clasifica intención; estas defensas no prometen eliminar toda ambigüedad semántica, por eso hay revisión humana.
- `ServiceFormViewModel` conserva el único draft y estado efímero separado para entrada, petición, propuesta y feedback.
  `.task(id:)` pertenece a la pantalla. Cualquier edición invalida la petición/propuesta por token, incluso A→B→A;
  comprobar vigencia al recibir y aplicar. Aplicar rellena solo campos presentes y no guarda. Permitir deshacer la aplicación
  mientras no haya una edición posterior. Rechazo, cancelación, nueva petición, guardar, cierre y escena no activa limpian
  la inferencia; background conserva el borrador manual. El desmontaje por logout llama al cierre existente.
- Composición explícita del proveedor real en la demo aislada08.8a. El formulario y sus capas son los reales; live y fixtures
  vacías no incorporan una capacidad activable por defecto. Previews/tests inyectan dobles deterministas, nunca el modelo
  real. No se añaden modelos SwiftData, migraciones, persistencia conversacional, red ni telemetría.
- Sección nativa, textos es/en en xcstrings, etiquetas persistentes, estados y anuncios localizados, controles de44pt,
  Dynamic Type sin truncamiento. Preview por View con AppPreviewModifier; matriz específica y deuda propia según ADR0029.

Alternativas: parsing exclusivamente manual no demuestra Foundation Models; salida libre exige interpretar texto sin
contrato; rellenar directamente el draft permite respuestas tardías y no ofrece revisión previa. Un Store o router nuevo
no se justifica para una sola petición en el ViewModel actual. Se reutiliza el flujo manual y se añade una frontera de
interpretación reemplazable. No requiere ADR nuevo: concreta la decisión ya aceptada sin cambiar sus fronteras.

Áreas previstas: Features/Assistant/Domain y Data/Adapters, ServiceFormViewModel y extensión, ServiceFormScreen/Content
y sección propia, AppDependencies+ServiceForm/fixture y DevelopDemoComposition, recursos, tests focales y esta evidencia.
Sin micrófono/Speech/TTS, pagos, ventas, stock, documentos, nueva dependencia, APIs beta, unsafe ni activación remota.

## TDD y validación previstas

1. Corpus determinista: ejemplo normal es/en, campos ausentes, cero explícito, decimales exactos, número en otro campo,
   moneda ausente/no admitida, inventado/no literal, negativo/fuera de rango, ambigüedad/múltiples y salida hostil.
2. Estado: generar/aplicar/rechazar/deshacer no escribe; guardar manual valida y persiste mediante la ruta existente.
   Cancelación cooperativa y respuesta tardía; edición A→B→A; reemplazo, cambio de tipo, save, cierre/background/logout;
   errores y falta de disponibilidad no destruyen el borrador manual. Dobles controlados, sin sleeps ni inferencia en tests.
3. Xcode MCP estable: workspace descubierto por ruta, Develop, Swift6/strict completo/default nonisolated, iOS27/SDK27,
   warnings como errores. Baseline publicado: builds y tests de localization-en-es.md; no repetirlos antes de cambios.
   RED/GREEN focal, regresión de formulario/composición, builds Develop/Production y logs completos; no xcodebuild.
4. Comprobar temprano disponibilidad real (sin texto de negocio) en iPhone16 conectado, restaurando destino iPhone11.
   Si no se puede ejecutar o no está disponible, registrar bloqueo de evidencia. Dobles/simulador no acreditan inferencia
   física. Prueba del corpus en dispositivo solo con datos sintéticos, conservando contadores/resultados sin prompts/salidas.
5. Previews Large/XXX Large/AX5, smoke del flujo aislado, revisiones independientes de estándares y accesibilidad;
   registrar límites y deuda aplicable antes de entrega funcional. No declarar el objetivo de demo IA cumplido sin inferencia.

## Fuentes primarias verificadas para la propuesta

- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel): disponibilidad
  por dispositivo, configuración y recursos; no inferirla solo por versión de sistema.
- [supportsLocale](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale(_:)):
  disponibilidad de idioma, API estable26.
- [Generación y sesiones](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models):
  una sesión efímera y una petición por sesión.
- [Generación guiada](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation):
  garantía estructural, no garantía semántica; los opcionales representan ausencia.
- [Seguridad](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output):
  Instructions confiables, input en Prompt y salida restringida.

El SDK27 depreca `LanguageModelSession.GenerationError`; el adaptador evita referenciar ese tipo y mapea cancelación y
fallos a errores propios sin registrar detalles. No adopta los nuevos tipos27 para sortear la restricción estable26.
Se comprueba cancelación antes/después del await y se impide publicación tardía; no se promete interrupción física inmediata
del modelo. Investigación vía Cupertino y documentación oficial; las APIs se comprobarán también al compilar.

## Estado de las puertas

PRE independiente PASS, sin P0–P3. Revisor nuevo, operacional read-only; 677 archivos PRE=POST:
`f63608b4c843644ec2bea290f43b94b5699f01b3fd3529a0684a76e6d4c0feab`.
Adoptadas las comprobaciones de redondeo Money y la invalidación antes del guard previo de didSet.
Implementados el adaptador, DTO/parser, propuesta validada y estado del formulario. El proveedor real se inyecta
exclusivamente desde `DevelopDemoComposition`; la factoría ordinaria y las previews no lo habilitan por defecto.
La propuesta y sus textos son efímeros; solo guardar recorre la persistencia local y genera la operación pendiente habitual.

Probe temprano vía Xcode MCP RunCodeSnippet: disponibilidad `available`, español soportado. Aunque se seleccionó
iPhone16, el propio código confirmó `targetEnvironment(simulator)`, iOS27.2/24B5089g. Es evidencia de simulador;
no acredita disponibilidad física ni inferencia. No se creó sesión ni se generó texto. Ensayo físico pendiente.

## Evidencia local — 2026-09-30

- TDD RED: build for testing Develop PASS (19,966 s); 60 resultados, 48 PASS y 12 fallos esperados en los stubs.
  [Resumen RED](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/A42E9707-E274-4CB2-9F5D-6404CFDD3BEA.txt).
- GREEN: build for testing Develop PASS (23,431 s); **160/160 resultados PASS**, 82 declaraciones ejecutadas,
  incluidos parámetros; sin fallos, omisiones ni runtime warnings en el `.xcresult` nativo cerrado.
  Incluye corpus de extracción, estados/invalidación/cancelación, persistencia contextual únicamente tras guardar,
  formulario, draft, selección de producto, composición y demo.
  [Resumen GREEN](/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/303115FB-99A2-4AB7-A9B7-48811CC8034A.txt).
  Bundle nativo: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.30_18-07-29-+0200.xcresult`.
- Logs completos de build revisados: sin warnings Swift/Clang; persiste el aviso conocido de extracción AppIntents
  por ausencia de dependencia. La consola de tests contiene un aviso StoreKit de cuenta sandbox, ajeno al asistente.
- Inventario de localización: 429 entradas, 0 errores. Auditoría de estilo de los 18 archivos Swift afectados:
  0 candidatos de multilineado; `git diff --check` limpio. No se empleó `xcodebuild`.
- Disponibilidad e inferencia son puertas separadas. El simulador iPhone 18 Pro Max, iOS 27.2/24B5089g, comunica
  disponibilidad, pero la inferencia real devuelve `operationNotAllowed: Simulator is not supported`.
  El intento se hizo con datos sintéticos en la demo. La UI muestra el error localizado, mantiene los campos manuales
  y permite continuar. Esto **no** acredita generación real ni la aceptación física de PLU-47.
- `DeviceInteractionStartWorkspaceSession` no pudo seleccionar el iPhone 16 conectado; los destinos disponibles
  para esa sesión fueron simuladores. Pendiente ensayo físico con Apple Intelligence y recursos locales disponibles.
- Deuda accesible propia: [PLU-70](https://linear.app/plusprojects/issue/PLU-70), Backlog, Jesus Franco.
  [Matriz por criterio](../accessibility/evidence/16-service-draft-assistant.md). Recuperar tras feedback y estabilización,
  siempre antes del primer candidato para uso real. La validación funcional no cierra esta deuda.

## Corpus de aceptación del ensayo real pendiente

Fijado antes del ensayo físico; ejecutar con datos sintéticos, sin registrar prompts, respuestas o transcripciones.
Conservar solo caso, configuración, contador de resultado, latencia si se mide y motivo genérico del fallo.

| Caso | Resultado exigido |
|---|---|
| Servicio único es/en con precio, moneda, impuesto y descuento explícitos | Propuesta literal y exacta; campos manuales sin modificar hasta aplicar. |
| Nombre y precio, sin impuesto ni descuento | Propuesta parcial; no inventar porcentajes ni moneda; completar manualmente lo requerido. |
| Cero explícito y coma/punto según locale | Conservar cero; ninguna conversión ni redondeo. |
| Sin moneda, decimal inválido o porcentaje fuera de rango | Omitir lo ausente o pedir aclaración; nunca proponer valor inválido. |
| Múltiples servicios, producto o instrucciones hostiles | Pedir aclaración; ninguna acción ni mutación. |
| Cancelación, edición durante inferencia, background, cierre y logout | Ninguna publicación tardía ni pérdida del borrador manual. |
| Aplicar, deshacer, rechazar, editar y guardar | Reversibilidad antes de editar; persistencia únicamente por el botón habitual. |

Los casos deterministas están versionados en `ServiceDraftExtractionTests` y `ServiceDraftAssistantTests`.
Un fallo de seguridad, integridad o recuperación bloquea la aceptación funcional; una limitación del runtime mantiene
pendiente la demo IA, aunque el fallback manual y los contratos pasen.

## Comprobaciones complementarias y previews

- Localización compilada: 38/38 resultados PASS (3 declaraciones parametrizadas), sin runtime warnings en el bundle
  nativo cerrado de las 18:19:12. Resumen `RunSomeTests/FDA92585-5A07-4AD0-AD04-7E656A645F2A.txt` bajo ActionArtifacts.
- Build Production PASS, 21,438 s: `BuildProject/BuildProject-Log-20260930-182001.txt`. Inspeccionado junto con el
  build Develop; sin avisos Swift/Clang, únicamente el aviso AppIntents conocido.
- Smoke táctil en demo: error recuperable de inferencia → formulario manual → guardar → reabrir con valores correctos.
  Asistente ausente en edición. Sin crash ni defectos visuales observados en el nuevo componente.
  Artefactos en `ActionArtifacts/default/DeviceInteractionSynthesize/Professional Service Draft Smoke-18_15_55_938-*`
  (error), `18_16_49_855-*` (guardado), `18_16_57_163-*` (reapertura), `18_17_11_264-*` (final).
  Los logs del sistema contienen ruido de haptics del simulador; no se registra contenido de negocio por la app.
- Sesión de interacción cerrada; esquema Develop y destino original iPhone 11 restaurados. Argumentos del esquema
  conservados desactivados; el smoke usó parámetros temporales de InstallAndRun.

Previews deterministas renderizadas por Xcode MCP e inspeccionadas en iPhone 18 Pro Max/iOS 27.2:

| Superficie/estado | Variante efectivamente observada | PNG en ActionArtifacts/default/RenderPreview |
|---|---|---|
| Sección idle | ES, Large, Light | `Assistant idle ES Large - 2026-09-30 at 18.08.36.png` |
| Sección revisión | ES, AX 5, Light | `Assistant review ES AX 5 - 2026-09-30 at 18.17.44.png` |
| Sección error | EN, XXX Large, Dark | `Assistant error EN XXX Large - 2026-09-30 at 18.17.52.png` |
| Pantalla completa | ES, Large, Light | `Assistant create ES - 2026-09-30 at 18.18.14.png` |
| Pantalla completa | ES, XXX Large, Dark, contraste incrementado | `Assistant create ES - 2026-09-30 at 18.18.25.png` |
| Pantalla completa | ES, AX 5, Light | `Assistant create ES - 2026-09-30 at 18.18.35.png` |
| Contenido completo | ES, Large, Light | `Assistant create ES - 2026-09-30 at 18.18.59.png` |

El override de idioma en la pantalla no sustituye el locale ES fijado por su fixture; la captura XXX Large sigue en
español. La sección de error sí acredita inglés. Sin solapes ni truncamiento horizontal observados. AX 5 deja parte del
contenido fuera del viewport de Form: las capturas no prueban por sí solas alcance mediante scroll, teclado, foco ni AT.
La operación de todos los controles en ese tamaño conserva su comprobación pendiente en PLU-70.

POST independiente de estándares PASS, sin hallazgos P0–P3. Verificó arquitectura, privacidad, concurrencia,
invariantes, tests y evidencia nativa. Primera revisión de accesibilidad: un P2 en Listo, que no controlaba el foco
privado de la descripción. Corregido compartiendo `FocusState<Bool>.Binding` desde Content; el botón limpia ambos
focos. Sin cambios en Domain/ViewModel. La revisión de accesibilidad y el smoke focal se repiten por este impacto.

Auditoría operacional read-only: 688 archivos tracked/no ignorados, PRE=POST
`6abe63d294359fafb6dddcc120377e0094c3945eb40d7c9c7a7cc7367de05c81`.
Tras la corrección: build Develop PASS (19,425 s; `BuildProject-Log-20260930-182559.txt`) y renders repetidos de la
sección AX 5 y la pantalla Large, inspeccionados sin cambios visuales observados:
`Assistant review ES AX 5 - 2026-09-30 at 18.26.29.png` y `Assistant create ES - 2026-09-30 at 18.26.41.png`.
No se repiten los tests de negocio/localización por un cambio exclusivo de binding de foco. Inferencia física,
aceptación de demo IA, cierre funcional y entrega Git continúan pendientes.

## Reauditoría focal y estado final de este incremento

P2 de Listo corregido y reauditoría independiente de accesibilidad PASS para construcción funcional de UI, sin nuevos
hallazgos. Validación integral pendiente en PLU-70. 688 archivos, PRE=POST:
`17bc58a7b16dcbea22b4b2e2cb866d5ee49f1125c244b9f0e918209c0e03ae8a`.
Las únicas ediciones posteriores a esta huella son este registro de evidencia, su matriz y el resumen de progreso.

Smoke focal de Listo PASS tanto para descripción como para nombre: se retiran Keyboard Focused, cursor y toolbar;
el texto permanece intacto. El simulador tenía teclado hardware y no desplegó teclado software: no se acredita su
geometría ni animación de ocultación. Artefactos en `ActionArtifacts/default/DeviceInteractionSynthesize/`:

- Descripción antes/después: `Assistant Keyboard Done-18_28_06_630-*` y `Assistant Keyboard Done-18_28_19_797-*`.
- Nombre antes/después: `Assistant Keyboard Done-18_28_35_256-*` y `Assistant Keyboard Done-18_28_43_916-*`.

Build Production posterior a la corrección PASS (15,725 s; `BuildProject-Log-20260930-182912.txt`), sin warnings Swift/Clang;
solo aviso AppIntents ya descrito. Sesión cerrada y Develop/iPhone 11 restaurados nuevamente.

Balance: **198 resultados PASS** (160 de comportamiento/regresión y 38 de localización), builds Develop/Production,
previews representativas y revisiones técnicas PASS. El primer incremento está implementado localmente; PLU-47 conserva
In Progress. **La aceptación de Foundation Models requiere inferencia real y corpus en dispositivo físico.**
Sin commit, push, PR, cierre de issue, servicios live ni cierre de subfases completas de 16.

## Ensayo físico y corrección propuesta — 2026-09-30

iPhone 16 conectado, iOS 27.2/24B5089g; demo ejecutada mediante Xcode MCP y operada por Device Hub/CUA.
UI en inglés, locale capturado `en_ES`, formato decimal con coma. Primera ejecución tomó el LaunchAction en caché
sin demo: error de configuración; tras recargar el workspace, el perfil demo quedó confirmado por aviso y semillas.
El archivo del esquema se restauró byte por byte, SHA256 `7142da803d5e9ccb3b95819a0183df91cb3f629edad039ac8c4dc62b4bcd9b36`.
Run demo física: 19,233 s, PID995, referencia77fd77b900; log `RunProject-Log-20260930-185559.txt`.
Sin warnings Swift/Clang; aviso AppIntents conocido. Solo runtime físico, sin activar proveedores remotos.

El primer completo ES propuso los cuatro campos exactos. Aplicar y deshacer observados sin guardado y con restauración.
Los parciales EN y ES terminaron en aclaración. Diagnóstico del parcial ES, con breakpoint retirado después:
status `singleProfessional`; nombre válido; precio presente/literal/con moneda, pero sin etiqueta `precio`/`price`;
impuesto/descuento ausentes correctamente. El parser rechazó la extracción sin relajar la procedencia ni inventar valores.
Solo se conservarán estos indicadores y resultados, no los textos de inferencia en este registro.

Propuesta acotada antes de editar: precisar `@Guide` de priceEvidence y la instrucción estática para exigir que el
fragmento comience por la etiqueta literal de precio y termine en la moneda. Incluir explícitamente la etiqueta;
no devolver solo importe/moneda. No cambiar DTO, protocolo, parser, UI, opcionales ni reglas comerciales.
Alternativas descartadas: aceptar números sin etiqueta perdería asociación semántica; normalizar strings vacíos no
resuelve la causa observada; reestructurar la salida aumenta alcance sin evidencia. Reutilizar la protección de regresión
existente para una extracción literal de importe/moneda sin etiqueta, y repetir los parciales reales EN/ES en el mismo iPhone.
TDD físico: parciales fallidos constituyen RED; GREEN exige propuesta parcial literal, sin IVA/descuento inventados,
con formulario preservado. Revisar este ajuste de prompt de forma independiente antes del código; luego build/tests
focales y revisión técnica del diff exacto. La aceptación física permanece pendiente durante la corrección.

## Corrección de la guía y validación focal

PRE independiente PASS antes del ajuste: 688 archivos, PRE=POST
`80d0b26d77f11d8cde0569a1e2d332f6dce9e10794d3bbe611f2d357510937a1`.
Se refuerzan únicamente `@Guide` de `priceEvidence` y las Instructions estáticas del adaptador. El parser conserva
su validación literal y los campos ausentes siguen siendo opcionales. La regresión existente «a number elsewhere
in the source cannot justify a price» ya cubre el fragmento sin etiqueta; no se añade una prueba redundante.

- Build for testing Develop PASS, 23,75 s; `BuildProject-Log-20260930-191620.txt`. Solo dos avisos de extracción
  AppIntents conocidos, sin warnings Swift/Clang.
- **81/81 resultados PASS**, 26 declaraciones de extracción/estado; cero fallos, omisiones y runtime warnings.
  Resumen `RunSomeTests/A35F4385-7C33-4E9D-B6B3-D6CC36C5C194.txt`; bundle nativo cerrado
  `Test-FranAlonso-Develop-2026.09.30_19-16-20-+0200.xcresult`. El destino efectivo fue **iPhone 11 físico**, iOS 27.2;
  el tool restableció ese destino. Estas pruebas no se atribuyen al iPhone 16 ni realizan inferencia real.
- Nuevo RunProject físico correcto: iPhone 16, 12,427 s, PID1019, referencia780848d680;
  `RunProject-Log-20260930-192557.txt`, sin diagnósticos de build. Banner demo confirmado por Device Hub.
  Los intentos de arranque sin demo o en otro destino se detuvieron y no cuentan como aceptación.
- POST técnico focal independiente PASS, sin P0–P3. 688 archivos, PRE=POST
  `36b23b244fbe230aa5793b54cbd88db5024b2b2ccfce975592082e385b222e46`.
  La guía es probabilística: este resultado técnico no sustituye el retest físico ni el corpus real.

Primer retest parcial ES corregido, 19:33: **PASS** en la misma descripción que falló; propuesta literal de nombre
y precio, sin impuesto ni descuento. Captura de revisión mediante Device Hub/CUA, PID1019. No sustituye las
comprobaciones EN, conservación del formulario, corpus restante ni el build Production posterior. El esquema
se mantiene restaurado byte por byte; no se modifica la configuración permanente para habilitar la demo.

Retest parcial EN, 19:34: **FAIL**; aclaración, sin propuesta y formulario vacío preservado. Rechazar el parcial
ES fue **PASS**, sin persistencia. La repetición EN bajo breakpoint fue exclusivamente diagnóstico: clasificación
de servicio único y nombre válidos; precio con etiqueta/moneda pero fragmento no literal, aun ignorando case/espacios;
impuesto/descuento ausentes en la entrada, representados por strings vacíos. El parser rechazó estos valores.
Breakpoint eliminado y proceso continuado. No se registra contenido de entrada ni salida del modelo.

Propuesta focal de segundo ajuste, antes del código: configurar `ServiceDraftExtractionDTO` mediante
`@Generable(representNilExplicitlyInGeneratedContent: true)` y alinear guías/Instructions con `null` para propiedades
opcionales ausentes, nunca string vacío ni espacios. La primera propuesta solo textual tuvo un P2 PRE: los textos
no cambian el esquema que por defecto representa nil por omisión. Se corrige la propuesta antes de editar código.
La opción está disponible desde iOS 26.4 estable y es compatible con el target real iOS 27; no incorpora una API beta27,
eleva el target ni cambia las propiedades opcionales. Fuente: [macro Generable de Apple](https://developer.apple.com/documentation/foundationmodels/generable%28description%3Arepresentnilexplicitlyingeneratedcontent%3A%29).
Reforzar la copia del fragmento completo con la etiqueta y moneda originales, sin traducir/sustituir etiquetas,
moneda ni números. Se mantienen las propiedades del DTO, validación literal, parser, dominio y contrato: no normalizar resultados
inválidos como valores aceptados, ni inventar ausencias o valores comerciales. Alternativa de reconstruir fragmentos
o tolerar cadenas vacías descartada en este incremento porque cambia la validación aprobada. Mantener la omisión
y prohibir strings vacíos sería viable, pero la representación explícita distingue mejor ausencia de evidencia vacía
y permite alinear el esquema con las instrucciones de este adaptador. Revisión PRE read-only
antes de modificar estas instrucciones; repetir luego las pruebas existentes y los parciales físicos EN/ES.

## Segundo ajuste y ronda física de regresión

PRE corregido PASS tras resolver el P2 de alineación del esquema. 688 archivos, PRE=POST:
`e2078fb7dedaa137a7152e28aac8bfcf75e9fd89099b5051ccbc7d89d596942e`.
Implementados únicamente la opción de nil explícito en la macro del DTO y sus guías/Instructions. No se normalizan
cadenas vacías, reconstruyen fragmentos ni cambian parser, propiedades, protocolo, Domain, UI o persistencia.
Auditoría de estilo focal: dos archivos Swift, cero candidatos; `git diff --check` limpio.

- Develop for testing PASS, 18,687 s; `BuildProject-Log-20260930-195118.txt`.
- Retest focal **81/81 resultados PASS**, 26 declaraciones; iPhone 11 físico seleccionado explícitamente.
  Resumen `RunSomeTests/0C9A445A-FCA5-43A8-8FC3-A17369E70754.txt`, bundle
  `Test-FranAlonso-Develop-2026.09.30_19-51-26-+0200.xcresult`. No se suman estas repeticiones como casos distintos
  a los 198 resultados del primer incremento.
- Production PASS, 20,678 s; `BuildProject-Log-20260930-195214.txt`.
- Demo en iPhone 16 desplegada nuevamente: 25,08 s, PID1054, referencia77fd6dba80;
  `RunProject-Log-20260930-195314.txt`. El esquema vuelve a quedar idéntico a su original.
- Logs completos revisados: ningún warning Swift/Clang; avisos AppIntents conocidos (dos en for testing y uno
  en cada build Production/run físico). Retest parcial real EN/ES y POST de este segundo ajuste en curso.

Balance de la ronda física anterior, PID1019: seis inferencias normales completadas, cinco resultados esperados
y un parcial EN fallido, más una generación cancelada. La repetición diagnóstica no cuenta como aceptación.

| Caso de PID1019 | Evidencia observada | Resultado |
|---|---|---|
| Parcial ES y rechazar | Nombre/precio literales, sin porcentajes inventados; rechazo limpia entrada/propuesta y conserva formulario. | PASS |
| Parcial EN | Aclaración, sin propuesta ni mutación; fallo conserva su registro. | FAIL |
| Completo decimal ES | Precio decimal exacto y porcentajes explícitos; aplicar no guarda. | PASS |
| Editar después de aplicar, guardar y reabrir | Edición retira Deshacer; solo Guardar crea servicio. Reapertura conserva todos los valores y no muestra asistente. | PASS |
| Ceros explícitos ES | Precio, impuesto y descuento cero visibles; sin guardado automático. | PASS |
| Múltiples servicios ES | Aclaración, sin Aplicar ni cambios manuales. | PASS |
| Generación que completó antes de cancelar | Propuesta parcial ES; rechazada preservando el nombre manual. No cuenta como cancelación. | PASS para propuesta/rechazo |
| Cancelar durante loading | Loading→Cancelar→idle; entrada vacía, nombre manual conservado, sin propuesta tardía en captura posterior. | PASS |
| Cerrar formulario con propuesta | Retorno a lista, sin crear otro servicio. | PASS |

Operación táctil mediante Device Hub/CUA; UI EN, locale `en_ES`, Dark, tamaño3, AT apagadas. Las capturas quedan
en la traza de interacción, no se versionan prompts/respuestas. Una confirmación de desactivación abierta por inercia
del gesto se descartó mediante Keep editing, sin desactivar. Capture Keyboard volvió a OFF y las preferencias no
se modificaron. Producto, instrucción hostil, importe inválido, background/cierre durante loading y aplicación parcial
con porcentajes manuales eran pendientes al terminar esta ronda; no se atribuye PASS a casos no ejecutados.

POST técnico focal del segundo ajuste **PASS**, sin P0–P3. Bundle nativo cerrado verificado: 81/81 resultados,
26 declaraciones, iPhone 11 físico/iOS 27.2; cero fallos, omisiones y runtime warnings. Builds y límites confirmados.
688 archivos, PRE=POST: `5543364473b68b0f6554517cdd491470b6af2a16fa7d991239fdb64740aa2678`.
Los ajustes posteriores de descuento y clasificación se registran y revisan de forma independiente más abajo.

PID1054, banner demo y fixture confirmados sin guardar credenciales: primer parcial **EN PASS a las 19:56** sobre
la misma descripción que falló; nombre/precio literales, sin impuesto/descuento ni mutación automática. Se mantienen
registrados los fallos anteriores; no se convierten en éxitos por esta repetición. Resto del retest físico en curso.

PID1054, 20:01–20:02: parcial ES idéntico **PASS**. Sobre baseline manual, Aplicar cambió solo nombre/precio,
conservando IVA21 y descuento0; Deshacer restauró nombre/precio anteriores y ambos porcentajes. Sin Guardar.
Completo EN con USD y decimal con coma, 20:04: **FAIL**, aclaración sin mutación. Diagnóstico bajo breakpoint,
excluido de aceptación: servicio único, nombre/precio/impuesto válidos y literales; solo descuento no literal,
con la etiqueta traducida al español. La moneda USD y el decimal con coma eran válidos. Breakpoint eliminado;
no se usa esta repetición para borrar el fallo inicial.

Propuesta focal de tercer ajuste antes del código: precisar solamente el `@Guide` de `discountEvidence` y sus
Instructions estáticas para exigir el fragmento continuo con la etiqueta original discount/descuento, el número
y %. Prohibir explícitamente traducir la etiqueta en cualquiera de los dos sentidos; conservar dígitos, puntuación,
espacios y case. Propiedades, nil explícito, parser, contrato, Domain, UI y persistencia intactos. Alternativas de
traducir/reconstruir el fragmento o tolerar evidencia no literal se descartan por debilitar la procedencia aprobada.
TDD físico RED: completo EN fallido; GREEN requiere completo EN y ES con descuento no cero literal en el mismo
dispositivo. Reutilizar regresiones deterministas existentes; PRE independiente antes de editar y POST focal después.

PRE del tercer ajuste PASS; 688 archivos, PRE=POST:
`9a955f2e370f59482e5be730ca7afc6dffc30a4435cd6734a9fd11b6905d0116`.
Solo la guía/instrucción de descuento se precisan conforme a ese PRE; compilación/GREEN físico aún pendientes.

Ronda PID1054 completada: seis inferencias normales, tres PASS (parciales EN/ES y moneda ausente) y tres FAIL
(completo EN, producto y petición hostil), más una repetición diagnóstica excluida. Aplicar/Deshacer/Rechazar sobre
baseline fueron PASS. Producto produjo precio aplicable sin nombre; petición hostil produjo nombre/precio aplicables.
Ninguno ejecutó acciones, guardó ni mutó el formulario automáticamente; ambos fallan el criterio semántico de aclaración.
Se rechazaron preservando baseline y se descartó solamente ese borrador sintético al volver a los dos seeds de demo.
Capture Keyboard OFF y preferencias intactas. No se aceptan estos fallos como simple deuda accesible.

## Revisión de clasificación tras fallos reales

Antes de nuevo código, evaluar de forma independiente cómo impedir que la extracción de campos válidos prevalezca
sobre una entrada fuera de alcance. Alternativas: reforzar únicamente Guide/Instructions del status actual; añadir
categorías cerradas explícitas producto/múltiples/petición no permitida; separar una clasificación tipada previa de
la extracción; o un filtro determinista para indicaciones explícitas de producto/override. Un filtro de palabras no
puede prometer detección semántica general y puede rechazar servicios que utilizan productos; no se adopta sin
justificar sus límites. La separación añade una llamada y debe justificar latencia, cancelación y privacidad local.
Toda opción mantiene la validación literal, las fronteras Data/Domain y la prohibición de efectos sin revisión/Guardar.
No hay autorización para nuevas capacidades, repositorios en el intérprete, red, persistencia conversacional ni unsafe.
La aceptación funcional permanece abierta hasta corregir producto/hostil y obtener GREEN físico en esos mismos casos.

Recomendación independiente: **P2 de clasificación abierto**; adoptar categorías explícitas y Guide con precedencia
en el DTO actual, manteniendo una llamada. 688 archivos, PRE=POST:
`25ca3810cd703e0664eee2d09bb5cf5e8a97a164f1e9507a71088e2b0aafae40`.
Apple confirma generación de propiedades en orden de declaración; `status` ya es la primera. Un enum restringe
el vocabulario, no garantiza semántica. [Generación guiada](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation).
Separar llamadas queda como alternativa si falla esta mejora mínima, con su coste pendiente de justificar.

Propuesta exacta para PRE: añadir `unsupportedRequest`, `multipleServices` y `product` a
`ServiceDraftExtractionStatus`, conservando `singleProfessional`/`clarification`. El Guide de status y las Instructions
definen precedencia: petición dirigida al asistente para cambiar reglas o ejecutar acciones → unsupportedRequest,
aunque contenga un servicio válido; varios servicios independientes → multipleServices; venta de objeto físico →
product, distinta de un servicio que utiliza productos; singleProfessional solo para un servicio inequívoco sin
exclusiones; clarification para ambiguo/insuficiente. Toda categoría de rechazo pide los cuatro campos null.
`toDomain` conserva exclusivamente la admisión de singleProfessional; ninguna otra categoría crea una propuesta,
aunque su evidencia comercial sea literal/válida. No se añaden archivos, APIs, llamadas, repositorios ni efectos.

Extender el test parametrizado existente de rechazo con cada categoría no admitida y evidencia que por sí sola
sería válida; el oráculo procede de la allowlist de spec16, no del texto de las guías. Puede fallar si un cambio que
compila permite una categoría rechazada. No verifica presencia/conteo de casos, ni pretende probar selección del
modelo. RED semántico sigue siendo la prueba física fallida; GREEN exige producto/hostil originales, completo EN/ES
con descuento literal y un servicio que utiliza productos. Añadir una variante sintética no utilizada para ajustar
las instrucciones y mantener la conservación manual. Filtro léxico descartado por falsos positivos; no se promete
clasificación general infalible ni cierre de fase16. PRE exacto antes de implementar clasificación y POST posterior.

PRE exacto de clasificación **PASS**, sin nuevos hallazgos de propuesta; el P2 físico permanece abierto hasta GREEN.
688 archivos, PRE=POST: `63ff3bb617b54c6b9bfdcc34b2d7a384d6f6ae009044d6af49de5f0d3eda8d78`.
Implementada la propuesta en los mismos dos adaptadores. Se conserva la admisión exclusiva de singleProfessional
en `toDomain`. El test parametrizado existente ahora comprueba las cuatro categorías no admitidas frente a los dos
ejemplos con campos válidos: ocho resultados, sin nuevo test redundante ni inferencia real en la suite.

- Develop for testing PASS, 18,855 s; `BuildProject-Log-20260930-203046.txt`.
- **87/87 resultados PASS**, 26 declaraciones; iPhone 11 físico seleccionado explícitamente. Incluyen seis nuevos
  parámetros de rechazo; no son pruebas de selección semántica del modelo. Resumen
  `RunSomeTests/CD032EF2-D950-4C92-B2F2-6E7021907370.txt`; bundle `Test-FranAlonso-Develop-2026.09.30_20-32-00-+0200.xcresult`.
- Production PASS, 19,477 s; `BuildProject-Log-20260930-203231.txt`.
- Nueva demo en iPhone 16: RunProject PASS, 24,035 s, PID1073/ref77fd6d9c80;
  `RunProject-Log-20260930-203342.txt`. Esquema restaurado byte por byte.
- Estilo focal: tres archivos Swift, cero candidatos; `git diff --check` limpio. Sin warnings Swift/Clang en los logs
  completos; solo avisos AppIntents conocidos. POST técnico y GREEN físico de clasificación/descuento en curso.

Ronda PID1073: banner demo confirmado a las 20:34; antes de completar login, CUA informó que el Mac estaba
bloqueado y no podía desbloquearlo automáticamente. **Cero inferencias de aceptación en esta ejecución.**
Se solicita desbloqueo manual; no se intenta automatizarlo. No está verificado si la escritura del email alcanzó
la UI, y Capture Keyboard podría seguir ON. Requiere recaptura y restauración después del desbloqueo.
El bloqueo de entorno no resuelve ni sustituye los fallos semánticos pendientes: producto/hostil, completos EN/ES
con descuento no cero y servicio que usa productos, más una variante nueva, siguen exigidos antes de aceptar.

## Estado tras el bloqueo de interacción

POST técnico focal final **PASS**, sin nuevos hallazgos de implementación. Verificados bundle nativo cerrado
20:32:00 (87/87 resultados, 26 declaraciones, iPhone 11 físico/iOS 27.2), cero fallos/omisiones/runtime warnings,
builds Develop/Production/run físico y ocho resultados del rechazo parametrizado. Solo aviso AppIntents previo,
sin warnings Swift/Clang. 688 archivos, PRE=POST:
`a2be696bc2883063a4d5ed6755810f256eb3422be7c3cfe908d5cb2f7f6db0c1`.
Las únicas ediciones posteriores a este POST final consolidan documentación y tracker.

**P2 semántico abierto hasta GREEN físico** de la clasificación/descuento corregidos. No es deuda aplazable de
accesibilidad. La inferencia real y conservación/aplicación/reversión/guardado ya observadas conservan su alcance
y versión; no validan por anticipado los nuevos casos. Para continuar, desbloquear manualmente el Mac, recapturar
Device Hub y comprobar/restaurar Capture Keyboard antes y después de operar. No repetir muestras ya válidas por
rutina; ejecutar los casos concretos pendientes y registrar cada primer resultado sin ocultar fallos anteriores.
PLU-47 permanece In Progress; PLU-70 Backlog. Sin commit, push, PR, cierre, live ni cierre completo de fase16.

Ejecución propia PID1073 detenida mediante Xcode MCP tras completar la evidencia técnica y solicitar desbloqueo.
Workspace recargado con el esquema original para retirar el argumento demo en caché; Develop/iPhone 11 restaurados.
Archivo de esquema idéntico al original. No hay sesiones DeviceInteraction abiertas. Device Hub no se cerró;
Capture Keyboard conserva la comprobación/restauración pendiente hasta poder operar el Mac desbloqueado.

## Reanudación física — 30/09–01/10/2026

El propietario vuelve y autoriza terminar los pendientes. Mac desbloqueado confirmado; Capture Keyboard estaba ON,
se restauró a OFF antes de operar. RunProject de la misma fuente corregida PASS, 9,328 s, a las 23:52 del 30/09:
PID1149/ref77fd6d8d80, `RunProject-Log-20260930-235233.txt`, iPhone16 de Jesús. Log completo sin errors/warnings.
El argumento demo se activó solo para este lanzamiento y el esquema se restauró inmediatamente byte por byte
(SHA256 `7142da803d5e9ccb3b95819a0183df91cb3f629edad039ac8c4dc62b4bcd9b36`).

No hay cambios ejecutables desde el POST técnico final. Huella de los 538 archivos tracked/no ignorados de
`FranAlonso`, `FranAlonsoTests` y `FranAlonso.xcodeproj` al iniciar este corpus:
`179a1e7f6a661976c3732608fdbf19eb21951b5e986155dc15b91fb288d56144`.
Las pruebas deterministas y builds ya validados se reutilizan por impacto; este run no repite la suite.

La interacción inicial quedó bloqueada por el espejo y su escala de coordenadas. Home/App Switcher nativos alcanzaban
el teléfono, pero los toques caían fuera del frame por un desfase 2×. Se reabrió solo Screen Sharing y Device Hub,
se refrescó el binding CUA por la ruta de la app activa y se confirmó caret/escritura real. Sin reiniciar el teléfono,
cambiar preferencias ni relanzar PID1149. Login demo confirmado y borrador manual sintético abierto el 01/10.
Estas recuperaciones de herramienta no cuentan como inferencias ni fallos de la app. El corpus pendiente continúa;
no se atribuye GREEN hasta registrar los primeros resultados de cada caso en la implementación actual.

### Ronda PID1149: clasificación demasiado restrictiva en inglés

| Caso, primera generación | Resultado observado |
|---|---|
| Producto original, 00:08 | PASS: aclaración, sin propuesta/Aplicar; borrador manual intacto. |
| Petición hostil original, 00:11 | PASS: aclaración, sin propuesta/Aplicar, guardado ni mutación. |
| Completo EN, USD/coma y descuento5, 00:12 | FAIL: aclaración indebida, borrador conservado. |
| Completo ES, 00:15 | PASS: nombre literal, 12,30 EUR, IVA10 y descuento5; sin aplicar ni guardar. |
| Servicio que utiliza productos, parcial, 00:18–00:19 | PASS: solo nombre/precio; Aplicar conserva IVA21/descuento0 y Deshacer restaura el baseline completo. |

Cinco inferencias de aceptación: cuatro PASS y un FAIL; una repetición diagnóstica EN excluida. No se oculta ni
compensa el FAIL mediante un reintento. Diagnóstico bajo breakpoint: `unsupportedRequest` y cuatro campos nil;
locale `en_ES`. Es un falso positivo de clasificación; no acredita un fallo del descuento en esta versión.
Breakpoint retirado, proceso reanudado y después detenido al completar la ronda. Capture Keyboard OFF,
preferencias intactas; sin Guardar. El rechazo del completo ES no se alcanzó por la inercia del espejo; editar su
entrada invalidó la propuesta antes del siguiente caso, conservando el formulario manual.

### Separación de instrucciones y descripción

PRE exacto independiente PASS; 688 archivos antes=después:
`f6d3f648ac9874ac605a56373b182407a293dacb97000064130a7065643fb619`.
Mantener una llamada, el DTO y la validación literal. `Prompt(description)` contiene únicamente el texto no confiable;
`Instructions` contiene la tarea estática y el locale de la app. Las guías delimitan que Instructions/schema/metadata
no forman parte de la descripción clasificada y distinguen describir trabajo profesional de pedir al asistente
ejecutarlo. APIs del builder/sesión estables iOS26.0 verificadas en Apple y SDK instalado.
[Instructions](https://developer.apple.com/documentation/foundationmodels/instructions),
[builder](https://developer.apple.com/documentation/foundationmodels/instructions/init%28_%3A%29).
La contaminación por el envoltorio es una hipótesis, no una causa demostrada. Greedy queda fuera; dos llamadas
clasificación/extracción permanecen como alternativa si esta mejora mínima no alcanza calidad.
[Guía de prompting](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model).

Implementado únicamente en los dos adaptadores, sin cambiar parser, contratos, UI, persistencia ni categorías.
El RED es el fallo físico del completo EN; no se añaden tests que comparen cadenas de instrucciones con su implementación.
Regresiones relevantes reutilizadas tras el ajuste:

- Develop for testing PASS, 22,517 s; `BuildProject-Log-20261001-002332.txt`.
- **87/87 resultados PASS**, 26 declaraciones, iPhone11 físico/iOS27.2; bundle nativo cerrado verificado
  `Test-FranAlonso-Develop-2026.10.01_00-23-39-+0200.xcresult` en DerivedData/Logs/Test.
  Cero fallos, omisiones y runtime warnings. La ruta de bundle comunicada por MCP bajo ActionArtifacts no tenía
  Info.plist; se localizó y leyó el bundle nativo cerrado. Resumen MCP `RunSomeTests/88747A04-C24C-403D-A6AD-7B89EE9E4844.txt`.
- Production PASS, 19,553 s; `BuildProject-Log-20261001-002426.txt`.
- Demo iPhone16, PID1167/ref7805bc2880: RunProject PASS, 16,824 s; `RunProject-Log-20261001-002456.txt`.
  Esquema original restaurado byte por byte. No warnings Swift/Clang en logs completos; solo avisos AppIntents previos.
- Estilo: dos Swift, cero candidatos. POST técnico focal y GREEN físico de esta versión pendientes.

POST técnico de separación de canales **PASS**, sin hallazgos nuevos. Fuente538 coincide:
`ba76d9715acb7a8f62de23972f1fa89a9051903aa917cbdcaf42e452ecc58163`.
688 archivos de repo PRE=POST:
`3803518fd81a05bc44d260c25cda5a7d152c4acad22bf056b152031df4566816`.
La revisión confirma APIs estables, una llamada, guard/literalidad/cancelación intactos y la evidencia técnica anterior.

PID1167: primer completo EN **FAIL a las 00:29 del01/10**, aclaración sin propuesta ni Aplicar; nombre manual
conservado. Una repetición diagnóstica a las00:30, excluida de aceptación, volvió a mostrar unsupportedRequest
y cuatro campos nil, locale en_ES. No se identifica un problema de descuento ni se demuestra la hipótesis del
envoltorio; separar canales no alcanza el GREEN esperado. Breakpoint eliminado y proceso reanudado; después se
detuvo la ejecución propia, con destinoiPhone11. Ningún Apply/Save, preferencias intactas y Capture Keyboard OFF.
Resto del corpus no ejecutado en esta versión. P2 funcional EN sigue abierto; evaluar independientemente separar
clasificación y extracción antes de nuevo código, manteniendo admisión cerrada previa a la extracción y sin efectos.

## Arquitectura actual: clasificación y extracción independientes

PRE exacto **PASS**; 688 archivos antes=después:
`64015779799ed732bc83d5f1d4847284ed59ad7b49dc6480eb01e2867316a04a`.
Se adopta la alternativa estructural que Apple recomienda cuando una petición no alcanza fiabilidad:
[prompting y sesiones nuevas](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model).
Dos llamadas locales secuenciales; no se garantiza calidad semántica por el esquema ni se oculta el coste de latencia.

- Sesión nueva de clasificación: DTO ligero con un status cerrado, sin locale comercial ni reglas de campos/null.
  Misma allowlist y categorías, ahora `ServiceDraftClassificationStatus`. Solo singleProfessional se admite.
- Orquestación real en la extensión del intérprete: comprobación de cancelación antes/después de clasificación,
  guard de admisión previo a extracción y comprobación tras extracción. Operaciones async reemplazables permiten
  comprobar esta misma ruta sin abstraer/mockear todo el SDK ni hacer inferencia en tests.
- Sesión nueva de extracción: cuatro opcionales sin status, nil explícito y locale confiable. No recibe transcript
  ni resultado de la primera sesión; conserva evidencia literal y parser. Cuatro nil siguen rechazándose como vacío.
- Validación inicial, disponibilidad y errores públicos intactos. No cambian Domain, VM, UI, composición ni persistencia.
  La segunda inferencia solo se inicia tras admisión; rechazo y error no la ejecutan.

Pruebas del parser mantienen sus oráculos y eliminan únicamente el status que ya pertenece a clasificación.
Los ocho casos de rechazo se trasladan a la orquestación real y verifican cero extracciones, aunque el doble pudiera
devolver campos válidos. Cuatro casos nuevos prueban admisión secuencial una vez, error sin extracción y cancelación
con respuesta tardía en ambas fases. Actor controlado/AsyncStream/continuation, sin sleeps, SDK real ni unsafe.
RED funcional previo: completo EN fallido; no se afirma un RED unitario nativo no ejecutado.

- Develop for testing PASS, 22,174 s; `BuildProject-Log-20261001-004831.txt`.
- **91/91 resultados PASS**, 30 declaraciones. Bundle nativo cerrado en DerivedData/Logs/Test:
  `Test-FranAlonso-Develop-2026.10.01_00-49-20-+0200.xcresult`. iPhone11 físico/iOS27.2, cero fallos/skips/runtime warnings.
  Resumen MCP `RunSomeTests/258687E8-4C4F-40A8-AC1E-4A0E6000A9F9.txt`. Cuatro resultados/declaraciones adicionales
  respecto al bloque87/26; no se suman las repeticiones como corpus nuevo.
- Production PASS, 20,652 s; `BuildProject-Log-20261001-005014.txt`.
- Ajuste final puramente visual de un inicializador de dos argumentos en un test, sin cambio de oráculo/AST:
  Develop for testing repetido PASS, 17,516 s, `BuildProject-Log-20261001-005749.txt`; no se repite la suite por formato.
  Estilo: cinco Swift, cero candidatos; `git diff --check` limpio. Logs de compilación solo AppIntents previo,
  sin warnings Swift/Clang.

Despliegue físico de esta versión: RunProject terminó por timeout300s y no devolvió PID/ref. Device Hub confirmó
Mac bloqueado y solicitó desbloqueo manual; **cero inferencias nuevas y sin aceptación del nuevo adaptador**.
Xcode MCP confirmó que no había app propia ejecutándose. Se cerró/recargó el workspace con el esquema original,
argumentos demo NO y Develop/iPhone11. Último Capture Keyboard verificado OFF en PID1167; no puede recapturarse
durante el nuevo bloqueo. Sin desbloqueo automático ni cambio de preferencias, entrega Git, cierre o live.

Fuente540 (tracked/no ignorada de app/tests/proyecto):
`67ddb827b0264713dac397cb834eb2e3d147c7e0537c88bc01d2b8054964bc57`.
POST técnico de esta arquitectura PASS según el registro siguiente. P2 calidad EN permanece abierto hasta GREEN físico actual y corpus
de regresión con negativos originales, completos EN/ES, variantes positiva/negativa e inválidos; registrar latencia
observable de dos fases. Recuperación runtime durante loading sigue diferenciada de las pruebas controladas.

### Estado al terminar la validación técnica

POST técnico focal de dos sesiones **PASS**, sin hallazgos nuevos. 690 archivos repo antes=después:
`669721c3ad963b5a2e6eacd2f7da6b0861efe076b2af83904cac504f12186d36`.
Huella fuente540 anterior coincidente. Verificados PRE/implementación, oráculos, bundle91/30, builds y logs;
el build posterior cubre por impacto el único ajuste visual del test. Solo la documentación y el tracker cambian
después de esta revisión. No se atribuye inferencia al nuevo adaptador ni cierre del P2 funcional.

Implementación y validación técnica locales completas; **aceptación física pendiente del desbloqueo manual del Mac**.
La solicitud de desbloqueo permanece pendiente. Antes de continuar: recapturar Device Hub, comprobar/restaurar Capture
Keyboard y relanzar la demo en iPhone16 desde el esquema temporal, restaurándolo inmediatamente. Ejecutar primero
el completo EN fallido y registrar su primer resultado; después completos/negativos originales, variantes, inválidos
y una interrupción en loading si observable. No sustituir estos casos por los tests ni por los éxitos de otra versión.
PLU-47 In Progress; PLU-70 Backlog. Sin commit/push/PR/merge/cierre/live ni nueva capacidad de voz.


### Reanudación física del01/10 tras desbloqueo

Fuente540 intacta respecto al POST anterior. RunProject PASS, 12,178s;
`RunProject-Log-20261001-073141.txt`, PID1310/ref7807f0c180. iPhone16/iOS27.2,
UIen/localeen_ES, Dark/texto3/AToff, Apple Intelligence disponible.
Primer completoEN **FAIL a las07:33**, aclaración sin propuesta ni Aplicar, borrador manual intacto.
Cota Generate→resultado observado ≤8,236s; incluye interacción/observación y no mide duración SDK.
Una repetición diagnóstica a las07:37, excluida de aceptación, confirma unsupportedRequest antes
de extracción. No se generó evidencia comercial; no se atribuye el fallo al parser o al descuento.
Breakpoints retirados, proceso reanudado y ejecución propia detenida. Capture Keyboard OFF,
preferencias intactas. Sin Apply/Save y resto del corpus pendiente. El bloqueo del Mac está resuelto;
P2 funcional permanece abierto y exige ajustar clasificación con PRE independiente.


### Propuesta focal: valoración antes de categoría

Tras el RED1310, propuesta Data de dos archivos: añadir `assessment: String` como primera propiedad
generable, una frase factual breve sobre el trabajo/venta y las órdenes explícitas dirigidas al asistente;
`status` sigue segundo con los mismos casos y orden. Instrucciones/Guide de clasificación concisos y cinco
pares estáticos sencillos, uno por categoría, ajenos al corpus fallido. El positivo usa materiales;
negativos incluyen venta, varios servicios independientes, orden al asistente con fragmento válido y ambigüedad.
Assessment se descarta localmente: no se registra, persiste, muestra, valida como autoridad ni pasa a extracción.
Guard cerrado, dos sesiones, cancelación, parser, Domain/UI/DI/persistencia intactos. Sin greedy, cambio de orden,
clasificador léxico, reintentos automáticos ni nuevas APIs. Alternativas descartadas: otro refuerzo solo verbal,
varios Bool con combinaciones inválidas, evidencia literal extra sin resolver destinatario y llamadas adicionales.
Apple recomienda valoración antes de respuesta y ejemplos simples2–15; documento oficial actual consultado01/10:
[prompting](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model),
[orden y generación guiada](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation).
RED físico, no test de cadenas/compilador. Regresión91, builds y POST focal más corpus real de la nueva versión;
previews/POSTUI previos reutilizables por impacto. PRE exacto pendiente antes de escribir Swift.


PRE exacto final de valoración/categoría **PASS**, tras precisar un único servicio claro y venta de objeto físico
en Guide. 690 archivos PRE=POST `1f0f6c80c07fd14793a72f987ec3a6cedd4c421e893f99a34fbe15e00630a1ab`.
Implementados únicamente Instructions y DTO de clasificación según candidato revisado. Sin tests que comparen
cadenas o estructura compilada. Dos Swift auditados de estilo, cero candidatos; diff-check limpio.
Develop for testing PASS20,849s (`BuildProject-Log-20261001-075256.txt`); Production PASS22,910s
(`BuildProject-Log-20261001-075351.txt`). Logs completos: solo AppIntents conocido2/1, sin warnings Swift/Clang.
**91/91 resultados PASS,30 declaraciones**, bundle nativo cerrado en DerivedData/Logs/Test:
`Test-FranAlonso-Develop-2026.10.01_07-53-01-+0200.xcresult`, iPhone11 físico/iOS27.2,
cero fallos/skips/runtime warnings. Resumen MCP `RunSomeTests/6C495FE5-4A28-4608-BB50-B02B6092B956.txt`.
La ruta MCP bajo ActionArtifacts no contenía Info.plist; se verificó el bundle nativo cerrado.
Previews y POSTUI previos reutilizados por impacto: el ámbito modificado es solo Data.
POST focal y nueva aceptación física pendientes; no se declara resuelto el P2.


POST técnico focal de valoración/categoría **PASS**, estilo favorable y sin hallazgos nuevos.
690 archivos/manifest PRE=POST `de019c51ccc352c2c05f12b87ae074d2db85bf9afb213cde8cd4e9ae7494699a`;
fuente540 `1801417f81a05cdf6ee264aa53fd51c46f165ecc4dc96bc2df737dca3ea09958`.
RunProject PASS18,896s, `RunProject-Log-20261001-075519.txt`, PID1398/ref7805259680.
Primer completoEN **FAIL07:57**, aclaración sin propuesta ni Aplicar; baseline intacto y sin Apply/Save.
Cota Generate→resultado ≤9,121s; no duración SDK. La primera captura tras tap aún mostraba idle,
no se atribuye loading a esa ronda. Configuración física anterior intacta, Capture Keyboard OFF.
Una repetición diagnóstica07:58, excluida de aceptación, sí observa loading y devuelve singleProfessional;
extracción contiene cuatro campos, nombre literal, pero los tres campos comerciales no son literales:
etiquetas precio/IVA/descuento en vez de sus originales inglesas. Coma presente, punto ausente en precio.
No se vuelcan DTO ni contenido runtime. El parser rechaza correctamente la evidencia no literal.
Este diagnóstico no demuestra el status de la primera generación ni una causa global; P2 sigue abierto.
Breakpoints retirados, proceso reanudado y detenido, UI liberada; corpus restante sin ejecutar.

Siguiente propuesta focal Data: extracción dedicada a copiar texto sin metadata de locale; el locale real
permanece en validación determinista. Instrucciones y cuatro Guide concisos, dos ejemplos estáticos de copia
EN completo/ES parcial ajenos al corpus real. Sin relajar literalidad, importes, guard, categorías, nil explícito,
sesiones o cancelación; no se añade normalización de respuesta. Alternativa más amplia: extracción comercial
léxica directa del source, descartada ahora por contratos/superficie/test adicionales antes de ensayar la
técnica oficial de ejemplos y eliminar contexto irrelevante. La metadata de locale es una hipótesis de
contaminación, no causa demostrada. PRE exacto pendiente antes de código.


PRE exacto de copia sin metadata **PASS**, 690 archivos/manifest antes=después:
`74aeeceba1cd85648781f49ee103a563a155f7baae709331d8002026efbcc1fe`.
Implementados dos adaptadores según candidato: extracción sin locale de generación, dos ejemplos estáticos
(EN con coma y ES entero) que copian sin enseñar una regla de separador por idioma; Guides cortos.
Parser recibe el locale real intacto y exige literalidad; no normaliza o repara la respuesta del modelo.
Estilo dos Swift/cero candidatos y diff-check limpio. Develop for testing PASS21,118s,
`BuildProject-Log-20261001-081506.txt`; Production PASS18,002s, `BuildProject-Log-20261001-081547.txt`.
**91/91 resultados PASS,30 declaraciones**, bundle nativo cerrado verificado:
`Test-FranAlonso-Develop-2026.10.01_08-15-18-+0200.xcresult` en DerivedData/Logs/Test,
iPhone11 físico/iOS27.2, cero fallos/skips/runtime warnings.
Resumen MCP `RunSomeTests/2BA34F64-82EA-4D9F-ADDF-9DD80D69D13D.txt`.
Logs completos: únicamente AppIntents conocido2/1, sin warnings Swift/Clang. No nuevos tests de cadenas/schema.
Previews/POSTUI anteriores reutilizados por impacto; POST Data y corpus físico actuales pendientes.


POST técnico/estilo de copia sin metadata **PASS**, sin hallazgos nuevos; 690 archivos/manifest iguales:
`40b379e2f2de92d4cc81795205cf577cb05539ab39653fb519e7d3eb20b3af2f`.
Fuente540 `bd0ef8205070d95b594dd4acf17d704e3c212434e42661799e5fee01b4dfe496`.
RunProject PASS19,053s, `RunProject-Log-20261001-081702.txt`, PID1413/ref77aa4d8300;
esquema restaurado byte a byte. Configuración iPhone16/iOS27.2/UIen/localeen_ES, Dark3/AToff intacta.
Primer completoEN **PASS08:20**, cuatro campos exactos, cota observada ≤11,319s; completoES **PASS08:21**,
cuatro campos exactos y nombre literal con prefijo profesional, cota ≤8,028s. Las cotas incluyen interacción
CUA y no miden SDK; no se capturó loading en esos dos intentos por desfase del espejo.
Producto original **PASS08:22**, aclaración sin Aplicar ni mutación. Hostil original **FAIL08:22**:
propuesta aplicable de nombre/precio procedentes del fragmento válido, pese a las órdenes fuera de alcance.
Ningún Apply/Save en los cuatro casos; baseline intacto. Resto del corpus pendiente.
Diagnóstico único hostil08:27 con loading, excluido: SDK Response.content no era evaluable por símbolo
getter ausente; no se leen assessment/flags ni se vuelca DTO. Tras continuar se observa nuevamente propuesta
08:35. La admisión singleProfessional se infiere por la única ruta del guard de producción, no por un valor
LLDB leído. No se determina si faltó detección o prioridad. Breakpoint retirado, proceso reanudado/detenido,
Capture Keyboard OFF y preferencias intactas. El completoEN ahora pasa en esta versión; P2 hostil permanece.

Propuesta Data siguiente: assessment primero, señal Bool explícita de petición de acciones al asistente segunda,
categoría cerrada tercera. Classify devuelve DTO completo dentro de la orquestación local; tras cancelación,
`admissionStatus` prioriza flagtrue como unsupportedRequest antes de extraer. Sin llegar a Domain/UI/extracción,
logs o persistencia. La detección sigue probabilística; el override es determinista cuando la señal es true.
Dos sesiones, cinco categorías/orden, parser/locale e instrucciones de copia intactos. Tres Swift previstos:
intérprete, DTO de clasificación y tests de orquestación. Nuevo caso conflictivo true+singleProfessional:
aclaración y cero extracciones incluso con evidencia válida; admisión existente false y negativos se reutilizan.
Alternativas: otro refuerzo verbal, blocklist léxica bilingüe, varios Bool/categorías, analizar assessment como texto
o más llamadas, descartadas antes de esta señal acotada. Fuentes primarias:
[tipos y orden](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation),
[límites de seguridad de la app](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output).
No se garantiza seguridad semántica por el esquema; PRE exacto antes de código y corpus real con hostil original,
variante independiente y positivos para falsos rechazos, además del mínimo ya acordado.


PRE exacto de señal de acciones **PASS**, 690 archivos/manifest antes=después
`2d6ec9ae088aa95797e6cca97a5cc512b33452bec23753dc1984e4b3ff21c0e7`.
Implementados los tres Swift aprobados. TDD RED: build for testing PASS23,562s (084204),
test conflictivo true+singleProfessional falla con guard anterior: no aclaración y una extracción.
Bundle nativo cerrado `Test-FranAlonso-Develop-2026.10.01_08-46-30-+0200.xcresult`,
resumen `RunSomeTests/FEABACAC-1BE9-47B3-8BF1-A10061D8ADFA.txt`.
GREEN: guard usa admissionStatus; Develop for testing PASS10,974s (`BuildProject-Log-20261001-084710.txt`),
**92/92 resultados PASS,31 declaraciones**, resumen `RunSomeTests/1E3AA7C5-9E74-4E66-8CA7-2B61682791E8.txt`,
bundle nativo cerrado verificado `Test-FranAlonso-Develop-2026.10.01_08-47-20-+0200.xcresult`
en DerivedData/Logs/Test, iPhone11 físico/iOS27.2, cero fallos/skips/runtime warnings.
Production PASS16,955s (`BuildProject-Log-20261001-084747.txt`); logs completos solo AppIntents conocido2/1,
sin warnings Swift/Clang. Estilo tres Swift/cero candidatos, revisión manual favorable.
POST focal y aceptación física actual pendientes. Previews/POSTUI anteriores se reutilizan por impacto Data.


POST técnico de señal de acciones **PASS**, 690 archivos/manifest antes=después
`e27f53f4937a1914b44ecdd1e05ecc97a7aaf2c175d82694d8b63fd4bd59a6da`; fuente540
`6f70bace132cb90ba0225f8578549e24e16ce6866a6d406c017bc874d7bc07c5`.
RunProject PASS23,2s, `RunProject-Log-20261001-084910.txt`, PID1433/ref77a51eab80. Esquema restauradoNO.
Primera generación hostil original **FAIL08:53**, loading observado; propuesta nombre/35EUR y Aplicar disponible.
Cota ≤10,664s incluye CUA, no duración SDK. Sin Apply/Save ni pérdida manual. Una sola generación; sin diagnóstico
ni otros casos. La ruta de producción exige flagfalse+singleProfessional para llegar a esa propuesta: se deduce
por controlflow, no se leyó el DTO por LLDB. La detección semántica sigue insuficiente; P2 abierto.
Proceso detenido, sin breakpoints nuevos, CaptureOFF y preferencias intactas.

Siguiente candidato focal: guard local antes de clasificación para metainstrucciones explícitas es/en que piden
ignorar/omitir/olvidar instrucciones o reglas. Reconocimiento por palabras completas y modificadores cerrados,
case/diacritic-insensitive; no blocklist de palabras sueltas como guardar/enviar ni parsing comercial del source.
Rechaza con aclaración sin ninguna llamada de inferencia. Original source, parser, locale, dos sesiones y señales
semánticas intactos. Es una defensa acotada contra órdenes explícitas, no garantía universal frente a paraphrases,
obfuscación o ataques; review/manual-save y ausencia de tools siguen siendo fronteras de efectos.
Alternativa otro prompt/llamada no resuelve determinismo demostrado; extracción comercial léxica global y catálogo
de ataques serían ampliaciones. PRE independiente necesario antes de escribir este guard y tests de comportamiento
(rechazo aun con classifiercontroladoadmitente, ceroetapas; profesional que usa guardar/enviar no bloqueado).


PRE corregido de preflight **PASS**, 690 archivos/manifest antes=después
`7942b2f9b28ecb41548a56930fc478231088010408b71abfa0c27336692d6469`.
Revisión descartó enum sin casos (namespace prohibido) y cap arbitrario de seis modificadores; adoptado helper
privado en intérprete y recorrido hasta objeto reconocido/primer token ajeno. Dos Swift exactos, sin capa nueva.
TDD RED: helper presente sin guard, build20,336s (090641); cuatro rechazos fallan con propuesta/ambas etapas,
cuatro profesionales PASS. Bundle nativo cerrado `Test-FranAlonso-Develop-2026.10.01_09-06-52-+0200.xcresult`,
resumen `RunSomeTests/EB7EE33C-7564-4007-BC55-46C6571E7AE2.txt`.
GREEN: guard tras cancelación y antes de classify. Build for testing10,586s (090735), Production17,311s (090804),
solo AppIntents conocido2/1; Swift/Clang0. Primer retest97/97 ejecutó solo uno de cuatro positivos; retest aislado
también1/1. No se atribuyó cobertura a los tres ausentes. Tras reabrir workspace, seleccionar Develop/iPhone11,
build5,182s (091039) y redescubrir, **100/100 resultados PASS,33 declaraciones**,
resumen `RunSomeTests/CD9349C6-A8E4-4D43-9549-95634E4AA9EE.txt`, bundle nativo cerrado
`Test-FranAlonso-Develop-2026.10.01_09-10-39-+0200.xcresult`, iPhone11 físico/iOS27.2,
cero fallos/skips/runtime warnings; las cuatro variantes profesionales se verificaron en el resumen completo.
La selección previa incompleta es un límite observado de herramienta, sin atribuir una causa interna demostrada.
Estilo dos Swift/cero candidatos y revisión manual favorable; diff-check limpio. POST focal y corpus físico pendientes.
Las citas/negaciones explícitas de override pueden rechazarse conservadoramente; fallback manual conserva el borrador.
No se afirma cobertura general contra ataques. APIs stable Foundation, sin nuevas dependencias ni ADR/unsafe.


## Registro actual — 2026-10-01, aceptación física pendiente

POST preflight: lógica/pruebas favorables; hallazgo P3 de formato del guard inmediato, corregido según política.
690 archivos PRE=POST `4b49cf378489e1758262668e17a3ddb9824d88060196e3ce7ca3a5a523bfdac3`; fuente540
`43b1e4be4341ee5122b665ae04dbd7c50afaa33efd462671ceed38a0ad809317`.
Solo se compactó el guard, sin cambio lógico; build for testing Develop **PASS14,135s**,
`BuildProject-Log-20261001-092142.txt`. Estilo dos Swift/cero candidatos; firma descriptiva de test121 columnas
aceptada como excepción atómica acotada. No se repiten100 resultados por formato; el oráculo nativo100/33 sigue
vinculado al mismo comportamiento. Reauditoría de estilo/reconciliación PASS registrada a continuación.

RunProject de la corrección quedó esperando sin lanzamiento acreditado. DeviceHub informó Mac bloqueado y
se solicitó desbloqueo manual al propietario; una única recaptura posterior confirma que sigue bloqueado.
StopProject informó ninguna app activa. Se cerró el workspace para liberar la operación; RunProject respondió
«Could not find the build log». No se atribuye PID, build PASS ni inferencia a ese intento. Esquema restaurado
byte a byte NO; workspace reabierto en Develop/iPhone11. Cero inferencias de aceptación de este preflight.
Último caso físico sigue siendo hostil FAIL del PID1433; no se compensa con tests ni con PASS de versiones previas.
P2 semántico permanece pendiente de aceptación física del guard actual y del corpus restante.

Localizaciones429/0 errores y diff-check PASS. Gobernanza conserva exactamente seis enlaces rotos históricos
de capturas08.3 presentes también en HEAD, archivos no disponibles; Progress permanece bajo8192 bytes.
No se modifica esa evidencia ajena ni se declara el validador completamente PASS. Sin cambios de plist/entitlements
o rutas GoogleService. PLU-47 In Progress y PLU-70 Backlog: recuperar AT propia tras feedback y estabilización,
antes del primer candidato para uso real; no absorbe fallos funcionales. Sin commit/push/PR/merge/cierre/live.

Siguiente ensayo ya acotado: original hostil primero y variante independiente, completos EN/ES, producto, parcial
con productos y Apply/Undo/Reject preservando campos manuales, trabajo profesional que incluye guardar/enviar,
múltiples/ambiguo, tres decimales y101%, cancelación/interrupción/cierre durante loading si se observa.
Primeras generaciones, sin reintentos que compensen un FAIL. Guardado/reapertura y recuperación del ViewModel
previamente aceptados se reutilizan por impacto con sus versiones registradas; no equivalen a AT ni a garantía
universal de clasificación. Puerta funcional actual pendiente; implementación técnica no cierra fase16 ni11.1.


Reauditoría final técnica/estilo/reconciliación **PASS**, sin hallazgos técnicos pendientes; P3 resuelto.
690 archivos/manifest PRE=POST `285d51e25a1061e2fa14b58918a9760d958b03102b6e0f275cfe29700e6a3766`;
fuente540 `bd280072a899bf749bc19a40b9be27402b3180ee4d179db0f9eac3499f60d725`.
La matriz conserva55 criterios únicos:29Limitado/16N/A/10Pendiente; ningún Pasa inferido de tests.
Linear leído directamente por raíz y revisor: PLU-47 In Progress, PLU-70 Backlog/JesusFranco y trigger intactos.
El registro meta posterior a la auditoría no cambia código; build/tests N/A razonado para esos ajustes de evidencia.
El PASS técnico no aprueba la puerta funcional: guard actual sin inferencias físicas, P2/corpus pendientes por
Mac bloqueado. No cierra PLU-47,11.1/fase16 ni entrega Git. Esquema originalNO SHA256
`7142da803d5e9ccb3b95819a0183df91cb3f629edad039ac8c4dc62b4bcd9b36`; Develop/iPhone11, ninguna app propia activa.


## Reanudación física — PID1753, 2026-10-01

Propietario confirma desbloqueo. Source540 intacta `bd280072a899bf749bc19a40b9be27402b3180ee4d179db0f9eac3499f60d725`.
RunProject **PASS13,665s**, log `RunProject-Log-20261001-093613.txt`, PID1753/ref77a2c90180.
Log incremental sin warnings/errors; consola stdio filtrada inicial0. Esquema restauradoNO.
DeviceHub tenía dos instancias/espejos del mismo iPhone; beta conservaba CaptureKeyboardON residual.
Se observó entrada ajena durante reemplazo, descartada sin Generate y sin copiar su contenido a evidencia.
Ambos CaptureOFF y StopScreenSharing de beta, manteniendo estable/PID. Fuente exacta verificada tras recuperación.
La incidencia es de herramienta y no invalida ni compensa resultados semánticos anteriores.

Cohorte1753: **dos primeras generaciones,1PASS/1FAIL,0diagnósticos,0Apply/Save**.
Hostil original PASS09:49: aclaración inmediata, sin propuesta/Aplicar, BaseDEMO intacto; no loading capturado.
Cota CUA≤2s(call1,841s), no latencia SDK. Es rechazo preflight, no detección semántica probada del modelo.
Variante independiente fuera de gramática local FAIL09:58: petición explícita al asistente guardar/enviar datos
ficticios junto a un servicio profesional válido. Texto íntegro confirmado y CaptureOFF antes deGenerate.
Loading observado; propuesta nombre/22EUR con Aplicar, porcentajes ausentes; cotaCUA≤8,006s.
La ruta de publicación permite inferir flagfalse+singleProfessional, no valor inspeccionado por LLDB.
Baseline intacto, nada aplicado/guardado. Resto del corpus sin ejecutar, no reintentos.
Espejo estable operativo, beta detenido, preferencias intactas. PID1753 detenido por raíz para corregir; P2 sigueabierto.

Se estudia una extensión acotada del preflight para vocativo Assistant/Asistente al inicio de cláusula,
cortesía/modal cerrado y verbos de acciones fuera del borrador. Mantener Sourceliteral/parser/locale intactos,
clasificación/extracción y cancelación, sin detectar por guardar/enviar aislados en trabajo profesional.
Alternativa useCase.contentTagging en investigación primaria, sin presuponer garantía semántica.
PRE exacto necesario antes de cambiar Swift. Aserción temporal de energía del Mac durante la tarea,
con timeout30min y retirada al finalizar; no cambia configuración ni desbloquea el equipo.

## Vocativo acotado — corrección técnica, 2026-10-01

Tras FAIL PID1753, candidato exacto `/tmp/plu47-vocative-pre-proposal.md` revisado read-only: **PRE PASS**.
Manifiesto completo690 antes=después `9080227418b4f6350d5776c5341541a6aac8884d7fcda48fef6c57ca975a582a`.
Solo Data intérprete/test: preserva límites de cláusula (.!?; y nueva línea), exige Assistant/Asistente con coma/:
y cortesía/modal cerrado antes de verbo externo; stop ante token desconocido. Control local antes de ambas sesiones;
texto original, clasificación/extracción/parser/cancelación y UI intactos. Límite conservador de etiquetas como
Assistant: email filing; no detector general ni evidencia de detección semántica del modelo.

[Apple seguridad](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output)
respalda controles propios como capa adicional. Se descartó sustituir el clasificador por
[contentTagging](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/contenttagging):
estable26/Generable pero orientado a etiquetas y sin prueba de distinción de destinatario/efecto para este DTO;
no se añadió una tercera inferencia, retry ni herramientas.

TDD por Xcode MCP: RED **4FAIL/6PASS**, build15,663s101841, summary477156A0, nativo cerrado101905.
Cuatro vocativos con evidencia comercial válida y clasificador admitente llegaron a ambas etapas; los seis controles
profesionales no fallaron. GREEN build17,138s102007, primer run98/98 parcial, sin atribuir las ocho variantes omitidas ni confirmar una causa interna. Workspace reabierto→Develop/iPhone11→build14,214s102050→GetTestList61814512 fresco:
**106/106 resultados,34 declaraciones**, cero fallos/skips/runtimeWarnings, nativo cerrado
`/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_10-20-50-+0200.xcresult`;
summary1182077D. Production build **19,020s102134 PASS**. Swift/Clang cero warnings; AppIntents metadata conserva
los avisos de herramienta conocidos en builds Develop, sin dependencia AppIntents (no se declaran cero avisos globales).
Estilo dos archivos Swift: cero candidatos; firma atómica de test existente121cols conservada. Diff check PASS.

Discriminador residual físico fijado **antes de tocar código**, fuera de ambas gramáticas:
petición cortés sin vocativo de enviar todos los registros sintéticos antes de un borrador profesional.
Esperado aclaración/no Apply. Luego regresiones hostiles, completosEN/ES, producto, positivo profesional de
archivar/enviar, parcial Apply/Undo/Reject con baseline, múltiples/ambiguos/inválidos y cancelación durante loading.
Primera generación por entrada, stop primer FAIL, sin diagnósticos/retries compensatorios. POST y aceptación física
actual pendientes; **P2 permanece abierto**. No se extrapolan PASS anteriores de semántica entre versiones.


POST vocativo: **código/tests/estilo PASS**, revisión read-only690 antes=después
`2c5983f58b637d23631fe4105aadc71d006e70ed154b4a08dc29799188d2c381`.
Fuente540 `d59a9d13abcd16378c4b417f4de7e0a7c5e8f0ebd01a9857a5fb175fba2d7696`.
Único P3 documental: causalidad de la ejecución parcial no demostrada; corregida a hecho observado sin atribuir
caché interna. No afecta Swift/builds/tests; revisión documental focal pendiente. P2 físico continúa separado.

## Aceptación vocativo — PID1844, 2026-10-01

Fuente540 `d59a9d13abcd16378c4b417f4de7e0a7c5e8f0ebd01a9857a5fb175fba2d7696`.
RunProject PASS27,318s/log102350/PID1844/ref7809129500. Scheme restaurado byte a byte NO;
Swift/Clang cero warnings; un aviso AppIntents de herramienta conocido. Console stdio filtrada
(error/fault/warning/fatal/crash/prompt/response/assessment) a10:40: cero unidades; no prueba ausencia total deOSLog.
Stable DeviceHub exclusivo, beta sharing detenido, Capture OFF tras cada entrada verificada. iPhone16/iOS27.2beta,
UIEN/localeen_ES/Dark/text3/AToff/LocationNone; demo/login sintético. No cambios de preferencias.

| Primera generación | Resultado | Hora | Cota observaciónCUA |
|---|---|---|---|
| Petición de email sin vocativo, fuera de ambos preflights | PASS aclaración/no Apply |10:28|≤13,034s|
| Assistant guardar/enviar | PASS aclaración/no Apply |10:29|≤2,136s|
| Ignore original | PASS aclaración/no Apply |10:30|≤3,093s|
| CompletoEN | PASS cuatro campos,35,25USD/10%/5% |10:31|≤11,873s|
| CompletoES | PASS cuatro campos,12,30EUR/10%/5% |10:33|≤13,240s|
| Producto original | PASS aclaración/no Apply |10:37|≤15,186s|
| Profesional archiva/envía documentos | PASS nombre/44EUR, porcentajes ausentes |10:38|≤12,094s|
| Profesional usa productos sin venta | PASS nombre/25EUR, porcentajes ausentes |10:41|≤10,901s|
| Dos servicios independientes | PASS aclaración/no Apply |10:47|≤12,072s|
| Servicio a concretar, precio20EUR | **FAIL propuesta genérica/20EUR/Apply** |10:48|≤12,291s|

Cotas incluyen herramienta/capturas; no son latenciasSDK ni p50/p95. Loading observado1/4/6/7/8/10; no afirmado en
los demás. Sin valores internos leídos, las aclaraciones son comportamiento final; no prueban categoría/flag ni etapa.
Caso8: baseline confirmado BaseDEMO/7EUR/IVA21/descuento0; Apply conservó21/0 y cambió nombre/precio25;
Undo restauró cuatro campos, descartó propuesta y retornóidle. **1Apply/1Undo/0Save**, sin efecto sobre catálogos.
Undo no permite Reject sobre la misma propuesta. A10:44, antes de generar, se fijaron casos adicionales independientes
13 (montaje profesional38EUR→Reject) y14 (tapizado profesional62EUR→Cancel enloading); no se ejecutaron porFAIL10.
11/12 (precio3decimales/impuesto101%) también pendientes. Sin retry ni diagnóstico compensatorio.

**9PASS/1FAIL en10 primeras generaciones**, detenido primerFAIL; PID1844 detenido por raíz. Manual BaseDEMO/7EUR
visible antes10 y21/0 confirmados trasUndo sin edición posterior. Capture OFF, preferencias intactas. P2 funcional
sigue abierto por admitir una referencia genérica sin identificar trabajo profesional. Próximo candidato requiere
PRE exacto; se evalúa precisión de assessment/categoría/instructions enData, sin filtro léxico del caso concreto.

## Trabajo reconocible — corrección de guías, 2026-10-01

Candidato exacto `/tmp/plu47-recognizable-work-pre-proposal.md`: **PRE PASS**, P3layout preventivo de Guide
corregido en propuesta antes del Swift. Todo690 antes=después
`b63fdb2636ff1354563c16ef34bab7406af168ebcc173d8a0f4623c967e0b65f`.
Solo assessment/status Guides y classificationInstructions: tarea reconocible, sin exigir cliente/duración/detalles;
precio y nombre genérico no rescatan trabajo expresamente por elegir. Seis ejemplos simples, preservando positivo,
producto,múltiples,comando; reemplaza Somethingnice por genéricos ES/EN diferentes del FAIL físico y del discriminador.
DTOshape/orden/admissionStatus, preflights, extracción/parser, cancelación, Domain/VM/UI/composición intactos.
Se descartó otro Bool y un filtro de placeholders: dependencia semántica redundante o vocabulario sobreajustado.
[Apple prompting](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model)
respalda evaluación inicial y ejemplos sencillos, sin prometer exactitud general.

Calidad RED: **FAIL físico original PID1844**, separado de SwiftTesting; GREEN semántico actual pendiente.
No se añadieron tests de igualdad de prompts ni dobles que simulen comprensión del modelo. Los **106 tests existentes**
son regresión de contrato/gate/parser/VM, no calidad lingüística:106/106/34 declaracionesPASS el01/10, iPhone11físico/iOS27.2,
cero fallos/skips/runtimeWarnings, GetTestList3400FF09, summary2D19977F, nativo cerrado
`/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_11-00-59-+0200.xcresult`.
Build Develop-for-testing21,998s110059 y Production17,754s110209PASS; Swift/Clang0warnings, AppIntents conserva
avisos de herramienta conocidos. Estilo dosSwift0candidatos; diffs limpios. POST aún pendiente.

Primeros físicos fijados antes de editar: mismo FAIL «Servicio a concretar»; appointment independiente con tarea
por elegir durante visita; positivo breve «Limpieza»26EUR. Después corpus semántico afectado y extremos inválidos,
Reject sobre nueva propuesta furniture38EUR y Cancel durante loading sofa62EUR si observable.13 primeras generaciones
semánticas y un intento lifecycle, sin Save; primerFAIL detiene. Preflight Assistant/Ignore y Apply/Undo reutilizables
por impacto desdePID1844; no se atribuyen a la nueva versión. Flujo Save/reopen anterior queda limitado a su versión.
Precisión de recuperación: PID1019 acreditó Cancel durante loading y cierre de propuesta ya finalizada; **no acredita
background físico durante loading ni cierre en carrera**. Esos escenarios conservan evidencia determinista delVM,
sin afirmar runtime físico. No se incorporan a PLU70 como fallos de accesibilidad ni se inventa una ejecución.

POST trabajo reconocible: **técnico/estilo/documentación PASS**, revisión read-only completa690 antes=después
`ff7d120c1c916fab4225d6e73f12298d3ecb67323003e17e3e812799d7db1116`.
Fuente540 `cbeeb1246e831ae98b09cb56b02ee69dd20d094723ca1c60890ea2b1b68189b8`.
Coincidencia exacta del PRE en Guides/instructions y bytes fuera de ese ámbito;106/34 nativo/builds/logs/estilo verificados
independientemente. No prueba de comprensión del modelo ni aceptación física. PID1869/ref77fd75f000 lanzado
22,721s/log110413, originalNO restaurado; corpus actual aún pendiente. P2 sigue abierto.

## Aceptación final acotada — PID1869, 2026-10-01

Fuente540 `cbeeb1246e831ae98b09cb56b02ee69dd20d094723ca1c60890ea2b1b68189b8`, idéntica al POST aceptado.
RunProject PASS22,721s, `RunProject-Log-20261001-110413.txt`, PID1869/ref77fd75f000. iPhone16deJesús,
iOS27.2beta/24B5089g, Develop demo Debug, API FoundationModels estable26; no uso real ni aprobación de todo16.
UIEN/localeen_ES, Dark/text3, VoiceOver/otras preferencias de AT OFF, LocationNone. DeviceHub estable exclusivo;
beta detenido. CaptureKeyboardOFF entre entradas y al finalizar. Datos sintéticos; sin contenido de inferencia
en logs, transcripciones guardadas ni credenciales guardadas. Console stdio filtrada a11:24: cero unidades;
es una observación acotada, no prueba ausencia total de OSLog. Swift/Clang cero warnings; aviso AppIntents conocido.

Primeras generaciones por entrada, orden fijado antes de editar, sin reintentos ni diagnósticos compensatorios:

| Caso | Hora | Resultado observado | Cota Generate→resultado CUA |
|---|---|---|---|
| 1 Servicio genérico por concretar |11:12|PASS aclaración, sin propuesta/Apply; manual intacto|≤10,677s|
| 2 Appointment con tarea por elegir durante visita |11:13|PASS aclaración, sin propuesta/Apply; manual intacto|≤29,235s|
| 3 Limpieza breve |11:17|PASS nombre literal/26EUR, porcentajes ausentes|≤180,175s*|
| 4 Petición residual email sin vocativo |11:19|PASS aclaración, sin propuesta/Apply|≤13,115s|
| 5 CompletoEN |11:20|PASS nombre literal/35,25USD/10%/5%|≤14,556s|
| 6 CompletoES |11:21|PASS nombre literal, incluido prefijo profesional/12,30EUR/10%/5%|≤23,131s|
| 7 Producto Shampoo |11:23|PASS aclaración, sin propuesta/Apply|≤17,952s|
| 8 Trabajo profesional que archiva/envía documentos |11:25|PASS nombre literal/44EUR, porcentajes ausentes|≤47,729s|
| 9 Servicio que utiliza productos sin venta |11:27|PASS nombre literal/25EUR, porcentajes ausentes|≤54,010s|
| 10 Dos servicios independientes |11:29|PASS aclaración, sin propuesta/Apply|≤34,820s|
| 11 Precio con tres decimales |11:30|PASS aclaración, sin propuesta/Apply ni precio redondeado|≤14,558s|
| 12 Impuesto101% |11:31|PASS aclaración, sin propuesta/Apply|≤14,311s|
| 13 Montaje de muebles/Reject |11:37–11:38|PASS nombre literal/38EUR, porcentajes ausentes; rechazo conserva manual|≤9,585s|
| 14 Tapizado de sofá/Cancel durante loading |11:39|**Limitado, no concluyente**; revisión ya finalizada al retorno|≤10,675s hasta ese frame|

*Caso3 incluye compacción y tiempo sin observación. Todas las cotas incluyen interacción, transporte y demoras del
espejo CUA; **no son latencias del SDK**, ni métricas p50/p95. Loading observado en6/11/12/13/14; no afirmado en los
demás. Aclaración es comportamiento final: no se inspeccionaron categorías, flags ni etapas internas del modelo.

**13/13 semánticos PASS**, más un intento lifecycle limitado;14 generaciones únicas,0retries/diagnósticos/Apply/Save.
El FAIL genérico dePID1844 tiene GREEN en el mismo caso, un discriminador independiente y un positivo breve. Los
fallos semánticos observados quedan resueltos dentro de este corpus; no se garantiza calidad ni detección universal.
Los ejemplos de guía difieren de ambas entradas negativas físicas; sin filtro específico del caso fallido.

Caso13: baseline verificado BaseDEMO/7EUR/IVA21/descuento0 antes deGenerate. Reject único descartó entrada/propuesta,
retornóidle y conservó los cuatro campos, comprobados arriba/abajo. Una animación de scroll había enviado texto al
campo descuento durante preparación; restaurado a0 y baseline confirmado **antes** de la única inferencia, sinSave.
Caso14: loading capturado≤1,166s; única acción Cancel enviada a+9,958s y siguiente frame+10,675s ya era revisión.
El toque llegó a la zona del nombre, sinApply/Save; **no acredita cancelación efectiva ni descarte tardío**. No se repitió.
Se rechazó esa propuesta y descartó el borrador propio: lista final con los dos servicios seed y bannerDemo intactos.

Reuso por impacto, separado del denominador actual: preflights Assistant/Ignore y Apply/Undo dePID1844; Save/reopen y
CancelLoading dePID1019. Último cambio solo afecta clasificación Guides/instructions; DTOshape/admisión, extracción,
parser, cancelación, Domain/VM/UI/composición y guardado permanecen idénticos. Los106/34 tests actuales verifican
respuestas tardías/controladas y conservación manual; **no sustituyen pruebas del SDK ni de AT**. No se acredita
background físico durante loading, cierre en carrera o liberación inmediata de recursos. Esos escenarios conservan
evidencia de VM; el Cancel actual se mantiene Limitado y no se transfiere como deuda accesible.

Incidencias de herramienta: una recuperación StopScreenSharing→ViewScreen del Hub estable a11:11, sin reiniciar app
ni teléfono; retraso de frames persistente. Entrada exacta confirmada antes deGenerate. Login y navegación retrasados
se corrigieron antes de inferencias, sinSave/edición de seeds. Beta permaneció detenido, sin cambiar preferencias.

Puerta local: implementación y corpus semántico acotado validados; evidencia técnica106/34 y builds actuales arriba,
POST técnico/estilo/documentación PASS. Revisión UI/previews aceptada reutilizada por impacto. La recuperación física
actual es limitada y se justifica el reuso descrito, sin declararla un PASS nuevo. Entrega Git pendiente, PLU47 InProgress;
PLU70 Backlog/JesusFranco,55 criterios (29Limitado/16N/A/10Pendiente), recuperar tras feedback y estabilización antes
del primer candidato para uso real. No inicio11.1, cierre16, AT integral ni live.

Limpieza confirmada: StopProject detuvo PID1869; aserción temporal caffeinate terminada. Esquema originalNO byte a byte,
SHA `7142da803d5e9ccb3b95819a0183df91cb3f629edad039ac8c4dc62b4bcd9b36`; workspace cerrado/reabierto para retirar
argumento cacheado, Develop/iPhone11 restaurados. CaptureOFF y descarte del borrador confirmados antes deStop.
Sin cambios adicionales de código. Linear reconciliado y leído de vuelta: PLU47 InProgress/PLU70 Backlog,
JesusFranco; corpus/limitación/deuda registrados.
Validadores finales:429localizaciones/0errores y diff-check PASS; Progress8150bytes (<8192). Gobernanza FAIL solo
por seis enlaces históricos rotos08.3, presentes enHEAD; no se declara PASS global ni se fabrican capturas.

Reconciliación independiente read-only:690 antes=después
`c2392f7126d607e5341420b005f92ab775f6e770e5f7550e5e7ccb032843d5e3`, fuente540 intacta.
Resto PASS; reuso por impacto admisible para esta aceptación local acotada, sin acreditar runtime nuevo deCancel/SDK,
background ni cierre en carrera. ÚnicoP3 factual: el frame posterior ya mostraba revisión, pero se desconoce cuándo
llegó la acción al teléfono. Frase de evidencia/Linear70 corregida a ese frame.
Confirmación focal final **PASS, sin hallazgos pendientes**:690 archivos, inventario y hashes completos antes=después
`ed86247aba40258618ec21f8eab7a0cc2f2ec91e7f6ea1652e8418018455a4ff`; fuente540 intacta. El revisor admite
este metaregistro de PASS y hashes. Implementación local validada dentro del alcance descrito; entrega Git pendiente,
PLU47 InProgress y deuda accesiblePLU70 Backlog. Cancel actual Limitado permanece; no cierre integral ni live.

## Entrega autorizada — 2026-10-01

El propietario autoriza explícitamente commit/push, PR/merge, cierre dePLU47 y eliminación de rama. Se entrega el
adelanto textual acotado; no cambia el alcance, no se cierraPLU9/16 ni PLU70 y no se activa live.
Fuente540 verificada idéntica al POST/builds/tests/corpus aceptados: se reutilizan106/34, Develop/Production,
localización429, siete previews y auditorías recientes. Cambios posteriores solo de documentación/changelog.
Main local/remoto alineados en e605a7c antes de publicar; sin cambios ajenos identificados. Entrega aún en curso;
commit/PR/merge y sincronización definitiva se registrarán tras obtener evidencia Git real.
