# Fase 08 — Clientes, consentimiento y foto

## Objetivo

Gestionar clientes, búsqueda, consentimiento firmado obligatorio y foto opcional preservando trabajo offline y evitando clientes activos sin consentimiento persistido.

## Prerrequisito de decisión

ADR 0009 aceptado antes de implementar la máquina de estados o activar clientes.

## Estado y responsabilidades

- `ClientListViewModel` coordina listado, búsqueda, selección y navegación.
- `ClientFormViewModel` es la fachada del formulario.
- Al incorporar firma, renderizado, subida, reintento y estados de activación, el ViewModel crea y conserva un `ClientConsentStore` `@Observable @MainActor` como responsabilidad cohesiva.
- El Store orquesta `RenderConsentUseCase`, `UploadConsentUseCase` y `ActivateClientUseCase`; no importa Firebase Storage ni PDFKit.
- El cliente usa estados `draft`, `consentPendingUpload` y `active`. Un borrador puede persistirse localmente sin red, pero no se activa hasta que el consentimiento obligatorio se haya subido y referenciado.
- La desactivación de 08.1 crea el tombstone del registro sincronizable definido
  por ADR 0006 y lo excluye de consultas operativas; no añade un cuarto
  `ClientStatus` ni elimina la referencia de consentimiento del payload
  conservado para sincronización e histórico.
- La foto es opcional y su fallo no invalida al cliente ni al consentimiento.
- La atomicidad y recuperación del flujo se documentan en ADR 0009.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 08.1 | Definir contratos y casos de uso CRUD/búsqueda. | Crear, editar, desactivar, buscar y errores. | UI observa SwiftData local. |
| 08.2 | Implementar `ClientListViewModel` y `ClientFormViewModel`. | Estados, validaciones, navegación y cancelación. | `@Observable @MainActor`. |
| 08.3 | Implementar listado, búsqueda y formulario. | Lógica ya cubierta en ViewModels. | Previews con 0, 1 y 80 clientes. |
| 08.4 | Implementar captura de firma como valor Sendable. | Firma vacía, válida y cancelada. | View sin persistencia directa. |
| 08.5 | Implementar renderizado de consentimiento. | Documento determinista con datos requeridos. | Trabajo pesado fuera de MainActor. |
| 08.6 | Implementar repositorio Storage y fake. | Éxito, offline, permiso, reintento y duplicado. | Firebase Storage encapsulado. |
| 08.7 | Introducir `ClientConsentStore`. | Estados draft/pending/active/error, reintento y cancelación. | ViewModel lo instancia sin duplicar estado. |
| 08.8 | Implementar activación idempotente tras upload. | Reinicio entre upload y activación. | Nunca activo sin referencia de consentimiento. |
| 08.9 | Implementar foto opcional y detalle. | Fallo no bloqueante, reemplazo y cancelación. | Receta, notas e histórico visibles. |

## Resultado de fase

Clientes offline-first con consentimiento obligatorio recuperable, Storage aislado y Store justificado por complejidad real.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), con subagente `$review-ios-standards` y segunda auditoría.
