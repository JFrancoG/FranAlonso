# Política del hook PreToolUse

El hook es una ayuda local, no una frontera completa de seguridad. Solo observa herramientas soportadas y nunca infiere
aprobación, alcance, TDD, arquitectura, accesibilidad o independencia de un revisor.

## Despliegue

1. Fase inicial: `audit`. El hook permite la llamada y aporta un aviso corto para medir falsos positivos.
2. Fase posterior: `enforce`, solo tras revisar fixtures y autorizar explícitamente la denegación.
3. Un cambio de reglas o script obliga a volver a revisar y confiar el hash del hook en Codex.

## Tabla determinista

| Política | Herramienta cubierta | Condición exacta | Audit | Enforce | Fallo |
|---|---|---|---|---|---|
| No usar `xcodebuild` | `Bash`/unified exec | Token de comando ejecutable igual a `xcodebuild` o ruta terminada en `/xcodebuild` | Avisar | Denegar | Fail-open |
| No reset destructivo | `Bash` | Comando Git con subcomando `reset` y opción `--hard` | Avisar | Denegar | Fail-open |
| No limpieza destructiva | `Bash` | Comando Git con subcomando `clean` y combinación que incluye force más `-d` o `-x` | Avisar | Denegar | Fail-open |
| No restauración masiva implícita | `Bash` | `git checkout -- <path>` o `git restore` con worktree/source sin autorización codificable | Avisar | Denegar | Fail-open |
| No borrado recursivo literal amplio | `Bash` | `rm` recursivo+force dirigido literalmente a `/`, `~`, `$HOME`, `${HOME}` o raíz Git | Avisar | Denegar | Fail-open |
| Ediciones | `apply_patch` | Sin regla sintáctica de alta confianza | No observar | No observar | N/A |
| MCP | MCP tools | Sin regla sintáctica común | No observar | No observar | N/A |

## Límites

- El parser usa `shlex` por comandos simples y separadores comunes; no ejecuta ni expande shell.
- Quoting, multilinea y rutas se cubren con fixtures. Command substitution y semántica completa de shell quedan fuera.
- `cwd` y raíz se normalizan con rutas reales. Fuera de la raíz del repositorio el hook no decide.
- Entrada malformada, herramienta distinta, excepción o timeout permiten la llamada sin escribir archivos.
- Presupuesto: menos de un segundo y salida máxima de un aviso o una decisión JSON.
- El script no lee transcripciones, secretos ni red y no escribe en disco.

## Activación de denegaciones

La configuración versionada permanece en `audit`. Cambiarla a `enforce` requiere revisar tests, falsos positivos y pedir
aprobación explícita; no forma parte de aceptar una fase o subfase.
