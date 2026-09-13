# ADR 0028 — Información firmada y autorización opcional de fotografía

## Estado

Aceptado por el propietario el 11 de septiembre de 2026 al aprobar el ajuste de planificación.
Sustituye parcialmente ADR 0009: precisa el significado del documento inicial y separa la autorización fotográfica
posterior. Conserva su activación inicial tras upload, estados e idempotencia. Su implementación queda en 08.5–08.9.

## Contexto

Fran utiliza la ficha para atender al cliente y envía ticket o factura por email únicamente bajo solicitud; no realiza
comunicaciones comerciales. La fotografía para identificación interna es opcional y poco frecuente. El propietario
acuerda mostrar información sin referencias a imágenes cuando no hay foto, y añadir la autorización correspondiente
cuando se solicita incorporarla, también después del alta.

08.4 captura trazos efímeros; no vincula por sí sola una firma a un texto o autorización. Los dos PDF de Resources son
borradores de contenido, no documentos firmados ni un lector accesible implementado.

## Drivers

- Leer lo que se firma y conservar exactamente ese contenido, sin perder trabajo offline.
- Separar la constancia de información de la autorización opcional; seleccionar una imagen no autoriza su uso.
- Mantener operativo un cliente activo cuando solicita añadir una foto, aunque cancele o falle su subida.
- Conservar los contratos existentes cuando sirven y evitar copias divergentes de textos o históricos.

## Opciones consideradas

1. Un documento genérico con fotografía para todos: sencillo, pero añade contenido innecesario al caso habitual.
2. Dos textos y flujos independientes: ajustados a cada caso, con duplicación y riesgo de divergencia.
3. Contenido común versionado y sección condicional, con documentos firmados inmutables: añade persistencia y
   recuperación específicas, pero permite explicar y acreditar cada decisión. Opción elegida.

## Decisión

### Información, lectura y firma

- Mantener la firma del documento inicial como regla de producto para activar la ficha. No presentarla como una
  exigencia legal general ni convertir el tratamiento necesario para prestar el servicio en una autorización opcional.
- Información accesible desde el formulario; al finalizar, revisión del texto aplicable antes de abrir la captura.
  Lectura nativa con Dynamic Type y tecnologías de asistencia; el texto sigue consultable al revisar la firma.
  No usar una imagen del texto ni inferir lectura por tiempo o por haber desplazado la pantalla.
- Sin foto: documento informativo y constancia de recepción. Con foto seleccionada: contenido común y autorización
  explícita, opcional y desmarcada inicialmente, limitada al uso interno indicado. Rechazarla permite continuar sin foto.
- Si se retira o rechaza la foto antes de firmar, presentar la variante sin foto. Cambiar contenido, datos incorporados
  al documento o decisiones invalida la firma pendiente y exige revisar y firmar el documento resultante.
- Mantener el texto en un catálogo común y una estructura versionada. 08.5 definirá su distribución a la app y al
  generador: hoy el catálogo legal está fuera del bundle. No duplicar manualmente el texto ni extraerlo del PDF en runtime.

### Documento y recuperación

- Crear un registro independiente de `ClientSignature`, con ID estable, cliente, finalidad/variante, versión e idioma,
  snapshot del contenido y datos presentados, decisiones explícitas, fecha, firma y vínculo al artefacto definitivo.
- Generar un PDF con texto real y firma desde ese snapshot; conservar sus bytes y comprobar su correspondencia con el
  registro. El PDF por sí solo no acredita accesibilidad: lector nativo y documento exportado requieren validación propia.
- Persistir localmente borrador y documento con recuperación tras cierre/reinicio. Reintentar el mismo envío con el
  mismo ID y contenido; un payload diferente bajo ese ID es conflicto, no una sobrescritura silenciosa.
- Una nueva versión no reescribe históricos ni amplía permisos. Conservar el documento inicial y los posteriores como
  registros distintos. Inmutabilidad no significa conservación indefinida: retención y eliminación se concretan antes
  del uso real, sin sustituir el contenido de un documento por otro.

### Activación y fotografía

- Conservar `draft` → `consentPendingUpload` → `active` para el alta inicial. La referencia existente puede seguir
  identificando su documento inicial; no renombrar tipos o formatos Codable solo por terminología.
- Añadir una foto a una ficha activa abre un proceso de autorización separado. No devolver el cliente a pendiente,
  vaciar su referencia inicial ni bloquear servicios mientras se firma o reintenta.
- La foto seleccionada es temporal y privada; no se publica ni sube como foto de ficha hasta conservar la autorización
  firmada correspondiente. Cancelar descarta la selección; un fallo de foto no invalida el documento ni al cliente.
- En 08.9 contemplar retirada de autorización y eliminación de foto, reemplazo y cambios de finalidad. No reutilizar
  una autorización retirada ni extender su alcance. Concretar limpieza local/remota, recuperación y retención antes
  de habilitar el flujo real; no declarar la retirada completada si queda trabajo remoto pendiente.

## Consecuencias

- 08.4 sigue siendo un componente reutilizable; no necesita contener texto legal, Storage ni activación.
- 08.5–08.9 requieren un registro durable y una coordinación de estados adicional a la ficha. Mantener límites
  Domain/Data/Presentation y `ClientConsentStore` propiedad del ViewModel, sin dependencias de proveedor en UI.
- El contenido jurídico sigue siendo borrador: responsables, proveedores, transferencias y conservación deben
  verificarse antes de su uso real. Este ADR aprueba arquitectura y producto, no certifica validez jurídica.

## Testing y validación

- Dos variantes y rechazo de foto; contenido presentado y renderizado coincidentes; cambio posterior invalida firma.
- Reinicio antes/después de render/upload/activación, duplicados y conflicto de payload bajo un mismo ID.
- Autorización posterior conserva cliente activo y documento anterior; cancelar/fallo no publica foto ni pierde ficha.
- Migración y reapertura de datos existentes; operaciones Codable pendientes conservadas.
- Lectura, revisión y firma accesibles según ADR 0022; excepción de trayectoria limitada por ADR 0027.

## Migración o reversibilidad

Planificar en 08.6 cualquier nuevo almacenamiento mediante nueva versión y migración desde la baseline 1.0.0 de
ADR 0018; conservar referencias previas y compatibilidad de operaciones pendientes. No reconstruir documentos
antiguos con el texto vigente ni inventar autorizaciones para referencias existentes. Las decisiones concretas de
schema, contrato remoto y limpieza se revisan antes de su código. Motores y uso live mantienen su puerta separada.

## Relaciones

- [ADR 0009](0009-client-consent-activation.md): sustituido únicamente en los puntos indicados.
- [ADR 0002](0002-swiftdata-local-sot-firestore-remote-sot.md), [ADR 0018](0018-swiftdata-baseline-from-phase-five-ten-c.md): persistencia y migración.
- [ADR 0022](0022-native-ios-wcag22-accessibility.md), [ADR 0027](0027-freehand-signature-input-product-exception.md): accesibilidad y captura.
- [Spec 08](../specs/08_clients_consent.md): reparto de implementación y criterios de aceptación.
- [Borradores y fuentes jurídicas](../progress/08-4-consent-text-proposal.md): antecedentes del contenido.
