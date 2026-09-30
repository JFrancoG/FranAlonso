# Organización de App — PLU-69

## Alcance y autorización — 2026-09-30

El propietario pide ordenar App en carpetas identificables. Es un cambio transversal independiente de las fases funcionales.
[PLU-69](https://linear.app/plusprojects/issue/PLU-69), responsable Jesus Franco, está Done tras
[PR31](https://github.com/JFrancoG/FranAlonso/pull/31). Rama `codex/plu-69-organize-app` eliminada;
base inicial limpia `main/origin/main` en `5246815`.
Autorizadas inicialmente la reorganización y su validación. El propietario amplía después la entrega a todos los cambios,
incluida su actualización de Firebase, y autoriza commit, push, PR, merge y cierre de issue y rama el 2026-09-30.
Autoridad: constitución, specs 02/03, ADR 0011, política Swift y guía de desarrollo. No requiere un ADR nuevo:
se conservan los límites entre capas y las responsabilidades existentes.

## Propuesta aprobada y aplicada

Conservar `FranAlonsoApp.swift` como única entrada Swift en la raíz y mover 29 archivos sin alterar su contenido:

| Carpeta | Responsabilidad y archivos |
|---|---|
| Startup | AppDelegate, ApplicationLaunchPlan: arranque y elección de perfil. |
| Composition | ApplicationComposition, AppRuntime, ClientDocumentComposition: composición y vida de dependencias. |
| Composition/Dependencies | AppDependencies y sus cinco extensiones, AppEnvironment: factories e inyección SwiftUI. |
| Persistence | AppModelSchema, ClientDocumentsSchema, StockMovementsSchema, PhaseFiveSchemaMigrationPlan, ModelContainerFactory. |
| Presentation/Authentication | AuthenticationRootScreen y AuthenticationRootViewModel. |
| Presentation/Shell | AppShellScreen y AppShellViewModel. |
| Presentation/Catalog | CatalogScreen y CatalogViewModel. |
| Development | DevelopAuthenticationFixture y los cinco archivos DevelopDemo*. |
| Navigation y Previews | Organización y archivos existentes conservados. |

AppEnvironment distribuye dependencias; AppRuntime administra la composición durante toda la vida de la app.
Alternativas descartadas: carpetas separadas Screens/ViewModels dispersan cada pareja; trasladar factories a Features
confunde la frontera App → Data/Presentation; una jerarquía más profunda añade navegación innecesaria.
Se eligen carpetas por responsabilidad y pantalla. [Mapa vigente](../design/app-organization.md).

Movimientos realizados mediante XcodeMakeDir/XcodeMV. El target conserva su grupo sincronizado y su membresía.
Las fuentes trasladadas no dependen de rutas de archivo. La reorganización no modifica plist, recursos, settings,
proyecto ni schemes; la actualización posterior de la dependencia se registra por separado debajo.
Actualizadas las rutas literales de BuildEnvironmentConfigurationTests, con las mismas aserciones, dos enlaces de
07-7-localization y las ubicaciones vigentes de docs/design/navigation. Las menciones históricas conservan su contexto.

## Validación — 2026-09-30

- PRE independiente: PASS, sin hallazgos, antes de mover código. Auditor operativo de solo lectura;
  manifiesto anterior y posterior idéntico: 671 archivos,
  SHA-256 `b0d4c91651e3c8149150ef27d082b3f1e911e35b08f43842d88decc5f6b33db7`.
- Verificación de contenido: los 41 archivos Swift de App conservan SHA-256 idéntico al baseline;
  exactamente 29 destinos previstos, sin duplicados, archivos perdidos ni fuentes Swift adicionales.
  XcodeLS confirma las nuevas ubicaciones y la única entrada Swift en raíz.
- Xcode MCP estable, workspace `workspace-TYwVLEuhvO`; target iOS 26, SDK 27, Swift 6,
  strict concurrency completo y warnings como errores, sin cambios de configuración.
- Build Develop con tests: PASS, 24,593 s. Log `BuildProject-Log-20260930-080400.txt`.
- GetTestList descubre 1.082 declaraciones. RunSomeTests ejecuta únicamente la suite existente
  BuildEnvironmentConfigurationTests: **13/13 PASS**, sin omisiones ni fallos.
  Resumen `2143CF4A-A457-4A22-9240-4F7C60C96764.txt`;
  bundle `Test-FranAlonso-Develop-2026.09.30_08-04-28-+0200.xcresult`.
- Build Production: PASS, 28,256 s. Log `BuildProject-Log-20260930-080552.txt`.
  GetBuildLog warning no devuelve incidencias; los logs completos conservan únicamente el aviso conocido
  de appintentsmetadataprocessor: extracción omitida al no existir dependencia AppIntents.framework.
- Develop restaurado. Xcode selecciona iPhone 18 Pro Max; el destino inicial iPhone 18 Pro ya no aparece
  en la lista elegible actual. No se han creado, eliminado ni reconfigurado simuladores.
- Auditoría de estilo del test modificado: cero candidatos. Solo cambia su ruta literal y el salto de línea
  de una tupla que excedería 120 columnas. `git diff --check`: PASS.
- Gobernanza: persisten únicamente los seis enlaces históricos de capturas 08.3 ya rotos antes del cambio.
  No se introducen enlaces rotos ni cambios en rutas sensibles.
- POST independiente: PASS, sin hallazgos. Revisados los movimientos contra HEAD, las rutas, los logs completos
  y el xcresult nativo cerrado: 13/13 PASS, sin omisiones ni runtime warnings. Destino efectivo de tests:
  iPhone 18 Pro Max con iOS 27.2; SDK de compilación 27.0.
  Auditoría operacional de solo lectura; manifiesto anterior y posterior idéntico: 672 archivos,
  SHA-256 `cf82532aec18210b9f5cfa60a19c9b4904ee442cbed77aff12b45fb4a4568f5c`.

Los artefactos de Xcode están en `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`,
subcarpetas BuildProject y RunSomeTests. Son evidencia local temporal.

## Límites y estado

TDD nuevo N/A: no hay comportamiento ni tests nuevos. La prueba de regresión usa las aserciones existentes.
Previews y matriz AT nuevas N/A para estos movimientos de fuentes idénticas; no cambian UI, textos, recursos ni interacción.
La evidencia y deuda accesible previas siguen vigentes: este trabajo no acredita conformidad integral ni cierra fases.
No cambia arquitectura, schema, migraciones, módulos aprobados, unsafe, live ni Foundation Models.
Bootstrap, Features, Shared y Telemetry conservan sus archivos; no se reordenan tests.
Entrega completa autorizada, validada e integrada. PLU-69 Done confirmado tras el merge.

## Actualización de Firebase y entrega conjunta — 2026-09-30

El propietario actualiza la regla de Firebase de mínimo 12.18.0 a 12.19.1, manteniendo `upToNextMajorVersion` (<13.0.0).
Package.resolved fija Firebase y GoogleAppMeasurement 12.19.2, GoogleAdsOnDeviceConversion 3.7.0,
GoogleDataTransport 10.1.1, GoogleUtilities 8.1.3 y GTMSessionFetcher 5.3.1. Los otros siete pins no cambian.
Son versiones de dependencias ya aprobadas: no se incorporan módulos ni paquetes nuevos.

Fuentes oficiales: [Firebase 12.19.2](https://github.com/firebase/firebase-ios-sdk/releases/tag/12.19.2),
[12.19.1](https://github.com/firebase/firebase-ios-sdk/releases/tag/12.19.1) y
[notas de Firebase](https://firebase.google.com/support/release-notes/ios).
12.19.1 corrige el nombre del ZIP; 12.19.2 corrige un fallo de Analytics y se distribuye por SwiftPM.
Los seis pins modificados se han contrastado con sus tags remotos oficiales; no hay SHAs inexistentes.

La resolución local fallaba por objetos Git ausentes (`unable to read tree`). Tras autorización concreta se trasladó
únicamente SourcePackages de este proyecto a Papelera (0,281 GiB); la carpeta se regeneró y Resolve Package Versions
terminó sin incidencias a las 08:40. Los 13 checkouts coinciden con Package.resolved. Esta reparación no modifica archivos
del repositorio ni se publica como parte del código. No se vació la Papelera ni se borró el resto de DerivedData.

Build Develop posterior a la actualización: PASS en Xcode 27.2 beta 2, iPad Pro 13-inch (M5), SDK 27.2, 29,287 s;
log `BuildProject-Log-20260930-084144.txt`. Solo aviso AppIntents conocido. El uso de la beta corresponde al Xcode abierto
por el propietario; no se eleva el target ni se cambia la política de toolchain del proyecto.

Validación final del conjunto en Xcode 27.2 beta 2, Develop/iPad Pro 13-inch (M5), SDK/iOS 27.2:

- Build Develop con tests PASS, 17,481 s; log `BuildProject-Log-20260930-084632.txt`.
- GetTestList: 1.082 declaraciones. RunAllTests: **1.564/1.564 PASS**, cero fallos, omisiones o avisos de runtime.
  Resumen `RunAllTests/9B37F53F-F097-4A42-8F75-53E9E0129CE1.txt`.
  Bundle nativo cerrado inspeccionado en
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/Test-FranAlonso-Develop-2026.09.30_08-47-20-+0200.xcresult`.
  La copia de ActionArtifacts carece de Info.plist; no se usa como prueba nativa cerrada.
- Build Production PASS, 25,539 s; log `BuildProject-Log-20260930-084838.txt`. Develop y destino inicial restaurados.
  Logs completos: únicamente aviso AppIntents previo; GetBuildLog warning sin incidencias estructuradas.
- POST independiente del delta de dependencias: PASS, sin hallazgos. Manifests compatibles; productos aprobados,
  fronteras de datos y telemetría conservados, sin IdentitySupport ni capacidad publicitaria enlazada adicional.
  Manifiesto anterior y posterior idéntico: 672 archivos,
  SHA-256 `4ea465eacc9361ef520ae8faef8f224fb6aed39c60663ca4ddf2a0e2a70d08c9`.
- Estilo del único test editado: cero candidatos. Los 41 Swift de App siguen idénticos al baseline y los 29 movimientos
  coinciden exactamente con el mapa aprobado. Diff check PASS; gobernanza conserva solo los seis enlaces históricos 08.3.

Se reutiliza la revisión de los movimientos porque sus fuentes Swift no han cambiado. No se añaden tests que reproduzcan
las mismas rutas o la implementación. Evidencia local; no acredita servicios live ni cierre integral de accesibilidad.
Entrega Git completada; PLU-69 cerrado después del merge verificado.

## Cierre de entrega — 2026-09-30

- Commit `a1d1894569ef26e0509876d7d9cb4f14392be812`, `🔧 chore(app): organize files and update Firebase`, publicado.
- [PR31](https://github.com/JFrancoG/FranAlonso/pull/31) MERGED mediante merge commit
  `ef65fc20320423a1158e0ffc67c418c8fa6ef9fe`. Antes de integrar: CLEAN/MERGEABLE, 38 archivos previstos,
  HEAD remoto idéntico al revisado; sin checks, revisiones obligatorias, protección ni rulesets remotos configurados.
- Árbol integrado completo idéntico al validado: 672 archivos,
  SHA-256 `f7053b01ca42defcde735da50e35a134f66fac308be4476669e0d299ce13a2a1`.
  Verificadas ascendencia y ausencia de commits únicos antes de eliminar la rama local y remota.
- PLU-69 Done confirmado por integración GitHub–Linear. Es una tarea transversal sin padre ni milestone;
  proyecto y fases conservan su estado y deuda. Descripción, comentario de entrega y proyecto reconciliados.
- Se reutilizan los builds, 1.564 resultados y revisiones anteriores: el código y la configuración integrados
  son idénticos a los validados. Cierre documental: Xcode N/A; no modifica fuentes ni configuración.
  Permanecen el aviso AppIntents y los seis enlaces históricos 08.3. No se acredita live ni accesibilidad integral.
- Siguiente gate funcional ya planificado: PLU-47 / Foundation Models según ADR0030, todavía no iniciado.
