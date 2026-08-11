# Development Guide

## Jerarquía documental

1. `docs/specs/01_constitution.md`: reglas estables.
2. ADR aceptados: decisiones y motivos.
3. Spec activa: alcance y resultado esperado.
4. Skills: procedimiento bajo demanda.
5. `docs/Progress.md` y `docs/progress/`: estado y evidencia.
6. Linear: operación; Git/PR: entrega verificable.

## Inicio de subfase

Usar `$franalonso-start-subphase`.

La puerta de inicio comprueba instrucciones, spec y ADR aplicables; Git; configuración real; Xcode MCP; Linear;
baseline; alcance exacto; alternativas; riesgos; tests y fuentes primarias. Un revisor independiente read-only valida la
propuesta antes de código ejecutable. La aprobación del propietario se refiere solo al alcance presentado.

## Implementación

- Aplicar TDD cuando cambie comportamiento: RED focalizado, implementación mínima, GREEN y regresión afectada.
- Usar `$ios-development-standards` para reglas iOS aplicables y `$ios-accessibility-implementation` por cada pantalla.
- Mantener Views declarativas, Domain puro, Data reemplazable y composición en App.
- Detenerse antes de dependencias, ADR, excepciones unsafe, activación live o ampliaciones no aprobadas.
- Documentar solo contratos semánticos y separar limpieza histórica de cambios funcionales.

## Validación

- Código/configuración: Xcode MCP para build, tests y diagnósticos; nunca `xcodebuild`.
- SwiftUI: descubrir variantes con Xcode MCP y revisar las soportadas `Large`, `XXX Large` y `AX 5`.
- Accesibilidad: completar la matriz de ADR 0022 y registrar comprobaciones semánticas y manuales no demostrables por
  snapshots.
- Documentación: enlaces, índices, formatos, diff y scripts de gobernanza; Xcode puede ser `N/A` justificado.

## Revisión especializada

- Ejecutar el agente read-only `$franalonso-review-ios-standards` después de cambios de implementación.
- Ejecutar en paralelo `$franalonso-review-accessibility` cuando cambien SwiftUI, previews, recursos visuales, localización o
  accesibilidad.
- Corregir hallazgos válidos y repetir solo la revisión afectada; ambas si la corrección cruza ámbitos.

## Cierre

Usar `$franalonso-finish-subphase` y `docs/PULL_REQUEST_CHECKLIST.md`.

Registrar en `docs/progress/phase-XX.md`: alcance, evidencia RED/GREEN, build/tests/diagnósticos, previews y accesibilidad,
auditorías, cambios documentales, pendiente y bloqueos. Mantener `docs/Progress.md` como snapshot breve y reconciliar
Linear sin confundir implementación, entrega y activación live.

## Definición de terminado

Una subfase está terminada cuando su alcance aprobado está implementado, las validaciones aplicables están verdes, las
auditorías no tienen hallazgos abiertos, la accesibilidad de cada pantalla tiene evidencia, la documentación está
reconciliada y el propietario ha autorizado la acción de entrega solicitada.
