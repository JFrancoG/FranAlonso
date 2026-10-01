# ADR 0031 — Certificar la precisión decimal del calculador de ventas

## Estado

Aceptado para la implementación local de 11.2. 2026-10-01.

Decisión técnica de Codex dentro del alcance autorizado por el propietario: abrir issue, rama e implementar 11.2.
La revisión PRE independiente confirma proporcionalidad y ausencia de excepción arquitectónica.
No atribuye al propietario una aprobación específica adicional del algoritmo ni autoriza entrega Git o live.
Complementa el contrato de [spec04](../specs/04_domain_model.md) y [spec11](../specs/11_sales_engine.md);
no sustituye ADR aceptados ni cambia monedas, snapshots, persistencia o reglas comerciales.

## Contexto

Los precios de venta incluyen IVA. Cada componente se redondea por línea con Money `.plain` a dos decimales EUR/USD;
solo después se agregan las líneas. Los resultados deben satisfacer subtotal menos descuento igual a total y
base más IVA igual a total, rechazando un importe no representable con MoneyError.invalidAmount.

Los RED de [11.2](../progress/phase-11.md) muestran overflow intermedio del descuento y pérdida de céntimos al agregar.
La primera implementación con NSDecimal* alcanza 1.790/1.792; falla la precisión de cantidad en EUR/USD.
Los diagnósticos Xcode MCP en iOS confirman NSDecimalMultiply plain/down/up con noError y producto truncado,
además de NSDecimalAdd/Subtract con noError y pérdida en el borde del coeficiente de 128 bits.
Un RED adicional confirma la suma defectuosa. Ni ese estado, ni dos cotas iguales, ni un roundtrip bastan como prueba.

## Decisión

Conservar las operaciones Foundation y sus estados, añadiendo un certificado privado en SaleCalculator.swift:

- Leer exclusivamente significand, exponent y sign públicos; NSDecimalString/POSIX convierte el coeficiente a UInt128.
  El coeficiente Decimal es de 128 bits. No acceder al almacenamiento interno.
- Usar el par fijo high/low UInt128 de multipliedFullWidth para un producto exacto de dos coeficientes.
  Normalizar ceros decimales con división por diez y resto comprobado. Comparar signo, coeficiente y exponente.
  El cero ignora signo/exponente; un exponente normalizado puede superar 127 sin alterar el Decimal original.
- Para suma/resta, normalizar y alinear al menor exponente en el mismo par fijo; comprobar overflow, carry y borrow.
  Signos distintos restan magnitudes ordenadas y conservan el signo de la mayor. La cancelación exacta es cero.
  Si la alineación excede 256 bits, el coeficiente menor de hasta 128 bits no puede cancelar hasta un Decimal exacto:
  con exponentes distintos, el coeficiente menor normalizado deja una última cifra no nula. Rechazar ese resultado.
- Certificar la escala conservando coeficiente/signo y ajustando exponente; comprobar los estados y NaN igualmente.
- Certificar el descuento contra el producto entero exacto redondeado a la escala de Money: dividir por diez hasta
  dos decimales y aumentar magnitud si el último resto es >=5. Los empates negativos también se alejan de cero.
  El candidato de las cotas Foundation solo se acepta si coincide con ese certificado.
- El cociente fiscal sigue requiriendo producto exacto que reproduzca el total o un intervalo de redondeo probado;
  tanto ese producto como los productos de los bordes usan el certificado. El IVA es el residual total menos base.

Este certificado tiene tamaño fijo y finalidad privada. No es un motor BigInt de tamaño arbitrario, una división
racional, una API aritmética general ni una nueva capa. Shared/Money y los modelos/DTO permanecen intactos.

## Alternativas y consecuencias

- Status Foundation, cotas de Multiply o división de retorno: descartados por evidencia del runtime.
- Rechazar todo producto inexacto: descartado; rompería porcentajes válidos de 38 dígitos con céntimo determinable.
- Un techo de negocio o más guard digits: descartados; restringen el dominio o no demuestran exactitud.
- Librería BigInt o motor racional propio: descartados por dependencia y alcance mayores.
- Certificado fijo nativo: elegido; elimina pérdidas silenciosas sin cambiar los resultados comerciales ordinarios.

El coste es más código numérico privado y revisión de signos, ceros y límites. Swift Testing conserva oráculos
literales, ambos signos/monedas, cancelación extrema, borrow, overflow, precisión, empates y payloads snapshot.
PRE focal antes del código, GREEN completo, builds y POST independiente son obligatorios; los diagnósticos no son GREEN.
La retirada es local al calculador y sus tests: no requiere migración de datos ni cambio de formato o configuración.
UI/accesibilidad N/A. La implementación local no cierra la issue ni la fase.

## Fuentes

- SDK 27: Foundation.framework/Headers/NSDecimal.h; coeficiente de 128 bits y división silenciosamente inexacta.
- [Decimal.significand](https://developer.apple.com/documentation/foundation/decimal/significand),
  [NSDecimalString](https://developer.apple.com/documentation/foundation/nsdecimalstring(_:_:)).
- [UInt128](https://developer.apple.com/documentation/swift/uint128),
  [multipliedFullWidth](https://developer.apple.com/documentation/swift/int128/multipliedfullwidth(by:)),
  [dividingFullWidth](https://developer.apple.com/documentation/swift/fixedwidthinteger/dividingfullwidth(_:)).
- [SE-0425](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0425-int128.md): incorporada en Swift 6.
- [Propuesta y evidencia de runtime](../progress/11-2-sale-calculator-proposal.md).
