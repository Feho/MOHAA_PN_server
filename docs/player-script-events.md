# Script-Callable Player Events

Curated reference of player-entity events callable from `.scr` scripts in this
OpenMoHAA build. Each runs on a player entity, e.g. `player setteam "axis"`.

Source of truth: `code/fgame/player.cpp` (event table at ~line 2080).

## Verified build status (deployed `game.so`, May 2026)
- **`OPM_FEATURES` is ENABLED** — the `#ifdef OPM_FEATURES` block compiled in
  (confirmed: `earthquake2` / `visionsetnaked` strings present in `game.so`).
  The OPM-only commands below are available.
- **`sv_reborn` is a no-op** — not registered as a cvar anywhere in OpenMoHAA;
  the only `sv_reborn->integer` read is commented out (`hud.cpp:1011`). The
  "Requires sv_reborn" doc text on `earthquake2` / `playlocalsound` is stale
  carryover from the original Reborn patch. Setting it does nothing.

---

## Movement / control
| Command | Args | What it does |
|---|---|---|
| `setspeed` | `<mult> [index]` | Movement speed multiplier (1–4 stackable slots). Negative clamps to 0. |
| `movespeedscale` | `<mult>` | Same handler as `setspeed` — alias for scaling move speed. |
| `freezecontrols` | `<bool>` | Block/unblock player input (sets `PMF_FROZEN`). |
| `dive` | — | Force player into a prone dive. |
| `setanimspeed` | `<float>` | Scale the player's animation playback speed. |

## Team / spectator / state
| Command | Args | What it does |
|---|---|---|
| `setteam` | `"axis"\|"allies"\|"spectator"\|"freeforall"\|"none"` | Move player to a team. |
| `spectator` | — | Put the player into spectator. |
| `isSpectator` | — (returns) | Non-zero if spectating. |
| `adminrights` / `isadmin` | — | Query/admin-rights checks. |

## Scoring (custom game modes)
| Command | Args | What it does |
|---|---|---|
| `addkills` | `<int>` | Add to the player's kill count. |
| `adddeaths` | `<int>` | Add to the player's death count. |
| `killaxis` | — | Credit an axis kill. |
| `getkills` / `getdeaths` | — (return) | Read current counts. |

## Inventory / weapons
| Command | Args | What it does |
|---|---|---|
| `inventory` | — (return) | Get the player's inventory. |
| `inventory` (set form) | args | Set up the inventory. |
| `listinventory` | — | List the player's inventory. |
| `bindweap` | args | Bind a weapon to the player. |
| `preferredweapon` | args | Set preferred weapon slot. |

## Audio / feedback
| Command | Args | What it does |
|---|---|---|
| `playlocalsound` | `<sound> ...` | Play a sound only this player hears (stereo variant per doc string). |
| `stoplocalsound` | — | Stop the local sound. |
| `earthquake2` | args | Smooth per-player screen shake. (OPM) |

## Visuals — OPM-only (`#ifdef OPM_FEATURES`, confirmed enabled here)
| Command | Args | What it does |
|---|---|---|
| `visionsetblur` | args | Per-player screen blur. |
| `visionsetnaked` | args | Vision/post-process override. |
| `setentityshader` | args | Override the player's shader. |
| `setclientflag` | args | Set a client-side flag. |
| `setlocalsoundrate` | args | Adjust local-sound playback rate. |

## Querying / identity
| Command | Args | What it does |
|---|---|---|
| `userinfo` | — (return) | Get the player's userinfo string. |
| `getuserinfo` | args | Read a userinfo field. |
| `getconnstate` | — | **DEPRECATED** — always returns `4` (CS_ACTIVE), prints a warning. |
