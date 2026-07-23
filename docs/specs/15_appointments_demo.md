# Fase 15 — Demo básica de citas

## Objetivo

Crear una agenda demostrativa para comparar con el sistema actual sin convertirla todavía en sistema de producción.

## Alcance deliberado

- CRUD básico, agenda diaria, cliente, servicios, horario y cancelación.
- Persistencia local SwiftData para la demo.
- Sin sincronización Firestore, notificaciones, recurrencias, recursos, pagos o sustitución del sistema actual salvo nueva decisión y ADR.
- `AppointmentsViewModel` y `AppointmentFormViewModel` son suficientes al inicio; no se añade Store preventivo.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 15.1 | Completar reglas de `Appointment`. | Horario inválido, solape permitido/prohibido según decisión y cancelación. | Política explícita. |
| 15.2 | Implementar repositorio local y casos de uso. | CRUD con ModelContainer in-memory. | Sin red o Firebase. |
| 15.3 | Implementar `GetAppointmentsForDayUseCase`. | Zona horaria, cambio de día y orden. | Calendar inyectado. |
| 15.4 | Implementar ViewModels de agenda/formulario. | Crear, editar, cancelar, error y navegación. | `@Observable @MainActor`. |
| 15.5 | Implementar agenda diaria adaptable. | Estado cubierto. | Preview vacío y múltiples citas. |
| 15.6 | Implementar formulario con cliente y servicios. | Referencias activas/inactivas. | Textos localizados. |
| 15.7 | Añadir datos demo deterministas. | Seed repetido no duplica. | Escenarios comparables. |
| 15.8 | Añadir acceso etiquetado Demo. | Ruta y feature flag local. | No se presenta como sistema definitivo. |

## Resultado de fase

Demo local, delimitada y reversible, sin comprometer el diseño remoto antes de validar el producto.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md).
