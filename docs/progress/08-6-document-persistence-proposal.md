# 08.6 — Propuesta de persistencia recuperable y envío de documentos

Fecha: 2026-09-13. Issue [PLU-40](https://linear.app/plusprojects/issue/PLU-40), In Progress.
Estado: implementación aprobada por el propietario el 13/09 («Si, adelante»), tras revisión independiente PRE favorable.
Implementada y validada localmente; [evidencia final](phase-08.md) y entrega Git pendiente.
Rama local `codex/plu-40-phase-08-6-document-persistence`, desde `main`/`origin/main`
`36f5efa88a97a7c223ac58c8eca1f4bac2b6ae72`, limpios y coincidentes al inicio.

## Autoridad y baseline

[Constitución](../specs/01_constitution.md), [spec08](../specs/08_clients_consent.md),
[ADR0002](../ADRs/0002-swiftdata-local-sot-firestore-remote-sot.md),
[ADR0006](../ADRs/0006-sync-conflicts-tombstones.md), [ADR0009](../ADRs/0009-client-consent-activation.md),
[ADR0011](../ADRs/0011-swiftui-boundaries-specialized-reviews.md),
[ADR0018](../ADRs/0018-swiftdata-baseline-from-phase-five-ten-c.md),
[ADR0021](../ADRs/0021-local-store-principal-authorization.md) y
[ADR0028](../ADRs/0028-client-signed-information-and-photo-authorization.md).
La arquitectura propia prevalece sobre defaults genéricos de skills: Domain puro, modelos SwiftData en Data,
conflicto explícito y primitivas de escritura compartidas conforme ADR0011; sin adoptar last-write-wins.

PLU-39 verificada Done; PR#12 integrada en `943cd84`. PLU-34 y PLU-38 permanecen abiertas.
Configuración real: iOS26.0, Swift6, concurrencia complete, aislamiento por defecto nonisolated y warnings como errores.
MCP registrado apunta a otra instancia de Xcode/Reguerta. Una sesión nueva del puente oficial de Xcode-RC27.0,
dirigida al proceso verificado mediante MCP_XCODE_PID, descubre53 herramientas y confirma FranAlonso:
`windowtab-QTPhkgjxly`, Develop, iPad Air11M4/26.5, SDK Simulator iOS27.0, Navigator sin incidencias.
No se cambia configuración global ni se ejecuta build/test. Antes de implementar se debe redescubrir la sesión correcta;
el PID y el identificador de ventana no son configuración permanente.

Baseline08.5 conservada:43 resultados de regresión, catálogo ampliado8/8 y build PASS12,132s.
Se relee el xcresult14:16:27:23 tests declarados con parametrización,43 resultados por destino y cero fallos/omitidos.
El log completo `BuildProject-Log-20260913-141942.txt` conserva únicamente el aviso conocido de extracción AppIntents.
Rutas y evidencia en [fase08](phase-08.md). No equivale a suite global, cero warnings globales, Production o CI.
La preparación actual es documental; build/tests nuevos N/A. Se conservan los seis enlaces históricos08.3 rotos.

## Comportamiento propuesto

1. Guardar una ficha borrador y su trabajo documental sin red. Un borrador durable conserva identidad de edición,
   clientID, ClientProfile, snapshot presentado, firma vinculada cuando exista y fecha fijada al aceptar esa firma.
   La identidad del borrador editable es distinta del ID inmutable del documento. Ninguna tinta entra en ClientProfile.
2. Conservar el trabajo antes del render: tras reiniciar, una firma válida recupera exactamente snapshot, binding y
   fecha; no consulta el catálogo actual. Cambiar un dato presentado, decisión o contenido invalida la firma pendiente,
   descarta su fecha y genera un nuevo ID de documento al preparar la siguiente firma. Un dato no presentado no la invalida.
3. Renderizar desde el binding y la fecha ya guardados, fuera de MainActor. Reutilizar RenderConsentUseCase y su reloj
   inyectable fijado a esa fecha. Si se interrumpe antes de guardar el resultado, puede repetirse el render sin pedir
   otra firma. Ningún envío comienza antes de aceptar durablemente el artefacto. Desde ese punto se conservan y
   reenvían siempre los mismos bytes; nunca se promete que dos renders independientes generen bytes iguales.
4. Aceptar documento completo y trabajo de envío en una sola escritura local. Conservar binding, snapshot, fecha,
   PDF definitivo y versión del envelope Codable. Mismo ID y valor completo es no-op; otro payload, firma, fecha
   o PDF bajo ese ID produce conflicto y no reemplaza el original. La igualdad no depende del orden de claves JSON.
5. Ofrecer guardado, recuperación y envío/reintento como capacidades Domain/Data consumibles por08.7. Guardar nueva
   ficha, sus cambios y operación ClientPendingUpsert junto al borrador usa una única transacción/contexto y las
   primitivas locales existentes. Cliente inicial permanece draft en08.6; no se implementa activación.
   Una autorización posterior conserva sin cambios el estado active y la referencia inicial del cliente existente.
6. UploadConsentUseCase carga únicamente el documento durable y lo entrega a un repositorio Storage neutral.
   El recibo incluye ID y referencia opaca estable, se valida contra la petición y se guarda antes de declarar envío
   completado. Si el remoto aceptó y el guardado del recibo falló, el siguiente intento recupera el mismo recibo.
   Ningún recibo activa clientes ni modifica su referencia inicial en esta subfase.
7. Offline y fallos transitorios dejan trabajo recuperable; permisos denegados requieren reintento explícito después
   de resolver acceso. Cancelación conserva el documento aceptado y no marca éxito. Un conflicto se conserva y
   detiene el reintento automático. No se purgan documentos/recibos ni se programan motores en background.
8. Cancelar la edición puede descartar explícitamente el borrador no enviado. No revoca ni borra un documento ya
   aceptado o una operación remota de resultado incierto; esos estados se mantienen recuperables. La limpieza de
   históricos, retirada de autorización y objetos remotos queda fuera de08.6.

## Schema y aceptación local

Propuesta aditiva: `ClientDocumentsSchema` versión2.0.0 con los28 modelos actuales sin modificar su forma y dos
modelos Data nuevos. `PhaseFiveBaselineSchema` sigue1.0.0 con sus28 modelos originales.

| Modelo nuevo | Responsabilidad y datos |
|---|---|
| ClientDocumentDraftModel | ID de borrador, clientID, revisión de edición, envelope Codable versionado con ficha/snapshot/binding/fecha según estado. |
| ClientSignedDocumentModel | ID documental único, clientID, envelope inmutable completo y bytes PDF; estado de envío, intento/retry, error neutral y recibo durable. |

El trabajo de envío pertenece a la fila documental; no se duplica el PDF en otra cola ni se reutiliza la cola Firestore
de clientes. El envelope firmado contiene los bytes PDF una sola vez. Se elige Data dentro del store para permitir
aceptación atómica con sus metadatos; no se añade un archivo sidecar cuya coordinación requiera otro protocolo.
Sin relaciones obligatorias nuevas hacia las tablas antiguas ni cambios de ClientRemoteRecord/ClientConsentReference.

La etapa propuesta es lightweight1.0.0→2.0.0: solo añade tablas vacías y no transforma filas anteriores.
Su viabilidad se demuestra con store raw representativo, migración y segunda reapertura antes de cambiar
Schema.franAlonso y la composición productiva. Se amplía PhaseFiveSchemaMigrationPlan manteniendo origen y orden.
Las aserciones históricas de una versión/cero etapas se actualizan al nuevo contrato; se conserva la prueba real del
origen1.0.0. Un origen desconocido o payload Codable de versión desconocida falla cerrado; sin reset ni fallback.
No se crea documento ni autorización a partir de una referencia antigua, ni se toca el texto de snapshots históricos.

Data tendrá un propietario transaccional @ModelActor para documentos. Las escrituras que incluyan ficha y borrador
usan el mismo ModelContext y una primitiva sin save intermedio para mapping/cola de cliente, extraída del adaptador
actual solo si hace falta. Save explícito, contexto limpio y rollback ante error; ningún await dentro de la aceptación
local. Una revisión esperada del borrador impide sobrescribir ediciones o aceptar renders obsoletos tras una suspensión.
Dos intentos simultáneos de aceptación revalidan el estado antes del save. Modelos vivos y contextos no cruzan actores.

Se mantiene el binding Keychain de ADR0021. SwiftDataStorePristineDataSource debe consultar también cada nueva tabla;
un store con solo borrador, documento o recibo impide reclamarlo como vacío. Las capacidades de lectura/escritura/envío
reciben autorización de principal y cancelación verificables; un resultado tras logout/reemplazo no concede acceso
ni se publica como completado para otra sesión. No añadir otro mecanismo de login, particionado o recuperación Keychain.

## Repositorio Storage y límites remotos

Contrato independiente de Firebase: clave estable derivada de principal opaco/documentID, documento completo,
resultado con recibo estable y errores neutrales. Nada de nombres, email, tinta, PDF, tokens o URLs privadas en logs.
El contrato exige creación inmutable y comparación del payload completo: crear si falta, devolver el mismo recibo si
coincide, conflicto si difiere. El fake actor permite modelar concurrencia, denegación, indisponibilidad, cancelación y
aceptación remota con respuesta perdida. Su almacenamiento se comparte entre instancias del repositorio en las pruebas
de reinicio; recrear repositorios/actores locales no debe borrar el remoto simulado.

08.6 implementa el repositorio neutral, coordinación local y fake inyectable; no un adaptador Firebase live.
FirebaseStorage ya está enlazado, pero no existe adaptador ni contrato de Rules Storage aceptado que demuestre
compare-and-create atómico. Leer metadata y luego sobrescribir no cumple la inmutabilidad frente a dos escritores.
El futuro adaptador necesitará probar esa garantía con primitivas/reglas adecuadas antes de activarse; un fake verde
no acredita backend, reglas, permisos reales, token freshness ni preparación productiva.

## Áreas previstas y alternativas

- Features/Clients/Domain: borrador y estados recuperables, contratos Repository, capacidades de guardado/recuperación
  y UploadConsentUseCase. Se reutilizan los valores documentales08.5 y el renderer existente.
- Features/Clients/Data: dos modelos, primitivas locales, actor de persistencia, repositorio y fake de Storage.
  Ajuste focal de la primitiva actual de cliente si la aceptación conjunta lo necesita; nada de refactor CRUD general.
- App/AppModelSchema.swift y PhaseFiveSchemaMigrationPlan.swift: nuevo schema/etapa, composición tras gate de migración.
- Authentication/Data/Adapters/SwiftDataStorePristineDataSource.swift: nuevas tablas en la comprobación de seguridad.
- FranAlonsoTests: migración/reapertura, persistencia documental, repositorio/upload, autorización y regresión afectada.
- docs/Progress.md y docs/progress/phase-08.md: estados, evidencia, fuentes, límites y siguiente puerta.

Se descartan ampliar ClientModel con firma/PDF (mutaría baseline y mezclaría histórico con ficha), guardar solo una
referencia/receta de render (perdería bytes históricos), archivo externo independiente (doble commit/limpieza), guardar
con varios actores y saves (posible aceptación parcial) y upload directo desde UI (sin recuperación independiente).
Dos modelos independientes y envío en la fila documental mantienen el cambio aditivo y su unidad de recuperación.
Un límite de tamaño arbitrario o externalStorage no se añade por intuición; se medirá con PDFs sintéticos ya existentes
y documento largo. Si hace falta otra estrategia durable, se revisa esa decisión antes de implementarla.

Fuentes Apple consultadas el13/09/2026:
[MigrationStage](https://developer.apple.com/documentation/swiftdata/migrationstage) ofrece etapas lightweight/custom;
[ModelContext.transaction](https://developer.apple.com/documentation/swiftdata/modelcontext/transaction(block:))
guarda cambios al terminar su closure. Ambas APIs están disponibles desde iOS17. La propuesta de migración aditiva
es una elección del proyecto, cuya seguridad se probará; la documentación no acredita nuestra matriz de datos.

## TDD y validación

Swift Testing con oráculos sintéticos independientes, reloj/IDs/errores inyectados y capacidades de producción reales.
Containers in-memory para errores focales; stores temporales en disco para reinicio y migración. Sin servicios live.

1. RED/GREEN de guardado y reapertura antes de firma, después de firma y antes del PDF; conserva ficha, texto, tinta
   y fecha. Cambio relevante invalida y render obsoleto no se acepta. Guardado fallido no deja ficha/cola/borrador parcial.
2. RED/GREEN de aceptación documental: mismo valor no duplica; mismo ID/payload distinto entra en conflicto y conserva
   original. Reinicio tras aceptación recupera exactamente bytes; un renderer que falle si se invoca prueba ausencia
   de regeneración durante reintento. Se prueba cancelación antes y después del punto durable sin falsos éxitos.
3. RED/GREEN del pipeline local→Storage fake→recibo: offline, permisos, reintento, concurrencia, respuesta perdida,
   fallo al guardar recibo y reinicio antes/después de subida. Repetir conserva una sola identidad/documento/recibo;
   discrepancia en el recibo se rechaza. Ninguna transición activa clientes ni sustituye consentimiento previo.
4. Raw1.0.0 con las28 tablas, cliente activo con referencia antigua, borrador y operaciones pendientes/conflictos/retry
   representativos. Migración2.0.0 conserva cada valor y payload previo; nuevas tablas vacías, segunda reapertura estable.
   También reapertura2.0.0 con documento/borrador/recibo pendientes y origen desconocido sin apertura destructiva.
5. Solo una fila de cada tabla nueva impide claim; principal diferente, binding ausente con datos, error Keychain,
   logout/reemplazo y resultados tardíos deniegan acceso. Fallos no emiten payloads a logs ni telemetría.
6. Tras pruebas focales, regresión CRUD/documentos/sesión y suite completa por cambio transversal de schema según
   ADR0018; build y lectura del log completo por Xcode MCP. Auditoría independiente de estándares, diff y gobernanza.
   UI/previews/AT N/A: no se toca Presentation ni se repiten pruebas físicas de firma aceptadas.

## Riesgos, reversibilidad y gate

Riesgos: forma histórica alterada accidentalmente, pérdida de bytes tras crash, confirmación remota incierta,
resultado asíncrono obsoleto, aceptación parcial, consumo de memoria de PDF y claim incorrecto de un store con documentos.
Los casos anteriores son puertas de implementación, no resultados ya probados.
Antes de migrar datos, los cambios de rama son reversibles; después de abrir2.0.0 no se promete downgrade ni se borra
el store para revertir. Se mantienen orígenes soportados y sus datos. No cambia target, dependencias o aislamiento unsafe.

Excluidos: lector/firma integrados y ClientConsentStore08.7, activación08.8, fotos/retirada/limpieza remota08.9,
Firebase Storage live, motores, Rules, revisión jurídica y cierre de08.4. Sin commits, push, PR, merge o cierre Linear.
La propuesta concreta de schema y contrato remoto se revisa antes de código, como pide ADR0028.

Revisión PRE independiente por agente nuevo `proposal086_pre`: PASS técnico acotado, sin hallazgos.
Contrasta propuesta/diff, autoridad, código afectado, fuentes Apple y evidencia nativa de baseline.
Root verifica digest idéntico antes/después de477 rutas tracked y untracked no ignoradas, ordenadas,
path+NUL seguido de SHA256 binario del contenido (MISSING para tracked eliminado):
`796c6f3db687fdf9fe0b1cd23b6e53acc89172469af658f2b9eaa0054f060e29`.
Revisión operacional sin escrituras/publicaciones ni build/tests/previews. Diff limpio; gobernanza conserva solo
los seis enlaces históricos08.3. No acredita implementación, migración ejecutada, backend ni cierre08.4.
La aprobación recibida comprende únicamente esta implementación08.6; su evidencia se conserva en fase08.
