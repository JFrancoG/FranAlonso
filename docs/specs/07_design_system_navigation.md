# Fase 07 — Design system, localización y navegación

## Objetivo

Construir una interfaz iPad-first adaptable, localizada y accesible, con componentes semánticos y navegación tipada,
sin introducir lógica de negocio en Views.

## Decisiones de fase

- Paletas aprobadas: [`../design/brand-palettes.md`](../design/brand-palettes.md).
- Navegación aprobada: [`../design/navigation.md`](../design/navigation.md).
- Accesibilidad: ADR 0022 y [`../accessibility/WCAG22_AA_IOS.md`](../accessibility/WCAG22_AA_IOS.md).
- Tokens y componentes viven en `Shared/Presentation` solo cuando existe reutilización real.
- La raíz autenticada usa `TabView` con `.sidebarAdaptable`; `AppShellViewModel` posee `AppSection` y comienza en Jornada.
- Cada sección conserva su `NavigationStack`; las rutas tipadas son locales y solo existen si hay varios destinos.
- No se crea router global, `NavigationPath` global, deep links ni restauración completa sin requisito demostrado.
- Jornada, Histórico, Clientes, Catálogo e Informes son secciones principales; Agenda permanece auxiliar `Demo`.
- Formularios y ediciones identificadas usan `.sheet(item:)`.
- Carga, vacío, contenido y error se representan explícitamente.

## Subfases

| ID | Alcance | Evidencia principal |
|---|---|---|
| 07.1 | Tokens visuales y nombres semánticos desde la paleta aprobada. | Catálogo, cuatro apariencias, contraste y Dynamic Type. |
| 07.2 | Botones, campos, filas y tarjetas reutilizables. | Tests de lógica fuera de View, estados, interacción y accesibilidad. |
| 07.3 | Vistas de carga, vacío y error. | Estados de ViewModel, previews y localización completa. |
| 07.4 | Confirmación genérica y alerta de stock semántica. | Política, foco, anuncio y acciones accesibles. |
| 07.5 | `AppSection`, `AppShellViewModel` y rutas locales necesarias. | Selección, push/pop y presentación por identidad. |
| 07.6 | Shell adaptable con Jornada inicial. | Estado por sección, iPhone, iPad, orientación y multitarea. |
| 07.7 | Completar `Localizable.xcstrings`. | Claves, placeholders, truncamiento y RTL. |

## Criterio de cierre

Cada subfase usa `$franalonso-start-subphase` y `$franalonso-finish-subphase`. Toda pantalla aplica
`$ios-accessibility-implementation`, completa la evidencia de ADR 0022 y supera ambos revisores especializados cuando
corresponda. Las reglas globales no se repiten aquí: rigen la constitución, ADR y guía de desarrollo.

## Resultado

Sistema visual y navegación moderna, accesible, localizada y desacoplada de infraestructura.
