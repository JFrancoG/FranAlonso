# Fase 07 — Design system, localización y navegación

## Objetivo

Construir una interfaz iPad-first adaptable, componentes semánticos, rutas tipadas y recursos localizados sin introducir lógica de negocio en las Views.

## Diseño

- Tokens y componentes viven en `Shared/Presentation` cuando se reutilizan de verdad.
- Las pantallas de cada feature permanecen dentro de su `Presentation`.
- La identidad cromática y sus alternativas están definidas en [brand-palettes.md](../design/brand-palettes.md).
- La navegación acordada está definida en [navigation.md](../design/navigation.md).
- La raíz autenticada usa `TabView` con estilo `.sidebarAdaptable`; un `AppShellViewModel` mínimo posee la selección `AppSection` y comienza en Jornada.
- Cada sección conserva un `NavigationStack` y define rutas tipadas locales solo cuando existen varios destinos.
- No se crea un `AppRouter`, un `NavigationPath` global, deep links o restauración completa durante el MVP sin un requisito demostrado.
- Jornada, Histórico, Clientes, Catálogo e Informes son secciones principales. Agenda permanece como acceso auxiliar `Demo`.
- Formularios y ediciones dirigidos por un elemento usan `.sheet(item:)`.
- Se usa la API moderna compatible con el deployment target comprobado; Cupertino MCP resuelve cualquier diferencia de versión.
- Dynamic Type, VoiceOver, contraste, tamaños de ventana, orientación e iPad multitarea forman parte de la revisión manual.
- Carga, vacío, contenido y error se representan explícitamente.
- No se crean tests UI nativos; las reglas se prueban fuera de la View y los estados visuales mediante previews deterministas.
- Cada archivo contiene un único tipo que conforme a `View`; las subviews extraídas viven en archivos propios.
- Las Views solo renderizan estado y llaman al ViewModel. Usan trailing closures en APIs SwiftUI y reservan `@ViewBuilder` para composición real con varios hijos o ramas heterogéneas.
- Toda dimensión numérica explícita de contenido no textual significativo que deba seguir Dynamic Type usa `@ScaledMetric(relativeTo:)`, salvo adaptación automática o tamaño fijo justificado.
- Cada `View` tiene un `#Preview` en su archivo con el trait `PreviewModifier` compartido, `ModelContainer` de test en memoria y datos deterministas, idempotentes y suficientes para usar la app.
- Xcode MCP renderiza e inspecciona cada pantalla afectada en las variantes soportadas `Large`, `XXX Large` y `AX 5`; VoiceOver y la semántica no demostrable por snapshots conservan una validación separada.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 07.1 | Implementar tokens visuales y nombres semánticos desde la paleta aprobada. | Validación de catálogo y recursos obligatorios. | Cuatro apariencias, contraste y previews con Dynamic Type. |
| 07.2 | Crear botones, campos, filas y tarjetas reutilizables. | Probar formatters/validadores fuera de View. | Previews de estados e interacción manual. |
| 07.3 | Crear vistas de carga, vacío y error. | Estados del ViewModel que las alimentan. | Sin strings hardcodeadas. |
| 07.4 | Crear confirmación genérica y alerta de stock semántica. | Política de presentación/acciones. | Accesibilidad y foco correctos. |
| 07.5 | Implementar `AppSection`, `AppShellViewModel` y rutas locales necesarias. | Selección inicial, cambio de sección, push, pop y presentación por identidad. | Fachada mínima, sin strings mágicas ni router global ceremonial. |
| 07.6 | Construir shell adaptable con Jornada inicial. | Selección y conservación del estado local por sección. | Tab bar en iPhone, adaptación en iPad y multitarea. |
| 07.7 | Completar `Localizable.xcstrings`. | Comprobación de claves críticas y placeholders. | Sin texto visible fuera del catálogo. |

## Resultado de fase

Sistema visual y navegación moderna, accesible, localizada y desacoplada de infraestructura.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
