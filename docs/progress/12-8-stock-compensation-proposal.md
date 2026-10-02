# 12.8 — Propuesta de compensación de stock

Autorización: «abre issue y rama e implementa12.8». [PLU-95](https://linear.app/plusprojects/issue/PLU-95/128-compensate-stock-when-voiding-a-paid-sale),
In Progress/Jesus Franco, hija PLU-85. No issue12.8 previa entre todas las hijas activas/archivadas de PLU-85.
Rama `codex/plu-95-sale-stock-compensation` desde main/origin/main `392d7ac4bf3a381f1e79cd08f5f6fbce94b92e9a`, limpia.
ADR0034 aceptado03/10 por «si, aprobada» tras PRE/focal PASS. Implementación/validación autorizadas; entrega pendiente.

## Autoridad y baseline

Constitución, spec12, DEVELOPMENT_GUIDE/checklist, política Swift y ADR0004/0006/0007/0011/0016/0018/0033.
12.7 Done/PLU-94/PR48; sus26Swift coinciden con manifest validado. Baseline nativa final02/10/2026 22:26:10:
2.319ejecuciones/1.465declaraciones PASS, 0fallos/skips/runtimeWarnings; finishTime cerrado y summary inspeccionado.
Builds Develop22:25:58 y Production22:19:13 PASS, 0diagnósticos Swift/Clang; aviso AppIntents metadata conocido.
Bundle real: `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/`
`Test-FranAlonso-Develop-2026.10.02_22-26-10-+0200.xcresult`. Evidencia histórica, no pruebas12.8.
Xcode MCP estable workspace-PfnUYLlMzY/proyecto real, Develop activo y settings verificados: target/SDK27,
Swift6/nonisolated/complete y warnings Swift/Clang como errores. Sin repetir tests con fuente/config idénticas.

## Conducta y áreas exactas

[ADR0034](../ADRs/0034-sale-stock-compensation.md) contiene identidad, lifecycle, aceptación, versiones y alternativas.
Registrar void de una venta **closed**, sin abrir awaitingDocument: misma restricción de Sale.void vigente.
Venta voided y compensaciones se aceptan juntas localmente, con replay exacto de reversal ID/fecha. Un movimiento
por cada línea de producto con unidades inversas; Product repetido conserva líneas separadas. Servicios profesionales
no generan stock. Snapshot comercial/pago/documento y consumos originales siguen intactos.

Áreas previstas:
- Products/Domain/StockMovementOrigin y construcción válida del nuevo origen; Sales/Domain/Policies para aceptación
  y derivación, ValueObjects/StockMovementID+SaleReversal, VoidSaleUseCase y error neutral SaleReversalError.
- SaleRepository capability voidSale (default fail-closed para dobles sin capacidad), Default/InMemory repositories;
  SaleLocalDataSource, SalePersistenceActor y SaleContextualPersistenceAdapter comparten una única frontera Data.
- StockLocalDataSource prepara compensaciones con originales verificados, sin condicionar historia al Product actual;
  StockMovementModel admite local3 y StockMovementDTO remoto2 compensatorio, preservando1/2 y remoto1 históricos.
- Composición concreta App expone la capacidad Domain sobre el repositorio existente; no añade acciones UI,
  mutaciones a pantallas históricas, navegación, localización, preview ni otro Store.
- Tests nuevos focales Domain/Data/durabilidad/transport/sync/composición; adaptar exhaustividad de fixtures por origen
  únicamente donde corresponda. Documentación/índice ADR/Progress/phase12 reflejan evidencia real.

La política reconstruye los consumos esperados desde la venta capturada; Data exige que cada original exista y sea
equivalente, sin conflictos. No genera originales durante el void. Un replay de voided puede completar un prefijo
compensatorio faltante con una sola aceptación, sin causal upsert nuevo ni reconocimientos remotos inventados.
Producto borrado/conflictivo/inactivo conserva historia y puede compensarse; Stock ID conflictiva o historial
corrupto/overflow bloquea todo. No reset/reseed/barrido automático ni edición de originales.

## TDD y validación previstas

Antes de tests leer tests-de-verdad/doctrina y estándares iOS aplicables. RED con ausencia real de compensaciones,
luego implementación mínima y GREEN/regresión. Oráculos literales independientes, fixtures Codable y barreras
deterministas sin sleeps ni expectativas que copien la implementación.

- Closed→voided con pago/cierre intactos; varios productos/líneas repetidas y profesional; snapshot obsoleto y estados
  anteriores rechazados; replay closed previo/voided aceptado solo con metadata exacta; reversal distinto conflictivo.
- ID literal derivada, inversión exacta, fechas precisas y origen trazable; originales ausentes, divergentes,
  corruptos o conflictivos bloquean todo; identidad compensatoria divergente y saldo conjunto fuera de Int.
- Fallo después de staging antes de único save: inspeccionar Sale/upsert/todos movimientos staged y lectura
  independiente aún original; rollback limpio, retry estable. Contexto sucio intacto; cancelación antes/después commit;
  señales solo tras estado durable, ambas rutas reales y composición compartida.
- Reopen file-backed después de fallo/éxito y segunda apertura tras liberar realmente cada container/context;
  mezcla manual1/consumo2/compensación3 mantiene bytes/metadata originales, Schema4/plan intactos.
- DTO remoto manual/sale1 idénticos, compensación2 round trip; versión/origen cruzados, claves extra, UUID no canónico,
  ID/referencia original inválida y futuros rechazados; conflicto remoto no sobrescribe ni consume secuencia.
- Sincronizar Sale y Stock explícitamente con dobles, reordenados/repetidos y tras restart/cancel/retry; compensación
  antes del consumo converge al mismo saldo sin derivar eventos desde Sale ni resucitar Product/Sale.
- Dos dispositivos offline desde el mismo closed, reversals distintos: la ID compensatoria es la misma por original,
  reversal ID/fecha son payload conflictivo. Solo un +q remoto y una secuencia; el segundo intento conserva conflicto,
  nunca otra restitución. Pull reordenado/repetido y reopen conservan originales y no añaden la segunda compensación.

Builds Develop/Production, pruebas focales y regresión por Xcode MCP, logs completos y native xcresult cerrado;
inspeccionar argumentos parametrizados reales. Estilo scoped/manual, diff y gobernanza; PRE antes de código,
POST técnico independiente después. UI/accesibilidad N/A si se mantiene ese ámbito; PLU-89/91 Backlog/Jesus,
feedback/estabilización y evidencia antes del primer candidato real conservados. No cierre integral ni fase13.

## Riesgos, alternativas y reversibilidad

ADR0034 explica por qué no usar ajuste manual o dos saves. Requiere aprobación por ampliar el contrato versionado0033
y permitir restitución histórica sin elegibilidad del catálogo. Mantener lectores de payloads nuevos una vez usados;
los clientes antiguos fallan cerrados. No cambiar Schema4 ni DTO Sale1. No CAS entre contextos independientes ni
atomicidad remota Sales+Stock; gates live0033/writers/compatibilidad siguen separados. Motor inactivo, sin scheduler.
No acredita ajuste fiscal o devolución monetaria: conserva la referencia para ese flujo de ADR0006.

## PRE y puerta del propietario — preparación02/10

PRE stock_compensation_12_8_pre detectó un P1: incluir reversalID en la ID permitía doble restitución entre writers
offline. Corregido en propuesta/ADR: una ID compensatoria por original; reversalID permanece en payload conflictivo.
Añadido escenario de dos dispositivos/reordenación/reinicio. No otros hallazgos. Snapshot original read-only890archivos:
digest inicial/final/root idéntico `1f83a4629d1561e1137302af7c9733a292a70e412356e473fb1f160616777f39`.
Focal independiente stock_compensation_12_8_pre: PASS sin hallazgos; P1 cerrado en la propuesta.890archivos,
digest inicial/final/root idéntico `3365991f61f254f06bbf482f0f2b973e35afee32a1427ce214e6e8678af94311`.
No builds/tests nuevos: revisión documental de propuesta, sin garantía ejecutable acreditada12.8.
Gobernanza conserva solo6enlaces Desktop históricos08.3; Progress bajo8192bytes; localizaciones577/0 y diffcheckPASS.
No escribir código hasta aprobar ADR0034. La solicitud inicial autoriza implementar12.8,
pero start-subphase exige dirección del propietario antes de un ADR no aprobado. Entrega sigue siendo separada.

## Implementación y evidencia03/10/2026

Aprobación «si, aprobada» registrada antes de código. Domain añade VoidSaleUseCase, aceptación de snapshot completo,
política inversa e ID única por venta/línea. Data exige originales válidos/conflictos ausentes, valida saldo agregado
y acepta Sale/upsert/inversas en un único save no suspensivo con rollback; actor y adapter contextual comparten
esa frontera. App compone la capacidad sobre su repositorio actual. No pantalla ni acción nueva; ajuste fiscal y
devolución financiera permanecen separados. Schema4 y plan sin cambio, transporte Sale1 intacto.

TDD: RED00:45:02, el payload local3 válido falló con storageFailure sobre producción anterior. GREEN focal
00:52:46:15/15; batería ampliada01:05:06:41/41 ejecuciones. La primera regresión01:06:50 detectó tres fallos
históricos de pago: dos closures default del nuevo init redirigían silenciosamente el trailing closure. Corregido
en producción sin tocar tests históricos: init(paymentSave:) original más init(reversalSave:paymentSave:) con
ambos argumentos explícitos. Un helper nuevo de tests inyecta solo el fallo de reversión manteniendo save real de pago.

Regresión final Xcode MCP estable01:08:46:2368/2368 ejecuciones,1491/1491 declaraciones,0fallos/skips/notRun/
expectedFailures/runtimeWarnings. Nuevas12.8:49ejecuciones/26declaraciones. Native summary y árbol de tests
inspeccionados, finishTime cerrado y todos los argumentos presentes (7fallos Stock,8payloads remotos,3versiones
locales,4términos históricos,3fences Sale,2estados de pago,2Product y2transportes históricos).
Bundle real en DerivedData: Test-FranAlonso-Develop-2026.10.03_01-08-46-+0200.xcresult.
Develop build-for-testing01:08:41 PASS12.238s; Production01:09:41 PASS22.677s; ambos GetBuildLog warning0
cerrados. Logs completos conservan únicamente aviso AppIntents metadata conocido; ningún diagnóstico Swift/Clang.
Destino iPadPro13-inch(M5)/Simulator27.2, SDK27; esquema Develop restaurado.

Cubierto: varias líneas/Product repetido/profesional, bytes originales, snapshot/metadata/replay/prefijo reparable,
fences/corrupción/overflow, save parcial fallido/rollback/retry, cancelación pre/postcommit y acknowledgement,
writer compartido concurrente, Product ausente/inactivo/conflictivo, saldo negativo, reopen file-backed con
liberación real verificada y segundo reopen, manual1/consumo2/inversa3, literal remoto2 y versión/origen cruzados.
Dos dispositivos offline compiten por una única inversa: conflicto durable y una sola suma/secuencia; reordenación,
replay/reinicio y llegada de inversas antes de originales convergen sin generar Stock por observar Sale.
Motores reales Sales y Stock ejercitados explícitamente con dobles remotos; producción sigue inactiva.

Estilo scoped:24Swift inspeccionados por script y manual;10candidatos justificados por closures/tipos función y
predicados históricos fuera del diff. UUID tuple conserva grupos de bytes como el contrato12.5; fixtures literales
son oráculos independientes. Sin normalización global. DiffcheckPASS, localizaciones577/0. Gobernanza conserva
solo6enlaces Desktop históricos08.3. UI/previews/accesibilidad12.8 N/A por ausencia de cambio; no acredita AT/físico.
PLU-89/91 Backlog/Jesus conservan Falla/Pendiente/Limitado y trigger feedback/estabilización antes candidato real.

POST independiente completado PASS sobre snapshot final; detalle a continuación. PLU-95/85 In Progress.
No prueba de fallo físico de disco, transacciones reales Firestore/Rules, contención live, CASmultiwriter ni
atomicidad remota entre colecciones. La subfase prepara compensación Stock y trazabilidad; fase12 sigue abierta.

### POST independiente y preparación de entrega12.8

stock_compensation_12_8_post, agente fresco ios-standards-reviewer, PASS funcional sin hallazgosP0–P3.
Auditó24Swift/diff/rutas afectadas y autoridad/docs; verificó RED, native2368/1491 y nuevas49/26, argumentos,
builds/diagnósticos y manifest24Swift sin discrepancias. ID literal recalculada independientemente.
Revisión operacional read-only:903archivos, digest inicial/final/auditor/root idéntico
`6dca85fe409d1c10337042ef4b845b6d73f34343cf9421133ae18a4b6c451d48`.
UI/accesibilidad12.8 N/A; deuda89/91 preservada, sin cierre integral/fase12. Fuentes Apple/Cupertino,
RFC9562 y transaccionesFirestore contrastadas con los límites locales/remotos aceptados0034.
Registro final solo documental; Swift conserva paridad literal con el código probado y auditado, sin necesidad
de repetir Xcode. PLU-95/85 In Progress/Jesus reconciliados con POST PASS y entrega pendiente.
Rama codex/plu-95-sale-stock-compensation sin commit/push/PR/merge/Done/live autorizado.12.8 preparada
para la siguiente autorización de entrega; fase12 y deuda accesible integral permanecen abiertas.

### Autorización de entrega03/10/2026

El propietario solicita «commit, push y entrega». Autoriza la entrega completa12.8 según el recorrido establecido:
commit de alcance exacto, push de rama, PR/revisión/merge, reconciliación Done de PLU-95 y limpieza de rama.
El resultado Git definitivo sigue pendiente; PLU-95/85 aún In Progress. No autoriza cierre integral/fase12, live
ni siguiente fase. Validación/auditoría recientes reutilizadas:24Swift iguales al manifest probado/auditado,
2368ejecuciones/1491declaraciones y nuevas49/26 PASS, buildsDevelop/Production, PRE/POST PASS.
Revisión de estilo read-only repetida sin cambios/hallazgos nuevos;10candidatos de closures/predicados adjudicados.
Cambios posteriores solo documentación/changelog; Xcode adicional N/A por paridad ejecutable literal.
