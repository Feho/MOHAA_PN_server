# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Clarification Rule
- If a feature request is ambiguous (tuning knob, behavior change, scope of a cleanup), ask one clarifying question before implementing rather than guessing.
- For bot AI tuning specifically, ask: "what should the bot do differently in observable terms?"

## Working Pattern
- Default flow for non-trivial work: analyze codebase → write plan to `plans/<feature>.md` → get Codex/advisor review → implement → commit.
- After non-trivial bot AI changes, always request a Codex or advisor second opinion before committing. Treat findings as a required fix-up pass, not optional.

## Runtime Paths
- Server logs are at `~/.openmohaa/main/qconsole.log` — always check here first for log-driven analysis, never assume a different path.

## Project Overview

This is a Medal of Honor: Allied Assault (MOHAA) dedicated server running the OpenMoHAA engine with custom gameplay mods. The "code" in this repo is primarily MOHAA `.scr` scripts and server configuration — there is no traditional build system.

## Server Management

**Start server (Linux, via systemd):**
```bash
sudo systemctl start mohaa-server
sudo systemctl status mohaa-server
```

**Start server manually (Linux):**
```bash
./omohaaded +set dedicated 2 +set sv_maxclients 16 +set net_port 12203 +exec server.cfg +set logfile 2
```

**Start server (Windows):**
Run `"run dedicated server.bat"` — includes auto-restart on crash.

**Reload a script change:** Restart the server or change maps. Scripts are re-executed each map load.

**Server logs:** `~/.openmohaa/main/qconsole.log`

## Architecture

### How Map Loading Works

When a map starts, the engine automatically executes `main/maps/<mapname>.scr`. That script's `main:` block calls `exec` or `waitthread` to load global systems. The typical call chain in a map script:

```
maps/m1l1.scr::main
  → exec global/DMprecache.scr          (asset caching)
  → exec global/squadmaker/squadmaker.scr (squad system)
  → exec global/feho/events.scr         (player event subscriptions)
  → exec global/feho/hvt_event.scr      (HVT event system)
  → exec global/feho/mapvote.scr        (map voting)
  → exec global/feho/maprotate.scr      (weighted map rotation)
```

Global scripts guard against double-initialization with `level.xxx_initialized == 1` checks.

### Custom Scripts (`main/global/feho/`)

| Script | Purpose |
|---|---|
| `events.scr` | Subscribes to `player_spawned`, `player_killed`, `player_damaged`; adjusts bot weapons and damage |
| `mapvote.scr` | End-of-round voting between 2 map candidates; players type `1` or `2` in chat |
| `maprotate.scr` | Weighted map selection with recent-map history; avoids replaying recently played maps |
| `hvt_event.scr` | Mid-match High-Value Target event; top scorer on each team becomes HVT |
| `utils.scr` | Shared helpers: player enumeration, weapon class detection, alive-player queries |
| `bomb.scr` | Search & Destroy bomb pickup/scan logic |
| `botcount.scr` | Allows players to control bot count via chat commands |
| `difficulty_adjustment.scr` | Rubber-banding: reduces damage taken by human players on a death streak (5+ deaths → 50% reduction, 8+ → 80%) |
| `squad.scr` | Custom squad logic |
| `messages.scr` | Periodic server broadcast messages |
| `grenade_alert.scr` | Warns teammates when a grenade lands nearby |
| `anticheat.scr` / `antinoob.scr` | Server-side cheat/noob-weapon detection |

### Map Scripts (`main/maps/`)

Each map script configures game mode, spawn points, and which global systems to load. Maps can override game type, set objective text, configure squadmaker area name and config (`level.squadmaker_config`).

### Map Rotation System

Map rotation is driven by two cooperating scripts:
- `maprotate.scr` owns the **weighted candidate selection** and **recent-map history** (stored in the `feho_map_recent` cvar so it survives map changes).
- `mapvote.scr` calls `maprotate.scr::choose_vote_options` to get two candidates, presents them to players, then commits the winner via `maprotate.scr::record_current_map`.
- `sv_maplist` in `server.cfg` is a **fallback/reference** — active rotation is driven by the scripts.

### Configuration

Main config: `main/server.cfg`. Key CVars:
- `g_gametype 2` = Team Deathmatch (default)
- `g_realism 1` = realism mode (reduced ammo, modified damage)
- `sv_minPlayers` / `sv_maxbots` = bot fill settings
- `g_hvt_bonus` = bonus score for killing an HVT (default: 10)
- `sqdmk_grenade_startammo` = grenade count per spawn in squadmaker
- `support_config` = squadmaker loadout config (`"realism"`, `"afrika"`, `"art_of_war"`)

Use `seta` for persistent CVars, `set` for runtime-only.

## Scripting Reference

### Variable Scopes
- `local.x` — local to current thread
- `level.x` — persists for the current map
- `game.x` — persists across maps (rarely used)
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

### Debugging
- Use `iprintln` for on-screen messages to all players, `println` for server console.
- Check `~/.openmohaa/main/qconsole.log` for script errors and `println` output.
- Common errors: NIL entity access, calling a function on a removed entity, infinite loops without `wait`.

## Mod Packaging

Scripts are loaded directly from the filesystem in development. For distribution, package scripts and assets into a `.pk3` file (ZIP format renamed to `.pk3`). Load order is alphabetical — prefix with `zz_` to load last (highest priority).

Active mods live in `main/`. Inactive mods are in `main/disabled_mods/`.

## Docs

The `docs/` directory contains:
- `scripting_documentation.md` — full MOHAA scripting language reference
- `01-script-events.md` — list of subscribable game events
- `map_voting_system.md` / `map_voting_testing.md` — mapvote design and test plan
- `pk3s_codebase.md` — content of all .scr files in one markdown file (useful to see all scripts at a glance)
