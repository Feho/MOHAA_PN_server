# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Clarification Rule
- If a feature request is ambiguous (tuning knob, behavior change, scope of a cleanup), ask one clarifying question before implementing rather than guessing.
- For bot AI tuning specifically, ask: "what should the bot do differently in observable terms?"

## Runtime Paths
- Server logs are at `~/.openmohaa/main/qconsole.log` — always check here first for log-driven analysis, never assume a different path.

## Project Overview

This is a Medal of Honor: Allied Assault (MOHAA) dedicated server running the OpenMoHAA engine with custom gameplay mods. The "code" in this repo is primarily MOHAA `.scr` scripts and server configuration — there is no compile step for scripts; the engine loads them from disk at map load.

## Common Commands

Routine operations live in the `justfile` — run `just` with no arguments to list every recipe. Check there before hand-rolling a shell command; the common ones already exist:

```bash
just scrcheck            # grammar-check every .scr under main/ (see below)
just scrcheck-changed    # grammar-check only what you've edited
just logs                # filtered server log (joins/leaves/chat/anticheat)
just restart             # restart prod via systemd
just status              # prod service status
just test-server         # local test server on port 12204 (cheats + developer on)
```

### Checking scripts before a map load

`just scrcheck` runs the engine's own lexer and grammar (`tools/scrcheck/`, built on
first use from the openmohaa checkout) over every script offline. It catches typos and
unbalanced braces in about a second, without restarting anything.

It is a **grammar check only** — it stops before the engine's codegen stage, so
duplicate labels, bad lvalues, and illegal `break`/`continue` still surface only at map
load. A clean run means "the parser accepts it", not "the map will load".

## Architecture

### How Map Loading Works

When a map starts, the engine automatically executes `main/maps/<mapname>.scr`. That script's `main:` block calls `exec` or `waitthread` to load global systems.
Global scripts guard against double-initialization with `level.xxx_initialized == 1` checks.

## Scripting Reference

### Variable Scopes
- `local.x` — local to current thread
- `level.x` — persists for the current map
- `parm.x` — parameters passed to a thread/exec
- `self` — the entity the script is running on

### Calling Other Scripts
```scr
exec global/feho/utils.scr                        // fire and forget
thread global/feho/utils.scr::function_name       // async
waitthread global/feho/utils.scr::function_name   // synchronous, can return a value
local.result = waitthread global/feho/utils.scr::get_weapon self
```

### Event Subscriptions
```scr
event_subscribe "player_spawned" event_player_spawned
event_subscribe "player_damaged" event_player_damaged
event_subscribe "player_killed" event_player_killed
event_subscribe "player_textMessage" event_player_textMessage
```

### Useful Built-ins
```scr
getcvar "cvar_name"          // read a cvar
setcvar "cvar_name" value    // write a cvar
isBot entity                 // true if entity is a bot
isalive entity               // true if entity is alive
iprintln "msg"               // print to all players' screens
println "msg"                // print to server console
randomint(n)                 // random integer 0..n-1
int(value)                   // cast to integer
```

## Mod Packaging

Scripts are loaded directly from the filesystem in development. For distribution, package scripts and assets into a `.pk3` file (ZIP format renamed to `.pk3`). Load order is alphabetical — prefix with `zz_` to load last (highest priority).

Active mods live in `main/`. Inactive mods are in `main/disabled_mods/`.

## Docs

The `docs/` directory contains:
- `scripting_documentation.md` — full MOHAA scripting language reference
- `01-script-events.md` — list of subscribable game events
- `pk3s_codebase.md` — content of all .scr files in one markdown file (useful to see all scripts at a glance)
