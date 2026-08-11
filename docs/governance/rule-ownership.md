# Propiedad de reglas tras la optimización

Esta matriz demuestra que reducir archivos siempre cargados no elimina reglas vigentes. Una regla estable vive en un
documento versionado; un skill solo explica cuándo y cómo aplicarla.

| Regla anterior | Vigencia | Propietario canónico | Routing | Validador posible |
|---|---|---|---|---|
| Autoridad, evidencia y aprobación exacta | Sí | Constitución, Plataforma y evidencia | `AGENTS.md` | Parcial: estructura, no semántica |
| Capas, View/ViewModel y `ModelContext` | Sí | Constitución + ADR 0011 | `$ios-development-standards` | Revisión estática/especialista |
| DTO/model conversion y Mapper justificado | Sí | `docs/standards/swift-code-policy.md` | `$ios-development-standards` | Parcial mediante búsqueda |
| `enum` sin casos como namespace | Sí | `docs/standards/swift-code-policy.md` | `$ios-development-standards` | Parcial mediante búsqueda |
| Inicializadores, factories e invariantes | Sí | `docs/standards/swift-code-policy.md` | `$ios-development-standards` | Revisión semántica |
| Conformidades e inferencia `Sendable` | Sí | Política Swift + constitución | `$ios-development-standards` | Compilador + revisión |
| Formato de firmas, variables, guards y helpers | Sí | `docs/standards/swift-code-policy.md` | `$ios-development-standards` | SwiftLint/diff focalizado |
| DocC semántico | Sí | Política Swift | `$ios-development-standards` | Parcial mediante diff |
| Valores `Money`, moneda, IVA, descuentos e invariantes numéricas | Sí | `docs/specs/04_domain_model.md` | Spec de subfase activa | Swift Testing + revisión |
| Modelado y ciclo de vida de Product/Service | Sí | `docs/specs/04_domain_model.md` y specs 09–10 | Spec de subfase activa | Swift Testing + revisión |
| Stock negativo, avisos y consumo por venta | Sí | Specs 04, 09 y 12 | Spec de subfase activa | Swift Testing |
| Numeración documental atómica e idempotente | Sí | ADR 0008 + `docs/specs/13_billing_pdf_email_counters.md` | Spec de subfase activa | Swift Testing + integración |
| Jornada, Histórico y visibilidad de operaciones anuladas | Sí | `docs/design/navigation.md` + specs 07, 11 y 12 | Spec de subfase activa | Preview + tests de estado |
| PDFs de consentimiento, ticket y factura | Sí | Specs 02, 08 y 13 | Spec de subfase activa | Recurso/build + render manual |
| Agenda local demo | Sí | `docs/specs/15_appointments_demo.md` | Spec de subfase activa | Swift Testing + preview |
| Una View por archivo, builders, previews, escalado | Sí | ADR 0011 | `$ios-accessibility-implementation` | Búsqueda + preview + auditoría |
| Objetivo de accesibilidad nativa | Sí | ADR 0022 + matriz WCAG | Skills UI y revisor | Matriz + evidencia manual |
| SwiftData/Firebase/offline-first | Sí | Constitución + ADR 0002/0006/0007/0012–0018 | `$ios-development-standards` | Tests + revisión |
| Swift Concurrency y prohibiciones unsafe | Sí | Constitución | `$ios-development-standards` | Compilador + búsqueda |
| APIs legacy/deprecated y target real | Sí | Constitución | `$ios-development-standards`, `$cupertino-mcp` | Compilador + búsqueda |
| Swift Testing sin UI tests | Sí | Constitución + ADR 0003 | Skills inicio/cierre | Config + búsqueda |
| Assistant on-device y solo propuestas reversibles | Sí | Constitución + ADR 0010 | Skill de fase aplicable | Revisión de capacidades |
| Privacidad, telemetría y secretos | Sí | Constitución + ADR aplicable | Skills inicio/cierre | Búsqueda + revisión |
| Xcode MCP, Linear, Obsidian y entrega | Sí | `AGENTS.md` + guía | Skills inicio/cierre | Estado de herramientas |

## Regla de mantenimiento

- Si una regla cambia el producto o arquitectura, crear/sustituir ADR.
- Si una regla es estable y transversal, actualizar constitución o una referencia versionada enlazada desde ella.
- Si cambia el procedimiento, actualizar el skill.
- Si una condición es sintáctica y de alta confianza, valorar un validador o hook con fixtures.
