# Mod Ideas

## The Bridge (obj_team4) — Incentives to destroy the bridge quickly

The round continues after bridge destruction (no restart — avoids client crashes on round restart).
Winner is determined at time end. The ideas below create urgency for Axis to blow the bridge early.

**Priority stack** (consensus from brainstorm + Codex):

### 1. Post-blow timer compression ⭐
When the bridge blows, clamp remaining round time to 5 minutes.
Blow at minute 3 = 5 more minutes of Axis advantage. Blow at minute 13 = 2 minutes.
Urgency becomes intrinsic to the round structure — nothing new for players to learn.
~5 lines. Single hook on the bridge-destroyed event.

### 2. Allied supply crates while bridge stands
Every 90s after 40% of round time, a supply crate spawns on the Allied side (allies-only pickup).
Reuses existing `treasure_spawn` system almost verbatim. Axis can see crates appearing and feel the cost of waiting.
Reinforces the fiction: defenders resupply while the target survives.
~40 lines.

### 3. Post-blow spawn shift
Single discrete spawn teleport on bridge destruction: Allies fall back to a rear position, Axis advances to a forward position.
Classic phase transition — not gradual creep. Same `tele` pattern as the squad system.
Balance concern: pair with timer compression so Allied fallback time is bounded.
~30 lines. Confirm with owner before implementing (close to "spawn creep" concept that was ruled out).

### 4. Axis HP regen on destruction
All living Axis players get +5 HP/s (capped at 100) for the aftermath phase.
Copy of `hvt_event.scr::hvt_regenerate`. Tangible reward felt immediately.
Risk: snowballing — if Axis already dominate, regen can make Allied defense feel hopeless. Keep it modest.
~25 lines.

### 5. Axis command voice escalation
Global Axis-team audio, 4 escalating voice lines tied to the round clock. Stops on bridge blow.
- ~3:00 — "Engineers, focus the bridge."
- ~6:00 — "That bridge should be down by now."
- ~9:00 — "Why is that bridge still standing?!"
- ~12:00 — "Destroy that bridge — we are losing this engagement!"
Weak incentive alone, but effective when paired with timer compression or supply crates.

### 6. Bridge alarm siren
`loopsound` an air-raid siren near the bridge after the halfway mark. `stoploopsound` on destruction.
Pure atmosphere — no gameplay impact. ~5 lines.
Note: test sound cleanup carefully on map end, bridge blow, and client reconnects.

### 7. Artillery strikes on Axis if bridge stands
Every 90-120s past 60% of round time, a telegraphed mortar strike hits the Axis approach corridor.
Audio warning 2-3s before impact. Stops on bridge destruction.
Most dramatic option but also most work (~80 lines). Risk of feeling random/punitive in tight corridors.
Good as a later escalation layer once simpler ideas are in place.

---

## Other server-wide ideas (from brainstorm session)

### Conquest / control points (PARKED behind a KotH adoption gate)
- **Persistent control points** — 3–5 capturable flags on a map; holding >half drains the enemy's tickets continuously (flat majority bleed). This is the definitive Battlefield mode and integrates deeply with the validated ticket economy.
- **Why parked, not dropped:** our playerbase is deathmatch-brained and tends to ignore objectives. Conquest *fails silently* if players won't cap flags — and worse, hands the one organized clan a compounding advantage over an uncoordinated pub (a stomp, not teamplay). It also needs hand-placed flag positions per map (much more setup than one KotH zone) and bleed-rate tuning that compounds with normal death-drain and could wreck the ~15-min round target.
- **The gate:** KotH is a time-boxed, single-zone, loudly-announced *kill magnet that happens to score* — it redirects existing kill behavior instead of asking players to change it. If KotH proves players *will* fight over a marked zone, that's the evidence Conquest's per-map flag work is worth it. If they ignore even one loud zone, we dodged a much bigger wasted effort. Revisit only after observing KotH adoption.

### Immersion / atmosphere
- **End-of-round MVP awards** — silly categories: "Worst aim", "Grenade magnet", "Tourist" (most distance walked).
- **Rivalries** — track who kills who most; announce "X got revenge on Y" or "X has a 5-kill streak against Y".

### Quality of life
- **Better onboarding** — welcome message on first spawn explaining the 2-3 most important mechanics (squad spawning, grenade launcher, bot control command).

---

# Ideas round: 2026-08-03 (measured from qconsole.log, 3-day window)

Every idea below was filtered against **measured server reality**, not imagination.
Numbers first, because they invalidate a lot of otherwise-good ideas.

## The measurements that drive everything here

Window: 2026-07-31 16:53 → 2026-08-03 16:20. 135 human connects, 350 map loads.

**Time-weighted concurrent HUMAN count** (bots excluded, LAN/localhost excluded):

| humans | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|---|
| % of time | 15% | 8% | 8% | **29%** | 19% | 10% | 5% | 4% | 3% | 0.4% |

Method caveat: connects were counted from `Client N (IP: …) is connecting` with
LAN/localhost filtered, disconnects from the broadcast line (name-only, so not
filterable by IP). That asymmetry biases the count slightly *down* — 124 counted
connects vs 119 disconnects, a −5 imbalance on ~124 events. Too small to move
the conclusion; the true median is 3, possibly 4.

- **Median = 3 humans. p90 = 5. Never above 9.** The server is a small-pod
  server that happens to have 20 slots, and it is *empty 15% of the time*.
- Player pool is thin and repeat-heavy: top IP 15 connects, then 8, 8, 7. A
  large share is Egyptian (197.x/41.x) — relevant for peak-hour and language.
- Peak hours 14:00–16:00 and 20:00–21:00 local.

**This kills any idea needing coordinated teams of 5+.** At 3 humans, "both
teams organize around a flag" is not a thing that can physically happen. It also
means bots are not filler — *bots are the majority of the server, always*.
Anything that only affects humans affects <20% of the entities in the match.

## Finding 1 — prod has never had queryable gameplay telemetry

`[Tickets]` lines: 102 on Jul 31, then **0 on Aug 1, 2, and 3**. Same for every
other `[Tag]` println (`[Squad]`, `[Anticheat]`, …).

This is **not a regression** — it is the steady state. `developer` appears
nowhere in `server.cfg` or `server2.cfg`, so prod runs `developer 0` and
suppresses every `println`, exactly as `feedback_production_developer0` records.
The *anomaly is Jul 31*: `just test-server` sets `+set developer 1` and — unlike
`start-server2` — passes no `fs_homedatapath`, so it writes into the very same
`~/.openmohaa/main/qconsole.log`. Those 102 lines came from a local dev session.

Consequence: **we have no gameplay telemetry from prod, ever** — not for three
days, but structurally. We cannot tell whether KotH is working, and we cannot
answer the Conquest gate above.

Caveats on the KotH numbers, since they are load-bearing:
- 11 KotH resolutions were observed, all inside that one dev-session window.
  **Provenance unverified** — `feat(koth): improve timer and add debug
  activation` exists, so some may be manual test activations rather than player
  behaviour. Do not read them as a live adoption rate.
- The "154 eligible loads" count matched on map name only; `koth_eligible` also
  requires `g_gametype == 4`, and `server.cfg` has `modematch "0"`. So 154 is an
  **upper bound** and the "0 since" denominator is soft.

### ⭐ Idea 1 — durable gameplay event log (unblocks the Conquest gate)

Stop depending on `developer 1` for anything we want to analyse. Append gameplay
events to a CSV via the proven `fs_open_append` path the anticheat already uses
(`reference_fsfile_append_logging`) — independent of the `developer` cvar.

Emit one line per: round start/end (map, gametype, human count, bot count),
mid-match event chosen + outcome, KotH progress samples, ticket swings.

Then the KotH question becomes answerable from data: at 3 humans, do players
actually converge on the zone, or does the bar move only because bots wander in?
That is *the* gate for Conquest, control points, and every future event — and
right now it is unanswerable, because prod emits nothing.

Also worth fixing while here: give `just test-server` its own `fs_homedatapath`
(as `start-server2` already has), so dev sessions stop contaminating the prod log.

- Hooks: `tickets.scr`, `koth.scr`, `event_manager.scr` — emit only, no logic change.
- ~60 lines .scr + a small `tools/` reader alongside `cheat_watcher.py`.
- Rubric: observe-first (#5), Python companion (#6), self-contained (#1).

## Finding 2 — the mid-match event pool has exactly one member

`register_event` is a nice generic pool, but `hvt_event.scr` is commented out at
`DMprecache.scr:200`, so **KotH is the only registered event**. One event per
round, no re-roll, and on the ~56% of map loads that aren't KotH-eligible the
round's single event slot resolves to *nothing at all*.

### ⭐ Idea 2 — a low-cost event that is eligible everywhere

Add one event with **no per-map preset requirement**, so non-preset maps stop
rolling an empty slot. Best fit at 3 humans: **Bounty** (already in the backlog
above, but re-scoped for this concurrency) — mark the current top scorer, killing
them pays a ticket swing + loud HUD callout. Works with 3 humans, works with
bots (`reference_bots_are_players`), needs zero map authoring.

- Registers via existing `register_event`; ships with notify HUD.
- Plugs into the ticket economy (#2), bots first-class (#4), HUD included (#3).
- ~80 lines, self-contained new .scr.

## Finding 3 — KotH preset coverage lags the rotation

9 maps are KotH-eligible; the rotation plays 25. The most-played maps include
`m2l1` (21 loads, most played) and `m1l2b` (18) — **neither has a preset**.
Meanwhile `m4l3` has a preset but only 9 loads.

### Idea 3 — presets follow play frequency, not authoring convenience

Author KotH zones for `m2l1`, `m1l2b`, `m4l1`, `dm/mohdm3` in that order (the
top uncovered maps by actual load count). Pure content work, no new code —
`tactical_helper.scr` already proves the in-game "stand here and press USE"
authoring pattern; the same trick works for zone capture.

## Finding 4 — the server is empty 15% of the time, and nobody knows

No player can tell the server is alive without joining it. With a pool this thin
and this repeat-heavy, the single highest-leverage retention lever is **telling
the regulars when a match is actually running**.

### ⭐ Idea 4 — presence beacon out of the dashboard

The dashboard + livemap already exist and already know who is on. Add a public
status endpoint / tiny page: current map, human count, who's playing. Optionally
a Discord/Telegram ping when human count crosses 2→3 (the threshold where the
server becomes fun).

This is the only idea here that grows attendance rather than improving the
match. Note the supporting claim is **presence, not retention** — session
lengths were not successfully measured (the join-line phrasing didn't parse),
so "players leave too early" remains unmeasured. The case rests on the two
numbers we do have: empty 15% of the time, and a small repeat-heavy pool.

- Pure Python, `dashboard/server.py` + the livemap feed. No .scr risk.
- Rubric: Python companion (#6). Ships visible feedback (#3).
- ⚠️ **Publishes player data off the box.** A public page + chat pings send live
  player names externally. Needs an explicit go-ahead and a deliberate choice of
  count-only vs. names; never expose IPs.

### Idea 5 — make the empty server self-warming

At 0–1 humans, the match is a bot sandbox. Bias the rotation toward small,
dense, DM-style maps when human count is low, and toward the bigger objective
maps once 4+ humans are on. `maprotate.scr` already has a weight table — this is
a weight multiplier keyed on `$player.size` minus bots, not a new system.

`reference_stock_dm_spawn_design` already recorded that big maps don't work at
low headcount; this applies that lesson to map *selection*, ~30 lines.

## Ideas explicitly REJECTED by the concurrency filter

- **Conquest / control points** — stays parked, and the measurement above says
  the gate still cannot be evaluated. At median 3 humans it is also structurally
  impossible: 3 players cannot contest 3–5 flags. Fix Idea 1 first.
- **Squad-leader artillery** — squads barely form at 3 humans; the mechanic
  would fire for a "squad" of one.
- **Rivalries / persistent profiles** — needs cross-map persistence
  (`feedback_game_scope`) and a stable identity; player names churn and the pool
  is small. Revisit once Idea 1's CSV exists — it is nearly free on top of it.
- **MVP awards** — fine, but at 3 humans the categories are near-degenerate
  ("Worst aim" among 3 people is just a callout of one person, repeatedly).

## Suggested order

1. **Idea 1** (event CSV) — unblocks every measurement question, including the repo's own parked gate.
2. **Idea 4** (presence beacon) — biggest retention lever, zero .scr risk.
3. **Idea 2** (map-agnostic second event) — stops the empty event slot.
4. **Idea 3** (presets by play frequency) — content, no code.
5. **Idea 5** (headcount-aware rotation weights).
