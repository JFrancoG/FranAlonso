# ADR 0030 — Demo reutilizable y adelanto acotado de Foundation Models

## Estado

Aceptado el 29 de septiembre de 2026 por el propietario con «ok, me parece bien, adelante», sobre la propuesta de
definir primero una demo reutilizable, continuar catálogo, demostrar rellenado de un servicio y completar ventas,
aplazando 08.9 hasta después de la demo. Autoriza registrar la decisión y reconciliar specs/Linear; no inicia código,
publicación Git, distribución ni servicios live. Cada implementación conserva su propuesta, revisión y autorización.

## Contexto y alternativas

08.8 está entregada funcionalmente. Su smoke usó una composición temporal ya retirada; Storage normal sigue no
disponible. Repetir ese montaje para cada demostración cuesta tiempo y no constituye una demo mantenida.
Fran necesita ver clientes/consentimiento, productos, servicios, venta completa y una prueba visible del modelo local.

08.9 incluye fotografía, autorización posterior, reemplazo, retirada y detalle. La foto es opcional según ADR 0028;
no es una dependencia técnica del alta sin foto, del catálogo o de la venta. El orden anterior era de planificación.
El Product actual representa inventario; nombre comercial, precio y reglas comerciales pertenecen a Service.

Se comparan tres opciones: mantener 08.9 y toda fase 16 en el orden original; repetir montajes temporales de demo;
o mantener una composición aislada y adelantar solo un borrador textual. Se elige la tercera: reduce preparación y
permite feedback de producto antes, a cambio de mantener una composición adicional y reconciliar evidencia parcial.

## Decisión

### Secuencia y autoridad

- Preparar **08.8a**, composición de demo reutilizable descrita en spec 08. Después, fases **09 y 10**, adelanto acotado
  de **16**, y fases **11–13** para venta con pago, stock y documento final. Las dependencias internas se conservan.
- **08.9/PLU-43 queda pendiente con todo su alcance**, incluido detalle, receta/notas/histórico. No bloquea esta ruta
  de demo. Retomar tras el feedback de esa demo, antes del cierre integral de fase 08 y del candidato para uso real.
- Las fases conservan sus números; se añade 08.8a sin renumerar las existentes. El adelanto de 16 se registra como
  alcance parcial de sus subfases, nunca como cierre anticipado de toda la fase. Fases 14–18 siguen en el MVP.
- Las specs de fase siguen siendo el único plan; el índice expresa el orden excepcional y Linear su ejecución.
  Esta aceptación no demuestra implementación ni cambia estados de validación histórica.

### Composición reutilizable

- Perfil explícito exclusivo de **Debug-Develop**, desactivado por defecto, seleccionado antes del bootstrap remoto.
  Mantener las puertas de compilación, entorno/bundle e intención de arranque; intención inválida o conflictiva falla
  cerrada conforme a ADR 0025. Production y Release no contienen capacidad activable ni argumentos de demo.
- Reutilizar las capas reales de autenticación, Domain, persistencia local, UseCases, ViewModels y pantallas.
  Sustituir proveedores externos por adaptadores deterministas en sus fronteras Data; composición concreta en App.
  No construir Firebase, telemetría, factories remotas, motores live, almacén durable ni binding Keychain reales.
- Datos sintéticos coherentes en un contenedor SwiftData en memoria y un escenario inicial conocido. Un nuevo
  lanzamiento recrea el escenario; no promete conservar cambios entre procesos ni demostrar recuperación durable.
  No se cambian las fixtures vacías de autenticación ni sus pruebas. Las futuras capacidades se incorporan al mismo
  perfil cuando exista su implementación, no mediante pantallas que simulen estados de éxito.
- La primera entrega cubre clientes sin foto, firma y envío/activación simulados. Catálogo se añade en 09–10; los
  adaptadores de documento/numeración de ventas se añaden al implementar 13. No anticipar todos esos módulos en 08.8a.
- Identificar la demo y sus datos sintéticos. La futura numeración de demostración usa un espacio aislado y PDFs
  inequívocamente de muestra; no consume series reales ni sustituye la transacción real exigida por ADR 0008.
  Las reglas de negocio siguen rechazando documentos ausentes o inválidos; no se fuerza un cliente activo o una venta
  cerrada para saltarse las invariantes. Sin envío de correo real en la demo.

### Foundation Models visible

El alcance canónico vive en spec 16: una descripción escrita propone campos de **un servicio profesional** en el
formulario normal ya operativo. Inferencia Apple local real, salida tipada y validada, edición/rechazo y guardado
visual habitual. No inventar campos ausentes ni dar al modelo acceso a persistencia o mutaciones. Corpus sintético,
disponibilidad real, cancelación, errores, respuestas tardías y privacidad son parte del primer incremento.

Se comprueba pronto el dispositivo previsto y el estado real del modelo; el fallback manual conserva el trabajo y
explica indisponibilidad, pero no cuenta como demostración satisfactoria de Foundation Models. No hay fallback cloud.
Speech, TTS, escucha continua y ensayo de ocho horas conservan sus puertas posteriores; no se requiere incorporarlos
para este borrador textual. Los tests usan dobles; la evidencia de demo del modelo requiere inferencia real.

### Calidad y recuperación

ADR 0029 sigue vigente: construcción accesible, revisión focal, previews representativas, TDD, validación técnica y
recorrido funcional por entrega. PLU-44/45 y PLU-38 conservan resultados, responsables y límites. Los nuevos incrementos
registran su propia deuda aplicable; no heredan un PASS. Retomar por flujo tras feedback y estabilización, antes de uso
real. Integridad, privacidad y bloqueos funcionales nunca se aplazan. Fase 18 comprueba también 08.9 y el resto de 16.

## Consecuencias, validación y reversibilidad

Se obtiene un escenario repetible y una demostración útil del modelo sin esperar al asistente de voz completo.
La composición de demo exige mantenimiento y puede ocultar errores de red, proveedor, durabilidad o integración:
su evidencia se etiqueta como simulada y no sustituye las pruebas de esas fronteras ni la puerta live.

Antes de implementar cada incremento: propuesta concreta, revisión independiente y APIs oficiales compatibles con
el target real. Para 08.8a, comprobar aislamiento, reset, consistencia de datos y recorrido de alta; para el adelanto,
corpus determinista más inferencia real en dispositivo y flujo manual intacto. Para esta decisión documental,
build/tests/previews nuevos N/A; verificar enlaces, dependencias, gobernanza y revisión independiente.

El perfil y el punto de entrada anticipado se pueden deshabilitar sin migrar datos reales ni alterar los contratos de
negocio. La evidencia parcial se reutiliza por impacto al completar fase 16; el alcance pendiente continúa explícito.

## Relaciones

- [Spec 08](../specs/08_clients_consent.md), [09](../specs/09_products_stock.md),
  [10](../specs/10_services_catalog.md), [13](../specs/13_billing_pdf_email_counters.md),
  [16](../specs/16_on_device_voice_assistant.md) e [índice](../specs/00_index.md).
- [ADR 0023](0023-develop-only-non-live-auth-fixture.md): complementa la fixture con un perfil separado que permite
  escenarios sintéticos sembrados. Conserva su aislamiento y su fixture original vacía.
- [ADR 0025](0025-develop-only-auth-root-error-fixtures.md): conserva fail-closed de intenciones explícitas inválidas.
- [ADR 0010](0010-on-device-assistant-provider-strategy.md): sustituye solo la secuencia de ejecución de la porción
  textual; conserva fronteras, privacidad y alcance completo del asistente posterior.
- [ADR 0029](0029-progressive-accessibility-validation.md): sustituye solo la conservación del orden anterior de
  ejecución; mantiene íntegra la política de validación y cierres. Ningún ADR aceptado se reescribe.
- [ADR 0028](0028-client-signed-information-and-photo-authorization.md) y
  [ADR 0008](0008-atomic-billing-numbering.md): contratos reales de autorización y numeración intactos.
