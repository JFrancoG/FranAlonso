# Evidencia 08.8 — Activación inicial recuperable

Fecha: 2026-09-29. Implementación local PLU-42. Puerta funcional para demo de ADR 0029;
no acredita cierre integral, certificación, conformidad jurídica ni subida a un servicio real.

## Alcance, evidencia y deuda

Incremento sobre [08.7](08-7-consent-flow.md): envío inicial prepara estado pendiente, activa solo con recibo durable,
ofrece Finalizar alta si el documento ya está enviado, explica el fallo local y confirma únicamente el documento
vinculado. Si el cliente está activo con una entrega no correlacionada, muestra un mensaje neutral sin reactivarlo.
Recuperar adopta el estado actual sin descartar ediciones locales. Lectura, captura y navegación existentes se conservan.

[PLU-45](https://linear.app/plusprojects/issue/PLU-45), hija de PLU-34 y relacionada con PLU-42/PLU-44, conserva
la comprobación accesible manual/integral del incremento. Responsable: Jesus Franco. Retomar después del feedback de Fran y
estabilización de este recorrido; completar antes del primer candidato para uso real. PLU-44 conserva los fallos de
08.7; PLU-38 conserva sus pendientes propios. La fase sigue abierta. No se cambia ningún resultado histórico por aplazar.

- Revisión estática/visual independiente: textos nativos localizados, acciones semánticas, mínimo44pt, scroll y estilos
  existentes. Sin corrección adicional de foco ni afirmación de locución a partir de AccessibilityFocusState.
- Seis previews inspeccionadas por root; el revisor inspecciona las tres del componente. Xcode MCP estable/Develop
  renderiza efectivamente iPad Pro13M5/iOS27.2; no confundirlo con iPadAir11M4/iOS27.0 usado por los tests.
- Pantalla completa: inicio del documento legible en las tres variantes; el pie queda fuera del viewport por longitud.
  Las previews del componente muestran por separado los nuevos mensajes y acciones con el mismo ancho máximo760pt.
- Swift Testing valida transiciones, reintento, cancelación, dos formularios y recibo seleccionado. Suite final
  835 declaraciones / 1.094 resultados PASS. Los tests no son evidencia de tecnologías de asistencia.
- No se repite el smoke táctil de 08.7: la nueva activación satisfactoria se valida con capas reales y Storage simulado
  en tests/previews. No se ejecuta un recorrido manual nuevo de éxito/fallo local posterior al upload, ni AT.
  La composición normal mantiene Storage no disponible. La futura composición de demo debe probar su recorrido real;
  no se afirma que el binario normal ya pueda completar una subida.

El smoke funcional breve de activación/reintento permanece en **PLU-42**, antes de su cierre funcional por ADR0029.
No se aplaza a PLU-45 ni a la estabilización posterior a la demo; puede validarse con una composición aislada
autorizada, sin Storage live. PLU-45 registra la operación accesible, anuncios/foco y matriz integral de los recorridos.

## Previews inspeccionadas

Directorio local de artefactos: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RenderPreview/`.
Fecha de todas: 2026-09-29. Sin errores de render.

| Archivo y hora | Alcance | Variante | Resultado observado |
|---|---|---|---|
| Finish activation — 00.44.03.png | Actions, pendiente | Large clara | Mensaje y Finalizar alta completos. |
| Active client — 00.47.44.png | Actions, activo | XXX Large clara | Confirmación completa; acción retirada. |
| Retry activation — 00.47.55.png | Actions, error local | AX5 oscura | Error, estado y botón completos, sin recorte. |
| Activation pending — 00.50.35.png | Screen | Large clara | Título y comienzo del documento completos. |
| Activated — 00.50.44.png | Screen | XXX Large clara | Metadatos y lectura escalados; pie fuera del viewport. |
| Activation failed — 00.51.01.png | Screen | AX5 oscura | Título/metadatos ajustan líneas; resto requiere scroll. |

Nombres reales: `<nombre> - 2026-09-29 at <hora>.png`. Previews anteriores a la corrección lógica de recuperación y
correlación: layout, estilo y textos de estos tres estados no cambian. El mensaje neutral no vinculado se revisa
estáticamente y mediante prueba de selección pendiente/subida; su inspección visual específica queda en PLU-45.

## Recorridos pendientes de validación manual

A01: subir documento inicial y verificar estado activo/listado, foco y anuncio. A02: reabrir después de upload y
finalizar sin refirmar/reenvío. A03: fallo local, mensaje, acción y reintento. A04: recuperar activación desde otra
ventana con/sin campos sin guardar. A05: escoger documento no vinculado y después el usado para el alta.
Ejecutar con datos sintéticos y una composición aislada explícita; nunca inferir servicio real desde la fixture.
VoiceOver, Control por voz, Control por botón, teclado/FKA, Inspector, contraste medido y variantes de preferencias,
ventana/orientación/RTL nuevas siguen pendientes según impacto. Reutilizar el resto de evidencia válida.

## Registro de los 55 criterios

La columna de resultado heredado conserva literalmente el estado de la matriz08.7; no extiende esa evidencia a08.8.
Las justificaciones de N/A siguen describiendo funciones ausentes. Los criterios sin cambio se resuelven con el
registro canónico enlazado; los nuevos métodos estáticos/visuales son limitados y no acreditan runtime completo.
Los fallos heredados 2.4.3/4.1.3 permanecen en PLU-44 y la nueva comprobación en PLU-45.

| ID | Aplicabilidad | Alcance del incremento o razón heredada | Resultado heredado08.7 | Evidencia08.8 |
|---|---|---|---|---|
| 1.1.1 | Aplicable | Estado de alta y error en texto nativo; Inspector pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.2.1 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.2.2 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.2.3 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.2.4 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.2.5 | N/A | No hay audio, vídeo ni medios sincronizados. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.3.1 | Aplicable | Mensaje de alta dentro del grupo retenido; árbol/rotor pendientes. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.3.2 | Aplicable | Orden error, documento, estado y acción; runtime pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.3.3 | Aplicable | Instrucciones de reintento sin refirmar ni reenviar. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.3.4 | Aplicable | Contenedor adaptable conservado; nuevas variantes runtime pendientes. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.3.5 | Aplicable | Los campos personales de 08.3 se conservan; verificar integración. | Limitado | Sin nueva ejecución |
| 1.4.1 | Aplicable | Éxito, pendiente y error expresados con texto, no solo color. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.4.2 | N/A | No se reproduce audio automático. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.4.3 | Aplicable | Estilos existentes; contraste nativo de nuevos textos pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.4.4 | Aplicable | Mensajes/acción inspeccionados Large/XXX Large/AX5. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.4.5 | Aplicable | Texto jurídico nativo; firma vectorial esencial, no imagen del texto. | Limitado | Sin nueva ejecución |
| 1.4.10 | Aplicable | Scroll conservado; variante estrecha nueva pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.4.11 | Aplicable | Controles/estilos existentes; medición final pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni mecanismo de espaciado de autor. | Limitado | N/A por función ausente, no por aplazamiento |
| 1.4.13 | N/A | No se incorpora contenido al hover ni ayudas dependientes del foco. | Limitado | N/A por función ausente, no por aplazamiento |
| 2.1.1 | Aplicable | Finalizar alta nativo; teclado pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.1.2 | Aplicable | Sin navegación nueva; operación y retorno por AT pendientes. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.1.4 | N/A | No se añaden atajos de caracteres simples. | Limitado | N/A por función ausente, no por aplazamiento |
| 2.2.1 | N/A | Lectura y decisión sin límite de tiempo. | Limitado | N/A por función ausente, no por aplazamiento |
| 2.2.2 | Aplicable | Operación finita y cancelable; cancelación cubierta por Swift Testing. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.3.1 | Aplicable | Sin destellos ni medios parpadeantes añadidos. | Limitado | Sin nueva ejecución |
| 2.4.1 | Aplicable | Encabezados del texto largo y foco inicial del lector. | Limitado | Sin nueva ejecución |
| 2.4.2 | Aplicable | Título visible y accesible en lector y selección recuperada. | Limitado | Sin nueva ejecución |
| 2.4.3 | Aplicable | Foco de éxito/fallo de activación pendiente; fallo heredado en PLU-44. | Falla | Limitado: estática/previews; runtime pendiente |
| 2.4.4 | Aplicable | Etiqueta Finalizar alta identifica la acción sin nuevo upload. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.4.5 | N/A | Recorrido secuencial acotado; listado y búsqueda de clientes no cambian. | Limitado | N/A por función ausente, no por aplazamiento |
| 2.4.6 | Aplicable | Estado y acción localizada; semántica runtime pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.4.7 | Aplicable | Estilo nativo conservado; FKA de nueva acción pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.4.11 | Aplicable | Alcanzar mensaje/acción en scroll con AT pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.5.1 | Aplicable | Button nativo; sin gesto nuevo. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.5.2 | Aplicable | Activación de Button; sin respuesta al inicio del toque. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.5.3 | Aplicable | Nombre visible Finalizar alta; Voice Control pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.5.4 | N/A | No hay activación por movimiento del dispositivo. | Limitado | N/A por función ausente, no por aplazamiento |
| 2.5.7 | Aplicable | Sin arrastre para activar/reintentar. | Limitado | Limitado: estática/previews; runtime pendiente |
| 2.5.8 | Aplicable | minHeight44 y ancho disponible; medición runtime pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.1.1 | Aplicable | Seis claves es en xcstrings; pronunciación pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.1.2 | Aplicable | Idioma de documento independiente de locale de controles. | Limitado | Sin nueva ejecución |
| 3.2.1 | Aplicable | Foco no activa; intención explícita. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.2.2 | Aplicable | Recuperar/abrir no activa; Swift Testing valida recuperación. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.2.3 | Aplicable | Mismo grupo/estilo de acciones; sin nueva navegación. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.2.4 | Aplicable | Enviar y finalizar distinguen estado durable. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.2.6 | N/A | No se incorpora un mecanismo de ayuda repetido. | Limitado | N/A por función ausente, no por aplazamiento |
| 3.3.1 | Aplicable | Error específico cuando hay recibo pero falla activación. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.3.2 | Aplicable | Metadatos y decisión opcional con instrucciones persistentes. | Limitado | Sin nueva ejecución |
| 3.3.3 | Aplicable | Reintento local sin refirmar ni reenviar; pruebas lógicas PASS. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.3.4 | Aplicable | Exige documento inicial firmado y recibo; no sustituye otro. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.3.7 | Aplicable | Reinicio durable y recuperación sin entrada redundante probados. | Limitado | Limitado: estática/previews; runtime pendiente |
| 3.3.8 | N/A | No cambia la entrada de autenticación; solo se revoca contenido al perder acceso. | Limitado | N/A por función ausente, no por aplazamiento |
| 4.1.2 | Aplicable | Controles nativos, estado correlacionado con documento; Inspector pendiente. | Limitado | Limitado: estática/previews; runtime pendiente |
| 4.1.3 | Aplicable | Nuevo anuncio explícito de alta; locución pendiente, fallo heredado en PLU-44. | Falla | Limitado: estática/previews; runtime pendiente |
