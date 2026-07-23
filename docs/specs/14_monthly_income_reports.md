# Fase 14 — Informes mensuales de ingresos

## Objetivo

Mostrar ingresos del mes actual y anterior, además de rankings acordados, sin introducir gastos o beneficio en el MVP.

## Diseño

- Los informes se calculan desde ventas pagadas materializadas en SwiftData, aunque la emisión documental esté pendiente; el ingreso no depende de que la operación ya haya salido de Jornada.
- Las anulaciones se incorporan como ajustes compensatorios en su fecha efectiva. Los informes muestran importes netos sin reescribir la venta original.
- Calendar, zona horaria y fecha actual se inyectan para evitar límites mensuales ambiguos y tests dependientes del reloj real.
- Importes usan `Money`/`Decimal`; las agrupaciones se basan en snapshots de `SaleLine`.
- `ReportsViewModel` es suficiente inicialmente; no se crea Store salvo nuevas responsabilidades independientes.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 14.1 | Crear `MonthlyIncomeSummary`. | Mes vacío, importes y moneda. | Value type Sendable. |
| 14.2 | Implementar `GetMonthlyIncomeSummaryUseCase`. | Inicio/fin de mes, zona horaria, año, mes anterior y anulaciones compensatorias. | Clock y Calendar inyectados; total neto por fecha efectiva. |
| 14.3 | Implementar ranking de servicios profesionales. | Empates, desactivados y snapshots históricos. | Orden determinista. |
| 14.4 | Implementar ranking de servicios producto. | Vínculos eliminados y cantidades. | No consulta catálogo actual para historia. |
| 14.5 | Implementar `ReportsViewModel`. | Loading, vacío, contenido, error y cancelación. | `@Observable @MainActor`. |
| 14.6 | Implementar pantalla de informe. | Lógica cubierta en Domain/ViewModel. | Previews y accesibilidad. |
| 14.7 | Integrar acceso desde navegación principal. | Estado de ruta. | Visible según sesión. |

## Resultado de fase

Informes deterministas basados en datos locales históricos, sin mezclar alcance financiero no solicitado.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
