# Propuesta 08.4 — Captura de firma

> Actualización 2026-09-11: el propietario aprueba el plan de [ADR 0028](../ADRs/0028-client-signed-information-and-photo-authorization.md)
> y [spec 08](../specs/08_clients_consent.md). Las propuestas de flujo pendientes de acuerdo que aparecen debajo son
> históricas. 08.4 conserva su alcance de captura y sus pruebas pendientes; lectura, documento y foto se entregarán
> en 08.5–08.9. El texto jurídico continúa siendo borrador; este acuerdo no lo valida para uso real.

Fecha: 2026-09-10. Autorización: el propietario solicita abrir issue/rama e implementar 8.04.
Issue: PLU-38, hija de PLU-34. Rama: `codex/plu-38-phase-08-4-signature-capture`.
Base: `main == origin/main == 9ffce6a`, árbol limpio antes de comenzar.

## Finalidades aclaradas y propuesta de texto — 2026-09-10

El propietario confirma que Fran no envía comunicaciones comerciales: solo ticket/factura por email a petición
del cliente, ficha de servicio e imagen interna opcional. Esta aclaración sustituye la propuesta anterior de tres
opciones: queda únicamente la autorización de foto. Texto concreto para revisar en
[propuesta ajustada](08-4-consent-text-proposal.md), incorporado posteriormente al catálogo y al PDF como borrador por petición expresa.
Se debe distinguir información, base del tratamiento necesario y consentimiento opcional; revisar además el requisito
operativo de firma para activar de ADR0009 antes de implementar el nuevo flujo. Sin cambio de ADR aceptado.

## Replanteamiento solicitado — propuesta de flujo pendiente de acuerdo

El 2026-09-10 el propietario pausa las pruebas hasta definir el consentimiento completo. La captura implementada
es reutilizable, pero su pantalla aislada no constituye la experiencia final. La app vigente compone texto y firma
en una imagen y la sube a Storage; no se adopta automáticamente ese formato para la app nueva.

Orientación inicial para discutir, no nueva decisión aceptada ni autorización de implementar08.5:

1. Mostrar el contenido completo como texto accesible y adaptable antes de firmar, con acceso al mismo texto desde
   la captura. Decidir pantalla única o lectura seguida de firma según extensión real en iPhone/iPad.
2. Concretar las finalidades y elecciones de datos/imágenes a partir del texto real. No asumir que la foto opcional
   del perfil de la spec es equivalente a autorizar publicación o cualquier otro uso de imágenes.
3. Fijar una copia del contenido/versionado y elecciones al firmar; texto mostrado y documento generado deben salir
   de la misma fuente. Un cambio de contenido o elecciones invalida la firma del borrador y exige nueva confirmación.
4. Evaluar PDF con texto real y firma como artefacto conservado, junto con datos estructurados mínimos para localizar
   qué versión se aceptó, por quién y cuándo. Hash de integridad no acredita identidad ni validez jurídica por sí solo.
5. Persistir localmente documento y estado de envío recuperable; reintentar la subida del mismo artefacto con ID
   estable. Activar solo tras upload y referencia, como ADR0009; no regenerar con una plantilla nueva al reintentar.

Borrador localizado e inspeccionado el 2026-09-10; hallazgos y propuesta ajustada a continuación. Falta confirmar
si las finalidades del borrador representan el producto actual y acordar UX, contrato de documento y recuperación
antes de modificar código o repartir cambios entre08.4–08.8. Ningún scroll o pulsación demuestra por sí solo comprensión.
Fuentes de esta orientación: [W3C, texto frente a imágenes de texto](https://www.w3.org/WAI/WCAG22/Understanding/images-of-text)
y [Firebase, subida de archivos en plataformas Apple](https://firebase.google.com/docs/storage/ios/upload-files).
Storage admite archivos; no obliga a mantener imagen como formato. Estas fuentes no acreditan requisitos legales.

## Borrador existente inspeccionado — 2026-09-10

Fuente entregada por el propietario: `FranAlonso/Resources/DocumentTemplates/client-consent-template.pdf`,
una página A4 con texto extraíble y sin campos AcroForm. Página completa renderizada e inspeccionada; versión
`2026-07-22-draft`, con marca visible de borrador pendiente de revisión jurídica. No se modifica ni regenera el PDF.

Autoridad editable ya existente: `docs/legal/DocumentTemplates.xcstrings` contiene el texto; el JSON
`docs/legal/document-template-content.json` fija estructura, versión e identidad del negocio. El generador
`scripts/generate_document_templates.py` produce el PDF. El catálogo está fuera del bundle según LOCALIZATION_GUIDE;
mostrarlo como texto nativo requerirá diseñar su disponibilidad sin crear una segunda fuente manual ni extraerlo
mediante OCR/PDF en runtime.

El borrador distingue información básica/adicional de tres consentimientos opcionales independientes:

- Fotografía exclusivamente para ficha interna y seguimiento de los servicios; no contempla publicación.
- Comunicaciones comerciales por medios electrónicos.
- Comunicaciones comerciales por teléfono o correo postal.

Según su cláusula de firma, firmar acredita recepción de la información y aceptación únicamente de las casillas
marcadas; no marcar equivale a no autorizar. Su texto dice que rechazar fotografía/comunicaciones no afecta al servicio.
Estos son contenidos del borrador, no una aprobación jurídica del agente. Por tanto, el requisito técnico de documento
firmado de ADR0009 no debe confundirse con exigir aceptación de alguna finalidad opcional para activar al cliente.
El PDF también reserva nombre/apellidos, DNI/NIE, fecha y firma; falta acordar qué datos recoger/reutilizar en la app.

Propuesta de UX para discutir: lectura accesible con información completa, tres opciones independientes inicialmente
sin seleccionar, y paso de firma que muestre las elecciones y permita volver al texto. La firma existente se reutiliza
como componente dentro de ese flujo. Rechazar todas las opciones sigue siendo una combinación representable.
El documento final incluiría contenido/versionado, opciones tanto aceptadas como rechazadas, datos acordados y firma.
Cambiar contenido/elecciones después de firmar invalida la firma del borrador. La revisión jurídica y la confirmación
de finalidades permanecen pendientes; no se implementa ni modifica el texto como consecuencia de esta lectura.

## Decisión vigente — retirada del modo por puntos

El propietario autoriza expresamente retirar el modo por puntos el 2026-09-10 tras considerarlo inadecuado para firmar.
[ADR 0027](../ADRs/0027-freehand-signature-input-product-exception.md) registra la decisión y su excepción limitada
a la regla interna de alternativas de ADR 0022. Las revisiones independientes previas de estándares y accesibilidad
validan la retirada; no se atribuye una alternativa implementada ni accesibilidad universal.

## Alcance

Pantalla de captura independiente dentro de Clients, preparada para que el futuro flujo de consentimiento reciba
`.captured(ClientSignature)` o `.cancelled`. No se conecta aún al formulario: este solo guarda ClientProfile y destruye
su sesión al terminar, por lo que integrar una firma efímera ahora induciría pérdida de trabajo. La integración durable
pertenece a las subfases siguientes de la spec 08 y ADR 0009.

- Domain: `ClientSignature`, valor inmutable con Sendable inferido, trazos de puntos Double normalizados en 0...1,
  coordenadas finitas, al menos dos puntos distintos por trazo y al menos un trazo. La validación solo acredita tinta,
  nunca identidad, validez jurídica ni consentimiento. Codable validante conserva la invariante al reconstruir.
- Presentation: `ClientSignatureCaptureViewModel` @Observable @MainActor posee exclusivamente el buffer efímero,
  trazos en curso, validación, deshacer, borrar, confirmación y cancelación. El callback terminal se emite una sola vez;
  cancelar/cerrar limpia los puntos y eventos tardíos no reabren la sesión. Confirmar solo entrega un valor válido.
- SwiftUI: pantalla con título, instrucciones, lienzo con proporción estable 3:1, estado textual y botones nativos.
  El dibujo transforma geometría únicamente al representar; el ViewModel recibe eventos semánticos y normaliza puntos.
  La View no recibe repositorios, ModelContext, Firebase, PDFKit ni capacidades de persistencia.
- Entrada manuscrita a mano alzada, con Deshacer y Borrar para revertir. Sin cursor, posiciones ni modo por puntos.
  La excepción de trayectoria afecta solo al dibujo; las acciones nativas mantienen su evidencia de accesibilidad.
- Cada View en su archivo, previews deterministas con AppPreviewModifier y textos españoles en Localizable.xcstrings.

## Alternativas y fuentes

1. PencilKit/PKCanvasView: entrada especializada y soporte de Apple Pencil, pero requiere puente UIKit/delegado,
   representación PKDrawing y conversión adicional. Se difiere para
   un requisito demostrado de presión, herramientas o fidelidad avanzada.
2. SwiftUI Canvas + DragGesture: opción elegida para tinta monocolor y trazos simples, sin dependencias ni nuevo
   límite de SDK. Las acciones nativas de edición y cierre conservan semántica fuera de Canvas.
3. Firma tipográfica/imagen importada: descartada, cambia la semántica y el alcance de producto.
4. Controles por coordenadas: implementados inicialmente y retirados por decisión del propietario; no resultan útiles
   para escribir una firma. La evidencia anterior se conserva como historial de esa versión.

Documentación Apple consultada con Cupertino MCP y URL oficial comprobada el 2026-09-10:

- https://developer.apple.com/documentation/swiftui/canvas (Canvas no ofrece accesibilidad por elemento).
- https://developer.apple.com/documentation/swiftui/draggesture
- https://developer.apple.com/documentation/swiftui/spatialtapgesture (alternativa evaluada en la propuesta inicial;
  ya no se implementa posicionamiento por puntos).
- https://developer.apple.com/documentation/pencilkit/pkcanvasview

Autoridad: constitución, spec 08, ADR 0009/0011/0022/0026 y política Swift. iOS 26, Swift 6,
strict concurrency complete, aislamiento por defecto nonisolated. Xcode MCP conectado al checkout;
scheme Develop, destino inicial iPad Air 11-inch (M4) (26.5), SDK Simulator iOS 27.

## TDD y validación

RED focal antes de implementación: vacío y trazos degenerados/inválidos; firma válida conserva orden y coordenadas;
cancelación borra sin capturar; terminal único y eventos tardíos; deshacer/borrar; geometría normalizada. El RED original
incluía el modo por puntos; al retirarlo se eliminan solo sus dos tests exclusivos y se conserva la regresión de los
contratos vigentes. No se añade un RED artificial ni tests de ausencia de símbolos.
GREEN y regresión Clients mediante Xcode MCP; build y log completo. Baseline conserva aviso AppIntents previo,
sin afirmar cero warnings globales. No se toca configuración para ocultarlo.

Previews Large/XXX Large/AX5 y cuatro apariencias; comprobación iPhone/iPad y matriz ADR0022 con límites explícitos.
Revisores independientes read-only de estándares/estilo y accesibilidad. El cierre seguirá pendiente cuando falte
evidencia runtime de VoiceOver, Voice Control, Switch Control, teclado o uso real del gesto.

## Exclusiones y riesgos

Sin PDF, Storage, Store, persistencia, activación, cambios de esquema, permisos, dependencia, target ni gate live.
No se promete durabilidad: el callback es una frontera de captura para el futuro orquestador. Cancelar es irreversible
solo respecto al buffer local de esta sesión; no elimina una firma previamente aceptada por el consumidor.
El lienzo mantiene proporción para evitar deformar la firma al cambiar ancho/orientación. La integración futura debe
persistir el borrador de ADR0009 antes de anunciar un guardado y restaurar el foco al origen de presentación.
Commit, push, PR, merge, cierre de issue y avance a 08.5 permanecen fuera de esta petición.
