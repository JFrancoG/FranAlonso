# Project Progress

Última actualización: 2026-08-21

## Puerta actual

- Fases 01–06 cerradas; 07.1 está aprobada y en implementación local sobre `10e817d`.
- Trabajo activo: catálogo de tokens visuales y corrección de Login implementados; orientación iPhone, Full Keyboard
  Access y targets operables de 44 pt pasan en la validación final de simulador.
- Accessibility Inspector permitió corregir el contraste del CTA y de ambos prompts; la repetición final no presenta
  contraste ni `Hit Region`. Sus cinco avisos genéricos de Dynamic Type no se reproducen en runtime AX 5 de Login.
- Las reauditorías finales de accesibilidad e iOS no detectan P0–P3 en las correcciones. La regresión física del último
  parche pasa; 07.1 queda en espera únicamente por Autorrelleno y flujos autenticados que hoy no pueden ejecutarse.
- Se añadieron recursos visuales, tests, dos input labels accesibles y el par semántico del CTA; no cambian navegación,
  copy ni lógica de negocio.
- Xcode MCP y Linear respondieron en el preflight del 11 de agosto de 2026; el vault Obsidian es la raíz del repositorio.

## Baseline verificada

- Validación ejecutable actual en iPhone 17 Simulator/iOS 26.5: build correcto, 788/788 tests verdes, cero warnings y
  cero issues warning+ con Firebase 12.18.0.
- `main` contiene el cierre funcional de fases 01–06 mediante PR #2; PR #3 fue una entrega de formato separada.
- Los motores de sincronización continúan inactivos; una validación local no autoriza activación live.
- El histórico completo y la evidencia anterior se conservan en
  [`progress/phases-00-06.md`](progress/phases-00-06.md).

## Trabajo en curso

- ADR 0022 `Aceptado`: objetivo interno de accesibilidad nativa basado en correspondencias WCAG 2.2 A/AA aplicables.
- Matriz de criterios, implementación y evidencia de accesibilidad.
- Constitución y documentación operativa reducidas a sus responsabilidades propias.
- Skills de inicio, cierre y accesibilidad; revisores read-only; validadores y hook determinista.
- Linear mantiene PLU-25 en Backlog y PLU-26 en `In Progress`.

La evidencia detallada de este trabajo y de las subfases 07.x vive en
[`progress/phase-07.md`](progress/phase-07.md).

## Siguiente acción

1. Configurar, en un trabajo autorizado separado, un método de acceso y un usuario de pruebas no productivo.
2. Con esa fixture, completar Autorrelleno y los flujos/ventanas autenticados restantes de ADR 0022.

## Bloqueos

Accessibility Inspector post-corrección ya no reproduce el contraste del CTA ni de los prompts. Sus cinco avisos genéricos
de Dynamic Type sobre controles SwiftUI nativos no se reproducen en Login a tamaño AX 5 real: título, labels, campos y
CTA escalan, los dos campos reciben foco y no hay recortes, solapes ni pérdida de controles. 1.4.4 pasa para Login; ambos
simuladores se restauraron después a tamaños ampliados desactivados y 50 %. Full Keyboard Access pasa en ambos sentidos,
con foco visible y activación por teclado. El P1 de Switch Control agrupado se reprodujo antes del parche en iPhone 11/iOS 26.6
(23G5057c) e iPhone 14/iOS 26.6 (23G71). Tras separar ambos campos en dos `Section`, pasa físicamente en los dos modelos
con agrupación activa. La regresión física final en el iPhone 14 pasa también tras ampliar el área operable: VoiceOver
recorre el formulario en ambos sentidos, cada campo recibe y conserva su propio foco, Voice Control activa Email,
Contraseña y Acceder a la primera, y Switch Control los opera por separado con `Agrupar ítems` activo. La validación vacía
muestra el error y devuelve el foco a Email. La limitación de los tests source-backed del destino físico continúa cerrada;
el plan final en simulador pasa 788/788, sin fallos, skips ni casos sin ejecutar. Los campos pasan 9/9 puntos operables
cada uno sobre un marco mínimo de 44 pt y la orientación iPhone admite portrait y ambos landscape. No existe todavía un
método de autenticación configurado ni un usuario de pruebas; por ello Autorrelleno real y los flujos autenticados quedan
en espera sin activar Firebase live ni crear datos fuera del alcance. El detalle se conserva en
[`accessibility/evidence/07-1-color-tokens.md`](accessibility/evidence/07-1-color-tokens.md).
