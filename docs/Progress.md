# Project Progress

Última actualización: 2026-08-24

## Puerta actual

- Fases 01–06 cerradas. 07.3 parte de `main == origin/main == fda767b`, con worktree limpio.
- PLU-25 y PLU-29 están `In Progress`; PLU-26, PLU-27 y PLU-28 están `Done`.
- 07.1 y sus fixtures Develop no-live están entregadas en `074ce5e`. Los motores live continúan inactivos.
- 07.2 está entregada por la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4): implementación `24802e6`,
  handoff `e8eca5a` y cierre documental `fda767b`.
- El gate independiente de 07.3 pasó sin P0–P3 y el owner aprobó el alcance exacto. La implementación permanece local
  en `codex/plu-29-073-content-state-views`; no hay autorización de commit, push, PR, merge ni cierre.
- ADR 0025 añade dos errores raíz y hace fail-closed toda fixture inválida. El owner amplía PLU-29 y acepta ADR 0026:
  iPhone queda portrait-only, iPad adaptativo y 1.3.4 se registra `A/No pasa — excepción de producto aceptada`.

## 07.3 — implementación en curso

- `LoadingStateView` conserva un `ProgressView` nativo y un `LocalizedStringResource` caller-owned. No contiene estado,
  estilo, foco, anuncios ni lógica.
- `UnavailableStateView<Actions: View>` conserva un `ContentUnavailableView` nativo con título, SF Symbol, descripción
  y acciones caller-owned. Su variante sin acciones usa `EmptyView`; los inicializadores de composición viven en
  extensiones del mismo archivo.
- Ambos componentes son Views pasivas sin `@MainActor` explícito, siguiendo el precedente de `FormFieldSection`.
- `ClientListContent`, `AuthenticationRootScreen` y `FranAlonsoApp` sustituyen solo las composiciones full-content
  equivalentes. Estados, transiciones, `List`, copy, símbolos, roles y acciones permanecen en sus propietarios.
- Login y Session quedan fuera: sus indicadores son feedback inline o semántica de sesión validada en 07.2.
- TDD RED/GREEN es `N/A` para esta extracción visual sin lógica. No se añaden tests ceremoniales, XCTest, XCUITest ni
  UI tests.
- La ampliación de fixture sí siguió RED/GREEN con Swift Testing: acceso local denegado atraviesa sesión restaurada,
  unlock, authorizer y logout reales; el fallo de observación termina solo el primer stream por instancia y Retry
  recupera signed-out mediante una segunda observación.
- Con las cinco fixtures restauradas a `NO`, Xcode MCP mantiene cero diagnósticos en los trece Swift afectados y en el
  test final de configuración. El build Develop pasa en 3,034 s, la suite completa en 860/860 y el build Production en
  18,741 s; ambos builds, sus logs y el Issue Navigator quedan sin warnings.
- La matriz de previews cubre Light/Dark, contraste normal/incrementado, Large/XXX Large/AX 5,
  portrait/landscape y LTR/RTL. En el destino iPad Simulator, carga, Clientes vacío/error y raíz/bootstrap quedan
  completos y sin solapes a pantalla completa; el pase runtime bootstrap confirma portrait y landscape en AX 5, y
  Clientes refluye también completo al ancho mínimo de multitarea.
- [`07-3-state-views.md`](accessibility/evidence/07-3-state-views.md) clasifica 55/55 criterios para Clientes y
  raíz/bootstrap. Los recorridos manuales solicitados pasan; loading queda limitado por no disponer de fixture
  suspendida y 1.3.4 queda como excepción de producto `A/No pasa` mediante ADR 0026.
- VoiceOver recorre completos los estados vacío y error de Clientes sin parada redundante para sus SF Symbols. En el
  error determinista, el foco inicial nativo comienza en «Cerrar sesión» y continúa por encabezamiento, título y
  descripción; la app no fuerza el foco de la barra de navegación.
- Voice Control activa «Cerrar sesión» por su nombre a la primera desde el error determinista y vuelve a Login.
- Switch Control resalta solo «Cerrar sesión» en ese estado, no crea objetivos redundantes y lo activa a la primera
  sin trampa, volviendo a Login.
- Full Keyboard Access muestra un marco azul solo sobre «Cerrar sesión»; flechas y Tab no incorporan contenido estático
  al circuito. Espacio lo activa a la primera y vuelve a Login sin trampa.
- El objetivo táctil del logout no cambia y conserva la validación física 07.1; no se repite una medición ajena al diff.
- 4.1.3 detectó que VoiceOver anunciaba solo logout al aparecer el error. Un anuncio textual propio duplicaba después
  el título nativo, tanto con prioridad normal como alta. La solución final publica un único `LayoutChanged` sin texto ni
  destino al transitar a `.failed`: VoiceOver dice el título una vez y conserva foco en logout. Las trazas temporales
  están retiradas; build Xcode MCP correcto en 7,348 s.
- iPhone 11/iOS 26.6.1 en portrait y AX 5 muestra completos el error de Clientes y logout, sin cortes ni solapes y con
  todos los elementos operables. iPad full-size portrait/landscape pasa en previews AX 5; en la ventana de multitarea
  más estrecha, error y logout siguen completos sin necesitar scroll. «Cerrar sesión» responde a la primera, vuelve una
  sola vez a Login y la pantalla de destino conserva todo el contenido completo.
- Accessibility Inspector emitió dos falsos avisos de contraste en Session: al seleccionarlos, los rectángulos quedan
  desplazados sobre el fondo/chrome exterior de la ventana iPad y los pares casi blancos no existen en los tokens de la
  app. El aviso Dynamic Type de Session vuelve a señalar el exterior; los dos de Clientes delimitan las dos líneas del
  título nativo, que está visiblemente escalado y refluye completo en AX 5. Los cinco se cierran como no reproducidos
  como defectos de la app; no se cambia código.
- Los cinco argumentos de fixture de `FranAlonso-Develop` quedan restaurados a `NO` antes del gate automático final.
- El gate ADR 0026 pasa sus tests runtime/source-backed en iPhone e iPad. iPhone permanece en portrait al girar a ambos
  lados y Login sigue completo y operativo. iPad rota en sus cuatro orientaciones; con AX 5, Login, el error raíz con
  Retry y el error de Clientes permanecen completos y operables en portrait, landscape y ventana mínima. El Login
  requiere desplazamiento en el ancho mínimo, sin perder controles. VoiceOver de iPad no se declara validado porque
  Apple no lo ofrece en Simulator; se conserva la evidencia física de iPhone sin extrapolarla.
- La comprobación VoiceOver detectó que el título grande podía conservar su nodo pero perder el glyph tras atravesar el
  loading compartido. `LoadingStateView` vuelve a un `ProgressView` centrado sin scroll; después, Sesión conservó el
  título visible y grande en 3/3 relanzamientos y Clientes también lo mostró correctamente. El hallazgo queda cerrado.
- Las auditorías finales iOS y accesibilidad pasan sin hallazgos P0–P3. Ambas usaron modo operacionalmente read-only y
  comprobaron huellas pre/post idénticas sobre 414 archivos. Confirman las clasificaciones 4.1.3, loading `A/L`,
  VoiceOver iPad no ejecutado y 1.3.4 `A/No pasa` mediante ADR 0026.

## 07.2 — entregada

- Los controles compartidos, la coordinación accesible de Login/Session y sus limitaciones nativas aceptadas están
  cerrados en [`07-2-reusable-controls.md`](accessibility/evidence/07-2-reusable-controls.md).
- Las dos `Section` de Login deben seguir separadas para Switch Control. `PrimaryActionStyle` debe conservar
  enabled/disabled y contraste; 07.3 no modifica ninguno de esos riesgos.

## Siguiente acción

1. Esperar autorización explícita para cualquier commit, push, PR, merge o cierre de Linear.

## Bloqueos

Sin blocker de código. La excepción 1.3.4 está aceptada, no se presenta como conformidad y su gate runtime/automático
pasa. Loading permanece como evidencia limitada aceptada y las auditorías finales pasan. No hay autorización de commit,
push, PR, merge ni cierre.

El histórico de fases 01–06 se conserva en [`progress/phases-00-06.md`](progress/phases-00-06.md), y el detalle de
fase 07 en [`progress/phase-07.md`](progress/phase-07.md).
