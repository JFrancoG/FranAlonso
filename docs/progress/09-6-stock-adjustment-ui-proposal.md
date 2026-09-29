# Propuesta09.6 — UI de ajustes de stock

2026-09-29. PLU-56, Jesus Franco, hija dePLU-49. Implementación solicitada explícitamente por el propietario después de
entregar09.5. Rama `codex/phase-09-6-stock-adjustment-ui`, base8908ab6, creada desde main/origin/main idénticos y limpios.
PRE antes de código; las decisiones siguientes concretan el alcance09.6 autorizado, sin nueva arquitectura ni ADR.
Entrega Git09.6 y09.7 conservan sus puertas separadas.

## Autoridad y baseline

Constitución, spec09, política Swift, ADR0006/0011/0021/0022/0029/0030 y propuesta09.5 aprobada.
09.5: commit3b308c3, PR21/70775d9, PLU-55 Done, ramas eliminadas y cierre8908ab6 publicado.1.268 resultados PASS,
Develop/Production y PRE/POST PASS; avisoAppIntents conocido. Se reutiliza esta evidencia hasta cambiar código.
Xcode MCP estable, workspace-EYu6rxi7hg, target26, Swift6 strict complete, aislamiento predeterminado nonisolated.
Perfil maintenance. No dependencias, plataforma ni servicios live nuevos. Accesibilidad integral previa permanece abierta.

## Recorrido y estado

- Botón visible «Ajustar stock» en la ficha de un producto existente, activo o inactivo, solo después de cargarlo.
  Abre una hoja propia; no cambia el nombre sin guardar ni cierra la ficha. Volver conserva el borrador de nombre.
  El formulario de alta debe guardarse antes de ajustar; no se añade detalle ni cantidad a cada fila del catálogo.
- Carga producto y saldo actual; error/ausencia impide guardar y permite reintentar o cancelar. Entrada/Salida nativas,
  campo unidades enteras positivas y motivo obligatorio. El signo lo determina la dirección, no el campo numérico.
  Input recorta blancos exteriores y acepta dígitos ASCII sin signo ni separadores, de1 aInt.max; se rechazan cero,
  negativos, decimales, vacíos y overflow. La regla de cantidad y el motivo viven en Domain, no en View.
- Conserva saldo cero/negativo y política de elegibilidad09.5. La pantalla muestra saldo negativo de forma textual;
  no añade mínimos ni bloqueo nuevo, ni cambia Product, precios o sincronización.
- Identidad de sesión distinta de la identidad del movimiento. Primer envío válido congela ID/fecha/payload canónico;
  retry tras fallo conserva exactamente esos valores. Campos bloqueados tras ese intento: la acción es reintentar el
  mismo ajuste, o cancelar con descarte explícito. Nunca cambia payload bajo el mismo ID ni reenvía por doble toque.
- Validación previa conserva campos editables y enfoca el campo inválido. Guardando bloquea controles y cancelación;
  cancelación previa no persiste, cancelación tras aceptación conserva éxito. Cerrar invalida respuestas antiguas y
  no afirma deshacer commits. No se retiene ModelContext ni Task de View fuera de su llamada estructurada.
- Tras aceptación, estado guardado terminal inmediatamente. La lectura del nuevo saldo es separada: si falla, mostrar
  «Ajuste registrado» y error al actualizar saldo con acción de recarga; nunca rehabilitar Guardar ni duplicar ajuste.
  Finalizar cierra solo esta hoja. Nueva apertura crea una sesión nueva y lee el saldo vigente.
- Cancelar con borrador exige confirmación, gesto de cierre deshabilitado; acciones explícitas Descartar/Seguir editando.
  Se conserva el patrón corregido09.4, evitando ocultar Seguir editando con role.cancel en el popover observado.

## Fronteras concretas

- Domain: cantidad de entrada validada y dirección, error neutral de cantidad; PrepareStockAdjustmentUseCase produce
  StockMovement manual. AdjustStockUseCase09.5 reutiliza esa preparación sin cambiar su contrato async/repository.
- StockAdjustmentViewModel @Observable @MainActor posee estado/borrador/ID de sesión y generación de operaciones.
  Recibe lectura Product/cantidad y closure contextual específica; reloj/ID inyectables para pruebas deterministas.
- Data: StockContextualPersistenceAdapter @MainActor invoca StockLocalDataSource.append, sin duplicar mapping,
  idempotencia, elegibilidad, suma, rollback ni commit. View pasa Environment.modelContext al ViewModel, que lo entrega
  de forma efímera a la closure compuesta en App conforme ADR0011. Ningún modelo/contexto cruza actores.
- App comparte repositorio actor para lecturas y una ruta contextual para escritura UI. El actor09.5 conserva su contrato
  probado pero no tiene productor de escrituras activo en este recorrido. El seed se completa antes de exponer contenedor.
  No se invocan actor.append y adapter.append para una misma acción. Ambas rutas comparten la primitiva síncrona Data.
- Serialización demostrada: todas las escrituras UI sobre el mismo contexto principal ocurren en MainActor y sin suspensión
  durante aceptación. Se prueban llamadas concurrentes a esa ruta y se conserva la prueba del actor09.5. No se promete
  CAS/atomicidad global entre writers o contextos independientes, ya excluida en09.5. Un futuro productor background
  exige definir su coordinación antes de activarlo; no se introduce aquí una cola ni un actor coordinador ceremonial.
- AppDependencies añade factory específica a composición real, demo y preview interactiva, compartiendo el actor por
  composición. Snapshot preview rechaza escrituras. No hay Store ni protocolo genérico nuevo.
- ProductFormViewModel posee destino tipado y permite abrir/cerrar solo la sesión vigente, sin alterar el borrador padre.
  Views renderizan estado y delegan intenciones; la factory se transmite explícitamente desde composición.

## Demo y UI accesible

Se añaden movimientos sintéticos estables a los dos productos de demo, con fecha fija y saldos8/2, después de crearlos.
Nueva composición restituye seed; guardar/reabrir conserva cambios dentro de la composición. Sin persistencia real ni
sincronización; fixtures de autenticación permanecen vacías y separadas.

Textos es/en en xcstrings; controles SwiftUI nativos, etiquetas persistentes, saldo formateado por locale, errores textuales,
acciones44pt y layout que envuelve Dynamic Type. Títulos compactos/acciones accesibles cuando AX lo requiera.
Foco semántico en validación y retorno al botón al cerrar hoja; anuncios de error/guardado sin timers ni bucles.
Cada View nueva tiene preview determinista con trait compartido. Large/XXX Large/AX5 en hoja y ficha afectada; muestras
claro/oscuro/contraste incrementado y estados editar, inválido, carga/error, guardando, guardado y saldo negativo.
ADR0029: construcción/revisión, previews y smoke son obligatorios ahora. Matriz manual/integral se registra en una nueva
issue enlazada, Jesus Franco, después de feedback/estabilización y antes de uso real; PLU-54 no absorbe el alcance nuevo.

## TDD y verificación

RED semántico compilable → GREEN; Swift Testing, Xcode MCP, estilo y PRE/POST independientes.

- Parseo/validación de unidades y motivo; entrada/salida, cero/negativo resultante y extremos permitidos.
- Carga/error/retry, sesiones reemplazadas, cancelar/cerrar, validación, exclusión de solapamientos, snapshot del envío,
  ID/fecha/payload congelados, cancelación previa/tardía y guardado irreversible frente a fallo posterior de lectura.
- Caller-context real, contexto ajeno sucio conservado, retry sin escritura, colisión preservada y concurrencia UI.
- Apertura solo en producto existente y no durante guardado; borrador padre intacto y cierre antiguo no cierra reapertura.
- Composición real/preview/demo: saldo sembrado, guardar/reabrir, reset y rechazo explícito en snapshots.
- Regresión09.5, Products y AppDependencies; suite completa si composición/transversalidad lo exige, Develop/Production.
- Smoke táctil: entrada, salida hasta saldo negativo, validación/corrección, retry de lectura donde sea reproducible,
  cancelar/seguir/descarte, nombre padre conservado, reabrir y reset. No se usan UI tests ni se afirma AT por capturas.

## Alternativas y límites

Un delta firmado ahorra un selector, pero Entrada/Salida expresa mejor la intención y evita signo ambiguo en teclado.
Un historial/detalle nuevo y mínimos ampliarían09.6. Reutilizar el actor ignorando el contexto incumpliría ADR0011;
serializar todos los contextos con infraestructura nueva no responde al único productor UI actual. Se conserva la
primitiva común y se documenta el límite, sin atribuir atomicidad global. No hace falta un ADR para aplicar ADR0011.

Riesgos: duplicación tras retry, pérdida de borrador padre y errores de saldo tras commit. Se mitigan con comando congelado,
estado guardado terminal, sesión/generación independiente y separación lectura/escritura. UI reversible; ledger conserva
los datos ya aceptados. No hay migración adicional, activación live, ventas, mínimos09.7 ni cierre integral de fase09.

## Fuentes primarias

Cupertino, documentos Apple completos consultados29/09/2026; APIs disponibles desdeiOS15, compatibles con target26:

- [interactiveDismissDisabled](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)):
  impide gesto de cierre; la cancelación programática sigue siendo responsabilidad del flujo.
- [accessibilityFocused](https://developer.apple.com/documentation/swiftui/view/accessibilityfocused(_:)):
  vincula foco accesible; requiere evidencia runtime antes de afirmar restauración real con tecnologías de asistencia.

## PRE

PASS independiente de ios-standards-reviewer, sin hallazgos P0–P3. Perfil maintenance.
Manifiesto `/tmp/franalonso-09-6-pre.json`, SHA256
`1e3d1328d4c7e15386df3be8a0f2f432be8782e1384f2ca6df5346c930632042`: reviewer y orquestador
verifican591/591 archivos idénticos, sin altas/bajas/cambios. Sin builds/tests durante revisión.
Vigilancia en implementación: onDisappear de ficha padre al presentar hoja; cubierto por prueba y smoke del borrador.
Implementación autorizada por la solicitud del propietario; no hay excepción ni nueva puerta de aprobación.
