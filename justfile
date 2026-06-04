# MOHAA dedicated server — common commands
# Run `just` (no args) to list recipes.

log := "~/.openmohaa/main/qconsole.log"

# list available recipes
default:
    @just --list

# show interesting log lines (joins/leaves/chat/aimbot/overflow), minus localhost & vote noise
logs:
    rg "Server:|(#.*entered|disconnected|says|aimbot|overflow)" {{log}} | tail -n 200 | rg -i -v "127.0.0.1|vote"

# follow the above filter live
logs-follow:
    tail -f {{log}} | rg --line-buffered "Server:|(#.*entered|disconnected|says|aimbot|overflow)" | rg --line-buffered -i -v "127.0.0.1|vote"

# start a local test server (cheats/developer on, port 12204)
test-server:
    ./omohaaded +set com_target_game 0 +set dedicated 2 +set sv_maxclients 16 +set net_port 12204 +exec server.cfg +set thereisnomonkey 1 +set cheats 1 +set developer 1
