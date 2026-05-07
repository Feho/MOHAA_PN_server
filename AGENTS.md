# Repository Guidelines

## Project Structure & Module Organization
This is a Medal of Honor: Allied Assault dedicated server using OpenMoHAA plus custom mods. Most editable logic is MOHAA `.scr` scripting under `main/`.

- `main/server.cfg` contains server CVars, bot limits, map lists, and mod configuration.
- `main/global/feho/` contains shared systems such as map voting, HVT events, bot control, grenade alerts, and helpers.
- `main/maps/` contains map-specific scripts. DM maps live in `main/maps/DM/`; objective maps live in `main/maps/obj/`.
- `main/squadmaker_config/` and `main/supportgun_config/` contain loadout and squad variants.
- `main/*.pk3` are active packaged mods/assets; `main/disabled_mods/` stores inactive mods.
- `docs/` contains scripting references and design notes. `map_retention.py` is a standalone Python log-analysis tool.

## Build, Test, and Development Commands
There is no build system; scripts load directly from the filesystem.

- `./omohaaded +set dedicated 2 +set sv_maxclients 16 +set net_port 12203 +exec server.cfg +set logfile 2` starts a local Linux dedicated server.
- `"run dedicated server.bat"` starts the Windows server loop with crash restart.
- `sudo systemctl start mohaa-server` starts the configured Linux service.
- `sudo systemctl status mohaa-server` checks service health.
- `python3 map_retention.py ~/.openmohaa/main/qconsole*.log` reports map drop-off statistics.

After changing `.scr` files, restart the server or change maps. Check `~/.openmohaa/main/qconsole.log` for runtime errors.

## Coding Style & Naming Conventions
Use MOHAA script scope prefixes consistently: `local.`, `level.`, `game.`, `parm.`, and `self`. Keep functions as `name:` blocks ending with `end`. Use lowercase snake_case for new script files and functions, matching `main/global/feho/maprotate.scr`. Guard global systems with `level.<system>_initialized == 1`. Validate entities before use, and avoid loops without `wait`.

## Testing Guidelines
No automated test suite is present. Test gameplay changes on a development server, then exercise the affected map or event path. Use `println` for console diagnostics and `iprintln` only for temporary player-visible debugging. For map voting, consult `docs/map_voting_testing.md`.

## Commit & Pull Request Guidelines
Recent commits use concise Conventional Commit-style messages, often with scopes: `feat(bots): add bot profiles`, `fix(m3l3): respawn bots at the beginning so they're not stuck`. Follow that pattern. Pull requests should describe gameplay impact, list changed maps/configs, mention testing, and include screenshots or log excerpts when UI messages, voting flows, or server behavior change.

## Security & Configuration Tips
Do not commit private server credentials, admin passwords, or production-only config. Prefer `seta` for persistent CVars and `set` for runtime-only values. Package releases as ZIP files renamed to `.pk3`; use `zz_` prefixes only for intentional load priority.
