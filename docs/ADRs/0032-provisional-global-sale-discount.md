# ADR 0032 — Descuento global provisional y snapshot comercial versionado

## Estado

Aceptado para la implementación local de 11.7, 2026-10-02, tras PRE independiente PASS sin hallazgos.
Decisión técnica dentro del alcance autorizado; no se atribuye una ratificación comercial definitiva a Fran.
El propietario autoriza una solución provisional para la demo que permita probar un descuento global independiente
de las promociones de producto/servicio. Fran confirmará la política comercial después de la demo.
La autorización inicial no incluía entrega Git, otra subfase ni activación live.
El 2026-10-02 el propietario autoriza commit, push, PR, merge, cierre de PLU-80 y eliminación de rama.
La ratificación comercial, la siguiente implementación y la activación live conservan sus puertas separadas.

## Contexto

El descuento de línea captura una promoción del catálogo. Black Friday puede aplicar un descuento adicional a toda
la venta sin sustituir esa promoción. Los totales se reconstruyen desde snapshots; cambiar una política sin
identificarla alteraría el cálculo de ventas antiguas. La propuesta inicial de incompatibilidad queda descartada.

SaleModel ya almacena `linesPayloadVersion` y `linesData`. Una columna nueva obligaría a evolucionar la forma
SwiftData según ADR0018; el payload comercial puede evolucionar sin cambiar las 31 tablas del esquema3.

## Decisión

- Guardar un término `SaleGlobalDiscount` opcional en Sale: Discount validado y política `lineThenGlobalV1`.
  Ausencia y cero son distintos; edición únicamente en draft. Cliente, líneas, estados posteriores y metadatos
  conservan ese término. La misma regla se utiliza en demo y composición normal, con motores live inactivos.
- V1 aplica por línea: subtotal → descuento de línea redondeado con Money → residual → descuento global redondeado
  con Money → total → base/IVA. Cada etapa usa el certificado existente ADR0031; no sumar porcentajes ni calcular
  el global sobre un agregado ya redondeado. Los importes de ambos descuentos se exponen por separado y su suma
  conserva el contrato `discountAmount`. El global se aplica también a líneas añadidas después.
- V1 permanece evaluable para ventas guardadas. Un cambio comercial posterior seleccionará otra política para
  nuevos términos; no reinterpreta V1 ni elimina promociones capturadas. No se introduce un motor de estrategias.
- Payload local1 conserva el array de líneas. Payload local2 guarda un envelope Codable `{lines, globalDiscount}`
  en el mismo `linesData`, con política y porcentaje canónico. Leer1 no modifica bytes. Una nueva escritura usa2.
  No cambian propiedades persistidas, modelos de esquemas1/2/3, versiones del plan ni configuración del container.
- SaleDTO admite1/2 con claves estrictas. V1 no acepta global, ni null, y se reencoda como1. V2 valida el término
  y rechaza políticas desconocidas. Los wrappers causales/pending/base/remote/conflict conservan su versión1:
  su snapshot interno tiene versión propia. Replay no recodifica ni actualiza payloads guardados.
- Firestore escribe la versión del DTO de cada operación, sin forzar la versión actual. Tombstones siguen en1.
  No se cambian rutas, Rules, cursores, retry, límites del backend ni se activa transporte.
- Repository/UseCase aceptan global con el candidato existente. El overload anterior conserva el término esperado,
  sin defaults nil que lo retiren por accidente. Store calcula el candidato completo antes de una única aceptación.

## Alternativas y límites

Incompatibilidad impediría probar el ejemplo solicitado. Sustituir descuentos de línea perdería su motivo original.
Un global efímero en Presentation desaparecería al recuperar la venta. Una columna o blob adicional introduce una
migración de esquema que no aporta consultas necesarias para esta demo. El envelope existente es la opción menor.

La compatibilidad es de lectura hacia delante y replay exacto, no de downgrade ni de coexistencia con writers binarios
antiguos: un writer antiguo con un snapshot previo puede sobrescribir un registro nuevo. No se promete rollback
automático de datos ni se abre un store rechazado mediante reset/reseed. Antes de uso real se ratifica la política y
se revisan las puertas pendientes; ADR0029 conserva la deuda accesible propia.

## Validación requerida

TDD Swift Testing con oráculos literales: 100€/línea10%/global20% → 72€; 0,07€/50%/50% → 0,01€;
dos líneas0,05€/global10% → 0,08€. Cubrir signos, cero/100/fracciones, límites de precisión, vacío, futuras líneas,
retirada independiente y conservación tras pago/cierre/anulación. Pipeline de Store, errores, cancelación, retry,
cierre y snapshots obsoletos incluidos cuando sólo cambia global.

Fixtures v1 auténticos para DTO/local/pending/base/remoto/conflicto y replay Firestore. Reapertura file-backed con
schema3 y plan vigente: lectura v1 sin escritura, aceptación sucesora v2 con bytes v1 intactos y segunda reapertura.
Mantener las regresiones de esquema1/2/3 y fijar sus writers históricos a v1 para evitar fixtures circulares.
No matriz1/2/3→4 porque no se propone nueva forma SwiftData.

Builds y tests Xcode MCP, previews Large/XXX/AX5, smoke de convivencia y retirada, auditorías independientes técnica,
estilo y UI. El informe de línea anterior no prueba el global. PLU-81 amplía su matriz por impacto; AT sigue pendiente.

## Relaciones

Complementa [ADR0016](0016-sale-sync-exact-timestamps-and-draft-discard.md),
[ADR0018](0018-swiftdata-baseline-from-phase-five-ten-c.md) y
[ADR0031](0031-sale-decimal-coefficient-certification.md).
[Propuesta global11.7](../progress/11-7-global-discount-proposal.md) concreta el ámbito de implementación.

La semántica provisional procede de la dirección del propietario en este chat. Las fronteras y codecs proceden del
código real y ADR aceptados, no de una recomendación externa. La documentación Apple de VersionedSchema y
MigrationStage, leída por Cupertino en la exploración inicial, no demuestra una migración; aquí no cambia el esquema.
