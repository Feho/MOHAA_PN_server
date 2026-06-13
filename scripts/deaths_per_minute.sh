#!/usr/bin/env bash
# Compute average deaths/minute from the OpenMoHAA qconsole.log.
# Death lines match either "<name> died" or "<name> was <verb> by <killer>".
set -eu

LOG="${1:-$HOME/.openmohaa/main/qconsole.log}"

if [[ ! -f "$LOG" ]]; then
  echo "log not found: $LOG" >&2
  exit 1
fi

# Pull first and last timestamps via grep, then count deaths via grep -cE.
first_ts=$(grep -oE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOG" | head -1 | tr -d '[')
last_ts=$( grep -oE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOG" | tail -1 | tr -d '[')

if [[ -z "$first_ts" || -z "$last_ts" ]]; then
  echo "no timestamps found in log" >&2
  exit 1
fi

first_epoch=$(date -d "$first_ts" +%s)
last_epoch=$( date -d "$last_ts"  +%s)
span_sec=$(( last_epoch - first_epoch ))

if (( span_sec <= 0 )); then
  echo "log spans zero time" >&2
  exit 1
fi

# Death matchers: " died" at end of line, or " was <something> by " mid-line.
# Count total deaths and tally distinct active minutes (minutes with >=1 death).
read deaths active_min <<<"$(
  awk '
    / died$/ || / was [^ ]+([- ][^ ]+)* by / {
      # timestamp prefix is "[YYYY-MM-DD HH:MM:" up to 18 chars — use that as the minute key.
      key = substr($0, 2, 17)
      if (!(key in seen)) { seen[key] = 1; active++ }
      deaths++
    }
    END { printf "%d %d\n", deaths, active }
  ' "$LOG"
)"

awk -v d="$deaths" -v a="$active_min" -v s="$span_sec" -v ft="$first_ts" -v lt="$last_ts" 'BEGIN {
  span_min = s / 60.0
  printf "first event       : %s\n", ft
  printf "last event        : %s\n", lt
  printf "deaths            : %d\n", d
  printf "wall-clock span   : %.1f minutes (%.2f hours)\n", span_min, span_min/60
  printf "active minutes    : %d (minutes with >=1 death)\n", a
  printf "deaths/min (wall) : %.3f\n", d / span_min
  if (a > 0) {
    printf "deaths/min (live) : %.3f\n", d / a
    printf "deaths/hour (live): %.2f\n", d / a * 60
  }
}'
