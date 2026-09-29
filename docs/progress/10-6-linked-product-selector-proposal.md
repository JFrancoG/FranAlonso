# Propuesta 10.6 — Selección del producto asociado

2026-09-30. PLU-66, hija de PLU-59, Jesus Franco, In Progress. Rama
`codex/phase-10-6-linked-product-selector` desde main/origin/main limpios `01d0657`.
10.5 entregada: PR28 MERGED/c2f1af0, PLU-64 Done, rama eliminada. Implementación 10.6 autorizada;
su entrega Git y 10.7 no están autorizadas todavía.

## Autoridad y alcance

Constitución, spec 10/índice, política Swift, ADR0002/0006/0011/0015/0018/0022/0029/0030.
Perfil maintenance; Xcode MCP estable workspace-EYu6rxi7hg: Swift 6 estricto, target 26/SDK 27,
warnings-as-errors. Baseline 10.5: 1061 declaraciones/1520 resultados PASS, Develop/Production,
previews y smoke PASS; aviso AppIntents y seis enlaces históricos 08.3 conocidos.
Solo Services/Presentation, composición App, tests y documentación. Sin Domain/Data/esquema,
sync, ventas, IA, dependencias, unsafe ni activación live.

## Propuesta y alternativas

El formulario permite cambiar entre Profesional y Producto mediante Picker nativo. Elegir
Profesional elimina explícitamente el vínculo; volver a Producto exige una elección nueva.
Elegir/sustituir un producto solo cambia linkedProductID, conserva los demás campos y no guarda.
Usar Picker `.navigationLink` dentro del NavigationStack/Form existente para el catálogo activo.
Apple recomienda este estilo cuando hay muchas opciones o interesa navegar al selector:
[NavigationLinkPickerStyle](https://developer.apple.com/documentation/swiftui/navigationlinkpickerstyle),
consultado por Cupertino. Compatible desde iOS 16; target 26. No pantalla personalizada ni nuevo
ViewModel: el control pertenece a la sesión ServiceFormViewModel, como los demás campos.

Inyectar ObserveLinkableProductsUseCase obligatorio en ServiceFormViewModel y sus factories,
usando el mismo ProductRepository de la composición. Estado independiente idle/loading/loaded/failed,
con generación propia para impedir publicaciones tras reemplazo o cierre. Método async caller-owned
mediante .task(id:) en Screen; retry explícito, sin Task interno, polling ni timers. Cierre cerca
ambas generaciones. La finalización normal conserva loaded si recibió al menos un snapshot (incluido vacío),
pues la composición snapshot termina después de emitir; finalizar sin ninguna emisión es fallo
recuperable neutral. Los errores pasan a failed y la cancelación no presenta un error. La observación no altera draft, baseline ni estado de escritura.

Selección síncrona desde los productos activos observados, guardada por canEdit y pertenencia a
la lista actual. La identidad elegida se conserva si después desaparece/inactiva. Una fila centinela
con ese tag muestra «Producto no disponible» tras lectura satisfactoria, o disponibilidad desconocida
si carga/falla: nunca UUID ni nombre inventado. No elegir automáticamente el primero. Placeholder
nil permite volver a no seleccionar, con validación explícita al guardar. Error/vacío muestran
recuperación adecuada; un error de lector no afirma eliminación. Retry no borra campos ni selección.

Alternativa descartada: consulta GetLinkableProductUseCase adicional al tocar cada fila, pues agrega
solapamiento/cancelación de selecciones sin eliminar la carrera hasta guardar. La aceptación contextual
10.3 sigue siendo la única frontera autoritativa y rechaza producto inactivo/eliminado entre elección
y guardado, sin efectos parciales. El usuario puede sustituirlo o convertir a Profesional y reintentar.
No modificar esa aceptación ni impedir desactivación histórica por un vínculo no disponible.

## UI, accesibilidad y validación

Textos ES/EN en xcstrings. Etiquetas persistentes, controles nativos, filas mínimas 44 pt y multilínea,
DynamicType; estado explícito loading/empty/error/unavailable. Error de vínculo junto al selector
con foco accesible tras intento explícito de guardar; no foco automático por cada evento del stream.
Anuncio de guardado fallido existente conservado. Ningún resultado observado borra errores de persistencia.
Campos y selector se bloquean durante load/save/deactivate/closed. Pantalla posee VM y las Views
renderizan estado y envían intenciones changeType/selectLinkedProduct/retry. Previews deterministas
para ambos tipos, selección, vínculo desaparecido, vacío y error; ES/EN y AX5 representativos.

TDD Swift Testing focal: cambio de tipo y limpieza, elegir/sustituir/preservar campos, dirty tracking,
rechazar identidad no activa/no observada, bloqueo durante mutación; observación vacía/contenido/error/
terminación finita con contenido/vacío emitido/sin emisión, retry/cancelación/cierre/reemplazo sin corrupción del borrador. Composición real crea y
sustituye servicio producto; producto desactivado entre selección y guardado rechaza sin escritura,
permite recuperación por otro producto o Profesional. Reutilizar pruebas históricas de desactivación.
Build/tests, logs y xcresult por Xcode MCP; previews y smoke demo focal sobre selector/cambio tipo/
sustitución/guardar/reabrir. POST estándares y accesibilidad independiente con huella read-only.

ADR 0029: issue propia vinculada para matriz integral después del feedback/estabilización y antes
uso real; no absorber PLU-65 ni convertir AT/Inspector/contraste/teclado/ventanas pendientes en PASS.
Riesgos: ciclo de vida del selector nativo, selección ausente de la lista, observaciones tardías,
scroll y foco AX. Smoke comprueba que navegar al Picker no cierra el formulario. Reversión sin migración.

## PRE independiente

PRE1 encontró P2 de finalización finita del repositorio snapshot; corregido contrato de arriba.
661 archivos idénticos, `/tmp/franalonso-10-6-pre1.json`, SHA256
`d1b518a1256bae9322892576ce20743de18831dc9e164c984c954286a927ac47`.
PRE2 PASS independiente antes de código: 661 archivos idénticos,
`/tmp/franalonso-10-6-pre2.json`, SHA256
`e57089c7c440035eff550b6e3c9d861a76396a9392b7c2df70e1626811a49d5c`. PLU-67 Backlog vinculada a PLU-66
cubre deuda integral propia, Jesus Franco, tras feedback/estabilización y antes de uso real.

## Resultado de implementación — 2026-09-30

Implementación y puerta funcional ADR0029 PASS; [registro completo](phase-10.md) y
[matriz accesible](../accessibility/evidence/10-6-linked-product-selector.md). TDD semántico RED,
1.073 declaraciones/1.544 resultados GREEN, builds Develop/Production, previews y smoke focal PASS.
POST independientes sin hallazgos nuevos; huella de664archivos idénticos en registro de fase.
Componente visual ServiceLinkedProductSection extraído; label nativo persistente evita duplicación.
PLU-66 In Progress, cambios locales sin commit/push. PLU-67 mantiene validación integral aplazada;
PLU-65 conserva diagnóstico de layout/localización previo. No se inicia10.7 ni se cierra fase10.
