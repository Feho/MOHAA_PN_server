# Repository Guidelines

## Project Structure & Module Organization
This is a Medal of Honor: Allied Assault dedicated server using OpenMoHAA plus custom mods. Most editable logic is MOHAA `.scr` scripting under `main/`.

- `main/server.cfg` contains server CVars, bot limits, map lists, and mod configuration.
- `main/global/feho/` contains shared systems such as map voting, HVT events, bot control, grenade alerts, and helpers.
- `main/maps/` contains map-specific scripts. DM maps live in `main/maps/DM/`; objective maps live in `main/maps/obj/`.
- `main/*.pk3` are active packaged mods/assets; `main/disabled_mods/` stores inactive mods.
- `docs/` contains scripting references and design notes.

## Runtime Paths
- Server logs are at `~/.openmohaa/main/qconsole.log` — always check here first for log-driven analysis, never assume a different path.

## Common Commands & Verification
Routine operations are `just` recipes — run `just` with no arguments to list them all, and check there before writing a one-off shell command.

Before restarting the server or asking anyone to load a map, grammar-check your scripts:

```bash
just scrcheck-changed    # only the .scr files you've edited
just scrcheck            # every script under main/
```

This runs the engine's real lexer and grammar offline (`tools/scrcheck/`, built on first use from the openmohaa checkout). It catches typos and unbalanced braces in about a second. It does **not** catch duplicate labels, bad lvalues, or illegal `break`/`continue` — those come from the engine's codegen stage and still only appear at map load.

Other frequently used recipes: `just logs` (filtered server log), `just restart` (systemd), `just test-server` (local server on port 12204 with `developer 1`).

## Coding Style & Naming Conventions
Use MOHAA script scope prefixes consistently: `local.`, `level.`, `parm.`, and `self`. Keep functions as `name:` blocks ending with `end`. Use lowercase snake_case for new script files and functions, matching `main/global/feho/maprotate.scr`. Guard global systems with `level.<system>_initialized == 1`. Validate entities before use, and avoid loops without `wait`.

## Commit & Pull Request Guidelines
Recent commits use concise Conventional Commit-style messages, often with scopes: `feat(bots): add bot profiles`, `fix(m3l3): respawn bots at the beginning so they're not stuck`. Follow that pattern. Always include a body that describes the changes.
