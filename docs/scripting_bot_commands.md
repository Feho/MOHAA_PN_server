# New scripting bot commands

- bot_holdposition 0|1
- bot_holdposition <vector> [duration] [radius]
- bot_stop
- bot_stand 0|1
- bot_crouch 0|1
- bot_prone 0|1
- bot_moveto <vector>
- bot_movenear <vector> <radius>
- bot_lookat <vector>
- bot_clearlook
- bot_watchat <vector>
- bot_clearwatch
- bot_primaryfire 0|1
- bot_secondaryfire 0|1
- bot_use 0|1
- bot_reload
- bot_releasecontrol
- bot_commandstatus <command_id>

Plus one `waittill` on the bot entity: `bot_move_done`.

## Knowing when a move finished

`bot_moveto`, `bot_movenear` and the vector form of `bot_holdposition` return a
**command ID**. The bot signals `bot_move_done` when that command reaches a terminal
state, and `bot_commandstatus` says which one:

| Status | Meaning |
|---|---|
| `running` | still travelling |
| `reached` | arrived at the goal |
| `failed` | unreachable, or the path was lost |
| `cancelled` | `bot_stop`, `bot_releasecontrol`, `bot_holdposition 1`, or respawn |
| `superseded` | a newer movement order replaced this one |
| `NIL` | unknown ID — recycled slot, or not a bot |

```scr
local.id = local.bot bot_moveto (1024 -512 32)
local.bot waittill_timeout 30 bot_move_done
local.status = local.bot bot_commandstatus local.id
```

The plain forms still work unchanged — `local.bot bot_moveto (x y z)` with no assignment
behaves exactly as before, so existing scripts need no edits.

### Two rules that matter

**Check the status before waiting.** A `bot_move_done` that fires before your thread
reaches the `waittill` is *lost* — the engine's wake is a no-op when nobody is registered,
and the wait then blocks until its timeout. So read `bot_commandstatus` first and only wait
while it says `running`, with nothing that yields in between:

```scr
local.status = local.bot bot_commandstatus local.id
if (local.status == "running")
{
    local.bot waittill_timeout 30 bot_move_done
    local.status = local.bot bot_commandstatus local.id   // why did we wake?
}
```

**Prefer `waittill_timeout` over `waittill`.** A bare `waittill bot_move_done` waits
forever if the notify is ever missed. `waittill_timeout <seconds> bot_move_done` always
resumes — but it does not report *why* it resumed, which is the reason to re-read
`bot_commandstatus` afterwards: a status still reading `running` means you timed out.

Command IDs live in a fixed 16-entry ring per bot, so a very old ID eventually reports
`NIL` rather than resurrecting a reused slot. Treat `NIL` as "no longer knowable", not as
an error.

### Just use the helper

Both rules above are already wrapped in `global/feho/utils.scr::await_command`, which
also handles a bot removed mid-move. Prefer it over hand-rolling the pattern:

```scr
local.id  = local.bot bot_moveto (1024 -512 32)
local.how = waitthread global/feho/utils.scr::await_command local.bot local.id
if (local.how != "reached") println("bot never made it: " + local.how)
```

It returns the same statuses plus `"timeout"`. Note that death arrives as `"cancelled"`
(the engine cancels the active command when the bot is killed), so there's no need to
poll `isalive` alongside the wait. `global/feho/bot_queue.scr` uses this for its
`moveto` / `movenear` steps.

## bot_holdposition vs bot_stop

`bot_stop` is a one-shot cancel: it clears the current scripted move and nothing else. The
bot's normal AI is free to move again on the very next frame. It takes no argument.

`bot_holdposition 1` is a persistent latch: it pins the bot in place every frame until
`bot_holdposition 0`. It only suppresses movement — the bot still aims, fires and defends
itself. `bot_stop` does **not** release an active hold.

### Move-then-hold

Passing a vector instead of `0`/`1` sends the bot to that point and latches the hold on
arrival:

```scr
bot_holdposition (1024 -512 32)           // go there, hold indefinitely
bot_holdposition (1024 -512 32) 30        // go there, then hold for 30s
bot_holdposition (1024 -512 32) 30 128    // as above, spread within 128 units
```

Semantics:

- The duration clock starts **on arrival**, not when the order is issued, so travel time
  never eats into the guard time. A duration of `0` (or omitted) holds indefinitely.
- If the point is unreachable or the path is lost, the bot holds **where it stopped**
  rather than returning to free-roam AI — a blocked squad member still guards.
- `bot_stop` cancels a pending move-then-hold order while the bot is still travelling.
  Once the hold has latched, only `bot_holdposition 0` releases it.
- `bot_moveto` / `bot_movenear` / `bot_holdposition 0` all clear a pending order.

### Ordering a squad

Give several bots the same point with a non-zero **radius**. Without one, all the bots path
to the exact same spot, block each other short of the goal, and clump:

```scr
local.point = (1024 -512 32);
for (local.i = 1; local.i <= local.squad.size; local.i++)
    local.squad[local.i] bot_holdposition local.point 45 160;
```

