# Development Guide

## Jerarquía documental

1. `docs/specs/01_constitution.md`: reglas estables.
2. ADR aceptados: decisiones y motivos.
3. Spec activa: alcance y resultado esperado.
4. Skills: procedimiento bajo demanda.
5. `docs/Progress.md` y `docs/progress/`: estado y evidencia.
6. Linear: operación; Git/PR: entrega verificable.

## Inicio de subfase

Usar `$franalonso-start-subphase`.

La puerta de inicio comprueba instrucciones, spec y ADR aplicables; Git; configuración real; Xcode MCP; Linear;
baseline; alcance exacto; alternativas; riesgos; tests y fuentes primarias. Un revisor independiente read-only valida la
propuesta antes de código ejecutable. La aprobación del propietario se refiere solo al alcance presentado.

## Implementación

- Aplicar TDD cuando cambie comportamiento: RED focalizado, implementación mínima, GREEN y regresión afectada.
- Usar `$ios-development-standards` para reglas iOS aplicables y `$ios-accessibility-implementation` por cada pantalla.
- Mantener Views declarativas, Domain puro, Data reemplazable y composición en App.
- Detenerse antes de dependencias, ADR, excepciones unsafe, activación live o ampliaciones no aprobadas.
- Documentar solo contratos semánticos y separar limpieza histórica de cambios funcionales.

## Validación

- Código/configuración: Xcode MCP para build, tests y diagnósticos; nunca `xcodebuild`.
- SwiftUI: descubrir variantes con Xcode MCP y revisar las pantallas afectadas en `Large`, `XXX Large` y `AX 5`
  cuando estén soportados, también para entrega funcional. Seleccionar estados/apariencias representativos; ADR 0029
  permite aplazar la matriz exhaustiva restante. Reutilizar evidencia aceptada y repetir según impacto.
- Accesibilidad: mantener la matriz de ADR 0022 y distinguir entrega funcional para demo y cierre integral según
  [ADR 0029](ADRs/0029-progressive-accessibility-validation.md). En demo, revisión focal y deuda vinculada; en cierre
  integral, toda evidencia aplicable, incluidas comprobaciones manuales no demostrables por snapshots.
- Documentación: enlaces, índices, formatos, diff y scripts de gobernanza; Xcode puede ser `N/A` justificado.

## Revisión especializada

- Ejecutar el agente read-only `$franalonso-review-ios-standards` después de cambios de implementación.
- Ejecutar en paralelo `$franalonso-review-accessibility` cuando cambien SwiftUI, previews, recursos visuales, localización o
  accesibilidad.
- Corregir hallazgos válidos o registrar el aplazamiento de accesibilidad permitido por ADR 0029. Repetir solo la
  revisión afectada; ambas si la corrección cruza ámbitos. No aplazar integridad, privacidad o bloqueos del recorrido.
- Si la plataforma no ofrece sandbox read-only, se acepta un fallback operacional: agente nuevo e independiente con
  prohibición explícita de escribir/publicar y huella determinista idéntica de todos los archivos Git tracked y
  untracked no ignorados antes y después. Cualquier cambio, huella no reproducible o auto-revisión invalida el gate.

## Cierre

Usar `$franalonso-finish-subphase` y `docs/PULL_REQUEST_CHECKLIST.md`.

Registrar en `docs/progress/phase-XX.md`: alcance, evidencia RED/GREEN, build/tests/diagnósticos, previews y accesibilidad,
auditorías, cambios documentales, pendiente y bloqueos. Mantener `docs/Progress.md` como snapshot breve y reconciliar
Linear sin confundir implementación, entrega y activación live.

## Definición de terminado

Una subfase puede cerrarse por entrega funcional para demo cuando su alcance aprobado está implementado y validado,
las revisiones no tienen hallazgos bloqueantes para esa entrega, la documentación está reconciliada y se ha realizado
la entrega autorizada. Todo defecto o evidencia accesible aplazado según ADR 0029 debe tener issue vinculada, responsable,
alcance, impacto y disparador de recuperación; el cierre enlaza esa deuda y no declara accesibilidad completa.

La validación integral se retoma al incorporar el feedback de Fran y estabilizar cada flujo. La fase permanece abierta
mientras conserve esa deuda. Antes del primer candidato para uso real deben estar completas las evidencias aplicables
y resueltos los hallazgos, con revisión independiente y las excepciones de producto aceptadas explícitas. Fase 18
verifica la puerta; no es necesario esperar a ella para resolver pendientes. Ni el cierre funcional ni el integral
autorizan por sí solos live o la siguiente subfase.
