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

## Coding Style & Naming Conventions
Use MOHAA script scope prefixes consistently: `local.`, `level.`, `parm.`, and `self`. Keep functions as `name:` blocks ending with `end`. Use lowercase snake_case for new script files and functions, matching `main/global/feho/maprotate.scr`. Guard global systems with `level.<system>_initialized == 1`. Validate entities before use, and avoid loops without `wait`.

## Commit & Pull Request Guidelines
Recent commits use concise Conventional Commit-style messages, often with scopes: `feat(bots): add bot profiles`, `fix(m3l3): respawn bots at the beginning so they're not stuck`. Follow that pattern. Always include a body that describes the changes.
