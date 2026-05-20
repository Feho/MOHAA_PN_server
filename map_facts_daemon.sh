#!/bin/bash
# Watches qconsole.log for map starts, then 12 minutes in generates 2 witty
# facts from that map's kill data and writes them to map_facts.txt.
# messages.scr reads the file at ~13 minutes and broadcasts the facts.
#
# Run as a systemd service alongside mohaa-server.service.

LOG_FILE="/home/feho/.openmohaa/main/qconsole.log"
SERVER_CFG="/home/feho/MOHAA/main/server.cfg"
OUTPUT_FILE="/home/feho/MOHAA/main/configs/map_facts.txt"
CLAUDE_BIN="/home/feho/.local/bin/claude"
DELAY=720  # 12 minutes

# Wait for the log file to exist (server may not have started yet)
while [ ! -f "$LOG_FILE" ]; do
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] daemon started, watching $LOG_FILE"

# Extract bot names from server.cfg into a Python set
get_bots_py() {
    python3 -c "
import re
bots = set()
with open('$SERVER_CFG', encoding='latin-1') as f:
    for line in f:
        m = re.search(r'_name\s+\"([^\"]+)\"', line)
        if m:
            bots.add(m.group(1))
print(repr(bots))
"
}

is_claude_limit_line() {
    local line="${1,,}"
    [[ "$line" == *"hit your limit"* && "$line" == *"resets"* ]]
}

clear_output_file() {
    rm -f "$OUTPUT_FILE"
}

sanitize_fact() {
    local fact="$1"
    fact="${fact//—/-}"
    fact="${fact//–/-}"
    fact="${fact//“/\"}"
    fact="${fact//”/\"}"
    fact="${fact//‘/\'}"
    fact="${fact//’/\'}"
    fact="${fact//…/...}"
    fact="${fact//•/-}"
    fact=$(printf '%s' "$fact" | LC_ALL=C tr -cd '\11\12\15\40-\176')
    printf '%s' "$fact"
}

handle_map_start() {
    local map_start_time="$1"
    local map_name="$2"
    local map_start_offset="$3"

    clear_output_file
    echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] map $map_name started at $map_start_time, offset $map_start_offset, sleeping ${DELAY}s"
    sleep "$DELAY"

    echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] extracting context since $map_start_time"

    local bots_py
    bots_py=$(get_bots_py)

    local context
    context=$(python3 - <<PYEOF
import os
import re
from datetime import datetime
from collections import Counter, defaultdict

bots = $bots_py
map_start = "$map_start_time"
map_name = "$map_name"
map_start_offset = int("$map_start_offset")

ts_line_re = re.compile(r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC.*?\] (?:\{#\d+ \| ([^}]+)\} )?(.*)$')
segment = []

try:
    log_size = os.path.getsize("$LOG_FILE")
except OSError:
    print("NO_CONTEXT")
    raise SystemExit

if map_start_offset > log_size:
    map_start_offset = 0

with open("$LOG_FILE", "rb") as f:
    f.seek(map_start_offset)
    data = f.read().decode("latin-1")

for line in data.splitlines():
    # Stop at next map start if this handler outlives a map transition.
    if "Server: " in line and "==== InitGame ====" not in line:
        ts_m = re.search(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
        if ts_m and ts_m.group(1) > map_start:
            break

    segment.append(line.strip())

def split_line(raw):
    m = ts_line_re.match(raw)
    if not m:
        return None, None, raw
    return m.group(1), m.group(2), m.group(3)

def ip_host(ip_port):
    if not ip_port:
        return ""
    return ip_port.split(":", 1)[0]

def subject_from_text(text):
    patterns = [
        r'(.+?) is preparing for deployment$',
        r'(.+?) has entered the battle$',
        r'(.+?) has joined the (?:Axis|Allies)$',
        r'(.+?) has left the battle$',
        r'(.+?) (?:says|shouts) @[^:]+:',
        r'(.+?) was ',
        r'(.+?) tripped on ',
        r'(.+?) is picking ',
        r'(.+?) (?:blew himself up|blew up|died|played catch with himself|took himself out of commision)$',
    ]
    for pattern in patterns:
        m = re.match(pattern, text)
        if m:
            return m.group(1)
    return None

human_names = set()
local_fake_names = set()
last_ts = map_start

for raw in segment:
    ts, ip_port, text = split_line(raw)
    if ts:
        last_ts = ts
    if not ip_port:
        continue

    subject = subject_from_text(text)
    if not subject:
        continue

    if ip_host(ip_port).startswith("127."):
        local_fake_names.add(subject)
    else:
        human_names.add(subject)

bots.update(local_fake_names)

if not human_names:
    print("NO_HUMANS")
    raise SystemExit

def parse_event(text):
    m = re.match(r"(.+?) was perforated by (.+?)'s'? SMG(?: in the (.+))?$", text)
    if m:
        hit = m.group(3) or ""
        return {"victim": m.group(1), "killer": m.group(2), "weapon": "SMG", "hit": hit, "kind": "kill"}

    m = re.match(r"(.+?) was (sniped|rifled|machine-gunned|killed) by (.+)$", text)
    if m:
        weapon = {
            "sniped": "sniper",
            "rifled": "rifle",
            "machine-gunned": "machine gun",
            "killed": "kill",
        }[m.group(2)]
        return {"victim": m.group(1), "killer": m.group(3), "weapon": weapon, "hit": "", "kind": "kill"}

    m = re.match(r"(.+?) was pumped full of buckshot by (.+)$", text)
    if m:
        return {"victim": m.group(1), "killer": m.group(2), "weapon": "shotgun", "hit": "", "kind": "kill"}

    m = re.match(r"(.+?) tripped on (.+?)'s grenade$", text)
    if m:
        return {"victim": m.group(1), "killer": m.group(2), "weapon": "grenade", "hit": "", "kind": "weird"}

    m = re.match(r"(.+?) is picking (.+?)'s shrapnel out of his teeth$", text)
    if m:
        return {"victim": m.group(1), "killer": m.group(2), "weapon": "grenade", "hit": "", "kind": "weird"}

    m = re.match(r"(.+?) (blew himself up|blew up|died|played catch with himself|took himself out of commision)$", text)
    if m:
        return {"victim": m.group(1), "killer": None, "weapon": "self", "hit": "", "kind": "weird"}

    return None

def is_human_name(name):
    return name in human_names

def ts_seconds(ts):
    if not ts:
        return None
    try:
        return int(datetime.strptime(ts, "%Y-%m-%d %H:%M:%S").timestamp())
    except ValueError:
        return None

events = []
chat_lines = []

for raw in segment:
    ts, ip_port, text = split_line(raw)

    chat = re.match(r"(.+?) (says|shouts) @([^:]+): (.+)$", text)
    if chat:
        speaker = chat.group(1)
        if is_human_name(speaker):
            chat_lines.append({
                "speaker": speaker,
                "target": chat.group(3),
                "message": chat.group(4),
                "seconds": ts_seconds(ts),
            })
        continue

    event = parse_event(text)
    if not event:
        continue

    victim = event["victim"]
    killer = event["killer"]

    if killer and victim in bots and killer in bots:
        continue
    if victim in bots and not killer:
        continue
    if not (is_human_name(victim) or (killer and is_human_name(killer))):
        continue

    event["ts"] = ts or ""
    event["seconds"] = ts_seconds(ts)
    event["seq"] = len(events)
    event["text"] = text
    events.append(event)

if not events and not chat_lines:
    print("NO_CONTEXT")
    raise SystemExit

killers = Counter(e["killer"] for e in events if e["killer"])
victims = Counter(e["victim"] for e in events)
weapons = Counter(e["weapon"] for e in events)
pairs = Counter((e["killer"], e["victim"]) for e in events if e["killer"])

moments = []

def player_label(name):
    return "human" if is_human_name(name) else "bot"

def add_moment(score, kind, text, players):
    human_bonus = 4 if any(is_human_name(p) for p in players if p) else 0
    moments.append({
        "score": score + human_bonus,
        "kind": kind,
        "text": text,
        "players": tuple(p for p in players if p),
    })

# Dominant pairings and rivalries.
for (killer, victim), count in pairs.items():
    if count >= 3 and (is_human_name(killer) or is_human_name(victim)):
        add_moment(
            8 + count,
            "domination",
            f"{killer} killed {victim} {count} times ({player_label(killer)} vs {player_label(victim)}).",
            (killer, victim),
        )

# Revenge: a player gets killed, then kills that same opponent soon after.
last_pair_event = {}
seen_revenge_pairs = set()
for e in events:
    killer = e["killer"]
    victim = e["victim"]
    if not killer:
        continue
    reverse = (victim, killer)
    previous = last_pair_event.get(reverse)
    if previous:
        revenge_key = frozenset((killer, victim))
        elapsed = None
        if e["seconds"] is not None and previous["seconds"] is not None:
            elapsed = e["seconds"] - previous["seconds"]
        if revenge_key not in seen_revenge_pairs and (elapsed is None or 0 <= elapsed <= 120):
            seen_revenge_pairs.add(revenge_key)
            timing = f" after {elapsed}s" if elapsed is not None else ""
            add_moment(
                9,
                "revenge",
                f"{killer} got revenge on {victim}{timing}.",
                (killer, victim),
            )
    last_pair_event[(killer, victim)] = e

# Kill streaks without dying, plus shutdowns when another player ends them.
active_streaks = defaultdict(lambda: {"count": 0, "weapons": Counter(), "start": None})
finished_streaks = []
for e in events:
    victim = e["victim"]
    killer = e["killer"]

    if victim in active_streaks and active_streaks[victim]["count"] >= 4:
        streak = active_streaks[victim]
        finished_streaks.append((victim, streak["count"], streak["weapons"].copy(), killer, e))
        if killer:
            add_moment(
                10 + streak["count"],
                "shutdown",
                f"{killer} ended {victim}'s {streak['count']}-kill streak.",
                (killer, victim),
            )
    active_streaks.pop(victim, None)

    if killer:
        streak = active_streaks[killer]
        streak["count"] += 1
        streak["weapons"][e["weapon"]] += 1
        if streak["start"] is None:
            streak["start"] = e

for killer, streak in active_streaks.items():
    if streak["count"] >= 4:
        finished_streaks.append((killer, streak["count"], streak["weapons"].copy(), None, None))

for killer, count, weapon_counts, ended_by, _ in finished_streaks:
    weapon = weapon_counts.most_common(1)[0][0] if weapon_counts else "weapon"
    add_moment(
        9 + count,
        "streak",
        f"{killer} built a {count}-kill streak, mostly with {weapon}.",
        (killer, ended_by),
    )

# Weapon obsessions for humans.
human_kills_by_weapon = defaultdict(Counter)
for e in events:
    killer = e["killer"]
    if killer and is_human_name(killer):
        human_kills_by_weapon[killer][e["weapon"]] += 1

for player, counts in human_kills_by_weapon.items():
    weapon, count = counts.most_common(1)[0]
    total = sum(counts.values())
    if count >= 5 and count / total >= 0.6:
        add_moment(
            7 + count,
            "weapon",
            f"{player} leaned hard on {weapon}: {count} of {total} kills.",
            (player,),
        )

# Weird deaths and headshot chains are usually better joke material than plain kills.
for e in events:
    if e["kind"] == "weird" and (is_human_name(e["victim"]) or (e["killer"] and is_human_name(e["killer"]))):
        add_moment(10, "weird death", e["text"] + ".", (e["victim"], e["killer"]))

headshot_counts = Counter(e["killer"] for e in events if e["killer"] and e["hit"] == "head")
for killer, count in headshot_counts.items():
    if count >= 3 and is_human_name(killer):
        add_moment(8 + count, "headshots", f"{killer} landed {count} SMG headshots.", (killer,))

# Chat karma: human taunts followed by their death shortly after.
for chat in chat_lines:
    speaker = chat["speaker"]
    if not is_human_name(speaker) or chat["seconds"] is None:
        continue
    for e in events:
        if e["victim"] != speaker or e["seconds"] is None:
            continue
        elapsed = e["seconds"] - chat["seconds"]
        if 0 <= elapsed <= 45:
            add_moment(
                11,
                "chat karma",
                f"{speaker} said \"{chat['message']}\" and died {elapsed}s later.",
                (speaker, e["killer"]),
            )
            break

# Human stat lines can be good when they are extreme.
human_kills = Counter(e["killer"] for e in events if e["killer"] and is_human_name(e["killer"]))
human_deaths = Counter(e["victim"] for e in events if is_human_name(e["victim"]))
for player in human_names:
    kills = human_kills[player]
    deaths = human_deaths[player]
    if kills >= 10 or deaths >= 8:
        add_moment(
            6 + max(kills, deaths),
            "stat line",
            f"{player} finished this window with {kills} kills and {deaths} deaths.",
            (player,),
        )

def moment_sort_key(moment):
    human_count = sum(1 for p in moment["players"] if is_human_name(p))
    return (moment["score"], human_count, len(moment["players"]))

seen_moments = set()
notable_moments = []
kind_counts = Counter()
player_counts = Counter()
kind_limits = {
    "weapon": 1,
    "stat line": 2,
    "streak": 2,
    "shutdown": 2,
    "domination": 3,
    "revenge": 2,
    "weird death": 2,
    "headshots": 1,
    "chat karma": 2,
}
for moment in sorted(moments, key=moment_sort_key, reverse=True):
    key = (moment["kind"], moment["text"])
    if key in seen_moments:
        continue
    if kind_counts[moment["kind"]] >= kind_limits.get(moment["kind"], 2):
        continue
    primary_players = [p for p in moment["players"] if is_human_name(p)] or list(moment["players"][:1])
    if primary_players and any(player_counts[p] >= 5 for p in primary_players):
        continue
    seen_moments.add(key)
    notable_moments.append(moment)
    kind_counts[moment["kind"]] += 1
    for player in primary_players:
        player_counts[player] += 1
    if len(notable_moments) >= 8:
        break

for required_kind in ("weird death", "chat karma"):
    if any(m["kind"] == required_kind for m in notable_moments):
        continue
    candidate = next((m for m in sorted(moments, key=moment_sort_key, reverse=True) if m["kind"] == required_kind), None)
    if not candidate:
        continue
    if len(notable_moments) >= 8:
        replace_index = None
        for i in range(len(notable_moments) - 1, -1, -1):
            if notable_moments[i]["kind"] not in ("weird death", "chat karma"):
                replace_index = i
                break
        if replace_index is not None:
            notable_moments[replace_index] = candidate
    else:
        notable_moments.append(candidate)

if len(events) < 5 and not notable_moments:
    print("NO_CONTEXT")
    raise SystemExit

def top_items(counter, limit=4):
    return ", ".join(f"{name} {count}" for name, count in counter.most_common(limit))

def top_pairs(counter, limit=4):
    return ", ".join(f"{killer} killed {victim} {count}x" for (killer, victim), count in counter.most_common(limit))

weird = [e["text"] for e in events if e["kind"] == "weird"][:5]
headshots = [e["text"] for e in events if e["hit"] == "head"][:5]
recent = [e["text"] for e in events[-12:]]

print(f"Map: {map_name}")
print(f"Window: {map_start} to {last_ts}")
print("Real humans seen: " + ", ".join(sorted(human_names)))
print(f"Human-related combat events: {len(events)}")
if notable_moments:
    print("Notable moments:")
    for i, moment in enumerate(notable_moments, 1):
        print(f"{i}. [{moment['kind']}] {moment['text']}")
if killers:
    print("Top killers: " + top_items(killers))
if victims:
    print("Top victims: " + top_items(victims))
if weapons:
    print("Weapons: " + top_items(weapons))
if pairs:
    print("Rivalries: " + top_pairs(pairs))
if headshots:
    print("Headshots: " + " | ".join(headshots))
if weird:
    print("Weird deaths: " + " | ".join(weird))
if chat_lines:
    print("Chat and taunts: " + " | ".join(f"{c['speaker']} @{c['target']}: {c['message']}" for c in chat_lines[-5:]))
if recent:
    print("Recent human-related combat:")
    for line in recent:
        print("- " + line)
PYEOF
)

    if [ -z "$context" ] || [ "$context" = "NO_HUMANS" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] no real human players found, skipping"
        return
    fi

    if [ "$context" = "NO_CONTEXT" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] no human-related context found, skipping"
        return
    fi

    local prompt="You are a witty WWII battle commentator for an online game server. Below is ranked context from the current map on a Medal of Honor: Allied Assault server.

Write exactly 2 short funny observations about specific players. Rules:
- Output ONLY the 2 lines, nothing else - no intro, no numbering, no bullet points, no blank lines
- Max 100 characters per line (displayed in-game chat)
- Use the Notable moments first; they are ranked by quality
- Make the 2 lines about different moments and avoid repeating the same joke structure
- Prefer one achievement/streak/rivalry line and one mishap/taunt/bad-luck line when possible
- Be playful, not mean; joke about events, weapons, timing, or bad luck
- Do not mock skill, nationality, language, or real-world identity
- Focus on real humans first, but mention bots when they are part of the joke
- Prefer simple sentences that even non-native English speakers can understand
- Avoid em dashes

Map context:
$context"

    local claude_lines=()
    mapfile -t claude_lines < <(echo "$prompt" | "$CLAUDE_BIN" --model haiku -p | grep -v '^[[:space:]]*$')

    local facts=()
    local claude_limit_seen=0
    local line
    for line in "${claude_lines[@]}"; do
        if is_claude_limit_line "$line"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] Claude limit message received, skipping line"
            claude_limit_seen=1
            continue
        fi

        facts+=("$line")
        if [ ${#facts[@]} -eq 2 ]; then
            break
        fi
    done

    if [ "$claude_limit_seen" -eq 1 ]; then
        clear_output_file
        echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] removed $OUTPUT_FILE after Claude limit"
        return
    fi

    if [ ${#facts[@]} -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] Claude returned no output, skipping"
        return
    fi

    local tmp_file
    tmp_file="${OUTPUT_FILE}.$$"

    {
        echo "local.a = makeArray"
        for fact in "${facts[@]}"; do
            fact=$(sanitize_fact "$fact")
            fact="${fact//\"/\'}"
            echo "    \"${fact}\""
        done
        echo "endArray"
        echo "end local.a"
    } > "$tmp_file"
    mv "$tmp_file" "$OUTPUT_FILE"

    echo "$(date '+%Y-%m-%d %H:%M:%S') [map_facts] wrote ${#facts[@]} facts to $OUTPUT_FILE"
}

# Main loop: watch for map starts
tail -F "$LOG_FILE" | while read -r line; do
    if [[ "$line" == *"Server: "* ]]; then
        # Extract timestamp from log line: [2026-05-05 14:07:03 UTC...]
        if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
            ts="${BASH_REMATCH[1]}"
        else
            continue
        fi

        if [[ "$line" =~ Server:\ ([^[:space:]]+) ]]; then
            map_name="${BASH_REMATCH[1]}"
        else
            continue
        fi

        map_start_offset=$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)

        # Kill any previous pending handle_map_start and start fresh
        kill "$last_pid" 2>/dev/null
        handle_map_start "$ts" "$map_name" "$map_start_offset" &
        last_pid=$!
    fi
done
