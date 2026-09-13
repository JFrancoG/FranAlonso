# Evidencia 08.4 — Captura independiente de firma

Fecha inicial: 2026-09-10. Estado consolidado: 2026-09-13. PLU-38. Captura local efímera; sin integración al formulario, persistencia ni activación.


## Reconciliación para PR borrador — 2026-09-13

La consolidación elimina pendientes genéricos ya acreditados. Revisión independiente `delivery084_evidence_audit`,
operacionalmente read-only, huella463 archivos pre/post idéntica
`b8620ab5514a2d6b0da26e1a898b3048fa8ff0ccd3263f5105436f645d086ba4`.
Ningún defecto ejecutable nuevo. Se conservan dos límites de evidencia: resize durante gesto activo y atribución/medición
 de contraste en el render nativo final de Cancelar/Confirmar/foco. El uso de ratón único no los convierte en N/A.

Recálculo independiente de pares de assets actuales (Light/Dark/LightHigh/DarkHigh):

| Par opaco | Ratios |
|---|---|
| ErrorInk/Surface | 5,244 / 5,001 / 7,367 / 8,411 |
| BrandPrimaryInk/Surface | 6,747 / 6,512 / 8,524 / 9,950 |
| TextPrimary/Surface | 13,573 / 13,937 / 16,962 / 17,015 |
| TextSecondary/Canvas | 5,373 / 6,356 / 12,433 / 13,802 |
| OnBrandPrimary/BrandPrimary | 4,945 / 9,812 / 10,554 / 12,280 |
| ErrorInk/Canvas | 6,187 / 6,105 / 9,122 / 10,381 |

Estos valores no miden la composición de estilos nativos. La observación1,68 del Confirmar inactivo continúa exenta;
no se afirma fallo activo. Las pruebas visuales aceptadas no se repiten para suplir una medición técnica pendiente.
Acceso temporal y esquema retirados con revisión PRE; build y3/3 tests de composición posteriores PASS, artefactos en fase08.
No se cierra ADR0022 ni08.4. Las anotaciones históricas que conservan acceso temporal no describen el estado actual.

POST final por agente nuevo `delivery084_final_accessibility`: sin hallazgos nuevos, PASS para draft con ambos límites
conservados. Inspeccionadas cuatro previews existentes; ninguna prueba runtime nueva inferida. Huella461 archivos
pre/post idéntica `81843677dceba2c254b9e2719b52eb1c49f293ee5aaae6a3457474a4666019a8`.

## Alcance y límites

- ClientSignatureCaptureScreen y Canvas a mano alzada; ViewModel y valor Domain. Modo por puntos retirado por el
  propietario; decisión y límites en ADR 0027. Regresión lógica, revisión estática/visual y recorridos funcionales R01/R02 completados.
- TDD, build final y previews completados; detalle y artefactos más abajo. Auditorías finales de estándares/estilo y accesibilidad completadas; detalle más abajo.
- Gesto, deshacer, borrar, confirmar y cancelar confirmados por el propietario en la versión final.
- VoiceOver confirmado en iPhone 14 físico: lectura básica y cancelación/retorno; el 2026-09-11 se añade
  anuncio de Confirmar firma como botón, activación y retorno del foco a Capturar firma.
- VoiceOver posterior a los iconos confirmado en iPhone 14 físico/iOS 26.6.1: nombres, estados, acciones y retorno de foco.
  Control por voz confirmado para Deshacer, Borrar y Confirmar; el 13/09 el propietario confirma Cancelar mediante voz,
  regreso a la pantalla principal y mensaje «Captura cancelada».
  Bloqueo durante el gesto confirmado: conserva el trazo terminado y descarta el interrumpido.
- Inspector: auditoría manual aportada por el propietario, con tres avisos analizados en la entrada final.
- Control por botón confirmado manualmente en iPhone 14 físico/iOS 26.6.1 para abrir, deshacer, borrar, cancelar y confirmar sobre tinta preparada.
- Teclado completado funcionalmente por el propietario en iPad Air 11-inch (M4)/iPadOS 26.5: abrir, deshacer, borrar, cancelar, confirmar y volver a seleccionar Capturar firma. Resalte de Confirmar corregido con contorno accesible rectangular: visible en Light/Dark, Espacio y recorrido local VoiceOver confirmados el 12/09. Sin medición normativa de contraste.
- Hallazgo de VoiceOver confirmado el 13/09: Deshacer/Borrar ejecutan la acción sin anunciar el resultado.
  Ajuste de prioridad alta limitado a esos dos anuncios: el propietario confirma ambos resultados audibles en el binario nuevo.
  Se resuelve el fallo de silencio. El propietario confirma también los valores vacío y listo del área de firma.
- Reducción/ampliación de ventana y acceso a acciones en tamaño mínimo confirmados por el propietario el 13/09,
  con dos trazos terminados conservados. No acredita redimensionado durante un gesto activo.
- Reducir movimiento confirmado el 13/09: abrir captura, dibujar y confirmar funcionan correctamente según el propietario.
- Aumentar contraste confirmado visualmente el 13/09 en Light/Dark: texto, firma, borde y tres botones distinguibles
  según el propietario. No acredita ratios de contraste ni una nueva auditoría Inspector.
- Pendientes: redimensionado durante gesto y reconciliación de mediciones de contraste. Scroll AX5 en iPad comprobado;
  detalle al final.
- Plan del flujo aprobado el 2026-09-11 en ADR 0028 y spec 08; pruebas retomadas con el propietario tras el ajuste.
  El cierre del componente conserva los pendientes de esta matriz; la lectura y el flujo durable se validan en 08.7–08.9.
  No hay nuevos resultados runtime por aceptar el plan.
- El resultado de captura no acredita identidad, consentimiento informado, validez jurídica ni guardado durable.
- La restauración de foco al formulario se evaluará al conectar el consumidor durable; no existe ese flujo en 08.4.

## Validación anterior a la retirada del modo por puntos

- Xcode MCP, Develop/iPad Air 11-inch (M4)/26.5: 28/28 resultados en cuatro suites (15:01:29),
  incluidos los cinco argumentos nan/inf/-inf/-0.01/1.01 verificados en el console log. Build final15:03:15 PASS12,016s.
- Previews inspeccionadas con Xcode MCP. El destino efectivo fue iPhone18Pro/iOS27 e iPadPro13M5/iOS27,
  aunque el destino del workspace era iPhone17e/26.5 o iPadAir11M4/26.5. No se presentan como evidencia de iOS26.
- Variantes Large, XXX Large, AX5 y cuatro apariencias; ancho350pt/RTL en preview iPad. No equivalen a multitarea
  real, desplazamiento, gesto ni tecnologías de asistencia. Las capturas AX5 muestran solo la zona inicialmente visible.
- Título truncado de iPhoneAX5 corregido mediante título multilínea en contenido y barra inline. Nuevo render comprobado.
- Borrar firma sobre fondo tinted oscuro daba3,642:1 con ErrorInk(255,107,99)/fondo(78,60,74). El área corregida usa
  Surface opaco, estilo plain y borde ErrorInk; nuevo render inspeccionado. Ya no depende del relleno nativo tinted.
- Ratios de assets en orden Light/Dark/Light High/Dark High: ErrorInk/Surface5,244/5,001/7,367/8,411;
  TextPrimary/Surface13,573/13,937/16,962/17,015; TextSecondary/Canvas5,373/6,356/12,433/13,802;
  OnBrandPrimary/BrandPrimary4,945/9,812/10,554/12,280. Medición de pares declarados, sin afirmar auditoría completa
  de controles nativos, foco o todas las combinaciones runtime.
- Controles alternativos materializados con Buttons individuales de altura mínima44pt, por la incertidumbre de los
  subobjetivos del Stepper. Cursor0...100 y ejes físicos estables. El área de tinta3:1 y grosor corresponden al dibujo,
  no a tipografía; conservar proporción evita deformar una firma al cambiar ancho o Dynamic Type.

Artefactos conservados en [directorio local](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4):

| Artefacto | Configuración y alcance |
|---|---|
| [iPhone final](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/iphone-ink-dark-large.png) | Dark Large; firma y acciones completas. |
| [AX5 final](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/iphone-point-mode-dark-ax5.png) | Título completo e instrucciones; controles inferiores requieren scroll, pendiente de runtime. |
| [iPad estrecho RTL](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/ipad-narrow-rtl.png) | Ancho350pt, dibujo sin invertir; controles completos Large. |
| [Light High XXXL](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/ipad-ink-light-high-xxxlarge.png) | iPad, acción destructiva corregida. |
| [Dark High Large](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/ipad-ink-dark-high-large.png) | iPad, acción destructiva corregida. |
| [Controles AX5](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/iphone-controls-light-ax5.png) | Solo cabecera/instrucciones iniciales; no prueba operación ni controles fuera del viewport. |

`previews.json` conserva rutas originales, configuración y hora. Dos capturas iniciales se conservan explícitamente como
anteriores a las correcciones; no sustituyen los renders finales. Reduce Motion/Transparency y preferencias no visuales
siguen pendientes de runtime; estáticamente no hay animación propia ni efectos transparentes en el lienzo.

## Auditorías anteriores a la retirada del modo por puntos

Revisiones finales operacionales estrictamente read-only, con huella pre/post idéntica de 457 archivos tracked y
untracked no ignorados: `54c54ae6f89d36473c243cfdb316bf6f4109937ac4972b16d78d8ee8a397e881`.

- Estándares iOS y estilo: PASS, sin hallazgos. Ocho Swift revisados manualmente y script de estilo sin candidatos.
- Accesibilidad: inspección estática de tres Views, 28 claves localizadas y matriz de 55 criterios; seis imágenes finales
  inspeccionadas. Único P2: clasificación de 1.3.4, corregida conforme a ADR 0026 sin cambiar la orientación de la app.
  Reauditoría documental focal PASS, sin nuevos hallazgos. El registro contiene 36 criterios aplicables y 19 N/A motivados.
- Huella pre/post de la reauditoría focal idéntica, 457 archivos:
  `facbcf8656ade9a6147bd02db44f4da1df54cce1a94df974e2851834f79e0716`.
- La columna Revisor identifica la revisión del código, los renders y la clasificación; no acredita técnicas manuales.
  Accessibility Inspector y todas las técnicas runtime enumeradas siguen pendientes. ADR 0022 permanece abierto.

## Registro completo por criterio

La clasificación vigente incorpora ADR 0027: 35 criterios aplicables y 20 N/A motivados. Integra las pruebas del
propietario y la revisión independiente del 11 de septiembre. Las secciones históricas conservan su fecha y alcance;
los pendientes de aquellas sesiones no sustituyen esta matriz consolidada. R01/R02 y la operación de los botones
han sido confirmados en la versión actual. Un resultado Pasa se limita al criterio y método indicados.

| ID | Aplicabilidad | Justificación | Resultado | Método y artefacto | Configuración | Hallazgo y disposición | Revisor |
|---|---|---|---|---|---|---|---|
| 1.1.1 | Aplicable | Contenido no textual (A) | Pasa | Código, previews y nombres de iconos/área confirmados con VoiceOver | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Nombres y controles del componente acreditados; no se extrapola al futuro documento firmado. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.2.1 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.2.2 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.2.3 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.2.4 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.2.5 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.3.1 | Aplicable | Información y relaciones (A) | Pasa | Código, previews y recorrido VoiceOver por área y controles | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Relaciones y secuencia de la captura comprobadas; no se infiere prueba de rotor. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.3.2 | Aplicable | Secuencia significativa (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 1.3.3 | Aplicable | Características sensoriales (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 1.3.4 | Aplicable | iPhone portrait-only; iPad conserva adaptación. | A/No pasa — excepción de producto aceptada | ADR0026; rotación iPad conserva tinta; reducción/ampliación y ventana mínima confirmadas | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Excepción iPhone conservada; resize con gesto activo pendiente, separado de orientación y adaptación ya probadas. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.3.5 | N/A | No solicita campos de datos personales ni autofill. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.4.1 | Aplicable | Uso del color (A) | Pasa | Inspección estática: iconos distintos, nombres, texto de estado y errores; reportes visuales | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | La información no depende solo del color. No se atribuye una ejecución de Differentiate Without Color. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.4.2 | N/A | Sin audio, vídeo ni medios temporizados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.4.3 | Aplicable | Contraste mínimo (AA) | Limitado | Assets/previews; Inspector del propietario: Confirmar inactivo 1,68:1 (#39393D/#0E0E0F); captura enlazada al final | 2026-09-11; captura vacía oscura del iPad; sin inferir binario exacto | Estado inactivo exento por WCAG 1.4.3; observación de legibilidad. No acredita todos los estados activos. | Revisión independiente audit084_inspector_evidence; Inspector ejecutado por propietario |
| 1.4.4 | Aplicable | Redimensionar texto (AA) | Pasa | Previews Large/XXX/AX5 y runtime AX5 con scroll; ventana mínima confirmada aparte | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Muestreos AX5 y ventana mínima independientes; no se afirma su combinación simultánea. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.4.5 | Aplicable | Imágenes de texto (AA) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 1.4.10 | Aplicable | Reflow (AA) | Pasa | Scroll AX5 en iPad y reporte de acceso a acciones en ventana mínima | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Acceso a controles confirmado; no se afirma que ventana mínima requiriera scroll ni AX5 simultáneo. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.4.11 | Aplicable | Contraste no textual (AA) | Limitado | Recálculo de pares de assets, previews y comprobación visual High Light/Dark | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Pares opacos propios respaldados; pendiente medición/atribución del render nativo final de controles y foco. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 1.4.12 | N/A | SwiftUI nativo sin markup ni override de espaciado. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 1.4.13 | N/A | No se introduce contenido hover ni popover. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.1.1 | Aplicable | Excepción de trayectoria limitada al dibujo libre. | Pasa | FKA en iPad: abrir, deshacer, borrar, cancelar, confirmar; Switch Control físico sobre tinta preparada | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Operación de controles acreditada. Excepción de trayectoria solo para dibujo libre según ADR0027. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.1.2 | Aplicable | Sin trampa de teclado (A) | Pasa | Entrada, navegación y salida mediante FKA y Control por botón confirmadas | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Sin trampa observada en los recorridos; no se afirma restauración automática FKA. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.1.4 | N/A | Sin atajos de carácter único. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.2.1 | N/A | Sin caducidad ni límite temporal. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.2.2 | N/A | Sin animación ni actualización autónoma. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.3.1 | N/A | Sin destellos ni medios animados. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.4.1 | Aplicable | Evitar bloques (A) | Pasa | Captura modal breve; recorrido por grupos/controles FKA y entrada/salida VoiceOver | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Acceso al contenido acreditado en el muestreo; no se infiere navegación por rotor. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.4.2 | Aplicable | Título (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 2.4.3 | Aplicable | Orden del foco (A) | Pasa | Orden VoiceOver local y recorrido FKA por grupos/botones confirmados; retorno VoiceOver al origen | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | No se infiere retorno automático FKA ni confirmación nueva de foco por el reporte de anuncios del13/09. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.4.4 | Aplicable | Propósito del enlace (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 2.4.5 | N/A | Una captura modal; no es una colección de destinos. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.4.6 | Aplicable | Encabezados y etiquetas (AA) | Pasa | Título, instrucciones y etiquetas de controles escuchados; semántica de encabezado inspeccionada | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Nombres y estructura acreditados; no se atribuye recorrido de rotor no reportado. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.4.7 | Aplicable | Foco visible (AA) | Limitado | Contorno rectangular: resalte visible Light/Dark, Espacio funcional; capturas y reportes al final | 2026-09-12; iPadAir11M4/26.5 | Identificación corregida en muestreo manual. No acredita contraste normativo ni todos los tamaños/preferencias. | Revisión estática independiente y propietario (runtime) |
| 2.4.11 | Aplicable | Foco no oculto mínimo (AA) | Pasa | FKA sobre grupos y botones, selección visible Light/Dark tras ajuste y Espacio funcional | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Foco no oculto en el recorrido probado; no se afirma toda combinación de tamaño/preferencia. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 2.5.1 | Aplicable | La tinta manuscrita depende de su trayectoria. | Limitado | W3C Pointer Gestures; ADR 0027; R01/R02 anteriores | 2026-09-10 | Excepción esencial acotada al dibujo. Regla interna ADR 0022 de alternativa a todo gesto no satisfecha; excepción puntual autorizada por propietario. Resto de botones con toque simple; no extrapolar a consentimiento/identidad. | Reauditoría independiente estática/visual |
| 2.5.2 | Aplicable | Cancelación del puntero (A) | Limitado | Swift Testing y bloqueo físico durante segundo trazo: conserva el primero y descarta el segundo | 2026-09-11; iPhone 14/iOS 26.6.1 | PASS de interrupción por bloqueo; pendiente cancelación durante cambio de tamaño. | Reporte del propietario; revisión estática independiente |
| 2.5.3 | Aplicable | Etiqueta en el nombre (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 2.5.4 | N/A | Sin activación por movimiento del dispositivo. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 2.5.7 | N/A | Se dibuja trayectoria; no se agarra y recoloca un objeto por su posición final. | Pasa | W3C Dragging Movements; inspección de alcance; ADR 0027 | 2026-09-10 | DragGesture es el nombre de la API, no la clasificación WCAG. Scroll nativo; reevaluar si se permite mover o redimensionar firmas. | Reauditoría independiente estática/visual |
| 2.5.8 | Aplicable | Tamaño de objetivo mínimo (AA) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.1.1 | Aplicable | Idioma de la página (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.1.2 | N/A | Interfaz española sin cambio de idioma de contenido. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 3.2.1 | Aplicable | Al recibir foco (A) | Pasa | FKA: enfocar sin activar y después Espacio; recorrido VoiceOver | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | No se observa navegación por mero foco en el muestreo. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 3.2.2 | Aplicable | Al introducir datos (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.2.3 | Aplicable | Navegación consistente (AA) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.2.4 | Aplicable | Identificación consistente (AA) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.2.6 | N/A | No se introducen mecanismos de ayuda repetidos. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 3.3.1 | Aplicable | Identificación de errores (A) | Pasa | Error de trazo y corrección escuchados; valores vacío/listo y anuncios de edición confirmados | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Pendiente antiguo de valores/anuncios resuelto; alcance limitado a errores de captura. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 3.3.2 | Aplicable | Etiquetas o instrucciones (A) | Pasa | Revisión de código/copy y previews; recorridos manuales R01/R02, VoiceOver y Control por voz; frames RocketSim para objetivos | 2026-09-11; iPhone 14/iOS 26.6.1 (propietario); iPad Air11M4/26.5 (frames) | Sin hallazgos en el alcance del criterio; no extrapolar a otras modalidades. | Revisión independiente close084_accessibility; reportes del propietario |
| 3.3.3 | Aplicable | Sugerencia ante errores (AA) | Pasa | Error de trazo, nueva firma válida y anuncio de trazo terminado confirmados | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Corrección de captura acreditada; valores y anuncios antes pendientes ya confirmados. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 3.3.4 | Aplicable | Prevención de errores (AA) | Pasa | Tests y recorridos manuales: deshacer, borrar, confirmar y cancelar captura efímera | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | Sin guardado ni acto legal irreversible aquí; lector y consentimiento durable pertenecen a08.5–08.9. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |
| 3.3.7 | N/A | No solicita de nuevo datos ya aportados; sesión de captura nueva. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 3.3.8 | N/A | No es un flujo de autenticación. | Pasa | Inspección estática | 2026-09-10 | No se introduce esta capacidad. | ios-accessibility-reviewer (estático/visual) |
| 4.1.2 | Aplicable | Nombre, función y valor (A) | Pasa | Nombres, roles y estados de botones acreditados; propietario confirma al enfocar el área «Todavía no hay firma» en vacío y «Firma lista para confirmar» tras dibujar | 2026-09-13; iPhone14 físico/iOS26.7, binario RunProject001300; recorridos anteriores con sus versiones documentadas | Muestreo de captura confirmado; no se extrapola al consumidor futuro ni a otras pantallas. | Propietario; revisiones estáticas independientes previas |
| 4.1.3 | Aplicable | Mensajes de estado (AA) | Pasa | Error/trazo terminado históricos; retest del13/09 confirma resultados Deshacer/Borrar tras prioridad alta | Sesiones10–13/09: dispositivos/OS/binarios especificados en entradas; iPad13/09 sin reidentificación completa | P2 de silencio resuelto en el muestreo. Respuesta final no acredita nueva verificación del foco ni duplicados. | Propietario; revisiones previas; consolidación delivery084_evidence_audit |

## Comprobaciones focales pendientes

1. Redimensionado durante gesto activo en iPad: descartar solo el trazo en curso. Conservación de tinta terminada
   al reducir/ampliar y acceso a acciones en ventana mínima confirmados el 13/09.
2. Reconciliar la evidencia técnica de contraste: comprobación visual con Aumentar contraste en Light/Dark confirmada
   el 13/09, sin atribuir ratios medidos. Reducir movimiento confirmado en abrir/dibujar/confirmar. Auditoría Inspector del estado vacío
   recibida y tres avisos clasificados; no equivale a inspección de todos los estados. AX5 y reducción de
   transparencia en iPad comprobados en la entrada final.
3. Finalizar revisión documental y entrega draft. Acceso temporal retirado el13/09; composición restaurada validada con build y3/3 tests, detalle en fase08.

VoiceOver: valores vacío/listo del lienzo, error, trazo terminado y resultados de Deshacer/Borrar confirmados;
nombres, acciones y retorno acreditados en los recorridos documentados. No repetir las comprobaciones aceptadas.
Deshacer/Borrar/Confirmar/Cancelar por voz y bloqueo físico durante el gesto están confirmados; no se vuelven a solicitar.
Resalte de teclado corregido y comprobado localmente el 12/09; recorridos funcionales de teclado y Control por botón
completados sobre tinta preparada; alcance al final.
El modo por puntos está fuera del alcance por ADR 0027.
No se presenta una revisión estática ni un render como prueba manual de estas técnicas.

## iPad: Aumentar contraste en claro y oscuro — 2026-09-13

Se solicita activar Aumentar contraste y observar la captura con un trazo en modo claro y oscuro, comprobando texto,
firma, borde del área y los tres botones. El propietario confirma «si, todo correcto». Se acredita percepción visual
correcta en ambas apariencias bajo esa preferencia, sin extrapolar a ratios normativos, todas las combinaciones
de estado o una auditoría Inspector nueva. Mismo contexto de iPad comunicado, sin nueva identificación de modelo/OS/binario.
No se repite este muestreo. Se indica devolver Aumentar contraste y la apariencia a sus valores anteriores;
no se da por realizada esa restauración. Registro documental; build/tests N/A.

## iPad: Reducir movimiento confirmado — 2026-09-13

Se solicita activar Reducir movimiento, volver a la app, abrir captura, dibujar un trazo y confirmar,
comprobando apertura/cierre sin saltos visuales que dificulten el uso. El propietario responde «si, funciona bien».
Se acredita el recorrido con esa preferencia activada en la sesión de iPad; no se vuelve a identificar modelo,
OS o binario ni se atribuye una nueva instalación. Se indicó devolver la preferencia a su estado anterior;
su restauración no ha sido confirmada. No se repite este muestreo aceptado. Registro documental; build/tests N/A.

## iPad: ventana mínima y conservación de tinta terminada — 2026-09-13

Con el iPad abierto, se pide abrir la captura, dibujar dos trazos, reducir la ventana de la app al mínimo permitido
y volver a ampliarla. El propietario responde «si» a la conservación de ambos trazos y al acceso a Deshacer,
Borrar y Confirmar, desplazando contenido si resulta necesario. Queda acreditado ese recorrido de adaptación.
No se infiere que necesitara desplazamiento ni que redimensionara mientras dibujaba; el descarte de trazo activo
durante resize conserva su pendiente. El contexto previo era iPad simulado, pero este reporte no vuelve a identificar
modelo, versión del sistema ni binario: no se atribuye una nueva instalación ni medidas exactas de ventana.
Evidencia manual comunicada; actualización documental, build/tests N/A. No repetir este recorrido aceptado.

## VoiceOver: valores del área de firma confirmados — 2026-09-13

En la misma sesión del iPhone14 físico/iOS26.7 y binario RunProject001300, se pide enfocar el área vacía y,
tras dibujar un trazo, volver a enfocarla. El propietario confirma «correcto, ha dicho ambas cosas» respecto de
«Todavía no hay firma» y «Firma lista para confirmar». Se resuelve el pendiente de valor accesible vacío/listo.
Evidencia manual comunicada, sin nueva grabación ni ejecución de herramientas. Actualización documental;
build/tests N/A. Se conserva el resto del alcance pendiente de 08.4.

## VoiceOver: silencio tras editar y piloto de prioridad — 2026-09-13

Resultado posterior: tras lanzar el binario nuevo, se solicita escuchar Deshacer sobre dos trazos y Borrar el restante.
El propietario confirma «Si, ahora ha anunciado el resultado tal y como has dicho»: quedan acreditados
«Último trazo deshecho» y «Firma borrada». Se conserva el ajuste y se resuelve el P2 de silencio en este recorrido.
No se infiere confirmación específica sobre permanencia de foco o duplicados, porque la respuesta se refiere al resultado
hablado. No se repite la prueba de audibilidad. Registro documental; build/tests N/A para esta actualización.
Esta conclusión sustituye los pendientes auditivos históricos de la entrada siguiente, sin cerrar 08.4.

Tras distinguir etiqueta/estado del botón y resultado posterior a activarlo, el propietario precisa:
«No dice nada solo se ejecuta la acción». Se registra fallo audible de Deshacer/Borrar; no se invalida su funcionamiento
ni la lectura correcta de los controles. El código ya publicaba ambos anuncios y el catálogo contiene sus textos.
La causa de la ausencia de voz no está demostrada.

Piloto acotado: el helper recibe prioridad explícita, crea AttributedString localizado y publica la notificación;
solo Deshacer/Borrar pasan `.high`. Los anuncios restantes conservan `.default`, sin cambios de foco, UI, VM ni Domain.
Apple documenta que `.high` interrumpe habla anterior y no es interrumpible una vez iniciado:
[Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement) y
[prioridades](https://developer.apple.com/documentation/foundation/attributescopes/accessibilityattributes/announcementpriorityattribute).
No se añaden demoras arbitrarias, tareas ni cambios de foco. Si no mejora, retirar el piloto y diagnosticar entrega/cola.

PRE independiente `undo_clear_announcement_pre`: PASS para piloto, no para audibilidad. 463 archivos tracked/untracked
no ignorados, huella pre/post idéntica `bd68e5d309c1f32bc4399261233ab53f52f685f9e4473342f8b1c89ee4b002c6`.
RED: fallo manual comunicado. No se añade un test unitario que simule o afirme audibilidad de VoiceOver;
la lógica de edición no cambia. Previews anteriores conservados: este delta solo afecta la locución.
Xcode MCP verifica Signature-Manual y iPhone14 de Jesús físico/iOS26.7; la versión histórica26.6.1 no se atribuye al retest.
Build oficial PASS; GetBuildLog sin issues estructurados. Log completo inspeccionado: único warning de extracción
AppIntents ya conocido, sin warnings Swift/Clang. Artefacto:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/GetBuildLog/7A55F026-FF68-4A97-8F02-D830B1B27FAF.txt`.
Tras confirmar el propietario que el iPhone está desbloqueado, RunProject devuelve lanzamiento correcto:
11,023 s, PID1157, Signature-Manual/iPhone14 físico, destino previamente identificado con iOS26.7.
Log: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260913-001300.txt`.
El binario nuevo está lanzado; la escucha de VoiceOver sigue pendiente del propietario.

POST independientes `undo_clear_announcement_post_ax` y `undo_clear_announcement_post_standards`: PASS estático acotado,
sin nuevos hallazgos; P2 audible sigue abierto. 463 archivos, huella pre/post comprobada por el orquestador e idéntica:
`9cef6eb166412830d5be38f3ea4cf2ace2292a634147c88d036f887ade04f2c1`.
Auditoría de estilo: 1 Swift, 0 candidatos; diff check limpio. Retest pendiente en el binario nuevo:
dos trazos → Deshacer → escuchar; Borrar el restante → escuchar, sin duplicados ni desplazamiento de foco.
08.4 sigue abierta.

## Control por voz: cancelación confirmada — 2026-09-13

El propietario informa de locución correcta de los botones Deshacer trazo y Borrar firma con VoiceOver.
Confirma sus etiquetas; este reporte no precisa el valor del lienzo ni los anuncios posteriores a activar esas acciones.
Después activa Control por voz y dice «Tocar cancelar firma»: regresa a la pantalla principal y aparece
«Captura cancelada». Se resuelve el pendiente de cancelación por voz, sin inferir retorno del foco ni locución del mensaje.
Contexto de la sesión: iPhone 14 físico/iOS 26.6.1, identificado previamente por el propietario; no se vuelve a verificar
la versión del sistema en este reporte. Evidencia manual comunicada, sin grabación ni nueva ejecución por herramientas.
Cambio documental; build/tests N/A. Los demás pendientes se conservan.

## Sesión manual preparada — 2026-09-10 17:46

El propietario ofrece firma de prueba, dispone de iPhone 11 físico y acepta comenzar en simulador. Tras reconectar
Xcode MCP se verifica este checkout en `windowtab-FDcXNxc6Nj`. La herramienta DeviceInteraction solo ofrecía
simuladores iOS 27; se seleccionó iPhone 17/iOS 27. No se extrapola esta ejecución al iPhone físico ni a iOS 26.

Acceso temporal en App, exclusivo de la rama `fixtureReady` y compilación `FRANALONSO_AUTH_FIXTURE`: pantalla
y ViewModel de validación presentan la captura real en sheet y conservan el resultado solo en memoria. Dos textos
temporales distinguen firma recibida sin guardar y cancelación. No se altera la implementación de Clients.
Propuesta independiente PASS; huella pre/post de 457 archivos idéntica:
`384ab28d10c041fccceafb3abee24c70a913eb64cd286e8fff643f58878ab5c7`.
Auditorías focales independientes de estándares/estilo y accesibilidad estática PASS; huella pre/post de 459 archivos
idéntica: `05ea8a7a03b101e25326033e266566684d162a5191cbe099cd3b1fba92fc239f`.

InstallAndRun MCP informó instalación/ejecución correctas, pero EndSession terminó ese proceso. Se cerraron ambas
sesiones de interacción. Ajuste de lanzamiento revisado: copia temporal de Develop en xcuserdata ignorado, habilitando
únicamente `--franalonso-auth-fixture-signed-out` en LaunchAction. El primer Run de las 17:45:37 no acredita selección
del esquema ni aislamiento efectivo y fue detenido; no se cuenta como evidencia de fixture. La ejecución final se hizo
tras verificar el esquema temporal mediante XcodeSwitchScheme. RunProject 17:46:08 PASS, 3,804 s, PID 61417. Se comprobó
en el proceso vivo que el único argumento de fixture era el signed-out esperado. Esa ejecución selecciona la composición
existente en memoria, sin bootstrap Firebase ni AppRuntime. Log:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260910-174608.txt`.
Build correcto; permanece el aviso conocido de extracción AppIntents. No se han ejecutado nuevos tests para el cableado
temporal trivial ni se atribuye a este lanzamiento la evidencia 28/28 anterior.

Tras lanzar, se restauraron App y catálogo byte a byte, se retiraron los dos Swift temporales y el esquema local creado,
y se restauró Develop/iPad Air 11-inch (M4)/26.5. El scheme canónico permaneció byte-idéntico. La huella de los 457 archivos
volvió exactamente a la inicial antes de esta anotación documental. PID 61417 seguía vivo y conservaba el argumento.
Copias del acceso temporal y backups fuera de Git:
`/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/manual-validation`.

Pendiente de resultado del propietario: abrir captura, dibujar dos trazos ficticios, deshacer uno y confirmar; comprobar
mensaje de recepción sin guardado. Después se verificará cancelar y el modo por puntos. No se ha acreditado aún gesto,
foco, anuncios, scroll, Inspector ni AT. Mantener el proceso preparado: si termina, relanzar mediante MCP con el argumento
exacto; abrir el icono sin argumento conserva la ruta normal existente y no constituye una sesión de prueba aislada.
No pulsar Run después de retirar el acceso temporal: recompilaría la app normal. Sin commit/push ni cierre de PLU-38.

Comprobación documental posterior: `git diff --check` PASS. El validador global de gobernanza falla por seis enlaces
a capturas de 08.3 del Escritorio que ya no existen (13:40:20–13:41:57), fuera del cambio 08.4. No se alteran esos
archivos ni se presenta el resultado global como PASS; no impide realizar esta sesión manual.

## Sesión manual retomada en iPad — 2026-09-10 18:04

El propietario empezó a dibujar y deshacer antes del fin de la preparación anterior; comunica que la app terminó
y que al relanzarla apareció Login. No se atribuye el cierre a otro proyecto sin evidencia ni se cuenta ese intento
como validación completa. Se corrige la retirada prematura: acceso temporal y esquema local permanecen activos
hasta que el propietario confirme el fin de las comprobaciones. Su retirada sigue pendiente y no deben entregarse.

Por instrucción explícita del propietario, no usar iPhone 17; los destinos acordados son iPad o su iPhone 14.
Destino actual: simulador iPad Air 11-inch (M4)/26.5, esquema local FranAlonso-Signature-Manual. RunProject MCP
18:04:28 PASS, 37,653 s, PID 69739 vivo y único argumento de fixture signed-out comprobado. Log:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260910-180428.txt`.
Build sin errores; mantiene aviso previo AppIntents. App, catálogo y los dos Swift temporales coinciden byte a byte
con las copias auditadas; esquema canónico Develop intacto. No se modifica la implementación de captura08.4.

Ahora el acceso temporal está presente en el árbol local y no se ha retirado: la anotación anterior de restauración
describe únicamente aquella primera sesión. Permanecen pendientes confirmación/cancelación y los demás resultados
manuales. Sin commit, push, cierre de PLU-38 ni avance de subfase.

## R01 — Dibujo, deshacer y confirmar — 2026-09-10

Confirmación explícita del propietario: «Correcto todo ese recorrido». Se refiere a la sesión preparada en el simulador
iPad Air 11-inch (M4)/26.5 y al recorrido indicado inmediatamente antes:

1. Abrir Capturar firma y dibujar dos trazos ficticios.
2. Deshacer trazo elimina únicamente el último.
3. Confirmar firma cierra la captura y muestra «Firma recibida para esta prueba. No se ha guardado».

Resultado R01: PASS manual por el propietario. Acredita este gesto, deshacer y confirmación con recepción del valor
en el consumidor temporal; no acredita guardado durable ni foco/locución con tecnologías de asistencia. Borrar,
cancelar y modo por puntos aún pendientes. Las clasificaciones limitadas de la matriz conservan las técnicas
no ejecutadas. Acceso temporal y sesión permanecen activos. Cambio de evidencia exclusivamente documental: build/tests N/A.

## R02 — Borrar y cancelar — 2026-09-10

El propietario confirma «Si, correcto» para ambos recorridos propuestos, en la misma sesión del simulador
iPad Air 11-inch (M4)/26.5:

1. Abrir otra captura, dibujar dos trazos y pulsar Borrar firma: lienzo vacío y Confirmar firma deshabilitado.
2. Dibujar de nuevo y pulsar Cancelar firma: cierre de la captura y mensaje
   «Captura cancelada. No se ha guardado ninguna firma».

R02 PASS manual por el propietario. No se extrapola a cancelación del gesto por interrupción/redimensionado,
Escape, cierre del proceso, foco ni anuncios de tecnologías de asistencia. Modo por puntos y demás técnicas
pendientes. La sesión y el acceso temporal siguen activos. Actualización documental; build/tests N/A.

## Retirada autorizada del modo por puntos — 2026-09-10

Se eliminan controles, cursor, estado/acciones exclusivos, doce claves de texto y dos tests específicos. La instrucción
de dibujo ya solo describe mano alzada. R01/R02 anteriores no se borran; deben confirmarse en la versión actualizada.
Revisiones previas de propuesta PASS, con huella pre/post idéntica de 459 archivos:
`f1bae91a9ff2eb5ea0d1a298e0ca2c499610e535d06ea459f1f95fc4d5209e7d`.

[ADR 0027](../../ADRs/0027-freehand-signature-input-product-exception.md) resuelve explícitamente la excepción
a la política interna de ADR 0022. No se afirma que todas las personas puedan dibujar ni se acredita firma por poderes.
Referencias primarias: [2.5.1](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures.html),
[2.5.7](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html),
[2.1.1](https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html).

Acceso temporal activo. Para retirarlo al finalizar, restaurar el catálogo limpio actualizado guardado fuera de Git en
`manual-validation/Localizable.xcstrings.freehand.before`; la copia anterior reintroduciría el modo eliminado.
Regresión MCP completada: 26/26 resultados en cuatro suites, incluidos los cinco argumentos de coordenadas inválidas.
Resumen: `9702A6D0-6A29-410C-A2EA-A4F188187DEE.txt` (ruta completa en phase-08.md).
Previews y revisión posterior completadas con los límites descritos abajo. Las tecnologías de asistencia siguen pendientes.

### Validación de la retirada

Build Xcode MCP Develop/iPad Air 11-inch (M4)/26.5, 18:27:12: PASS en 12,878 s. Log completo:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260910-182712.txt`.
Sin errores; el aviso previo de extracción AppIntents permanece. Regresión 26/26 ya registrada.

Cuatro renders posteriores a la retirada inspeccionados. Destino efectivo iPad Pro 13-inch (M5)/iOS 27, diferente
al destino de build/tests; no equivalen a prueba visual iPadOS 26.5 ni a operación del propietario:

| Artefacto | Variante | Observación estática/visual |
|---|---|---|
| [Mano alzada Large](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/freehand/base.png) | Light / Standard / Large | Instrucción sin modo alternativo y acciones completas. |
| [Mano alzada AX5](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/freehand/ax5.png) | Dark / Standard / AX5 | Título, texto, lienzo y acciones visibles completos en este tamaño de iPad. |
| [Mano alzada XXXL](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/freehand/xxxl.png) | Light / Increased / XXX Large | Acciones y tinta completas; sin controles por coordenadas. |
| [Mano alzada estrecho RTL](/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/freehand/rtl.png) | Dark / Increased / Large, 350 pt RTL | Trazos sin invertir, instrucciones y acciones completas. |

Metadatos originales en `freehand/previews.json` del mismo directorio local. Sin nueva medición de ratios: los assets
y estilos de tinta/acciones no cambian respecto a las mediciones previas. Inspección visual no acredita Inspector ni AT.
Revisión posterior de estándares/estilo por audit_freehand_final_standards: PASS, sin hallazgos.
Reauditoría accesible por review_freehand_accessibility_scope: PASS estático/visual, inspección directa de los cuatro
PNG, doce claves retiradas y 55 criterios (35 aplicables/20 N/A). Se reutilizó el revisor independiente de propuesta
porque crear un agente nuevo falló por límite de agentes. No acredita el requisito de revisor nuevo de la puerta final;
ese requisito y la evidencia runtime siguen pendientes. No se declara cierre de ADR 0022 ni de 08.4.
Huella pre/post comprobada por el implementador tras ambas revisiones, 459 archivos idénticos:
`37ba75728f6819b3f59f96cb119042b8308788ffbdcc599226b06fba37c56228`.

### Sesión vigente con mano alzada — 2026-09-10 18:34

RunProject 18:31:23 compiló correctamente pero informó fallo de arranque. El PID comunicado por la consulta de
sesión posterior no estaba vivo; ese intento no acredita lanzamiento. Reintento Xcode MCP 18:34:53 PASS en 4,760 s:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260910-183453.txt`.
PID 78962 vivo y único argumento de fixture `--franalonso-auth-fixture-signed-out` verificado sin volcar datos de consola.
Esquema local FranAlonso-Signature-Manual, iPad Air 11-inch (M4)/26.5. Acceso temporal y proceso se dejan activos
hasta que termine el propietario. El arranque acredita preparación; R01/R02 de este binario y las técnicas AT siguen
pendientes. No repetir ni inferir como PASS las pruebas manuales de la versión anterior.


### R01/R02 — regresión final confirmada por el propietario — 2026-09-10

«Muy bien, he probado todo lo anterior y funciona bien». Confirmación de los recorridos funcionales en la versión
sin modo por puntos, tras el lanzamiento MCP 18:34:53 en iPad Air 11-inch (M4)/26.5:

- R01 PASS: dibujar dos trazos, deshacer únicamente el último y confirmar; cierre y recepción sin guardado.
- R02 PASS: borrar deja el lienzo vacío y la confirmación deshabilitada; dibujar de nuevo y cancelar cierra con
  mensaje de cancelación sin guardado.

Sustituye el pendiente de regresión funcional de las anotaciones anteriores. Fuente: reporte explícito del propietario;
no nueva observación directa del agente. No se infiere Inspector, tecnologías de asistencia, interrupción/redimensionado
ni persistencia. El acceso temporal se conserva para completar las técnicas restantes. Actualización documental;
build/tests N/A, sin cambios de código ni lanzamiento adicional.


### VoiceOver básico en iPhone 14 físico y pausa de validación — 2026-09-10

El propietario responde «Todo correcto» al recorrido solicitado de VoiceOver: abrir Capturar firma, leer título,
instrucciones y botones, cancelar y volver a Capturar firma. Precisa iPhone 14 físico, no iPad; sistema no indicado.
PASS manual acotado a ese recorrido. No se infiere dibujo bajo VoiceOver, confirmación, lectura de errores,
estados con tinta, rotor, locución exacta ni cobertura global. No hay audio ni observación directa del agente.
La atribución anterior al iPad de la siguiente prueba propuesta queda corregida para este resultado.

El propietario suspende las pruebas hasta concretar lectura/aceptación del texto y vínculo con firma/guardado.
Se conserva la evidencia funcional del componente; no acredita consentimiento de extremo a extremo. Los pendientes
siguen abiertos, sin requerir al propietario nuevos recorridos ahora. Sin cambios de código ni configuración.


### VoiceOver — confirmar y devolver el foco — 2026-09-11

El propietario realiza el recorrido solicitado en iPhone 14 físico: preparar un trazo con VoiceOver desactivado,
activar VoiceOver, recorrer hasta Confirmar firma y activarlo. Reporte literal: «Confirmar firma botón y acaba en el
botón Capturar firma botón». PASS manual acotado al anuncio del nombre/rol de Confirmar firma, su activación y
retorno del foco al botón de apertura del montaje temporal. No acredita firma dibujada con VoiceOver, errores,
estados deshabilitados, otras tecnologías de asistencia ni foco del futuro formulario durable.
La pausa de pruebas durante planificación queda superada por esta sesión; permanecen los demás pendientes de la matriz.
No se modifica código ni se repiten build/tests: N/A para registrar evidencia aportada por el propietario.


### VoiceOver — controles con firma vacía — 2026-09-11

En la misma sesión de iPhone 14 físico, el propietario abre la captura sin dibujar y recorre Deshacer trazo, Borrar
firma y Confirmar firma con VoiceOver. Reporte literal: «en los tres dice atenuado botón». PASS manual acotado al
anuncio del rol botón y estado deshabilitado de los tres controles con firma vacía. No se infiere de este resultado
la activación posterior, anuncios tras editar, lectura de errores ni otras técnicas de asistencia.
Registro documental; código sin cambios, build/tests N/A y restantes pendientes conservados.


### Interrupción tras completar trazos — 2026-09-11

En la sesión de iPhone 14 físico, el propietario confirma «si, todo correcto» al recorrido solicitado: VoiceOver
apagado, dos trazos terminados levantando el dedo, ir a Inicio y volver sin terminar la app desde el selector.
Ambos trazos se conservan y Deshacer elimina solo el último. PASS manual limitado a suspensión/retorno con trazos
completos; no acredita cancelación de un gesto en curso, redimensionado ni recuperación durable tras terminar proceso.
El propietario propone a continuación revisar distribución de acciones: Deshacer/Borrar en una fila de iconos bajo
el lienzo y Confirmar separado y menos alto. Propuesta visual pendiente; no se modifica código ni se invalida esta
prueba por discutir el cambio. Registro documental, build/tests N/A.


### Distribución de botones autorizada — 2026-09-11

El propietario aprueba agrupar Deshacer/Borrar como iconos bajo el lienzo y reducir altura de Confirmar. Implementado
solo en ClientSignatureCaptureScreen: fila trailing con separación 16 pt, Labels iconOnly, nombres existentes,
Large Content Viewer y objetivos mínimos 44×44 con contentShape. Fondo Surface y bordes semánticos; rol/disabled,
acciones y anuncios conservados. Confirmar mantiene estilo primario y elimina únicamente el mínimo interior44.
Sin cambios de Domain, ViewModel, estilo compartido, catálogo ni nuevos tests estructurales.

Revisión previa independiente por agente nuevo PASS, 462 archivos pre/post idénticos:
`77915993aafda695f758e1b89a6d97e4e463ba396eaf0d6e3ddafdf46b71fcb7`.
Revisión posterior estática y source-style por otro agente nuevo sin hallazgos; 462 archivos pre/post idénticos:
`bd6bed08494954bbc3fc03455a67cede01d9ccb8838b1fc249dc64879dd04693`.
Huellas verificadas por el orquestador. Ratios de assets opacos, Light/Dark/Light High/Dark High:
BrandPrimaryInk/Surface 6,75/6,51/8,52/9,95 y ErrorInk/Surface 5,24/5,00/7,37/8,41. No son mediciones de render.

XcodeListWindows falla repetidamente con Transport closed aunque Xcode está abierto y el servidor está habilitado.
Propietario avisado para reconectar. Build, previews Large/XXX Large/AX5/RTL y ejecución del nuevo código pendientes;
no se sustituye la compilación por RocketSim ni se presenta un binario anterior como validación de este cambio.
Falta medir objetivo real de Confirmar, estados deshabilitados y verificar nombres/acciones/foco con iconos nuevos.
Los resultados anteriores conservan su fecha y versión; no validan automáticamente la nueva presentación. La matriz
mantiene sus límites, 08.4 sigue abierta y se conserva el acceso temporal. Diff-check limpio; sin entrega Git.


### Botones: compilación, visual y runtime focal — 2026-09-11

Reconexión confirmada por XcodeListWindows: windowtab-az8xO7lJDL, checkout FranAlonso. Scheme Signature-Manual;
destino inicial iPhone14 de Jesús/26.6.1, cambiado temporalmente a iPad Air11M4/26.5. RunProject02:20:42 PASS12,791s,
PID84938. Log completo inspeccionado: aviso AppIntents previo, ningún otro warning/error encontrado; GetBuildLog
no devuelve incidencias estructuradas. No se declara cero warnings. Destino inicial restaurado; app iPad abierta por
petición de revisión del propietario, sin Run/Stop físico ni retirada del montaje temporal.

El propietario responde «ha quedado bien» al observar la distribución nueva. Aprobación visual, no prueba global AT.
RocketSim recoge nombres Deshacer trazo/Borrar firma/Confirmar firma y frames44×44/44×44/548×50,5pt, separación16pt.
Prueba focal por HID: trazo ficticio → estado listo → icono Deshacer → vacío; otro trazo → icono Borrar → vacío,
con postcondiciones verificadas. Lienzo vacío y captura abierta al terminar. El campo enabled de RocketSim no distingue
el estado deshabilitado observado por VoiceOver; no se usa como evidencia de habilitación real.

Previews Xcode MCP inspeccionadas: Large claro, XXX Large oscuro, AX5 claro/contraste alto/350pt RTL, AX5 oscuro con
contraste alto y Empty oscuro. Destino efectivo iPad Pro13M5/iOS27, distinto del runtime iPadAir/iOS26.5. En estrecho AX5,
Confirmar queda parcialmente fuera del viewport: acceso mediante scroll pendiente de runtime. Estado inactivo de
Confirmar muy oscuro en preview y runtime; observación de legibilidad conservada, no regresión atribuida a este layout
ni fallo del umbral de contraste que exime controles inactivos.

Revisión focal visual independiente favorable, sin hallazgos nuevos de distribución; digest462archivos pre/post
idéntico verificado: `20fc242a16fc0de3e30ba34f6ed31b80c5d4bc7ec4007a0f6e3ef4dae2da7bc3`.
Artefactos: [Large](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/large-light.png>),
[XXX Large](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/xxxlarge-dark.png>),
[AX5 RTL](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/ax5-rtl-light-high.png>),
[AX5 oscuro](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/ax5-dark-high.png>),
[vacío](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/empty-dark.png>),
[runtime](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/runtime-ink-dark.png>) y
[log](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/RunProject-Log-20260911-022042.txt>).
No nuevas suites por cambio visual sin lógica; 26/26 anteriores conservados como históricos. Inspector y AT de la nueva
presentación permanecen pendientes. No se cierra08.4 ni se entrega Git. Esta entrada resuelve el bloqueo de conexión
registrado anteriormente sin convertir evidencia parcial en cierre de accesibilidad.


### VoiceOver — reporte posterior al cambio de botones — 2026-09-11

El propietario comunica: «He probado los botones con voiceover y los ha nombrado igual que antes, diciendo atenuado
cuando estaban deshabilitados, los he probado tambien y funcionan y hacen lo que tienen que hacer. Al volver ha
vuelto donde antes». Reporte favorable de nombres, estados deshabilitados, operación y retorno del foco al origen.
Pendiente identificar el dispositivo y confirmar que veía la nueva fila de iconos: la última instalación realizada
por el agente fue en iPad Air11M4/26.5; el iPhone14 quedó seleccionado, pero no recibió una nueva ejecución del agente.
No atribuir este reporte a un dispositivo o binario por inferencia. Una vez identificado, completar la evidencia focal
sin extrapolar a Inspector, otras tecnologías de asistencia, gesto en curso o redimensionado. Código sin cambios;
build/tests N/A para registrar el reporte. 08.4 permanece abierta.


### Dispositivo del reporte VoiceOver confirmado — 2026-09-11

El propietario precisa «iphone 14 ios 26.6.1» para el reporte posterior al cambio de botones. La evidencia manual
queda atribuida a iPhone14 físico/iOS26.6.1: nombres conservados, anuncio de estado atenuado, acciones correctas y
retorno del foco al origen. PASS manual focal aportado por el propietario. Resuelve la identificación de dispositivo
pendiente en la entrada anterior; no es una ejecución/instalación física realizada por el agente ni una verificación
del identificador del binario. No extrapolar a Inspector, otras tecnologías, gesto en curso o redimensionado.

### Validación de cierre en curso — 2026-09-11

El propietario autoriza continuar los pendientes. Control por voz en iPhone 14/iOS 26.6.1: reporte «Todo correcto»
al reconocer y ejecutar «Tocar Deshacer trazo», «Tocar Borrar firma» y «Tocar Confirmar firma» sobre trazos preparados.
No acredita Cancelar mediante voz ni el dibujo libre por esa técnica.

Bloqueo físico durante segundo trazo, sin levantar el dedo: «eso ha ocurrido exactamente, al volver no estaba el que
estaba realizando». PASS manual: conserva el primer trazo completado y descarta el segundo interrumpido. No se infiere
redimensionado ni recuperación tras terminar el proceso.

Dos agentes nuevos independientes completan auditorías operacionales read-only: accesibilidad sin hallazgos nuevos
de implementación y estándares sin defectos de arquitectura/Domain/VM/tests. Estándares aprueba previamente retirar
el harness al terminar pruebas: restaurar solo fixtureReady de HEAD, retirar sus dos archivos y dos claves exclusivas,
conservar Develop byte idéntico. Build Develop y tests de composición específicos después; sin tests nuevos de espejo.
Digest pre/post de ambos y comprobación del orquestador: 462 archivos tracked y untracked no ignorados,
`8107f53d2a29f9d8251706991d64ed383f6e637fe3a54720824ffbb03d5ab7c6`.
La revisión UI exige consolidar esta matriz y mantiene el gate abierto por técnicas pendientes, no por un defecto nuevo.

### VoiceOver, simulador y límites de herramientas — 2026-09-11

El propietario confirma en iPhone14/iOS26.6.1: «Si, se ha oido el error, luego bien trazo terminado, los botones se han
dicho correctamente». PASS manual para anuncio del error al tocar sin desplazar y de trazo terminado después de
corregir dibujando. Su respuesta no identifica expresamente el valor inicial del lienzo ni las frases posteriores a
Deshacer/Borrar, por lo que no se dan por escuchadas esas frases concretas.

Xcode MCP relanza el mismo código en iPad Air11M4/26.5 a las02:43:29: PASS20,171s, PID90608. Log completo inspeccionado:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260911-024329.txt`.
Solo warning previoAppIntents; no se repiten tests sin cambios de lógica. La rotación explícita Portrait→Landscape Right
reduce la ventana del componente de820×1125 a375×486pt; trazo terminado visible, proporcional y estado «Firma lista
para confirmar» conservado. Se restaura Portrait. Este recorrido no acredita cambio de tamaño mientras se dibuja.

Limitaciones observadas en herramientas: RocketSim no identifica ancestro desplazable en el botón (no_scrollable_ancestor)
y los gestos de desplazamiento en la ventana pequeña no producen postcondición visible. Activación AX de Capturar sí
abre el componente; un gesto HID en Portrait sí genera tinta. No se atribuye todavía el fallo de scroll a la app.
Inspector beta y estable permiten seleccionar Simulator/Fran DEV, pero Run Audit no devuelve informe. El ajuste de
Dynamic Type en Inspector no produjo cambio visual verificable; restaurado al valor inicial0,2727272727272727.
No se presenta ese intento como ejecución deAX5 ni como auditoría sin incidencias.

Acceso total con teclado se activa desde Ajustes del simulador, comprobando FKAEnabledSwitch=1; envío de teclado del
Simulator activado. Tab/Right no producen un recorrido verificable por los controles. Se restauran FKAEnabledSwitch=0
y Capture Keyboard=0, verificados por árbol nativo. Control por botón no aparece en la pantalla Accesibilidad del
simulador observado; no se ha probado. El propietario no tiene teclado ni Control por botón preparados en el iPhone.
Se conserva el harness para terminar la validación; estas limitaciones no se convierten en PASS ni en defectos confirmados.

### AX5 y reducción de transparencia en runtime — 2026-09-11

Se supera el bloqueo de Inspector para AX5 mediante Ajustes nativos del mismo iPad: Tamaños más grandes=1 y slider
100%, comprobados por árbol de accesibilidad. Al volver a la captura se ve tipografía máxima y acciones fuera de la
vista inicial. Swipe sobre instrucciones desplaza el ScrollView y deja Deshacer, Borrar y Confirmar completamente
visibles, sin solapamientos. Tap HID en Confirmar cierra y muestra «Firma recibida para esta prueba. No se ha guardado».
PASS de acceso y operación mediante scroll AX5 en el sheet del iPad; no acredita ventana mínima375pt ni teclado.
[Captura AX5 tras desplazamiento](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/runtime-ax5-scrolled.png>).
Restaurados slider27% con extra activo y después extra=0/slider50%, equivalentes al valor inicial Large; verificado.

Reducir transparencia=1 en Ajustes, verificado por árbol nativo. Apertura de captura, trazo HID y estado listo; texto,
lienzo y acciones legibles en Dark/Large sin alteración de layout visible. Inspección focal, sin medición completa de
contraste de render. [Captura](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-buttons/runtime-reduce-transparency.png>).
Reducir transparencia restaurado=0, verificado. No se modificaron las demás preferencias visuales.

### Inspector aportado por el propietario — 2026-09-11, capturas 08:13–08:14

El propietario pulsa Run Audit y aporta el resumen y las tres selecciones de elementos. Esto resuelve la falta de
informe de la sesión anterior para la captura vacía mostrada. Resultado real: **tres avisos**, no auditoría sin incidencias.
Se conservan copias byte a byte de las cuatro imágenes fuera de Git; los originales permanecen en Desktop.

| Aviso y elemento | Evidencia | Disposición |
|---|---|---|
| Contrast failed: Confirmar deshabilitado; 1,68:1, #39393D frente a #0E0E0F | [Selección](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-inspector/contrast-disabled-confirm.png>) | Medición de Inspector conservada. El componente inactivo está exento del mínimo de WCAG 1.4.3; observación de legibilidad, sin corrección obligatoria. No extrapolar al estado habilitado. |
| Dynamic Type unsupported: instrucciones | [Selección](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-inspector/dynamic-type-instructions.png>) | Advertencia no reproducida: Text sin fuente fija ni límite de Dynamic Type y escalado AX5 observado. No cambiar fuentes para silenciar el auditor. |
| Dynamic Type unsupported: Confirmar | [Selección](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-inspector/dynamic-type-confirm.png>) | Advertencia no reproducida: Text y PrimaryActionStyle no fijan tamaño; AX5 muestra texto ampliado completo y confirmación tras scroll ya acreditada. |

[Resumen original de los tres avisos](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-inspector/audit-summary.png>).
La exención del estado inactivo se contrasta con [W3C, Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
Las capturas no identifican por sí solas el binario exacto ni la causa del desacuerdo de Inspector con el escalado observado.
No se afirma un defecto universal de la herramienta ni se ocultan sus avisos.

Revisión focal independiente por agente nuevo audit084_inspector_evidence: favorable, sin defectos nuevos confirmados.
Inspeccionadas las cuatro capturas, runtime-ax5-scrolled.png, Screen y PrimaryActionStyle. Revisión operacional read-only:
462 archivos tracked/untracked no ignorados, digest pre/post idéntico y comprobado por el orquestador antes de esta anotación:
`3b37d1d4b89c494b4854227d1a38f24aca35736a2273551b5659c158c9326a02`.
Solo actualización documental; build/tests N/A y sin cambios ejecutables. No repetir AX5 por estos avisos. El cierre
integral conserva los pendientes enumerados; no se retira el acceso temporal ni se entrega Git por recibir estas capturas.

## Control por botón en iPhone 14 — 2026-09-11

PASS manual comunicado por el propietario en iPhone 14 físico/iOS 26.6.1. Configuración: botón de pantalla
completa, Seleccionar ítem y exploración automática. Con dos trazos preparados, selecciona Deshacer trazo
y confirma que desaparece solo el último; selecciona Borrar firma y confirma que se elimina el restante.
Cancelar firma cierra la captura. Mediante Control por botón abre de nuevo Capturar firma; desactiva
temporalmente esta ayuda para dibujar y la reactiva para seleccionar Confirmar firma. Confirma cierre
y resultado de firma recibida en el acceso temporal de prueba.

Evidencia basada en respuestas del propietario a cada paso, sin grabación. Acredita selección y operación
de esas acciones sobre tinta preparada; no dibujo mediante Control por botón, recorrido AX5, foco exacto
de retorno ni teclado. Se conserva la excepción de trayectoria de ADR 0027. Próximo recorrido: teclado
del Mac en simulador iPad. Build/tests N/A: registro documental sin cambios de código.

## Teclado del Mac en iPad simulado — 2026-09-11

Configuración: iPad Air 11-inch (M4)/iPadOS 26.5, Acceso total con teclado y teclado del Mac en la ventana
nativa de Simulator. El propietario confirma que Tab mueve el foco entre grupos y flecha abajo permite
entrar en el grupo de contenido. Con dos trazos preparados con el ratón, selecciona Deshacer y pulsa
Espacio: desaparece solo el último. Borrar elimina el restante y Cancelar cierra, sin usar el ratón.
Después abre Capturar firma con el teclado, dibuja un trazo con el ratón, selecciona Confirmar y pulsa
Espacio: la captura cierra, muestra firma recibida y permite volver a seleccionar Capturar firma.

PASS funcional manual para las acciones indicadas y salida/reentrada; no acredita dibujar con teclado
ni restauración automática del foco. Reporte explícito del propietario: el contorno de foco rosa se
confunde con el borde de los botones de edición y también cuesta distinguirlo en los otros botones.
Inicialmente esta dificultad visual hizo parecer que flecha abajo no entraba en el grupo.
Visibilidad del foco y contraste quedan pendientes de diagnóstico; no se declara PASS visual ni una
relación de contraste medida a partir del relato. Capturas aportadas: Desktop/Captura de pantalla
2026-09-11 a las 21.51.02.png (configuración) y 21.52.21.png (grupo de contenido resaltado).
Build/tests N/A: registro documental, sin cambios de código.

### Revisión focal de visibilidad de foco

Revisor independiente ios-accessibility-reviewer: P2 de usabilidad por reporte del propietario, sin
ratio suficiente para clasificar 1.4.11 ni causa atribuible a tint. Solicita comparar Confirmar y
Deshacer individualmente enfocados con su estado sin foco y la configuración de aspecto FKA.
No se aprueba un parche especulativo con FocusState/focusable ni cambio global de marca. Si el halo
coincide con el borde, evaluar separación neutra local conservando foco nativo y objetivos44pt.
Revisión operacional read-only: 462 archivos; digest pre/post idéntico verificado por el orquestador:
`caf98de7e5afea76779a4bc2ba22b0b2b91dfae74b8d129a99632f3a7e9e0e73`.

Imágenes conservadas en `/Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/`:
`full-keyboard-access-enabled.png`, `content-group-focused.png` y `confirm-focused.png`. Esta última
fue tomada por RocketSim tras el aviso del propietario de haber enfocado Confirmar, pero solo permite
ver el marco del grupo, no distinguir un indicador individual. El nombre no acredita ese foco;
posible autoocultación o limitación de captura sin causa verificada. Pendiente evidencia individual.
Fuentes: [Apple FKA](https://support.apple.com/en-gb/guide/ipad/ipad5f765d6f/ipados) y
[Apple HIG teclados](https://developer.apple.com/design/human-interface-guidelines/keyboards).

### Referencia visible en el botón principal

El propietario dirige la inspección al botón Capturar firma de la pantalla temporal, donde el mayor
tamaño permite distinguir mejor el foco. RocketSim conserva
[main-button-focus.png](</Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/main-button-focus.png>).
Inspección visual: se aprecia un contorno doble rosa/magenta adyacente al relleno rosa del botón.
Esta captura sí aporta un indicador individual visible y descarta que toda captura RocketSim omita
siempre ese indicador. No determina por qué no se veía en la captura anterior ni acredita el foco
de Confirmar dentro del sheet. Sin medición de contraste ni cambio de código; permanece el hallazgo
de dificultad de distinción reportado por el propietario. No se requiere repetir el recorrido funcional.

### Estudio de mejora del foco

[Propuesta y fuentes](../../progress/08-4-keyboard-focus-proposal.md): estudio completado con revisión
independiente y digest462 estable. Medición orientativa del PNG sin ICC: banda magenta/relleno2,25:1;
banda exterior/fondo7,95:1. No se declara incumplimiento por una sola pareja del indicador compuesto.
No se encontró API pública documentada para cambiar solo el halo FKA de Button SwiftUI. Se recomienda
prototipo local de separación neutra y, como alternativa, decoración separada de tint, sujeto a runtime.
Sin cambios ejecutables ni de preferencias; hallazgo visual abierto.

## Prototipo con separación probado — 2026-09-11

El propietario autoriza probar aire conservando color. Único archivo ejecutable cambiado en este ensayo:
SignatureManualValidationScreen.swift, botón Capturar firma del acceso temporal. Label con mínimo44pt,
padding horizontal16/vertical6, relleno brandPrimary y margen exterior6 sobre canvas; estilo plain,
tint brandPrimary y contentShape interaction capsule. Conserva acción, nombre y accessibilityFocused.
PrimaryActionStyle compartido y controles del sheet no se modifican.

RunProject oficial Xcode MCP, Signature-Manual/iPadAir11M4/26.5: PASS9,561s, PID17468.
Log completo: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20260911-230619.txt`.
GetBuildLog no devuelve incidencias estructuradas; log completo contiene solo aviso AppIntents previo.
No tests decorativos nuevos ni regresión lógica repetida; comportamiento de captura no cambiado.

Previews inspeccionadas Large Light, XXXLarge Dark y AX5 Light High: texto/botón completos.
Destino efectivo iPadPro13M5/iOS27.0; no acredita foco ni runtime26.5. Copias fuera de Git:
`/Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/gap-preview-*.png`.

Runtime: `gap-prototype-focused-dark.png` muestra banda neutra #1C1C1E entre relleno y halo.
Muestreo PNG nativo x400: fondo hasta1229, banda rosa1230–1233, magenta1234–1237, separación1238–1241,
relleno desde1242. Los6pt de margen se traducen en2pt visibles en esta sección porque el indicador
ocupa parte del margen; no se afirma6pt de aire útil. `gap-prototype-light-after-update.png` muestra
Light sin foco individual; `gap-prototype-focused-light.png` capturó aún Dark durante transición.
Los nombres de archivos no acreditan su apariencia ni foco por sí solos.

Propietario: inicialmente percibe mejora en oscuro como borde oscuro; precisa que en claro sí ve aire y
que en oscuro se ve menos, pero se ve. Confirma después que Espacio abre la captura en este prototipo.
Se conserva margen6; el aumento a10 fue revisado como alternativa pero no aplicado tras esa aclaración.
Apariencia del simulador restaurada y verificada Dark. Preferencias FKA conservadas.

Revisión preejecutable independiente PASS, huella463 estable
`6cb9b08afacc4b6989bc74a9b45ecfb99e2461343657484b1f3681d39a00617a`.
Revisiones POST por nuevos agentes de estándares y accesibilidad/estilo: sin hallazgos en el prototipo.
Huella463 pre/post idéntica verificada por root:
`95f619059d75d60964279c039560044b67d176c1001a571c3936c37fe2849846`.

Resultado favorable limitado al acceso temporal: aire distinguible manualmente en ambos modos y
activación conservada. No cierra foco de Deshacer/Borrar/Confirmar/Cancelar del sheet ni08.4.
Siguiente paso: trasladar la solución a los controles de captura y comprobar su geometría y foco
sin recuperar la altura excesiva rechazada ni repetir los recorridos ya acreditados.

## Aclaración del foco dentro del grupo — 2026-09-11

El propietario precisa que dentro del grupo el marco continúa rodeando todo el contenido, mientras
el botón seleccionado recibe una superposición muy transparente. En Deshacer/Borrar se percibe;
en el botón principal interior apenas permite distinguir la selección. Su término «subfoco» describe
la apariencia observada, no una API ni una atribución técnica confirmada.

La prueba favorable del botón aislado del acceso temporal no resuelve este comportamiento. Se cambia
el siguiente paso: diagnosticar el indicador individual dentro del grupo antes de trasladar el margen
a los botones del sheet. No atribuirlo solo a contraste ni modificar la agrupación de accesibilidad
sin verificar el efecto sobre navegación y scroll.

La captura automática `group-subfocus-reported.png` recoge la pantalla de acceso tras cancelar,
sin indicador visible; no acredita el estado interior descrito. Se conserva el reporte manual y las
capturas anteriores del grupo. Sin nuevo cambio de código, build ni tests.

## Captura del indicador interior — 2026-09-12

Se recopilan doce PNG nativos con RocketSim durante navegación FKA manual en iPad Air11M4/iPadOS26.5 Dark, sin activar acciones. Archivos fuera de Git: `/Users/jesusf/Documents/Codex/2026-09-11/franalonso-08-4-keyboard/group-focus-sequence-00.png` a `-11.png`.
La toma04 muestra marco del ScrollView y rectángulo translúcido en Deshacer. La06 muestra el mismo marco exterior y selección de Confirmar. Comparación RGB con `group-before-keyboard-selection.png`: la región cambiada de Confirmar abarca x272–1367/y1523–1623; el relleno muestreado x600/y1570 sigue #E49ACE en ambos estados. La selección se confunde con su relleno. No se declara ratio normativo ni causa interna de iPadOS a partir de esta comparación.
La toma aislada `group-confirm-focused-20260912.png` no muestra indicadores; no sirve como evidencia de foco. La ocultación automática previamente observada puede explicar la pérdida, sin atribución confirmada.

Revisión diagnóstica read-only: no existe agrupación explícita en la View que retirar. Se preservan ScrollView, semántica, acciones y foco nativo. No se usan FocusState, APIs privadas ni preferencias forzadas. El siguiente ensayo limita el margen neutro al botón Confirmar dentro del sheet; el resultado del botón exterior no se extrapola como PASS.

## Piloto Confirmar con margen: descartado — 2026-09-12

Se ensaya únicamente Confirmar: label con mínimo44pt, margen exterior6pt sobre canvas y estilo plain. Conserva Button, acción, disabled, colores y ScrollView. Runtime confirma tamaño548×56pt, atenuación e inoperabilidad al pulsarlo vacío. RunProject PASS14,759s/PID78429; log `RunProject-Log-20260912-012313.txt`. Cuatro previews inspeccionadas en iPadPro13M5/iOS27: Empty Light/Large, Ink Dark/XXXLarge, Ink Light/AX5 High e Ink Dark/Large High; sin recorte del botón. No tests decorativos nuevos.

Gate PRE read-only independiente:463 archivos, digest idéntico e95596e21aef46a1b5cc8993f94a7c40040dfa1f9e54ebc2bc3b24598b9151f3. POST visual por agente nuevo y estándares/estilo por revisor PRE independiente del implementador (límite técnico al crear otro agente): sin hallazgos estáticos, digest463 idéntico 5083e5d5159bc4a5800e1cc76d36302b9aa9c0705f50838516fe2429e4ccf4ed. Estas revisiones no acreditan éxito del foco.

El propietario prueba la versión y responde «no, lo veo igual». Se descarta el piloto por falta de mejora perceptible; no se acredita Espacio a partir de esa respuesta ni se pide repetir otros recorridos. Se restaura exactamente el código anterior de Confirmar con primaryActionStyle; digest global previo a editar documentación vuelve a e95596e21aef46a1b5cc8993f94a7c40040dfa1f9e54ebc2bc3b24598b9151f3.
RunProject tras restauración PASS9,203s/PID80161, log `RunProject-Log-20260912-012628.txt`; ambos logs completos contienen solo aviso AppIntents conocido y ningún aviso Swift/Clang. El acceso temporal exterior conserva su ensayo anterior. P2 de foco interior sigue abierto: aumentar margen no queda recomendado como solución. Siguiente investigación: comparar el indicador de controles nativos dentro de scroll bajo los mismos ajustes FKA, antes de otra modificación de diseño.

## Ensayo de contorno accesible rectangular — 2026-09-12

Nuevo reporte: el propietario distingue las esquinas del resalte cuadrado sobre Deshacer/Borrar redondos,
pero en Confirmar percibe sobre todo las letras. El frame accesible previo ya abarca548×50,5pt.
Comparación de PNG anteriores: existen cambios en ambos bordes (59 píxeles en cada región de esquina
38×32), además del texto; no demuestra que el foco se limite al texto.

Ensayo autorizado de una línea en ClientSignatureCaptureScreen, después de primaryActionStyle:
`contentShape(.accessibility, .rect)`. Mantiene diseño, ancho, altura, hit-testing, acción y disabled.
[Apple](https://developer.apple.com/documentation/swiftui/contentshapekinds/accessibility) documenta
modificación de frame/path, indicador accesible y ordenación; no se considera exclusivamente visual.
No se reduce el ancho ni se recupera el margen descartado. FKA y orden VoiceOver requieren evidencia local.

PRE independiente read-only:463 archivos, digest idéntico
`0de8e0b521c372cdc3179e3af0cf7b64d6ec2e66e259fb952dd32c3764b195df`.
POST AX por agente nuevo y estándares/estilo por revisor PRE independiente del implementador
(reutilizado por límite de agentes): sin hallazgos del delta, 0 candidatos de estilo.
Digest463 POST idéntico verificado:
`d9e8f7acce64fdb7895a494131ca191a687cd8767f20211f875c712fa9f64096`.

RunProject Xcode oficial PASS11,431s/PID19402, Signature-Manual/iPadAir11M4/26.5.
Log completo `RunProject-Log-20260912-104101.txt`: solo aviso AppIntents conocido, sin Swift/Clang warnings.
Previews inspeccionadas Large Light, XXXLarge Dark, AX5 Light High en iPadPro13M5/iOS27; botón completo.
Runtime: un único Confirmar548×50,5pt; pulsarlo vacío no cambia estado/pantalla (hash cbcd545d).
No tests decorativos nuevos. Preparado trazo y solicitada comparación FKA de esquinas.
Pendientes: resultado visual Light/Dark, Espacio y recorrido VoiceOver local; no cierre de P2/08.4.

## Confirmación visual del contorno — 2026-09-12

El propietario confirma sobre el ensayo: «ahora se ve, es sutil pero al desbordar por las esquinas ya si se ve».
Se acredita mejora perceptible del indicador individual de Confirmar en la apariencia probada.
No se infiere validación de ambas apariencias, contraste normativo, Espacio ni orden VoiceOver de este reporte.
Se conserva la línea contentShape accessibility rect. Pendientes del delta: contraste/apariencia restante,
activación por Espacio y recorrido local VoiceOver entre controles vecinos. Sin nuevo cambio ejecutable;
build/tests N/A para registrar este resultado manual. 08.4 continúa abierta.

## Activación por teclado del contorno rectangular — 2026-09-12

El propietario confirma que, con Confirmar firma enfocado, Espacio confirma y vuelve correctamente
a la pantalla anterior en el ensayo con contentShape accessibility rect. PASS manual focal de activación
por teclado del control modificado; no implica haber comprobado el retorno del foco ni el orden VoiceOver.
Se conservan las pruebas anteriores. Pendientes: resalte en Light y recorrido VoiceOver local.
Sin nuevo cambio ejecutable; build/tests N/A para registrar evidencia manual. 08.4 abierta.

## Resalte en Light confirmado — 2026-09-12

El propietario confirma que el contorno rectangular se distingue en modo claro «mejor aún».
Con el reporte Dark previo y Espacio ya confirmado, queda acreditada la mejora perceptible en ambas
apariencias y la activación focal por teclado. No equivale a medición normativa de contraste ni cierre
completo de accesibilidad. Se mantiene pendiente únicamente el recorrido VoiceOver local para este delta.
Sin nuevo código; registro manual, build/tests N/A. 08.4 conserva los demás pendientes de su matriz.

## VoiceOver local del ajuste confirmado — 2026-09-12

El propietario confirma en iPhone14 físico/iOS26.6.1, versión ejecutada mediante RunProject
11,366s/PID16678, que VoiceOver recorre correctamente Área de firma → Deshacer → Borrar → Confirmar
y regreso, y anuncia «atenuado» en captura vacía. No reporta saltos ni duplicados.
PASS manual focal de orden y estado del control tras contentShape accessibility rect.
Junto a FKA Light/Dark y Espacio, quedan completadas las comprobaciones locales solicitadas para
este ajuste. Se conserva la solución; no requiere repetir los recorridos anteriores.
No equivale a medición normativa de contraste ni cierra los otros pendientes de 08.4.
Registro documental, sin nuevo código: build/tests N/A.


Preparación de VO físico: Xcode selecciona Signature-Manual/iPhone14 de Jesús/iOS26.6.1.
Compilación terminada correctamente; log completo GetBuildLog/9665B170-F5D9-44D0-B49C-5FAF5CF9463D.txt,
único aviso AppIntents conocido. RunProject aún espera el arranque; no se acredita instalación/ejecución
física ni prueba VoiceOver. Se solicita mantener el iPhone desbloqueado y conectado, sin atribuir
la espera a una causa no confirmada. iPad devuelto a apariencia Dark tras la comparación Light.

Actualización: el primer RunProject devuelve fallo de arranque tras build correcto (log
RunProject-Log-20260912-111936.txt), sin causa de lanzamiento confirmada. Reintento tras intervención
del propietario, con scheme/destino reconfirmados: arranque físico correcto en iPhone14/iOS26.6.1,
PASS11,366s/PID16678, sesión84d4d0000, log RunProject-Log-20260912-112209.txt.
Se solicita únicamente recorrido VoiceOver local Área de firma → Deshacer → Borrar → Confirmar
y regreso, sin duplicados ni saltos; con captura vacía, controles atenuados. Resultado aún pendiente.
