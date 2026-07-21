# Plantillas documentales provisionales

Las plantillas de consentimiento, ticket A4 y factura A4 se generan desde dos
fuentes complementarias mediante
[`scripts/generate_document_templates.py`](../../scripts/generate_document_templates.py):

- [`DocumentTemplates.xcstrings`](DocumentTemplates.xcstrings) contiene todo el
  copy localizable, con claves semánticas, español de origen y contexto.
- [`document-template-content.json`](document-template-content.json) contiene
  solo estructura, versión y datos del negocio que no se traducen.
Los nombres incluidos en la aplicación son estables para que una revisión de
texto o logotipo no obligue a cambiar el código:

- `client-consent-template.pdf`
- `billing-ticket-a4-template.pdf`
- `billing-invoice-a4-template.pdf`

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

Después de cualquier cambio se deben renderizar los tres PDF, revisarlos
visualmente y ejecutar `DocumentTemplateResourceTests` mediante Xcode MCP.
