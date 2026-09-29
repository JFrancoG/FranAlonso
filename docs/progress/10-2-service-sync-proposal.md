# Propuesta 10.2 — CRUD de Service, sincronización y recuperación durable

Fecha: 2026-09-29. [PLU-61](https://linear.app/plusprojects/issue/PLU-61), hija de
[PLU-59](https://linear.app/plusprojects/issue/PLU-59), Jesus Franco, In Progress.
El propietario autoriza issue, rama e implementación: «Adelante abre issue y rama e implementa 10.2».
Implementación completada tras PRE PASS: cinco caracterizaciones PASS inicial, sin cambios productivos;
1.013 declaraciones/1.400 resultados PASS y build Develop con tests PASS. Retest final20/20 PASS tras corregir espera temprana del test de ACK; POST2 PASS. [Evidencia](phase-10.md).
Entregada por [PR25](https://github.com/JFrancoG/FranAlonso/pull/25), merge df0a5d6, commit25ef353 intacto;
PLU-61 Done y rama eliminada. Los apartados siguientes conservan el historial previo a la entrega.

## Autoridad y estado real

[Spec10](../specs/10_services_catalog.md), constitución, política Swift, guía de desarrollo y ADR0002/0006/0011/0015/0018/
0029/0030. Perfil maintenance: conservar límites Domain/Data/Presentation/App y composición local existente.
10.1/PLU-60 está entregada por PR24. Rama `codex/phase-10-2-service-sync` desde main/origin/main
`d9731f2804ea918fa08ab810c3fe231148fd9501`, limpios e idénticos al inicio. No otros cambios locales.

Baseline10.1 reutilizada:1.008 declaraciones/1.395 resultados PASS, Develop11,043s/Production19,421s y PRE/POST PASS.
[Evidencia](phase-10.md). Aviso AppIntents previo y seis enlaces históricos08.3 conservados.
Xcode MCP estable confirma workspace-EYu6rxi7hg, scheme Develop, iPhone18Pro y configuración vigente, sin alterarla.
Nuevos build/tests N/A durante la preparación; se ejecutarán después de implementar.

## Inspección y propuesta

ServiceLocalDataSource acepta los comandos10.1 mediante persistPendingUpsert; actor y adapter contextual comparten
primitivas atómicas. ServiceSyncEngine ya implementa pull, push causal, ACK que conserva descendientes, conflictos,
tombstones y retry durable. AppRuntime comparte actor/señal entre repositorio y motor; su construcción no inicia I/O.
Las pruebas actuales de CRUD son locales y las de sync suelen sembrar operaciones técnicas. Falta probar juntos los
comandos comerciales y el motor, con reapertura de un store real. No hay defecto productivo demostrado.

Añadir cinco caracterizaciones con capas reales y remoto determinista sobre el seam ServiceRemoteDataSource existente:

| Escenario | Comportamiento y oráculo |
|---|---|
| CRUD/repetición | Crear, editar perfil completo y desactivar; sincronizar repetidamente. Un documento remoto inactivo, tres operation IDs aplicados una vez, cola vacía y ausencia de pending delete. Desactivar tras ACK no cambia revisión ni encola. |
| ACK antiguo | Gate tras commit remoto del alta; editar/desactivar por adapter contextual con container/señal compartidos. ACK preserva el último perfil inactivo y descendientes. Siguiente pase converge sin reactivación. |
| Conflicto remoto | Cambios comerciales locales y revisión remota concurrente: conservar snapshot, ambos lados del conflicto y cadena causal; bloquear update/deactivate/sucesores, manteniendo otra identidad operable. |
| Tombstone | Recibir por sync un tombstone para identidad con CRUD pendiente. Stream local vacío, lookup nil; create alreadyExists, update/deactivate deleted; evidencia retenida y repetición sin resurrección ni upserts adicionales. |
| Offline/reapertura | CRUD aceptado y fallo de push con presupuesto de retry agotado mediante reloj manual. Liberar consumidores/container; reabrir misma URL única y comprobar snapshot, bytes de payload/base, IDs/predecesores, cursor/estado remoto y retry. Recuperar remoto, converger sin duplicados y reabrir otra vez, sin colas/retries reaparecidos. |

Service añade nombre, precio/moneda exactos con Decimal(string:), impuesto/descuento y tipo/vínculo a los oráculos.
Ejercitar cambio profesional→producto y producto→profesional, retención del vínculo al desactivar y distinción nil/cero
de descuento cuando corresponda. No validar existencia/actividad del Product: pertenece10.3.
No usar la política productiva como único oráculo del fake: comprobar valores esperados y aplicaciones explícitas.

La reapertura usa Schema.franAlonso y PhaseFiveSchemaMigrationPlan actuales (StockMovementsSchema3.0, con etapas previas),
sin cambiar schema ni migraciones. Comprobar weak references nil entre lifetimes, cancelar observaciones y esperar tareas;
no confundir otro actor sobre un container vivo con una reapertura. URL temporal aislada, limpieza al finalizar.
Concurrencia mediante continuations/AsyncStream, sin polling, sleeps de sincronización ni deadlines de pared.

## Archivos, alternativas y límites

Crear ServiceCRUDSyncIntegrationTests.swift y ServiceCRUDDurabilityTests.swift. Extraer solo helpers ya compartibles
(ServiceSyncRemoteFake, ServiceSyncAcknowledgementGate y reloj manual) a ServiceSyncTestSupport.swift, adaptando los
usos existentes. Añadir registro de operation IDs aplicados y entrada remota al fake; ningún framework genérico nuevo.
Se ejecuta producción real contra expectativas independientes: las cinco preguntas de tests-de-verdad aplican.
Si pasan inicialmente, registrar PASS inicial de caracterización, sin fabricar RED. Si revelan un defecto, conservar RED
y corregir únicamente el contrato aprobado responsable en datasource/actor/repository/contextualadapter/engine.
Cualquier regla nueva, arquitectura, dependencia, unsafe, schema/API adicional o live exige propuesta separada.

Alternativas descartadas: reescribir una vertical ya existente; duplicar unitarios sin recorrer CRUD→sync; usar red real
para offline; declarar durabilidad solo con un actor nuevo in-memory. Riesgos: confundir inactive con tombstone, perder
sucesores al ACK, redondear importes, oráculo circular del fake o retener el primer container. Los escenarios los distinguen.
Retirar tests/helpers es reversible y no cambia datos ni proveedores de la app.

Excluidos: UI/ViewModels/previews/recursos, Product disponible10.3, stock, ventas, seed demo, FoundationModels, scheduler,
activación live y resolución UI de conflictos. La observación local se valida vía stream del repositorio real, sin crear UI.
UI/accesibilidad nueva N/A; deuda08 y PLU-54/57 mantienen responsable y recuperación tras feedback, antes de uso real.

## Validación y fuentes

Primero nuevos escenarios, después regresión afectada: CRUDService, sync/policies/retry/recovery, DTO/remoteadapter,
repositorio/actor, composición App y migraciones actuales. Xcode MCP y resultados nativos cerrados; comprobar número
real de casos parametrizados. Si la selección vuelve a omitir argumentos, suite completa como fallback documentado.
Build Develop con tests/log completo; Production nueva solo si cambia producción/configuración. Sin warning Swift/Clang;
separar AppIntents conocido. Diff-check, gobernanza, auditoría de estilo y POST independiente read-only.

Fuentes primarias: contratos y rutas reales citados, ADR aceptados; no API nueva. Reapertura con los contratos Apple de
[ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) y
[ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration), ya usados por el precedente09.2.
La evidencia local no acredita Firestore live. No cerrar fase ni debt accesible mediante estas pruebas.

Commit/push, PR/merge/cierres y10.3 quedan pendientes de autorización posterior.

## Resultado PRE

PRE independiente PASS, sin hallazgos P0–P3. Reviewer/root verifican626 archivos idénticos, manifiesto
`/tmp/franalonso-10-2-pre1.json`, SHA256 `3b3b2cb43a81e4aed166e1cf118a4a8243df609e459efe43d9be08da079d17d2`.
Revisadas rutas reales, fuentes Apple y baseline nativa; auditor sin escrituras/builds/tests. Implementación autorizada
por la petición inicial. Conservar oráculos independientes y liberar gates también ante errores.


## Resultado final y entrega pendiente

POST1 detectó una espera sin salida temprana en el test del ACK; corregida con señal persistente de finalización y
cleanup estructurado. Dos inyecciones negativas temporales terminaron con el fallo explícito esperado; retiradas antes
del retest20/20 PASS. POST2 independiente PASS, sin hallazgos restantes. Reviewer/root verifican629/629 archivos idénticos;
manifest `/tmp/franalonso-10-2-post2.json`, SHA256 `dded9b8352ce3afe685b315205b002274232c1e42cf0c6c2d1fb92e14e46c1fe`.
Solo este registro documental se añade después. Código/configuración/tests conservan el árbol validado y auditado.
PLU-61 y PLU-59 siguen In Progress, pendientes de entrega Git explícita.10.3 aún no iniciada.
