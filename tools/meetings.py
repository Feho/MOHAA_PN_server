#!/usr/bin/env python3
"""Meeting-point survey: where does contact actually happen for each zone pair?

WHY NOT THE MIDPOINT
    The obvious "where do they meet" answer is the midpoint of the two base
    centres. On m1l2a that is WRONG, and wrong in a way that matters: the
    navigable area is a bent NW->SE ribbon, so the straight-line midpoint of
    two zones routinely lands in unwalkable space outside the mesh.

    Contact happens where two advancing fronts MEET ALONG THE PATH between
    them -- i.e. the point on the walkable graph that is equidistant in
    TRAVEL time from both bases. That is what this computes: a double BFS
    from each zone, then the node minimising |dist_a - dist_b|.

    Ties are broken toward the node with the smaller total distance, which
    picks the meeting point on the most direct route rather than an
    equidistant point out on some far loop.

WHAT IT REPORTS PER PAIR
    meet zone   which of the N zones the contact point falls in
    approach    hops-to-contact, converted to world units, per side
    detour      how much longer the walk is than the straight line; a high
                value means the two bases are close on the map but far apart
                to walk, which reads as frustrating rather than tactical
    fairness    |approach_a - approach_b|; asymmetric pairs let one team hold
                the contested ground before the other arrives

WHAT THIS TOOL DOES NOT PROVE
    Nothing here is a spawn position. A zone is a region suggestion; every
    shipped spawn must still be hand-harvested in-game with
    main/global/feho/spawn_helper.scr. See the mix post-mortem in
    main/maps/m1l2a.scr for what happens when that step is skipped.

USAGE
    python3 tools/meetings.py survey m1l2a [n_zones]
    python3 tools/meetings.py rotation m1l2a [n_zones] [k_pairs]
"""

from __future__ import annotations

import math
import os
import sys
from collections import deque
from itertools import combinations

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zones as Z  # noqa: E402


def bfs_from(adj, sources, members):
    """Hop distance from a SET of sources, not a single node.

    NOTE the sources must be a zone's SPAWN AREA (its core), never all of its
    nodes. Seeding from every node measures from the zone's nearest EDGE, so
    two zones that share a border come out as ~1 hop apart -- technically
    true and completely useless, since players spawn in the middle of a zone,
    not on its boundary. Seeding from the core is what makes "approach"
    mean "how far you actually walk after respawning".
    """
    dist = {}
    dq = deque()
    for s in sources:
        dist[s] = 0
        dq.append(s)
    while dq:
        u = dq.popleft()
        for v in adj[u]:
            if v in members and v not in dist:
                dist[v] = dist[u] + 1
                dq.append(v)
    return dist


def analyse(mapname, k=6):
    nodes = Z.pathnodes(mapname)
    if not nodes:
        print(f"no pathnodes for {mapname}")
        return None
    adj = Z.build_graph(nodes)
    main = Z.components(adj, len(nodes))[0]
    mset = set(main)
    seeds = Z.farthest_seeds(nodes, adj, main, k)
    owner = Z.multi_bfs(adj, seeds, mset)

    zmembers = {}
    for i in main:
        zmembers.setdefault(owner[i], []).append(i)
    zcen = {}
    for z, idx in zmembers.items():
        pts = [nodes[i] for i in idx]
        zcen[z] = (sum(p[0] for p in pts) / len(pts),
                   sum(p[1] for p in pts) / len(pts))

    # Hop distance is converted to world units via the mean edge length, so
    # "approach" is readable in the same units as everything else.
    tot = n = 0
    for u in main:
        for v in adj[u]:
            if v in mset:
                tot += Z.d2(nodes[u], nodes[v])
                n += 1
    hop_u = tot / n if n else Z.LINK_DIST

    # Spawn cores: the nodes closest to each zone centre. Players deploy in
    # the middle of a zone, so distances are measured from there (see the
    # note in bfs_from -- seeding from the whole zone measures edge-to-edge
    # and makes bordering zones look adjacent).
    zcore = {}
    for z, idx in zmembers.items():
        ranked = sorted(idx, key=lambda i: Z.d2(nodes[i], zcen[z]))
        zcore[z] = ranked[:max(1, len(ranked) // 8)]

    dists = {z: bfs_from(adj, zcore[z], mset) for z in zmembers}
    return dict(nodes=nodes, adj=adj, main=main, mset=mset, owner=owner,
                zmembers=zmembers, zcen=zcen, zcore=zcore,
                dists=dists, hop_u=hop_u)


def meeting(ctx, a, b):
    da, db = ctx["dists"][a], ctx["dists"][b]
    best, score = None, None
    for i in ctx["main"]:
        if i not in da or i not in db:
            continue
        s = (abs(da[i] - db[i]), da[i] + db[i])
        if score is None or s < score:
            best, score = i, s
    if best is None:
        return None
    return dict(node=best, zone=ctx["owner"][best],
                pos=ctx["nodes"][best],
                hops_a=da[best], hops_b=db[best])


def survey(mapname, k=6):
    ctx = analyse(mapname, k)
    if not ctx:
        return
    hop = ctx["hop_u"]
    print(f"=== meeting-point survey: {mapname}   ({k} zones, "
          f"{len(ctx['main'])} nodes, ~{hop:.0f}u per hop)\n")

    rows = []
    for a, b in combinations(sorted(ctx["zmembers"]), 2):
        m = meeting(ctx, a, b)
        if not m:
            continue
        appr_a = m["hops_a"] * hop
        appr_b = m["hops_b"] * hop
        straight = Z.d2(ctx["zcen"][a], ctx["zcen"][b])
        walk = appr_a + appr_b
        rows.append(dict(a=a, b=b, meet=m["zone"], pos=m["pos"],
                         appr_a=appr_a, appr_b=appr_b,
                         approach=(appr_a + appr_b) / 2,
                         fairness=abs(appr_a - appr_b),
                         detour=walk / straight if straight else 0))

    rows.sort(key=lambda r: r["approach"])
    print(f"{'pair':<7}{'meets in':>9}{'meet point':>20}{'approach':>10}"
          f"{'fair':>8}{'detour':>8}")
    for r in rows:
        p = r["pos"]
        print(f"z{r['a']}-z{r['b']:<4}{r['meet']:>9}"
              f"{f'({p[0]:.0f},{p[1]:.0f})':>20}"
              f"{r['approach']:>10.0f}{r['fairness']:>8.0f}{r['detour']:>8.2f}")

    from collections import Counter
    c = Counter(r["meet"] for r in rows)
    print(f"\ncontact zone distribution over all {len(rows)} pairs:")
    for z in sorted(ctx["zmembers"]):
        bar = "#" * c.get(z, 0)
        print(f"  zone {z}: {c.get(z,0):>2} {bar}")
    cold = [z for z in ctx["zmembers"] if c.get(z, 0) == 0]
    if cold:
        print(f"  zones that are NEVER a meeting point: {cold}")
        print("  (these can only ever be transited, whatever the pairing)")
    return ctx, rows


def rotation(mapname, k=6, pick=4):
    """Choose a pair set that spreads contact across the most zones.

    Greedy: repeatedly take the pair whose meeting zone is least represented
    so far, tie-broken by shortest approach. Optimises for VARIETY OF
    CONTACT, which is the actual complaint, rather than for base spread.
    """
    out = survey(mapname, k)
    if not out:
        return
    ctx, rows = out

    chosen, used = [], {}
    pool = sorted(rows, key=lambda r: r["approach"])
    while len(chosen) < pick and pool:
        pool.sort(key=lambda r: (used.get(r["meet"], 0), r["approach"]))
        best = pool.pop(0)
        chosen.append(best)
        used[best["meet"]] = used.get(best["meet"], 0) + 1

    print(f"\n=== suggested rotation: {len(chosen)} pairs")
    print(f"{'#':<3}{'pair':<8}{'meets in':>9}{'approach':>10}{'fair':>8}")
    for i, r in enumerate(chosen, 1):
        print(f"{i:<3}z{r['a']}-z{r['b']:<5}{r['meet']:>9}"
              f"{r['approach']:>10.0f}{r['fairness']:>8.0f}")
    covered = sorted({r["meet"] for r in chosen})
    print(f"\ncontact spread over zones {covered} "
          f"({len(covered)}/{k} zones see fighting)")
    avg = sum(r["approach"] for r in chosen) / len(chosen)
    print(f"mean approach {avg:.0f}u  (current swa ~3004u, twn ~3943u)")
    print("\nNOT a spawn plan. Walk each zone with spawn_helper.scr and press")
    print("+use on good spots; only hand-harvested positions ship.")
    return chosen


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return
    cmd, mapname = sys.argv[1], sys.argv[2]
    k = int(sys.argv[3]) if len(sys.argv) > 3 else 6
    if cmd == "survey":
        survey(mapname, k)
    elif cmd == "rotation":
        rotation(mapname, k, int(sys.argv[4]) if len(sys.argv) > 4 else 4)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
