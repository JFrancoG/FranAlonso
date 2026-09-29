# Propuesta 08.8 — Activación inicial recuperable

Fecha: 2026-09-29. PLU-42, hija de PLU-34. Inicio e implementación autorizados por el propietario:
«Abre issue y rama e implementa 08.8». PRE independiente PASS antes de código, con 519 rutas idénticas antes/después.

## Estado y autoridad

Rama `codex/plu-42-phase-08-8-client-activation` desde main/origin/main limpio en `70905c2`.
PLU-41 Done funcional, PR #14 integrada. PLU-38 y PLU-44 conservan sus pendientes; fase 08 abierta.
Spec 08 y ADR 0002/0006/0009/0011/0018/0021/0028/0029 gobiernan este cambio. Sin nueva excepción arquitectónica.
Xcode MCP estable: workspace-EYu6rxi7hg, Develop; iOS mínimo 26, SDK 27.0, Swift 6, aislamiento nonisolated,
concurrencia completa y warnings Swift/Clang como errores. Destino inicial iPhone 11, a restaurar tras Simulator.
Baseline inmediata: 1.067 resultados PASS, retest 2/2, build 6,685 s con aviso AppIntents; seis enlaces históricos
rotos de 08.3. El cierre documental posterior no modificó ejecutables. No se repite baseline por rutina.

## Comportamiento exacto

1. Conservar `accept` y `UploadConsentUseCase` como operaciones documentales que no activan por sí solas.
2. Añadir capacidad Domain `ClientActivationRepository` con preparación y activación por `clientID`, `documentID`
   y `operationID`. La implementación Data usa el actor documental compartido, acceso por sesión/principal y señal local.
3. `ActivateClientUseCase` orquesta preparación durable de `consentPendingUpload`, upload existente y activación.
   Se llama por intención explícita del flujo retenido. Consultar, recuperar o abrir una ficha no escribe activación.
   Cada mutación usa un ID de operación distinto; repetir un payload ya aplicado no crea otra operación causal.
4. Preparación y activación vuelven a resolver documento y cliente dentro de una transacción síncrona del actor.
   Validar identidad de cliente/documento, finalidad inicial, ausencia de tombstone/conflicto y sesión autorizada.
   Activar exige estado uploaded y recibo correlacionado con principal/documento; conflicto con recibo sigue rechazado.
5. Activar conserva los campos actuales del cliente y fija `active(reference)` con la referencia durable inicial.
   Misma referencia ya activa es éxito sin escritura; referencia diferente se rechaza. Documento posterior de fotografía
   no activa ni sustituye la referencia. No resucitar clientes ni sobrescribir ediciones confirmadas durante el await del upload.
   El actor documental no aporta exclusión global frente a commits simultáneos de otros contextos CRUD.
6. Si falla la subida, conservar pending y firma/PDF. Si falla la activación, conservar recibo subido y reintentar solo
   la transición local. Reabrir tras upload ofrece «Finalizar alta»; un cliente activo muestra confirmación de alta.
   La fachada actualiza el cliente cargado con el resultado persistido sin perder ediciones de formulario sin guardar.
7. UI: intención existente de envío, estado pendiente/activo y acción de finalización/reintento localizada. Mantener
   controles nativos, lectura del documento, escalado y coordinación accesible existente. No reescribir foco 08.7.
   La confirmación exige correlación entre recibo seleccionado y referencia activa; otros documentos muestran un
   estado neutral sin reactivar. Recuperar adopta el cliente durable y mantiene separadas las ediciones locales.
8. Composición normal sigue usando Storage no disponible. Tests y previews usan almacenamiento simulado ya existente;
   ningún recibo falso se incorpora a la composición normal ni se activa un motor/servicio real.

## Ámbito de archivos

- Nuevos contrato/UseCase Domain y repositorio/extensión de activación Data; reutilizar `stagePendingUpsert`.
- Servicios y Store de consentimiento, fachada de formulario, feedback/acciones y composición App/previews.
- Localizable.xcstrings y tests de activación, recuperación, formulario/composición afectados.
- Progress, registro de fase y evidencia accesible del flujo actualizado con deuda vinculada conforme ADR 0029.
- Sin cambios de schema/modelos persistentes, migración, transporte Firebase, reglas, fotos 08.9 o siguiente fase.

## Alternativas y riesgos

Activar con `ClientRepository.saveClient` desde el Store permite snapshots obsoletos y carece de validación durable;
se descarta. Hacerlo dentro de upload acopla documentos posteriores y rompe el contrato existente; se descarta.
Extender ClientDocumentRepository con activación mezcla dos capacidades, obliga a todos sus dobles y contradice su
contrato; se prefiere capacidad estrecha nueva con el mismo propietario transaccional. No hay nuevo actor global.
No se añade scheduler ni arranque automático: la recuperación explícita es determinista y conserva autorización.
Riesgos: cancelación tras commit, cambio de sesión, perfil concurrente, documento de otro cliente, fallo de save y dos
activaciones solapadas. El resultado de una operación revocada no se presenta; el trabajo durable se reconcilia al abrir.

## TDD y validación

- RED focal con API mínima antes de implementación: recibo durable→active, reinicio tras upload y fallo/reintento local.
- Pipeline real Domain/Data con ModelContainer aislado y oráculos de estado/cola/documento desde contexto independiente.
- Reapertura de store en disco entre upload y activación; no confundir actor nuevo en memoria con reinicio durable.
- Doble activación no duplica causal upsert/documento; otra referencia, propósito posterior, recibo ausente/ajeno,
  conflicto y cliente desactivado rechazan. Perfil vigente se conserva; fallo save revierte transición y cola.
- Dos formularios: completar edición mientras upload está suspendido; verificar perfil y cola desde otro contexto.
- Store/fachada: offline→pending, uploaded→finalizar, reintento sin red/render/firma, campos editados conservados y
  cancelación/logout sin aplicar resultado obsoleto. Regresión de documentos, CRUD, composición y suite final por MCP.
- Build y logs completos por Xcode MCP. Previews representativas Large/XXX Large/AX5 de pendiente/activo/error;
  revisión independiente de estándares/estilo y UI. Matriz exhaustiva/manual diferida y registrada según ADR 0029.

## Fuentes primarias

Apple consultado mediante Cupertino el 29/09/2026:
- [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor): acceso aislado del contexto; no garantiza
  exclusión entre actores distintos. Se reutiliza el propietario documental y la transacción existente sin suspensiones.
- [ModelContext.rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()): revierte cambios
  pendientes al último estado confirmado. El test de fallo save verifica que no queda estado/cola parcial.

## Entrega

Implementar y validar está autorizado. Commit, push, PR, merge, cierre de PLU-42, 08.9 y live permanecen puertas separadas.
Implementación local y TDD completados; [fase08](phase-08.md) conserva los resultados finales. Revisión POST detectó
dos P2 de recuperación/correlación UI, reproducidos con RED3/4 y corregidos tras PRE focal favorable.
La deuda accesible nueva se registra en PLU-45 según [evidencia08.8](../accessibility/evidence/08-8-client-activation.md).
