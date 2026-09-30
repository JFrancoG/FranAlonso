# Corrección transversal de localización — 2026-09-30

## Alcance autorizado

El propietario solicita completar el inglés y comprobar que no falte texto en español ni inglés tras observar claves
`authentication.login.*` en el login de su iPhone configurado en inglés. Referencias: spec02/02.5, spec06/06.6,
spec07/07.7, spec08 y ADR0011/0028/0029. No inicia otra fase. El propietario autoriza después commit y push;
no autoriza cambios operativos en Linear.

- `Localizable.xcstrings`: 333 textos; 182 traducciones inglesas añadidas.
- `DocumentTemplates.xcstrings`: 75 traducciones inglesas añadidas; el manifiesto sigue autorizando solo `es`.
  Versiones, contenido español, PDFs y documentos firmados permanecen intactos. No se habilita emisión inglesa.
- `InfoPlist.xcstrings`: aviso Face ID en ambos idiomas. Las dos identidades `CFBundleDisplayName`/`CFBundleName`
  usan `shouldTranslate: false`: el nombre efectivo depende de Develop (`Fran DEV`) o Production (`Fran Alonso`).
- `knownRegions` registra `en` y conserva `es`, `Base` y el cambio local previo del propietario a iOS27.
- El propietario confirma que los dispositivos de Fran ya usan iOS27 y autoriza alinear los tests: las cuatro
  configuraciones Debug/Release Develop/Production de `FranAlonsoTests` usan mínimo27, igual que la app.
  Los overrides de target prevalecen sobre el valor base26 del proyecto. No se adoptan APIs nuevas en este cambio.
- Inventario test-only de409 claves; Swift Testing comprueba su presencia real en las tablas compiladas es/en,
  lookup explícito, ausencia de claves/vacíos, identidad por entorno y copy independiente de los15 textos del login.
- `scripts/validate_localizations.py` comprueba ambos idiomas, estados, valores, placeholders, igualdad bidireccional
  del inventario/tablas, idiomas del proyecto y literales UI directos no catalogados.

## Validación final local — 2026-09-30

- Xcode27.0 Service, Simulator iPhone17/iOS27.2; targets app/tests mínimo27. Builds-for-testing Develop/Production
  PASS; cero errores/warnings Swift/Clang e issues estructuradas. Logs completos conservan solo el aviso previo de
  extracción AppIntents omitida por ausencia de dependencia; no se presenta como cero warnings absolutos.
- Suite completa Develop: MCP1.602 resultados PASS. Regresión focal inicial68/68, incluyendo38 casos nuevos de
  localización. Suite completa Production: MCP1.552 resultados PASS,11 entradas de fixtures exclusivas Develop
  sin resultado bajo el guard de compilación. Native xcresult confirma PASS/cero fallos en ambas suites.
  Native registra1.602 casos en Develop y1.513 en Production;1.085/1.035 declaraciones respectivamente.
  Los recuentos MCP incluyen resultados agregados; no equivalen a casos ejecutados únicos.
- Production: los38 casos de localización pasan; tabla compilada de409 textos ×2 idiomas, copy del login,
  identidad configurada y fixture ausente del bundle app. Después de la restauración del nombre por entorno,
  build Develop PASS y retest focal MCP27 resultados PASS; native26 casos/13 declaraciones, cero fallos.
  El runner focal no repitió todos los argumentos originales.
- Nombre efectivo comprobado: Develop `Fran DEV`, Production `Fran Alonso`, mínimo27. El propietario autorizó
  restaurar `$(APP_DISPLAY_NAME)` en las cuatro configuraciones tras detectar un override local nuevo `Fran DEV`.
  No se debilitó el test para aceptar un nombre incorrecto en Production.
- Seis previews del login es/en × Large/XXX Large/AX5 PASS: texto traducido y jerarquía legible. Destino real de
  render iPhone18ProMax/iOS27.2, distinto del Simulator de tests. Large/XXX Large claros; AX5 oscuro y layout apilado.
  La Form es desplazable; un snapshot no demuestra operación, foco, VoiceOver o accesibilidad integral.
- Xcode volvió a Develop/iPhone11 y conservó ambos planes originales. Sin app live ni sesiones de interacción.
- Incidencias resueltas de validación: tras cambiar el proyecto, una petición no calculó el grafo de dependencias;
  la recarga también reinició la selección y un run acabó en Develop/iPhone físico.13 tests de lectura de archivos
  del Mac fallaron ahí. La selección explícita posterior en Simulator completó la validación. No se modificaron
  esos tests históricos ni se atribuyeron esos errores a traducción o comportamiento de producto.
- Catálogos/checker/diff PASS. Gobernanza conserva solo los seis enlaces históricos rotos de capturas08.3;
  el resumen Progress respeta el límite8192 bytes. Revisiones estáticas previas favorables.
  La deuda accesible histórica conserva su registro; este cambio no cierra una fase ni acredita revisión jurídica.

Artifacts Xcode locales: Develop suite `Test-FranAlonso-Develop-2026.09.30_16-28-42-+0200.xcresult`, Production suite
`Test-FranAlonso-Production-2026.09.30_16-32-31-+0200.xcresult`; builds finales `BuildProject-Log-20260930-163214.txt`
y `BuildProject-Log-20260930-163407.txt`. Los logs de build viven bajo `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/BuildProject/`;
los bundles nativos durables verificados, en `~/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/`.

## Revisiones finales independientes

Revisores iOS/estilo y localización/accesibilidad: dictamen técnico favorable. El revisor iOS detectó un P3 documental:
retest final con recuento MCP agregado presentado sin distinción; corregido arriba a27 resultados MCP/26 casos nativos.
El revisor de localización inspeccionó las seis capturas sin claves, truncamientos textuales ni hallazgos P0–P3.
No se acredita operación del desplazamiento ni tecnologías de asistencia por esas capturas.
Ambas revisiones fueron read-only, con huellas Git tracked/untracked PRE=POST:
`b7a4b62bbb1ec7cb5ef86a9df924f911b20551c020bed044a5e42b57513c50e4`.
Relectura focal iOS del ajuste documental: P3 resuelto, dictamen favorable; PRE=POST:
`164e091dc5ba9d7e6c315dbd827f0ec51b2149aecfc16fb36b5b87d9ca3426a1`.

## Historial de preparación y bloqueos superados

- Revisión PRE independiente favorable después de excluir nombres de bundle de la traducción. Modo operacional
  read-only: huella Git tracked/untracked pre/post idéntica
  `e9fae3525f37852c6ba03d0208fcaf713f1442d614abd50f028bcbf6b3adf137`.
- RED estático:519 errores con catálogos originales (ausencias inglesas y diagnósticos derivados). GREEN estático:
  **409 entradas ×2 idiomas, cero errores**. `git diff --check` PASS.
- Comparación Codable/JSON del contenido contra HEAD: todo español y las151 traducciones inglesas previas intactos;
  claves iguales y manifiesto jurídico idéntico. Lectura focal de UI: los literales verbatim son prompts vacíos;
  nombres de cliente/producto/servicio son datos, y etiquetas/estados usan recursos localizables.
- Xcode27.0 Service, workspace FranAlonso, esquema Develop. Baseline del último build anterior al cambio exitoso;
  cero issues estructuradas, pero log completo conserva el aviso AppIntents conocido de extracción omitida.
- Build-for-testing bloqueado antes de compilar los tests nuevos: app local iOS27, test target iOS26;
  `Compiling for iOS 26.0, but module 'FranAlonso' has a minimum deployment target of iOS 27.0`.
  No es un RED de comportamiento. El propietario autorizó la alineación y se corrigieron las cuatro configuraciones;
  revisión PRE/POST favorable, huellas respectivas pre/post idénticas:
  `7e228424e3c0095e5f0c4a21f749c19cdb5e214e95e42906fc04ac7774c53998` y
  `a216de48423a6fbb7dd6e3b02285ec402d3f9529d05ab984a254d8135d3f9d71`.
- La compilación tras editar catálogos fue cancelada por interacción manual en Xcode. Reanudación solicitada;
  no se presume éxito ni se siguen ejecutando operaciones de Xcode mientras la respuesta esté pendiente.
  Después de autorizar la alineación, el reintento build-for-testing también fue cancelado por Xcode en1,507s
  (`BuildProject-Log-20260930-142940.txt`). Se detuvieron las operaciones y se preguntó cómo proceder.
  El destino Service al retomar era Develop/iPhone11 por selección posterior del propietario; la validación lo cambió
  temporalmente a iPhone17. Restaurar Develop/iPhone11 al retomar/finalizar, conservando el plan Develop.
- En ese punto, tests ejecutados, bundle final y previews es/en seguían pendientes; completados arriba.
- Revisiones POST independientes iOS/estilo Swift y localización/accesibilidad: **sin hallazgos P0–P3 estáticos**.
  Huella tracked/untracked pre/post idéntica:
  `4289fb1b9dd0f464d6fa710ba7115406d07c666ca51746ccf33c8a9fcf733f3d`.
  La revisión de textos dinámicos complementa el escáner regex; este no demuestra ausencia futura de textos indirectos.
  Controles negativos del checker sobre copia temporal: eliminar traducción en/es del login falla; restaurar pasa.
  No se declara cierre funcional ni accesibilidad integral.

## Límites y siguiente paso

El propietario autoriza el 2026-09-30 commit y push de esta corrección validada en `main`.
PR, merge, cambio de estado en Linear y activación live quedan fuera del alcance.
El tracker mantiene los estados verificados:
PLU-32 Done (catálogo español histórico), PLU-25 In Progress; no se cierra ninguna fase con esta corrección.
La localización del catálogo legal no equivale a revisión jurídica ni habilita un idioma de firma nuevo.
La deuda accesible histórica conserva sus issues/matrices y no se declara resuelta por traducciones.

Fuentes primarias consultadas con Xcode DocumentationSearch:
[String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog),
[Bundle lookup](https://developer.apple.com/documentation/foundation/bundle/localizedstring(forkey:value:table:)).

La entrega Git reutiliza los builds, suites y auditorías anteriores: desde esos checks solo cambian el registro
de autorización y el changelog. Xcode adicional: N/A para ese ajuste exclusivamente documental.
