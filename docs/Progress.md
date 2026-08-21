# Project Progress

Última actualización: 2026-08-22

## Puerta actual

- Fases 01–06 cerradas; la entrega de 07.1 y su fixture no-live están publicadas en `main`/`origin/main` mediante
  `f779f77`.
- El suplemento de ADR 0024 hace alcanzable el error de Clientes sin Firebase live. Su recorrido manual pasa VoiceOver,
  Voice Control, Switch Control, teclado, orientaciones, iPad y ventana estrecha; ya no queda evidencia física pendiente.
- ADR 0023, la fixture no-live, la validación automática y ambos recorridos físicos están completos; no hubo actividad
  Firebase live. AutoFill queda limitado al selector del sistema por ausencia de Associated Domains.
- El suplemento ejecutable fue aprobado explícitamente. Los hallazgos de composición, lifecycle y matriz de compilación
  están corregidos; las reauditorías finales iOS y accesibilidad pasan sin hallazgos P0–P3.
- La aclaración de 07.2 está aprobada: fila y tarjeta compartidas quedan `N/A`/diferidas hasta un consumidor real.
- PLU-28/07.2 conserva inventario y propuesta inspeccionados, sin código ejecutable iniciado.
- Accessibility Inspector permitió corregir el contraste del CTA/prompts y del botón biométrico. Su único aviso final de
  Dynamic Type en sesión no se reproduce: el nodo escala y conserva el texto completo en AX 5.
- El gate técnico, la evidencia manual de ADR 0022 y ambos revisores read-only pasan; queda la entrega autorizada.
- El RED físico AX 5 amplió, con aprobación del propietario, el alcance correctivo a `SessionContent`; la corrección
  adaptativa pasa en iPhone 11/iPhone 14 y en previews soportadas.
- El preflight de 07.2 confirma Xcode MCP y Linear operativos; el vault Obsidian es la raíz del repositorio.

## Baseline verificada

- Validación ejecutable actual en iPhone 17 Simulator/iOS 26.5: `FranAlonso-Develop` compila, 830/830 outcomes pasan y
  no hay warnings Swift/Clang ni issues warning+. `FranAlonso-Production` ofrece el mismo resultado con Firebase 12.18.0.
  Ambos logs contienen solo: `Metadata extraction skipped. No AppIntents.framework dependency found`.
- `main` contiene el cierre funcional de fases 01–06 mediante PR #2; PR #3 fue una entrega de formato separada.
- Los motores de sincronización continúan inactivos; una validación local no autoriza activación live.
- El histórico completo y la evidencia anterior se conservan en
  [`progress/phases-00-06.md`](progress/phases-00-06.md).

## Trabajo en curso

- ADR 0022 `Aceptado`: objetivo interno de accesibilidad nativa basado en correspondencias WCAG 2.2 A/AA aplicables.
- Matriz de criterios, implementación y evidencia de accesibilidad.
- Constitución y documentación operativa reducidas a sus responsabilidades propias.
- Skills de inicio, cierre y accesibilidad; revisores read-only; validadores y hook determinista.
- Linear mantiene PLU-25/PLU-28 en Backlog y PLU-26/PLU-27 en `In Progress`.
- La revisión independiente detectó que PLU-27 debe cortar antes de `FirebaseApp.configure()`, excluirse por compilación
  fuera de `Debug-Develop`, autorizar solo el UID exacto de fixture y cubrir la cadena real completa. La propuesta y el
  ADR 0023 incorporan esas correcciones.
- El fallback de revisión operacionalmente read-only quedó demostrado con agentes frescos, prohibición de escritura y
  huellas completas idénticas. Las pasadas finales iOS y accesibilidad devuelven `Sin hallazgos P0–P3` y `PASS`.
- La implementación de PLU-27 añade una decisión inmutable de arranque, composición Develop aislada, SwiftData en
  memoria, telemetría nula y un `AuthenticationDataSource` determinista; Production excluye todos sus seams propios.

La evidencia detallada de este trabajo y de las subfases 07.x vive en
[`progress/phase-07.md`](progress/phase-07.md).

## Siguiente acción

1. Reconciliar PLU-27/PLU-26 y solicitar autorización de entrega.
2. Tras esa entrega, PLU-28/07.2 podrá solicitar su gate de inicio ejecutable.

## Bloqueos

Login, ambos modos de fixture, AutoFill limitado, sesión restaurada, Face ID, Clientes vacío/error, logout, VoiceOver,
Voice Control, Switch Control, Dynamic Type AX 5 y orientación iPhone pasan; el plan de simulador pasa 830/830. Full
Keyboard Access e iPad/multitarea pasan en Login, sesión protegida y Clientes; 1.4.12 queda `N/A` para SwiftUI nativo.
No quedan bloqueos de evidencia; PLU-27/PLU-26 siguen abiertos hasta la entrega autorizada. El detalle vive en
[`accessibility/evidence/07-1-color-tokens.md`](accessibility/evidence/07-1-color-tokens.md).
