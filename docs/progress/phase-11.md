# Fase11 — Jornada y motor de ventas

Última actualización: 2026-10-02.
[PLU-71](https://linear.app/plusprojects/issue/PLU-71): In Progress, Jesus Franco.
Autoridad: [spec11](../specs/11_sales_engine.md), constitución y ADR0011/0016/0018/0030.

## 11.1 — Ciclo local de borrador

[PLU-72](https://linear.app/plusprojects/issue/PLU-72): Done; rama `codex/plu-72-sale-draft-lifecycle` eliminada.
Base main `4175fb1`, limpia y sincronizada. Usuario autoriza issue/rama e implementación local.
El01/10 autoriza también commit, push, PR, merge, cierre de issue y eliminación de rama.
[Propuesta](11-1-sale-draft-proposal.md): crear, recuperar, editar y descartar sobre la infraestructura05.10c.
PRE favorable por revisor nuevo `sales_draft_pre`: sin hallazgos. Inventario692 y huella idéntica antes/después:
`3966a0abc919b90e64b1853a991caadc0140839b839115d32c6507d9908279ea`.
Modo operacional read-only sin writes/builds. Baseline reciente documental no acredita11.1.
La ruta nativa histórica no estaba disponible para el PRE; se exige evidencia nueva de este incremento.
Implementación local completa: cuatro UseCases, recuperación individual, creación de identidad nueva,
edición del snapshot esperado y descarte draft-only. Actor y adapter comparten el mismo local source;
SwiftData y cola causal permanecen como SoT. No cambia el esquema, DTO ni la política remota.
Se conservan id, fecha exacta y términos capturados de líneas retenidas; cantidad/descuento son editables.
Conflictos, identidades conocidas, tombstones, copias obsoletas y ventas progresadas rechazan sin sobrescritura.
`saveSale` genérico conserva su contrato de infraestructura previo; este incremento usa comandos específicos.
La comprobación/aceptación no suspende en su contexto; no promete CAS entre contextos independientes.
Sin UI: previews/AT N/A; no se activa sync ni se modifica el esquema SwiftData.

### TDD y validación técnica

- RED: tres declaraciones/ocho resultados fallan por `.persistenceUnavailable` de stubs mínimos compilables.
  Build12,410s; summary `69E5AE71-0674-4422-8EE9-B757F9A89E8E.txt`.
  Huella de698 archivos en RED: `495e55fec0630a3f70166a7e91be0c3c2181e70af3643fefa73edf6e5fbf6bb0`.
  El primer intento tuvo dos `try` faltantes en macros de test; corregidos antes del RED válido.
- GREEN/regresión focal inicial: **156/156 resultados,119 declaraciones**, cero failed/skipped/notRun/expectedFailures.
  Sales Domain/DTO/persistencia/sync/retry/remote/schema y AppDependencies, seleccionados desde lista fresca
  `2C15F970-DEBC-4E50-9BA8-39E64C859302.txt` por Xcode MCP.
  Suite nueva definida:18 declaraciones/43 variantes; el resultado focal ejecutó38 variantes, como detectó POST.
  Composición:+2 declaraciones.
  Summary `CEA94BBB-5A23-423A-A853-D69E2916DA32.txt`.
- Evidencia nativa cerrada y examinada con `xcresulttool`:119 declaraciones/156 invocaciones, PASS,
  sin fallos ni runtime warnings. iPhone11 físico/iOS27.2(24B5089g), Xcode27.0/27A266a, SDK27.0;
  esquema/plan `FranAlonso-Develop`. Ruta:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_13-25-15-+0200.xcresult`.
- Build Develop-for-testing17,567s: `BuildProject-Log-20261001-132441.txt`;
  Production20,377s: `BuildProject-Log-20261001-132707.txt`. MCP, sin `xcodebuild`.
  Logs completos revisados; cero warnings Swift/Clang. Se conserva el aviso previo del extractor
  AppIntents: `Metadata extraction skipped, no AppIntents.framework dependency found` (dos en Develop, uno en Production).
  No se atribuye cero warnings globales ni se añade una dependencia ceremonial.
  Consulta warning MCP sin issues ni truncación: `74B0F3F2-...`/`6B433221-...`.
  Esquema Develop/destino iPhone11 restaurados; planes no alterados.
- Rollback de create/update/discard provocado tras mutación mediante fila sintética no decodificable;
  verificación en contexto nuevo confirma snapshot/cola sin cambios y contexto limpio. Colisión de operación cubierta.
  Cancelación cubierta antes del UseCase y dentro de actor tras hop; no se fuerza un error de cancelación después de commit.
  Paridad adapter/repository, copia obsoleta y seis identidades conocidas cubiertas.
  Correcciones de setup: predecessor faltante en fixture de descarte; errores raw de rollback/colisión sustituidos por
  el error neutral exigido por el contrato aprobado, conservando todas las aserciones de efectos.
- Fuente validada:546 archivos App/Tests/proyecto,
  SHA256 `f3caaf866be54502ec4302a47c5d451f6da3ed38540a8ced526e375b6ad73980`.
- Estilo Swift Audit:16 archivos modificados/nuevos; cuatro candidatos adjudicados:
  función closure/genérica vertical y tres predicates previos fuera del diff. Sin líneas mayores de120 ni hallazgos nuevos.
  `git diff --check` PASS. Gobernanza mantiene únicamente seis enlaces históricos rotos de capturas08.3,
  documentados en Progress previo; ningún enlace nuevo roto. Sin cambios en secretos, paquetes, targets o configuración.

### Cobertura completa tras el hallazgo POST

- P2: el resultado focal omitió `false` en creación y cuatro estados progresados; se preserva su PASS156
  sin atribuirle toda la matriz. Retest de los dos métodos también ejecutó solo `true`/`awaitingPayment`,
  PASS2 en summary `05822F19-18EE-4519-AE0F-8B30DE887D53.txt`; no cerró el hallazgo.
- Se amplió a `RunAllTests` sin filtro de métodos, justificadamente por esa cobertura ausente.
  iPhone11: **1.740PASS/13FAIL**,1.753 resultados/1.139 declaraciones, summary `140D956A-16E2-4929-BE26-5ED5A4502B52.txt`.
  Suite nueva completa **43/43PASS**, incluidos vacío y los cinco estados; árbol nativo examinado.
  Los13 fallos fueron exclusivamente inspecciones de archivos del Mac por `#filePath`:
  diez `BuildEnvironmentConfigurationTests` y tres `DesignSystemColorAssetTests`, todos Cocoa260.
  No se alteraron esos tests ni se atribuye PASS a este ensayo físico global.
- **GREEN completo en Simulator iPhone17/iOS27.2:1.753/1.753PASS,1.139 declaraciones**,
  cero failed/skipped/notRun/expectedFailures y runtime warnings. `RunAllTests` por Xcode MCP estable.
  Summary `18F1D7F7-723A-4457-994F-39CFBA4BA4A2.txt`; native cerrado:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_13-43-16-+0200.xcresult`.
  Summary/árbol examinados:18 declaraciones/43 variantes nuevasPASS, `false`+`true` y
  `.inProgress`/`.awaitingPayment`/`.awaitingDocument`/`.closed`/`.voided` presentes yPASS.
  Las13 inspecciones tambiénPASS en su entorno con acceso a los archivos.
- Build de tests Simulator correcto; warning MCP `7B0B86A5-B12E-4D0B-90C0-FD20A4A33ED3.txt`,
  sin issues ni truncación. Fuente546 y todo el inventario698 conservaron sus huellas durante los retests.
  Destino iPhone11/esquema Develop restaurados. Sin cambios de código, configuración o plan para corregir el P2.

### Auditoría POST

Primera pasada por revisor nuevo `sales_draft_post`: sin hallazgos de implementación/estilo,
P2 de cobertura/evidencia corregido mediante ejecución completa y documentación. Inventario698 idéntico antes/después:
`ee493259ddc00b14ecc770ba88ae3fa6beaf6f6a8c627e50964aec0ed049882f`.
Reauditoría focal posterior de evidencia por el mismo revisor: **PASS**, sin hallazgos abiertos; P2 resuelto.
Resultados nativos y logs examinados directamente; código/configuración intactos, sin repetir la auditoría de implementación.
Inventario698 idéntico antes/después de esta reauditoría, certificado por el orquestador:
`adf0d60d9962ae94d2dfa63f3a2d792d72bb22b417e1e9f1dd8951113196a647`.
UI/accesibilidad N/A (sin delta). Solo se reconcilia después la metadata de auditoría y entrega.

## Pendientes

11.1 entregada y cerrada; no quedan gates abiertos dentro de su alcance aprobado.
11.2 entregada y cerrada en PR34/PLU-73; GREEN/builds/PRE/POST PASS.
11.3 entregada y cerrada en PR35/PLU-74; 1.840/1.840, builds y PRE/POST/entrega favorables.
11.4–11.6 entregadas en PR36–38; 11.5/11.6 cierran su gate funcional según ADR0029.
11.7–11.9 conservan sus propios gates; PLU-77/79 mantienen validación accesible integral.
La demo completa necesita stock12 y documento13; fase11 y deuda accesible previa siguen abiertas.

## Entrega11.1 — 2026-10-01

- Autorización completa del usuario: commit, push, PR, merge, cierre de issue y eliminación de rama.
- Commit `8cc3181f537093454204b069bdd6176191fa6f90`,
  `✨ feat(sales): complete local draft lifecycle`, publicado en origin.
- [PR33](https://github.com/JFrancoG/FranAlonso/pull/33) MERGED;
  merge `794478ebc2bcac85c2a4048f2fa71abf0928fa13`, con dos padres y árbol idéntico al head validado.
  Antes de integrar: head/base exactos, CLEAN/MERGEABLE, 21 archivos previstos, sin reviews ni checks pendientes.
  GitHub no tiene workflows/checks, protección de main ni rulesets configurados; no se atribuye CI PASS.
- Evidencia técnica reutilizada por identidad de fuente546 y SHA validada; no cambió código/configuración desde GREEN.
  El cierre documental modifica solo metadata de entrega: Xcode build/tests N/A razonado; no se repiten validaciones.
- Rama local/remota eliminada después de verificar ancestry y cero commits únicos frente a origin/main.
  Se comprobó ausencia local/remota y main limpio, actualizado por fast-forward y sincronizado con origin/main.
- PLU-72 Done leído de vuelta tras el merge; descripción y comentario reconciliados con entrega y límites.
  PLU-71 conserva In Progress y registra11.1 entregada; siguiente gate11.2/SaleCalculator, sin iniciar.
- Progress, spec11 y CHANGELOG reconciliados; publicación documental posterior en main según el flujo reciente.
  `git diff --check` PASS y presupuesto Progress respetado; solo seis enlaces históricos08.3 siguen rotos.
  Este cierre no activa live ni declara terminada la fase11 o la demo completa.

## 11.2 — Cálculo monetario

Registro del inicio y gate local, anterior a la autorización de entrega:

[PLU-73](https://linear.app/plusprojects/issue/PLU-73): In Progress, Jesus Franco.
Rama `codex/plu-73-sale-calculator`, base limpia/sincronizada `c800ccd`.
Autorización de issue, rama e implementación local; sin entrega Git ni cierre autorizados.
[Propuesta](11-2-sale-calculator-proposal.md): completar límites de Decimal sobre el calculador04.4,
conservando precios IVA incluido, descuento por línea y snapshots. Sin descuento global11.7/UI/live.
Baseline técnico reciente11.1 reutilizado por fuente idéntica; no acredita11.2.
PRE inicial: P2 por restricción general de productos inexactos; sustituida por cotas dirigidas de descuento
para preservar porcentajes válidos.699 archivos idénticos antes/después de esa pasada,
SHA `3b31409e98eca382857355184909207de157917b2c21a9e5949d6849e5813692`.
Reauditoría focal PRE favorable: P2 resuelto, sin nuevo ADR;699 archivos idénticos antes/después,
SHA `35525f306997d1ced04773ac9a9299af743d22ff447dbe3420e1c39e08bf5d6d`.
### TDD 11.2

- Archivo nuevo `SaleCalculatorBoundaryTests.swift`: siete declaraciones, 39 variantes previstas;
  oráculos literales EUR/USD, fracciones, empates con ambos signos, Int.max, overflow, precisión y payloads SaleDTO.
- Build-for-testing Develop por Xcode MCP estable PASS, cero issues en log completo sin truncar
  `FD776156-B0F8-4256-BDB2-D90557428DAA.txt`.
- Primera ejecución descartada como RED: `Decimal(string: "1e164")` falla en el setup iOS.
  Se conserva el valor exacto con significando de 38 dígitos y exponente 127, sin alterar las expectativas.
- RED real: 0 PASS / 2 FAIL, sin skipped/notRun/expectedFailures; producción aún intacta.
  Descuento 100 % sobre 10^164 lanza invalidAmount aunque el resultado cabe;
  sumar ese importe y 0.01 no rechaza la pérdida del céntimo.
  Summary MCP `9753A881-76BA-4189-938B-F4C35F161669.txt`, native cerrado y examinado:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_15-07-46-+0200.xcresult`.
  Fuente 547: `1eabb17f6e86a5f06e134b8ddc4dfccccd7de3864af0acfc89dbad3ce3328127`.
- Primera implementación después del RED real: Develop-for-testing PASS (log `BuildProject-Log-20261001-151232.txt`).
  Primera regresión completa: 1.790/1.792; ambos RED iniciales PASS, dos variantes cantidad FAIL.
  Summary `95EB3F7B-F119-4FA4-9F10-E2690F84B016.txt`.
  Diagnósticos RunCodeSnippet por Xcode MCP: NSDecimalMultiply plain/down/up retornan noError y mismo resultado
  truncado en ese producto. NSDecimalAdd/Subtract también retornan noError tras perder precisión en un borde de coeficiente.
  UInt128/public significand/exponent verificados en el target; no se atribuye GREEN a estos diagnósticos.
- RED adicional de suma: 0/1 PASS, expected error ausente al agregar UInt128.max/100 y 0.01;
  fixture de 39 dígitos conservado y comprobado. Summary `85716013-1516-4486-9466-A00891AE9232.txt`, native cerrado:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_15-29-58-+0200.xcresult`.
  Se propone certificado privado de coeficientes con operaciones nativas fijas de UInt128; revisión focal antes del ajuste.
  PRE focal técnica sin hallazgos; P2 exige ADR antes del ajuste. Inventario 700 idéntico antes/después:
  `dadd9d1fae0ff5527221002f2e0f786a2bf1b25f0937b3a7910e9d21c78df61c`.
  [ADR 0031](../ADRs/0031-sale-decimal-coefficient-certification.md) registrado dentro de la autorización local de 11.2;
  reauditoría documental favorable, P2 resuelto antes del ajuste; inventario 701 idéntico antes/después:
  `572672ff3319ba162a8456bcb849e03f68143f76b034515fd6e1bffff14eae74`.
  Suite nueva ampliada a diez declaraciones / 44 variantes (cancelación/signo/borrow).
  Ajuste posterior al PRE aplicado; GREEN definitivo, builds y POST acreditados abajo.

### Implementación y GREEN 11.2

- Cambio acotado a `SaleCalculator.swift` y nuevo `SaleCalculatorBoundaryTests.swift`.
  Certificado privado de coeficientes conforme a ADR 0031 para productos, sumas/restas y escalas;
  descuento probado a escala monetaria, IVA por cociente exacto certificado o intervalo probado.
  IVA residual e identidades por línea/agregado, monedas y orden/IDs conservados.
  Sin cambios a Money, modelos, DTO, configuración, Store, UI, persistencia, sync o live.
- Source-style Audit antes del GREEN: dos archivos, cero candidatos del helper; adjudicación manual sin hallazgos.
  Cuatro argumentos permanecen verticales según política; llamadas Money largas no colapsan; líneas <=120.
  Inicializadores del certificado en extensión, DocC semántico y cero opt-outs de concurrencia.
- Build Develop-for-testing PASS, 16.742 s: `BuildProject-Log-20261001-155510.txt`.
  Log MCP de warning sin issues/truncación: `089689C6-4C73-42E2-A853-C54E86B155BD.txt`.
- GREEN por `RunAllTests` Xcode MCP estable, Develop/plan Develop, iPhone 17 Simulator/iOS 27.2:
  **1.797/1.797 variantes PASS**, cero failed/skipped/notRun/expectedFailures; **1.149 declaraciones**.
  Summary `81018973-6985-4BCC-9DF1-342A7A6A7342.txt`; native cerrado y summary/árbol examinados:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_15-55-36-+0200.xcresult`.
  El summary nativo cuenta 1.149 declaraciones; el árbol acredita 1.797 hojas PASS y cero runtime warnings.
  **Diez declaraciones / 44 variantes nuevas PASS**, con todas las variantes EUR/USD y ambos signos presentes:
  26 oráculos, cuatro cantidad/overflow, cuatro próximos al empate, dos payloads, dos cancelación, dos borrow
  y cuatro casos no parametrizados (descuento extremo, suma extrema, borde de coeficiente y factor fiscal diminuto).
  Todos los RED reales anteriores son GREEN; no se debilitó ningún oráculo para pasar.
- Build Production PASS, 20.206 s: `BuildProject-Log-20261001-155619.txt`.
  Log MCP sin issues/truncación: `FB6D2D74-AAF3-4FC7-AAE8-DCB2DB0260BC.txt`.
  Logs completos Develop/Production examinados: cero warnings Swift/Clang y cero errores.
  Único aviso de herramienta conocido: appintentsmetadataprocessor omite extracción por ausencia de dependencia;
  dos apariciones Develop-for-testing y una Production. No se afirma silencio absoluto del log.
- Fuente 547 idéntica antes/después de builds y tests:
  `0e473095954d921d4329178ee6de2a72124bf1ae2d8a0d2abfaf7770c944b2ee`.
  Archivo calculador SHA256 `a018db72cc6f4cacd96ca87ec9ca9ca70c0bc39fd24a95a958b19ce1583d3d4c`.
  Esquema Develop/plan Develop/destino iPhone 11 restaurados.
- UI, previews, recursos, localización, accesibilidad y dispositivo físico N/A por ausencia de delta de pantalla.
  Governance conserva únicamente seis enlaces históricos rotos en evidencia08.3; enlaces nuevos y diff --check PASS.
  Implementación y validación técnica local completadas, POST favorable; PLU-73 conserva In Progress.
  Commit/push/PR/merge, cierre de issue/rama, live y 11.3 no se han autorizado ni realizado para este incremento.

### Auditoría POST 11.2

Revisor nuevo e independiente `calculator_post`: **sin hallazgos, POST favorable para implementación local**.
Nueve archivos auditados; algoritmo, arquitectura, Domain/datos, pruebas, fuentes, estilo, evidencia y gobernanza.
El revisor y su auxiliar operaron solo en lectura, sin builds/tests ni publicaciones.
Inventario completo 701 tracked/untracked no ignorados idéntico antes/después, certificado por el orquestador:
`17286ec0ff326f12370260535026eb499ab3c145f9d348bd10452d00d0cb1e42`.
Resultados nativos y logs completos leídos independientemente; 44 variantes nuevas y 1.797 hojas PASS confirmadas.
Los tests tienen oráculos deterministas seleccionados; no son prueba exhaustiva de todos los operandos Decimal.
UI/accesibilidad N/A. Sin hallazgos aplazados nuevos; los seis enlaces históricos de 08.3 siguen fuera del cambio.
Después del veredicto se actualiza únicamente metadata de estado/auditoría y entrega pendiente en docs y Linear.
Fuente 547 conserva la huella GREEN; no se repiten builds/tests por esta conciliación documental.
PLU-73 y PLU-71 In Progress; issue y rama abiertas, sin commit/push/PR/merge/cierre/live para 11.2.

### Autorización de entrega 11.2 — 2026-10-01

Después de completar el gate local, el usuario autoriza commit, push, PR, merge, cierre de PLU-73 y eliminación de rama.
La fuente 547 coincide exactamente con GREEN y POST:
`0e473095954d921d4329178ee6de2a72124bf1ae2d8a0d2abfaf7770c944b2ee`.
Se reutilizan esas validaciones; desde entonces solo cambia metadata documental. Main/origin en `c800ccd`, sin drift.
El cierre conserva PLU-71 activa y 11.3 pendiente de su propio inicio; no autoriza live.

## Entrega11.2 — 2026-10-01

- Autorización completa del usuario: commit, push, PR, merge, cierre de issue y eliminación de rama.
- Commit `5ac7f454e161ea8a7997285f22eb235ebfbcf3ac`,
  `✨ feat(sales): complete deterministic sale calculations`, publicado en origin.
- [PR34](https://github.com/JFrancoG/FranAlonso/pull/34) MERGED;
  merge `ad5eeb552b2115aec1b1aedc0c9fa2116881e8ed`, con dos padres y árbol idéntico al head validado:
  `f6f70d0b6bf4664eda9f5ca3b123e2dc728b582e`.
  Antes de integrar: base `c800ccd`, head exacto, CLEAN/MERGEABLE, nueve archivos previstos, sin reviews/checks pendientes.
  GitHub sin workflows/checks, protección de main ni rulesets configurados; no se atribuye CI PASS.
- GREEN completo de 1.797/1.797 variantes, builds Develop-for-testing/Production, estilo y PRE/POST reutilizados
  por identidad de la fuente547. Comprobación independiente de entrega favorable; sin hallazgos abiertos.
  Cero warnings Swift/Clang; aviso conocido AppIntents documentado. UI/accesibilidad/previews/físico N/A.
- Rama local/remota eliminada tras verificar ancestry contra main/origin y cero commits únicos.
  Ausencia local/remota comprobada; main actualizado por fast-forward, limpio y sincronizado.
- PLU-73 Done leído de vuelta tras el merge; descripción y comentario reconciliados con entrega y límites.
  PLU-71 permanece In Progress y registra11.2 entregada; siguiente gate11.3/SaleDraftStore pendiente de inicio.
- Progress, spec11 y CHANGELOG reconciliados; cierre documental publicado después en main según el flujo reciente.
  Solo metadata documental: Xcode build/tests N/A; fuente547 conserva SHA
  `0e473095954d921d4329178ee6de2a72124bf1ae2d8a0d2abfaf7770c944b2ee`.
  Diff/enlaces nuevos y presupuesto Progress correctos; gobernanza conserva los seis enlaces históricos08.3 rotos.
  Este cierre no activa live ni termina la fase11 o la demo completa.


## 11.3 — Estado cohesivo de borrador

[PLU-74](https://linear.app/plusprojects/issue/PLU-74): In Progress, Jesus Franco.
Rama `codex/plu-74-sale-draft-store`, base limpia/sincronizada `5fade88`.
Usuario autoriza issue, rama e implementación local; entrega Git, cierre y live no autorizados.
[Propuesta](11-3-sale-draft-store-proposal.md): Store MainActor observable, política pura Domain,
mutaciones de snapshot, cálculo previo, aceptación11.1, busy exclusivo y cierre terminal.
PRE independiente por `draft_store_pre`: favorable, sin hallazgos; precisiones registradas antes del código.
702 archivos completos idénticos antes/después, SHA
`f13bc3be7ca13fa5e432d3f2150882051b66e32dc9e347b56a4f9e62c49b202b`.
Baseline de11.2 reutilizado por fuente547 idéntica; no acredita11.3. Implementación y GREEN nuevos abajo.
UI/previews/accesibilidad/físico N/A por ausencia de delta; 11.4–11.9 siguen pendientes.

### Implementación y TDD 11.3

- Nuevos `SaleDraftEditingPolicy.swift` (Domain), `SaleDraftStore.swift` (Presentation),
  `SaleDraftStoreTests.swift` y `SaleDraftStoreConcurrencyTests.swift`.
  El Store MainActor observable publica un único `editing(Sale, SaleCalculation)` aceptado.
  Crear/recuperar, añadir/quitar por identidad, cantidad, cliente y descuento de línea reutilizan UseCases11.1.
  La política pura conserva orden, identidad, fecha y términos capturados; no agrupa servicios repetidos.
  Todo candidato se calcula antes de persistir. Fallos, obsolescencia y cancelación previa conservan el último estado.
  Busy exclusivo, ausencia válida, descarte durable idempotente y close terminal sin tasks propias ni reapertura tardía.
  Un write ya aceptado sigue devolviendo éxito aunque el caller cancele o cierre el Store.
  Sin UI/ViewModel11.4, composición App, selector11.6, descuento global11.7, pago, stock/documento, live o dependencia nueva.
- Scaffold compilable después de corregir dos errores de preparación (inicializador de clase y `try` de fixture).
  No son RED de comportamiento. RED focal real: **0/2 PASS**, ciclo de edición y cálculo inválido lanzan `noDraft`.
  Summary `DB4C2B48-F1C4-4444-B3B5-3D8018E9738E.txt`; native cerrado y errores examinados:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_17-04-00-+0200.xcresult`.
  Fuente550 del RED: `2201b46dcd644b2ef784581d20bfbef2640ca63dbe3b15064f54425956513ebd`.
- Primera regresión completa: **1.839/1.840**, único caso fallido por cuatro oráculos Decimal construidos desde
  literales Double (19.08/39.08/36.08/32.67). El cálculo devuelve los importes previstos.
  Summary `F9AE54FB-D7CF-4D8C-9F15-2482D2C43F1B.txt` y árbol nativo revisados.
  Corrección exclusivamente en fixtures/oráculos: cadenas con `Decimal(string:locale:)` POSIX y `#require`;
  valores previstos y comparaciones estrictas conservados, sin redondear resultados ni cambiar producción.
- Source-style Audit independiente por `draft_store_pre` antes del GREEN: cuatro archivos revisados manualmente,
  un candidato del helper correctamente vertical por tipo función MainActor. Ajustes P3 de layout corregidos
  por los implementadores y comprobados en revisiones focales; sin hallazgos abiertos ni cambios de comportamiento.
  Inventarios completos706 idénticos en cada pasada, certificados por el orquestador.
  Última pasada después del ajuste de oráculos: `5a35173a7d1d7fac5aff95a4a04a30eae6b0653bec7cac9a93316da548a9e9ea`.
  Style PASS no sustituye POST funcional.
- Build final Develop-for-testing PASS, 11.015 s: `BuildProject-Log-20261001-171958.txt`.
  MCP warnings sin issues/truncación: `761979C6-57FC-4270-8B0A-979B20B5F21A.txt`.
  Build final Production PASS, 14.260 s: `BuildProject-Log-20261001-172013.txt`.
  MCP warnings sin issues/truncación: `4E5FF6B7-A2FC-4E62-AB75-16037555DEB9.txt`.
  Logs completos examinados: cero errores o warnings Swift/Clang. Aviso conocido AppIntents de extracción omitida,
  dos apariciones Develop-for-testing y una Production; no se afirma silencio absoluto del log.
- GREEN definitivo por `RunAllTests` Xcode MCP estable, Develop/plan Develop, iPhone17 Simulator/iOS27.2:
  **1.840/1.840 variantes PASS**, cero failed/skipped/notRun/expectedFailures; **1.175 declaraciones**.
  **26 declaraciones / 43 variantes nuevas PASS**: 16/28 de persistencia/edición y 10/15 de concurrencia.
  Todos los RED reales son GREEN; no se debilitaron los oráculos.
  Summary `20AC0FFB-6579-42C1-B3CD-D1C941B04D51.txt`; native cerrado, summary y árbol completos examinados:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_17-21-04-+0200.xcresult`.
  El path exportado temporal por MCP no tenía Info.plist; se verificó el bundle nativo cerrado de la misma ejecución,
  no un resultado anterior. Summary nativo 1.175/1.175, árbol con 1.840 hojas PASS, cero runtime warnings.
  Matrices EUR/USD, seis intenciones sin draft, cantidades inválidas, identidad ausente/duplicada/progresada,
  cálculo/moneda preflight, causalidad/tombstone, recuperación/stale/retry y tracking de getters cubiertos.
  Suspensiones explícitas sin sleeps acreditan cuatro solapamientos, cancelación antes/después de aceptación
  y close durante lectura/write, sin reabrir presentación ni convertir éxito durable en fallo.
- Fuente551 íntegra e idéntica antes/después de los builds finales y GREEN:
  `90302546c9985a3aa461b7551c485bdae897872c07f26fc3586d558d2d844157`.
  Xcode Develop/plan Develop/destino inicial iPhone11 restaurados y leídos de vuelta.
  UI/previews/recursos/localización/accesibilidad/dispositivo físico N/A: no hay pantalla modificada.
  Governance conserva los seis enlaces históricos de evidencia08.3; enlaces nuevos y diff --check correctos.
  Validación local completada; POST funcional favorable. PLU-74 y PLU-71 In Progress, issue/rama abiertas.
  Commit/push/PR/merge/Done/cierre de rama y live pendientes de autorización; 11.4 no iniciado.

### Auditoría POST y conciliación 11.3

Revisor nuevo e independiente `draft_store_post`: sin hallazgos funcionales, de arquitectura, datos o concurrencia;
gate funcional favorable. Nueve archivos auditados y call paths directamente afectados; el revisor y el auxiliar
de contraste de evidencia actuaron solo en lectura, sin builds/tests ni publicaciones.
Inventario completo706 idéntico antes/después, certificado por el orquestador:
`c6fbbddaf025d4dccb26487df8fbb6b7b365eb1db76a7b2e2ed7caabe66ca77d`.
RED cerrado, GREEN 1.175 declaraciones/1.840 variantes y nuevas26/43 PASS, logs completos y huella fuente551
cotejados independientemente; cero warnings Swift/Clang, aviso AppIntents conocido. UI/accesibilidad/físico N/A.

Único P3 documental: el bloque Pendientes conservaba «TDD en curso». Corregido después del veredicto junto con
Progress, spec, propuesta y las descripciones de PLU-74/71; ambos issues conservan In Progress y entrega Git pendiente.
No se modifica fuente/configuración; no requiere nuevos builds/tests. Comprobación focal read-only favorable:
sin hallazgos, P3 cerrado y gate local PASS. Inventario completo706 idéntico antes/después, certificado por el orquestador:
`b1b548f314a8ee304800d8d1e8a099ef371b605c02a7e87393706ef4db0d2a6c`.
El inventario551 conserva la huella GREEN; seis enlaces históricos08.3 siguen fuera del cambio.
Main/origin permanecen en `5fade88`; rama74 solo local, sin commits nuevos ni archivos staged.
No se realizan commit/push/PR/merge/Done, eliminación de rama, live o inicio11.4 para este incremento.

### Autorización de entrega 11.3 — 2026-10-01

Después del gate local PASS, el usuario autoriza commit, push, PR, merge, cierre de PLU-74 y eliminación de rama.
La fuente551 coincide íntegramente con GREEN y POST:
`90302546c9985a3aa461b7551c485bdae897872c07f26fc3586d558d2d844157`.
Se reutilizan 1.840/1.840 variantes, builds Develop-for-testing/Production y auditorías PRE/estilo/POST favorables.
Desde esa validación solo cambia metadata documental; nuevos builds/tests N/A para estos ajustes.
Main/origin continúan en `5fade88`; nueve archivos exactos, sin cambios ajenos ni archivos staged al preflight.
PLU-71 sigue activa; 11.4 conserva su propio gate. Esta entrega no activa live.

## Entrega11.3 — 2026-10-01

- Autorización completa del usuario: commit, push, PR, merge, cierre de issue y eliminación de rama.
- Commit `16ba2c5dafe2cbae46be0e7c40a6023c9f45044e`,
  `✨ feat(sales): coordinate accepted sale drafts`, publicado en origin.
- [PR35](https://github.com/JFrancoG/FranAlonso/pull/35) MERGED;
  merge `d0a117ee181c0b22c104d4080571a5afc74b6b16`, con dos padres y árbol idéntico al head validado:
  `383d3614bece40c7484fed808f687f68265345fa`.
  Antes de integrar: base `5fade88`, head exacto, CLEAN/MERGEABLE, nueve archivos previstos, sin reviews/checks pendientes.
  GitHub sin workflows/checks, protección de main ni rulesets configurados; no se atribuye CI PASS.
- GREEN 1.840/1.840, 26 declaraciones/43 variantes nuevas, builds Develop-for-testing/Production,
  Source-style Audit y PRE/POST reutilizados por fuente551 idéntica.
  Comprobación independiente focal de entrega por `draft_store_delivery`: sin hallazgos, PASS.
  Inventario completo706 antes/después idéntico, certificado por el orquestador:
  `d6faa5149801fc2beb4aad66bf594fe7ce8e78e1c00b6fa2c435731a2c1cdd75`.
  Cero warnings Swift/Clang; aviso AppIntents conocido. UI/previews/accesibilidad/físico N/A.
- Rama local/remota eliminada después de verificar ancestry contra main/origin, head remoto estable
  y cero commits únicos. Ausencia local/remota comprobada; main actualizado por fast-forward, limpio y sincronizado.
- PLU-74 Done leído de vuelta tras el merge; descripción y comentario conciliados con entrega y límites.
  PLU-71 permanece In Progress, conserva historia11.1–11.2 y registra11.3 entregada;
  siguiente11.4/WorkdayViewModel y SaleDraftViewModel pendiente de autorización.
- Progress, spec11, propuesta y CHANGELOG conciliados con la entrega. Cierre documental publicado después
  en main según el flujo reciente. Solo metadata: nuevos builds/tests N/A, fuente551 conserva SHA
  `90302546c9985a3aa461b7551c485bdae897872c07f26fc3586d558d2d844157`.
  Diff/enlaces nuevos y presupuesto Progress correctos; gobernanza conserva los seis enlaces históricos08.3 rotos.
  Este cierre no activa live ni termina fase11 o la demo completa.


## Inicio11.4 — 2026-10-01

Usuario autoriza issue/rama e implementación local: PLU-75 In Progress, hija de PLU-71, Jesus Franco;
`codex/plu-75-workday-viewmodels` sobre main/origin limpio `b16621d474b340579039fe6bdd213a3c4981ec13`.
Sin duplicado equivalente en Linear. Propuesta y fuentes: [11.4](11-4-workday-viewmodels-proposal.md).
PRE independiente viewmodels_pre sin hallazgos, PASS antes de código ejecutable; whole707 idéntico
`b2b06903659aa155a481b272267d7c0cd64e8bcdab8a1bfd7c55a52c7ba6ab42`, fuente551 igual a GREEN11.3.
Clasificación Domain, fachada del tablero/sesiones y Store único para borrador; operación progressed solo lectura.
Al iniciar, TDD RED/GREEN, builds, estilo y POST estaban pendientes; resultados finales registrados abajo.
Sin UI/previews/accesibilidad/físico aplicables en este gate.
Commit/push/PR/merge/cierre, live y11.5 no autorizados por esta solicitud.

### TDD RED11.4

Scaffolding mínimo compilable y dos criterios contra oráculos independientes. Dos fallos de setup corregidos antes
de ejecutar: módulo testable FranAlonso y try interno en lectura throwing de #require; no cuentan como RED funcional.
Build-for-testing Develop/iPhone17 Simulator27.2 PASS12.636s; logs completos sin warnings Swift/Clang,
con avisos AppIntents metadata conocidos. BuildProject-Log-20261001-183730.txt, ActionArtifacts/default/BuildProject.
RED nativo0/2: policy vacío donde se esperan2 próximas,1 en curso y2 pendientes; fachada noDraft al cambiar cantidad.
Prueba de fachada usa DefaultSaleRepository/SalePersistenceActor/Signal y SwiftData in-memory; oráculos literales
24.20 total,20.00 base,4.20 IVA, lectura posterior desde contexto independiente. No se debilitan asserts.
xcresult cerrado parseado: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_18-37-46-+0200.xcresult`;
`/tmp/plu75-red-native-summary.json`.
Implementación completa, GREEN, estilo, builds finales y POST registrados a continuación.

### Estilo11.4

Auditoría independiente viewmodels_style sobre11 archivos nuevos: whole718 idéntico antes/después,
SHA `c8814797ff5053466722f2fba77de081660ad9f92000dc541ba277a6206fbfe1`. Único P3:14 closures con efectos
compactas en los2 tests de concurrencia. Corrección exclusivamente léxica, sin cambiar oráculos/semántica.
Reauditoría focal PASS sin hallazgos antes de GREEN; whole718 íntegro e idéntico
`ca8a53b7ac5b0116c62f2c134d10cd20f0b133f333b77fc486cd7e13d412cd40`.
Un candidato de init Workday justificado por closure MainActor. La primera compilación completa detectó el import
Foundation necesario para UUID.uuidString; añadido sin cambiar comportamiento, luego build y POST PASS.

### Implementación y GREEN11.4

- Cinco archivos productivos nuevos: policy Domain para clasificación, lectura neutral GetSaleUseCase,
  destino tipado con identidad de sesión y fachadas WorkdayViewModel/SaleDraftViewModel.
  Jornada conserva ventas operativas sin filtro de fecha; closed/voided salen y awaitingDocument pagada permanece.
  Selección, navegación y observación reemplazada/cancelada se cercan; close es terminal.
- La fachada de borrador conserva un solo Store11.3 y proyecta getters observables sin copiar estado.
  Intenciones existentes se delegan; el éxito local durable permanece tras cancelación/cierre.
  Inspección operativa es solo lectura, con recarga explícita y sin writes; una carrera draft/progreso falla cerrada.
  Integración App con las pantallas queda para11.5. Ningún archivo previo de fuente/configuración cambió.
- Seis archivos nuevos de Swift Testing:38 declaraciones/66 variantes. Focal66/66 PASS y regresión completa
  1.213 declaraciones/1.906 variantes, todas Passed. Cero fallos, skipped, notRun, expectedFailures o runtimeWarnings.
  Los dos criterios RED conservan oráculos. SwiftData real confirma persistencia y24.20/20.00/4.20;
  casos deterministas cubren streams/lecturas tardías, sustitución, reintento, cancelación y aceptación durable.
- Xcode MCP, iPhone17 Simulator27.2: Develop-for-testing PASS16.278s y Production PASS17.867s.
  Logs completos y GetBuildLog: cero warnings Swift/Clang; avisos conocidos AppIntents metadata separados
  (dos en Develop-for-testing, uno en Production). La consola focal no contiene errores de persistencia;
  la regresión conserva diagnósticos esperados de los tests previos de save read-only y schema desconocido.
  Xcode restaurado y verificado Develop/planDevelop/iPhone11. Sin validación física en esta subfase.

Artefactos nativos cerrados y parseados completos:

- Develop: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-185911.txt`.
- Production: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-190402.txt`.
- Focal: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_19-04-24-+0200.xcresult`.
- Regresión: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.01_19-05-34-+0200.xcresult`.
- JSON summary/tree: `/tmp/plu75-green-focused-summary.json`, `/tmp/plu75-green-focused-tree.json`,
  `/tmp/plu75-green-all-summary.json`, `/tmp/plu75-green-all-tree.json`; sin nodos inesperados.

Fuente/configuración562 completa idéntica antes/después de GREEN:
`cb84502ae0f20bb078216ecf33b8d93b1598b344848ccc9c7103fec6b2060872`.
Los551 archivos baseline siguen intactos; solo11 adiciones Swift (5 producción/6 tests).

### POST y estado operativo11.4

POST independiente fresco viewmodels_post: PASS, sin hallazgos; revisa código, rutas afectadas, autoridad,
alternativas, Observation, límites de edición/lectura, concurrencia, éxito durable, DocC y evidencia completa.
Fallback operacional read-only probado por comparación del JSON íntegro antes/después:718 archivos,
`6418774b186de9172343151849b654a751a8189cefaa239a194854678818acc2`.
El import Foundation posterior a estilo no altera el resultado favorable.

UI, previews, localización, accesibilidad y dispositivo físico: N/A por ausencia de pantallas o recursos modificados;
no acredita ni resuelve evidencia de otras fases. Diff/secret-sensitive paths revisados, git diff --check PASS.
Gobernanza conserva solo las seis capturas históricas08.3 rotas; enlaces nuevos y presupuesto Progress correctos.
Antes de la entrega, documentación y Linear reconciliados: PLU-75 y fasePLU-71 In Progress. Sin bloqueos
funcionales11.4; entrega Git pendiente de autorización. No commit/push/PR/merge/cierre ni live;11.5 no iniciada.

### Entrega autorizada11.4 — 2026-10-01

El usuario autoriza commit, push, PR, merge y cierre de PLU-75/rama. No autoriza iniciar11.5.
11.4 contiene policy, lectura neutral, destinos y ViewModels; no se ha implementado ninguna pantalla11.5 ni su
composición App. Se reutilizan el estilo y POST independientes, builds y GREEN recién registrados:
fuente/configuración562 íntegra idéntica antes de entrega, hash `cb84502ae0f20bb078216ecf33b8d93b1598b344848ccc9c7103fec6b2060872`.
La preparación de entrega solo añade documentación/changelog; validación Xcode adicional N/A para estos cambios.
Inventario previsto:11 archivos Swift nuevos, cuatro documentos de progreso/spec/propuesta y CHANGELOG.
Auditoría focal independiente viewmodels_delivery PASS, sin hallazgos: confirma alcance11.4 y ausencia de UI/App11.5,
reuso válido de evidencia nativa reciente e inventario exacto. JSON completo718 idéntico antes/después,
`efa9e4dd584675e0ad9592cc265a15a7826d0b7adc23db47f721510f11edbd5a`.

### Cierre de entrega11.4

- Commit `08898f7e5e2e84a3a649d4345ef4344b6d45eb61`, `✨ feat(sales): coordinate workday and sale detail`,
  publicado en origin con los16 archivos previstos. Diff publicado idéntico al revisado:
  16 archivos, SHA256 `d9a997713138ed712b9c5a6e4e9f8879797cf720fe054adafc70f160da1247be`.
- [PR36](https://github.com/JFrancoG/FranAlonso/pull/36) MERGED el2026-10-01, head exacto `08898f7`;
  merge `d9d1ed1b833dc19bbe193224907762bf401dd130`. Main remoto era la base verificada;
  antes del merge se releen criterios/estado/comentarios de PLU-75, sin ampliación o trabajo concurrente.
  Mergeable/CLEAN, sin checks CI configurados; no se atribuye CI verde.
- Árbol de merge idéntico al commit validado. Main actualizado fast-forward; fuente/configuración562 completa
  idéntica a GREEN `cb84502ae0f20bb078216ecf33b8d93b1598b344848ccc9c7103fec6b2060872`.
  Reutilizadas builds/pruebas/PRE/estilo/POST y revisión focal de entrega, sin cambios funcionales posteriores.
- Antes de eliminar rama: merge-base confirma ancestro de main y cero commits únicos.
  `codex/plu-75-workday-viewmodels` eliminada local/remota; consulta refs remotas confirma ausencia.
- PLU-75 Done tras integración GitHub/Linear, descripción reconciliada; PLU-71 conserva In Progress y entrega11.4.
  Progress/spec/propuesta/changelog recogen cierre y evidencia. Registro final solo documental;
  validación Xcode adicional N/A. Gobernanza conserva seis capturas08.3 históricas rotas, sin fallos nuevos.
- 11.5 no está implementada: UI de Jornada/detalle, previews y composición App quedan para ese gate.
  Este cierre no activa live ni termina fase11, la demo completa o validación accesible de otras fases.


## 11.5 — Jornada y detalle operativo local — 2026-10-01

### Inicio, alcance y PRE

Usuario autoriza issue, rama e implementación local. [PLU-76](https://linear.app/plusprojects/issue/PLU-76),
In Progress/Jesus Franco, hija de PLU-71; rama `codex/plu-76-workday-screens` desde main/origin limpio
`edc2f26b5835f7b2af1d3a364d1c78fe9e00d564`. [Propuesta](11-5-workday-screens-proposal.md) y PRE independiente
workday_screens_pre PASS antes de código: JSON completo719 archivos idéntico antes/después,
`bb9b3c0bd2134d9b9f5cc8134cacc21cff76562bcf2d65402bc7ff4c5f9ae491`.
Fuentes primarias Apple, specs/ADR/código y alternativas revisados; perfil mantenimiento Swift6/SwiftUI.

Dos Screens y cinco subviews sustituyen el placeholder Jornada. Tablero con próximas/en curso/pendientes de cierre,
operaciones independientes antiguas, cliente opcional y pagadas awaitingDocument presentes. Sheet tipada con identidad
por sesión y un único Store por detalle. Nueva sesión sin write, Create explícito sin cliente, cantidades acotadas,
retirada confirmada y descarte separado confirmado. Cerrar conserva aceptaciones locales; readonly para estados
progresados. Factories App comparten SalesRepository, actor y signal; cantidades/importes usan snapshots capturados.
Resolución de nombres de cliente separada de la observación de ventas, con fences de generación/IDs/cancelación/cierre.
Nuevo modo Develop workday: seis ventas y dos clientes sintéticos draft, sobre capas reales y memoria aislada;
seed antes de exponer dependencias, gates fail-closed previos a Firebase. Otros modos conservan cero ventas.

No selector11.6, descuentos11.7, inicio/progreso/pago11.8, histórico11.9, stock12, documento13, dependencia,
unsafe, cambio de target/schema ni live. No es una venta completa ni validación física/AT.

### TDD, estilo y validación técnica

- RED compilable real:6 declaraciones/6 fallos, cero passes/skips/expected/runtimeWarnings, iPhone17 Simulator27.2.
  Oráculos de cantidades, carga/nombres, labels y aislamiento del modo workday; no se sustituyen después por asserts de markup.
- 18 declaraciones/28 variantes nuevas frente a baseline11.4. Tests Swift Testing de fachadas/presentación semántica,
  cancelación/reemplazo de lectura y nombres, retries, readonly y aceptación local; composición usa SwiftData real,
  observador real del mismo repositorio y lecturas con contexto distinto. Oráculos monetarios literales independientes.
- Focal nativa69 declaraciones/99 variantes Passed; regresión completa1.231 declaraciones/1.934 variantes Passed.
  Ambas en iPad Pro13-inch(M5) Simulator27.2, cero fallos, skipped, expected failures o runtimeWarnings.
  El resumen MCP de la focal enumeró100; prevalece el conteo nativo cerrado99, sin inferir otra ejecución.
  La regresión completa contiene las28 variantes nuevas. No se confunde lista de declaraciones con runs parametrizados.
- Xcode MCP estable27.0: Develop-for-testing19.346s y Production21.066s PASS.
  Logs completos: cero errores/warnings Swift/Clang, strict complete/default nonisolated y warnings-as-errors.
  Extracción AppIntents conocida separada: dos avisos en Develop-for-testing, uno en Production.
- Localización:56 claves nuevas ES/EN;409 en Localizable y485 entradas traducibles en los tres catálogos,
  `validate_localizations.py` PASS/0 errores. Nombres/precios/impuestos capturados siguen siendo datos.
- Estilo independiente22 Swift:0 candidatos/0 líneas mayores de120. Whole733 idéntico,
  `5e48e1722b7fa6a36d14bbbc86e899d0516d80589f44928c0bc4738a07bb5db7`.
  Preparación async de los previews recibió revisión focal PASS, whole733 idéntico,
  `153224b144eedc9a2876a00026dcd76f67eb76650524888c35d9561f3e1a6faf`.

Artefactos nativos cerrados y parseados:

- RED: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_19-59-15-+0200.xcresult`.
- Focal: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_20-24-20-+0200.xcresult`.
- Regresión: `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_20-30-40-+0200.xcresult`.
  Se usa este bundle nativo completo: la copia MCP inicial no tenía Info.plist y no acreditaba cierre.
- JSON completos: `/tmp/plu76-red-native-summary.json`, `/tmp/plu76-focused-green-summary.json`,
  `/tmp/plu76-focused-green-tree.json`, `/tmp/plu76-all-green-summary.json`, `/tmp/plu76-all-green-tree.json`.
- Develop: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-202804.txt`.
- Production: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-203441.txt`.

Fuente/configuración576 completa idéntica antes/después de la regresión:
`38434c64c42689870d700d1d23e3439c824158f9a43c712e096f4180ba9cff45`.
POST técnico independiente fresco workday_post_technical PASS, sin hallazgos P0–P2. Inspección de fuente, factories,
VM/Store/UseCases/repos/actor/signal, auth, fixtures, tests y logs/JSON completos. Whole734 idéntico antes/después,
`10e684b29fbb6888f58ee0de2106d428161edd4db7dbd900bd326d59074d6e44`.
Previews/AT/smoke y cierre documental mantienen sus límites propios; la revisión no ejecutó ni publicó cambios.

### Previews y accesibilidad progresiva

17 renders Xcode MCP exitosos con snapshots inspeccionados. Dos anteriores sobre iPad Pro13-inch(M5)27.2 y15
sobre iPhone18ProMax27.2, según renderedDestination real. Manifiesto `/tmp/plu76-previews-final.json` conserva
path, definición, locale, variante y destino de cada imagen. Large/XXX Large/AX5 en ambos Screens, más contenidos
preparados antes del render: vacío, varios clientes, draft con nombre de servicio largo, en curso, pendiente de cobro
y pagada pendiente de documento. ES/EN, claro/oscuro y contraste aumentado representativos; no matriz exhaustiva.

WorkdayScreen se captura en carga inicial; el Content preparado acredita filas/grupos y el smoke acredita su operación.
SaleDraftScreen listo conserva fallback de nombre antes de terminar lookup en el snapshot; el Content preparado
resuelve nombres y el runtime confirma Alba/Bruno. Textos largos envuelven sin elipsis observada; contenido inferior
fuera del viewport requiere scroll, no se declara validado por una sola captura. IVA21% e importes24,20/20,00/4,20
visibles; Locale del dispositivo y selección de lengua de preview se registran por separado.

[Matriz11.5](../accessibility/evidence/11-5-workday-screens.md) conserva55 criterios A/AA con aplicabilidad/N/A razonados,
Limitado/Pendiente, controles nativos, headers, nombres/roles/valores, 44pt solicitado y retorno declarativo sin timers.
P2 de retirada sin confirmación en primera revisión UI corregido con confirmationDialog antes de mutar.
[PLU-77](https://linear.app/plusprojects/issue/PLU-77), Backlog, Jesus Franco, relacionada con PLU-76/hijaPLU-71:
retomar tras feedback de Fran y estabilización de cada flujo, antes del primer candidato para uso real y cierre integral.
VoiceOver/foco/anuncios, VoiceControl/SwitchControl/FKA, Inspector, hit areas/contraste medidos, cuatro apariencias,
RTL/orientaciones/ventanas/preferencias y dispositivo físico permanecen pendientes. No se absorbe deuda previa.

### Smoke y corrección focal de hit testing

Interacción Xcode nativa delegada mediante skill Apple device-interaction, sesión Workday Screens Smoke,
iPhone17 Simulator27.2, Develop y único argumento --franalonso-demo-workday, login sintético/no red.
Recorrido anterior al fix: crear/cerrar antes de aceptar no añade venta; Create explícito y Close conservan borrador vacío;
reapertura mediante texto hijo, cancel/confirm descarte; cantidad1→2 y48,40€ persistida al reabrir, retirar cancelado conserva
y confirmar deja cero; tres estados readonly sin edición/descarte/pago; nombres resueltos y tab roundtrip funcionan.

Defecto observado: centro del Button plain de una fila vacía no responde, Text hijo sí; dos intentos con hitPoint.
No se acepta como PASS de área operable. PRE focal independiente workday_ui_post aprueba contentShape interaction
sobre el label después de frame/padding. Alternativa estilo automático amplía cambio visual y se descarta aquí.
Whole734 read-only idéntico al hash técnico anterior. Se añade una línea en WorkdaySaleRow, única diferencia de los576
archivos frente a GREEN: nuevo digest `5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`.
Develop build focal9.899s PASS, cero Swift/Clang warnings; conocido AppIntents metadata1 separado:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-205421.txt`.
Renders focales de Row/Large y board/AX5 oscuro/contraste aumentado PASS, sin cambio visual observado.
No se repite suite completa por una modificación exclusivamente de hit testing: se reutiliza GREEN de negocios/fachadas,
se recompila y se retestea el defecto táctil. Retest final, build Production posterior y POST UI se registran a continuación.

### Estado de cierre local

PLU-76 y fasePLU-71 siguen In Progress. Entrega Git y cierre no autorizados; rama local activa, sin commit/push/PR/merge.
Retest/POST y reconciliación final registrados a continuación; entrega Git permanece pendiente.


### Retest y configuración final11.5

Smoke workday_screens_pre final PASS: tras reinstalar el fix, primer toque en centro de fila vacía, centro Alba,
espacio vacío derecho y centro readonly abre correctamente. No hallazgos funcionales/visuales observados restantes.
Se reutiliza el resto del CRUD previo porque la única corrección afecta hit testing. Informe `/tmp/plu76-smoke-report.md`
con31 juegos verificados de hierarchy/screenshot/log; PID14947 previo y17935 final. Root inspeccionó screenshots
listos21_00_51_068,21_01_37_991,21_02_09_756. Conserva Falla anterior y límites de cancelación fuera del popover/AT.
Base: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/DeviceInteractionSynthesize/`.

Production posterior al fix: Xcode MCP/iPhone17 Simulator27.2,20.419s PASS, cero Swift/Clang warnings/errores,
solo AppIntents metadata conocido1. Log completo:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261001-210341.txt`.
Fuente576 igual al fix antes/después de renders/retest/builds, `5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`.
DeviceInteractionEndSession confirma Session stopped; Xcode restaurado y releído Develop/planDevelop/iPhone11.
Sin pruebas físicas en11.5. POST UI final y reconciliación registrados a continuación.


### POST UI y estado final local11.5

workday_ui_post independiente PASS para gate funcional ADR0029, sin hallazgos abiertos accionables. Inspecciona17
snapshots reales, Screens/subviews/factories/VM delegación,56claves ES/EN,55 criterios y31 juegos smoke; seis jerarquías
y tres screenshots focales del fix. Sin ejecución Xcode ni escrituras. Root certifica JSON completo734 archivos idéntico
antes/después, `e194eb3268e1c9a09ae01cec3993c0b2840f6517ba4fac779dff17ebf4f99642`.
Matriz:37Aplicable (29Limitado/8Pendiente) y18N/A motivados; integral sigue pendiente en PLU-77.

Inventario final:30 archivos afectados:22Swift (17producción/5tests), un catálogo de textos, su inventario,
esquema Develop y cinco documentos. No archivo secret-sensitive ni cambio ajeno; staging vacío. `git diff --check` PASS,
localización485/0errores; gobernanza solo las seis capturas históricas08.3 rotas, sin incidencias nuevas.
Progress dentro de8192bytes. Regresión completa reutilizada para negocio/fachadas; la única diferencia posterior
es contentShape, con PRE/POST UI, build Develop/Production y retest real favorable. Fuente576 final intacta.
Documentación final no modifica fuente/configuración: Xcode adicional N/A razonado para esa reconciliación.

PLU-76 y PLU-71 In Progress, PLU-77 Backlog/Jesus Franco; descripciones reconciliadas con implementación/evidencia
y deuda propia. Sin bloqueos funcionales11.5. Rama `codex/plu-76-workday-screens` activa sobre `edc2f26`,
no commit/push/PR/merge/cierre de issue o rama autorizados en este turno. 11.6 mantiene inicio propio, live inactivo.
Xcode Develop/planDevelop/iPhone11 restaurado y sesión de interacción cerrada. La fase11 permanece abierta.

Cleanup final: StopProject detiene exclusivamente PID17935, la segunda ejecución de esta tarea;
DeviceInteraction ya estaba cerrado. No se dejó el debugger/app iniciados por la validación en ejecución.


### Entrega autorizada11.5 — 2026-10-01

El usuario autoriza commit, push, PR, merge y cierre de PLU-76/rama. Se prepara entrega funcional de demo según
ADR0029; PLU-77 conserva validación integral propia, responsable y recuperación antes del uso real. PLU-71 continúa
activa. No autoriza11.6 ni live. Reutilizadas evidencia TDD/regresión, builds Develop/Production,17previews,
smoke/retest y PRE/estilo/POST técnico/UI recién aprobados: fuente/configuración576 completa idéntica a validación,
`5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`.
Preparación de entrega solo añade autorización/documentación y changelog, sin cambios ejecutables;
Xcode adicional N/A para esta preparación. Inventario previsto31 archivos, de ellos22Swift.
Revisión focal independiente workday_delivery_review PASS, sin P0–P2; PLU-76 sigue In Progress hasta integración.
JSON completo734 idéntico antes/después, `291a6e07b161037e760759b09eed458b36f2a1ff532771ecb21f22914c3179cf`.
Único P3 documental: frase de autorización obsoleta en matriz; corregida para reflejar entrega autorizada/en curso.
Corrección de metadata, sin cambiar evidencia/aplicabilidad/resultado integral; verificación focal posterior PASS.
Whole734 idéntico antes/después del retest documental: `c6e960c82b27240d9b89c5925daa1a9a15ebf774ada9efb1c9ab69888af36a41`.

### Entrega funcional completada11.5 — 2026-10-01

[PR37](https://github.com/JFrancoG/FranAlonso/pull/37) MERGED a las19:47:29UTC. Commit de implementación
`ad53cf2b2a1d185a97712d68f944dfbb25e33991` → merge `c01ff046d40ea896d4921fc7ab3e79376a48f127`.
Patch comprometido idéntico al staging revisado:31 archivos, SHA256
`719f28e8fd3f8117a742cfb807d381b3e55f29191b20bd84061ec535e7ae048f`.
Árbol merge idéntico al feature `edbfacf256fccc3822c6d633c872017f240f2ad9`; fuente/configuración576
íntegra, digest `5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`.
Main actualizado por fast-forward, limpio y sincronizado en el merge; rama `codex/plu-76-workday-screens`
local/remota eliminada tras ancestry y cero commits exclusivos, ausencia verificada.
GitHub sin checks configurados; no se atribuye CI a validación local por Xcode MCP.
PLU-76 Done funcional (integración Linear lo cerró al merge); descripciones y comentario de entrega reconciliados.
PLU-71 sigue In Progress, PLU-77 Backlog/Jesus Franco conserva matriz55 y recuperación antes de uso real.
11.6 mantiene inicio propio; sin cierre integral ni live.

Reconciliación posterior en main: seis documentos/changelog, sin código/configuración ni nueva evidencia de UI.
Xcode adicional N/A: fuente idéntica y validación reciente reutilizada. Progress dentro de8192bytes,
diff whitespace PASS; gobernanza mantiene únicamente seis enlaces históricos de capturas08.3 rotos.
Commit/push documental de cierre autorizado por la entrega completa; main limpio y sincronizado al finalizar.

### Inicio11.6 — 2026-10-01

[PLU-78](https://linear.app/plusprojects/issue/PLU-78), In Progress/Jesus Franco, rama
`codex/plu-78-sale-service-selection` sobre main limpio/sincronizado `0d9b06f6fefcd3ad408bf7c84faebb5c5f3f3f37`.
Usuario autoriza issue/rama e implementación11.6, sin entrega Git/cierre/siguiente subfase/live.
[Propuesta](11-6-service-selection-proposal.md): selector activo10.7→factory pura SaleLine→fachada/Store aceptado,
cantidad inicial1, captura literal de términos/UUID estable al retry; sin copia de catálogo/venta ni Data/schema nuevo.
PRE independiente selection_pre PASS sin hallazgos; JSON completos735 antes/después y root idénticos:
`a8705ba560f51217749d625a6916b7fbe1073eef99247266a109612c3d17756f`.
Baseline11.5 reutilizada solo como punto de partida; validación11.6 pendiente, sin extrapolar resultados.
XcodeMCP estable Service/SDK27, Develop/planDevelop/iPadPro13M5Simulator27.2 confirmados; guardar/restaurar estado real.
[PLU-79](https://linear.app/plusprojects/issue/PLU-79) Backlog/Jesus Franco: deuda integral propia11.6,
recuperar tras feedback/estabilización por flujo antes del primer candidato para uso real.
PLU-77 conserva deuda11.5; PLU-71 activa. Gobernanza conserva seis enlaces históricos de capturas08.3 rotos.


### Implementación y validación técnica11.6

Reutiliza catálogo activo10.7, VM padre y Store único. Coordinador observable MainActor posee sólo intención,
observación y estado de aceptación; no otra venta ni catálogo. Captura síncrona antes de await: ID estable, referencia,
nombre, cantidad1, precio/moneda, IVA, descuento opcional y vínculo de producto. Retry conserva ID/términos, doble
toque no duplica, cierre cerca publicación sin deshacer aceptación durable. App compone capacidades concretas del
mismo repositorio/parent retenido; readonly/noDraft/busy/closed rechazan antes de escritura. Sheet tipada preserva
Store padre; catálogo usa el último estado visible observado, sin CAS entre actores ni stock.

RED nativo compilable:3 declaraciones/6 variantes fallidas por ausencia del comportamiento, sin fallos de setup.
Primer GREEN detecta dos oráculos incorrectos:43.27/(1+7.5%) redondea base40.25/IVA3.02 (Decimal independiente),
y rechazo contractual SaleCalculatorError.incompatibleCurrency, no MoneyError. Correcciones sólo de valores/tipo;
captura previa al await, ID, términos originales y reopen real intactos.
14 declaraciones/25 variantes nuevas Swift Testing, con SwiftData real/otros contextos, App/catálogo compartido,
retry, dobles intenciones, cancelación antes/después de aceptación, identidad visible y cercado de sesión.
Focal GREEN nativa14 declaraciones/15 ejecuciones efectivas PASS (RunSome selecciona sólo7 argumentos dinámicos);
regresión completa ejecuta todas las25 variantes nuevas:1.245 declaraciones/1.959 ejecuciones PASS. No se atribuye25
a la focal. Ambas iPadPro13M5 Simulator27.2; cero fail/skips/expected/runtimeWarnings.

Builds Xcode MCP estable27.0 finales: Develop-for-testing19.103s y Production19.51s PASS; logs completos sin
warnings/errores Swift/Clang. Notices AppIntents extraction conocidos separados:2Develop/1Production.
Localización20 claves nuevasES/EN,429Localizable y505entradas totales, validador0errores. Todos los409textos previos
y su orden/formato intactos; sólo20entradas insertadas, sin reordenación del catálogo.
Estilo independiente16Swift:2P3UI corregidos (array/factory); retest4archivos PASS, whole745JSON idénticos antes/después
`2189ab18f69eaf5fdb9e602ffbea652a789d688e9f226e479cab6923cdcef7fc`.
Fuente/configuración586de GREEN coincide par a par con snapshot previo a estilo/validación final:
`00b10bca668f0aa86c1dbbb45e4caeb8ba94748624aada463c3bc77eaac21253`.

Artefactos nativos y exports:
- RED histórico, cerrado y parseado al ejecutarse: `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.01_22-27-58-+0200.xcresult`.
- Focal GREEN original histórico, cerrado y parseado al ejecutarse: misma carpeta `Test-FranAlonso-Develop-2026.10.01_22-44-50-+0200.xcresult`.
- Regresión original histórica, cerrada y parseada al ejecutarse: misma carpeta `Test-FranAlonso-Develop-2026.10.01_22-45-19-+0200.xcresult`.
  Los tres originales de DerivedData fueron retirados durante la validación. Se conserva el export RED histórico
  `/tmp/plu78-red-native-summary.json` y resumen MCP. Copias MCP GREEN/regresión actuales contienen Info.plist,
  se parsean y sus cuatro JSON summary/tree coinciden íntegramente con exports; paths abajo. Una copia incompleta
  sinInfo.plist no se usa como prueba de cierre ni se reconstruye.
- JSON: `/tmp/plu78-red-native-summary.json`, `/tmp/plu78-green-native-summary.json`, `/tmp/plu78-green-native-tree.json`,
  `/tmp/plu78-regression-native-summary.json`, `/tmp/plu78-regression-native-tree.json`, `/tmp/plu78-new-regression-nodes.json`.
- Logs Develop/Production bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/`:
  `BuildProject-Log-20261001-224437.txt` y `BuildProject-Log-20261001-224626.txt`.

Smokes/previews/POST en curso. Primer smoke confirma cancel/reopen sin cerrar parent, búsqueda/vacío y filtrado/
selección profesional/producto. HitPoint agregado del Picker sin respuesta; trailing value funciona. Propuesta focal
y retest propios antes de cierre. PLU-79 conserva pendientes integrales. Gobernanza sólo6capturas históricas08.3rotas;
sin bloqueo nuevo ni entrega autorizada.


### Corrección focal del filtro11.6

Smoke inicial14comprobaciones/45eventos RunningPID49936, iPhone17Simulator27.2 sobre demo en memoria aislada:
cancel/reopen mantiene Store, búsqueda/noMatch/clear, filtros porvalortrailing, selección profesional35€/producto20€,
repetición en líneas distintas, cantidad2/total125€, close/reopen preserva líneas, cambio de catálogo nombre/precio40€
conserva snapshots35€ y nueva selección40€/total165€, consulta readonly sin Añadir. Artefactos originales intactos
`/tmp/plu78-smoke-report.md` y `/tmp/plu78-smoke-manifest.json`. No prueba AT, dispositivo físico ni durabilidad entre
procesos del demo en memoria; pipeline SwiftData cubre su propio reopen local con contexto distinto.

Defecto P2 real: Pickerstandalone330×31pt informa centro sinrespuesta dos veces; valortrailing abre. No se aplaza.
[Propuesta focal](11-6-service-selection-proposal.md), alternativas y fuentes Apple revisadas independientemente
selection_filter_pre PASS; whole746JSON idénticos antes/después/root:
`f6eee87e30ea9c31d2c8a2d4066173d25afe35cb0a8bb12ad49d681534202103`.
Menu nativo sin primaryAction, label con ViewThatFits horizontal/vertical, frame44/contentShape interaction internos,
chevron decorativo oculto, nombre/valor accesibles; Pickerinline con Binding y mismas3opciones. Sin estado/negocio nuevo.
Estilo focal selection_style PASS, whole746 idéntico:
`3398847253ef2909477b9c99ca1eb7826bd3f2d6285e97233a011cc9246215ce`.
Builds posteriores XcodeMCP: Develop-for-testing23.962s y Production19.288s PASS; full logs
`BuildProject-Log-20261001-230132.txt` y `BuildProject-Log-20261001-230228.txt` en carpetaBuildProject ya registrada.
Cero warnings/errores Swift/Clang; noticesAppIntents separados. Solo cambia Content UI y formato/orden del catálogo
restaurado conservando JSONsemántico respectoGREEN; contratos/lógica/App/tests íntegros iguales, regresión reutilizada.
Cambio de scheme invalidó la primera sesión; StopProject cerró sóloPID49936. Sesión nueva de retest activa;
retetest táctil final, nuevos previews, POST y cleanup/reconciliación todavía pendientes.


### Validación final local11.6 — 2026-10-01

POST técnico independiente selection_post_technical favorable sin P0–P2; únicoP3 corregido: el bundleRED original
fue retirado por retención de Xcode, conservando export histórico cerrado/parseado. Whole746 idéntico antes/después
`85427a6ea3bdc4f3c6e726578f6e17c11de1f8af4be8bd91e3241b349fa1be77`.
No es cierre integral ni autorización de entrega.

Primer retest Menu8checks/18eventos PASS,3filtros/alta/cancel/reopen, iPhone17Simulator27.2;
`/tmp/plu78-filter-retest-report.md` y `/tmp/plu78-filter-retest-manifest.json`. Sesión cerrada y StopProjectPID55774.
Posteriores previews fallaban por AttributeGraph invalidtype(DisplayList/LayoutComputer). Reproducción en varios
procesos/destinos. PRE/read-only de layout explícito DynamicType y separador; ambos intentos negativos, sin causa
atribuida. PRE de ubicación746 íntegro `120e9586dcbcd4e8a4828e8865d415af6c130e9167bd792498aa71fdfa8c9661`:
Menu fuera de filas de List, instrucción/estados/catálogo desplazables, AX vertical/min44/shape/valor/Binding intactos.
Esta composición sí renderiza. Separador experimental retirado. Estilo PASS746
`e52b75ec2bb616d1380a096a63b84ff3047940175092c8b1209889af2f033177`.

Retest final disposición10checks/23capturas PASS, iPhone17Simulator27.2, ES/texto estándar/demo aislada:
centroMenu370×44 abre3veces,3filtros correctos, búsqueda/noMatches/clear, ambas ofertas alcanzables, altaCorte35€/qty1,
dismiss al padre, cancelación conserva línea y reopen operativo. Primera NuevaVenta requiere una recaptura/retry
por transición inicial; sin fallo restante. `/tmp/plu78-final-smoke-report.md`, `/tmp/plu78-final-smoke-manifest.json`:
92rutas verificadas/0ausentes, PID65757Running en todas las capturas. Consola sólo diagnósticos de framework
AX/haptics/pointer clasificados en informe; sin error de aplicación/layout/AttributeGraph observado. No acredita AT.
Teclado hardware con foco; teclado en pantalla no observado. CUA Simulator no accesible, sin cambiar preferencias;
viewport con teclado táctil y tecnologías de asistencia permanecen enPLU-79. DeviceInteractionEndSession y
StopProjectPID65757 confirmados, ninguna ejecución propia activa. Develop/planDevelop/iPadPro13M5 restaurado.

Previews finales18: selector Content y Screen + SaleDraftContent/Screen Large/XXX/AX5 ES/EN Light/Dark;
iPadLarge y iPhone18ProMax27.2, vacío/error catálogo/error alta/noMatch/fila producto. Inspección visual de cada
snapshot; manifiesto `/tmp/plu78-previews-final.json` contiene requests, overrides y destinos/resultados reales.
Los cuatro estados secundarios tenían contexto standalone que omitía Menu en su captura: PRE preview-only PASS
sobre746 `e52b75ec2bb616d1380a096a63b84ff3047940175092c8b1209889af2f033177`; NavigationStack/título como Screen,
fixtures/bindings iguales, re-render PASS con Menu visible. Estilo de esos bloques PASS whole746 íntegro
`c325d8274c81c3c34bdd067933890cf042ce1b8d700b2a79a4b06fb56a7dc49e`.
Screens pueden capturar carga inicial o contenido aceptado; Content fijo aporta estados/entrada independiente del
momento async. CapturaAX5 no demuestra scroll efectivo ni operación por AT/teclado. LayoutJornada/Shell sin cambios,
su muestra11.5 aceptada se reutiliza por impacto de composición, sin atribuirla al selector nuevo.

Builds finales traspreview-only: Develop-for-testing16.807s y Production19.598s PASS por XcodeMCP estable27.0;
logs completos `BuildProject-Log-20261001-234409.txt`/`BuildProject-Log-20261001-234445.txt`, misma carpeta anterior.
Cero warnings/errores Swift/Clang; noticesAppIntents extraction2Develop/1Production separados.
Fuente/configuración586 final: 4e05e357feab9199227697ee9f077a2030c6b8335f190545b72c6fda0575e968.
Comparación par a par con GREEN: sólo ContentUI y formato/orden de Localizable restaurado (semántica igual), todos
contratos/lógica/App/tests/config intactos. Frente al retest funcional sólo4bloques #Preview cambian. Fullregresión
1.245/1.959 y25variantes nuevas reutilizada por impacto; sin nueva regla de negocio que justifique repetirla.

[Matriz55](../accessibility/evidence/11-6-sale-service-selector.md):37aplicables/16N/A/2condicionales,
45Limitado/10Pendiente; fallo táctil inicial preservado en historia, corregido y retesteado funcionalmente, sin Pasa
normativo ni Inspector. PLU-79 Backlog/Jesus Franco conserva evidencia/pendientes, recuperación tras feedback y
estabilización de este flujo antes del primer candidato real. PLU-77/65/67 conservan deuda propia; fase11 activa.
POST técnico focal y UI final en curso sobre fuente congelada. PLU-78 permanece In Progress; rama activa y cambios
sin commit/staging. Usuario sólo autoriza issue/rama/implementación11.6; sin push/PR/merge/cierre/11.7/live.


### Correcciones de POST y retest focal11.6

POST final técnico favorable, únicoP3 documental de ubicación nativa; UI: P2 estático anuncio omitted unavailable y
P3 de traits de encabezado. Whole746 root/técnico/UIbefore/after idéntico
`0f50856a458be0412e903552efa6cf5314431ed6eaecc1c34ea6feee431ab52b`.
PRE focal UI PASS antes de corregir: onChange isSelectionUnavailable anuncia título existente como los otros errores;
títulos de vacío/noMatches/error catálogo declaran .isHeader. Ningún estado/negocio/recurso/foco/timer nuevo.
No prueba entrega por AT. Estilo focal2Swift PASS whole746 íntegro
`7f4142531eb49c63d2cd8c32399a7ad8d3c7d2f89bd63821c6e3fb22ff142c4f`.
Cuatro previews afectados re-render PASS e inspección visual: vacíoLargeES, errorXXXENdark, noMatchXXXES,
ScreenAX5EN; restantes snapshots vigentes por impacto,18 en manifiesto final. Builds finales Develop-for-testing12.679s
`BuildProject-Log-20261001-235540.txt` y Production15.559s `BuildProject-Log-20261001-235619.txt` PASS,
cero warnings/errores Swift/Clang,2/1noticesmetadatos separados. Source586 final: b335eec849cf32f3baf861ca637da6780eaf6fc848cfe75cca850ffbc32f84d9.
Contrato/VM/App/tests/config intactos alGREEN; diferencia final de source sólo ContentUI/Screenanuncio y formato
semánticamente igual de recursos. No justifica repetir suite lógica ni smoke del recorrido intacto para traits/
anuncio cuya entrega sigue pendiente por AT. Datos/regresión anterior y retest10/23 reutilizados por impacto.

Originales DerivedData Logs/Test hoy retirados; copias MCP actuales cerradas y parseadas verificadas por revisor:
- `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.01_22-44-50-+0200.xcresult`
- `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.01_22-45-19-+0200.xcresult`
Ambas conInfo.plist; summaries/árboles FULLJSON iguales a exportsGREEN/regresión retenidos, sin recrearartefactos.
Matriz conserva límites35.7pt de opciones nativas y outer/innerButton de jerarquía; operación/traversalAT/Inspector
pendientes enPLU79, noFallaATinventada. Retest POST focal técnico documental y UI pendientes tras estas correcciones.


### Implementación local11.6 completada — 2026-10-02

Retest focal POST técnico y UI PASS, sin nuevos hallazgos. Ambos agentes read-only; JSON completos746 antes/después
iguales al root, `bf27ceb314e985aaaa3dcd5f620244102c7c0236aab0110a1dfb08770518ee7d`.
P2/P3 UI construidos y P3 documental resueltos; entrega de anuncios/tecnologías de asistencia no se declara probada.
Fuente586 final `b335eec849cf32f3baf861ca637da6780eaf6fc848cfe75cca850ffbc32f84d9` intacta tras los dictámenes.
Sólo reconciliación documental posterior registra esos dictámenes y límites, sin código/configuración nuevo.
Regresión1.245/1.959 con25variantes nuevas, builds finales12.679s/15.559s,18snapshots y smoke10/23 PASS.
Localización505/0, diff whitespace PASS,23paths(16Swift); staging vacío, sin ruta secreta afectada.
Gobernanza mantiene sólo6capturas históricas08.3rotas, sin bloqueo nuevo. Progress dentro de8192bytes.
Sesiones y app propias detenidas; Develop/planDevelop/iPadPro13M5 restaurado.

PLU78 permanece In Progress/Jesus Franco, rama `codex/plu-78-sale-service-selection` local activa sobre0d9b06f;
implementación y gate funcional terminados, entrega Git pendiente. PLU71 In Progress, PLU79 Backlog/Jesus Franco
con matriz55 y recuperación tras feedback/estabilización de este flujo antes del primer candidato real.
PLU77/65/67 conservan su deuda; sin cierre integral,11.7–11.9 ni live. Linear se reconcilia con este estado.


### Preparación de entrega autorizada11.6 — 2026-10-02

Usuario autoriza commit, push, PR, merge y cierre dePLU78/rama. Entrega funcional de demo ADR0029;
PLU79 Backlog/Jesus Franco retiene matriz55 propia, recuperación tras feedback/estabilización por flujo antes del
primer candidato real. PLU71 sigue In Progress. No autoriza11.7–11.9 ni live.
Git y Linear actuales verificados: rama exacta sobre0d9b06f, origin/main sin deriva y sin PR previa de esta rama.
Fuente/configuración586 FULLJSON igual a validación final
`b335eec849cf32f3baf861ca637da6780eaf6fc848cfe75cca850ffbc32f84d9`.
Se reutilizan TDD/regresión1.245/1.959(25variantes nuevas), buildsDevelop/Production,18previews, smoke10/23 y
PRE/estilo/POST técnico/UI finales PASS; preparación sólo documental/changelog, Xcode adicional N/A razonado.
Inventario24paths/16Swift, sin cambios ajenos ni datos sensibles. PLU78 In Progress hasta integración;
revisión independiente focal de entrega antes del commit/PR/merge. Gobernanza sólo6enlaces históricos08.3rotos.

Revisión independiente focal de entrega PASS sin hallazgos; agente fresh/read-only, sin mutaciones.
Root y reviewer FULLJSON746 before/after íntegros iguales
`03cd4722a43626051376e394d9bf9639d7b98163ad512a1020b100bde2ecfb88`.
Informe `/tmp/plu78-delivery-independent-report.md`; proofs propios
`/tmp/plu78-delivery-independent-before.json` y `/tmp/plu78-delivery-independent-after.json`.
Fuente586 igual, bundles actuales/exports y logs finales verificados. Registro posterior sólo documental.

### Entrega funcional 11.6 — 2026-10-02

- Autorización completa del usuario: commit, push, PR, merge, cierre de issue y rama.
- Commit `fcb0a6e7dec24dc8b574b123971865321243862f`,
  `✨ feat(sales): add service selection to sale drafts`, publicado en origin.
  Staging explícito de 24 rutas; índice igual al worktree en cada archivo y sin cambios ajenos.
  Patch revisado, commit y diff publicado de PR idénticos:
  SHA256 `b1966f569909014cdf930b0d243ba5c44646dfdc3c91aa8649a8a275cd224deb`.
- [PR38](https://github.com/JFrancoG/FranAlonso/pull/38) MERGED en main;
  merge `9f38731f766492da0d00699cd3010290e179aebb`, árbol idéntico al commit validado.
  Head/base exactos, 24 archivos previstos y CLEAN/MERGEABLE antes de integrar;
  no checks remotos ni reviews pendientes, main sin protección. No se atribuye CI PASS.
  Linear y criterios releídos inmediatamente antes del merge, sin ampliaciones concurrentes.
- Rama `codex/plu-78-sale-service-selection` local/remota eliminada después de probar ancestry,
  cero commits únicos y worktree limpio; ausencia local/remota verificada tras fetch/prune.
  Main actualizado por fast-forward y local/origin/main iguales en el merge.
- Fuente/configuración586 FULLJSON idénticos después de integrar:
  `b335eec849cf32f3baf861ca637da6780eaf6fc848cfe75cca850ffbc32f84d9`.
  Se reutilizan RED/GREEN, regresión1245/1959, builds finales, 18 previews, smoke10/23 y auditorías PASS.
  Los 2/1 avisos conocidos de metadatos AppIntents se conservan separados de Swift/Clang.
- PLU-78 Done funcional por integración Linear/GitHub, leído de vuelta; descripción reconciliada.
  PLU-71 permanece In Progress, con 11.6 entregada y siguiente gate11.7/descuentos sin iniciar.
  PLU-79 sigue Backlog/Jesus Franco: matriz55, 45Limitado/10Pendiente, tras feedback y estabilización
  por flujo antes del primer candidato real. Teclado en pantalla, AT, Inspector y evidencia física pendientes.
  PLU-77/65/67 conservan su propia deuda; sin cierre integral, siguiente subfase ni live.

Reconciliación posterior en main: seis documentos/changelog, sin código/configuración ni resultados accesibles nuevos.
Xcode adicional N/A: fuente idéntica y validación reciente reutilizada. Progress dentro de8192bytes,
diff whitespace PASS; gobernanza mantiene únicamente seis enlaces históricos de capturas08.3 rotos.
Commit/push documental de cierre autorizado por la entrega completa; verificación final de main tras publicarlo.

### Inicio 11.7 — 2026-10-02

Usuario autoriza issue/rama e implementación local11.7. [PLU-80](https://linear.app/plusprojects/issue/PLU-80),
In Progress/Jesus Franco, hijaPLU71; `codex/plu-80-sale-discounts` desde main limpio/sincronizado`ea78dc6`.
[Propuesta](11-7-sale-discounts-proposal.md): política global no definida por04/11; consulta al propietario pendiente.
Exploración independiente confirma riesgos de DTOv2/schema4 y replay antiguos si se elige global persistente.
PRE parcial independiente PASS para mostrar/editar descuento DE LÍNEA sobre Store/fachada actuales sin Domain/Data/schema.
WholeJSON747 before/after/root idénticos`5fb9e30eb37fd46db73926606f252eb895bf873b937ccc2702c51feed2556473`;
contrato congelado de comando/retry/cierre y parsing neutral reutilizado. TDD/validación/POST aún pendientes.
11.7 no completada; política global y su PRE propio pendientes. Sin entrega Git, siguiente subfase, cierre ni live.

### TDD parcial11.7 — editor de línea

XcodeMCP Develop/iPadPro13M5: build-for-testingRED28.11s PASS;18declaraciones/40variantes RED funcional
(39Failed/1Passed;17/18declaraciones fallan) por requestID/estado/aceptación ausentes, no por setup.
Bundle nativo cerrado conInfo.plist y summary/tree exportados a `/tmp/plu80-red-native-{summary,tests}.json`:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.02_01-34-44-+0200.xcresult`.
GREEN inicial build25.16s; focal27declaraciones incluidos9ServiceFormDraft,33ejecuciones registradas PASS.
La exportación focal conserva sólo una parte de argumentos paramétricos: no acredita todas las variantes nuevas;
la regresión completa final deberá comprobarlas. Bundlecerrado/exports `/tmp/plu80-green-native-{summary,tests}.json`:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.02_01-40-20-+0200.xcresult`.
Ambos builds ceroSwift/Clangwarnings/errores;2avisos conocidosAppIntents en cada uno separados.
Parser extraído con cuerpo idéntico salvo nombre y aliasServices; testsRED intactos.
Estilo independiente, validación final/previews/smoke y POST pendientes; global/completitud11.7 pendientes.

Estilo independiente17Swift: hallazgo único de llamada119columnas corregido; retestPASS con0candidatos,
restantes14Swiftidénticos. Se corrigieron sólo fixtures de2Views para capturarLocale delCanvas también enEN.
WholeJSON757 before/after/root iguales`60d1823ea49318f938095aed96a3742d469f9afecd846f885f26790303f564ba`;
informe `/tmp/plu80-line-style-retest-report.md`. Cambios posteriores aGREEN: formato y fixtures/previews,
sin comportamiento de aceptación. Regresión/builds finales pendientes.


### Validación técnica final parcial11.7 — 2026-10-02

Fuente/configuración595 FULLJSON antes/después de validación iguales
`885dd7f229d74449846b1a0b56767f90228c385096046f80090972cc2dd6427d`;
`/tmp/plu80-before-final-validation-source.json` y `/tmp/plu80-after-final-validation-source.json`.
Build-for-testingDevelop13.602s y Production20.727s PASS, ceroSwift/Clangwarnings/errores;
2/1avisos conocidosAppIntents separados. Logs completos:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-015211.txt`
y `BuildProject-Log-20261002-015944.txt` en el mismo directorio.
RunAll cerrado1263declaraciones/1999ejecuciones PASS, incluidas18declaraciones/40variantes nuevas;
0failed/skip/expectedFailure/runtimeWarnings/testFailures nativos. Export íntegro
`/tmp/plu80-regression-native-{summary,tests}.json`, nodos nuevos `/tmp/plu80-new-regression-nodes.json`;
bundle conInfo.plist cerrado:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.02_01-52-19-+0200.xcresult`.
Esto resuelve la limitación de argumentos del focal anterior. Console conserva avisos internosCrashlytics
sobreXCTestCore y errores esperados de pruebas negativas de persistencia/migración; no se declara consola vacía.

13previews de editor/error/borrador, inspeccionadas porroot con0errores y destino real
 iPadPro13M5Simulator27.2, SDK27.0. Manifiesto `/tmp/plu80-preview-manifest.json`:
discovery1; editorESLightLarge/XXX/AX5, editorENDarkLarge/XXX/AX5, errorESLightLarge/XXX/AX5,
borradorESLightLarge/XXX/AX5. Nombre largo, label, instrucciones y acciones con wrapping.
El overrideEN cambia idioma, no prueba región/separador inglés; gramáticas locales cubiertas por tests.
En capturaESAX5 el toolbarCerrar no aparece; enENAX5sí. No concluir ausencia/alcanzabilidad runtime.
BorradorAX5 requiere desplazamiento vertical; no se acredita su recorrido exhaustivo por captura.

POST técnico independiente parcial PASS, sin hallazgos. FULLJSON757 before/after/root íntegramente iguales
`508faf3ac922ccce5fa3b8cb2e383fca6a705cb415ee4b804cadfd19e91cc25e`;
informe `/tmp/plu80-post-tech-report.md`, proofs `/tmp/plu80-post-tech-{before,after}.json`
y `/tmp/plu80-post-tech-root-after.json`. Scope17Swift y16strings; sin modificaciónDomain/Data/schema/global.
Smoke y POSTUI permanecen en curso; no se declara gate funcional ni11.7completada.
[PLU-81](https://linear.app/plusprojects/issue/PLU-81), Backlog/Jesus Franco, deuda propia accesible11.7,
recuperar tras feedback/estabilización del recorrido antes del primer candidato real; matriz55 propia.
Localización521/0errores y diff whitespacePASS. Gobernanza sólo6capturas históricas08.3rotas, exit1;
no resultado globalPASS ni reparación fuera de alcance. Sin commit/push/PR/merge/cierre/live.

### HallazgoUI y PRE focal11.7 — 2026-10-02

Smoke inicial9/9checks de negocio/26capturas conserva P2 de primera apertura:08editor→09padre sin gesto→10retry.
POSTUI independiente: correct before proceeding, no gate funcionalPASS. Log07→08 registra intento de presentar
PlatformAlertController mientras ya existe PresentationHostingController; logs08=09, causa de dispatch no demostrada.
Defecto funcional enPLU-80; no transferirlo como deuda integralPLU-81. Informe `/tmp/plu80-post-ui-report.md`;
smoke `/tmp/plu80-smoke-report.md` y manifest,104artefactos copiados/SHAverificados. RuntimeRunningPID4710,
StopProject confirmado; EndSession informa sesión inexistente,Develop/planDevelop/iPadPro13M5 restaurados.

PRE técnico focal independiente PASS para SOLOdos `.buttonStyle(.borderless)` en Editar descuento/Retirar servicio
 de SaleDraftLineRow: preservar Stepper NATIVO,closures,rol/labels/foco/44pt y capas. Alternativasplain/menu/fila aparte
más amplias descartadas; APIAppleprimaryCupertinoiOS13+,target27. Automatic contextual es hipótesis,runtimeGREEN
 debe probar independencia real. Sources/provenance en `/tmp/plu80-line-button-pre-report.md`.
RootFULLJSON757 UI/PREbefore/after íntegramente iguales
`2dae23d8b01d2b9a68ffd769a1be3f7a88833c0f089053854c725d27313a87c6`.
TDDautomático adicionalN/Arazonado: sólo modificadores de estilo/routingUI, sin contratoVMnuevo; no tests miméticos
 de presencia del modifier ni harnessUIprohibido. REDmanual conservado; requierecoldGREEN abrir/permanecer/cerrar,
Aplicar/reabrir/Retirar descuento y Retirar servicio→confirmación propia→cancelar conservando venta; inspeccionar logs,
builds/previewsparentLarge/XXX/AX5 y POSTUIfocal. Hasta entonces P2 sigueabierto/globalpendiente.

Corrección aplicada después delPRE: exactamente2modifiers; delta source595 únicamenteSaleDraftLineRow,
otros594files y16Swift afectados antes idénticos. Nuevo sourceFULLJSON595
`7b114f62fb147ebb6d694dda456fab4d7699836a804ebaeef37e04144c9fd432`,
`/tmp/plu80-{before,after}-button-fix-source.json`. POST técnico/estilo focalPASS, sin hallazgos;
proof757root/reviewerbefore/after íntegros iguales
`1e6c82731c846aa5422b4d973374b3cb93ab2b5396f6cb6a3d140f4cbe4d2fec`;
informe `/tmp/plu80-button-fix-post-tech-report.md`.

Builds corregidos XcodeMCPDevelop18.155s/Production18.752s PASS, ceroSwift/Clangwarnings/errores;
2/1metadatanoticesAppIntents separados. Logs BuildProject-Log-20261002-022841.txt /-023111.txt
 bajo ActionArtifacts/default/BuildProject. GetBuildLogwarnings0issues/truncatedfalse;
logcompleto conserva únicoavisoAppIntents, no ceroavisos de todaslasherramientas.
RunAll corregido cerrado1263declaraciones/1999ejecuciones PASS; mismas18declaraciones/40variantes nuevas
queRED, todasPassed,0fail/skip/expectedFailure/runtimeWarningsnativos. Exports
`/tmp/plu80-corrected-regression-native-{summary,tests}.json` y18nodos `/tmp/plu80-corrected-new-regression-nodes.json`;
Info.plist cerrado de bundle
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.02_02-29-22-+0200.xcresult`.
Retest3previews padreESLightLarge/XXX/AX5,0errores, render/inspecciónroot de wrappers/acciones;
`/tmp/plu80-corrected-preview-manifest.json`; demás previews iniciales reutilizadas por source/tipo sin cambios.
Coldsmoke y POSTUIfocal pendientes; P2 aún no declarado corregido. Política global pendiente de respuesta.


GREENmanual corregido:9/9checks,22capturas/88artefactos nativos copiados/SHAverificados,
phone17Simulator27.2/Develop/demoESportrait402×874pt/textoestándar,02/10/2026.
Primera apertura al primer toque permanece en dosrecapturas sin gesto; Cerrar conserva nil/24,20€.
Retirarservicio muestra sólo su confirmación; cancelar conserva fila. Stepper1→2→1 da48,40→24,20sinotrosdestinos.
12,5 aplica/reabre21,17€ (descuento3,03€,base17,50€,IVA3,67€); retirarDESCUENTOvuelve nil/24,20sinretirarservicio.
Source de cálculo intacta:3,025redondeado3,03antesderestar; oráculo21,18inicial incorrecto, no ajustarpolítica.
0matchesPlatformAlert/alreadyPresentingen22logs, ruido de frameworks/haptics persistente; no ceroavisosglobales.
No demuestra ejecución de dosclosuresni causa original; prueba independencia observable del binario corregido.
PopoverDismissRegionhitPointno cerró confirmación; una recaptura/fallbackexterior la canceló, sin confirmar borrado.
No nuevaspruebas101/0/readonly: iniciales aceptadas y source afectada enreadonly no renderiza esosButtons.
Informe `/tmp/plu80-corrected-smoke-report.md`, manifest `/tmp/plu80-corrected-smoke-manifest.json`.
Runtime22Running/PID13389; StopProject propio confirmado,EndSession informa inexistente, destinoDevelop/iPadPro13M5
restaurado; sin edición persistente de argumentos/scheme, clave temporal eliminada. AT/durabilidaddisco no probados.
Source595wholeJSONantes/despuésvalidacióncorregida íntegros iguales7b114f62…;
`/tmp/plu80-corrected-validation-source-after.json`. POSTUIfocal pendiente para disponerP2; globalpendiente.

### POST UI focal y estado parcial 11.7 — 2026-10-02

Revisión independiente `ios-accessibility-reviewer`: PASS exclusivamente para el gate funcional parcial
del editor de descuento de línea, según ADR0029. El P2 de primera apertura queda resuelto por el GREEN
observado; sin nuevos hallazgos P0–P3. Se preserva el RED histórico y no se afirma una causa demostrada
ni estabilidad universal. Informe `/tmp/plu80-ui-retest-report.md`.

El revisor inspeccionó las dos modificaciones borderless, tres previews parentales, jerarquías/logs y capturas
focales. Revisor y raíz verificaron los 88 artefactos, 88 rutas únicas y cero discrepancias SHA256.
Los cuatro FULLJSON antes/después de raíz y revisor son íntegramente iguales: 757 archivos,
`c3cb973314395f62be1a7bb67fd1dc1f271881386863be059bec3728b9e94bcc`;
`/tmp/plu80-ui-retest-{root-before,before,after,root-after}.json`.

Fuente/config595 final conserva FULLJSON idéntico al binario validado
`7b114f62fb147ebb6d694dda456fab4d7699836a804ebaeef37e04144c9fd432`;
`/tmp/plu80-local-final-source.json`. Xcode conserva scheme/plan FranAlonso-Develop; destino iPad restaurado
y sesiones de interacción propias detenidas. Build, tests y renders adicionales tras reconciliar sólo docs: N/A,
sin cambio de fuente/configuración. RunAll corregido conserva cinco repeticiones del mismo aviso interno
Crashlytics/XCTTerminateHandler y sondas negativas SwiftData; runtimeWarnings nativos vacíos.

PLU-80 permanece In Progress/Jesus Franco, rama `codex/plu-80-sale-discounts`: editor de línea implementado
y validado, descuento global pendiente de decisión del propietario y PRE correspondiente. No cierre completo
11.7, entrega Git, 11.8 ni live. PLU-81 Backlog/Jesus Franco conserva los 55 criterios propios, 45 Limitado y
10 Pendiente, tras feedback/estabilización de este recorrido y antes del primer candidato para uso real.
El defecto funcional resuelto pertenece a PLU-80; no se transfiere a la deuda integral.

Reconciliación final local/Linear verificada: PLU-80 y PLU-71 In Progress, PLU-81 Backlog, todos con Jesus Franco;
evidencia final añadida sin sustituir descripciones previas. Localización 521/0 y diffcheck PASS.
Governance devuelve exit1 exclusivamente por seis enlaces históricos a capturas Desktop en08.3, ya presentes
en la baseline; no se declara PASS global ni se corrigen archivos ajenos. Progress8191bytes, dentro del límite8192.
24 rutas locales, ninguna staged; HEAD permanece `ea78dc69865af9a51750c3c6db6464eb15011a07`.
Fuente/config595 FULLJSON después de reconciliar docs idéntico7b114f62…;
`/tmp/plu80-local-final-source-after-docs.json`. No cambios ejecutables posteriores a la validación.

### Continuación global provisional 11.7 — 2026-10-02

El propietario pide la solución menor para la demo: global independiente y acumulable con promociones de catálogo,
para preguntar a Fran y ratificar la política a la vuelta. Nueva propuesta `11-7-global-discount-proposal.md` y
ADR0032: término/política V1 guardados, cálculo sucesivo por etapa/línea y codec comercial2 en linesData existente.
Schema3/31tablas sin cambios; DTO1/2 con replay exacto por versión y tombstone1, sin downgrade/live.
No sustituir la promoción de línea ni recalcular históricos con una política futura.

PRE técnico nuevo read-only PASS, sin hallazgos P0–P3 ni excepciones arquitectónicas/unsafe/dependencias/live.
Informe `/tmp/plu80-global-pre-report.md`; cuatro FULLJSON759 root/reviewer before/after idénticos,
`2bff3d3833898cfd2c6d4f9b2c5599f6a2ac703897d614f5a8076ec55c230054`.
Fuente595 de línea antes de este tramo aún7b114f62… idéntica, configuración y workspace estable comprobados.
ADR0032 aceptado para implementación técnica local dentro del alcance humano; política comercial definitiva pendiente.
PhaseA de tests/stubs comienza después del PRE. RED/GREEN y validación global siguen sin ejecutar.


### GREEN global y validación técnica — 2026-10-02

TDD: PhaseA compilable BuildForTesting 13,713s PASS. RED focal 47 declaraciones / 99 ejecuciones,
32 declaraciones Failed (56 variantes) y 15 Passed (43), sin skips ni preparación fallida.
Bundle cerrado `RunSomeTests/Test-FranAlonso-Develop-2026.10.02_08-31-26-+0200.xcresult`.
Exports nativos `/tmp/plu80-global-red-native-summary.json` y `-tests.json`. Los fallos prueban ausencia de
cálculo/global, destino y codecs2; después se implementó el GREEN aprobado.

El editor único SaleDiscountViewModel/Screen/Content sirve línea y global. Un destino identificado excluye
editores concurrentes y selección; el comando congelado Discount? conserva task identity y retry.
La sección global muestra porcentaje/ausencia y alcance; desgloses separados más agregado. La inspección calcula
la venta completa sin dar capacidad de edición. Store conserva la aceptación existente y valida antes de escribir.
Domain fija lineThenGlobalV1 y aplica promoción → global → IVA por línea, reutilizando el certificado ADR0031.
SaleDTO y payload local1/2 estrictos; Firestore reenvía la versión capturada, tombstones1. Sin @Model/schema/migración
nueva ni wrappers causales nuevos. Lectura v1 no reescribe; aceptar una edición escribe2. Sin soporte downgrade ni
promesa de coexistencia con writers binarios viejos. La ratificación comercial por Fran sigue pendiente.

Estilo independiente: 4 P3 en tests corregidos sin modificar oráculos. Retest PASS sobre las 7 construcciones
corregidas de 5 archivos; cuatro FULL JSON de 770 archivos idénticos, digest b6b35794c1fc…8352632.
Informes `/tmp/plu80-global-style-report.md` y `-style-retest-report.md`; el primer proof fue4d118c5e…c9de8.
La regresión detectó un fixture histórico que inyectaba versión local2 como inválida; ahora2 es válida.
Corrección mínima: poison3 y precondición explícita unsupportedLinesVersion(3), conservando las assertions de
rollback, fila y cola. No cambió código funcional ni se ocultó un fallo de integridad.

Tres intentos RunSomeTests GREEN retornaron resultados parciales sin cerrar Info.plist (incluido un aislado puro
Calculator); no se cuentan como evidencia final ni se atribuye la causa a un deadlock. RunAllTests confirmó el
recorrido completo: primer run 1.309/1.310 declaraciones y 2.095/2.098 variantes, sólo el fixture anterior falló.
RunAll final cerrado, Info.plist verificado: 1.310/1.310 declaraciones, 2.098/2.098 ejecuciones, sin fallos, skips,
expectedFailures ni runtimeWarnings nativos. Incluye las 47 declaraciones / 99 ejecuciones nuevas Passed y sus
argumentos, así como las regresiones de schema1/2/3, línea y rollback. Develop / iPad Pro13M5 Simulator27.2, SDK27.0.
Bundle `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.02_08-55-48-+0200.xcresult`.
Exports `/tmp/plu80-global-final-native-summary.json`, `-native-tests.json`, `-final-new-nodes.json`.

Builds finales Develop-for-testing 3,341s y Production21,110s PASS. Logs completos
`BuildProject-Log-20261002-085643.txt` / `BuildProject-Log-20261002-085757.txt`: sin errores ni warnings Swift/Clang;
avisos AppIntents de extracción omitida separados. Consola conserva sondas negativas SwiftData/migración esperadas
y ruido interno de frameworks; no se afirma ausencia de todos los avisos del entorno.
Fuente/config606 archivada `/tmp/plu80-global-final-source-proof.json`; las previews sólo requieren producción,
sin cambio de fuente después de los renders. Localización528 textos /0errores,23 claves nuevas frente aHEAD:
16 de línea y7 de global; sólo el label agregado anterior cambia a Descuento total/Total discounts.

20 renders globales /0errores e inspección root de cada PNG, manifiesto `/tmp/plu80-global-preview-manifest.json`
con SHA256. Editor ESLight /ENDark Large/XXX/AX5; error global ES en los tres tamaños; borrador y readonly;
sección global propia y desgloses AX5. Dos Screen de borrador sólo capturaron Loading: no prueban contenido;
se renderizó el Content cargado determinista XXX/AX5 para cubrir ese impacto. En AX5ES el toolbar Cerrar no
aparece en la captura global; permanece a verificar runtime/AT en PLU-81. Contenido global/total bajo fold requiere
scroll; overrideEN no acredita región. Sin ratios/Inspector ni matriz AT/física integral.

Smoke global nuevo en curso, con sesión iPhone17 Simulator27.2 Develop / demo sintética ES aislada. POST global
independiente técnico/UI pendiente. PLU-80/71 In Progress; PLU-81 Backlog propio,45 Limitado/10 Pendiente,
recuperación tras feedback/estabilización antes del primer candidato real. Governance exit1 sólo por seis enlaces
Desktop históricos08.3; diffcheck y localizaciones PASS. Sin commit/push/PR/merge/cierre/11.8 ni live.

### Smoke global y POST técnico final — 2026-10-02

Smoke focal:9 comprobaciones PASS, sin fallo funcional observado. Apertura global20 y dos recapturas idénticas;
Cerrar conserva; aplicar25 mantiene línea10 (total16,33€); retirar global conserva promoción (21,78€);
retirar línea recupera24,20€;101 rechazado/corregido20; añadir Champú sin promoción conserva global20
(subtotal44,20€, total35,36€). Inspección en curso conserva línea10/global20, total17,42€, sin acciones de edición.
Falta caso UI de nueva línea con promoción de catálogo: fixture ofrece sólo discount:nil. Domain/Store lo cubren,
sin sustituir esa ejecución runtime. Tamaño estándar ES Simulator, sin AT/física ni acreditación AX5.

Informe `/tmp/plu80-global-smoke-report.md`; manifest `/tmp/plu80-global-smoke-manifest.json`:
36capturas/144copias exactas, original/copia SHA256 y tamaños iguales verificados independientemente por root.
`/tmp/plu80-global-smoke-root-verification.json`. Root inspeccionó los PNG10/16/19/22/27/32/36.
Proceso93907 Running durante toda la interacción, sin fallback de coordenadas ni activación de otra app.
StopProject detuvo93907; EndSession posterior devuelve Session doesn't exist anymore. Archivo de credencial temporal
propio eliminado y Develop/iPadPro13M5 restaurado. Los paths públicos de evidencia redactan la clave de sesión.
Logs conservan ruido UIKit/teclado/haptics/AXSimulator sin crash, constraints ni diagnóstico de fuente FranAlonso;
no se afirma ausencia de todos los avisos de frameworks.

POST técnico independiente fresco PASS, sin hallazgos P0–P3. Informe `/tmp/plu80-global-post-report.md`.
Cuatro FULLJSON770 root/reviewer before/after iguales:
`2b0601d40381ab967e05fbd0fa24f8e0335d579b86ed316cb43d3e53c2de80d0`.
Fuente/config606 iguales al proof del RunAll final, digest
`7ba47495872f25bfb0603f158476d668658ec7e08310ec87287447dff53235df`;
reexport nativo independiente de summary/tests idéntico al de root. Auditoría incluye corrección del poison3,
fixtures históricos1 literales, codecs1/2, política guardada, contratos causales y límites de downgrade.

Dos recapturas DraftScreen cargadas en XXX/AX5,0errores, inspección root:22renders totales. Las dos Loading
anteriores no se borran ni se cuentan como contenido. Nombre largo completo y promoción visibles; global/importes
bajo fold en AX5 y toolbar ausente de esa captura permanecen limitados. POST UI global aún pendiente;
no cambia gate integral, estados Linear, ratificación comercial ni autorización de entrega.

### POST UI y reconciliación local final — 2026-10-02

POST UI fresco independiente inspeccionó22/22previews y144/144copias del smoke. Informe
`/tmp/plu80-global-ui-post-report.md`: único P3 en copy de indisponibilidad compartido, global pedía revisar «la línea».
Cuatro FULLJSON770 root/reviewer before/after iguales, digest
`4ba21c40471f3c92705c7a449026b3cdf64bb160847dec3849ed38512c17dd2c`.
Corrección mínima de2valores ES/EN en sales.discount.unavailable.message, sin Swift/tests/config/keys/oráculos:
«Cierra este editor y revisa el borrador de venta.» / «Close this editor and review the sale draft.».

Catálogo528/0 y diffcheck PASS; builds por impacto Develop-for-testing21,841s y Production18,958s PASS.
Logs completos `BuildProject-Log-20261002-093451.txt` (14.335líneas) y `-093522.txt` (16.592líneas),
0errores/warnings Swift/Clang;2/1avisos AppIntents de metadata omitida separados. Fuente/config606 actual
`/tmp/plu80-global-after-copy-source-proof.json`, digest
`d788ebbd0aaa49ece0630a5cdef47b09b882190282f33674c9f9e6114fa330d4`:
sólo Localizable.xcstrings difiere frente al RunAll, otras605rutas/hashes idénticos. Se reutilizan1310/2098tests,
22previews y9checks por impacto; no se repiten pruebas de comportamiento por un copy neutral más corto.

Retest independiente focal `/tmp/plu80-global-ui-copy-retest-report.md`: P3resuelto, sin nuevosP0–P3;
PASS final UI para gate funcional demo ADR0029. Cuatro FULLJSON770 completos idénticos,
`8af22ceae27c644c0b6c58d4c3cfc734151c8b820cea9883dd0d5cfbb657a1c4`.
El mensaje se acredita estáticamente, no con lector. AX5ES Cerrar/toolbar, scroll/teclado/AT, Inspector/ratios,
dispositivo físico y matriz exhaustiva siguen limitados o pendientes; caso UI de añadir promoción sin fixture
sigue sin ejecutar. Matriz55 mantiene45Limitado/10Pendiente, PLU-81Backlog/JesusFranco y recuperación tras
feedback/estabilización antes del primer candidato real; PLU-77/79 independientes.

Implementación local11.7 validada funcionalmente para demo: PRE/estilo/POST técnico/UI PASS, TDD y regresión
nativa cerrada, builds/previews/smoke favorables. Política V1 provisional y ratificación comercial por Fran pendiente.
PLU-80/71 siguen InProgress y PLU-81Backlog; esta reconciliación sólo documenta evidencia, no cierra trabajo
operativo ni autoriza entregaGit,11.8 o live. Los cambios documentales posteriores no requieren otro build (N/A:
no fuente/config); mantener equivalencia FULLJSON606 con el proof de copy validado y comprobar estado final.

Reconciliación verificada: notas finales de PLU-80/81/71 persistidas y releídas, estados InProgress/Backlog/InProgress
y propietarioJesusFranco conservados. Progress8.173bytes ≤8.192,69rutas locales/0staged, rama
codex/plu-80-sale-discounts y HEADea78dc69865af9a51750c3c6db6464eb15011a07 intactos. Fuente/config606
FULLJSON posterior a docs idéntico al proof de copy validado:
`/tmp/plu80-global-local-final-source-after-docs.json`, digestd788ebbd…330d4. Localización528/0 y diffcheckPASS;
governance exit1 sólo por6linksDesktop08.3 históricos. XcodeDevelop/iPadPro13M5 restaurado; credencial temporal
propia eliminada. No cambios ejecutables tras builds/retest ni entregaGit/cierre operativo/11.8/live.

### Preparación de entrega autorizada11.7 — 2026-10-02

El propietario autoriza expresamente commit, push, PR, merge, cierre de PLU-80 y eliminación de rama.
Preflight Git: HEAD/main/origin-main ea78dc6,69rutas del alcance aprobado,0staged, sin cambios ajenos.
FULLJSON770 de todo el repo idéntico al estado local final revisado; fuente/config606 idéntica al proof validado
d788ebbd…330d4. Se reutilizan TDD, RunAll1310/2098, builds,22previews, smoke y PRE/estilo/POST técnico/UI
independientes recientes: no se ha modificado ningún Swift, test ni configuración. Sólo changelog/autorización
y evidencia documental de entrega; nuevos builds/tests N/A razonado por ausencia de impacto ejecutable.
PLU-80 permanece InProgress hasta verificar merge; fasePLU-71 abierta y PLU-81Backlog/JesusFranco con55criterios
45Limitado/10Pendiente, trasfeedback/estabilización antesprimerusoreal. Ratificación Fran sigue pendiente.
Siguiente subfase normativa11.8: RegisterSalePaymentUseCase, efectivo/tarjeta, PaymentID estable y recuperación;
el pago no retira de Jornada una venta pendiente de documento. No se inicia11.8 ni se activa live con esta entrega.

### Entrega11.7 verificada — 2026-10-02

Commit `08e7550f9bf032948d6f74e4ab422e102349ff60`, ✨ feat(sales): add global and line sale discounts,
70rutas del alcance aprobado, push a origin/codex/plu-80-sale-discounts. Todos los606blobs fuente/config del índice
coincidían con el proof validado d788ebbd…330d4, sin config/secretos/cambios ajenos incluidos.
[PR39](https://github.com/JFrancoG/FranAlonso/pull/39) creada, adjuntada a Codex y revisada: diff remoto idéntico
al local, MERGEABLE/CLEAN, sin checks remotos ni review requerida publicados. No se atribuye PASS de CI inexistente.
Merge autorizado normal `073a1808d36fd8130b1f9c6e409e9396fafcf71b`; PR MERGED y árbol completo idéntico al
commit validado. main actualizado ff-only; antes de borrar rama se comprobaron tip remoto/local08e7550,
ancestría en origin/main y ausencia de commits únicos. Rama local/remota codex/plu-80-sale-discounts eliminada.

LinearPLU-80Done tras el merge, descripción y evidencia de entrega reconciliadas. PLU-71InProgress y
PLU-81Backlog/JesusFranco conservan deuda integral propia55criterios45Limitado10Pendiente, recuperada trasfeedback
y estabilización antes del primer candidato real.11.7cerrada funcionalmente para demo ADR0029; Fran ratificará
la regla provisional después.11.8/pago es el siguiente gate y no está iniciado;12/stock y13/documento/cierre
conservan sus dependencias. Seis links históricosDesktop08.3 continúan pendientes, sin ampliar este cambio.

Cierre documental en main: Progress/spec11/registro accesible/changelog actualizados; build/tests N/A porque sólo
documentan hechos de entrega, sin modificar fuente/config ni el gate validado. Verificar fuente606 y sincronización
local/remota al terminar; la fase no se marcaDone ni se activa transporte live.


## 11.8 — Registro local de pago (PLU-82), en curso

2026-10-02. Jesus Franco. Autorizados issue, rama e implementación; sin entrega Git ni live.
Rama `codex/plu-82-sale-payment`, base main `bc183d7`; [propuesta](11-8-sale-payment-proposal.md).
Perfil maintenance. PRE independiente sin hallazgos, cuatro FULL JSON idénticos:771 archivos,
digest `8751d36b79bad15a0f30d27303d2d98b8e8fda0da9ed5e3002113679efa3f662`.
Informe `/tmp/plu82-pre-review.md`, proofs `/tmp/plu82-pre-{root,reviewer}-{before,after}.json`.

TDD RED compilado:17 declaraciones/30 variantes fallidas por stubs cerrados, bundle nativo cerrado:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.02_10-42-16-+0200.xcresult`.
Export `/tmp/plu82-red-native-summary.json`. Errores previos de imports/access corregidos antes del RED funcional.
Caso de uso, política Domain, protocolo, Default/InMemory, actor/contextual y App compuestos;
PaymentID/fecha explícitos, replay sin downgrade ni reescritura, contenido comercial protegido.
Primer GREEN MCP17/17 declarado, pero bundle sinInfo.plist: no acredita validación nativa cerrada.
Se usará RunAllTests para evidencia final; no se atribuye esa anomalía de lifecycle al cambio.

Sin cambios Presentation/View/localización/recursos: previews/smoke/AT N/A para11.8, sin acreditar
flujo visual de cobro. PLU-77/79/81 conservan su deuda y la fase sigue abierta. Schema3/31modelos,
DTO1/2 y gates live intactos. Estilo, suite completa, builds finales y POST pendientes.


### Validación final11.8 previa a POST

Estilo: primer pase cuatro gruposP3 corregidos sin cambio semántico; retest PASS sobre19Swift.
Cuatro FULL JSON idénticos775archivos,digest`94af1e9e9daaafd63e2a92abbf06b229299b949eda95b5c9e434a22331a4bbe2`;
reports `/tmp/plu82-style-review.md` y `/tmp/plu82-style-retest-review.md`, proofs completos `/tmp/plu82-style-retest-*`.
Después de corregir layout, Develop-for-testing25.489s y Production16.233s PASS, cero errores/warnings Swift/Clang;
notices AppIntents metadata skipped2/1 separados (no dependencia AppIntents). Logs:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-105217.txt`
y `BuildProject-Log-20261002-105349.txt` en mismo directorio.

RunAllTests final cerrado:1.331declaraciones/2.132ejecuciones PASS,0fallos/skips/notRun/expectedFailures;
21declaraciones/34ejecuciones nuevas11.8, incluidas composición local, observación, cancelación posterior
al commit, recuperación file-backed doble y v1 no-op sin reescritura. iPadPro13M5 Simulator27.2, SDK27.0,
Swift6 completo. Bundle:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.10.02_10-52-17-+0200.xcresult`.
Exports `/tmp/plu82-final-native-{summary,tests}.json`; declaración/ejecución separadas, finishTime presente.
Fuente/config610archivos idénticos antes/después builds/tests:
`2bc25c4caf77bea9a8ce86a9e7c3a40f23974572e72d84a65782f56ef90bf7d3`,
proofs `/tmp/plu82-final-source-{before,after}.json`. Xcode restaurado Develop/iPad.

Diffcheck PASS; localizaciones528/0. Gobernanza detecta sólo los seis enlaces Desktop históricos08.3,
igual a baseline, sin declarar PASS global. No paths secretos/PII/payload de negocio; fixtures sintéticas.
POST técnico independiente pendiente; sin UI nueva no corresponde POST UI ni nuevos previews/AT.
PLU-82 In Progress, entrega pendiente; fasePLU-71/deuda77/79/81 abiertas, live inactivo.


### Handoff11.8 — implementación y validación local completas

POST técnico independiente sin hallazgos PASS, informe `/tmp/plu82-post-review.md`.
Cuatro FULL JSON íntegros idénticos775archivos:
`c3467947893939f79bff9fc67b245312bfe1d19bc7975d4c8d5fcc36a9be9684`,
proofs `/tmp/plu82-post-{root,reviewer}-{before,after}.json`.
PRE, estilo corregido/retest, builds y suite nativa finales PASS; no cambios ejecutables después.
Actualización posterior sólo documental, build adicional N/A razonado. La evidencia acredita motor,
persistencia y composición local del pago, no un nuevo recorrido visual o interacción física.
PLU-82 In Progress por entrega pendiente; fasePLU-71 y deuda77/79/81 abiertas. No se realizó
commit/push/PR/merge/Done/eliminación de rama ni activación live.11.9 conserva su gate posterior.


### Autorización de entrega11.8

2026-10-02: propietario solicita «commit, push y entrega», cierre completo del flujo PR/merge/issue/rama
conforme al contexto de entregas previas. Se reutilizan PRE/estilo/POST, suite cerrada y builds finales:
fuente/config610 íntegra verificada antes de entrega, sin cambios ejecutables tras validación.
Únicos cambios posteriores: autorización/changelog/cierre documental; Xcode adicional N/A razonado.
PLU-82 permanece In Progress hasta confirmar merge; fasePLU-71 y deuda77/79/81 siguen abiertas.
Sin ampliación a UI de cobro, documento/stock ni live;11.9 conserva su gate independiente.

Revisión independiente de entrega sin hallazgos PASS: `/tmp/plu82-delivery-review.md`;
cuatro FULL JSON idénticos775archivos,digest`d8f88f35971d9741b6b287b01a544e7d8168de7c9034ba1daacbbe03fdb8abc6`.
Informe valida reutilización de fuente/evidencia y límites. Gate de entrega satisfecho; cierre operativo
se realiza sólo tras merge definitivo y comprobación de árbol validado intacto.
