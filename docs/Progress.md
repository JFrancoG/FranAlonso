# Project Progress

Última actualización: 2026-09-13

## Estado actual

- Fase08 / [PLU-34](https://linear.app/plusprojects/issue/PLU-34) abierta.
- **08.6 / [PLU-40](https://linear.app/plusprojects/issue/PLU-40): completada y Done**.
  [PR #13](https://github.com/JFrancoG/FranAlonso/pull/13) integrada con `7ac0fb5`; implementación publicada en `32e314c`.
  Rama local y remota eliminadas. Persistencia recuperable, migración aditiva 1→2 y envío con Storage neutral/fake.
  Xcode MCP: 770 declaraciones / 113 suites / 1.020 resultados verdes, cero fallos/omitidos; build PASS 6,993 s.
  PRE, POST y reauditoría focal PASS sin hallazgos; huellas pre/post verificadas y evidencia en fase08.
  Aviso AppIntents y seis enlaces históricos de 08.3 conservados. Sin checks remotos, integración de pantalla o live.
- **08.4 / [PLU-38](https://linear.app/plusprojects/issue/PLU-38): integrada mediante [PR#11](https://github.com/JFrancoG/FranAlonso/pull/11); DoD pendiente**.
  Merge autorizado y completado el13/09: `c4d7b00989a58783f953752bdc8f29dca90c6715`. Rama anterior conservada.
  Linear cerró automáticamente la issue al integrar; restaurada a In Progress para mantener su evidencia pendiente.
- **08.5 / [PLU-39](https://linear.app/plusprojects/issue/PLU-39): completada y Done**.
  [PR#12](https://github.com/JFrancoG/FranAlonso/pull/12) integrada el13/09 mediante
  `943cd84f93883c019206b0df6b5cc721dea3395d`; rama local y remota de08.5 eliminadas.
  Catálogo único en Resources/Legal, snapshot/firma inmutables y PDF con texto real mediante actor Data.
  TDD preparación6 RED→6 GREEN y render6 RED→6 GREEN; regresión43/43, catálogo ampliado8/8 y build PASS12,132s
  por Xcode MCP Develop/iPadAir11M4/26.5. PDF sintéticos inspeccionados; borradores anteriores conservados.
  Dos agentes nuevos independientes completan POST de estándares y recursos/localización/PDF sin hallazgos pendientes.
  P3 documental de la spec corregido y releído; huellas pre/post verificadas. Sin cambios ejecutables posteriores.
  GitHub sin checks remotos, no equivale a CI. Sin UI integrada, guardado, upload ni activación live.
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
08.5 completada; 08.6 / PLU-40 completada y Done mediante PR #13. 08.7–08.9 / PLU-41–PLU-43 permanecen en Backlog.
El vault Obsidian es este repositorio. Sin activación live ni cierre administrativo de08.4.

## Entregas anteriores

- 08.3 / PLU-37 completada: PR#10 integrada mediante `1377cc4`, cierre documental `9ffce6a`.
- Fases01–06: [histórico](progress/phases-00-06.md).
- Fase07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done, PLU-25 conserva cierre administrativo pendiente.
- Evidencia08.3: [pantallas](accessibility/evidence/08-3-client-screens.md), con excepción ADR0026 conservada.
