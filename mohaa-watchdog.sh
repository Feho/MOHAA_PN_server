#!/bin/bash
# Staleness watchdog for the MOHAA dedicated server.
#
# systemd's Restart=always only catches a CRASH (process exit). It cannot detect
# a HANG: omohaaded can spin in a busy-loop (e.g. a never-terminating collision
# trace in MOD_matches/SV_Trace) while the process stays alive and systemd keeps
# reporting active(running). See plans/hang-2026-06-16.md.
#
# This watchdog treats a stale qconsole.log as the liveness signal: a running
# server writes to the log continuously (kills, connects, map changes, hitch
# warnings). If the log has not been touched for STALE_SECS while the service is
# active, we restart it.

set -u

LOG=/home/feho/.openmohaa/main/qconsole.log
SERVICE=mohaa-server.service
STALE_SECS=${STALE_SECS:-300}   # 5 min; real hang was stale ~6300s, normal gaps are seconds
CAPTURE_DIR=${CAPTURE_DIR:-/home/feho/MOHAA/hang-captures}

log() { echo "mohaa-watchdog: $*"; }

# Only act when systemd thinks the server is up. During its own restart window
# (Restart=always + RestartSec) the service is not active, so we stay out of the way.
if ! systemctl is-active --quiet "$SERVICE"; then
    log "$SERVICE not active; nothing to do."
    exit 0
fi

if [[ ! -f "$LOG" ]]; then
    log "log $LOG missing while service active; not restarting (likely just (re)starting)."
    exit 0
fi

now=$(date +%s)
mtime=$(stat -c %Y "$LOG")
age=$(( now - mtime ))

if (( age >= STALE_SECS )); then
    log "log stale ${age}s (>= ${STALE_SECS}s) while $SERVICE active -> capturing forensics then restarting (suspected hang)."

    # Capture forensics BEFORE the restart kills the evidence. The 2026-06-16 hang
    # could not be diagnosed past "spinning in engine collision trace" because gdb's
    # auto-unwind failed across the engine<->game.so boundary on aarch64. A raw stack
    # dump + a full core let us recover the real game.so return address offline.
    PID=$(pgrep -f 'MOHAA omohaaded' | head -1)
    if [[ -n "$PID" ]]; then
        ts=$(date +%Y%m%d_%H%M%S)
        outdir="$CAPTURE_DIR/hang_$ts"
        mkdir -p "$outdir"
        log "capturing pid $PID -> $outdir"

        # Lightweight, always: registers + raw stack of the (single) thread. The raw
        # stack lets manual unwinding when gdb's bt is corrupt.
        timeout 60 gdb -p "$PID" -batch \
            -ex "set pagination off" \
            -ex "thread apply all bt" \
            -ex "info registers" \
            -ex "info sharedlibrary" \
            -ex "x/512xg \$sp" \
            -ex "detach" >"$outdir/gdb.txt" 2>&1

        # /proc snapshot (maps lets us turn raw addresses into module+offset offline).
        cat "/proc/$PID/maps"   >"$outdir/maps"   2>/dev/null
        cat "/proc/$PID/status" >"$outdir/status" 2>/dev/null

        # Full core if it fits and gcore is present (best evidence; can be large).
        if command -v gcore >/dev/null 2>&1; then
            timeout 120 gcore -o "$outdir/core" "$PID" >>"$outdir/gdb.txt" 2>&1 \
                && log "core written to $outdir" \
                || log "gcore failed/timed out (see gdb.txt)"
        fi
    else
        log "WARN: service active but no omohaaded pid found to capture."
    fi

    systemctl restart "$SERVICE"
    exit 0
fi

log "ok: log age ${age}s (< ${STALE_SECS}s)."
exit 0
