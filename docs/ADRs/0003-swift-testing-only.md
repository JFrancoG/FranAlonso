# ADR 0003 — Swift Testing sin tests UI nativos

## Estado

Propuesto

## Contexto

El proyecto necesita TDD para dominio, persistencia, sincronización y presentación observable. Los flujos previstos no justifican por ahora el coste de mantener automatización UI nativa.

## Opciones consideradas

1. XCTest/XCUITest completos: cobertura UI, mayor coste y mezcla de frameworks.
2. Swift Testing para lógica e integración, previews y QA manual para UI.
3. Sin tests automatizados: coste inicial bajo, riesgo de regresiones alto.

## Decisión

Usar exclusivamente Swift Testing para tests unitarios y de integración. No crear XCTest, XCUITest ni tests UI nativos. Validar UI mediante ViewModels/Stores, previews deterministas y checklists manuales.

## Consecuencias

- Suite moderna, paralela y centrada en comportamiento.
- Los recorridos visuales requieren disciplina manual; si el producto crece, un nuevo ADR reconsiderará automatización UI.

## Testing y validación

- RED/GREEN/REFACTOR en toda subfase que cambie comportamiento ejecutable. Documentación, QA manual y distribución usan `N/A` justificado y evidencia proporcional; cualquier corrección de código vuelve a TDD.
- Fakes de Firestore/Storage, ModelContainer in-memory y reloj/UUID inyectados.
- Build y tests mediante Xcode MCP.
