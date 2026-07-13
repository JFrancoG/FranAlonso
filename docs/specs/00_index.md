# Plan SDD — Fran Alonso

Índice operativo para reconstruir la aplicación mediante Spec Driven Development, TDD y subfases revisables.

## Documentos obligatorios

- [AGENTS.md](../../AGENTS.md): reglas del repositorio y flujo Xcode MCP-only.
- [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md): protocolo obligatorio y Definition of Done de cada subfase.
- [Progress.md](../Progress.md): estado actual, evidencia, trabajo pendiente y bloqueos.
- [PULL_REQUEST_CHECKLIST.md](../PULL_REQUEST_CHECKLIST.md): checklist de entrega.
- [Índice de ADRs](../ADRs/README.md): decisiones propuestas, aceptadas y sustituidas.

## Orden de fases

1. [Constitución](01_constitution.md)
2. [Bootstrap](02_project_bootstrap.md)
3. [Arquitectura y Observation](03_clean_architecture_observable.md)
4. [Modelo de dominio](04_domain_model.md)
5. [SwiftData, Firestore y sincronización](05_data_swiftdata_firestore_sync.md)
6. [Autenticación y sesión](06_auth_session.md)
7. [Design system y navegación](07_design_system_navigation.md)
8. [Clientes y consentimiento](08_clients_consent.md)
9. [Productos y stock](09_products_stock.md)
10. [Catálogo de servicios](10_services_catalog.md)
11. [Motor de ventas](11_sales_engine.md)
12. [Integración venta-stock](12_stock_sale_integration.md)
13. [Facturación, PDF, correo y numeración](13_billing_pdf_email_counters.md)
14. [Informes de ingresos](14_monthly_income_reports.md)
15. [Demo de citas](15_appointments_demo.md)
16. [Integración y endurecimiento](16_sync_integration_hardening.md)
17. [QA y entrega](17_qa_release.md)

Los documentos de fase son la única fuente de verdad del plan. No se mantiene un plan consolidado duplicado.

## Uso con Codex

Para iniciar una subfase, proporcionar o cargar:

- `AGENTS.md` y `docs/DEVELOPMENT_GUIDE.md`.
- `docs/specs/01_constitution.md`.
- La fase y fila activa.
- Los ADR aceptados aplicables.
- Los contratos, `docs/Progress.md` y el diff del que dependa.

Invocar `$ios-development-standards` para implementar. Tras validar, crear un subagente nuevo con `$review-ios-standards` en modo de solo lectura. Corregir los hallazgos válidos y repetir la auditoría antes de cerrar la subfase. Actualizar `docs/Progress.md` con la evidencia y el siguiente paso.

## Decisiones transversales

- Deployment target, SDK y Swift se obtienen del proyecto real; ninguna beta se adopta implícitamente.
- Xcode MCP es la única vía autorizada para builds, tests, previews y diagnósticos salvo autorización explícita del usuario.
- SwiftData es la fuente de verdad local; Firestore es la remota mientras siga vigente la excepción Firebase.
- La UI observa estado local y la sincronización es bidireccional, offline-first e idempotente.
- Cada pantalla conserva un `ViewModel` `@Observable @MainActor`. Un `Store` se extrae solo por complejidad o responsabilidad cohesiva demostrable.
- Se aplica TDD con Swift Testing. No se crean XCTest, XCUITest ni tests UI nativos.
- Solo se permiten frameworks Apple, excepto Firebase Auth, Firestore y Storage mientras se prepara la migración a Vapor.
- Toda decisión no trivial se documenta en `docs/ADRs/` antes de implementar.

## Reglas de producto invariantes

- Todo elemento cobrable es un `Service`; `Product` representa exclusivamente stock físico.
- Un servicio de tipo producto requiere `linkedProductID`.
- Las variantes de tamaño son productos distintos y, si se venden, servicios distintos.
- Stock insuficiente muestra advertencia y confirmación, pero no bloquea la venta.
- Ticket y factura usan secuencias remotas independientes y atómicas.
- Los documentos se generan como PDF y se adjuntan a un correo de envío manual.
- La agenda se limita a una demo local durante el MVP.
