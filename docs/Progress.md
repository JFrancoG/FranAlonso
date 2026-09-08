# Project Progress

Última actualización: 2026-09-08

## Puerta actual

- Fase 08 iniciada por autorización del propietario. Padre [PLU-34](https://linear.app/plusprojects/issue/PLU-34) y
  [PLU-35 / 08.1](https://linear.app/plusprojects/issue/PLU-35) en `In Progress`.
- Rama `codex/plu-35-phase-08-1-client-crud-search`, desde `main` limpio en `c24f6e5`.
- 08.1 implementa contratos/casos de uso de alta, lectura, edición, desactivación y búsqueda local. Crear fuerza
  `draft`; editar conserva consentimiento/estado; desactivar retiene el último perfil local y lo excluye de CRUD.
- La propuesta independiente pasa después de retirar una garantía CAS entre contextos que el diseño no ofrecía.
  No cambia esquema, protocolo remoto, Presentation ni configuración permanente. Los motores live siguen inactivos.
- Xcode MCP: regresión por 22 suites completas, **168/168**; build `FranAlonso-Develop` correcto en 3,580 s;
  resumen MCP/Navigator y cuatro diagnósticos focales en cero. El log completo conserva el aviso conocido de
  extracción AppIntents; no se declara cero warnings globales. Fixture temporal signed-out restaurada byte a byte;
  no se ha ejecutado una nueva validación Production ni la suite global.
- Auditoría final iOS/estilo PASS. P2 de evidencia de warnings corregido y cerrado por reauditoría documental;
  sin hallazgos abiertos. Previews y accesibilidad `N/A`: sin cambios de UI, recursos o semántica accesible.
- Alcance, TDD, rutas de evidencia y límites: [fase 08](progress/phase-08.md).

## Entregas anteriores

- Fases 01–06 cerradas; histórico en [phases-00-06.md](progress/phases-00-06.md).
- Entregables de fase 07 integrados: PLU-26–PLU-33 están `Done`. PLU-25 mantiene pendiente su cierre administrativo
  independiente; iniciar 08.1 no lo cierra. Última entrega Swift: PR #9, `c8bb283`; cierre documental en `99709d1`.
- El detalle de entregas, auditorías y accesibilidad permanece en [fase 07](progress/phase-07.md). ADR 0026 conserva
  la excepción de orientación 1.3.4; loading mantiene la limitación aceptada de 07.3. No se declaran nuevas pruebas AT.

## Siguiente acción y límites

El propietario autoriza commit/push de 08.1 e inicio de 08.2 el 2026-09-08; ejecución y verificación en curso.
PR, merge y cierre de issues conservan autorización independiente. El histórico retenido es local: no se recupera
un perfil que un dispositivo nunca tuvo.
