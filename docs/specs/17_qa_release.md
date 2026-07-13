# Fase 17 — QA, TestFlight y entrega

## Objetivo

Preparar una versión estable para uso real en iPad, con evidencia de calidad, migración y recuperación, sin ampliar funcionalidad.

## Estrategia de QA

- Swift Testing cubre Domain, Data, sincronización, Stores y ViewModels.
- No se crean XCTest, XCUITest ni tests UI nativos.
- Los flujos visuales se validan con previews, revisión manual y un checklist en dispositivos acordados.
- Cualquier ajuste de esta fase corrige un defecto o deuda de entrega; una feature nueva vuelve a planificación.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 17.1 | Ejecutar suite completa y revisar tests frágiles. | Reproducir cualquier fallo antes de corregir. | Suite verde, paralela y determinista. |
| 17.2 | Compilar todos los targets con warnings como errores. | Diagnóstico reproducible. | Cero warnings mediante Xcode MCP. |
| 17.3 | Validar migración y recuperación de datos. | Esquema anterior, pendientes y reinicios. | Sin pérdida ni duplicados. |
| 17.4 | Ejecutar checklist manual iPad/iPhone acordado. | No aplica test UI nativo. | Navegación, multitarea, accesibilidad y documentos. |
| 17.5 | Corregir defectos UX sin nuevas features. | Test de lógica antes de cada corrección. | Previews y recorrido afectado. |
| 17.6 | Revisar privacidad, permisos y datos sensibles. | Estados denegado/restringido. | Descripciones y comportamiento correctos. |
| 17.7 | Crear guía de uso y recuperación. | Revisión contra build candidata. | Pasos reproducibles para Fran. |
| 17.8 | Fijar versión/build y preparar release notes. | Validación de configuración. | Build identificable y trazable. |
| 17.9 | Distribuir por TestFlight. | Smoke manual sobre build distribuida. | Instalable en dispositivos acordados. |
| 17.10 | Recoger feedback como issues priorizados. | Reproducción y criterio de aceptación. | Sin mezclar feedback con el build cerrado. |

## Resultado de fase

Build candidata trazable, sin warnings, con suite verde, validación manual y plan de recuperación documentado.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md). La build no se entrega hasta que el subagente `$review-ios-standards` complete la segunda auditoría sin hallazgos válidos abiertos.
