# 08.5 — Propuesta de contenido versionado y documento firmado

Fecha: 2026-09-13. Issue [PLU-39](https://linear.app/plusprojects/issue/PLU-39).
Estado: implementación autorizada por el propietario el13/09 («adelante con la subfase 8.05»).
Revisión independiente PRE favorable; resultado de implementación en [fase08](phase-08.md).

## Estado y autoridad

Rama `codex/plu-39-phase-08-5-signed-documents`, base `c4d7b00989a58783f953752bdc8f29dca90c6715`.
PR#11 integrada por autorización expresa. PLU-38 conserva su evidencia pendiente; no se declara DoD08.4.
Autoridad: [constitución](../specs/01_constitution.md), [spec08](../specs/08_clients_consent.md),
[ADR0009](../ADRs/0009-client-consent-activation.md),
[ADR0028](../ADRs/0028-client-signed-information-and-photo-authorization.md),
[guía](../DEVELOPMENT_GUIDE.md) y [política Swift](../standards/swift-code-policy.md).

Configuración inspeccionada: iOS26.0, Swift6 y aislamiento por defecto nonisolated. Xcode MCP identifica
`windowtab-QTPhkgjxly` como FranAlonso. Baseline Develop/iPad Air11M4/26.5: build PASS14,159s y composición3/3
tras retirar el acceso temporal, documentados en [fase08](phase-08.md). Regresión histórica26/26 conservada.
Aviso AppIntents conocido y seis enlaces históricos08.3 rotos, sin atribuir cero warnings ni CI remota.

`ClientSignature` ya contiene tinta normalizada inmutable y Codable validante; no acredita identidad ni consentimiento.
`ClientConsentReference` es una referencia opaca existente, no un documento. El catálogo legal JSON/xcstrings está
fuera del bundle y el generador Python produce borradores, no documentos firmados en runtime.

## Comportamiento propuesto

1. Resolver explícitamente versión e idioma de un catálogo legal local y materializar contenido semántico ordenado.
   Mantener el texto aprobado como borrador; no reescribirlo ni declararlo jurídicamente validado.
2. Preparar la información inicial sin foto o con autorización interna opcional. La autorización comienza sin conceder;
   rechazo o retirada de foto produce la variante sin referencias a imágenes. Modelar el contexto de autorización
   posterior para que08.7/08.9 lo consuman, sin selector ni imagen real y sin cambiar estados del cliente.
3. Fijar un snapshot inmutable con ID estable, cliente, finalidad/variante, versión, idioma, secciones ya resueltas,
   datos presentados y decisiones. No releer el catálogo al renderizar un snapshot existente.
4. Vincular la firma al snapshot exacto presentado. Comparación semántica completa: si cambian contenido, datos
   presentados, versión, idioma, finalidad o decisiones, rechazar la firma pendiente y exigir nueva captura.
   Un cambio de campos de ficha que no se presentaron no invalida por accidente el documento.
5. `RenderConsentUseCase` recibe el snapshot, el vínculo de firma y dependencias inyectadas de fecha/identidad;
   produce un documento firmado inmutable que conserva snapshot, firma, fecha y bytes PDF definitivos asociados
   al mismo ID. Construcción y decodificación validan las invariantes; no agregar firma a `ClientProfile`.
6. PDF A4 con texto real, secciones completas, datos, decisiones, fecha y firma vectorial proporcional3:1.
   Paginación explícita sin truncar texto; error ante contenido/idioma ausente, firma desactualizada o fallo de render.
   No emitir un documento parcialmente válido. Cancelación cooperativa entre páginas, sin payloads en logs.

## Distribución y fronteras

- Trasladar la única fuente `DocumentTemplates.xcstrings` y su JSON estructural a `Resources/Legal` y actualizar
  referencias del generador. El catálogo compilado es el origen del texto visible de la app; el generador de
  borradores consume esos mismos archivos fuente. Evitar dos copias editables, OCR o extracción del PDF en runtime.
  Resolver idioma explícito y comprobar disponibilidad, sin fallback silencioso que mezcle idiomas.
- Reutilizar secciones comunes mediante claves compartidas y overrides semánticos de variante. Conservar textos,
  versiones y PDF de ticket/factura sin cambios funcionales. Tests de paridad y recursos protegen el traslado.
- Domain: value objects de contenido, contexto/decisiones, snapshot, vínculo de firma y documento/artefacto;
  protocolo de render y casos de uso de preparación/render. Foundation, sin CoreGraphics/CoreText/PDFKit ni UI.
- Data: adaptador de catálogo del bundle y actor concreto de render CoreGraphics/CoreText. Contextos, frames y
  attributed strings locales a una operación; no transferir objetos gráficos entre actores ni usar GCD/unchecked.
  Solo valores enviables cruzan la frontera. El actor separa el trabajo pesado de MainActor.
- App: composición concreta mínima cuando sea necesaria para exponer los casos de uso a sus futuros consumidores;
  no conectarlos al formulario ni añadir una pantalla temporal de prueba. Tests con dependencias inyectadas.
- Artefacto estable significa conservar los bytes generados junto al documento y no reconstruir históricos ni
  reintentos desde el catálogo actual. Verificar determinismo semántico con IDs/fecha/locale fijos. No presuponer
  igualdad binaria de dos renders independientes entre versiones del sistema o fuentes instaladas; medirla y
  documentarla por separado. La persistencia de esos bytes y la idempotencia de envío corresponden a08.6.

## Alternativas y fuentes

Se propone CoreGraphics/CoreText para un exportador PDF separado de UI y ejecutado en actor. No usar captura de
SwiftUI ni imagen del texto porque se perdería el texto real. Mantener Python para borradores de desarrollo evita
introducir un runtime externo en iOS. Mover las fuentes al bundle resulta más simple que generar otra copia
intermedia y mantener sincronización obligatoria en cada build.

Fuentes Apple consultadas mediante Cupertino el13/09/2026:

- [Contexto PDF con consumidor](https://developer.apple.com/documentation/coregraphics/cgcontext/init(consumer:mediabox:_:)):
  permite producir instrucciones PDF en un consumidor de datos y definir el tamaño de página.
- [CTFrameDraw](https://developer.apple.com/documentation/coretext/ctframedraw(_:_:)):
  dibuja un frame de texto en el contexto. Su uso no acredita por sí solo PDF accesible ni extracción completa.
- [Core Text Overview](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/CoreText_Programming/Overview/Overview.html):
  guía fundacional archivada sobre concurrencia; parámetros mutables no se comparten durante operaciones.
  Se aplica como fundamento de confinamiento, comprobando las firmas modernas con el SDK real al implementar.

## TDD y validación de implementación

Antes de crear suites se aplicarán las skills de Swift Testing y tests-de-verdad. Secuencia RED/GREEN focalizada:

1. Preparación de ambas variantes y rechazo/retirada de foto; ausencia de claves, versión o idioma; datos presentados
   exactos, contexto posterior diferenciado y autorización inicialmente no concedida.
2. Firma vinculada: cada cambio semántico relevante invalida; snapshots previos permanecen iguales tras cambiar el
   catálogo; round-trip Codable e intentos de decodificación que eludan invariantes.
3. Render mediante fake para errores, cancelación y dependencias deterministas. Actor real con PDFKit solo en tests
   para extraer y comparar texto normalizado con el snapshot, datos/fecha/decisiones e identidad; ambas variantes,
   contenido largo multipágina y Unicode. Verificar presencia/ubicación de firma mediante render visual del artefacto.
4. Conservación exacta del artefacto tras round-trip sin regenerarlo, independencia de versión vigente y contrato
   preparado para persistencia08.6. No crear pruebas que afirmen recuperación durable o upload inexistentes.
5. Build/tests por Xcode MCP en iPad26.5; diagnóstico completo, inspección visual de PDF generados con datos
   sintéticos y revisión independiente de arquitectura/recursos/localización. Regresión afectada de firma y recursos.

No hay pantalla nueva: previews/recorridos manuales de lectura nativa son N/A aquí, se validan en08.7.
Texto extraíble no implica PDF etiquetado ni accesibilidad universal: registrar sus límites y conservar la lectura
nativa accesible como canal independiente. No pedir al propietario que repita pruebas de captura ya aceptadas.

## Exclusiones, riesgos y reversibilidad

Sin persistencia durable, migración SwiftData, Firebase/Storage, Store, upload, activación de clientes, selector/subida
de fotografía, lectura UI integrada ni revisión jurídica. Sin dependencias externas nuevas, aumento de target,
excepciones unsafe ni activación live. No sustituir el documento inicial por una autorización posterior.

Riesgos concretos: catálogo compilado ausente o locale incorrecto, paginación/truncado, deriva entre snapshot y PDF,
metadatos variables del motor PDF y cambios de fuente entre sistemas. Se cubren mediante recursos reales del bundle,
fallos explícitos, tests semánticos y revisión del export. Antes de ampliar el contrato se vuelve a revisar la propuesta.
Los cambios permanecen aislados en la rama; el traslado de recursos conserva una sola fuente y sus referencias.

## Revisión de preparación

Agente nuevo `proposal085_pre`: sin hallazgos accionables, PASS de preparación. Revisados propuesta, diff documental,
autoridad, fronteras, alternativas y fuentes Apple mediante Cupertino. Modo operacional read-only: huella de462
archivos tracked/untracked no ignorados idéntica antes/después, verificada por el orquestador:
`e47ff50cfc5e3d3a0edd91597ca8458f37a62fb65389ca08d096a43106cb26a8`.
No acredita implementación, test nuevo ni cierre de subfase. Build/tests N/A para esta preparación documental;
diff-check limpio y gobernanza conserva únicamente los seis enlaces históricos08.3 ya declarados.
