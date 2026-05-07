#!/usr/bin/env python3
"""
Parse OpenMoHAA qconsole logs to report map vote statistics.

Tracks which maps were offered, which won, how many votes were cast,
and which maps tended to be ignored (0-0 votes).

Usage:
    python3 map_votes.py ~/.openmohaa/main/qconsole*.log
"""

import re
import sys
from collections import defaultdict
from datetime import datetime

LOG_TS = re.compile(r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC[^\]]+\] (.+)$')
SERVER_LINE = re.compile(r'^Server: (.+)$')
MAP_VOTE_RESULTS = 'MAP VOTE RESULTS:'

# V1 format (early): "[MAP VOTE] 1: mapid vs 2: mapid"  +  results: "mapid: N votes"
V1_OPTIONS = re.compile(r'^\[MAP VOTE\] 1: (.+) vs 2: (.+)$')
V1_RESULT  = re.compile(r'^([a-z0-9/_]+): (\d+) votes$')

# V2 format (current): "[MAP VOTE] 1: Display Name (mapid)"  +  results: "Display Name (mapid): N votes"
V2_OPTION  = re.compile(r'^\[MAP VOTE\] (\d): .+\(([^)]+)\)$')
V2_RESULT  = re.compile(r'^.+\(([^)]+)\): (\d+) votes$')

# V3 format (brief intermediate): "[MAP VOTE] Type 1: Display Name (mapid)"  +  results: "1: Display Name (mapid): N votes"
V3_OPTION  = re.compile(r'^\[MAP VOTE\] Type (\d): .+\(([^)]+)\)$')
V3_RESULT  = re.compile(r'^(\d): .+\(([^)]+)\): (\d+) votes$')


def parse_ts(s):
    return datetime.strptime(s, "%Y-%m-%d %H:%M:%S")


def parse_files(paths):
    """
    Returns a list of vote sessions:
      {'ts', 'map', 'option1', 'option2', 'votes1', 'votes2', 'winner'}
    """
    sessions = []
    current_map = None

    # Rolling state for current vote
    fmt = None           # 'v1', 'v2', 'v3'
    opt = {}             # slot(int) -> mapid
    session_ts = None
    in_results = False
    res = {}             # slot(int or str key) -> votes

    def flush(ts):
        nonlocal fmt, opt, session_ts, in_results, res
        if fmt and len(opt) == 2 and len(res) >= 2:
            opt1 = opt.get(1)
            opt2 = opt.get(2)
            v1, v2 = res.get(1, 0), res.get(2, 0)
            winner = None
            if v1 > v2:
                winner = opt1
            elif v2 > v1:
                winner = opt2
            sessions.append({
                'ts': session_ts or ts,
                'map': current_map,
                'option1': opt1,
                'option2': opt2,
                'votes1': v1,
                'votes2': v2,
                'winner': winner,
                'total_votes': v1 + v2,
            })
        fmt = None
        opt = {}
        session_ts = None
        in_results = False
        res = {}

    for path in paths:
        with open(path, errors='replace') as f:
            for line in f:
                m = LOG_TS.match(line.strip())
                if not m:
                    continue
                ts, raw = parse_ts(m.group(1)), m.group(2)
                body = raw[len('console: '):] if raw.startswith('console: ') else raw

                if (sm := SERVER_LINE.match(body)):
                    flush(ts)
                    current_map = sm.group(1)
                    continue

                if body == MAP_VOTE_RESULTS:
                    in_results = True
                    res = {}
                    continue

                if in_results:
                    # V3 results: "1: Display (mapid): N votes"
                    if (rm := V3_RESULT.match(body)):
                        slot, mapid, votes = int(rm.group(1)), rm.group(2), int(rm.group(3))
                        res[slot] = votes
                        if mapid not in opt.values():
                            opt[slot] = mapid
                        if len(res) == 2:
                            flush(ts)
                        continue
                    # V2 results: "Display (mapid): N votes" — order determines slot
                    if (rm := V2_RESULT.match(body)):
                        mapid, votes = rm.group(1), int(rm.group(2))
                        # assign slot by insertion order
                        slot = len(res) + 1
                        res[slot] = votes
                        if slot not in opt:
                            opt[slot] = mapid
                        if len(res) == 2:
                            flush(ts)
                        continue
                    # V1 results: "mapid: N votes"
                    if (rm := V1_RESULT.match(body)):
                        mapid, votes = rm.group(1), int(rm.group(2))
                        slot = len(res) + 1
                        res[slot] = votes
                        if slot not in opt:
                            opt[slot] = mapid
                        if len(res) == 2:
                            flush(ts)
                        continue
                    # non-result line while in_results — abandon if not blank/noise
                    # (keep in_results=True; next vote or map will reset)

                # Option lines — only outside results phase
                if not in_results:
                    if (om := V3_OPTION.match(body)):
                        slot, mapid = int(om.group(1)), om.group(2)
                        if slot == 1:
                            opt = {1: mapid}
                            session_ts = ts
                            fmt = 'v3'
                        else:
                            opt[slot] = mapid
                        continue
                    if (om := V2_OPTION.match(body)):
                        slot, mapid = int(om.group(1)), om.group(2)
                        if slot == 1:
                            opt = {1: mapid}
                            session_ts = ts
                            fmt = 'v2'
                        else:
                            opt[slot] = mapid
                        continue
                    if (om := V1_OPTIONS.match(body)):
                        opt = {1: om.group(1).strip(), 2: om.group(2).strip()}
                        session_ts = ts
                        fmt = 'v1'
                        continue

    return sessions


def report(sessions):
    if not sessions:
        print("No vote sessions found.")
        return

    total = len(sessions)
    contested = [s for s in sessions if s['total_votes'] > 0]
    uncontested = [s for s in sessions if s['total_votes'] == 0]

    print(f"Total vote sessions: {total}  |  Contested: {len(contested)}  |  No votes: {len(uncontested)}")
    print()

    offered = defaultdict(lambda: {'offered': 0, 'won': 0, 'lost': 0, 'tied': 0, 'votes_for': 0})
    for s in sessions:
        for slot, opt, my_v, opp_v in [
            (1, s['option1'], s['votes1'], s['votes2']),
            (2, s['option2'], s['votes2'], s['votes1']),
        ]:
            if not opt:
                continue
            offered[opt]['offered'] += 1
            offered[opt]['votes_for'] += my_v
            if s['total_votes'] > 0:
                if s['winner'] == opt:
                    offered[opt]['won'] += 1
                elif s['winner'] is None:
                    offered[opt]['tied'] += 1
                else:
                    offered[opt]['lost'] += 1

    rows = []
    for mapid, d in offered.items():
        contested_shown = d['won'] + d['lost'] + d['tied']
        win_rate = 100 * d['won'] / contested_shown if contested_shown else None
        avg_votes = d['votes_for'] / d['offered'] if d['offered'] else 0.0
        rows.append((mapid, d['offered'], d['won'], d['lost'], d['tied'], win_rate, avg_votes))

    # Sort: maps with contested appearances first (by win rate), then uncontested by times offered
    rows.sort(key=lambda r: (-(r[5] if r[5] is not None else -1), -r[1]))

    print(f"{'Map':<32} {'Offered':>7} {'Won':>5} {'Lost':>5} {'Tied':>5} {'Win%':>6} {'AvgVotes':>9}")
    print("-" * 74)
    for mapid, offered_n, won, lost, tied, win_rate, avg_votes in rows:
        win_str = f"{win_rate:5.0f}%" if win_rate is not None else "   n/a"
        print(f"{mapid:<32} {offered_n:>7} {won:>5} {lost:>5} {tied:>5} {win_str} {avg_votes:>8.1f}")

    print()
    print("Win% = among contested sessions only (at least 1 vote cast)")
    print("AvgVotes = average votes received per time offered")

    won_counts = defaultdict(int)
    for s in sessions:
        if s['winner']:
            won_counts[s['winner']] += 1

    if won_counts:
        print()
        print("--- Maps most often voted in ---")
        for mapid, count in sorted(won_counts.items(), key=lambda x: -x[1])[:10]:
            print(f"  {mapid:<32} {count:>3}x")

    if contested:
        print()
        total_votes_cast = sum(s['total_votes'] for s in contested)
        avg_per_session = total_votes_cast / len(contested)
        print(f"Avg votes per contested session: {avg_per_session:.1f}")
        print(f"Total votes cast: {total_votes_cast}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <qconsole*.log ...>")
        sys.exit(1)
    sessions = parse_files(sys.argv[1:])
    report(sessions)
