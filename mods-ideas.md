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

### Mid-match events (complement to HVT)
- **King of the Hill** — a capture zone appears mid-match at a map-specific location. Team with more players inside earns points over time. Ends after 2-3 minutes or when a threshold is reached. Plays well with squads. Feasible with trigger zones + HUD, same pattern as HVT event.
- **Bounty system** — kill the top player and steal a portion of their score.
- **Artillery strikes** — squad leaders can call in a timed bombardment once per round.

### Immersion / atmosphere
- **End-of-round MVP awards** — silly categories: "Worst aim", "Grenade magnet", "Tourist" (most distance walked).
- **Rivalries** — track who kills who most; announce "X got revenge on Y" or "X has a 5-kill streak against Y".

### Quality of life
- **Better onboarding** — welcome message on first spawn explaining the 2-3 most important mechanics (squad spawning, grenade launcher, bot control command).
