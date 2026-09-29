# Fase 08 — Clientes, consentimiento y foto

## Objetivo

Gestionar clientes, búsqueda, información inicial firmada y fotografía interna opcional, preservando trabajo offline.
La firma inicial se conserva como regla de producto para activar la ficha; la fotografía exige autorización separada
y opcional. El documento aplicable se lee antes de firmar y se conserva sin reescribir su contenido histórico.

## Prerrequisito de decisión

ADR 0009 y [ADR 0028](../ADRs/0028-client-signed-information-and-photo-authorization.md) aceptados.
ADR 0028 precisa el significado del documento inicial y la autorización posterior; conserva los estados de alta.
[ADR 0029](../ADRs/0029-progressive-accessibility-validation.md) permite separar la entrega funcional para demo de
08.7 y su validación integral de accesibilidad, sin cambiar contratos ni dependencias funcionales.
[ADR 0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md) añade la base de demo 08.8a y aplaza
08.9 hasta después del feedback de la demo, manteniendo su alcance y la fase abierta.

## Estado y responsabilidades

- `ClientListViewModel` coordina listado, búsqueda, selección y navegación.
- `ClientFormViewModel` es la fachada del formulario.
- Al incorporar firma, renderizado, subida, reintento y estados de activación, el ViewModel crea y conserva un `ClientConsentStore` `@Observable @MainActor` como responsabilidad cohesiva.
- El Store orquesta `RenderConsentUseCase`, `UploadConsentUseCase` y `ActivateClientUseCase`; no importa Firebase Storage ni PDFKit.
- El cliente usa estados `draft`, `consentPendingUpload` y `active`. Un borrador puede persistirse localmente sin red, pero no se activa hasta que el documento inicial firmado se haya subido y referenciado.
- La desactivación de 08.1 crea el tombstone del registro sincronizable definido
  por ADR 0006 y lo excluye de consultas operativas; no añade un cuarto
  `ClientStatus` ni elimina la referencia de consentimiento del payload
  conservado para sincronización e histórico.
- La foto es opcional y su fallo no invalida al cliente ni al consentimiento.
- La atomicidad y recuperación del alta siguen ADR 0009; el vínculo documento/firma y la foto posterior siguen ADR 0028.
- Una autorización de foto posterior no cambia `active` ni sustituye la referencia inicial. Su registro y envío son independientes.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 08.1 | Definir contratos y casos de uso CRUD/búsqueda. | Crear, editar, desactivar, buscar y errores. | UI observa SwiftData local. |
| 08.2 | Implementar `ClientListViewModel` y `ClientFormViewModel`. | Estados, validaciones, navegación y cancelación. | `@Observable @MainActor`. |
| 08.3 | Implementar listado, búsqueda y formulario. | Lógica ya cubierta en ViewModels. | Previews con 0, 1 y 80 clientes. |
| 08.4 | Captura efímera a mano alzada como valor inmutable, según ADR 0027. | Firma vacía, válida, cancelada; deshacer, borrar e interrupción. | View sin persistencia; cerrar únicamente evidencia propia y retirar acceso temporal. |
| 08.5 | Contenido común versionado, dos variantes, contrato de documento firmado y renderizado. | Correspondencia entre contenido presentado y PDF, decisiones, versión, invalidación de firma y artefacto estable. | Definir distribución del catálogo a lector/generador; texto real, trabajo pesado fuera de MainActor. |
| 08.6 | Persistencia recuperable del documento/borrador y repositorio Storage con fake. | Reinicio, offline, permisos, reintentos, duplicados, conflicto de ID/payload y migración. | SwiftData local-first; Storage encapsulado; schema versionado según ADR 0018. |
| 08.7 | Integrar lectura, revisión y firma mediante `ClientConsentStore`. | Sin foto, autorización/rechazo, cambio de contenido, cancelación, recuperación y errores. | ViewModel posee Store; documento fijado al firmar; entrega funcional PLU-41 y validación integral PLU-44 según ADR 0029. |
| 08.8 | Activación inicial idempotente tras upload. | Reinicio entre upload y activación; reintento sin duplicar documento ni alta. | Nunca activo sin referencia del documento inicial firmado. |
| 08.8a | Composición de demo reutilizable para el recorrido sin foto. | Selección exclusiva/fail-closed, aislamiento, escenario coherente y reset al relanzar. | Capas reales, datos en memoria y proveedores simulados; alta funcional y ausencia de servicios reales. |
| 08.9 | Foto opcional inicial/posterior y detalle. | Autorización posterior, fallo no bloqueante, reemplazo, retirada, cancelación y recuperación. | Foto no publicada sin autorización; ficha activa permanece operativa; receta, notas e histórico visibles. |

## 08.8a — Base reutilizable de demo

[PLU-46](https://linear.app/plusprojects/issue/PLU-46), Backlog, responsable Jesus Franco: siguiente trabajo planificado
después de PLU-42, pendiente de inicio y propuesta concreta. Conserva el patrón aislado
de ADR0023/0025 mediante un perfil separado: Debug-Develop, entorno/bundle correcto y argumento explícito único;
intención inválida/conflictiva falla cerrada antes de construir Firebase. Las fixtures originales permanecen vacías.

- Contenedor SwiftData en memoria, principal sintético autorizado, telemetría nula y proveedores remotos simulados.
  No construir el almacén durable, binding Keychain, motores/factories remotos o SDK Firebase del camino normal.
- Escenario inicial mínimo y determinista de clientes, sin datos personales reales. Relanzar recrea ese escenario;
  no se promete conservar cambios entre procesos. No se inventan entidades de catálogo o ventas futuras.
- Login/raíz, repositorios locales, UseCases, validaciones y pantallas reales. El adaptador simulado de documentos
  conserva idempotencia/correlación: solo permite activar tras un recibo compatible, sin forzar estados en Presentation.
- Demo identificable, activación deshabilitada por defecto y excluida de Production/Release. La selección no cambia
  la composición normal ni sus gates live. Sin PII ni payloads en logs/telemetría, también durante la demostración.
- La propuesta de implementación concretará los argumentos, propiedad del escenario y escenarios de error/reintento,
  reutilizando componentes existentes. No se requiere infraestructura genérica o seed remoto de fase17.

Aceptación: arranque aislado, listado/datos iniciales coherentes, crear/editar cliente sin foto, revisión/firma,
conservación/envío simulado, alta, fallo/reintento y reapertura en el mismo proceso; nuevo lanzamiento vuelve al
escenario conocido. Probar que argumentos inválidos, logout y capacidades antiguas fallan cerrados. Se documentan
destino/build y límites de simulación. Construcción accesible, previews/revisión focal y deuda conforme a ADR0029.
Esta base no acredita Storage real, sincronización ni recuperación durable; sus pruebas propias permanecen vigentes.

Las fases09/10 añaden catálogo sintético cuando exista su UI; fase13 añade adaptadores de numeración/documentos de
demo. No se implementan anticipadamente en08.8a. Foundation Models real se incorpora por el adelanto de spec16.

## 08.9 — Recuperación después de la demo

PLU-43 permanece Backlog, responsable Jesus Franco; retomar tras el feedback de la demo acordada de clientes,
catálogo, borrador asistido y venta completa. Conserva selección/foto inicial y posterior, autorización independiente,
reemplazo, retirada/limpieza recuperable y detalle con receta/notas/histórico. No se cierra parcialmente por aplazarla.
La fase08 conserva este pendiente hasta su entrega y evidencia aplicable; debe resolverse antes de uso real.
La ruta de demo sin foto no depende de este detalle ni de una autorización fotográfica inexistente.

## Recorrido y criterios de aceptación

1. Información disponible durante el formulario; al terminar se revisa la variante aplicable antes de capturar firma.
   Sin foto no se muestran referencias a imágenes. Con foto se ofrece una autorización interna explícita y opcional.
   Rechazar o retirar la selección permite seguir con el documento sin foto.
2. Texto común y sección condicional proceden de una fuente versionada. Desde 08.5, el catálogo legal se distribuye
   en el bundle desde `FranAlonso/Resources/Legal` y alimenta también el generador de borradores; no se lee el contenido
   mediante OCR ni se mantienen dos copias manuales.
3. El documento firmado fija ID, cliente, variante/finalidad, versión/idioma, contenido y datos presentados, decisiones,
   fecha, firma y artefacto. Cambiar un dato incluido, el texto o las decisiones invalida la firma pendiente.
4. Lectura nativa y revisión accesibles según ADR 0022, con secuencia de validación de ADR 0029. Consultar el texto sigue siendo posible al revisar la firma;
   desplazarlo o esperar un tiempo no se interpreta como lectura. PDF con texto real y firma, validado por separado.
5. Persistir borrador, documento y envío de forma recuperable; reiniciar o perder red no exige repetir una firma cuyo
   contenido no ha cambiado. Reintentar el mismo ID/artefacto, sin regenerar históricos desde el catálogo vigente.
6. Añadir foto después del alta solicita la autorización correspondiente, conserva el documento anterior y mantiene
   la ficha activa. Selección temporal, publicación tras autorización conservada, cancelación sin bloqueo del servicio.
7. Retirada de autorización y eliminación/reemplazo de fotografía se concretan en 08.9, incluida limpieza recuperable
   local/remota y retención; no dar por finalizada una retirada con trabajo remoto pendiente.

## Dependencias y cierre de 08.4

- Orden de dependencias: 08.4 → 08.5 → 08.6 → 08.7 → 08.8. Desde ADR0030 se prepara08.8a y continúa09–10,
  adelanto16 y11–13 antes de recuperar08.9 tras el feedback. Planificar no inicia código ni cierra evidencia pendiente.
- 08.5 define el contexto de foto y autorización que 08.7 consumirá. 08.7 valida ambas variantes con fixtures;
  el selector/subida de foto reales y el recorrido completo con foto se integran en 08.9. Así no depende del código
  futuro de 08.9 para cerrar su alcance ni se declara antes una integración fotográfica inexistente.
- 08.4 / PLU-38 integrada mediante PR#11 el13/09/2026 por autorización expresa; continúa abierta por evidencia propia.
  El propietario autoriza preparar issue/rama de08.5 desde ese merge. Se conserva regresión y evidencia manual;
  este inicio no acredita los pendientes de08.4 ni requiere repetir las pruebas aceptadas.
- Antes de cerrar 08.4: completar solo evidencia aplicable pendiente (incluidos interrupción/redimensionado y técnicas
  de asistencia), obtener revisión UI final por agente nuevo y retirar el acceso/esquema temporal de validación.
  Validar por Xcode MCP la composición resultante de esa retirada. La lectura y persistencia futuras no son su DoD.
- La pausa de pruebas durante el ajuste de planificación terminó; la evidencia manual del componente se conserva
  en su matriz, con los pendientes propios explícitos. Usar iPhone 14 físico o iPad; no usar iPhone 17.
- 08.4 no se cierra automáticamente por aceptar ADR 0028; entrega Git y comienzo de 08.5 conservan autorización separada.


## Separación de entrega y validación de 08.7 — actualización 2026-09-29

- [PLU-41](https://linear.app/plusprojects/issue/PLU-41) conserva el alcance funcional de lectura, revisión, firma,
  invalidación, conservación y recuperación; `Done` funcional tras [PR #14](https://github.com/JFrancoG/FranAlonso/pull/14)
  integrada en `334703d`. La fase 08 / PLU-34 permanece `In Progress`.
- [PLU-44](https://linear.app/plusprojects/issue/PLU-44), hija de fase 08 y relacionada con PLU-41, conserva los fallos
  accesibles conocidos y la evidencia pendiente. Responsable: Jesus Franco. La
  [matriz 08.7](../accessibility/evidence/08-7-consent-flow.md) sigue siendo el registro canónico de resultados.
- Retomar PLU-44 tras incorporar el feedback de Fran y estabilizar cada recorrido; completarla antes del primer
  candidato para uso real. No bloquea por sí sola la entrega funcional de PLU-41 ni 08.8 tras satisfacer la dependencia
  funcional. Sí impide el cierre integral de fase 08 y la puerta de uso real de fase 18.
- El cierre funcional de PLU-41 valida su recorrido, reconcilia la deuda y completa la entrega autorizada;
  enlaza PLU-44 abierta. Esta separación no aplaza integridad, privacidad o recuperación funcional.
- 08.4/PLU-38 conserva sus pendientes separados. 08.8/PLU-42 queda Done funcional tras entrega autorizada por
  [PR #15](https://github.com/JFrancoG/FranAlonso/pull/15), merge `0126c6b`, con smoke aislado validado y sin Storage real.
  08.9/PLU-43 continúa en Backlog tras ADR0030, con dependencia funcional satisfecha y recuperación tras la demo.
  08.8a es la siguiente puerta de inicio; la fase08 permanece abierta.
- [PLU-45](https://linear.app/plusprojects/issue/PLU-45) conserva la validación accesible integral nueva de08.8,
  con Jesus Franco como responsable y el mismo disparador de feedback/estabilización antes del uso real.
  [Evidencia08.8](../accessibility/evidence/08-8-client-activation.md) distingue el smoke funcional aislado
  de la validación accesible integral pendiente.

## Resultado de fase

Clientes offline-first con documento inicial firmado recuperable, autorización fotográfica opcional independiente,
Storage aislado y Store justificado por complejidad real. Los borradores jurídicos requieren verificación antes del uso real.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), identificando entrega funcional
para demo o cierre integral conforme a ADR 0029. La fase permanece abierta mientras conserve validaciones vinculadas.
