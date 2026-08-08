# MOHAA dedicated server — common commands
# Run `just` (no args) to list recipes.

log := "~/.openmohaa/main/qconsole.log"
logs_all := "~/.openmohaa/main/qconsole*.log"
dashboard_url := "http://127.0.0.1:8088"
dashboard_screen := "mohaa_dashboard"
dashboard_tunnel_screen := "mohaa_dashboard_tunnel"
watcher := "tools/cheat_watcher.py"
watcher_screen := "mohaa_watcher"
watcher_audit := "~/.openmohaa/main/anticheat/watcher_audit.log"
scrcheck := "tools/scrcheck/scrcheck"

# list available recipes
default:
    @just --list

# show interesting log lines (joins/leaves/chat/aimbot/overflow), minus localhost & vote noise
logs:
    rg "Server:|(#.*entered|disconnected|says|aimbot|overflow)" {{log}} | tail -n 200 | rg -i -v "127.0.0.1|vote|broadcast: print"

# follow the above filter live
logs-follow:
    tail -f {{log}} | rg --line-buffered "Server:|(#.*entered|disconnected|says|aimbot|overflow)" | rg --line-buffered -i -v "127.0.0.1|vote|broadcast: print"

# chat-only feed, minus localhost
chat:
    rg "says" {{log}} | rg -i -v "127.0.0.1|broadcast: print" | tail -n 100

# grep the log for an arbitrary term:  just glog aimbot
glog term:
    rg -i "{{term}}" {{log}} | rg -i -v "broadcast: print" | tail -n 200

# real human connections (Client N + IP), localhost excluded
joins:
    rg "Client \d+ \(IP: " {{log}} | rg -v "127.0.0.1|broadcast: print" | tail -n 40

# unique human IPs seen, by frequency
ips:
    @rg "is connecting" {{log}} | rg -v "127.0.0.1" | rg -oP "IP: \K[0-9.]+" | sort | uniq -c | sort -rn

# frag scoreboard — top killers in the current log
scores:
    @rg -P "was (machine-gunned|perforated|sniped|rifled|blasted|killed) by \K[^'\\[]+?(?='s'| in |$| \\[)" -o {{log}} | sed 's/ *$//' | sort | uniq -c | sort -rn | head -20

# busiest hours — human connection count per hour-of-day
peakhours:
    @rg "is connecting" {{log}} | rg -v "127.0.0.1" | rg -oP "\d{4}-\d\d-\d\d \K\d\d" | sort | uniq -c

# search ALL logs (current + rotated):  just histgrep PlayerName
histgrep term:
    @rg -i "{{term}}" {{logs_all}} | rg -v "broadcast: print" | tail -n 100

# map rotation history (which map loaded, with timestamp, in order)
maps:
    @rg "^\[[^]]+\] Server: \S" {{log}} | tail -n 40

# tail the raw log live, unfiltered
raw:
    tail -f {{log}}

# show the last map load and everything around it
lastmap:
    rg -n "Loading|spawnpoint|gametype|InitGame" {{log}} | tail -n 40

# count chat messages per player
chatstats:
    rg "says" {{log}} | rg -oP '\(\K[^)]+' | sort | uniq -c | sort -rn | head

# anything that looks like a script/engine error
scripterrors:
    rg -i "script|\.scr|exception|null|signal" {{log}} | tail -n 100

# run the read-only local web dashboard for cloudflared/Cloudflare Access
dashboard:
    python3 dashboard/server.py

# start the read-only local web dashboard in a detached screen session
dashboard-start:
    @if screen -S {{dashboard_screen}} -Q select . >/dev/null 2>&1; then echo "screen session already running: {{dashboard_screen}}"; else screen -dmS {{dashboard_screen}} python3 dashboard/server.py; echo "started dashboard in screen session: {{dashboard_screen}}"; fi

# attach to the dashboard server session (detach with Ctrl-A then D)
dashboard-attach:
    screen -r {{dashboard_screen}}

# start the dashboard and cloudflared in detached screen sessions
dashboard-tunnel:
    @just dashboard-start
    @if screen -S {{dashboard_tunnel_screen}} -Q select . >/dev/null 2>&1; then echo "screen session already running: {{dashboard_tunnel_screen}}"; else screen -dmS {{dashboard_tunnel_screen}} cloudflared tunnel --url {{dashboard_url}}; echo "started cloudflared in screen session: {{dashboard_tunnel_screen}}"; fi
    @echo "dashboard local URL: {{dashboard_url}}"
    @echo "attach with: just dashboard-tunnel-attach"

# attach to the dashboard cloudflared session (detach with Ctrl-A then D)
dashboard-tunnel-attach:
    screen -r {{dashboard_tunnel_screen}}

# stop the dashboard and cloudflared screen sessions
dashboard-tunnel-stop:
    @if screen -S {{dashboard_tunnel_screen}} -Q select . >/dev/null 2>&1; then screen -S {{dashboard_tunnel_screen}} -X quit; echo "stopped screen session: {{dashboard_tunnel_screen}}"; else echo "screen session not running: {{dashboard_tunnel_screen}}"; fi
    @if screen -S {{dashboard_screen}} -Q select . >/dev/null 2>&1; then screen -S {{dashboard_screen}} -X quit; echo "stopped screen session: {{dashboard_screen}}"; else echo "screen session not running: {{dashboard_screen}}"; fi

# --- production server (systemd, runs in screen 'mohaa_server' on port 12203) ---

# prod service status
status:
    systemctl status mohaa-server.service --no-pager

# restart prod
restart:
    sudo systemctl restart mohaa-server.service

# stop prod
stop:
    sudo systemctl stop mohaa-server.service

# attach to the live prod console (detach with Ctrl-A then D)
console:
    screen -r mohaa_server

# follow prod logs via journald
journal:
    journalctl -u mohaa-server.service -f

# start a local test server (cheats/developer on, port 12205)
test-server:
    ./omohaaded +set com_target_game 0 +set dedicated 2 +set sv_maxclients 16 +set net_port 12205 +exec server.cfg +set thereisnomonkey 1 +set cheats 1 +set developer 1 +set fs_homedatapath /home/feho/.openmohaa2

# start server #2 with custom maps
start-server2:
    ./omohaaded +set com_target_game 0 +set dedicated 2 +set net_port 12204 +set net_gamespy_port 12301 +exec server2.cfg +set fs_homedatapath /home/feho/.openmohaa2 +set logfile 2

# --- anticheat / cheat watcher (VPN + K/M -> nerf) ---

# run the cheat watcher in DRY-RUN in the foreground (Ctrl-C to stop)
watch:
    python3 {{watcher}}

# run the watcher ARMED in the foreground (will issue real nerfs — be sure first)
watch-arm:
    python3 {{watcher}} --arm

# start the watcher (DRY-RUN) in a detached screen session
watch-start:
    @if screen -S {{watcher_screen}} -Q select . >/dev/null 2>&1; then echo "screen session already running: {{watcher_screen}}"; else screen -dmS {{watcher_screen}} python3 {{watcher}}; echo "started watcher (dry-run) in screen session: {{watcher_screen}}"; fi

# start the watcher ARMED in a detached screen session (issues real nerfs)
watch-start-arm:
    @if screen -S {{watcher_screen}} -Q select . >/dev/null 2>&1; then echo "screen session already running: {{watcher_screen}}"; else screen -dmS {{watcher_screen}} python3 {{watcher}} --arm; echo "started watcher (ARMED) in screen session: {{watcher_screen}}"; fi

# attach to the watcher screen session (detach with Ctrl-A then D)
watch-attach:
    screen -r {{watcher_screen}}

# stop the watcher screen session
watch-stop:
    @if screen -S {{watcher_screen}} -Q select . >/dev/null 2>&1; then screen -S {{watcher_screen}} -X quit; echo "stopped screen session: {{watcher_screen}}"; else echo "screen session not running: {{watcher_screen}}"; fi

# replay the existing log through the watcher (dry-run) and exit — for testing
watch-backfill:
    python3 {{watcher}} --backfill-only

# follow the watcher's decisions (connects, WOULD/NERF, KMFLAG)
watch-audit:
    tail -f {{watcher_audit}}

# K/M observability + flags from the live log: the distribution that sets the threshold
km:
    @rg "\[KM\]|\[KMFLAG\]|\[KMNERF\]" {{log}} | tail -n 60

# all anticheat signal lines (aimbot swings, K/M, accuracy, nerfs)
ac:
    @rg "\[AIMBOT\]|\[KM\]|\[KMFLAG\]|\[KMNERF\]|\[ACCURACY:MG\]" {{log}} | tail -n 80

# --- script syntax check (offline .scr parser built from the engine grammar) ---
#
# GRAMMAR ONLY. This runs the engine's yyparse() but not its codegen stage, so
# it catches typos, unbalanced braces and bad syntax — NOT duplicate labels,
# bad lvalues or illegal break/continue, which the engine only rejects at map
# load. A clean run means "the parser accepts it", not "the map will load".

# grammar-check .scr files:  just scrcheck main/global/feho/squad.scr   (default: all of main/)
scrcheck +files="":
    @just _scrcheck-build
    @if [ -z "{{files}}" ]; then \
        find main -name '*.scr' -not -path '*/disabled_mods/*' -print0 | xargs -0 {{scrcheck}} -q \
            && echo "all $(find main -name '*.scr' -not -path '*/disabled_mods/*' | wc -l) scripts under main/ parse"; \
    else \
        {{scrcheck}} {{files}}; \
    fi

# check only the .scr files you've changed vs git HEAD
scrcheck-changed:
    @just _scrcheck-build
    @changed=$(git diff --name-only HEAD -- '*.scr'; git ls-files --others --exclude-standard -- '*.scr') ; \
    existing=$(echo "$changed" | sort -u | while read -r f; do [ -n "$f" ] && [ -f "$f" ] && echo "$f"; done) ; \
    if [ -z "$existing" ]; then echo "no changed .scr files"; else \
        echo "$existing" | tr '\n' '\0' | xargs -0 {{scrcheck}}; \
    fi

# force a rebuild of the checker (after pulling new openmohaa parser changes)
scrcheck-rebuild:
    @rm -rf tools/scrcheck/.obj {{scrcheck}}
    @just _scrcheck-build
    @echo "rebuilt {{scrcheck}}"

# build the checker only if it's missing (internal)
_scrcheck-build:
    @test -x {{scrcheck}} || ./tools/scrcheck/build.sh

# --- live map (top-down player positions in the browser) ---

# show the current live position snapshot
livemap-peek:
    @cat ~/.openmohaa/main/livemap/positions.txt 2>/dev/null && echo "" || echo "no snapshot yet"

# render map images for the browser view:  just livemap-render m2l1 mohdm3   (or 'all')
livemap-render +maps:
    python3 tools/bspmap.py {{maps}}

# render every map found in main/*.pk3 (slow — patches are tessellated in pure python)
livemap-render-all:
    python3 tools/bspmap.py all

# which maps already have a rendered image
livemap-maps:
    @ls dashboard/maps/*.png 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/.png$//' || echo "none rendered yet"

# is the feed alive? (tick should advance)
livemap-check:
    @python3 -c "import time,pathlib; p=pathlib.Path.home()/'.openmohaa/main/livemap/positions.txt'; a=p.read_text().split('|')[0]; time.sleep(1); b=p.read_text().split('|')[0]; print(f'tick {a} -> {b}', '  LIVE' if b!=a else '  STALLED')"
