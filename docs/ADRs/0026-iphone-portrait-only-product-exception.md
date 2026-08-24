# ADR 0026 — iPhone solo portrait como excepción de producto

## Estado

Aceptado

## Contexto

El target de la app declaraba portrait y ambos landscape en iPhone. Durante la evidencia manual de 07.3, producto
confirmó que el diseño definitivo para iPhone se limita a portrait y mantiene las orientaciones adaptativas únicamente
en iPad.

ADR 0022 adopta como objetivo interno la correspondencia aplicable de WCAG 2.2 A/AA y bloquea el Definition of Done
cuando queda un hallazgo aplicable abierto. Su criterio 1.3.4 exige no restringir la orientación salvo que una orientación
concreta sea esencial. WCAG2ICT aplica ese criterio directamente al software nativo y solo añade una consideración para
hardware de orientación fija o sin capacidad de reorientarse.

FranAlonso no tiene una necesidad esencial de portrait: permitir landscape no alteraría fundamentalmente su información
o funcionalidad. La decisión es por tanto una preferencia de producto consciente, no una excepción normativa. Debe
registrarse como `A/No pasa — excepción de producto aceptada`, sin presentarla como conformidad, `N/A` o necesidad
esencial.

## Drivers

- Fijar de forma inequívoca la decisión final de producto para iPhone.
- Conservar iPad adaptativo en portrait, landscape, multitarea y ventanas redimensionables.
- Evitar lógica de orientación en Views, UIKit, navegación o estado de Presentation.
- Proteger la política por configuración y tests source-backed en las cuatro variantes de la app.
- Hacer visible el impacto accesible para futuras revisiones y decisiones de reversión.

## Opciones consideradas

### Mantener iPhone adaptativo y validar landscape

Es la opción accesible recomendada y permitiría clasificar 1.3.4 como `A/P`. No exige código ni configuración nueva,
pero producto la rechaza porque el recorrido definitivo de iPhone será portrait-only.

### Configurar iPhone portrait-only e iPad adaptativo

Usa las claves de orientación específicas por dispositivo que ofrece la plataforma. Es la opción elegida, aceptando
expresamente que iPhone no satisface 1.3.4.

### Bloquear orientación dinámicamente desde la app

Añadiría UIKit o lógica condicional a Views y navegación sin aportar valor frente a la configuración declarativa del
bundle. Se rechaza.

## Decisión

- Las cuatro configuraciones de la aplicación —`Debug-Develop`, `Release-Develop`, `Debug-Production` y
  `Release-Production`— declaran únicamente `UIInterfaceOrientationPortrait` para iPhone.
- Las cuatro configuraciones conservan para iPad `UIInterfaceOrientationPortrait`,
  `UIInterfaceOrientationPortraitUpsideDown`, `UIInterfaceOrientationLandscapeLeft` y
  `UIInterfaceOrientationLandscapeRight`.
- La política vive solo en `UISupportedInterfaceOrientations` y su variante iPad. No se añade código Swift/UIKit de
  producción, orientación dinámica, dependencia ni cambio de View; el test hospedado usa `UIDevice` únicamente para
  comprobar el contrato generado que corresponde al dispositivo donde se ejecuta.
- Swift Testing verifica el `Info.plist` generado de la aplicación hospedada y protege source-backed las cuatro
  configuraciones iPhone y las cuatro configuraciones iPad.
- La matriz de 07.3 registra 1.3.4 como `A/No pasa — excepción de producto aceptada` para Clientes y raíz/bootstrap.
  La evidencia iPad no compensa la restricción de iPhone.
- Esta decisión sustituye únicamente la conservación de orientaciones de ADR 0025. También crea una excepción explícita
  y limitada a la regla de cierre de ADR 0022 para el hallazgo 1.3.4 derivado de esta política; no rebaja ningún otro
  criterio, pantalla o evidencia exigida por ADR 0022.

El propietario aceptó conscientemente esta excepción el 24 de agosto de 2026 después de recibir dos revisiones
independientes coincidentes sobre su clasificación y consecuencias.

## Consecuencias

### Positivas

- El comportamiento declarado del target coincide con la decisión final de producto.
- iPhone deja de anunciar orientaciones que el producto no quiere soportar.
- iPad conserva sus cuatro orientaciones y su adaptación a multitarea y ventanas.
- La excepción queda auditable y no se confunde con una limitación técnica o normativa.

### Negativas y riesgos

- Personas que usan el iPhone montado en landscape no podrán adaptar la app a esa posición.
- Personas con baja visión pueden perder una alternativa útil de distribución horizontal.
- El producto no satisface WCAG 2.2, criterio 1.3.4, según la correspondencia interna adoptada por ADR 0022.
- Una revisión regulatoria o contractual futura puede exigir revertir esta decisión, aunque el ADR no afirme
  certificación ni conformidad legal.

## Testing y validación

- Test runtime del `UISupportedInterfaceOrientations` generado: conjunto exacto portrait en iPhone.
- Test source-backed: cuatro configuraciones iPhone portrait-only y cuatro configuraciones iPad adaptativas.
- Builds Xcode MCP de Develop y Production, diagnóstico del test afectado, focal de configuración y suite completa.
- Runtime iPhone: no rota a landscape y conserva operativo el recorrido portrait.
- Runtime iPad: portrait y ambos landscape continúan operativos; AX 5 y ventana estrecha conservan la evidencia de 07.3.
- Auditorías independientes iOS y accesibilidad sobre la configuración, clasificación y documentación finales.

## Migración o reversibilidad

La decisión es reversible restaurando ambos valores landscape en las cuatro configuraciones iPhone y actualizando sus
tests y evidencia. La reversión no requiere migración de datos, cambio de View ni modificación de iPad.

## Relaciones

- Sustituye únicamente la decisión de orientación de ADR 0025.
- Excepciona de forma limitada la disposición de cierre de ADR 0022 para este `A/No pasa`; conserva el resto de su
  objetivo y puerta de accesibilidad.
- No modifica ADR 0023/0024, fixtures Develop, Firebase/live, Domain, Data ni Presentation.

## Referencias

- [WCAG 2.2 — criterio 1.3.4 Orientation](https://www.w3.org/TR/WCAG22/#orientation)
- [Understanding Success Criterion 1.3.4](https://www.w3.org/WAI/WCAG22/Understanding/orientation.html)
- [WCAG2ICT — Applying SC 1.3.4 to Non-Web Documents and Software](https://www.w3.org/TR/wcag2ict-22/#orientation)
- [Apple — UISupportedInterfaceOrientations](https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations)
