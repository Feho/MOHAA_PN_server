#!/usr/bin/env bash
# Top 15 players ordered by total play time.
#
# Session start: "<name> has joined the Allies/Axis"
# Session end  : 'broadcast: print "<name> disconnected\n"' or '"... timed out\n"'
# Notes:
#   - Team switches re-fire "has joined"; we keep the original session start.
#   - Sessions still open at end-of-log are closed at the last log timestamp.
#   - Bots (names matching ^bot[0-9]+$) are excluded.
set -eu

LOG="${1:-$HOME/.openmohaa/main/qconsole.log}"

if [[ ! -f "$LOG" ]]; then
  echo "log not found: $LOG" >&2
  exit 1
fi

awk '
  function ts_epoch(s,   y, mo, d, h, mi, se) {
    # s = "YYYY-MM-DD HH:MM:SS"
    y  = substr(s, 1, 4)  + 0
    mo = substr(s, 6, 2)  + 0
    d  = substr(s, 9, 2)  + 0
    h  = substr(s,12, 2)  + 0
    mi = substr(s,15, 2)  + 0
    se = substr(s,18, 2)  + 0
    # mawk lacks mktime; use a fixed epoch (Unix days since 1970) for the date,
    # which is fine because we only need DIFFERENCES, not absolute Unix time.
    # Days from year 1970-01-01 to (y, mo, d) using Zeller-friendly cumulative days.
    return days_from_epoch(y, mo, d) * 86400 + h*3600 + mi*60 + se
  }
  function is_leap(y) {
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)
  }
  function days_from_epoch(y, mo, d,    i, total, ml) {
    split("31 28 31 30 31 30 31 31 30 31 30 31", ml, " ")
    total = 0
    for (i = 1970; i < y; i++) total += is_leap(i) ? 366 : 365
    if (is_leap(y)) ml[2] = 29
    for (i = 1; i < mo; i++) total += ml[i]
    total += d - 1
    return total
  }

  {
    # Every line starts with "[YYYY-MM-DD HH:MM:SS"
    if (substr($0, 1, 1) != "[") next
    tstr = substr($0, 2, 19)
    if (substr(tstr, 5, 1) != "-") next
    now = ts_epoch(tstr)
    if (last_ts < now) last_ts = now

    rest = $0
    sub(/^\[[^]]+\] /, "", rest)
    # Real players always carry a {#N | ip:port} prefix on their join lines;
    # AI personas (bot scripts spawning with human names) never do.
    has_client_tag = (rest ~ /^\{#[0-9]+ \| [^}]+\} /)
    sub(/^\{#[0-9]+ \| [^}]+\} /, "", rest)

    # --- Join (only count real-client joins; ignore AI persona joins) ---
    if (has_client_tag && match(rest, / has joined the (Allies|Axis|Spectator)$/)) {
      name = substr(rest, 1, RSTART - 1)
      if (name ~ /^bot[0-9]+$/) next
      if (!(name in active)) {
        active[name] = now
      }
      next
    }

    # --- Leave: broadcast: print "<name> disconnected\n"
    #             broadcast: print "<name> timed out\n"
    if (rest ~ /^broadcast: print ".+ (disconnected|timed out)\\n"$/) {
      # Strip prefix up through the opening quote, then trailing chunk.
      payload = rest
      sub(/^broadcast: print "/, "", payload)
      sub(/\\n"$/, "", payload)
      # payload is now "<name> disconnected" or "<name> timed out"
      if (sub(/ disconnected$/, "", payload) || sub(/ timed out$/, "", payload)) {
        name = payload
        if (name ~ /^bot[0-9]+$/) next
        if (name in active) {
          total[name] += now - active[name]
          delete active[name]
          sessions[name]++
        }
      }
      next
    }
  }
  END {
    # Sessions still open at end-of-log are dropped (no explicit disconnect).

    n = 0
    for (name in total) {
      n++
      names[n] = name
      times[n] = total[name]
    }

    # Sort by playtime desc (simple insertion sort — n is small)
    for (i = 2; i <= n; i++) {
      kt = times[i]; kn = names[i]; j = i - 1
      while (j >= 1 && times[j] < kt) {
        times[j+1] = times[j]; names[j+1] = names[j]; j--
      }
      times[j+1] = kt; names[j+1] = kn
    }

    printf "%-4s %-32s %10s %10s %8s\n", "#", "player", "playtime", "h:mm:ss", "sessions"
    printf "%-4s %-32s %10s %10s %8s\n", "----", "--------------------------------", "----------", "----------", "--------"
    limit = (n < 15) ? n : 15
    for (i = 1; i <= limit; i++) {
      secs = times[i]
      hh = int(secs / 3600)
      mm = int((secs % 3600) / 60)
      ss = secs % 60
      printf "%-4d %-32s %7d min %4d:%02d:%02d %8d\n", i, names[i], int(secs/60), hh, mm, ss, sessions[names[i]]
    }
  }
' "$LOG"
