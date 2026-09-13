# Fase 08 — Clientes, consentimiento y foto

## Commit y push de08.5 autorizados — 2026-09-13

El propietario solicita commit y push y pregunta por el siguiente paso. Se prepara la publicación de la rama
`codex/plu-39-phase-08-5-signed-documents`, conservando validaciones y límites ya registrados.
No hay cambios ejecutables desde el build validado. La PR y el cierre no se interpretan como autorizados por la pregunta;
primero queda la revisión por agente nuevo, después revisión de PR, merge autorizado y cierre documental/operativo.
No se hace ninguna activación live ni se inicia08.6.

## Implementación08.5 autorizada y validación local — 2026-09-13

El propietario autoriza «adelante con la subfase 8.05» sobre la propuesta PRE favorable. Implementación en
`codex/plu-39-phase-08-5-signed-documents`, sin commit/push/PR ni cierre de issue autorizado para esta subfase.
PLU-38 conserva sus dos pendientes de evidencia; no se alteran ni repiten sus recorridos aceptados.

Domain incorpora contenido semántico resuelto, contexto/finalidad/decisión, snapshot inmutable, firma ligada al snapshot
y documento firmado con bytes definitivos. Invariantes se validan también al decodificar; una foto indecisa no puede
firmarse. Cambio de identidad, cliente, nombre, finalidad, decisión, versión, idioma, texto o variante rechaza tinta
anterior antes de llamar al render. Autorización posterior conserva finalidad independiente, sin modificar clientes.

Data resuelve idioma/versión explícitos del bundle y falla ante catálogo/idioma/clave ausente. Fuentes únicas trasladadas
a `FranAlonso/Resources/Legal`: String Catalog compilado para app y JSON estructural, consumidos también por el
generador de borradores. Sus claves/textos anteriores y estructura original conservados; ocho etiquetas documentales
nuevas y lista de idiomas soportados. Los cuatro PDF de Resources/DocumentTemplates permanecen byte a byte en HEAD.
No hay una copia editable en docs/legal; README/guía apuntan a la nueva fuente.

Actor CoreGraphics/CoreText genera A4, texto real, firma vectorial3:1 y páginas adicionales sin truncado, usando solo
snapshot/fecha/firma. No conoce catálogo vigente ni SDK en Domain. Errores y cancelación no emiten documento parcial.
Fecha e ID inyectables; los bytes generados se conservan en el valor Codable. El motor Quartz incorpora metadatos de
creación propios: no se promete determinismo binario entre renders/sistemas. La estabilidad histórica se consigue
reteniendo el artefacto, sin regenerarlo. El framing validado al decodificar no es validación criptográfica del PDF.

### Evidencia ejecutada

- Preparación: RED6/6 por `.unavailableCatalog` con adaptador aún sin implementar, resultado14:06:40;
  GREEN6/6 con catálogo real del bundle14:08:51.
- Render: RED6/6 por `.renderingFailed` con export aún sin implementar, resultado14:11:02;
  GREEN6/6 con PDF real14:13:10. Se comprueba rechazo de firma desactualizada y texto completo.
- Regresión14:16:27:43/43, cero fallidos/omitidos/no ejecutados:17 fronteras de documento,6 pipelinePDF,
  6 preparación,10 invariantes de tinta y4 recursos previos. Resultado nativo:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.09.13_14-16-27-+0200.xcresult`.
- Catálogo ampliado14:18:45:8/8, añade manifest ausente y localización incompleta con bundles aislados. No sumar
  esta repetición como ocho casos distintos de los seis anteriores.
- Build oficial Develop/iPadAir11M4/26.5 PASS12,132s, log `BuildProject-Log-20260913-141942.txt`.
  GetBuildLog sin incidencias estructuradas; log completo conserva solo aviso AppIntents conocido, sin Swift/Clang nuevos.
- Generador Python de producción carga las fuentes trasladadas; comparación con HEAD confirma textos/estructura
  originales sin alteración. No se regeneran ni modifican los PDF de borrador, ni se añade dependencia runtime.
- Revisión visual con skill PDF: ambos documentos iniciales y autorización posterior (dos páginas cada uno), y
  hoja de contacto completa del fixture de80 párrafos/12 páginas. Firma colocada bajo su etiqueta tras corregir
  separación excesiva del primer render; texto/tinta sin superposición ni recorte observado.

Artefactos sintéticos extraídos del xcresult en
`/Users/jesusf/Documents/Codex/2026-09-13/franalonso-08-5/`:
`informacion-firmada-sintetica.pdf`, `informacion-con-foto-firmada-sintetica.pdf`,
`autorizacion-posterior-sintetica.pdf` y `paginacion-unicode-sintetica.pdf`.
No contienen datos de clientes reales ni se incluyen en Git. Los PDF conservan la marca de borrador jurídico;
no están etiquetados para accesibilidad. Texto extraíble no acredita conformidad WCAG/PDF-UA.

### Límites y revisión final

Sin alcance SwiftUI: previews, Inspector y técnicas de asistencia N/A para08.5. La lectura nativa y su evidencia
corresponden a08.7; persistencia08.6, Store08.7, activación08.8 y foto real08.9 permanecen sin implementar.
No se añade composición App sin consumidor ni una pantalla temporal; se prueban las dependencias concretas inyectadas.
Gobernanza conserva solo seis enlaces históricos08.3 rotos; diff-check sin problemas. No activación live ni entrega Git nueva.

POST: intento de crear revisor nuevo devuelve `agent thread limit reached`. Se reutilizan dos agentes independientes
que nunca implementaron08.5: `proposal085_pre` para estándares/estilo y `delivery084_final_accessibility` para
recursos/localización/PDF. Ambos encuentran únicamente P3 en LOCALIZATION_GUIDE, cuyo párrafo aún describía la
distribución como futura. Corregido y releído por ambos: sin hallazgos técnicos pendientes.
Revisión de14 Swift, script de estilo0 candidatos y pasada manual favorable. PDF2/2/2/12 páginas, texto extraíble,
sin etiquetado estructural; N/A SwiftUI. No se declara revisión por agente nuevo ni cierre completo de la puerta.

Huellas operacionales de479 rutas tracked+untracked no ignoradas, ordenadas, path+NUL seguido de SHA256 de bytes
(literal MISSING para tracked eliminado), verificadas por el orquestador antes/después:
`60178dbff01d72de75cce0cf17e9a522fd603fcc5054e83830e7715ad7d68dcd` para POST completo y
`4ab4085e1214a1b3c020e112934ff90409bcef3784a7bd9d0ac85c12d3f1481b` para corrección documental.
Ningún cambio ejecutable posterior a build12,132s; retest N/A del último delta exclusivamente documental.
Pendientes de cierre: cumplir puerta de revisión por agente nuevo y obtener autorización de entrega Git.
No hace falta repetir pruebas físicas de firma ni modificar el alcance08.6–08.9.

## Integración de08.4 e inicio de preparación de08.5 — 2026-09-13

El propietario solicita expresamente merge e issue/rama para08.5. PR#11 pasa de borrador a lista y se integra
con merge commit `c4d7b00989a58783f953752bdc8f29dca90c6715`, verificado MERGED en GitHub.
Main actualizado por fast-forward; rama nueva `codex/plu-39-phase-08-5-signed-documents` creada desde ese commit.
Se conserva la rama08.4. Sin nuevos cambios ejecutables ni activación live.

Linear cerró automáticamente PLU-38 al integrar. Restaurada a In Progress: permanecen evidencia runtime de
resize durante gesto y medición/atribución del contraste nativo final. No se infiere DoD ni se repiten pruebas aceptadas.
PLU-39 ya existía; reutilizada y puesta In Progress para preparación. Su dependencia de entrega de38 está integrada;
se cambia a relación de seguimiento sin cerrar la evidencia. PLU-40–43 conservan Backlog y su secuencia.

[Propuesta08.5](08-5-signed-document-proposal.md): contenido versionado común y dos variantes, snapshot firmado y
render PDF con texto real fuera de MainActor. Sin persistencia, Store, UI de lectura/firma integrada ni foto real.
Baseline técnico anterior conservado, build/tests N/A para este cambio exclusivamente documental.
Las entradas de entrega draft inferiores son históricas y no describen el estado actual de GitHub.

PRE `proposal085_pre` por agente nuevo: sin hallazgos, PASS de preparación. Huella462 archivos pre/post idéntica
`e47ff50cfc5e3d3a0edd91597ca8458f37a62fb65389ca08d096a43106cb26a8`, verificada por el orquestador.
Diff-check limpio; gobernanza conserva solo los seis enlaces históricos08.3 rotos. Preparación documental local,
sin commit/push de08.5 ni implementación. La petición de issue/rama queda completada.

## Entrega parcial publicada — 2026-09-13

Commit funcional `7aab140` y push de `codex/plu-38-phase-08-4-signature-capture` completados.
[PR#11](https://github.com/JFrancoG/FranAlonso/pull/11) abierta como borrador contra main, verificada OPEN/draft.
GitHub devolvió errores internos en los primeros intentos; se verificó ausencia de PR entre reintentos y el POST final
respondió201 con PR#11. No se creó una PR duplicada. El readback no muestra checks remotos configurados; no es un PASS de CI.

PLU-38 actualizado con enlace, evidencia y los dos límites; readback confirma In Progress y attachment de PR#11.
No merge, cierre de issue, eliminación de rama, activación live ni inicio de08.5.
Este registro de entrega solo cambia documentación; build/tests N/A. Conserva los resultados técnicos y auditorías
anteriores, y los seis enlaces históricos08.3 rotos permanecen declarados. Los estados de preparación inferiores son históricos.

## Preparación de entrega draft — 2026-09-13

El propietario autoriza commit, push y PR. Se prepara PR borrador porque quedan evidencia de resize durante gesto activo
y medición/atribución del contraste nativo final; sin merge, cierre de PLU-38, activación live ni código de08.5.
La matriz se consolida con los reportes ya aceptados; no se repiten pruebas ni se transforman limitaciones en PASS.

Limpieza con PRE independiente `delivery084_cleanup_pre` PASS: App.swift restaurada byte a byte frente a HEAD,
retirados los dos Swift temporales, solo sus dos claves de catálogo y el esquema local ignorado Signature-Manual.
Xcode confirma únicamente Develop/Production; Develop queda seleccionado en iPadAir11M4/26.5.
Se conserva el fixture de previews de firma, independiente del acceso temporal eliminado.
Huella PRE/triage read-only463 archivos estable: `b8620ab5514a2d6b0da26e1a898b3048fa8ff0ccd3263f5105436f645d086ba4`.

Primer build falla por lista de entradas aún referida a los archivos eliminados. XcodeLS confirma después su ausencia;
repetición oficial PASS14,159s. Log `BuildProject-Log-20260913-111436.txt`, único warning AppIntents previo.
Tres tests existentes de composición ejecutados:3/3, cero fallidos/omitidos/no ejecutados:
`developFixtureLaunchArgumentsAreDisabledByDefault`, `sharedFixtureSeamsRemainInsideCompilationGuard` y
`signedOutFixtureTraversesFullAuthenticationChain`.
Resultado nativo: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.09.13_11-14-46-+0200.xcresult`.
La regresión histórica26/26 se conserva, sin presentarla como ejecución nueva. No hay nuevos tests de lógica para una
restauración exacta; las previews anteriores se conservan porque no cambió la UI de captura desde el delta de voz validado.

Gobernanza: Progress vuelve a cumplir presupuesto8192 bytes. Persisten exclusivamente los seis enlaces históricos rotos
 de08.3; no se incluyen cambios ajenos para ocultarlos. Diff check limpio. POST finales favorables para draft; publicación autorizada pendiente de completar.
Esta cabecera sustituye estados de entrega/acceso temporal de entradas históricas inferiores.

POST finales por agentes nuevos `delivery084_final_standards` y `delivery084_final_accessibility`: sin hallazgos nuevos,
PASS para commit/push/PR borrador, no DoD ni merge. Revisadas7 Swift, catálogo y alcance de planificación;
revisor UI inspecciona cuatro previews existentes (Large Light, XXXDark, AX5LightHigh y AX5RTL) sin repetir render.
55/55 criterios,35 aplicables y20 N/A, con excepciones y límites explícitos.
Huella read-only461 archivos pre/post idéntica verificada por el orquestador:
`81843677dceba2c254b9e2719b52eb1c49f293ee5aaae6a3457474a4666019a8`.
Inspección de28 archivos previstos sin patrones de claves privadas/API/JWT ni credenciales en query; JSON válidos.
Sin cambios de negocio ni nuevos builds tras registrar estos dictámenes.

## iPad: contraste incrementado comprobado en claro/oscuro — 2026-09-13

El propietario confirma texto, firma, borde y botones distinguibles en ambas apariencias con Aumentar contraste.
Se completa ese muestreo visual; no acredita medición de ratios. Restan resize durante gesto activo, reconciliación
de evidencia técnica y cierre de 08.4. Se indica restaurar preferencias anteriores sin afirmar que ya se ha realizado.
Detalle en matriz08.4; build/tests N/A documental.

## iPad: Reducir movimiento confirmado — 2026-09-13

El propietario confirma funcionamiento correcto al abrir captura, dibujar y confirmar con Reducir movimiento activado.
Se resuelve ese muestreo; se conserva evidencia previa y quedan contraste, resize durante gesto y cierre técnico/documental.
Se indicó restaurar la preferencia previa, sin confirmación todavía. Registro manual; build/tests N/A.

## iPad: adaptación de ventana confirmada — 2026-09-13

El propietario confirma conservación de dos trazos terminados al reducir/ampliar la ventana y acceso a Deshacer,
Borrar y Confirmar en tamaño mínimo. Se resuelve ese recorrido, sin inferir resize durante gesto activo.
Restan ese caso de interrupción, preferencias de accesibilidad y cierre técnico/documental; no repetir ventana mínima.
Reporte manual sin nueva identificación de modelo/OS/binario; detalle en matriz08.4. Build/tests N/A documental.

## VoiceOver: estados vacío y listo confirmados — 2026-09-13

El propietario confirma «Todavía no hay firma» al enfocar el área vacía y «Firma lista para confirmar» después
de dibujar. Misma sesión iPhone14 físico/iOS26.7 y binario RunProject001300. Se resuelve el pendiente de valor
del lienzo; no se repiten estas pruebas ni las de anuncios ya confirmadas. Quedan las comprobaciones de ventana
y preferencias de iPad y el cierre técnico/documental de 08.4. Build/tests N/A, registro manual.

## VoiceOver: resultados de edición confirmados — 2026-09-13

Retest del propietario sobre el binario nuevo: Deshacer y Borrar anuncian los resultados previstos.
Se conserva el ajuste de prioridad y se resuelve el P2 de silencio en el recorrido probado. No se infiere de la respuesta
permanencia del foco ni ausencia de duplicados. La audibilidad deja de ser pendiente; el valor del lienzo y el resto
de comprobaciones de 08.4 se conservan. Las anotaciones siguientes describen el diagnóstico previo.

El propietario precisa que Deshacer/Borrar ejecutan la acción sin anunciar resultado. P2 abierto en 4.1.3.
Piloto mínimo revisado independientemente: prioridad alta solo en esos dos anuncios, conservando foco/diseño/textos
y prioridad de los demás. Causa no demostrada; requiere retest audible. Xcode identifica iPhone14 físico/iOS26.7.
Build PASS, solo warning AppIntents conocido; POST accesibilidad/estándares favorables con huella estable.
RunProject confirma lanzamiento en el iPhone14 tras desbloquearlo: PASS11,023s, PID1157.
Binario nuevo preparado; falta comprobar audibilidad con el propietario.
Detalle, fuente y huella PRE en la [matriz 08.4](../accessibility/evidence/08-4-signature-capture.md).

## Cancelación por Control por voz confirmada — 2026-09-13

El propietario confirma «Tocar cancelar firma»: vuelve a la pantalla principal y aparece «Captura cancelada».
También confirma locución correcta de los botones Deshacer trazo y Borrar firma con VoiceOver; no se infieren
anuncios de resultado ni valor del lienzo. Cancelar por voz deja de ser pendiente; las menciones inferiores son históricas.
Detalle y límites en la [matriz 08.4](../accessibility/evidence/08-4-signature-capture.md).
Registro documental, build/tests N/A; sin cierre de subfase ni entrega Git.

## Contorno accesible rectangular: comprobaciones locales completadas — 2026-09-12

Estado final del ajuste: resalte perceptible en Dark/Light, Espacio confirma y vuelve, y VoiceOver
recorre correctamente los controles vecinos en iPhone14 físico/iOS26.6.1, anunciando atenuado cuando
están vacíos. Se conserva la solución. Esta conclusión sustituye los pendientes locales históricos
enumerados debajo; no cierra las restantes comprobaciones de 08.4 ni la medición de contraste.

Light confirmado posteriormente: el propietario percibe el resalte mejor aún que en Dark.
Mejora visible en ambas apariencias y activación por teclado acreditadas; pendiente VO local del delta.

Activación posterior acreditada: el propietario confirma que Espacio ejecuta Confirmar y vuelve
a la pantalla anterior. No se infiere retorno del foco. Pendientes Light y orden VoiceOver local.

Resultado manual posterior: el propietario confirma que ahora identifica el foco por las esquinas
que sobresalen, aunque sigue sutil. Se conserva el cambio. No se infieren ambas apariencias ni
activación/orden VoiceOver; esas comprobaciones locales siguen pendientes.

Nuevo dato del propietario sobre esquinas visibles en iconos y resalte aparente del texto de Confirmar.
Se ensaya una línea contentShape accessibility rect sobre el botón completo sin alterar ancho/diseño.
Xcode RunProject PASS11,431s, tres previews y revisiones read-only sin hallazgos del delta.
El árbol conserva un único Confirmar548×50,5pt; pulsación vacía inoperable. Pendientes FKA Light/Dark,
Espacio y orden VoiceOver local. Detalle en [propuesta](08-4-keyboard-focus-proposal.md); 08.4 abierta.

## Piloto del foco interior descartado — 2026-09-12

Capturado el indicador individual FKA de Deshacer y Confirmar dentro del grupo. Ensayo local
de margen6pt solo en Confirmar compilado, cuatro previews y revisión independiente sin hallazgos
estáticos. El propietario indica que lo ve igual: no resuelve el objetivo y se retira.
Código anterior restaurado exactamente y ejecutado en iPadAir11M4/26.5, PASS9,203s con único aviso
AppIntents previo. No se acredita Espacio del piloto ni cierre de foco/08.4. No se repiten las
pruebas funcionales anteriores. Detalle y digests en [propuesta](08-4-keyboard-focus-proposal.md).

## Resalte individual dentro del grupo — 2026-09-11

El propietario distingue marco persistente del grupo y resalte transparente muy sutil del control
seleccionado, especialmente en el botón principal interior. La prueba del botón aislado no valida
ese comportamiento. Se prioriza diagnosticar el indicador individual antes de trasladar el margen
al sheet. Sin código ni pruebas nuevas; detalle en matriz08.4.

## Prueba de separación del foco favorable — 2026-09-11

Prototipo limitado a Capturar firma del acceso temporal, margen6pt y colores existentes. Propietario
distingue aire en Light y Dark (menos evidente en Dark) y confirma activación por Espacio. Xcode MCP
RunProject PASS9,561s, único aviso AppIntents previo. Tres previews hasta AX5 sin recorte y dos nuevas
auditorías read-only favorables con digest463 estable. Apariencia restaurada Dark. Detalle en
[propuesta](08-4-keyboard-focus-proposal.md) y matriz08.4. Pendiente traslado al sheet; no se cierra
el hallazgo global ni08.4. No nuevos tests decorativos, commit ni entrega.

## Estudio del foco de teclado — 2026-09-11

Estudio autorizado completado: [propuesta](08-4-keyboard-focus-proposal.md), fuentes Apple, medición orientativa
y revisión independiente read-only con digest462 estable. No se encontró un canal público documentado para
cambiar únicamente el halo FKA de Button SwiftUI. Recomendado prototipo local de separación neutra y
alternativa de decoración separada de tint, sin asumir comportamiento hasta probarlo. Sin código ni
preferencias modificadas. P2 visual continúa abierto; build/tests N/A documental.

## Teclado: recorrido funcional completado y foco por revisar — 2026-09-11

El propietario confirma con teclado del Mac y Acceso total con teclado en iPadAir11M4/26.5 la selección
y operación de abrir, Deshacer, Borrar, Cancelar y Confirmar, y volver a seleccionar Capturar firma.
Trazos preparados con el ratón. Tab cambia de grupo; flecha abajo entra en el contenido. El foco rosa
se confunde con el borde/relleno de los botones y al principio impidió reconocer que había entrado.
PASS funcional focal; visibilidad del foco pendiente de diagnóstico, sin declarar PASS de contraste.
Detalle en matriz08.4. Build/tests N/A documental; 08.4 sigue abierta y el acceso temporal se conserva.

## Control por botón completado — 2026-09-11

El propietario confirma en iPhone 14 físico/iOS 26.6.1 el recorrido con botón de pantalla completa y
exploración automática: Deshacer elimina solo el último de dos trazos; Borrar elimina el restante;
Cancelar cierra; Capturar firma vuelve a abrir; Confirmar cierra y muestra firma recibida. Tinta preparada
con la ayuda desactivada. PASS manual focal de selección y operación, sin acreditar dibujo con Control
por botón ni foco exacto de retorno. Próxima prueba acordada: teclado del Mac en simulador iPad.
Detalle en matriz08.4. Build/tests N/A documental; se conserva el acceso temporal y 08.4 sigue abierta.

## Inspector manual recibido y clasificado — 2026-09-11

El propietario ejecuta Run Audit y aporta cuatro capturas: resumen de tres avisos y elementos afectados. Contraste1,68
corresponde a Confirmar deshabilitado (exento1.4.3); las dos advertencias de Dynamic Type afectan a instrucciones y
Confirmar, cuyo escalado AX5 ya está acreditado y no tienen fuente fija. Sin defectos nuevos confirmados ni cambios
necesarios de código. Revisión independiente focal favorable con digest462 pre/post verificado; detalle, imágenes y
fuente W3C en matriz08.4. Resuelta la falta de informe para el estado vacío auditado; no acredita todas las técnicas.
Build/tests N/A documental. 08.4 conserva los demás pendientes y el acceso temporal, sin entrega Git.

## Validación de cierre retomada — 2026-09-11

Control por voz confirmado por el propietario en iPhone14/iOS26.6.1 para Deshacer, Borrar y Confirmar. Bloqueo durante
el segundo trazo conserva el primero terminado y descarta el que estaba en curso. Dos revisiones independientes
read-only sin defectos nuevos; propuesta de retirar harness aprobada por estándares cuando terminen las pruebas.
Huella de462 archivos pre/post idéntica y verificada: `8107f53d2a29f9d8251706991d64ed383f6e637fe3a54720824ffbb03d5ab7c6`.
Matriz consolidada para eliminar pendientes ya resueltos, conservando histórico y excepciones ADR26/27.
Último RunProject iPadAir11M4/26.5, 02:43:29 PASS20,171s, único aviso previoAppIntents; relanzado por diagnóstico de
interacción. VoiceOver: propietario confirma error y trazo terminado tras corregir. Rotación iPad conserva tinta
terminada. Inspector no entrega informe y scroll/teclado no verificables; ajustes temporales restaurados.
AX5 comprobado desde Ajustes nativos: scroll muestra todos los controles y Confirmar cierra. Reducción de transparencia
comprobada en Dark/Large; ajustes restaurados. Artefactos en matriz.
Pendientes tras esta sesión histórica (Inspector resuelto en la entrada posterior de cabecera): valores/anuncios de edición, Cancelar por voz, Switch Control/teclado, resize durante
gesto/ventana mínima, Reduce Motion y limpieza.
08.4 sigue abierta y sin entrega Git. No se inicia08.5.

## Dispositivo VoiceOver confirmado — 2026-09-11

El propietario identifica iPhone14 físico/iOS26.6.1 para su reporte posterior al cambio de botones. PASS manual focal
para nombres, anuncio atenuado, acciones y retorno del foco. Resuelve identificación de dispositivo; no acredita una
instalación física por el agente ni las restantes técnicas de la matriz. Evidencia/Progress actualizados, sin código,
build ni tests nuevos. 08.4 sigue abierta.

## Reporte VoiceOver posterior a los iconos — 2026-09-11

El propietario confirma nombres iguales a los anteriores, anuncio «atenuado» al deshabilitar, acciones correctas y
retorno del foco al origen. Falta identificar dispositivo y confirmar la nueva fila de iconos; el último Run del agente
actualizó el iPad, no el iPhone14. Se conserva el reporte sin atribuirlo a un binario por inferencia. Detalle en matriz;
sin código ni ejecución adicional. 08.4 sigue abierta y los restantes pendientes no quedan cubiertos por este reporte.

## Botones mostrados y distribución aprobada — 2026-09-11

Conexión Xcode restablecida. RunProject Signature-Manual/iPadAir11M4/26.5 PASS12,791s (02:20:42, PID84938), con aviso
AppIntents previo en log completo y sin otros warnings/errores encontrados. Usuario ve el resultado y confirma
«ha quedado bien». Cinco previews MCP inspeccionadas en iPadPro13M5/iOS27; límites AX5/RTL y estado inactivo en matriz.
RocketSim verifica nombres, frames de iconos44×44 y Confirmar548×50,5pt; trazo/deshacer y trazo/borrar vuelven a vacío.
Revisión focal visual independiente favorable, huella462pre/post idéntica verificada:
`20fc242a16fc0de3e30ba34f6ed31b80c5d4bc7ec4007a0f6e3ef4dae2da7bc3`.
Artefactos y log conservados en Documents/Codex/2026-09-11/franalonso-08-4-buttons, enlazados desde matriz08.4.
Restaurada selección inicial iPhone14 de Jesús; app iPad abierta en captura vacía para el propietario. Sin ejecución
física nueva ni retirada de acceso temporal. La reconexión deja de ser bloqueo; Inspector/AT y cierre08.4 pendientes.

## Botones de firma: cambio aplicado, validación Xcode pendiente — 2026-09-11

El propietario autoriza implementar la fila de iconos Deshacer/Borrar bajo Canvas y Confirmar con altura natural.
Solo cambia ClientSignatureCaptureScreen; se mantienen lógica, nombres accesibles, rol, estados y anuncios.
Revisión previa por agente nuevo PASS y posterior estática/estilo por otro agente nuevo sin hallazgos. Huellas
pre/post verificadas de462 archivos: `77915993aafda695f758e1b89a6d97e4e463ba396eaf0d6e3ddafdf46b71fcb7` y
`bd6bed08494954bbc3fc03455a67cede01d9ccb8838b1fc249dc64879dd04693`. Detalle en la matriz08.4.
Build/previews/runtime pendientes: XcodeListWindows devuelve Transport closed; Xcode abierto y MCP habilitado no
acreditan conexión operativa. Usuario avisado para reconectar; no se lanza un binario antiguo como resultado nuevo.
Sin tests nuevos por cambio de layout sin lógica, diff-check limpio. 08.4 permanece abierta, sin entrega ni08.5.

## Interrupción y propuesta visual de acciones — 2026-09-11

El propietario confirma en iPhone 14 físico conservación de dos trazos terminados al ir a Inicio y volver, y Deshacer
solo el último. PASS manual limitado a ese recorrido; gesto en curso, redimensionado y terminación de proceso no se
infieren. Evidencia detallada en la matriz de 08.4; build/tests N/A documental.
Propone Deshacer/Borrar como iconos en una fila bajo el lienzo y Confirmar separado con menos altura. Revisión de la
View muestra tres acciones apiladas y un mínimo de 44 pt en el contenido de Confirmar más el estilo nativo large.
Propuesta pendiente de implementación: acciones secundarias con nombres accesibles y superficies mínimas de 44×44 pt,
Confirmar con altura natural adaptable. No cambia la lógica de captura ni se inicia 08.5; 08.4 permanece abierta.

## VoiceOver: controles deshabilitados con firma vacía — 2026-09-11

El propietario confirma en iPhone 14 físico que Deshacer trazo, Borrar firma y Confirmar firma se anuncian como
«atenuado botón» al abrir la captura sin dibujar. PASS manual limitado a esos anuncios de rol/estado; no extrapola
activación posterior, errores ni otras técnicas. Matriz y Progress actualizados; sin código ni nuevas ejecuciones.
08.4 / PLU-38 sigue In Progress; build/tests N/A para registrar el resultado aportado.

## VoiceOver: confirmación y retorno de foco — 2026-09-11

Pruebas retomadas tras el ajuste documental. El propietario confirma en iPhone 14 físico: «Confirmar firma botón y
acaba en el botón Capturar firma botón». PASS manual acotado al anuncio, activación y foco de retorno del montaje
temporal tras preparar un trazo sin VoiceOver. No acredita dibujo con VoiceOver, errores ni otros pendientes de la
matriz. Evidencia detallada en 08-4-signature-capture.md; código sin cambios y build/tests N/A para esta anotación.
08.4 / PLU-38 continúa In Progress, sin cierre ni retirada del acceso temporal.

## Plan aprobado y situación de 08.4 — 2026-09-11

El propietario aprueba la recomendación de revisión: continuar en esta tarea, registrar ADR 0028 y ajustar specs y
Linear antes de retomar validación. [ADR 0028](../ADRs/0028-client-signed-information-and-photo-authorization.md)
precisa parcialmente ADR 0009 sin reescribirlo: información inicial firmada como regla de producto, contenido común
versionado, autorización de fotografía opcional y proceso posterior independiente de la activación inicial.
Specs 04/05/08 y guía de localización alineadas; contratos ejecutables, esquemas y recursos conservados.

08.4 / PLU-38 sigue In Progress en `codex/plu-38-phase-08-4-signature-capture`. Mantiene sus 26/26 resultados previos,
R01/R02 finales y VoiceOver básico de iPhone 14 físico. Falta completar la evidencia aplicable indicada en su matriz,
revisor UI final nuevo y retirada del montaje temporal con validación Xcode MCP de la composición final. La revisión
documental de este plan no sustituye esa revisión UI. No esperar a implementar 08.9 para cerrar el componente.
No se reanuda ni ejecuta ahora la app; la siguiente validación será el pendiente del componente, con iPhone 14 o iPad.

Plan operativo creado en Backlog bajo PLU-34; dependencia de entrega encadenada desde PLU-38:

| Subfase | Issue | Alcance de implementación |
|---|---|---|
| 08.5 | [PLU-39](https://linear.app/plusprojects/issue/PLU-39) | Contenido/variantes, contrato versionado y render. |
| 08.6 | [PLU-40](https://linear.app/plusprojects/issue/PLU-40) | Persistencia recuperable, migración y Storage idempotente. |
| 08.7 | [PLU-41](https://linear.app/plusprojects/issue/PLU-41) | Lectura accesible, revisión y firma; contexto de foto mediante fixtures. |
| 08.8 | [PLU-42](https://linear.app/plusprojects/issue/PLU-42) | Activación inicial tras upload. |
| 08.9 | [PLU-43](https://linear.app/plusprojects/issue/PLU-43) | Selector/foto real inicial y posterior, retirada y detalle. |

La dependencia no es circular: 08.5 define el contexto fotográfico, 08.7 consume ambas variantes con fixtures y
08.9 completa su integración real. Es planificación aprobada, no inicio de nuevas subfases. La spec 08 conserva el
plan normativo; esta tabla solo vincula trabajo operativo. Obsidian usa estos mismos archivos del repositorio.
Revisión jurídica de los borradores y verificación de proveedores/transferencias/conservación siguen pendientes antes
del uso real. Build/tests N/A por cambio exclusivamente documental; sin cierre, entrega Git ni activación live.

Validación del ajuste documental: revisor de estándares nuevo e independiente PASS sin hallazgos, limitado a los
12 Markdown del turno; no sustituye revisión UI ni gate previo del código futuro. Huella de 462 archivos pre/post
idéntica, también verificada por el orquestador: `0968f7b62d75d85592214153830db381d41601f60273455f6fd744670d016aae`.
Diff-check limpio; gobernanza conserva solo los seis enlaces históricos rotos de 08.3. Readback de Linear confirma
PLU-38 In Progress y PLU-39–PLU-43 Backlog, sus padres y dependencias; Obsidian confirma el Progress actualizado.
Esta anotación de evidencia se añade después de cerrar la revisión; el resto del contenido revisado se conserva.

Las anotaciones siguientes son históricas; los pendientes de acuerdo de diseño de septiembre 10 quedan sustituidos
por este plan, conservando su evidencia y los pendientes de validación/implementación.

## Borrador adicional sin imágenes — 2026-09-10

El propietario autoriza generar, entregar y añadir a Resources un borrador simple sin referencias a imágenes.
Se añade client-data-information-template.pdf; se conservan los tres PDF anteriores byte a byte. Reutiliza estructura,
estilos y textos comunes; ocho claves específicas y lista vacía de autorizaciones. El generador omite ese apartado
cuando no hay opciones. Nombre, fecha y firma dejan constancia de recepción; marca jurídica y nota editorial pendientes
conservadas. Sin Swift, cambios de activación o integración del recurso en DocumentTemplateResource.

Copia: `/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/consent-draft/informacion-datos-personales-borrador-2026-09-10.pdf`.
SHA-256: `ed788c875ec7af7c49e92440524bea4f91dfdec3dea01afe70c002a42e7eba17`.
Una página A4, sin AcroForm, 19 claves de contenido verificadas y ninguna referencia a foto/imagen/casilla/autorizo.
Render completo inspeccionado; consentimiento con foto, ticket y factura mantienen bytes y evidencia visual anteriores.
Dos regeneraciones idénticas de los cuatro PDF en CPython 3.12.14/zlib 1.2.12 y requirements fijados.
Copia entregable y recurso incluido en el bundle de la app idénticos al original generado.

Revisión previa independiente PASS; digest de 460 archivos pre/post idéntico:
`ab2c6d9084113fafc047db4bb96eec95b5c57b6e54c4b513df929994734bc3e4`.
Xcode MCP Signature-Manual/iPad Air 11-inch (M4)/26.5: DocumentTemplateResourceTests 4/4 a las 23:48:24,
resumen `046E34A7-FC40-430A-BFFC-F21E60D29689.txt`. Solo regresión de los tres recursos anteriores; no cubre el nuevo.
Build 23:49:10 PASS en 9,991 s; log `BuildProject-Log-20260910-234910.txt` acredita copia del recurso, sin errores
 y con el aviso AppIntents previo. Destino inicial iPhone14 de Jesús restaurado, sin Run/Stop físico.
Revisión final focal por agente nuevo PASS, sin hallazgos; 461 archivos pre/post idénticos:
`d179735b0ecadf5cde186fec14e5aee500c7f5758df9445010bb978739079be9`.
El PDF no tiene etiquetado accesible: la revisión visual no acredita lectura VoiceOver del futuro flujo.
Diff-check PASS; gobernanza conserva únicamente los seis enlaces históricos rotos de 08.3.
Las pruebas manuales del flujo continúan pausadas.

El propietario indica expresamente revisar ADR, Obsidian/vault, Linear e historia de usuario antes de planear e
implementar el flujo en su momento. Queda como siguiente paso de planificación; no se modifica ahora un ADR ni se
crea una nueva fase/issue de implementación. Progress y Linear conservan la evidencia y el pendiente; sin entrega Git.

## Sustitución autorizada del PDF de consentimiento — 2026-09-10

El propietario pide una copia del borrador ajustado y sustituir el recurso. Actualizados catálogo/estructura y
client-consent-template.pdf, versión específica2026-09-10-draft. Una opción de foto, emailticket/factura solicitado,
nombre/fecha/firma sin DNI sistemático. Marca jurídica y nota editorial sobre transferencias conservadas.
Generador acotado a versión propia de consentimiento, dos columnas de identificación y cuerpo8,4pt.
No cambia código Swift, activación ni pantalla. PDF nuevo de una página A4, texto extraíble sin AcroForm.
Copia idéntica: `/Users/jesusf/Documents/Codex/2026-09-10/franalonso-08-4/consent-draft/consentimiento-datos-fotografia-borrador-2026-09-10.pdf`.

Propuesta independiente read-only PASS, huella460archivos pre/post idéntica:
`ebb29363057d606d376c0a10c01051262966112e0628cf721deb326a04643a75`.
Regenerado con CPython3.12.14/zlib1.2.12 y requirements fijados en venvexterno; dos pasadas binarias idénticas.
Ticket y factura reproducen y conservan los originales. Tres renders inspeccionados; consentimiento sin recortes,
texto y firma completos; no se alteran layouts previos de facturación. Extracción verifica las20claves de contenido
referenciadas, ausencia de opciones comerciales y DNI/NIE, versión y marca jurídica.
SHA256consentimiento: `5895c606ab265b062081c5ac3d9fa2a73aabe3e8bc3bb42917475da8749b5106`.

Xcode MCP en esquema localSignature-Manual/iPadAir11M4/26.5: DocumentTemplateResourceTests4/4, sin fallidos/omitidos.
Resumen `ABC7DE53-9D2A-43B3-A066-7956E9F09652.txt`, RunSomeTests22:44:36. Build22:45:31 PASS6,033s.
Log completo `BuildProject-Log-20260910-224531.txt`: sin errores y con el aviso AppIntents previo.
Destino inicial iPhone14 de Jesús restaurado tras validación; no Run/Stop ni instalación en el teléfono.
Son comprobaciones de recurso, no reanudación de pruebas manuales. Revisión final focal por agente nuevo PASS,
sin hallazgos; digest pre/post idéntico de 460 archivos:
`4220d8236d06427a0a7db2e1ceb781082937651d88571cab2353559b4e51b7c9`.
Diff-check PASS; gobernanza solo falla por los seis enlaces históricos08.3 ya registrados.
Sin commit/push, cierre08.4 ni inicio08.5.

## Finalidades reales y optimización del texto — 2026-09-10

El propietario confirma ausencia de marketing: ficha, foto interna opcional y envío de ticket/factura por email
solo a quien lo solicita. Preparada propuesta08.4-consent-text con una única autorización opcional, información
sobre tratamiento necesario, constancia de recepción y versionado del documento. Consultadas fuentes oficiales
AEPD/RGPD; no se presenta el borrador como jurídicamente validado. Datos de proveedores/transferencias y conservación
siguen pendientes de ajuste real. Señalada la revisión del requisito de firma para activar de ADR0009 como decisión
operativa, sin alterar el ADR ni la máquina de estados. Solo documentación; pruebas pausadas y build/tests N/A.

## Lectura del borrador de consentimiento existente — 2026-09-10

El propietario localiza el borrador en Resources/DocumentTemplates. Se inspecciona íntegramente
client-consent-template.pdf (A4, una página, texto extraíble, sin campos AcroForm), incluido render visual.
El texto y estructura ya se generan desde docs/legal/DocumentTemplates.xcstrings y document-template-content.json.
Se identifica recepción de información y tres opciones independientes: foto interna, comunicaciones electrónicas,
comunicaciones por teléfono/correo postal. No contempla publicación de imágenes; rechazar opciones no impide servicio
según el propio borrador. Mantiene marca y versión de borrador pendiente de revisión jurídica.
Hallazgos y orientación UX incorporados a propuesta08.4; fuente de texto ya localizada, finalidades por confirmar.
Sin cambios del PDF, textos legales, código o configuración; no se reanudan pruebas. Build/tests N/A documental.

## Replanteamiento del consentimiento y pausa de pruebas — 2026-09-10

El propietario confirma el recorrido VoiceOver solicitado (título, instrucciones, botones, cancelar y volver a
Capturar firma) y precisa que lo realiza en iPhone 14 físico. Se corrige la atribución de esta comprobación al iPad;
no se deduce un cambio de dispositivo para los recorridos anteriores ni una nueva ejecución MCP en el teléfono.
No consta versión del sistema físico. Evidencia comunicada por propietario, sin audio ni Inspector.

El propietario pide detener las pruebas de la pantalla aislada hasta definir cómo leer y firmar el consentimiento
para uso de datos e imágenes y cómo conservarlo. Describe la app vigente: imagen del texto y firma compuestas en
una imagen que se guarda en Firebase Storage; es contexto del producto, no decisión técnica para la app nueva.
Pruebas pausadas por instrucción explícita; sin más cambios ejecutables, relanzamientos ni retirada del acceso temporal.

La spec08 y ADR0009 ya distribuyen captura/renderizado/Storage/orquestación/activación entre 08.4–08.8 y fijan
borrador local recuperable antes de activar tras upload. Falta acordar lectura, opciones de aceptación, versión de
contenido, vínculo con firma y artefacto conservado. La captura actual queda como componente validado, no como
flujo de consentimiento validado. Orientación de diseño en propuesta08.4, pendiente de texto real y aprobación.
No se cierran ADR0022/08.4/PLU-38 ni se inicia08.5. Actualización documental: build/tests N/A.



## Confirmación funcional de la versión final 08.4 — 2026-09-10

El propietario comunica: «Muy bien, he probado todo lo anterior y funciona bien». Confirma la regresión de R01/R02
tras retirar el modo por puntos, en la sesión preparada de iPad Air 11-inch (M4)/26.5: dibujar, deshacer el último
trazo, confirmar con recepción sin guardado, borrar con confirmación deshabilitada y cancelar con cierre.
Ambos recorridos PASS manual en la versión final. Esta confirmación sustituye su pendiente funcional anterior;
no acredita técnicas de asistencia ni interrupción/redimensionado, que no formaban parte de esos recorridos.
Acceso temporal conservado para las comprobaciones restantes. Solo evidencia/documentación: build/tests N/A;
se conservan 26/26 y build MCP ya ejecutados, sin cambios de código, esquema ni proceso. PLU-38 sigue In Progress.

## Estado vigente 08.4 — retirada del modo por puntos — 2026-09-10

El propietario rechaza el modo por coordenadas y autoriza retirarlo. ADR 0027 documenta la excepción puntual de
entrada manuscrita frente a ADR 0022; no presupone accesibilidad universal, identidad, poderes ni validez jurídica.
Se elimina ClientSignaturePointControls, Toggle/cursor/estado y acciones exclusivos, doce textos y dos tests de ese
modo. Instrucciones actualizadas y preview Narrow RTL usa tinta manuscrita. Domain y contratos terminales intactos.

Propuestas independientes de estándares y accesibilidad PASS antes del código; digest pre/post idéntico de 459 archivos:
`f1bae91a9ff2eb5ea0d1a298e0ca2c499610e535d06ea459f1f95fc4d5209e7d`.
No se fabrica un RED para comprobar ausencia de código; se conserva la regresión de los contratos vigentes.
Xcode MCP, Develop/iPad Air 11-inch (M4)/26.5: 26/26 resultados, 0 fallidos/omitidos/no ejecutados; cuatro suites
completas, incluidos los cinco argumentos de coordenadas inválidas. Resumen:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/9702A6D0-6A29-410C-A2EA-A4F188187DEE.txt`.
Estilo: cinco Swift modificados, cero candidatos y revisión manual local e independiente PASS.
Build final MCP 18:27:12 PASS, 12,878 s, sin errores y aviso previo AppIntents. Cuatro previews iPad efectivas
iOS 27 inspeccionadas: Light/Large, Dark/AX5, Light High/XXX Large y Dark High/350 pt RTL; detalle en matriz.
Auditoría final de estándares/estilo PASS. Reauditoría accesible estática/visual PASS, sin hallazgos, por revisor
independiente reutilizado: el límite de agentes impidió crear uno nuevo y esa puerta operativa queda pendiente.
Huella pre/post idéntica de 459 archivos: `37ba75728f6819b3f59f96cb119042b8308788ffbdcc599226b06fba37c56228`.
R01/R02 se conservan como historia de la versión anterior, pendientes de regresión con el propietario en el binario actualizado.
RunProject 18:31 compiló pero falló al lanzar; PID informado después no estaba vivo. Reintento MCP 18:34:53 PASS
en 4,760 s, PID 78962 vivo y único argumento `--franalonso-auth-fixture-signed-out` comprobado.
Destino iPad Air 11-inch (M4)/26.5 y esquema local FranAlonso-Signature-Manual. Acceso temporal se mantendrá hasta terminar las pruebas.
Para limpiarlo, usar Localizable.xcstrings.freehand.before fuera de Git: el backup antiguo reintroduciría el modo.

Las secciones siguientes conservan el historial y sus resultados con su versión; este apartado fija el alcance vigente.

## Implementación inicial 08.4 — evidencia manual pendiente — 2026-09-10

El propietario solicita abrir issue/rama e implementar 8.04. Creada [PLU-38](https://linear.app/plusprojects/issue/PLU-38)
en In Progress, hija de PLU-34, y rama `codex/plu-38-phase-08-4-signature-capture` desde `9ffce6a`.
`git fetch` y comparación `main...origin/main` 0/0; árbol inicial limpio. Xcode MCP identifica este checkout en
`windowtab-jyb1Pv0A7J`: Develop, iPad Air 11-inch (M4)/26.5, SDK Simulator iOS27, Swift6, target26.

Propuesta exacta, alternativas, fuentes y exclusiones: [captura08.4](08-4-signature-proposal.md).
Dos revisiones independientes previas PASS (`review_084_proposal`, `review_084_ui_proposal`), estrictamente read-only.
Huella pre/post idéntica de 448 archivos tracked y untracked no ignorados:
`42e35bb814c491c3a321ec56eb9373f22ce75a6f15232cfef6ef1971aa42b20d`.
La autorización de implementación del propietario cubre esta subfase; no se requiere repetirla.

Captura independiente: firma vectorial inmutable, coordenadas normalizadas y validación al construir/decodificar;
ViewModel posee el buffer, cancelación, deshacer/borrar y callback terminal único. La pantalla se conecta al consumidor
durable en una subfase posterior: el formulario actual solo guarda ClientProfile y destruye su sesión al finalizar.
No se añade firma efímera a Guardar cliente ni se implementa PDF, Storage, Store, activación o gate live.

TDD con Swift Testing y Xcode MCP:
- Primer intento no ejecutó tests por import CoreGraphics ausente en el nuevo test; corregido antes del RED válido.
- RED válido: 18 resultados, 17 fallos esperados y 1 negativo que ya pasaba con el stub vacío. Resumen
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/224DA948-1DED-4A81-BB33-023988510EF6.txt`.
- GREEN inicial: 14 resultados correctos, resumen
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/F0AE9D92-A984-46D5-BEAB-9F4EFF3D5C71.txt`.
  Inspección del console log acredita solo -inf de los cinco valores Double. Se sustituyen los argumentos de test por
  cadenas identificables que se convierten a los mismos valores antes de llamar a producción; sin rebajar aserciones.
  Ese GREEN parcial no acredita los cinco casos; la pasada final por suites descrita abajo sí los ejecuta.
- Log completo de baseline y del GREEN conserva Metadata extraction skipped / AppIntents ya existente. No se afirma
  cero warnings globales ni se altera configuración para ocultarlo.

Evidencia de pantalla: [matriz08.4](../accessibility/evidence/08-4-signature-capture.md), con 55 criterios clasificados.
Validación final: selección por suites completas en Xcode MCP15:01:29, 28/28 resultados de cuatro suites,
con los cinco argumentos de coordenadas acreditados en el console log. Resumen:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/D7EDFC55-162D-44A8-8A88-72C573F258DD.txt`.
La ejecución por método conservaba una selección de casos obsoleta: el primer reintento con cadenas ejecutó cero
casos de coordenadas aunque el resumen era verde. El reintento por suite resolvió esta limitación; no se cuenta como
cobertura la ejecución vacía. Domain aislado también pasó10/10, incluidas las cinco cadenas.

Build MCP15:03:15 PASS12,016s; log `BuildProject-Log-20260910-150315.txt`. Cero errores y sin diagnósticos Swift
nuevos; log completo conserva aviso AppIntents previo. Sin afirmación de cero warnings globales ni Production.
Previews finales Large/XXX Large/AX5, cuatro apariencias, iPhone/iPad y350pt RTL inspeccionadas. Corregidos título
AX5 truncado y contraste de Borrar firma oscuro3,642:1 mediante superficie opaca; detalle y ratios en matriz.
Scheme sin modificaciones, destino restaurado a iPadAir11M4/26.5. No harness ni cambios de configuración.
Auditorías finales independientes read-only completadas. Estándares iOS y estilo PASS, sin hallazgos: ocho Swift,
script con cero candidatos y pasada manual. Accesibilidad revisó tres Views, 28 claves, seis imágenes finales y los
55 criterios; único P2 documental corregido: 1.3.4 conserva `A/No pasa — excepción de producto aceptada` de ADR 0026.
Reauditoría documental focal PASS, sin nuevos hallazgos. Huella pre/post de ambos revisores idéntica, 457 archivos tracked y untracked
no ignorados: `54c54ae6f89d36473c243cfdb316bf6f4109937ac4972b16d78d8ee8a397e881`.
Huella pre/post focal también idéntica, 457 archivos:
`facbcf8656ade9a6147bd02db44f4da1df54cce1a94df974e2851834f79e0716`.
Última corrección exclusivamente documental: build/tests N/A; conserva la validación ejecutada sobre el código final.
Gobernanza y diff-check PASS. Runtime/AT permanece pendiente hasta evidencia real; PLU-38 conserva In Progress.
Sin commit, push, PR, merge, cierre de PLU-38 ni avance a08.5.

### R02 manual confirmado — 2026-09-10

Propietario confirma borrar dos trazos (lienzo vacío y confirmación deshabilitada) y cancelar después de volver
a dibujar (cierre y mensaje de cancelación sin guardado), en la sesión iPad Air 11-inch (M4)/26.5. R02 PASS.
No equivale a interrupción del gesto, redimensionado ni técnicas de asistencia. Modo por puntos pendiente;
acceso temporal activo. Evidencia documental, build/tests N/A.

### R01 manual confirmado — 2026-09-10

Propietario confirma el recorrido completo en iPad Air 11-inch (M4)/26.5: dos trazos, deshacer solo el último y
confirmar, cierre de captura y mensaje de firma recibida sin guardar. R01 PASS; no se infiere persistencia ni AT.
Borrar, cancelar, modo por puntos y las técnicas de asistencia siguen pendientes. Acceso temporal activo hasta
terminar las pruebas. Detalle en matriz08.4; actualización documental, build/tests N/A.

### Estado manual vigente — 2026-09-10 18:04

Sesión retomada tras retirada prematura del acceso. Usuario indica usar iPad o su iPhone 14, no iPhone 17.
RunProject MCP en iPad Air 11-inch (M4)/26.5 PASS, 37,653 s; PID 69739 vivo con único argumento signed-out verificado.
Acceso temporal idéntico al ya auditado y esquema local FranAlonso-Signature-Manual permanecen activos hasta que
el propietario termine; retirada pendiente, excluidos de entrega. El scheme canónico sigue intacto. Resultado manual
aún pendiente. Detalle y log en matriz08.4. Esta nota sustituye el estado operativo de la sesión anterior.

### Acceso manual preparado — 2026-09-10 17:46

RunProject MCP PASS en iPhone 17/iOS 27 con argumento signed-out comprobado en PID 61417. Acceso temporal revisado
antes y después, ya retirado; App, catálogo y scheme canónico restaurados byte a byte. Develop/iPad Air 11-inch (M4)/26.5
restaurado y proceso de prueba aún vivo. Solo se añaden anotaciones documentales; código final08.4 sin modificaciones.
Gesto y resultados del propietario pendientes. Detalle de intentos, limitaciones, logs y huellas en la
[sesión manual](../accessibility/evidence/08-4-signature-capture.md#sesión-manual-preparada--2026-09-10-1746).


Comprobación documental posterior: `git diff --check` PASS. El validador global de gobernanza falla por seis enlaces
a capturas de 08.3 del Escritorio que ya no existen (13:40:20–13:41:57), fuera del cambio 08.4. No se alteran esos
archivos ni se presenta el resultado global como PASS; no impide realizar esta sesión manual.

## Cierre vigente de08.3 — 2026-09-10

PR#10 integrada en main: merge1377cc446eb0cdb377c1f360bff011ce008ac414. Incluye08.1/08.2,
base08.3 y correcciones hasta c743e7a. PLU-37 Done. Rama08.3 eliminada local/remota.
GitHub MERGEABLE/CLEAN antes del merge, sin checks remotos configurados; validación local y
revisiones registradas más abajo. Gobernanza y diff-check PASS. Fase08 abierta;08.4 no iniciada.
Este cierre sustituye los pendientes de publicación y cierre de las entradas históricas siguientes.
No cambia el alcance de las evidencias ni la excepción ADR0026. Registro documental, build/tests N/A.

## Estado vigente reconciliado — 2026-09-10

Este resumen sustituye los pendientes históricos de las sesiones fechadas inferiores. Detalle por
criterio y técnica en [evidencia08.3](../accessibility/evidence/08-3-client-screens.md).

- Base08.3 publicada5533948 y documentación4527b03; HEAD/remoto4527b03 verificados. La nueva
  confirmación, ClientFormScreen, estilo de Reintentar en ClientFormContent y documentación siguen
  incluidas en el commit de correcciones autorizado el2026-09-10. La publicación previa no incluía estas correcciones.
- R09 lectura/reintento/campos/Cancelar→fila confirmado por propietario; fallo de guardado ya validado.
  Harness retirados, AppDependencies+ClientForm.swift restaurado byteexactoHEAD. Build125405 PASS8,46s,
  RunProject125546 PASS8,152s, Develop/iPhone14/26.6.1 mediante MCP27. Aviso previo AppIntents persiste.
- Nueva sheet validada por propietario en apariencia habitual y VoiceOver: lectura, Cancelar/retorno,
  confirmación con anuncio final completo. Locución parcial transitoria no bloqueante, sin causa atribuida.
  Reintentar con cápsula visible y preview12:55:29 inspeccionada.
- Comprobación acotada completada: seis capturas del propietario de las13:40–13:41 muestran listado,
  formulario y nueva sheet en iPad/ventana estrecha con texto ampliado. La secuencia13:41:46→13:41:57
  acredita que al desplazar ambos botones aparecen completos. El propietario confirma apariencia correcta.
  No se infiere pulsación ni locución de las capturas; Cancelar/VoiceOver ya tienen evidencia anterior.
  Sin nuevas pruebas manuales pendientes en el muestreo acordado; ADR0026 sigue como excepción aceptada.
- Correcciones publicadas en69acaa4. Posteriormente el propietario autoriza publicar también
  plist/pbxproj para dejar el árbol limpio; scheme ya coincide con Git. Revisión estática independiente
  PASS, build MCP141420 PASS4,129s y valores efectivos del plist generado verificados.
  PR/merge/cierre/activaciónlive/08.4 siguen fuera de esta entrega.
- Reauditorías documentales focales de estándares iOS y accesibilidad PASS, sin hallazgos abiertos
  en esta reconciliación. Gobernanza y diff-check PASS; build/tests N/A por cambio documental.
- Se reclasifican34 enlaces a artefactos eliminados como rutas históricas no disponibles, conservando
  su identidad y resultado comunicado. No se recrea evidencia ni se exige repetir pruebas por perder
  un archivo temporal. Se retiran de la matriz los pendientes ya resueltos, sin declarar cobertura global.

Las secciones siguientes son el registro cronológico: las limitaciones se leen con su fecha y no
sustituyen este estado vigente ni las tablas R/ADR reconciliadas.

## Inicio — 2026-09-08

- El propietario autoriza comenzar fase 08, abrir issue/rama e implementar 8.01, equivalente a 08.1 de la spec.
- Padre [PLU-34](https://linear.app/plusprojects/issue/PLU-34) y ejecución
  [PLU-35](https://linear.app/plusprojects/issue/PLU-35), ambos `In Progress`.
- Rama `codex/plu-35-phase-08-1-client-crud-search`, desde `main` limpio en `c24f6e5`.
- PLU-25 conserva su cierre administrativo independiente pendiente; sus entregables están integrados.
- Xcode MCP conecta `windowtab1` al checkout correcto. Esquema activo `FranAlonso-Develop`; lista de 636
  declaraciones habilitadas. Último build consultado correcto y sin entradas en el resumen MCP; no es una ejecución nueva.
- Target iOS 26.0, Swift 6, aislamiento por defecto `nonisolated`, concurrencia estricta completa y warnings como
  errores. El log inspeccionado usa el SDK iPhoneSimulator26.5. No se modifica configuración.

## Propuesta 08.1

Autoridad: spec 08, constitución y ADR 0002, 0006, 0009, 0011, 0012 y 0018. Perfil de mantenimiento del proyecto.

1. Completar `ClientRepository` con lectura por ID, creación, edición y desactivación semánticas. Mantener las
   operaciones existentes para sus consumidores. Los nuevos casos de uso exponen esas intenciones sin SwiftData.
2. Un valor Domain de campos editables valida nombre no vacío tras trim y contiene nombre, identificador fiscal y
   dirección opcionales. Crear recibe identidad estable y fuerza `draft`; una identidad ya existente se rechaza.
   No se impone unicidad de nombre o identificador fiscal. Editar recibe ID y nuevos campos; Data recupera el perfil en su contexto y preserva identidad, estado y
   consentimiento. No promete CAS ni exclusión entre los contextos de las rutas actor y contextual.
3. `ClientLocalDataSource` acepta los comandos sin suspensiones entre lectura/comprobación/escritura y reutiliza
   `persistPendingUpsert`/`persistPendingDelete`. Actor y adaptador contextual comparten esta primitiva. No se introduce
   un ciclo read/modify/write con varios awaits desde Domain ni se duplica la cola local-first.
4. Desactivar excluye el cliente de lecturas operativas y crea el tombstone causal existente. Se conserva el
   `ClientModel` como último perfil histórico local, incluido consentimiento, en aceptación, ack, pull y conflicto.
   Las consultas excluyen los IDs presentes en pending delete o tombstone remoto. No hay cuarto `ClientStatus`.
   El formato remoto sigue sin PII/payload de negocio y no cambia ninguna forma SwiftData publicada.
5. La retención es local: un dispositivo que solo recibe el tombstone no obtiene un perfil histórico que nunca tuvo.
   No se promete archivo remoto ni recuperación de datos ya eliminados. Esos flujos necesitan otra decisión.
6. Búsqueda pura sobre snapshots locales visibles, por nombre o identificador fiscal, con comparación de usuario
   insensible a mayúsculas/diacríticos. Query vacía tras trim devuelve la colección y se conserva el orden de entrada.
   Las altas y los borradores pendientes permanecen visibles para gestión; esto no habilita su uso comercial.
7. Errores de alta duplicada, no encontrado, conflicto, desactivado y fallo local salen por el
   contrato Domain. Cancelación antes de aceptar la escritura no produce efectos; no se inventa un fallo tras commit.
   La observación publica solo tras aceptación durable y sigue leyendo exclusivamente SwiftData.

### Áreas afectadas y alternativas

- `Clients/Domain`: valor de edición, errores y casos de uso CRUD/búsqueda; contrato Repository.
- `Clients/Data`: Repository real/en memoria/fixture, actor, adaptador contextual y primitiva local.
- Tests Clients y conformidades de sus dobles; documentación y changelog.
- Se rechazan upsert indiferenciado como CRUD (puede crear al editar), búsqueda remota (rompe offline), nuevo status
  `inactive` (contradice spec), borrado físico del último perfil (pierde consentimiento) y tabla/flag de archivo nuevos
  (duplican metadata ya persistida y exigirían migración sin necesidad).
- No se introduce ADR nuevo: se concreta la retención local exigida por 08.1 conservando el protocolo remoto y las
  decisiones de identidad, conflicto y esquema. La revisión previa debe comprobar expresamente este encaje.

### TDD y validación prevista

- RED/GREEN: crear draft, rechazo duplicado, edición que conserva consentimiento, no encontrado, búsqueda vacía/nombre/fiscal/
  diacríticos/sin resultados, desactivación idempotente y errores/cancelación sin escritura.
- Integración con SwiftData in-memory: observación CRUD, cola atómica y paridad contextual; consentimiento retenido
  tras delete/ack/pull/conflicto, exclusión operativa y reapertura. Regresión de sync, no resurrección y tombstone sin PII.
- Xcode MCP para tests focales y regresión afectada, build y log; sin `xcodebuild`. No se declara nueva evidencia hasta
  ejecutarla. Auditoría final iOS y estilo Swift; UI/accesibilidad `N/A` porque no se toca Presentation ni recursos.
- Fuentes primarias consultadas: [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor) para
  confinamiento y acceso excluyente; [búsqueda de texto de usuario](https://developer.apple.com/documentation/foundation/nsstring/localizedstandardcontains(_:)).

### Exclusiones

08.2–08.9, ViewModels/formulario/UI de búsqueda, firma, PDF, Storage, upload, activación, foto, histórico remoto,
restauración y resolución de conflictos, motores live, dependencias, targets y migraciones. Commit/push/PR/merge,
cierre Linear y siguiente subfase no están autorizados.

## Evidencia de implementación

- Revisión previa independiente: P2 sobre CAS corregido. Huella operacional pre/post inicial: 418 archivos,
  `40be4b6d196c4018172e787976b4109eeddd6a259644d1872c41048610e109f8`. Reauditoría focal PASS sin hallazgos y
  pre/post idéntico: `ac5f84e4710d4db154856c7a6c53d32bcc1760efff3ff52270737a5492f25f2e` (418 archivos).
- `ClientProfile` valida nombre al construir/decodificar. CRUD expone errores Domain; toda identidad ya utilizada,
  incluso desactivada, rechaza una nueva alta con `alreadyExists`. El antiguo upsert conserva sus consumidores.
- La aceptación Data es síncrona dentro de cada contexto: perfil y cola comparten save/rollback. No se añade CAS
  entre contextos ni se activa sincronización. Repository y adaptador contextual publican después del commit.
- `ClientModel` retiene el último perfil local en las cuatro rutas de tombstone. Las lecturas consultan los marcadores
  ya existentes y excluyen el histórico. Payload remoto, forma SwiftData y metadata causal permanecen intactos.
- Se amplían dos contenedores mínimos de tests para incluir los marcadores que ahora requiere la lectura operativa;
  no cambian modelos ni esquema de producto. Los dobles de observación solo incorporan conformidades al contrato.

### TDD y regresión Xcode MCP

- RED de retención: 0/5, por ausencia del perfil en delete local, ack, pull, conflicto y reapertura file-backed.
  Informe `A2FD0D3D-DAA9-4017-9245-CA9110B18DFE.txt`.
- RED CRUD: símbolos/métodos ausentes (`ClientProfile`, `ClientError`, CRUD de Repository/adaptador y búsqueda).
  Logs `210A6744-466D-43CE-A890-BC7077573618.txt` y `9726726A-DC38-4D03-BAFB-4DF4DAD95517.txt`.
  El segundo reveló además un warning de Swift Testing por duplicar el display name de nombres escapados; se retiró
  solo el atributo redundante antes del GREEN.
- Primer focal: 46/48. Se corrigió el error de alta sobre identidad desactivada a `alreadyExists`. Un conteo del
  contexto tras rollback devolvió una fila mientras el contexto nuevo estaba vacío; se añadieron fetch real y lookup
  del producto en ese mismo contexto. Ambos devuelven vacío/nil y también pasa el conteo posterior. No se atribuye
  una causa no demostrada ni se cambia `includePendingChanges`. Focal correctivo: 2/2.
- La selección por método de Xcode llegó a ejecutar solo el primer argumento de algunos tests parametrizados.
  La validación definitiva usa suites completas: retención 5/5 y regresión de **22 suites / 168 resultados**, todos
  pasados, sin fallos, omitidos o no ejecutados. Incluye CRUD/búsqueda, persistencia, conflictos, cursor, retry,
  sincronización, DTO/Firestore sin red, observación y composición de Clientes.
- Informe definitivo: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/08333A6D-A925-40FA-B540-944A21D01F65.txt`.
  Consola: `test-console-log-2026-09-08T13-01-12+02-00.txt`, en la misma carpeta.
  Destino de esta ejecución: iPhone 11 físico con iOS 27.0; build con SDK iPhoneOS26.5.
- Se habilitó temporalmente signed-out en el archivo del scheme, que se restauró byte a byte con cinco argumentos
  `NO` y diff vacío. Rectificación al validar 08.3: no quedó acreditada su activación efectiva en el host de este run
  de 08.1; los tests construyen sus propias composiciones aisladas. Véase la nota de fixture de 08.3.
- Build final `FranAlonso-Develop`: correcto en 3,580 s, log `BuildProject-Log-20260908-130205.txt` bajo
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/`.
  `GetBuildLog` MCP filtrado por warning devuelve cero entradas (`FBFEDC4C-3FFF-4385-96CA-DEDFA0D5E4AB.txt`)
  y Navigator cero issues. El log completo sí registra en la línea 10729 el aviso de tooling
  `Metadata extraction skipped. No AppIntents.framework dependency found.`, ya documentado en fase 07.
  No se declara cero warnings globales ni se atribuye el aviso a caché. Diagnósticos focales de `ClientProfile`,
  `ClientRepository`, `ClientLocalDataSource` y adaptador contextual: cero issues.
- No se repite la suite global ni se ejecuta una nueva pasada Production. La evidencia corresponde al esquema Develop
  conectado y al alcance afectado; no se presenta como ReleaseGate ni validación live.
- Revisión de estilo sobre 23 Swift nuevos/modificados: once ajustes de formato aplicados antes de la regresión final.
  Gobernanza y `git diff --check` pasan.
- SwiftUI, previews, localización y ADR 0022: `N/A` razonado. No cambia ninguna View, ViewModel, recurso ni semántica
  accesible; las pantallas existentes mantienen su observación local.

### Auditoría final independiente

- `ios-standards-reviewer` revisa los 23 Swift, límites Domain/Data, cuatro rutas de retención, tests, estilo,
  artefactos y paridad con Linear. Sin hallazgos P0–P3 de implementación o estilo.
- Único P2 documental: la afirmación de log sin warnings no reflejaba el aviso de extracción AppIntents.
  Corregida la distinción entre log completo y diagnósticos MCP/Navigator en este registro, Progress y Linear.
  Reauditoría focal PASS: P2 cerrado, sin nuevos hallazgos; no cambia código/configuración ni se repiten tests.
- Fallback operacional read-only, sin aislamiento técnico: el orquestador acredita 429 archivos con huellas
  pre/post idénticas `61ddaebd086818daa9729a62ce10ed188707d967a75ee995c60686f0a2cbbe46`.
- El auditor verifica los 168 resultados de 22 suites, build correcto y scheme idéntico a HEAD con cinco `NO`.
  La duración, Navigator y cuatro diagnósticos MCP constan por ejecución del orquestador; no se presentan como
  observación directa del auditor.
- Reauditoría focal también read-only: 429 archivos, huellas pre/post idénticas acreditadas por el orquestador
  `f6f57246335d5bf757487e8d56def18e040616201ceb3a81e1dd04c92868aa3b`.
  Gate final PASS, sin hallazgos abiertos. El registro posterior del veredicto no altera el código validado.

## Entrega parcial de 08.1 — 2026-09-08

- El propietario autoriza commit/push de 08.1 e inicio de 08.2. Commit
  [`1164c62`](https://github.com/JFrancoG/FranAlonso/commit/1164c626d8a0276682d9060e95cb0a0757c3cf91):
  `✨ feat(clients): add client CRUD and local search`, 26 rutas explícitas, sin configuración ni credenciales.
- Push a `origin/codex/plu-35-phase-08-1-client-crud-search` verificado por SHA remoto idéntico.
  Árbol e índice limpios antes de abrir la nueva rama. Se conserva la validación y auditoría del código de 08.1;
  solo cambiaron el registro de autorización y el título de changelog después de esas puertas.
- PLU-34/PLU-35 continúan `In Progress`; no se ha creado PR, integrado en main ni cerrado issues.

## Inicio de 08.2 — propuesta

- Inicio autorizado como 8.02; [PLU-36](https://linear.app/plusprojects/issue/PLU-36) en `In Progress`.
- Rama local `codex/plu-36-phase-08-2-client-view-models` creada sobre `1164c62`. Depende de 08.1 aún no integrada
  en main; una futura entrega debe conservar esa dependencia, sin mezclar ambas subfases en un diff contra main.
- `windowtab1` sigue conectado a este checkout. Target 26.0, Swift 6, `nonisolated`, concurrencia `complete`,
  warnings Swift/Clang como errores, sin cambios. Baseline heredado: Develop/iPhone 11 físico iOS 27.0,
  SDK iPhoneOS26.5, 168/168 de 22 suites y build correcto. La consulta MCP actual devuelve cero entradas de warning
  (`GetBuildLog/27F56422-7261-497B-8CB7-9932BDB02C91.txt`) y Navigator cero issues; el log completo conserva AppIntents.
  No se han ejecutado nuevos tests/builds: todavía no hay cambios ejecutables de 08.2.
- Autoridad: constitución, spec 08, ADR 0002/0006/0009/0011/0022, política Swift y navegación acordada.

### Comportamiento propuesto

1. Ampliar `ClientListViewModel`, manteniendo su `@Observable @MainActor` y los casos existentes de `State` para
   preservar la pantalla actual. Conservar un único snapshot fuente; derivar los resultados de `SearchClientsUseCase`
   y la query vigente sin guardar una segunda colección filtrada. Distinguir fuente vacía de búsqueda sin coincidencias.
   Cada nuevo snapshot se filtra con la query actual. Error/reintento/cancelación siguen siendo intenciones del ViewModel.
2. Navegación local con destino tipado alta/edición, identificable por una sesión estable. La intención de alta genera
   el ClientID una sola vez mediante generador inyectable; editar referencia el ID del cliente visible. El destino no
   transporta modelos SwiftData ni conserva un segundo estado de formulario. Cierre y resultado de guardado son
   intenciones semánticas; el cierre de una sesión antigua no afecta a otra posterior. Presentar la sheet es 08.3.
3. Añadir `ClientFormViewModel` `@Observable @MainActor`, con modo/ID de sesión inmutables, campos editables y estado
   finito de carga, edición, guardado, resultado o fallo. Crear comienza vacío; editar carga por `GetClientUseCase`.
   Un fallo de lectura no permite guardar valores vacíos como edición; el reintento es explícito. Se conservan campos
   ante fallo de escritura y cancelación. No se persiste cada pulsación ni se activa el cliente.
4. Preparar los campos mediante un `PrepareClientProfileUseCase` puro que convierte el borrador de formulario a
   `ClientProfile`: trim de campos, fiscal vacío a nil y dirección completamente vacía a nil; una dirección parcial
   se conserva sin inventar campos obligatorios. `ClientProfile` sigue garantizando nombre no vacío. Esta conversión
   de opcionales representa una política real de entrada y satisface el valor validado previo exigido por ADR 0011;
   no se duplica la validación ni se añade un UseCase que solo reenvía argumentos. Sin validación de DNI/NIF, unicidad
   de nombre ni requisito de dirección no presentes en Domain.
5. Guardar alta/edición y desactivar un cliente existente mediante closures de operación `@MainActor` con entradas
   Domain validadas y `ModelContext` efímero. La confirmación visual de desactivación pertenece a 08.3; el ViewModel
   recibe la intención ya confirmada. No almacena el contexto, no hace CRUD/mapping/save, ni llama también a los
   UseCases mutadores context-free. Data reutiliza exclusivamente `ClientContextualPersistenceAdapter` de 08.1.
6. La composición concreta se prepara en una factory de App para el formulario, que recibe destino y los roles
   `ClientPersistenceActor`/`ClientObservationSignal` ya propiedad del runtime. Compone Get con un Repository sobre
   esos roles y las closures con un adaptador contextual que comparte la señal. No crea otro contenedor, actor
   persistente o canal de observación. El wiring visual y la adaptación de `AppPreviewModifier` quedan en 08.3;
   no se presenta el repository in-memory one-shot de previews como CRUD reactivo.
7. Cargas/observaciones async propiedad del caller, sin `Task.detached` ni tareas que capturen ModelContext.
   Tokens de generación impiden que una operación reemplazada cambie el estado actual; la cancelación del caller
   sigue siendo cooperativa. El guardado bloquea envíos simultáneos, captura el borrador aceptado y conserva la
   identidad al reintentar. Cancelar antes de delegar no escribe; una respuesta durable de éxito sigue siendo éxito
   aunque el caller se cancele después. Cerrar no promete deshacer una escritura ya aceptada y un resultado tardío
   no reabre una sesión cerrada. La exclusión local del ViewModel no promete CAS entre contextos.
8. Errores semánticos finitos para validación/carga/guardado, sin textos visibles, PII ni mensajes de SDK.
   La View de 08.3 resolverá el copy desde `.xcstrings`. No se añade `ClientConsentStore` antes de 08.7.

### Ámbito y alternativas

- Cambios previstos: `Clients/Presentation/ViewModels/ClientListViewModel.swift`, nuevo `ClientFormViewModel`,
  destino tipado y valor de campos solo si simplifican el estado; `Clients/Domain/UseCases/PrepareClientProfileUseCase`;
  factory concreta bajo `App`; suites de ViewModels, preparación de campos y composición contextual; Progress/changelog.
- Se reutiliza el contrato de estados del listado, evitando modificar Views solo para preparar el estado futuro.
- Se descartan router global/NavigationPath, Store de formulario sin responsabilidad adicional, búsqueda remota o
  debounce artificial para una búsqueda local síncrona, duplicar escrituras por Repository y closure, y retener
  ModelContext en tareas/estado. No se necesita ADR, dependencia, opt-out ni migración nuevos.
- 08.3–08.9 quedan fuera: Views, bindings/sheet, recursos/localización, firma/PDF/Storage, ConsentStore, activación,
  foto/detalle, resolución de conflictos, restauración, motores live, targets y configuración.
- UI/previews/ADR 0022 son `N/A` en esta propuesta porque no cambia ninguna superficie ni semántica accesible actual;
  la integración visual de 08.3 debe completar esa evidencia antes de su cierre.

### TDD, fuentes y revisión

- RED/GREEN con Swift Testing: filtro sobre query/snapshot cambiantes; sin coincidencias frente fuente vacía;
  observación antigua/cancelada que no pisa la actual; identidad estable de alta y selección por ID; cierre de sesión
  obsoleta; carga de edición/missing/error/reintento; inválido sin escritura; normalización de opcionales;
  guardado concurrente rechazado; fallo conservando campos; cancelación previa y éxito durable tras cancelación;
  desactivación idempotente y resultado que no reabre formulario cerrado.
- Composición con SwiftData in-memory: el formulario escribe una sola operación y la observación del mismo contenedor
  publica el resultado; editar conserva consentimiento/estado y desactivar excluye el histórico. Dobles controlables,
  sin sleeps ni repetir tests de asignación. Una prueba de cancelación no debe esperar cooperación del doble si el
  caso quiere demostrar protección ante una respuesta obsoleta.
- Validación prevista por Xcode MCP: suites completas afectadas para cubrir todos los parámetros, build/diagnósticos
  y auditoría final iOS/estilo. No se declara nuevo ReleaseGate, Production o runtime visual por el baseline heredado.
- Fuentes Apple consultadas por Cupertino: [Observation](https://developer.apple.com/documentation/observation/observable())
  y [Task/cancelación cooperativa](https://developer.apple.com/documentation/swift/task#Task-Cancellation).
  Los tokens de generación son una decisión del proyecto para controlar resultados obsoletos; no una garantía implícita
  de MainActor ni un mecanismo de rollback.
- Revisión previa independiente PASS, sin hallazgos P0–P3: confirma alcance, normalización Domain, composición
  contextual, alternativas, cancelación y plan TDD. No sustituye la aprobación del propietario del alcance presentado.
- Revisor nuevo en sesión efímera con sandbox read-only impuesto, tras alcanzar el límite de hilos de collaboration.
  Aplica `franalonso-review-ios-standards`; sin ediciones, mutaciones Git, publicaciones, builds ni tests.
  Huellas pre/post verificadas por el orquestador: 429 archivos,
  `0babb2baf739aa8b5ed7746a4487d3bbcc19a03869ea1951d848c850cd2ccbe6`.
  Informe local: `/tmp/franalonso-082-proposal-review-result.md`; eventos:
  `/tmp/franalonso-082-proposal-review-events.jsonl`.
- El revisor verifica Git local y las fronteras fuente, y contrasta fuentes Apple oficiales por web porque Cupertino
  no recibió aprobación en su sandbox. Xcode MCP, remoto vivo y Linear están verificados por el orquestador, no por
  ejecución directa del revisor. El propietario aprueba después esta propuesta; la implementación se registra debajo.

## Implementación de 08.2 — 2026-09-08

- El propietario autoriza la propuesta exacta. Se mantiene `codex/plu-36-phase-08-2-client-view-models` y PLU-36
  `In Progress`; no se autoriza entrega ni 08.3.
- Se conserva la pantalla existente y su `State`; query y resultados se derivan de su único snapshot.
  Los destinos distinguen sesión de formulario y ClientID. Formulario, campos, preparación Domain y factory App
  incorporan exclusivamente los límites revisados, con contextos efímeros y señal de observación compartida.
- RED inicial por Xcode MCP: `PrepareClientProfileUseCase` no encontrado en las tres declaraciones de su suite.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/GetBuildLog/91D8D40B-0F38-49BB-A696-F188A0EC7598.txt`.
- Primer build de implementación no resuelve `ClientFormDestination` recién creado. El navigator ya lista los cinco
  archivos nuevos; se reescriben con los mismos bytes mediante `XcodeWrite` y el build posterior pasa en 10,874 s,
  sin cambios en project.pbxproj. No se atribuye una causa de indexación no demostrada.
- Primer GREEN: 5 suites completas / 41 resultados, todos pasados. Incluye las cuatro suites nuevas y los seis casos
  anteriores de `ClientListViewModelTests`. Informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/2846C8CE-A83E-41DB-9076-F71E41A08F36.txt`.
  Se amplía después la verificación de cancelación de lectura vigente y preservación de dirección/fiscal al editar.
- Argumento signed-out temporal en el archivo del scheme, con copia de bytes originales en
  `/tmp/franalonso-082-develop-scheme.original`. Restaurada byte a byte contra HEAD antes del build final;
  cinco argumentos `NO`, diff vacío y SHA256 `102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`.
  Rectificación al validar 08.3: la activación efectiva de esa fixture en el host de 08.2 no quedó acreditada;
  los tests construyen composiciones aisladas. Véase la nota de fixture de 08.3.
- Revisión independiente de estilo: 10 Swift inventariados, 28 ubicaciones de tests corregidas; reauditoría de los
  dos archivos afectados sin hallazgos, script 2 archivos/0 candidatos. Los ocho restantes no cambiaron después
  de su revisión. Sin normalización histórica.
- El fake de observación se amplía para suspender tanto al obtener el stream como dentro de `next()` mediante
  [AsyncThrowingStream(unfolding:)](https://developer.apple.com/documentation/swift/asyncthrowingstream/init(unfolding:)).
  Se prueban valor/error/fin/cancelación en ambas fronteras, sin sleeps ni polling. Focal final: **46/46**.
- Regresión definitiva por Xcode MCP: **26 suites completas / 208 resultados**, todos pasados; cero fallos,
  omitidos o no ejecutados. Incluye **40 casos nuevos**: preparación 5, coordinación de listado 13, formulario 20
  y composición contextual 2, además de los 168 casos de regresión Clients/composición de 08.1.
  Informe `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/927CD8D4-7501-4190-B377-BCB5885352A5.txt`.
  Consola `test-console-log-2026-09-08T14-26-01+02-00.txt` en la misma carpeta. Develop/iPhone 11 físico, iOS 27.0.
- Build final `FranAlonso-Develop` correcto en 3,958 s después de restaurar el scheme.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-142620.txt`.
  El log completo conserva el aviso conocido de extracción AppIntents en línea 10729. GetBuildLog MCP filtrado
  por warning devuelve cero entradas (`CA8DD88C-A06C-4C47-82F5-40E4F7EB0B7F.txt`), Navigator cero issues y los seis
  Swift de producción cero diagnósticos. No se declara cero warnings globales ni causa cacheada del aviso.
- Gobernanza, enlaces locales y `git diff --check` pasan. Sin cambios en Data, esquema, configuración, Views,
  localización ni semántica accesible; previews y auditoría de accesibilidad `N/A`. No se ejecuta una nueva suite
  global/Production, no se activa live y no se presenta esta regresión como ReleaseGate.
- Auditoría final independiente iOS: **PASS, sin hallazgos P0–P3** sobre diez Swift y tres documentos contra
  `1164c62`. Revisor nuevo en sesión efímera con sandbox read-only impuesto; aplica
  `franalonso-review-ios-standards`. No propone correcciones ni realiza escrituras, publicaciones o cambios de tracker.
  Huellas pre/post verificadas por el orquestador: **438 archivos**, idénticas,
  `1e5d3aa45950fab789cee0b1cb2fea2939d64a96a3c54e65bcfb8921a0bae1b4`.
  Informe local: `/tmp/franalonso-082-final-review-result.md`; eventos:
  `/tmp/franalonso-082-final-review-events.jsonl`.
- El revisor contrasta directamente fuentes, oráculos de los 40 casos nuevos, informes 46/46 y 208/208,
  selección de las 26 suites, `BUILD SUCCEEDED`, warning completo y restauración del scheme. Duración/destino,
  ceros de filtros MCP/Navigator/refreshes, remoto y Linear son evidencia del orquestador, no ejecución propia.
  Cupertino no obtiene aprobación en su sandbox; contrasta documentación Apple oficial por web. No solicita
  builds/tests: la primera lectura Git emite mensajes del shim Apple y las siguientes usan el binario Git directo.
  El PASS queda limitado a 08.2; la futura integración debe mantener contextos del mismo contenedor y tareas
  propiedad del caller. El registro documental de este dictamen se añade después de comprobar las huellas.

## Publicación de 08.2 — 2026-09-08

- El propietario autoriza commit/push de 08.2 y avanzar con 08.3. Commit
  `64736583b4717c92cdd7445f004e76a3f9aab7f8` — `✨ feat(clients): coordinate client list and form state`.
  Se incluyen trece rutas explícitas; changelog incluido, staged diff y gobernanza comprobados.
- Push con upstream `origin/codex/plu-36-phase-08-2-client-view-models`; `git ls-remote` devuelve el mismo SHA.
  Árbol limpio tras publicar. No se repiten build/tests porque solo cambió el registro documental de autorización.
  PLU-36 conserva `In Progress`; sin PR/merge/cierre. 08.1 y 08.2 continúan apiladas y no integradas en main.

## Inicio de 08.3 — propuesta

- [PLU-37](https://linear.app/plusprojects/issue/PLU-37), hija de PLU-34, `In Progress`.
  Rama `codex/plu-37-phase-08-3-client-screens`, desde `6473658` limpio; sin código ejecutable nuevo.
- Xcode MCP conectado a este checkout (`windowtab1`). Superficie core de 21 herramientas; no hay herramientas
  extendidas de lanzamiento, cambio de destino ni interacción accesible anunciadas. La operabilidad de Inspector y
  tecnologías de asistencia debe verificarse en la implementación; no se presume de herramientas históricas.
- Configuración comprobada: target iOS 26.0, Swift 6, strict concurrency complete, aislamiento por defecto
  nonisolated y warnings Swift/Clang como errores. Xcode instalado 26.6, Swift 6.3.3, SDK iPhoneOS 26.5.
- Baseline heredado y vigente de 08.2: 26 suites/208 resultados, build Develop y auditorías PASS con el aviso
  AppIntents documentado. No se acredita nuevo render, runtime, accesibilidad ni Production de 08.3.

### Alcance concreto

1. Integrar `ClientListScreen` con búsqueda nativa `.searchable`, alta desde toolbar y edición desde filas Button.
   `ClientListContent` recibe los resultados derivados de `visibleClients` y `hasNoSearchResults`; distingue carga,
   fuente vacía, contenido filtrado, sin coincidencias y error con reintento. Ni Screen ni contenido filtran datos.
   La búsqueda conserva la query al regresar del formulario y no introduce debounce ni peticiones remotas.
2. Presentar una única `.sheet(item:)` con `ClientFormDestination`. El binding delega el cierre mediante el ID de
   sesión capturado; no escribe directamente en `private(set)` ni deja que un callback antiguo cierre otra sesión.
   El formulario conserva su ViewModel en `@State` por identidad; no se reconstruye al editar un campo.
3. Crear `ClientFormScreen` y contenido declarativo de formulario con controles SwiftUI nativos. Nombre obligatorio,
   identificador fiscal opcional y dirección opcional (calle, código postal, localidad, provincia). Labels persistentes,
   propósito de entrada/autofill cuando corresponda y teclado operable. No se inventan validaciones fiscales.
   El alta comunica que guarda un borrador; no se ofrece activación ni se afirma disponer de consentimiento.
4. Representar carga inicial, edición, validación, guardando/desactivando, fallo de lectura o mutación y resultado.
   Nombre inválido se asocia al campo y propone corrección. Los errores se traducen desde errores semánticos finitos
   a recursos de Presentation; no se muestran strings de SDK. Reintentar carga no permite guardar un perfil vacío.
   Guardar/cancelar son acciones explícitas; cancelar descarta los cambios sin guardar. Se impide el cierre interactivo
   que pudiera descartar accidentalmente el formulario y se bloquean sus acciones incompatibles durante una mutación.
5. Desactivar solo un cliente existente cargado mediante confirmación nativa explícita y acción destructiva localizada.
   Guardado/desactivación cierran tras aceptación local y el listado se actualiza por su observación existente.
   La confirmación no promete eliminación remota ni borrado del histórico/consentimiento retenido.
6. Las tareas pertenecen al Screen mediante `.task`/`.task(id:)`, siguiendo el patrón existente de `LoginScreen`.
   Las intenciones usan identificadores de solicitud efímeros; ninguna tarea ni propiedad conserva `ModelContext`.
   El Screen lo obtiene del entorno y lo pasa a `save(in:)` o `deactivate(in:)`; toda persistencia queda en Data.
   Cerrar invalida la sesión; una cancelación no promete revertir una escritura ya aceptada. Se reutilizan los guards
   y tokens de 08.2; solo se amplía lógica semántica si la integración demuestra una necesidad cubierta primero por test.
7. App expone una capacidad de creación de formularios que captura únicamente los roles ya compuestos para Clients.
   Runtime y composición local Develop comparten actor/señal entre lectura, observación y adaptador contextual.
   La Screen recibe esa capacidad, sin acceder a `AppRuntime` ni construir repositories. Las composiciones inyectadas
   de tests reciben capacidades explícitas; no se introduce una segunda ruta de escritura o un fallback live.
8. El preview navegable estándar comparte su `ModelContainer` in-memory entre lecturas y escrituras, con telemetría
   fake e instancias de actor/señal únicas para ese contexto. `AppPreviewModifier` conserva seed idempotente fuera de
   cualquier View; se evita el repositorio one-shot paralelo actual. Los previews snapshot de 0/1/80 clientes usan
   valores sintéticos deterministas, sin resembrar diferentes escenarios sobre el mismo contexto estático cacheado.
   Los helpers existentes de previews solo de lectura no se presentan como prueba de CRUD reactivo.
9. Cada View nueva/modificada mantiene un tipo View por archivo y preview propio con trait compartido. Se usan los
   componentes/tokens existentes; los nuevos textos y anuncios viven en `Localizable.xcstrings`, español vigente.
   No se añade idioma, dependencia, router, Store, migración, target, permiso ni configuración de producto.
10. Accesibilidad por construcción según ADR 0022: nombres alineados con texto, estructura/encabezados, 44×44 pt
    operables, contenido largo hasta AX 5, errores asociados, resultados anunciados y orden/restauración de foco al
    abrir/cerrar sheet o confirmación. Se empieza por comportamiento nativo y se corrigen fallos de foco observados;
    no se mueve foco por cada tecla de búsqueda. iPad mantiene adaptación; iPhone conserva la excepción 1.3.4 de ADR 0026.

### Archivos y alternativas

- Clients/Presentation: `ClientListScreen`, `ClientListContent`, `ClientRow`, nuevos `ClientFormScreen` y contenido
  del formulario; helpers semánticos de Presentation solo si evitan lógica en View. Ajustes mínimos de ViewModels
  limitados a necesidades de integración demostradas y testeadas, sin rehacer las reglas de 08.2.
- App: `AppDependencies`, `AppDependencies+ClientForm`, `AppShellScreen`, `AppPreviewModifier` y fixtures de preview.
  Composición/test callers afectados; `Localizable.xcstrings`; tests de composición/presentación nuevos pertinentes;
  Progress, changelog y registro de accesibilidad de fase 08.
- Se eligen List/Form/searchable/sheet/confirmationDialog nativos. Se descartan buscador o navegación custom,
  un formulario global en el shell, construir un ViewModel en cada render, pasar modelos SwiftData vivos o almacenar
  el contexto, y sustituir observación local por recargas manuales tras cada cierre.
- El cambio del preview navegable es necesario para demostrar que guardar y observar usan la misma fuente local.
  Se conserva la capacidad de previews snapshot para estados específicos; no se crean fixtures runtime de fallos
  o latencia sin revisión expresa de ADR 0023/0024. La fixture estándar existente basta para el recorrido local feliz.
- Quedan fuera firma/consentimiento/PDF/Storage, `ClientConsentStore`, activación, foto/detalle de 08.9, histórico
  remoto, live, restauración/deep links, rediseño del shell y cambios funcionales de otras features.

### TDD, validación, fuentes y riesgos

- La lógica de 08.2 ya tiene 40 casos nuevos. No se añaden UI tests ni tests que repitan el árbol de SwiftUI.
  RED/GREEN focal para la nueva composición expuesta: crear/editar/desactivar mediante la capacidad pública y
  comprobar snapshot del mismo contenedor, ausencia de doble escritura y preservación de configuración no-live.
  Cualquier nuevo mapping o coordinación con comportamiento real recibe un oráculo independiente.
- Regresión por suites completas de ViewModels/Clients, composición App/previews, localización y shell afectado.
  Build y diagnósticos Xcode MCP; no se declara ReleaseGate global sin ejecutarlo ni se repite por ritual la suite total.
- Previews: listado con 0/1/80 clientes, sin coincidencias, error y carga; formulario alta, edición con contenido largo,
  validación, fallo inicial, fallo de guardado y ocupado. Render e inspección de variantes soportadas Large/XXX Large/AX 5,
  Light/Dark y contraste normal/incrementado, RTL, iPad/ventana estrecha y preferencias de accesibilidad pertinentes.
- Runtime manual/Inspector sobre listado, formulario y flujo transversal: alta → búsqueda → edición → cancelación →
  validación → guardar → desactivar, apertura/reapertura y foco. Registrar VoiceOver, Voice Control, Switch Control y
  Full Keyboard Access de forma separada. La fixture Develop estándar usa SwiftData in-memory sin live; la fixture de
  error de listado no se recupera al reintentar. Loading sostenido/fallos de formulario carecen de fixture runtime actual:
  previews/tests no acreditan su recorrido AT. Esa evidencia queda pendiente si no puede demostrarse, sin cerrar la subfase.
- Cada pantalla y flujo conserva todas las filas de la matriz ADR 0022, con aplicabilidad, resultado y evidencia precisa.
  Auditorías finales independientes iOS/estilo y SwiftUI/accesibilidad; solo se repite el ámbito afectado por correcciones.
- Fuentes consultadas por Cupertino, Apple oficial:
  [sheet(item:)](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)),
  [searchable](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)-18a8f) y
  [AccessibilityNotification.Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement).
  Sustentan presentación por identidad, buscador nativo y anuncios; el control de sesión/cancelación es decisión del
  proyecto, no garantía automática de esas APIs. Autoridad local: spec 08, ADR 0011/0022/0026 y navegación aprobada.
- Riesgos principales: instancias de formulario recreadas, cierres obsoletos, contexto distinto al observado, contaminación
  del preview cacheado y pérdida de foco/acciones con AX 5. Se cubren por identidad, composición, tests y evidencia manual.
  Reversibilidad: el cambio es Presentation/composición/recursos; no hay migración ni operación remota.
- Revisión independiente previa: **PASS, sin hallazgos P0–P3**. Revisor nuevo en sesión efímera con sandbox
  read-only impuesto, sin escrituras, mutaciones Git/tracker, builds/tests/previews ni subagentes. Git directo evita
  el shim Apple. Huellas pre/post verificadas por el orquestador: **438 archivos**, idénticas,
  `a2104da6c1313a0768f8c9c72d6bf842864d3990ce6d69f1625fe6b5b733bd6f`.
  Informe: `/tmp/franalonso-083-proposal-review-result.md`; eventos:
  `/tmp/franalonso-083-proposal-review-events.jsonl`.
- El revisor confirma viabilidad de composición, identidad, cancelación, previews, TDD y límites de accesibilidad;
  contrasta directamente baseline 208/208, build y aviso AppIntents. Conexión Xcode, duración, remoto y Linear son
  evidencia del orquestador. Consulta Apple oficial por web al no obtener aprobación para Cupertino en su sandbox.
  No acredita implementación o runtime nuevos. El propietario aprueba después el alcance concreto presentado.

## Implementación de 08.3 — 2026-09-08

- El propietario aprueba la propuesta. Se inicia implementación en PLU-37 y su rama existente; sin autorización
  de entrega, cierre, 08.4 o live.
- RED focal Xcode MCP: `ClientScreenCompositionTests` no compila porque `AppDependencies` todavía no expone
  `makeClientForm`; los demás errores de inferencia son cascadas. Log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/GetBuildLog/02FFE988-2450-4877-9CFB-1143169676F1.txt`.
- Integrados listado, búsqueda, sheet por identidad y formulario nativo de alta/edición, validación, cancelación,
  guardado y confirmación de desactivación. App expone la factory sobre los roles existentes; la observación y el
  contexto de escritura comparten contenedor. Los previews navegables usan esa composición reactiva; las variantes
  snapshot e inyectadas rechazan escritura explícitamente. Sin cambios Domain/Data, migración ni motores live.
- Ocho casos nuevos de composición prueban CRUD observado, una operación pendiente por mutación y denegación de
  escritura en capacidades de solo lectura. Primer GREEN **20/20** en tres suites, informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/4C445747-9053-4F3E-A2DD-B7E16421D532.txt`.
- La primera regresión se canceló: el test histórico de preview esperaba que terminase un stream que ahora permanece
  reactivo. Se retiró esa expectativa obsoleta, conservando comprobaciones de seed/snapshot e idempotencia, y se limitó
  la suite a un minuto. El nuevo caso de composición acredita las actualizaciones sucesivas. Reejecución completa
  de **32 suites / 259 resultados pasados**, sin fallos, omitidos ni no ejecutados; selección de 197 declaraciones
  con casos parametrizados. Develop/iPhone 11 físico iOS 27.0. Informe
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/374AC178-95F3-462D-B95E-D4DD746CE2A3.txt`;
  selección exacta en `/tmp/franalonso-083-regression-suites.json`. No es ReleaseGate global ni Production.
- Primer build correcto en 11,897 s; build de simulador verificado en 22,365 s, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-161108.txt`.
  Build final tras restaurar configuración: **PASS, 12,07 s**, Develop/iPhone 11, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-162602.txt`.
  GetBuildLog warning devuelve cero entradas (`1480064F-5641-49AD-8CB2-6EFFA02F4E12.txt`) y Navigator cero issues.
  El log completo conserva el aviso AppIntents en línea 10950; no se declara cero warnings agregados. Los logs de
  host/simulador también contienen diagnósticos de Firebase sin configurar, dSYM y teclado/hápticos del runtime;
  no se presentan como una sesión Production validada ni se corrigen mediante cambios ajenos a 08.3.
- Se produjeron e inspeccionaron **19 capturas** de previews, incluidas capturas iniciales reemplazadas y una pantalla
  de edición que solo llegó a carga. Listado 0/1/80, sin coincidencias, fallo y carga; formulario alta, edición larga,
  validación, fallo inicial/de guardado y progreso; Large/XXX Large/AX 5 y variantes claras/oscuras/de contraste
  descritas individualmente en el [registro accesible](../accessibility/evidence/08-3-client-screens.md).
  Se corrigió el recorte del label obligatorio en AX 5 mediante dos ajustes de crecimiento vertical del componente
  compartido, y se situaron errores/progreso antes de los campos para que resulten visibles. El render posterior al
  build confirma el label completo; el preview propio compartido también conserva el label. No acredita todos sus
  consumidores ni las combinaciones visuales todavía pendientes.
- Runtime CUA en iPhone 17e/iOS 26.5: alta sintética, nombre vacío rechazado, búsqueda, edición, cancelación sin
  persistir, reapertura con consulta conservada y guardado de campo fiscal recuperado al reabrir. La desactivación
  UI no quedó demostrada: las acciones de scroll/drag CUA no desplazaron el viewport; no se atribuye todavía un
  defecto a Form. Inspector pudo seleccionar Fran DEV, pero Run Audit no produjo un informe. Después se cerró
  el pipe nativo CUA; la reconexión permitió detener la app y restaurar configuración.
- Corrección de evidencia de fixture: editar externamente el argumento en `.xcscheme` no actualizó el estado
  cacheado del IDE. Los tests pasan usando sus propias composiciones aisladas, pero no se acredita la fixture del
  host de los runs de **08.1, 08.2 y 08.3**. La auditoría contrasta inicialización Firebase en las consolas históricas
  de 08.1 (13:01:12, líneas 373–383) y 08.2 (14:26:01, líneas 435–445); no permite reconstruir la ruta exacta del host,
  ni deducir tráfico o escrituras live. La restauración de los archivos sí está acreditada. Los primeros lanzamientos
  de 08.3 tampoco acreditan la fixture. El recorrido de Clientes anterior sí se hizo
  después de verificar en Edit Scheme el argumento signed-out activado y los otros cuatro desactivados, sobre la
  fixture Develop existente. Al terminar se verificaron **los cinco argumentos desactivados en el IDE**, se restauró
  el scheme byte a byte desde `/tmp/franalonso-083-develop-scheme.original` (SHA-256
  `102acd2d88ad638d698face0f77aabb384bfd0a418dfdbf035bd867596fdac9a`) y se devolvió el destino al iPhone 11.
- Registro ADR 0022 con **55 filas por listado, formulario y flujo transversal**. La evidencia de tecnologías de
  asistencia, foco/anuncios completos, contraste medido, preferencias, iPad/ventanas/RTL y desactivación UI permanece
  pendiente. La excepción de orientación iPhone de ADR 0026 no autoriza cerrar los demás pendientes. Las pruebas
  lógicas y los previews no se convierten en pasadas runtime accesibles. Auditorías finales independientes en curso.

### Auditorías independientes y correcciones focales

- Dos revisores nuevos, `ios-standards-reviewer` e `ios-accessibility-reviewer`, en modo operacional estrictamente
  read-only: sin ediciones, publicaciones, cambios Git/tracker o ejecuciones Xcode. Orquestador verifica **446 archivos**
  tracked y no ignorados, pre/post idénticos: `886d7286850e9f2f4ebc43252fd703e0f9d1ef815e0158a0abe93d7e7c1f76f4`.
  Manifiestos `/tmp/franalonso-083-final-audit-before.json` y `/tmp/franalonso-083-final-audit-after.json`.
- iOS: sin hallazgos técnicos/estilo en **17 Swift**, cinco candidatos léxicos justificados (cuatro tuplas UUID y un
  inicializador con closure ViewBuilder). Contrasta directamente RED, 20/20, 259/259 y build/log final. Único P2:
  ampliar la rectificación de fixture al histórico 08.1/08.2. Corregido en ambos apartados y en la nota de 08.3;
  no se deducen tráfico ni escrituras live a partir de inicialización Firebase.
- Accesibilidad: confirma 55 criterios exactos L/F/X, 34 recursos nuevos sin cambios en los anteriores, estructura
  declarativa y los 19 renders iniciales. Dos P2: título inline recortado en AX 5 y contraste raster insuficiente del
  label de progreso en claro. Corregidos mediante título nativo grande y token `TextPrimary` en ese label.
- Build tras esos dos ajustes visuales: **PASS, 7,686 s**, Develop/iPhone 11, log
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260908-163708.txt`.
  GetBuildLog warning sin entradas (`875B3B13-AF51-496F-A54B-2DDDCF449D0C.txt`); AppIntents persiste en línea 10917.
  No se repiten los tests lógicos: solo cambian presentación de título y color. Se añaden siete renders, **26 capturas
  en total**: título completo Large/AX 5, progreso en cuatro apariencias y labels Email/Contraseña del consumidor
  LoginContent completos a AX 5. Muestreo raster del progreso supera 4,5:1 en las cuatro capturas, con método y límites
  en el registro accesible; no se presenta como Inspector ni contraste general de pantalla.
- Reauditorías focales: **iOS PASS, P2 documental cerrado; accesibilidad cierra los dos P2 visuales, sin nuevos
  hallazgos P0–P3**. El especialista inspecciona los siete renders correctivos y reproduce los cuatro ratios del
  label de progreso. Orquestador verifica de nuevo **446 archivos** pre/post idénticos:
  `7eed94728aa868f98313e5b9680765ed498812e08fa8dca30cdc9a54e8e940f2`, manifiestos
  `/tmp/franalonso-083-reaudit-before.json` y `/tmp/franalonso-083-reaudit-after.json`. Sin escrituras o ejecuciones
  Xcode por los revisores. El registro de los dictámenes se añade después de verificar las huellas.
- La auditoría accesible mantiene el gate ADR 0022 bloqueado por evidencia aplicable no ejecutada; cerrar los
  hallazgos visuales no permite cerrar 08.3. Gobernanza, enlaces y diff-check pasan; el diff conserva 34 recursos
  nuevos sin cambios de los existentes, y no incluye configuración, credenciales o archivos de entorno.
- Linear: PLU-34/PLU-37 reflejan implementación y validación parcial, `In Progress`; las notas de PLU-35/PLU-36
  distinguen la restauración del scheme de la activación no acreditada del host. Sin cambios de estado ni entrega.

### Prueba guiada en iPhone 14 y recuperación del error de nombre

- 2026-09-08: recorrido realizado y comunicado por el propietario, iPhone 14 / iOS 26.6.1,
  Xcode 26.6 / Develop, fixture signed-out habilitada para la sesión manual. Confirma listado vacío,
  Guardar vacío mantiene el formulario y muestra el error con foco en nombre; cumplimenta los seis campos,
  desplaza hasta Provincia y guarda: sheet cerrada y una sola fila. No acredita tecnologías de asistencia.
- Defecto descubierto: el error de nombre permanecía al escribir un nombre válido y al perder foco.
  Corrección acotada en `ClientFormViewModel.fields`: solo retira `.failed(.save, .invalidDisplayName)`
  cuando cambia el nombre y el constructor Domain `ClientProfile` lo acepta. No normaliza el texto escrito,
  no guarda y conserva errores ajenos, espacios inválidos y estados ocupados/cerrados.
- Propuesta independiente read-only PASS; 446 archivos pre/post idénticos, SHA-256
  `a716b92c447483f9120ddd0e0acb0dc1127f984ac748332bed297932d2a60f10`.
- TDD mediante Xcode MCP, Develop / iPhone 14: RED **21 pasados / 1 fallo esperado por la regresión**
  (no marcado como expected failure), en la expectativa de `.editing` antes de volver a guardar.
  Artefacto `RunSomeTests/DA820EDF-566F-427A-89F6-3D55223C2170.txt`.
  GREEN **32/32**, suites `ClientFormViewModelTests`, `ClientFormCompositionTests` y
  `ClientScreenCompositionTests`, 0 fallos/omitidos/no ejecutados; incluye dos casos nuevos parametrizados.
  Artefacto `RunSomeTests/D943B43D-CCD6-41C8-A782-61A2B3E5FF5A.txt`.
  Ambos bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`.
- Build posterior **PASS, 4,08 s**: `BuildProject/BuildProject-Log-20260908-190516.txt` en la misma base.
  Navigator/GetBuildLog sin issues; aviso AppIntents persiste en línea 10729 del log completo.
  No se repiten las 32 suites históricas: cambio focal cubierto por estas tres suites.
- El scheme signed-out y destino iPhone 14 quedan configurados para continuar la prueba del usuario;
  sustituyen la restauración histórica al iPhone 11. Los datos de esta fixture son temporales.
  El propietario confirma después que el error desaparece al escribir en el iPhone 14.
  Confirma también guardar el cliente, reabrirlo, cambiar su nombre y cancelar: el nombre original
  permanece en el listado y al reabrir el formulario. Prueba posterior confirma guardar una edición con
  nombre «Cliente editado 08.3» y ciudad «Sevilla»: ambos valores se conservan al reabrir y el listado
  mantiene una sola fila para ese cliente. Evidencia AT de esta sesión aún pendiente. Resultado manual comunicado por el propietario, sin nueva ejecución de código.

- El propietario comunica que confirmó Desactivar y el cliente desapareció del listado: desactivación UI
  acreditada por reporte manual en iPhone 14. En otra apertura, el diálogo no mostró Cancelar; una pulsación
  en Cancelar de la edición cerró el diálogo y la segunda cerró el formulario. No se infiere todavía
  conservación del cliente tras esa cancelación ni acceso con AT.
  El código sí declara el botón con rol cancel. Apple describe que las action sheets ancladas de iOS 26
  omiten Cancelar y se cierran tocando fuera ([WWDC25, 284](https://developer.apple.com/videos/play/wwdc2025/284/)).
  Es compatible con el reporte, sin inspección directa de su presentación. En la prueba posterior, el
  propietario confirma que tocar fuera cierra solo la confirmación, deja el formulario abierto y conserva
  el cliente al cerrar la edición y volver al listado. Cancelación de desactivación confirmada por reporte
  manual; AT sigue pendiente. Se corrige la instrucción manual, sin cambiar código nativo.

- Reauditorías focales finales iOS y accesibilidad: **PASS, sin hallazgos P0–P3**. Inspección estática confirma
  mensaje/hint derivados del mismo estado y ausencia de nuevas solicitudes de foco por pulsación.
  Orquestador acredita 446 archivos pre/post idénticos, SHA-256
  `017d8ba56e758bceff8ad569b7fad33e659af9c857355cff7bdbfc942d8ca2e9`, manifiestos
  `/tmp/franalonso-083-name-fix-final-before.json` y `/tmp/franalonso-083-name-fix-final-after.json`.
  PLU-37 actualizado con la sesión y corrección, conserva `In Progress`. Confirmación visual posterior del propietario: el error desaparece al escribir.
  Registro documental de este resultado; build/tests N/A, sin cambios de código.

- El propietario confirma búsqueda por «editado», estado sin coincidencias con «zzzinexistente083»
  y recuperación del cliente al borrar la consulta, en iPhone 14 / iOS 26.6.1. Evidencia manual sin AT. Registro documental, build/tests N/A.

### Corrección visual tras capturas AX 5 — 2026-09-09

- El propietario aporta cuatro capturas originales (1170×2532) del iPhone 14 / iOS 26.6.1 en oscuro,
  tras solicitar el tamaño de accesibilidad máximo: `/Users/jesusf/Downloads/IMG_1245.PNG`, `IMG_1246.PNG`,
  `IMG_1247.PNG`, `IMG_1249.PNG`. Inspección visual confirma placeholders duplicados truncados en nombre,
  calle, localidad y provincia; fiscal/postal se ven menores. Título colapsado Nuevo/Editar también truncado.
  Se alcanzan los seis campos y Desactivar. No demuestra entrada con teclado, activación ni AT a ese tamaño.
- La evidencia correctiva anterior C01/C02 cubría el título expandido, no el colapsado: se reabre ese límite.
  Corrección acotada en dos Views: los seis TextField conservan título y accessibilityLabel localizados y
  reciben prompt explícito vacío; ejes, bindings, content types, foco y submit no cambian. No se limita Dynamic Type.
  En tamaños accesibles, Cancelar/Guardar usan xmark/checkmark con área mínima 44×44, nombres localizados
  y large content viewer con texto/símbolo. Otros tamaños conservan acciones textuales; título nativo grande.
- Propuesta independiente de accesibilidad PASS, sin hallazgos bloqueantes. 446 archivos pre/post idénticos,
  SHA-256 `eb6878ffca93a1210e964a2850ba4a6d336ac815212b772006b3091fef15f8e4`, manifiestos
  `/tmp/franalonso-083-ax5-proposal-before.json` y `-after.json`.
- Build Xcode MCP Develop / iPhone 14 **PASS, 10,967 s**:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260909-003114.txt`.
  Navigator/GetBuildLog sin issues; aviso AppIntents persiste en línea 11617. No se repiten tests de negocio:
  solo layout/semántica de Views, sin cambio de lógica; spec 08.3 mantiene lógica cubierta en ViewModels.
- Se inspeccionan un render anterior y cinco correctivos, manifiesto `/tmp/franalonso-083-ax5-preview-manifest.json`:
  alta Large/XXX Large claro y AX 5 oscuro; edición AX 5 oscuro y campos con valor AX 5 claro. Título expandido,
  acciones y label/nombre visibles correctos. Los renders solo cubren el viewport inicial, no título colapsado,
  seis campos completos a AX 5, tamaños reales de objetivos, teclado ni nombres/operación con AT.
- Xcode tenía aviso de sesión terminada por desconexión del iPhone 14; se cierra el aviso, sin relanzar la app
  ni cambiar scheme/destino/fixture. Verificación física de esta corrección pendiente. No se declara resuelto
  el título colapsado por los renders iniciales ni se cierra ADR 0022. Sin commit/push/cierre/live.

- Reauditorías finales focales iOS/estilo y accesibilidad **PASS, sin nuevos hallazgos P0–P3**.
  Dos Swift auditados; especialista inspecciona A01–A05. Título colapsado y operación runtime siguen abiertos.
  446 archivos pre/post idénticos, SHA-256 `ec23ec1cd6f6d5b0e93c8d34888a0e56e804ba768e597d0f3e10ede02e530083`,
  manifiestos `/tmp/franalonso-083-ax5-final-before.json` y `/tmp/franalonso-083-ax5-final-after.json`.
  PLU-37 sincronizado sin cambio de estado; dictámenes registrados después del cotejo de huellas.

- Confirmación posterior del propietario (09-09), tras el guion de relanzar, mantener texto máximo, abrir
  Nuevo cliente, recorrer campos y escribir nombre: «Ahora si, todo correcto y completo». Confirma visualmente
  la corrección de los campos y el título después del scroll en iPhone 14 / iOS 26.6.1. Evidencia comunicada
  por el propietario, sin captura posterior ni inspección directa. No acredita todos los campos con valores
  largos, Guardar/Cancelar con símbolos, long press, foco/anuncios ni tecnologías de asistencia a AX 5.
  Registro documental únicamente, build/tests N/A. Los límites de renders anteriores permanecen históricos.

- Continuación del propietario a texto máximo (09-09): conserva el nombre, escribe Sevilla en Localidad
  y Provincia con teclado abierto, pulsa ✓ Guardar y reabre el cliente; confirma acceso a ambos campos,
  guardado y conservación de los datos. Reporte manual en iPhone 14 / iOS 26.6.1, sin nueva captura.
  No acredita valores largos en todos los campos, Cancelar con ×, long press, foco/anuncios o AT.
  Solo registro documental, build/tests N/A.

- El propietario confirma Cancelar con × a texto máximo (09-09): cambia Localidad de Sevilla a Madrid,
  pulsa ×, vuelve al listado y reabre; conserva Sevilla. Acción y descarte confirmados por reporte manual
  en iPhone 14 / iOS 26.6.1. No acredita long press, valores largos en todos los campos, foco/anuncios o AT.
  Registro documental únicamente, build/tests N/A. Siguiente prueba guiada: VoiceOver en el listado.

- Inicio de VoiceOver comunicado por el propietario (09-09), iPhone 14 / iOS 26.6.1. Se pidió restaurar
  tamaño habitual; categoría exacta no registrada. Anuncios reportados: «Añadir cliente, botón»;
  «Buscar clientes, campo de búsqueda, toca dos veces para editar»; fila con nombre del cliente, «botón,
  abre el formulario de este cliente». Se omite el valor del nombre del registro de evidencia.
  Nombres, roles e instrucciones de esos tres elementos confirmados por reporte, sin audio ni Inspector.
  No acredita apertura, entrada, rotor, foco/restauración, errores o mutaciones con VoiceOver. R03 parcial.
  Registro documental, build/tests N/A; siguiente paso: abrir el cliente y escuchar campos/botones.

- Continuación VoiceOver del propietario (09-09): al abrir el cliente, foco inicial en «Cancelar, botón»;
  después «Guardar, botón», «Editar cliente, encabezamiento», todos los campos y «Desactivar cliente, botón».
  Cada TextField anuncia su etiqueta, obligatorio/opcional, valor si existe, rol campo de texto e instrucción
  de doble toque para editar; informa también del rotor para palabras mal escritas. No se registran valores.
  Cuando el encabezado está colapsado, se lee entre Cancelar y Guardar, conforme al orden visual comunicado.
  Apertura, foco inicial y recorrido lineal confirmados por reporte en iPhone 14 / iOS 26.6.1, sin audio/Inspector.
  La mención del rotor no acredita su uso. No demuestra aún validación, mutaciones ni restauración al salir.
  Registro documental, build/tests N/A; siguiente prueba: retorno y error de nombre vacío con VoiceOver.

- VoiceOver, retorno y nombre obligatorio (reporte del propietario, 09-09, iPhone 14 / iOS 26.6.1):
  Cancelar edición restaura el foco en la fila del cliente desde la que se abrió. Añadir cliente y Guardar
  vacío lleva al nombre; anuncia «Nombre obligatorio, campo de texto, edición en curso, carácter, punto
  de inserción al principio. Escribe el nombre del cliente para poder guardarlo».
  Se acreditan por reporte el retorno de cancelación, foco de validación e instrucción de corrección escuchada.
  Sin audio/Inspector, no se infiere ausencia de duplicados o interrupciones no reportadas. Recuperación al
  escribir, guardado/desactivación y sus retornos, y uso del rotor siguen pendientes. Build/tests N/A, documentación.

- VoiceOver, recuperación y guardado (propietario, 09-09, iPhone 14 / iOS 26.6.1): al escribir
  desaparece el error y al guardar escucha «Cliente guardado». Regresa al listado, pero el foco queda en
  «Cerrar sesión»: defecto de retorno confirmado. Corrección acotada a ClientListScreen: tras cerrar un
  alta, solicita foco VoiceOver en Añadir cliente, con identidad de sesión comprobada y flag consumido
  en onDismiss; edición conserva su retorno nativo. Propuesta independiente PASS, 446 archivos idénticos
  pre/post, SHA-256 `b8dd332c6e29f36a76c92af7c9fa539fb6813c43f90635d8a11f6998bc6f51d5`.
  Build Xcode MCP PASS (8,706 s), Develop / iPhone 14: `BuildProject-Log-20260909-023110.txt`;
  Navigator/GetBuildLog sin issues, log completo mantiene aviso AppIntents (línea 11610).
  Preview de listado inspeccionada: `RenderPreview_result_2026-09-09T003147Z@3x.png`, estado de carga;
  no acredita foco ni anuncios. Tests unitarios no repetidos: ajuste exclusivo de ciclo UI/foco, sin lógica
  de negocio nueva. Pendiente retest físico: alta guardada/cancelada → Añadir, edición cancelada → fila,
  nueva sesión sin foco obsoleto y anuncio completo sin interrupción. Defecto y puerta ADR 0022 abiertos.

- Reauditorías focales finales de retorno VoiceOver: accesibilidad e iOS/estilo PASS, sin hallazgos.
  Read-only operacional verificado por el orquestador: 446 archivos idénticos, SHA-256
  `cb18d5179a9794f3c8ba94ebdc420a7863f5ca93e6c106ee6406f5c5e6cc3d18`.
  PASS estático; el defecto runtime permanece abierto hasta el retest del propietario.

- Retest VoiceOver del propietario (09-09): el ajuste anterior FALLA. Al guardar escucha «Cliente guar…»
  cortado por el retorno al listado, cuyo foco sigue en «Cerrar sesión». Tras esa prueba añade
  `ToolbarSpacer(.fixed, placement: .primaryAction)` para separar Cerrar sesión y Añadir; se conserva
  exactamente. No se atribuye el fallo anterior al separador ni se acredita todavía su efecto táctil.
  Nueva corrección en ClientFormScreen/ClientListScreen: resultado explícito `Completion` por closure
  `@MainActor`; el listado comprueba identidad, conserva resultado efímero y cierra mediante su ViewModel.
  `onDismiss` consume el resultado, solicita foco VoiceOver en Añadir para alta/desactivación y anuncia
  éxito con prioridad `.high`, solo después del cierre. Cancelar/guardar edición mantiene retorno nativo.
  Sin retrasos, UIKit, cambio de datos o anuncio de éxito previo al cierre. La causa exacta del fallo de foco
  anterior no está demostrada. Apple: [Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement),
  [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate).
  Propuesta independiente PASS; 446 archivos pre/post idénticos, SHA-256
  `6762c1286eb036abf5774e1481ec452e8a9a6f75518853f12212e31702680668`.
  Xcode MCP build PASS (8,95 s), Develop / iPhone 14: `BuildProject-Log-20260909-083959.txt`.
  Navigator/GetBuildLog sin issues; log completo conserva aviso AppIntents en línea 11610.
  Previews inspeccionadas, prefijo `RenderPreview_result_2026-09-09T`, sufijo `Z@3x.png`: listado Large
  `064035` (contenido) y AX 5 `064055` (carga); formulario Large `064108`, XXX Large `064143` y AX 5
  `064115`, viewport inicial. Listado XXX Large falla dos veces en código generado preview-thunk:
  `ambiguous use of __designTimeSelection`, junto al Button de toolbar; no se modifica el separador para
  sortearlo. Primera petición XXX Large del formulario y AX 5 compartieron ruta; `064143` sustituye la
  evidencia XXX Large. Las capturas no prueban cierre, foco, locución ni separación junto a Cerrar sesión.
  Sin tests unitarios nuevos ni repetición de negocio: solo coordinación de presentación; spec 08.3
  mantiene esa lógica cubierta en ViewModels. Defectos de foco/anuncio y ADR 0022 abiertos hasta retest:
  guardar/cancelar alta → Añadir, cancelar/guardar edición → fila, desactivar → Añadir y anuncios completos.

- Reauditorías finales de la nueva finalización explícita: iOS/estilo y accesibilidad PASS estático,
  sin hallazgos P0–P3. Read-only operacional verificado: 446 archivos idénticos, SHA-256
  `a9ed1f28d1f457b2cc9dfdd149c7ccf59ddf309e18e0997672510bf83207161a`.
  No acredita resolución runtime: foco y locución pendientes del retest del propietario.

- Retest posterior del propietario (09-09, iPhone 14 / iOS 26.6.1): «Cliente guardado» se escucha completo;
  al volver sigue anunciando «Cerrar sesión, botón». El anuncio completo queda confirmado por reporte;
  el defecto de foco sigue abierto. Ajuste mínimo posterior: `.accessibilityDefaultFocus($addButtonIsFocused, true)`
  en la raíz del listado, configurando Añadir como destino predeterminado de VoiceOver cuando el sistema
  evalúa foco inicial/de retorno. API nativa iOS 26 verificada en SDK y
  [Apple](https://developer.apple.com/documentation/swiftui/view/accessibilitydefaultfocus(_:_:)).
  Propuesta independiente PASS, sin regresión inevitable identificada; no demuestra corrección runtime.
  Huellas pre/post idénticas de 446 archivos: `eb926847e90b368e7aacb4a64187e5caddee477a7c9c7d9c5ab0c53412e202c1`.
  Se mantienen secuencia de anuncio y ToolbarSpacer del propietario. Build Xcode MCP PASS (8,724 s):
  `BuildProject-Log-20260909-085614.txt`; Navigator/GetBuildLog sin issues, aviso AppIntents en línea 11535.
  Previews listado XXX Large `RenderPreview_result_2026-09-09T065652Z@3x.png` y AX 5
  `RenderPreview_result_2026-09-09T065657Z@3x.png` inspeccionadas, contenido visible. Large falla dos veces
  con la ambigüedad de `__designTimeSelection` en código generado del preview; queda como limitación.
  No cambian geometría ni negocio; tests unitarios no repetidos. Retest de foco pendiente: alta → Añadir,
  cancelación/guardado de edición → fila de origen, desactivación → destino estable. El foco predeterminado
  también debe comprobarse al entrar al listado y durante búsqueda; capturas no acreditan AT. ADR 0022 abierto.

- Reauditoría focal de foco predeterminado PASS estático; 446 archivos idénticos pre/post, SHA-256
  `c0124cf0efc173f2dd9b4922785c1342bd3a128840bc35db8b0f8340237ebbc5`. Defecto de foco pendiente de retest.

- Retest final de alta y cancelación de edición con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  tras guardar el alta el foco queda en la fila del cliente recién creado. El propietario confirma después
  que abrir ese cliente y Cancelar devuelve el foco a la misma fila. Ese destino conserva el contexto del
  alta y se acepta como resultado válido; no se exige desplazarlo a Añadir si iOS restaura la fila creada.
  El anuncio completo «Cliente guardado» ya fue confirmado en el retest anterior. Queda verificado por reporte
  el retorno contextual en estos dos recorridos, sin audio/Inspector ni atribución causal del comportamiento
  a un modificador concreto. No se extrapola a guardado de edición, alta cancelada, desactivación o búsqueda.
  Siguiente prueba: modificar un campo opcional, Guardar con VoiceOver y comprobar anuncio, foco y valor al reabrir.
  Solo documentación; build/tests N/A. ADR 0022 y 08.3 siguen abiertos por el resto de evidencia pendiente.

- Guardado de edición con VoiceOver confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  modifica Localidad, guarda, escucha «Cliente guardado» completo, vuelve el foco a la misma fila y al
  reabrir se conserva el cambio. No se registra el valor introducido. Resultado por reporte, sin audio ni
  Inspector; no acredita otros recorridos. Siguiente prueba: apertura y recorrido de la confirmación de
  desactivación con VoiceOver, sin ejecutar todavía la acción destructiva. Build/tests N/A, documentación.

- Confirmación de desactivación con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): al abrirla
  anuncia «alerta», lee título, contenido y «Desactivar, botón». Tras pedir cancelar mediante el gesto de
  escape, el propietario informa foco en «Desactivar cliente, botón» del formulario. Se acredita la lectura
  del diálogo y el retorno al control de origen tras cancelar; no se infiere desactivación efectiva ni
  eliminación del cliente. Siguiente prueba: confirmar la desactivación del cliente de prueba y comprobar
  anuncio, desaparición de su fila y destino del foco. Reporte sin audio/Inspector; build/tests N/A documental.

- Desactivación y estado vacío con VoiceOver (propietario, 09-09, iPhone 14 / iOS 26.6.1): confirma
  «Cliente desactivado» completo y, al volver, escucha «Los clientes aparecerán aquí cuando estén disponibles».
  Después de abrir Añadir y cancelar sin rellenar, informa «No hay clientes». Desde ese estado confirma
  que alcanza Añadir cliente con tres deslizamientos a la izquierda y puede abrirlo de nuevo. Son destinos
  contextuales válidos para una lista vacía; no se exige retorno a Añadir. El estado vacío comunicado tras
  desactivar es coherente con la retirada del último cliente; no se infiere inspección de persistencia.
  Reportes sin audio/Inspector; búsqueda con VoiceOver y resto de tecnologías/criterios siguen pendientes.
  Siguiente prueba: búsqueda con coincidencia y sin resultados sobre un cliente de prueba.
  Build/tests N/A: actualización documental, sin cambios de código ni cierre de subfase.

- Búsqueda con VoiceOver confirmada por el propietario (09-09, iPhone 14 / iOS 26.6.1): crea un cliente
  de prueba, busca parte del nombre y alcanza/abre su fila sin dificultad. Al introducir una consulta sin
  resultados escucha «Sin coincidencias»; al borrar la consulta vuelve a aparecer el cliente. Se verifica
  por reporte búsqueda con coincidencia, anuncio de ausencia y restauración de resultados; no se infiere
  foco concreto tras cada cambio ni ausencia de interrupciones no reportadas. Sin audio/Inspector.
  Continúa la comprobación del rotor por encabezamientos. Build/tests N/A, actualización documental.

- Rotor VoiceOver por encabezamientos confirmado por el propietario (09-09, iPhone 14 / iOS 26.6.1):
  dentro del formulario encuentra «Editar cliente» y se anuncia como encabezamiento. Se acredita este
  recorrido del rotor, no todos sus modos ni encabezamientos de otras pantallas. Reporte sin audio/Inspector.
  Continúa Control por voz en el listado; no se extrapola evidencia entre tecnologías de asistencia.
  Build/tests N/A: actualización documental, sin código ni cierre del gate ADR 0022.

- Control por voz iniciado por el propietario (09-09, iPhone 14 / iOS 26.6.1). «Mostrar nombres» en
  listado expone «Añadir cliente», «campo de búsqueda» y el nombre del cliente sobre su fila. Al abrir
  Añadir por voz, el formulario muestra Cancelar, Guardar y etiquetas de campos con obligatorio/opcional,
  según reporte hasta el final. Se omiten valores de clientes del registro. Confirma después alta completa
  usando solo voz: activar Nombre obligatorio, dictar nombre de prueba, activar Guardar y aparición en listado.
  Se acreditan nombres y operación de ese recorrido, no edición/cancelación, búsqueda ni desactivación por voz.
  Sin audio/Inspector. Siguiente prueba: abrir, editar un campo opcional y cancelar por voz, comprobando descarte.
  Build/tests N/A documental; ADR 0022 sigue abierto, sin extrapolar evidencia a otras tecnologías.

- Control por voz, edición cancelada y desactivación (propietario, 09-09, iPhone 14 / iOS 26.6.1):
  confirma abrir el cliente, introducir Localidad, Cancelar y comprobar al reabrir que el cambio se descarta.
  Confirma también desactivación por voz, incluida la confirmación, y desaparición del cliente del listado,
  todo a la primera. Se completa el muestreo representativo de Control por voz: identificación, alta,
  entrada, edición/descartado y acción destructiva confirmada. Sin audio/Inspector; no se atribuyen otros
  recorridos no ejecutados. El propietario pide rigor proporcional y evitar pruebas repetitivas.
  Plan restante agrupado: Inspector y variantes/preferencias pendientes; recorrido breve de teclado y
  Control por botón cuando se disponga de esa configuración; estados de fallo/carga conservan su límite
  de fixture. No repetir CRUD completo con cada tecnología ni todas las combinaciones visuales. R07 se
  actualiza con la evidencia física AX 5 ya comunicada. ADR 0022 permanece abierto sin convertir pendientes
  en Pasa ni N/A por reducir repeticiones. Build/tests N/A: documentación únicamente.

- Teclado del Mac en Simulator (propietario, 09-09): no dispone de teclado externo para el iPhone físico.
  Se indicó iPhone 17e / iOS 26.5, conectar el teclado del Mac y activar Acceso total mediante teclado
  dentro de iOS. En ese contexto guiado informa que Tab o cursores hacen aparecer el primer foco, pero
  para avanzar usa los cursores; alcanza todas las acciones. Confirma después abrir Añadir con teclado,
  escribir un nombre, activar Cancelar, volver al listado y continuar moviendo el foco sin dificultad.
  Muestreo representativo de navegación, foco visible, entrada y salida completado por reporte. No se
  atribuye al iPhone físico ni a todos los recorridos de Full Keyboard Access; ajustes no inspeccionados
  directamente por el orquestador, sin captura/Inspector. No repetir CRUD por teclado. Control por botón,
  Inspector y adaptación/preferencias conservan sus pendientes. Build/tests N/A documental; ADR 0022 abierto.

- Control por botón, muestreo representativo (propietario, 09-09, iPhone 14 / iOS 26.6.1): tras la
  configuración guiada de pantalla completa/seleccionar ítem y exploración automática, observa dos grupos:
  Cerrar sesión/Añadir/Buscar y las pestañas. Confirma entrar al grupo, abrir Añadir, recorrer el formulario
  incluido Cancelar y volver al listado. Se acredita por reporte exploración, selección, apertura y salida
  sin bloqueo; no se infiere entrada de texto, confirmación destructiva ni todos los recorridos de esta AT.
  Sin audio/Inspector. No repetir CRUD con Control por botón. Sigue una prueba combinada de preferencias
  visuales y movimiento. Build/tests N/A documental; resto de evidencia ADR 0022 permanece abierto.

- Preferencias combinadas confirmadas por el propietario (09-09, iPhone 14 / iOS 26.6.1): tras indicar
  Aumentar contraste, Reducir transparencia, Diferenciar sin color y Reducir movimiento simultáneamente,
  confirma listado y apertura/cancelación del formulario legibles, botones utilizables y transiciones sin
  problemas. Muestreo conjunto por reporte; no acredita medición de ratios, cada combinación ni inspección
  directa de ajustes. Se indicó restaurar preferencias habituales al terminar; restauración no confirmada.
  Continúa adaptación mínima en iPad (ADR 0026 conserva iPad adaptativo); Inspector y otras variantes no
  observadas conservan límites. Build/tests N/A documental; sin cambios de código ni cierre de subfase.

- Adaptación iPad confirmada por el propietario (09-09): listado/formulario correctos en todas las
  orientaciones probadas y en la ventana más pequeña permitida, incluidos recorrido de campos y acceso a
  Cancelar/Guardar. La inspección CUA posterior identifica el simulador real como iPad Air 11-inch (M4),
  iOS 26.5 (se había sugerido Pro 11; no se atribuye el resultado a ese modelo). Captura CUA muestra la
  ventana estrecha en landscape con Editar cliente, Cancelar/Guardar y campos finales/Desactivar visibles,
  sin solapamiento observado. Tamaño exacto de ventana no medido; no demuestra RTL ni todas las variantes.
- Nuevo intento Accessibility Inspector (Xcode.app, no beta), 09-09: seleccionada Fran DEV en el simulador,
  Run Audit no proporciona filas ni captura. El modo Inspection tampoco obtiene elemento/propiedades al
  usar el puntero sobre el formulario. Se desactiva el puntero y se deja la pestaña Audit con Fran DEV.
  No se interpreta vacío como cero incidencias. Pendiente comprobación manual de Run Audit por el propietario;
  no se modifica código ni se repiten recorridos funcionales. Build/tests N/A documental; ADR 0022 sigue abierto.

- Inspector, 09-09, capturas del propietario entre 18:55 y 19:02: ya se obtienen informes.
  Audit 1, ventana mínima: cuatro avisos de contraste y uno de Dynamic Type, con resaltados fuera
  de la ventana; atribución no confirmada. Audit 2, ventana ampliada: tres avisos de contraste
  (1,00: #000200/#000100; 1,01: #2B2B2D/#2C2C2E; 1,49: #2C2C2E/#000300) y uno de texto
  potencialmente inaccesible. Los resaltados corresponden a fondo superior, Calle y número,
  Desactivar cliente y Jornada detrás del modal, respectivamente. Los nueve avisos del Inspector
  son el agregado de ambos informes, no nueve hallazgos nuevos. El segundo no reproduce el aviso
  Dynamic Type; no se interpreta como corrección acreditada.
  Inspection confirma Desactivar cliente con nombre, rol botón, acción Activate y jerarquía dentro
  del formulario modal. El ratio informado no incluye el rojo del texto y no acredita su contraste
  real. Inspection no recupera propiedades del aviso Calle y número. Atribución y medición real
  pendientes; no se descartan avisos como falsos positivos ni se cambian colores por estas capturas.
  Evidencia original local: Desktop/Captura de pantalla 2026-09-09 a las 18.55.27.png y serie
  19.01.01.png–19.02.56.png. Sin cambios ejecutables; build/tests N/A documental.

- Corrección focal autorizada 09-09: `ClientFormContent` aplica `.foregroundStyle(.errorInk)`
  únicamente al texto Desactivar cliente. Conserva rol destructivo, acción, disabled y 44 pt.
  Revisión independiente previa y final estática: PASS. Ratios del asset frente a blanco/#2C2C2E:
  normal 6,57/5,00:1; contraste incrementado 9,12/6,89:1. No son una medición del modal final.
  Build Xcode MCP PASS (9,115 s), log BuildProject-Log-20260909-191906.txt; persiste aviso
  AppIntents metadata extraction skipped, línea 10886, sin errores. Previews Edit long profile
  Light/Dark generados e inspeccionados: RenderPreview_result_2026-09-09T172001Z@2x.png y
  RenderPreview_result_2026-09-09T172016Z@2x.png. Texto completo; muestreo ICC convertido a sRGB
  consistente con ErrorInk. El preview oscuro usa #1C1C1E, distinto del modal #2C2C2E.
  Sin repetir tests de negocio ni CRUD por un delta de color. Retest visual del modal actualizado
  pendiente; no cierra los otros avisos Inspector ni ADR 0022. Sin commit/push.

- Retest visual del propietario, 09-09 a las 19:23: confirma «Se ve bien» tras ejecutar la
  corrección. Captura local `/Users/jesusf/Desktop/Captura de pantalla 2026-09-09 a las 19.23.57.png`:
  Desactivar cliente completo y legible sobre la superficie oscura del formulario. Retest visual
  focal completado; no se repite la acción destructiva. No acredita nueva auditoría Inspector
  ni cierra los restantes avisos o la puerta general ADR 0022. Build/tests N/A documental.

## Reconciliación previa a commit/push — 2026-09-09

- El propietario autoriza publicar tras reconciliar evidencia, triar Inspector y revisión final.
- Snapshot y matriz actualizados: R03–R08 tienen muestreo representativo; no son pendientes globales.
- Triaje por aviso, RTL sintético y límites reales constan en el cierre del registro accesible 08.3.
- Dos revisores independientes sin nuevos defectos ejecutables; 446 archivos pre/post idénticos,
  SHA-256 `da8d69ef75a69414034f8db18df2cde9ca03f17848f4b9088c51f673aa590f14`.
- Se excluye del commit el único cambio temporal del scheme Develop (fixture signed-out activada),
  conservándolo localmente para no alterar la sesión. ToolbarSpacer del propietario se incluye.
- La publicación no cierra ADR 0022: R09 con AT y medición completa no textual/objetivos siguen limitados.
  PLU-37 permanece In Progress; no PR/merge/Done/08.4/live.

## Siguiente puerta

Completar la evidencia accesible pendiente de 08.3. Implementación, auditorías y regresión focalizada
disponibles; subfase abierta según ADR 0022. Commit/push de 08.2 ya completados; entrega de 08.3 y subfases posteriores
separadas. Commit/push de implementación 08.3 completados en `553394833376c565ee0a259e35b931e283e59948`;
remoto `codex/plu-37-phase-08-3-client-screens` verificado idéntico. 24 archivos publicados; fixture local excluida.
PR, merge, cierre y live no autorizados.

Reauditorías documentales finales PASS; huella de 446 archivos idéntica pre/post:
`cf1610776435e4981e72eed52e47366073664c9f645f30c18baa52a1876a5e4d`. Gobernanza y staged diff-check PASS.

Pruebas focales posteriores: cancelación táctil de Añadir confirmada por propietario. Autorrelleno
ofrece sugerencias/menú, pero selección en ficha de Contactos no inserta; causa no determinada.
Propósitos semánticos de campos inspeccionados y coherentes; inserción automática aún pendiente.

Autorrelleno: propietario confirma inserción al tocar la sugerencia del teclado. Vía nativa de
sugerencias operativa; incidencia del selector Contactos separada, sin causa atribuida.

Preparación temporal autorizada de fallo de guardado (09-09): únicamente factoryComposed dentro de
FRANALONSO_AUTH_FIXTURE; primer guardado por formulario espera 3s cancelables y falla antes de escritura,
segundo usa adaptador original. No cambios live/Views/Domain. Backup byte a byte en
`/tmp/fa083-before-save-failure-AppDependencies.swift`, restaurar después de sesión; NO publicar harness.
Propuesta y revisión independiente final PASS; huellas pre/post verificadas. Build MCP PASS8,958s,
log200846, aviso AppIntents10912. Snippet de verificación: primer intento no compila por importFoundation
omitido; segundo con imports corregidos agota timeout60s. No acredita conteos/resultado runtime.
Pendiente prueba guiada VoiceOver de guardado/fallo/reintento. No cubre fallo de carga inicial.

Retest VoiceOver del fallo de guardado: propietario escucha «No se ha podido completar la operación.
Inténtalo de nuevo». Confirma nombre conservado y segundo Guardar exitoso, anuncio Cliente guardado,
retorno al listado con una sola fila. Guardado fallido y recuperación acreditados por reporte manual;
no se extrapola a fallo de lectura inicial, desactivación ni conteos internos de la cola.
Harness temporal retirado: AppDependencies.swift restaurado byte a byte al backup y HEAD.
La app ya instalada mantiene el harness hasta la siguiente ejecución de la versión restaurada.

Medición runtime iPad20:24–20:26: cuatro apariencias, Desactivar5,001/6,548/9,125/5,960:1,
etiquetas≥12,058:1 e iconos≥5,206:1 en muestreo ICC. HitRegion activado sin avisos en viewport final.
Informe aún con1contraste bajo toolbar,2DT y2detección; no conformidad global. Apariencia restaurada.
Detalle y límites en registro accesible, sin cambio ejecutable.


### Reconciliación posterior a pruebas focales — 2026-09-09

Cancelación táctil de Añadir, inserción por sugerencia y fallo de guardado/reintento con VoiceOver
completados. Harness retirado y versión restaurada relanzada. Matriz R09 actualizada: lectura inicial
fallida/Reintentar sigue sin evidencia runtime. Contraste Desactivar/etiqueta/icono postal suficiente
en cuatro apariencias. Inspector: detecciones del formulario corresponden a Jornada/Catálogo bajo
modal; listado sin Contrast/Hit Region/Element Detection, seis Dynamic Type por atribuir. Pendientes
concretos y revisión independiente en la reconciliación vigente del registro 08.3; no repetir recorridos
manuales completados. No cambios ejecutables ni nueva autorización de PR/merge/cierre.

Atribución del listado completada: cinco etiquetas de sidebar y fila cliente. Revisión focal independiente
sin nuevo defecto ejecutable; huella de 446 archivos estable. Pendientes: lectura inicial fallida/Reintentar
con VoiceOver y comprobaciones del agente de escalado sidebar/fila, buscador/foco y geometría toolbar/
confirmación. Reutilizar estilos equivalentes. No repetir las pruebas manuales ya acreditadas.


### Bloque 1 — 2026-09-09 23:50–23:58

Escalado sidebar/fila confirmado mediante dos incrementos y restaurado. Buscador6,97:1, icono15,88:1,
error5:1; superficies visibles toolbar44pt/confirmación48pt. Capturas/mediciones en registro08.3.
Nuevo dato por disponer: rojo nativo del diálogo4,11:1; falta verificar tipografía/clasificación antes
de corregir. Foco de teclado sin captura válida con CUA; no confundir overlaysInspector. No cambios
ejecutables ni datos; app en listado, preferencias restauradas. Bloque1 aún no globalmente aprobado.

Revisión focal independiente confirma muestreo de escalado/geometría suficiente y conserva potencial
P2 contraste nativo4,11:1 hasta acreditar tipografía grande o corregir. Foco: solicitar únicamente
captura de Añadir enfocado sin Inspector; no repetir navegación. Huella446 idéntica, gobernanza PASS.


### Foco de teclado — 2026-09-10

Propietario aporta tres capturas; primera acredita foco Añadir solicitado. Medición ICC→sRGB: banda
3,577:1 exterior/4,271:1 interior; banda oscura8,862:1 exterior. Petición de captura resuelta, sin
repetir recorrido. Las otras dos aportan contexto, no resuelven tipografía/contraste oscuro del diálogo.
Pendientes: disposición de contraste nativo y prueba VO de lectura inicial/Reintentar.


## Corrección de contraste de confirmación — 2026-09-10 00:54

Xcode Debug View Hierarchy expuso el UILabel de Desactivar: .SFUI-Medium 16 pt, systemRedColor.
El ratio oscuro previo 4,113:1 no alcanza 4,5:1; queda confirmado el defecto y sustituida la
incertidumbre tipográfica anterior. Una prueba mínima de foregroundStyle en confirmationDialog
fue ignorada por el sistema y retirada antes de implementar la alternativa revisada.

ClientFormScreen presenta ahora ClientDeactivationConfirmationView en popover nativo, con adaptación
vertical a sheet, Cancelar explícito, rol destructivo y colores opacos ErrorInk/Surface. Reutiliza
recursos, estado y operación existentes. Foco inicial limitado a VoiceOver, título encabezamiento,
labels pulsables de altura mínima 44 pt más padding y contenido desplazable cuando falta altura.
Propuesta y revisión estática final independientes por close083_accessibility: PASS. El revisor
no escribió archivos ni operó UI; no se aporta digest pre/post completo para esta segunda revisión.

Build Xcode MCP PASS 13,683 s, log BuildProject-Log-20260910-005002.txt; único warning encontrado:
AppIntents metadata extraction skipped, ya existente. No se afirma cero warnings globales.
Previews renderizadas e inspeccionadas: Large Light, AX 5 Dark, XXX Large Light Increased Contrast,
Large Dark Increased Contrast; texto sin truncamiento. Artefactos RenderPreview_result_2026-09-09T
225036Z, 225045Z, 225143Z y 225144Z (@3x.png), directorio ActionArtifacts/default/RenderPreview.
Ratios calculados de los assets opacos ErrorInk/Surface: Light 5,244; Dark 5,001; Light High 7,367;
Dark High 8,411. Estas medidas de recursos y previews no son auditoría Inspector del nuevo popover.

Runtime iPhone 17e/iOS 26.5, sesión sintética: encabezamiento, mensaje y ambos botones expuestos;
Cancelar conserva formulario y datos; reabrir y confirmar cierra formulario y vuelve a No hay clientes.
Captura nativa: /Users/jesusf/Desktop/Simulator Screenshot - iPhone 17e - 2026-09-10 at 00.53.40.png.
Pendiente VoiceOver focal del nuevo modal (entrada, Cancelar/retorno y confirmación/anuncio), además
R09 lectura inicial fallida/Reintentar. No repetir CRUD completo ni el fallo de guardado ya validado.
Fixture signed-out del scheme permanece local. Sin PR, merge, cierre ni avance de subfase.


## Corrección de posición tras IMG_1250 — 2026-09-10

El propietario rechaza la disposición del popover: arriba a la izquierda, sobre la barra del formulario.
La comprobación anterior de contraste/semántica no acreditaba una presentación visual adecuada.
Sustituido por sheet nativa con detents medium/large y large para tamaños de accesibilidad, ancho
flexible y alineación superior. Mantiene colores, roles, Cancelar, escape y operación existente.
Propuesta independiente focal PASS. Build MCP PASS 8,469 s, BuildProject-Log-20260910-082837.txt;
único warning encontrado AppIntents metadata ya existente. Previews de presentación real inspeccionadas
062920/062928: hoja inferior estándar y hoja grande AX5; en AX5 contenido desplazable para acciones.
No se acreditan todavía presentación iPad, cierre interactivo ni retorno/anuncios VoiceOver de la sheet.
IMG_1250 muestra foco en encabezamiento del popover anterior; no extrapolar ese foco a esta versión.
Siguiente paso: confirmar apariencia corregida y retest VO focal; R09 lectura/reintento sigue pendiente.


## Jerarquía, botones y altura tras IMG_1251 — 2026-09-10

El propietario rechaza título poco destacado, botones sin delimitación y vacío inferior de la sheet.
Corregido en ClientDeactivationConfirmationView: título title2 bold, botones headline delimitados
por contornos redondeados y área mínima de 52 pt. Cancelar usa borde TextSecondary y Desactivar
ErrorInk sobre Surface. Ratios calculados contra Surface (Light/Dark/Light High/Dark High):
borde Cancelar 4,555/5,206/10,042/11,183; borde Desactivar 5,244/5,001/7,367/8,411.

La prueba de form.fitted aislado no redujo la altura de iPhone. Se usa onGeometryChange sobre
contenido intrínseco con padding para detent height, estado exclusivamente visual redondeado;
AX conserva large y ScrollView. No se añade lógica de negocio ni tests unitarios de geometría.
Fuente Apple consultada: https://developer.apple.com/documentation/swiftui/view/presentationsizing(_:).
Build MCP085713 PASS7,232 s; único warning encontrado AppIntents metadata previo. Preview normal
Dark065745 inspeccionada: hoja compacta, título jerárquico y botones delimitados. Los overrides
sobre una sheet no acreditan AX5 si la captura conserva el tamaño normal; no inferir por el nombre.
Propuesta y revisión estática final independientes PASS. Huellas pre/post del alcance Swift idénticas:
View07691027ff52aac0c265b166625bbe5345dad9ea37aec5acf201f92cddcb409d;
Screen29a65239af2a59a7b815a3b21f77a9fd2514f1fd9d9d183a37a2032ada216c55.
Pendientes aceptación visual física, adaptación iPad y VoiceOver focal/R09; sin cierre ni entrega.

Preview AX5 explícita065911 inspeccionada: título y contenido grandes sin truncamiento horizontal;
Desactivar queda parcialmente fuera del viewport inicial, con ScrollView declarado. Alcance por
desplazamiento y VoiceOver pendiente de runtime; no se afirma desde esta imagen.


### Ajuste final solicitado: título centrado — 2026-09-10

Propietario acepta la disposición con ajuste de centrado del título. Añadidos exclusivamente
multilineTextAlignment(.center) y frame(maxWidth: .infinity) al título; conserva semántica/foco.
Propuesta focal independiente PASS; build Xcode MCP092935 PASS8,092 s, aviso AppIntents previo.
No repetir pruebas funcionales por alineación. VoiceOver focal/R09 siguen pendientes.


### VoiceOver de confirmación actual — reporte del propietario 2026-09-10

Recorre todos los elementos de la sheet correctamente. Empieza por «Tirador de la hoja, media
pantalla, botón, toca dos veces para cerrar la hoja»; restantes elementos correctos según reporte.
El componente declara presentationDragIndicator(.visible): el tirador pertenece a la presentación
nativa. No se acredita foco inicial en título aunque exista AccessibilityFocusState. El recorrido
por el tirador no bloquea el contenido. No se infiere todavía ejecución del cierre, retorno de foco
ni confirmación/anuncio de la versión actual. Próximo paso focal: Cancelar y retorno al formulario.


VoiceOver, propietario 2026-09-10: Cancelar en la sheet actual cierra únicamente la confirmación
y devuelve el foco a Desactivar cliente del formulario. Confirmado por reporte manual; no acredita
aún confirmar/desactivar y anuncio de esta versión. Siguiente paso focal: confirmar una vez.


### Confirmación efectiva con VoiceOver — propietario, 2026-09-10

Al cerrar la confirmación comienza una locución «cliente desa…» que se interrumpe; después se
cierra el formulario y en el listado escucha «Cliente desactivado» completo y «No hay clientes».
Resultado final, desactivación y retorno contextual confirmados por reporte. Se registra la
interrupción transitoria como observación no bloqueante, sin atribuir causa ni duplicado de éxito.
Inspección actual: una única emisión explícita de éxito en ClientListScreen.restoreFormFocus/onDismiss.
Revisión independiente focal read-only: no defecto adicional demostrado; no modificar sincronización
ni repetir el recorrido cuando el resultado final completo y el destino están confirmados.
R09 lectura inicial fallida/reintento sigue pendiente. Solo documentación; build/tests N/A.


### R09 preparado para prueba guiada — 2026-09-10 12:43

Autorización «preparala entonces». Harness TEMPORAL en App/AppDependencies+ClientForm.swift:
InitialReadFailureRepository privado, aislado por actor, falla primer client(id:) por formulario
con persistenceUnavailable y luego delega. Task.checkCancellation precede al consumo del fallo.
Gates FRANALONSO_AUTH_FIXTURE + ApplicationLaunchPlan.authenticationFixture. Lista y adapter
mutador intactos; alta normal, abrir edición produce error y Reintentar carga perfil existente.
No valida VoiceOver por sí mismo. Propuesta independiente PASS; prueba manual pendiente.

Xcode MCP27: Develop, iPhone14 de Jesús/iOS26.6.1, SDK27, argumento signed-out activo.
Build124238 PASS8,429s, único warning encontrado AppIntents metadata previo. RunProject124255
PASS3,577s, app lanzada PID15053. No se modifican plist/pbxproj locales ajenos ni scheme.

Restaurar únicamente AppDependencies+ClientForm.swift tras la prueba y recompilar:
original /tmp/franalonso-r09-clientform-original.swift
SHA256 25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182.
Harness preparado SHA256 7890ff55aab238baf41afbf4ba123606a50fceff42b6e75df081bbe70531ad28.
Excluir este archivo temporal de cualquier entrega; comprobar que no hay cambios posteriores ajenos
antes de restaurar. No commit/push/PR/cierre/live.


### R09 confirmado y harness retirado — 2026-09-10 12:55

Propietario confirma Reintentar → campos cargados con datos y recorribles por VoiceOver; Cancelar
→ listado con foco en el cliente abierto. Recorrido R09 de lectura fallida/reintento/retorno confirmado
por reporte manual, sin atribuir anuncio inicial exacto no transcrito. No repetir prueba.

Harness restaurado byte a byte desde copia verificada: AppDependencies+ClientForm.swift SHA original
25763a3b9599762d05b243946f3af8a0d8d82b07a97f2162dffdcbcc60708182, diff contra HEAD vacío.
Mejora visual prometida tras IMG1252: Reintentar usa primaryActionStyle existente (cápsula rellena),
conserva texto, minHeight44, acción y disabled. Ratios de assets OnBrandPrimary/BrandPrimary
4,945/9,812/10,554/12,280. Propuesta y revisión final focal read-only PASS.
Build MCP125405 PASS8,46s, warning AppIntents previo. Preview Load failure12:55:29 inspeccionada,
iPhone18Pro/iOS27, control visiblemente delimitado; primer render agotó tiempo y reintento pasó.
RunProject125546 PASS8,152s en iPhone14: app relanzada sin inyección del error.
Solo resta reconciliar evidencia/límites y entrega autorizada; no se declara subfase cerrada.
Los enlaces históricos a artefactos eliminados siguen pendientes de reconciliación documental.

## Entrega de correcciones autorizada — 2026-09-10

El propietario autoriza revisar el diff, commit y push. Alcance: ClientFormScreen, ClientFormContent,
ClientDeactivationConfirmationView, tres registros documentales y CHANGELOG. Configuración local
plist/pbxproj/scheme excluida; harness fuera del diff. Se conservan build125405, ejecución125546,
auditorías focales y evidencia manual ya obtenidos: no hay código nuevo desde esas validaciones.
Gobernanza y diff-check se repiten para la entrega. Hash y remoto se verifican tras publicar en Linear;
este registro queda identificado por su propio commit. Sin PR, merge ni cierre de PLU-37.

## Entrega de configuración autorizada — 2026-09-10

Tras publicar69acaa4, el propietario solicita commit/push de la configuración pendiente para dejar
el árbol limpio. Solo quedan plist y pbxproj; el scheme ya coincide con HEAD, sin intervención en
esta entrega. Se conserva el traslado de CFBundleDisplayName y NSFaceIDUsageDescription a las cuatro
configuraciones del target; valores idénticos, sin nuevos permisos ni cambios de privacidad.

Revisión independiente read-only de estándares PASS: equivalencia estática de las cuatro
configuraciones y plist. Build oficial Xcode MCP141420 PASS4,129s, Develop/Simulator. Lectura del
plist generado: nombre Fran DEV, descripción FaceID original y flags Analytics false/true conservados.
El log incluye el aviso previo de extracción AppIntents; no se afirma cero warnings ni build de
Production. Sin cambio lógico: tests y nueva auditoría UI N/A. Gobernanza y staged diff comprobados
antes del commit. Commit/push autorizados; PR/merge/cierre e inicio08.4 no forman parte de esta entrega.
