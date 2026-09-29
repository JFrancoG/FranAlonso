# Propuesta10.3 — Productos vinculables y aceptación del vínculo

Fecha:2026-09-29. [PLU-62](https://linear.app/plusprojects/issue/PLU-62), hija dePLU-59, Jesus Franco, In Progress.
El propietario autoriza implementar10.3 después de entregar10.2. Rama `codex/phase-10-3-linkable-products` desde
main/origin/main84a57e5 limpios y sincronizados. PR25 MERGED/df0a5d6, PLU-61 Done y rama anterior eliminada.
PRE PASS e implementación completada; validación registrada en fase10. POST independiente PASS sin hallazgos P0–P3.
No requiere otra autorización de implementación para este alcance canónico.

## Autoridad y baseline

Constitución, spec10, política Swift, guía/checklist y ADR0002/0006/0011/0015/0018/0029/0030 vigentes.
Perfil maintenance. Spec10 y ADR0015 asignan existencia/actividad del Product a10.3; UI y selector quedan10.4–10.6.
Baseline10.2:1.013 declaraciones/1.400 resultados PASS más retest final20/20 tras corrección del harness; PRE/POST2 PASS.
Develop con tests28,376s; Production19,421s de10.1 vigente por producción/configuración intactas. Aviso AppIntents previo.
Xcode MCP estable verifica workspace-EYu6rxi7hg, Develop/iPhone18Pro y configuración sin cambios (Swift6 estricto,
SDK27.0/target26). Baseline de preparación; las nuevas ejecuciones de implementación constan en fase10.

## Comportamiento y frontera exacta

1. ObserveLinkableProductsUseCase en Services/Domain usa ProductRepository existente y filtra solo Product.active,
   conservando orden, identidad, nombre, emisiones vacías, errores, finalización y cancelación del origen. Devolver la
   secuencia transformada de Swift evita crear un productor/Task adicional solo para filtrar. Sin filtro por stock ni conflicto.
2. GetLinkableProductUseCase vuelve a consultar el ID en ProductRepository; devuelve el Product activo correspondiente.
   Ausente, borrado, inactivo o ID discordante fallan con ServiceError.linkedProductUnavailable. Los fallos de lectura no
   se disfrazan de ausencia; cancelación se conserva. Es lectura local puntual, no una reserva del Product.
3. ServiceProductLinkPolicy pura valida perfil e instantánea Product suministrada. Para profesional no necesita Product;
   para producto exige identidad coincidente y actividad. Reutilizar esa política en lectura puntual y aceptación.
4. Toda alta/edición comercial de tipo producto exige Product activo al comprobar la aceptación local, incluso si el
   vínculo no cambió. Si Product se inactiva/desaparece, conservar Service histórico; una nueva edición requiere sustituir
   el vínculo por uno válido o cambiar a profesional. Desactivar Service continúa permitido sin Product disponible.
5. ServiceLocalDataSource.createService/updateService aplica la política después de comprobar estado de Service y antes
   de insertar snapshot/cola. Resuelve Product mediante ProductLocalDataSource.product(id:in:) usando el mismo contexto;
   no interpreta ProductModel/DTO ni duplica tombstones. Política/frontera de negocio sigue en Domain; esta colaboración
   concreta entre adaptadores Data solo suministra Product y no añade acceso a Data desde Domain. Sin suspensión entre
   lectura y commit, sin prometer CAS/atomicidad global entre contextos independientes.
6. Preservar prioridad de errores de identidad/conflicto, cancelación previa, contexto sucio, rollback y éxito tras commit.
   Fallos de lectura Product se traducen a ServiceError.persistenceUnavailable, conservando CancellationError.
   Rechazar vínculo no escribe Service ni cola ni publica señal. No modifica Product ni su cola.
7. InMemoryServiceRepository recibe ProductRepository por inicializador (default repositorio vacío para fixtures
   profesionales), valida la misma política y vuelve a comprobar identidad/estado después del await antes de mutar.
   AppDependencies.preview inyecta su ProductRepository compartido; no crea otro catálogo divergente.
   La doble lectura entre actores no promete atomicidad distribuida. Semántica de observación finita del preview intacta.

Se reutiliza Product como valor Domain (ID/nombre/estado): no hace falta otra proyección ni protocolo duplicado.
La consulta general Product/SearchProductsUseCase conserva inactivos para inventario. Service.init/Codable/DTO, sync,
upsert/persistPendingUpsert técnico, saveService legacy y desactivación no endurecen sus reglas de vínculos históricos.
No se reescriben referencias cuando se elimina Product ni se bloquea la recepción de Services antes que Products.
App expone observeLinkableProducts/getLinkableProduct compuestos sobre el mismo ProductRepository para10.4–10.6;
sin factories de formularios ni nuevas pantallas todavía.

## Cambios y TDD

Producción: nuevos UseCases/política en Services/Domain; error y DocC de Service/Repository; ServiceLocalDataSource,
InMemoryServiceRepository y composición lectora/preview en AppDependencies. Sin cambio de schema, DTO, motor ni Product.
Tests nuevos de lectura/observación y aceptación local. Ajustar fixtures10.1/10.2 para sembrar Product activo cuando prueban
un guardado comercial válido: preservar los oráculos de causalidad y durabilidad, y comprobar Product/cola sin mutaciones.
No cambiar fixtures técnicos de sync/legacy que conservan referencias históricas.

TDD: escribir escenarios, compilar API mínima, registrar RED semántico real; implementar aceptación mínima y GREEN.
- Lectura: colección mixta/vacía y orden; cambios activos→inactivos/ausentes; fin/error/cancelación sin error→vacío.
- Consulta puntual: ID activo válido, ausente, inactivo, eliminado real y selección antigua reconsultada; error/cancelación.
- Guardado por actor y contextual: alta/edición rechazada sin cambiar snapshot/cola; edición con mismo vínculo ahora
  inválido; sustitución válida y cambio a profesional; conflicto/identidad prevalecen y ninguna escritura Product.
- Histórico: lectura y transporte/sync conservados; desactivación posible tras inactivar/borrar Product.
- InMemory: misma disponibilidad, dependencia compartida y cancelación; reentrada no sobrescribe un estado más reciente.
- App: lectores usan el catálogo inyectado y no consultan al construir. Regresión10.1/10.2 y suites Service/Product afectadas.

Xcode MCP: RED/GREEN focal, regresión por impacto y global si vuelve a ser necesario para variantes parametrizadas;
builds Develop/Production y logs completos. Usar resultados nativos cerrados. Style audit, gobernanza y POST independiente.
Sin pruebas manuales de accesibilidad ni previews nuevos por ausencia de UI; deuda08/PLU-54/57 intacta.

## Alternativas, fuentes y límites

Solo filtrar en UI incumple spec10. Solo validar en UseCases CRUD asíncronos deja fuera la ruta contextual y crea una
ventana antes de aceptación. Un coordinador transaccional genérico entre features añade arquitectura y garantías no
requeridas. Endurecer Service/DTO/sync impediría históricos y recepción fuera de orden. Una copia [Product] fija en
InMemoryServiceRepository no reflejaría cambios del catálogo; usar ProductRepository compartido.

Fuentes primarias: ProductRepository/ProductLocalDataSource, ServiceLocalDataSource y adapter/contextual actuales,
ADR0011/0015 y AppDependencies. Cupertino: [AsyncMapSequence](https://developer.apple.com/documentation/swift/asyncmapsequence)
para transformación de AsyncSequence sin productor adicional. Verificar compilación con SDK actual.
Riesgos: validación solo visual, ventana entre consulta y aceptación, errores de lectura ocultos como vacío, reentrada de
actor al consultar Product y endurecimiento accidental de históricos. Los escenarios distinguen estos riesgos.
Reversibilidad: retirar lectores/política y validación comercial no migra datos ni cambia formatos existentes.
Excluidos: UI/ViewModels10.4–10.6, venta/stock positivo, unicidad Product–Service, cascadas, sync/live, IA y nuevas dependencias.
Commit/push/PR/merge/cierre10.3 y siguiente10.4 no autorizados en esta petición.


## PRE y autorización de implementación

PRE independiente PASS sin hallazgos P0–P3. Reviewer/root verifican630 archivos idénticos, manifest
`/tmp/franalonso-10-3-pre1.json`, SHA256 `4495a4d5f48aaf65b8be37685d4ee292f5acacb11dc9e38546aed17f31bee906`.
Precisiones: consulta puntual conserva errores Product; aceptación los traduce a Service.persistenceUnavailable;
InMemory comprueba identidad antes/después del await, estado/index recientes y conflicto antes de vínculo en Data.
Probar lectura tras inactivación/tombstone desde otra ruta. Implementación autorizada por petición inicial del propietario.


## Resultado de implementación y POST

17 declaraciones/36 resultados nuevos; global1.030 declaraciones/1.436 resultados PASS, Develop/Production PASS.
RED semántico23fallos/13PASS; GREEN focal18/18 con variantes omitidas cubiertas después por la global.
Evidencia y límites completos en [fase10](phase-10.md). POST independiente por agente nuevo,14Swift/4docs, sin hallazgos.
635archivos idénticos antes/después, verificados por reviewer y root; manifest `/tmp/franalonso-10-3-post1.json`,
SHA256 `0b4c39ca5a7ff9e227bc33e5e3b154eb98ad534eb597a3a439a2ac9316b395c4`. Sin builds/tests/escrituras del auditor.
Solo se añade este resultado documental después del cierre de huella. Entrega Git10.3 y10.4 no iniciadas.
