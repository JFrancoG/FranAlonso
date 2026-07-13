# Fase 07 — Design system, localización y navegación

## Objetivo

Construir una interfaz iPad-first adaptable, componentes semánticos, rutas tipadas y recursos localizados sin introducir lógica de negocio en las Views.

## Diseño

- Tokens y componentes viven en `Shared/Presentation` cuando se reutilizan de verdad.
- Las pantallas de cada feature permanecen dentro de su `Presentation`.
- Navegación modelada con enums de rutas y estado observable en `AppRouter` `@MainActor`.
- Se usa la API moderna compatible con el deployment target comprobado; Cupertino MCP resuelve cualquier diferencia de versión.
- Dynamic Type, VoiceOver, contraste, tamaños de ventana, orientación e iPad multitarea forman parte de la revisión manual.
- Carga, vacío, contenido y error se representan explícitamente.
- No se crean tests UI nativos; las reglas se prueban fuera de la View y los estados visuales mediante previews deterministas.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 07.1 | Definir tokens visuales y nombres semánticos de assets. | Validación de catálogo y recursos obligatorios. | Previews claro/oscuro y Dynamic Type. |
| 07.2 | Crear botones, campos, filas y tarjetas reutilizables. | Probar formatters/validadores fuera de View. | Previews de estados e interacción manual. |
| 07.3 | Crear vistas de carga, vacío y error. | Estados del ViewModel que las alimentan. | Sin strings hardcodeadas. |
| 07.4 | Crear confirmación genérica y alerta de stock semántica. | Política de presentación/acciones. | Accesibilidad y foco correctos. |
| 07.5 | Implementar `AppRoute` y `AppRouter`. | Push, pop, deep state y restauración soportada. | Rutas tipadas, sin strings mágicas. |
| 07.6 | Construir shell iPad-first adaptable. | Estado de selección/navegación. | iPad, iPhone y multitarea acordados. |
| 07.7 | Completar `Localizable.xcstrings`. | Comprobación de claves críticas y placeholders. | Sin texto visible fuera del catálogo. |

## Resultado de fase

Sistema visual y navegación moderna, accesible, localizada y desacoplada de infraestructura.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluido subagente `$review-ios-standards` y segunda auditoría.
