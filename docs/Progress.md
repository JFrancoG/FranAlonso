# Project Progress

Última actualización: 2026-09-08

## Puerta actual

- Fase 08 activa: padre [PLU-34](https://linear.app/plusprojects/issue/PLU-34) en `In Progress`.
- [PLU-35 / 08.1](https://linear.app/plusprojects/issue/PLU-35) publicada por commit/push autorizados en `1164c62`,
  remoto `codex/plu-35-phase-08-1-client-crud-search` verificado. Sin PR/merge/cierre; continúa `In Progress`.
- [PLU-36 / 08.2](https://linear.app/plusprojects/issue/PLU-36) implementada localmente, en `In Progress`.
  Rama local `codex/plu-36-phase-08-2-client-view-models` sobre `1164c62`, dependiente de 08.1 aún no integrada.
  Propuesta independiente PASS y aprobación del propietario registradas. Listado con búsqueda/identidad de sesión;
  formulario con validación, guardado contextual, desactivación confirmada y protección frente a respuestas obsoletas.
- La preparación Domain normaliza opcionales; App compone sobre actor y señal existentes. No se duplican escrituras
  ni se retiene ModelContext; tampoco se promete CAS. Las Views quedan en 08.3 y los motores live siguen inactivos.
- Xcode MCP: **26 suites / 208 resultados pasados**, incluidos 40 casos nuevos. Build Develop correcto en 3,958 s;
  resumen MCP/Navigator y seis diagnósticos de producción en cero. El log completo conserva el aviso conocido de
  extracción AppIntents; no se declara cero warnings globales. Fixture temporal restaurada byte a byte.
- Estilo: diez Swift revisados, ajustes de tests corregidos y reauditoría focal limpia. Auditoría final iOS PASS,
  sin hallazgos P0–P3, sandbox read-only y huellas pre/post idénticas de 438 archivos.
  Gobernanza y diff-check pasan. Previews/accesibilidad `N/A`: no cambia ninguna superficie visual o semántica accesible.
- Sin nueva validación Production, suite global o live. Alcance, TDD, artefactos y límites: [fase 08](progress/phase-08.md).

## Entregas anteriores

- Fases 01–06 cerradas; histórico en [phases-00-06.md](progress/phases-00-06.md).
- Entregables de fase 07 integrados: PLU-26–PLU-33 están `Done`. PLU-25 mantiene pendiente su cierre administrativo
  independiente; iniciar 08.1 no lo cierra. Última entrega Swift: PR #9, `c8bb283`; cierre documental en `99709d1`.
- El detalle de entregas, auditorías y accesibilidad permanece en [fase 07](progress/phase-07.md). ADR 0026 conserva
  la excepción de orientación 1.3.4; loading mantiene la limitación aceptada de 07.3. No se declaran nuevas pruebas AT.

## Siguiente acción y límites

El propietario autoriza commit/push de 08.2 e inicio de 08.3 el 2026-09-08; ejecución y verificación en curso.
Firma/consentimiento/activación/foto se mantienen en sus subfases. PR, merge y cierre de issues conservan
autorización independiente. La retención de consentimiento de 08.1 sigue siendo local.
