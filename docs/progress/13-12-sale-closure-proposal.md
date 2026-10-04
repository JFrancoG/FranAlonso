# 13.12 — Cierre local idempotente y Jornada

## Estado y autorización

04/10/2026 Europe/Madrid. «abre issue y rama e implementa13.12» autoriza la implementación local exacta.
[PLU-109](https://linear.app/plusprojects/issue/PLU-109), Jesus Franco, In Progress;
rama`codex/plu-109-close-billed-sales`, base main/origin/main`8a4af43a7d40ac1d72c939dab4f0f3613dc41bee`,
limpia y sincronizada. No autoriza entrega Git, Done,13.13, servicios live ni correo real.
PRE independiente obligatorio antes de código ejecutable; esta propuesta conserva el resultado al registrarlo.

PRE`billing_13_12_pre` PASS/Sin hallazgosP0–P3 antes de código, 1061files inicial/final/revisor/root idénticos
`98f9f777d7e05be796387ae4595c72dabd3fddb268a2c79fad4cc072743f9012` antes de registrar el dictamen.
Confirma separación del cierre y upload, alcance demo, APIs/alternativas, baseline y límites.
La autorización expresa del usuario ya permite iniciar esta implementación exacta sin ampliaciones.

Xcode MCP oficial stable en modo Service: proyecto absoluto verificado,
workspace`workspace-DSfPhPVzqA`, Develop/testplanDevelop, destino inicial iPhone18Pro.
GetTargetBuildSettings confirma iOS27.0/SDKsimulator27.0/Swift6/strict complete/defaultnonisolated;
warnings Swift/Clang como errores. Ningún cambio de plataforma/configuración previsto.
Baseline13.11:75nuevos/113focales/globalúnico2941/2941PASS, builds Develop/Production y revisionesPASS.
Fuentes/configuración siguen idénticas tras su entrega; baseline reutilizable, no prueba anticipada de13.12.
Ocho links externos históricos/temporales y avisos AppIntents2/1 siguen siendo límites conocidos.

## Autoridad y frontera del documento

Constitución, spec13/fila13.12 y spec11 fijan pago previo, número definitivo, PDF final y retirada de Jornada.
Spec11 declara expresamente que subida/correo pendientes no reabren Jornada. Se aplica ese criterio al cierre:
un delivery local autorizado debe conservar documento confirmado y PDF final validado, aunque aún no tenga receipt.
No se cambia `BillingDocumentDelivery.isFinal`: continúa describiendo finalización de subida13.10, con receipt.
Se separan los dos contratos: preparación de correo13.11 conserva su requisito de upload final; el cierre13.12
no exige enviar correo ni terminar Storage. El outbox conserva checkpoint, failure y retry tras cerrar la venta.
La propuesta13.10 dejó expresamente fuera el cierre; su gate de Storage no sustituye la regla normativa de spec11.

ADR0008 mantiene request estable, series independientes y número+documento atómicos.
ADR0002/0021 mantienen SwiftData local y autorización del principal. ADR0011 mantiene contexto efímero en ViewModel
y una primitiva Data compartida. ADR0022/0029 gobiernan UI y evidencia; ADR0030 permite proveedores sintéticos de demo.
El perfil maintenance de autoridad local prevalece sobre defaults genéricos de skills SwiftData.

## Comportamiento aprobado

1. `CloseSaleUseCase` acepta un comando de cierre sobre snapshot pagado, requestID explícito y fecha finita.
   Domain define comando y política de aceptación; no importa SwiftData/UI/Firebase. El Repository falla cerrado
   por defecto cuando no implementa la capacidad específica: no se usa SaveSaleUseCase para fabricar un cierre.
2. Data relee venta y `BillingDocumentDeliveryModel` en el mismo contexto limpio, sin suspensión entre validación y save.
   Su decode completo verifica envelope/índices/PDF. Exige principal/request/document/venta/pago y snapshot comercial
   íntegros, detecta claim del documento por otra venta, conflicto y deletion/tombstone. Nunca usa solo número/ID.
3. Primera aceptación guarda venta cerrada y successor causal juntos en un solo save; no toca documento, número,
   PDF, receipt ni stock. Replay sobre el mismo documento conserva fecha almacenada y eventual anulación,
   sin otro save/upsert. Fecha nueva de reentrada no sustituye la primera aceptación durable.
4. Repository y adapter contextual comparten esa primitiva. El UseCase/cierre contextual valida la capability
   `BillingAssetAccess`; conocer UID no concede acceso. Solo se publica observación tras aceptación local.
   Cancelación anterior al commit aborta; posterior no deshace cierre. Generaciones revocan publicaciones UI tardías.
5. Billing Store/ViewModel conserva una sola selección/delivery y coordina generación, recuperación, cierre/error/retry.
   View solo renderiza y envía intenciones; el contexto principal pasa efímero por ViewModel y closure App→Data.
   El cierre nunca reserva/renderiza/sube/envía por sí mismo. Jornada observa el mismo repositorio y retira/dismiss
   únicamente el snapshot local closed/voided; Histórico muestra el cierre. Detalle histórico sigue read-only.
6. Activar en el formulario el recorrido explícito: selección fiscal→preparación durable→generación del PDF→cierre manual.
   La composición normal conserva numeración/Storage remotos no disponibles, sin construir proveedores live;
   representa pendiente/error y no elimina la venta. Recursos locales aprobados no activan Firebase ni firmas privadas.
7. La demo reutilizable Debug-Develop añade un adaptador de reserva idempotente con series sintéticas separadas
   y registro coherente, render real con marca inequívoca DEMO/muestra y Storage simulado, sobre el contenedor
   existente en memoria. Reiniciar recrea escenario, sin prometer durabilidad demo. Sin Mail real ni secuencias reales.
   Usar factories concretas y un puente explícito solo en la frontera que requiere sustituir normal/demo en runtime.

## Áreas y reversibilidad

- Sales Domain: nuevo comando/política/UseCase y capacidad específica en SaleRepository.
- Sales Data: SaleLocalDataSource, actor, DefaultSaleRepository y adapter contextual; sin schema/migración.
- Billing Presentation: Store/estado/ViewModel, Screen/SelectionContent y componente de progreso/cierre con preview propio.
- App: factories Billing, composición local/demo, proveedores demo aislados y fixtures/previews deterministas afectados.
- Resources/Tests: nuevos textos es/en e inventario; tests nuevos de cierre/persistencia/reentrada/Jornada/demo.
- Docs: CHANGELOG, Progress, phase13 y matriz55 propia del nuevo flujo; conservar deudaPLU-108/101 y demás límites.

Revertir la nueva composición/control conserva pago, outbox, PDF y cierres ya aceptados; no cambia esquema5.0.0.
No se promete CAS entre contextos independientes ni transacción entre dos actors. Se conserva la primitiva actual.

## Alternativas descartadas

Guardar un snapshot closed libre: elude existencia/correlación del PDF y cola causal.
Leer Billing por actor y guardar Sale después: abre TOCTOU entre la autorización del documento y aceptación local.
Esperar envío/receipt para cerrar: contradice spec11 y deja trabajo pagado con PDF ocupando Jornada.
Reservar otro request al reabrir: puede consumir números duplicados; recuperar familia antes de generar identidad.
Simular éxito directamente en UI: elude reglas y no demuestra cierre; usar capas reales con proveedores aislados.
Activar Firestore/Storage reales: gate live distinto, no necesario para demostrar el cierre autorizado.

## TDD y validación

RED con APIs compilables pero conducta inerte; guardar resultados originales. GREEN sin acomodar tests al código.
Domain: ticket/factura, pago ausente, número/PDF ausentes, datos/pago obsoletos, request ajeno, replay y void posterior.
Data: decode/correlaciones/principal/claim ajeno; conflicto/deletion; save fallido/rollback; contexto sucio intacto;
cancelación pre/post aceptación; fila y cola observables desde contexto independiente, reapertura file-backed y replay sin writes.
Presentation: recuperación de request, reentrada/retry y fechas estables; operación simultánea/cierre de sesión/respuesta tardía;
Jornada→Histórico mediante aceptación real. Demo: IDs/series/PDF sintéticos y sin doble reserva/documento/cierre.
TDD focal por ámbito, regresión Sales/Billing/Workday/localización y un global final. Develop/Production y diagnósticos
por Xcode MCP, estilo read-only sobre todos los Swift cambiados antes de validación final.
Previews representativas Large/XXX Large/AX5 y smoke manual del recorrido de demo, incluidos pending/error/reentrada
y ticket/factura. Auditores POST independientes técnico/UI, con freeze completo reproducible antes/después.
Matriz55 propia: resultados limitados/manuales pendientes explícitos, responsable Jesus Franco y recuperación tras
feedback/estabilización antes del candidato real. La implementación local mantiene esa deuda en PLU-109; cualquier
transferencia/cierre funcional posterior conserva autorización de entrega propia.

## Fuentes primarias y límites

[Apple ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext), leído mediante Cupertino:
contexto de entorno MainActor, tracking de cambios, save/autosave/rollback. Corpus indica crawl08/05/2026;
disponibilidad y contrato se contrastan con SDK27.0 y build real, sin asumir CAS externo ni APIs nuevas.
Las implementaciones actuales de aceptación pago/anulación y observers son evidencia del patrón concreto local.
ADR0022 enlaza Apple HIG y WCAG2ICT; controles nativos, labels visibles,44pt, anuncios/foco y AX5 por construcción.
Previews/tests no acreditan Inspector/VoiceOver/VoiceControl/SwitchControl/teclado físico ni contraste integral.
Sin datos reales, secretos, payloads en logs, activación live, envío real,13.13 o entrega Git.

## Corrección autorizada por POST — recuperación de ambas familias

POST original read-only técnico detecta P2: load sin kind ante ticket+factura retenidos bloquea selección/retry.
POST UI detecta P3: recoveryFailed sin actividad muestra «Recuperando…». Ambos informes y root conservan
1136 archivos/digest idéntico `cfd5138c1a20ae5515ca4563ef84f14239d5910b46f340da3e21a43c43431d0d`.
La corrección pertenece a la recuperación/reentrada de13.12 ya autorizada; no amplía emisión ni cierre.
PRE correctivo independiente billing_13_12_post favorable antes de conducta ejecutable:
representar ambigüedad y permitir Picker+acción explícita recoverFamily(kind), capturada en la intención.
Recuperar únicamente familia retenida; conservar IDs/número/PDF y no preparar/reservar/renderizar/subir.
Ausencia/error mantiene elección; una única familia se recupera automáticamente. Preparación/edición fiscal
permanecen bloqueadas hasta recuperación válida. Texto de error detenido localizado es/en.
Guarda parent @MainActor efímera en Store/runDurable antes/después operación y relectura fallback, antes
de publicar estado nuevo; si falla, conservar solo checkpoint anterior. Capability Data y fences permanecen.
Tomar primera UUID o emitir otra familia contradice13.10; una nueva autoridad/Store no se justifica.
TDD RED→GREEN observa ambas familias, identidades/filas/motores y revocación/cancelación; luego regresión,
builds/diagnósticos, previews de elección/error y POST afectados. Sin cambios schema/targets/dependencias.
