# Project Progress

Última actualización: 2026-09-10

## Estado actual

- Fase08 [PLU-34](https://linear.app/plusprojects/issue/PLU-34) y subfase08.3
  [PLU-37](https://linear.app/plusprojects/issue/PLU-37) siguen In Progress.
- Rama `codex/plu-37-phase-08-3-client-screens`: base previa verificada en `4527b03`.
  Publicados: 08.1 `1164c62`, 08.2 `6473658`, base funcional08.3 `5533948` y registro `4527b03`.
- **Correcciones incluidas en la entrega autorizada:** nueva sheet de confirmación (altura ajustada, título centrado,
  botones delimitados y contraste), integración en ClientFormScreen, estilo visible de Reintentar y docs.
- Validación lógica histórica: 259/259 resultados en32suites; error de nombre RED/GREEN32/32.
  Último build MCP27 `125405` PASS8,46s y RunProject `125546` PASS8,152s en iPhone14/iOS26.6.1.
  Persiste aviso previo AppIntents; no se afirma cero warnings globales ni ReleaseGate/Production.
- Muestreo manual completado: CRUD, búsqueda, VoiceOver, Control por voz, Control por botón, teclado
  en Simulator, texto máximo, preferencias combinadas e iPad para listado/formulario original.
  RTL sintético inspeccionado. No repetir esas pruebas.
- Nueva sheet: VoiceOver recorre desde el tirador, Cancelar devuelve foco a Desactivar cliente y
  confirmar anuncia Cliente desactivado completo y retorna al listado vacío. Locución parcial previa
  durante transición registrada como observación no bloqueante; causa no determinada.
- **R09 completado:** reintentos de guardado y lectura, datos conservados/cargados y retorno a la fila.
  Ambos harness retirados. AppDependencies+ClientForm.swift coincide byte a byte con HEAD.
  Reintentar usa estilo primario; preview posterior inspeccionada, sin cambio de acción/etiqueta.
- Contraste y foco tienen muestras explícitas en el registro. No se declara Inspector limpio ni
  cobertura total desde las previews. Artefactos locales eliminados están marcados como no disponibles.
- **Comprobación representativa completada:** capturas del propietario de las13:40–13:41 muestran
  listado, formulario y nueva sheet en iPad/ventana estrecha con texto ampliado; al desplazar aparecen
  completos Cancelar y Desactivar. Sin nuevas pruebas manuales pendientes dentro del alcance acordado.
- ADR0026 conserva la excepción aceptada de orientación iPhone. Se mantienen los límites de muestreo
  ADR0022; no se declara conformidad global. El cierre operativo sigue pendiente.
- Correcciones08.3 publicadas en `69acaa4`, remoto verificado. El propietario autoriza también publicar
  el traslado de DisplayName/FaceID del plist a los ajustes del target; scheme ya coincide con Git.
  Revisión independiente PASS; build MCP `141420` PASS4,129s. Plist generado Develop/Simulator
  conserva Fran DEV, texto FaceID y Analytics desactivado. Persiste aviso previo AppIntents.
  ToolbarSpacer conservado. Sin más cambios locales previstos tras esta entrega.

## Evidencia y siguiente paso

Estado y límites reconciliados en [fase08](progress/phase-08.md) y
[registro accesible08.3](accessibility/evidence/08-3-client-screens.md). Revisiones documentales focales
independientes; sin nuevas pruebas lógicas por esta actualización documental.
Commit y push de las correcciones autorizados por el propietario el2026-09-10. El commit que contiene
este registro incluye tres archivos Swift, esta documentación y CHANGELOG; la verificación del remoto
se registra en Linear tras publicar. PR, merge, cierre operativo, live y08.4 quedan fuera del alcance.

## Entregas anteriores

- Fases01–06: [histórico](progress/phases-00-06.md).
- Fase07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done. PLU-25 conserva cierre administrativo
  pendiente. Última entrega Swift PR#9 `c8bb283`, cierre documental `99709d1`.
