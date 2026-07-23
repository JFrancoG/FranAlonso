# ADR 0010 — Asistente local en el MVP y proveedor remoto pos-MVP

## Estado

Aceptado

## Contexto

Fran necesita poder mantener Jornada abierta durante el trabajo, hablar con la aplicación, recibir una respuesta por voz y preparar datos sin abandonar la tarea física en curso. Una jornada objetivo dura ocho horas y puede concentrar entre 20 y 25 interacciones por hora. El flujo puede oír voces de clientes, tratar datos personales y proponer cambios comerciales, por lo que escucha, retención, confirmación y ejecución forman parte de la arquitectura y no son solo detalles de interfaz.

El proyecto usa iOS 26.0 y Xcode 26.6. El SDK estable ya ofrece `SpeechAnalyzer`, `SpeechTranscriber`, `SpeechDetector`, `SystemLanguageModel`, `LanguageModelSession`, generación guiada y `AVSpeechSynthesizer`. Algunas abstracciones publicadas para iOS 27 siguen en beta y no justifican elevar el deployment target. El modelo remoto `gpt-5.6-luna` acepta texto e imágenes y devuelve texto; no sustituye la canalización de audio. `gpt-realtime-2.1` sí permite voz a voz, pero transmite audio y tiene un perfil de privacidad, conectividad y coste distinto.

## Opciones consideradas

1. Implementar el MVP con procesamiento Apple local y una degradación manual explícita.
2. Usar `gpt-5.6-luna` desde el MVP mediante un backend autenticado.
3. Usar GPT Realtime desde el MVP para una conversación de voz a voz.
4. Posponer todo el asistente hasta después del MVP.

## Decisión

El MVP incluye un asistente local basado exclusivamente en APIs Apple estables para iOS 26:

- `AVAudioEngine` alimenta mediante `AsyncStream` y `AnalyzerInput` a `SpeechAnalyzer`, `SpeechDetector` y `SpeechTranscriber`.
- `SystemLanguageModel` y `LanguageModelSession` interpretan texto y producen una salida tipada mediante generación guiada.
- `AVSpeechSynthesizer` verbaliza aclaraciones, propuestas y resultados.
- La disponibilidad real de idioma, activos y Apple Intelligence se comprueba antes de iniciar la sesión. Si falta, la aplicación conserva intacto el flujo manual y explica el motivo.

La experiencia es una sesión en primer plano, iniciada y detenida expresamente por Fran, con indicador persistente de escucha, duración y parada. Puede permanecer activa mientras Jornada está visible y usar detección de voz y una frase de invocación local para delimitar intentos, pero no promete un wake word del sistema, escucha global ni ejecución en segundo plano. Se detiene inmediatamente al bloquear, cerrar sesión, perder el permiso o pasar la escena a segundo plano y nunca se reanuda sola. No se añade `UIBackgroundModes=audio`.

La conversación es half-duplex: la captura se pausa mientras habla el sintetizador para impedir realimentación. El audio usa un buffer volátil y acotado; audio, transcripción intermedia, prompt, respuesta y estado conversacional se descartan al terminar, cancelar, rechazar o interrumpir y no se guardan, sincronizan, copian al portapapeles ni envían a logs o telemetría. Las respuestas habladas no repiten datos sensibles en un entorno público.

El límite funcional es independiente del proveedor:

- Domain define contexto mínimo, intención, propuesta tipada, política de efectos y contratos de interpretación; no importa `FoundationModels`, `Speech`, `AVFAudio`, SwiftUI, SwiftData ni Firebase.
- Data/Infrastructure adapta las APIs Apple y transforma sus DTO generables a modelos de Domain.
- Presentation mantiene un `VoiceAssistantViewModel` y un `VoiceSessionStore` solo porque captura, interrupciones, turnos, cancelación y síntesis forman una responsabilidad de sesión cohesiva.
- El modelo puede consultar snapshots mínimos y producir navegación o borradores reversibles. No recibe acceso directo a SwiftData, Firebase, bindings ni repositorios concretos.
- En el MVP el asistente no invoca mutaciones. Presenta el borrador exacto para revisión y edición; Fran usa la confirmación visual normal del formulario, que llama una sola vez al UseCase existente. La voz no confirma ni guarda. Pago, documento, correo, stock, consentimiento, anulación y eliminación permanecen además fuera de las capacidades de voz.

Después del MVP se evaluará `gpt-5.6-luna` como intérprete remoto opcional detrás del mismo contrato. La voz seguirá siendo local: el cliente enviará solo texto y contexto minimizado a un backend autenticado, nunca una clave de OpenAI ni audio desde la aplicación. Esa integración exige una decisión posterior sobre responsable/encargado, base jurídica, retención, residencia, seguridad, presupuesto y consentimiento antes de tratar datos reales.

GPT Realtime queda como alternativa no planificada. Adoptarlo requerirá un ADR nuevo porque cambiaría la frontera de audio, privacidad, coste y disponibilidad; no es fallback implícito de Foundation Models ni de Luna.

No se adoptan para el MVP APIs beta de iOS/Xcode 27, incluidas `CaptureInputSequenceProvider`, `AnalyzerInputConverter`, el protocolo genérico `LanguageModel`, perfiles dinámicos o `PrivateCloudComputeLanguageModel`.

## Consecuencias

- El MVP funciona sin coste variable de inferencia y sin enviar audio o prompts a terceros, pero solo en dispositivos, idiomas y configuraciones compatibles con Apple Intelligence.
- La sesión visible reduce el riesgo de escucha inadvertida, aunque sigue requiriendo permisos de micrófono y reconocimiento, explicación accesible sobre voces cercanas, parada inmediata e indicadores inequívocos.
- El asistente ayuda a navegar y rellenar borradores; la aplicación, no el modelo, conserva invariantes, autorización, confirmación y persistencia.
- Un mismo corpus y contrato permiten comparar Foundation Models con Luna sin reescribir los flujos de producto.
- Luna añade dependencia de red, backend y coste; su evaluación no bloquea el MVP.
- El flujo manual es una capacidad permanente, no un error excepcional.

## Testing y validación

- Dobles deterministas cubren disponibilidad, permisos, activos no preparados, parciales de transcripción, silencio, interrupciones, cancelación, límites de contexto, respuestas inválidas y errores de generación o síntesis.
- Un corpus versionado y sin PII prueba clasificación, campos obligatorios, aclaraciones, propuestas, confirmaciones, rechazo, idempotencia y resistencia a instrucciones presentes en datos de negocio.
- Antes de habilitar el modo de jornada se ejecuta una prueba controlada de ocho horas y 160–200 intentos. Se registran únicamente métricas agregadas y no sensibles: éxito, corrección manual, falsas activaciones, latencia, interrupciones, batería y estado térmico.
- Antes de la jornada se prueba el asistente en modo avión con los recursos locales ya instalados y se compara consumo con una línea base equivalente sin escucha.
- Son puertas de seguridad: cero efectos originados por la voz, cero audio/transcripciones/prompts retenidos o telemetrizados, cero tráfico de voz y recuperación íntegra tras cada interrupción. Los umbrales de usabilidad se fijan antes del ensayo para elegir entre sesión manos libres, pulsar para hablar o fallback manual sin expulsar Foundation Models del MVP.
- iPhone, iPad, multitarea, VoiceOver, Dynamic Type, permisos denegados y dispositivo/modelo no disponible se validan manualmente, además de Swift Testing y Xcode MCP. La integración añade descripciones específicas de uso del micrófono y del reconocimiento de voz.

## Relaciones

- Complementa ADR 0001, ADR 0003, ADR 0007 y ADR 0009.
- Se ejecuta en la fase 16 del MVP y prepara la fase 19 pos-MVP.

## Referencias

- [Apple — SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
- [Apple — SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
- [Apple — Speech synthesis](https://developer.apple.com/documentation/avfoundation/speech-synthesis)
- [OpenAI — GPT-5.6 Luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [OpenAI — GPT Realtime 2.1](https://developers.openai.com/api/docs/models/gpt-realtime-2.1)
