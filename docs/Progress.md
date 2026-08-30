# Project Progress

Última actualización: 2026-08-30

## Puerta actual

- Fases 01–06 cerradas. 07.3 está integrada en `main` mediante la
  [PR #5](https://github.com/JFrancoG/FranAlonso/pull/5).
- PLU-25 y PLU-31 están `In Progress`; PLU-26, PLU-27, PLU-28, PLU-29 y PLU-30 están `Done`.
- 07.1 y sus fixtures Develop no-live están entregadas en `074ce5e`. Los motores live continúan inactivos.
- 07.2 está entregada por la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4): implementación `24802e6`,
  handoff `e8eca5a` y cierre documental `fda767b`.
- La PR #5 quedó integrada por rebase: implementación `56133a2` y handoff `266489a`. El gate independiente de 07.3
  pasó sin P0–P3.
- ADR 0025 añade dos errores raíz y hace fail-closed toda fixture inválida. El owner amplía PLU-29 y acepta ADR 0026:
  iPhone queda portrait-only, iPad adaptativo y 1.3.4 se registra `A/No pasa — excepción de producto aceptada`.
- El gate de propuesta 07.4 pasa sin P0–P3 y queda `N/A`/diferido a 12.3–12.4: no existe todavía pantalla de venta,
  estado de Presentation ni consumidor real. No creó issue propio, rama, componente, copy ni test ceremonial.
- El gate de propuesta 07.5 pasa sin P0–P3. La [PR #6](https://github.com/JFrancoG/FranAlonso/pull/6) integra PLU-30
  por rebase en `a220a3d`.
- El gate corregido de propuesta 07.6 pasa sin P0–P3 y el owner autoriza su alcance exacto. PLU-31 permanece
  `In Progress` en `codex/plu-31-076-adaptive-app-shell`: la implementación local está validada automáticamente,
  las auditorías y ADR 0022 pasan tras reconciliar su evidencia; commit/push están autorizados y PR sigue separada.

## 07.6 — cierre local validado

- `AppShellScreen` compone las cinco secciones en `TabView(selection:)` con `.sidebarAdaptable`; cada sección posee su
  `NavigationStack`, Jornada continúa siendo inicial y Clientes reutiliza su pantalla real. Las otras cuatro raíces
  muestran el estado inerte localizado ya aprobado, sin anticipar features.
- `AuthenticationRootScreen` conserva un único `NavigationStack` para todos los estados no autenticados y extrae solo
  el shell protegido; `.id(session.id)` y la intención de logout permanecen en la frontera Authentication.
- La inspección de preview detectó que labels genéricos de `Tab` expulsaban barra y safe areas en iPhone con
  `XXX Large`/`AX 5`. Usar el inicializador semántico nativo de `Tab` cerró el hallazgo; iPhone y iPad pasan los
  rerenders trazados: `Large`/`XXX Large`/`AX 5` en iPhone y `AX 5` en iPad portrait/landscape, además de las
  apariencias, el contraste y el RTL sintético registrados.
- Xcode MCP final: Develop 815/815 y 22/22 focales; Production 787 pasados, 0 fallos y 6 no ejecutados de 793. Builds
  Develop/Production correctos, cero diagnósticos en los dos Swift afectados y cero warnings en log/Issue Navigator.
- ADR 0022 queda en 29 `Pasa`, 0 `Limitado`, 0 `Pendiente`, 25 `N/A` y la excepción 1.3.4 aceptada por ADR 0026.
  Inspector, VoiceOver, Voice Control, Switch Control, teclado, Touch, foco/rotor, cinco logout, Dynamic Type,
  preferencias, cuatro orientaciones iPad y multitarea mínima están acreditados. Los controles nativos no introducen
  geometría ni color custom; la ausencia de puntero físico no limita 2.5.8.
- Las auditorías iOS y accesibilidad pasan tras corregir únicamente imprecisiones documentales; no quedan P0–P3 ni
  pruebas manuales adicionales para el shell actual.
- No hubo Firebase/Keychain live, persistencia durable, dependencia, ruta ficticia, cambio de target, commit, push o PR.

## 07.5 — entregada

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

1. Mantener PLU-25/PLU-31 `In Progress`; ejecutar solo commit/push y no abrir PR ni iniciar 07.7 sin autorización.

## Bloqueos

Sin blocker de código, auditoría o accesibilidad en PLU-31. La excepción 1.3.4 está aceptada y no se presenta como
conformidad. Loading conserva su limitación aceptada de 07.3.

El histórico de fases 01–06 se conserva en [`progress/phases-00-06.md`](progress/phases-00-06.md), y el detalle de
fase 07 en [`progress/phase-07.md`](progress/phase-07.md).
