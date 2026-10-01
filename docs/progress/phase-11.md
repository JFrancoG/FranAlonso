# Fase11 — Jornada y motor de ventas

Última actualización: 2026-10-01.
[PLU-71](https://linear.app/plusprojects/issue/PLU-71): In Progress, Jesus Franco.
Autoridad: [spec11](../specs/11_sales_engine.md), constitución y ADR0011/0016/0018/0030.

## 11.1 — Ciclo local de borrador

[PLU-72](https://linear.app/plusprojects/issue/PLU-72): In Progress; rama `codex/plu-72-sale-draft-lifecycle`.
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

Implementación local11.1 y puertas técnicas completas; PLU-72 permanece In Progress hasta la entrega autorizada.
Entrega administrativa11.1 autorizada y en curso: commit, push, PR, merge y cierre pendientes.
11.2–11.9 pendientes, cada una con su propio gate.
La demo completa necesita stock12 y documento13; fase11 y deuda accesible previa siguen abiertas.
