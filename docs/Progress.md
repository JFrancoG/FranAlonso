# Project Progress

Última actualización: 2026-08-23

## Puerta actual

- Fases 01–06 cerradas. La baseline aprobada de fase 07 es `main == origin/main == 074ce5e`.
- PLU-25 está `In Progress`; PLU-28 está `In Review`; PLU-26 y PLU-27 están `Done`. PLU-28 no tiene blockers.
- 07.1 y sus fixtures Develop no-live están entregadas en `074ce5e`. Los motores live continúan inactivos.
- 07.2 implementa controles reutilizables de autenticación y conserva fuera de alcance filas/tarjetas sin un segundo
  consumidor, Domain, Data, App, navegación, configuración, servicios live y subfases 07.3/07.4.
- La implementación, las validaciones y las auditorías read-only finales están completas sin hallazgos abiertos.
  El commit `91e9a58` está publicado y la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4) permanece abierta;
  PLU-28 pasa a `In Review`.

## 07.2 — snapshot funcional

- `PrimaryActionStyle` se aplica al `Button` nativo completo y comparte foreground semántico, estilo prominent, tint,
  cápsula y tamaño `.large`. Login y Session conservan sus acciones, estados `disabled` y labels caller-owned.
- Los dos CTA «Acceder» quedan unificados, sin iconos, con una altura visual aproximada de 49 pt y contraste correcto
  en enabled/disabled. El fallback «Salir y acceder con email» permanece como acción de texto nativa.
- Los estados de éxito, aviso y error usan `successInk`, `warningInk` y `errorInk`; el label del fallback destructivo
  aplica `errorInk` sin perder `role: .destructive`, para cumplir contraste textual también en Light.
- `FormFieldSection` conserva exactamente una `Section` nativa, el `VStack` leading, el label visual y contenido
  caller-owned. Las dos secciones de campos de Login siguen separadas para Switch Control.
- Email y Contraseña conservan bindings, prompts, teclado, AutoFill, autocorrección, input labels, superficie mínima,
  submit y foco. Los labels incorporan SF Symbols; el botón de ojo, único control solo-icono, muestra u oculta la
  contraseña sin trasladar lógica de negocio a la View.
- La transición inicial a Login y los errores importantes coordinan la semántica accesible sin delays, UIKit ni foco
  forzado tras el retorno biométrico. El copy breve del fallback se selecciona con `ViewThatFits`.
- RED/GREEN es `N/A` para la extracción visual sin lógica. La coordinación biométrica pura sí tiene cobertura con
  Swift Testing; no se añadieron XCTest, XCUITest ni UI tests ceremoniales.

## Evidencia automática final

- Xcode MCP, `FranAlonso-Develop`, iPhone 17e Simulator/iOS 26.5: build final correcto en 13,424 s; Issue Navigator sin
  warnings; cero diagnósticos en los Swift de producción afectados.
- La consulta aislada de `BiometricAnnouncementGateTests.swift` devolvió `SourceEditor error 5`; el archivo compiló y
  ejecutó correctamente, por lo que se registra como límite del editor, no como regresión.
- Previews de `FormFieldSection`, Login y Session: Light/Dark, contraste normal/incrementado, Large/XXX Large/AX 5,
  portrait/landscape y RTL, incluidos estados enabled/disabled.
- Focales: 6/6 `DesignSystemColorAssetTests`; 39/39 localización + anuncio biométrico; 58/58 root/Login/Session
  ViewModels; 28/28 lanzamiento/configuración. Total focal: 131/131.
- Suite completa: 843/843 outcomes.
- Una ejecución de `DesignSystemColorAssetTests` en iPhone 11 físico obtuvo 3/6 porque tres casos source-backed no
  pueden acceder a la ruta fuente del Mac desde el sandbox del dispositivo. La repetición equivalente en simulador
  pasó 6/6; no es una regresión del producto.
- La auditoría AX inicial detectó contraste insuficiente en los colores nativos de estado y del fallback. La corrección
  semántica posterior pasó build, Issue Navigator sin warnings, `DesignSystemColorAssetTests` 6/6 y previews de Login
  error, Session warning/fallback y Session error/fallback en Light/Dark × contraste normal/incrementado.
- Los tres argumentos de fixture del esquema Develop quedaron desactivados (`NO`).

## Evidencia manual ADR 0022

- VoiceOver, Voice Control, Switch Control agrupado y Full Keyboard Access pasan en los flujos aplicables de Login y
  Session. Los nombres, roles, orden, foco visible, activación única y recuperación tras error se comprobaron en
  runtime.
- Login conserva tres grupos de primer nivel en Switch Control: Email; Contraseña + ojo; Acceder. Email, contraseña
  oculta/visible, ojo y CTA pasan las comprobaciones de centro y extremos y ejecutan una única acción.
- Session conserva dos controles independientes cuando la biometría está disponible. Acceder abre una sola petición y
  completa una única transición. El fallback, aunque no dibuja fondo ni borde, respondió siempre a la primera en centro
  y extremos y navegó exactamente una vez a Login.
- AutoFill, Dynamic Type hasta AX 5, Light/Dark, contraste normal/incrementado, orientaciones, RTL y superficies
  operables están comprobados. Los CTA compartidos mantienen contraste y aspecto disabled.
- El fallback corto está implementado mediante `ViewThatFits` y cubierto por localización y previews; no se presenta
  como observado manualmente en runtime porque esa variante no llegó a mostrarse.
- La matriz detallada vive en
  [`accessibility/evidence/07-2-reusable-controls.md`](accessibility/evidence/07-2-reusable-controls.md).

## Limitaciones aceptadas

- Al volver de contraseña visible a `SecureField`, el comportamiento nativo puede reemplazar el valor al reanudar la
  escritura. Se conserva SwiftUI moderno y no se añade un wrapper UIKit para controlar selección interna.
- Tras anunciar completo un fallo biométrico, el destino final de VoiceOver puede variar entre dispositivos. La app no
  fuerza un foco posterior ni introduce saltos o trampas.
- Si se reactiva Login mientras el foco está en su nodo dinámico de error, iOS puede volver al encabezamiento. Cada
  error nuevo sí recibe foco y se anuncia completo una vez; no se añade lógica compensatoria.
- AutoFill funciona con la cuenta sintética, pero permanece limitado por la ausencia deliberada de Associated Domains.

## Siguiente acción

1. Revisar la [PR #4](https://github.com/JFrancoG/FranAlonso/pull/4) y mantener PLU-28 `In Review`.
2. No hacer merge, cambiar PLU-28 a `Done` ni cerrar Linear sin autorización separada.

## Bloqueos

Ninguno. Las limitaciones anteriores están aceptadas y documentadas; no habilitan Firebase/live ni amplían 07.2.

El histórico de fases 01–06 se conserva en [`progress/phases-00-06.md`](progress/phases-00-06.md), y el detalle de
fase 07 en [`progress/phase-07.md`](progress/phase-07.md).
