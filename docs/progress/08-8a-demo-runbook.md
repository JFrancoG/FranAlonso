# Demo de clientes — 08.8a

## Arranque

Usar el esquema **FranAlonso-Develop**, configuración **Debug-Develop**, y activar exclusivamente uno de estos
argumentos de LaunchAction (ambos se conservan desactivados en Git):

| Argumento | Recorrido |
|---|---|
| `--franalonso-demo-clients` | Alta normal con envío simulado. |
| `--franalonso-demo-clients-response-lost` | Primer envío aceptado por el proveedor simulado, con respuesta perdida. |

No combinar con argumentos `--franalonso-auth-fixture-*` ni `--franalonso-clients-fixture-*`. Una intención de demo
inválida dentro de la capacidad Develop termina en la pantalla de configuración fallida antes de Firebase.
Production/Release no contienen una demo activable. El arranque normal sin argumentos conserva su composición habitual.

La raíz muestra «Demo · Datos de ejemplo». Credencial exclusivamente sintética, compartida con las fixtures existentes:
correo `accessibility@franalonso.invalid`, contraseña `FranAlonso-Fixture-Only`. No utilizar datos ni firmas personales.
El login, navegación, formularios, lectura, firma, conservación y activación atraviesan las capas reales.

## Recorrido normal

1. Entrar con la credencial sintética y abrir Clientes.
2. Ver «Cliente DEMO Alba» y «Cliente DEMO Bruno», ambos borradores sin foto ni documento inicial.
3. Editar uno o crear un cliente de ejemplo. Revisar información, dibujar una firma de prueba y conservarla.
4. Pulsar «Reintentar envío», la acción que muestra el documento conservado pendiente de envío. El proveedor en memoria
   lo acepta; la confirmación «Cliente activo» refleja la activación real local.
5. Cerrar y reabrir la ficha para comprobar el documento/alta. Cerrar sesión y volver a entrar conserva el mismo proceso.

## Recorrido de recuperación

Con el segundo argumento, seguir el mismo recorrido hasta el envío. Solo el primer envío del proceso pierde la respuesta
después de la aceptación simulada. La UI muestra el error y conserva el documento pendiente, sin activar todavía.
Cerrar/reabrir la ficha, abrir «Reanudar documento» y pulsar «Reintentar envío»: se recupera el mismo recibo y se activa
sin firmar de nuevo. «Finalizar alta» corresponde al caso distinto de recibo ya confirmado con activación local pendiente.
Los envíos siguientes del mismo proceso funcionan normalmente. No crear otro documento para resolver ese error.

## Reinicio y límites

Terminar el proceso y volver a lanzar recrea los dos borradores, vacía documentos/recibos y rearma el primer fallo del modo
de recuperación. Ir a segundo plano o reabrir una pantalla no reinicia datos. Este reset no es recuperación durable.
El storage normal continúa no disponible; esta demo no utiliza Firebase, Keychain, telemetría real ni motores live.
No demuestra transporte, sincronización, persistencia entre procesos, fotografía, catálogo, venta o Foundation Models.

Usar parámetros temporales de `DeviceInteractionInstallAndRun` al validar con Xcode MCP; no es necesario editar el esquema
para cada recorrido. Cerrar la sesión de interacción al terminar y conservar ambos argumentos `NO` en el esquema.
Resultados de validación y deuda accesible en [fase08](phase-08.md); diseño y límites en
[propuesta08.8a](08-8a-reusable-demo-proposal.md) y [ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md).
