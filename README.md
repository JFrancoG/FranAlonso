# FranAlonso

Aplicación iOS reconstruida con SwiftUI mediante Spec Driven Development y TDD. La constitución y el bootstrap están completos; la implementación de producto todavía no ha comenzado.

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

Las fases 01 y 02 están completas, incluidos los ADR 0001–0009 y la gobernanza del bootstrap. La siguiente subfase es 03.1, primera vertical mínima de arquitectura.
