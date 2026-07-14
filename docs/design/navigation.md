# Navegación y Jornada

Estado: diseño acordado con el propietario del producto el 14 de julio de 2026.

## Principio

La navegación debe ser proporcional a una aplicación pequeña y operativa. No se implementa un `AppRouter` global, un `NavigationPath` central ni una jerarquía permanente con `NavigationSplitView` sin una necesidad demostrada.

La raíz autenticada usa un `TabView` con estilo `.sidebarAdaptable`:

- iPhone presenta una barra inferior.
- iPad presenta una barra superior que puede adaptarse a sidebar.
- Cada sección conserva su propio `NavigationStack`.
- Las rutas internas son enums tipados y locales a la feature que los necesita.
- Los formularios con un elemento concreto usan presentación dirigida por identidad mediante `.sheet(item:)`.

## Secciones principales

| Sección | Propósito |
|---|---|
| Jornada | Pantalla inicial y tablero operativo que Fran mantiene abierto. |
| Histórico | Consulta separada de operaciones cerradas y sus documentos. |
| Clientes | Listado, búsqueda, detalle, alta y edición. |
| Catálogo | Servicios comerciales, productos físicos y stock. |
| Informes | Ingresos y rankings acordados. |

La Agenda permanece como una ruta auxiliar marcada `Demo`; no ocupa una pestaña principal. Logout y ajustes se presentan desde la toolbar o el menú de cuenta.

## Jornada

Jornada muestra una tarjeta por cliente u operación que todavía requiere una acción. Puede contener servicios:

1. Próximos.
2. En curso.
3. Terminados pendientes de cierre.

La tarjeta permite abrir el detalle, actualizar servicios, registrar el pago y emitir ticket o factura. No existe una pantalla de inicio o dashboard adicional.

El documento solo puede solicitarse después de registrar el pago. La UI no permite una operación documentada sin pago.

### Regla de permanencia

Una operación permanece en Jornada mientras falte cualquiera de estas condiciones:

- Todos sus servicios están terminados.
- El pago está registrado.
- Se ha emitido un ticket o una factura.

La emisión se considera completa cuando el documento tiene número definitivo y su PDF final está generado y materializado localmente. La subida a Storage o el envío manual por correo pueden reintentarse desde el detalle o el Histórico y no devuelven la operación a Jornada.

Si no hay red y no puede obtenerse el número definitivo, la operación continúa visible como documento pendiente. No se oculta trabajo accionable.

Cuando se cumplen las tres condiciones, la operación desaparece inmediatamente de Jornada y queda disponible en Histórico. No se conserva hasta el final del día: libera espacio en iPad y evita confundir trabajo cerrado con trabajo pendiente.

El ciclo se modela con estados finitos, no con booleanos independientes: `draft → inProgress → awaitingPayment → awaitingDocument → closed`. Cada línea pasa por próximo, en curso y terminado. Al pagar se congelan líneas, importes, impuestos, descuentos y método de pago; el cierre posterior solo añade la referencia del documento y los metadatos de cierre. Registrar el pago y cerrar la operación son transiciones distintas e idempotentes.

## Histórico

Histórico es una sección principal independiente:

- Presenta operaciones terminales: cerradas y anuladas.
- Las anuladas se diferencian visualmente y conservan el documento original y la trazabilidad de sus ajustes compensatorios.
- Permite filtrar y ordenar por fecha.
- Abre detalle, ticket o factura.
- No comparte su raíz visual con Jornada.

## Estado mínimo de navegación

El shell solo necesita una selección tipada y una fachada mínima:

```swift
enum AppSection: Hashable {
    case workday
    case history
    case clients
    case catalog
    case reports
}

@Observable @MainActor
final class AppShellViewModel {
    var selectedSection: AppSection = .workday
}
```

`AppShellViewModel` posee exclusivamente la selección principal; no sustituye los ViewModels de las features ni actúa como router. La sesión decide entre `LoginScreen` y el shell autenticado. Deep links, restauración de rutas completas y coordinación global entre features quedan fuera del MVP hasta que exista un requisito real.

## Archivos previstos

Los archivos se crearán con el primer tipo real, no como carpetas vacías:

- `App/Navigation/AppSection.swift`.
- `App/AppShellScreen.swift`.
- `App/AppShellViewModel.swift`.
- Rutas locales dentro de `Features/<Feature>/Presentation` cuando una feature tenga más de un destino.

## Validación futura

- Jornada es la selección inicial tras autenticarse.
- Cambiar de sección conserva el estado local de su `NavigationStack`.
- Una operación pagada pero sin documento sigue en Jornada.
- No puede solicitarse ni emitirse un documento antes de registrar el pago.
- Una operación terminada, pagada y documentada desaparece inmediatamente y aparece en Histórico.
- Una anulación posterior permanece consultable en Histórico, diferenciada y con sus compensaciones trazables.
- iPhone, iPad, multitarea, Dynamic Type y VoiceOver se revisan mediante previews y validación manual.

Referencias: [Apple HIG — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars), [Apple HIG — Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars) y [`SidebarAdaptableTabViewStyle`](https://developer.apple.com/documentation/swiftui/sidebaradaptabletabviewstyle).
