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

