# Fase 19 — Proveedor remoto GPT-5.6 Luna (pos-MVP)

## Objetivo

Evaluar e integrar `gpt-5.6-luna` como intérprete remoto opcional detrás del contrato del asistente de la fase 16, comparando calidad, latencia, disponibilidad y coste sin enviar audio ni permitir que el proveedor ejecute mutaciones directamente.

Esta fase empieza después de entregar el MVP en la fase 18 y de revisar el informe de jornada real de la fase 16. No bloquea la salida del producto.

## Prerrequisitos

- Contratos, corpus, métricas, confirmaciones y fallback de la fase 16 estables.
- Informe de la prueba de ocho horas con Foundation Models.
- Backend autenticado capaz de custodiar la clave y aplicar autorización, rate limits, presupuestos y auditoría técnica sin PII.
- ADR posterior que apruebe proveedor, responsable/encargado, base jurídica, minimización, retención, residencia, seguridad, consentimiento y presupuesto vigentes en ese momento.

## Diseño

- `LunaAssistantInterpreter` implementa el mismo contrato Domain que Foundation Models; Domain y Presentation no conocen OpenAI.
- La aplicación conserva reconocimiento y síntesis Apple locales. Solo envía al backend texto y contexto tipado estrictamente necesario; nunca audio, historial completo, credenciales ni acceso directo a SwiftData/Firebase.
- El backend usa Responses API con `gpt-5.6-luna`, salida estructurada y allowlist cerrada de capacidades. La respuesta se valida y mapea a `AssistantProposal` antes de volver a Presentation.
- Igual que en el MVP, Luna solo puede producir lectura, navegación o borradores. Guardar sigue siendo una confirmación visual normal de Fran fuera del intérprete; una respuesta remota no eleva privilegios ni cambia invariantes.
- Foundation Models y el flujo manual permanecen disponibles. La selección de proveedor es explícita, observable y reversible; un fallo de red o presupuesto no bloquea la operación del salón.
- GPT Realtime no forma parte de esta fase. Su eventual adopción exige otro ADR y una evaluación específica de audio, privacidad y coste.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 19.1 | Revalidar el modelo disponible, sus capacidades y precios; aceptar el ADR remoto. | Matriz de requisitos y amenazas antes de código. | Decisión legal, técnica y económica vigente y trazable. |
| 19.2 | Definir el sobre minimizado y versionado cliente/backend. | Campos permitidos, omisión de PII, payload hostil, versión desconocida y tamaño máximo. | Sin audio, credenciales, historial indiscriminado ni modelos de persistencia. |
| 19.3 | Implementar el relay autenticado y presupuestado. | Auth, autorización, rate limit, timeout, cancelación, reintento seguro y corte de presupuesto. | Clave solo en servidor; logs redactados; métricas no sensibles. |
| 19.4 | Implementar `LunaAssistantInterpreter`. | Respuesta estructurada válida/inválida, red, servidor, límite y cancelación. | Sustituible por Foundation Models sin cambiar Domain/Presentation. |
| 19.5 | Ejecutar el mismo corpus y comparar proveedores. | Casos y scoring congelados antes de observar resultados. | Informe de calidad, corrección, latencia y coste por interacción/jornada/mes. |
| 19.6 | Ejecutar piloto opt-in sin datos reales y después controlado. | Seguridad y privacidad deben pasar antes del piloto real. | Decisión documentada de adoptar, mantener opcional o descartar Luna. |
| 19.7 | Endurecer fallback, selección y soporte operativo. | Caída de red, cuota, presupuesto, proveedor degradado y revocación. | Jornada nunca queda bloqueada y la selección se puede desactivar remotamente. |

## Resultado de fase

Una decisión basada en evidencia y, solo si supera las puertas acordadas, un proveedor Luna opcional que mejora la interpretación sin alterar la seguridad, el flujo manual ni la arquitectura del MVP.

## Cierre obligatorio de cada subfase

Ejecutar [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md), incluida la auditoría con un subagente `$review-ios-standards` y la segunda revisión tras corregir hallazgos.
