#!/usr/bin/env python3
"""
Spike: can we learn why a join would fail, without launching the game?

Tests two assumptions from the launcher blueprint:

  1. Direct-join launch works        -- client + "+connect host:port"
  2. Failure reasons are recoverable -- the "own the bounce" feature

Finding that motivated this spike (from code/server/sv_client.c): the server
rejects clients with explicit out-of-band messages, not silence:

    droperror\\nKicked from server
    droperror\\nServer is full
    droperror\\nYou are banned from this server.\\nReason: %s
    droperror\\nServer uses protocol version %i
    print\\nServer is for high pings only
    print\\nNo or bad challenge for your address.

RESULT (2026-08-18, verified against a live OpenMoHAA 0.83.0 dedicated server):

    The pre-launch probe WORKS -- but only with MOHAA's five-byte out-of-band
    prefix. This is the detail that matters, and it is not the Quake 3 one:

        b"\\xff\\xff\\xff\\xff\\x02"   client -> server
        b"\\xff\\xff\\xff\\xff\\x01"   server -> client

    Four 0xff bytes alone (plain Q3) get you silence on every command. With the
    direction byte, all three answer immediately:

        getchallenge -> challengeResponse 1465150022   (see CAVEAT below)
        getinfo      -> infoResponse   (compact,  ~200 B, 12 keys)
        getstatus    -> statusResponse (full,    ~1.1 kB, 43 keys)

    getstatus is far richer than the GameSpy query on port 12300, and returns
    things the launcher needs that GameSpy does not expose at all:

        sv_maplist        the ENTIRE map rotation, not just the current map
        sets-cvars        serverinfo vars survive here (Connection, sqdmk...),
                          so PakRadar's pr_downloads is discoverable pre-connect
        sv_allowDownload  whether the server will serve files at all
        protocol          exact protocol version for the compatibility gate
        sv_minPing/maxPing predicts the "high pings only" rejection
        g_allowjointime   how long after round start joining is permitted
        sv_mapChecksum    server's current map checksum

    Prefer getstatus on the game port over the GameSpy query for everything
    except master-server enumeration.

CAVEAT (2026-08-19): a challengeResponse does NOT mean the join would succeed.

    An earlier version of this file claimed it did. It does not. SV_GetChallenge
    issues the token before any of the tests that can reject you; bans, capacity,
    protocol and ping gates are all evaluated later, in SV_DirectConnect. A
    challengeResponse only proves the server is awake and reachable.

    Learning the real answer would mean sending the Huffman-compressed "connect"
    packet (see fake_client.py), which on success creates a live CS_CONNECTED
    client on someone else's server. That is a join, not a probe -- do not do it
    across a server list.

    So what IS knowable before launch is exactly what getstatus reports: content,
    protocol, ping band, join window, reserved slots. Everything decided about a
    specific player is a post-launch recovery problem.

The rejection table below maps engine strings to player-facing copy, for
outcomes that still only appear after launching (kick, ban, mid-game drop).

Usage:
    python3 tools/spike_connect.py                      # probe local server
    python3 tools/spike_connect.py 1.2.3.4 12203        # probe a remote one
    python3 tools/spike_connect.py --launch /path/to/openmohaa 1.2.3.4 12203
"""

import argparse
import os
import re
import socket
import subprocess
import sys
import time

# MOHAA extends the Quake 3 out-of-band header with a direction byte.
# Without it the server ignores you entirely. See fake_client.py.
OOB_SEND = b"\xff\xff\xff\xff\x02"
OOB_RECV = b"\xff\xff\xff\xff\x01"

# code/server/sv_client.c -- rejection strings, mapped to player-facing copy.
REJECTIONS = [
    (r"Server is full", "The server is full. We'll watch for a slot."),
    (r"You are banned from this server\.?\s*(?:Reason:\s*(?P<reason>.*))?",
     "You're banned from this server.{reason}"),
    (r"Kicked from server", "You were kicked from this server."),
    (r"Server uses protocol version (?P<ver>\d+)",
     "Version mismatch - the server runs protocol {ver}. Switch profile."),
    (r"Server is for high pings only", "This server only accepts high-ping clients."),
    (r"No or bad challenge for your address", "The server refused the handshake. Try again."),
    (r"Awaiting CD key authorization", "The server is waiting on CD-key authorisation."),
    (r"Invalid password|BadPassword", "This server needs a password."),
]


def oob_request(host: str, port: int, command: str, timeout: float = 4.0) -> bytes:
    """Send one MOHAA out-of-band command and return the payload after the header."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    try:
        sock.sendto(OOB_SEND + command.encode(), (host, port))
        data, _ = sock.recvfrom(65535)
        if data.startswith(OOB_RECV):
            return data[5:]
        if data.startswith(b"\xff\xff\xff\xff"):
            return data[5:]
        return data
    finally:
        sock.close()


def parse_serverinfo(payload: str) -> dict:
    """statusResponse/infoResponse bodies are \\key\\value pairs on the second line."""
    _, _, rest = payload.partition("\n")
    line = rest.split("\n")[0]
    parts = line.split("\\")[1:]
    return dict(zip(parts[0::2], parts[1::2]))


def report_compatibility(info: dict) -> None:
    """Everything the launcher can decide before the game is even started."""
    interesting = [
        ("gamever", "engine + patch level"),
        ("protocol", "protocol version"),
        ("com_gamename", "expansion family"),
        ("mapname", "current map"),
        ("sv_allowDownload", "will the server serve files"),
        ("pure", "checksum enforcement"),
        ("sv_privateClients", "reserved slots"),
        ("g_allowjointime", "join window after round start"),
        ("sv_minPing", "min ping accepted"),
        ("sv_maxPing", "max ping accepted"),
        ("pr_downloads", "PakRadar manifest URL"),
    ]
    print("\n  compatibility-relevant fields:")
    for key, meaning in interesting:
        if key in info:
            print(f"    {key:20} = {info[key][:52]:54} ({meaning})")

    maplist = info.get("sv_maplist", "").split()
    if maplist:
        print(f"\n  sv_maplist -- FULL rotation, {len(maplist)} entries:")
        print("    " + " ".join(maplist[:12]))
        if len(maplist) > 12:
            print(f"    ... and {len(maplist) - 12} more")
        print("    (check every one of these against the local map index, not just")
        print("     the current map -- that is what prevents a mid-session drop)")


def interpret(payload: str):
    """Map a raw server reply to player-facing copy, or None if not a rejection."""
    for pattern, template in REJECTIONS:
        match = re.search(pattern, payload, re.IGNORECASE)
        if match:
            groups = match.groupdict()
            reason = groups.get("reason")
            return template.format(
                reason=f" Reason: {reason.strip()}" if reason else "",
                ver=groups.get("ver", "?"),
            )
    return None


def probe(host: str, port: int) -> int:
    print(f"probing {host}:{port}\n")

    status_info = {}
    for command in ("getchallenge", "getinfo xxx", "getstatus"):
        try:
            reply = oob_request(host, port, command)
        except socket.timeout:
            print(f"  {command:16} -> no reply (timeout)")
            continue
        except OSError as exc:
            print(f"  {command:16} -> {type(exc).__name__}: {exc}")
            continue

        text = reply.decode("latin-1", errors="replace")
        head = text.split("\n")[0][:70]
        print(f"  {command:16} -> {head}  ({len(reply)} B)")

        if command == "getstatus":
            status_info = parse_serverinfo(text)
            print(f"  {'':16}    {len(status_info)} serverinfo keys")

        message = interpret(text)
        if message:
            print(f"  {'':16}    would tell the player: {message}")

    if status_info:
        report_compatibility(status_info)

    print("\nA challengeResponse means the server is awake -- NOT that a join")
    print("would be accepted. Bans, capacity and ping gates are decided later,")
    print("in SV_DirectConnect. Only the getstatus fields above are predictive.")
    return 0


def launch(binary: str, host: str, port: int, wait: float = 25.0) -> int:
    """Launch the client straight into a server and watch its log for the outcome."""
    if not os.path.isfile(binary):
        print(f"error: no such binary: {binary}")
        return 2

    log = os.path.expanduser("~/.openmohaa/main/qconsole.log")
    start_size = os.path.getsize(log) if os.path.exists(log) else 0

    argv = [binary, "+set", "logfile", "2", "+connect", f"{host}:{port}"]
    print("launching:", " ".join(argv))
    proc = subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    deadline = time.time() + wait
    seen = ""
    while time.time() < deadline and proc.poll() is None:
        time.sleep(1.0)
        if not os.path.exists(log):
            continue
        with open(log, "r", errors="replace") as handle:
            handle.seek(start_size)
            seen += handle.read()
            start_size = handle.tell()
        if "droperror" in seen or "Server disconnected" in seen:
            break

    if proc.poll() is None:
        print(f"client still running after {wait:.0f}s -- treat that as a successful join")
    else:
        print(f"client exited with code {proc.returncode}")

    message = interpret(seen)
    if message:
        print(f"detected outcome: {message}")
    elif seen.strip():
        print("log tail (no known rejection matched):")
        print("\n".join(seen.strip().splitlines()[-12:]))
    else:
        print("no new log output captured")

    if proc.poll() is None:
        proc.terminate()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("host", nargs="?", default="127.0.0.1")
    parser.add_argument("port", nargs="?", type=int, default=12203)
    parser.add_argument("--launch", metavar="CLIENT_BINARY",
                        help="also launch this client with +connect and watch the log")
    args = parser.parse_args()

    status = probe(args.host, args.port)
    if args.launch:
        print()
        status = launch(args.launch, args.host, args.port)
    return status


if __name__ == "__main__":
    sys.exit(main())
