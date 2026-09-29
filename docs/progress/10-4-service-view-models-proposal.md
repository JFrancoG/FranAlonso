# Propuesta 10.4 — Estado de lista y formulario de servicios

Fecha:2026-09-29. [PLU-63](https://linear.app/plusprojects/issue/PLU-63), hija dePLU-59, Jesus Franco, In Progress.
El propietario autoriza implementar10.4 después de entregar10.3. PR26 MERGED/3a771c2, PLU-62 Done, rama eliminada;
main/origin/main0c98eae limpios e idénticos antes de abrir `codex/phase-10-4-service-view-models`.
Implementación autorizada dentro de spec10; PRE independiente antes de código. Entrega Git10.4 y10.5 no autorizadas.

## Autoridad, fuentes y baseline

Constitución, spec10/índice, política Swift, ADR0002/0006/0011/0015/0018/0029/0030. Perfil maintenance.
Xcode MCP estable confirma workspace-EYu6rxi7hg y configuración actual sin cambios: Swift6 estricto, target26/SDK27,
Develop/iPhone18Pro. Baseline10.3:1.030 declaraciones/1.436 resultados PASS, Develop con tests3,965s/Production20,291s,
PRE/POST PASS. Árbol integrado idéntico; nuevos builds/tests N/A en preparación documental. Aviso AppIntents y seis
capturas históricas08.3 ausentes conservados. API Decimal contrastada en documentación Apple mediante Cupertino:
[precision](https://developer.apple.com/documentation/foundation/decimal/formatstyle/precision(_:)) y
[decimalSeparator](https://developer.apple.com/documentation/foundation/locale/decimalseparator).
Product09.3 aporta el patrón concreto de generaciones, sesiones y closures contextuales; no copiar sus campos de stock.

## Contrato de lista

ServiceListViewModel @Observable @MainActor: idle/loading/empty/content([Service])/failed, query y resultados calculados
por SearchServicesUseCase, sin esconder tipos ni inactivos. Distinguir sin coincidencias de colección vacía.
load() observa snapshots mediante ObserveServicesUseCase durante la tarea del caller: fin sin valor→empty,
cancelación→idle y error→failed. Generación impide que un load reemplazado publique valor/fin/error. Sin Task en init.
ServiceFormDestination separa UUID de sesión, ServiceID y modo create/edit. Asignar IDs una vez por creación; abrir edición
solo para resultados visibles; apertura repetida no sustituye la sesión. Cierre tardío solo afecta su UUID coincidente.
UUID de navegación inyectable. No Sheets ni nuevas Views en esta subfase.

## Borrador y entrada decimal

ServiceFormDraft, valor Equatable de Presentation, reúne name, type, linkedProductID, priceText, currency, taxText,
discountText. Borrador inicial: nombre/precio/impuesto/descuento vacíos, profesional, sin vínculo, EUR. No suponer un
impuesto comercial por defecto. El formulario recibe Locale fija por sesión (default current, inyectable en tests).

Un codec concreto de Presentation interpreta números completos de entrada, sin Double, NSNumber ni tipos DTO/Data.
Gramática acotada para las localizaciones actuales ES/EN: espacios exteriores permitidos, signo menos opcional,
al menos un dígito ASCII entero y fracción opcional con al menos un dígito tras el separador decimal del Locale.
Permitir ceros iniciales/finales; rechazar agrupadores, otro separador, '+', exponentes, símbolos moneda/porcentaje,
entradas parciales, basura y pérdida de precisión. No aceptar un prefijo numérico de una cadena inválida.
Normalizar únicamente el texto (ceros y signo de cero), construir Decimal y comparar con su formato POSIX sin agrupación
con1...38dígitos significativos: si cambia el valor representado, rechazar. Después Money aplica su redondeo vigente a
unidades menores; se conserva el contrato10.1 de validar precio normalizado (cero válido, incluido -0.004→0).

Formatear al cargar con la representación exacta Decimal y separador de sesión, sin agrupadores ni conversión Double.
No perder fracciones altas de impuesto/descuento. Impuesto y descuento son puntos porcentuales0...100 por Domain.
Descuento vacío→nil; '0'→Discount(0). Errores de sintaxis/rango identifican price/tax/discount en un enum semántico
ServiceFormError de Presentation; errores Service se conservan en su caso service(ServiceError).
Nombre, precio comercial y relación tipo/vínculo se validan mediante PrepareServiceProfileUseCase y valores Domain.
No introducir reglas fiscales ni duplicar rangos/invariantes en Presentation. No corregir silenciosamente un vínculo
profesional inválido. La futura acción de cambio de tipo podrá limpiar su selección en10.5/10.6.

## Contrato de formulario

ServiceFormViewModel @Observable @MainActor recibe destination, GetServiceUseCase y closures create/update/deactivate.
State: idle/loading/editing/saving/deactivating/saved(Service)/deactivated/failed(Operation,ServiceFormError)/closed.
Operation load/save/deactivate. loadedService conserva última entidad aceptada. Sin Store: no responsabilidad adicional.
Estado semántico y errores sin cadenas visibles; localización/pantallas corresponden a10.5 y selector a10.6.

Crear empieza editing; editar empieza idle. Solo una lectura válida permite editar; ausencia/error de carga bloquea
escrituras y permite retry. Carga no reemplaza un borrador editable. Carga histórica no consulta disponibilidad Product:
se debe poder desactivar un Service aunque su producto haya desaparecido. canDeactivate exige edit+loaded active+canEdit.
canEdit permite retry tras fallo de mutación; éxito/cierre/carga fallida no son escribibles. hasUnsavedChanges compara
borrador completo con su baseline cargada o vacía, sin convertir cambios textuales inválidos en ausencia de cambios.

save(in:) captura y valida el perfil completo antes de await, invoca una sola closure y usa el Service aceptado al volver.
Bloquear envíos/desactivación superpuestos; conservar todo el borrador/ID tras error. Al corregir entrada inválida a perfil
válido puede limpiarse solo el error de validación local, nunca un fallo de persistencia/conflicto/vínculo indisponible.
ServiceError se conserva y errores desconocidos→service(persistenceUnavailable). No añadir preflight Product asíncrono:
la aceptación10.3 comprueba disponibilidad en el mismo contexto de escritura. Desactivar ignora borrador comercial
inválido y no guarda campos no confirmados. La intención de desactivación llega confirmada por el futuro caller.

Cancelación previa no delega; CancellationError de mutación vuelve a editing conservando borrador. Éxito local posterior
a cancelación sigue siendo éxito. close() limpia borrador/entidad e invalida generación sin fingir rollback del commit.
Resultados tras cierre y cargas reemplazadas se descartan. Caller posee las tareas; sin polling/sleeps/Task interno.

## Composición y archivos

SaveOperation @MainActor(ServiceID,ServiceProfile,ModelContext) async throws -> Service y DeactivateOperation
@MainActor(ServiceID,ModelContext) async throws -> Void. ModelContext efímero, sin almacenar ni cruzar actores.
AppDependencies+ServiceForm compone GetServiceUseCase sobre actor/señal existentes y closures capturando
ServiceContextualPersistenceAdapter. No invocar además el UseCase mutador context-free. Domain y Data intactos.
AppDependencies añade ServiceFormFactory/makeServiceForm a live, fixture y preview interactiva; snapshot preview
comparte repositorio finito y rechaza toda mutación antes de acceder al contexto. Ajustar callsites de tests necesarios.

Nuevos archivos Services/Presentation/ViewModels/{ServiceListViewModel,ServiceFormViewModel},
Navigation/ServiceFormDestination, Models/{ServiceFormDraft,ServiceFormError,ServiceDecimalInput} (codec si cohesivo).
App/AppDependencies+ServiceForm y cambio mínimo AppDependencies. Tests de lista/sesiones, formulario, entrada y composición.
Spec10, Progress, phase10 y propuesta registran contratos/evidencia. Sin Views, strings/resources, schema/DTO/sync/seed.

## TDD, validación, riesgos y alternativas

Escribir tests/API mínima compilable y registrar RED semántico antes de GREEN. Oráculos independientes; dobles por contrato,
streams/gates deterministas que se liberan también ante errores y contenedores aislados. No tests de pura estructura.
- Lista: contenido/vacío/error/fin/cancelación y reemplazo; query y nuevos snapshots; sesión estable y cierre antiguo.
- Entrada: ES/EN, exactitud alta, ausencia frente a0, redondeo Money, porcentaje límites, basura/prefijo/overflow/precisión,
  precio negativo, tipo/vínculo; carga/guardado sin editar preserva todos los campos exactos.
- Formulario: ausente/error/retry, borrador, captura previa a await, errores neutrales, bloqueo simultáneo, deactivación
  independiente del borrador, cancelación previa/cooperativa/tardía, cierre/reemplazo y protección de cambios.
- App real: create/update/deactivate contextuales, cadena causal/observación, rechazo de producto obsoleto, preview
  snapshot sin escrituras. Reusar matrices10.1–10.3 para datos en vez de duplicarlas.
Xcode MCP focal+regresión por impacto; global solo si selección omite variantes o alcance la justifica. Develop/Production,
logs completos/xcresult cerrado, estilo cambiado y POST independiente. UI/previews/a11y nueva N/A, deuda08/PLU54/57 intacta.

Alternativas descartadas: Store genérico o reutilizar ProductFormViewModel mezcla dominios; persistir desde ViewModel
incumpleADR0011; parser lenient/Double pierde datos; DTOdecimal en Presentation cruza capas; consulta Product previa no
sustituye aceptación y bloquearía históricos. Un codec de borrador tiene responsabilidad real por gramática y exactitud.
Riesgos principales: precisión/localización, campos inválidos silenciosamente descartados, sesiones/cancelación y
composición divergente. Retirar estas fachadas/factories revierte sin migración. No dependencia, unsafe, target nuevo,
UI10.5/selector10.6/picker10.7, IA, live ni ampliación de alcance. No se requiere ADR nuevo para aplicar estos contratos.


## PRE independiente

PASS sin hallazgos P0–P3. Reviewer/root verifican636 archivos idénticos antes/después, manifest
`/tmp/franalonso-10-4-pre1.json`, SHA256 `808a082063aed458d2614715936547c2b38b992a32936508de9ad89bce5bfcc8`.
Read-only operacional, sin builds/tests/escrituras. Implementación autorizada por la petición inicial; no nueva confirmación.

## Implementación y evidencia

Alcance implementado, RED/GREEN y builds registrados en [fase10](phase-10.md). 28 declaraciones nuevas/80 resultados;
global 1.058 declaraciones/1.516 resultados PASS. Domain/Data y configuración intactos. POST PASS sin hallazgos; 647 archivos idénticos antes/después.
Manifest `/tmp/franalonso-10-4-post1.json`, SHA256 `2de90204134fa7379d9d1b6765323fee8d0a53734a38ca1d6edbd13911a24df6`.
Entrega Git de10.4 y10.5 siguen pendientes de autorización; PLU-63/PLU-59 In Progress.
