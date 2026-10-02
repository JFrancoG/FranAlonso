# 12.4 — Confirmación de stock no bloqueante

## Inicio — 2026-10-02

PLU-90, Jesus Franco, hija PLU-85. Rama `codex/plu-90-sale-stock-confirmation`, base limpia
`main`/`origin/main` `a222513`. Xcode MCP estable Service conectado a FranAlonso; Develop activo.
Swift 6, strict complete, aislamiento por defecto nonisolated, app iOS27, warnings Swift como errores.
Baseline vigente12.3:191/191 regresión +38/38 localización, Develop/Production y auditorías PASS;
no se repite antes de introducir comportamiento afectado.

Autoridades: constitución, spec12, ADR0001/0011,0003,0005,0022/0029 y política Swift propia.
La petición autoriza issue, rama e implementación12.4; no commit/push/PR/merge/Done ni live.

## Frontera encontrada

`SaleDraftViewModel` solo edita borradores; `inspect` recupera estados operativos sin capacidad mutadora.
El Store contiene un único snapshot editable y proyección monetaria/stock; no hay otro Store de venta.
`RegisterSalePaymentUseCase` y aceptación local idempotente existen desde11.8.
No hay acciones visuales para iniciar venta, iniciar/terminar líneas ni cobrar. `SaveSaleUseCase` permite
guardar snapshots, pero no ofrece aceptación de transición con comparación del snapshot esperado.
Conectar cobro de extremo a extremo requiere ese alcance adicional; no se debe ocultar bajo un botón
que solo cierre una alerta o marque una intención sin consumidor.

## Alcance12.4 y aceptación

- Coordinación observable de una solicitud identificada, aviso nativo localizado y confirmación Continuar/Cancelar.
- Mostrar o cancelar no modifica venta, stock, cola ni telemetría. Repetir presentación sigue sin efectos.
- Una confirmación vigente entrega su intención una vez; callbacks viejos, cierre y cambios invalidan solicitudes.
- Stock suficiente no pide confirmación innecesaria; desconocido/fallido nunca se describe como suficiente.
- Sin duplicar reglas: reutilizar `AnalyzeSaleStockImpactUseCase` y el stock del Store.
- Swift Testing: continuar/cancelar/repetir, replay obsoleto, close, cambios de snapshot, stock suficiente/desconocido;
  oráculo de efectos en repositorios aislados, no afirmaciones estructurales.

## Alternativas evaluadas

1. Solo componente/coordinador: alcance estricto12.4, conexión al recorrido de pago declarada pendiente;
   no publicar un falso cobro ni acciones sin efecto en Jornada.
2. Recorrido mínimo completo de Jornada: propuesta adicional de aceptación local de inicio/progreso con comparación
   del snapshot esperado, recuperación y fencing; selección de método y pago11.8; confirmación no bloqueante antes
   de la transición. Requiere autorización explícita de esta ampliación antes de escribir ejecutables.
3. Guardar snapshots mediante `saveSale` sin protección de obsolescencia: descartado por riesgo de sobrescribir
   cambios concurrentes; omitir inicio/fin de servicios tampoco respeta las invariantes de Domain.

La consulta inicial se resolvió con «si, adelante»; opción2 autorizada y PRE exacto completado antes de código.

## Revisión preliminar independiente

Agente nuevo `stock_confirmation_scope_pre`, rol ios-standards-reviewer,02/10: sin hallazgos sobre la frontera;
confirma que componente/coordinador sin consumidor no acredita «Continuar» ni completa12.4. Recomienda opción2
tras autorización de la ampliación y PRE exacto sobre disparador, archivos, aceptación, reintentos y stock desconocido.
Esta revisión preliminar no habilita ejecutables ni acredita12.4 implementada.

Fallback operacional read-only: prohibición explícita de escribir/publicar;828 archivos Git tracked y untracked
noignorados con SHA256 anterior/posterior idéntico
`17225839f6d7eae345d75f6b55f8973d393b34a4bef54a1c7def52399690aa71`, verificado por root tras respuesta.
`git diff --check` PASS; gobernanza conserva solo seis enlaces históricos08.3.
Xcode/build/tests/previews nuevos N/A: solo documentación y preparación, sin cambios ejecutables.

## Exclusiones y validación

No movimientos12.5, pago+stock atómico12.6, sync/compensación12.7–12.8, documento13, dependencia, unsafe, target,
schema, fixture adicional ni live. Una eventual conexión al pago no acredita impacto stock aplicado.

Xcode MCP: RED/GREEN focal, regresión afectada, builds Develop/Production y diagnósticos. Previews representativas
Large/XXX Large/AX5; recorrido manual según superficie operable. Auditorías POST estándares y accesibilidad;
matriz ADR0022 y deuda específica bajo ADR0029 cuando corresponda. Privacy y funcionalidad no se aplazan.

Las APIs de presentación seguirán controles SwiftUI nativos existentes en el repositorio; cualquier API dudosa
se verificará en documentación Apple actual antes de elegirla. Código afectado se fijará tras la decisión de alcance.

## Ampliación autorizada y propuesta ejecutable exacta

El propietario responde «si, adelante» a añadir el recorrido mínimo,02/10. Se selecciona opción2.

- Domain: `SaleProgressAction` (iniciar venta/iniciar línea/completar línea), UseCase, política de aceptación y error.
  La política aplica las invariantes existentes de Sale. `current == expected` acepta candidato; replay exacto
  `current == candidate` no escribe; cualquier otra versión se rechaza. No se inventa pago antes de terminar líneas.
- Repository: nuevo método de progreso; default fail-closed para dobles/capacidades sin implementación. Default e
  InMemory implementan; DataSource y PersistenceActor reutilizan persistPendingUpsert dentro de contexto limpio
  sin suspensión, conflicto/deletion comprobados y rollback existente. No nuevo modelo/schema/sync ni CAS global.
- Store: único snapshot aceptado también para operaciones iniciadas; acceso draft conserva significado editable.
  Carga operativa, progreso y pago usan exclusión/generation común. Publicación tardía no reabre tras close;
  éxito local permanece éxito después de cancelación/close. Se reutiliza análisis de stock sobre líneas aceptadas.
- ViewModel: capacidades progreso/pago opcionales inyectadas por App; nueva navegación `.operate` para Jornada
  en curso/pendiente de pago/documento, `.inspect` sigue estrictamente read-only. El detalle iniciado desde borrador
  conserva identidad hasta terminar sesión, revoca edición de términos tras iniciar; no crea otro Store/snapshot.
- UI: sección de workflow en detalle con iniciar venta y acciones por línea elegibles; al terminar todas aparece
  selección de método y registrar pago. Pago mantiene venta en Jornada pendiente de documento13.
- Solicitar pago refresca stock en tarea caller-owned sin escribir; suficiente/profesional sigue al pago existente.
  Déficit muestra confirmación scrollable con Continuar/Cancelar; fallo/desconocido informa que no puede comprobarse
  y permite explícitamente continuar. No se afirma stock suficiente ni se bloquea por disponibilidad.
- Confirmación tiene identidad, venta/método congelados, paymentID/fecha estables. Cancelar/swipe descarta intención
  sin efectos; callbacks viejos o close no pagan. Continuar consume la confirmación una vez y entrega comando
  a la tarea del Screen. Fallo local retiene el mismo comando para retry; nueva elección/presentación exige nueva
  revisión. Un snapshot diferente invalida la continuación; Repository protege obsolescencia en aceptación final.
- App compone Domain UseCases sobre repositorios compartidos; clock/identidad inyectables en ViewModel.
- SwiftUI sheet(item:onDismiss:content:) nativo comprobado en Cupertino/Apple:
  https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:).
  Confirmación es componente View de la pantalla con ViewModel dueño; no Screen adicional ni Store ceremonial.
  Locale es/en, nombres/acciones visibles equivalentes, botones44pt/wrapping, foco de retorno al botón de pago.

Archivos: Sales/Domain (acción/error/política/UseCase/Repository), Data (Default/InMemory/DataSource/actor),
Store/ViewModel/WorkdayViewModel/navigation, nueva View de workflow y confirmación, SaleDraftContent/Screen,
AppDependencies+Sales/previews, catálogo/inventario tests y suites focales de progreso/confirmación.

TDD: progreso durable/replay/stale/conflict/deleted/fallo/dirty-context/rollback y snapshot recuperado; confirmación
mostrar/cancelar/repetir sin colas/movimientos, continuar paga una sola vez, suficiente/exacto0/profesional,
unknown/fallo con permiso explícito, close/cancel y callbacks obsoletos, método/fecha/ID estables tras fallo/retry,
operaciones concurrentes y fences. Integración real in-memory SwiftData verifica cola/venta/movimientos desde
contexto fresco, además de doubles deterministas para suspensión. Regresión de navegación según contrato nuevo.

## PRE exacto completado antes de ejecutables

`stock_confirmation_scope_pre`, ios-standards-reviewer independiente: PASS sin hallazgos sobre propuesta ampliada.
Huella root determinista828archivos antes/después idéntica:
`16dceb9336254cdecb446d512b8cb910a8f2dff0629df0b54127212591938e43`.
No escritura/publicación ni Git por el revisor; fallback operacional read-only según skill.
Validación y auditorías POST se conservan en phase-12 y evidencia12.4.
