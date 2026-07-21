# Fase 13 — Documentos, PDF, correo y numeración

## Objetivo

Generar tickets y facturas con numeración remota única, PDF basado en plantillas y correo preparado para envío manual, con recuperación ante interrupciones.

## Corrección de diseño de numeración

No se usa un flujo separado `getNext` / `confirmNumber`: una caída entre ambos puede consumir o duplicar números sin un documento recuperable.

- Una transacción Firestore recibe un `documentRequestID` estable, incrementa la serie correspondiente y crea el registro remoto de `BillingDocument` en la misma operación.
- Repetir el mismo request devuelve el documento ya creado; no consume otro número.
- Ticket y factura usan series y documentos independientes.
- El número definitivo nunca se inventa localmente. Sin red, la solicitud queda `pendingNumber`; la venta permanece pagada pero continúa en Jornada hasta poder emitir el documento.
- Tras confirmar el registro remoto, el sync lo materializa en SwiftData y continúa renderizado/subida.
- No se reserva ni emite ticket o factura antes de registrar el pago.
- La firma y el sello del negocio son un recurso privado: no se versionan ni se incluyen en el bundle. Se importan o descargan después de autenticar al usuario, se validan y se almacenan con protección local; su ausencia permite generar el documento sin firma.
- La estrategia y sus consecuencias se documentan en ADR 0008. Los requisitos fiscales y de conservación deben validarse con la asesoría responsable antes de producción.

## Estado de presentación

- `BillingViewModel` es la fachada de selección, navegación y presentación.
- `BillingDocumentStore` se justifica por la máquina de estados: selección, datos fiscales, numeración, renderizado, subida, correo, error, reintento y cancelación.
- El ViewModel instancia el Store; no duplica su estado.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 13.1 | Modelar solicitud, documento y estados locales/remotos. | Ticket, factura, pago ausente, pending y failed. | Sin emisión previa al pago; toda operación cerrada tiene documento; Domain sin Firebase/PDFKit. |
| 13.2 | Implementar `ReserveBillingDocumentUseCase` y contrato remoto. | Request repetido, series independientes y conflicto. | API idempotente. |
| 13.3 | Implementar transacción Firestore atómica. | Fake transaccional, interrupción y concurrencia. | Número y documento nacen juntos. |
| 13.4 | Implementar `BillingDocumentStore` y `BillingViewModel`. | Máquina de estados, reintento y cancelación. | Sin estado duplicado. |
| 13.5 | Implementar selección y formulario fiscal. | Campos requeridos, validaciones y cancelación. | Textos localizados. |
| 13.6 | Implementar carga validada de plantillas y firma privada opcional. | Asset ausente, corrupto y válido; firma no autenticada o no disponible. | Error recuperable; la firma nunca está en el bundle. |
| 13.7 | Implementar `BillingPDFRenderer`. | Salida determinista, campos y páginas requeridas. | Render pesado fuera de MainActor. |
| 13.8 | Renderizar ticket y factura. | Snapshots de datos y PDF no vacío. | Revisión visual manual con plantillas reales. |
| 13.9 | Guardar PDF mediante Storage repository. | Upload repetido, offline, permiso y recuperación. | Ruta estable por document ID. |
| 13.10 | Materializar estado final en SwiftData. | Reinicio en cada frontera del flujo. | UI refleja siempre estado local. |
| 13.11 | Crear `EmailDraft` y adaptador de composición Apple. | Destinatario, asunto, cuerpo y adjunto. | Envío siempre manual. |
| 13.12 | Implementar `CloseSaleUseCase` e integrar el cierre de Jornada. | Ticket/factura, pago pendiente, documento pendiente, cierre repetido y reentrada. | Solo retira de Jornada tras pago y documento final; no duplica cierre, documento o número. |
| 13.13 | Implementar ajuste administrativo de series. | Autorización, límites y auditoría. | Operación explícita y trazable. |

## Resultado de fase

Documentos numerados y recuperables, PDF testeable, Storage aislado y correo manual sin dobles reservas.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), con subagente `$review-ios-standards` y segunda auditoría.
