#!/usr/bin/env python3
"""Zone survey: partition a map's navigable area into candidate spawn regions.

GOAL
    Not "find spawn positions" -- this tool never emits a spawn line. It
    partitions the REACHABLE ground into a handful of regions that TILE the
    map, so a rotation over them gives measurable map coverage:

        coverage after m matches ~= 1 - (1 - k/N)^m

    with N zones and k live per match. For ~90% coverage in 3 matches you
    need k/N ~= 0.55; in 2 matches, ~0.68. Zones that merely DIFFER are not
    enough -- two distinct zones both in the south leave the north cold
    forever. Tiling is the property that makes coverage converge.

WHAT THIS TOOL DOES NOT PROVE
    A zone is a REGION SUGGESTION, not a spawn position. Nothing here proves
    a player box fits anywhere in it (see tools/spawns.py for why pathnodes
    are only a candidate filter, and main/maps/m1l2a.scr for the mix
    post-mortem where that mistake shipped broken spawns).

    The intended workflow is:
        1. this tool proposes N regions + a walk order
        2. a HUMAN walks each region in-game and presses +use on good spots,
           using main/global/feho/spawn_helper.scr, which prints a ready
           spawn line at a position the player was demonstrably standing on
        3. only those hand-harvested lines ever ship

CONNECTIVITY, NOT GEOMETRY
    Regions are grown over a connectivity graph of the navmesh, not by
    slicing the bounding box. A box slice happily proposes a region split by
    a cliff or a locked door; a connected component cannot be. Two points in
    the same zone here are always mutually walkable.

USAGE
    python3 tools/zones.py survey m1l2a [n_zones]
    python3 tools/zones.py coverage 6 3      # N zones, k live -> coverage table
"""

from __future__ import annotations

import math
import os
import sys
import zipfile
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bspmap  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN = os.path.join(REPO, "main")

# Two pathnodes within this horizontal distance are treated as mutually
# walkable. The SP mesh on m1l2a is dense (median spacing well under this),
# so it links genuine neighbours without bridging across walls.
LINK_DIST = 420.0

# Max vertical step for a link. Stops a graph edge from tunnelling between a
# rooftop and the street directly below it, which would merge two regions a
# player cannot actually walk between.
LINK_DZ = 160.0


def d2(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def pathnodes(mapname):
    found = bspmap.find_bsp(mapname, MAIN)
    if not found:
        return []
    pk3, member = found
    data = zipfile.ZipFile(pk3).read(member)
    out = []
    for e in bspmap.entities(data):
        if e.get("classname") != "info_pathnode":
            continue
        o = e.get("origin", "").split()
        if len(o) == 3:
            out.append(tuple(float(v) for v in o))
    return out


def build_graph(nodes):
    """Adjacency over the navmesh, bucketed so it stays O(n) not O(n^2)."""
    cell = LINK_DIST
    grid = {}
    for i, p in enumerate(nodes):
        grid.setdefault((int(p[0] // cell), int(p[1] // cell)), []).append(i)

    adj = [[] for _ in nodes]
    for i, p in enumerate(nodes):
        cx, cy = int(p[0] // cell), int(p[1] // cell)
        for gx in (cx - 1, cx, cx + 1):
            for gy in (cy - 1, cy, cy + 1):
                for j in grid.get((gx, gy), ()):
                    if j <= i:
                        continue
                    q = nodes[j]
                    if abs(p[2] - q[2]) > LINK_DZ:
                        continue
                    if d2(p, q) <= LINK_DIST:
                        adj[i].append(j)
                        adj[j].append(i)
    return adj


def components(adj, n):
    seen = [False] * n
    out = []
    for s in range(n):
        if seen[s]:
            continue
        comp, dq = [], deque([s])
        seen[s] = True
        while dq:
            u = dq.popleft()
            comp.append(u)
            for v in adj[u]:
                if not seen[v]:
                    seen[v] = True
                    dq.append(v)
        out.append(comp)
    out.sort(key=len, reverse=True)
    return out


def multi_bfs(adj, seeds, members):
    """Grow all seeds simultaneously; each node joins its nearest seed.

    Simultaneous growth is what makes the result a PARTITION -- every
    reachable node ends up in exactly one zone, with boundaries falling
    naturally at the chokepoints between regions.
    """
    owner = {i: None for i in members}
    dist = {i: 0 for i in members}
    dq = deque()
    for z, s in enumerate(seeds):
        owner[s] = z
        dq.append(s)
    while dq:
        u = dq.popleft()
        for v in adj[u]:
            if v in owner and owner[v] is None:
                owner[v] = owner[u]
                dist[v] = dist[u] + 1
                dq.append(v)
    return owner


def farthest_seeds(nodes, adj, members, k):
    """Pick k seeds that are far apart IN GRAPH HOPS, not in metres.

    Graph distance is the right metric: two points either side of a wall are
    metrically close but many hops apart, and belong in different zones.
    """
    def bfs(src):
        d = {src: 0}
        dq = deque([src])
        while dq:
            u = dq.popleft()
            for v in adj[u]:
                if v in members and v not in d:
                    d[v] = d[u] + 1
                    dq.append(v)
        return d

    start = members[0]
    d0 = bfs(start)
    seeds = [max(d0, key=lambda i: d0[i])]
    best = bfs(seeds[0])
    while len(seeds) < k:
        nxt = max(best, key=lambda i: best[i])
        if best.get(nxt, 0) == 0:
            break
        seeds.append(nxt)
        d = bfs(nxt)
        for i, v in d.items():
            if i in best:
                best[i] = min(best[i], v)
    return seeds


def survey(mapname, k=6):
    nodes = pathnodes(mapname)
    if not nodes:
        print(f"no pathnodes for {mapname}")
        return
    adj = build_graph(nodes)
    comps = components(adj, len(nodes))
    main = comps[0]
    print(f"=== zone survey: {mapname}")
    print(f"pathnodes {len(nodes)}   graph components {len(comps)}   "
          f"largest {len(main)} ({len(main)/len(nodes)*100:.0f}% of mesh)")
    if len(comps) > 1:
        skipped = sum(len(c) for c in comps[1:])
        print(f"  ignoring {len(comps)-1} disconnected fragment(s), "
              f"{skipped} nodes -- unreachable from the main area")

    xs = [nodes[i][0] for i in main]
    ys = [nodes[i][1] for i in main]
    print(f"navigable extent {math.hypot(max(xs)-min(xs), max(ys)-min(ys)):.0f}u"
          f"  (mohdm6 ~3181u, mohdm7 ~7791u)")

    mset = set(main)
    seeds = farthest_seeds(nodes, adj, main, k)
    owner = multi_bfs(adj, seeds, mset)

    zones = {}
    for i in main:
        zones.setdefault(owner[i], []).append(i)

    print(f"\n{'zone':<6}{'nodes':>7}{'centre':>22}{'radius':>9}{'z-range':>16}")
    info = []
    for z in sorted(zones):
        pts = [nodes[i] for i in zones[z]]
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        cz = sum(p[2] for p in pts) / len(pts)
        rad = max(d2(p, (cx, cy)) for p in pts)
        zlo = min(p[2] for p in pts)
        zhi = max(p[2] for p in pts)
        info.append(dict(z=z, n=len(pts), c=(cx, cy, cz), rad=rad,
                         zlo=zlo, zhi=zhi))
        print(f"{z:<6}{len(pts):>7}  ({cx:7.0f},{cy:7.0f},{cz:6.0f})"
              f"{rad:>9.0f}{f'{zlo:.0f}..{zhi:.0f}':>16}")

    share = [i["n"] / len(main) for i in info]
    print(f"\nzone size balance: smallest {min(share)*100:.0f}% of mesh, "
          f"largest {max(share)*100:.0f}%")
    if max(share) > 0.35:
        print("  NOTE: one zone dominates -- consider a higher zone count")

    print("\ninter-zone centre distances (u):")
    hdr = "      " + "".join(f"{i['z']:>8}" for i in info)
    print(hdr)
    for a in info:
        row = f"{a['z']:<6}"
        for b in info:
            row += f"{d2(a['c'], b['c']):>8.0f}" if a is not b else f"{'-':>8}"
        print(row)

    print("\n--- WALK ORDER for spawn_helper.scr ---")
    print("set spawn_helper 1, then walk each zone centre and press +use on")
    print("good-looking spots. Only hand-harvested positions should ship.")
    for a in info:
        print(f"  zone {a['z']}: head to ({a['c'][0]:.0f}, {a['c'][1]:.0f}) "
              f"-- {a['n']} nodes within ~{a['rad']:.0f}u")

    print("\ncoverage if k of these N zones are live per match:")
    coverage(len(info), None)
    return info


def coverage(n, k=None):
    ks = [k] if k else range(1, n + 1)
    print(f"{'k live':<8}{'1 match':>10}{'2 matches':>12}{'3 matches':>12}")
    for kk in ks:
        p = kk / n
        row = f"{kk:<8}"
        for m in (1, 2, 3):
            row += f"{(1-(1-p)**m)*100:>11.0f}%"
        print(row)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    if sys.argv[1] == "survey" and len(sys.argv) > 2:
        survey(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 6)
    elif sys.argv[1] == "coverage" and len(sys.argv) > 3:
        coverage(int(sys.argv[2]), int(sys.argv[3]))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
