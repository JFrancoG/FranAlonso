# Project Progress

Última actualización: 2026-09-29

## Estado actual

- **08.8 / [PLU-42](https://linear.app/plusprojects/issue/PLU-42): Done funcional**, entrega y cierre autorizados.
  [PR #15](https://github.com/JFrancoG/FranAlonso/pull/15) integrada en `0126c6b`; árbol validado `91eb3a7` intacto.
  Rama local/remota eliminadas; [propuesta](progress/08-8-client-activation-proposal.md).
  Alta inicial recuperable: pending antes de upload, active solo con recibo durable, reintento sin nuevo envío/firma,
  referencia inicial inmutable y conservación de edición concurrente. UI de Finalizar alta, éxito y fallo localizado.
  Recuperar adopta el estado vigente y la confirmación distingue el documento que realmente completó el alta.
  Xcode MCP final Develop/iPadAir11M4/27.0: **835 declaraciones / 1.094 resultados PASS**, cero fallos/omitidos;
  build **9,323s**, único aviso AppIntents previo. TDD inicial7RED→53GREEN; POST reproduce dos P2 en3/4 casos,
  corregidos y cubiertos por la suite final. Previews Large/XXX Large/AX5 de pantalla y componente inspeccionadas.
  PRE y POST independientes PASS tras corregir los hallazgos; evidencia y límites en [fase08](progress/phase-08.md).
  Smoke táctil por Xcode MCP PASS: fallo local después del envío, vuelta a lista, reapertura, Finalizar alta y
  nueva reapertura activa, sin refirma y con un único upload. Datos sintéticos y Storage simulado, mismo proceso.
  Harness temporal retirado byte a byte; las 527 rutas previas coinciden. Build restaurado **8,907s** y retest
  focal **2/2 PASS**; aviso AppIntents previo. Composición normal sigue sin Storage disponible; no acredita live,
  reinicio del proceso ni tecnologías de asistencia. Sin checks remotos. Evidencia reutilizada por árbol idéntico.
- **08.9 / [PLU-43](https://linear.app/plusprojects/issue/PLU-43): Backlog**, siguiente dependencia funcional satisfecha.
  Foto opcional inicial/posterior, autorización independiente y detalle; requiere su puerta de inicio y propuesta.
  El cierre de 08.8 no inicia código de 08.9 ni crea una composición permanente de demo.
- **[PLU-45](https://linear.app/plusprojects/issue/PLU-45): Backlog**, validación accesible integral nueva de08.8.
  Responsable Jesus Franco; hija dePLU-34 y relacionada conPLU-42/44. [Matriz08.8](accessibility/evidence/08-8-client-activation.md)
  conserva construcción/revisión y previews, con foco/anuncios/AT, Inspector, contraste y variantes pendientes.
  Retomar tras feedback de Fran y estabilización del flujo, antes del primer candidato para uso real.
- **Fase08 / [PLU-34](https://linear.app/plusprojects/issue/PLU-34): In Progress**.
  [ADR0029](ADRs/0029-progressive-accessibility-validation.md) separa entrega funcional de validación integral;
  no aplaza integridad, privacidad ni recuperación funcional. La fase y puerta de uso real conservan su deuda.
- **08.7 / [PLU-41](https://linear.app/plusprojects/issue/PLU-41): Done funcional** tras
  [PR#14](https://github.com/JFrancoG/FranAlonso/pull/14), merge `334703d`, commit validado `ece99ff`.
  Rama local/remota eliminadas; cierre documental `70905c2`. Sin checks remotos ni servicios live.
  Evidencia:1.067/1.067PASS, retest2/2, build6,685s y smoke táctil de firma/conservación/error/reintento/reapertura.
- **[PLU-44](https://linear.app/plusprojects/issue/PLU-44): Backlog**, accesibilidad aplazada de08.7.
  Responsable Jesus Franco; conservar fallos de foco/anuncios VoiceOver y descubribilidad de error/reintento;
  Inspector, contraste nativo y tecnologías/variantes restantes pendientes. FKA del botón principal en cuatro
  apariencias y legibilidad ya aceptados. Retomar tras feedback/UI estable por flujo, antes del uso real.
  [Matriz08.7](accessibility/evidence/08-7-consent-flow.md):55 criterios intactos; smoke táctil no acredita AT.
- **08.6 / PLU-40: Done**, [PR#13](https://github.com/JFrancoG/FranAlonso/pull/13), merge `7ac0fb5`;
  persistencia recuperable, migración1→2 y Storage neutral/fake.1.020 resultados PASS, build6,993s, PRE/POST favorables.
- **08.5 / PLU-39: Done**, [PR#12](https://github.com/JFrancoG/FranAlonso/pull/12), merge `943cd84`;
  catálogo versionado, snapshot/firma inmutable y PDF de texto real. TDD, regresión43/43, catálogo8/8 y build12,132s.
- **08.4 / [PLU-38](https://linear.app/plusprojects/issue/PLU-38): In Progress**, integrada mediante
  [PR#11](https://github.com/JFrancoG/FranAlonso/pull/11), merge `c4d7b00`; DoD propia pendiente.
  Captura inmutable Codable, ViewModel, lienzo/edición y excepción de trayectoria ADR0027. Acceso temporal retirado.
  Confirmados los recorridos físicos/manuales ya registrados, incluidos VoiceOver básico, Control por voz/botón,
  teclado/FKA, bloqueo físico, AX5, rotación, ventana mínima y preferencias. No se repiten por rutina ni se amplía su alcance.

## Pendientes separados de08.4

- Runtime de redimensionado durante un trazo activo; prueba con un ratón no acredita simultaneidad.
- Medición/atribución del contraste del render nativo final de Cancelar/Confirmar/foco. Assets y comprobación visual
  no sustituyen ratios del estilo compuesto. PR integrada no equivale a cierre de evidencia.
- Detalle en [matriz08.4](accessibility/evidence/08-4-signature-capture.md),
  [propuesta08.4](progress/08-4-signature-proposal.md) y [propuesta de foco](progress/08-4-keyboard-focus-proposal.md).

## Plan y fuentes

[Spec08](specs/08_clients_consent.md), ADR0028/0029 y [fase08](progress/phase-08.md) conservan autoridad y evidencia.
Información inicial firmada y autorización fotográfica opcional siguen separadas. Borradores jurídicos pendientes de
revisión antes del uso real. Sin activación live, foto real08.9 ni cierre administrativo de08.4.
El vault Obsidian es este repositorio. Gobernanza conserva seis enlaces históricos rotos de capturas08.3.

## Entregas anteriores

- 08.3 / PLU-37: Done, PR#10 merge `1377cc4`, cierre documental `9ffce6a`; [pantallas](accessibility/evidence/08-3-client-screens.md)
  y excepción ADR0026 conservadas.
- Fases01–06: [histórico](progress/phases-00-06.md).
- Fase07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done, PLU-25 conserva cierre administrativo pendiente.
