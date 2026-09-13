# Fase 08 — Clientes, consentimiento y foto

## Objetivo

Gestionar clientes, búsqueda, información inicial firmada y fotografía interna opcional, preservando trabajo offline.
La firma inicial se conserva como regla de producto para activar la ficha; la fotografía exige autorización separada
y opcional. El documento aplicable se lee antes de firmar y se conserva sin reescribir su contenido histórico.

## Prerrequisito de decisión

ADR 0009 y [ADR 0028](../ADRs/0028-client-signed-information-and-photo-authorization.md) aceptados.
ADR 0028 precisa el significado del documento inicial y la autorización posterior; conserva los estados de alta.

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
| 08.7 | Integrar lectura, revisión y firma mediante `ClientConsentStore`. | Sin foto, autorización/rechazo, cambio de contenido, cancelación, recuperación y errores. | ViewModel posee Store; lectura nativa accesible y documento fijado al firmar. |
| 08.8 | Activación inicial idempotente tras upload. | Reinicio entre upload y activación; reintento sin duplicar documento ni alta. | Nunca activo sin referencia del documento inicial firmado. |
| 08.9 | Foto opcional inicial/posterior y detalle. | Autorización posterior, fallo no bloqueante, reemplazo, retirada, cancelación y recuperación. | Foto no publicada sin autorización; ficha activa permanece operativa; receta, notas e histórico visibles. |

## Recorrido y criterios de aceptación

1. Información disponible durante el formulario; al terminar se revisa la variante aplicable antes de capturar firma.
   Sin foto no se muestran referencias a imágenes. Con foto se ofrece una autorización interna explícita y opcional.
   Rechazar o retirar la selección permite seguir con el documento sin foto.
2. Texto común y sección condicional proceden de una fuente versionada. 08.5 define la distribución a la app del
   catálogo legal, hoy fuera del bundle; no se lee el contenido mediante OCR ni se mantienen dos copias manuales.
3. El documento firmado fija ID, cliente, variante/finalidad, versión/idioma, contenido y datos presentados, decisiones,
   fecha, firma y artefacto. Cambiar un dato incluido, el texto o las decisiones invalida la firma pendiente.
4. Lectura nativa y revisión accesibles según ADR 0022. Consultar el texto sigue siendo posible al revisar la firma;
   desplazarlo o esperar un tiempo no se interpreta como lectura. PDF con texto real y firma, validado por separado.
5. Persistir borrador, documento y envío de forma recuperable; reiniciar o perder red no exige repetir una firma cuyo
   contenido no ha cambiado. Reintentar el mismo ID/artefacto, sin regenerar históricos desde el catálogo vigente.
6. Añadir foto después del alta solicita la autorización correspondiente, conserva el documento anterior y mantiene
   la ficha activa. Selección temporal, publicación tras autorización conservada, cancelación sin bloqueo del servicio.
7. Retirada de autorización y eliminación/reemplazo de fotografía se concretan en 08.9, incluida limpieza recuperable
   local/remota y retención; no dar por finalizada una retirada con trabajo remoto pendiente.

## Dependencias y cierre de 08.4

- Orden de entrega: 08.4 → 08.5 → 08.6 → 08.7 → 08.8 → 08.9. La planificación de 08.5–08.9 no inicia su código.
- 08.5 define el contexto de foto y autorización que 08.7 consumirá. 08.7 valida ambas variantes con fixtures;
  el selector/subida de foto reales y el recorrido completo con foto se integran en 08.9. Así no depende del código
  futuro de 08.9 para cerrar su alcance ni se declara antes una integración fotográfica inexistente.
- 08.4 / PLU-38 continúa abierta en su rama actual. Conserva regresión y evidencia manual acreditadas; no hay que
  repetirlas por este cambio documental ni esperar a implementar 08.9 para cerrar la captura.
- Antes de cerrar 08.4: completar solo evidencia aplicable pendiente (incluidos interrupción/redimensionado y técnicas
  de asistencia), obtener revisión UI final por agente nuevo y retirar el acceso/esquema temporal de validación.
  Validar por Xcode MCP la composición resultante de esa retirada. La lectura y persistencia futuras no son su DoD.
- La pausa de pruebas durante el ajuste de planificación terminó; la evidencia manual del componente se conserva
  en su matriz, con los pendientes propios explícitos. Usar iPhone 14 físico o iPad; no usar iPhone 17.
- 08.4 no se cierra automáticamente por aceptar ADR 0028; entrega Git y comienzo de 08.5 conservan autorización separada.


## Resultado de fase

Clientes offline-first con documento inicial firmado recuperable, autorización fotográfica opcional independiente,
Storage aislado y Store justificado por complejidad real. Los borradores jurídicos requieren verificación antes del uso real.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
