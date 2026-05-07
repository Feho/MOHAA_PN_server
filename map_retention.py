#!/usr/bin/env python3
"""
Parse OpenMoHAA qconsole logs to report which maps cause human players to leave early.

Usage:
    python3 map_retention.py ~/.openmohaa/main/qconsole*.log
"""

import re
import sys
from collections import defaultdict
from datetime import datetime

LOG_TS = re.compile(r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC[^\]]+\] (.+)$')
MAP_LINE = re.compile(r'^Server: (.+)$')
ENTER = re.compile(r'^\{#\d+ \| [^}]+\} (.+) has entered the battle$')
LEAVE = re.compile(r'^broadcast: print "(.+) disconnected\\n"$')


def parse_ts(s):
    return datetime.strptime(s, "%Y-%m-%d %H:%M:%S")


def parse_files(paths):
    events = []
    for path in paths:
        with open(path, errors='replace') as f:
            for line in f:
                m = LOG_TS.match(line.strip())
                if not m:
                    continue
                ts, body = parse_ts(m.group(1)), m.group(2)
                if MAP_LINE.match(body):
                    events.append((ts, 'map', MAP_LINE.match(body).group(1)))
                elif ENTER.match(body):
                    name = ENTER.match(body).group(1)
                    if 'Feho' not in name:
                        events.append((ts, 'enter', name))
                elif LEAVE.match(body):
                    name = LEAVE.match(body).group(1)
                    if 'Feho' not in name:
                        events.append((ts, 'leave', name))
    events.sort(key=lambda e: e[0])
    return events


def analyze(events):
    # Per map: list of (time_on_map_seconds, stayed_to_end: bool) per human session
    map_sessions = defaultdict(list)

    current_map = None
    current_sessions = []
    # player -> join time on current map
    online = {}

    for ts, kind, name in events:
        if kind == 'map':
            # Close out all still-online players as "stayed to end"
            if current_map:
                for player, join_ts in online.items():
                    duration = (ts - join_ts).total_seconds()
                    current_sessions.append((duration, True))
                map_sessions[current_map].extend(current_sessions)
            online = {}
            current_sessions = []
            current_map = name
        elif kind == 'enter':
            online[name] = ts
        elif kind == 'leave':
            if name in online and current_map:
                duration = (ts - online.pop(name)).total_seconds()
                current_sessions.append((duration, False))

    return map_sessions


def report(map_sessions):
    print(f"{'Map':<22} {'Sessions':>8} {'Dropped':>8} {'Drop%':>7} {'Avg time':>10} {'Median':>8}")
    print("-" * 68)

    rows = []
    for map_name, sessions in map_sessions.items():
        human = [(d, stayed) for d, stayed in sessions]
        if not human:
            continue
        dropped = [d for d, stayed in human if not stayed]
        total = len(human)
        n_dropped = len(dropped)
        drop_pct = 100 * n_dropped / total if total else 0
        avg = sum(d for d, _ in human) / total
        sorted_d = sorted(d for d, _ in human)
        median = sorted_d[len(sorted_d) // 2]
        rows.append((map_name, total, n_dropped, drop_pct, avg, median))

    rows.sort(key=lambda r: -r[3])  # sort by drop %

    for map_name, total, n_dropped, drop_pct, avg, median in rows:
        print(f"{map_name:<22} {total:>8} {n_dropped:>8} {drop_pct:>6.0f}% {avg/60:>8.1f}m {median/60:>6.1f}m")

    print()
    print("Drop% = % of human sessions that ended mid-map (disconnected before map change)")
    print("Avg/Median = time spent on map before leaving or map ending")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <qconsole*.log ...>")
        sys.exit(1)
    events = parse_files(sys.argv[1:])
    sessions = analyze(events)
    report(sessions)
