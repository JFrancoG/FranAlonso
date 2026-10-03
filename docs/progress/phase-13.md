# Fase13 — Facturación, PDF, correo y numeración

## 13.7 / PLU-103 — Entrega autorizada en preparación

03/10/2026: «commit, push y entrega» autoriza el circuito establecido de commit/push/PR/revisión/merge,
cierre dePLU-103 y eliminación segura de rama integrada. Fase13/proyecto permanecen abiertos;
sin live ni inicio13.8. Issue In Progress antes de publicar; main/origin/main siguen7db053d,0divergencia.
Sin PR13.7 existente. GitHub permite merge commit; main sin protección/rulesets/workflows configurados.
Eso no acredita CI. Preservar aceptación y deuda previa antes del merge que puede automatizar el cierre.

Los11Swift mantienen hashes finales y manifest probado
`db5aaa41ad192c27b46826256f587a515cf820ef0664773c8205313d0276b38a`.
Se reutilizan51casos nuevos completos/12grupos,238afectados y2685globales PASS, RED51/51,
buildsDevelop/Production y revisionesPRE/POST/PDF/estilo independientes. No cambios ejecutables,
configuración ni recursos después; Xcode nuevo N/A para metadatos de entrega.
0diagnósticosSwift/Clang,2/1avisosAppIntents conocidos;607textos/0errores y6linksDesktop08.3 históricos.
Stock118 histórico no corregido; PASS global único no acredita estabilidad. Cancelación durante render
solo revisada estáticamente. PDF-UA/fiscalidad/protección física/AT no acreditados; UI N/A sin alcanceSwiftUI.
13.8 conserva mapping comercial/fiscal/partición/revisión visual real; PLU-101/deuda previa permanecen
Backlog/Jesus/feedback/estabilización antes de uso real. Sin nuevos aplazamientos ni transferencia de privacidad.
Revisión independiente focal `billing_13_7_delivery` **PASS**, sin hallazgosP0–P3;
997archivos inicial/final/revisor/root idénticos
`2e009323a57dcba7180902054a5b6aa88afe1a6ba5de1f76ea34765648c1b62e`.
Tras freeze solo se registra el dictamen;11Swift/configuración/recursos conservan identidad probada.
Revisión remota del diff/head exactos pendiente antes de integrar.

## 13.7 — Historial de implementación local

03/10/2026: «abre issue y rama e implementa13.7» autoriza apertura e implementación local.
[PLU-103](https://linear.app/plusprojects/issue/PLU-103) In Progress, Jesus Franco, relacionado conPLU-102;
rama `codex/plu-103-billing-pdf-renderer` desde main/origin/main `7db053d` limpio.
[Propuesta exacta](13-7-billing-pdf-renderer-proposal.md): motor de páginas/campos íntegros con encabezados
confirmados, template A4 y firma opcional, actor fuera de MainActor. Determinismo semántico, no bytes Quartz.
13.8 conserva composición financiera/fiscal/partición y revisión visual real. PRE independiente PASS sin hallazgosP0–P3;987archivos,
huella root/revisor inicial/final idéntica `adb894bc623af15d0e27ecbe74f8d076881f2e1274de1b77657e4d3331cf76af`.

### Implementación y TDD

Domain: portSendable async, plan efímero validado, geometríaA4/campos/páginas/firma opcional; sin importsUI/Data.
Número definitivo y fechaUTC del documento confirmado en todas las páginas; plan explícito íntegro y
ordenado, texto Unicode seleccionable/extractable. Actor Data con CoreGraphics/CoreText/ImageIO locales,
sin reloj/FS/red/auth/caché; checks de cancelación y cierre del contexto antes de publicar Data.
Rango UTF16 visible completo y bounds reales de glifos obligatorios; overflow/layout/recursos inválidos
fallan sin bytes parciales, recorte ni reducción implícita. Firma aspect-fit solo en última página.
Shared validator extrae13.6 sin alterar reglas; factoryApp concreta inactiva.11Swift, sin UI/assets/configuración.
Límites:1...100páginas,1...200campos/página,20.000UTF16/campo,200.000total, font6...24pt,
fecha0001...9999; template≤1MiB y firma≤2MiB/4.194.304px conservan políticas13.6.

RED compilable20:36:49 **0/51PASS**,22declaraciones, comportamiento ausente y guards aún sin implementar;
summary `RunSomeTests/F39197A2-E175-4F0E-AA4A-B3DEE98EEA08.txt`.
Dos builds anteriores detectaron try faltante en macros de fixtures, corregido sin expectativas; no son RED.
Primer GREEN20:38:55 **33/35PASS**, selección parcial de argumentos: fecha0001 desplazada dos días y
oráculo raster magenta fallido. Diagnóstico Swift Testing20:44:30 conserva ambos fallos y demuestra
que FormatStyle/ISO8601/Calendar actuales dan0001-01-03; RGB calibrado da[255,64,255] y también falla
un rectángulo dibujado por el oráculo independiente. Fixture/oráculo fijan DeviceRGB explícito, sin
cambiar umbral/presencia/proporciones; focal firma1/1PASS (`52AB6844-B103-4D9C-9DDA-7A15496E1E3C.txt`).
RunCodeSnippet20:41:46 fue inconcluso: preview dyld no cargó libSystem.B.dylib; no fue fallo del producto.

PRE focal fecha `billing_13_7_pre` PASS antes del cambio;997archivos inicial/final/root idénticos
`af57e491442f5732a5dd170c6dad70b9b96e20e0b5114579b2a2368063440868`.
DateFormatter vigente local al actor, en_US_POSIX/GMT/yyyy-MM-dd y corte gregoriano0001 explícito;
FormatStyle no expone corte equivalente. Razón/API documentadas, sin opt-out/ADR/dependencia nueva.
GREEN fecha+firma5/5PASS, `RunSomeTests/4CC20E3B-2E3C-4713-A561-37467C4451C3.txt`.

### Validación completa

**RunAllTests20:51:45:2685/2685PASS**,1635declaraciones,0failed/skipped/expected/notRun;
summary `RunAllTests/791655B7-6F06-4BB1-9EC5-FA11430AFB0C.txt` en
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`.
Bundle nativo válido: `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.03_20-51-45-+0200.xcresult`.
xcresulttool confirma **22declaraciones/51casos nuevos completos PASS**,12grupos parametrizados
de2/2/4/2/4/2/2/5/5/4/2/7 argumentos completos; no se infiere cobertura total de focal parcial.
Billing+AuthenticationRoot+ClientSignedDocument **138declaraciones/238casos completos PASS**;
templates13.6 **13declaraciones/20casos PASS**. Incluye100páginas, contenido Unicode ordenado,
metadata/encabezados/repetición semántica entre actores, límites/overlap/overflow, ausencia/firma final
y proporciones, fallo recuperable/cancelación sin sleeps y callerMainActor usando el port real.

Tras global solo wrapping horizontal de una llamada CTFontCreateWithName, sin cambio semántico;
fuente final build-for-testingDevelop20:53:02 **12.81sPASS** y Production20:54:11 **28.243sPASS**.
Logs `BuildProject-Log-20261003-205302.txt` / `BuildProject-Log-20261003-205411.txt`, carpeta
ActionArtifacts/default/BuildProject anterior:0errores/diagnósticosSwift/Clang; únicamente2/1avisos
AppIntents metadata conocidos. Builds incrementales, sin afirmar clean-build ni cero warnings globales.
Focal finalUnicode/firma/callerMainActor **3/3PASS**, summary
`RunSomeTests/FFC270E5-7EB0-44CE-90C7-BDD54357F198.txt`.
Develop/planDevelop/iPadPro13(M5) inicial restaurados; SDK27.0/Simulator27.2.
Una única ejecución global13.7; Stock118 pasa aquí, fuente intacta SHA256
`98fc8bac80f10492150b8120d7391d627ac53bb9902e915d66437246ef1f4590`.
El fallo histórico13.6 sigue registrado; este PASS no acredita corrección ni estabilidad de su lifetime.

Localización607es/en/0errores; governance exit1 solo6links Desktop08.3 históricos; diff--checkPASS.
Ticket/invoice bundle conservan SHA256 `4d4efabdb58501a19274b40794ed3a8fb935112017ba67d1496b3df7d612ad14`
y `7180f83a5ecdfc1e0126e40f8ac5182e5961405a3f02025360a9e8fd12073b80`.
Sin firmas/PII/payload real, plist privado ni material sensible nuevo en Git/logs.

### Auditoría y gates

POST independiente `billing_13_7_post`: sin hallazgosP0–P2; P3 de tres llamadas nuevas con cuatro
argumentos horizontales en motor/Rectangle/TextField. Scanner0candidatos no detecta esta categoría;
revisión manual de11Swift lo identificó. Solo wrapping vertical corregido, sin argumento/behavior cambiado.
Originales de esos tres archivos reconstruyen sus SHA256 auditados; los8Swift restantes byte-idénticos.
Manifest auditado11Swift `7d00892829c4fc73c8d67a12eb134dac4d739e0b808569422e53f7c82f4f6543`.
Nueva compilación final Develop-for-testing21:07:56 **12.703sPASS** y Production21:08:17 **19.806sPASS**;
logs completos `BuildProject-Log-20261003-210756.txt`/`BuildProject-Log-20261003-210817.txt`,0errores/
diagnósticosSwift/Clang y2/1avisosAppIntents conocidos. Develop/plan/destino inicial restaurados.
Matriz completa20:51:45 reutilizada por identidad semántica; tests/expectativas permanecen byte-idénticos.
Diagnósticos Xcode de11Swift success=true/0issues; estilo11Swift/0candidatos, sin líneas>120.
Reauditoría focal independiente `billing_13_7_post` **PASS**, sin hallazgosP0–P3 restantes;
solo ámbito de ese hallazgo, sin repetir auditoría funcional/AT.997archivos inicial/final/root idénticos
`390fba825ac9833a5c95c5569aa0d2af7c4890bf9c97997b0c79175e2957236c`.
Manifest final11Swift `db5aaa41ad192c27b46826256f587a515cf820ef0664773c8205313d0276b38a`.
Tras freeze solo se registran dictámenes y paridad Linear; fuentes/configuración/recursos intactos.

Revisor independiente `billing_13_7_post_accessibility`: PASS PDF focal, sin hallazgosP0–P3;
puertaUI **N/A: sin alcanceSwiftUI**, no previews/Inspector/runtimeAT manual ejecutados.
Ambos revisores/root comprobaron997archivos inicial/final idénticos
`485a1197a231384692c4e2cf21fcd20dd38059133d2dc35c90cda4ea9e86f611`.
Cancelación previa probada; cancelación durante el render revisada estáticamente, sin afirmar prueba runtime.
UI/previews/AT nuevos N/A para este motor sin pantallas; no se afirma taggedPDF/PDF-UA/fiscalidad.
13.8 debe mapear snapshots, particionar ventas completas y revisar visualmente templates reales.
Protección física privada13.6 sigue limitada/pendiente; deudaPLU-101 Backlog/Jesus tras feedback y
estabilización antes del primer candidato real. No aplazamientos nuevos ni transferencia de privacidad.
Paridad Linear verificada tras actualización19:12:04/05UTC: PLU-103/proyecto In Progress,
descripciones con implementación/validación/dictámenes/límites; rama exacta preservada, deuda previa vinculada.
Sin parent/milestone13. HEAD permanece7db053d y staging vacío; implementación local lista para entrega.
Sin commit/push/PR/merge/Done/live/13.8 autorizados.

## 13.6 / PLU-102 — Entregada funcionalmente; Done

03/10/2026: «commit, push y entrega» autoriza el circuito establecido completo.
[PR55](https://github.com/JFrancoG/FranAlonso/pull/55) MERGED a main a17:59:00UTC;
feature `bb61b068d9cfe2ad7bea0c03aff6d5f662c9c854` → merge `4be44f989757a71def12f5493a6cd94ceaf0886a`.
Árbol completo integrado idéntico al feature auditado, tree `f95204a391e1b67821e784f2f10f058ba673a9f9`;
14Swift conservan manifest probado `3500f614414c4e1552a440f71de63f15dee56366cbf3e88e2e9114b268234468`.
[PLU-102](https://linear.app/plusprojects/issue/PLU-102) Done verificado tras merge, updated17:59:02UTC;
no se ejecutó una mutación manual de estado. Rama `codex/plu-102-billing-template-assets` eliminada
local/remota tras verificar ascendencia a main/origin/main, head remoto exacto y0commits únicos.
Main/origin/main sincronizados al merge; cierre documental final preparado debajo.

Revisión final focal de preparación de entrega independiente PASS, sin hallazgosP0–P3;
freeze986 inicial/final/revisor/root idéntico
`38af5bd2d217f266704bb3a1c96f9d26e82f7170abc391f1047540b83c524e3b`.
Revisión remota focal independiente PASS sobre18paths, headbb61b06/base d867fb1; diffPR/local idénticos
SHA256 `0e33bb78302b3be5554eb281542e17561744e53716f0c06e814fa11421853569`.
Freeze986 inicial/final/revisor/root idéntico
`5a63052c99ca8e060a717528641d3074b01e20c5738a77ba5bdc59392fab4b24`.
Review GitHub COMMENTED desde cuenta propietaria, basada en agente independiente read-only,
sin representar aprobación humana de otra cuenta. CLEAN/MERGEABLE antes del merge; sin checks/Rules/workflows
configurados, no equivale a validación CI. Merge con head exacto, sin force-push; criterios/estado releídos antes.

Se reutilizan52casos nuevos completos/35declaraciones y181casos afectados PASS, buildsDevelop/Production,
PRE/POST y estilo favorables; todas las fuentes/configuración/recursos conservan identidad.
**Global final2633/2634 conserva único fallo previo StockSyncDurabilityTests118**, fuente intacta;
no corregido ni atribuido, no se declara regresión global verde.2/1avisosAppIntents y6linksDesktop08.3 previos
conservan límites;607textos/0errores. Evidencia completa, RED/GREEN y parámetros en historial debajo.
Cierre funcional de alcance13.6: firma ausente opcional, recursos validados y defaults productivos que exigen
protección completa y deniegan nil/none. Protección física limitada/pendiente antes de uso real; no aplazada
como accesibilidad ni declarada seguridad integral. UI/previews/accesibilidad nueva N/A por ausencia de cambio.
PLU-101/deuda previa Backlog/Jesus, recuperación tras feedback/estabilización antes de candidato real, intactas.
Fase13/proyecto siguen In Progress, sin parent/milestone13;13.1–13.6 entregadas funcionalmente.
Siguiente gate separado13.7: BillingPDFRenderer, sin autorización/inicio; live inactivo.

Cierre documental limitado a Progress/phase13/CHANGELOG; Xcode nuevo N/A, fuente/configuración intactas.
Auditoría documental final focal PASS, sin hallazgosP0–P3 pendientes sobre esos tres archivos;
paridad de descripciones Linear corregida y verificada, Progress8145bytes.
986archivos, huella inicial/final/revisor/root idéntica
`339954b25efe24279f4692ac252d3468ad2f03282d95d8aa32db77fb95c81f62`.
Tras freeze solo se registra dictamen; fuentes/configuración/recursos conservan identidad probada.

## 13.6 — Historial de preparación de entrega

03/10/2026: «commit, push y entrega» autoriza el circuito establecido de commit/push/PR/revisión/merge,
cierre funcional en Linear y eliminación segura de rama. Fase13/proyecto y deuda previa permanecen abiertos;
13.7 y live conservan autorización separada. PLU-102 In Progress hasta verificar integración y cierre.
Se reutilizan por identidad exacta14Swift y configuración los52casos nuevos completos/35declaraciones,
181casos afectados y builds Develop/Production, PRE/POST/estilo PASS descritos debajo. El único cambio posterior
es documentación de entrega/CHANGELOG; Xcode nuevo N/A por ausencia de código/configuración adicional.
Global final2633/2634 conserva fallo histórico Stock118, fuente intacta; no se declara regresión global verde.
2/1avisos AppIntents y6links Desktop08.3 previos conservan sus límites. Firma opcional ausente funciona sin
lectura privada y default productivo deniega nil/none; protección física sigue limitada/pendiente antes de uso real.
UI/previews/accesibilidad nueva N/A; PLU-101/deuda previa conservan dueño/feedback/estabilización y puerta real.
Entrega funcional de alcance13.6, sin afirmar seguridad integral/fiscalidad/uso real ni introducir aplazamientos nuevos.
Revisión final focal de documentación y gates de entrega independiente PASS, sin hallazgosP0–P3;
986archivos inicial/final/revisor/root idénticos
`38af5bd2d217f266704bb3a1c96f9d26e82f7170abc391f1047540b83c524e3b`.
Tras freeze solo se registra dictamen;14Swift/configuración/recursos conservan identidad probada.
Revisión remota del head exacto pendiente antes de integrar.

## 13.6 — Historial de implementación local

03/10/2026: «abre issue y rama e implementa13.6».
[PLU-102](https://linear.app/plusprojects/issue/PLU-102) In Progress/Jesus Franco;
`codex/plu-102-billing-template-assets` desde main/origin/main limpio `d867fb1`.
[Propuesta y fuentes](13-6-billing-template-assets-proposal.md). Perfil maintenance, iOS27/Swift6
complete/nonisolated, capas actuales; sin configuración/dependencia/unsafe/live nuevos.

### Autoridad y PRE

PRE independiente `billing_13_6_pre` PASS sin hallazgosP0–P3 antes del código;974archivos,
huella inicial/final/root `4646a427e010f6842f38eb7418349d3b7f5ba1fe782ee01ac204250de64071b9`.
Verificador por limitación de Simulator revisado antes del código: PRE focal PASS,985archivos
inicial/final/root `32ea0aa7b3bf170da049cf85f9dc01cc4cd886897deff8b8c88fbf6bcdadb4ef`.
Corrección de recuperación revisada antes del código por `billing_13_6_post`: PRE focal PASS,985archivos
inicial/final/root `e1a4210bd97fa60c37deebcce15dec28b966b525336a76bed5bc216364cd2de7`.
Fuentes Apple completas PDFKit/ImageIO/protección/backup/reemplazo y URLResourceValues.fileProtection;
web JS/Markdown no siempre extraíble, disponibilidad confirmada compilando SDK27.0.
SE-0306 fundamenta reentrancia y commit síncrono aislado.

### Implementación

Domain: contratos de plantilla y firma opcional, capacidad de principal con validación async y fallos neutrales.
Data: actor bundle y adaptador privado inmutable; coordinador actor compartido posee todo su filesystem.
FileHandle acotado, PDFKit e ImageIO locales sin cruzar actores. PDF≤1MiB, cabecera/EOF, no cifrado/locked,
una página A4 portrait sin rotación, origen0/tolerancia0.5pt; bytes conservados. Imagen PNG/JPEG≤2MiB,
una imagen, ejes≤4096/área≤4194304, estado completo y decode efectivo.
Ausencia devuelve nil tras reautorizar, sin crear directorio; formato/lectura/metadatos fallidos son recuperables.
Caché por SHA256 del principal, fuera de bundle, rechazo de symlinks, .complete y exclusión de backup.
Importación valida antes de mutar, candidato protegido, reautoriza antes del commit síncrono entre instancias.
Copia privada `.previous-signature` de bytes anteriores vigentes DESPUÉS de la última await; reemplazo,
metadata nueva/verificación final y eliminación de copia solo tras aceptación. Error intenta restaurar;
si no puede verificar restauración, copia protegida sigue autoritativa para carga y recuperación al importar.
No usa ubicaciones de NSError ni permite que archivo desplazado se convierta en ausencia. Cancelación/
revocación previas conservan la versión anterior. Restauración conserva bytes acotados del recurso previo,
incluso corrupto; toda carga valida imagen y una importación válida permite reparar corrupción existente.
Root captura identidad/revisiones vigentes y cerca authorizer durable antes/después; logout, otro principal,
retry y mismo UID reautorizado revocan capacidad antigua. App compone adapters inactivos, sin consumidor UI.

Simulator informa nil tanto protectionKey como URLResourceValues.fileProtection pese a solicitar .complete;
logs diagnósticos18:22:29/18:23:34 muestran backup=true y rechazo correcto signatureUnavailable.
Solo fixtures inyectan verificador de protección y fallo síncrono de reemplazo para recuperación; formatos,
filesystem/backup/auth/symlinks siguen reales. App usa defaults: .complete obligatorio, nil/none denegados,
FileManager real. Test del default falla cerrado; no bypass de Simulator en producción.
Los dobles no acreditan clase/bloqueo/copia física: protección en dispositivo queda limitada/pendiente.
No firma real ni payload privado en repo/logs.

### TDD y validación exacta

Primer build detectó acceso de enum fixture privado, corregido sin expectativas. RED compilable18:18:26:
35ejecuciones,4PASS/31FAIL por behavior ausente; templates20/17FAIL/3PASS. Summary
`RunSomeTests/F355973B-A22F-4FC6-AEA8-72A24CAAF1D8.txt`. GREEN focal18:30:44:33/33,
selección parcial de parámetros por Xcode: no acredita matriz completa.
Global18:33:08:2630/2631, fixture0 Quartz generaba1página válida. Fixture a PDF /Count0:
PDFKit rechaza árbol vacío; oráculo permite nil o0 para ese caso, exige2 exacto para multipágina;
rejection invalidTemplate/producción intactos. Global18:37:17:2629/2631, oráculo0 inicial y Stock118.
Global anterior a corrección:18:39:37 **2631/2631PASS**,32declaraciones/49casos nuevos completos;
summary `RunAllTests/98F6C3F6-D372-4C10-BC49-3FF4398D4C15.txt`. Es histórico, no resultado final.

POST inicial detectó P2 conservación tras replaceItemAt y P3 estilo sobre freeze985
`75f0ba418c48c264928d4022494e80a6888eb3ba5bf98a5a3fd05ab2b4701ba1`.
Corrección de P2 con PRE focal arriba: tres tests primero RED19:18:58 **0/3PASS**, luego GREEN19:23:28
**3/3PASS**, sin cambiar expectativas. Summaries `RunSomeTests/985D0FB0-79D8-4452-9148-388981D67BD6.txt`
y `RunSomeTests/C9DB79CE-33AD-440D-97BD-3601B951A986.txt`. Cubren original desplazado, rollback
sin verificación, reapertura y éxito de segunda instancia mientras primera espera autorización.
P3 corregidos solo en código nuevo/tocado: firmas/efectos multilinea, inicializadores de struct en extensión.

**RunAllTests completo de comportamiento19:24:25:2633/2634PASS**,1613declaraciones, único fallo StockSyncDurabilityTests118
(lifetime == nil),0skipped/expected/notRun. Summary `RunAllTests/27EE73B7-83D4-41D2-B7BA-BFBA993CAC0C.txt`.
Bundle nativo `Test-FranAlonso-Develop-2026.10.03_19-24-25-+0200.xcresult` en
`/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/`.
Ruta copiada devuelta por MCP en ActionArtifacts carece Info.plist; xcresulttool leyó bundle nativo válido.
Confirma **35declaraciones nuevas/52casos completos PASS**: templates13/20, firma18/25, Root4/7;
12grupos parametrizados completos. Billing+AuthenticationRoot **111declaraciones/181casos PASS**.
Ausencia/corrupto/válido, límites/metadata/symlinks, aislamiento, reintento/reapertura, revocación tardía,
cancelación prepublicación, root real suspendido y recuperación multinstancia; sin sleeps/XCTest/UI tests.
Stock ya observado en13.5 y global18:37:17; fuente intacta SHA256
`98fc8bac80f10492150b8120d7391d627ac53bb9902e915d66437246ef1f4590`. No corregido ni atribuido;
no se repite la suite para sustituir el fallo por una ejecución verde. Regresión global no se declara PASS.

Build-for-testing Develop19:25:06/4.168s PASS, `BuildProject-Log-20261003-192506.txt`;
Production19:25:54/23.771s PASS, `BuildProject-Log-20261003-192554.txt`.
Logs completos:0errores/diagnósticos Swift/Clang; únicamente2/1avisos AppIntents metadata conocidos.
Builds incrementales; sin afirmar clean-build o cero warnings globales. Develop/planDevelop/iPadPro13(M5)
inicial restaurados; Simulator27.2, SDK27.0. No protección física ni fiscalidad acreditadas.

### Auditoría y límites

14Swift tocados; script estilo señala2firmas nuevas con tipos función que deben seguir verticales y
1waitUntil histórico intacto. POST funcional final `billing_13_6_post` PASS sin hallazgos funcionales nuevos;
P2 corregido,986archivos inicial/final/root idénticos
`cf75a736c49d6c6288558ad5a0aa8bd70196cea48c2ce802971c9cac873210c6`.
Estilo en ese freeze encontró solo P3 wrapping híbrido de @Test; ajuste exacto a argumento por línea.
Fuera del freeze solo ese formato y metadatos: reconstrucción del atributo previo coincide con su SHA256
anterior; ningún argumento/expectativa/behavior cambió. Se reutiliza matriz completa19:24:25 por identidad
semántica; manifest funcional14Swift digest `fbbfb391890f8c4ede20fea27b834d9f75f5ffd196d4d5ea91c84406165a302e`.
Build-for-testing adicional19:37:27/29.529s PASS, log `BuildProject-Log-20261003-193727.txt` completo:
0errores/diagnósticosSwift/Clang,2avisosAppIntents conocidos. Focal19:37:46 1/1PASS, summary
`RunSomeTests/204E9A7A-AB3C-4050-9AD7-E63F7D8AEE1B.txt`: Xcode selecciona solo caso12bytes,
no se afirma cobertura completa por ese focal. Todos los3argumentos constan completos en native19:24:25.
Production ya probado y fuentes productivas byte-idénticas; no build repetido por formato solo de test.
Reauditoría focal final de estilo `billing_13_5_post_standards` PASS, sin hallazgosP0–P3 pendientes;
986archivos inicial/final/root idénticos
`69b7ffe69e96b5e5bda8f708d3b474634051a2fb7bfe64f2155182edfea6ea49`.
Atributo exacto verificado,13Swift restantes conservan identidad y revisión manual;14Swift sin líneas>120.
Tras ambas auditorías solo se registra su dictamen en phase13/Progress y se reconcilia Linear;
fuentes/configuración/recursos preservan hashes probados. Sin entrega Git ni cambio a Done.
UI/previews/localización/accesibilidad nueva N/A: no Views/textos/recursos visuales cambiados;
PDF/catálogo bytes intactos, App no conecta consumidores ni cambia rutas/estados del shell.
PLU-101 y deuda previa conservan dueño y recuperación tras feedback/estabilización, antes de uso real.
607textos es/en/0errores; gobernanza solo6enlaces Desktop históricos08.3; diffcheckPASS, Progress≤8192B.
Sin renderer13.7, render13.8, nuevos números/Storage/correo/SwiftData13.10/cierre13.12, ni live.
Entrega Git/Done no autorizada; issue/proyecto In Progress y fase13 abierta.

### Manifest Swift probado

14Swift, digest del manifest SHA256
`3500f614414c4e1552a440f71de63f15dee56366cbf3e88e2e9114b268234468`:

```text
a924b738fa38a8070d6dc6a42ab4ec2d4be01bd6b49aa9c846c3ae1f99c7c83b  FranAlonso/App/Composition/Dependencies/AppDependencies+BillingAssets.swift
a90d441941c7ff037d8d06759dec8c41cc35ff6513fd46729a3b3d4a2e021363  FranAlonso/App/Presentation/Authentication/AuthenticationRootViewModel.swift
5cfc5bc46c4b0977aa49eabd7cefe799abc1bdb2d0521e05cfaade0c8558b018  FranAlonso/Features/Billing/Data/Repositories/BundleBillingDocumentTemplateRepository.swift
6983e94dd31196734ba8b55d5a03e84e1ce981f5bd163fd3c469f0af5faeb358  FranAlonso/Features/Billing/Data/Repositories/ProtectedLocalBillingSignatureRepository.swift
97e7b89d338259245a7ad72a3aabbfe31db0794552c4a0d8c844c919cac0f89e  FranAlonso/Features/Billing/Data/Support/BillingAssetFileReader.swift
8f254a8d9d15f8c8f69834db757c934d683ec1fca2ae4768102187389d9140bc  FranAlonso/Features/Billing/Data/Support/BillingSignatureCacheCoordinator.swift
d52d48ffb08ce4f4d109bd814d75db78fb95401dba99bb1caaea92c73fc94226  FranAlonso/Features/Billing/Data/Support/BillingSignatureImageValidator.swift
e005a2148fe05c8a24b70b47c979190b7c67d4852abd780c18430370ace5e095  FranAlonso/Features/Billing/Domain/Repositories/BillingBusinessSignatureRepository.swift
ee82134156310ab9880588a0d6778479f221939ee97c352cef31a8414d0c8865  FranAlonso/Features/Billing/Domain/Repositories/BillingDocumentTemplateRepository.swift
70add571d3bd921a81fc047f7c5d4de7f1f618bb0290d440e9dd8ae6022db90b  FranAlonso/Features/Billing/Domain/Services/BillingAssetAccess.swift
8cf80e3c61cadda0368628840cd68bb19e0e6f23189f24069389dbb683b1db0b  FranAlonso/Features/Billing/Domain/ValueObjects/BillingAssetError.swift
fb91a6904eb179c4b9df21a754caa55a6107bc6e8a317a225860e2591948e2eb  FranAlonsoTests/AuthenticationRootViewModelTests.swift
2ac0dab51fd45d032e4ad2f944f19e69b0a22442d151edf91999a695ce3da8c6  FranAlonsoTests/BillingBusinessSignatureRepositoryTests.swift
1bfd7b6964c51a160560beff42d6c4ab148e9f095bc36d002be71d2a133d2edd  FranAlonsoTests/BillingDocumentTemplateRepositoryTests.swift
```

## 13.5 / PLU-100 — Entregada funcionalmente; Done

03/10/2026: «commit, push y entrega» autoriza el circuito establecido completo.
[PR54](https://github.com/JFrancoG/FranAlonso/pull/54) MERGED a main a15:07:34UTC;
feature `8f3e5c4f922315a130ecbfecaa0060186a3de65f` → merge `a5565f39783bf341d6ad79421a1c7482adeb8182`.
Árbol completo del merge idéntico al feature auditado, tree `dcc4430764588de81d336570bcc5d1c7eb5fdeb9`.
[PLU-100](https://linear.app/plusprojects/issue/PLU-100) Done verificado tras merge, updated15:07:36UTC;
no se ejecutó una mutación manual de estado. Rama `codex/plu-100-billing-selection-form` eliminada local/remota
tras comprobar ascendencia, head remoto exacto y cero commits únicos; main/origin/main sincronizados al merge.

Revisiones finales independientes de estándares y accesibilidad focal por metadata PASS, sin hallazgosP0–P3;
freeze973 inicial/final/revisores/root `a1f93379e54b0ee3ccc4963b86aedf09dd77fc5e6d0b51677876abb5eb7b2fcd`.
Después del freeze solo se registró el resultado enphase13;32Swift/catálogo/artefactos conservaron sus hashes.
Revisión remota focal independiente PASS sobre65paths: diff PR/local idéntico SHA256
`34f3645dbff55d741fe50a57bef037645e6f1bc850012caffab5301d6a746212`; head8f3e5c4/base76835cb.
Freeze973 inicial/final/revisor/root `2cad4041a36161fd2b9998d05c4187d965b9efc5e62414e0b46d08151df0d48a`.
Antes del merge CLEAN/MERGEABLE; sin protección/rulesets/workflows/checks remotos configurados. ReviewGitHub
COMMENTED desde cuenta propietaria, basada en agente read-only, sin representar aprobación humana distinta.
Merge con match-head8f3e5c4, sin force-push. Criterios dePLU-100/deuda releídos antes de integrar/cerrar.

Se reutilizan por identidad exacta59casos nuevos completos/28declaraciones y155pruebas afectadas PASS,
Develop-for-testing11.15s/Production18.983s PASS, PRE/POST/estilo y evidenciaUI funcional descritos debajo.
**La suite global final sigue fallando:2581/2582 en tres ejecuciones, único falloStockSyncDurabilityTests118**;
fuente histórica intacta/focalStock1/1PASS, sin atribuir causa ni declarar regresión global verde.2/1avisosAppIntents,
607textos/0errores y seis links históricos08.3 conservan sus límites. No se modifica Stock fuera del alcance.
Cierre documental limitado a Progress/phase13/CHANGELOG; Xcode nuevo N/A, sin cambios ejecutables/configuración.
Auditoría documental final focal PASS, sin hallazgosP0–P3 sobre esos tres archivos; Progress8182bytes.
973archivos, huella inicial/final/revisor/root idéntica
`cb0e3523572e9803ef7e29673565abc6e1be2f48075e422806953cb3f990b3fe`.
Después del freeze solo se registra este dictamen; toda fuente/configuración/artefactos conserva identidad.

Entrega funcional de demo ADR0029; [PLU-101](https://linear.app/plusprojects/issue/PLU-101) Backlog/Jesus Franco,
recuperación integral tras feedback y estabilización de cada recorrido, antes del primer candidato para uso real.
PLU-91/deuda previa y resultados Falla/Pendiente/Limitado intactos. Fase13/proyecto abiertos, sin parent/milestone13;
13.1–13.5 entregadas funcionalmente. Siguiente gate separado13.6: carga validada de plantillas y firma privada
opcional, sin iniciar/autorización; live inactivo. Los snapshots de implementación/autorizaciones debajo son históricos.

## 13.5 — Historial de preparación de entrega

03/10/2026: «commit, push y entrega» autoriza el circuito establecido de commit/push/PR/revisión/merge,
cierre funcional en Linear y eliminación segura de rama. Se entrega el ámbito funcional para demo conforme
a ADR0029; PLU-101 conserva la validación accesible integral con responsable y recuperación descritos debajo.
Se reutilizan fuentes/configuración y artefactos validados sin cambios ejecutables:59casos nuevos completos,
155pruebas afectadas y ambos builds PASS; POST/estilo favorables. La suite global final2581/2582 sigue fallando
en StockSyncDurabilityTests118 histórico, fuente intacta, sin atribuir causa ni declarar regresión global verde.
Los avisos AppIntents y seis enlaces históricos08.3 permanecen documentados. Xcode nuevo N/A para metadatos
de entrega. Fase13/proyecto siguen abiertos;13.6 y live mantienen autorización separada.
PLU-100 continúa In Progress hasta verificar la integración definitiva y completar los gates de entrega.
Revisiones finales independientes de estándares y accesibilidad focal por metadata: PASS funcional, sin
hallazgosP0–P3. Freeze973 inicial/final/revisores/root idéntico
`a1f93379e54b0ee3ccc4963b86aedf09dd77fc5e6d0b51677876abb5eb7b2fcd`.
Después del freeze solo se registra este resultado;32Swift/catálogo/artefactos conservan hashes validados.

## 13.5 — Historial de implementación local

03/10/2026: «abre issue y rama e implementa13.5».
[PLU-100](https://linear.app/plusprojects/issue/PLU-100) In Progress/Jesus Franco;
`codex/plu-100-billing-selection-form` desde main/origin/main limpio `76835cb`.
[Propuesta exacta y fuentes](13-5-billing-selection-proposal.md): selección ticket/factura desde venta
pagada, destinatario inmutable validado, payloadv1 histórico/v2 y cancelación sin reserva/cierre.
PRE independiente PASS antes de código; P3 de atribución a13.6 corregido y reauditoría focal PASS.
926archivos, freezePRE `80d7f3d9e6f29f3aa74e160c45d663ab25618b7594dc5942adfae408234e3afc`;
reauditoría inicial/final/root `76f7103034e4d0c5ccf31728b23a73aaf6973ddecec22593f507263042765572`.
Sin dependencia/unsafe/target/live nuevos; proyecto/fase13 y deuda previa siguen abiertos.

### Implementación13.5

Domain: seis campos requeridos tras trim exterior, preservando Unicode/case/espacios internos; política de
completitud de la app, sin checksum/país/suficiencia legal. UseCase valida venta pagada y destinatario antes
de generar IDs/fecha; ticket no contiene datos fiscales. Request sella snapshot inmutable y Codable revalida.
Domain conserva invoice histórica sin profile. Data: payloadv1 exacto histórico sin destinatario, v2 solo
invoice completa; rechaza claves extra, null, destinatario parcial/v1 y versiones no soportadas. Envelopes,
transacción y numeración13.3 intactos: conflicto fiscal no consume otro número, replay/lost response conserva
snapshot. Solo dos fixtures históricas cambian versión desconocida2→3, manteniendo su rechazo anterior.

BillingViewModel mantiene Store13.4 como única autoridad de request y añade formulario previo, error y carga
local caller-owned; borra draft al preparar/cerrar. Prefill no reemplaza edición, sesión cerrada, tipo distinto,
identidad ajena ni padre revocado. Padre cerca UUID/saleID/snapshot/estado; apertura pagada estable y callback
antiguo ignorado. Composición concreta App con adaptador unavailable/cancelable; sin reserva falsa ni Firebase.
Views nativas separadas, una View/archivo, VM por pantalla, previews deterministas, textos es/en. Preparar
muestra resumen; cancelar/cerrar conserva venta pagada pendiente en Jornada. Sin PDF/Storage/correo/firma,
persistencia13.10, cierre13.12 ni gate13.6. Ningún perfil cliente escrito, payload fiscal logueado o live activado.

### TDD y validación13.5

RED compilable7/7 FAIL esperado, build17.205s PASS; summary
`RunSomeTests/5B23EF9F-EE61-4898-A080-B070743306A5.txt` (14:20:31).
GREEN focal173/173 PASS, selección parametrizada parcial, summary
`RunSomeTests/BD1E820B-FE56-45B6-98C1-80A5291BCE09.txt` (14:25:29).
28declaraciones nuevas/59casos completos: campos whitespace/trim, no IDs antes de validar, ticket privacidad,
request nativa/DTOv1-v2/malformed, conflicto por cada campo/lost response, inmutabilidad/identidad/prefill tardío,
revocación padre, cancelación/sin reserva y navegación. Swift Testing, sin sleeps/XCTest ni backend acreditado.

Smoke detectó que setter sin cambio borraba error al tomar foco. Regresión compilable RED1/1 FAIL
`RunSomeTests/F7A2DE00-064F-4A0E-BCA1-9B95007A41A3.txt` (14:53:30), GREEN1/1 PASS
`RunSomeTests/E11760B2-9899-4D07-85EA-EFC40D75EACA.txt` (14:59:40): igualdad conserva issue/validationID,
edición real limpia. Labels accesibles explícitas; retest táctil confirma mensaje antes de editar y seis labels AX.

Estilo independiente Audit32Swift/20nuevos/1818líneas tocadas: recall0; seisP3 corregidos. Freeze946
`8955b00eb65f50983d38f4dbb5984530a14bd33e796dfc5be636b363562476e2` antes/después/root.
Reauditoría focal PASS, freeze946 `b8bd88ee02f206dd25c1f1912e24f6feedb8e30ed80ed1dc2661b114cbe7576e`.
Focal adicional setter/label/regresión PASS, 3Swift/recall0;966archivos antes/después/root
`fdb1349ad3c00a6d76037608701c59eaa1c71ffd099cce3bf19f32863b0660cd`.

Global anterior14:46:09:2578/2579 PASS, StockSyncDurabilityTests línea118 weak ModelContainer aún vivo;
focal1/1 FAIL (7E3311B3), global14:47:56:2579/2579 PASS (E9636DDC). Stock no modificado ni corregido;
se conserva intermitencia histórica, sin atribuir causa. Tras fix inicial de formulario, global previo alPOST15:00:49:
**2580/2580ejecuciones PASS /1577declaraciones**, cero failed/skipped/expected/notRun.
Summary `RunAllTests/77A70739-82A1-446A-BD78-655A949A7DFC.txt`.
Bundle original DerivedData Logs/Test copiado íntegro con Info.plist/Data a ActionArtifacts/RunAllTests:
`Test-FranAlonso-Develop-2026.10.03_15-00-49-+0200.xcresult`; xcresulttool confirma27nuevas/57casos,
1577declaraciones y2580ejecuciones; runtimeWarnings vacío. Export previo `/tmp/franalonso-13-5-pre-post-summary.json`
y `...-tests.json`. La ruta reportada inicialmente por MCP no contenía el bundle nativo; copia real verificada.

Build-for-testing Develop previo alPOST8.746s PASS, `BuildProject-Log-20261003-150044.txt`;
Production21.896s PASS, `BuildProject-Log-20261003-150152.txt`. Logs completos:2/1avisos AppIntents
conocidos respectivamente, cero errores/diagnósticos Swift-Clang. Incrementales, sin claim clean-build ni
cero warnings globales. Buildruntime iPhone17 corregido12.543s PASS, `BuildProject-Log-20261003-150001.txt`.
Xcode MCP27.0 estable Service/workspace-PfnUYLlMzY, target27/Swift6 strict complete/default nonisolated,
Simulator27.2/iPadPro13(M5). Develop/plan/destino inicial restaurados, sin cambios de configuración.
Localizaciones607es/en/0errores (531+75+1),30nuevas. Diffcheck PASS; gobernanza exit1 exclusivamente seis
links Desktop históricos08.3, sin nuevos errores. Progress≤8192bytes. Sin GoogleService-Info/PII en cambios.

### Correcciones del POST13.5

Ambos revisores detectaron P2 funcional: Prepare inválido durante carga local y respuesta posterior completa
mantenía error/validationID de un campo ya rellenado. Se acepta input solo si difiere y limpia validación; un
input idéntico la conserva. No marca edición manual ni prepara/reserva automáticamente. Regresión gated con
respuesta distinta/idéntica RED2casos:1FAIL/1PASS (5F2B5A60,15:24); GREEN3/3 incluyendo setter idéntico
(03989E09,15:25). P3 estándares: JSON conservaba exactInvoiceRecipient pese al texto de sanitización;
se elimina ese bloque duplicado sintético y se actualizan hash/bytes del manifest. Sin PII real encontrada.
Estilo focal independiente PASS2Swift/recall0, freeze973 inicial/final/root
`05353597b6d8a4cd3754b21aafda9740cf1001232258b119ec1e8e603f056628`.

Builds finales trasP2: Develop-for-testing11.15s `BuildProject-Log-20261003-152457.txt`, Production18.983s
`BuildProject-Log-20261003-152711.txt`, PASS. Logs completos:2/1avisosAppIntents,0errores/Swift-Clang;
incrementales. Develop/plan/iPadPro13(M5) restaurados. Focal final155/155 PASS, selección de127identificadores
con parámetros parciales: `RunSomeTests/09C09C37-1BE8-457B-8EFC-4C944374BF0C.txt` (15:34:25).

**Global final NO pasa**:2581/2582 en tres ejecuciones trasP2, único fallo StockSyncDurabilityTests118:
weak ModelContainer aún vivo. Summaries441EDDD7 (15:25:39),05025F43 (15:27:21),BD25D864 (15:29:31).
FocalStock1/1PASS, BDD95254 (15:26). Fuente Stock byte-exact contraHEAD76835cb, SHA256
`98fc8bac80f10492150b8120d7391d627ac53bb9902e915d66437246ef1f4590`; ninguna causa/corrección atribuida.
El xcresult final íntegro15:29:31 confirma1578declaraciones/2582ejecuciones,28nuevas/59casos completos PASS,
un fallo histórico,0skipped/expected/notRun y runtimeWarnings vacío. Tres bundles nativos copiados íntegros
Logs/Test→ActionArtifacts/RunAllTests con Info.plist/Data. Export final `/tmp/franalonso-13-5-final-summary.json`
y `...-tests.json`; exports del PASS previo se conservan como `/tmp/franalonso-13-5-pre-post-{summary,tests}.json`.
PASS del ámbito13.5 tras reauditoría focalP2/P3; no acredita regresión global verde ni entrega.
No se amplía el scope para modificar Stock. Se conservan todos los resultados y el límite de validación global.
Previews/smoke se reutilizan por impacto: ningún layout, label, recorrido normal de prefill ni navegación cambia;
la respuesta suspendida después de validar se verifica en la regresión gated, sin inferir AT de ese caso.

### UI y evidencia13.5

[Matriz55/manifest/PNG](../accessibility/evidence/13-5-billing-selection-form.md):18previews originales
Large/XXX Large/AX5,es/en,Light/Dark,contraste estándar/aumentado; hostreal iPhone18ProMax27.2/portrait.
Título nuevo corregido a Documento/Document, recapturado completoAX5. Dos recapturas finales errorLarge/AX5
tras fix guard/label; resto reutilizado por impacto sin cambio visual, sin afirmar render posterior. Campos,
error/resumen y entrada del detalle requieren scroll; recorte del título histórico detalle sigue enPLU-91.
Smoke táctil13.5 iniciado en iPhone17/27.2, build corregido instalado/launchdemo fresco. Retest error/labels PASS;
factura con seis datos exactos, ticket sin destinatario y retorno a Jornada pagada pendiente PASS.
Large/es/Light: capturas originales de error/resumen/retorno; no verificar AT/Inspector/contraste/físico.

[PLU-101](https://linear.app/plusprojects/issue/PLU-101) Backlog/Jesus Franco, deuda específica integral:
VoiceOver/VoiceControl/SwitchControl/FKA/foco/anuncios/Inspector/ratios/autofill/preferencias/landscape/iPad/RTL/
scrollAX5/dispositivo físico. Recuperar tras feedback y estabilización de cada recorrido, antes del primer
candidato para uso real; PLU-91 y deudas anteriores intactas. ADR0029 permite entrega funcional sin declararlas resueltas.
POST estándares y accesibilidad independientes PASS para el ámbito funcional; integral pendiente en PLU-101.
En este snapshot de implementación, entrega Git/Done aún no autorizada; fase13/proyecto abiertos.

### Dictamen final13.5

POST inicial ambos revisores973 `33150ad0f28821a495ce61d7c2af120a68ab312aa01a367fdec401cf6e3ad1fe`:
P2 validación tras prefill corregido; P3 sanitización corregido, sin PII real. Reauditoría estándares del código/
validación PASS,973 inicial/final/root `43b4571ed242ef1ef6d463d83767666e07152fc88101b60ead3689413e11e84b`.
El revisor confirma que la guía/checklist requieren tests afectados/builds verdes; este PASS de implementación
no acredita regresión global verde ni entrega, y no amplía scope para Stock histórico intacto.

P3 adicional de procedencia documental resuelto: tres manifests32fuentes fechados,18originales previos al
setter/label,2recapturas posteriores y fuente actual trasP2. Hashes de captura y actuales separados;
29Swift idénticos,3diferencias documentadas. Todos PNG byte-exact, reutilizados por impacto, sin claim render
posterior alP2. Reauditoría documental estándares y POST UI/accesibilidad funcional ADR0029 **PASS**, sin
hallazgos nuevosP0–P3. Ambos973, huella inicial/final/revisores/root idéntica
`7f7d1aa7040c4c0cb2cce8fa791258fe8052b8e3d5e7aeed4fe46fb58d741d1b`.
Fuentes/configuración y32hashesSwift validados intactos; Xcode nuevoN/A por solo metadata/documentación.
Solo se registra este dictamen después del freeze. Linear/Progress reflejan scopePASS,globalStockfallido,
PLU-101Backlog/Jesus/recuperación antes de candidato real y fase/proyecto abiertos. En este snapshot aún
no hay entrega Git;13.6/live siguen separados. La autorización de entrega posterior figura arriba.

## 13.4 / PLU-99 — Entregada; Done

03/10/2026: «commit, push y entrega» autoriza el circuito establecido completo.
[PR53](https://github.com/JFrancoG/FranAlonso/pull/53) MERGED a main;
feature `7498ccd6e8d385767f57c17641c41291bc5ef4f3` → merge `268efd3b18e21983de2e67e3198edabb7d83b137`.
Árbol completo integrado idéntico al feature validado, tree `fd312337a8fbd218e32d96afaf8a24ee3cc03399`.
Rama `codex/plu-99-billing-document-state` eliminada local/remota después de comprobar
ascendencia, head remoto exacto y cero commits únicos; main/origin/main sincronizados al merge.
[PLU-99](https://linear.app/plusprojects/issue/PLU-99) Done verificado tras actualización explícita
03/10/2026 11:21:23 UTC; no se atribuye ese cambio a automatización GitHub–Linear.

Revisión independiente final de entrega PASS sin hallazgosP0–P3, nueve archivos previstos;
freeze925 inicial/final/revisor/root `d9503ba0945cb074fe8f4887e4c755df07a7e901df3d44dbe966e7637d423949`.
Rerevisión remota focal PASS: diff PR/local idéntico SHA256
`80c6d57cf6e754739ec2bf7eff0aa9442559531eed45dfda90fd1f832bfdbc35`, mismo head/base;
CLEAN/MERGEABLE antes del merge, sin protección/rulesets/workflows/checks remotos configurados.
Revisión GitHub COMMENTED desde cuenta propietaria basada en agente read-only; no representa
aprobación humana distinta. Se integró con match-head7498ccd, sin force-push.

Se reutilizan2523/2523 ejecuciones /1550declaraciones,16nuevas/30casos completos, ambos builds y
PRE/POST/estilo por identidad exacta de los cinco Swift y toda fuente/configuración histórica.
El revisor relee bundle xcresult completo y logs, sin nuevos builds/tests por metadatos de entrega.
Cierre documental limitado a Progress/phase13/CHANGELOG; Xcode nuevo N/A por ausencia de cambios ejecutables.
Auditoría documental final focal PASS sin hallazgosP0–P3 sobre tres documentos:
925archivos, huella inicial/final/revisor/root
`332925a77efa3c9bb3dcee43e64c58002e5a2a47a611df460229346f1da7ffd9`.
Después del freeze solo se registra este resultado; fuentes/configuración mantienen el manifest validado.
AppIntents, intermitencia Stock y seis enlaces históricos08.3 conservan sus límites descritos debajo.
UI/accesibilidad N/A; deuda previa mantiene responsable/recuperación antes del primer candidato real.
Fase13/proyecto abiertos, sin parent/milestone13;13.1–13.4 entregadas.13.5 selección/formulario fiscal
es el siguiente gate separado con propuesta/PRE/autorización propias, sin iniciar; live permanece inactivo.
Los snapshots de implementación y autorizaciones iniciales conservados debajo son históricos.

## 13.4 — Historial de implementación local

03/10/2026: «abre issue y rama e implementa13.4».
[PLU-99](https://linear.app/plusprojects/issue/PLU-99), Jesus Franco, In Progress;
rama `codex/plu-99-billing-document-state` desde main/origin/main limpio `8256d3b`.
[Propuesta exacta y fuentes](13-4-billing-presentation-proposal.md), spec13/ADR0008/0011.
PRE independiente PASS sin hallazgosP0–P3 antes de código:920archivos,
huella inicial/final/root `ed7bc5e954faef3b46254793de2fef5c934b22f081db719ba7c3541852a32ee5`.
No nuevo ADR/dependencias/configuración; Swift histórico Billing13.1–13.3 y Sales/App intactos.

### Implementación13.4

Dos Swift nuevos en Presentation: BillingDocumentStore y BillingViewModel @Observable @MainActor,
genéricos por el Repository aprobado. VM instancia Store privado; todos sus estados/proyecciones leen
Store mediante getters, sin copia/lastError mutable, Task interna ni efectos en init.
Única máquina selection/allocation(BillingDocumentLocalState)/reserving(request)/closed(snapshot retenido).
Una sesión sella request validada sin generar ID/fecha ni I/O; misma request no-op, otra/busy/closed rechazan.
Reserve usa UseCase13.2 y un intento explícito; numbered devuelve el mismo documento sin otro contacto.
Errores neutrales conservan request; invalidResponse se presenta unavailable, sin payloads/logs.
Cancelación previa/al volver del await deja pendingNumber aun desde failed. CancelReservation cerca
publicación; no cancela task del caller ni promete rollback remoto. Tokens privados impiden que éxito,
catch o defer antiguos contaminen un reintento activo. Close terminal retiene request/documento y no cierra venta.

Tres Swift Testing nuevos:16declaraciones/30casos. Seam Repository real con planes consumidos antes
de suspender y gates compartidos, sin sleeps/red. Incluye pipeline real Store→UseCase→Repository13.3→
ledger transaccional histórico para respuesta perdida, cancelación postcommit y replay con un solo commit.
Doble gate completa éxito/error antiguos mientras el nuevo sigue bloqueado, sin cancelar la task antigua
(para comprobar fencing Store); Observation confirmation demuestra tracking real de getters VM.
También familias, request sellada, errores privados/respuesta ajena, no auto retry, busy, precontact cancel
desde pending/failed, numbered monotónico, close selection/pending/failed/numbered y delegación fachada.
Fixtures sintéticas; el fake no acredita backend/Rules ni reinicio durable13.10.

### TDD y validación13.4

RED compilable11/11 FAIL por stub noRequest y falta de invalidación Observation:
`RunSomeTests/481D6E82-61C5-45FD-B322-FEB4EB94006D.txt`; build-for-testing27.002s PASS.
GREEN focal25/25 PASS, selección parametrizada parcial de16declaraciones:
`RunSomeTests/3C5E7C2D-1D56-4A0D-92C9-367EB6600CD0.txt`.
Primer global2523/2523 PASS12:29:08 antes de dos cambios puramente de layout.

Estilo independiente:5Swift/693líneas, recall1candidato,2P3 en tests corregidos:
ledger init horizontal117columnas y atributoTest95columnas. Freeze925
`26504356a949ef52fd6344a98c3fe384e6899356b8ab2c43e57a6dcfbca573de` antes/después/root.
Reauditoría focal PASS sin hallazgos; resto del Audit vigente, recall0candidatos;925archivos,
huella inicial/final/root `6d639a7896a7f71c5d563a16e7c12a11f76e021839f70c19b90f38dcb1d16eb1`.

Build-for-testing Develop definitivo12:31:37 /13.086s PASS,
`BuildProject-Log-20261003-123137.txt`; Production12:32:52 /33.143s PASS,
`BuildProject-Log-20261003-123252.txt`. Logs completos: dos avisos AppIntents conocidos por build,
cero diagnósticos estructurados Swift/Clang; incrementales, sin claim clean-build/cero warnings globales.
Xcode MCP27.0 estable Service, workspace-PfnUYLlMzY; target27/Swift6 strict complete/default nonisolated,
SDK27.0/Simulator27.2 iPadPro13(M5). Develop/plan/destino inicial restaurados, sin archivos temporales de esquema.

Global12:31:45:2522/2523 PASS, fallo histórico StockSyncDurabilityTests línea118,
weak ModelContainer todavía vivo; no se tocó Stock ni se atribuye corrección/causa.
Retest focal1/1 PASS, `RunSomeTests/29B5435C-7753-4EDD-B581-556A9DADC8CE.txt`.
Global definitivo12:33:45: **2523/2523ejecuciones PASS**, **1550declaraciones**,
cero failed/skipped/expected/notRun. Summary `RunAllTests/F22EED90-EA36-4C74-AF0C-613762AB27E8.txt`.
Bundle ActionArtifacts íntegro `Test-FranAlonso-Develop-2026.10.03_12-33-45-+0200.xcresult`;
xcresulttool confirma2523ejecuciones/1550declaraciones,16declaraciones nuevas/30casos completos y
runtimeWarnings vacío. Export `/tmp/franalonso-13-4-final-summary.json` y `...-tests.json`.

### Auditoría y límites13.4

POST independiente de estándares PASS sin hallazgosP0–P3:8archivos (5Swift/3docs),pipeline
Domain/Data,contratos,token/catch/defer,oráculos,fuentes Apple,evidencia nativa completa y límites.
925archivos,huella inicial/final/revisor/root idéntica
`5272c60c1a76797928d3c782bf93eb0feefcd1ddd97308933312b42e9304a4a3`.
Solo se registra este resultado después del audit; fuentes/config mantienen el manifest validado.
Implementación local lista; PLU-99 In Progress hasta una entrega Git autorizada.
Diffcheck PASS; validador de gobernanza solo conserva seis enlaces históricos08.3 a Desktop
(exit1), sin nuevos problemas; no se declara PASS global de gobernanza. Progress conserva el límite≤8192bytes.
UI/previews/accesibilidad N/A: no Views/pantalla/texto/navegación visible tocados. Deuda previa y
responsable/recuperación antes de uso real permanecen intactos; no se acredita matriz accesible nueva.
No composición App, formulario/modelo fiscal13.5, plantillas/firma, PDF/Storage/correo, SwiftData13.10,
cierre13.12, Rules/deploy/bootstrap ni live. Nada se cierra de fase/proyecto; entrega Git/Done no autorizada.

### Manifest13.4 — Fuente definitiva validada

- `BillingDocumentStore.swift`: `7ec497a8aa9ba633f2f9774ba7a294b3de37c59353abbd411112d8f515334bb5`.
- `BillingViewModel.swift`: `e705b3174e469e93aa96fe7045ce0114ceda7f9cfec12dc06acb85f25bfd07ca`.
- `BillingDocumentStoreTests.swift`: `e40846723e9a253953265a6128dc8f31449b36966ecd6aa7caf72a7ad6def19b`.
- `BillingViewModelTests.swift`: `d6117a74e7b5ecc8709c574f2180e867238da967fa33227e536c583291c5f54b`.
- `BillingPresentationFixtures.swift`: `8213bd2cf6b792bf5e1cb38a1e920ec493c135f55b5b83cf010e6d9a2c52c2ff`.

## 13.3 / PLU-98 — Entregada; Done

03/10/2026: «abre issue y rama e implementa 13.3». [PLU-98](https://linear.app/plusprojects/issue/PLU-98)
Done / Jesus Franco tras [PR52](https://github.com/JFrancoG/FranAlonso/pull/52);
rama `codex/plu-98-atomic-billing-reservation` eliminada, baseline main/origin `965827a` limpio.
[Propuesta exacta, fuentes y compatibilidad](13-3-billing-transaction-proposal.md). PRE independiente PASS antes
de código, sin hallazgos P0–P3:913archivos, digest inicial/final/revisor/root
`9594a8cd6327c921e1d9607fdfdb7d3fa7bc396814b5f7ded3eba807caa8f756`.
Ocho Swift13.1/13.2 byte-exact contra965827a y sus manifests históricos; configuración/dependencias intactas.

### Implementación y TDD 13.3

Cuatro Swift nuevos en Billing/Data: DTO versionados exactos, política y seam transaccional, Repository genérico,
actor Firebase. Tres claves en una transacción: asociación requestID→documentID, documento inmutable y contador
independiente ticket/invoice. Reads antes de cualquier write; la política de producción se recalcula por intento.
Replay de request íntegro validado retorna número/fecha originales sin writes, incluso con contador corrupto.
Conflicto de contenido/identidad no consume número; huérfanos, versiones, fechas/pago/números y overflow fallan
cerrado. Solo primera creación escribe los tres registros juntos. No reparación ni numeración local.

Venta reutiliza SaleDTO v2/SaleTimestampDTO exactos; no se cambia Sales. Los envelopes Billing rechazan claves
desconocidas. El actor usa runTransaction async del SDK12.19.2 aprobado y provider obligatorio Sendable de cliente
ya configurado, sin default, SDK retenido en estado, cambios de configuración, fresh-instance promise ni opt-outs.
Bloque SDK síncrono obligatorio, sin efectos de aplicación; resultado Data Codable nuevo mediante sending Any?.
@ServerTimestamp<Date> nil genera el transform en el commit. Lectura server posterior exige snapshot existente,
sin cache/writes pendientes, fecha resuelta y versión/request/serie/número exactos al plan confirmado. Ningún reloj
local decide issuedAt. Pérdida de respuesta/cancelación después de commit se recupera con el mismo request;
Repository no reintenta automáticamente y solo expone errores neutrales/CancellationError. Sin logs ni payloads.

Dos Swift Testing nuevos:18declaraciones/66ejecuciones. Fake con transporte Codable, snapshot/versiones y barrera
determinista fuerza contención/intentos obsoletos y reejecuta la política real; commits completos sin await entre writes.
Interrupción previa/postcommit, cancelación posterior con éxito/error tardío, replay tras recrear Repository,
identidades, independencia, corrupción y precisión (decimal mayor que2^53, orden de líneas, pago y bits de fechas).
Codec SDK real Encoder/Decoder local: sentinel es serverTimestamp, solo fecha resuelta confirma, metadata/path y
campos extra inválidos rechazan. Sin bootstrap Firebase ni red. El fake no acredita servidor/Rules reales.

RED compilable inicial:15/15 FAIL, unavailable intencional; `RunSomeTests/138EFFDF-A57B-4E94-BA3A-1A6619D400C7.txt`.
RED de campos desconocidos:4/4 FAIL, junto con7casos core PASS; `RunSomeTests/CF21FFA9-AFA3-49E9-8FCD-5E1DD6EE41F7.txt`.
RED codec SDK:10/10 FAIL por stub unavailable; `RunSomeTests/74FB37AD-38C8-4118-8918-143FAA5F893F.txt`.
GREEN focal:47/47 PASS, selección parcial de argumentos por Xcode; `RunSomeTests/5F9AF095-D8C9-44E5-89A3-1E7EC59D81D3.txt`.
No se atribuye cobertura66 al focal. Primer global11:01:02:2493/2493 PASS, incluidos66nuevos, confirmado nativamente;
`RunAllTests/DEB0EF12-707D-4691-987A-1D5908FA8468.txt`. Después se normalizaron únicamente cinco bloques de estilo.

### Validación definitiva 13.3

MCP Xcode27.0 estable (27A266), workspace-PfnUYLlMzY; Develop/plan Develop inicial restaurados,
iPad Pro13(M5) Simulator27.2/SDK27.0. Target27.0, Swift6 complete/default nonisolated, warnings como errores.
Build-for-testing Develop11:05:39 /28.706s PASS, `BuildProject-Log-20261003-110539.txt`;
Production11:07:26 /28.572s PASS, `BuildProject-Log-20261003-110726.txt`.
Cero diagnósticos estructurados Swift/Clang; logs completos solo los dos avisos conocidos AppIntents por build.
Builds incrementales; no clean-build ni cero warnings globales. Sin tests nativos UI/XCTest ni xcodebuild.

RunAllTests definitivo11:05:57: **2493/2493ejecuciones PASS**, **1534/1534declaraciones**, cero
failed/skipped/expected/notRun. Summary `RunAllTests/72BF9DA2-C01B-4FDC-B091-EB64DC8D542F.txt`.
Bundle `Test-FranAlonso-Develop-2026.10.03_11-05-57-+0200.xcresult`: copia ActionArtifacts sin Info.plist;
se leyó el original íntegro en DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test por xcresulttool.
Confirmó2493ejecuciones/1534declaraciones,18/18declaraciones y66/66ejecuciones nuevas con todos los grupos:
2/2/4/1/2/3/2/4/13/6/6/1/6/1/1/1/9/2. También Stock histórico PASS, sin corregir su intermitencia previamente registrada.

### Auditorías y gobernanza 13.3

Estilo independiente:6Swift, script1candidato (init actor válido por parámetro closure), pase manual detectó3P3
en5bloques. Corregidos dos bodies de closures throwing/await en fixture y tres if del helper SDK a multiline;
misma lógica/expectativas. Auditoría inicial read-only:919archivos, digest inicial/final/root
`7ee40785cca0023b75c198851476cea0ddfa38491abbf6484836ddb6834196fc`.
Reauditoría de estilo PASS:6Swift leídos completos,5bloques corregidos, único candidato lexical justificado.
POST independiente PASS sin hallazgosP0–P3:revisó autoridad,6Swift/3docs,SDK fijado, provider/configure-before-use,
puente NSError/Swift, paths/transacción/DTOs, TDD, counts nativos completos, dos logs, manifests y límites.
Ambas auditorías operacionales read-only:919archivos, huella inicial/final/revisor/root idéntica
`cbd22b7ed26a3c70da1ceb9593194a4f38ab94cef2bcc519dca6f70277a3ef2d`.

Diagnóstico adicional RunCodeSnippet11:12:47 no ejecutó código: DYLD no pudo cargar `/usr/lib/libSystem.B.dylib`
en dispositivo privado de Previews. `RunCodeSnippet/RunCodeSnippet-ErrorDetails-20261003-111247.txt`.
No cuenta como prueba runtime de bridge ni como preview; no se altera entorno para corregirlo en este alcance.
SDK/Swift contrastados estáticamente: NSError original conservado y camino de transacción inspeccionado sin log
del Status. No hay hallazgo demostrado ni modificación de producción por esa hipótesis.
Gobernanza conserva únicamente seis enlaces Desktop históricos rotos08.3; diffcheck PASS. Scope exacto9archivos
(6Swift+3docs), sin secretos/PII/logs, dependencias, target/settings, Rules/índices/deploy ni cambios históricos.

UI/previews/localización/accesibilidad N/A: solo Data/tests, sin pantallas ni recursos; deuda previa conserva dueño
y recuperación tras feedback/estabilización, antes del primer candidato real. Sin App/composición/demo ni tráfico.
13.4 Store/VM,13.10 SwiftData, PDF/Storage/correo, cierre13.12 y ajuste13.13 siguen fuera. Backend/Rules reales,
conservación de contadores, permisos/writers y tamaño/contención requieren puerta live separada; esta evidencia
no acredita emisión fiscal o integración real. Snapshot tras implementación y antes de entrega: PLU-98 In Progress,
validada con PRE/POST/estilo PASS y pendiente de autorización Git/Done. El resultado definitivo aparece abajo;
fase13/proyecto siguen abiertos. Registro de dictámenes/estado documental: Xcode N/A por paridad literal.

### Manifest Swift 13.3 probado

```text
BillingDocumentRecordDTO.swift 5ca6fb658c4ae6c6dc9425e971a00dc079171d7a295cf3badf966e6e2fa9ce04
BillingTransactionDataSource.swift 2e8e0f588d196ddbbdafdc31c8b3b1b2299f242865569abf441fb7d4abe3d2ff
FirebaseBillingTransactionDataSource.swift 7f4b3413b19e0a4190b4965a50285f16d085f5631c32d27b6ca915837a5c6c20
FirestoreBillingDocumentReservationRepository.swift 12630a822c54321213ac43b8b14cb95e739ddef3af1587f9a178cc73ac452000
BillingTransactionFixtures.swift 2bb4d999f399494715baeac32f127cfb3d0eed08dda386a7681f06186772d712
FirestoreBillingDocumentReservationTests.swift 214b70a4a20fe324d1f5e2f55e1e224e6d4bab31c28c19b0c1033ccaa2b751ab
```

### Autorización de entrega 13.3

03/10/2026: el propietario solicita «commit, push y entrega». Autoriza el mismo recorrido completo establecido
para13.1/13.2: commit del alcance exacto, push, PR/revisión/merge, reconciliación PLU-98 Done y limpieza de rama
tras verificar ancestry. No autoriza13.4, cierre de fase13 ni live.
Se reutilizan2493/2493ejecuciones,1534declaraciones,66/66casos nuevos, ambos builds y PRE/POST/estilo PASS:
los seis Swift nuevos y ocho históricos mantienen los bytes/hashes exactos probados. Solo documentación/changelog
de entrega adicional: Xcode N/A por paridad literal. Revisión focal previa a entrega PASS sin hallazgosP0–P3:
919archivos, huella inicial/final/revisor/root `a71bd67cfa426e4ce7319fad522e8a7454d1fcd417b14c84dd35b111de3cfc3e`.
Confirmó6hashes y8históricos exactos, nativo2493/1534/66/18, dos logs, estilo y4documentos. Resultado Git pendiente.
PLU-98 In Progress / Jesus Franco; sin comentarios concurrentes ni parent/milestone13 existentes, proyecto In Progress.
Avisos AppIntents, seis enlaces Desktop históricos08.3, intermitencia Stock no corregida y límite DYLD del diagnóstico
adicional conservados. No servidor/Rules reales, UI, materialización SwiftData, PDF/correo, cierre13.12 ni activación.

### Entrega verificada 13.3

[PR52](https://github.com/JFrancoG/FranAlonso/pull/52) MERGED03/10/2026 11:49:58 Madrid:
feature `e18b92a7d50b5eda8d21024f86de82af40573f52` → merge `9bdc2216d06ee66ec5ffb047fc6f06e4d1198e23`.
Árbol completo del merge idéntico al head revisado; seis Swift nuevos y ocho históricos byte-exact al manifest.
Revisión independiente PR PASS sin hallazgosP0–P3: diff remoto/local de diez archivos idéntico,92200bytes,
SHA256 `c474fc32ca162315c3686629521e63b73059d51c31e3e9d1e06f1899f43eab18`.
919archivos, huella inicial/final/revisor/root `1d03381768ab39bcb5ff90b598bbf4cb3db397c35e56203c5ff38a514e75b280`.
Dictamen publicado COMMENTED con cuenta propietaria, sin atribuir aprobación a otro colaborador humano.
Head protegido con match-head-commit, CLEAN/MERGEABLE. Sin checks/workflows remotos ni protección/rulesets;
no se declara CI verde. Main local fast-forward al merge; ramas local/remota eliminadas tras ancestry y cero
commits únicos, y HEAD remoto de feature verificado antes de borrarlo.

PLU-98 pasó automáticamente a Done tras merge; completedAt09:50:00.070 UTC verificado. Proyecto In Progress,
sin parent/milestone13 existente. Fase13 abierta;13.4 exige autorización propia. Deuda accesible previa mantiene
responsables y recuperación tras feedback/estabilización, antes del primer candidato real. UI/accesibilidad13.3 N/A.
Se reutilizan2493/2493ejecuciones,1534declaraciones,66/66casos nuevos, ambos builds y PRE/POST/estilo PASS.
Este cierre cambia únicamente Progress,phase13 y CHANGELOG: Xcode adicional N/A por paridad literal de14Swift.
Avisos AppIntents/enlaces históricos, intermitencia Stock sin diagnóstico y límite DYLD conservados. Sin server/Rules
reales, composición/tráfico, SwiftData13.10, PDF/correo, cierre13.12, live ni implementación13.4.
Descripción/comentario de entrega PLU-98 y snapshot de proyecto se reconcilian con este resultado definitivo.

Reauditoría final documental PASS sin hallazgosP0–P3:919archivos, huella inicial/final/revisor/root
`2392bc00f47a84f011e9502b7ec5a7271c7a43868b388b3463c252b9abb3193d`.
Confirmó Git/PR/review/árbol `c913428aca95de0739a369be776cced72d11486d`, ancestry/ramas eliminadas,
PLU-98 Done/proyecto In Progress y tres documentos. Reconciliación externa prevista tras este commit documental.
Este registro posterior del dictamen no altera ningún Swift; Xcode N/A por paridad literal.

## 13.2 / PLU-97 — Entregada; Done

03/10/2026: «abre issue y rama e implementa 13.2». [PLU-97](https://linear.app/plusprojects/issue/PLU-97)
Done / Jesus Franco tras [PR51](https://github.com/JFrancoG/FranAlonso/pull/51);
rama `codex/plu-97-billing-document-reservation` eliminada, base `ee97380` main/origin limpio.
[Propuesta exacta](13-2-billing-reservation-proposal.md). PRE independiente PASS sin hallazgos antes de código:
909 archivos, digest inicial/final/revisor/root `944ec711df66681414ada01a85be93be70b35fc44fd6312a5e00b0a41c8de620`.
Baseline 13.1 reutilizado inicialmente por paridad literal: 2393 ejecuciones, Billing 34/22, ambos builds y
PRE/POST PASS. Los cinco Swift de 13.1 conservan exactamente el manifest histórico incluido al final.
Esa solicitud no autorizaba entrega Git/Done. La autorización posterior de entrega se registra abajo;
13.3 y live conservan gates propios. Fase 13 abierta; deuda accesible previa intacta.

### Implementación y TDD 13.2

Nuevo contrato `BillingDocumentReservationRepository: Sendable`: reserva atómica número/documento, replay del
request íntegro, conflicto de identidades/contenido y series independientes para ticket/factura. Errores neutrales.
Nuevo `ReserveBillingDocumentUseCase` genérico: una llamada por intento, correlación completa de la respuesta,
cancelación antes y después del contacto, propagación de errores neutrales y traducción del fallo desconocido.
El llamante conserva el request para recuperar explícitamente un commit cuya respuesta se perdió. No genera
identidades, fechas o números; no cachea, reintenta automáticamente, muta estado local ni cierra la venta.
La autoridad real, transacción e idempotencia Firestore pertenecen a 13.3; el doble actor no las acredita.

Tests escritos primero, 11 declaraciones / 34 ejecuciones: replay tras recrear UseCase, series intercaladas,
nueve variantes de conflicto, identidad de documento reutilizada, diez variantes de respuesta mal correlacionada,
cuatro errores neutrales, error desconocido, respuesta perdida y cancelación previa/postcommit/nativa.
Gates deterministas sin sleeps; se drenan tareas y continuations también en RED.
Dos fallos de setup se corrigieron antes del RED ejecutable: initializer del actor en extensión y ambigüedad de
macro Swift Testing para arrays de enteros. Esta última se resolvió conservando cuatro oráculos individuales
41/42/91/92; no se retiraron expectativas ni tests históricos.

RED compilable 03:01:58: **34/34 FAIL**, por el stub que devuelve unavailable;
summary `RunSomeTests/AFE343DA-2D50-4A15-9612-A813564B9C5E.txt`.
GREEN focal 03:02:57: **13/13 PASS**, selección parcial de argumentos por Xcode;
summary `RunSomeTests/44FF0F32-7366-4B03-9670-D843AAE6E567.txt`.
No se atribuye cobertura completa al GREEN parcial; la matriz completa se verificó en la suite global.
Estos bundles focales no quedaron disponibles para lectura nativa; se conserva la evidencia MCP/summary completa.

### Validación definitiva 13.2

Xcode MCP oficial estable, Xcode 27.0 (27A266), `workspace-PfnUYLlMzY`; Develop/plan Develop,
iPad Pro 13-inch (M5) Simulator 27.2 / SDK 27.0. Target 27.0, Swift 6 complete/default nonisolated;
warnings Swift/Clang como errores. Configuración y archivos históricos sin cambios.
Build-for-testing Develop 03:21:12 / 24.212 s PASS (`BuildProject-Log-20261003-032112.txt`);
Production 03:09:34 / 31.277 s PASS (`BuildProject-Log-20261003-030934.txt`).
Cero diagnósticos estructurados Swift/Clang; logs completos: únicamente dos avisos conocidos AppIntents por build.
Builds incrementales; no se afirma clean-build ni cero warnings globales. Scheme/plan/destino inicial conservados.

RunAllTests definitivo 03:21:12: **2427/2427 ejecuciones PASS**, 1516 declaraciones;
cero failed/skipped/expected/notRun. Summary `RunAllTests/F29C6B05-EBBC-44C5-8072-81F12FB90B87.txt`, bundle
`RunAllTests/Test-FranAlonso-Develop-2026.10.03_03-21-12-+0200.xcresult` en ActionArtifacts/default.
xcresulttool confirma 1516/1516 declaraciones y 2427/2427 ejecuciones; nueva suite 11/11 declaraciones,
34/34 ejecuciones y todos los grupos parametrizados completos (10/9/2/4/2/2).
UI/previews/localización/accesibilidad 13.2 N/A: solo Domain, sin pantallas ni texto visible.
Sin acreditación de backend real, durabilidad Billing, PDF, correo, cierre 13.12 o live.

### Intermitencia histórica de Stock observada

Primer RunAllTests 03:06:12: 2426/2427 PASS; 34/34 nuevos PASS. Único fallo en
`StockSyncDurabilityTests.swift:118`: weak ModelContainer no nil después de un acknowledge/reopen.
Summary `RunAllTests/54F69667-5D94-4A05-93B4-759F2B9C4A56.txt`; bundle nativo confirma 1515/1516 declaraciones.
Se reprodujo focalmente en Develop y Production, sin modificar ese test ni sus helpers o producción Stock.

Abrir el worktree baseline exacto `ee97380` necesitó autorización nativa Xcode: no se abrió ni se ejecutó allí;
checkout limpio archivado. Alternativa aceptada previamente por el revisor: excluir temporalmente de compilación
solo los tres Swift nuevos mediante `#if false`, build Develop 03:20:23 / 28.879 s PASS y mismo test 0/1 PASS,
fallando otra vez en la línea 118 (`RunSomeTests/7223FD1A-7938-4809-B53B-C497266CF0F2.txt`).
Control de aislamiento funcional: demuestra que el fallo puede aparecer sin ejecutar las incorporaciones 13.2;
no representa un checkout baseline exacto ni demuestra la causa de la retención.
Restauración en finally de los bytes exactos; huella completa 912 archivos volvió al digest POST de abajo.
La ejecución definitiva posterior pasó también ese test, sin alterar ninguna expectativa.
Se registra la intermitencia; no se declara corregida, no se omite el test y su diagnóstico queda separado de 13.2.

### Estilo, POST y gobernanza 13.2

Estilo independiente: tres Swift; script cero candidatos, pase manual detectó un patrón en dos closures
`try await` en línea. Normalizadas a multiline sin cambiar comportamiento ni expectativas; reauditoría focal PASS
antes de builds definitivos. Huella inicial 912 archivos `17323b4a8e5ffcd739a52434d967d5b482a2d7c211b2a449278f0c9c817b2282`;
tras corrección, inicial/final/root `f49069b3cabcdec6d5be0ff1f04d6159b20307ca73e494a9fb761ff55544bd57`.
POST independiente `billing_13_2_post`: código/evidencia PASS, sin hallazgos P0–P3, huella operacional read-only
912 archivos inicial/final/root idéntica al digest anterior. Verificó PRE, RED/GREEN, primera regresión con fallo
histórico, builds completos y manifest. Reauditoría documental/de validación final PASS sin hallazgos P0–P3:
912 archivos, huella inicial/final/revisor/root
`ba18be5eb8873fe66b18c7542a106c0ecb0814edf8d2d929b75121202e599b2e`.
Verificó el control y restauración exacta, 2427/2427 ejecuciones / 1516 declaraciones finales, los 34 nuevos
completos, Stock Passed, ambos logs y los tres documentos. La causa de su intermitencia continúa sin diagnosticar.
Sin imports UI/persistencia/SDK, opt-outs, GCD, JSONSerialization, dependencias o cambios de target en el alcance.
Gobernanza: únicamente seis enlaces Desktop históricos rotos de 08.3, conservados; diffcheck PASS.
No hay cambio de código posterior al manifest. Actualizaciones documentales adicionales: Xcode N/A por paridad.
PLU-97 permaneció In Progress hasta la entrega autorizada y verificada más abajo.

### Manifest Swift 13.2 probado

SHA256 de los únicos tres Swift nuevos; todas las directivas del control temporal retiradas:

```text
BillingDocumentReservationRepository.swift 00f9422f0cbc1ecbe86a7aad907911000b0af4c3930942053e0a8eaecfd11116
ReserveBillingDocumentUseCase.swift ad757cccab7c127c4e7bb818e6b7bc2b524969e4184808e22477dca6987a9098
ReserveBillingDocumentUseCaseTests.swift 4e6b8654c71f6c095880d1b2adcb62a1477d710bbf486ec2533bb89461c8c899
```

### Autorización de entrega 13.2

03/10/2026: el propietario solicita «commit, push y entrega». Autoriza el mismo recorrido completo establecido
para 13.1: commit del alcance exacto, push, PR/revisión/merge, reconciliación PLU-97 Done y limpieza de rama
tras comprobar ancestry. No autoriza 13.3, cierre de fase 13 ni live.
Se reutilizan 2427/2427 ejecuciones, 1516 declaraciones, 34/34 casos nuevos y ambos builds/PRE/POST/estilo PASS:
los tres Swift 13.2 y cinco Swift 13.1 mantienen los hashes exactos probados/auditados.
Solo se añade documentación/changelog de entrega: Xcode adicional N/A por paridad literal.
Revisión focal previa a entrega PASS sin hallazgos P0–P3: 912 archivos, huella inicial/final/root
`50774cfbf5bc5a0ce4d2117fd88702896d1d8c5ac076d01e7ca7705429d87631`.
Confirmó ocho Swift exactos y audit de estilo de los tres nuevos: cero candidatos, pase manual PASS.
Resultado Git definitivo pendiente. El propietario reconectó Linear tras la reautenticación requerida;
PLU-97 In Progress / Jesus Franco, sin comentarios concurrentes ni parent/milestone13 y proyecto In Progress.
No se declara Done hasta comprobar entrega y estado. La intermitencia observada en Stock sigue sin corrección.

### Entrega verificada 13.2

[PR51](https://github.com/JFrancoG/FranAlonso/pull/51) MERGED 03/10/2026 10:04:19 Madrid:
feature `09b5e193dd35d6bc0b3df49f920d895a98d85acd` → merge `29b4b8a9a6aa9f8e00898d110a06126dc573b567`.
Árbol completo integrado idéntico al head revisado; tres Swift nuevos y cinco históricos exactos al manifest probado.
Revisión independiente de PR PASS sin hallazgos P0–P3: diff remoto/commit local idénticos, siete archivos previstos;
912 archivos, digest inicial/final/root `2ffe7e98ca0f6d97ac24ddba2ca4b26547d9e1ac34b7c7691fbe11ebc48cce49`.
Dictamen registrado como COMMENTED en GitHub, sin atribuir aprobación a otro colaborador.
Head fijado con match-head-commit antes de merge; CLEAN/MERGEABLE, sin checks/workflows remotos ni protección/rulesets.
No se declara CI verde. Main local fast-forward; ramas local/remota eliminadas tras ancestry y cero commits únicos.

PLU-97 pasó automáticamente a Done tras el merge; estado verificado con completedAt 08:04:20 UTC.
Proyecto In Progress; sin parent/milestone de fase 13 existentes. Fase 13 permanece abierta y 13.3 requiere su propio inicio.
Reconciliación de descripción/comentario de entrega y snapshot de proyecto basada en este resultado verificado.
UI/previews/localización/accesibilidad 13.2 N/A; deuda previa conserva responsables y condiciones de recuperación.
Se reutilizan 2427/2427 ejecuciones, 1516 declaraciones, 34 casos nuevos, ambos builds y PRE/POST/estilo PASS.
Este cierre modifica solo documentación/changelog: Xcode adicional N/A por paridad literal de los ocho Swift.
Intermitencia del test histórico de Stock sin corrección ni causa atribuida; avisos AppIntents conocidos conservados.
Diffcheck y enlaces del alcance PASS; gobernanza mantiene únicamente seis enlaces Desktop históricos rotos de 08.3.
Sin backend real, persistencia Billing, PDF/correo, cierre 13.12, live ni implementación 13.3.

Reauditoría final documental PASS sin hallazgos P0–P3: 912 archivos, huella inicial/final/root
`ebef4124d6ec654bd42621ab5d7129d436de6b64417e2bccd496d0e8a9d0f67f`.
Verificó PR/merge, tres árboles idénticos, ancestry/ramas eliminadas, PLU-97 Done y los cuatro documentos.
Descripción y comentario de entrega reconciliados; snapshot de proyecto actualizado sin cambiar In Progress.
Registro posterior de este resultado exclusivamente documental; ocho Swift probados intactos, Xcode N/A.

## 13.1 / PLU-96 — Entregada; Done

03/10/2026: autorización «Abre issue y rama e implementa la subfase13.1».
[PLU-96](https://linear.app/plusprojects/issue/PLU-96), Done/Jesus Franco tras la entrega verificada más abajo;
`codex/plu-96-billing-domain-states`, baseline `38b49f4` en main/origin/main sin cambios locales.
[Propuesta y límites](13-1-billing-domain-proposal.md). [PR50](https://github.com/JFrancoG/FranAlonso/pull/50)
integrada; rama local/remota eliminada. Fase13 abierta,13.2 conserva autorización propia.

## Puerta de inicio

Constitución, spec13, ADR0003/0004/0008/0011/0030 y política Swift revisados. Billing04.6 tenía estados
pending/numbered pero permitía construcción mediante solo saleID sin validar pago. No hay DTO, esquema SwiftData
ni consumidor productivo de esas fábricas. Sale ya conserva documento obligatorio en closed/voided y rechaza cierre
antes del pago; esa lógica y su serialización no cambian13.1.

PRE independiente `billing_13_1_pre` PASS sin hallazgosP0–P3 antes del código. Modo operacional read-only:
904archivos Git tracked/untracked no ignorados, digest inicial/final/root idéntico
`8c40dc936bd9975b654a59b5b732d71881fad66f76e5643c5b6eb9e4ad504568`.
Apple Codable leído completo por el revisor; custom decode/encode contrastados con Xcode DocumentationSearch.
Spec04 alineada con la separación solicitud local/documento remoto de13.1.

## Baseline actual

Xcode27.0(27A266), MCP oficial estable Service `workspace-PfnUYLlMzY`; Develop, planFranAlonso-Develop,
iPad Pro13-inch(M5) Simulator27.2/SDK27.0. Target27.0, Swift6 complete/nonisolated y warnings Swift/Clang como errores.
Inventario1491declaraciones. Billing/SaleDomain/Workday:35/35ejecuciones PASS,0failed/skipped/expected/notRun.
`RunSomeTests/E1DF7396-A39F-4895-84B5-50C50270DD06.txt`, bundle01:45:48Madrid03/10.
Build baseline:0diagnósticos Swift/Clang; aviso conocido AppIntents metadata en app y test target.

## Implementación y TDD

`BillingDocumentRequest` valida la venta pagada en awaitingDocument y conserva el snapshot exacto/identidades/familia.
Rechaza venta impagada/terminal y fecha no finita tanto al construir como al decodificar; precedencia causal por estado.
`BillingDocument` es el registro numerado confirmado: serie compatible, entero positivo y fecha finita preservada.
No compara relojes independientes ni reserva/incrementa números ni acredita PDF final.
`BillingDocumentLocalState` separa pendingNumber/failed/numbered;
fallos neutrales sin strings de infraestructura, reintento con idéntica solicitud, recuperación desde failed y replay
exacto idempotente. Conflictos de request/snapshot/número/fecha no reemplazan el estado; numbered no vuelve a pendiente.

Se conservan/adaptan los8casos anteriores y se añaden14declaraciones de comportamiento. El codec preparatorio04.6
sin solicitud pagada se rechaza explícitamente; no existe store/DTO Billing publicado ni datos reales que migrar.
Sale.close/DTO/schema y política de Jornada intactos: confirmar número no cierra la venta.13.12 verificará documento final.

Tests primero y superficie mínima compilable: primer build detectó un `try` ausente en un payload de test; corregido
sin cambiar expectativas. RED ejecutable01:56:59:34ejecuciones,17PASS/17FAIL,9declaraciones con fallo, por las nuevas
invariantes deliberadamente ausentes. No fueron fallos de setup. Summary `559ADC25-F104-427C-ABBF-65CECC438FBF.txt`.
Tras implementación, GREEN focal01:57:50:26/26PASS; inspección del log detectó selección parcial de algunos argumentos
por Xcode. Ese resultado no acredita toda la matriz: resuelto mediante RunAllTests posterior.

## Primera validación por Xcode MCP

Misma conexión/SDK/destino. Build-for-testing Develop02:01:20/12.121s PASS:
`BuildProject-Log-20261003-020120.txt`; Production02:02:23/27.334s PASS:
`BuildProject-Log-20261003-020223.txt`.0diagnósticos estructurados Swift/Clang.
Logs completos inspeccionados: únicamente2avisos conocidos AppIntents metadata por build (app y target test).
Builds incrementales, sin afirmación de clean-build ni de cero warnings globales. Develop/plan/destino inicial restaurados.

RunAllTests02:01:20:2393/2393ejecuciones PASS,1505declaraciones en inventario,
0failed/skipped/expected/notRun. Summary `2934C230-40D2-4566-8CEF-3D019CEEF2EA.txt`;
bundle `Test-FranAlonso-Develop-2026.10.03_02-01-20-+0200.xcresult`, en ActionArtifacts/default/RunAllTests.
Inspección nativa con xcresulttool confirma Billing34/34ejecuciones de22declaraciones y los8grupos parametrizados
completos (2/3/2/3/3/3/2/2casos). Regresión incluye Sale, Jornada, pago/stock, persistencia/sync y resto de suite.
No prueba emisión fiscal, Firestore/Storage/correo reales, recuperación durable Billing ni cierre13.12.

## Estilo, auditoría y gobernanza

Auditoría independiente `billing_style`:5Swift; script0candidatos, pase manual detectó1guard fragmentado118columnas.
Compactado y reauditoría focal PASS antes de validación final. Digest read-only inicial/final908archivos:
`328b4047f8559b4f4e90b1706a497cdac7b864df7010693ad8bfb6b334e83ce0`;
revisión tras corrección `14895f8f037cdf97683ae9d2a73f3bc8ea4a1ca9a077c7cf295c8226f681caa3`.
Sin imports UI/persistencia/Firebase/PDFKit, opt-outs, GCD, JSONSerialization ni dependencias nuevas en el alcance.
UI/previews/localización/accesibilidad13.1 N/A: solo Domain sin pantalla ni texto visible.
Gobernanza repetida: únicamente6enlaces históricos rotos08.3, idénticos al baseline; diffcheckPASS.
Primera POST:1P2 de comparación de relojes, corregido debajo; sin otros hallazgos. Reauditoría focal PASS.
La deuda accesible previa mantiene sus issues/responsables/trigger.
Fase13 abierta; solo13.1 autorizada. Entrega13.1 verificada debajo; live y13.2–13.13 conservan gates separados.

## P2 corregido y validación definitiva

`billing_13_1_post` comprobó causalidad de pago, captura local paymentDate() y
[timestamp del servidor](https://firebase.google.com/docs/firestore/manage-data/add-data#server_timestamp).
Las comparaciones requestedAt/issuedAt>=paidAt suponían una autoridad de reloj común no garantizada. Podían impedir
solicitud desde otro dispositivo o recuperación de una asignación ya confirmada. Propuso y aprobó read-only antes del
ajuste conservar fechas finitas exactamente y usar awaitingDocument como prueba causal del pago.
Gate inicial: corregirP2;908archivos, digest inicial/final/root idéntico
`920bcca25225e6fe008946370753facaac99152ceb0038f01859ff9dd334a2a0`.

Tests del desfase escritos antes de retirar comparaciones: RED2/2FAIL02:11:17 con invalidChronology,
summary `D4A45E0F-D664-4665-BF11-0EF2A571F650.txt`; GREEN2/2PASS02:12:05,
summary `70272543-0ED1-4EA3-9988-627BC04EC853.txt`. Dos expectativas temporales del diseño inicial sustituidas por
el contrato causal revisado; no se debilita el gate de pago ni se fabrican fechas. Retirado invalidChronology;
constructor/decoder/aceptación/replay prueban paidAt200/requestedAt199 o issuedAt199 según el reloj originario.

Estilo independiente repetido sobre cambios de entidades/tests:5Swift/0candidatos/manualPASS,
0líneas>120; digest908files `1f3d8c0653bed4609b394e752844992a47dfa0885e0b4b25344eaf3f8de99630`.
Después: Build-for-testing Develop02:13:37/3.554s PASS (`BuildProject-Log-20261003-021337.txt`),
Production02:14:22/28.643s PASS (`BuildProject-Log-20261003-021422.txt`);0diagnósticos estructurados Swift/Clang.
Logs completos conservan únicamente los avisos conocidos AppIntents; build incremental, sin certificado clean-build.
Scheme Develop/plan/destino inicial restaurados.

RunAllTests definitivo02:13:37:2393/2393PASS,0failed/skipped/expected/notRun;1505declaraciones.
Summary `28266BE4-F100-45E9-B262-81F8752A57A1.txt`, bundle
`Test-FranAlonso-Develop-2026.10.03_02-13-37-+0200.xcresult`, ActionArtifacts/default/RunAllTests.
xcresulttool confirma Billing34/34ejecuciones de22declaraciones con todos los argumentos completos, incluidos desfases.
Manifest siguiente corresponde exclusivamente al código definitivo probado. Reauditoría POST focal PASS.

## POST definitivo y estado de entrega

`billing_13_1_post` verificó la corrección, RED2/GREEN2, bundle definitivo2393/1505 y Billing34/22/todos argumentos,
manifest5Swift y ambos logs. P2 resuelto; sin hallazgosP0–P3 restantes. Revisión operacional read-only908archivos,
digest inicial/final/root idéntico `5995db168f7d5f1e4aabf3495eaf7d7e31da9796546e7212f4e3e345a4450878`.
Actualización posterior exclusivamente documental: paridad literal de5Swift probados/auditados; Xcode adicionalN/A.
Tras POST, PLU-96 permanecía In Progress/Jesus; documentación y descripción reconciliadas. Rama local lista para entrega;
sin commit/push/PR/merge/Done en ese momento. Fase13 abierta,13.2 y live conservan sus gates.

## Autorización de entrega03/10/2026

El propietario solicita «commit, push y entrega». Autoriza el recorrido completo de13.1 ya establecido:
commit del alcance exacto, push de rama, PR/revisión/merge, PLU-96 Done y limpieza de rama tras comprobar ancestry.
Resultado Git definitivo pendiente; PLU-96 aún In Progress. No autoriza13.2, cierre de fase13 ni live.
Se reutilizan2393ejecuciones/1505declaraciones, Billing34/22, buildsDevelop/Production y PRE/POST PASS:
los5Swift conservan SHA256 exactos del manifest probado/auditado. Estilo scoped repetido:5Swift/0candidatos,
sin cambios posteriores de código ni hallazgos nuevos. Solo documentación/changelog; Xcode adicionalN/A.

## Entrega verificada13.1

[PR50](https://github.com/JFrancoG/FranAlonso/pull/50) MERGED03/10/2026 02:36:39Madrid:
feature `ad7c344b59bf0e24289cde52e9404a00b444d4f5` → merge `646fe84ac5705c3ac2126bd6595200a70426d56a`.
Árbol completo del merge idéntico al head revisado;5Swift exactos al manifest probado/auditado.
PR CLEAN/MERGEABLE con head fijado antes de merge; sin workflows/checks remotos ni protección de main.
No se declara CI verde. Main local fast-forward; ramas local/remota eliminadas tras ancestry y0commits únicos.

PLU-96 pasó automáticamente a Done tras el merge; estado verificado y descripción/comentario de entrega reconciliados.
Proyecto In Progress, sin parent/milestone13 existente; no se cierra fase13.13.2 es el siguiente gate independiente.
UI/previews/localización/accesibilidad13.1 N/A; deuda previa conserva issues/responsables/trigger.
Se reutiliza la validación literal anterior:2393/2393, Billing34/22, buildsDevelop/Production, PRE/POST y estilo PASS.
Este cierre cambia solo documentación/changelog: Xcode adicionalN/A. Diffcheck/enlaces del alcance PASS;
gobernanza conserva únicamente6enlaces Desktop históricos08.3, y AppIntents mantiene sus avisos conocidos.
Sin backend, PDF, persistencia Billing, correo, cierre13.12, live ni implementación13.2.

## Manifest Swift definitivo probado

SHA256 por archivo; los tres primeros viven en Billing/Domain/Entities, los dos últimos en FranAlonsoTests:

```text
BillingDocument.swift 01689d22c7c6c236713df0e9cd504e007f4b0c1a8beac7a82674d024a231c430
BillingDocumentRequest.swift c806e7eaf78b3fe3c896d32d1fc04ba7428acf05dbbdc313c2c058ca4b22dce9
BillingDocumentLocalState.swift 2b7a0ca80f25cab8bf4c706ec5df3df577af310abeda5777295c9f5ce0b6a2a1
BillingDocumentTests.swift b8836eaffed88f135253a795468749b153a5d2de945f254af0c2f0c5b10bf873
BillingDocumentRequestTests.swift f7b870233c36eb9dcd96451f900e78953e0c01d14509f40518982ce8e2cd52ed
```
