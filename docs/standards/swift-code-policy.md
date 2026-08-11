# Política Swift propia de FranAlonso

Esta referencia conserva reglas semánticas estables que no deben residir en un skill procedural. La constitución la
mantiene como autoridad y `AGENTS.md` la enruta solo cuando se modifica Swift.

## Modelado y conformidades

- Siempre que sea semánticamente posible, los value types y modelos de Domain usan identidad estable e inmutable y
  conforman a `Identifiable`, `Codable` y `Equatable`.
- Declarar solo el protocolo más específico; no repetir un protocolo heredado como `Equatable` junto a `Hashable`, salvo
  exigencia compilada de una frontera condicional o genérica y motivo documentado.
- Los valores internos confían en `Sendable` inferido cuando todos sus miembros lo permiten. Los actores no repiten
  `Sendable`. Una conformidad explícita requiere una frontera compilada real y no oculta estado no enviable.

## Conversiones Data/Domain

- Una conversión concreta y determinista sin dependencia, configuración, versionado, política o estrategia vive en una
  extensión de la representación propiedad de Data.
- Usar `toDomain()` para reconstruir Domain y un inicializador de conversión sin etiqueta, como `ClientDTO(client)`, para
  el sentido inverso.
- Domain no conoce DTO ni modelos persistentes. Introducir `Mapper` solo cuando posea una responsabilidad real demostrada.

## Namespaces

- No usar un `enum` sin casos solo como namespace de miembros estáticos.
- Elegir por semántica: extensión del tipo propietario, servicio/valor real compuesto o función/constante con el acceso más
  estrecho cuando no exista propietario.
- Un enum sin casos sigue siendo válido si el conjunto imposible de valores es el contrato modelado. No sustituirlo
  mecánicamente por un `struct` sin estado.

## Construcción e invariantes

- Mantener la declaración primaria de un `struct` libre de inicializadores explícitos.
- Usar el memberwise sintetizado cuando expresa el contrato; eliminar inicializadores que solo copian argumentos.
- Usar factory estática con nombre para estados, presets o composiciones semánticas. Mantener inicializadores validantes,
  de inyección, composición o `Decodable` en extensiones del mismo archivo.
- Una invariante se garantiza al construir. Si la síntesis pudiera eludirla, usar almacenamiento privado y API de solo
  lectura; no sustituirla por `isValid` o `validate()` posteriores.

## Formato

- Límite preferido de 120 columnas incluida la indentación.
- Mantener `func`, `init` o `subscript` en una línea si la firma completa cabe y tiene hasta tres parámetros simples.
- Usar formato vertical con un parámetro por línea cuando supera 120 columnas, tiene cuatro o más parámetros, closures,
  tipos función, genéricos/tuplas complejos, atributos de closure, defaults multilínea o requisitos genéricos.
- Mantener `let` y `var` en una línea cuando la declaración completa cabe y el inicializador no es multilínea.
- Mantener `guard condition else { exit }` en una línea solo si cabe y `exit` es una transferencia inmediata simple.
- Una función completa puede ir en una línea solo si es un predicado, accessor, adaptador o doble puro y trivial. Negocio,
  mutación, `await`, `try`, control de flujo y efectos permanecen multilínea.
- Aplicar estas reglas a código nuevo o tocado; separar cualquier formateo histórico del cambio funcional.

## DocC

- Documentar en inglés tipos y contratos semánticos de producción nuevos o modificados: Domain, Repository, UseCase,
  políticas, factories, validación, transiciones y operaciones no obvias con errores, asincronía o mutación.
- Explicar invariantes, unidades, efectos, idempotencia, cancelación, parámetros, retorno y errores solo cuando añaden
  información a la firma.
- No documentar propiedades evidentes, Views, Codable mecánico, helpers triviales ni tests por cobertura.
