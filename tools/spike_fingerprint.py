#!/usr/bin/env python3
"""
Spike: identify a MOHAA install from disk alone.

This is Step 1 of the launcher pipeline, prototyped in Python before it gets
rewritten in Rust. It answers, for any folder a player points at:

    Which game is this? Which patch level? Which expansions are present?
    Which maps do they already own?

That last question is the compatibility gate. A server reports "mapname" in its
status response; if the map is absent from this index, the join WILL fail. It is
a reliable negative and an unreliable positive -- a map you own says nothing
about the skins or sounds the server also wants -- so report the negative
confidently and never render the positive as a green tick.

Two things worth knowing about the output:

  * The version corpus starts empty and is grown by running this on known-good
    installs. Nobody has a public sha256 -> version table for MOHAA; building
    one is a prerequisite for "one-click install" and this is how it starts.
  * pk3 files are ZIPs. Map names inside them ("maps/dm/mohdm6.bsp") match the
    format servers report ("dm/mohdm6") after stripping "maps/" and ".bsp".

Usage:
    python3 tools/spike_fingerprint.py /path/to/mohaa
    python3 tools/spike_fingerprint.py /path/to/mohaa --json corpus.json
"""

import argparse
import hashlib
import json
import os
import sys
import zipfile

# Binaries worth fingerprinting, and what their presence implies.
BINARY_HINTS = {
    "mohaa.exe": "Allied Assault (retail)",
    "mohaas.exe": "Spearhead (retail)",
    "mohaab.exe": "Breakthrough (retail)",
    "openmohaa": "OpenMoHAA (client)",
    "openmohaa.exe": "OpenMoHAA (client)",
    "omohaaded": "OpenMoHAA (dedicated server)",
    "omohaaded.exe": "OpenMoHAA (dedicated server)",
    "MOHAA_server.exe": "Allied Assault (dedicated server)",
}

# Expansion detection by data directory. code/gamespy/sv_gamespy.c maps these
# to the gamename a server advertises.
EXPANSION_DIRS = {
    "main": ("mohaa", "Allied Assault"),
    "mainta": ("mohaas", "Spearhead"),
    "maintt": ("mohaab", "Breakthrough"),
}


def sha256(path, chunk=1 << 20):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        while True:
            block = handle.read(chunk)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def find_binaries(root):
    """Hash any recognisable game binary at the top level of the install."""
    found = []
    for entry in sorted(os.listdir(root)):
        full = os.path.join(root, entry)
        if not os.path.isfile(full):
            continue
        hint = BINARY_HINTS.get(entry)
        if hint is None:
            continue
        found.append({
            "file": entry,
            "implies": hint,
            "size": os.path.getsize(full),
            "sha256": sha256(full),
        })
    return found


def find_expansions(root):
    present = []
    for dirname, (gamename, label) in EXPANSION_DIRS.items():
        path = os.path.join(root, dirname)
        if os.path.isdir(path):
            paks = [f for f in os.listdir(path) if f.lower().endswith(".pk3")]
            present.append({
                "dir": dirname,
                "gamename": gamename,
                "label": label,
                "pk3_count": len(paks),
            })
    return present


def index_maps(root):
    """Map name -> the pk3 providing it. This is the compatibility gate's index."""
    index = {}
    broken = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in sorted(filenames):
            if not name.lower().endswith(".pk3"):
                continue
            full = os.path.join(dirpath, name)
            try:
                with zipfile.ZipFile(full) as archive:
                    for member in archive.namelist():
                        lowered = member.lower()
                        if lowered.startswith("maps/") and lowered.endswith(".bsp"):
                            # "maps/dm/mohdm6.bsp" -> "dm/mohdm6", matching
                            # the mapname a server reports.
                            mapname = member[len("maps/"):-len(".bsp")]
                            index.setdefault(mapname.lower(), []).append(
                                os.path.relpath(full, root)
                            )
            except (zipfile.BadZipFile, OSError) as exc:
                broken.append((os.path.relpath(full, root), str(exc)))
    return index, broken


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("root", help="game install directory")
    parser.add_argument("--json", metavar="OUT", help="write the full report as JSON")
    parser.add_argument("--check", metavar="MAPNAME",
                        help="ask whether one map is present, e.g. dm/mohdm6")
    args = parser.parse_args()

    root = os.path.abspath(os.path.expanduser(args.root))
    if not os.path.isdir(root):
        print(f"error: not a directory: {root}")
        return 2

    print(f"scanning {root}\n")

    binaries = find_binaries(root)
    print(f"binaries ({len(binaries)})")
    for item in binaries:
        print(f"  {item['file']:22} {item['implies']}")
        print(f"  {'':22} sha256 {item['sha256'][:32]}...  {item['size']:,} bytes")
    if not binaries:
        print("  none recognised -- add its filename to BINARY_HINTS")

    expansions = find_expansions(root)
    print(f"\nexpansions ({len(expansions)})")
    for item in expansions:
        print(f"  {item['dir']:8} {item['label']:18} gamename={item['gamename']:7} "
              f"{item['pk3_count']} pk3s")
    if not expansions:
        print("  none -- is this really a game directory?")

    index, broken = index_maps(root)
    print(f"\nmaps indexed: {len(index)} across all pk3s")
    for mapname in sorted(index)[:10]:
        sources = index[mapname]
        suffix = f"  (+{len(sources) - 1} more pk3s)" if len(sources) > 1 else ""
        print(f"  {mapname:34} {os.path.basename(sources[0])}{suffix}")
    if len(index) > 10:
        print(f"  ... and {len(index) - 10} more")

    duplicates = {k: v for k, v in index.items() if len(v) > 1}
    if duplicates:
        print(f"\n{len(duplicates)} maps provided by more than one pk3 -- load order decides "
              "which wins, so preserve exact filenames on install")

    if broken:
        print(f"\n{len(broken)} unreadable pk3s")
        for path, err in broken[:5]:
            print(f"  {path}: {err}")

    if args.check:
        wanted = args.check.lower()
        if wanted in index:
            print(f"\n'{args.check}' -> PRESENT via {index[wanted][0]}")
            print("  (reliable positive for the .bsp only; other assets may still be missing)")
        else:
            print(f"\n'{args.check}' -> MISSING. A join to a server on this map will fail.")

    if args.json:
        report = {
            "root": root,
            "binaries": binaries,
            "expansions": expansions,
            "maps": {k: v for k, v in sorted(index.items())},
            "unreadable_pk3s": broken,
        }
        with open(args.json, "w") as handle:
            json.dump(report, handle, indent=2)
        print(f"\nwrote {args.json}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
