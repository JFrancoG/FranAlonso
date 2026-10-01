# 11.5 — Jornada y detalle operativo

## Inicio y autorización

2026-10-01. El usuario autoriza issue, rama e implementación local11.5.
[PLU-76](https://linear.app/plusprojects/issue/PLU-76), hija de PLU-71, Jesus Franco, In Progress.
Rama `codex/plu-76-workday-screens`; base limpia main/origin `edc2f26b5835f7b2af1d3a364d1c78fe9e00d564`.
Entrega Git, cierre, live y11.6 requieren autorización propia.
Xcode MCP estable: workspace `workspace-PfnUYLlMzY`, Develop/planDevelop/iPhone11.
Target real iOS27.0, Swift6 strict complete, default nonisolated, Swift/Clang warnings como errores.
Baseline562 idéntica a GREEN11.4: `cb84502ae0f20bb078216ecf33b8d93b1598b344848ccc9c7103fec6b2060872`.

## Alcance concreto

- Sustituir el placeholder Jornada por tablero próximas/en curso/pendientes de cierre, usando WorkdayViewModel11.4.
  Conservar operaciones antiguas, clientes opcionales, varias operaciones por cliente y awaitingDocument pagadas.
- Sheet con SaleDraftDestination estable y una única SaleDraftViewModel/Store por sesión. Crear requiere acción
  explícita; abrir una sesión nueva no escribe. El borrador nuevo es sin cliente; asociación/selector no se inventan aquí.
- Editar cantidad y retirar líneas ya capturadas, consultar importes y snapshots; cerrar conserva ediciones aceptadas.
  Descartar es separado, confirmado y solo cierra tras aceptación durable. Inspección progressed exclusivamente lectura.
- Estados carga, vacío, error/reintento y ausencia; errores sanitizados y acciones semánticas en ViewModel.
  Extensiones pequeñas a las fachadas: estado de carga editable, resultado de operación, incremento/decremento acotado
  y proyección de nombres resueltos mediante GetClientUseCase. Ningún segundo Sale/calculation mutable en Presentation.
- AppDependencies compone lectura neutral y factories concretas con el mismo repositorio/actor/signal Sales;
  creación fija identidad/fecha por sesión. Identidad protegida de autenticación sigue recreando la Shell al revocar acceso.
  Cancelar observación al desaparecer permite reabrir pestaña; no llamar close terminal del Workday al cambiar pestaña.
- Controles nativos, texto ES/EN xcstrings, importes Decimal por locale, wrapping Dynamic Type y targets44pt.
  Foco de retorno ligado a sesión: fila origen si sigue visible, botón crear si desaparece; sin timers o bucles.
- Previews con fixtures sintéticas de IDs/fechas fijos, trait compartido PreviewModifier, almacenamiento en memoria local.
  Nuevo escenario Develop `.workday` bajo el gate existente FRANALONSO_AUTH_FIXTURE, desactivado por defecto,
  antes de Firebase, fail-closed ante intenciones inválidas. Los escenarios `.clients` existentes conservan cero ventas.
  El seed Sales usa el materializador local existente y transiciones Domain, sin pending ni activación de clientes demo.

## Límites y alternativas

No selector11.6, descuentos11.7, inicio/progreso/pago11.8, historial11.9, stock12, documentos13, nuevas dependencias,
schema/migraciones, settings/targets, tráfico Firebase o sync. No botones ficticios para acciones todavía no implementadas.
Se mantiene precio/impuesto/nombre capturados sin reconsultar catálogo. Cliente eliminado se presenta no disponible,
sin modificar asociación histórica ni usar UUID como etiqueta.

Se descarta una segunda Store de pantalla y lógica de negocio en Views: las fachadas11.4 ya coordinan aceptación local.
Se descarta reutilizar el seed `.clients` para ventas: rompería el contrato probado de cero ventas de otras pantallas.
Se descarta usar el repositorio preview finito para smoke interactivo: se necesita actor/signal real compartido.
Se prefiere sheet tipada a una ruta con snapshots y Binding con fence de sessionID para evitar dismiss tardío.
El nuevo modo Develop amplía la composición existente, sin crear otro bootstrap o permitir live por typo.
Reversibilidad: retirar pantallas/factories/fixtures; persistencia y motores previos siguen intactos.

## Autoridad y fuentes

Constitución, spec11/index/Progress, Swift policy, Guide/checklist; ADR0011 contextualidad,0016 descarte/causalidad,
0018 baseline inmutable,0022 accesibilidad,0025 fixtures fail-closed,0029 demo funcional y0030 secuencia operativa.
Código real: ServiceListScreen/FormScreen/Row, AppPreviewModifier, AppDependencies, AppShellScreen,
AuthenticationRootScreen, DevelopDemoComposition, ApplicationLaunchPlan, Workday/SaleDraftViewModels y Store11.3.

Fuentes primarias Apple leídas mediante Cupertino:
[task(id:priority:_:)](https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:)):
cancelación automática al desaparecer/reemplazar id, complementada por fences de fachadas y requests;
[AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate):
focus opcional/Boolean, bindings de elementos y petición declarativa. No equivale a evidencia física de VoiceOver.
[PreviewModifier.makeSharedContext](https://developer.apple.com/documentation/swiftui/previewmodifier/makesharedcontext()):
contrato MainActor async throws, utilizado para preparar modelos deterministas de contenido antes del render.

## Archivos y validación prevista

Sales/Presentation: dos Screens, subviews separadas con una conformidad View por archivo y preview propio,
extensions de etiquetas/localización y pequeñas adiciones a los ViewModels. App: composición, Shell,
fixtures/trait y configuración/launchplan de demo aislada. Tests Swift Testing: semántica UI, composición común,
aceptación local y gates de fixture; sin XCTest/XCUITest ni tests que repliquen markup.

TDD RED funcional compilable primero: cantidades acotadas, escritura local observada en tablero y aislamiento
del escenario workday respecto clients/live. Oráculos independientes y posterior lectura con contexto distinto.
Después GREEN focal y regresión completa, builds Develop-for-testing y Production, logs completos sin warnings
Swift/Clang por Xcode MCP. Fuente/configuración congelada para vincular pruebas y auditoría al diff exacto.
Previews Xcode vacío/múltiples clientes/en curso/awaitingPayment/awaitingDocument, ES/EN y Large/XXXLarge/AX5
según overrides realmente expuestos; inspección de snapshots. Smoke Simulator nativo con crear/cerrar/reabrir,
editar/retirar línea, cancelar/confirmar descarte, readonly y volver a pestaña; sin UI tests automatizados.

Revisión PRE independiente read-only obligatoria antes de código ejecutable, seguida de estilo y POST técnico/UI.
Fallback operacional requiere agente fresco no-write/no-publish y JSON completo tracked/nonignored idéntico
antes/después. PRE workday_screens_pre PASS, sin hallazgos: JSON719 íntegro e idéntico certificado por root,
`bb9b3c0bd2134d9b9f5cc8134cacc21cff76562bcf2d65402bc7ff4c5f9ae491`.
ADR0029: gate funcional de demo, no cierre integral. Matriz WCAG22 A/AA con criterios aplicables, evidencia y N/A
razonados; pendientes manuales VoiceOver/Inspector/teclado/contraste/físico tendrán issue vinculada,
Jesus Franco y recuperación tras feedback y antes del primer candidato para uso real. No se declararán resueltos.
Progress/spec/phase y Linear deben reflejar resultados y entrega pendiente; fase11 conserva In Progress.

## Ajuste focal de interacción

Smoke táctil detecta fila nueva con área visible mayor que el hit testing del label Button plain:
el centro de fila no abre, pero el Text hijo sí. PRE independiente workday_ui_post PASS aprueba añadir
`contentShape(.interaction, Rectangle())` después del padding del label, sin cambiar estilo ni intención.
Fuentes Apple: [contentShape](https://developer.apple.com/documentation/swiftui/view/contentshape(_:_:eofill:)),
[interaction](https://developer.apple.com/documentation/swiftui/contentshapekinds/interaction) y ejemplo
[DisclosureGroupStyle](https://developer.apple.com/documentation/swiftui/disclosuregroupstyle).
API iOS15+ compatible con target27.0. Alternativa estilo automático descartada por ampliar efecto visual/interactivo.
Revisión read-only: JSON734 idéntico, `10e684b29fbb6888f58ee0de2106d428161edd4db7dbd900bd326d59074d6e44`.
Corrección de una línea en WorkdaySaleRow, build Develop9.899s PASS; retest táctil PASS y POST UI funcional PASS.


## Resultado técnico local

18 declaraciones/28 variantes nuevas; regresión1.231/1.934 PASS, builds Develop/Production,
17 renders y smoke con retest focal de hit area PASS. POST técnico independiente PASS.
Matriz55 y deuda propia PLU-77 Backlog/Jesus Franco con recuperación antes de uso real.
Fuente final576 `5ee1d8dbf39acb1ddc01d5136b2b8d348b45cbdd802b6b48ecb82327ed0a074b`;
única diferencia respecto a GREEN completo es contentShape de Row, recompilado y retesteado por impacto.
Evidencia y artefactos canónicos en [fase11](phase-11.md). POST UI funcional PASS; no entrega Git/live/11.6.


## Cierre local

POST UI independiente workday_ui_post PASS para demo funcional ADR0029, sin nuevos hallazgos accionables.
Revisión read-only:734 archivos y JSON íntegro antes/después idénticos,
`e194eb3268e1c9a09ae01cec3993c0b2840f6517ba4fac779dff17ebf4f99642`.
Matriz55 conserva37 Aplicable (29Limitado/8Pendiente) y18N/A; deuda integral en PLU-77.
Progress/spec/fase/Linear reconciliados. Sin bloqueos funcionales11.5 ni cambios ajenos;
entrega Git pendiente de autorización, PLU-76/PLU-71 In Progress. No inicia11.6 ni activa live.


## Autorización de entrega

2026-10-01: usuario autoriza commit/push/PR/merge y cierre de PLU-76/rama. Preparación documental y changelog;
fuente/configuración576 idéntica al cierre local validado, sin nueva implementación ni cambios de UI.
Se reutiliza evidencia reciente y sus límites; revisión focal de entrega y resultado Git se registran en fase11.
PLU-77 conserva deuda integral, fase11 sigue activa y11.6/live requieren su gate propio.
