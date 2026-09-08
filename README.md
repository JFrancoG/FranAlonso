# FranAlonso

Aplicación iOS reconstruida con SwiftUI mediante Spec Driven Development y TDD.

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

Las fases 01–06 están cerradas. Las entregas de la fase 07 y la limpieza Swift PLU-33 están integradas; 07.4 queda diferida a 12.3–12.4. La puerta actual es el cierre independiente de fase 07 / PLU-25. La siguiente propuesta es 08.1, contratos y casos de uso CRUD/búsqueda de Clientes, todavía sin iniciar.

El [progreso actual](docs/Progress.md) y el [detalle de fase 07](docs/progress/phase-07.md) mantienen la evidencia y los pendientes. El [índice de especificaciones](docs/specs/00_index.md) fija el orden del roadmap.

## Obsidian

La raíz de este repositorio es el vault `FranAlonso`. Obsidian consulta y edita directamente los documentos versionados, incluidos progreso, specs y ADR. El índice del vault personal enlaza a estos archivos; su diario de desarrollo permanece como histórico. La configuración local `.obsidian/` queda excluida de Git.
