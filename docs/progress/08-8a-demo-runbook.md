# Demo de clientes, productos, stock y servicios — 08.8a / 09 / 10 / PLU-47

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

## Catálogo de productos — 09.4

En el mismo proceso, abrir Catálogo → Productos: muestra «Champú DEMO hidratante» y «Mascarilla DEMO nutritiva».
Buscar por nombre, añadir un producto, editarlo y cancelar con descarte confirmado. Desactivar exige confirmación;
el producto queda visible como Inactivo y se puede editar su nombre. La desactivación descarta cambios de nombre
sin guardar, tal como avisa el diálogo. La hoja se cierra por sus acciones explícitas, no arrastrándola.
Guardar vacío muestra un error; corregir y guardar recorre la persistencia local real. El precio comercial pertenece a Servicios, no al inventario.

## Ajuste de stock — 09.6

Abrir un producto existente y pulsar «Ajustar stock». Champú arranca con8 unidades y Mascarilla con2.
Elegir Entrada o Salida, indicar unidades enteras positivas y un motivo; pulsar «Registrar».
«Ajuste registrado» confirma aceptación local. «Finalizar» vuelve a la ficha; reabrir el ajuste lee el saldo vigente.
Una salida de10 unidades del Champú inicial deja saldo−2, permitido y mostrado textualmente.

Probar unidades0 y motivo vacío; corregir después del error. Cancelar con datos muestra Descartar/Seguir editando.
El nombre sin guardar en la ficha padre se conserva al entrar/salir de stock. Los productos inactivos también permiten
ajustes; un producto nuevo debe guardarse antes. Un fallo de envío congela el ajuste para reintentar exactamente el mismo;
un fallo de recarga después de aceptar solo ofrece actualizar existencias, sin volver a registrar.

## Catálogo comercial — 10.5–10.6

Catálogo → Servicios muestra «Corte y peinado DEMO» (profesional, 35 EUR) y «Champú DEMO venta»
(producto, 20 EUR), vinculado a «Champú DEMO hidratante». Ambos tienen impuesto 21 y ningún descuento.
Buscar por nombre y añadir un servicio profesional. Guardar vacío muestra la validación; completar nombre, precio e
impuesto (por ejemplo 21). En español usar coma decimal, sin separadores de miles; descuento vacío significa ninguno.
La moneda puede ser EUR o USD. Guardar cierra y actualiza la lista mediante persistencia local real.

Abrir, editar y cancelar exige confirmar descarte. Desactivar confirma que conserva historial y descarta el borrador;
reabrir muestra Inactivo. En Tipo se puede elegir Profesional o Producto. Para Producto, abrir «Producto asociado»
y elegir uno activo; volver al formulario conserva todos los datos comerciales. Reabrir el selector permite sustituirlo.
Guardar sin elegir revela un error junto al selector. Cambiar a Profesional limpia el vínculo; volver a Producto exige
volver a elegir. Elegir por sí solo no guarda la ficha.

Si se desactiva el producto de inventario asociado, el servicio histórico sigue visible y desactivable. Su ficha muestra
el vínculo no disponible y puede recuperarse eligiendo otro producto activo o convirtiendo a Profesional. Guardar vuelve
a comprobar la disponibilidad actual sin perder el borrador si falla. Si falla la lectura del catálogo, «Reintentar productos»
recupera las opciones; no se afirma que el producto haya sido eliminado. Reiniciar restaura el escenario original.

## Borrador de servicio con Foundation Models — PLU-47

Solo en esta composición Develop, abrir Catálogo → Servicios → Nuevo servicio → Profesional.
La sección «Borrador con Apple Intelligence» permite escribir una descripción sintética y generar una propuesta.
Usar etiquetas explícitas y moneda: `Corte DEMO, precio 32,50 EUR, IVA 21 %, descuento 10 %` con locale español;
en inglés usar punto decimal y las etiquetas `price`, `tax`, `discount`.

1. Generar y revisar los campos propuestos; el formulario todavía conserva sus valores anteriores.
2. Rechazar descarta la propuesta. Aplicar rellena únicamente los campos presentes y permite deshacer antes de otra edición.
3. Completar o corregir el formulario y guardar con la acción habitual. Un impuesto ausente no se infiere:
   debe completarse manualmente si el formulario sigue vacío.
4. Cancelar una generación, cambiar de tipo o editar el formulario invalida cualquier respuesta tardía.
   Ir a segundo plano limpia el asistente y conserva el borrador manual.

El proveedor real usa el modelo local de Apple, sin red de fallback, tools ni almacenamiento del texto o la respuesta.
Requiere dispositivo, Apple Intelligence, idioma y recursos compatibles; una versión de iOS por sí sola no lo garantiza.
La ausencia del modelo o un error deja utilizable el formulario manual. Esta capacidad no está inyectada en el arranque
normal, Production ni las previews; las previews usan un proveedor determinista. La inferencia física y el corpus real
se acreditan solo con el ensayo correspondiente en [fase 16](phase-16.md), no con pruebas de dobles.

## Reinicio y límites de ambos recorridos

Terminar el proceso y volver a lanzar recrea los dos borradores y dos productos con saldos8/2 y los dos servicios iniciales, vacía documentos/recibos y rearma el primer fallo del modo
de recuperación. Ir a segundo plano o reabrir una pantalla no reinicia datos. Este reset no es recuperación durable.
El storage normal continúa no disponible; esta demo no utiliza Firebase, Keychain, telemetría real ni motores live.
No demuestra transporte, sincronización, persistencia entre procesos, fotografía ni venta. Los movimientos de stock de
la demo solo viven durante ese proceso. PLU-47 añade únicamente el borrador textual anterior, no la fase 16 completa.

Usar parámetros temporales de `DeviceInteractionInstallAndRun` al validar con Xcode MCP; no es necesario editar el esquema
para cada recorrido. Cerrar la sesión de interacción al terminar y conservar ambos argumentos `NO` en el esquema.
Resultados de validación y deuda accesible en [fase08](phase-08.md), [fase09](phase-09.md), [fase10](phase-10.md) y
[fase16](phase-16.md); diseño y límites en
[propuesta08.8a](08-8a-reusable-demo-proposal.md) y [ADR0030](../ADRs/0030-reusable-demo-and-early-foundation-models.md).
