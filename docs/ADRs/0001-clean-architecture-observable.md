# ADR 0001 — Clean Architecture con ViewModel y Store opcional

## Estado

Propuesto

## Contexto

La cadena anterior `Interactor → ModelLogic → ViewModel` superponía orquestación y estado observable, favoreciendo duplicación. La aplicación necesita límites testeables sin frameworks de arquitectura externos y debe permitir dividir ViewModels complejos sin eliminarlos.

## Opciones consideradas

1. Mantener Interactor/ModelLogic/ViewModel: más tipos, pero responsabilidades ambiguas.
2. ViewModel directo a implementaciones Data: menos código, pero Presentation queda acoplada.
3. Clean Architecture por feature con UseCases, Repository y Store opcional: separación clara y complejidad incremental.

## Decisión

Organizar por feature y después por `Domain`, `Data` y `Presentation`, con composición en `App`. Cada pantalla conserva un `ViewModel` `@Observable @MainActor`. Solo cuando exista una responsabilidad cohesiva extraíble, el ViewModel instancia y conserva un `Store` `@Observable @MainActor`. Domain define casos de uso y contratos; Data los implementa.

## Consecuencias

### Positivas

- Firebase y SwiftData no alcanzan Presentation o Domain.
- ViewModels siguen siendo la fachada estable de pantalla.
- Stores reducen Massive ViewModels sin convertirse en capa obligatoria.

### Negativas y riesgos

- Hay más mappers y límites explícitos.
- Una aplicación mecánica puede crear protocolos o Stores ceremoniales; la revisión debe exigir responsabilidad real.

## Testing y validación

- Swift Testing para UseCases, repositories, Stores y ViewModels.
- `$review-ios-standards` comprueba imports, dependencias, estado duplicado y nomenclatura.

## Migración o reversibilidad

Los límites por contratos permiten sustituir implementaciones sin cambiar Views. Un Store puede volver al ViewModel si deja de representar una responsabilidad independiente.
