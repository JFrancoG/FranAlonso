# 11.2 — Completar el cálculo monetario de ventas

2026-10-01. Usuario autoriza issue, rama e implementación local de 11.2.
[PLU-73](https://linear.app/plusprojects/issue/PLU-73), hija de PLU-71, Jesus Franco, In Progress.
Rama `codex/plu-73-sale-calculator`; base main limpia/sincronizada `c800ccd`.

## Autoridad y baseline

Constitución, specs 04/11, política Swift, ADR 0011/0015/0016/0030.
Perfil maintenance; Domain puro, Swift 6/complete/nonisolated, target efectivo iOS 27, SDK 27.0/Xcode 27.0.
MCP estable `workspace-PfnUYLlMzY`, Develop/plan Develop; destino inicial iPhone 11.
11.1 entregada en PR 33; fuente 546 intacta respecto a 1.753/1.753 resultados y builds Develop/Production.
Esa evidencia es baseline, no acredita este incremento. SaleCalculator existe desde 04.4, con diez tests.

## Contrato conservado

Precio snapshot con IVA incluido; descuento por línea antes de extraer base.
Money normaliza `.plain` a dos decimales EUR/USD. IVA residual = total menos base redondeada.
Agregar únicamente las líneas ya normalizadas, preservando id y orden, sin tocar snapshots.
Vacío devuelve cero en moneda explícita; monedas incompatibles y IDs duplicados rechazan.
Desgloses efímeros no Codable; no catálogo vivo ni descuento global (11.7).
No añadir una prohibición de precios negativos históricos: Money/SaleLine actualmente los admiten.

## Brechas y cambio propuesto

1. `subtotal * porcentaje /100` puede desbordar aunque el descuento final quepa.
   Escalar primero el subtotal por 10^-2 y multiplicar después el porcentaje, sin normalizar prematuramente a Money.
2. Operadores Decimal y Money.adding ocultan pérdida de precisión. En este calculador, usar NSDecimal* y comprobar
   estados y certificados de coeficientes descritos abajo: cantidad, suma/resta y factor fiscal exigen aritmética exacta;
   overflow, underflow, NaN o pérdida no demostrada
   producen el error existente MoneyError.invalidAmount. No cambiar Shared/Money ni introducir un techo de negocio.
3. División de IVA recurrente necesita precisión antes de redondear. Se admite `.noError`/`.lossOfPrecision` de
   NSDecimalDivide, pero no se confía solo en su resultado: si multiplicar el cociente por el factor reproduce
   exactamente el total, el cociente es exacto; en otro caso, certificar la base candidata mediante su intervalo
   de redondeo. Los bordes base ±0.005 y su producto por el factor deben calcularse exactamente.
   Para base positiva, intervalo [inferior, superior); negativa, (inferior, superior]; cero, ambos bordes abiertos.
   El factor es positivo y se construye exactamente; si los bordes no son representables, fallo cerrado.
   Evita rechazar todo IVA recurrente o aceptar céntimos ya perdidos con un mero roundtrip.
4. Preservar/revalidar `subtotal - descuento == total` y `base + IVA == total` también en los agregados.
   Helpers privados concretos en Sales, sin nueva capa, protocolo, dependencia, persistencia ni unsafe opt-out.
   Las referencias inout exigidas por NSDecimal* viven solo en la llamada síncrona sobre variables locales.

Implementación prevista: SaleCalculator.swift y helpers privados en ese archivo; tests nuevos en archivo propio.
El producto de descuento se calcula con NSDecimalMultiply `.down` y `.up`; se aceptan estados `.noError`
o `.lossOfPrecision` solo si ambos extremos normalizados mediante Money `.plain` coinciden y un certificado entero
independiente confirma ese redondeo.
Se rechazan errores, NaN o cotas con distinto céntimo: no se rechaza todo porcentaje preciso válido.
Las cotas dirigidas son válidas también para subtotales negativos; no se convierten a Double.
No se reescriben tests históricos, Money, DTO, modelos, configuración, ciclo de venta o UI.

## Alternativas

- Mantener operadores: mínimo código, pero pérdida/overflow ocultos; descartado.
- Rechazar toda división inexacta: rompe IVA21% ordinario; descartado.
- Un techo fijo o más guard digits: no prueba el redondeo alrededor de medio céntimo; descartado.
- Racional/BigInt propio o nueva librería: mayor alcance/dependencia; descartado.
- Aritmética comprobada y certificación por intervalo: elegida para preservar el contrato monetario actual.

## TDD y gates

RED real de descuento100% extremo representable y sumas/cantidad que pierden precisión monetaria.
Oráculos independientes y literales exactos: porcentajes fraccionarios, IVA0/100, cero, descuento nil/0/100,
empates positivos/negativos, monedas EUR/USD, Int.max representable, overflow, agregación y límites de precisión.
Descuentos de 38 dígitos ordinarios (19.99 y 12.345678901234567890123456789012345678 % => 2.47),
y productos próximos al empate ±0.03: resultado correcto o error explícito si las cotas son ambiguas.
Incluir caso fiscal diminuto sobre importe extremo: resultado correcto o rechazo explícito, nunca impuesto oculto.
Mantener los diez tests existentes y regresión de Domain/Sales/DTO/persistencia sobre snapshots.
Swift Testing/Xcode MCP; selección completa de variantes, `.xcresult` cerrado y logs completos.
Builds Develop-for-testing/Production, estilo Audit antes del GREEN final, PRE/POST independientes read-only.
UI/previews/accesibilidad N/A por ausencia de delta. Sin commit/push/PR/merge/cierre/live autorizados.

## Fuentes primarias examinadas

- [NSDecimalAdd](https://developer.apple.com/documentation/foundation/nsdecimaladd(_:_:_:_:)):
  límite de precisión y estados de cálculo.
- [NSDecimalDivide](https://developer.apple.com/documentation/foundation/nsdecimaldivide(_:_:_:_:)):
  cocientes recurrentes y precisión finita.
- [NSDecimalMultiply](https://developer.apple.com/documentation/foundation/nsdecimalmultiply(_:_:_:_:)) y
  [RoundingMode](https://developer.apple.com/documentation/foundation/nsdecimalnumber/roundingmode):
  productos con cotas dirigidas `.down`/`.up`, examinados por Cupertino y PRE.
- [NSDecimalMultiplyByPowerOf10](https://developer.apple.com/documentation/foundation/nsdecimalmultiplybypowerof10(_:_:_:_:)):
  escala decimal sin Double.
- [RoundingMode.plain](https://developer.apple.com/documentation/foundation/nsdecimalnumber/roundingmode/plain):
  empates alejándose de cero, examinada por Cupertino y referencia web oficial.

PRE inicial y reauditoría focal favorables tras resolver la restricción general de productos inexactos.
El RED nuevo y los gates posteriores se registran en [phase-11.md](phase-11.md).

## Ajuste focal por evidencia del runtime

La primera implementación obtiene 1.790/1.792; fallan únicamente las dos variantes de producto con pérdida de precisión.
`RunCodeSnippet` por Xcode MCP sobre el Simulator confirma:

- Precio exacto `999999999999999999999999999999999999.99` por Int.max:
  NSDecimalMultiply plain/down/up devuelven `.noError` y el mismo producto truncado.
  Resultado matemático independiente:
  `9223372036854775806999999999999999999907766279631452241.93`.
  El subtotal devuelto termina en `9900000000000000000`: se pierden `7766279631452241.93`.
- Sumar 0.01 a `3402823669209384634633746074317682114.55` (coeficiente UInt128.max) o restar -0.01:
  NSDecimalAdd/Subtract devuelven `.noError` y un importe terminado en `.5`, en lugar de `.56`.
  Se añade un RED del calculador para esta suma. El setup conserva el valor literal exacto.
- El SDK 27 advierte que la división puede ser silenciosamente inexacta. Un roundtrip Decimal tampoco prueba exactitud.

Por tanto los estados y las cotas calculadas solo con NSDecimalMultiply son insuficientes en este runtime.
Se propone un certificado privado de coeficientes para todas las operaciones del calculador:

1. Acceder únicamente a `Decimal.significand`, `.exponent` y `.sign`; convertir el significando positivo
   mediante NSDecimalString/POSIX a UInt128. El SDK documenta un coeficiente de 128 bits y la ejecución lo confirma.
   No acceder a almacenamiento privado ni suponer que el exponente normalizado está limitado a 127.
2. Un producto de dos coeficientes de 128 bits cabe exactamente en el par fijo high/low UInt128 que devuelve
   `multipliedFullWidth`. Normalizar ceros decimales mediante `dividingFullWidth` por diez con resto comprobado.
   Comparar coeficiente, exponente y signo con el resultado Decimal; el cero ignora signo y exponente.
3. Suma/resta: alinear los coeficientes al exponente menor en ese mismo par fijo, con reportingOverflow;
   sumar con carry o restar magnitudes ordenadas con borrow según los signos. Normalizar y certificar el resultado.
   Si una alineación no cabe en 256 bits y ambos operandos son distintos de cero, tampoco cabe un resultado Decimal
   exacto: una cancelación representable requiere que sus significandos de 128 bits puedan cubrir la diferencia.
   La escala por diez conserva coeficiente/signo y ajusta únicamente el exponente.
4. Descuento: además del prefiltro de cotas, redondear el producto entero exacto a dos decimales;
   dividir por diez hasta la escala monetaria, y usar el último resto >=5 para aumentar magnitud, también en negativos.
   Es `.plain`, no bankers. Exigir igualdad con Money candidato, conservando el porcentaje ordinario de 38 dígitos.
5. La prueba del cociente fiscal y los productos de bordes usan el mismo certificado de producto exacto.
   No se confía en un producto con `.noError` sin esta prueba adicional.

Es un certificado acotado a los coeficientes de Decimal, sin enteros de tamaño arbitrario, división racional,
API aritmética general, nueva capa, dependencia ni cambios a Money/persistencia/monedas/errores.
El comportamiento comercial y los oráculos aprobados permanecen iguales.
La decisión se registra antes del ajuste ejecutable en [ADR 0031](../ADRs/0031-sale-decimal-coefficient-certification.md).
PRE focal técnica sin hallazgos; reauditoría documental favorable, P2 de registro ADR resuelto antes del código.
Alternativas descartadas por la evidencia: status solamente, producto down/up solamente y división de retorno.

Fuentes adicionales: SDK 27 `Foundation.framework/Headers/NSDecimal.h`;
[SE-0425](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0425-int128.md), implementada en Swift 6;
[multipliedFullWidth](https://developer.apple.com/documentation/swift/int128/multipliedfullwidth(by:)).
UInt128 y el acceso público al coeficiente se han compilado/ejecutado por Xcode MCP en el target real.
