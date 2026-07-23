# Fase 18 — QA, TestFlight y entrega

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
| 18.1 | Ejecutar suite completa y revisar tests frágiles. | Reproducir cualquier fallo antes de corregir. | Suite verde, paralela y determinista. |
| 18.2 | Compilar todos los targets con warnings como errores. | Diagnóstico reproducible. | Cero warnings mediante Xcode MCP. |
| 18.3 | Validar migración y recuperación de datos. | Esquema anterior, pendientes y reinicios. | Sin pérdida ni duplicados. |
| 18.4 | Ejecutar checklist manual iPad/iPhone acordado. | No aplica test UI nativo. | Navegación, multitarea, accesibilidad, documentos y asistente local. |
| 18.5 | Corregir defectos UX sin nuevas features. | Test de lógica antes de cada corrección. | Previews y recorrido afectado. |
| 18.6 | Revisar privacidad, permisos y datos sensibles. | Estados denegado/restringido y ausencia de retención conversacional. | Descripciones y comportamiento correctos. |
| 18.7 | Crear guía de uso y recuperación. | Revisión contra build candidata. | Pasos reproducibles para Fran, incluido fallback manual. |
| 18.8 | Fijar versión/build y preparar release notes. | Validación de configuración. | Build identificable y trazable. |
| 18.9 | Distribuir por TestFlight. | Smoke manual sobre build distribuida. | Instalable en dispositivos acordados. |
| 18.10 | Recoger feedback como issues priorizados. | Reproducción y criterio de aceptación. | Sin mezclar feedback con el build cerrado. |

## Resultado de fase

Build candidata trazable, sin warnings, con suite verde, validación manual y plan de recuperación documentado.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md). La build no se entrega mientras cualquiera de las auditorías aplicables conserve hallazgos válidos abiertos.
