#!/usr/bin/env python3
"""Render a top-down height-shaded PNG from a MOHAA .bsp. Stdlib only.

Proof-of-concept for the live tactical map: produces <map>.png plus a
<map>.json with the world->image transform so a browser can place player
dots without re-deriving anything.
"""
import json
import struct
import sys
import zlib
from pathlib import Path

# --- BSP layout (verified against Pak5/maps/DM/mohdm1.bsp) ---
L_SHADERS, L_SURFACES, L_DRAWVERTS, L_INDEXES = 0, 3, 4, 5
SHADER_STRIDE, SURF_STRIDE, VERT_STRIDE = 140, 108, 44

SURF_NODRAW = 0x80
SURF_SKY = 0x4
# content flag bit set on clip/trigger brushes that are invisible in game
CONTENTS_DETAIL_IGNORE = ()

SKIP_TOKENS = ("clip", "nodraw", "caulk", "sky", "trigger", "hint", "origin", "portal",
               "treeline", "common/black", "backdrop")


def load_lumps(data):
    return [struct.unpack("<ii", data[12 + i * 8: 20 + i * 8]) for i in range(20)]


def parse(data):
    L = load_lumps(data)

    o, l = L[L_SHADERS]
    shaders = []
    for i in range(l // SHADER_STRIDE):
        r = data[o + i * SHADER_STRIDE: o + (i + 1) * SHADER_STRIDE]
        name = r[:64].split(b"\0")[0].decode("latin1")
        surf, cont = struct.unpack("<ii", r[64:72])
        shaders.append((name, surf, cont))

    o, l = L[L_DRAWVERTS]
    nvert = l // VERT_STRIDE
    verts = [struct.unpack("<fff", data[o + k * VERT_STRIDE: o + k * VERT_STRIDE + 12])
             for k in range(nvert)]

    o, l = L[L_INDEXES]
    indexes = struct.unpack("<%di" % (l // 4), data[o:o + l])

    o, l = L[L_SURFACES]
    surfs = []
    for k in range(l // SURF_STRIDE):
        f = struct.unpack("<27i", data[o + k * SURF_STRIDE: o + k * SURF_STRIDE + 108])
        surfs.append({"shader": f[0], "firstVert": f[3], "numVerts": f[4],
                      "firstIndex": f[5], "numIndexes": f[6],
                      "patchWidth": f[24], "patchHeight": f[25]})
    return shaders, verts, indexes, surfs


def patch_triangles(verts, first, pw, ph, level=4):
    """Tessellate a biquadratic Bezier patch into triangles.

    Surfaces with numIndexes == 0 are curved patches: numVerts control points
    laid out as a pw x ph grid (fields 24/25, verified pw*ph == numVerts on
    570/570 patches in m2l1). Ignoring them leaves terrain floors missing and
    the map renders as buildings floating in void.

    The grid is a set of overlapping 3x3 biquadratic subpatches stepping by 2,
    which is the standard Q3/idTech3 layout.
    """
    def ctrl(r, c):
        return verts[first + r * pw + c]

    def bez(p0, p1, p2, t):
        a, b = (1.0 - t) ** 2, 2 * t * (1.0 - t)
        c = t * t
        return (a * p0[0] + b * p1[0] + c * p2[0],
                a * p0[1] + b * p1[1] + c * p2[1],
                a * p0[2] + b * p1[2] + c * p2[2])

    tris = []
    n = level
    for r0 in range(0, ph - 2, 2):
        for c0 in range(0, pw - 2, 2):
            grid = [[ctrl(r0 + r, c0 + c) for c in range(3)] for r in range(3)]
            # evaluate an (n+1)x(n+1) sample grid over the subpatch
            pts = []
            for i in range(n + 1):
                u = i / n
                rows = [bez(grid[r][0], grid[r][1], grid[r][2], u) for r in range(3)]
                col = []
                for j in range(n + 1):
                    v = j / n
                    col.append(bez(rows[0], rows[1], rows[2], v))
                pts.append(col)
            for i in range(n):
                for j in range(n):
                    a, b = pts[i][j], pts[i + 1][j]
                    c, d = pts[i + 1][j + 1], pts[i][j + 1]
                    tris.append((a, b, c))
                    tris.append((a, c, d))
    return tris


def drawable(shader):
    name, surf, cont = shader
    if surf & (SURF_NODRAW | SURF_SKY):
        return False
    low = name.lower()
    return not any(t in low for t in SKIP_TOKENS)


def entities(data):
    """Entity lump is the one containing the worldspawn text block."""
    i = data.find(b'"classname"')
    if i < 0:
        return []
    for o, l in load_lumps(data):
        if o <= i < o + l:
            text = data[o:o + l].decode("latin1")
            break
    else:
        return []
    ents, cur = [], None
    for line in text.splitlines():
        line = line.strip()
        if line == "{":
            cur = {}
        elif line == "}":
            if cur:
                ents.append(cur)
            cur = None
        elif cur is not None and line.startswith('"'):
            parts = line.split('"')
            if len(parts) >= 5:
                cur[parts[1]] = parts[3]
    return ents


def write_png(path, w, h, rgb):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += rgb[y * w * 3:(y + 1) * w * 3]

    def chunk(tag, payload):
        c = struct.pack(">I", len(payload)) + tag + payload
        return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
           + chunk(b"IEND", b""))
    Path(path).write_bytes(png)


def ramp(t):
    """Dark blue-grey (low) -> warm bone (high). Readable in both themes."""
    stops = [(0.0, (24, 28, 38)), (0.35, (48, 64, 78)),
             (0.65, (110, 120, 110)), (1.0, (226, 214, 186))]
    for i in range(len(stops) - 1):
        a, ca = stops[i]
        b, cb = stops[i + 1]
        if a <= t <= b:
            f = (t - a) / (b - a)
            return tuple(int(ca[j] + (cb[j] - ca[j]) * f) for j in range(3))
    return stops[-1][1]


def render(bsp_bytes, out_png, out_json, size=1024):
    shaders, verts, indexes, surfs = parse(bsp_bytes)

    ents = entities(bsp_bytes)
    spawn_pts = []
    for e in ents:
        if e.get("classname", "").startswith("info_player") and "origin" in e:
            try:
                x, y, _ = [float(v) for v in e["origin"].split()]
                spawn_pts.append((x, y))
            except ValueError:
                pass

    tris = []
    n_patch = 0
    for s in surfs:
        if not drawable(shaders[s["shader"]]):
            continue
        fv, fi, ni = s["firstVert"], s["firstIndex"], s["numIndexes"]
        if ni >= 3:
            for k in range(0, ni - 2, 3):
                tris.append(tuple(verts[fv + indexes[fi + k + j]] for j in range(3)))
        elif s["numVerts"] > 0:
            pw, ph = s["patchWidth"], s["patchHeight"]
            if pw >= 3 and ph >= 3 and pw * ph == s["numVerts"]:
                tris.extend(patch_triangles(verts, fv, pw, ph))
                n_patch += 1

    if not tris:
        raise SystemExit("no drawable geometry")

    xs = sorted(v[0] for t in tris for v in t)
    ys = sorted(v[1] for t in tris for v in t)
    zs = sorted(v[2] for t in tris for v in t)

    def pct(seq, p):
        return seq[min(len(seq) - 1, max(0, int(len(seq) * p)))]

    # Percentile framing: distant backdrops/void-fillers that escape the shader
    # filter would otherwise blow the bbox out and shrink the playable area to a
    # dot. Trim the outer 0.5% per axis, then union with the spawn extents so we
    # can never crop away somewhere a player can actually stand.
    minx, maxx = pct(xs, 0.005), pct(xs, 0.995)
    miny, maxy = pct(ys, 0.005), pct(ys, 0.995)
    if spawn_pts:
        sx = [p[0] for p in spawn_pts]
        sy = [p[1] for p in spawn_pts]
        m = 192.0  # keep spawns comfortably inside the frame
        minx, maxx = min(minx, min(sx) - m), max(maxx, max(sx) + m)
        miny, maxy = min(miny, min(sy) - m), max(maxy, max(sy) + m)

    # Height ramp on percentiles too, so one tall spire doesn't flatten contrast.
    minz, maxz = pct(zs, 0.01), pct(zs, 0.99)

    pad = 0.02 * max(maxx - minx, maxy - miny)
    minx -= pad; maxx += pad; miny -= pad; maxy += pad
    span = max(maxx - minx, maxy - miny)
    scale = (size - 1) / span

    # Non-square maps: size the canvas to the content so a wide map fills the
    # frame instead of floating in a square field of void.
    W = max(1, min(size, int((maxx - minx) * scale) + 1))
    H = max(1, min(size, int((maxy - miny) * scale) + 1))

    NEG = -1e30
    zbuf = [NEG] * (W * H)

    def put(px, py, z):
        if 0 <= px < W and 0 <= py < H:
            i = py * W + px
            if z > zbuf[i]:
                zbuf[i] = z

    # rasterize each triangle: scanline fill with max-Z (top-down)
    for tri in tris:
        pts = []
        for (wx, wy, wz) in tri:
            px = (wx - minx) * scale
            py = (maxy - wy) * scale   # flip Y: world +Y is north, image +Y is down
            pts.append((px, py, wz))
        ymin = max(0, int(min(p[1] for p in pts)))
        ymax = min(H - 1, int(max(p[1] for p in pts)) + 1)
        (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = pts
        den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(den) < 1e-9:
            continue
        xmn = max(0, int(min(p[0] for p in pts)))
        xmx = min(W - 1, int(max(p[0] for p in pts)) + 1)
        for py in range(ymin, ymax + 1):
            for px in range(xmn, xmx + 1):
                l0 = ((y1 - y2) * (px + .5 - x2) + (x2 - x1) * (py + .5 - y2)) / den
                l1 = ((y2 - y0) * (px + .5 - x2) + (x0 - x2) * (py + .5 - y2)) / den
                l2 = 1 - l0 - l1
                if l0 >= -0.002 and l1 >= -0.002 and l2 >= -0.002:
                    put(px, py, l0 * z0 + l1 * z1 + l2 * z2)

    rgb = bytearray(W * H * 3)
    zr = (maxz - minz) or 1.0
    for i, z in enumerate(zbuf):
        if z == NEG:
            r, g, b = 15, 17, 22          # void
        else:
            t = (z - minz) / zr
            r, g, b = ramp(0.0 if t < 0 else 1.0 if t > 1 else t)
        rgb[i * 3] = r; rgb[i * 3 + 1] = g; rgb[i * 3 + 2] = b

    write_png(out_png, W, H, rgb)

    meta = {
        "width": W,
        "height": H,
        "world": {"minx": minx, "maxx": maxx, "miny": miny, "maxy": maxy,
                  "minz": minz, "maxz": maxz},
        "scale": scale,
        "hint": "px=(wx-minx)*scale ; py=(maxy-wy)*scale",
        "triangles": len(tris),
        "patches_tessellated": n_patch,
        "patches_skipped": sum(1 for s in surfs
                               if drawable(shaders[s["shader"]])
                               and s["numIndexes"] == 0 and s["numVerts"] > 0
                               and not (s["patchWidth"] >= 3 and s["patchHeight"] >= 3
                                        and s["patchWidth"] * s["patchHeight"]
                                        == s["numVerts"])),
    }
    Path(out_json).write_text(json.dumps(meta, indent=2))
    return meta, ents


def find_bsp(mapname, main_dir):
    """Locate <mapname>.bsp across every pk3 in main_dir.

    Two things this has to get right:
      - case: stock Pak5 stores 'maps/DM/mohdm1.bsp' (uppercase DM) while
        community pk3s use lowercase 'maps/dm/...'. cfg map names match
        neither reliably, so compare case-insensitively.
      - load order: MOHAA loads pk3s alphabetically and later wins, so a
        custom pk3 overriding a stock map must take precedence. Scanning in
        sorted order and keeping the LAST hit reproduces that.

    Returns (pk3_path, inner_name) or None.
    """
    import zipfile

    target = mapname.lower()
    if not target.endswith(".bsp"):
        target += ".bsp"
    found = None
    for pk3 in sorted(Path(main_dir).glob("*.pk3")):
        try:
            names = zipfile.ZipFile(pk3).namelist()
        except (zipfile.BadZipFile, OSError):
            continue
        for n in names:
            if n.lower().endswith("/" + target) or n.lower() == target:
                found = (pk3, n)      # keep last = highest load-order priority
    return found


def build(mapname, main_dir, out_dir, size=1024):
    """Render <mapname> to out_dir/<mapname>.png + .json. Returns meta."""
    import zipfile

    # Accept the engine's prefixed form ("dm/mohdm3") as well as a bare stem;
    # assets are always keyed by the stem.
    mapname = mapname.rsplit("/", 1)[-1].lower()
    hit = find_bsp(mapname, main_dir)
    if hit is None:
        raise SystemExit(f"no .bsp found for map {mapname!r} under {main_dir}")
    pk3, inner = hit
    data = zipfile.ZipFile(pk3).read(inner)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    base = out / mapname.lower()
    meta, ents = render(data, str(base) + ".png", str(base) + ".json", size=size)
    meta["map"] = mapname.lower()
    meta["source"] = f"{pk3.name}:{inner}"
    Path(str(base) + ".json").write_text(json.dumps(meta, indent=2))
    return meta, ents


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser(
        description="Render a top-down PNG + world->image transform for MOHAA maps.")
    ap.add_argument("maps", nargs="+", help="map names, e.g. m2l1 mohdm3 (or 'all')")
    ap.add_argument("--main", default=str(Path(__file__).resolve().parent.parent / "main"))
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent.parent
                                         / "dashboard" / "maps"))
    ap.add_argument("--size", type=int, default=1024)
    args = ap.parse_args()

    names = args.maps
    if names == ["all"]:
        import zipfile
        seen = set()
        for pk3 in sorted(Path(args.main).glob("*.pk3")):
            try:
                entries = zipfile.ZipFile(pk3).namelist()
            except (zipfile.BadZipFile, OSError):
                continue
            for n in entries:
                if n.lower().endswith(".bsp"):
                    seen.add(Path(n).stem.lower())
        names = sorted(seen)

    for name in names:
        try:
            meta, ents = build(name, args.main, args.out, size=args.size)
        except SystemExit as exc:
            print(f"{name:24} SKIP  {exc}")
            continue
        except Exception as exc:  # noqa: BLE001 - one bad map must not stop a batch
            print(f"{name:24} FAIL  {type(exc).__name__}: {exc}")
            continue
        spawns = sum(1 for e in ents
                     if e.get("classname", "").startswith("info_player"))
        warn = "  ⚠ patches" if meta.get("patches_skipped", 0) > 0 else ""
        print(f"{name:24} {meta['width']}x{meta['height']}  "
              f"tris={meta['triangles']:<6} spawns={spawns:<4} "
              f"patch={meta['patches_tessellated']} skipped={meta['patches_skipped']}{warn}")
