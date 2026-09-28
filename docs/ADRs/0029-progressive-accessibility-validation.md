# ADR 0029 — Entrega funcional y validación progresiva de accesibilidad

## Estado

Aceptado el 28 de septiembre de 2026 por el propietario con «OK, me parece bien, hazlo así», sobre la propuesta de
separar la entrega funcional de 08.7 y su validación aplazada. La aceptación autoriza la reconciliación documental y
operativa; no entrega código, cierra PLU-41, inicia 08.8 ni activa servicios live.

## Contexto

Fran necesita revisar pronto funcionalidades, UI, textos y recorridos. La 08.7 está implementada localmente, con
validación técnica registrada, pruebas manuales parciales y defectos conocidos de foco/anuncios. Exigir toda la matriz
antes de cada entrega funcional retrasa ese feedback y puede obligar a repetir comprobaciones sobre UI que cambiará.

ADR 0022 conserva el objetivo interno de accesibilidad nativa. Esta decisión sustituye únicamente su disposición que
impide el cierre funcional de una pantalla mientras falte cualquier evidencia aplicable o exista un hallazgo de
accesibilidad aplazado. El cierre integral sigue exigiendo la evidencia aplicable y resolver los defectos, salvo las
excepciones de producto aceptadas por sus ADR específicos. No se modifica ADR 0011 ni el objetivo final de ADR 0022.

## Drivers

- Obtener feedback de producto sobre recorridos completos antes de la evaluación exhaustiva de la UI estabilizada.
- Conservar accesibilidad por construcción, integridad de datos, TDD y revisiones independientes.
- Hacer visible el trabajo aplazado sin convertir fallos o ausencia de evidencia en resultados favorables.

## Opciones consideradas

1. Mantener toda la matriz como bloqueo de cada entrega: máxima evidencia temprana, con demora del feedback actual.
2. Posponer toda la calidad hasta el final: avance aparente, con riesgo de propagar defectos estructurales y funcionales.
3. Separar entrega funcional para demo y validación integral: permite avanzar, con deuda explícita y un cierre posterior
   obligatorio. Se adopta esta opción.

## Decisión

### Entrega funcional para demo

- Mantener controles nativos y semántica, localización, Dynamic Type, acciones alcanzables, errores/estados comprensibles,
  revisión estática focal y previews de las pantallas afectadas en `Large`, `XXX Large` y `AX 5` cuando estén soportados,
  conforme a ADR 0011. Seleccionar estados/apariencias representativos; la matriz exhaustiva restante puede aplazarse.
  Reutilizar evidencia vigente y no repetir combinaciones sin impacto.
- Mantener TDD, tests afectados, build/diagnósticos Xcode MCP y revisiones independientes. El recorrido que se enseñará
  debe comprobarse funcionalmente; previews y tests no acreditan por sí solos su comportamiento manual.
- Pueden aplazarse la matriz runtime exhaustiva, Inspector, mediciones finales y defectos de accesibilidad registrados
  que no impidan operar el recorrido acordado de la demo. No se aplazan pérdida/duplicación de datos, privacidad,
  invariantes, regresiones funcionales ni un bloqueo del recorrido de demo, incluida la tecnología de asistencia que
  necesite su participante.
- Cada aplazamiento identifica alcance, criterio/flujo, evidencia y limitaciones, impacto, responsable, issue vinculada
  y momento de recuperación. La matriz es el registro de resultados; Linear organiza su resolución.
- `Falla`, `Pendiente` y `Limitado` conservan su significado. Diferir nunca produce `Pasa` ni `N/A`. Una revisión puede
  aprobar la entrega funcional con deuda registrada, sin aprobar el cierre integral de accesibilidad.
- Una subfase puede quedar `Done` por su alcance funcional únicamente tras completar esa validación, reconciliar la
  deuda y realizar la entrega expresamente autorizada. Su descripción y Progress enlazan la validación aún abierta.
  La fase conserva pendientes integrales; el cierre funcional no autoriza por sí mismo la siguiente subfase.

### Recuperación y cierre integral

- Retomar las pruebas al incorporar el feedback de Fran y acordar que cada recorrido está suficientemente estable.
  No esperar a una UI definitiva de toda la aplicación ni a alcanzar numéricamente la fase 18.
- Antes del primer candidato para uso real, completar toda evidencia aplicable aplazada, corregir defectos y obtener
  revisión independiente. La fase 18 verifica esta puerta; una demo de feedback no equivale a entrega para uso real.
- Conservar pruebas aceptadas con su dispositivo/build y límites. Revalidar por impacto: texto afecta nombres/lectura y
  layout; navegación afecta foco/transiciones; estilos compartidos afectan sus consumidores. Un cambio relevante de
  plataforma o componente también exige revisar la aplicabilidad de la evidencia.
- No se habilitan código de nuevas subfases, fixtures adicionales, cambios de arquitectura, publicación o servicios
  reales. Las dependencias funcionales y las autorizaciones de entrega permanecen vigentes.

## Aplicación inicial a 08.7

- PLU-41 permanece `In Progress`: falta preparar y realizar su entrega funcional, incluido revisar el diff y la
  configuración temporal de validación. Esta decisión no declara un build actual verificado ni cero warnings.
- Separar sus fallos conocidos de foco/anuncios y comprobaciones accesibles pendientes en una issue hija de fase 08,
  relacionada con PLU-41. La [matriz 08.7](../accessibility/evidence/08-7-consent-flow.md) conserva evidencia y vínculo.
- Las comprobaciones de integridad/recuperación funcional siguen siendo responsabilidad de PLU-41. La issue aplazada
  cubre la operación y comunicación accesibles de esos recorridos, no su corrección de negocio o persistencia.
- PLU-38/08.4 conserva sus pendientes propios y no se cierra ni se transfiere automáticamente. 08.8–08.9 mantienen su
  alcance y estado. No se renumeran fases ni se crea un plan consolidado paralelo.

## Consecuencias

- Se obtiene feedback antes y se reduce repetición sobre UI provisional.
- Se mantiene un coste posterior de validación y pueden aparecer defectos que exijan rehacer UI; aplazar no elimina
  ese coste. El vínculo operativo, responsable y bloqueo del uso real evitan perder la deuda.
- Los informes deben distinguir implementación, entrega funcional, cierre integral y activación live.

## Testing y validación

- Para este cambio documental: enlaces, coherencia entre autoridades/skills/specs/Progress/Linear, diff y validador de
  gobernanza. Xcode MCP, tests y previews nuevos: `N/A`, sin cambio de código/configuración de la app.
- Revisiones independientes de estándares y accesibilidad sobre la política y separación de pendientes.
- Para cada entrega posterior: evidencia funcional y revisión focal; para uso real: matriz completa y deuda resuelta.

## Migración o reversibilidad

La política se aplica desde 08.7 a entregas para demo que documenten expresamente sus pendientes conforme a este ADR.
No cambia retrospectivamente resultados ni cierra issues existentes. Una decisión posterior puede recuperar la puerta
integral por subfase; las matrices y evidencias siguen siendo reutilizables.

## Relaciones y referencias

- [ADR 0022](0022-native-ios-wcag22-accessibility.md): objetivo vigente; disposición de cierre parcialmente sustituida.
- [ADR 0011](0011-swiftui-boundaries-specialized-reviews.md): revisores y límites SwiftUI conservados.
- [Guía de desarrollo](../DEVELOPMENT_GUIDE.md), [spec 08](../specs/08_clients_consent.md) y
  [spec 18](../specs/18_qa_release.md): aplicación y puerta final.
- [W3C — WCAG-EM](https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/): evaluación preliminar y accesibilidad
  durante el ciclo de desarrollo. La separación de cierres es una decisión del proyecto, no una exención de W3C.
