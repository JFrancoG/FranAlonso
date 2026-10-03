# 13.1 — Solicitud pagada y estados de facturación

## Autoridad y alcance

03/10/2026: «Abre issue y rama e implementa la subfase 13.1» autoriza issue, rama e implementación.
[PLU-96](https://linear.app/plusprojects/issue/PLU-96), Jesus Franco, In Progress;
`codex/plu-96-billing-domain-states`, baseline `38b49f4` limpio en main/origin/main.
Constitución, spec13, ADR0008/0003/0004/0011/0030 y política Swift gobiernan el cambio.
Esa autorización inicial no incluía commit, push, PR, merge, Done, live ni13.2.
Autorización posterior03/10/2026: «commit, push y entrega»; recorrido y resultado en [fase13](phase-13.md).
13.2 y live mantienen sus gates propios.

## Propuesta concreta

- Añadir `BillingDocumentRequest`, valor inmutable Codable construido con identidad estable de solicitud/documento,
  familia, snapshot de `Sale` pagada en `awaitingDocument` y fecha de solicitud. Rechazar ventas sin pago y terminales,
  fechas no finitas; el decoder aplica las mismas invariantes. El snapshot evita refrescar
  términos históricos y conserva el pago sin duplicar campos derivados.
- `BillingDocument` representa exclusivamente el registro numerado confirmado por una autoridad. Conserva la solicitud,
  número positivo de la familia correcta y fecha finita. Construcción/decoding validan el contrato.
  Este modelo no asigna números, no verifica Firestore ni promete documento PDF final.
- `BillingDocumentLocalState`: `pendingNumber(request)`, `failed(request, reason)` o `numbered(document)`;
  fallo neutral Codable sin strings de infraestructura. Pendiente/fallo carecen de número. Reintento conserva la misma
  solicitud; aceptar el resultado exige coincidencia exacta con el snapshot, incluidos IDs y familia. Resultado repetido
  idéntico es idempotente; resultado diferente es conflicto. Una confirmación remota recuperada puede resolver un fallo.
- Retirar la construcción de documento mediante solo `saleID`: permitía emitir sin prueba de pago. No tiene consumidores
  de producción fuera del tipo ni persistencia Billing/DTO/schema publicados. Evolución explícita del codec Domain
  preparatorio04.6; no se declara compatibilidad del payload antiguo sin pago verificable. Adaptar sus tests al contrato.
- `Sale.close(documentID:)` y sus codecs permanecen intactos: ya exigen pago y documento en terminales. La verificación
  entre agregados y documento final se integra en13.12;13.1 no declara un cierre final listo para uso real.

## Alternativas, riesgos y reversibilidad

Conservar fábricas con saleID deja el gate de pago eludible. Añadir booleano paid o metadatos opcionales permite estados
contradictorios. Se elige solicitud validada y snapshot; a cambio aumenta el payload Domain y acopla Billing al agregado
Sales ya existente. Data podrá definir DTO propios13.3/13.10 sin filtrar Firebase. Mantener documento pending confunde
intención local y registro remoto: se separan con enums/value types, sin Store ni repositorio anticipados.
No hay datos Billing persistidos que migrar; si aparece un consumidor real no inventariado, detener y reevaluar.
El fallo conserva identidad para recuperar un commit remoto cuyo resultado se perdió; no reintenta ni consume series.

## Archivos y validación

Billing/Domain/Entities y ValueObjects; BillingDocumentTests y nueva suite focal; este registro, fase13 y Progress.
TDD primero: ausencia de pago/terminales, ambos tipos, pending/failed, recuperación y conflictos; entradas Codable
adversariales, fechas/series y conservación del snapshot. RED ejecutable cuando exista superficie mínima compilable;
GREEN focal y regresión Sale/Workday; builds Develop/Production y diagnósticos Xcode MCP. PRE y POST independientes,
estilo scoped y gobernanza. UI/previews/localización/accesibilidad nueva N/A: solo Domain sin pantalla.

## Baseline y fuentes

Xcode MCP oficial estable, Service `workspace-PfnUYLlMzY`, FranAlonso.xcodeproj; Develop activo, iPad Pro13-inch(M5)
Simulator27.2, SDK27.0; target27.0, Swift6, concurrencia complete/nonisolated, warnings Swift/Clang como errores.
Inventario1491declaraciones habilitadas. Última evidencia válida12.8:2368ejecuciones PASS, buildsDevelop/Production y
PRE/POST PASS; main38b49f4 documenta entrega sin cambios ejecutables posteriores.
Fuentes: spec13/ADR0008, modelos/tests reales04.6 y Sale; [Apple Codable](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types).
No API Apple nueva incierta, dependencia, excepción unsafe ni target nuevo.

PRE independiente `billing_13_1_pre`: PASS sin hallazgosP0–P3 antes del código. Revisión operacional read-only:
904archivos, SHA256 inicial/final/root `8c40dc936bd9975b654a59b5b732d71881fad66f76e5643c5b6eb9e4ad504568`.
Fuente Apple completa recuperada por el revisor y contraste adicional mediante Xcode DocumentationSearch.
Baseline focal actual:35/35ejecuciones PASS,0failed/skipped/expected/notRun, Billing/Sale/Workday.
Build baseline sin warnings Swift/Clang; conserva aviso conocido AppIntents metadata (app y target test).

## Corrección de propuesta tras POST

POST independiente identificóP2 en las comparaciones solicitada/emitida>=paidAt del primer diseño.
paidAt procede del reloj local; otro dispositivo, corrección del reloj o autoridad remota pueden usar otro reloj.
La precedencia exigida por spec13 es causal: venta en awaitingDocument tras pago registrado. Las fechas son metadatos
finitos preservados exactamente, sin comparar relojes ni normalizarlos para fabricar orden.
[Firestore server timestamp](https://firebase.google.com/docs/firestore/manage-data/add-data#server_timestamp) documenta
la hora de recepción del servidor; con la captura local paymentDate() se infiere la ausencia de reloj común garantizado.
El revisor `billing_13_1_post` aprueba read-only esta corrección mínima antes de código: RED2 de desfase en
construcción/decoding/aceptación, retirar ambas comparaciones/invalidChronology y repetir validación/auditoría focal.
No cambia el gate de pago, el snapshot, el codec validante ni el alcance13.1.
