# Project Progress

Última actualización: 2026-09-13

## Estado actual

- Fase08 / [PLU-34](https://linear.app/plusprojects/issue/PLU-34) abierta.
- **08.4 / [PLU-38](https://linear.app/plusprojects/issue/PLU-38): integrada mediante [PR#11](https://github.com/JFrancoG/FranAlonso/pull/11); DoD pendiente**.
  Merge autorizado y completado el13/09: `c4d7b00989a58783f953752bdc8f29dca90c6715`. Rama anterior conservada.
  Linear cerró automáticamente la issue al integrar; restaurada a In Progress para mantener su evidencia pendiente.
- **08.5 / [PLU-39](https://linear.app/plusprojects/issue/PLU-39): implementada y validada localmente; puerta de revisor nuevo pendiente**.
  Rama `codex/plu-39-phase-08-5-signed-documents`; implementación autorizada tras la
  [propuesta revisada](progress/08-5-signed-document-proposal.md). Catálogo único en Resources/Legal, snapshot y firma
  inmutables, autorización opcional y PDF con texto real mediante actor Data. Sin UI integrada, guardado ni upload.
  TDD: preparación6 RED→6 GREEN; render6 RED→6 GREEN. Regresión43/43 y catálogo ampliado8/8; build PASS12,132s
  por Xcode MCP Develop/iPadAir11M4/26.5. PDF sintéticos inspeccionados; sin cambios en los cuatro borradores PDF.
  Dos revisiones independientes reutilizadas favorables tras corregir un P3 documental; el límite de agentes impidió
  crear revisores nuevos. Commit funcional `bce8859` y push completados el13/09; rama con upstream sincronizado.
  La PR, el merge y el cierre de issue siguen pendientes, incluida la revisión por agente nuevo.
- Captura efímera con valor inmutable Codable, ViewModel, lienzo, deshacer/borrar/confirmar/cancelar. No se integra
  todavía en formulario, persistencia, PDF firmado, Storage ni activación. ADR0027 limita la excepción de dibujo libre.
- Botones de edición en fila, Confirmar con forma accesible rectangular y resultados Deshacer/Borrar con prioridad alta.
  Foco visible Light/Dark y activación por Espacio confirmados; VoiceOver confirma nombres/roles/atenuado, recorrido,
  valores vacío/listo y resultados. Último retest físico: iPhone14/iOS26.7, RunProject001300, PASS11,023s.
- Recorridos previos conservados: Control por voz incluyendo Cancelar, Control por botón con tinta preparada,
  teclado/FKA, bloqueo físico durante trazo, rotación iPad, AX5 con scroll y Reducir transparencia.
  El13/09 el propietario confirma ventana mínima, conservación de tinta terminada al reducir/ampliar,
  Reducir movimiento y Aumentar contraste en Light/Dark. No se infiere restauración de preferencias ni ratios medidos.
- Acceso temporal retirado: App restaurada byte a byte frente a HEAD, dos Swift y dos claves temporales eliminados,
  esquema local Signature-Manual retirado y Develop/iPadAir11M4/26.5 seleccionado.
  Build posterior PASS14,159s por Xcode MCP y tres tests de composición3/3; revisiones finales independientes favorables para PR borrador.
- Evidencia lógica histórica:26/26 resultados (16 de firma y10 de composición), no26 tests de firma.
  Persiste aviso conocido de extracción AppIntents; no se declara cero warnings globales ni Production.

## Pendientes para cerrar 08.4

- Runtime de redimensionado durante un trazo activo. Guards de Canvas, test de interrupción y bloqueo físico aportan
  evidencia parcial; no se convierte en PASS la limitación de probarlo con un solo ratón.
- Medición/atribución del contraste del render nativo final de Cancelar/Confirmar/foco. Ratios de assets propios
  recalculados y comprobación visual High Light/Dark favorables; no son una medición del estilo nativo compuesto.
- PR#11 integrada por autorización expresa. Composición restaurada validada3/3 y auditorías previas conservadas;
  integración no equivale a cierre de la evidencia pendiente. PLU-38 sigue In Progress y relacionada con PLU-39.
- Gobernanza heredada: seis enlaces históricos a capturas08.3 eliminadas siguen rotos; no se alteran en esta entrega.

## Plan y fuentes

Detalle en [fase08](progress/phase-08.md), [propuesta08.4](progress/08-4-signature-proposal.md),
[matriz08.4](accessibility/evidence/08-4-signature-capture.md) y [propuesta de foco](progress/08-4-keyboard-focus-proposal.md).
La consolidación actual sustituye pendientes ya resueltos de las anotaciones históricas; no requiere repetir pruebas aceptadas.

ADR0028 y spec08 aprobados distinguen información inicial firmada y autorización fotográfica opcional. Dos borradores
PDF en Resources, catálogo y generador ajustados; continúan pendientes de revisión jurídica antes del uso real.
08.5 en validación local; 08.6–08.9 / PLU-40–PLU-43 permanecen en Backlog, sin implementar.
El vault Obsidian es este repositorio. Sin activación live ni cierre administrativo de08.4.

## Entregas anteriores

- 08.3 / PLU-37 completada: PR#10 integrada mediante `1377cc4`, cierre documental `9ffce6a`.
- Fases01–06: [histórico](progress/phases-00-06.md).
- Fase07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done, PLU-25 conserva cierre administrativo pendiente.
- Evidencia08.3: [pantallas](accessibility/evidence/08-3-client-screens.md), con excepción ADR0026 conservada.
