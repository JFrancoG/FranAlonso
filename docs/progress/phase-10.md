# Fase 10 — Catálogo comercial de servicios

## Estado actual —10.1 entregada —2026-09-29

[PR24](https://github.com/JFrancoG/FranAlonso/pull/24) MERGED, commit funcional
`5665dbb114ea1c4271193b99c7cc8f960280e709`, merge `fd4ed5aa898bc187ba5cd1df04e21bfb8e546c53`.
El árbol integrado completo es idéntico al head publicado. Código/configuración/tests conservan la huella POST;
se reutilizan1.008 declaraciones/1.395 resultados PASS, Develop/Production y PRE/POST independientes.
Solo cambiaron registros documentales de entrega/changelog después de validar. Xcode N/A para este cierre documental.

Rama `codex/phase-10-1-service-contracts` eliminada localmente y en origin tras verificar ancestry y0commits únicos.
GitHub confirmó CLEAN/MERGEABLE antes del merge; no checks/reviews remotos ni reglas de protección configuradas.
PLU-60 quedó Done por la integración GitHub–Linear tras el merge; fase10/PLU-59 y el proyecto siguen In Progress.
Changelog, Progress, issue y padre/proyecto se reconcilian con esta entrega. Solo quedan los límites previos registrados:
aviso AppIntents, seis enlaces históricos08.3 y deuda accesible de otras subfases;10.1 no cambia UI.

Siguiente puerta: preparar10.2, integración completa de CRUD con sync/ack/conflictos/tombstones/offline y reapertura
durable. No se inicia aquí ni se activa live.10.3–10.7 y adelanto FoundationModels/PLU-47 mantienen su orden aprobado.
Los apartados siguientes conservan el historial de preparación, implementación y revisión anterior a esta entrega.

## Inicio y preparación10.1 —2026-09-29

Inicio autorizado por el propietario: «Abre issue y rama y empieza10.1».
[PLU-59](https://linear.app/plusprojects/issue/PLU-59), fase10, y
[PLU-60](https://linear.app/plusprojects/issue/PLU-60),10.1, In Progress, Jesus Franco.
Rama `codex/phase-10-1-service-contracts` desde main/origin/main50ecc39 limpios e idénticos.
[Propuesta10.1](10-1-service-contracts-proposal.md) para contratos/entrada comercial/CRUD/búsqueda y aceptación local mínima.
PRE independiente PASS, sin hallazgos P0–P3. Aprobación concreta posterior: «si, adelante».

Inspección real: Service y valores monetarios de04, vertical Service05.10b y precedenteProduct09.1.
Se propone ServiceProfile sin identidad/estado: nombre no vacío y precio no negativo, cero válido; conservar datos históricos.
Precio con impuesto incluido, tipos/vínculos estructurales y decimales vigentes. CRUD comercial con desactivación,
estado actual preservado, búsqueda por nombre y errores neutrales. Validación de Product disponible permanece en10.3.
No se amplían schema/DTO/sync, UI, demo ni Foundation Models. Perfil maintenance y configuración actual conservados.

Baseline09.7 reutilizada:979 declaraciones/1.346 resultados PASS, Develop22,583s/Production20,338s, PRE/POST PASS.
PR23/b40e1f6, head51afed1, cierre50ecc39; código/configuración/tests idénticos a POST2.
Xcode MCP estable y GetTargetBuildSettings verificados: workspace-EYu6rxi7hg, Develop, SDK27.0/target26,
Swift6/strict complete/default nonisolated, warnings como errores. Sin cambio de esquema/destino ni nueva ejecución.
Nuevos builds/tests/previews N/A por preparación documental; aviso AppIntents y seis enlaces históricos08.3 conservados.
Consulta primaria Cupertino: localizedStandardContains. PRE revisó propuesta, alternativas, fuentes y límites.

Fase09/PLU-49 sigue In Progress por PLU-54/57; deuda08 intacta. Tras10.1–10.7 sigue PLU-47/adelanto textual16,
después11–13 para venta completa y08.9 tras feedback según ADR0030. Ningún servicio live ni entregaGit10 autorizado.

## Resultado PRE y puerta siguiente

Auditoría independiente ios-standards-reviewer: PASS limitado a la propuesta, sin hallazgos P0–P3.
Reviewer y root verifican615/615 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas.
Manifiesto `/tmp/franalonso-10-1-pre1.json`, SHA256 `481bd333f62daf02278909af206bebd300404eff7c313600d47597501536d83f`.
El reviewer contrasta documentación Apple de StringProtocol.localizedStandardContains y Foundation, callpaths Data,
dominio monetario y logs/summary de baseline09.7. No ejecuta Xcode ni escribe archivos. Después de verificar la huella,
solo se añade este registro documental y se reconcilia Linear. Gobernanza conserva únicamente seis enlaces históricos08.3.

La propuesta fue aprobada antes de código, incluidos precio normalizado>=0, cero válido, desactivación y
la adaptación local mínima. Registro de implementación y validación a continuación. UI/accesibilidad nueva N/A;
no equivale a cerrar la deuda existente. Commit/push, PR/merge/cierre y10.2 conservan autorizaciones separadas.


## Implementación10.1 —2026-09-29

Alcance aprobado implementado en19 archivos Swift nuevos/modificados: ServiceProfile, seis UseCases, contrato Repository,
regla tipo/vínculo compartida, repositorio in-memory y aceptación local en datasource/actor/repositorio/contextualadapter.
Dos dobles existentes adaptados únicamente a la conformidad ampliada. No cambia la composición de App ni la infraestructura
DTO/modelos/sync. Spec10 documenta los contratos aprobados. Nombre recortado/no vacío, precio normalizado>=0/cero válido,
exactitud decimal, tipos y vínculo estructural; los snapshots históricos siguen legibles.

Alta no reutiliza identidad conocida; edición reemplaza campos comerciales preservando ID/estado vigente. Desactivar
conserva vínculo/importes y no vuelve a encolar ni publicar si ya inactive sin conflicto, incluso tras ack. Tombstones y
conflictos bloquean mutaciones. Actor y ruta contextual usan la misma operación sin suspensión; errores neutrales,
rollback atómico, contexto sucio intacto y cancelación previa/tardía preservan la frontera de aceptación.
Búsqueda local insensible a caja/diacríticos conserva orden, tipos y estados.10.3 conserva disponibilidad del Product.

### TDD y evidencia Xcode MCP

Xcode estable, workspace-EYu6rxi7hg, iPhone18Pro/iOS27.0, scheme y plan FranAlonso-Develop.29 declaraciones nuevas,
49 resultados añadidos a la suite global. Tests de comportamiento comercial, Codable adversarial, legacy, transiciones,
exactitud de importes, homónimos, búsqueda, estado, causalidad, conflictos, tombstones, rollback y cancelación.

- RED compilable: buildForTesting PASS25,976s. Selección29 declaraciones:49 resultados,45 fallos semánticos y4PASS
  de caminos que ya coincidían; nombres/precios/vínculos no validados, búsqueda sin filtrar y CRUD aún sin aceptar.
  No fallos de configuración de fixtures ni compilación. Summary `RunSomeTests/8F6EEED0-376E-4217-8BB1-980D41A3D59E.txt`.
- GREEN focal:29 declaraciones/38 resultados seleccionados PASS. Summary
  `RunSomeTests/026A952F-61AC-4A10-9F95-1CA35D8A5C8E.txt`; resultado nativo cerrado inspeccionado, sin runtimewarnings.
  La selección focal de Xcode no ejecutó todas las variantes de argumentos; la suite global siguiente sí las incluye.
- GREEN global: **1.008 declaraciones/1.395 resultados PASS**,0fallos/skip/notRun/expectedFailures,0runtimewarnings.
  Summary `RunAllTests/8E5601DC-4DA8-465D-9BE4-53468B07D408.txt` bajo ActionArtifacts/default.
  La copia MCP del xcresult carecía de Info.plist; se inspeccionó el original cerrado, sin repetir tests:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.29_21-04-27-+0200.xcresult`.
  Summary nativo1008PASS y finishTime presente. No se confunde inventario, declaraciones y resultados parametrizados.
- Builds finales Develop11,043s y Production19,421s PASS. Logs completos inspeccionados:
  `BuildProject-Log-20260929-210513.txt` y `BuildProject-Log-20260929-210547.txt` bajo ActionArtifacts/default/BuildProject.
  Sin warnings Swift/Clang ni errores; únicamente aviso previo AppIntents metadata por ausencia de dependencia.
  GetBuildLog warning sin issues estructurados. Scheme/plan Develop e iPhone18Pro restaurados.

### Revisión y límites

Auditoría de estilo en19 archivos Swift: recall con3 candidatos (dos firmas con closures y predicado histórico intacto),
correctamente verticales por complejidad; literals JSON largos deliberados. Corregida una llamada nueva de124columnas.
`git diff --check` limpio. Gobernanza mantiene solo seis enlaces históricos08.3 a capturas ausentes; sin fallos nuevos.
POST independiente PASS, sin hallazgos P0–P3, sobre este árbol validado. UI/previews/accesibilidad nueva N/A porque no hay cambios en
pantallas, recursos, localización ni interacción. PLU-54/57 y deuda08 conservan dueño/disparador/evidencia existentes.

PLU-60 y PLU-59 permanecen In Progress. Implementación validada y auditada pendiente de entrega Git explícita;
no commit/push/PR/merge/cierre, siguiente subfase ni live.10.2 integrará CRUD con sync/ack/conflictos/tombstone/offline
completos y reapertura durable;10.3 productos vinculables,10.4–10.7 UI y selección. PLU-47/FoundationModels después.


### Resultado POST y entrega pendiente

Auditoría independiente nueva ios-standards-reviewer: **POST PASS, sin hallazgos P0–P3**. Inspeccionados19Swift y4docs,
callpaths afectados, fuentes Apple de búsqueda localizada/rollback/hasChanges y logs/summary/xcresult anteriores.
Modo operacional read-only: prohibición explícita de escribir/publicar, sin builds ni tests del auditor. Reviewer y root
verifican625/625 archivos tracked/untracked no ignorados idénticos antes/después, sin altas/bajas/cambios.
Manifiesto `/tmp/franalonso-10-1-post1.json`, SHA256 `67b7d7d153d3c2c45a7a3fbd026a34cc5d1ecbea3f497391970512c321bb9b26`.
Tras cerrar la huella, solo se añade el resultado documental a propuesta/Progress/fase10 y se reconcilia Linear.
Código/configuración/tests conservan exactamente el árbol validado; no se repite Xcode por este registro.

10.1 queda lista para commit/push y posterior PR/merge/cierre cuando se autoricen. PLU-60 y fase10/PLU-59 siguen
In Progress. Próxima subfase tras entregar10.1: preparar10.2 con integración CRUD/sync y durabilidad; no iniciada aquí.


## Entrega10.1 autorizada —2026-09-29

Petición posterior del propietario: «Commit y push, lanza PR, merge y cierra su rama».
Preflight de root y revisor independiente:19Swift/configuración/tests idénticos al POST; solo tres documentos registran
el resultado de la auditoría. Main/origin/main y base local coinciden en50ecc39. Sin PR previa para la rama.
Se reutilizan1.008 declaraciones/1.395 resultados, ambos builds y PRE/POST. Nuevas ejecuciones Xcode N/A por registros
documentales de entrega; aviso AppIntents y seis enlaces históricos08.3 permanecen documentados. Entrega en curso.
