#!/usr/bin/env python3
"""Interleaved spawn-layout generator + engine-metric simulator.

STATUS: THE INTERLEAVED LAYOUT WAS TESTED ON m1l2a AND REJECTED.
    Kept because the SIMULATOR is sound and reusable; the GENERATOR is not
    safe to ship from unattended. Two failures, both found in play and
    neither visible to any metric in this file:

    1. Auto-placement on pathnodes produced spawns inside objects and behind
       closed doors. A pathnode is a candidate filter, not proof a player box
       fits (see the long note in tools/spawns.py). Anything emit() produces
       MUST be walked in-game before it ships.

    2. Scale. m1l2a's extent is ~146000u vs mohdm6's ~3200u (~46x). Ten
       shared locations over that much ground meant players spent the match
       walking to find each other. The stock interleaved pattern depends on a
       SMALL arena. Matching the spawn geometry of mohdm6 does not import the
       thing that makes mohdm6 work.

    The simulate/compare commands remain useful for scoring ANY candidate
    layout against the real engine metric. Just do not read a good simulated
    score as permission to ship -- it measures spawn SAFETY only, not whether
    the map is fun to walk around.

WHY THIS EXISTS
    The stock DM maps (mohdm1/4/6/7) do not build two opposing team bases.
    They scatter 5-12 shared LOCATIONS across the map and place BOTH an
    info_player_allied and an info_player_axis at most of them. Measured on
    the shipped .bsp entity lumps:

        map      sep  sep/extent  spread/sep  clusters a/x  nearer-enemy
        mohdm7    18        0.00       123.0        12/12         18/18
        mohdm6    47        0.01        17.9          5/5         25/25
        mohdm1    88        0.02        15.1          5/6         20/22
        mohdm4   801        0.10         2.7         9/12         14/33
        m1l2a   6118        0.04         0.36          4/4          0/55

    Two teams, one shared pool of ground.

WHY THAT IS SAFE (the part I got wrong first)
    A 24u allied/axis pair on mohdm6 is NOT "spawn next to the enemy". Team
    spawn selection is dynamic: SpawnpointMetric_Team in the engine
    (code/fgame/dm_manager.cpp:153) scores every enabled spawn at the moment
    of respawn:

        fMetric = fMinEnemyDistSquared - (random()*0.25 + 1.0)*Square(1024)
        if (nFriends)
            fMetric += (Square(23170) - fSumFriendDistSquared/nFriends) * 0.25

    i.e. maximise distance to the NEAREST LIVING ENEMY, with a weaker pull
    toward the team's centre of mass, and a random slack term worth
    1024-1280u. Non-positive scores are dropped; the survivors are sampled
    with a bias toward the best (GetRandomSpawnpointFromList).

    So placement does not assign players to positions. It supplies a MENU the
    engine picks from at runtime. Co-located pairs are a location offering
    itself to whichever team is currently safe there. The design goal is
    therefore not "good average geometry" but "from any live game state, the
    metric still has a safe option far from the enemy".

    That is what simulate() measures, and it is the only number here that
    reflects how the map actually plays.

USAGE
    python3 tools/interleave.py plan m1l2a          # locations + geometry
    python3 tools/interleave.py emit m1l2a [out]    # writes a tdm_spawns block
    python3 tools/interleave.py simulate m1l2a      # metric sim vs swa/twn
"""

from __future__ import annotations

import math
import os
import random
import statistics
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bspmap  # noqa: E402
import spawns as S  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN = os.path.join(REPO, "main")

# Engine constants, from SpawnpointMetric_Team.
ENEMY_CAP = 23170.0        # sentinel "no enemy anywhere" distance
SLACK = 1024.0             # random slack is (random()*0.25+1.0) * Square(1024)
FRIEND_WEIGHT = 0.25

# A location must hold both an allied and an axis spawn without the two being
# effectively the same point. Stock maps sit at 24-80u; 64u keeps them
# distinct while still reading as one location.
PAIR_OFFSET = 64.0

# Locations closer together than this are the same place. Stock inter-cluster
# spacing on mohdm6/7 runs 600-1500u.
LOCATION_GAP = 900.0


def d2(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def centroid(pts):
    return [statistics.mean(p[i] for p in pts) for i in range(3)]


def spread(pts, c=None):
    c = c or centroid(pts)
    return statistics.mean(d2(p, c) for p in pts)


def bsp_data(mapname):
    found = bspmap.find_bsp(mapname, MAIN)
    if not found:
        return None
    pk3, member = found
    return zipfile.ZipFile(pk3).read(member)


def pathnodes(mapname):
    data = bsp_data(mapname)
    if data is None:
        return []
    out = []
    for e in bspmap.entities(data):
        if e.get("classname") != "info_pathnode":
            continue
        o = e.get("origin", "").split()
        if len(o) == 3:
            out.append(tuple(float(v) for v in o))
    return out


# --------------------------------------------------------------------------
# Location selection
# --------------------------------------------------------------------------

def pick_locations(nodes, count, seed_pts):
    """Farthest-point sampling over the navmesh.

    Greedy max-min: repeatedly take the pathnode furthest from everything
    chosen so far. That is what produces the even map-wide scatter the stock
    maps have, instead of a cluster with a long tail.

    seed_pts anchors the set to the existing spawn areas so the two known-good
    zones (south-west, town) are certain to be represented rather than left to
    chance.
    """
    if not nodes:
        return []
    chosen = list(seed_pts)
    if not chosen:
        chosen = [max(nodes, key=lambda n: d2(n, centroid(nodes)))]

    while len(chosen) < count:
        best, bestd = None, -1.0
        for n in nodes:
            d = min(d2(n, c) for c in chosen)
            if d > bestd:
                best, bestd = n, d
        if best is None or bestd < LOCATION_GAP:
            break
        chosen.append(best)
    return chosen


def local_slots(nodes, loc, want, taken):
    """`want` distinct standable points clustered around one location.

    Real spawn locations are not single points -- mohdm6 puts 3-5 spawns in a
    room. Drawing them from nearby pathnodes keeps every one on validated
    ground and gives the metric several options within a location.
    """
    near = sorted((n for n in nodes if d2(n, loc) <= LOCATION_GAP * 0.45),
                  key=lambda n: d2(n, loc))
    out = []
    for n in near:
        if len(out) >= want:
            break
        if any(d2(n, t) < PAIR_OFFSET * 2 for t in out):
            continue
        if any(d2(n, t) < PAIR_OFFSET * 2 for t in taken):
            continue
        out.append(n)
    return out


def build(mapname, n_locations=10, per_location=2):
    """Interleaved layout: both teams present at every location."""
    nodes = pathnodes(mapname)
    if not nodes:
        return None
    sp, _ = S.parse_scr(mapname)
    allied = [s.origin for s in sp if s.team == "allied"]
    axis = [s.origin for s in sp if s.team == "axis"]

    # Anchor on the existing zones: the SW pocket, the town, the Axis core.
    seeds = []
    if axis:
        seeds.append(tuple(centroid(axis)))
    if allied:
        # The two allied zones are separable by x; seed both.
        west = [p for p in allied if p[0] < 0]
        east = [p for p in allied if p[0] >= 0]
        for grp in (west, east):
            if grp:
                c = centroid(grp)
                seeds.append(min(nodes, key=lambda n: d2(n, c)))

    locs = pick_locations(nodes, n_locations, seeds)
    world_c = centroid(nodes)

    pairs = []          # (loc, [(cls, origin, angle), ...])
    taken = []
    for loc in locs:
        slots = local_slots(nodes, loc, per_location * 2, taken)
        if len(slots) < 2:
            continue
        taken.extend(slots)
        ents = []
        for i, pt in enumerate(slots):
            cls = ("info_player_allied" if i % 2 == 0
                   else "info_player_axis")
            ang = S.face_towards(pt, world_c)
            ents.append((cls, pt, ang))
        pairs.append((loc, ents))
    return pairs


# --------------------------------------------------------------------------
# Engine metric simulation
# --------------------------------------------------------------------------

def metric_team(origin, enemies, friends, rng):
    """Faithful port of SpawnpointMetric_Team (dm_manager.cpp:153).

    Squared distances throughout, as in the original -- the metric is never
    square-rooted, so the enemy term dominates far more steeply than a linear
    reading suggests.
    """
    min_enemy_sq = ENEMY_CAP ** 2
    for e in enemies:
        d = (origin[0] - e[0]) ** 2 + (origin[1] - e[1]) ** 2 + (origin[2] - e[2]) ** 2
        if d < min_enemy_sq:
            min_enemy_sq = d

    m = min_enemy_sq - (rng.random() * 0.25 + 1.0) * SLACK ** 2

    if friends:
        s = 0.0
        for f in friends:
            s += (origin[0] - f[0]) ** 2 + (origin[1] - f[1]) ** 2 + (origin[2] - f[2]) ** 2
        m += (ENEMY_CAP ** 2 - s / len(friends)) * FRIEND_WEIGHT
    return m


def pick_spawn(points, enemies, friends, rng):
    """Approximate GetRandomSpawnpointFromList: score, drop <=0, bias to best.

    The engine's exact sampling arithmetic is quirky (dm_manager.cpp:95-127);
    what matters for placement quality is that it discards non-positive
    scores and samples the survivors weighted toward the top. Modelled here as
    a weighted draw over the positive set, which preserves the property under
    test: does a SAFE option exist and get taken?
    """
    scored = [(metric_team(p, enemies, friends, rng), p) for p in points]
    good = [(m, p) for m, p in scored if m > 0]
    if not good:
        # Engine falls back to offset probing around spawns; for placement
        # quality the honest reading is "no safe spawn existed".
        return max(scored, key=lambda t: t[0])[1], False
    good.sort(key=lambda t: -t[0])
    n = len(good)
    weights = [n - i for i in range(n)]
    total = sum(weights)
    r = rng.random() * total
    for (m, p), w in zip(good, weights):
        r -= w
        if r <= 0:
            return p, True
    return good[0][1], True


def simulate(allied_pts, axis_pts, n_players=12, rounds=4000, seed=7):
    """Respawn players into a running game and measure the spawn they get.

    Live players are modelled as sitting at their own spawns, which is where
    they are in the seconds after a wave -- the moment when a bad layout
    actually bites.
    """
    rng = random.Random(seed)
    if not allied_pts or not axis_pts:
        return None
    dists, unsafe = [], 0
    per_side = max(1, n_players // 2)

    for _ in range(rounds):
        allies_live = [rng.choice(allied_pts) for _ in range(per_side)]
        axis_live = [rng.choice(axis_pts) for _ in range(per_side)]
        for team_pts, enemies, friends in (
                (allied_pts, axis_live, allies_live),
                (axis_pts, allies_live, axis_live)):
            spot, ok = pick_spawn(team_pts, enemies, friends, rng)
            if not ok:
                unsafe += 1
            dists.append(min(d2(spot, e) for e in enemies))

    dists.sort()
    return dict(
        n=len(dists),
        median=statistics.median(dists),
        p05=dists[int(len(dists) * 0.05)],
        p25=dists[int(len(dists) * 0.25)],
        worst=dists[0],
        under1000=sum(1 for d in dists if d < 1000) / len(dists) * 100,
        under2000=sum(1 for d in dists if d < 2000) / len(dists) * 100,
        unsafe=unsafe,
    )


# --------------------------------------------------------------------------
# Reporting / emit
# --------------------------------------------------------------------------

def zone_points(mapname, targetname):
    """Allied spawns belonging to one targetname group in the live .scr."""
    path = os.path.join(MAIN, "maps", f"{mapname}.scr")
    text = open(path, errors="replace").read()
    m = __import__("re").search(r"^tdm_spawns:(.*?)^end", text,
                                __import__("re").S | __import__("re").M)
    if not m:
        return []
    out = []
    for line in m.group(1).splitlines():
        if f'"targetname" "{targetname}"' not in line:
            continue
        sm = S.SPAWN_RE.search(line)
        if sm:
            vals = [float(v) for v in sm.group(2).split()]
            if len(vals) == 3:
                out.append(tuple(vals))
    return out


def plan(mapname, n_locations=10, per_location=2):
    pairs = build(mapname, n_locations, per_location)
    if not pairs:
        print(f"no pathnodes for {mapname}")
        return
    allied = [o for _, ents in pairs for c, o, _ in ents if c.endswith("allied")]
    axis = [o for _, ents in pairs for c, o, _ in ents if c.endswith("axis")]
    ca, cx = centroid(allied), centroid(axis)
    sep = d2(ca, cx)
    print(f"=== interleaved plan for {mapname}")
    print(f"locations: {len(pairs)}   allied: {len(allied)}   axis: {len(axis)}\n")
    for i, (loc, ents) in enumerate(pairs, 1):
        na = sum(1 for c, _, _ in ents if c.endswith("allied"))
        nx = len(ents) - na
        print(f"  {i:>2}. ({loc[0]:8.0f},{loc[1]:8.0f},{loc[2]:7.0f})  "
              f"allied {na}  axis {nx}")
    print(f"\nseparation      {sep:>8.0f}u")
    print(f"spread allied   {spread(allied, ca):>8.0f}u")
    print(f"spread axis     {spread(axis, cx):>8.0f}u")
    print(f"spread/sep      {(spread(allied,ca)+spread(axis,cx))/2/sep:>8.2f}"
          f"   (mohdm6 17.9, mohdm4 2.7, current m1l2a 0.36)")
    print(f"closest cross   {min(d2(p,q) for p in allied for q in axis):>8.0f}u")
    nearer = sum(1 for p in allied if d2(p, cx) < d2(p, ca))
    print(f"allied nearer axis centroid: {nearer}/{len(allied)}")
    return pairs


def emit(mapname, out_path=None, n_locations=10, per_location=2):
    pairs = build(mapname, n_locations, per_location)
    if not pairs:
        print(f"no pathnodes for {mapname}")
        return
    lines = ["\t// ---- interleaved variant (group: mix) ----",
             "\t// Both teams share every location; the engine's"
             " SpawnpointMetric_Team",
             "\t// decides who gets which at respawn.", ""]
    for i, (loc, ents) in enumerate(pairs, 1):
        lines.append(f"\t// location {i} @ ({loc[0]:.0f}, {loc[1]:.0f})")
        for cls, o, ang in ents:
            lines.append(f'\tspawn {cls} "origin" "{o[0]:.2f} {o[1]:.2f} {o[2]:.2f}"'
                         f' "angle" "{ang:.0f}" "targetname" "mix"')
        lines.append("")
    block = "\n".join(lines)
    if out_path:
        open(out_path, "w").write(block + "\n")
        print(f"block written to {out_path}")
        print("NOT applied to the .scr -- review, then paste it in yourself.")
    else:
        print(block)
    return block


def compare(mapname):
    """Metric simulation: interleaved vs the two live zone variants."""
    pairs = build(mapname)
    if not pairs:
        print(f"no pathnodes for {mapname}")
        return
    mix_a = [o for _, e in pairs for c, o, _ in e if c.endswith("allied")]
    mix_x = [o for _, e in pairs for c, o, _ in e if c.endswith("axis")]

    sp, _ = S.parse_scr(mapname)
    axis_now = [s.origin for s in sp if s.team == "axis"]
    swa = zone_points(mapname, "swa")
    twn = zone_points(mapname, "twn")

    cases = [
        ("swa (live)", swa, axis_now),
        ("twn (live)", twn, axis_now),
        ("interleaved", mix_a, mix_x),
    ]
    print(f"=== respawn simulation, {mapname} "
          f"(12 players, 4000 waves, engine metric)\n")
    print(f"{'layout':<14}{'spawns':>8}{'median':>9}{'p25':>8}{'p05':>8}"
          f"{'worst':>8}{'<1000u':>8}{'<2000u':>8}{'unsafe':>8}")
    for name, a, x in cases:
        if not a or not x:
            print(f"{name:<14}  (missing spawns)")
            continue
        r = simulate(a, x)
        print(f"{name:<14}{len(a)+len(x):>8}{r['median']:>9.0f}{r['p25']:>8.0f}"
              f"{r['p05']:>8.0f}{r['worst']:>8.0f}{r['under1000']:>7.1f}%"
              f"{r['under2000']:>7.1f}%{r['unsafe']:>8}")
    print("\nmedian/p05 = distance from the spawn you GET to the nearest living"
          " enemy.\nhigher is safer; p05 is the bad-luck case that actually"
          " causes spawn deaths.")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return
    cmd, mapname = sys.argv[1], sys.argv[2]
    if cmd == "plan":
        plan(mapname)
    elif cmd == "emit":
        emit(mapname, sys.argv[3] if len(sys.argv) > 3 else None)
    elif cmd == "simulate":
        compare(mapname)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
