# MOHAA dedicated server — common commands
# Run `just` (no args) to list recipes.

log := "~/.openmohaa/main/qconsole.log"
logs_all := "~/.openmohaa/main/qconsole*.log"

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

# start a local test server (cheats/developer on, port 12204)
test-server:
    ./omohaaded +set com_target_game 0 +set dedicated 2 +set sv_maxclients 16 +set net_port 12204 +exec server.cfg +set thereisnomonkey 1 +set cheats 1 +set developer 1
