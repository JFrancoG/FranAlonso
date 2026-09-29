# Fase 16 — Asistente de voz local

## Objetivo

Incorporar al MVP un asistente en Jornada que Fran inicia explícitamente, que escucha y responde en voz mientras la aplicación permanece en primer plano y que prepara navegación o borradores tipados sin saltarse confirmaciones ni invariantes de negocio.

## Alcance

- Voz a texto local con `SpeechAnalyzer`, `SpeechDetector` y `SpeechTranscriber` sobre la canalización estable de iOS 26.
- Interpretación local con `SystemLanguageModel`, `LanguageModelSession` y generación guiada.
- Respuesta local con `AVSpeechSynthesizer`.
- Consultas de solo lectura, navegación y rellenado reversible de campos de los flujos ya implementados.
- Propuestas de borrador revisables; el asistente no guarda ni confirma por voz.
- Sesión visible iniciada/detenida por Fran; no wake word del sistema, escucha global ni segundo plano.
- Fallback manual completo cuando permisos, idioma, activos, Apple Intelligence o dispositivo no sean compatibles.

Quedan fuera de esta fase los proveedores remotos, las APIs beta de iOS/Xcode 27, el envío de audio fuera del dispositivo y la ejecución autónoma de mutaciones.

## Diseño

```text
AVAudioEngine
  → SpeechAnalyzer / SpeechDetector / SpeechTranscriber
  → AssistantInterpreter (contrato Domain)
  → AssistantProposal tipada
  → UI de borrador editable
  → confirmación visual normal de Fran
  → UseCase existente, sin intervención del asistente
  → respuesta de texto
  → AVSpeechSynthesizer
```

- Domain contiene `AssistantContext`, `AssistantIntent`, `AssistantProposal`, `AssistantEffectPolicy` y el contrato `AssistantInterpreter`; todos son `Codable`, `Equatable` y `Sendable` cuando semánticamente proceda.
- Los adaptadores de `FoundationModels`, `Speech` y `AVFAudio` viven en `Data/Adapters`. Sus tipos no cruzan el límite de Domain o Presentation.
- El contexto contiene únicamente los campos necesarios y snapshots inmutables. Los datos recuperados se tratan como datos, nunca como instrucciones para el modelo.
- El intérprete devuelve tipos cerrados y validables. Una salida desconocida, incompleta o fuera de política produce aclaración o fallback, no una acción aproximada.
- `VoiceSessionStore` es `@Observable @MainActor` y posee la máquina de estados de captura, turnos, interrupciones, cancelación y síntesis. `VoiceAssistantViewModel` sigue siendo la fachada de la pantalla y no duplica ese estado.
- Navegar o rellenar un borrador es reversible. Guardar se hace desde el control visual normal del formulario; el asistente no lo invoca ni acepta una confirmación por voz. Pagar, emitir, enviar, ajustar stock, consentir, anular o eliminar no son capacidades de voz del MVP.
- No se persiste audio, transcripción, prompt, respuesta ni historial de conversación. La telemetría no recibe PII ni payloads; la prueba de campo usa solo contadores y medidas agregadas locales.
- La captura se pausa mientras `AVSpeechSynthesizer` habla. La sesión se detiene al bloquear, cerrar sesión, perder permisos o pasar a segundo plano, descarta todo el estado efímero y no se reanuda automáticamente. No se habilita ningún modo de audio en background.

## Estados de sesión

`inactive → checkingAvailability → requestingPermission → listening → transcribing → interpreting → clarifying | proposing → speaking → listening`

`stopping`, `interrupted`, `unavailable` y `failed` son salidas explícitas y recuperables. Una interrupción o cambio de sección cancela el trabajo estructurado, descarta buffers efímeros y nunca confirma una propuesta pendiente.

## Adelanto acotado para la demo: borrador escrito de un servicio profesional

[ADR 0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md) permite adelantar este recorrido después de las
[fases 09](09_products_stock.md) y [10](10_services_catalog.md), cuando el formulario manual de `Service` y sus reglas
estén estables y comprobados. Es alcance aprobado para planificación; esta sección no acredita implementación ni
cierra subfases de la fase 16. Su ejecución requiere el inicio autorizado y la revisión previa correspondientes.
[PLU-47](https://linear.app/plusprojects/issue/PLU-47), hija de PLU-9, permanece Backlog, responsable Jesus Franco;
depende de la base [PLU-46](https://linear.app/plusprojects/issue/PLU-46) y de la entrega funcional de09–10.

```text
Descripción escrita con datos sintéticos
  → inferencia real local de Foundation Models
  → propuesta tipada de un único servicio profesional
  → campos editables del formulario de Service
  → revisión de Fran y botón habitual de guardar
  → UseCase existente y sus validaciones
```

### Límites del recorrido

- Solo se propone un servicio profesional, sin `linkedProductID`. `Product` sigue siendo inventario físico sin precios
  ni descuentos; no se adelanta el rellenado de productos ni de servicios de tipo producto.
- La propuesta solo puede contener campos existentes del contrato y del formulario de `Service`. No introduce campos,
  reglas comerciales ni valores que la entrada no justifique. Un impuesto, descuento o dato obligatorio no indicado
  permanece sin proponer y requiere revisión manual; el modelo no inventa ni selecciona un impuesto por defecto.
- Por ejemplo, «Servicio profesional de corte y peinado, precio 35 euros» puede proponer nombre y precio en EUR. No
  determina el impuesto, descuento ni otros valores ausentes. Las validaciones normales deciden cuándo se puede guardar.
- El adaptador de Foundation Models devuelve una propuesta validable; no accede a bindings, repositorios concretos,
  SwiftData, Firebase ni UseCases mutadores. Aplicar una propuesta al borrador es reversible y no guarda el servicio.
  Guardar conserva el botón, el UseCase y las invariantes del formulario habitual, con revisión explícita de la persona.
- No se incorporan `Speech`, micrófono, permisos de captura, transcripción, TTS, sesión continua ni ensayo de ocho horas.
  Las consultas, navegación y demás capacidades del asistente permanecen en el alcance completo de fase 16.

### Recuperación, disponibilidad y privacidad

- Comprobar disponibilidad del modelo en el dispositivo e idioma previstos antes de depender de esta función para la
  demo. La falta de compatibilidad, recursos o disponibilidad se muestra de forma comprensible y deja el formulario
  manual operativo; no hay fallback cloud ni una respuesta prefabricada presentada como inferencia satisfactoria.
- Una entrada ambigua, varios servicios en el mismo texto, salida inválida o datos insuficientes no se convierten en un
  alta aproximada. Se solicita reformular o completar manualmente, conservando el borrador válido de la persona.
- Error y cancelación permiten recuperar el flujo manual y reintentar explícitamente. Cerrar el formulario, abandonar
  el flujo o iniciar otra solicitud invalida el trabajo anterior: un resultado tardío no repuebla un formulario cerrado,
  no sustituye otra propuesta ni sobrescribe una edición posterior de la persona.
- Los límites de 16.9 se aplican desde el primer incremento: datos sintéticos para la demo, contenido recuperado tratado
  como datos y política de efectos cerrada. Entrada, prompt, respuesta y estado de inferencia son efímeros y nunca se
  guardan ni aparecen en logs o telemetría. Solo los valores revisados y guardados por la persona pasan a la persistencia
  ordinaria del servicio. Rechazar, cerrar o interrumpir descarta el contenido efímero.

### Evidencia y relación con las subfases

- Los dobles deterministas sirven para tests de contrato, validación y recuperación. La evidencia de la demo exige
  inferencia real en el dispositivo previsto, con build/commit, versión de sistema, idioma y disponibilidad registrados
  sin conservar prompts ni respuestas. Un doble no acredita disponibilidad, latencia o calidad del modelo real.
- Comprobar funcionalmente generar, revisar/editar, rechazar y guardar por el flujo manual, además de disponibilidad
  fallida, error, ambigüedad, cancelación y resultado tardío. Registrar qué escenarios se comprobaron en dispositivo y
  cuáles con dobles; no atribuir a runtime los resultados de tests. La validación de UI aplica ADR 0029 y enlaza la deuda
  accesible pendiente sin declararla resuelta.
- La inferencia fallida o no disponible queda registrada como tal. El recorrido manual puede seguir mostrándose, pero
  no acredita el objetivo de demostrar Foundation Models; ese objetivo sigue pendiente hasta obtener evidencia real.

| Subfase existente | Trabajo que puede aportar el adelanto | Alcance que permanece pendiente |
|---|---|---|
| 16.1 | Contrato, propuesta tipada y política de efectos para un servicio profesional. | Contratos y capacidades restantes del asistente. |
| 16.2 | Dobles y corpus sintético acotados a entrada escrita de ese servicio. | Corpus completo, evaluación de voz y umbrales del ensayo. |
| 16.3 | Adaptador real, disponibilidad y recuperación para esta interpretación. | Cobertura del resto de intenciones y contextos admitidos. |
| 16.8 | Conexión reversible con el formulario y guardado manual existente de `Service`. | Consultas, navegación y restantes borradores tipados. |
| 16.9 | Privacidad, rechazo de mutaciones y recuperación exigidos desde el inicio. | Permisos, captura, interrupciones y recuperación del asistente completo. |

La evidencia aprovechable se vinculará a esas subfases sin marcarlas completadas por este adelanto. Se mantienen
íntegras 16.1–16.10, incluida la prueba de jornada y la decisión posterior sobre modalidad de voz; no se crea una
numeración ni un plan de fase paralelos.

## Subfases

| ID | Tarea | Test primero | Validación |
|---|---|---|---|
| 16.1 | Definir contratos puros, tipos cerrados, allowlist de capacidades y política de efectos. | Intenciones válidas/desconocidas, propuestas incompletas, lectura, borrador y rechazo de toda mutación. | Domain no importa frameworks; solo lectura, navegación y borradores son representables por voz. |
| 16.2 | Crear dobles, corpus sin PII y protocolo de evaluación antes de elegir umbrales. | Casos normales, ruido, ambigüedad, prompt injection en datos y todos los flujos de producto admitidos. | Corpus versionado; métricas y umbrales manos libres/pulsar/fallback congelados antes del ensayo. |
| 16.3 | Implementar el intérprete `FoundationModelsAssistantInterpreter`. | Disponibilidad, activos no listos, salida guiada válida/inválida, límite de contexto, cancelación y error. | Solo APIs estables iOS 26; DTO generable mapeado a Domain; fallback explicable. |
| 16.4 | Implementar captura y transcripción locales. | Permisos concedidos/denegados, parciales, silencio, frase de invocación, cambios de formato e interrupción. | `AVAudioEngine` + `AsyncStream<AnalyzerInput>`; `NSMicrophoneUsageDescription` y `NSSpeechRecognitionUsageDescription`; sin helpers beta ni retención. |
| 16.5 | Implementar síntesis de voz local y política half-duplex. | Cola, pausa de captura, interrupción, cancelación, voz no disponible y contenido sensible. | Sin realimentación TTS→micrófono; respuesta detenible y coherente con el texto visible. |
| 16.6 | Implementar `VoiceSessionStore` y coordinación de turnos. | Todas las transiciones, eventos tardíos, solapamiento, stop, bloqueo, background, logout y revocación. | Estado determinista, sin reanudación automática, latest-wins cuando aplique y cero trabajo huérfano. |
| 16.7 | Integrar `VoiceAssistantViewModel` y el control visible en Jornada. | Inicio/parada, disponibilidad, propuesta, confirmación, rechazo y fallback manual. | Previews iPhone/iPad, Dynamic Type, VoiceOver y localización; sin pestaña o router global nuevo. |
| 16.8 | Conectar consultas, navegación y borradores tipados con las fachadas existentes. | Un caso por capacidad, datos ausentes, acceso denegado, repetición y contexto hostil. | El modelo no accede a repositorios concretos, SwiftData, Firebase, bindings ni UseCases mutadores. |
| 16.9 | Endurecer privacidad, permisos, retención y recuperación. | Revocación, cancelación, rechazo, interrupción, reinicio, dispositivo/idioma/modelo incompatible y ausencia de red. | Flujo manual intacto; cero efecto de voz, dato conversacional retenido/telemetrizado o fallback cloud. |
| 16.10 | Ejecutar una jornada real controlada de 8 horas con 20–25 intentos por hora. | Modo avión y línea base de consumo previos; checklist y umbrales fijados en 16.2; no se usan datos reales hasta superar seguridad. | Informe agregado de 160–200 intentos, batería/térmica/latencia/errores y decisión documentada: manos libres, pulsar para hablar o fallback manual. |

## Matriz de retención

| Dato | Durante el turno | Al terminar/cancelar/interrumpir | Persistencia, logs o telemetría |
|---|---|---|---|
| Audio y detección | Buffer volátil acotado | Descartado | Nunca |
| Transcripción, prompt y respuesta | Memoria efímera del turno | Descartados | Nunca |
| Propuesta de borrador | Memoria de Presentation hasta revisar/rechazar | Descartada al rechazar o cerrar | Nunca como conversación |
| Valores confirmados visualmente | Copiados al comando normal de la app | Conservados por el dominio aplicable | Solo persistencia de negocio ordinaria |
| Métricas de la prueba | Contadores agregados sin contenido | Informe agregado | Locales, sin PII ni texto libre |

## Prueba de jornada

- Identificar dispositivo físico, versión estable de iOS, build Release, commit, estado inicial de batería y condiciones ambientales.
- Instalar antes todos los recursos de voz/modelo y demostrar un recorrido funcional en modo avión.
- Medir una línea base comparable con Jornada en primer plano y escucha desactivada; no fijar un porcentaje de batería sin ese control.
- Repartir 160–200 intentos entre éxito, edición, rechazo, cancelación, silencio, ambigüedad, ruido representativo e interrupciones.
- Exigir cero crash, watchdog, efecto originado por voz, realimentación, retención o tráfico conversacional; cero estado térmico sostenido `serious`/`critical`; y ausencia de crecimiento monotónico de memoria tras el calentamiento.
- Registrar p50/p95 de latencia, tasa de tarea completada, correcciones y falsas activaciones contra los umbrales fijados en 16.2.
- Verificar que detener, bloquear o pasar a segundo plano libera micrófono y estado efímero dentro del límite fijado en 16.2 y que nunca reanuda la sesión por sí sola.

## Resultado de fase

El MVP dispone de un asistente local, reversible y verificable. La modalidad final de interacción se decide con evidencia de una jornada real, pero el flujo manual sigue disponible y la seguridad no depende de la calidad probabilística del modelo.

## Cierre obligatorio de cada subfase

Ejecutar las puertas especializadas de [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md). La 16.10 añade el informe de prueba de campo como evidencia obligatoria.
