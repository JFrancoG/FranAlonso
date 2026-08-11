# Plan SDD — Fran Alonso

Índice operativo para reconstruir la aplicación mediante Spec Driven Development, TDD y subfases revisables.

## Documentos obligatorios

- [AGENTS.md](../../AGENTS.md): reglas del repositorio y flujo Xcode MCP-only.
- [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md): protocolo obligatorio y Definition of Done de cada subfase.
- [Progress.md](../Progress.md): estado actual, evidencia, trabajo pendiente y bloqueos.
- [PULL_REQUEST_CHECKLIST.md](../PULL_REQUEST_CHECKLIST.md): checklist de entrega.
- [Índice de ADRs](../ADRs/README.md): decisiones propuestas, aceptadas y sustituidas.
- [Identidad cromática](../design/brand-palettes.md): paleta activa, alternativas y reglas de accesibilidad.
- [Navegación y Jornada](../design/navigation.md): shell simple, secciones y cierre operativo.

## Orden de fases

1. [Constitución](01_constitution.md)
2. [Bootstrap](02_project_bootstrap.md)
3. [Arquitectura y Observation](03_clean_architecture_observable.md)
4. [Modelo de dominio](04_domain_model.md)
5. [SwiftData, Firestore y sincronización](05_data_swiftdata_firestore_sync.md)
6. [Autenticación y sesión](06_auth_session.md)
7. [Design system y navegación simple](07_design_system_navigation.md)
8. [Clientes y consentimiento](08_clients_consent.md)
9. [Productos y stock](09_products_stock.md)
10. [Catálogo de servicios](10_services_catalog.md)
11. [Jornada y motor de ventas](11_sales_engine.md)
12. [Integración venta-stock](12_stock_sale_integration.md)
13. [Facturación, PDF, correo y numeración](13_billing_pdf_email_counters.md)
14. [Informes de ingresos](14_monthly_income_reports.md)
15. [Demo de citas](15_appointments_demo.md)
16. [Asistente de voz local](16_on_device_voice_assistant.md)
17. [Integración y endurecimiento](17_sync_integration_hardening.md)
18. [QA y entrega](18_qa_release.md)

Las fases 01–18 constituyen el MVP. Tras entregarlo:

19. [Proveedor remoto GPT-5.6 Luna](19_remote_assistant_luna.md) — evolución pos-MVP, no bloquea la entrega.

Los documentos de fase son la única fuente de verdad del plan. No se mantiene un plan consolidado duplicado.

## Uso con Codex

Para iniciar una subfase, proporcionar o cargar:

- `AGENTS.md` y `docs/DEVELOPMENT_GUIDE.md`.
- `docs/specs/01_constitution.md`.
- La fase y fila activa.
- Los ADR aceptados aplicables.
- Los contratos, `docs/Progress.md` y el diff del que dependa.

Invocar `$ios-development-standards` para implementar. Tras validar, crear un subagente nuevo con `$franalonso-review-ios-standards` para arquitectura, datos y concurrencia. Si existe alcance SwiftUI, crear en paralelo otro con `$franalonso-review-accessibility`; si no, registrar esa puerta como `N/A`. Corregir los hallazgos válidos y repetir solo la auditoría especializada cuyo ámbito cambie. Actualizar `docs/Progress.md` con la evidencia y el siguiente paso.

## Decisiones transversales

- Deployment target, SDK y Swift se obtienen del proyecto real; ninguna beta se adopta implícitamente.
- Xcode MCP es la única vía autorizada para builds, tests, previews y diagnósticos salvo autorización explícita del usuario.
- SwiftData es la fuente de verdad local; Firestore es la remota mientras siga vigente la excepción Firebase.
- La UI observa estado local y la sincronización es bidireccional, offline-first e idempotente.
- Cada pantalla conserva un `ViewModel` `@Observable @MainActor`. Un `Store` se extrae solo por complejidad o responsabilidad cohesiva demostrable.
- Las Views son declarativas, contienen un único tipo `View` por archivo, delegan acciones al ViewModel, usan las formas trailing closure de SwiftUI, limitan `@ViewBuilder` a composición real y escalan dimensiones custom no textuales con `@ScaledMetric` cuando deben seguir Dynamic Type.
- Las mutaciones del contexto principal siguen `View → ViewModel → closure @MainActor → adaptador Data`: la View solo pasa `ModelContext`, App compone la closure, Domain no conoce SwiftData y Data conserva CRUD/mapping/local-first sin importar Presentation.
- Cada `View` tiene un `#Preview` con el trait compartido `PreviewModifier`, `ModelContainer` de test y datos navegables; las pantallas afectadas se inspeccionan mediante Xcode MCP en `Large`, `XXX Large` y `AX 5` cuando estén soportados.
- Se aplica TDD con Swift Testing. No se crean XCTest, XCUITest ni tests UI nativos.
- Solo se permiten frameworks Apple, excepto los productos aprobados `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalyticsCore` y `FirebaseCrashlytics`; backend y telemetría conservan fronteras de sustitución independientes.
- El asistente del MVP usa APIs Apple estables y procesamiento local detrás de contratos propios. No eleva el target, adopta beta ni activa un fallback cloud silencioso.
- GPT-5.6 Luna queda preparado como proveedor textual pos-MVP; GPT Realtime no forma parte del plan y requeriría una decisión nueva.
- Toda decisión no trivial se documenta en `docs/ADRs/` antes de implementar.

## Reglas de producto invariantes

- Todo elemento cobrable es un `Service`; `Product` representa exclusivamente stock físico.
- Un servicio de tipo producto requiere `linkedProductID`.
- Las variantes de tamaño son productos distintos y, si se venden, servicios distintos.
- Stock insuficiente muestra advertencia y confirmación, pero no bloquea la venta.
- Ticket y factura usan secuencias remotas independientes y atómicas.
- Los documentos se generan como PDF y se adjuntan a un correo de envío manual.
- La agenda se limita a una demo local durante el MVP.
- La voz solo consulta, navega y rellena borradores. Nunca guarda ni confirma por voz; no retiene audio, transcripciones, prompts o respuestas y el flujo manual permanece completo.
