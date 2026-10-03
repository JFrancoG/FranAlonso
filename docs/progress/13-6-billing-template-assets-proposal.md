# Propuesta13.6 — Plantillas validadas y firma privada opcional

03/10/2026, autorización «abre issue y rama e implementa13.6».
PLU-102 In Progress/Jesus Franco; `codex/plu-102-billing-template-assets`, baseline limpio
main/origin/main `d867fb133ce7d0b3fe34c914c0e415cba8ebc60d`.
Perfil maintenance, iOS27/Swift6 strict complete/default nonisolated; Xcode MCP27.0 estable Service,
workspace-PfnUYLlMzY, Develop/planDevelop/iPadPro13(M5). Sin cambios de configuración.

## Autoridad y situación

Constitución, spec13 fila13.6, ADR0008/0011 y guía/checklist. Spec13 y docs/legal/README fijan la firma/sello
como recurso privado fuera de bundle/Git, validado después de autenticar y cacheado con protección local;
su ausencia permite continuar sin firma. Esto no es una firma criptográfica ni certificación fiscal.
13.1–13.5 entregadas, PLU-101 y deuda previa abiertas. Baseline conservada:59casos nuevos/155afectados,
builds13.5 y auditorías PASS; global2581/2582 falla en Stock118 histórico intacto, sin causa atribuida.
No se repite ni modifica Stock para preparar esta subfase.

`DocumentTemplateResource` ya identifica los PDF ticket/factura y solo resuelve BundleURL. Tests previos
verifican una página A4; falta carga validada y error recuperable. PDFs actuales intactos: ticket3043B,
SHA2564d4efabdb58501a19274b40794ed3a8fb935112017ba67d1496b3df7d612ad14; invoice3236B,
SHA2567180f83a5ecdfc1e0126e40f8ac5182e5961405a3f02025360a9e8fd12073b80.
Catálogo legal08.5 y documentos históricos permanecen separados, sin extraer copy del PDF.
`BundleClientDocumentCatalog` demuestra Bundle inyectado/actorData/errores neutros/cancelación.
`AuthenticationRootViewModel.ProtectedAccessIdentity` identifica principal y revisiones local/autorización;
`makeClientDocumentAccess` demuestra revalidación alrededor del authorizer durable. No existe caché de firma.

## Comportamiento propuesto

1. Dos contratos Domain cohesivos: `BillingDocumentTemplateRepository` carga bytes PDF por
   `BillingDocumentKind`; `BillingBusinessSignatureRepository` carga bytes opcionales e importa bytes
   explícitos a la caché privada. Foundation/Data/errores propios, sin PDFKit/ImageIO/UIKit/SwiftData/Firebase
   en Domain. No se añaden modelos, UseCases, DTO ni protocolos de filesystem sin responsabilidad necesaria.
2. `BundleBillingDocumentTemplateRepository`, actorData con Bundle explícito, reutiliza los nombres de
   `DocumentTemplateResource`. Lectura acotada hasta1MiB+1byte, cancelación antes/después, bytes exactos.
   Rechaza ausencia/lectura fallida, bytes vacíos/corruptos/truncados, PDF cifrado/bloqueado, más/menos de
   una página, página inexistente, rotación o geometría incompatible. Política de plantilla: PDF con
   cabecera/terminador completos y página A4 portrait, origen0 y595.2756×841.8898pt con tolerancia0.5pt;
   PDFKit debe abrirlo y entregar la página. No se afirma integridad editorial, suficiencia fiscal ni PDF/UA.
3. `BillingAssetAccess` es una capacidad Domain con principal opaco y validación async explícita.
   Root compone una nueva capacidad Billing con la identidad vigente del shell, authorizer local existente
   y revisión antes/después de cada autorización. No se autoriza con UID arbitrario, bool ni currentUser.
   Logout, cambio de principal, mismo UID reautorizado, retry de observación y cancelación revocan acceso.
   Sin capacidad no se crea el repositorio privado; no cambia la semántica del acceso Clients.
4. `ProtectedLocalBillingSignatureRepository`, actorData, recibe capacidad y directorio privado
   compuesto en App bajo ApplicationSupport/BillingPrivateAssets, sin acceso al recurso real ni lectura
   en startup. Separa por SHA256 del principal, sin UID como segmento ni payload en logs. Rechaza symlinks
   y ubicaciones de bundle; no sigue enlaces en su directorio/archivo propios. No hay backend ni descarga.
5. Imagen permitida PNG/JPEG de una sola imagen: bytes1..2MiB, ejes1..4096 y máximo4194304píxeles.
   ImageIO comprueba tipo real, estado completo, dimensiones antes de decodificar y decodificación efectiva.
   Ningún CGImage/PDFDocument/FileHandle cruza actores. Validación de formato no acredita autenticidad
   visual/legal. Bytes preservados, sin reencode ni transformación de la firma.
6. Caché privada: FileProtection.complete y exclusión de backup en directorio y archivo, verificadas;
   ausencia de archivo devuelve nil tras revalidar acceso. Permisos/protección/formato fallidos devuelven
   error neutral recuperable, nunca bytes inseguros. Nil permite generación futura sin firma; no se oculta
   cancelación/revocación como éxito ni se incorpora ya esa decisión al renderer/UI.
7. Importación Data explícita y autenticada, sin nueva UI: valida antes de tocar la caché; prepara candidato
   protegido/excluido de backup, revalida acceso antes de publicar y reemplaza atómicamente el archivo propio.
   Sin await dentro del commit de filesystem. Rechazo/cancelación antes de publicar conserva el recurso
   previo y elimina candidato; una aceptación durable no se revierte por una cancelación observada después.
   Carga revalida acceso después de lectura/decodificación y antes de entregar bytes, incluso con respuesta
   tardía. Al fallar no se expone payload ni NSError/URL. Reinicio recupera la caché validada de ese principal.
8. Composición concreta App para futuras fases, sin activar consumidores de UI/Store ni alterar la venta,
   numeración, PDF o Jornada. La fábrica obtiene capacidad Root y ruta privada; tests usan directorios propios
   temporales y recursos sintéticos, nunca la firma/sello reales ni archivos privados del usuario.

## Áreas y alternativas

Domain: dos Repository, BillingAssetAccess y BillingAssetError. Data: dos implementaciones Repository,
validador de imagen y lector de archivos acotado si comparte la misma responsabilidad en ambos adaptadores.
App: método Root para capacidad Billing y composición AppDependencies+BillingAssets. Tests: plantillas,
caché/imagen/acceso y composición/Root; fixtures propios temporales/gates. Docs: propuesta, phase13, Progress.
No se modifica ningún PDF/catálogo legal ni el Shared resource enum, Store, formulario fiscal o proyecto.

- Solo resolver URL: no detecta corrupción/protección ni garantiza bytes válidos; descartado.
- Reutilizar ClientDocumentAccess desde Billing: acopla dominios distintos; se conserva su patrón en capacidad propia.
- Firma en bundle/Assets o constante: incumple privacidad; descartado. Keychain para la imagen completa no añade
  beneficio a este caché binario; se utiliza protección de archivos de plataforma y authorizer existente.
- Descargar de Storage ahora: activa un proveedor sin puerta live y amplía integración; excluido. La importación
  explícita permite validar/cargar/cachear el recurso con un origen reemplazable en una autorización futura.
- Biblioteca PDF/imagen, renderer o framework nuevo de persistencia: innecesarios; solo frameworks Apple existentes.

## TDD y validación

Swift Testing, oráculos independientes: PDFs reales conservados, PDFs negativos sintéticos, imágenes sintéticas
PNG/JPEG y archivos privados temporales. RED compilable de ausencia/válido/corrupto antes de implementación;
GREEN y regresión afectada. Rechazo de geometría/cifrado/tamaño/truncado; recuperación tras corregir recurso,
bytes exactos, ausencia de firma, protección/backup, principal distinto, importación inválida conserva anterior,
reinicio y gates sin sleeps para revocación/cancelación/respuesta tardía. Root real con session stream sintético,
authorizer inyectado y mismas revisiones que producción; no assert de forma ni tests que reflejen la implementación.

Auditoría estilo de todos los Swift nuevos/tocados, POST estándares independiente, Xcode MCP Develop y Production
con logs completos y pruebas afectadas. Se registra el resultado global que se ejecute sin convertir Stock histórico
en PASS. Configuración inicial restaurada; diffcheck/localizaciones/gobernanza y Progress≤8192bytes.
UI/previews/accesibilidad nuevos N/A por ausencia de pantalla/textos/recorrido visual cambiado; deuda previa intacta.
Protección comprobada por API en Simulator no demuestra bloqueo físico, copias reales ni seguridad integral.

## Límites y fuentes

Sin firma real/PII/secreto, red/Firebase/Rules/live, dependencia/unsafe/target/ADR nuevos, UI de importación,
renderer13.7/render13.8/numeración/Storage/correo/SwiftData13.10/cierre13.12 ni ajuste administrativo de series.
Commit/push/PR/merge/Done y siguiente subfase quedan fuera de esta autorización. Fase13/proyecto abiertos.

Apple oficial, consultado03/10/2026 mediante Cupertino MCP y contraste web cuando accesible:
[PDFDocument](https://developer.apple.com/documentation/pdfkit/pdfdocument),
[init(data:)](https://developer.apple.com/documentation/pdfkit/pdfdocument/init(data:)),
[FileProtection.complete](https://developer.apple.com/documentation/foundation/fileprotectiontype/complete),
[exclusión de backup](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup),
[reemplazo sin pérdida](https://developer.apple.com/documentation/foundation/filemanager/replaceitemat(_:withitemat:backupitemname:options:)),
[ImageIO decode](https://developer.apple.com/documentation/imageio/cgimagesourcecreateimageatindex(_:_:_:)),
[estado de imagen](https://developer.apple.com/documentation/imageio/cgimagesourcegetstatus(_:)).
Los cuerpos Cupertino soportan las APIs; web de Apple ofrece JS/Markdown y no todos los endpoints son extraíbles.
Disponibilidad/aislamiento se confirman compilando con el SDK conectado; no se deducen de snippets.

## Ajuste revisado por limitación de Simulator

La API real del Simulator devuelve nil en protectionKey y URLResourceValues.fileProtection pese a solicitar
.complete; backup=true. Logs18:22:29/18:23:34 muestran rechazo correcto signatureUnavailable.
PRE focal independiente PASS antes del ajuste;985archivos inicial/final/root
`32ea0aa7b3bf170da049cf85f9dc01cc4cd886897deff8b8c88fbf6bcdadb4ef`.
Se añade únicamente verificador de protección inyectable en Data. Default productivo exige fileProtection.complete,
deniega nil/none y App siempre usa el default. El doble explícito de tests no altera tipo/symlinks/backup,
autorización/imagen/filesystem/publicación. Protección física queda limitada/pendiente, nunca PASS por el doble.
[API oficial](https://developer.apple.com/documentation/foundation/urlresourcevalues/fileprotection) leída completa.

## Corrección P2 — Conservación ante fallo de publicación

POST original985/75f0ba418c48c264928d4022494e80a6888eb3ba5bf98a5a3fd05ab2b4701ba1 detecta que
replaceItemAt puede lanzar tras mover el original; neutralizar NSError permitiría nil en la siguiente carga.
No se considera fuera del contrato. Antes del ajuste funcional se revisa esta alternativa exacta:

- Adaptador privado inmutable Sendable; un actor Data compartido `BillingSignatureCacheCoordinator` aísla TODAS
  las operaciones de filesystem de todas las instancias/principales. No registry, lock, GCD, unsafe ni singleton mutable
  fuera de aislamiento. El actor es propietario cohesivo del acceso a este caché, no un Store de negocio.
  API mínima load(access, read closure) y publish(access, prepare, commit, discard closures), todas Sendable.
  load autoriza, ejecuta read síncrono, reautoriza antes de devolver. publish autoriza, prepara candidato único,
  reautoriza, ejecuta commit síncrono; discard queda dentro del mismo actor. Reentrancia en autorización permite
  otras operaciones, pero nunca intercalar backup/publicación/restauración/cleanup síncronos entre instancias.
- Prepare valida imagen/paths/directorios y candidato. Backup no se crea ni recupera antes de la última await.
  Commit revalida dirs/candidato, recupera primero cualquier backup pendiente y captura el recurso anterior vigente
  EN ESE MOMENTO; no un snapshot anterior al await que pudiera pisar el éxito de otra instancia.
- Backup conocido `.previous-signature`, bytes previos acotados≤2MiB, escritura atomic/complete, exclusión de backup
  y tipo/protección verificados. Durante commit no hay await. Luego replaceItemAt usando metadata nueva o primer
  move, verificación de destino y solo entonces eliminación del backup. Todos los archivos siguen privados.
- Backup existente es siempre recurso anterior autoritativo. Crash/fallo antes de eliminarlo no acepta una firma
  nueva incierta: load lee/valida backup y reautoriza, sin nil. Commit posterior restaura ese backup antes de importar
  otro candidato. Si falla publicación/verificación/cleanup, intenta restaurar desde backup mediante escritura atomic
  complete y metadata verificada. Backup se elimina únicamente tras restauración verificada; si falla, se conserva.
  Corrupción/metadata inválida/lectura fallida del backup lanzan error recuperable, no ausencia.
- No se leen ni mutan ubicaciones arbitrarias suministradas por NSError. Se preservan bytes previos independientes
  del comportamiento interno de Foundation; el error expuesto sigue neutral. Sin copia ilimitada ni payload/logs.
- Una seam síncrona solo para reemplazo con default FileManager real permite fallo determinista después de mover
  original fuera de su URL. App nunca sobreescribe protección ni reemplazo. Tests siguen usando filesystem real,
  backup/symlinks/formatos/autoridad reales; doble de protección se limita al Simulator conocido.
- Tests nuevos: failure tras mover original conserva bytes en carga/reapertura; rollback que no logra verificación
  mantiene backup autoritativo; import posterior recupera y publica; dos instancias de mismo principal/cache,
  primera suspendida en reautorización y segunda publica, fallo posterior de primera conserva la versión vigente
  de segunda. Se verifica ausencia de candidatos tras rechazo y backup protegido/excluido en recuperación pendiente.
  RED focal compilable antes del fix y GREEN completo después; builds y POST/estilo se repiten en ámbitos afectados.

La persistencia es solo recuperación del recurso privado13.6; no introduce DTO/store Billing13.10, UI, nuevos
proveedores/dependencias/ADR/opt-outs ni live. P3 de estilo se corrigen sin cambiar behavior ni fixtures originales.
