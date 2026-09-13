# Plantillas documentales provisionales

Las plantillas informativa, de consentimiento, ticket A4 y factura A4 se generan desde dos
fuentes complementarias mediante
[`scripts/generate_document_templates.py`](../../scripts/generate_document_templates.py):

- [`DocumentTemplates.xcstrings`](../../FranAlonso/Resources/Legal/DocumentTemplates.xcstrings) contiene todo el
  copy localizable, con claves semánticas, español de origen y contexto.
- [`document-template-content.json`](../../FranAlonso/Resources/Legal/document-template-content.json) contiene
  solo estructura, versión y datos del negocio que no se traducen.
Los nombres incluidos en la aplicación son estables para que una revisión de
texto o logotipo no obligue a cambiar el código:

- `client-data-information-template.pdf` (información de ficha sin referencias a imágenes)
- `client-consent-template.pdf` (incluye autorización de fotografía interna)
- `billing-ticket-a4-template.pdf`
- `billing-invoice-a4-template.pdf`

## Plan de integración aprobado — 2026-09-11

[ADR 0028](../ADRs/0028-client-signed-information-and-photo-authorization.md) y [spec 08](../specs/08_clients_consent.md)
sitúan contenido/versionado y render en 08.5, persistencia en 08.6, lector y firma en 08.7, activación en 08.8 y foto
real inicial/posterior en 08.9. 08.5 traslada ambas fuentes a Resources/Legal: el catálogo se compila para la app y el generador consume la misma fuente.
Los PDF conservan su condición de borradores y sus límites de accesibilidad/revisión jurídica. Las notas inferiores
registran el estado de cada generación, no un bloqueo vigente de planificación.

## Variante informativa sin imágenes — 2026-09-10

Petición expresa del propietario: añadir un borrador sencillo para la ficha sin fotografía, conservando el documento
con foto. El JSON `dataInformation` reutiliza las secciones comunes y referencia ocho textos específicos del catálogo.
La lista de autorizaciones queda vacía: el generador omite ese apartado y presenta la firma como constancia de recepción.
Las cuatro plantillas se generan con la misma herramienta. Los tres PDF anteriores mantienen sus bytes.
El nuevo PDF es un recurso documental adicional; todavía no se añade a DocumentTemplateResource ni se conecta al flujo.

La implementación se planeará más adelante tras revisar ADR/specs, Progress del vault del proyecto y Linear/historia
correspondiente. Esta petición no autoriza implementar el recorrido, cerrar 08.4 ni iniciar otra subfase.

## Revisión del consentimiento — 2026-09-10

El propietario autoriza sustituir el borrador por el texto ajustado a ficha de clientes, foto interna opcional
(y ninguna finalidad publicitaria) y envío de ticket/factura por email bajo solicitud. Se conserva la marca de borrador
y la nota editorial pendiente sobre transferencias internacionales. El consentimiento usa `consent.documentVersion`
(`2026-09-10-draft`); ticket y factura conservan `documentVersion` y sus PDFs originales byte a byte.
Nombre, fecha y firma sustituyen las tres columnas anteriores: no se pide DNI/NIE sistemático en este documento.
Texto canónico en el catálogo; propuesta de discusión archivada en `docs/progress/08-4-consent-text-proposal.md`.

Regeneración de esta revisión: CPython 3.12.14/zlib1.2.12 y requirements fijados; dos pasadas idénticas.
Ticket/factura reproducen los hashes previos. Esta comprobación no extiende la reproducibilidad a otros entornos.

## Estado de revisión

El consentimiento es un borrador de trabajo pendiente de revisión jurídica. La
marca visible y los metadatos del PDF no deben eliminarse hasta recibir esa
aprobación. Su estructura sigue el deber de información del artículo 13 del
RGPD y la recomendación de información por capas de la AEPD; la revisión final
debe adaptarlo a los tratamientos, encargados, transferencias y plazos reales.
Las correcciones de copy se realizan en el String Catalog, no en el generador.

Fuentes oficiales consultadas:

- [Reglamento (UE) 2016/679, artículo 13](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:32016R0679)
- [Ley Orgánica 3/2018, de 5 de diciembre](https://www.boe.es/eli/es/lo/2018/12/05/3/con)
- [AEPD: información cuando los datos se obtienen del afectado](https://www.aepd.es/preguntas-frecuentes/2-tus-obligaciones-como-responsable-del-tratamiento/6-el-deber-de-informacion/FAQ-0217-que-informacion-debe-facilitarse-cuando-los-datos-se-obtengan-directamente-del-afectado)
- [AEPD: herramienta Facilita RGPD](https://www.aepd.es/guias-y-herramientas/herramientas/facilita-rgpd)

## Identidad y firma

El wordmark de estas plantillas es una aproximación vectorial provisional
derivada de la única fuente del nombre comercial en
`document-template-content.json`; el generador no duplica sus palabras. Se
reemplazará por el recurso vectorial original si Fran Alonso facilita una
fuente mejor, sin cambiar los nombres de las plantillas.

La fotografía original de la firma y el sello se ha inspeccionado, pero no se
versiona ni se incluye en el bundle: una imagen incluida en la aplicación puede
extraerse del paquete. La fase 13 cargará la firma privada después de autenticar
al usuario, validará su formato y mantendrá una caché local protegida. Su
ausencia será recuperable y no impedirá generar un documento sin firma.

## Regeneración

El entorno validado usa CPython 3.12.13, zlib 1.2.12 y las dependencias
fijadas en `scripts/requirements-document-templates.txt`. Desde un clon limpio:

```sh
python3.12 -m venv .venv-document-templates
.venv-document-templates/bin/python -m pip install \
  -r scripts/requirements-document-templates.txt
.venv-document-templates/bin/python scripts/generate_document_templates.py
```

El modo invariante de ReportLab garantiza una salida binaria estable entre
ejecuciones del entorno validado. No se promete identidad byte a byte con otra
versión de Python, ReportLab, Pillow, charset-normalizer o zlib; en ese caso se
debe volver a revisar visualmente el resultado antes de aceptar el nuevo hash.

Después de cualquier cambio se deben renderizar los PDF afectados, revisarlos
visualmente y ejecutar `DocumentTemplateResourceTests` mediante Xcode MCP.

Los tests actuales cubren los tres recursos originales. Para el borrador informativo adicional, comprobar
texto, A4, render, reproducibilidad e inclusión en el bundle hasta que se planifique su integración Swift.
