# Propuesta 10.1 — Contratos del catálogo comercial

2026-09-29. [PLU-60](https://linear.app/plusprojects/issue/PLU-60), Jesus Franco, hija de
[fase10/PLU-59](https://linear.app/plusprojects/issue/PLU-59). Inicio autorizado: «Abre issue y rama y empieza10.1».
Rama `codex/phase-10-1-service-contracts` desde main/origin/main `50ecc39`, limpios e idénticos.
Estado: propuesta PRE PASS aprobada por el propietario («si, adelante»); implementación10.1 validada, POST PASS sin hallazgos.
Entrega Git autorizada posteriormente: «Commit y push, lanza PR, merge y cierra su rama».
Registro de entrega en phase-10.md;10.2 y live conservan su puerta.

## Autoridad y baseline

Constitución, spec10 fila10.1, contratos monetarios de spec04 y política Swift; ADR0002/0006/0011/0015/0018/0029/0030.
Perfil maintenance: conservar capas, modelos, toolchain, contratos de persistencia y pruebas. Ningún ADR nuevo previsto.
La secuencia aprobada es09→10→adelanto textual16/PLU-47→11–13; el inicio10.1 no entrega esas capacidades posteriores.
Fase09 conserva PLU-54/57 de accesibilidad integral; fase08 mantiene su deuda y08.9 aplazada. No se transfieren a10.1.

Baseline09.7 entregada: commit51afed1, PR23/merge b40e1f6, cierre documental50ecc39, PLU-58 Done y rama eliminada.
979 declaraciones/1.346 resultados PASS, Develop22,583s/Production20,338s, PRE/POST PASS. Árbol de código/configuración
y tests intacto respecto a POST2; solo cambia preparación documental. Aviso AppIntents y seis enlaces históricos08.3.
Xcode MCP estable conectado a `workspace-EYu6rxi7hg`, ruta FranAlonso.xcodeproj, scheme Develop. Configuración real
verificada con GetTargetBuildSettings: SDK27.0, target26, Swift6, strict complete, default nonisolated, warnings como errores.
No se cambia configuración ni se repiten builds/tests por documentación. Esta preparación no acredita comportamiento nuevo.

## Código real y hueco

Service ya contiene ID, nombre, tipo, linkedProductID, Money, TaxRate, Discount opcional y estado. Su construcción y
Codable garantizan producto→vínculo obligatorio y profesional→sin vínculo. Money normaliza unidades menores con Decimal;
acepta negativos para usos monetarios generales. TaxRate/Discount ya validan0…100, también al decodificar.
Service no exige nombre no vacío ni precio no negativo. Los snapshots históricos/DTO pueden representar esos valores.

ServiceRepository solo observa/guarda snapshots; ObserveServicesUseCase y SaveServiceUseCase mantienen esa superficie.
La vertical05.10b existe: repositorio, actor, adaptador contextual, datasource, DTO/mapping, cola causal, tombstones,
conflictos, cursor, retry y motor. ADR0015 conserva decimales exactos como cadenas canónicas sin Double.
Faltan entrada comercial editable validada, lectura individual, alta/edición/desactivación semánticas y búsqueda.
El precedente09.1 ya resuelve aceptación local única sin suspensiones para actor y contexto de UI.

## Comportamiento propuesto

1. Añadir ServiceProfile: entrada comercial editable sin ID ni estado, con nombre, tipo, vínculo, Money, TaxRate y
   Discount opcional. Codable/Equatable; construcción y decodificación garantizan las mismas invariantes.
   Recortar whitespace/newlines exteriores del nombre y rechazar vacío; conservar grafía y espacios interiores.
2. Para altas/ediciones nuevas, aceptar precio normalizado por Money mayor o igual a cero; cero permite un concepto
   gratuito. Rechazar negativos en ServiceProfile, sin endurecer Money ni los snapshots Service/DTO históricos.
   Conservar EUR/USD soportados, redondeo vigente y precio con impuesto incluido. Sin moneda implícita, conversión,
   límite máximo arbitrario ni impuestos/descuentos predeterminados. TaxRate/Discount se reciben ya validados.
   Discount nil y porcentaje0 conservan su distinción actual; no normalizarlos ni calcular importes finales aquí.
3. Validar relación tipo/vínculo tanto en perfil como en Service mediante una única comprobación pura de ServiceType,
   extraída de la regla vigente sin cambiar sus resultados ni Codable. No fabricar un ServiceID para validar el perfil.
   Cambiar profesional↔producto es una edición permitida si el perfil completo es coherente. No modifica ventas pasadas.
4. La validez estructural del vínculo no demuestra existencia/disponibilidad de Product. Mantener la frontera expresa
   de ADR0015: consulta y política de productos activos/vínculos desaparecidos pertenecen a10.3. Ningún ProductRepository
   nuevo en ServiceProfile o Data10.1. No se presenta10.1 como catálogo listo para vender hasta completar las otras puertas.
5. Leer por ServiceID devuelve activo/inactivo; ausente/tombstone devuelve nil. Alta con ID explícito nace active y
   rechaza identidad ya usada en snapshot, cola, estado remoto o tombstone; no sobrescribe ni restaura. Duplicados son
   identidad, no nombre: permitir homónimos con IDs distintos. El caller aporta ID; Data conserva operation IDs causales.
6. Editar requiere entidad existente, reemplaza el perfil comercial completo y preserva ID/estado vigentes leídos en
   la aceptación. Inactive sigue editable sin reactivarse. Ausente no crea; tombstone/conflicto rechazan mutación.
   No aceptar un snapshot antiguo del caller capaz de sobrescribir el estado actual. Las ventas retienen sus snapshots.
7. Desactivar significa active→inactive conservando todos los campos y vínculo. Inactive sin conflicto devuelve éxito
   sin guardar ni crear una operación, también después del ack anterior. Comprobar conflicto antes del no-op.
   Desconocido falla; tombstone no se restaura. Borrado técnico, restauración y reactivación quedan fuera de10.1.
8. Observación/gestión mantienen activos e inactivos. SearchServicesUseCase filtra snapshots suministrados por nombre
   parcial, localizado, insensible a caja/diacríticos; query recortada y vacía devuelve todos, conservando orden y tipo.
   No consulta Data ni red. Filtros comerciales de venta corresponden a10.7; no inventar búsqueda por precio o producto.
9. Ampliar ServiceError con nombre/precio inválidos, identidad existente, notFound, deleted, conflict y fallo local
   neutral; conservar los dos errores de vínculo. No filtrar payloads ni tipos SwiftData/Firebase a Presentation.
   CancellationError permanece distinguible: antes de aceptación no escribe; después del commit conserva éxito.

## Diseño y frontera10.1/10.2

Ampliar ServiceRepository con lectura/create/update/deactivate y añadir Get/Create/Update/DeactivateServiceUseCase,
PrepareServiceProfileUseCase y SearchServicesUseCase. Prepare recibe campos comerciales tipados; el parseo de texto
monetario/localizado del formulario pertenece a10.4. No añadir Stores ni protocolos paralelos para estos comandos.

Completar la aceptación local mínima real de las nuevas conformidades. ServiceLocalDataSource comparte comprobaciones
de existencia/conflicto/tombstone, construcción Domain y persistPendingUpsert en una única operación sin suspensión.
No implementar read-async→save-async. Actor y adaptador contextual delegan en esa misma primitiva; ModelContext es efímero,
sin cruzar actores. Rechazar contexto con cambios pendientes antes de un rollback para no descartar trabajo ajeno.
DefaultServiceRepository y adapter publican la misma ServiceObservationSignal después de aceptación; una cancelación
tardía no transforma un commit en error. Desactivación repetida no publica una nueva mutación. Mantener deduplicación
de payload/operationID existente y rollback de snapshot+cola; no se promete CAS entre contextos independientes.

Conservar save/observe legacy sin endurecimiento global: materialización/sync continúa representando snapshots ya
admitidos. Los nuevos comandos usan siempre ServiceProfile. InMemoryServiceRepository reproduce las reglas semánticas
para tests/previews, sin atribuirle durabilidad/sync. App ya compone repositorio/actor/señal; no exponer nuevas acciones
de UI hasta10.4 ni activar el motor. Solo adaptar las dos conformidades fake actuales además de repositorios reales.

10.2 conserva integración CRUD→sync/ack, conflicto remoto, tombstone recibido, offline y reapertura durable. No se
reconstruyen DTO, modelo, schema, encoder decimal, kernel de retry ni motor05.10b. No hay migración ni red nueva en10.1.

## Archivos y áreas previstas

- Services/Domain: ServiceProfile nuevo; Service.swift solo comparte regla tipo/vínculo y amplía/ubica ServiceError;
  ServiceRepository y seis UseCases nuevos. Observe/Save existentes se conservan.
- Services/Data: ServiceLocalDataSource, ServicePersistenceActor, ServiceContextualPersistenceAdapter,
  DefaultServiceRepository e InMemoryServiceRepository; primitiva compartida y delegaciones mínimas.
- FranAlonsoTests: ServiceProfile/CRUD/búsqueda y aceptación local; adaptar ServiceRepositoryUseCaseTests y
  AppDependenciesTests únicamente por la conformidad ampliada. Reutilizar suites Service y dominio monetario existentes.
- Documentar contratos aprobados en spec10 y evidencia en phase-10/Progress al implementar. Sin cambios SwiftUI, textos,
  recursos, seed de demo, App runtime, schema/DTO, navegación o Foundation Models.

## Alternativas, riesgos y reversibilidad

- Save genérico para crear/editar no distingue intenciones ni protege estado vigente. Añadir comandos semánticos.
- Solo Domain con stubs hasta10.2 entrega contratos ficticios; se elige mínima adaptación local probada, como09.1.
- Endurecer Service/Money globalmente alteraría lectura histórica y sync; la entrada nueva concentra nombre/precio.
- Usar tombstone como desactivación confunde disponibilidad y borrado; conservar inactive y referencias.
- Moneda única, precio estrictamente positivo o unicidad por nombre son reglas de producto adicionales; no se imponen.
- Integrar productos vinculables/UI/sync completa ahora diluye las subfases; conservar10.2–10.7 y sus gates.

Riesgos: snapshot antiguo del caller, pérdida de decimales, vínculo estructural interpretado como disponibilidad real,
rechazo retroactivo de datos existentes y rollback de cambios ajenos. Los contratos anteriores y tests específicos los
acotan. Sin cambios persistidos de forma; reversibilidad mediante retirar nuevas intenciones sin borrar datos existentes.

## TDD y validación previstos

Después de aprobar la propuesta, leer tests-de-verdad y aplicar Swift Testing RED semántico compilable→GREEN con Xcode MCP.
No nuevos tests de getters, delegación trivial ni detalles internos; usar resultados comerciales/locales como oráculos.

- Nombre vacío/whitespace/normalización; precio negativo rechazado y cero válido; Money conserva decimal/moneda.
- Codable adversarial no elude nombre/precio/tipo/vínculo; Service histórico mantiene comportamiento previo.
- Alta/lectura de ambos tipos, ID repetido sin sobrescritura y homónimos con IDs distintos.
- Edición cambia todos los campos comerciales, conserva estado actual e identidad; transiciones de tipo coherentes;
  ausencia no crea. Desactivar conserva vínculo y valores exactos; repetir tras ack no crea nueva operación.
- Búsqueda de ambos tipos/estados, query vacía/parcial/caja/diacríticos, sin resultados y orden de corpus independiente.
- Snapshot+cola atómicos, rollback/error neutral, conflicto bloqueante e inactivos con conflicto; tombstone no revive.
- Paridad actor/contextual, observación después de aceptación, cancelación previa/tardía y contexto sucio intacto.
- Regresión Service, Money/TaxRate/Discount, mapping y composición; no clonar la matriz sync existente.

GREEN focal y suite global por ampliación del contrato compartido, builds Develop/Production y logs completos;
auditoría de estilo y POST independiente. Nuevas previews/UI/accesibilidad N/A si el diff conserva este alcance.
Resultado ejecutado en [fase10](phase-10.md): TDD y suite global PASS. La integración completa de10.2 sigue pendiente;
PRE no acredita comportamiento por sí mismo.

## Fuentes primarias y puerta siguiente

Autoridad de comportamiento comercial: specs04/10 y ADR0006/0015/0030, no inferencias de una API de Apple.
Consultada con Cupertino el29/09/2026 la documentación completa de
[localizedStandardContains](https://developer.apple.com/documentation/foundation/nsstring/localizedstandardcontains(_:)):
confirma búsqueda localizada insensible a caja/diacríticos, compatible con el target. Se reutiliza el patrón vigente de
SearchProductsUseCase. No se requiere API, dependencia, excepción unsafe ni ADR nuevo.

PRE independiente ios-standards-reviewer: PASS, sin hallazgos P0–P3. Reviewer y root verifican615/615 archivos idénticos,
sin altas/bajas/cambios; manifiesto `/tmp/franalonso-10-1-pre1.json`, SHA256
`481bd333f62daf02278909af206bebd300404eff7c313600d47597501536d83f`. Revisor contrasta también la fuente Apple
[StringProtocol.localizedStandardContains](https://developer.apple.com/documentation/swift/stringprotocol/localizedstandardcontains(_:)).
El resultado se registra después de comprobar la huella. No acredita código, TDD ni comportamiento nuevo.
El propietario aprobó este alcance concreto («si, adelante»), incluido precio normalizado>=0/cero válido.
Implementación/TDD/builds validados, POST PASS; evidencia en [fase10](phase-10.md).
Publicación Git, cierre de issues y10.2 conservan autorizaciones separadas.
