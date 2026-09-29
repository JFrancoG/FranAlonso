# Project Progress

Última actualización: 2026-09-29

## Estado actual

- **Fase09 / [PLU-49](https://linear.app/plusprojects/issue/PLU-49): In Progress**.
  09.1/09.2 Done por PR17/18; **09.3 / [PLU-52](https://linear.app/plusprojects/issue/PLU-52): Done** por
  [PR19](https://github.com/JFrancoG/FranAlonso/pull/19), merge13b0839, head58ee95f intacto; ramas eliminadas.
  09.3: **1.191/1.191 PASS**, Develop/Production y PRE/POST PASS; aviso AppIntents conocido.
  **09.4 / [PLU-53](https://linear.app/plusprojects/issue/PLU-53): implementada localmente**; 1.199/1.199 PASS.
  Develop/Production, smoke y PRE/POST funcionales PASS; accesibilidad integral pendiente.
  Lista/formulario, Catálogo y demo; [propuesta](progress/09-4-product-screens-proposal.md), [evidencia](progress/phase-09.md).
  [PLU-54](https://linear.app/plusprojects/issue/PLU-54): Backlog accesible09.4, Jesus Franco, tras feedback antes de uso real.
  Entrega09.4 y comienzo09.5 autorizados; sin servicios live.
- **[ADR0030](ADRs/0030-reusable-demo-and-early-foundation-models.md) aceptado y publicado** el29/09;
  orden excepcional y alcance canónico en [índice](specs/00_index.md). [Registro](progress/phase-08.md).
- **08.8a / [PLU-46](https://linear.app/plusprojects/issue/PLU-46): Done funcional**, entrega y cierre autorizados.
  [PR #16](https://github.com/JFrancoG/FranAlonso/pull/16), merge `b334c04`; árbol validado `0c76967` intacto.
  Rama local/remota eliminadas; [guía](progress/08-8a-demo-runbook.md), evidencia en [fase08](progress/phase-08.md).
  Demo Debug-Develop aislada: dos borradores, capas reales, datos en memoria y proveedores simulados; sin live/durabilidad.
  Xcode MCP: **847 declaraciones /1.120 resultados PASS**, builds Develop/Production PASS con aviso AppIntents conocido.
  PRE/POST favorables; seis previews Large/XXX Large/AX5. Smoke PASS: alta, crear/editar, logout/login, reset y recuperación
  sin refirmar. Sesiones cerradas, Develop/iPhone11 restaurado, argumentos `NO`. Sin checks remotos.
  Fase09 iniciada según ADR0030; detalle arriba.
- **[PLU-48](https://linear.app/plusprojects/issue/PLU-48): Backlog**, evidencia accesible integral nueva del aviso/encuadre.
  Jesus Franco, hija dePLU-34 y relacionada conPLU-46; [matriz55](accessibility/evidence/08-8a-reusable-demo.md).
  Recuperar tras feedback y estabilización de este flujo, antes de uso real. PLU-44/45/38 conservan su deuda propia.
- **[PLU-47](https://linear.app/plusprojects/issue/PLU-47): Backlog**, adelanto de Foundation Models tras09–10.
  Una descripción escrita propone un servicio profesional editable; inferencia local real y guardado manual habitual.
  Hija dePLU-9, responsable Jesus Franco; alcance parcial en [spec16](specs/16_on_device_voice_assistant.md).
  Resto de16 pendiente. Después siguen11–13 para venta completa; la demo se amplía al implementar cada capacidad.
- **08.8 / [PLU-42](https://linear.app/plusprojects/issue/PLU-42): Done funcional**, entrega y cierre autorizados.
  [PR #15](https://github.com/JFrancoG/FranAlonso/pull/15) integrada en `0126c6b`; árbol validado `91eb3a7` intacto.
  Rama local/remota eliminadas; [propuesta](progress/08-8-client-activation-proposal.md).
  Alta recuperable tras recibo durable, reintento sin refirma ni segundo envío y conservación de edición concurrente.
  Xcode MCP:1.094/1.094 resultados PASS; build9,323s, retest2/2 y restauración8,907s con aviso AppIntents previo.
  PRE/POST, previews y smoke táctil PASS; harness temporal retirado byte a byte. Árbol integrado idéntico al validado;
  sin checks remotos. Evidencia completa en [fase08](progress/phase-08.md); no acredita Storage real ni AT integral.
- **08.9 / [PLU-43](https://linear.app/plusprojects/issue/PLU-43): Backlog**, aplazada por ADR0030 hasta el feedback
  de la demo acordada. Responsable Jesus Franco; foto, autorización y detalle completos conservados. Retomar antes
  del cierre integral de fase08 y uso real. No bloquea09–10/venta sin foto; no equivale a una subfase terminada.
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

[Índice](specs/00_index.md), specs de fase, ADR0028/0029/0030 y [fase08](progress/phase-08.md) conservan autoridad y evidencia.
Información inicial firmada y autorización fotográfica opcional siguen separadas. Borradores jurídicos pendientes de
revisión antes del uso real. Sin activación live, foto real08.9 ni cierre administrativo de08.4.
El vault Obsidian es este repositorio. Gobernanza conserva seis enlaces históricos rotos de capturas08.3.

## Entregas anteriores

- 08.3 / PLU-37: Done, PR#10 merge `1377cc4`, cierre documental `9ffce6a`; [pantallas](accessibility/evidence/08-3-client-screens.md)
  y excepción ADR0026 conservadas.
- Fases01–06: [histórico](progress/phases-00-06.md).
- Fase07: [evidencia](progress/phase-07.md); PLU-26–PLU-33 Done, PLU-25 conserva cierre administrativo pendiente.
