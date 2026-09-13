# ADR 0027 — Firma a mano alzada y excepción de entrada por trayectoria

## Estado

Aceptado por decisión explícita del propietario el 2026-09-10, durante la validación de 08.4 (PLU-38).
Sustituye únicamente la exigencia de alternativa de toque simple de ADR 0022 para dibujar esta firma manuscrita.

## Contexto

La captura 08.4 incorporó controles de coordenadas para evitar el arrastre. El propietario los considera inadecuados
para firmar y autoriza retirarlos. Aunque producen tinta válida, su construcción punto a punto no ofrece una experiencia
útil para escribir una firma. No hay un requisito aprobado de edición de diagramas ni de firma tipográfica.

W3C distingue la entrada manuscrita, cuyo resultado depende de una trayectoria, de la confirmación de identidad o
aceptación, que no necesariamente la requiere. Las excepciones normativas de entrada esencial no modifican por sí solas
la regla interna más estricta de ADR 0022: ese ADR exige alternativa para todo gesto de trayectoria o arrastre.

## Decisión

- La captura utiliza únicamente tinta a mano alzada. Se retiran el modo por puntos, su cursor, controles, estados,
  acciones, textos y tests exclusivos. Se conservan deshacer, borrar, confirmar y cancelar mediante botones nativos.
- Se acepta una excepción puntual a la regla interna de alternativa de ADR 0022 para la entrada manuscrita de 08.4.
  La matriz registra la regla no satisfecha y esta disposición; no se presenta como alternativa implementada.
- 2.5.1 permanece aplicable y limitado: la excepción esencial afecta únicamente al dibujo de la firma. 2.5.7 es N/A
  para este lienzo porque se dibuja una trayectoria, sin agarrar y recolocar un objeto. Se reevalúa si se añade esa edición.
- 2.1.1 permanece aplicable: la excepción del dibujo no exime botones, navegación, desplazamiento ni gestión de foco.
  Las tecnologías de asistencia y demás comprobaciones aplicables mantienen la puerta de evidencia de ADR 0022.
- No cambia el contrato `ClientSignature`, la geometría normalizada, el resultado terminal único ni su carácter efímero.
  El flujo futuro de consentimiento requiere su propio análisis al integrarse; no hereda una exención global.

## Alternativas consideradas

- Conservar los controles por coordenadas: rechazado por el propietario por su escasa utilidad para firmar.
- Entrada manuscrita con acciones de edición simples: opción elegida y limitada a captura de tinta.
- Firma tipográfica, importación o flujo de representación: no forman parte del cambio aprobado.

## Consecuencias y límites

La interfaz y su estado se simplifican. Quien no pueda dibujar no dispone de una alternativa equivalente implementada
en esta pantalla. No se presupone que todas las personas puedan hacer un trazo ni que otra persona pueda sustituir
válidamente al firmante. No se modelan poderes, representación, identidad ni validez jurídica en 08.4.

Esta decisión no declara cumplimiento completo de ADR 0022, certificación WCAG ni conformidad legal. Conserva la
excepción de orientación de ADR 0026 y todas las evidencias pendientes ajenas a esta retirada.

## Validación y reversibilidad

Conservar la regresión de Domain, ViewModel y composición mediante Swift Testing/Xcode MCP; eliminar únicamente los
dos tests de la capacidad retirada. Inspeccionar previews Large, XXX Large, AX5 y RTL; repetir el recorrido manual
de captura tras actualizar el binario. No introducir tests estructurales que comprueben solo ausencia de símbolos.

El acceso temporal de validación sigue activo hasta finalizar las pruebas del propietario y queda excluido de entrega.
Revertir esta decisión o diseñar otra modalidad requiere acordar su utilidad y actualizar este registro mediante otro ADR.

## Referencias

- [ADR 0022](0022-native-ios-wcag22-accessibility.md)
- [Spec 08](../specs/08_clients_consent.md)
- [W3C — Pointer Gestures](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures.html)
- [W3C — Dragging Movements](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html)
- [W3C — Keyboard](https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html)
