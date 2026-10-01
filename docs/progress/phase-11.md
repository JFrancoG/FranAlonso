# Fase11 — Jornada y motor de ventas

Última actualización: 2026-10-01.
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
11.4–11.9 conservan sus propios gates.
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
