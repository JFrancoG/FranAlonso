# Fase 12 — Venta y stock

Actualizado: 2026-10-02. [Spec](../specs/12_stock_sale_integration.md).
[Fase PLU-85](https://linear.app/plusprojects/issue/PLU-85): In Progress, sin cierre ni activación live.

## 12.1 — Análisis puro de impacto

[PLU-86](https://linear.app/plusprojects/issue/PLU-86), Done, Jesus Franco.
Rama `codex/plu-86-sale-stock-impact`, base limpia `0a9729c` en main/origin-main.
Autorización: «Abre issue y rama e implementa la subfase 12.1».
[Propuesta y revisión PRE](12-1-stock-impact-proposal.md): PASS independiente, huella idéntica.

`AnalyzeSaleStockImpactUseCase` en Sales/Domain delega en la política publicada `StockWarningPolicy`, sin duplicarla.
Recibe líneas y cantidades actuales por producto y devuelve impactos en orden para las líneas vinculadas;
acumula productos repetidos incluso intercalados, omite servicios profesionales y no modifica entradas.
Agotamiento exacto suficiente; stock cero/negativo produce aviso no bloqueante. Ausencia de stock, identidad
duplicada y overflow siguen siendo errores de datos. Operación síncrona, sin I/O, reservas ni efectos persistentes.

### Validación Xcode MCP

Service estable `workspace-PfnUYLlMzY`, FranAlonso.xcodeproj, iPad Pro13(M5) Simulator27.2,
SDK27.0, target27.0, Swift6/nonisolated/strict complete/approachable concurrency y warnings-as-errors.
Develop y plan FranAlonso-Develop restaurados tras verificar Production; destino original preservado.

- Baseline focal: política publicada10/10 PASS. Log previo existente Production01/10 distinguido del trabajo actual.
- RED: build-for-testing02/10 falló por `AnalyzeSaleStockImpactUseCase` ausente, con diagnósticos derivados.
  Log: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133412.txt`.
- GREEN:6 declaraciones nuevas/10 escenarios y9 declaraciones anteriores/10 escenarios: **20/20 PASS**,
  sin fallos, skips ni resultados no ejecutados. Oráculos literales de spec, sin mocks de cálculo ni comparación
  contra la política para fabricar resultados esperados. Inventario1359 habilitadas; no se ejecutó toda la app.
  Resultado nativo cerrado: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/Test-FranAlonso-Develop-2026.10.02_13-35-07-+0200.xcresult`.
- Develop build-for-testing: PASS26,681s. Production build: PASS22,241s.
  Logs: `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133454.txt`
  y `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-133556.txt`.
  Cero warnings estructurados y cero warnings Swift/Clang. Los logs completos conservan el aviso histórico
  de appintentsmetadataprocessor: metadata omitida porque no existe dependencia AppIntents; no se declara cero
  avisos absolutos ni se introduce framework para silenciarlo.
- Diagnósticos de los dos archivos nuevos:0/0, ambos `success=true` mediante Xcode MCP.
- `validate_localizations.py`:561 entradas es/en,0 errores; catálogo sin cambios.
- Gobernanza: persisten únicamente los seis enlaces Desktop rotos conocidos de08.3, fuera del alcance.
- UI, previews y auditoría accesible N/A: no View, recurso visual, texto localizado ni flujo cambiado.

### Auditoría y estado

POST técnica y estilo Swift independientes: sin hallazgos en los dos Swift, recall2 archivos/0 candidatos
y revisión manual completa. Resultado nativo20/20 y logs finales contrastados por el revisor.
Huella operacional idéntica antes/después:799 archivos,
SHA256 `7b951260e6d2e720dc39b54e0fb27ea4af24d576e4aab70340dc5bebc7a78b2a`.
Único hallazgo P3 documental: Progress excedía8192bytes. Entrada nueva compactada, conservando detalle aquí;
Revisión documental focal posterior: PASS sin hallazgos; Progress8176≤8192bytes, historial intacto.
Huella documental antes/después idéntica:799 archivos,
SHA256 `1e8d67221418ce8a3e76cc46f29dcdd10945cdee90f624b3542802dbfc1f536c`.
Swift intacto, no requiere repetir builds/tests. Gobernanza final solo conserva seis enlaces08.3 históricos.
Entrega completa autorizada el02/10: «commit, push y entrega».
Se reutiliza la validación de esta sesión: los dos Swift conservan sus hashes, con cambios posteriores solo documentales.
Snapshots pueden quedar obsoletos:12.2 debe obtener/refrescar entradas sin mover la regla al Store.
12.2–12.8, pago atómico, movimientos y sync conservan gates separados. El análisis no acredita stock live.

### Entrega definitiva

[PR42](https://github.com/JFrancoG/FranAlonso/pull/42) MERGED el02/10.
Commit `01769e502f548c5cb5e42ca1353ee63333a0d323` → merge `029bc46b5cbc6bf1480cb61fc6241383ffe63b64`.
Árbol completo integrado idéntico al commit revisado; ningún cambio Swift/config tras validación.
Checks remotos y workflow runs vacíos, main sin reglas/protección requeridas: no se acredita CI remota.
Rama `codex/plu-86-sale-stock-impact` eliminada local/remota tras verificar ambos tips y ascendencia al main remoto.
PLU-86 Done; PLU-85 In Progress con12.1 entregada y12.2–12.8 pendientes. No se inicia12.2.
Este cierre solo modifica documentación; Xcode adicional N/A porque la fuente/config validada sigue intacta.


## 12.2 — Avisos de stock del Store

[PLU-87](https://linear.app/plusprojects/issue/PLU-87), Done, Jesus Franco, hija PLU-85.
Autorización02/10: «abre issue y rama e implementa12.2». Base limpia main/origin-main `a543125`;
rama `codex/plu-87-sale-draft-stock-warnings`. [Propuesta/PRE](12-2-stock-store-proposal.md): PASS independiente.
La entrega previa12.1 no extiende autorización a commit/push/PR/merge/cierre12.2.

### Implementación

`GetSaleStockQuantitiesUseCase` lee cada producto vinculado una vez por refresco, por orden de primera aparición,
mediante StockRepository existente; comprueba cancelación antes/después de las lecturas suspendidas.
Snapshot local secuencial, no atómico multi-producto y sin reserva, observaciones ni movimientos.
`SaleDraftStore` conserva venta/cálculo aceptados; proyecta por separado stockState idle/loading/ready/failed y
stockError. Create/load/edit aceptados invalidan avisos anteriores y refrescan en la tarea estructurada del caller,
delegando la regla a AnalyzeSaleStockImpactUseCase. Cantidad/eliminación/alta recalculan productos repetidos.
Stock conocido cero/negativo no bloquea; ausencia de lector/cantidad, overflow o fallo de lectura quedan en failed.
El error advisory no contamina lastError ni revoca el éxito durable. Cancelación advisory deja idle sin error.
Refresh público usa generación independiente y snapshot original: resultado/error obsoleto no sustituye el actual;
close/discard/ausencia invalidan la proyección. Edición rechazada conserva avisos del último borrador aceptado.
La edición conserva exclusión hasta completar el análisis; refresh manual no introduce operación de escritura.
ViewModel solo proyecta estado/delega refresh editable. Composición live/local/demo y preview interactivo inyectan
el mismo repositorio stock local. Constructores históricos/preview finito conservan capacidad opcional explícita:
con líneas físicas y sin lector -> failed/readerUnavailable; sin físicas -> ready([]), nunca stock inventado.
Sin modificación de View/texto/catálogo/configuración, sin pago/movimientos/sync ni activación live.

### Evidencia Xcode MCP

Service estable `workspace-PfnUYLlMzY`, Develop/planDevelop; Simulator iPadPro13(M5)27.2, SDK27.0,
iOS27/Swift6/nonisolated/strict complete/warnings-as-errors. Production verificado y Develop/destino restaurados.

- Baseline Store/concurrencia:49/49 PASS.
- RED antes de código: APIs UseCase/estado/refresh ausentes; fallo esperado de compilación de tests.
  Log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-135703.txt`.
- GREEN inicial16/16; final16 declaraciones/18 escenarios nuevos incluidos en regresión **153/153 PASS**,
  0 fallos/skips/expected failures/no ejecutados: Stock/Store/concurrencia/ViewModel/composición/demo/política/semántica.
  Oráculos literales independientes, barreras deterministas sin sleeps para latest-wins con éxito/error,
  edición/discard/close/cancelación tras aceptar. Recarga usa stock actual; refresh no reescribe venta;
  composición in-memorySwiftData verifica libro real compartido, cantidades actuales y solo movimientos explícitos.
  Resumen completo (MCP trunca inline a100):
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/30DF811C-B43A-40E9-8F5F-C20CA9887947.txt`.
  Resultado nativo cerrado real inspeccionado con xcresulttool (solo lectura):
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_14-03-30-+0200.xcresult`.
  107 declaraciones,24 parametrizadas/70 ejecuciones,153 resultados por dispositivo; runtimeWarnings vacíos.
  El xcresultBundlePath devuelto por MCP en ActionArtifacts no existe: se contrastó el bundle real de DerivedData.
- Develop build-for-testing22,128s + final incremental3,674s PASS; Production21,103s PASS.
  Logs `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-140157.txt`,
  `BuildProject-Log-20261002-140359.txt` y `BuildProject-Log-20261002-140434.txt` en la misma carpeta.
  Cero warnings Swift/Clang o estructurados; persiste aviso histórico appintentsmetadataprocessor de metadata
  omitida por ausencia de AppIntents.framework. No se declara cero avisos absolutos.
- Diagnósticos MCP de los6 Swift:0 cada uno, success=true. Dos fallos transitorios SourceEditor(error5) pasaron al reintentar.
- Catálogos561 es/en,0 errores; diff-check PASS. Gobernanza solo conserva seis links Desktop rotos08.3 históricos.
- Estilo recall6 archivos/1 candidato: firma edit con función aislada, previa al cambio; vertical preserva lectura.
  Inspección manual del diff y archivo nuevo, sin cambios oportunistas a estilo histórico.
- UI/previews/auditoría accesible N/A: no cambia pantalla ni presentación de avisos, asignada a12.3.
  Esta evidencia no valida VoiceOver ni la deuda previa ADR0029 y no cierra fase12.

### Auditoría y pendiente

POST independiente: sin hallazgos funcionales/arquitectura/datos/concurrencia. Un P3 lexical en7 closures
con efectos de tests (Task/finish/continuations) corregido expandiendo solo layout. Huella primera pasada
antes/después idéntica:802 archivos, SHA256 `1aaa2cf3d83a3ab3781e1fa843b65b12f20ad1bbd1deea72bdbc90ffba7439dc`.
Tras corrección, focal18/18 PASS (16 declaraciones/2 parametrizadas/4ejecuciones), native runtimeWarnings vacíos,
Develop build-for-testing3,926s y diagnóstico tests0 PASS. Código/config Production intactos desde validación;
no se repite Production ni regresión completa porque solo cambió whitespace en tests.
Resumen `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/9426CAB4-B851-4191-87CF-C91E674059CC.txt`.
Native real cerrado `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_14-10-43-+0200.xcresult`.
Build log `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-141133.txt`.
Re-auditoría lexical/documental focal independiente: sin hallazgos, P3 resuelto, POST PASS.
Recall test1 archivo/0 candidatos más revisión manual. Huella focal antes/después idéntica:
802 archivos, SHA256 `349877866fafa698adcef8d3d748e31afdcd7610125db949ff2b78adc940a9ff`.
Solo documentación de resultado posterior; fuentes/config idénticas a las validadas y auditadas.
PRE/POST/estilo PASS; no hallazgos abiertos para12.2.
Entrega12.2 autorizada el02/10: «commit, push y entrega.».
PLU-87 Done tras integración verificada. Fase PLU-85 abierta;12.3–12.8 conservan sus gates.
Se reutiliza la validación de esta sesión: al iniciar entrega se reconstruyó virtualmente el snapshot documental
anterior y su huella completa coincide exactamente con la auditada (802files/349877…): Swift/config/tests intactos.
Cambios posteriores solo documentan autorización/changelog/entrega; Xcode adicional N/A por ausencia de cambios
al código o configuración. Sin nuevas dependencias, excepción arquitectónica ni activación live.


### Entrega definitiva12.2

[PR43](https://github.com/JFrancoG/FranAlonso/pull/43) MERGED el02/10.
Commit `463de375ebead1dce691b5c37534080273c691c7` → merge `cf05c9c525f2f43963480246c6201aaddafb9002`.
Árbol completo de origin/main idéntico al commit entregado; ningún cambio Swift/config/tests tras validación.
Checks/workflow runs remotos vacíos; main sin protección/reglas requeridas: no se acredita CI remota.
Rama `codex/plu-87-sale-draft-stock-warnings` eliminada local/remota tras verificar ambos tips463de37 y ascendencia
al main remoto. PLU-87 Done; PLU-85 In Progress con12.1–12.2 entregadas y12.3–12.8 pendientes.
Cierre documental en main siguiendo la entrega anterior: CHANGELOG/Progress/fase, validadores y diff-check;
Xcode adicional N/A por ausencia de cambios al código/configuración. Gobernanza solo conserva seis links08.3 históricos.
No activa live, no cierra fase12 ni inicia12.3.

## 12.3 — Advertencia visual accesible

[PLU-88](https://linear.app/plusprojects/issue/PLU-88), In Progress/Jesus Franco, hija PLU-85.
Autorización02/10: «abre issue y rama e implementa12.3». Base limpia main/origin-main `a938332`;
rama `codex/plu-88-sale-stock-warning-ui`. [Propuesta/PRE](12-3-stock-warning-proposal.md) PASS independiente,
803archivos/huella antes-después idéntica `a2c49a5cadc7eb5fc45e544c5523cef980d79e5a24c72fdda541cd8b3a08b627`.
La entrega12.2 no autoriza entrega12.3. Sin commit/push/PR/merge/cierre ni activación live.

### Implementación y alcance

SaleDraftViewModel proyecta solo impactos negativos actuales desde ready editable/no cerrado, por SaleLineID.
No recalcula negocio ni duplica venta/cálculo/Store. Idle/loading/failed omiten avisos viejos sin afirmar suficiencia;
inspect/close no comunican. Deduplicación efímera ObservationIgnored por identidad: nuevos avisos producen un
mensaje; cambios de cantidad manteniendo déficit no repiten; ready sin déficit rearma; estados unknown conservan
dedup. Consumo solo al poder comunicar, no mientras se difiere una operación/sheet.
SaleDraftContent pasa impacto a SaleDraftLineRow; SaleStockWarningView presenta cantidad ya calculada, Label/
símbolo decorativo y texto es/en con ErrorInk adaptativo en cuatro apariencias, wrapping/font semántico.
Nombre accesible contiene mensaje visible y servicio; no acción ni rasgo bloqueante. Controles existentes disponibles.
Screen usa Announcement moderno existente: una comunicación propia tras aceptar (warning nuevo o éxito),
observación de stock sin request/sheets y retorno de selector/descuento. Sin nueva tarea/timer ni foco hacia el aviso.
Se conservan las restauraciones existentes; orden efectivo de habla/foco requiere AT real.
Tres claves/copy bilingüe y su inventario de tests compilados. Trait nuevo App/in-memory prepara async borrador
con ledger real: stock1, qty1 exact0, qty2 del mismo producto→-2 y profesional sin vínculo. Fixtures históricas
intactas. Constructor fileprivate de pantalla solo para su preview omite load inicial sobre modelo ya preparado;
inicializador de producción conserva comportamiento. Cada View afectada tiene preview propio con trait.
No cambios Domain/Data/Store/pago/movimientos/sync/config; confirmación no bloqueante corresponde a12.4.

### Evidencia técnica

Xcode MCP estable workspace-PfnUYLlMzY, SDK/target27.0, Swift6/nonisolated/strictcomplete/warnings-as-errors.
Tests y builds en iPadPro13(M5) Simulator27.2, Develop/planDevelop; Production verificado y Develop/destino restaurados.

- Baseline30/30 PASS. RED por proyección/consumo/copy ausentes antes de implementación:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-145137.txt`.
- GREEN focal37/37: seis declaraciones nuevas/siete escenarios incluidos. Identidades/repetidos/profesional,
  controles/total, loading/error/close/inspect, recuperación/readyexact0, dedup y mensajes es/en con contexto.
  Resumen `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/5485ED30-8D6E-493C-B090-8E7271B07D20.txt`.
- Regresión **191/191 PASS**, cero fallos/skips/expected failures/no ejecutados: stock/Store/VM/concurrencia,
  semántica/selección/descuentos/navegación/composición/Apppreview. Sin ejecución de toda la app.
  Resumen completo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/AACA70D2-4920-47B9-99F4-E6F7B4DD746A.txt`.
  Bundle nativo real cerrado inspeccionado con xcresulttool solo lectura:
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_15-00-14-+0200.xcresult`.
  128declaraciones/34parametrizadas/97ejecuciones parametrizadas,191resultados por dispositivo; runtimeWarnings vacío.
  xcresultBundlePath MCP en ActionArtifacts no existe; se contrastó DerivedData real.
- Recursos compilados **38/38 PASS** tras actualizar inventario; catálogos564 es/en/0errores.
  Resumen `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/AE42D380-0F55-4AFA-A160-747C97F1EAD4.txt`.
  Bundle real cerrado DerivedData/Logs/Test `Test-FranAlonso-Develop-2026.10.02_15-03-20-+0200.xcresult`:
  3declaraciones/38resultados por dispositivo, runtimeWarnings vacío, resultPassed.
- Develop build-for-testing19,689s, final4,126s PASS; Production22,164s PASS.
  Tras ajustar solo layout de llamadas nuevas, Develop18,441s y Production16,995s PASS; negocio/tests intactos,
  previews anteriores reutilizados por igualdad semántica. Logs finales:
  `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-150728.txt`
  y `BuildProject-Log-20261002-150745.txt` en la misma carpeta.
  Cero Swift/Clang/structured warnings; persiste metadata omitida de appintentsmetadataprocessor sin dependencia
  AppIntents.framework en logs completos, también en baseline histórico. No cero avisos absolutos.
- Diagnósticos MCP7Swift:0, success=true. Tests recuperados tras error transitorio SourceEditor(error5).
- Recall lexical7Swift/0candidatos y revisión manual; solo formato del cambio. Diff-check PASS.
  Gobernanza únicamente seis enlaces Desktop rotos preexistentes08.3, sin ampliación de alcance.

### Evidencia visual y deuda

[Registro completo55criterios y flujos](../accessibility/evidence/12-3-sale-stock-warnings.md).
Diez PNG originales conservados en su manifest: pantallaLarge/XXX Large/AX5, componente mismas variantes,
filaXXXL/AX5, contenidoLarge y cuarta apariencia. es/en/Light/Dark/contraste normal/aumentado representativos.
Render host iPhone18ProMax27.2, destino workspaceiPhone17; iPad original falló dyld/libSystem antes del cambio.
No limpieza destructiva de caches/simuladores ni modificación target. Modelo async preparado; captura inicial de
pantalla mostró carga y se corrigió solo el constructor de preview para mostrar estado listo determinista.
Aviso completo aisladoAX5; fila/formulario requieren scroll real; título nativo truncadoAX5 conserva **Falla**.
Inspector/VoiceOver/VoiceControl/SwitchControl/FKA, habla/foco, scroll/superficies/contraste medido,
orientación/ventanas/iPad/preferencias/RTL permanecen Pendiente/Limitado.
Deuda nueva [PLU-89](https://linear.app/plusprojects/issue/PLU-89), Backlog/Jesus, vinculadaPLU-88 y fasePLU-85:
recuperar tras feedback y estabilización de cada recorrido, siempre antes del primer candidato real.
Deuda histórica11 separada; esta evidencia no valida accesibilidad integral ni cierra la fase.

### Auditorías y estado

POST técnica/estilo independiente stock_ui_post_standards: PASS sin hallazgos, recall7/0 más manual.
La creación inicial de reviewerUI alcanzó el límite de agentes; una inspección complementaria con reviewerPRE12.1
reutilizado no sustituyó el gate. Posteriormente se creó correctamente el hijo fresco
stock_ui_post_standards/fresh_ui_post, rol ios-accessibility-reviewer: sin otros defectos de fuente/copy/previews.
Único P2 documental compartido: afirmación de operabilidad de demo sin smoke; retirada, manteniendo pendiente
la comprobación antes de entrega. No se acredita gate completo de entrega funcional ni accesibilidad integral.
Read-only operacional probado porroot antes/después de ambos:817archivos,
SHA256 `1e0302304a197859cdedd478e462beca677ec0f094a44c486ef0253cbbd3737f` idéntico.
Revisión documental focal independiente posterior PASS: P2 corregido, sin hallazgos adicionales.
Huella antes/después817archivos idéntica `f8b2ebf2e918522a67d130ea84a81e04f9458b7fad3f3c22578a7b9302630eaa`.
Fuente/copy/previews favorables; el smoke pendiente de este POST se completó después, según registro siguiente.
Swift/config/tests/PNG intactos, no requiere repetir validaciónXcode por el cierre documental de esta implementación.
### Smoke táctil retomado — 02/10

Usuario: «Ya está desbloqueado, termina las pruebas». Instalado el Develop ya validado por Xcode MCP en
Simulator iPhone17/iOS27.2, bundle com.plusprojects.FranAlonso.develop, argumento --franalonso-demo-workday.
Composición local real con ModelContainer in-memory, datos sintéticos y runtime nil; sin activación externa.
Portrait/light, content_size extra-Small consultado con simctl ui; no se cambiaron preferencias del usuario.
RocketSim: toques HID y swipes con guard de snapshot, lectura AX y cuatro PNG originales inspeccionados.
CUA permitió omitir la propuesta de guardar credencial sintética; distribución del teclado requirió corregir
@/guiones y verificar la entrada. CUA volvió a informar bloqueo del Mac; RocketSim continuó operativo y
completó el recorrido. No se guardó credencial, ni se alteró la composición para evitar autenticación.

PASS funcional focal: profesional sin aviso; físico qty1 sin aviso, qty8 exact0 sin aviso, qty9→-1 y qty10→-2;
reducción10→9→8 retira aviso, aumento8→9 lo recupera. Stepper y edición funcionan con déficit, sin bloqueo.
Descuento de línea10% aplicado: qty9/aviso-1 conservados; selector abierto/cancelado conserva estado.
Añadir segunda línea del mismo producto qty1 publica impacto acumulado-2; primera mantiene-1.
Cerrar/reabrir borrador conserva tres servicios, cantidades9/1 y descuento10%; avisos se recalculan al abrir.
Solicitud de retirar segunda línea abierta y cancelada tocando fuera del popover: sin retirada, estado conservado.
No se ejecutó pago/confirmación12.4 ni se acreditan movimientos por este smoke.

[Evidencia runtime](../accessibility/evidence/12-3-sale-stock-warnings.md#smoke-táctil-funcional)
y [manifest](../accessibility/evidence/assets/12-3/runtime/manifest.json): PNG originales, snapshots y transiciones
JSON sin contexto del protocolo/token local. Es interacción táctil en Simulator, no prueba física ni AT/foco/habla.
El bloqueo inicial queda resuelto para el gate funcional; accesibilidad integral/FallaAX5 permanecen en PLU-89.
Swift/config/tests/previews intactos: se reutilizan191/191,38/38 y builds ya cerrados; no hay motivo de retestXcode.
Revisión focal independiente fresh_ui_post PASS sin hallazgos:4PNG/5JSON,9/9 hashes correctos.
Huella root antes/después827archivos idéntica:
`08e5391c50e2f6553f628a3da40bccd54d05cbc2f377e99cb1c0448f505b7adc`.
Gate funcionaldemo respaldado para esta configuración; registro integral mantiene42Limitado/11Pendiente/2Falla.
Localizaciones564/0errores y diff-check PASS; gobernanza conserva solo seis enlaces históricos08.3.
PLU-88 In Progress; PLU-85 abierta.
Implementación y smoke completados; autorización de entrega recibida después, según registro siguiente.
12.4–12.8 mantienen gates separados.

### Preparación de entrega 12.3 — 02/10

Entrega completa autorizada: «commit, push y entrega», siguiendo la integración de12.1–12.2.
Snapshot revisado827archivos reproducido exactamente mediante reversión virtual de los únicos dos registros
posteriores de auditoría: SHA25608e5391c50e2f6553f628a3da40bccd54d05cbc2f377e99cb1c0448f505b7adc.
Swift/config/tests/PNG no cambiaron después de validación; se reutilizan buildsDevelop/Production,
191/191,38/38,previews y smoke de esta sesión. Audit estilo pre-PR7Swift/0candidatos más manual sin hallazgos.
Cambios nuevos únicamente autorización/changelog/entrega; Xcode adicional N/A por alcance documental.
PLU-89 conserva explícitamente validación integral/defectos aplazados, Jesus Franco, antes del candidato real.
PLU-88 permanece In Progress hasta integración; PLU-85 abierta, sin live ni inicio12.4.

### Entrega 12.3 verificada — 02/10

[PR44](https://github.com/JFrancoG/FranAlonso/pull/44) MERGED02/10.
Commit `d6d0b99dafd86e385843b1450aa15010483193ce` → merge `c845c83d18279e13a945ba66b35431c6e97035f6`.
Árbol completo de origin/main idéntico al entregado; HEAD de PR y remoto verificados antes de merge.
GitHub mergeable/CLEAN y sin checks configurados: no se presenta CI inexistente como PASS.
Se reutiliza validación local cerrada indicada arriba; ningún cambio ejecutable posterior.
Ramas local/remota eliminadas después de verificar inclusión y ausencia de commits únicos.
PLU-88 Done funcionaldemo por ADR0029; PLU-89 Backlog/Jesus conserva42Limitado/11Pendiente/2Falla,
recuperación tras feedback/estabilización antes candidato real. PLU-85 In Progress con12.1–12.3 entregadas.
Cierre documental en main siguiendo12.1–12.2: CHANGELOG/Progress/fase/registro accesible, diff-check y gobernanza.
Xcode adicional N/A: solo documentos; seis enlacesDesktop08.3 históricos permanecen, sin nuevos fallos.
Sin activación live, cierre integral de fase ni inicio12.4.

## 12.4 — Confirmación no bloqueante (PLU-90), Done funcional para demo

Autorización02/10 «abre issue y rama e implementa12.4» y ampliación «si, adelante»:
[PLU-90](https://linear.app/plusprojects/issue/PLU-90), Jesus Franco, hija85. Rama
`codex/plu-90-sale-stock-confirmation` desde main/origin-main limpios `a222513`.
[Propuesta exacta](12-4-stock-confirmation-proposal.md), alternativas y fuentes Apple antes de código.
PRE independiente stock_confirmation_scope_pre PASS sin hallazgos;828archivos SHA256 root antes/después idéntico
`16dceb9336254cdecb446d512b8cb910a8f2dff0629df0b54127212591938e43`.

### Comportamiento implementado

Aceptación de progreso Domain/Data contra expected/current, replay sin cola extra, stale/conflicto/deleted rechazados
y rollback local existente. Sin nueva persistencia/schema/SDK. Store único retiene snapshot y cálculo; transición
iniciada revoca edición comercial. Jornada .operate conserva sesión; .inspect permanece sin mutaciones.
Inicio/fin de servicios y selección de método conducen al pago11.8 pendiente de documento.
Refresco advisory sin escritura; déficit y stock desconocido piden permiso explícito. Mostrar/cancelar/repetir no
aceptan operaciones; Continuar consume identidad una vez. Comando ID/método/fecha congelados para retry; close,
callbacks viejos y carga diferente quedan fenced. Éxito local tardío permanece éxito sin reabrir presentación.
UI nativa con sheet scrollable, retorno de foco declarativo,13claves es/en y previews por View.

### TDD, regresión y builds

RED18:06:51 de compilación por APIs ausentes (no RED ejecutado):
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20261002-180651.txt`.
GREEN19/19ejecuciones17declaraciones, suites SaleWorkflow/ProgressAcceptance; bundle nativo cerrado18:18:37.
Oráculos SwiftData frescos: venta/cola/movimientos, stale/dirty/conflicto/deleted/collision rollback/replay,
cash/card,unknown/exacto0, cancel/repetir, retry mismaID/fecha, concurrencia/close/callback tardío.

Regresión inicial123/130:7expectativas antiguas inspect/cierre al iniciar; ajustadas al contrato autorizado.
Posterior32/32 navegación/workflow. Regresión final **295/295 ejecuciones,170declaraciones,16suites**
(incluye38/38 recursos),02/10iPhone17Simulator27.2/Develop. Resumen
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/1139FC3B-A462-4316-8F90-D94B037464A4.txt`.
Bundle nativo cerrado inspeccionado con xcresulttool:0failed/skipped/expected/notRun, runtimeWarnings[]:
`/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_18-31-31-+0200.xcresult`.

Builds Xcode MCP **Develop-for-testing PASS**18:37:37/25.040s, iPadPro13(M5);
**Production PASS**18:33:26/23.765s, iPhone17. Swift6/complete/SDK y target27.0.
Logs `BuildProject-Log-20261002-183737.txt` y `BuildProject-Log-20261002-183326.txt` en ActionArtifacts/BuildProject.
GetBuildLog severitywarning0diagnósticos; logs completos conservan aviso conocido appintentsmetadataprocessor
“Metadata extraction skipped, no AppIntents.framework dependency found”. No se afirma cero avisos absolutos.
Sin xcodebuild/XCTest/XCUITest/UI tests nativos.

### Accesibilidad y comprobaciones

[Registro12.4](../accessibility/evidence/12-4-sale-stock-confirmation.md): matriz55,10PNG originales con
manifest/hashes, es/en Large/XXX Large/AX5 y apariencias representativas. Host real iPhone18ProMax27.2;
iPad privado de previews falla dyld/libSystem antes de código; workspace temporal iPhone17, luego restaurado
a Develop/iPad original. Falla AX5 título nativo/placeholder Picker, ejecución integral pendiente.
[PLU-91](https://linear.app/plusprojects/issue/PLU-91), Backlog/Jesus, deuda específica tras feedback/estabilización
por flujo y antes del primer candidato real. PLU-89 permanece separada; no cierre integral de fase.
Smoke táctil funcional PASS (inicio/fin, cash, cancelar/repetir/continuar, cerrar/reabrir);
auditorías POST funcionales PASS tras correcciones. Source-style recall24Swift,6candidatos históricos
closures/predicates fuera del cambio; adjudicación manual independiente PASS. Localización577entradas0error; diff --check PASS.
Gobernanza conserva únicamente6enlaces Desktop históricos08.3; ninguna incidencia nueva.

Al terminar implementación, entrega aún no autorizada. Sin movimientos12.5, atomicidad12.6, sync/compensación12.7/12.8,
documento13 ni live. PLU-85 y90 permanecen In Progress.

### Correcciones de auditoría y regresión final

POST técnica confirmation_post_standards inicial:2P2 recuperación y1P3 formato. Huella856archivos anterior/posterior
idéntica `c2d8ca22b79ba484a27019a1b4de67f6191fbc42bff740c9be2f3d42442ab110`, root verificado tras final.
Propuesta de corrección revisada read-only por ese especialista: lifecycle hasCreatedSale distingue reserva sin
lectura de creación aceptada; load posterior recupera misma identidad, ausencia no reaparece como nueva creación.
requiresDraft/staleDraft de edición requieren recarga igual que staleSale, conservando fencing/composición aprobados.
RED real4/17failures en suiteWorkflow18:51:22,13casos previosPASS:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/E188EB26-E106-4140-8613-426CD71B7870.txt`.
Se corrigieron ambos defectos y if mutadores/calls4args nuevos con formato obligatorio.

Regresión final **299/299 ejecuciones,173declaraciones,16suites**, Develop/iPadPro13(M5)Simulator27.2:
`/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/RunSomeTests/6FE7A583-45F4-456A-8D06-5D8FF083E9D6.txt`.
Bundle nativo cerrado con finishTime,0failed/skipped, runtimeWarnings[]:
`/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.10.02_18-52-51-+0200.xcresult`.
Incluye23ejecuciones20declaraciones nuevas12.4; snapshots frescos recuperan cambio comercial/progreso externo;
la sesión creada rechaza recrear después de ausencia persistente. Build-for-testing18:52:51/20.171sPASS;
Production18:53:49/24.064sPASS en iPad original; diagwarning0Swift/Clang, aviso metadata conocido retenido.
Revisión focal técnica y primera UI fresca sobre correcciones PASS. No se reutiliza auditoría12.3.

### Dictámenes finales y frontera de entrega

confirmation_post_standards focal: PASS sin hallazgos residuales;2P2+P3 iniciales corregidos y verificados.
confirmation_post_accessibility_fresh, rol ios-accessibility-reviewer: PASS funcional ADR0029;2P2 AX5
(selector/título truncados) conservados Falla en PLU-91. Diez previews,2PNG+4JSONruntime y hashes inspeccionados;
matriz55/5flujos revisada, owner/trigger de deuda verificados en Linear. Sin AT/Inspector/habla/foco/ratio medido
ni dispositivo físico; no acredita scrollAX5. Evidencia integral pendiente, fase12 abierta.
Ambos revisores exclusivamente read-only con prohibición explícita de escribir/Git/publicar. Huella root856archivos
ante/post idéntica `04b562137fd0907129d40ccd2cb09001f897d3a10d1ab2e0a3b085db3ca2fa46`,
verificada tras ambos dictámenes antes de reconciliación documental.
Build Develop-for-testing final18:54:50/26.553sPASS, log `BuildProject-Log-20261002-185450.txt`;
Production final18:53:49PASS; workspace originalDevelop/iPadPro13(M5) restaurado.
Snapshot previo a autorización de entrega: implementado y validado; PLU-90 In Progress, PLU-91 Backlog/Jesus.
Sin commit/push/PR/merge/Done, sin live ni siguiente subfase.

### Preparación de entrega autorizada

Autorización02/10 «commit, push y entrega»: commit/push/PR e integración funcional siguiendo12.1–12.3.
Preflight: el snapshot auditado de856archivos reproduce exactamente el SHA256 `04b562137fd0907129d40ccd2cb09001f897d3a10d1ab2e0a3b085db3ca2fa46`
al revertir virtualmente solo la reconciliación documental posterior. Código/tests/recursos/config y capturas intactos;
se reutilizan299/299, ambos builds finales y auditorías PASS. Recall precommit24Swift/6candidatos históricos,
sin cambios respecto al dictamen manual independiente. CHANGELOG registra el comportamiento entregable.
Sin cambios locales ajenos. PLU-90 sigue In Progress hasta merge; PLU-91 Backlog y PLU-85 In Progress.
Sin live, cierre integral ni inicio12.5. Las menciones anteriores a falta de autorización son históricas.

### Entrega definitiva 12.4

[PR45](https://github.com/JFrancoG/FranAlonso/pull/45) MERGED02/10/2026 17:08:39UTC a main.
Commit `74fb8442d5a36cf5c5028a9aa79a07e611a5df8a` → merge `4973e37ca750fdebbaa5978c3135850fa6717c90`.
Árbol completo integrado idéntico al commit validado; main/origin-main sincronizados y limpios tras merge.
PR revisada:49archivos previstos, head remoto/local idéntico, MERGEABLE/CLEAN; ningún check ni review obligatorio,
main sin protección requerida. No se acredita CI remota. Merge normal con comprobación del head esperado, sin force.
Rama `codex/plu-90-sale-stock-confirmation` eliminada local/remota tras verificar ascendencia y cero commits únicos.

Linear reconciliado tras merge: PLU-90 Done funcionaldemo; PLU-91 Backlog/Jesus retiene toda deuda y trigger;
PLU-85 In Progress con12.1–12.4 entregadas,12.5–12.8 pendientes. Descripciones operativas actuales y evidencia
vinculadas; decisión de ampliación y recuperación RED/GREEN preservadas en propuesta/fase y comentario de cierre.
Se reutilizan299/299ejecuciones, ambos builds finales y auditorías independientes: código/tests/recursos/config
intactos y árbol integrado idéntico. Source-style recall precommit24Swift/6candidatos históricos sin cambios.
Localización577/0 y diff-check PASS; gobernanza solo seis enlacesDesktop08.3 preexistentes, sin nueva incidencia.

Cierre documental directo en main siguiendo12.1–12.3: CHANGELOG,Progress,fase12 y registro accesible actualizados.
Xcode adicional N/A por cuatro documentos únicamente; no modifica evidencia original ni criterios de validación.
Sin cierre integral, activación live, movimientos/atomicidad/sync posteriores ni inicio12.5.
