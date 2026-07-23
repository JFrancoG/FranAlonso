# FranAlonso

Aplicación iOS reconstruida con SwiftUI mediante Spec Driven Development y TDD. La constitución, el bootstrap y la primera vertical de arquitectura están completos; el modelo de dominio está en curso.

## Fuentes de verdad

- [Guía de desarrollo](docs/DEVELOPMENT_GUIDE.md)
- [Índice de especificaciones](docs/specs/00_index.md)
- [Constitución del proyecto](docs/specs/01_constitution.md)
- [Progreso actual](docs/Progress.md)
- [Decisiones de arquitectura](docs/ADRs/README.md)
- [Checklist de pull request](docs/PULL_REQUEST_CHECKLIST.md)

## Flujo de trabajo

Cada subfase se ejecuta siguiendo `docs/DEVELOPMENT_GUIDE.md`: preflight, TDD con Swift Testing cuando corresponda, validación, auditoría independiente y actualización de `docs/Progress.md`.

Los builds, tests, previews y diagnósticos se realizan exclusivamente mediante el Xcode MCP oficial. No se usa `xcodebuild`.

## Estado

Las fases 01–03 y las subfases 04.1–04.3 están completas. La puerta actual es 04.4, el cálculo determinista de ventas. El MVP incorpora en la fase 16 un asistente de voz local con Foundation Models; la fase 19 prepara GPT-5.6 Luna como proveedor textual opcional después de entregar el MVP. GPT Realtime queda como alternativa no planificada.
