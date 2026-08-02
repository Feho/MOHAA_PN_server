# MOHAA Dashboard

Read-only web dashboard for the OpenMoHAA dedicated server.

## Run

```bash
just dashboard
```

By default it listens on `http://127.0.0.1:8088` and reads:

```text
~/.openmohaa/main/qconsole.log
```

Override defaults when needed:

```bash
MOHAA_DASHBOARD_HOST=127.0.0.1 MOHAA_DASHBOARD_PORT=8088 MOHAA_LOG=~/.openmohaa/main/qconsole.log python3 dashboard/server.py
```

## Cloudflared

Expose only the local dashboard origin through a tunnel:

```bash
just dashboard-tunnel
```

Protect the public hostname with Cloudflare Access. The app has no built-in
password in v1, and it is intentionally read-only.

`just dashboard-tunnel` starts both the local dashboard and cloudflared in
detached `screen` sessions.

Attach to the cloudflared screen session to see the tunnel URL:

```bash
just dashboard-tunnel-attach
```

Detach from screen with `Ctrl-A` then `D`. Stop the tunnel and local dashboard with:

```bash
just dashboard-tunnel-stop
```

## Data Shown

- connected human players derived from log join/leave events
- current map
- human and bot counts
- last 50 chat messages
- recent joins/leaves/map loads
- warning/error lines from the current log
- log freshness based on the same stale-log signal as the watchdog

Player IP addresses are not returned by the API or rendered in the page.

## Live Map (`/map`)

A 2D top-down view of the running map with a dot per alive player — blue for
Allies, red for Axis, with a wedge showing facing.

**Bots vs humans:** a bot keeps its team colour but is drawn dimmed (45%) and
without the dark outline, so humans stand out. Colour is never used to mark a
bot — it means team, and only team. The header spells the split out per team
(`axis 2 human · 4 bot`), with the bot half muted.

```text
main/global/feho/livemap.scr   writes a snapshot ~5x/second
        |                      ~/.openmohaa/main/livemap/positions.txt
        v
dashboard/livemap.py           one reader thread polls + parses it
        |
        v
/events/positions (SSE)  ->  /map   dots over a pre-rendered PNG
```

### Rendering the map images

The background images come from the game's own `.bsp` files. They are
generated **once per map**, offline — the live path only serves them:

```bash
just livemap-render-all            # ALL 88 maps in main/*.pk3 -- do this once
just livemap-render m2l1 mohdm3    # or just specific maps
just livemap-maps                  # what's already rendered
```

Output lands in `dashboard/maps/<map>.png` plus a `<map>.json` holding the
world->image transform (`px = (wx-minx)*scale`, `py = (maxy-wy)*scale`). The
browser uses that JSON to place dots; it never re-derives geometry.

Timing: patches are tessellated in pure Python, so a big map takes a while —
m2l1 (570 patches, 61k triangles) is ~30s. The full 29-map rotation took a few
minutes. It is not hung; let it run.

Render **everything**, not just the maps in `maprotate.scr`: the server also
serves objective maps (`obj_team1..4`) and custom pk3 maps, and an unrendered
one shows a placeholder instead of the map.

A map with no rendered image still works — the page names the command to run,
and picks the image up automatically once it exists (no refresh needed).

### Checking the feed

```bash
just livemap-check   # tick should advance
just livemap-peek    # raw snapshot line
```

`/api/livemap/stats` reports read/discard counts. Discards are expected to be
near zero; a rising rate means snapshots are being caught mid-write.

### Notes

- The producer writes are **not atomic**, so the reader rejects any malformed
  or empty snapshot and reuses the last good one. Measured 0 discards over
  300+ live reads.
- One reader thread serves all browsers, so N viewers is still one file read
  per tick.
- **Transport is adaptive.** The page prefers SSE (`/events/positions`), but
  Cloudflare *quick* tunnels buffer `text/event-stream` — measured ~20s to the
  first event, then a burst. If nothing arrives within 2.5s the page falls back
  to polling `/api/positions` every 200ms. Direct/LAN access keeps SSE. Check
  the browser console: it logs `livemap: using SSE` or `using polling`.
- Toggle the feed live with `livemap_enabled 0` / `1` (no restart needed).
- **This is admin-only by design.** Live positions are a wallhack if a player
  can reach them — keep `/map` behind the same Cloudflare Access gate as the
  rest of the dashboard.
