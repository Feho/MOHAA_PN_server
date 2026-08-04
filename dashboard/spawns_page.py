"""The /spawns page: before/after spawn-placement review for a map.

A read-only review surface for proposals from tools/spawns.py. The overlays are
plain PNGs already sitting in dashboard/maps/ (served by /api/map/<name>.png),
so this page adds no new file-serving path and no new attack surface.

Same constraints as the rest of the dashboard: stdlib only, no external assets.
"""

SPAWNS_HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MOHAA — spawn review: m1l2a</title>
<style>
  :root {
    --bg:#0d1117; --panel:#161b22; --line:#30363d;
    --text:#e6edf3; --muted:#8b949e;
    --allies:#4f9dff; --axis:#ff5252; --warn:#ffd600; --ok:#3fb950;
  }
  @media (prefers-color-scheme: light) {
    :root { --bg:#f6f8fa; --panel:#fff; --line:#d0d7de; --text:#1f2328; --muted:#636c76; }
  }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--text);
         font:14px/1.6 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif; }
  header { display:flex; align-items:center; gap:16px; flex-wrap:wrap;
           padding:10px 16px; border-bottom:1px solid var(--line); background:var(--panel); }
  h1 { font-size:15px; margin:0; font-weight:600; }
  a { color:var(--allies); }
  .pill { font-size:12px; color:var(--muted); }
  .pill b { color:var(--text); font-weight:600; }
  main { padding:16px; max-width:1100px; margin:0 auto; }
  .legend { display:flex; gap:18px; flex-wrap:wrap; margin:0 0 14px;
            font-size:12px; color:var(--muted); }
  .sw { display:inline-block; width:10px; height:10px; border-radius:50%;
        margin-right:5px; vertical-align:-1px; }
  .sw.ring { background:transparent; border:2px solid var(--warn); }
  .sw.ringok { background:transparent; border:2px solid var(--ok); }
  /* Slider comparison: both images stacked, the top one clipped by width. */
  #cmp { position:relative; line-height:0; border:1px solid var(--line);
         border-radius:6px; overflow:hidden; touch-action:none; }
  #cmp img { display:block; width:100%; height:auto; }
  #after { position:absolute; inset:0; width:100%;
           clip-path:inset(0 0 0 50%); }
  #handle { position:absolute; top:0; bottom:0; left:50%; width:2px;
            background:var(--text); opacity:.85; pointer-events:none; }
  #handle::after { content:""; position:absolute; top:50%; left:50%;
    width:30px; height:30px; margin:-15px 0 0 -15px; border-radius:50%;
    background:var(--panel); border:2px solid var(--text); }
  .tag { position:absolute; top:8px; font-size:11px; letter-spacing:.04em;
         background:rgba(0,0,0,.6); color:#fff; padding:2px 7px; border-radius:3px; }
  .tag.l { left:8px; } .tag.r { right:8px; }
  input[type=range] { width:100%; margin:10px 0 0; }
  table { border-collapse:collapse; margin:18px 0; font-size:13px; }
  th,td { border:1px solid var(--line); padding:5px 10px; text-align:right; }
  th:first-child, td:first-child { text-align:left; }
  th { background:var(--panel); font-weight:600; }
  .bad { color:var(--axis); } .good { color:var(--ok); }
  .note { color:var(--muted); font-size:13px; border-left:2px solid var(--line);
          padding-left:12px; margin:14px 0; }
  code { background:var(--panel); border:1px solid var(--line); border-radius:4px;
         padding:1px 5px; font-size:12px; }
</style>
</head>
<body>
<header>
  <h1>Spawn review — m1l2a</h1>
  <span class="pill">drag the slider to compare</span>
  <span class="pill" style="margin-left:auto"><a href="/map">← live map</a></span>
</header>
<main>

<div class="legend">
  <span><span class="sw" style="background:var(--axis)"></span>Axis spawn</span>
  <span><span class="sw" style="background:var(--allies)"></span>Allied spawn</span>
  <span><span class="sw ring"></span>stray (&gt;2500u from own centroid)</span>
  <span><span class="sw ringok"></span>relocated by the proposal</span>
</div>

<div id="cmp">
  <img id="before" src="/api/map/spawns_m1l2a_before.png" alt="current spawns">
  <img id="after"  src="/api/map/spawns_m1l2a_after.png"  alt="proposed spawns">
  <span class="tag l">CURRENT</span>
  <span class="tag r">PROPOSED</span>
  <div id="handle"></div>
</div>
<input type="range" id="slider" min="0" max="100" value="50" aria-label="compare">

<table>
  <tr><th>metric</th><th>current</th><th>proposed</th><th>server median</th></tr>
  <tr><td>separation</td><td>7322</td><td class="bad">7738</td><td>3970</td></tr>
  <tr><td>spread axis</td><td class="bad">2121</td><td class="good">911</td><td>—</td></tr>
  <tr><td>spread allied</td><td>1157</td><td>1157</td><td>—</td></tr>
  <tr><td>closest cross-team pair</td><td>4256</td><td>4256</td><td>—</td></tr>
</table>

<p class="note">
The proposal above fixes the Axis clustering but makes separation
<em>worse</em>, and separation was never the real problem — see below.
</p>

<h2 style="font-size:15px;margin:28px 0 8px">Why the fight is always in the corridor</h2>

<div id="chokewrap" style="line-height:0">
  <img src="/api/map/spawns_m1l2a_applied.png" alt="choke point"
       style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
</div>
<div class="legend" style="margin-top:10px">
  <span><span class="sw" style="background:#5a6473"></span>walkable ground (SP navmesh)</span>
  <span><span class="sw" style="background:#ff8c00"></span>the ONLY route between the two sides</span>
</div>

<p class="note">
Building a connectivity graph over the navmesh and deleting the orange lane
leaves <b>no path at all</b> between the two spawn areas. It is a true
articulation point: roughly 780u wide, ~97 nodes, and every engagement in the
match has to happen there.
</p>

<table>
  <tr><th>distance to the corridor</th><th>nearest</th><th>median</th><th>furthest</th></tr>
  <tr><td>Allied spawns</td><td class="good">1617u</td><td class="good">3474u</td><td>4161u</td></tr>
  <tr><td>Axis spawns</td><td class="bad">3499u</td><td class="bad">5354u</td><td>6689u</td></tr>
</table>

<p class="note">
So it is not symmetric either: <b>Allies spawn on top of the only chokepoint</b>
and can hold it before Axis arrive, while Axis cross the whole open middle to
contest it. Moving spawns cannot create a second route — the map has one.
What spawn placement <em>can</em> do is even up who reaches it first, and stop
Axis players walking 5000u to rejoin the fight after every death.
</p>

<h2 style="font-size:15px;margin:28px 0 8px">
  APPLIED: Allies moved to the south-west compound
  <span style="color:var(--ok);font-weight:400"> &check; live in m1l2a.scr</span>
</h2>

<div style="line-height:0">
  <img src="/api/map/spawns_m1l2a_applied.png" alt="applied spawn layout"
       style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
</div>

<p class="note">
Allies relocate to the walled compound in the south-west (116 walkable nodes,
15 spawns fit at &ge;200u apart). The old corridor — still orange — is then
next to <em>nobody's</em> spawn, so it stops being the default meeting point.
The three Axis spawns that used to sit in this pocket move back to the Axis
core, or they would have become 128u spawn-kills inside the new Allied base.
</p>

<table>
  <tr><th>metric</th><th>current</th><th>proposed</th><th></th></tr>
  <tr><td>chokepoints on the route</td><td class="bad">9</td><td class="good">1</td><td>fewer forced fights</td></tr>
  <tr><td>needs the old corridor</td><td class="bad">yes</td><td class="good">no</td><td>route is independent</td></tr>
  <tr><td>separation</td><td>7322</td><td>7401</td><td>unchanged in practice</td></tr>
  <tr><td>spread allied</td><td>1157</td><td class="good">485</td><td>tighter base</td></tr>
  <tr><td>spread axis</td><td class="bad">2121</td><td class="good">906</td><td>strays fixed</td></tr>
  <tr><td>closest cross-team pair</td><td>4256</td><td class="good">5990</td><td>no spawn-kill risk</td></tr>
</table>

<p class="note">
Caveat worth stating plainly: this <b>abandons the town</b> as an Allied base
and gives up the whole east side of the map. That is a deliberate trade — the
map is large enough that losing an area is acceptable if the flow improves,
but it is a taste call, not something the metrics can settle.
</p>

<h2 style="font-size:15px;margin:28px 0 8px">
  APPLIED: two Allied zones, one rolled per map load
  <span style="color:var(--ok);font-weight:400"> &check; live</span>
</h2>

<p class="note">
The complaint was never the corridor itself — it was that <em>every</em> fight
happened there. So both zones stay in play and the map rolls between them at
load, using the same <code>enablespawn</code>/<code>disablespawn</code>
mechanism m1l2b already uses. The corridor still comes up, just not every time.
Each zone holds <b>20 spawns at ~1100u spread</b>, versus the cramped 485u of
the first attempt.
</p>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
  <div>
    <div style="font-size:12px;color:var(--muted);margin-bottom:6px">
      variant <code>swa</code> — meets at ~(912,&nbsp;-368)</div>
    <img src="/api/map/spawns_m1l2a_var_sw.png" alt="south-west variant"
         style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
  </div>
  <div>
    <div style="font-size:12px;color:var(--muted);margin-bottom:6px">
      variant <code>twn</code> — meets at ~(3560,&nbsp;-392), the corridor</div>
    <img src="/api/map/spawns_m1l2a_var_town.png" alt="town variant"
         style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
  </div>
</div>

<table>
  <tr><th>zone</th><th>spawns</th><th>spread</th><th>min gap</th><th>cross-team</th></tr>
  <tr><td>swa (south-west)</td><td>20</td><td>1072u</td><td>248u</td><td>3332u</td></tr>
  <tr><td>twn (town)</td><td>20</td><td>1111u</td><td>204u</td><td>4501u</td></tr>
</table>

<p class="note">
Both groups are validated <em>independently</em> — only one is live at a time,
so scoring their union would hide a bad group. All 40 sit exactly on
<code>info_pathnode</code> positions. Axis spawns are untargeted and therefore
always active.
</p>

<p class="note">
Blocks kept at <code>plans/m1l2a_tdm_spawns*.txt</code>; backups of the .scr in
the session scratchpad.
</p>

<h2 style="font-size:15px;margin:28px 0 8px">
  REJECTED: interleaved layout
  <span style="color:var(--axis);font-weight:400"> &times; failed in play</span>
</h2>

<p class="note">
Copying the stock DM pattern (both teams sharing 10 locations) simulated well
&mdash; safer than mohdm4/6/7 on distance-to-nearest-enemy &mdash; but failed
for two reasons no metric here could see. <b>Spawns were auto-placed on
<code>info_pathnode</code> positions</b>, which prove an AI path runs through a
point, not that a 32&times;32&times;96 player box fits or that a door is open:
players spawned inside objects and behind closed doors. And the pattern needs a
small arena; spread over m1l2a players just walked. The spawn lines are kept in
the .scr, permanently disabled, with a post-mortem comment.
</p>

<h2 style="font-size:15px;margin:28px 0 8px">Zone survey &mdash; six regions</h2>

<div style="line-height:0">
  <img src="/api/map/zones_m1l2a.png" alt="zone partition"
       style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
</div>
<div class="legend" style="margin-top:10px">
  <span>each colour = one zone &middot; large dot = zone centre (walk here)</span>
</div>

<p class="note">
Grown by simultaneous BFS over a connectivity graph of the navmesh, so every
zone is guaranteed internally walkable &mdash; a bounding-box slice would
happily straddle a cliff. 99% of the mesh is one connected component; three
fragments totalling 9 nodes are unreachable and excluded. Navigable extent is
<b>13156u</b> &mdash; note this corrects an earlier figure of 146785u, which was
an entity bounding box inflated by junk entities outside the playable area.
</p>

<table>
  <tr><th>zone</th><th>nodes</th><th>centre</th><th>radius</th><th>share</th></tr>
  <tr><td>0</td><td>87</td><td>(6080, -4419)</td><td>1140u</td><td>8%</td></tr>
  <tr><td>1</td><td>219</td><td>(1679, 3626)</td><td>1142u</td><td>20%</td></tr>
  <tr><td>2</td><td>116</td><td>(-1010, -2093)</td><td>1924u</td><td>11%</td></tr>
  <tr><td>3</td><td>220</td><td>(2993, -548)</td><td>3161u</td><td>20%</td></tr>
  <tr><td>4</td><td>265</td><td>(1234, 1910)</td><td>1921u</td><td>24%</td></tr>
  <tr><td>5</td><td>188</td><td>(5164, -2232)</td><td>2011u</td><td>17%</td></tr>
</table>

<p class="note">
<b>The surprise: coverage is already complete.</b> The shipping layout touches
every zone &mdash; <code>swa</code> &rarr; z2/z3, <code>twn</code> &rarr; z0/z5,
<code>axc</code> &rarr; z1/z4. There are no cold regions to open up.
</p>

<table>
  <tr><th>layout</th><th>meets in</th><th>walk to contact</th></tr>
  <tr><td>swa</td><td class="bad">zone 4</td><td class="bad">~3004u each</td></tr>
  <tr><td>twn</td><td class="bad">zone 3</td><td class="bad">~3943u each</td></tr>
</table>

<p class="note">
So the problem is not <em>where the bases are</em> but <em>where contact
resolves</em>: both layouts collapse into the two big middle zones (3 and 4).
Zones 0, 2 and 5 are walked <em>through</em>, never fought over. You explore
most of the map but only ever fight in the middle third &mdash; and pay
3000-3900u of approach for it every life. The fix is choosing base pairs whose
<em>midpoint</em> lands somewhere new, and picking adjacent pairs to cut the
walk (z5&harr;z0 is 2371u, z3&harr;z5 2747u).
</p>

<h2 style="font-size:15px;margin:28px 0 8px">Meeting-point survey &mdash; all 15 zone pairs</h2>

<div style="line-height:0">
  <img src="/api/map/meetings_m1l2a.png" alt="meeting points"
       style="width:100%;height:auto;border:1px solid var(--line);border-radius:6px">
</div>
<div class="legend" style="margin-top:10px">
  <span><span class="sw" style="background:#ff5040"></span>meeting point (where contact resolves)</span>
  <span>large coloured dot = zone centre &middot; small dots = spawn core</span>
</div>

<p class="note">
Contact is computed on the walkable graph, not as a straight-line midpoint:
each zone's spawn core seeds a BFS and the meeting point is the node
<em>equidistant in travel</em> from both. On a bent ribbon like m1l2a the
straight-line midpoint often lands outside the mesh entirely, so it would be
meaningless. Distances are seeded from each zone's <b>core</b>, not its whole
node set &mdash; seeding from every node measures edge-to-edge and makes
bordering zones look 1 hop apart.
</p>

<table>
  <tr><th>pair</th><th>meets in</th><th>meet point</th><th>approach</th><th>detour</th></tr>
  <tr><td>z1&ndash;z4</td><td class="good">4</td><td>(1515, 2631)</td><td class="good">532u</td><td>0.60</td></tr>
  <tr><td>z0&ndash;z5</td><td class="good">5</td><td>(5480, -3360)</td><td class="good">797u</td><td>0.67</td></tr>
  <tr><td>z3&ndash;z4</td><td>4</td><td>(792, 40)</td><td class="good">1063u</td><td>0.70</td></tr>
  <tr><td>z3&ndash;z5</td><td>3</td><td>(4676, -452)</td><td class="good">1063u</td><td>0.77</td></tr>
  <tr><td>z2&ndash;z3</td><td>3</td><td>(464, -904)</td><td>1329u</td><td>0.62</td></tr>
  <tr><td>z1&ndash;z3</td><td>4</td><td>(1424, 1168)</td><td>1595u</td><td>0.73</td></tr>
  <tr><td>z2&ndash;z4</td><td>3</td><td>(780, -732)</td><td>1595u</td><td>0.70</td></tr>
  <tr><td>z0&ndash;z3</td><td>5</td><td>(5152, -1888)</td><td>2127u</td><td>0.86</td></tr>
  <tr><td>z1&ndash;z2</td><td>4</td><td>(1040, 272)</td><td>2392u</td><td>0.76</td></tr>
  <tr><td>z4&ndash;z5</td><td>3</td><td>(2836, -236)</td><td>2658u</td><td>0.93</td></tr>
  <tr><td>z2&ndash;z5</td><td>3</td><td>(2612, -612)</td><td>2924u</td><td>0.95</td></tr>
  <tr><td>z1&ndash;z5</td><td>3</td><td>(2216, -704)</td><td>3190u</td><td>0.94</td></tr>
  <tr><td>z0&ndash;z4</td><td>3</td><td>(4252, -68)</td><td class="bad">3456u</td><td>0.87</td></tr>
  <tr><td>z0&ndash;z2</td><td>3</td><td>(3560, -392)</td><td class="bad">3855u</td><td>1.03</td></tr>
  <tr><td>z0&ndash;z1</td><td>3</td><td>(3476, -500)</td><td class="bad">4253u</td><td>0.93</td></tr>
</table>

<p class="note">
<b>Zones 0, 1 and 2 are never a meeting point &mdash; for any pairing.</b> That
is structural, not an artefact of the zone count: re-running at 5, 8 and 10
zones leaves the map's endpoints permanently cold. They are the ends of the
ribbon, so a front can only ever pass <em>through</em> them. All 15 meeting
points are nonetheless distinct locations &mdash; the concentration is in which
<em>zone</em> they fall in (9 of 15 in zone 3), not in the points themselves.
</p>

<p class="note">
The last three rows are roughly today's experience: <code>z0&ndash;z1</code>
meets at (3476,&nbsp;-500) after a <b>4253u</b> approach, and
<code>z0&ndash;z2</code> at (3560,&nbsp;-392) &mdash; which is the old corridor,
matching the measured <code>twn</code> meeting point almost exactly. The
current layouts are near the <em>worst</em> pairs available on this map.
</p>

<table>
  <tr><th>#</th><th>suggested rotation</th><th>meets in</th><th>approach</th></tr>
  <tr><td>1</td><td>z1&ndash;z4</td><td>4</td><td class="good">532u</td></tr>
  <tr><td>2</td><td>z0&ndash;z5</td><td>5</td><td class="good">797u</td></tr>
  <tr><td>3</td><td>z3&ndash;z5</td><td>3</td><td class="good">1063u</td></tr>
  <tr><td>4</td><td>z3&ndash;z4</td><td>4</td><td class="good">1063u</td></tr>
</table>

<p class="note">
Mean approach <b>864u</b> against today's 3004u (<code>swa</code>) and 3943u
(<code>twn</code>) &mdash; roughly a quarter of the current walk, with contact
spread over three zones instead of collapsing into one.
<b>This is not a spawn plan.</b> Zones are region suggestions; every shipped
position must still be walked in-game and harvested with
<code>spawn_helper.scr</code>.
</p>

</main>
<script>
const cmp = document.getElementById("cmp");
const after = document.getElementById("after");
const handle = document.getElementById("handle");
const slider = document.getElementById("slider");

function setPos(pct) {
  pct = Math.max(0, Math.min(100, pct));
  after.style.clipPath = `inset(0 0 0 ${pct}%)`;
  handle.style.left = pct + "%";
  if (slider.value != pct) slider.value = pct;
}
slider.addEventListener("input", () => setPos(Number(slider.value)));

// Dragging directly on the image is the natural gesture; keep the range input
// as the accessible/keyboard path.
let dragging = false;
const fromEvent = e => {
  const r = cmp.getBoundingClientRect();
  const x = (e.touches ? e.touches[0].clientX : e.clientX) - r.left;
  return (x / r.width) * 100;
};
cmp.addEventListener("pointerdown", e => { dragging = true; setPos(fromEvent(e)); });
window.addEventListener("pointermove", e => { if (dragging) setPos(fromEvent(e)); });
window.addEventListener("pointerup", () => { dragging = false; });
setPos(50);
</script>
</body>
</html>
"""
