# Project Progress

Última actualización: 2026-08-29

## Puerta actual

- Fases 01–06 cerradas. 07.3 está integrada en `main` mediante la
  [PR #5](https://github.com/JFrancoG/FranAlonso/pull/5).
- PLU-25 y PLU-30 están `In Progress`; PLU-26, PLU-27, PLU-28 y PLU-29 están `Done`.
- 07.1 y sus fixtures Develop no-live están entregadas en `074ce5e`. Los motores live continúan inactivos.
- 07.2 está entregada por la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4): implementación `24802e6`,
  handoff `e8eca5a` y cierre documental `fda767b`.
- La PR #5 quedó integrada por rebase: implementación `56133a2` y handoff `266489a`. El gate independiente de 07.3
  pasó sin P0–P3.
- ADR 0025 añade dos errores raíz y hace fail-closed toda fixture inválida. El owner amplía PLU-29 y acepta ADR 0026:
  iPhone queda portrait-only, iPad adaptativo y 1.3.4 se registra `A/No pasa — excepción de producto aceptada`.
- El gate de propuesta 07.4 pasa sin P0–P3 y queda `N/A`/diferido a 12.3–12.4: no existe todavía pantalla de venta,
  estado de Presentation ni consumidor real. No creó issue propio, rama, componente, copy ni test ceremonial.
- El gate de propuesta 07.5 pasa sin P0–P3. PLU-30 y la rama `codex/plu-30-075-app-shell-selection` contienen la
  implementación local aprobada; su entrega remota y 07.6 continúan sin autorizar.

## 07.5 — implementación local validada

- `AppSection` modela exactamente Jornada, Histórico, Clientes, Catálogo e Informes; `AppShellViewModel` posee solo
  `selectedSection` y comienza en `.workday`.
- No se añaden rutas locales sin un segundo destino real, Store, router global, `NavigationPath`, deep links ni
  dependencias. El `TabView`, `.sidebarAdaptable`, cada `NavigationStack` y la integración visual pertenecen a 07.6.
- TDD RED/GREEN con Swift Testing: el focal falló primero por los símbolos ausentes y después pasó 1/1. Se conserva
  solo la expectativa independiente de selección inicial; una asignación seguida de lectura sería tautológica.
- Xcode MCP sobre `FranAlonso-Production` registra 793 tests: 761 pasan, ninguno falla y 32 quedan sin ejecutar por
  `FRANALONSO_AUTH_FIXTURE`. El build final pasa en 8,596 s; build log e Issue Navigator quedan a cero warnings.
- Preview, localización y ADR 0022 son `N/A`: 07.5 no crea ni modifica Views, copy o superficies interactivas. No
  existe actividad Firebase live ni cambio de configuración.
- La auditoría iOS cerró su único P2 al reconciliar la descripción de PLU-25; la repetición afectada pasó sin P0–P3.
  Gobernanza y `git diff --check` pasan; la auditoría de accesibilidad es `N/A` por ausencia de UI.

## 07.3 — entregada

- `LoadingStateView` y `UnavailableStateView` conservan primitivas SwiftUI nativas y acciones caller-owned; sustituyen
  únicamente estados full-content equivalentes de Clientes y la raíz autenticada.
- Las fixtures Develop de acceso local denegado y fallo de observación permanecen desactivadas por defecto, fallan
  cerradas y no alcanzan Firebase live.
- El gate final entregado mantiene 860/860, builds Develop/Production y cero warnings. Su detalle reproducible se
  conserva en [`progress/phase-07.md`](progress/phase-07.md).
- La evidencia ADR 0022 está en
  [`07-3-state-views.md`](accessibility/evidence/07-3-state-views.md): loading queda `A/L` y 1.3.4 `A/No pasa` mediante
  la excepción de producto aceptada en ADR 0026.
- Las auditorías finales iOS y accesibilidad pasaron sin hallazgos P0–P3; PLU-29 está integrado y `Done`.

## 07.2 — entregada

- Los controles compartidos, la coordinación accesible de Login/Session y sus limitaciones nativas aceptadas están
  cerrados en [`07-2-reusable-controls.md`](accessibility/evidence/07-2-reusable-controls.md).
- Las dos `Section` de Login deben seguir separadas para Switch Control. `PrimaryActionStyle` debe conservar
  enabled/disabled y contraste; 07.3 no modifica ninguno de esos riesgos.

## Siguiente acción

1. Mantener PLU-25 y PLU-30 `In Progress` hasta una autorización separada de entrega. No iniciar 07.6 desde este cierre
   local.

## Bloqueos

Sin blocker de código. La entrega de PLU-30 permanece pendiente de autorización explícita. La excepción 1.3.4 está
aceptada, no se presenta como conformidad y su gate runtime/automático pasa. Loading permanece como evidencia limitada
aceptada y PLU-29 no conserva bloqueos pendientes.

El histórico de fases 01–06 se conserva en [`progress/phases-00-06.md`](progress/phases-00-06.md), y el detalle de
fase 07 en [`progress/phase-07.md`](progress/phase-07.md).
