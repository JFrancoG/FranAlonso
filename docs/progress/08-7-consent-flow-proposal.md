# Propuesta 08.7 — Lectura, revisión y firma

Fecha: 2026-09-13. Issue: [PLU-41](https://linear.app/plusprojects/issue/PLU-41), hija de PLU-34.
Estado vigente 29/09/2026: implementación publicada en rama; PLU-41 In Progress, pendiente de integración. ADR 0029
separa la validación accesible aplazada en [PLU-44](https://linear.app/plusprojects/issue/PLU-44), obligatoria tras
feedback/UI estable y antes del primer candidato para uso real. La validación funcional sigue en PLU-41. El alcance
y evidencia históricos inferiores se conservan; las disposiciones de cierre integral se leen con
[ADR 0029](../ADRs/0029-progressive-accessibility-validation.md).
PRE PASS y autorización «Si, adelante» del13/09; POST/retests técnicos PASS, detalle en phase-08.md.

Preparación autorizada el28/09 con «ok, adelante»: instrumentación temporal retirada y esquema Develop restaurado;
smoke funcional focal favorable. La revisión detectó aceptación de un nombre obsoleto si otra ventana lo cambia
durante render. PRE de corrección favorable: comprobar el nombre vigente en la nueva aceptación atómica,
devolver conflicto recuperable y mantener tanto campos no presentados como históricos aceptados. Dos pruebas
integradas reproducen el fallo y sus límites; RED→GREEN, suite final 1.067/1.067 y build PASS6,685s.
Sin nueva arquitectura, schema, UI ni ampliación de08.8. Revisiones finales favorables; PR/merge pendientes;
evidencia completa en [fase08](phase-08.md).

## Estado reconstruido

- Rama `codex/plu-41-phase-08-7-consent-flow`, creada desde `main` limpio en
  `b8a3d47d091bc75ea9faa866d3190afcd8c27fdd`; remoto main consultado y coincidente.
- 08.6 / PLU-40 Done, PR #13 integrada; dependencia de entrega satisfecha. 08.4 / PLU-38 conserva sus pendientes
  propios de redimensionado durante trazo y medición del contraste nativo. No se repiten pruebas ya aceptadas.
- Xcode MCP conectado a FranAlonso, `windowtab-QTPhkgjxly`, `FranAlonso-Develop`,
  iPad Air 11-inch (M4)/26.5. Settings consultados por MCP: iOS mínimo 26, Swift 6, concurrencia completa,
  aislamiento por defecto nonisolated, warnings Swift/Clang como errores; SDK de simulador 27.0 ya seleccionado.
  No se cambia toolchain, target, esquema ni destino.
- Baseline nativa de 08.6 releída con `xcresulttool`: 770 declaraciones, 1.020 resultados por destino,
  cero fallos/omitidos. Bundle cerrado:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunAllTests/Test-FranAlonso-Develop-2026.09.13_20-39-26-+0200.xcresult`.
- Último GetBuildLog confirma build correcto; log completo conserva el warning conocido de extracción AppIntents.
  El build de cierre registrado duró 6,993 s. Desde `32e314c` solo cambió documentación.
  No se ejecutan nuevos builds/tests por esta preparación documental, ni se atribuye CI/Production/live.
- Gobernanza inicial: seis enlaces históricos rotos en la evidencia de 08.3; ningún hallazgo nuevo atribuido a 08.7.

## Autoridad y fuentes

Constitución, spec 08 y ADR 0002/0006/0009/0011/0018/0021/0022/0027/0028. ADR 0028 concreta el contenido y la
autorización opcional; ADR 0009 conserva la activación posterior. La política Swift propia y DEVELOPMENT_GUIDE
gobiernan implementación y validación. No hace falta una nueva excepción arquitectónica para el alcance propuesto.

Fuentes Apple consultadas mediante Cupertino el 13/09 (documentación indexada, contrastada con SDK/proyecto):

- [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app):
  Observation rastrea propiedades leídas, también mediante objetos anidados. Permite compartir el Store propiedad del
  ViewModel sin copiar su estado; la separación concreta por capas la impone ADR 0011.
- [VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover): títulos, encabezados, agrupación,
  orden y comunicación de cambios. Se aplican al lector nativo; la corrección final requiere evidencia runtime.

## Comportamiento propuesto

1. El formulario ofrece consultar la información desde el principio, sin exigir un nombre válido para leerla y sin
   persistir por abrir el lector. Ese contenido informativo aún no es el snapshot personal fijado para firma.
2. Guardar borrador conserva el guardado CRUD existente. Una acción diferenciada de revisión y firma valida la ficha,
   prepara el snapshot personal y guarda ficha+borrador mediante una única operación documental. No cierra el formulario
   como hace hoy el guardado simple. No se invocan CRUD contextual y guardado documental para la misma mutación.
   Una vez existe trabajo documental pendiente, también Guardar borrador usa su pipeline para invalidar/revisar el
   snapshot cuando proceda. La fachada serializa todas las mutaciones de formulario y Store. Se conserva el estado
   del cliente cargado: una ficha activa mantiene edición CRUD e información, sin iniciar otro alta/documento inicial;
   la autorización posterior de foto corresponde a 08.9. Entregas aceptadas conservan consulta/reintento inmutables.
3. `ClientFormViewModel` crea y conserva un `ClientConsentStore` `@Observable @MainActor` durante su sesión.
   Posee las intenciones públicas y la fachada del formulario; Store es la autoridad del recorrido documental,
   sin duplicar firma, snapshot, documento o estado de envío en el ViewModel ni en las Views.
4. El lector nativo muestra título, secciones y texto íntegro del snapshot que se firmará. El avance se decide con
   una acción explícita de revisión, nunca por scroll, tiempo transcurrido o supuesta prueba de lectura.
5. La composición normal usa la variante sin foto y no muestra referencias a imágenes. Fixtures deterministas
   proporcionan contexto de foto para validar la otra variante: autorización inicialmente desmarcada, aceptación
   explícita o rechazo/retirada que permite continuar con la variante sin foto. No hay selector ni subida real de foto.
6. Se reutiliza `ClientSignatureCaptureViewModel` y su pantalla 08.4. Confirmar tinta fija la firma al snapshot y fecha
   actuales, y guarda ese borrador antes del render para poder recuperar tras cierre. Cancelar captura descarta solo
   la tinta de esa captura y vuelve a revisión, conservando la ficha y cualquier estado durable anterior.
7. La revisión de firma conserva acceso al texto exacto y permite volver a editar. La aceptación final genera y
   conserva el PDF mediante `RenderAndPersistConsentUseCase`; muestra resultado o error recuperable. No es activación.
8. Cambiar datos incluidos en el documento, contenido, variante, idioma o decisiones invalida firma/fecha pendientes;
   un documento distinto obtiene un ID nuevo y obliga a revisar. Datos de ficha no incluidos no invalidan por sí solos
   una firma cuando el snapshot presentado sigue siendo idéntico. Ningún histórico aceptado se sobrescribe.
9. Salir del recorrido cancela trabajo pendiente y cierra presentación; nunca promete deshacer una escritura aceptada.
   Las ediciones posteriores al último guardado tienen confirmación de descarte cuando corresponda. El trabajo durable
   válido se recupera al reabrir. Descartar un borrador es una intención separada y explícita: no borra la ficha ni cola,
   y no se ofrece sobre documentos aceptados. No hay limpieza automática ni borrado de históricos.
10. Errores de carga, guardado, render, autorización, conflicto y envío muestran causa de producto y acción pertinente.
    Un recibo durable permite reutilización sin red; un conflicto terminal no se presenta como reintento transitorio.
    08.7 no convierte a `active`, no fija la referencia inicial ni implementa `ActivateClientUseCase` (08.8).

## Recuperación e identidad

- `destination.id` identifica una sesión de formulario, no un borrador durable. Se descubren borradores y entregas
  mediante `clientID`, y se reutilizan `draft.id`, revisión, snapshot, binding, fecha y artefacto existentes.
- `PrepareClientDocumentUseCase` crea un UUID en cada invocación. Solo se invoca al preparar contenido nuevo o
  cambiado; consultar/reabrir el mismo texto reutiliza su snapshot. NIF/dirección no están en el snapshot actual:
  no invalidan la firma mientras no cambie ningún dato efectivamente presentado.
- `drafts(clientID:)` devuelve también borradores aceptados y ordena por UUID: no existe semántica de «último».
  Se cruzan con `deliveries(clientID:)` por `snapshot.id`. Un único borrador no aceptado puede reanudarse; varios
  requieren elección explícita con metadatos legibles, sin elegir por `.first`/`.last`. Los aceptados son inmutables.
- Un documento aceptado se muestra desde su entrega y bytes conservados, sin reconstruirlo desde el catálogo actual.
  Si el catálogo vigente cambió durante trabajo pendiente, revisar una versión nueva invalida la firma; una recuperación
  sin cambios conserva el snapshot firmado original. No se adopta una versión nueva silenciosamente.
- Se respeta el control de revisión de 08.6 y sus IDs retirados. Un conflicto o respuesta obsoleta provoca recarga y
  explicación, nunca sobrescritura. Dos ventanas no pueden aceptar una revisión documental ya invalidada.
- La ficha cargada y el perfil del borrador recuperado se reconcilian explícitamente: si difieren, se presentan como
  revisión pendiente y no se salva una copia antigua sobre cambios más recientes sin decisión de la persona.

## Fronteras y composición

| Área | Cambio previsto |
|---|---|
| Clients/Presentation/ViewModels | Extender ClientFormViewModel con dueño del Store e intenciones; coordinar carga, revisión, cierre e invalidación. |
| Clients/Presentation/Stores | Nuevo ClientConsentStore; estado de flujo, operación en curso, recuperación y errores semánticos. |
| Clients/Presentation/Screens y Views | Lector, revisión y selección recuperable; integración en ClientFormScreen; una View por archivo y preview determinista. |
| Clients/Domain | Reutilizar catálogo, snapshot, draft y UseCases 08.5/08.6; pequeñas políticas puras de selección/invalidación si aportan una invariante real. |
| Clients/Data/Documents | Reutilizar actor, repositorio autorizado, renderer y envío neutral. Adaptación puntual solo si una prueba de integración demuestra un hueco. |
| App | Componer capacidades documentales por container y sesión; ampliar AppDependencies+ClientForm, runtime y raíz autenticada según sus responsabilidades. |
| Resources/Localizable.xcstrings | Copy del flujo y errores; texto jurídico continúa en el catálogo versionado Resources/Legal, sin duplicación ni modificación jurídica. |
| FranAlonsoTests | Store, fachada/formulario, composición autorizada, recuperación, concurrencia y regresión afectada con Swift Testing. |
| docs | Progress, fase08, propuesta y matriz accesible específica del lector/flujo. |

Las pantallas se apoyan en una fachada ViewModel `@Observable @MainActor`; ninguna Screen recibe únicamente un Store
como sustituto del ViewModel obligatorio. Reutilizar la fachada de formulario donde sea la misma sesión; extraer otra
solo si existe una pantalla con responsabilidad propia, sin copiar el estado documental.

App posee un único `ClientDocumentPersistenceActor` por container, comparte la señal existente de clientes y compone
`DefaultClientDocumentRepository`, renderer y UseCases. No se fabrica un actor por cada sheet. El guardado documental
usa su actor y valores Domain; las mutaciones CRUD del contexto principal conservan la closure efímera ADR 0011.
No se conserva ni se cruza un `ModelContext` hacia el Store/actor, ni Data importa Presentation.

La fábrica actual nace antes que `AuthenticationRootViewModel` y aún no recibe autoridad documental. Se ampliará su
composición para capturar una `AuthenticationSession` autorizada junto con `localAccessRevision` y un validador que
consulte la raíz vigente en MainActor. `ClientDocumentAccess` validará la sesión antes/después del authorizer existente.
Logout, bloqueo, cambio de principal o una nueva revisión revocan la capacidad anterior, también al volver la misma
cuenta. No basta con cerrar una sheet ni comparar únicamente UID. No se cambia la política de autenticación.
La pérdida de acceso cancela tareas y limpia las copias visibles de perfil/snapshot/firma del recorrido revocado.

Las tareas de pantalla se cancelan al salir y cada respuesta se contrasta con generación/revisión del recorrido.
Cancelar no deshace commits durables ya aceptados ni elimina el artefacto. El render pesado permanece en Data.
Tras cancelar con una escritura/envío en vuelo, se reconcilia el resultado durable antes del siguiente intento.
No hay GCD, escapes unsafe ni dependencias nuevas.

El Storage de composición normal queda explícitamente no disponible mientras no exista gate live: conserva pendiente,
sin producir recibos ficticios ni tráfico. El fake capaz de confirmar envíos se limita a tests/previews/fixture aislada
sin datos reales. Se prueba la orquestación de `UploadConsentUseCase` y su recuperación; no se activa un motor remoto.
El cliente conserva los estados permitidos por el pipeline actual y ninguna ruta 08.7 inventa activación.

## Alternativas

- Ampliar todo en ClientFormViewModel: mezclaría edición de ficha con un ciclo documental recuperable; se elige Store
  por responsabilidad cohesiva aprobada en la spec, con una sola autoridad de estado.
- Usar PDF/WebView como lector: dificulta la lectura nativa requerida; se elige texto SwiftUI derivado del snapshot.
- Regenerar al recuperar o escoger el último UUID: rompería la identidad/historia; se recuperan los valores persistidos
  y se pide elección únicamente si existe ambigüedad real.
- Activar al guardar o simular subida en composición normal: no cumple las fronteras de 08.8 y del gate live.

## TDD y validación prevista

1. RED/GREEN del Store: información sin datos válidos; sin foto; aceptación/rechazo/retirada en fixture; recorrido
   revisión→captura→firma→persistencia→render; doble pulsación; cancelar desde cada etapa y errores recuperables.
2. Invariantes: texto mostrado igual al snapshot renderizado, revisión explícita, ningún bloqueo por scroll/tiempo;
   cambios incluidos invalidan, cambios no incluidos conservan; binding/fecha antes de render; nuevo ID al cambiar texto.
3. Recuperación con nuevo Store y repositorio: reinicio antes/después de firmar/render/aceptar/enviar, mismo ID/bytes,
   múltiples borradores y entrega aceptada, perfil concurrente, conflicto terminal, permisos/offline y recibo cacheado.
4. Composición: actor compartido, una escritura ficha+borrador+cola, señal de listado, cierre obsoleto, dos formularios,
   principal distinto, logout/login de la misma cuenta, bloqueo y respuesta tardía durante lectura/render/upload.
5. Regresión de CRUD, firma, catálogo/render/persistencia, principal y autenticación. Suite global final proporcional
   al cambio transversal en composición; builds/diagnósticos completos solo por Xcode MCP. Registrar fallos/resultados
   reales, sin confundir parámetros con declaraciones ni repetir validaciones ya verdes sin un cambio que lo justifique.
6. Previews deterministas de cada View con trait compartido: vacío/carga/revisión/firmado/pendiente/error/recuperación,
   ambas variantes de contenido, texto largo y RTL. Descubrir y usar Large, XXX Large y AX5 soportados; Light/Dark,
   contraste y tamaños iPad. Copy de controles en xcstrings; legal desde catálogo/snapshot con su idioma fijado.
7. Matriz ADR0022 del lector y flujo: encabezados/rotor, lectura íntegra, etiquetas/valores, foco ida/vuelta de firma,
   errores/anuncios, VoiceOver, Voice Control, Switch Control y FKA aplicables; 44pt, preferencias, orientación y ventana.
   Runtime con iPhone14 físico o iPad, sin iPhone17. Reutilizar evidencia intacta de captura; probar las transiciones nuevas.
8. Revisores POST nuevos de estándares y accesibilidad, read-only con huellas pre/post. No cerrar 08.7 mientras falte
   evidencia propia aplicable; pendientes PLU-38 separados y visibles. No declarar accesibilidad de PDF por el lector.

## Límites, riesgos y reversibilidad

Sin 08.8/08.9, foto real, publicación, activación live, nuevo schema/migración, cambios legales, dependencias, unsafe,
limpieza histórica, cierre PLU-38 ni entrega Git. Un hueco que exija esos cambios vuelve a propuesta antes de implementar.
Riesgos principales: pérdida por cierre, borrador ambiguo, doble persistencia, respuestas de sesión obsoleta y exposición
de contenido equivocado; los tests anteriores cubren cada frontera. La UI se puede retirar conservando íntegra la
persistencia 08.6; no se revierte borrando datos. Los textos jurídicos siguen pendientes de revisión antes de uso real.

## Revisión y aprobación

PRE independiente por el agente nuevo `proposal087_pre`: PASS sin hallazgos. Contrastó propuesta, rutas reales,
fuentes Apple y baseline nativa; no ejecutó código ni modificó/publicó archivos. Root verificó 499 rutas Git tracked
y untracked no ignoradas, ordenadas, con path+NUL y SHA256 binario del contenido (MISSING para ausentes), idénticas
antes/después: `bcdb3609b5bbc69dfe453358c9e0e5751f38c16712431a0509165a00a5919dba`.
Este resultado valida la propuesta, no acredita implementación ni runtime. La anotación de resultado y la
reconciliación de Progress/Linear son posteriores a esa huella, sin cambiar el alcance revisado.
El propietario autorizó implementar esta propuesta con «Si, adelante» el 13/09; entrega, cierre y siguientes subfases separados.

## Evidencia posterior

Implementada con Store, fachada, composición por sesión y lector nativo. La adaptación Data prevista fue necesaria
para impedir que confirmar firma reescribiera una ficha modificada en otra ventana; se acreditó RED/GREEN y revisión
independiente. PreviewModifier.makeSharedContext async prepara los datos antes de la captura del preview, conforme a
[documentación Apple](https://developer.apple.com/documentation/swiftui/previewmodifier/makesharedcontext()).
806declaraciones/1.059resultadosPASS; build de 15,651 s; veinte previews inspeccionadas y sin hallazgos de implementación
abiertos tras retests. Por límite de agentes, el mismo revisor POST independiente cubrió ambos ámbitos con skills
específicos; se registraron huellas pre/post. Esto adapta el plan original de dos revisores, sin atribuir identidades falsas.
La [matriz08.7](../accessibility/evidence/08-7-consent-flow.md) conserva pendiente la evidencia runtime nueva.
Sin entrega Git, cierre, activación ni foto real. Detalle de artefactos y límites en [fase08](phase-08.md).
