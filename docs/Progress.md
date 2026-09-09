# Project Progress

Última actualización: 2026-09-09

## Estado actual

- Fase 08 activa: [PLU-34](https://linear.app/plusprojects/issue/PLU-34), In Progress.
- 08.1 publicada en `1164c62`; 08.2 en `6473658`. Sin PR/merge/cierre operativo de esas subfases.
- [08.3 / PLU-37](https://linear.app/plusprojects/issue/PLU-37): listado, búsqueda y formulario implementados
  en `codex/plu-37-phase-08-3-client-screens`. Commit/push autorizados tras reconciliación y revisión.
  La publicación no equivale a cierre de subfase: ADR 0022 mantiene límites de evidencia aplicable.
- Composición y ViewModels validados con Xcode MCP: RED/GREEN 20/20, regresión 32 suites/259 resultados;
  corrección del error de nombre RED y GREEN 32/32. Último build PASS 9,115 s, log `20260909-191906`;
  persiste el aviso previo AppIntents de extracción de metadatos. No se afirma cero warnings globales.
- Correcciones validadas: error de nombre al escribir, placeholders/título a texto máximo, anuncios completos
  y retorno contextual del foco, contraste de Desactivar cliente. Se conserva ToolbarSpacer del propietario.
- Evidencia manual representativa: CRUD/búsqueda, VoiceOver, Control por voz, Control por botón, teclado
  en Simulator, texto máximo, preferencias combinadas, orientaciones y ventana mínima iPad.
  iPhone 14/iOS 26.6.1; iPad Air 11-inch (M4)/iOS 26.5. No repetir los recorridos ya confirmados.
- RTL sintético de lista y formulario renderizado e inspeccionado; overrides temporales restaurados.
- Inspector: nueve avisos en dos informes, triados individualmente. Fondo bajo modal y texto bajo barra
  no representan controles plenamente expuestos; primer informe tiene atribución incierta. Rojo corregido
  con evidencia independiente. No se declara informe limpio ni contraste global aprobado.
- Pendientes reales: R09 de carga/fallos asíncronos/reintento con AT y mediciones completas de contraste
  no textual/objetivos. ADR 0026 conserva la excepción de orientación iPhone. Subfase In Progress.
- Revisiones finales independientes sin nuevos defectos ejecutables; reconciliación documental en curso
  de verificación. Preparación de fixture signed-out permanece local y fuera de la entrega Git.

## Evidencia y siguiente paso

Detalle y artefactos en [fase 08](progress/phase-08.md) y
[registro accesible 08.3](accessibility/evidence/08-3-client-screens.md).
Publicar el commit/push autorizado tras verificar documentación y staged diff. PR, merge, cierre de issues,
activación live y comienzo de 08.4 requieren autorización independiente.

## Entregas anteriores

- Fases 01–06: [histórico](progress/phases-00-06.md).
- Fase 07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done. PLU-25 conserva cierre administrativo
  pendiente. Última entrega Swift PR #9 `c8bb283`, cierre documental `99709d1`.
