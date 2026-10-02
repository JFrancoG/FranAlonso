# 11.7 — Descuentos de venta y de línea

2026-10-02. [PLU-80](https://linear.app/plusprojects/issue/PLU-80), In Progress/Jesus Franco;
rama `codex/plu-80-sale-discounts` desde main limpio/sincronizado `ea78dc6`.
El usuario autoriza issue, rama e implementación local11.7. Entrega Git, cierre,11.8 y live conservan sus puertas.
**Editor de línea implementado y validado; dirección global provisional recibida para la demo.**
La [propuesta global actual](11-7-global-discount-proposal.md) sustituye sólo las alternativas globales iniciales
de este registro. PRE e implementación global pendientes; no se declara11.7 completada.

## Autoridad, estado y baseline

Constitución, spec11/11.7, contrato monetario04, política Swift y ADR0011/0016/0018/0022/0029/0030/0031.
Perfil maintenance: conservar arquitectura por feature, Store/fachada y pipeline local-first existentes.
Xcode MCP estable apunta a este proyecto (`workspace-PfnUYLlMzY`): Develop/planDevelop e iPad Pro13M5 Simulator27.2.
Configuración real verificada mediante GetTargetBuildSettings: Swift6, concurrencia complete, default noMainActor,
targetiOS27 y warnings Swift/Clang como errores; sin elevación ni nueva dependencia.
Baseline11.6 entregada porPR38: fuente/configuración586
`b335eec849cf32f3baf861ca637da6780eaf6fc848cfe75cca850ffbc32f84d9`, 1.245 declaraciones/1.959 ejecuciones,
buildsDevelop/Production, previews, smoke y auditorías PASS. Esta evidencia no valida11.7.
PLU-71 permanece activa; PLU-77/79 conservan deuda integral propia bajoADR0029.

## Decisión comercial pendiente

Spec04 aplaza expresamente el descuento global a11.7. Spec11 exige global, porlínea, límites e incompatibilidades,
pero no determina persistencia, acumulación ni qué sucede al añadir una línea después. Se consultan estas alternativas:

1. **Recomendada: global persistente, incompatible con descuentos de línea.** La venta posee un porcentaje propio,
   también aplicable a futuras líneas. Requiere retirar explícitamente uno antes de aplicar el otro; nada se sustituye
   ni borra en silencio. El global no se infiere comparando porcentajes iguales en las líneas.
2. **Global persistente acumulable.** Aplicación sucesiva:10%línea y20%global producen28%efectivo antes del redondeo.
   Aumenta la complejidad del certificado monetario y exige aclarar el desglose visible y los límites combinados.
3. **Aplicación puntual a las líneas actuales.** Sustituye sus porcentajes con una única aceptación local; una línea
   incorporada después conserva su descuento capturado del catálogo. No existe modo global persistente ni migración.

No se adopta una alternativa por tiempo transcurrido. Después de la respuesta se concretan también el significado de
0 frente a ausencia, el servicio capturado con descuento bajo global y la edición de una venta vacía.
Recomendación adicional para la opción1: porcentaje presente, incluido0, representa un término explícito; al incorporar
un servicio con descuento capturado bajo global, rechazar sin escritura y comunicar la incompatibilidad. Evita borrar
términos capturados o modificar silenciosamente el precio efectivo. La retirada manual permite continuar.

## Contratos comunes a las alternativas

- `Discount` ya valida Decimal finito0…100; conservar fracciones y100, sin Double ni un techo adicional arbitrario.
- Los descuentos son términos snapshot: sustituir o retirar solo en draft; precio/nombre/IVA/producto/identidad intactos.
- Descuento antes del IVA incluido; redondeo porlínea antes de agregar, conforme a04 y al certificadoADR0031.
- Toda edición construye y calcula un candidato antes de aceptar localmente. Error, invalidez, incompatibilidad o
  cancelación anterior conservan venta/totales/colas. Éxito durable no se convierte en fallo reintentable tras cancelar.
- Reutilizar Store→UseCase→Repository→Data y comparación del snapshot esperado; no prometer CAS entre contextos.
- UI manual completa: consultar descuento vigente, introducir porcentaje localizado, aplicar/retirar/cancelar,
  error específico/reintento y lectura readonly. Las Views renderizan estado y envían intenciones semánticas.
- Editor posee ViewModel MainActor; input vacío no equivale a0 ni a retirada automática. Parsing completo exacto con
  separador de sesión, sin aceptar prefijos, símbolos, agrupación o precisión perdida. Reutilizar el contrato probado
  de ServiceDecimalInput mediante un helper Presentation neutral solo si se demuestra esa responsabilidad compartida.
- Una View porarchivo, preview determinista, textosES/EN xcstrings, wrapping y controles nativos alcanzables.
  Retorno de foco al control invocador y comunicación semántica sin timers ni bucles de rearmado.

## Evolución condicionada a global persistente

Domain añade `Sale.globalDiscount: Discount?` y transporta íntegramente ese término por fábricas, Codable, edición,
transiciones y cálculo. Todos los caminos create/load/inspect/edit usan el mismo contrato. Las líneas siguen siendo
snapshots; no se reparte ni materializa el global escribiendo descuentos de línea si se elige una propiedad de venta.

Data añade SaleDTOv2 con lector1/2 y campo global canónico opcional. Decodev1 conserva versión1 y global ausente;
campo global bajo versión1, porcentaje inválido y versión desconocida fallan cerrados. Operaciones nuevas usanv2,
pero pendientes/bases/conflictos/remotos v1 ya guardados conservan versión y bytes; nunca normalizar su replay.
Firestore escribe la versión del payload de la operación y conserva compatibilidad de tombstonesv1. Los envoltorios
causales no evolucionan por este campo; IDs/predecesores/revisiones/retries/cursores y motores inactivos intactos.

SaleModel añade `globalDiscountPercentageCanonical: String?`, distinto entre nil y"0". Congelar una sola forma
histórica exacta de SaleModel para los esquemas1/2/3; el esquema4 sustituye solo esa entidad y sigue con31 tablas.
Plan1→2→3→4 y Schema.franAlonso apuntando a4. Migración ligera3→4 es candidata, no garantía: el gate real debe
demostrar identidad de entidad, preservación de los3 orígenes soportados y reapertura doble. No reconstruir ni vaciar
un store rechazado. Los writers de pruebas históricas deben usar la forma antigua y DTOv1 auténticos.

La alternativa puntual no altera DTO/modelo/schema. Su política deberá describir sustitución explícita, atomicidad,
futuras líneas y comportamiento de0/ausencia, sin presentar un modo persistente inexistente.

## Áreas previstas y exclusiones

- Sales/Domain: Sale, política de edición, calculador y contratosUseCase/Repository según decisión.
- Sales/Data y App/Persistence solo si global persistente: DTO/model/mapping, actualizaciones local-first,
  adaptadorFirestore, histórico congelado, schema4 y migrationplan; sin nuevo motor, actor o transporte.
- Sales/Presentation: Store/fachada, destino/editor/Screen/Content y filas/totales para mostrar y editar descuentos.
- App: composición y previews; Shared/Presentation únicamente para el parsing realmente compartido.
- Tests focales de Domain/DTO/codec/rawmigration/Store/VM/composición; recursos, matriz y registros operativos.

Fuera:11.8/pago nuevo, stock12, numeración/PDF13, cambios del catálogo, nuevos límites comerciales no acordados,
backend/rules/deployment/live, nuevos paquetes/unsafe, targetbeta, refactor ajeno, entrega Git o cierre de fase.

## TDD, validación y riesgos

SwiftTesting RED funcional antes de implementación; oráculos literales, no tests ceremoniales. Porcentaje0/100/fracción,
nil distinto de0, límites/NaN, mixtoIVA/moneda, redondeo porlínea y certificado de precisión. Comprobar incompatibilidad
sin escritura y futuras líneas conforme a la opción elegida; venta vacía, retirada y edición solo draft.
Pipeline real: aceptación única, errores/cancelación/reintento, doble toque, cierre y resultado tardío sin republicar;
recuperación durable conserva global/lineas/totales. Pago/cierre/anulación preservan el término comercial existente.
Si hay evolución: lectorv1/v2, replay antiguo sin recodificación, writer versión correcta, unknownversion sin cursor,
rawstorev1/v2/v3→v4 con todas las familias/blobs/documentos/stock y segunda apertura, metadata/colas exactas.
Ninguna garantía general nueva sobre inmutabilidad remota postpago se atribuye al transporte existente.

Xcode MCP serializado: RED/GREEN focales, regresión afectada y fullplan si cambia Domain/Data/schema/composición;
buildsDevelop/Production con logs completos y avisos AppIntents separados. Auditoría independiente de estilo antes
de validación final; POST técnico/UI read-only con JSON completos de tracked+untracked noignorados idénticos.
Previews representativos Large/XXX/AX5 ES/EN de contenido/editor/error/readonly; smokeSimulator real de aplicar,
retirar, cancelar, incompatibilidad, nuevas líneas y reapertura. No acreditan AT/Inspector/contraste físicos.
ADR0029 exige matriz55 propia, deuda vinculada/Jesus y recuperación tras feedback/estabilización de este flujo,
antes del primer candidato real. PLU-77/79 no absorben automáticamente la nueva superficie.

Riesgos principales: política ambigua, términos perdidos por defaultsnil, redondeo/certificación alterados, versión de
operaciones antiguas normalizada, entidad histórica mutable, sheet cerrada que publica tarde y error sin recuperar.
Reversibilidad local por rama/diff; migración no implica rollback de datos tras guardar un descuento nuevo.

## Fuentes y puerta independiente

Fuentes primarias Apple leídas medianteCupertino: [VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema),
[SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan) y
[MigrationStage.lightweight](https://developer.apple.com/documentation/swiftdata/migrationstage/lightweight(fromversion:toversion:)).
Son documentación oficial cacheada; la recuperación web actual no ofreció contenido equivalente legible. Describen
las APIs, pero no prueban esta migración concreta. Compilación y rawstore gates deben aportar esa evidencia.
Contratos monetarios/repositorio vigentes y SDK real prevalecen frente a ejemplos genéricos.

Exploración independiente read-only de Domain/Data completada, sin escrituras ni selección comercial. La propuesta
definitiva y el gate PRE de implementación permanecen pendientes de la decisión del propietario y revisión independiente.

## PRE parcial y primer tramo independiente — 2026-10-02

`discount_pre`, agente nuevo ios-standards-reviewer, sin hallazgos bloqueantes; PASS exclusivamente para descuento
manual DE LÍNEA sobre fachada/Store actuales, conservando Domain/Data/schema y política0…100. GlobalPENDING.
Root verificó FULLJSON747 before/after/root idénticos:
`5fb9e30eb37fd46db73926606f252eb895bf873b937ccc2702c51feed2556473`.
Informe y proofs en `/tmp/plu80-pre-independent-report.md` y `/tmp/plu80-pre-independent-{before,after}.json`.

Contrato concreto revisado: sheet identificable con destino/finish en fachada existente, ViewModel propio
Observable/MainActor y capacidades canEdit/setDiscount compuestas enApp. Texto editable de sesión, sin copia de venta/
totales; valor Discount? y requestUUID congelados antes del await. UUID permanece requested→applying para no cancelar
la tarea al iniciar. Vacío inválido,0 explícito y Retirar nil separado. Retry conserva valor/lineID; editar texto invalida
el fallo. Dobles toques/terminales no escriben; cierre cercará publicación y cancela tarea caller sin cerrarStore padre.
Mostrar descuento vigente también readonly. Parser neutral Shared/Presentation reutiliza exactamente el contrato de
Services; adaptación sin cambio semántico y regresión existente obligatoria. Fuera del tramo: global/incompatibilidad
nueva, Domain/Data/schema, entrega y cierre11.7. TDD/validación/POST parciales todavía pendientes.


## Resultado técnico del ámbito parcial — 2026-10-02

Editor manual de línea sobre Store/fachada existentes: consultar porcentaje/ausencia, aplicar Decimal0…100,
retirar nil explícito y cerrar sin solicitar escritura. Cero no equivale a ausencia; vacío es inválido.
Comando congelado, UUID estable durante aceptación, retry del mismo término y cierre que cerca publicación
sin cerrar el borrador padre. Parser Presentation neutral byte-idéntico con alias para Services.
No Domain/Data/schema ni política global implementados.16 clavesES/EN;521 entradas y0errores.

TDD funcional RED39/40 variantes fallidas, después GREEN completo1263declaraciones/1999ejecuciones,
incluidas18declaraciones/40variantes nuevas, todasPassed;0fail/skip/expectedFailure/runtimeWarnings nativos.
Builds finales XcodeMCP estable Develop18.155s/Production18.752s, ceroSwift/Clangwarnings/errores;
2/1avisos conocidosAppIntents separados. La consola de tests contiene avisos internosCrashlytics y errores
esperados de sondas negativas; no es una consola sin mensajes. Bundles/exports/logs en [fase11](phase-11.md).
13previews propias renderizadas/inspeccionadas, sin errores: editorESLight/ENDark, errorES y borradorES,
Large/XXX Large/AX5 en iPadPro13M5Simulator27.2. Override de idiomaEN no acredita región/separador inglés;
Locale de sesión y gramáticaES/EN sí tienen pruebas. AX5toolbar/scroll/AT siguen limitados por captura.
POST técnico parcial independiente PASS, sin hallazgos; estilo17SwiftPASS. Smoke inicial9/9conservó P2funcional
 de primera apertura. PRE focal técnico/UI aprobó2stylesborderless en botones de fila, conservandoStepper/capas.
La versión corregida tiene regresión1263/1999incluidas40nuevas y coldsmoke9/9sin retorno
 ni presentacióncompetidora observados. POST UI focal independiente PASS: P2 de primera apertura resuelto
 para el gate funcional parcial del editor de línea ADR0029; sin nuevos hallazgos. No demuestra causa original
 ni estabilidad universal. Fuente/config595 validada sin cambios tras el retest; bundles/proofs en fase11.
Deuda integral propia [PLU-81](https://linear.app/plusprojects/issue/PLU-81),
Backlog/Jesus Franco, tras feedback y estabilización del recorrido antes del primer candidato real;
[matriz55](../accessibility/evidence/11-7-sale-line-discounts.md). No entrega Git ni cierre de subfase/fase.
