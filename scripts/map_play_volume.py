#!/usr/bin/env python3
"""
Map rotation volume: round count and total wall-clock time per map.

Complements map_retention.py (which reports per-player session retention).
This script answers "how often does the rotation pick each map, and how
much real time does the server spend on it?"

Usage:
    python3 map_play_volume.py [logfile ...]
"""

import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

LOG_TS = re.compile(r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC[^\]]+\] (.+)$')
MAP_LINE = re.compile(r'^Server: (.+)$')

DEFAULT_LOG = Path.home() / ".openmohaa/main/qconsole.log"


def collect_rounds(paths):
    """Yield (map_name, start_ts, end_ts) for each round across all logs."""
    boundaries = []  # list of (ts, map_name)
    for path in paths:
        with open(path, errors='replace') as f:
            for line in f:
                m = LOG_TS.match(line.rstrip("\n"))
                if not m:
                    continue
                ts_str, body = m.group(1), m.group(2)
                mm = MAP_LINE.match(body)
                if mm:
                    boundaries.append((datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S"), mm.group(1)))

    boundaries.sort(key=lambda b: b[0])

    for (ts, name), (next_ts, _) in zip(boundaries, boundaries[1:]):
        yield name, ts, next_ts
    # The final round has no terminating boundary — drop it rather than guess.


def report(rounds):
    counts = defaultdict(int)
    total_sec = defaultdict(float)
    durations = defaultdict(list)

    for name, start, end in rounds:
        dur = (end - start).total_seconds()
        if dur <= 0 or dur > 6 * 3600:  # drop log gaps (server downtime between rotations)
            continue
        counts[name] += 1
        total_sec[name] += dur
        durations[name].append(dur)

    grand_total = sum(total_sec.values()) or 1

    rows = []
    for name in counts:
        ds = sorted(durations[name])
        median = ds[len(ds) // 2]
        rows.append((
            name,
            counts[name],
            total_sec[name],
            total_sec[name] / counts[name],
            median,
            100 * total_sec[name] / grand_total,
        ))

    rows.sort(key=lambda r: -r[2])  # by total time desc

    print(f"{'Map':<24} {'Rounds':>7} {'Total':>9} {'Avg':>7} {'Median':>7} {'Share':>7}")
    print("-" * 66)
    for name, n, total, avg, median, share in rows:
        print(f"{name:<24} {n:>7} {total/3600:>7.1f}h {avg/60:>5.1f}m {median/60:>5.1f}m {share:>6.1f}%")

    print()
    print(f"Total rounds: {sum(counts.values())}   Total time: {grand_total/3600:.1f}h")
    print("Rounds > 6h are treated as log gaps (server downtime) and excluded.")


if __name__ == '__main__':
    paths = sys.argv[1:] or [str(DEFAULT_LOG)]
    report(collect_rounds(paths))
