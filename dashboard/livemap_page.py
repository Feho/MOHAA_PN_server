"""The /map page: pre-rendered map PNG + live player dots over SSE.

Kept out of server.py so the existing dashboard stays a log viewer and this
stays self-contained. Same stdlib-only, no-external-assets constraints.
"""

MAP_HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MOHAA — live map</title>
<style>
  :root {
    --bg: #0d1117; --panel: #161b22; --line: #30363d;
    --text: #e6edf3; --muted: #8b949e;
    --allies: #4f9dff; --axis: #ff5252;
  }
  @media (prefers-color-scheme: light) {
    :root { --bg:#f6f8fa; --panel:#fff; --line:#d0d7de; --text:#1f2328; --muted:#636c76; }
  }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--text);
         font:14px/1.5 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif; }
  header { display:flex; align-items:center; gap:16px; flex-wrap:wrap;
           padding:10px 16px; border-bottom:1px solid var(--line); background:var(--panel); }
  h1 { font-size:15px; margin:0; font-weight:600; letter-spacing:.02em; }
  .pill { font-size:12px; color:var(--muted); white-space:nowrap; }
  .pill b { color:var(--text); font-weight:600; }
  .dot-legend { display:inline-block; width:9px; height:9px; border-radius:50%;
                margin-right:4px; vertical-align:-1px; }
  #status { margin-left:auto; font-size:12px; }
  #status.live b { color:#3fb950; }
  #status.stale b { color:#d29922; }
  #status.down b { color:#f85149; }
  main { padding:16px; display:flex; justify-content:center; }
  /* The overlay must cover exactly the rendered <img> box. #wrap is
     inline-block so it shrink-wraps the image at any viewport width, and the
     svg is pinned to that same box with a viewBox in image pixels -- so a dot
     at image coords lands on the same feature no matter how the img scales. */
  #wrap { position:relative; display:inline-block; max-width:100%; line-height:0; }
  #wrap img { max-width:100%; height:auto; border:1px solid var(--line); border-radius:6px;
              image-rendering:auto; display:block; }
  #dots { position:absolute; top:0; left:0; width:100%; height:100%;
          pointer-events:none; }
  #msg { color:var(--muted); text-align:center; padding:48px 16px; line-height:1.6; }
  code { background:var(--panel); border:1px solid var(--line); border-radius:4px;
         padding:1px 5px; font-size:12px; }
</style>
</head>
<body>
<header>
  <h1>Live map</h1>
  <span class="pill">map <b id="mapname">—</b></span>
  <span class="pill"><span class="dot-legend" style="background:var(--allies)"></span>allies <b id="n-allies">0</b></span>
  <span class="pill"><span class="dot-legend" style="background:var(--axis)"></span>axis <b id="n-axis">0</b></span>
  <span class="pill">tick <b id="tick">—</b></span>
  <span class="pill" id="status">feed <b>connecting…</b></span>
</header>
<main>
  <div id="wrap" hidden>
    <img id="mapimg" alt="">
    <svg id="dots" preserveAspectRatio="none"></svg>
  </div>
  <div id="msg">waiting for the first snapshot…</div>
</main>
<script>
const SVGNS = "http://www.w3.org/2000/svg";
// Literal colours, NOT var(--allies): a var() inside an SVG *presentation
// attribute* is not reliably resolved across browsers and fails to black,
// which would silently make both teams the same colour. Keep these in sync
// with the :root custom properties above.
const COLOR = { a: "#4f9dff", x: "#ff5252" };
let meta = null, currentMap = null, lastTick = null, lastSeen = 0, latest = null;

const $ = id => document.getElementById(id);

// Guard against a load stampede: SSE events arrive every ~200ms, but fetching
// the map metadata takes a round trip (much longer over the tunnel). Without
// this, every event that lands mid-fetch sees `snap.map !== currentMap` and
// kicks off ANOTHER loadMap -- measured 6 fetches for one map change, which is
// what made the first paint take >10s. Claim the name synchronously and share
// one in-flight promise.
let loadingMap = null;      // name currently being fetched
let loadPromise = null;     // its promise, shared by concurrent callers

// Retry a map whose image doesn't exist yet, so rendering it on the server
// fixes an open page without a refresh. Without this the failed name stays in
// loadingMap and every later snapshot short-circuits on the cached rejected
// promise -- the page would sit on "No rendered image" forever.
const RETRY_MISSING_MS = 15000;
let missingSince = 0;

function loadMap(name) {
  if (loadingMap === name && loadPromise) {
    // Same map already in flight, or previously failed. Only re-attempt a
    // FAILED one, and only every RETRY_MISSING_MS.
    if (currentMap === name) return loadPromise;          // succeeded already
    if (Date.now() - missingSince < RETRY_MISSING_MS) return loadPromise;
  }
  loadingMap = name;
  missingSince = Date.now();
  loadPromise = (async () => {
    const r = await fetch(`/api/map/${encodeURIComponent(name)}`, {cache:"no-store"});
    if (!r.ok) { meta = null; currentMap = null; return false; }
    const m = await r.json();
    if (loadingMap !== name) return false;    // a newer map won the race
    meta = m;
    $("mapimg").src = `/api/map/${encodeURIComponent(name)}.png`;
    $("dots").setAttribute("viewBox", `0 0 ${meta.width} ${meta.height}`);
    currentMap = name;
    $("wrap").hidden = false;
    $("msg").hidden = true;
    return true;
  })();
  return loadPromise;
}

// world -> image, exactly the transform baked into <map>.json by tools/bspmap.py
function project(p) {
  return [ (p.x - meta.world.minx) * meta.scale,
           (meta.world.maxy - p.y) * meta.scale ];
}

function draw(players) {
  const svg = $("dots");
  while (svg.firstChild) svg.removeChild(svg.firstChild);
  if (!meta) return;
  const r = Math.max(3, meta.width / 190);
  for (const p of players) {
    const [cx, cy] = project(p);
    const g = document.createElementNS(SVGNS, "g");
    // facing wedge: yaw is degrees CCW from +X in world space; screen Y is
    // flipped, hence the negation.
    const a = -p.yaw * Math.PI / 180;
    const len = r * 2.6;
    const wedge = document.createElementNS(SVGNS, "path");
    const spread = 0.42;
    wedge.setAttribute("d",
      `M ${cx} ${cy} L ${cx + Math.cos(a-spread)*len} ${cy + Math.sin(a-spread)*len}`
      + ` L ${cx + Math.cos(a+spread)*len} ${cy + Math.sin(a+spread)*len} Z`);
    wedge.setAttribute("fill", COLOR[p.team] || "#999");
    wedge.setAttribute("opacity", "0.30");
    g.appendChild(wedge);
    const c = document.createElementNS(SVGNS, "circle");
    c.setAttribute("cx", cx); c.setAttribute("cy", cy); c.setAttribute("r", r);
    c.setAttribute("fill", COLOR[p.team] || "#999");
    c.setAttribute("stroke", "#0b0e13");
    c.setAttribute("stroke-width", Math.max(1, r/3.5));
    g.appendChild(c);
    svg.appendChild(g);
  }
}

function setStatus(kind, text) {
  const el = $("status");
  el.className = kind;
  el.innerHTML = `feed <b>${text}</b>`;
}

// Deliberately NOT async: apply() must never block on a network round trip.
// Header counters and dots update from the snapshot we already have, and the
// map image loads in the background. Awaiting here is what made every event
// during a load queue up behind the fetch.
function apply(snap) {
  lastSeen = Date.now();
  lastTick = snap.tick;
  latest = snap;
  $("tick").textContent = snap.tick;
  $("mapname").textContent = snap.map || "—";
  $("n-allies").textContent = snap.players.filter(p => p.team === "a").length;
  $("n-axis").textContent = snap.players.filter(p => p.team === "x").length;
  setStatus(snap.stale ? "stale" : "live", snap.stale ? "stale" : "live");

  if (snap.map && snap.map !== currentMap) {
    loadMap(snap.map).then(ok => {
      if (!ok) {
        $("wrap").hidden = true; $("msg").hidden = false;
        $("msg").innerHTML = `No rendered image for <code>${snap.map}</code>.<br>`
          + `Generate it with <code>just livemap-render ${snap.map}</code>`
          + ` — this page will pick it up automatically.`;
        return;
      }
      if (latest) draw(latest.players);   // paint with the freshest snapshot
    });
    return;
  }
  if (meta) draw(snap.players);
}

// Transport: SSE when it actually streams, polling otherwise.
//
// Cloudflare quick tunnels (trycloudflare.com) BUFFER text/event-stream: the
// server flushes every event immediately (10ms locally) but the first one
// doesn't reach the browser for ~20s, then ~100 events arrive at once. Padding
// the stream doesn't fix it -- 8K/32K/64K shortened the delay, 128K/256K did
// not, so it is not a byte threshold we can push past. Plain GETs over the same
// tunnel are ~250ms, so polling is unaffected.
//
// So: open the stream, but if no event lands within SSE_PROBE_MS, give up on it
// and poll instead. Direct/LAN access keeps the efficient push path; tunnelled
// access degrades to a 200ms poll that still looks live.
const SSE_PROBE_MS = 2500;
const POLL_MS = 200;
let transport = null, pollTimer = null, es = null;

function startPolling(why) {
  if (transport === "poll") return;
  transport = "poll";
  if (es) { try { es.close(); } catch (e) {} es = null; }
  console.info(`livemap: using polling (${why})`);
  const tick = async () => {
    try {
      const r = await fetch("/api/positions", {cache:"no-store"});
      if (r.ok) apply(await r.json());
    } catch (e) {
      setStatus("down", "no data");
    }
    pollTimer = setTimeout(tick, POLL_MS);
  };
  tick();
}

function connect() {
  let gotEvent = false;
  try {
    es = new EventSource("/events/positions");
  } catch (e) {
    startPolling("EventSource unavailable");
    return;
  }
  es.onmessage = ev => {
    gotEvent = true;
    if (transport === null) { transport = "sse"; console.info("livemap: using SSE"); }
    if (transport !== "sse") return;          // polling already took over
    try { apply(JSON.parse(ev.data)); } catch (e) {}
  };
  es.onerror = () => {
    if (transport === "sse") setStatus("down", "reconnecting…");
    else if (!gotEvent) startPolling("stream errored");
  };
  // The probe: if the stream hasn't delivered anything by now, it's buffered.
  setTimeout(() => { if (!gotEvent) startPolling("stream buffered by proxy"); },
             SSE_PROBE_MS);
}

// Independent of the stream: if no event lands for a while, say so.
setInterval(() => {
  if (lastSeen && Date.now() - lastSeen > 6000) setStatus("down", "no data");
}, 2000);

// Kick off the map fetch from a plain snapshot immediately, in PARALLEL with
// opening the stream. Waiting for the first SSE event just to learn the map
// name costs an extra round trip before anything can be drawn -- noticeable
// over the tunnel, invisible locally.
(async () => {
  try {
    const r = await fetch("/api/positions", {cache:"no-store"});
    if (r.ok) {
      const snap = await r.json();
      if (snap && snap.map) apply(snap);
    }
  } catch (e) { /* the stream will populate us shortly */ }
})();

connect();
</script>
</body>
</html>
"""
