#!/usr/bin/env python3
"""Spawn-point analysis and proposal for MOHAA map .scr files.

Read-only by default: this NEVER edits a .scr. It reports on existing spawns
and, with `propose`, writes a candidate spawn block to a file for review.

WHY PATHNODES -- AND WHAT THEY DO NOT PROVE
    Map .bsp files carry the singleplayer AI navigation mesh as
    `info_pathnode` entities (1104 of them in m1l2a). Candidate spawns are
    SELECTED from pathnodes rather than invented, which keeps a generated
    position roughly on the ground rather than in the void.

    Sanity-checked on m1l2a: the median hand-placed spawn sits 93u from the
    nearest pathnode and 40/45 are within 256u, i.e. the human-authored spawns
    and the pathnode mesh describe broadly the same walkable space.

    That is where the guarantee STOPS. This file used to claim a pathnode is
    "the designers' assertion that a character can stand there". That is
    FALSE, and it shipped broken spawns on m1l2a in the interleaved
    experiment (see the post-mortem in main/maps/m1l2a.scr). A pathnode
    asserts only that an AI PATH runs through the point. It does not assert:

      - that a 32x32x96 player bounding box FITS there (AI clip is smaller,
        and nodes sit inside crates, pillars and doorframes);
      - anything about DOORS -- a node behind a door that starts closed is a
        perfectly good AI path and a trap for a spawning player;
      - that the point is reachable from the rest of the live MP playfield.

    So: pathnodes are a CANDIDATE FILTER, not a placement guarantee. Any
    auto-generated spawn must be walked in-game before it ships. The engine's
    own SpotWouldTelefrag check (dm_manager.cpp:43) does not save you here --
    it tests for a blocking entity at respawn, not for bad geometry.

WHAT "BETTER" MEANS
    Measured across the 18 maps on this server that define both teams, the
    median allied<->axis centroid separation is ~3970u. m1l2a is 7322u — the
    most separated map here, +1.86 sigma. So for this map the fix direction is
    INWARD. Do not write an optimiser that maximises separation; it would make
    the worst map worse. Target the observed band instead.

USAGE
    python3 tools/spawns.py survey                 # rank every map
    python3 tools/spawns.py report m1l2a           # detail for one map
    python3 tools/spawns.py propose m1l2a          # candidate block -> stdout/file
"""

from __future__ import annotations

import math
import os
import re
import statistics
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bspmap  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN = os.path.join(REPO, "main")

# A spawn further than this from its own team's centroid is reported as a
# stray. 2500u is well past the spread of any well-formed team cluster
# observed on this server (the tightest maps sit near 300-900u).
STRAY_DISTANCE = 2500

# Two spawns closer than this are effectively one spawn: players telefrag or
# spawn on top of each other.
MIN_SPAWN_GAP = 128

SPAWN_RE = re.compile(
    r'spawn\s+(info_player_\w+)\s+"origin"\s+"([-\d.\s]+)"'
    r'(?:\s+"angle"\s+"([-\d.]+)")?(.*)$'
)


class Spawn:
    """One `spawn info_player_*` line, with its trailing comment preserved.

    The trailing `//`, `//*`, `// --` marks are the map author's own notes
    about which spawns are good or bad -- hand-earned knowledge from walking
    the map. Any rewrite has to carry them through, so they are parsed as data
    rather than discarded.
    """

    def __init__(self, cls, origin, angle, note, lineno):
        self.cls = cls
        self.origin = origin
        self.angle = angle
        self.note = note
        self.lineno = lineno

    @property
    def team(self):
        return {"info_player_axis": "axis",
                "info_player_allied": "allied"}.get(self.cls, "other")

    def line(self):
        x, y, z = self.origin
        s = (f'\tspawn {self.cls} "origin" "{x:.2f} {y:.2f} {z:.2f}"'
             f' "angle" "{self.angle:.0f}"')
        return s + (f" {self.note}" if self.note else "")


def parse_scr(mapname, block="tdm_spawns"):
    """Pull spawns out of ONE labelled block.

    Scoped to a single block on purpose: m1l2a also has an `ffa_spawns` block
    of 15 `info_player_deathmatch` entries feeding a different game mode.
    Rewriting those is out of scope and would change FFA behaviour silently.
    """
    path = os.path.join(MAIN, "maps", f"{mapname}.scr")
    if not os.path.exists(path):
        return [], None
    text = open(path, errors="replace").read()
    m = re.search(rf"^{block}:(.*?)^end", text, re.S | re.M)
    if not m:
        return [], text
    start = text[:m.start(1)].count("\n") + 1
    out = []
    for i, line in enumerate(m.group(1).splitlines()):
        sm = SPAWN_RE.search(line)
        if not sm:
            continue
        cls, origin, angle, note = sm.groups()
        vals = [float(v) for v in origin.split()]
        if len(vals) != 3:
            continue
        out.append(Spawn(cls, vals, float(angle) if angle else 0.0,
                         note.strip(), start + i))
    return out, text


def pathnodes(mapname):
    """Walkable candidate positions from the BSP's SP navigation mesh."""
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


def centroid(pts):
    return [statistics.mean(p[i] for p in pts) for i in range(3)]


def spread(pts, c=None):
    c = c or centroid(pts)
    return statistics.mean(math.dist(p, c) for p in pts)


def geometry(spawns):
    """Separation / spread / closest-cross-pair for one map."""
    allied = [s.origin for s in spawns if s.team == "allied"]
    axis = [s.origin for s in spawns if s.team == "axis"]
    if not (allied and axis):
        return None
    ca, cx = centroid(allied), centroid(axis)
    return dict(
        n_allied=len(allied), n_axis=len(axis),
        separation=math.dist(ca, cx),
        spread_allied=spread(allied, ca), spread_axis=spread(axis, cx),
        closest_cross=min(math.dist(p, q) for p in allied for q in axis),
        centroid_allied=ca, centroid_axis=cx,
    )


def strays(spawns, team):
    """Spawns far from their own team's centre, worst first.

    These are what actually drive a bad spread number: on m1l2a three Axis
    spawns sit 3840-5900u out and alone account for 2121u -> 854u of spread.
    Relocating a handful of outliers is a reviewable diff; re-solving all 15
    positions is not.
    """
    pts = [s for s in spawns if s.team == team]
    if not pts:
        return []
    c = centroid([s.origin for s in pts])
    scored = [(math.dist(s.origin, c), s) for s in pts]
    scored.sort(key=lambda t: -t[0])
    return scored


def survey():
    maps = sorted({os.path.basename(p)[:-4]
                   for p in os.listdir(os.path.join(MAIN, "maps"))
                   if p.endswith(".scr")}) if os.path.isdir(
                       os.path.join(MAIN, "maps")) else []
    rows = []
    for m in maps:
        sp, _ = parse_scr(m)
        if not sp:
            continue
        g = geometry(sp)
        if g:
            g["map"] = m
            rows.append(g)
    rows.sort(key=lambda r: -r["separation"])
    print(f"{'map':<14}{'a/x':<8}{'separation':>11}{'spread_a':>10}"
          f"{'spread_x':>10}{'closest':>9}")
    for r in rows:
        print(f"{r['map']:<14}{str(r['n_allied'])+'/'+str(r['n_axis']):<8}"
              f"{r['separation']:>11.0f}{r['spread_allied']:>10.0f}"
              f"{r['spread_axis']:>10.0f}{r['closest_cross']:>9.0f}")
    seps = [r["separation"] for r in rows]
    if len(seps) > 2:
        mu, sd = statistics.mean(seps), statistics.pstdev(seps)
        print(f"\nmaps: {len(rows)}  median: {statistics.median(seps):.0f}"
              f"  mean: {mu:.0f}  stdev: {sd:.0f}")
        print("\noutliers (|z| >= 1.5):")
        for r in rows:
            z = (r["separation"] - mu) / sd if sd else 0
            if abs(z) >= 1.5:
                d = "TOO FAR APART" if z > 0 else "TOO CLOSE"
                print(f"   {r['map']:<12} sep={r['separation']:>6.0f}"
                      f"  z={z:+.2f}  {d}")
    return rows


def report(mapname):
    sp, _ = parse_scr(mapname)
    if not sp:
        print(f"no tdm_spawns block found for {mapname}")
        return
    g = geometry(sp)
    nodes = pathnodes(mapname)
    print(f"=== {mapname}: {len(sp)} spawns in tdm_spawns, "
          f"{len(nodes)} pathnodes in bsp\n")
    if g:
        print(f"separation      {g['separation']:>8.0f}u")
        print(f"spread allied   {g['spread_allied']:>8.0f}u  ({g['n_allied']} spawns)")
        print(f"spread axis     {g['spread_axis']:>8.0f}u  ({g['n_axis']} spawns)")
        print(f"closest cross   {g['closest_cross']:>8.0f}u")

    if nodes:
        ds = []
        for s in sp:
            ds.append(min(math.dist(s.origin, n) for n in nodes))
        print(f"\nspawn -> nearest pathnode: median {statistics.median(ds):.0f}u, "
              f"{sum(1 for d in ds if d <= 256)}/{len(ds)} within 256u")

    for team in ("axis", "allied"):
        rows = strays(sp, team)
        if not rows:
            continue
        bad = [r for r in rows if r[0] > STRAY_DISTANCE]
        print(f"\n--- {team}: {len(rows)} spawns, {len(bad)} stray "
              f"(>{STRAY_DISTANCE}u from own centroid)")
        for d, s in rows[:6]:
            mark = "  <== STRAY" if d > STRAY_DISTANCE else ""
            x, y, z = s.origin
            print(f"   {d:>7.0f}u  ({x:8.1f},{y:8.1f},{z:7.1f})"
                  f"  note={s.note!r}{mark}")
        if bad:
            keep = [r[1].origin for r in rows if r[0] <= STRAY_DISTANCE]
            if keep:
                print(f"   spread without strays: "
                      f"{spread(keep):.0f}u (currently {spread([r[1].origin for r in rows]):.0f}u)")


def face_towards(origin, target):
    """Yaw in degrees so a player at `origin` looks at `target`.

    Pathnodes carry no angle, so facing has to be synthesised. Pointing at the
    enemy centroid is the safe default: it is never a wall-stare, and it
    matches what a human placer does instinctively.
    """
    return math.degrees(math.atan2(target[1] - origin[1],
                                   target[0] - origin[0]))


def propose(mapname, out_path=None):
    """Relocate stray spawns onto pathnodes near the team's real cluster.

    Deliberately minimal: keeps every non-stray spawn (and its note) exactly
    as-is, and only moves the outliers. That produces a diff a human can
    actually review line by line.
    """
    sp, _ = parse_scr(mapname)
    if not sp:
        print(f"no tdm_spawns block for {mapname}")
        return
    nodes = pathnodes(mapname)
    if not nodes:
        print(f"no pathnodes in {mapname}.bsp -- cannot validate positions")
        return

    proposal, notes = [], []
    for team, enemy in (("axis", "allied"), ("allied", "axis")):
        rows = strays(sp, team)
        keep = [s for d, s in rows if d <= STRAY_DISTANCE]
        move = [s for d, s in rows if d > STRAY_DISTANCE]
        if not keep:
            proposal.extend(s for _, s in rows)
            continue

        core = centroid([s.origin for s in keep])
        enemy_pts = [s.origin for s in sp if s.team == enemy]
        enemy_c = centroid(enemy_pts) if enemy_pts else core
        core_spread = spread([s.origin for s in keep], core)

        # Candidates: walkable, near the team's real cluster, at a plausible
        # height for that cluster, and not on top of a spawn we are keeping.
        zs = [s.origin[2] for s in keep]
        zlo, zhi = min(zs) - 192, max(zs) + 192
        taken = [s.origin for s in keep]
        cands = []
        for n in nodes:
            if not (zlo <= n[2] <= zhi):
                continue
            d = math.dist(n, core)
            if d > core_spread * 1.35:
                continue
            if min((math.dist(n, t) for t in taken), default=1e9) < MIN_SPAWN_GAP:
                continue
            cands.append((d, n))

        # Spread the replacements out: take the ones furthest from each other
        # inside the cluster rather than clumping them at the centroid.
        cands.sort(key=lambda t: -t[0])
        chosen = []
        for _, n in cands:
            if len(chosen) >= len(move):
                break
            if all(math.dist(n, c) >= MIN_SPAWN_GAP * 2 for c in chosen):
                chosen.append(n)

        proposal.extend(keep)
        for i, old in enumerate(move):
            if i < len(chosen):
                new = chosen[i]
                ang = face_towards(new, enemy_c)
                note = (old.note + " " if old.note else "") + "// moved: was stray"
                proposal.append(Spawn(old.cls, list(new), ang, note.strip(),
                                      old.lineno))
                notes.append(f"  {team:<7} ({old.origin[0]:8.1f},{old.origin[1]:8.1f},"
                             f"{old.origin[2]:7.1f}) -> ({new[0]:8.1f},{new[1]:8.1f},"
                             f"{new[2]:7.1f})  angle {ang:.0f}")
            else:
                proposal.append(old)
                notes.append(f"  {team:<7} KEPT (no candidate found): {old.origin}")

    lines = ["tdm_spawns:", ""]
    for team in ("axis", "allied"):
        for i, s in enumerate([p for p in proposal if p.team == team]):
            if i and i % 5 == 0:
                lines.append("")
            lines.append(s.line())
        lines.append("")
    lines.append("end")
    block = "\n".join(lines)

    before = geometry(sp)
    after = geometry(proposal)
    print(f"=== proposal for {mapname}\n")
    print("relocations:")
    print("\n".join(notes) if notes else "  (none needed)")
    print(f"\n{'metric':<18}{'before':>10}{'after':>10}")
    for k, label in (("separation", "separation"), ("spread_axis", "spread axis"),
                     ("spread_allied", "spread allied"),
                     ("closest_cross", "closest cross")):
        print(f"{label:<18}{before[k]:>10.0f}{after[k]:>10.0f}")

    if out_path:
        with open(out_path, "w") as f:
            f.write(block + "\n")
        print(f"\nblock written to {out_path}")
        print("NOT applied to the .scr -- review, then paste it in yourself.")
    return proposal


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd = sys.argv[1]
    if cmd == "survey":
        survey()
    elif cmd == "report" and len(sys.argv) > 2:
        report(sys.argv[2])
    elif cmd == "propose" and len(sys.argv) > 2:
        out = sys.argv[3] if len(sys.argv) > 3 else None
        propose(sys.argv[2], out)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
